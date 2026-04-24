import 'package:flutter_test/flutter_test.dart';
import 'package:mnema/models/srs_state.dart';
import 'package:mnema/services/srs_service.dart';

void main() {
  group('SrsService SM-2 Algorithm', () {
    const int bookId = 1;
    const int questionId = 100;

    SrsState newState() => const SrsState(
          questionId: questionId,
          bookId: bookId,
        );

    test('new card + Again -> interval 1 day, ease -0.2, reps 0, relearning',
        () {
      final state = newState();
      final result = SrsService.review(state, SrsRating.again);

      expect(result.intervalDays, 1);
      expect(result.easeFactor, 2.3); // 2.5 - 0.2
      expect(result.repetitions, 0);
      expect(result.lapses, 1);
      expect(result.reviewState, SrsReviewState.relearning);
      expect(result.dueDate, isNotNull);
    });

    test('new card + Good -> interval 1 day, ease unchanged, reps 1, review',
        () {
      final state = newState();
      final result = SrsService.review(state, SrsRating.good);

      expect(result.intervalDays, 1);
      expect(result.easeFactor, 2.5);
      expect(result.repetitions, 1);
      expect(result.lapses, 0);
      expect(result.reviewState, SrsReviewState.review);
    });

    test(
        'new card + Easy -> interval 4 days, ease clamped to max 2.5, reps 1, review',
        () {
      final state = newState();
      final result = SrsService.review(state, SrsRating.easy);

      expect(result.intervalDays, 4);
      // Default ease is already 2.5 (max), so it stays at 2.5 after clamping
      expect(result.easeFactor, 2.5);
      expect(result.repetitions, 1);
      expect(result.reviewState, SrsReviewState.review);
    });

    test('new card with lower ease + Easy -> ease increases', () {
      final state = newState().copyWith(easeFactor: 2.3);
      final result = SrsService.review(state, SrsRating.easy);

      expect(result.easeFactor, closeTo(2.45, 0.001)); // 2.3 + 0.15
    });

    test('second review + Good -> interval 6 days', () {
      final state = newState().copyWith(repetitions: 1);
      final result = SrsService.review(state, SrsRating.good);

      expect(result.intervalDays, 6);
      expect(result.repetitions, 2);
    });

    test('third review + Good -> interval = previous * ease', () {
      final state = newState().copyWith(
        repetitions: 2,
        intervalDays: 6,
        easeFactor: 2.5,
      );
      final result = SrsService.review(state, SrsRating.good);

      expect(result.intervalDays, 15); // 6 * 2.5 = 15
      expect(result.repetitions, 3);
    });

    test('Hard -> interval * 1.2, ease -0.15', () {
      final state = newState().copyWith(
        repetitions: 2,
        intervalDays: 10,
        easeFactor: 2.5,
      );
      final result = SrsService.review(state, SrsRating.hard);

      expect(result.intervalDays, 12); // 10 * 1.2 = 12 (ceil)
      expect(result.easeFactor, 2.35); // 2.5 - 0.15
      expect(result.repetitions, 3);
    });

    test('Again after multiple reps -> resets reps to 0, reduces ease', () {
      final state = newState().copyWith(
        repetitions: 5,
        intervalDays: 30,
        easeFactor: 2.5,
        lapses: 1,
      );
      final result = SrsService.review(state, SrsRating.again);

      expect(result.intervalDays, 1);
      expect(result.repetitions, 0);
      expect(result.lapses, 2);
      expect(result.easeFactor, 2.3);
    });

    test('ease factor clamped to minimum 1.3', () {
      final state = newState().copyWith(easeFactor: 1.35);
      final result = SrsService.review(state, SrsRating.again);

      expect(result.easeFactor, 1.3); // 1.35 - 0.2 = 1.15, clamped to 1.3
    });

    test('ease factor clamped to maximum 2.5', () {
      final state = newState().copyWith(easeFactor: 2.5);
      final result = SrsService.review(state, SrsRating.easy);

      expect(result.easeFactor, 2.5); // 2.5 + 0.15 = 2.65, clamped to 2.5
    });

    test('intervalLabel for new card Again shows 1 day', () {
      final state = newState();
      final label = SrsService.intervalLabel(state, SrsRating.again);
      expect(label, '1 day');
    });

    test('intervalLabel for new card Good shows 1 day', () {
      final state = newState();
      final label = SrsService.intervalLabel(state, SrsRating.good);
      expect(label, '1 day');
    });

    test('intervalLabel for established card shows days', () {
      final state = newState().copyWith(repetitions: 3, intervalDays: 10);
      final label = SrsService.intervalLabel(state, SrsRating.good);
      expect(label.contains('days'), isTrue);
    });

    test('intervalLabel for long interval shows months', () {
      final state = newState().copyWith(repetitions: 5, intervalDays: 60);
      final label = SrsService.intervalLabel(state, SrsRating.good);
      expect(label.contains('months'), isTrue);
    });

    test('intervalLabel for very long interval shows years', () {
      final state = newState().copyWith(repetitions: 10, intervalDays: 400);
      final label = SrsService.intervalLabel(state, SrsRating.good);
      expect(label.contains('years'), isTrue);
    });
  });
}
