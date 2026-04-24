import 'feedback_event.dart';
import 'sound_theme.dart';
import 'haptic_strategy.dart';
import 'themes/default_sound_theme.dart';
import 'themes/default_haptic_strategy.dart';

/// Centralised feedback service that coordinates sound and haptic output.
///
/// Consumers should call [playCorrect] or [playWrong]; this service takes
/// care of respecting the enabled/disabled flags and the continuous-feedback
/// setting.
///
/// ```dart
/// final feedback = FeedbackService();
/// await feedback.init();
/// feedback.configure(
///   soundEnabled: settings.soundEffects,
///   hapticEnabled: settings.hapticFeedback,
///   continuousFeedback: settings.continuousFeedback,
/// );
/// feedback.playCorrect(); // handles streak mapping internally
/// ```
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal()
      : _soundTheme = DefaultSoundTheme(),
        _hapticStrategy = DefaultHapticStrategy();

  SoundTheme _soundTheme;
  HapticStrategy _hapticStrategy;

  bool _initialized = false;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _continuousFeedback = true;
  int _streak = 0;

  int get streak => _streak;

  FeedbackService.withTheme({
    SoundTheme? soundTheme,
    HapticStrategy? hapticStrategy,
  })  : _soundTheme = soundTheme ?? DefaultSoundTheme(),
        _hapticStrategy = hapticStrategy ?? DefaultHapticStrategy();

  /// Initialise the underlying theme and strategy.
  Future<void> init() async {
    if (_initialized) return;
    await _soundTheme.init();
    await _hapticStrategy.init();
    _initialized = true;
  }

  /// Re-configure the service at runtime (e.g. when settings change).
  void configure({
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? continuousFeedback,
    SoundTheme? soundTheme,
    HapticStrategy? hapticStrategy,
  }) {
    if (soundEnabled != null) _soundEnabled = soundEnabled;
    if (hapticEnabled != null) _hapticEnabled = hapticEnabled;
    if (continuousFeedback != null) _continuousFeedback = continuousFeedback;

    if (soundTheme != null && soundTheme.id != _soundTheme.id) {
      _soundTheme.dispose();
      _soundTheme = soundTheme;
      _soundTheme.init();
    }

    if (hapticStrategy != null && hapticStrategy.id != _hapticStrategy.id) {
      _hapticStrategy.dispose();
      _hapticStrategy = hapticStrategy;
      _hapticStrategy.init();
    }
  }

  /// Increment the internal streak counter.
  void incrementStreak() => _streak++;

  /// Reset the internal streak counter.
  void resetStreak() => _streak = 0;

  /// Play the "correct" feedback.
  ///
  /// When [_continuousFeedback] is enabled the event is chosen based on the
  /// current streak.  When disabled [FeedbackEvent.correct] is always used.
  Future<void> playCorrect() async {
    if (!_initialized) return;

    final event = (_continuousFeedback && _streak > 0)
        ? _streakToEvent(_streak)
        : FeedbackEvent.correct;

    if (_soundEnabled) await _soundTheme.play(event);
    if (_hapticEnabled) await _hapticStrategy.play(event);
  }

  /// Play the "wrong" feedback.
  Future<void> playWrong() async {
    if (!_initialized) return;

    if (_soundEnabled) await _soundTheme.play(FeedbackEvent.wrong);
    if (_hapticEnabled) await _hapticStrategy.play(FeedbackEvent.wrong);
  }

  /// Clean up resources.
  Future<void> dispose() async {
    await _soundTheme.dispose();
    await _hapticStrategy.dispose();
    _initialized = false;
    _streak = 0;
  }

  FeedbackEvent _streakToEvent(int streak) {
    return switch (streak) {
      1 => FeedbackEvent.streak1,
      2 => FeedbackEvent.streak2,
      3 => FeedbackEvent.streak3,
      4 => FeedbackEvent.streak4,
      5 => FeedbackEvent.streak5,
      _ => FeedbackEvent.streakAce,
    };
  }
}
