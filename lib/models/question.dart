import 'dart:convert';

class QuestionChoice {
  final String key;
  final String html;

  QuestionChoice({required this.key, required this.html});

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    return QuestionChoice(
      key: json['key'] as String? ?? '',
      html: json['html'] as String? ?? '',
    );
  }
}

class Question {
  final int id;
  final int bookId;
  final String sectionId;
  final int? parentId;
  final String content;
  final List<QuestionChoice> choices;
  final String answer;
  final String explanation;

  Question({
    required this.id,
    required this.bookId,
    required this.sectionId,
    this.parentId,
    required this.content,
    required this.choices,
    required this.answer,
    required this.explanation,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    List<QuestionChoice> parsedChoices = [];

    final choicesData = map['choices'];
    if (choicesData is String && choicesData.isNotEmpty) {
      try {
        final decoded = jsonDecode(choicesData) as List;
        parsedChoices = decoded
            .map((e) => QuestionChoice.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return Question(
      id: map['id'] as int,
      bookId: map['book_id'] as int,
      sectionId: map['section_id'] as String? ?? '',
      parentId: map['parent_id'] as int?,
      content: map['content'] as String? ?? '',
      choices: parsedChoices,
      answer: map['answer'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
    );
  }

  String getChoiceHtml(String key) {
    final choice = choices.where((c) => c.key == key).firstOrNull;
    return choice?.html ?? '';
  }

  List<MapEntry<String, String>> get choiceEntries =>
      choices.map((c) => MapEntry(c.key, c.html)).toList();
}
