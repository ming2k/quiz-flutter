/// SRS review state for a single question.
/// Based on the SM-2 spaced repetition algorithm.
class SrsState {
  final int questionId;
  final int bookId;
  final int intervalDays;
  final double easeFactor;
  final int repetitions;
  final int lapses;
  final int? dueDate;
  final int? lastReviewed;
  final SrsReviewState reviewState;

  const SrsState({
    required this.questionId,
    required this.bookId,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.lapses = 0,
    this.dueDate,
    this.lastReviewed,
    this.reviewState = SrsReviewState.newCard,
  });

  factory SrsState.fromMap(Map<String, dynamic> map) {
    return SrsState(
      questionId: map['question_id'] as int,
      bookId: map['book_id'] as int,
      intervalDays: map['interval_days'] as int? ?? 0,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      repetitions: map['repetitions'] as int? ?? 0,
      lapses: map['lapses'] as int? ?? 0,
      dueDate: map['due_date'] as int?,
      lastReviewed: map['last_reviewed'] as int?,
      reviewState: SrsReviewState.values[map['review_state'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'book_id': bookId,
      'interval_days': intervalDays,
      'ease_factor': easeFactor,
      'repetitions': repetitions,
      'lapses': lapses,
      'due_date': dueDate,
      'last_reviewed': lastReviewed,
      'review_state': reviewState.index,
    };
  }

  SrsState copyWith({
    int? questionId,
    int? bookId,
    int? intervalDays,
    double? easeFactor,
    int? repetitions,
    int? lapses,
    int? dueDate,
    int? lastReviewed,
    SrsReviewState? reviewState,
  }) {
    return SrsState(
      questionId: questionId ?? this.questionId,
      bookId: bookId ?? this.bookId,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueDate: dueDate ?? this.dueDate,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewState: reviewState ?? this.reviewState,
    );
  }

  bool get isDue {
    if (dueDate == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= dueDate!;
  }

  bool get isNew => reviewState == SrsReviewState.newCard;
  bool get isLearning =>
      reviewState == SrsReviewState.learning ||
      reviewState == SrsReviewState.relearning;
  bool get isReview => reviewState == SrsReviewState.review;
}

/// Review state of a card in the SRS system.
enum SrsReviewState {
  /// Never reviewed before.
  newCard,

  /// In the learning phase (first few reviews).
  learning,

  /// In the regular review phase.
  review,

  /// Forgotten and being re-learned.
  relearning,
}

/// User's self-assessment rating after reviewing a card.
enum SrsRating {
  /// Complete blackout. Card will be scheduled for immediate re-review.
  again,

  /// Remembered with significant difficulty. Slightly increases interval.
  hard,

  /// Remembered correctly. Standard interval progression.
  good,

  /// Remembered perfectly. Larger interval bonus.
  easy,
}

/// Aggregated SRS statistics for a book.
class SrsStats {
  final int newCards;
  final int learning;
  final int review;
  final int total;

  const SrsStats({
    this.newCards = 0,
    this.learning = 0,
    this.review = 0,
    this.total = 0,
  });

  int get dueToday => learning + review;
}
