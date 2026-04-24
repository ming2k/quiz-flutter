import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnema/models/models.dart';
import 'package:mnema/services/services.dart';

/// Unit tests for package parsing and validation logic.
/// These tests use hard-coded fixture data and do NOT require
/// the large output/ packages. They run on every CI build.

void main() {
  group('QuestionChoice.fromJson', () {
    test('parses standard format with html field', () {
      final choice = QuestionChoice.fromJson({
        'key': 'A',
        'html': 'Answer with <b>HTML</b>',
      });
      expect(choice.key, equals('A'));
      expect(choice.content, equals('Answer with <b>HTML</b>'));
    });

    test('parses standard format with content field', () {
      final choice = QuestionChoice.fromJson({
        'key': 'B',
        'content': 'Answer content',
      });
      expect(choice.key, equals('B'));
      expect(choice.content, equals('Answer content'));
    });

    test('parses format with text field (used by packages)', () {
      final choice = QuestionChoice.fromJson({
        'key': 'C',
        'text': 'specified by international authorities',
      });
      expect(choice.key, equals('C'));
      expect(
        choice.content,
        equals('specified by international authorities'),
        reason: 'QuestionChoice should parse text field',
      );
    });

    test('parses single entry map format', () {
      final choice = QuestionChoice.fromJson({'D': 'Single entry choice'});
      expect(choice.key, equals('D'));
      expect(choice.content, equals('Single entry choice'));
    });
  });

  group('Question.fromMap with package choices format', () {
    test('parses choices with text field', () {
      final questionMap = {
        'id': 1,
        'book_id': 1,
        'section_id': 'section_1',
        'content': 'Test question?',
        'choices': jsonEncode([
          {'key': 'A', 'text': 'Option A'},
          {'key': 'B', 'text': 'Option B'},
          {'key': 'C', 'text': 'Option C'},
          {'key': 'D', 'text': 'Option D'},
        ]),
        'answer': 'A',
        'explanation': 'Test explanation',
      };

      final question = Question.fromMap(questionMap);

      expect(question.choices.length, equals(4));
      expect(question.choices[0].key, equals('A'));
      expect(
        question.choices[0].content,
        equals('Option A'),
        reason: 'Choice content should be populated from text field',
      );
    });

    test('parses protocol v2 type and flashcard templates', () {
      final questionMap = {
        'id': 2,
        'book_id': 1,
        'section_id': 'section_1',
        'content': 'Front',
        'choices': '[]',
        'answer': 'Back',
        'explanation': 'Details',
        'question_type': 'flashcard',
        'front_template': 'Custom front',
        'back_template': 'Custom back',
      };

      final question = Question.fromMap(questionMap);

      expect(question.questionType, QuestionType.flashcard);
      expect(question.isAnswerable, isTrue);
      expect(question.isChoiceBased, isFalse);
      expect(question.needsAnswerReveal, isTrue);
      expect(question.displayFront, 'Custom front');
      expect(question.displayBack, 'Custom back');
    });

    test('recognizes passage rows as non-study containers', () {
      final questionMap = {
        'id': 3,
        'book_id': 1,
        'section_id': 'section_1',
        'content': 'Shared passage',
        'choices': '[]',
        'answer': '',
        'explanation': '',
        'question_type': 'passage',
      };

      final question = Question.fromMap(questionMap);

      expect(question.questionType, QuestionType.passage);
      expect(question.isPassage, isTrue);
      expect(question.isAnswerable, isFalse);
      expect(question.isChoiceBased, isFalse);
    });
  });

  group('Package validation for question types', () {
    Map<String, dynamic> _packageWithQuestion(Map<String, dynamic> question) => {
      'subject_name_zh': 'Sample',
      'subject_name_en': 'sample',
      'chapters': [
        {
          'title': 'Chapter',
          'sections': [
            {
              'title': 'Section',
              'questions': [question],
            },
          ],
        },
      ],
    };

    test('accepts passage parent with answerable child', () {
      final errors = DatabaseService().validatePackageData(
        _packageWithQuestion({
          'question_type': 'passage',
          'content': 'Shared passage',
          'questions': [
            {
              'question_type': 'multiple_choice',
              'content': 'Child question',
              'choices': [
                {'key': 'A', 'content': 'First'},
                {'key': 'B', 'content': 'Second'},
              ],
              'answer': 'A',
            },
          ],
        }),
      );

      expect(errors, isEmpty);
    });

    test('rejects unsupported question type', () {
      final errors = DatabaseService().validatePackageData(
        _packageWithQuestion({
          'question_type': 'essay',
          'content': 'Explain this topic.',
          'answer': 'Expected answer',
        }),
      );

      expect(errors.single, contains('Unsupported question_type'));
    });

    test('rejects multiple-choice without answer', () {
      final errors = DatabaseService().validatePackageData(
        _packageWithQuestion({
          'question_type': 'multiple_choice',
          'content': 'Q?',
          'choices': [
            {'key': 'A', 'content': 'First'},
          ],
        }),
      );

      expect(errors, isNotEmpty);
    });
  });

  group('Minimal fixture package round-trip', () {
    late Map<String, dynamic> fixture;

    setUpAll(() {
      final file = File('test/fixtures/minimal_package.json');
      expect(file.existsSync(), isTrue, reason: 'fixture should exist');
      fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('has required top-level fields', () {
      expect(fixture['subject_name_zh'], isNotNull);
      expect(fixture['subject_name_en'], isNotNull);
      expect(fixture['chapters'], isA<List>());
    });

    test('covers every known question type', () {
      final typesFound = <String>{};
      final chapters = fixture['chapters'] as List;
      for (final chapter in chapters) {
        final sections = chapter['sections'] as List;
        for (final section in sections) {
          final questions = section['questions'] as List;
          for (final q in questions) {
            typesFound.add(q['question_type'] ?? 'multiple_choice');
            final children = q['questions'] as List?;
            if (children != null) {
              for (final child in children) {
                typesFound.add(child['question_type'] ?? 'multiple_choice');
              }
            }
          }
        }
      }

      expect(typesFound, contains('multiple_choice'));
      expect(typesFound, contains('true_false'));
      expect(typesFound, contains('fill_blank'));
      expect(typesFound, contains('cloze'));
      expect(typesFound, contains('flashcard'));
      expect(typesFound, contains('passage'));
    });

    test('passes DatabaseService validation', () {
      final errors = DatabaseService().validatePackageData(fixture);
      expect(errors, isEmpty, reason: 'fixture should be valid: $errors');
    });
  });
}
