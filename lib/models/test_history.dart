import 'dart:convert';

class TestHistoryEntry {
  final String bankFilename;
  final String mode;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final double accuracy;
  final int startTime;
  final int endTime;
  final int duration;
  final List<int> questionsAsked;
  final Map<int, String> answers;
  final int timestamp;

  TestHistoryEntry({
    required this.bankFilename,
    required this.mode,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.accuracy,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.questionsAsked,
    required this.answers,
    required this.timestamp,
  });

  factory TestHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TestHistoryEntry(
      bankFilename: json['bankFilename'] as String,
      mode: json['mode'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctCount: json['correctCount'] as int,
      wrongCount: json['wrongCount'] as int,
      unansweredCount: json['unansweredCount'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      startTime: json['startTime'] as int,
      endTime: json['endTime'] as int,
      duration: json['duration'] as int,
      questionsAsked: (json['questionsAsked'] as List).cast<int>(),
      answers: (json['answers'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), v as String),
      ),
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankFilename': bankFilename,
      'mode': mode,
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'unansweredCount': unansweredCount,
      'accuracy': accuracy,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'questionsAsked': questionsAsked,
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'timestamp': timestamp,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory TestHistoryEntry.fromJsonString(String jsonStr) {
    return TestHistoryEntry.fromJson(jsonDecode(jsonStr));
  }

  String get formattedDuration {
    final minutes = duration ~/ 60000;
    final seconds = (duration % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get accuracyPercent => '${(accuracy * 100).toStringAsFixed(1)}%';
}
