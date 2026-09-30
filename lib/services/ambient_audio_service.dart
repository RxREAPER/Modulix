import 'package:audioplayers/audioplayers.dart';
import '../widgets/timer/ambient_sound_sheet.dart';

class AmbientAudioService {
  static final AmbientAudioService instance = AmbientAudioService._();
  AmbientAudioService._();

  final AudioPlayer _player = AudioPlayer();
  String _activeId = 'none';
  String get activeId => _activeId;

  Future<void> playSound(String soundId) async {
    _activeId = soundId;
    await _player.stop();
    if (soundId == 'none') return;

    final match = kAmbientSounds.where((s) => s.id == soundId).firstOrNull;
    if (match == null || match.assetPath.isEmpty) return;

    try {
      await _player.setVolume(0.85);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(match.assetPath));
    } catch (e) {
      // debugPrint('Audio error: $e');
    }
  }

  Future<void> stop() async {
    _activeId = 'none';
    await _player.stop();
  }

  void dispose() => _player.dispose();
}
