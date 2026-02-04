import 'dart:convert';
import 'chat_message.dart';

enum AppMode { practice, review, memorize, test }

class UserAnswer {
  final String? selected;
  final bool? isCorrect;
  final bool markedWrong;

  UserAnswer({
    this.selected,
    this.isCorrect,
    this.markedWrong = false,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      selected: json['selected'] as String?,
      isCorrect: json['isCorrect'] as bool?,
      markedWrong: json['markedWrong'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selected': selected,
      'isCorrect': isCorrect,
      'markedWrong': markedWrong,
    };
  }

  UserAnswer copyWith({
    String? selected,
    bool? isCorrect,
    bool? markedWrong,
  }) {
    return UserAnswer(
      selected: selected ?? this.selected,
      isCorrect: isCorrect ?? this.isCorrect,
      markedWrong: markedWrong ?? this.markedWrong,
    );
  }
}

class PartitionStats {
  final int correct;
  final int wrong;

  PartitionStats({
    this.correct = 0,
    this.wrong = 0,
  });

  factory PartitionStats.fromJson(Map<String, dynamic> json) {
    return PartitionStats(
      correct: json['correct'] as int? ?? 0,
      wrong: json['wrong'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correct': correct,
      'wrong': wrong,
    };
  }

  double get accuracy {
    final total = correct + wrong;
    if (total == 0) return 0;
    return correct / total;
  }
}

class UserProgress {
  final String bankFilename;
  final AppMode appMode;
  final int currentQuestionIndex;
  final Map<AppMode, int> modePositions;
  final String currentPartitionId;
  final Map<String, Map<AppMode, int>> partitionModePositions;
  final Map<String, List<UserAnswer>> userAnswersByPartition;
  final Map<String, List<int>> markedQuestionsByPartition;
  final List<String> questionNotes;
  final Map<int, List<ChatMessage>> aiChatHistoryByQuestionId;
  final Map<String, PartitionStats> statsByPartition;
  final int timestamp;

  UserProgress({
    required this.bankFilename,
    this.appMode = AppMode.practice,
    this.currentQuestionIndex = 0,
    Map<AppMode, int>? modePositions,
    this.currentPartitionId = 'all',
    Map<String, Map<AppMode, int>>? partitionModePositions,
    Map<String, List<UserAnswer>>? userAnswersByPartition,
    Map<String, List<int>>? markedQuestionsByPartition,
    List<String>? questionNotes,
    Map<int, List<ChatMessage>>? aiChatHistoryByQuestionId,
    Map<String, PartitionStats>? statsByPartition,
    int? timestamp,
  })  : modePositions = modePositions ??
            {
              AppMode.practice: 0,
              AppMode.review: 0,
              AppMode.memorize: 0,
              AppMode.test: 0,
            },
        partitionModePositions = partitionModePositions ?? {},
        userAnswersByPartition = userAnswersByPartition ?? {},
        markedQuestionsByPartition = markedQuestionsByPartition ?? {},
        questionNotes = questionNotes ?? [],
        aiChatHistoryByQuestionId = aiChatHistoryByQuestionId ?? {},
        statsByPartition = statsByPartition ?? {},
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      bankFilename: json['bankFilename'] as String,
      appMode: AppMode.values.firstWhere(
        (e) => e.name == json['appMode'],
        orElse: () => AppMode.practice,
      ),
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      modePositions: (json['modePositions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              AppMode.values.firstWhere((e) => e.name == k),
              v as int,
            ),
          ) ??
          {},
      currentPartitionId: json['currentPartitionId'] as String? ?? 'all',
      partitionModePositions:
          (json['partitionModePositions'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(
                  k,
                  (v as Map<String, dynamic>).map(
                    (mk, mv) => MapEntry(
                      AppMode.values.firstWhere((e) => e.name == mk),
                      mv as int,
                    ),
                  ),
                ),
              ) ??
              {},
      userAnswersByPartition:
          (json['userAnswersByPartition'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(
                  k,
                  (v as List)
                      .map((e) => e == null
                          ? UserAnswer()
                          : UserAnswer.fromJson(e as Map<String, dynamic>))
                      .toList(),
                ),
              ) ??
              {},
      markedQuestionsByPartition:
          (json['markedQuestionsByPartition'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as List).cast<int>()),
              ) ??
              {},
      questionNotes:
          (json['questionNotes'] as List?)?.cast<String>().toList() ?? [],
      aiChatHistoryByQuestionId: (json['aiChatHistoryByQuestionId'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              int.parse(k),
              (v as List)
                  .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ),
          ) ??
          {},
      statsByPartition:
          (json['statsByPartition'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, PartitionStats.fromJson(v)),
              ) ??
              {},
      timestamp: json['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankFilename': bankFilename,
      'appMode': appMode.name,
      'currentQuestionIndex': currentQuestionIndex,
      'modePositions': modePositions.map((k, v) => MapEntry(k.name, v)),
      'currentPartitionId': currentPartitionId,
      'partitionModePositions': partitionModePositions.map(
        (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv))),
      ),
      'userAnswersByPartition': userAnswersByPartition.map(
        (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
      ),
      'markedQuestionsByPartition': markedQuestionsByPartition,
      'questionNotes': questionNotes,
      'aiChatHistoryByQuestionId': aiChatHistoryByQuestionId.map(
        (k, v) => MapEntry(k.toString(), v.map((e) => e.toJson()).toList()),
      ),
      'statsByPartition':
          statsByPartition.map((k, v) => MapEntry(k, v.toJson())),
      'timestamp': timestamp,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserProgress.fromJsonString(String jsonStr) {
    return UserProgress.fromJson(jsonDecode(jsonStr));
  }

  UserProgress copyWith({
    String? bankFilename,
    AppMode? appMode,
    int? currentQuestionIndex,
    Map<AppMode, int>? modePositions,
    String? currentPartitionId,
    Map<String, Map<AppMode, int>>? partitionModePositions,
    Map<String, List<UserAnswer>>? userAnswersByPartition,
    Map<String, List<int>>? markedQuestionsByPartition,
    List<String>? questionNotes,
    Map<int, List<ChatMessage>>? aiChatHistoryByQuestionId,
    Map<String, PartitionStats>? statsByPartition,
    int? timestamp,
  }) {
    return UserProgress(
      bankFilename: bankFilename ?? this.bankFilename,
      appMode: appMode ?? this.appMode,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      modePositions: modePositions ?? Map.from(this.modePositions),
      currentPartitionId: currentPartitionId ?? this.currentPartitionId,
      partitionModePositions:
          partitionModePositions ?? Map.from(this.partitionModePositions),
      userAnswersByPartition:
          userAnswersByPartition ?? Map.from(this.userAnswersByPartition),
      markedQuestionsByPartition:
          markedQuestionsByPartition ?? Map.from(this.markedQuestionsByPartition),
      questionNotes: questionNotes ?? List.from(this.questionNotes),
      aiChatHistoryByQuestionId: aiChatHistoryByQuestionId ?? Map.from(this.aiChatHistoryByQuestionId),
      statsByPartition: statsByPartition ?? Map.from(this.statsByPartition),
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
