import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

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
  List<ChatMessage> get currentAiChatHistory {
    if (_currentQuestion == null || _progress == null) return [];
    return _progress!.aiChatHistoryByQuestionId[_currentQuestion!.id] ?? [];
  }
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

  int get correctCount =>
      _userAnswers.values.where((a) => a.isCorrect == true).length;
  int get wrongCount =>
      _userAnswers.values.where((a) => a.isCorrect == false).length;
  int get answeredCount => _userAnswers.length;
  int get unansweredCount => totalQuestions - answeredCount;

  double get accuracy {
    final answered = correctCount + wrongCount;
    if (answered == 0) return 0;
    return correctCount / answered;
  }

  // AI Chat
  Future<void> addAiChatMessage(ChatMessage message) async {
    if (_currentQuestion == null || _progress == null) return;

    final questionId = _currentQuestion!.id;
    final history = _progress!.aiChatHistoryByQuestionId[questionId] ?? [];
    history.add(message);

    final newHistoryMap =
        Map<int, List<ChatMessage>>.from(_progress!.aiChatHistoryByQuestionId);
    newHistoryMap[questionId] = history;

    _progress = _progress!.copyWith(aiChatHistoryByQuestionId: newHistoryMap);
    await _saveProgress();
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

      // Import built-in packages on first run if no books exist
      if (_books.isEmpty) {
        final builtInPackages = [
          'assets/packages/maritime-english.zip',
          'assets/packages/navigation.zip',
          'assets/packages/ship-management.zip',
          'assets/packages/ship-maneuvering-collision-avoidance.zip',
          'assets/packages/ship-structure-cargo.zip',
          'assets/packages/sample-quiz.zip',
        ];

        for (final package in builtInPackages) {
          try {
            await PackageService().importBuiltInPackage(package);
          } catch (e) {
            print('Failed to import built-in package $package: $e');
          }
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
      _filteredQuestions = List.from(_questions);
      _currentPartitionId = 'all';

      // Load package image path if applicable
      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
         _currentPackageImagePath = await PackageService().getPackageImagePath(book.filename);
      } else {
         _currentPackageImagePath = null;
      }

      // Load saved progress
      _progress = await _storage.loadProgress(book.filename);
      if (_progress != null) {
        _restoreProgress();
      } else {
        _resetState();
        // Create initial progress if none exists
        _progress = UserProgress(bankFilename: book.filename);
      }
      
      await _storage.saveLastOpenedBank(book.filename);

      if (_filteredQuestions.isNotEmpty) {
        // Clamp index to a valid range
        if (_currentIndex >= _filteredQuestions.length) {
          _currentIndex = _filteredQuestions.length - 1;
        }
        if (_currentIndex < 0) {
          _currentIndex = 0;
        }
        _currentQuestion = _filteredQuestions[_currentIndex];
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

    // Restore user answers
    _userAnswers.clear();
    final partitionAnswers =
        _progress!.userAnswersByPartition[_currentPartitionId] ?? [];
    for (int i = 0; i < partitionAnswers.length && i < _filteredQuestions.length; i++) {
      if (partitionAnswers[i].selected != null) {
        _userAnswers[_filteredQuestions[i].id] = partitionAnswers[i];
      }
    }

    // Restore marked questions
    _markedQuestions.clear();
    final markedIndices =
        _progress!.markedQuestionsByPartition[_currentPartitionId] ?? [];
    for (final idx in markedIndices) {
      if (idx < _filteredQuestions.length) {
        _markedQuestions.add(_filteredQuestions[idx].id);
      }
    }

    // Apply partition filter
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
  Future<void> selectPartition(String partitionId) async {
    _currentPartitionId = partitionId;
    _currentIndex = 0;

    if (partitionId == 'all') {
      _filteredQuestions = List.from(_questions);
    } else {
      _applyPartitionFilter();
    }

    if (_filteredQuestions.isNotEmpty) {
      _currentQuestion = _filteredQuestions[_currentIndex];
    }

    _debouncedSave();
    notifyListeners();
  }

  void _applyPartitionFilter() {
    _filteredQuestions =
        _questions.where((q) => q.sectionId == _currentPartitionId).toList();
  }

  // Mode Selection
  void setMode(AppMode mode) {
    _appMode = mode;

    if (mode == AppMode.review) {
      // Filter to only wrong/marked questions
      _filteredQuestions = _questions.where((q) {
        final answer = _userAnswers[q.id];
        return (answer != null && answer.isCorrect == false) ||
            _markedQuestions.contains(q.id);
      }).toList();
    } else if (_currentPartitionId == 'all') {
      _filteredQuestions = List.from(_questions);
    } else {
      _applyPartitionFilter();
    }

    _currentIndex = 0;
    if (_filteredQuestions.isNotEmpty) {
      _currentQuestion = _filteredQuestions[_currentIndex];
    }

    _debouncedSave();
    notifyListeners();
  }

  // Navigation
  void goToQuestion(int index) {
    if (index < 0 || index >= _filteredQuestions.length) return;
    _currentIndex = index;
    _currentQuestion = _filteredQuestions[_currentIndex];
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
  void answerQuestion(String selected) {
    if (_currentQuestion == null) return;

    final isCorrect =
        selected.toUpperCase() == _currentQuestion!.answer.toUpperCase();

    _userAnswers[_currentQuestion!.id] = UserAnswer(
      selected: selected,
      isCorrect: isCorrect,
    );

    _debouncedSave();
    notifyListeners();
  }

  // Mark Question
  void toggleMark() {
    if (_currentQuestion == null) return;

    if (_markedQuestions.contains(_currentQuestion!.id)) {
      _markedQuestions.remove(_currentQuestion!.id);
    } else {
      _markedQuestions.add(_currentQuestion!.id);
    }

    _debouncedSave();
    notifyListeners();
  }

  // Reset Current Question
  void resetCurrentQuestion() {
    if (_currentQuestion == null) return;
    _userAnswers.remove(_currentQuestion!.id);
    _debouncedSave();
    notifyListeners();
  }

  // Reset All Progress
  Future<void> resetAllProgress() async {
    _userAnswers.clear();
    _markedQuestions.clear();
    _currentIndex = 0;
    if (_filteredQuestions.isNotEmpty) {
      _currentQuestion = _filteredQuestions[0];
    }
    await _saveProgress();
    notifyListeners();
  }

  // Test Mode
  void startTest(int questionCount) {
    final random = Random();
    final indices = List<int>.generate(_questions.length, (i) => i);
    indices.shuffle(random);

    _testQuestionIndices =
        indices.take(min(questionCount, _questions.length)).toList();
    _filteredQuestions =
        _testQuestionIndices.map((i) => _questions[i]).toList();

    _currentIndex = 0;
    if (_filteredQuestions.isNotEmpty) {
      _currentQuestion = _filteredQuestions[0];
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
      _filteredQuestions = List.from(_questions);
    } else {
      _applyPartitionFilter();
    }
    _currentIndex = 0;
    if (_filteredQuestions.isNotEmpty) {
      _currentQuestion = _filteredQuestions[0];
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

    final progress = _progress?.copyWith(
          appMode: _appMode,
          currentQuestionIndex: _currentIndex,
          currentPartitionId: _currentPartitionId,
          // The maps below are complex; handle them carefully
          // This is a simplified example. A real app might need a
          // more robust way to merge/update these maps.
        ) ??
        UserProgress(
          bankFilename: _currentBook!.filename,
          appMode: _appMode,
          currentQuestionIndex: _currentIndex,
          currentPartitionId: _currentPartitionId,
        );

    // This is not ideal, we should be merging maps, not overwriting
    // but for this example, we'll just save the current state.
    final answersList = <UserAnswer>[];
    for (int i = 0; i < _filteredQuestions.length; i++) {
      final answer = _userAnswers[_filteredQuestions[i].id];
      answersList.add(answer ?? UserAnswer());
    }

    final markedIndices = <int>[];
    for (int i = 0; i < _filteredQuestions.length; i++) {
      if (_markedQuestions.contains(_filteredQuestions[i].id)) {
        markedIndices.add(i);
      }
    }

    final finalProgress = progress.copyWith(
      userAnswersByPartition: {
        ...progress.userAnswersByPartition,
        _currentPartitionId: answersList,
      },
      markedQuestionsByPartition: {
        ...progress.markedQuestionsByPartition,
        _currentPartitionId: markedIndices,
      },
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
    super.dispose();
  }
}

enum QuestionStatus { unanswered, correct, wrong, marked }
