class ChatSession {
  final int id;
  final int questionId;
  final String title;
  final int createdAt;

  ChatSession({
    required this.id,
    required this.questionId,
    required this.title,
    required this.createdAt,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as int,
      questionId: map['question_id'] as int,
      title: map['title'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'title': title,
      'created_at': createdAt,
    };
  }
}
