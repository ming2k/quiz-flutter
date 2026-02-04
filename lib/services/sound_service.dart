import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _correctPlayer;
  AudioPlayer? _wrongPlayer;
  bool _initialized = false;

  /// Initialize and pre-load sounds for instant playback
  Future<void> init() async {
    if (_initialized) return;

    // Configure audio context
    AudioPlayer.global.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: {},
      ),
    ));

    // Create dedicated players for each sound
    _correctPlayer = AudioPlayer();
    _wrongPlayer = AudioPlayer();

    // Pre-load the audio sources
    await Future.wait([
      _correctPlayer!.setSource(AssetSource('sounds/correct.wav')),
      _wrongPlayer!.setSource(AssetSource('sounds/wrong.wav')),
    ]);

    // Set players to stop at end so they can be replayed
    _correctPlayer!.setReleaseMode(ReleaseMode.stop);
    _wrongPlayer!.setReleaseMode(ReleaseMode.stop);

    _initialized = true;
  }

  /// Play correct answer sound
  Future<void> playCorrect() async {
    if (!_initialized || _correctPlayer == null) return;
    await _correctPlayer!.stop();
    await _correctPlayer!.seek(Duration.zero);
    await _correctPlayer!.resume();
  }

  /// Play wrong answer sound
  Future<void> playWrong() async {
    if (!_initialized || _wrongPlayer == null) return;
    await _wrongPlayer!.stop();
    await _wrongPlayer!.seek(Duration.zero);
    await _wrongPlayer!.resume();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _correctPlayer?.dispose();
    await _wrongPlayer?.dispose();
    _correctPlayer = null;
    _wrongPlayer = null;
    _initialized = false;
  }
}
