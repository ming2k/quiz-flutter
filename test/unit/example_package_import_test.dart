import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mnema/models/models.dart';
import 'package:mnema/services/services.dart';
import '../helpers/test_database.dart';

/// Verifies that the example package in examples/minimal-package/
/// can be parsed and imported by DatabaseService without errors.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initTestDatabase);

  group('Example minimal package', () {
    late DatabaseService db;

    setUp(() async {
      db = DatabaseService();
    });

    tearDown(() async {
      await db.close();
      final dbFile = File(
        join(Directory.systemTemp.path, 'quiz.db'),
      );
      if (dbFile.existsSync()) {
        await databaseFactory.deleteDatabase(dbFile.path);
      }
    });

    test('imports successfully and produces expected counts', () async {
      final fixture = File('examples/minimal-package/data.json');
      expect(fixture.existsSync(), isTrue, reason: 'Example package must exist');

      final data = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
      await db.importData(data, 'example_minimal');

      final books = await db.getBooks();
      expect(books.length, 1);

      final book = books.first;
      expect(book.subjectNameZh, '示例科目');
      expect(book.subjectNameEn, 'example-subject');
      expect(book.totalChapters, 2);
      expect(book.totalSections, 5);
      // 7 answerable: 2 MC + 1 TF + 1 fill_blank + 1 flashcard + 2 passage sub-Qs
      expect(book.totalQuestions, 7);

      final chapters = await db.getChapters(book.id);
      expect(chapters.length, 2);

      final sections = await db.getSections(book.id);
      expect(sections.length, 5);

      final questions = await db.getQuestions(book.id);
      expect(questions.length, 8); // includes passage parent

      final answerable = questions.where((q) => q.isAnswerable).toList();
      expect(answerable.length, 7);

      // Verify question types are preserved
      final types = questions.map((q) => q.questionType).toSet();
      expect(
        types,
        containsAll([
          QuestionType.multipleChoice,
          QuestionType.trueFalse,
          QuestionType.fillBlank,
          QuestionType.flashcard,
          QuestionType.passage,
        ]),
      );
    });

    test('passage parent is non-answerable and has sub-questions', () async {
      final fixture = File('examples/minimal-package/data.json');
      final data = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
      await db.importData(data, 'example_passage');

      final books = await db.getBooks();
      final questions = await db.getQuestions(books.first.id);

      final passage = questions.firstWhere((q) => q.questionType == QuestionType.passage);
      expect(passage.isAnswerable, isFalse);
      expect(passage.answer, isEmpty);

      final subs = questions.where((q) => q.parentId == passage.id).toList();
      expect(subs.length, 2);
      expect(subs.every((q) => q.isAnswerable), isTrue);
    });
  });
}
