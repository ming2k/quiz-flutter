import '../models/srs_state.dart';

/// Spaced Repetition System (SRS) service implementing the SM-2 algorithm.
///
/// This is a simplified variant of the SuperMemo SM-2 algorithm,
/// adapted for quiz-style review where the user self-rates their recall.
///
/// Algorithm rules:
/// - [SrsRating.again]: Reset card to learning state, interval = 1 day,
///   ease factor decreases by 0.2 (min 1.3).
/// - [SrsRating.hard]: Multiply interval by 1.2, ease factor decreases by 0.15,
///   increment repetition count.
/// - [SrsRating.good]: Standard SM-2 progression. 1st rep = 1 day, 2nd = 6 days,
///   thereafter interval * ease factor. Ease stays unchanged.
/// - [SrsRating.easy]: Bonus multiplier of 1.3x on the interval, ease factor
///   increases by 0.15 (max 2.5). 1st rep = 4 days.
class SrsService {
  static const double _minEase = 1.3;
  static const double _maxEase = 2.5;
  static const double _againEaseDelta = 0.2;
  static const double _hardEaseDelta = 0.15;
  static const double _easyEaseDelta = 0.15;
  static const double _hardIntervalMultiplier = 1.2;
  static const double _easyIntervalMultiplier = 1.3;

  static const int _firstIntervalAgain = 1;
  static const int _firstIntervalGood = 1;
  static const int _firstIntervalEasy = 4;
  static const int _secondIntervalGood = 6;

  /// Computes the next SRS state after a review rating.
  static SrsState review(SrsState state, SrsRating rating) {
    final now = DateTime.now().millisecondsSinceEpoch;

    switch (rating) {
      case SrsRating.again:
        return _handleAgain(state, now);
      case SrsRating.hard:
        return _handleHard(state, now);
      case SrsRating.good:
        return _handleGood(state, now);
      case SrsRating.easy:
        return _handleEasy(state, now);
    }
  }

  static SrsState _handleAgain(SrsState state, int now) {
    final newEase = (state.easeFactor - _againEaseDelta).clamp(
      _minEase,
      _maxEase,
    );
    return state.copyWith(
      intervalDays: _firstIntervalAgain,
      easeFactor: newEase,
      repetitions: 0,
      lapses: state.lapses + 1,
      reviewState: SrsReviewState.relearning,
      dueDate: now + const Duration(minutes: 1).inMilliseconds,
      lastReviewed: now,
    );
  }

  static SrsState _handleHard(SrsState state, int now) {
    final newEase = (state.easeFactor - _hardEaseDelta).clamp(
      _minEase,
      _maxEase,
    );
    final newInterval =
        (state.intervalDays * _hardIntervalMultiplier).ceil().clamp(1, 36500);

    return state.copyWith(
      intervalDays: newInterval,
      easeFactor: newEase,
      repetitions: state.repetitions + 1,
      reviewState: SrsReviewState.review,
      dueDate: now + Duration(days: newInterval).inMilliseconds,
      lastReviewed: now,
    );
  }

  static SrsState _handleGood(SrsState state, int now) {
    int newInterval;
    if (state.repetitions == 0) {
      newInterval = _firstIntervalGood;
    } else if (state.repetitions == 1) {
      newInterval = _secondIntervalGood;
    } else {
      newInterval = (state.intervalDays * state.easeFactor).round();
    }
    newInterval = newInterval.clamp(1, 36500);

    return state.copyWith(
      intervalDays: newInterval,
      easeFactor: state.easeFactor.clamp(_minEase, _maxEase),
      repetitions: state.repetitions + 1,
      reviewState: SrsReviewState.review,
      dueDate: now + Duration(days: newInterval).inMilliseconds,
      lastReviewed: now,
    );
  }

  static SrsState _handleEasy(SrsState state, int now) {
    final newEase = (state.easeFactor + _easyEaseDelta).clamp(
      _minEase,
      _maxEase,
    );
    int newInterval;
    if (state.repetitions == 0) {
      newInterval = _firstIntervalEasy;
    } else {
      newInterval =
          (state.intervalDays * state.easeFactor * _easyIntervalMultiplier)
              .round();
    }
    newInterval = newInterval.clamp(1, 36500);

    return state.copyWith(
      intervalDays: newInterval,
      easeFactor: newEase,
      repetitions: state.repetitions + 1,
      reviewState: SrsReviewState.review,
      dueDate: now + Duration(days: newInterval).inMilliseconds,
      lastReviewed: now,
    );
  }

  /// Returns a human-readable label for the next interval.
  static String intervalLabel(SrsState state, SrsRating rating) {
    final next = review(state, rating);
    final days = next.intervalDays;

    if (days == 0) return '< 1 min';
    if (days == 1) return '1 day';
    if (days < 30) return '$days days';
    if (days < 365) return '${(days / 30).round()} months';
    return '${(days / 365).round()} years';
  }
}
