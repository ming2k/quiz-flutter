import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Callback for configuring AiService before use
typedef AiServiceConfigurator = void Function(AiService service);

/// Mixin that provides AI chat capabilities for study/test providers.
///
/// The including class must:
/// - extend or mixin `ChangeNotifier`
/// - provide a `currentQuestion` getter returning the active `Question?`
mixin AiChatMixin on ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<ChatMessage> _currentChatHistory = [];
  List<ChatSession> _chatSessions = [];
  int? _currentChatSessionId;

  final AiService _aiService = AiService();
  final Map<int, AiStreamState> _aiStreams = {};
  AiServiceConfigurator? _aiConfigurator;

  /// The currently active question. Must be provided by the including class.
  Question? get currentQuestion;

  // Getters
  List<ChatMessage> get currentAiChatHistory =>
      List.unmodifiable(_currentChatHistory);
  List<ChatSession> get chatSessions => List.unmodifiable(_chatSessions);
  int? get currentChatSessionId => _currentChatSessionId;

  AiStreamState? get currentAiStream =>
      _currentChatSessionId != null ? _aiStreams[_currentChatSessionId] : null;
  bool get isAiStreaming => currentAiStream?.isLoading ?? false;
  String get aiStreamingResponse => currentAiStream?.streamingResponse ?? '';
  AiStreamState? getAiStream(int sessionId) => _aiStreams[sessionId];

  Future<void> loadChatHistory() async {
    final question = currentQuestion;
    if (question == null) {
      _currentChatHistory = [];
      _chatSessions = [];
      _currentChatSessionId = null;
      return;
    }

    _chatSessions = await _db.getChatSessions(question.id);

    if (_chatSessions.isNotEmpty) {
      if (_currentChatSessionId == null ||
          !_chatSessions.any((s) => s.id == _currentChatSessionId)) {
        _currentChatSessionId = _chatSessions.first.id;
      }

      if (_currentChatSessionId != null) {
        _currentChatHistory = await _db.getChatHistory(_currentChatSessionId!);
      }
    } else {
      _currentChatSessionId = null;
      _currentChatHistory = [];
    }

    notifyListeners();
  }

  Future<void> createChatSession([String title = 'New Chat']) async {
    final question = currentQuestion;
    if (question == null) return;

    final session = await _db.createChatSession(question.id, title);
    _chatSessions.insert(0, session);
    _currentChatSessionId = session.id;
    _currentChatHistory = [];
    notifyListeners();
  }

  Future<void> switchChatSession(int sessionId) async {
    if (_currentChatSessionId == sessionId) return;

    _currentChatSessionId = sessionId;
    _currentChatHistory = await _db.getChatHistory(sessionId);
    notifyListeners();
  }

  Future<void> deleteChatSession(int sessionId) async {
    await cancelAiChat(sessionId);
    _aiService.clearSessionContext(sessionId);

    await _db.deleteChatSession(sessionId);
    _chatSessions.removeWhere((s) => s.id == sessionId);

    if (_currentChatSessionId == sessionId) {
      if (_chatSessions.isNotEmpty) {
        _currentChatSessionId = _chatSessions.first.id;
        _currentChatHistory = await _db.getChatHistory(_currentChatSessionId!);
      } else {
        _currentChatSessionId = null;
        _currentChatHistory = [];
      }
    }
    notifyListeners();
  }

  Future<void> addAiChatMessage(ChatMessage message) async {
    if (currentQuestion == null) return;

    if (_currentChatSessionId == null) {
      String title = message.text.replaceAll('\n', ' ').trim();
      if (title.length > 30) title = '${title.substring(0, 30)}...';
      if (title.isEmpty) title = 'Chat';

      await createChatSession(title);
    } else if (message.isUser) {
      final currentSession = _chatSessions.firstWhere(
        (s) => s.id == _currentChatSessionId,
      );
      if (currentSession.title == 'New Chat' ||
          currentSession.title == 'Chat') {
        String newTitle = message.text.replaceAll('\n', ' ').trim();
        if (newTitle.length > 30) newTitle = '${newTitle.substring(0, 30)}...';
        if (newTitle.isNotEmpty) {
          await _db.updateChatSessionTitle(_currentChatSessionId!, newTitle);
          final index = _chatSessions.indexWhere(
            (s) => s.id == _currentChatSessionId,
          );
          if (index != -1) {
            _chatSessions[index] = ChatSession(
              id: currentSession.id,
              questionId: currentSession.questionId,
              title: newTitle,
              createdAt: currentSession.createdAt,
            );
          }
        }
      }
    }

    if (_currentChatSessionId != null) {
      await _db.saveChatMessage(_currentChatSessionId!, message);
      _currentChatHistory.add(message);
      notifyListeners();
    }
  }

  void setAiConfigurator(AiServiceConfigurator configurator) {
    _aiConfigurator = configurator;
    configurator(_aiService);
  }

  Future<void> startAiChat(String userMessage) async {
    final question = currentQuestion;
    if (question == null) return;

    if (_currentChatSessionId == null) {
      await createChatSession();
    }

    final sessionId = _currentChatSessionId!;
    final questionId = question.id;

    if (_aiConfigurator != null) {
      _aiConfigurator!(_aiService);
    }

    if (!_aiService.isConfigured) {
      throw Exception('AI service not configured. Please set API key.');
    }

    await cancelAiChat(sessionId);

    await addAiChatMessage(ChatMessage(text: userMessage, isUser: true));
    final sessionHistory = List<ChatMessage>.from(_currentChatHistory);

    final state = AiStreamState(questionId: questionId, sessionId: sessionId);
    _aiStreams[sessionId] = state;
    notifyListeners();

    try {
      final stream = _aiService.explain(
        questionStem: question.content,
        options: {for (var c in question.choices) c.key: c.content},
        correctAnswer: question.answer,
        userQuestion: userMessage,
        history: sessionHistory,
        sessionId: sessionId,
      );

      final subscription = stream.listen(
        (chunk) {
          state.streamingResponse += chunk;
          notifyListeners();
        },
        onError: (error) async {
          state.isLoading = false;
          state.error = error.toString().replaceAll("Exception: ", "");

          await _db.saveChatMessage(
            sessionId,
            ChatMessage(text: 'Error: ${state.error}', isUser: false),
          );

          if (_currentChatSessionId == sessionId) {
            _currentChatHistory.add(
              ChatMessage(text: 'Error: ${state.error}', isUser: false),
            );
          }

          _aiStreams.remove(sessionId);
          notifyListeners();
        },
        onDone: () async {
          state.isLoading = false;
          if (state.streamingResponse.isNotEmpty && state.error == null) {
            await _saveStreamResponse(
              sessionId,
              state.streamingResponse,
              questionId,
            );
          }
          _aiStreams.remove(sessionId);
          notifyListeners();
        },
        cancelOnError: true,
      );

      state.setSubscription(subscription);
    } catch (e) {
      state.isLoading = false;
      state.error = e.toString().replaceAll("Exception: ", "");

      await _db.saveChatMessage(
        sessionId,
        ChatMessage(text: 'Error: ${state.error}', isUser: false),
      );

      if (_currentChatSessionId == sessionId) {
        _currentChatHistory.add(
          ChatMessage(text: 'Error: ${state.error}', isUser: false),
        );
      }

      _aiStreams.remove(sessionId);
      notifyListeners();
    }
  }

  Future<void> _saveStreamResponse(
    int sessionId,
    String response,
    int questionId,
  ) async {
    if (_currentChatSessionId == sessionId) {
      await _db.saveChatMessage(
        sessionId,
        ChatMessage(text: response, isUser: false),
      );
      if (_currentChatHistory.isEmpty ||
          _currentChatHistory.last.text != response ||
          _currentChatHistory.last.isUser) {
        _currentChatHistory.add(ChatMessage(text: response, isUser: false));
      }
    } else {
      await _db.saveChatMessage(
        sessionId,
        ChatMessage(text: response, isUser: false),
      );
    }
  }

  Future<void> cancelAiChat(int sessionId) async {
    final state = _aiStreams[sessionId];
    if (state != null) {
      final questionId = state.questionId;
      final partialResponse = state.streamingResponse;

      await state.cancel();

      if (partialResponse.isNotEmpty) {
        await _saveStreamResponse(sessionId, partialResponse, questionId);
      }

      _aiStreams.remove(sessionId);
      notifyListeners();
    }
  }

  Future<void> cancelAllAiChats() async {
    for (final state in _aiStreams.values) {
      await state.cancel();
    }
    _aiStreams.clear();
    notifyListeners();
  }

  void disposeAiChat() {
    for (final state in _aiStreams.values) {
      state.cancel();
    }
    _aiStreams.clear();
  }
}
