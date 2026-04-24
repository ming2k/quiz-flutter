import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class PreviewProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Section> _sections = [];
  List<Question> _allItems = [];
  List<Question> _filteredItems = [];

  Book? _currentBook;
  Question? _currentItem;
  int _currentIndex = 0;
  String _currentPartitionId = 'all';
  String? _currentPackageImagePath;

  bool _isLoading = false;
  String? _error;

  Book? get currentBook => _currentBook;
  Question? get currentItem => _currentItem;
  int get currentIndex => _currentIndex;
  String get currentPartitionId => _currentPartitionId;
  String? get currentPackageImagePath => _currentPackageImagePath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Section> get sections => List.unmodifiable(_sections);
  List<Question> get items => List.unmodifiable(_filteredItems);
  int get totalItems => _filteredItems.length;

  List<Question> getSubQuestions(int parentId) {
    return _allItems.where((q) => q.parentId == parentId).toList();
  }

  Future<void> loadBook(Book book) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBook = book;
      _sections = await _db.getSections(book.id);
      _allItems = await _db.getQuestions(book.id);

      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
        _currentPackageImagePath = await PackageService().getPackageImagePath(
          book.filename,
        );
      } else {
        _currentPackageImagePath = null;
      }

      _filteredItems = List.from(_allItems);
      _currentPartitionId = 'all';
      _currentIndex = 0;
      if (_filteredItems.isNotEmpty) {
        _currentItem = _filteredItems[0];
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
      _allItems = await _db.getQuestionsByCollection(collectionId);

      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
        _currentPackageImagePath = await PackageService().getPackageImagePath(
          book.filename,
        );
      } else {
        _currentPackageImagePath = null;
      }

      _filteredItems = List.from(_allItems);
      _currentPartitionId = 'collection_$collectionId';
      _currentIndex = 0;
      if (_filteredItems.isNotEmpty) {
        _currentItem = _filteredItems[0];
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
      _allItems = await _db.getQuestionsByIds(ids);

      if (!book.filename.endsWith('.json') && !book.filename.endsWith('.db')) {
        _currentPackageImagePath = await PackageService().getPackageImagePath(
          book.filename,
        );
      } else {
        _currentPackageImagePath = null;
      }

      _filteredItems = List.from(_allItems);
      _currentPartitionId = 'smart_${collection.id}';
      _currentIndex = 0;
      if (_filteredItems.isNotEmpty) {
        _currentItem = _filteredItems[0];
      }
    } catch (e) {
      _error = 'Failed to load smart collection: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPartition(String partitionId) {
    _currentPartitionId = partitionId;
    if (partitionId == 'all') {
      _filteredItems = List.from(_allItems);
    } else {
      _filteredItems =
          _allItems.where((q) => q.sectionId == partitionId).toList();
    }
    _currentIndex = 0;
    if (_filteredItems.isNotEmpty) {
      _currentItem = _filteredItems[0];
    }
    notifyListeners();
  }

  void goToItem(int index) {
    if (index < 0 || index >= _filteredItems.length) return;
    _currentIndex = index;
    _currentItem = _filteredItems[_currentIndex];
    notifyListeners();
  }

  void nextItem() {
    if (_currentIndex < _filteredItems.length - 1) {
      goToItem(_currentIndex + 1);
    }
  }

  void previousItem() {
    if (_currentIndex > 0) {
      goToItem(_currentIndex - 1);
    }
  }
}
