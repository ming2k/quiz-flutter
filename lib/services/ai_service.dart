import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiProvider { gemini, claude, vertex }

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  String? _apiKey;
  String? _baseUrl;
  AiProvider _provider = AiProvider.gemini;
  String _model = 'gemini-2.0-flash';
  String _systemPrompt = '你是一名海航专业且母语为中文的学霸，精通海航英语、航海学（气象学、航海仪器）、船舶结构与货运、船舶操纵与避碰、船舶管理等知识。熟读 UK Hydrographic Office 的 ADMIRALTY 出版物和海图，掌握 COLREG 规范、STCW 公约、SOLAS 等。你的任务是帮助我快速学习相关知识，回答内容精炼易懂，最后总结关键内容方便记忆。';

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

  Stream<String> explain({
    required String questionStem,
    required Map<String, String> options,
    required String correctAnswer,
    String? userQuestion,
  }) async* {
    if (!isConfigured) {
      throw Exception('AI service not configured. Please set API key.');
    }

    final prompt = _buildPrompt(
      questionStem: questionStem,
      options: options,
      correctAnswer: correctAnswer,
      userQuestion: userQuestion,
    );

    Stream<String> stream;
    switch (_provider) {
      case AiProvider.gemini:
        stream = _callGeminiStream(prompt);
        break;
      case AiProvider.claude:
        stream = _callClaudeStream(prompt);
        break;
      case AiProvider.vertex:
        stream = _callVertexStream(prompt);
        break;
    }

    yield* stream;
  }

  Stream<String> _callGeminiStream(String prompt) async* {
    final host = (_baseUrl != null && _baseUrl!.isNotEmpty)
        ? _baseUrl!
        : 'https://generativelanguage.googleapis.com';
    final cleanHost = host.endsWith('/') ? host.substring(0, host.length - 1) : host;

    final url = Uri.parse(
      '$cleanHost/v1beta/models/$_model:streamGenerateContent?alt=sse',
    );

    final client = http.Client();
    http.StreamedResponse response;

    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['x-goog-api-key'] = _apiKey!
        ..body = jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': _systemPrompt}
            ]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
          }
        });

      // Connection timeout logic manually implemented since http.send doesn't have it directly
      // However, we can use a Future with timeout for the connection part.
      response = await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
         final body = await response.stream.bytesToString();
         throw Exception('Gemini API error: ${response.statusCode} - $body');
      }

      await for (final line in response.stream
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
              final text = data['candidates'][0]['content']['parts'][0]['text'] as String?;
              if (text != null) yield text;
            }
          } catch (e) {
            // Ignore parse errors for partial chunks or malformed lines
          }
        }
      }
    } on TimeoutException {
      throw Exception('连接超时 (30s)，请检查网络');
    } catch (e) {
      throw Exception('AI Service Error: $e');
    } finally {
      client.close();
    }
  }

  Stream<String> _callClaudeStream(String prompt) async* {
    final host = (_baseUrl != null && _baseUrl!.isNotEmpty)
        ? _baseUrl!
        : 'https://api.anthropic.com';
    final cleanHost = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    final url = Uri.parse('$cleanHost/v1/messages');

    final client = http.Client();
    http.StreamedResponse response;

    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['x-api-key'] = _apiKey!
        ..headers['anthropic-version'] = '2023-06-01'
        ..body = jsonEncode({
          'model': _model.isEmpty ? 'claude-3-haiku-20240307' : _model,
          'max_tokens': 2048,
          'stream': true,
          'system': _systemPrompt,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        });

      response = await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Claude API error: ${response.statusCode} - $body');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr == '[DONE]') break;
          try {
            final data = jsonDecode(jsonStr);
            if (data['type'] == 'content_block_delta' && data['delta'] != null) {
               final text = data['delta']['text'] as String?;
               if (text != null) yield text;
            }
          } catch (_) {}
        }
      }
    } on TimeoutException {
      throw Exception('连接超时 (30s)，请检查网络');
    } catch (e) {
      throw Exception('AI Service Error: $e');
    } finally {
      client.close();
    }
  }

  Stream<String> _callVertexStream(String prompt) async* {
    throw UnimplementedError('Vertex AI streaming not implemented');
  }

  String _buildPrompt({
    required String questionStem,
    required Map<String, String> options,
    required String correctAnswer,
    String? userQuestion,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('题目：');
    buffer.writeln(_convertToMarkdown(questionStem));
    buffer.writeln();
    buffer.writeln('选项：');
    options.forEach((key, value) {
      buffer.writeln('$key. ${_convertToMarkdown(value)}');
    });
    buffer.writeln();
    buffer.writeln('正确答案：$correctAnswer');

    if (userQuestion != null && userQuestion.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('用户问题：$userQuestion');
    } else {
      buffer.writeln();
      buffer.writeln('请详细解析这道题，说明为什么答案是正确的。');
    }

    return buffer.toString();
  }

  String _convertToMarkdown(String html) {
    if (html.isEmpty) return '';

    // If it already looks like markdown (simple check), return as is
    if (html.contains('**') || html.contains('# ') || (html.contains('[') && html.contains(']'))) {
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