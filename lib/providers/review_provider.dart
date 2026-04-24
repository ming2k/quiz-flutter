import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class ReviewProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  Book? _currentBook;
  List<Question> _questions = [];
  List<int> _reviewQueue = [];
  Map<int, SrsState> _srsStates = {};
  int _currentQueueIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  String? _error;
  SrsStats? _stats;

  // Getters
  Book? get currentBook => _currentBook;
  List<Question> get questions => List.unmodifiable(_questions);
  bool get showAnswer => _showAnswer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isComplete => _currentQueueIndex >= _reviewQueue.length;
  int get remaining => _reviewQueue.length - _currentQueueIndex;
  int get total => _reviewQueue.length;
  int get currentIndex => _currentQueueIndex;
  SrsStats? get stats => _stats;

  Question? get currentQuestion {
    if (isComplete || _currentQueueIndex >= _reviewQueue.length) return null;
    final qId = _reviewQueue[_currentQueueIndex];
    return _questions.firstWhere(
      (q) => q.id == qId,
      orElse: () => Question(
        id: -1,
        bookId: -1,
        sectionId: '',
        content: '',
        choices: [],
        answer: '',
        explanation: '',
      ),
    );
  }

  SrsState? get currentSrsState {
    if (currentQuestion == null || currentQuestion!.id == -1) return null;
    return _srsStates[currentQuestion!.id];
  }

  bool get isCurrentNew {
    final state = currentSrsState;
    return state == null || state.isNew;
  }

  Future<void> loadStats(Book book) async {
    _stats = await _db.getSrsStats(book.id);
    notifyListeners();
  }

  Future<void> startReview(Book book) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBook = book;
      _questions = await _db.getQuestions(book.id);

      // Initialize SRS records for any questions that don't have them yet
      await _db.initializeSrsForBook(book.id);

      // Get due cards (learning + review)
      final dueIds = await _db.getDueQuestionIds(book.id);

      // Get new cards (limit to 20 new cards per session)
      final newIds = await _db.getNewQuestionIds(book.id);
      final limitedNewIds = newIds.take(20).toList();

      // Build queue: due cards first (sorted by due date), then new cards
      _reviewQueue = [...dueIds, ...limitedNewIds];
      _srsStates = await _db.getSrsStates(book.id);

      _currentQueueIndex = 0;
      _showAnswer = false;

      // Refresh stats
      _stats = await _db.getSrsStats(book.id);
    } catch (e) {
      _error = 'Failed to start review: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void revealAnswer() {
    _showAnswer = true;
    notifyListeners();
  }

  Future<void> rateCard(SrsRating rating) async {
    if (isComplete || currentQuestion == null || currentQuestion!.id == -1) {
      return;
    }

    final qId = currentQuestion!.id;
    final state = _srsStates[qId] ??
        SrsState(
          questionId: qId,
          bookId: _currentBook!.id,
        );

    final newState = SrsService.review(state, rating);
    _srsStates[qId] = newState;
    await _db.saveSrsState(newState);

    _showAnswer = false;
    _currentQueueIndex++;

    // Refresh stats after rating
    _stats = await _db.getSrsStats(_currentBook!.id);

    notifyListeners();
  }

  Future<void> resetReview() async {
    if (_currentBook == null) return;
    await startReview(_currentBook!);
  }

  void clear() {
    _currentBook = null;
    _questions = [];
    _reviewQueue = [];
    _srsStates = {};
    _currentQueueIndex = 0;
    _showAnswer = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
