import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../feedback_event.dart';
import '../haptic_strategy.dart';

/// The default haptic strategy.
///
/// Designed to be short and non-intrusive so it does not distract from
/// studying.  Feedback patterns are kept under ~250ms.
///
/// - **Wrong**: A single dull thud (~200ms) to signal error without alarm.
/// - **Correct**: A crisp short tick (~50ms).
/// - **Streak 5 / Ace**: A slightly stronger double-tap to give a small
///   dopamine kick while still being very brief.
class DefaultHapticStrategy implements HapticStrategy {
  @override
  String get id => 'default';

  @override
  String get displayName => 'Default';

  bool _hasVibrator = false;
  bool _hasCustomVibrationsSupport = false;

  bool get _supportsVibrationPlugin {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<void> init() async {
    if (!_supportsVibrationPlugin) {
      _hasVibrator = false;
      _hasCustomVibrationsSupport = false;
      return;
    }

    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
      _hasCustomVibrationsSupport =
          await Vibration.hasCustomVibrationsSupport() ?? false;
    } on MissingPluginException {
      _hasVibrator = false;
      _hasCustomVibrationsSupport = false;
    } on PlatformException {
      _hasVibrator = false;
      _hasCustomVibrationsSupport = false;
    }
  }

  @override
  Future<void> dispose() async {
    // Nothing to clean up.
  }

  @override
  Future<void> play(FeedbackEvent event) async {
    if (!_hasVibrator) return;

    switch (event) {
      case FeedbackEvent.wrong:
        await _playWrong();
      case FeedbackEvent.correct:
      case FeedbackEvent.streak1:
      case FeedbackEvent.streak2:
      case FeedbackEvent.streak3:
      case FeedbackEvent.streak4:
        await _playCorrect();
      case FeedbackEvent.streak5:
      case FeedbackEvent.streakAce:
        await _playStreakReward();
    }
  }

  /// Short, crisp confirmation tick.
  Future<void> _playCorrect() async {
    if (_hasCustomVibrationsSupport) {
      await _safeVibrate(pattern: [0, 50], intensities: [0, 180]);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Slightly stronger double-tap for streak milestones.
  /// Still under 150ms total.
  Future<void> _playStreakReward() async {
    if (_hasCustomVibrationsSupport) {
      await _safeVibrate(
        pattern: [0, 40, 30, 60],
        intensities: [0, 160, 0, 220],
      );
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Dull, medium-duration thud for errors.
  Future<void> _playWrong() async {
    if (_hasCustomVibrationsSupport) {
      // 200ms at ~45% intensity – noticeable but not jarring.
      await _safeVibrate(pattern: [0, 200], intensities: [0, 115]);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> _safeVibrate({
    required List<int> pattern,
    required List<int> intensities,
  }) async {
    try {
      await Vibration.vibrate(pattern: pattern, intensities: intensities);
    } on MissingPluginException {
      _hasVibrator = false;
      _hasCustomVibrationsSupport = false;
    } on PlatformException {
      _hasVibrator = false;
      _hasCustomVibrationsSupport = false;
    }
  }
}
