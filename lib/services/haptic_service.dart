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

    // We have 6 distinct sound levels: streak_1 to streak_5 and streak_ace (for 6+)
    
    if (streak == 1) {
      // Level 1: Sharp custom tick
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(pattern: [0, 40], intensities: [0, 180]);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } else if (streak == 2) {
      // Level 2: Double tap (rhythmic)
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [0, 40, 60, 40], 
          intensities: [0, 150, 0, 200],
        );
      } else {
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.mediumImpact();
      }
    } else if (streak == 3) {
      // Level 3: Triple rising (accelerating)
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [0, 40, 50, 40, 50, 80], 
          intensities: [0, 100, 0, 160, 0, 240],
        );
      } else {
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.heavyImpact();
      }
    } else if (streak == 4) {
      // Level 4: The "Combo" beat
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [0, 30, 40, 30, 40, 30, 40, 120], 
          intensities: [0, 100, 0, 130, 0, 160, 0, 255],
        );
      } else {
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.heavyImpact();
      }
    } else if (streak == 5) {
      // Level 5: Epic Fanfare (6s sound)
      // Sound: Starts at 0.4s
      // Haptic: 1.1 seconds of continuous vibration (Immediate response)
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [0, 1100], // 0ms delay, 1.1 seconds continuous
          intensities: [0, 255],
        );
      } else {
        await HapticFeedback.heavyImpact();
      }
    } else {
      // Level 6 (Ace): Legendary Swirl & Explosion (6s sound)
      // Sound: Rising magic swirl -> Massive explosion
      // Haptic: Swirl build-up (Immediate) + 0.8s Massive impact
      if (_hasCustomVibrationsSupport) {
        await Vibration.vibrate(
          pattern: [
            // 1. Rising swirl (starts immediately)
            0, 20, 100, 20, 90, 20, 80, 20, 70, 20, 60, 20, 50, 20, 40, 20, 30, 20, 20, 20, 10, 20,
            // 2. THE BIG BANG (lasts 0.8s)
            40, 800, 
          ], 
          intensities: [
            // Rising swirl
            0, 40, 0, 60, 0, 80, 0, 100, 0, 120, 0, 140, 0, 160, 0, 180, 0, 200, 0, 220, 0, 240,
            // EXPLOSION
            0, 255, 
          ],
        );
      } else {
        await HapticFeedback.heavyImpact();
      }
    }
  }

  /// Play haptic feedback for a wrong answer
  Future<void> playWrong() async {
    if (!_hasVibrator) return;
    
    // "Heavy & Dull" effect: Longer duration but medium intensity
    if (_hasCustomVibrationsSupport) {
      // A 400ms "thud" at 45% intensity
      await Vibration.vibrate(
        pattern: [0, 400],
        intensities: [0, 115],
      );
    } else {
      await HapticFeedback.heavyImpact();
    }
  }
}