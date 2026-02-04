import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/services/ai_service.dart';

void main() {
  group('AiService Integration Tests', () {
    test('explain returns stream of text with real API call', () async {
      // 1. Get API Key from Environment
      String? apiKey = Platform.environment['GEMINI_API_KEY'];
      
      // Fallback check for --dart-define if Platform.environment is empty
      if (apiKey == null || apiKey.isEmpty) {
         const envKey = String.fromEnvironment('GEMINI_API_KEY');
         if (envKey.isNotEmpty) {
           apiKey = envKey;
         }
      }

      if (apiKey == null || apiKey.isEmpty) {
        print('SKIPPING TEST: GEMINI_API_KEY not found in environment variables or --dart-define.');
        print('Usage: export GEMINI_API_KEY=your_key && flutter test test/ai_service_test.dart');
        // We mark the test as skipped or just return. 
        // In Dart test, marking as skipped programmatically inside test body isn't standard, 
        // so we just return with a printed message to avoid failure.
        return; 
      }

      print('Using API Key: ${apiKey.substring(0, 4)}****');

      // 2. Configure Service
      final service = AiService();
      service.configure(
        apiKey: apiKey,
        provider: AiProvider.gemini,
        model: 'gemini-2.0-flash',
      );

      // 3. Call API
      // Simple maritime question to verify system prompt alignment
      final stream = service.explain(
        questionStem: 'What is the primary purpose of the International Regulations for Preventing Collisions at Sea (COLREGs)?',
        options: {
          'A': 'To prevent collisions at sea',
          'B': 'To regulate marine insurance',
          'C': 'To determine port tariffs',
          'D': 'To standardize ship construction'
        },
        correctAnswer: 'A',
      );

      // 4. Verify Response
      final buffer = StringBuffer();
      await for (final chunk in stream) {
        buffer.write(chunk);
      }
      
      final fullResponse = buffer.toString();
      print('''
--- API Response ---
$fullResponse
--------------------''');
      
      expect(fullResponse, isNotEmpty);
      expect(fullResponse.toLowerCase(), contains('collision'));
      // Check if it follows markdown instructions (bolding)
      expect(fullResponse.contains('**'), isTrue, reason: 'Response should contain markdown bolding');
    });
  });
}
