import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _wrongPlayer;
  final List<AudioPlayer> _streakPlayers = [];
  AudioPlayer? _acePlayer;
  bool _initialized = false;

  int _currentStreak = 0;

  int get currentStreak => _currentStreak;

  Future<void> init() async {
    if (_initialized) return;

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

    _wrongPlayer = AudioPlayer();
    await _wrongPlayer!.setSource(AssetSource('sounds/wrong.wav'));
    _wrongPlayer!.setReleaseMode(ReleaseMode.stop);

    // Load streak sounds (1-5)
    for (int i = 1; i <= 5; i++) {
      final player = AudioPlayer();
      await player.setSource(AssetSource('sounds/streak_$i.mp3'));
      player.setReleaseMode(ReleaseMode.stop);
      _streakPlayers.add(player);
    }

    // Load ace sound (for 6+ streak)
    _acePlayer = AudioPlayer();
    await _acePlayer!.setSource(AssetSource('sounds/streak_ace.mp3'));
    _acePlayer!.setReleaseMode(ReleaseMode.stop);

    _initialized = true;
  }

  /// Play correct answer sound based on current streak
  Future<void> playCorrect() async {
    if (!_initialized) return;

    _currentStreak++;

    AudioPlayer? player;
    if (_currentStreak >= 6) {
      player = _acePlayer;
    } else {
      player = _streakPlayers[_currentStreak - 1];
    }

    if (player != null) {
      await player.stop();
      await player.seek(Duration.zero);
      await player.resume();
    }
  }

  /// Play wrong answer sound and reset streak
  Future<void> playWrong() async {
    if (!_initialized || _wrongPlayer == null) return;

    _currentStreak = 0;

    await _wrongPlayer!.stop();
    await _wrongPlayer!.seek(Duration.zero);
    await _wrongPlayer!.resume();
  }

  /// Reset streak without playing sound (e.g., when changing questions manually)
  void resetStreak() {
    _currentStreak = 0;
  }

  Future<void> dispose() async {
    await _wrongPlayer?.dispose();
    for (final player in _streakPlayers) {
      await player.dispose();
    }
    await _acePlayer?.dispose();

    _wrongPlayer = null;
    _streakPlayers.clear();
    _acePlayer = null;
    _initialized = false;
    _currentStreak = 0;
  }
}
