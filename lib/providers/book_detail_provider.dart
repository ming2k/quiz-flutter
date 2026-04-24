import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class BookDetailProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  Book? _book;
  List<Collection> _collections = [];
  Map<int, bool> _expandedCollections = {};
  Map<int, int> _collectionQuestionCounts = {};
  Map<int, int> _collectionAnsweredCounts = {};
  Map<int, int> _smartCollectionCounts = {};
  SrsStats? _srsStats;
  bool _isLoading = false;
  String? _error;

  Book? get book => _book;
  List<Collection> get collections => List.unmodifiable(_collections);
  SrsStats? get srsStats => _srsStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Collection> get sourceCollections {
    return _collections.where((c) => c.isSource).toList();
  }

  List<Collection> get smartCollections {
    return _collections.where((c) => c.isSmart).toList();
  }

  List<Collection> get topicCollections {
    return _collections.where((c) => c.type == CollectionType.topic).toList();
  }

  List<Collection> get userCollections {
    return _collections.where((c) =>
        c.type == CollectionType.practiceSet ||
        c.type == CollectionType.playlist,
    ).toList();
  }

  List<Collection> get blueprintCollections {
    return _collections.where((c) => c.type == CollectionType.examBlueprint).toList();
  }

  List<Collection> get topLevelCollections {
    return _collections.where((c) => c.isSource && c.parentId == null).toList();
  }

  List<Collection> getChildren(int parentId) {
    return _collections.where((c) => c.parentId == parentId).toList();
  }

  int getQuestionCount(int collectionId) {
    return _collectionQuestionCounts[collectionId] ?? 0;
  }

  int getAnsweredCount(int collectionId) {
    return _collectionAnsweredCounts[collectionId] ?? 0;
  }

  int getSmartCollectionCount(int collectionId) {
    return _smartCollectionCounts[collectionId] ?? 0;
  }

  bool isExpanded(int collectionId) {
    return _expandedCollections[collectionId] ?? false;
  }

  Future<void> loadBook(Book book) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _book = book;
      await _db.ensureBuiltinSmartCollections(book.id);
      await _db.generateTopicCollections(book.id);
      _collections = await _db.getCollections(book.id);
      _expandedCollections = {
        for (final c in _collections.where((c) => c.isSource)) c.id: false,
      };
      _srsStats = await _db.getSrsStats(book.id);
      _collectionQuestionCounts = await _db.getCollectionQuestionCounts(book.id);
      _collectionAnsweredCounts =
          await _db.getCollectionAnsweredCounts(book.id);

      final engine = SmartCollectionEngine(db: _db);
      _smartCollectionCounts = {};
      for (final c in _collections.where((c) => c.isSmart)) {
        final count = (await engine.evaluate(book.id, c.config)).length;
        _smartCollectionCounts[c.id] = count;
      }
    } catch (e) {
      _error = 'Failed to load book details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleExpand(int collectionId) {
    _expandedCollections[collectionId] =
        !(_expandedCollections[collectionId] ?? false);
    notifyListeners();
  }

  Future<void> refreshCollections() async {
    if (_book == null) return;
    _collections = await _db.getCollections(_book!.id);

    final engine = SmartCollectionEngine(db: _db);
    _smartCollectionCounts = {};
    for (final c in _collections.where((c) => c.isSmart)) {
      final count = (await engine.evaluate(_book!.id, c.config)).length;
      _smartCollectionCounts[c.id] = count;
    }

    notifyListeners();
  }

  Future<void> deleteCollection(int collectionId) async {
    await _db.deleteCollection(collectionId);
    _collections.removeWhere((c) => c.id == collectionId);
    notifyListeners();
  }

  void clear() {
    _book = null;
    _collections = [];
    _expandedCollections = {};
    _collectionQuestionCounts = {};
    _collectionAnsweredCounts = {};
    _smartCollectionCounts = {};
    _srsStats = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
