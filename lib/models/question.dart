import 'dart:convert';

enum QuestionType {
  multipleChoice('multiple_choice'),
  trueFalse('true_false'),
  fillBlank('fill_blank'),
  cloze('cloze'),
  flashcard('flashcard'),
  passage('passage'),
  unknown('unknown');

  const QuestionType(this.protocolValue);

  final String protocolValue;

  static QuestionType fromProtocol(String? value) {
    if (value == null || value.isEmpty) return QuestionType.multipleChoice;
    return QuestionType.values.firstWhere(
      (type) => type.protocolValue == value,
      orElse: () => QuestionType.unknown,
    );
  }
}

class QuestionChoice {
  final String key;
  final String content;

  QuestionChoice({required this.key, required this.content});

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    // Standard format: {"key": "A", "content": "..."} or {"key": "A", "text": "..."}
    if (json.containsKey('key') &&
        (json.containsKey('content') ||
            json.containsKey('html') ||
            json.containsKey('text'))) {
      return QuestionChoice(
        key: json['key'] as String? ?? '',
        content:
            (json['content'] ?? json['html'] ?? json['text']) as String? ?? '',
      );
    }

    // Alternative: If it's a single entry map like {"A": "Choice content"}
    if (json.length == 1) {
      final entry = json.entries.first;
      return QuestionChoice(key: entry.key, content: entry.value.toString());
    }

    return QuestionChoice(
      key: json['key'] as String? ?? '',
      content: json['content'] as String? ?? '',
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
  final QuestionType questionType;

  // Protocol v2 optional fields
  final List<String> tags;
  final double? difficulty;
  final String? note;
  final String? frontTemplate;
  final String? backTemplate;

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
    this.questionType = QuestionType.multipleChoice,
    this.tags = const [],
    this.difficulty,
    this.note,
    this.frontTemplate,
    this.backTemplate,
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
              .map(
                (e) => QuestionChoice(
                  key: e.key.toString(),
                  content: e.value.toString(),
                ),
              )
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
          .map(
            (e) => QuestionChoice(
              key: e.key.toString(),
              content: e.value.toString(),
            ),
          )
          .toList();
    }

    parsedChoices.sort((a, b) => a.key.compareTo(b.key));

    // print('Parsed choices count: ${parsedChoices.length}');

    // Parse tags from JSON string
    List<String> parsedTags = [];
    final tagsData = map['tags'];
    if (tagsData is String && tagsData.isNotEmpty) {
      try {
        final decoded = jsonDecode(tagsData);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
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
      questionType: QuestionType.fromProtocol(map['question_type'] as String?),
      tags: parsedTags,
      difficulty: (map['difficulty'] as num?)?.toDouble(),
      note: map['note'] as String?,
      frontTemplate: map['front_template'] as String?,
      backTemplate: map['back_template'] as String?,
    );
  }

  String getChoiceContent(String key) {
    final choice = choices.where((c) => c.key == key).firstOrNull;
    return choice?.content ?? '';
  }

  List<MapEntry<String, String>> get choiceEntries =>
      choices.map((c) => MapEntry(c.key, c.content)).toList();

  bool get isPassage => questionType == QuestionType.passage;

  bool get isAnswerable => questionType != QuestionType.passage;

  bool get isChoiceBased =>
      isAnswerable &&
      (questionType == QuestionType.multipleChoice ||
          questionType == QuestionType.trueFalse ||
          choices.isNotEmpty);

  bool get needsAnswerReveal => isAnswerable && choices.isEmpty;

  String get displayFront =>
      frontTemplate != null && frontTemplate!.trim().isNotEmpty
      ? frontTemplate!
      : content;

  String get displayBack {
    if (backTemplate != null && backTemplate!.trim().isNotEmpty) {
      return backTemplate!;
    }
    if (explanation.trim().isEmpty) return answer;
    return '$answer\n\n$explanation';
  }
}

enum QuestionStatus { unanswered, correct, wrong, marked }
