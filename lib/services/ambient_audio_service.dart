import 'package:audioplayers/audioplayers.dart';
import '../widgets/timer/ambient_sound_sheet.dart';

class AmbientAudioService {
  static final AmbientAudioService instance = AmbientAudioService._();
  AmbientAudioService._();

  final AudioPlayer _player = AudioPlayer();
  String _activeId = 'none';
  String get activeId => _activeId;
  bool _contextConfigured = false;

  Future<void> _ensureAudioContext() async {
    if (_contextConfigured) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
      _contextConfigured = true;
    } catch (_) {}
  }

  Future<void> playSound(String soundId) async {
    _activeId = soundId;
    await _player.stop();
    if (soundId == 'none') return;

    final match = kAmbientSounds.where((s) => s.id == soundId).firstOrNull;
    if (match == null || match.assetPath.isEmpty) return;

    try {
      await _ensureAudioContext();
      await _player.setVolume(0.85);
      await _player.setReleaseMode(ReleaseMode.loop);
      // audioplayers AssetSource prepends 'assets/' by default
      await _player.play(AssetSource('audio/${match.assetPath}'));
    } catch (e) {
      // Audio error handled silently
    }
  }

  Future<void> stop() async {
    _activeId = 'none';
    await _player.stop();
  }

  void dispose() => _player.dispose();
}
