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
  String _model = 'gemini-1.5-flash';
  String _systemPrompt = '你是一位专业的海事教育专家，擅长解释航海相关的考试题目。请用简洁明了的方式解释问题和答案。';

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

  Future<String> explain({
    required String questionStem,
    required Map<String, String> options,
    required String correctAnswer,
    String? userQuestion,
  }) async {
    if (!isConfigured) {
      throw Exception('AI service not configured. Please set API key.');
    }

    final prompt = _buildPrompt(
      questionStem: questionStem,
      options: options,
      correctAnswer: correctAnswer,
      userQuestion: userQuestion,
    );

    switch (_provider) {
      case AiProvider.gemini:
        return await _callGemini(prompt);
      case AiProvider.claude:
        return await _callClaude(prompt);
      case AiProvider.vertex:
        return await _callVertex(prompt);
    }
  }

  String _buildPrompt({
    required String questionStem,
    required Map<String, String> options,
    required String correctAnswer,
    String? userQuestion,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('题目：');
    buffer.writeln(_stripHtml(questionStem));
    buffer.writeln();
    buffer.writeln('选项：');
    options.forEach((key, value) {
      buffer.writeln('$key. ${_stripHtml(value)}');
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

  String _stripHtml(String html) {
    // Basic regex to strip HTML tags.
    // Replaces <br>, <p>, </div> with newlines to preserve some structure
    var text = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                   .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
                   .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    
    // Remove all other tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode basic entities (optional, but good for readability)
    text = text.replaceAll('&nbsp;', ' ')
               .replaceAll('&lt;', '<')
               .replaceAll('&gt;', '>')
               .replaceAll('&amp;', '&')
               .replaceAll('&quot;', '"');
               
    return text.trim();
  }

  Future<String> _callGemini(String prompt) async {
    final host = (_baseUrl != null && _baseUrl!.isNotEmpty)
        ? _baseUrl! 
        : 'https://generativelanguage.googleapis.com';
        
    // Handle potential trailing slash in user input
    final cleanHost = host.endsWith('/') ? host.substring(0, host.length - 1) : host;

    final url = Uri.parse(
      '$cleanHost/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': '$_systemPrompt\n\n$prompt'}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 2048,
              }
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      if (data['candidates'] == null ||
          (data['candidates'] as List).isEmpty ||
          data['candidates'][0]['content'] == null) {
        throw Exception('Empty response from Gemini API');
      }
      
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your network or try a faster model.');
    } catch (e) {
      throw Exception('Failed to connect to AI service: $e');
    }
  }

  Future<String> _callClaude(String prompt) async {
    final host = (_baseUrl != null && _baseUrl!.isNotEmpty)
        ? _baseUrl! 
        : 'https://api.anthropic.com';
        
    final cleanHost = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    final url = Uri.parse('$cleanHost/v1/messages');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey!,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _model.isEmpty ? 'claude-3-haiku-20240307' : _model,
              'max_tokens': 2048,
              'system': _systemPrompt,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Claude API error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your network.');
    } catch (e) {
      throw Exception('Failed to connect to AI service: $e');
    }
  }

  Future<String> _callVertex(String prompt) async {
    // Vertex AI requires OAuth2 authentication
    // This is a simplified implementation
    throw UnimplementedError(
      'Vertex AI requires Google Cloud authentication. Please use Gemini or Claude.',
    );
  }

  static List<String> getDefaultPrompts() {
    return [
      '详细解析本题',
      '为什么其他选项是错误的？',
      '这道题考察的知识点是什么？',
      '有类似的题目吗？',
      '用更简单的话解释',
    ];
  }
}