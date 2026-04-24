import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

/// Callback for configuring AiService before use
typedef AiServiceConfigurator = void Function(AiService service);

enum AiProvider { gemini, vertex, kimi }

class _GeminiContextCacheEntry {
  final String name;
  final String fingerprint;

  const _GeminiContextCacheEntry({
    required this.name,
    required this.fingerprint,
  });
}

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  String? _apiKey;
  String? _baseUrl;
  AiProvider _provider = AiProvider.gemini;
  String _model = 'gemini-3.1-flash-lite-preview';
  String _systemPrompt =
      "You are a maritime education expert fluent in English. You specialize in maritime English, navigation (meteorology, navigational instruments), ship structure and cargo handling, ship maneuvering and collision avoidance, and ship management. You are familiar with UK Hydrographic Office ADMIRALTY publications, charts, COLREG, STCW, and SOLAS. Your task is to help me learn relevant knowledge efficiently. Keep answers concise, easy to understand, and summarize key points for memorization.";
  final Map<int, _GeminiContextCacheEntry> _geminiContextCache = {};

  void configure({
    String? apiKey,
    String? baseUrl,
    AiProvider? provider,
    String? model,
    String? systemPrompt,
  }) {
    if (apiKey != null) _apiKey = apiKey;
    if (baseUrl != null) _baseUrl = baseUrl;
    if (provider != null) _provider = provider;
    if (model != null) _model = model;
    if (systemPrompt != null) _systemPrompt = systemPrompt;
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  void clearSessionContext(int sessionId) {
    _geminiContextCache.remove(sessionId);
  }

  Stream<String> explain({
    required String questionStem,
    required Map<String, String> options,
    required String correctAnswer,
    String? userQuestion,
    List<ChatMessage> history = const [],
    int? sessionId,
  }) async* {
    if (!isConfigured) {
      throw Exception('AI service not configured. Please set API key.');
    }

    final questionContext = _buildQuestionContext(
      questionStem: questionStem,
      options: options,
      correctAnswer: correctAnswer,
    );
    final effectiveHistory = _buildEffectiveHistory(
      history: history,
      userQuestion: userQuestion,
    );

    Stream<String> stream;
    switch (_provider) {
      case AiProvider.gemini:
        stream = _callGeminiStream(
          questionContext: questionContext,
          history: effectiveHistory,
          sessionId: sessionId,
        );
        break;
      case AiProvider.vertex:
        stream = _callVertexStream(
          questionContext: questionContext,
          history: effectiveHistory,
        );
        break;
      case AiProvider.kimi:
        stream = _callKimiStream(
          questionContext: questionContext,
          history: effectiveHistory,
          sessionId: sessionId,
        );
        break;
    }

    yield* stream;
  }

  Stream<String> _callGeminiStream({
    required String questionContext,
    required List<ChatMessage> history,
    int? sessionId,
  }) async* {
    final host = (_baseUrl != null && _baseUrl!.isNotEmpty)
        ? _baseUrl!
        : 'https://generativelanguage.googleapis.com';
    final cleanHost = host.endsWith('/')
        ? host.substring(0, host.length - 1)
        : host;

    final url = Uri.parse(
      '$cleanHost/v1beta/models/$_model:streamGenerateContent?alt=sse',
    );

    final client = http.Client();
    http.StreamedResponse response;

    try {
      final cachedContentName = sessionId == null
          ? null
          : await _ensureGeminiCachedContext(
              sessionId: sessionId,
              questionContext: questionContext,
              host: cleanHost,
            );

      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['x-goog-api-key'] = _apiKey!
        ..body = jsonEncode({
          ...?cachedContentName == null
              ? null
              : {'cachedContent': cachedContentName},
          ...?cachedContentName != null
              ? null
              : {
                  'systemInstruction': {
                    'parts': [
                      {
                        'text': _buildInlineContextSystemPrompt(
                          questionContext,
                        ),
                      },
                    ],
                  },
                },
          'contents': _buildGeminiContents(history),
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
            // Gemini 3.x models have thinking enabled by default.
            // Use 'low' to reduce latency for quiz explanations.
            'thinkingConfig': {'thinkingLevel': 'low'},
          },
        });

      // Connection timeout logic manually implemented since http.send doesn't have it directly
      // However, we can use a Future with timeout for the connection part.
      response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        if (cachedContentName != null &&
            (body.contains('cachedContent') ||
                body.contains('cachedContents'))) {
          _geminiContextCache.remove(sessionId);
          yield* _callGeminiStream(
            questionContext: questionContext,
            history: history,
            sessionId: sessionId,
          );
          return;
        }
        throw Exception('Gemini API error: ${response.statusCode} - $body');
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final data = jsonDecode(jsonStr);
            if (data['candidates'] != null &&
                (data['candidates'] as List).isNotEmpty &&
                data['candidates'][0]['content'] != null) {
              final parts = data['candidates'][0]['content']['parts'] as List?;
              if (parts != null) {
                for (final part in parts) {
                  // Gemini 3.x returns thinking parts with thought: true.
                  // Skip those and only yield the actual answer text.
                  if (part['thought'] == true) continue;
                  final text = part['text'] as String?;
                  if (text != null) yield text;
                }
              }
            }
          } catch (e) {
            // Ignore parse errors for partial chunks or malformed lines
          }
        }
      }
    } on TimeoutException {
      throw Exception('Connection timed out (30s). Please check your network.');
    } catch (e) {
      throw Exception('AI Service Error: $e');
    } finally {
      client.close();
    }
  }

  Stream<String> _callKimiStream({
    required String questionContext,
    required List<ChatMessage> history,
    int? sessionId,
  }) async* {
    final host = (_baseUrl != null && _baseUrl!.isNotEmpty)
        ? _baseUrl!
        : 'https://api.moonshot.cn';
    final cleanHost = host.endsWith('/')
        ? host.substring(0, host.length - 1)
        : host;

    final url = Uri.parse('$cleanHost/v1/chat/completions');

    final client = http.Client();
    http.StreamedResponse response;

    try {
      final messages = <Map<String, dynamic>>[];

      // System message with system prompt and question context
      messages.add({
        'role': 'system',
        'content': _buildInlineContextSystemPrompt(questionContext),
      });

      // History messages
      for (final message in history) {
        messages.add({
          'role': message.isUser ? 'user' : 'assistant',
          'content': message.text,
        });
      }

      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..body = jsonEncode({
          'model': _model,
          'messages': messages,
          'stream': true,
          'temperature': 0.7,
          'max_tokens': 2048,
        });

      response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Kimi API error: ${response.statusCode} - $body');
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
          try {
            final data = jsonDecode(jsonStr);
            final choices = data['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              if (delta != null) {
                final content = delta['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              }
            }
          } catch (e) {
            // Ignore parse errors for partial chunks
          }
        }
      }
    } on TimeoutException {
      throw Exception('Connection timed out (30s). Please check your network.');
    } catch (e) {
      throw Exception('AI Service Error: $e');
    } finally {
      client.close();
    }
  }

  Stream<String> _callVertexStream({
    required String questionContext,
    required List<ChatMessage> history,
  }) async* {
    throw UnimplementedError('Vertex AI streaming not implemented');
  }

  Future<String?> _ensureGeminiCachedContext({
    required int sessionId,
    required String questionContext,
    required String host,
  }) async {
    final fingerprint = '$host\n$_model\n$_systemPrompt\n$questionContext';
    final cachedEntry = _geminiContextCache[sessionId];
    if (cachedEntry != null && cachedEntry.fingerprint == fingerprint) {
      return cachedEntry.name;
    }

    final url = Uri.parse('$host/v1beta/cachedContents');
    final client = http.Client();

    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['x-goog-api-key'] = _apiKey!
        ..body = jsonEncode({
          'model': 'models/$_model',
          'displayName': 'mnema-session-$sessionId',
          'systemInstruction': {
            'parts': [
              {'text': _systemPrompt},
            ],
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': questionContext},
              ],
            },
          ],
          'ttl': '3600s',
        });

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final body = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final name = data['name'] as String?;
      if (name == null || name.isEmpty) return null;

      _geminiContextCache[sessionId] = _GeminiContextCacheEntry(
        name: name,
        fingerprint: fingerprint,
      );
      return name;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  List<ChatMessage> _buildEffectiveHistory({
    required List<ChatMessage> history,
    String? userQuestion,
  }) {
    final effectiveHistory =
        history
            .where(_shouldIncludeHistoryMessage)
            .map(
              (message) => ChatMessage(
                text: message.text.trim(),
                isUser: message.isUser,
                timestamp: message.timestamp,
              ),
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (effectiveHistory.isNotEmpty) {
      return effectiveHistory;
    }

    final fallbackPrompt =
        (userQuestion != null && userQuestion.trim().isNotEmpty)
        ? userQuestion.trim()
        : 'Please analyze this question in detail and explain why the correct answer is right.';

    return [ChatMessage(text: fallbackPrompt, isUser: true)];
  }

  bool _shouldIncludeHistoryMessage(ChatMessage message) {
    final text = message.text.trim();
    if (text.isEmpty) return false;
    if (!message.isUser && text.startsWith('Error:')) return false;
    return true;
  }

  List<Map<String, dynamic>> _buildGeminiContents(List<ChatMessage> history) {
    return history
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'model',
            'parts': [
              {'text': message.text},
            ],
          },
        )
        .toList();
  }

  String _buildQuestionContext({
    required String questionStem,
    required Map<String, String> options,
    required String correctAnswer,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Question:');
    buffer.writeln(_convertToMarkdown(questionStem));
    buffer.writeln();
    buffer.writeln('Options:');
    options.forEach((key, value) {
      buffer.writeln('$key. ${_convertToMarkdown(value)}');
    });
    buffer.writeln();
    buffer.writeln('Correct answer: $correctAnswer');
    return buffer.toString();
  }

  String _buildInlineContextSystemPrompt(String questionContext) {
    return '$_systemPrompt\n\nThe following question context is fixed for this conversation. Always use it as reference:\n\n$questionContext';
  }

  String _convertToMarkdown(String html) {
    if (html.isEmpty) return '';

    // If it already looks like markdown (simple check), return as is
    if (html.contains('**') ||
        html.contains('# ') ||
        (html.contains('[') && html.contains(']'))) {
      return html;
    }

    // Basic HTML to Markdown conversion
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<div>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<strong>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'</strong>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'<b>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'</b>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'<em>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'</em>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'<i>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'</i>', caseSensitive: false), '*');

    // Remove all remaining tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");

    return text.trim();
  }
}
