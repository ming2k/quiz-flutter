import 'feedback_event.dart';

/// Abstract interface for a sound theme.
///
/// Implementations define how each [FeedbackEvent] maps to an actual sound.
/// New themes can be added by implementing this interface and registering
/// them in [availableThemes].
abstract class SoundTheme {
  String get id;
  String get displayName;

  Future<void> init();
  Future<void> dispose();
  Future<void> play(FeedbackEvent event);

  static List<SoundTheme> get availableThemes => [];
}
