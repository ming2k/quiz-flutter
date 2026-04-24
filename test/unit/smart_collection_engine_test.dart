import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mnema/models/models.dart';
import 'package:mnema/services/services.dart';

import '../helpers/test_database.dart';

/// Unit tests for SmartCollectionEngine using an in-memory SQLite database.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initTestDatabase);

  group('SmartCollectionEngine.evaluate', () {
    late DatabaseService db;
    late SmartCollectionEngine engine;
    late int bookId;

    setUpAll(() async {
      db = DatabaseService();
      engine = SmartCollectionEngine(db: db);

      // Import the minimal fixture package once for the whole group
      final fixture = File('test/fixtures/minimal_package.json');
      final data = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
      await db.importData(data, 'fixture_test');

      final books = await db.getBooks();
      bookId = books.first.id;
    });

    tearDownAll(() async {
      await db.close();
      final dbFile = File(join(Directory.systemTemp.path, 'quiz.db'));
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
    });

    test('null config returns empty list', () async {
      final result = await engine.evaluate(bookId, null);
      expect(result, isEmpty);
    });

    test('empty config returns empty list', () async {
      final result = await engine.evaluate(bookId, '');
      expect(result, isEmpty);
    });

    test('no filters returns all answerable question IDs', () async {
      final result = await engine.evaluate(bookId, '{}');
      // Fixture has 8 answerable questions (all except passage parent)
      expect(result.length, 8);
    });

    test('unanswered filter returns questions with no recorded answers', () async {
      final result = await engine.evaluate(
        bookId,
        jsonEncode({'filters': [{'type': 'unanswered'}]}),
      );
      // All 8 are unanswered since we have not recorded any answers
      expect(result.length, 8);
    });

    test('tag filter returns matching questions', () async {
      final result = await engine.evaluate(
        bookId,
        jsonEncode({'filters': [{'type': 'tag', 'tag': 'math'}]}),
      );
      // Only question 2 has 'math' tag in fixture
      expect(result.length, 1);
    });

    test('tag filter returns empty when no match', () async {
      final result = await engine.evaluate(
        bookId,
        jsonEncode({'filters': [{'type': 'tag', 'tag': 'nonexistent'}]}),
      );
      expect(result, isEmpty);
    });

    test('wrong filter returns empty when no wrong answers', () async {
      final result = await engine.evaluate(
        bookId,
        jsonEncode({'filters': [{'type': 'wrong'}]}),
      );
      expect(result, isEmpty);
    });

    test('srs_due filter returns empty when no SRS data', () async {
      final result = await engine.evaluate(
        bookId,
        jsonEncode({'filters': [{'type': 'srs_due'}]}),
      );
      expect(result, isEmpty);
    });

    test('limit restricts result count', () async {
      final result = await engine.evaluate(
        bookId,
        jsonEncode({'limit': 3}),
      );
      expect(result.length, 3);
    });

    test('limit does not expand below available', () async {
      final result = await engine.evaluate(
        bookId,
        jsonEncode({'limit': 100}),
      );
      expect(result.length, 8);
    });

    test('combining tag + unanswered filters with AND logic', () async {
      final result = await engine.evaluate(
        bookId,
        jsonEncode({
          'filters': [
            {'type': 'tag', 'tag': 'science'},
            {'type': 'unanswered'},
          ],
        }),
      );
      // science tag: q3(true_false) + q4(fill_blank) = 2 answerable; q7(passage) is not answerable
      expect(result.length, 2);
    });
  });

  group('SmartCollectionEngine.evaluateBlueprint', () {
    late DatabaseService db;
    late SmartCollectionEngine engine;
    late int bookId;

    setUpAll(() async {
      db = DatabaseService();
      engine = SmartCollectionEngine(db: db);

      final fixture = File('test/fixtures/minimal_package.json');
      final data = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
      await db.importData(data, 'blueprint_test');

      final books = await db.getBooks();
      bookId = books.first.id;

      // Create a user collection and add some questions to it
      final collectionId = await db.createUserCollection(
        bookId: bookId,
        name: 'Test Set',
        type: CollectionType.practiceSet,
      );

      // Add first 3 answerable questions from the book
      final questions = await db.getQuestions(bookId);
      var added = 0;
      for (final q in questions) {
        if (q.isAnswerable && added < 3) {
          await db.addQuestionToCollection(collectionId, q.id);
          added++;
        }
      }
    });

    tearDownAll(() async {
      await db.close();
      final dbFile = File(join(Directory.systemTemp.path, 'quiz.db'));
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
    });

    test('single section blueprint samples from collection', () async {
      // Get the user collection ID (first non-source collection)
      final collections = await db.getCollectionsByType(bookId, CollectionType.practiceSet);
      expect(collections, isNotEmpty);
      final collectionId = collections.first.id;

      final config = jsonEncode({
        'sections': [
          {'collectionId': collectionId, 'count': 2},
        ],
      });

      final result = await engine.evaluate(bookId, config);
      expect(result.length, 2);
    });

    test('blueprint count capped by available questions', () async {
      final collections = await db.getCollectionsByType(bookId, CollectionType.practiceSet);
      final collectionId = collections.first.id;

      final config = jsonEncode({
        'sections': [
          {'collectionId': collectionId, 'count': 100},
        ],
      });

      final result = await engine.evaluate(bookId, config);
      // Only 3 questions were added to the collection
      expect(result.length, 3);
    });

    test('empty blueprint returns empty list', () async {
      final result = await engine.evaluate(bookId, '{"sections":[]}');
      expect(result, isEmpty);
    });
  });
}
