import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/models/question.dart';

void main() {
  final outputDir = Directory('output');

  group('Package Format Tests', () {
    test('output directory exists', () {
      expect(outputDir.existsSync(), isTrue, reason: 'output directory should exist');
    });

    test('packages have valid zip format', () {
      final zipFiles = outputDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      expect(zipFiles.isNotEmpty, isTrue, reason: 'Should have at least one zip package');

      for (final zipFile in zipFiles) {
        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        expect(archive.files.isNotEmpty, isTrue,
            reason: '${zipFile.path} should contain files');
      }
    });

    test('each package contains valid JSON structure', () {
      final zipFiles = outputDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      for (final zipFile in zipFiles) {
        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        // Find the JSON file
        final jsonFile = archive.files.firstWhere(
          (f) => f.name.endsWith('.json'),
          orElse: () => throw Exception('No JSON file found in ${zipFile.path}'),
        );

        final jsonContent = utf8.decode(jsonFile.content as List<int>);
        final data = jsonDecode(jsonContent) as Map<String, dynamic>;

        // Validate required fields
        expect(data.containsKey('subject_name_zh'), isTrue,
            reason: '${zipFile.path} should have subject_name_zh');
        expect(data.containsKey('subject_name_en'), isTrue,
            reason: '${zipFile.path} should have subject_name_en');
        expect(data.containsKey('chapters'), isTrue,
            reason: '${zipFile.path} should have chapters');
        expect(data['chapters'], isList,
            reason: '${zipFile.path} chapters should be a list');
      }
    });

    test('all packages have valid question structure', () {
      final zipFiles = outputDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      for (final zipFile in zipFiles) {
        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        final jsonFile = archive.files.firstWhere(
          (f) => f.name.endsWith('.json'),
        );

        final jsonContent = utf8.decode(jsonFile.content as List<int>);
        final data = jsonDecode(jsonContent) as Map<String, dynamic>;

        final chapters = data['chapters'] as List;
        int totalQuestions = 0;
        int passageQuestions = 0; // Questions without choices (reading passages)

        for (final chapter in chapters) {
          expect(chapter, isA<Map<String, dynamic>>());
          expect(chapter['title'], isNotNull,
              reason: 'Chapter should have a title');

          final sections = chapter['sections'] as List?;
          if (sections != null) {
            for (final section in sections) {
              expect(section, isA<Map<String, dynamic>>());
              expect(section['title'], isNotNull,
                  reason: 'Section should have a title');

              final questions = section['questions'] as List?;
              if (questions != null) {
                for (final question in questions) {
                  totalQuestions++;
                  expect(question['content'], isNotNull,
                      reason: 'Question should have content');

                  final choices = question['choices'] as List?;

                  // Allow questions without choices (reading passages, fill-in-the-blank, etc.)
                  if (choices == null || choices.isEmpty) {
                    passageQuestions++;
                    continue;
                  }

                  // Regular multiple-choice question
                  expect(question['answer'], isNotNull,
                      reason: 'Multiple-choice question should have answer');

                  for (final choice in choices) {
                    expect(choice['key'], isNotNull,
                        reason: 'Choice should have key');
                    // Check for text field - this is what the packages actually use
                    expect(choice['text'] ?? choice['html'] ?? choice['content'], isNotNull,
                        reason: 'Choice should have text/html/content');
                  }
                }
              }
            }
          }
        }

        print('${zipFile.path}: $totalQuestions questions ($passageQuestions passages)');
        expect(totalQuestions, greaterThan(0),
            reason: '${zipFile.path} should have at least one question');
      }
    });
  });

  group('QuestionChoice.fromJson Tests', () {
    test('parses standard format with html field', () {
      final choice = QuestionChoice.fromJson({
        'key': 'A',
        'html': 'Answer with <b>HTML</b>',
      });

      expect(choice.key, equals('A'));
      expect(choice.html, equals('Answer with <b>HTML</b>'));
    });

    test('parses standard format with content field', () {
      final choice = QuestionChoice.fromJson({
        'key': 'B',
        'content': 'Answer content',
      });

      expect(choice.key, equals('B'));
      expect(choice.html, equals('Answer content'));
    });

    test('parses format with text field (used by packages)', () {
      final choice = QuestionChoice.fromJson({
        'key': 'C',
        'text': 'specified by international authorities',
      });

      expect(choice.key, equals('C'));
      // This test will FAIL with current implementation
      // because QuestionChoice.fromJson doesn't handle 'text' field
      expect(choice.html, equals('specified by international authorities'),
          reason: 'QuestionChoice should parse text field');
    });

    test('parses single entry map format', () {
      final choice = QuestionChoice.fromJson({
        'D': 'Single entry choice',
      });

      expect(choice.key, equals('D'));
      expect(choice.html, equals('Single entry choice'));
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
      // This will FAIL with current implementation
      expect(question.choices[0].html, equals('Option A'),
          reason: 'Choice html should be populated from text field');
    });
  });
}
