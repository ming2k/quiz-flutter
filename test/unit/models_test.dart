import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnema/models/models.dart';

void main() {
  group('QuestionType', () {
    test('fromProtocol parses all known types', () {
      expect(QuestionType.fromProtocol('multiple_choice'), QuestionType.multipleChoice);
      expect(QuestionType.fromProtocol('true_false'), QuestionType.trueFalse);
      expect(QuestionType.fromProtocol('fill_blank'), QuestionType.fillBlank);
      expect(QuestionType.fromProtocol('cloze'), QuestionType.cloze);
      expect(QuestionType.fromProtocol('flashcard'), QuestionType.flashcard);
      expect(QuestionType.fromProtocol('passage'), QuestionType.passage);
    });

    test('fromProtocol defaults to multipleChoice for null', () {
      expect(QuestionType.fromProtocol(null), QuestionType.multipleChoice);
      expect(QuestionType.fromProtocol(''), QuestionType.multipleChoice);
    });

    test('fromProtocol returns unknown for unrecognised', () {
      expect(QuestionType.fromProtocol('essay'), QuestionType.unknown);
    });

    test('protocolValue round-trip', () {
      for (final type in QuestionType.values) {
        expect(QuestionType.fromProtocol(type.protocolValue), type);
      }
    });
  });

  group('QuestionChoice', () {
    test('parses standard key+text format', () {
      final c = QuestionChoice.fromJson({'key': 'A', 'text': 'Option A'});
      expect(c.key, 'A');
      expect(c.content, 'Option A');
    });

    test('parses key+html format', () {
      final c = QuestionChoice.fromJson({'key': 'B', 'html': '<b>Bold</b>'});
      expect(c.content, '<b>Bold</b>');
    });

    test('parses key+content format', () {
      final c = QuestionChoice.fromJson({'key': 'C', 'content': 'Plain'});
      expect(c.content, 'Plain');
    });

    test('parses single-entry map format', () {
      final c = QuestionChoice.fromJson({'D': 'Single'});
      expect(c.key, 'D');
      expect(c.content, 'Single');
    });

    test('prefers content over html over text', () {
      final c = QuestionChoice.fromJson({
        'key': 'A',
        'text': 'text',
        'html': 'html',
        'content': 'content',
      });
      expect(c.content, 'content');
    });
  });

  group('Question', () {
    test('default type is multipleChoice when question_type is null', () {
      final q = Question.fromMap({
        'id': 1,
        'book_id': 1,
        'section_id': 's1',
        'content': 'Q?',
        'choices': '[]',
        'answer': 'A',
        'explanation': '',
      });
      expect(q.questionType, QuestionType.multipleChoice);
    });

    test('flashcard type sets isChoiceBased to false', () {
      final q = Question.fromMap({
        'id': 2,
        'book_id': 1,
        'section_id': 's1',
        'content': 'Front',
        'choices': '[]',
        'answer': 'Back',
        'explanation': 'Details',
        'question_type': 'flashcard',
        'front_template': 'Custom front',
        'back_template': 'Custom back',
      });
      expect(q.questionType, QuestionType.flashcard);
      expect(q.isAnswerable, isTrue);
      expect(q.isChoiceBased, isFalse);
      expect(q.needsAnswerReveal, isTrue);
      expect(q.displayFront, 'Custom front');
      expect(q.displayBack, 'Custom back');
    });

    test('passage type is non-answerable container', () {
      final q = Question.fromMap({
        'id': 3,
        'book_id': 1,
        'section_id': 's1',
        'content': 'Shared passage',
        'choices': '[]',
        'answer': '',
        'explanation': '',
        'question_type': 'passage',
      });
      expect(q.questionType, QuestionType.passage);
      expect(q.isPassage, isTrue);
      expect(q.isAnswerable, isFalse);
      expect(q.isChoiceBased, isFalse);
    });

    test('true_false type recognised', () {
      final q = Question.fromMap({
        'id': 4,
        'book_id': 1,
        'section_id': 's1',
        'content': 'True or false?',
        'choices': jsonEncode([
          {'key': 'A', 'text': 'True'},
          {'key': 'B', 'text': 'False'},
        ]),
        'answer': 'A',
        'explanation': '',
        'question_type': 'true_false',
      });
      expect(q.questionType, QuestionType.trueFalse);
      expect(q.isChoiceBased, isTrue);
    });

    test('fill_blank type recognised', () {
      final q = Question.fromMap({
        'id': 5,
        'book_id': 1,
        'section_id': 's1',
        'content': 'Fill ___ blank.',
        'choices': '[]',
        'answer': 'the',
        'explanation': '',
        'question_type': 'fill_blank',
      });
      expect(q.questionType, QuestionType.fillBlank);
      expect(q.isChoiceBased, isFalse);
    });

    test('cloze type recognised', () {
      final q = Question.fromMap({
        'id': 6,
        'book_id': 1,
        'section_id': 's1',
        'content': 'The {{c1::answer}} is here.',
        'choices': '[]',
        'answer': 'answer',
        'explanation': '',
        'question_type': 'cloze',
      });
      expect(q.questionType, QuestionType.cloze);
      expect(q.isChoiceBased, isFalse);
    });

    test('ignores plain comma-separated string for tags', () {
      final q = Question.fromMap({
        'id': 7,
        'book_id': 1,
        'section_id': 's1',
        'content': 'Q',
        'choices': '[]',
        'answer': 'A',
        'explanation': '',
        'tags': 'math,algebra',
      });
      // Current implementation only supports JSON-encoded arrays
      expect(q.tags, isEmpty);
    });

    test('parses tags from JSON array string', () {
      final q = Question.fromMap({
        'id': 8,
        'book_id': 1,
        'section_id': 's1',
        'content': 'Q',
        'choices': '[]',
        'answer': 'A',
        'explanation': '',
        'tags': jsonEncode(['science', 'physics']),
      });
      expect(q.tags, ['science', 'physics']);
    });
  });

  group('Collection', () {
    test('fromMap parses all fields', () {
      final c = Collection.fromMap({
        'id': 10,
        'book_id': 1,
        'type': 'smart',
        'name': 'Due Today',
        'description': 'SRS due cards',
        'config': '{"filter":"due"}',
        'sort_order': 5,
        'created_at': 1700000000,
        'updated_at': 1700000100,
        'parent_id': 2,
      });
      expect(c.id, 10);
      expect(c.bookId, 1);
      expect(c.type, CollectionType.smart);
      expect(c.name, 'Due Today');
      expect(c.description, 'SRS due cards');
      expect(c.config, '{"filter":"due"}');
      expect(c.sortOrder, 5);
      expect(c.createdAt, 1700000000);
      expect(c.updatedAt, 1700000100);
      expect(c.parentId, 2);
    });

    test('fromMap defaults missing fields safely', () {
      final c = Collection.fromMap({
        'id': 1,
        'book_id': 1,
        'type': 'topic',
        'name': 'Topic A',
        'created_at': 0,
      });
      expect(c.description, isNull);
      expect(c.config, isNull);
      expect(c.sortOrder, 0);
      expect(c.updatedAt, isNull);
      expect(c.parentId, isNull);
    });

    test('toMap round-trip', () {
      final original = Collection.fromMap({
        'id': 1,
        'book_id': 1,
        'type': 'practiceSet',
        'name': 'My Set',
        'created_at': 1000,
      });
      final map = original.toMap();
      final restored = Collection.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.name, original.name);
    });

    test('isSource / isSmart / isBlueprint helpers', () {
      final source = Collection.fromMap({'id': 1, 'book_id': 1, 'type': 'source', 'name': 'S', 'created_at': 0});
      final smart = Collection.fromMap({'id': 2, 'book_id': 1, 'type': 'smart', 'name': 'S', 'created_at': 0});
      final blueprint = Collection.fromMap({'id': 3, 'book_id': 1, 'type': 'examBlueprint', 'name': 'B', 'created_at': 0});

      expect(source.isSource, isTrue);
      expect(source.isSmart, isFalse);
      expect(smart.isSmart, isTrue);
      expect(blueprint.isBlueprint, isTrue);
    });
  });

  group('SrsState', () {
    test('default values for new card', () {
      const state = SrsState(questionId: 1, bookId: 1);
      expect(state.repetitions, 0);
      expect(state.intervalDays, 0);
      expect(state.easeFactor, 2.5);
      expect(state.lapses, 0);
      expect(state.reviewState, SrsReviewState.newCard);
      expect(state.isNew, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const state = SrsState(questionId: 1, bookId: 1);
      final copied = state.copyWith(repetitions: 3, intervalDays: 10);
      expect(copied.questionId, 1);
      expect(copied.repetitions, 3);
      expect(copied.intervalDays, 10);
      expect(copied.easeFactor, 2.5); // unchanged
    });
  });
}
