import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _hasVibrator = false;
  bool _hasCustomVibrationsSupport = false;

  Future<void> init() async {
    _hasVibrator = await Vibration.hasVibrator() ?? false;
    _hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport() ?? false;
  }

  /// Play haptic feedback for a correct answer based on current streak
  Future<void> playCorrect(int streak) async {
    if (!_hasVibrator) return;

    if (streak <= 1) {
      await HapticFeedback.mediumImpact();
    } else if (streak == 2) {
      // Light-Medium double tap
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [0, 50, 50, 100],
          intensities: [0, 128, 0, 180],
        );
      } else {
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.mediumImpact();
      }
    } else if (streak == 3) {
      // Triple beat
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [0, 40, 40, 40, 40, 100],
          intensities: [0, 100, 0, 150, 0, 200],
        );
      } else {
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.mediumImpact();
      }
    } else if (streak == 4) {
      // Rhythmic rising
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [0, 30, 30, 30, 30, 30, 30, 120],
          intensities: [0, 80, 0, 120, 0, 180, 0, 240],
        );
      } else {
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.heavyImpact();
      }
    } else {
      // Streak 5+ : "Hearthstone Legend" style - powerful rhythmic sequence
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [0, 40, 40, 40, 40, 40, 40, 200],
          intensities: [0, 100, 0, 150, 0, 200, 0, 255],
        );
      } else {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.heavyImpact();
      }
    }
  }

  /// Play haptic feedback for a wrong answer
  Future<void> playWrong() async {
    if (!_hasVibrator) return;
    await HapticFeedback.heavyImpact();
  }
}
