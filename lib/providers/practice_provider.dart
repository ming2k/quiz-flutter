import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class PracticeProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();

  // Data
  List<Section> _sections = [];
  List<Question> _questions = [];
  List<Question> _filteredQuestions = [];

  // Current State
  Book? _currentBook;
  Section? _currentSection;
  Question? _currentQuestion;
  int _currentIndex = 0;
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

  // Loading State
  bool _isLoading = false;
  String? _error;

  // Timer for debounced saving
  Timer? _saveTimer;

  // Getters
  List<Section> get sections => List.unmodifiable(_sections);
  List<Question> get questions => List.unmodifiable(_filteredQuestions);
  List<ChatMessage> get currentAiChatHistory =>
      List.unmodifiable(_currentChatHistory);
  List<ChatSession> get chatSessions => List.unmodifiable(_chatSessions);
  int? get currentChatSessionId => _currentChatSessionId;

  // AI Stream getters
  AiStreamState? get currentAiStream =>
      _currentChatSessionId != null ? _aiStreams[_currentChatSessionId] : null;
  bool get isAiStreaming => currentAiStream?.isLoading ?? false;
  String get aiStreamingResponse => currentAiStream?.streamingResponse ?? '';
  AiStreamState? getAiStream(int sessionId) => _aiStreams[sessionId];
  Book? get currentBook => _currentBook;
  Section? get currentSection => _currentSection;
  Question? get currentQuestion => _currentQuestion;
  int get currentIndex => _currentIndex;
  String get currentPartitionId => _currentPartitionId;
  String? get currentPackageImagePath => _currentPackageImagePath;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

    _chatSessions = await _db.getChatSessions(_currentQuestion!.id);

    if (_chatSessions.isNotEmpty) {
      if (_currentChatSessionId == null ||
          !_chatSessions.any((s) => s.id == _currentChatSessionId)) {
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

    final session = await _db.createChatSession(_currentQuestion!.id, title);
    _chatSessions.insert(0, session);
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
    await cancelAiChat(sessionId);
    _aiService.clearSessionContext(sessionId);

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

    if (_currentChatSessionId == null) {
      String title = message.text.replaceAll('\n', ' ').trim();
      if (title.length > 30) title = '${title.substring(0, 30)}...';
      if (title.isEmpty) title = 'Chat';

      await createChatSession(title);
    } else if (message.isUser) {
      final currentSession = _chatSessions.firstWhere(
        (s) => s.id == _currentChatSessionId,
      );
      if (currentSession.title == 'New Chat' ||
          currentSession.title == 'Chat') {
        String newTitle = message.text.replaceAll('\n', ' ').trim();
        if (newTitle.length > 30) newTitle = '${newTitle.substring(0, 30)}...';
        if (newTitle.isNotEmpty) {
          await _db.updateChatSessionTitle(_currentChatSessionId!, newTitle);
          final index = _chatSessions.indexWhere(
            (s) => s.id == _currentChatSessionId,
          );
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

  void setAiConfigurator(AiServiceConfigurator configurator) {
    _aiConfigurator = configurator;
    configurator(_aiService);
  }

  Future<void> startAiChat(String userMessage) async {
    if (_currentQuestion == null) return;

    if (_currentChatSessionId == null) {
      await createChatSession();
    }

    final sessionId = _currentChatSessionId!;
    final questionId = _currentQuestion!.id;

    if (_aiConfigurator != null) {
      _aiConfigurator!(_aiService);
    }

    if (!_aiService.isConfigured) {
      throw Exception('AI service not configured. Please set API key.');
    }

    await cancelAiChat(sessionId);

    await addAiChatMessage(ChatMessage(text: userMessage, isUser: true));
    final sessionHistory = List<ChatMessage>.from(_currentChatHistory);

    final state = AiStreamState(questionId: questionId, sessionId: sessionId);
    _aiStreams[sessionId] = state;
    notifyListeners();

    try {
      final stream = _aiService.explain(
        questionStem: _currentQuestion!.content,
        options: {for (var c in _currentQuestion!.choices) c.key: c.content},
        correctAnswer: _currentQuestion!.answer,
        userQuestion: userMessage,
        history: sessionHistory,
        sessionId: sessionId,
      );

      final subscription = stream.listen(
        (chunk) {
          state.streamingResponse += chunk;
          notifyListeners();
        },
        onError: (error) async {
          state.isLoading = false;
          state.error = error.toString().replaceAll("Exception: ", "");

          await _db.saveChatMessage(
            sessionId,
            ChatMessage(text: 'Error: ${state.error}', isUser: false),
          );

          if (_currentChatSessionId == sessionId) {
            _currentChatHistory.add(
              ChatMessage(text: 'Error: ${state.error}', isUser: false),
            );
          }

          _aiStreams.remove(sessionId);
          notifyListeners();
        },
        onDone: () async {
          state.isLoading = false;
          if (state.streamingResponse.isNotEmpty && state.error == null) {
            await _saveStreamResponse(
              sessionId,
              state.streamingResponse,
              questionId,
            );
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

      await _db.saveChatMessage(
        sessionId,
        ChatMessage(text: 'Error: ${state.error}', isUser: false),
      );

      if (_currentChatSessionId == sessionId) {
        _currentChatHistory.add(
          ChatMessage(text: 'Error: ${state.error}', isUser: false),
        );
      }

      _aiStreams.remove(sessionId);
      notifyListeners();
    }
  }

  Future<void> _saveStreamResponse(
    int sessionId,
    String response,
    int questionId,
  ) async {
    if (_currentChatSessionId == sessionId) {
      await _db.saveChatMessage(
        sessionId,
        ChatMessage(text: response, isUser: false),
      );
      if (_currentChatHistory.isEmpty ||
          _currentChatHistory.last.text != response ||
          _currentChatHistory.last.isUser) {
        _currentChatHistory.add(ChatMessage(text: response, isUser: false));
      }
    } else {
      await _db.saveChatMessage(
        sessionId,
        ChatMessage(text: response, isUser: false),
      );
    }
  }

  Future<void> cancelAiChat(int sessionId) async {
    final state = _aiStreams[sessionId];
    if (state != null) {
      final questionId = state.questionId;
      final partialResponse = state.streamingResponse;

      await state.cancel();

      if (partialResponse.isNotEmpty) {
        await _saveStreamResponse(sessionId, partialResponse, questionId);
      }

      _aiStreams.remove(sessionId);
      notifyListeners();
    }
  }

  Future<void> cancelAllAiChats() async {
    for (final state in _aiStreams.values) {
      await state.cancel();
    }
    _aiStreams.clear();
    notifyListeners();
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
      _filteredQuestions = _questions.where((q) => q.isChoiceBased).toList();
      _currentPartitionId = 'all';

      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
        _currentPackageImagePath = await PackageService().getPackageImagePath(
          book.filename,
        );
      } else {
        _currentPackageImagePath = null;
      }

      _progress = await _storage.loadProgress(book.filename);

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

      if (_filteredQuestions.isNotEmpty) {
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

  Future<void> loadCollection(Book book, int collectionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBook = book;
      _sections = await _db.getSections(book.id);
      _questions = await _db.getQuestionsByCollection(collectionId);
      _filteredQuestions = _questions.where((q) => q.isChoiceBased).toList();
      _currentPartitionId = 'collection_$collectionId';

      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
        _currentPackageImagePath = await PackageService().getPackageImagePath(
          book.filename,
        );
      } else {
        _currentPackageImagePath = null;
      }

      _progress = await _storage.loadProgress(book.filename);

      final dbAnswers = await _db.getUserAnswers(book.id);
      final dbMarks = await _db.getMarkedQuestions(book.id);

      _userAnswers.clear();
      _markedQuestions.clear();

      _userAnswers.addAll(dbAnswers);
      _markedQuestions.addAll(dbMarks);

      _resetState();
      _progress = UserProgress(bankFilename: book.filename);

      await _storage.saveLastOpenedBank(book.filename);

      if (_filteredQuestions.isNotEmpty) {
        _currentIndex = 0;
        _currentQuestion = _filteredQuestions[_currentIndex];
        await _loadChatHistory();
      }
    } catch (e) {
      _error = 'Failed to load collection: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSmartCollection(Book book, Collection collection) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBook = book;
      _sections = await _db.getSections(book.id);

      final engine = SmartCollectionEngine(db: _db);
      final ids = await engine.evaluate(book.id, collection.config);
      _questions = await _db.getQuestionsByIds(ids);
      _filteredQuestions = _questions.where((q) => q.isChoiceBased).toList();
      _currentPartitionId = 'smart_${collection.id}';

      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
        _currentPackageImagePath = await PackageService().getPackageImagePath(
          book.filename,
        );
      } else {
        _currentPackageImagePath = null;
      }

      _progress = await _storage.loadProgress(book.filename);

      final dbAnswers = await _db.getUserAnswers(book.id);
      final dbMarks = await _db.getMarkedQuestions(book.id);

      _userAnswers.clear();
      _markedQuestions.clear();

      _userAnswers.addAll(dbAnswers);
      _markedQuestions.addAll(dbMarks);

      _resetState();
      _progress = UserProgress(bankFilename: book.filename);

      await _storage.saveLastOpenedBank(book.filename);

      if (_filteredQuestions.isNotEmpty) {
        _currentIndex = 0;
        _currentQuestion = _filteredQuestions[_currentIndex];
        await _loadChatHistory();
      }
    } catch (e) {
      _error = 'Failed to load smart collection: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQuestions(Book book, List<Question> questions, {String? partitionId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBook = book;
      _sections = await _db.getSections(book.id);
      _questions = questions;
      _filteredQuestions = _questions.where((q) => q.isChoiceBased).toList();
      _currentPartitionId = partitionId ?? 'custom';

      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
        _currentPackageImagePath = await PackageService().getPackageImagePath(
          book.filename,
        );
      } else {
        _currentPackageImagePath = null;
      }

      _progress = await _storage.loadProgress(book.filename);

      final dbAnswers = await _db.getUserAnswers(book.id);
      final dbMarks = await _db.getMarkedQuestions(book.id);

      _userAnswers.clear();
      _markedQuestions.clear();

      _userAnswers.addAll(dbAnswers);
      _markedQuestions.addAll(dbMarks);

      _resetState();
      _progress = UserProgress(bankFilename: book.filename);

      await _storage.saveLastOpenedBank(book.filename);

      if (_filteredQuestions.isNotEmpty) {
        _currentIndex = 0;
        _currentQuestion = _filteredQuestions[_currentIndex];
        await _loadChatHistory();
      }
    } catch (e) {
      _error = 'Failed to load questions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _restoreProgress() {
    if (_progress == null) return;

    _currentPartitionId = _progress!.currentPartitionId;
    _currentIndex = _progress!.currentQuestionIndex;

    if (_currentPartitionId != 'all') {
      _applyPartitionFilter();
    }
  }

  void _resetState() {
    _currentPartitionId = 'all';
    _currentIndex = 0;
    _userAnswers.clear();
    _markedQuestions.clear();
  }

  // Partition (Section) Selection
  Future<void> selectPartition(String partitionId, {int? index}) async {
    _currentPartitionId = partitionId;

    if (index != null) {
      _currentIndex = index;
    } else {
      int savedIndex = 0;
      if (partitionId == 'all') {
        savedIndex = _progress?.modePositions[AppMode.practice] ?? 0;
      } else {
        savedIndex =
            _progress?.partitionModePositions[partitionId]?[AppMode.practice] ??
            0;
      }
      _currentIndex = savedIndex;
    }

    if (partitionId == 'all') {
      _filteredQuestions = _questions.where((q) => q.isChoiceBased).toList();
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
        .where((q) => q.sectionId == _currentPartitionId && q.isChoiceBased)
        .toList();
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

    final answer = UserAnswer(selected: selected, isCorrect: isCorrect);

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

  // Review mistakes from a test history entry.
  void startMistakeReview(TestHistoryEntry entry) {
    if (_currentBook == null || _questions.isEmpty) return;

    final questionMap = {for (var q in _questions) q.id: q};
    final wrongIds = <int>[];

    for (final qId in entry.questionsAsked) {
      final question = questionMap[qId];
      if (question == null) continue;

      final userAnswer = entry.answers[qId];
      if (userAnswer == null) {
        wrongIds.add(qId);
        continue;
      }
      if (userAnswer.toUpperCase() != question.answer.toUpperCase()) {
        wrongIds.add(qId);
      }
    }

    if (wrongIds.isEmpty) return;

    _filteredQuestions = wrongIds
        .map((id) => questionMap[id])
        .whereType<Question>()
        .toList();
    _currentIndex = 0;
    _currentQuestion = _filteredQuestions[0];
    _userAnswers.clear();
    _markedQuestions.clear();
    _loadChatHistory();
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

  // Save Progress
  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    if (_currentBook == null) return;

    final newModePositions = Map<AppMode, int>.from(
      _progress?.modePositions ?? {},
    );
    final newPartitionModePositions = Map<String, Map<AppMode, int>>.from(
      _progress?.partitionModePositions ?? {},
    );

    if (_currentPartitionId == 'all') {
      newModePositions[AppMode.practice] = _currentIndex;
    }

    if (!newPartitionModePositions.containsKey(_currentPartitionId)) {
      newPartitionModePositions[_currentPartitionId] = {};
    }
    newPartitionModePositions[_currentPartitionId] = Map<AppMode, int>.from(
      newPartitionModePositions[_currentPartitionId]!,
    );
    newPartitionModePositions[_currentPartitionId]![AppMode.practice] =
        _currentIndex;

    final progress =
        _progress?.copyWith(
          appMode: AppMode.practice,
          currentQuestionIndex: _currentIndex,
          currentPartitionId: _currentPartitionId,
          modePositions: newModePositions,
          partitionModePositions: newPartitionModePositions,
        ) ??
        UserProgress(
          bankFilename: _currentBook!.filename,
          appMode: AppMode.practice,
          currentQuestionIndex: _currentIndex,
          currentPartitionId: _currentPartitionId,
          modePositions: newModePositions,
          partitionModePositions: newPartitionModePositions,
        );

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
    for (final state in _aiStreams.values) {
      state.cancel();
    }
    _aiStreams.clear();
    super.dispose();
  }
}
