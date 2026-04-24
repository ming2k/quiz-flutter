import 'package:audioplayers/audioplayers.dart';
import '../feedback_event.dart';
import '../sound_theme.dart';

/// The default sound theme.
///
/// Maps feedback events to the built-in asset sounds:
/// - [FeedbackEvent.correct] / [FeedbackEvent.streak1] → `streak_1.mp3`
/// - [FeedbackEvent.streak2] → `streak_2.mp3`
/// - [FeedbackEvent.streak3] → `streak_3.mp3`
/// - [FeedbackEvent.streak4] → `streak_4.mp3`
/// - [FeedbackEvent.streak5] → `streak_5.mp3`
/// - [FeedbackEvent.streakAce] → `streak_ace.mp3`
/// - [FeedbackEvent.wrong] → `wrong.mp3`
class DefaultSoundTheme implements SoundTheme {
  @override
  String get id => 'default';

  @override
  String get displayName => 'Default';

  AudioPlayer? _wrongPlayer;
  final List<AudioPlayer> _streakPlayers = [];
  AudioPlayer? _acePlayer;
  bool _initialized = false;

  @override
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
    await _wrongPlayer!.setSource(AssetSource('sounds/wrong.mp3'));
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

  @override
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
  }

  @override
  Future<void> play(FeedbackEvent event) async {
    if (!_initialized) return;

    final AudioPlayer? player = switch (event) {
      FeedbackEvent.wrong => _wrongPlayer,
      FeedbackEvent.correct || FeedbackEvent.streak1 => _streakPlayers.isNotEmpty ? _streakPlayers[0] : null,
      FeedbackEvent.streak2 => _streakPlayers.length > 1 ? _streakPlayers[1] : null,
      FeedbackEvent.streak3 => _streakPlayers.length > 2 ? _streakPlayers[2] : null,
      FeedbackEvent.streak4 => _streakPlayers.length > 3 ? _streakPlayers[3] : null,
      FeedbackEvent.streak5 => _streakPlayers.length > 4 ? _streakPlayers[4] : null,
      FeedbackEvent.streakAce => _acePlayer,
    };

    if (player != null) {
      await player.stop();
      await player.seek(Duration.zero);
      await player.resume();
    }
  }
}
