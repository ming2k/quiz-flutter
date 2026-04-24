import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class LibraryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();
  final PackageService _packageService = PackageService();

  List<Book> _books = [];
  Book? _currentBook;
  bool _isLoading = false;
  String? _error;

  List<Book> get books => List.unmodifiable(_books);
  Book? get currentBook => _currentBook;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _db.getBooks();

      final bool isSampleInitialized =
          await _storage.loadSetting<bool>(
            'is_sample_package_initialized',
            defaultValue: false,
          ) ??
          false;

      if (_books.isEmpty && !isSampleInitialized) {
        final result = await _packageService.importBuiltInPackage(
          'assets/packages/sample-package.zip',
        );
        if (!result.success && result.errorMessage != null) {
          _error = result.errorMessage;
        } else {
          await _storage.saveSetting('is_sample_package_initialized', true);
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

  Future<void> reorderBooks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _books.removeAt(oldIndex);
    _books.insert(newIndex, item);
    notifyListeners();

    final ids = _books.map((b) => b.id).toList();
    try {
      await _db.updateBookOrder(ids);
    } catch (_) {}
  }

  Future<void> deleteBook(int bookId) async {
    try {
      await _db.deleteBook(bookId);
      _books.removeWhere((b) => b.id == bookId);
      if (_currentBook?.id == bookId) {
        _currentBook = null;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete book: $e';
      notifyListeners();
    }
  }

  void selectBook(Book book) {
    _currentBook = book;
    notifyListeners();
  }

  Book? findBookByFilename(String filename) {
    try {
      return _books.firstWhere((b) => b.filename == filename);
    } catch (_) {
      return null;
    }
  }

  Future<void> importBuiltInPackage(String assetPath) async {
    final result = await _packageService.importBuiltInPackage(assetPath);
    if (result.success) {
      await loadBooks();
    }
  }
}
