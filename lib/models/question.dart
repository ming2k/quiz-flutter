import 'dart:convert';

class QuestionChoice {
  final String key;
  final String html;

  QuestionChoice({required this.key, required this.html});

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    // Standard format: {"key": "A", "html": "..."} or {"key": "A", "text": "..."}
    if (json.containsKey('key') && (json.containsKey('html') || json.containsKey('content') || json.containsKey('text'))) {
      return QuestionChoice(
        key: json['key'] as String? ?? '',
        html: (json['html'] ?? json['content'] ?? json['text']) as String? ?? '',
      );
    }
    
    // Alternative: If it's a single entry map like {"A": "Choice content"}
    if (json.length == 1) {
      final entry = json.entries.first;
      return QuestionChoice(
        key: entry.key,
        html: entry.value.toString(),
      );
    }

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
  
  // Extended fields for reading comprehension
  String? parentContent;
  List<Question>? subQuestions;

  Question({
    required this.id,
    required this.bookId,
    required this.sectionId,
    this.parentId,
    required this.content,
    required this.choices,
    required this.answer,
    required this.explanation,
    this.parentContent,
    this.subQuestions,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    List<QuestionChoice> parsedChoices = [];

    final choicesData = map['choices'];
    // print('Question.fromMap ID: ${map['id']}, choicesData type: ${choicesData.runtimeType}, value: $choicesData');
    
    if (choicesData is String && choicesData.isNotEmpty) {
      try {
        final decoded = jsonDecode(choicesData);
        if (decoded is List) {
          parsedChoices = decoded
              .map((e) => QuestionChoice.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (decoded is Map) {
          parsedChoices = decoded.entries
              .map((e) => QuestionChoice(key: e.key.toString(), html: e.value.toString()))
              .toList();
        }
      } catch (e) {
        // print('Error decoding choices string: $e');
      }
    } else if (choicesData is List) {
      parsedChoices = choicesData
          .map((e) => QuestionChoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (choicesData is Map) {
      parsedChoices = choicesData.entries
          .map((e) => QuestionChoice(key: e.key.toString(), html: e.value.toString()))
          .toList();
    }
    
    parsedChoices.sort((a, b) => a.key.compareTo(b.key));
    
    // print('Parsed choices count: ${parsedChoices.length}');

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
