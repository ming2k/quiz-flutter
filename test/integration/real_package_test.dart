@Tags(['integration'])
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests that validate the real packages in output/.
/// These are slow and file-dependent; they only run when
/// --dart-define=MNEMA_RUN_INTEGRATION=1 is set.
///
/// Run locally:
///   flutter test --dart-define=MNEMA_RUN_INTEGRATION=1 test/integration/

void main() {
  final outputDir = Directory('output');

  group('Real Package Format Tests', () {
    test('output directory exists', () {
      expect(
        outputDir.existsSync(),
        isTrue,
        reason: 'output directory should exist',
      );
    });

    test('packages have valid zip format', () {
      final zipFiles = outputDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      expect(
        zipFiles.isNotEmpty,
        isTrue,
        reason: 'Should have at least one zip package',
      );

      for (final zipFile in zipFiles) {
        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        expect(
          archive.files.isNotEmpty,
          isTrue,
          reason: '${zipFile.path} should contain files',
        );
      }
    });

    test('each package contains valid JSON structure', () {
      final zipFiles = outputDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      for (final zipFile in zipFiles) {
        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        final jsonFile = archive.files.firstWhere(
          (f) => f.name.endsWith('.json'),
          orElse: () =>
              throw Exception('No JSON file found in ${zipFile.path}'),
        );

        final jsonContent = utf8.decode(jsonFile.content as List<int>);
        final data = jsonDecode(jsonContent) as Map<String, dynamic>;

        expect(
          data.containsKey('subject_name_zh'),
          isTrue,
          reason: '${zipFile.path} should have subject_name_zh',
        );
        expect(
          data.containsKey('subject_name_en'),
          isTrue,
          reason: '${zipFile.path} should have subject_name_en',
        );
        expect(
          data.containsKey('chapters'),
          isTrue,
          reason: '${zipFile.path} should have chapters',
        );
        expect(
          data['chapters'],
          isList,
          reason: '${zipFile.path} chapters should be a list',
        );
      }
    });

    test('all packages have valid question structure', () {
      final zipFiles = outputDir
          .listSync()
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
        int passageQuestions = 0;

        for (final chapter in chapters) {
          expect(chapter, isA<Map<String, dynamic>>());
          expect(
            chapter['title'],
            isNotNull,
            reason: 'Chapter should have a title',
          );

          final sections = chapter['sections'] as List?;
          if (sections != null) {
            for (final section in sections) {
              expect(section, isA<Map<String, dynamic>>());
              expect(
                section['title'],
                isNotNull,
                reason: 'Section should have a title',
              );

              final questions = section['questions'] as List?;
              if (questions != null) {
                for (final question in questions) {
                  totalQuestions++;
                  expect(
                    question['content'],
                    isNotNull,
                    reason: 'Question should have content',
                  );

                  final choices = question['choices'] as List?;

                  if (choices == null || choices.isEmpty) {
                    passageQuestions++;
                    continue;
                  }

                  expect(
                    question['answer'],
                    isNotNull,
                    reason: 'Multiple-choice question should have answer',
                  );

                  for (final choice in choices) {
                    expect(
                      choice['key'],
                      isNotNull,
                      reason: 'Choice should have key',
                    );
                    expect(
                      choice['text'] ?? choice['html'] ?? choice['content'],
                      isNotNull,
                      reason: 'Choice should have text/html/content',
                    );
                  }
                }
              }
            }
          }
        }

        expect(
          totalQuestions,
          greaterThan(0),
          reason: '${zipFile.path} should have at least one question',
        );
      }
    });
  });
}
