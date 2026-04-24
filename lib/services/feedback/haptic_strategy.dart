import 'feedback_event.dart';

/// Abstract interface for a haptic (vibration) strategy.
///
/// Implementations define how each [FeedbackEvent] maps to haptic patterns.
abstract class HapticStrategy {
  String get id;
  String get displayName;

  Future<void> init();
  Future<void> dispose();
  Future<void> play(FeedbackEvent event);

  static List<HapticStrategy> get availableStrategies => [];
}
