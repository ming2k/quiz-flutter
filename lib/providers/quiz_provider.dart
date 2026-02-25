import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Callback for configuring AiService before use
typedef AiServiceConfigurator = void Function(AiService service);

class QuizProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();

  // Data
  List<Book> _books = [];
  List<Section> _sections = [];
  List<Question> _questions = [];
  List<Question> _filteredQuestions = [];

  // Current State
  Book? _currentBook;
  Section? _currentSection;
  Question? _currentQuestion;
  int _currentIndex = 0;
  AppMode _appMode = AppMode.practice;
  String _currentPartitionId = 'all';
  String? _currentPackageImagePath;

  // Chat
  List<ChatMessage> _currentChatHistory = [];
  List<ChatSession> _chatSessions = [];
  int? _currentChatSessionId;

  // AI Streaming - managed by Provider for background continuation
  final AiService _aiService = AiService();
  final Map<int, AiStreamState> _aiStreams = {}; // sessionId -> state
  AiServiceConfigurator? _aiConfigurator;

  // Progress
  UserProgress? _progress;
  final Map<int, UserAnswer> _userAnswers = {};
  final Set<int> _markedQuestions = {};

  // Test Mode
  bool _isTestActive = false;
  int _testStartTime = 0;
  List<int> _testQuestionIndices = [];

  // Loading State
  bool _isLoading = false;
  String? _error;

  // Timer for debounced saving
  Timer? _saveTimer;

  // Getters
  List<Book> get books => List.unmodifiable(_books);
  List<Section> get sections => List.unmodifiable(_sections);
  List<Question> get questions => List.unmodifiable(_filteredQuestions);
  List<ChatMessage> get currentAiChatHistory => List.unmodifiable(_currentChatHistory);
  List<ChatSession> get chatSessions => List.unmodifiable(_chatSessions);
  int? get currentChatSessionId => _currentChatSessionId;

  // AI Stream getters
  AiStreamState? get currentAiStream => _currentChatSessionId != null ? _aiStreams[_currentChatSessionId] : null;
  bool get isAiStreaming => currentAiStream?.isLoading ?? false;
  String get aiStreamingResponse => currentAiStream?.streamingResponse ?? '';
  AiStreamState? getAiStream(int sessionId) => _aiStreams[sessionId];
  Book? get currentBook => _currentBook;
  Section? get currentSection => _currentSection;
  Question? get currentQuestion => _currentQuestion;
  int get currentIndex => _currentIndex;
  AppMode get appMode => _appMode;
  String get currentPartitionId => _currentPartitionId;
  String? get currentPackageImagePath => _currentPackageImagePath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTestActive => _isTestActive;
  int get testStartTime => _testStartTime;

  int get totalQuestions => _filteredQuestions.length;

  UserAnswer? get currentUserAnswer {
    if (_currentQuestion == null) return null;
    return _userAnswers[_currentQuestion!.id];
  }

  bool get isCurrentMarked {
    if (_currentQuestion == null) return false;
    return _markedQuestions.contains(_currentQuestion!.id);
  }

  bool isMarked(int questionId) {
    return _markedQuestions.contains(questionId);
  }

  int get correctCount =>
      _userAnswers.values.where((a) => a.isCorrect == true).length;
  int get wrongCount =>
      _userAnswers.values.where((a) => a.isCorrect == false).length;
  int get answeredCount => _userAnswers.length;
  int get unansweredCount => totalQuestions - answeredCount;
  int get markedCount => _markedQuestions.length;

  double get accuracy {
    final answered = correctCount + wrongCount;
    if (answered == 0) return 0;
    return correctCount / answered;
  }

  // AI Chat
  Future<void> _loadChatHistory() async {
    if (_currentQuestion == null) {
      _currentChatHistory = [];
      _chatSessions = [];
      _currentChatSessionId = null;
      return;
    }
    
    // Load sessions for this question
    _chatSessions = await _db.getChatSessions(_currentQuestion!.id);
    
    if (_chatSessions.isNotEmpty) {
      // If we don't have a current session selected, or the selected one isn't in the list
      // (e.g. changed question), select the most recent one (first in list).
      if (_currentChatSessionId == null || !_chatSessions.any((s) => s.id == _currentChatSessionId)) {
        _currentChatSessionId = _chatSessions.first.id;
      }
      
      if (_currentChatSessionId != null) {
        _currentChatHistory = await _db.getChatHistory(_currentChatSessionId!);
      }
    } else {
      _currentChatSessionId = null;
      _currentChatHistory = [];
    }
    
    notifyListeners();
  }
  
  Future<void> createChatSession([String title = 'New Chat']) async {
    if (_currentQuestion == null) return;
    
    // In the new multi-session logic, we DON'T cancel other sessions
    // Each session can have its own background stream.
    
    final session = await _db.createChatSession(_currentQuestion!.id, title);
    _chatSessions.insert(0, session); // Add to top
    _currentChatSessionId = session.id;
    _currentChatHistory = [];
    notifyListeners();
  }
  
  Future<void> switchChatSession(int sessionId) async {
    if (_currentChatSessionId == sessionId) return;
    
    _currentChatSessionId = sessionId;
    _currentChatHistory = await _db.getChatHistory(sessionId);
    notifyListeners();
  }

  Future<void> deleteChatSession(int sessionId) async {
    // Cancel stream if active
    await cancelAiChat(sessionId);
    
    await _db.deleteChatSession(sessionId);
    _chatSessions.removeWhere((s) => s.id == sessionId);
    
    if (_currentChatSessionId == sessionId) {
      if (_chatSessions.isNotEmpty) {
        _currentChatSessionId = _chatSessions.first.id;
        _currentChatHistory = await _db.getChatHistory(_currentChatSessionId!);
      } else {
        _currentChatSessionId = null;
        _currentChatHistory = [];
      }
    }
    notifyListeners();
  }

  Future<void> addAiChatMessage(ChatMessage message) async {
    if (_currentQuestion == null) return;

    // If no session exists, create one
    if (_currentChatSessionId == null) {
      // Use the message text as title, truncated
      String title = message.text.replaceAll('\n', ' ').trim();
      if (title.length > 30) title = '${title.substring(0, 30)}...';
      if (title.isEmpty) title = 'Chat';

      await createChatSession(title);
    } else if (message.isUser) {
      // If it's the first user message in a "New Chat", update the title
      final currentSession = _chatSessions.firstWhere((s) => s.id == _currentChatSessionId);
      if (currentSession.title == 'New Chat' || currentSession.title == 'Chat' || currentSession.title == '新对话') {
        String newTitle = message.text.replaceAll('\n', ' ').trim();
        if (newTitle.length > 30) newTitle = '${newTitle.substring(0, 30)}...';
        if (newTitle.isNotEmpty) {
          await _db.updateChatSessionTitle(_currentChatSessionId!, newTitle);
          // Update in-memory list
          final index = _chatSessions.indexWhere((s) => s.id == _currentChatSessionId);
          if (index != -1) {
            _chatSessions[index] = ChatSession(
              id: currentSession.id,
              questionId: currentSession.questionId,
              title: newTitle,
              createdAt: currentSession.createdAt,
            );
          }
        }
      }
    }

    if (_currentChatSessionId != null) {
      await _db.saveChatMessage(_currentChatSessionId!, message);
      _currentChatHistory.add(message);
      notifyListeners();
    }
  }

  // AI Service Configuration
  void setAiConfigurator(AiServiceConfigurator configurator) {
    _aiConfigurator = configurator;
    configurator(_aiService);
  }

  /// Start AI chat stream for a question
  /// Returns immediately, stream runs in background
  Future<void> startAiChat(String userMessage) async {
    if (_currentQuestion == null) return;

    // Ensure we have a session
    if (_currentChatSessionId == null) {
      await createChatSession();
    }
    
    final sessionId = _currentChatSessionId!;
    final questionId = _currentQuestion!.id;

    // Configure AI service if configurator is set
    if (_aiConfigurator != null) {
      _aiConfigurator!(_aiService);
    }

    if (!_aiService.isConfigured) {
      throw Exception('AI service not configured. Please set API key.');
    }

    // Cancel any existing stream for THIS session
    await cancelAiChat(sessionId);

    // Add user message
    await addAiChatMessage(ChatMessage(text: userMessage, isUser: true));

    // Create stream state
    final state = AiStreamState(
      questionId: questionId,
      sessionId: sessionId,
    );
    _aiStreams[sessionId] = state;
    notifyListeners();

    try {
      final stream = _aiService.explain(
        questionStem: _currentQuestion!.content,
        options: {for (var c in _currentQuestion!.choices) c.key: c.content},
        correctAnswer: _currentQuestion!.answer,
        userQuestion: userMessage,
      );

      final subscription = stream.listen(
        (chunk) {
          state.streamingResponse += chunk;
          notifyListeners();
        },
        onError: (error) async {
          state.isLoading = false;
          state.error = error.toString().replaceAll("Exception: ", "");
          
          // Save error to DB for this session
          await _db.saveChatMessage(sessionId, ChatMessage(
            text: 'Error: ${state.error}',
            isUser: false,
          ));
          
          // If this session is still current, add to in-memory history
          if (_currentChatSessionId == sessionId) {
            _currentChatHistory.add(ChatMessage(
              text: 'Error: ${state.error}',
              isUser: false,
            ));
          }
          
          _aiStreams.remove(sessionId);
          notifyListeners();
        },
        onDone: () async {
          state.isLoading = false;
          if (state.streamingResponse.isNotEmpty && state.error == null) {
            await _saveStreamResponse(sessionId, state.streamingResponse, questionId);
          }
          _aiStreams.remove(sessionId);
          notifyListeners();
        },
        cancelOnError: true,
      );

      state.setSubscription(subscription);
    } catch (e) {
      state.isLoading = false;
      state.error = e.toString().replaceAll("Exception: ", "");
      
      await _db.saveChatMessage(sessionId, ChatMessage(
        text: 'Error: ${state.error}',
        isUser: false,
      ));
      
      if (_currentChatSessionId == sessionId) {
        _currentChatHistory.add(ChatMessage(
          text: 'Error: ${state.error}',
          isUser: false,
        ));
      }
      
      _aiStreams.remove(sessionId);
      notifyListeners();
    }
  }

  /// Save completed stream response to chat history
  Future<void> _saveStreamResponse(int sessionId, String response, int questionId) async {
    // Check if this session is still current
    if (_currentChatSessionId == sessionId) {
      await _db.saveChatMessage(sessionId, ChatMessage(text: response, isUser: false));
      // Only add to history if it's not already the last message
      if (_currentChatHistory.isEmpty || _currentChatHistory.last.text != response || _currentChatHistory.last.isUser) {
        _currentChatHistory.add(ChatMessage(text: response, isUser: false));
      }
    } else {
      // Save directly to DB for background session
      await _db.saveChatMessage(sessionId, ChatMessage(text: response, isUser: false));
    }
  }

  /// Cancel AI chat stream for a specific session
  Future<void> cancelAiChat(int sessionId) async {
    final state = _aiStreams[sessionId];
    if (state != null) {
      final questionId = state.questionId;
      final partialResponse = state.streamingResponse;
      
      await state.cancel();
      
      // Save partial response if exists
      if (partialResponse.isNotEmpty) {
        await _saveStreamResponse(sessionId, partialResponse, questionId);
      }
      
      _aiStreams.remove(sessionId);
      notifyListeners();
    }
  }

  /// Cancel all active AI streams
  Future<void> cancelAllAiChats() async {
    for (final state in _aiStreams.values) {
      await state.cancel();
    }
    _aiStreams.clear();
    notifyListeners();
  }

  // Delete Book
  Future<void> deleteBook(int bookId) async {
    try {
      await _db.deleteBook(bookId);
      await loadBooks(); // Reload list
      
      // If deleted book was selected, clear selection
      if (_currentBook?.id == bookId) {
        _currentBook = null;
        _sections = [];
        _questions = [];
        _filteredQuestions = [];
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to delete book: $e';
      notifyListeners();
    }
  }

  // Initialize
  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _db.getBooks();

      final bool isSampleInitialized = await _storage.loadSetting<bool>('is_sample_quiz_initialized', defaultValue: false) ?? false;

      // Import built-in sample package on first run if no books exist and not yet initialized
      if (_books.isEmpty && !isSampleInitialized) {
        final result = await PackageService().importBuiltInPackage('assets/packages/sample-quiz.zip');
        if (!result.success && result.errorMessage != null) {
          _error = result.errorMessage;
        } else {
          await _storage.saveSetting('is_sample_quiz_initialized', true);
        }
        _books = await _db.getBooks();
      }
    } catch (e) {
      _error = 'Failed to load books: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reorder Books
  Future<void> reorderBooks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _books.removeAt(oldIndex);
    _books.insert(newIndex, item);
    notifyListeners();

    // Persist order
    final ids = _books.map((b) => b.id).toList();
    try {
      await _db.updateBookOrder(ids);
    } catch (e) {
      // Ignore or log error if DB update fails (e.g. schema mismatch)
      // print('Failed to update book order: $e');
    }
  }

  // Select Book
  Future<void> selectBook(Book book) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBook = book;
      _sections = await _db.getSections(book.id);
      _questions = await _db.getQuestions(book.id);
      _filteredQuestions = _questions.where((q) => q.choices.isNotEmpty || q.answer.isNotEmpty).toList();
      _currentPartitionId = 'all';

      // Load package image path if applicable
      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
         _currentPackageImagePath = await PackageService().getPackageImagePath(book.filename);
      } else {
         _currentPackageImagePath = null;
      }

      // Load saved progress (metadata like current index/mode)
      _progress = await _storage.loadProgress(book.filename);
      
      // Load answers and marks from SQLite
      final dbAnswers = await _db.getUserAnswers(book.id);
      final dbMarks = await _db.getMarkedQuestions(book.id);

      _userAnswers.clear();
      _markedQuestions.clear();

      _userAnswers.addAll(dbAnswers);
      _markedQuestions.addAll(dbMarks);

      if (_progress != null) {
        _restoreProgress();
      } else {
        _resetState();
        _progress = UserProgress(bankFilename: book.filename);
      }
      
      await _storage.saveLastOpenedBank(book.filename);

      // _restoreProgress calls _applyPartitionFilter which populates _filteredQuestions
      if (_filteredQuestions.isNotEmpty) {
        // Clamp index to a valid range of the FILTERED list
        if (_currentIndex >= _filteredQuestions.length) {
          _currentIndex = _filteredQuestions.length - 1;
        }
        if (_currentIndex < 0) {
          _currentIndex = 0;
        }
        _currentQuestion = _filteredQuestions[_currentIndex];
        await _loadChatHistory();
      }
    } catch (e) {
      _error = 'Failed to load book: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _restoreProgress() {
    if (_progress == null) return;

    _appMode = _progress!.appMode;
    _currentPartitionId = _progress!.currentPartitionId;
    _currentIndex = _progress!.currentQuestionIndex;

    // Apply partition filter if needed
    if (_currentPartitionId != 'all') {
      _applyPartitionFilter();
    }
  }

  void _resetState() {
    _appMode = AppMode.practice;
    _currentPartitionId = 'all';
    _currentIndex = 0;
    _userAnswers.clear();
    _markedQuestions.clear();
    _isTestActive = false;
  }

  // Partition (Section) Selection
  Future<void> selectPartition(String partitionId, {int? index}) async {
    _currentPartitionId = partitionId;
    
    if (index != null) {
      _currentIndex = index;
    } else {
      // Try to restore index for this partition and current mode
      int savedIndex = 0;
      if (partitionId == 'all') {
         savedIndex = _progress?.modePositions[_appMode] ?? 0;
      } else {
         savedIndex = _progress?.partitionModePositions[partitionId]?[_appMode] ?? 0;
      }
      _currentIndex = savedIndex;
    }

    if (partitionId == 'all') {
      _filteredQuestions = _questions.where((q) => q.choices.isNotEmpty || q.answer.isNotEmpty).toList();
    } else {
      _applyPartitionFilter();
    }

    if (_filteredQuestions.isNotEmpty) {
      if (_currentIndex >= _filteredQuestions.length) _currentIndex = 0;
      _currentQuestion = _filteredQuestions[_currentIndex];
      _loadChatHistory();
    }

    _debouncedSave();
    notifyListeners();
  }

  void _applyPartitionFilter() {
    _filteredQuestions = _questions
        .where((q) =>
            q.sectionId == _currentPartitionId &&
            (q.choices.isNotEmpty || q.answer.isNotEmpty))
        .toList();
  }

  // Mode Selection
  void setMode(AppMode mode, {int? index}) {
    _appMode = mode;

    if (_currentPartitionId == 'all') {
      _filteredQuestions = _questions.where((q) => q.choices.isNotEmpty || q.answer.isNotEmpty).toList();
    } else {
      _applyPartitionFilter();
    }

    if (index != null) {
      _currentIndex = index;
    } else {
       // Try to restore index for this mode and current partition
       int savedIndex = 0;
       if (_currentPartitionId == 'all') {
         savedIndex = _progress?.modePositions[mode] ?? 0;
       } else {
         savedIndex = _progress?.partitionModePositions[_currentPartitionId]?[mode] ?? 0;
       }
       _currentIndex = savedIndex;
    }

    // Ensure index is within bounds (in case question list changed)
    if (_filteredQuestions.isNotEmpty) {
      if (_currentIndex >= _filteredQuestions.length) {
        _currentIndex = _filteredQuestions.length - 1;
      }
      if (_currentIndex < 0) {
        _currentIndex = 0;
      }
      _currentQuestion = _filteredQuestions[_currentIndex];
      _loadChatHistory();
    }

    _debouncedSave();
    notifyListeners();
  }

  // Navigation
  void goToQuestion(int index) {
    if (index < 0 || index >= _filteredQuestions.length) return;
    _currentIndex = index;
    _currentQuestion = _filteredQuestions[_currentIndex];
    _loadChatHistory();
    _debouncedSave();
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _filteredQuestions.length - 1) {
      goToQuestion(_currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      goToQuestion(_currentIndex - 1);
    }
  }

  // Answer Question
  Future<void> answerQuestion(String selected) async {
    if (_currentQuestion == null || _currentBook == null) return;

    final isCorrect =
        selected.toUpperCase() == _currentQuestion!.answer.toUpperCase();

    final answer = UserAnswer(
      selected: selected,
      isCorrect: isCorrect,
    );

    _userAnswers[_currentQuestion!.id] = answer;
    await _db.saveUserAnswer(_currentBook!.id, _currentQuestion!.id, answer);

    _debouncedSave();
    notifyListeners();
  }

  // Mark Question
  Future<void> toggleMark([int? questionId]) async {
    if (_currentBook == null) return;

    final id = questionId ?? _currentQuestion?.id;
    if (id == null) return;

    final isMarked = !_markedQuestions.contains(id);
    if (isMarked) {
      _markedQuestions.add(id);
    } else {
      _markedQuestions.remove(id);
    }

    await _db.setUserMark(_currentBook!.id, id, isMarked);

    _debouncedSave();
    notifyListeners();
  }

  // Reset Current Question
  Future<void> resetCurrentQuestion() async {
    if (_currentQuestion == null) return;
    _userAnswers.remove(_currentQuestion!.id);
    await _db.deleteUserAnswer(_currentQuestion!.id);
    _debouncedSave();
    notifyListeners();
  }

  // Reset All Progress
  Future<void> resetAllProgress() async {
    if (_currentBook == null) return;
    _userAnswers.clear();
    _markedQuestions.clear();
    _currentIndex = 0;
    if (_filteredQuestions.isNotEmpty) {
      _currentQuestion = _filteredQuestions[0];
      await _loadChatHistory();
    }
    
    await _db.clearBookProgress(_currentBook!.id);
    await _saveProgress();
    notifyListeners();
  }

  // Test Mode
  void startTest(int questionCount) {
    final random = Random();
    final validIndices = <int>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.choices.isNotEmpty || q.answer.isNotEmpty) {
        validIndices.add(i);
      }
    }
    
    validIndices.shuffle(random);

    _testQuestionIndices =
        validIndices.take(min(questionCount, validIndices.length)).toList();
    _filteredQuestions =
        _testQuestionIndices.map((i) => _questions[i]).toList();

    _currentIndex = 0;
    if (_filteredQuestions.isNotEmpty) {
      _currentQuestion = _filteredQuestions[0];
      _loadChatHistory();
    }

    _userAnswers.clear();
    _isTestActive = true;
    _testStartTime = DateTime.now().millisecondsSinceEpoch;
    _appMode = AppMode.test;

    notifyListeners();
  }

  Future<TestHistoryEntry> finishTest() async {
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final duration = endTime - _testStartTime;

    final entry = TestHistoryEntry(
      bankFilename: _currentBook!.filename,
      mode: 'test',
      totalQuestions: _filteredQuestions.length,
      correctCount: correctCount,
      wrongCount: wrongCount,
      unansweredCount: unansweredCount,
      accuracy: accuracy,
      startTime: _testStartTime,
      endTime: endTime,
      duration: duration,
      questionsAsked: _testQuestionIndices,
      answers: _userAnswers.map((k, v) => MapEntry(k, v.selected ?? '')),
      timestamp: endTime,
    );

    await _storage.addHistoryEntry(entry);

    _isTestActive = false;
    _testStartTime = 0;
    _testQuestionIndices.clear();

    // Restore normal mode
    _appMode = AppMode.practice;
    if (_currentPartitionId == 'all') {
      _filteredQuestions = _questions.where((q) => q.choices.isNotEmpty || q.answer.isNotEmpty).toList();
    } else {
      _applyPartitionFilter();
    }
    _currentIndex = 0;
    if (_filteredQuestions.isNotEmpty) {
      _currentQuestion = _filteredQuestions[0];
      _loadChatHistory();
    }

    notifyListeners();
    return entry;
  }

  // Get Test History
  Future<List<TestHistoryEntry>> getTestHistory() async {
    if (_currentBook == null) return [];
    return await _storage.getHistoryEntries(_currentBook!.filename);
  }

  // Save Progress
  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    if (_currentBook == null) return;

    // Create or update the maps
    final newModePositions =
        Map<AppMode, int>.from(_progress?.modePositions ?? {});
    final newPartitionModePositions =
        Map<String, Map<AppMode, int>>.from(_progress?.partitionModePositions ?? {});

    // Update current positions
    if (_currentPartitionId == 'all') {
      newModePositions[_appMode] = _currentIndex;
    }

    // Always update partition map for the current partition
    if (!newPartitionModePositions.containsKey(_currentPartitionId)) {
      newPartitionModePositions[_currentPartitionId] = {};
    }
    // We need to copy the inner map too if we are modifying it
    newPartitionModePositions[_currentPartitionId] =
        Map<AppMode, int>.from(newPartitionModePositions[_currentPartitionId]!);
    newPartitionModePositions[_currentPartitionId]![_appMode] = _currentIndex;

    final progress = _progress?.copyWith(
          appMode: _appMode,
          currentQuestionIndex: _currentIndex,
          currentPartitionId: _currentPartitionId,
          modePositions: newModePositions,
          partitionModePositions: newPartitionModePositions,
        ) ??
        UserProgress(
          bankFilename: _currentBook!.filename,
          appMode: _appMode,
          currentQuestionIndex: _currentIndex,
          currentPartitionId: _currentPartitionId,
          modePositions: newModePositions,
          partitionModePositions: newPartitionModePositions,
        );

    // No longer saving userAnswersByPartition or markedQuestionsByPartition here
    // as they are handled by SQLite.

    final finalProgress = progress.copyWith(
      statsByPartition: {
        ...progress.statsByPartition,
        _currentPartitionId: PartitionStats(
          correct: correctCount,
          wrong: wrongCount,
        ),
      },
    );

    await _storage.saveProgress(finalProgress);
    _progress = finalProgress;
  }

  // Question status for overview
  QuestionStatus getQuestionStatus(int index) {
    if (index < 0 || index >= _filteredQuestions.length) {
      return QuestionStatus.unanswered;
    }

    final question = _filteredQuestions[index];
    final answer = _userAnswers[question.id];
    final isMarked = _markedQuestions.contains(question.id);

    if (isMarked) return QuestionStatus.marked;
    if (answer == null) return QuestionStatus.unanswered;
    if (answer.isCorrect == true) return QuestionStatus.correct;
    return QuestionStatus.wrong;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Cancel all AI streams
    for (final state in _aiStreams.values) {
      state.cancel();
    }
    _aiStreams.clear();
    super.dispose();
  }
}

enum QuestionStatus { unanswered, correct, wrong, marked }