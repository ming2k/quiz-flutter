import 'dart:async';

/// State for an active AI streaming response
class AiStreamState {
  final int questionId;
  final int sessionId;
  bool isLoading;
  String streamingResponse;
  String? error;
  StreamSubscription<String>? _subscription;

  AiStreamState({
    required this.questionId,
    required this.sessionId,
    this.isLoading = true,
    this.streamingResponse = '',
    this.error,
  });

  void setSubscription(StreamSubscription<String> sub) {
    _subscription = sub;
  }

  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  bool get isActive => _subscription != null && isLoading;
}
