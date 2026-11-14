import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AmbientCategory { weather, nature, focus }

class AmbientSoundOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String assetFileName;
  final AmbientCategory category;

  const AmbientSoundOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.assetFileName,
    required this.category,
  });
}

class AmbientPreset {
  final String id;
  final String name;
  final IconData icon;
  final Map<String, double> trackVolumes; // trackId -> volume (0.0 - 1.0)

  const AmbientPreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.trackVolumes,
  });
}

const kAmbientSounds = [
  // Weather & Water
  AmbientSoundOption(
    id: 'rain_window',
    label: 'Rain on Window',
    subtitle: 'Glass raindrops',
    icon: Icons.water_drop_rounded,
    assetFileName: 'rain_on_window.mp3',
    category: AmbientCategory.weather,
  ),
  AmbientSoundOption(
    id: 'rain_light',
    label: 'Gentle Drizzle',
    subtitle: 'Soft rain mist',
    icon: Icons.grain_rounded,
    assetFileName: 'rain_light.mp3',
    category: AmbientCategory.weather,
  ),
  AmbientSoundOption(
    id: 'creek',
    label: 'Quiet Creek',
    subtitle: 'Streaming stream',
    icon: Icons.water_rounded,
    assetFileName: 'forest_creek.mp3',
    category: AmbientCategory.weather,
  ),

  // Nature & Warmth
  AmbientSoundOption(
    id: 'fireplace',
    label: 'Cozy Fireplace',
    subtitle: 'Crackling embers',
    icon: Icons.local_fire_department_rounded,
    assetFileName: 'forest_fire.mp3',
    category: AmbientCategory.nature,
  ),
  AmbientSoundOption(
    id: 'forest_birds',
    label: 'Forest Canopy',
    subtitle: 'Leaves & birds',
    icon: Icons.forest_rounded,
    assetFileName: 'forest_birds.mp3',
    category: AmbientCategory.nature,
  ),
  AmbientSoundOption(
    id: 'wind',
    label: 'Mountain Wind',
    subtitle: 'Gentle breeze',
    icon: Icons.air_rounded,
    assetFileName: 'forest_wind.mp3',
    category: AmbientCategory.nature,
  ),

  // Deep Study & White Noise
  AmbientSoundOption(
    id: 'brown_noise',
    label: 'Deep Brown Noise',
    subtitle: 'Low-frequency rumble',
    icon: Icons.graphic_eq_rounded,
    assetFileName: 'meditation_brown_noise.mp3',
    category: AmbientCategory.focus,
  ),
  AmbientSoundOption(
    id: 'white_noise',
    label: 'Pure White Noise',
    subtitle: 'Steady static mask',
    icon: Icons.waves_rounded,
    assetFileName: 'meditation_white_noise.mp3',
    category: AmbientCategory.focus,
  ),
  AmbientSoundOption(
    id: 'keyboard',
    label: 'Library Keyboard',
    subtitle: 'Mechanical keys',
    icon: Icons.keyboard_rounded,
    assetFileName: 'city_keyboard.mp3',
    category: AmbientCategory.focus,
  ),
  AmbientSoundOption(
    id: 'singing_bowl',
    label: 'Singing Bowl',
    subtitle: 'Tibetan resonance',
    icon: Icons.self_improvement_rounded,
    assetFileName: 'meditation_bowl.mp3',
    category: AmbientCategory.focus,
  ),
];

const kAmbientPresets = [
  AmbientPreset(
    id: 'preset_library',
    name: 'Rainy Library',
    icon: Icons.local_library_rounded,
    trackVolumes: {
      'rain_window': 0.65,
      'brown_noise': 0.45,
      'keyboard': 0.30,
    },
  ),
  AmbientPreset(
    id: 'preset_cabin',
    name: 'Late-Night Cabin',
    icon: Icons.cabin_rounded,
    trackVolumes: {
      'fireplace': 0.70,
      'creek': 0.35,
      'wind': 0.25,
    },
  ),
  AmbientPreset(
    id: 'preset_sanctum',
    name: 'Deep Focus Sanctum',
    icon: Icons.self_improvement_rounded,
    trackVolumes: {
      'brown_noise': 0.80,
      'singing_bowl': 0.40,
    },
  ),
  AmbientPreset(
    id: 'preset_resident',
    name: "Resident's Lounge",
    icon: Icons.coffee_rounded,
    trackVolumes: {
      'rain_light': 0.50,
      'keyboard': 0.35,
      'forest_birds': 0.25,
    },
  ),
];

/// Multi-track ambient audio mixer service.
/// Supports simultaneous channels, volume faders, background playback, and call ducking.
class AmbientAudioService extends ChangeNotifier {
  static final AmbientAudioService instance = AmbientAudioService._();
  AmbientAudioService._() {
    _loadPersistedState();
    _initNoisyReceiver();
  }

  static const MethodChannel _noisyChannel = MethodChannel('com.modulix.app/audio_becoming_noisy');
  static const _prefActiveTracksKey = 'modulix_ambient_active_tracks_v1';
  static const _prefVolumesKey = 'modulix_ambient_volumes_v1';
  static const _prefMasterVolumeKey = 'modulix_ambient_master_vol_v1';

  void _initNoisyReceiver() {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      _noisyChannel.setMethodCallHandler((call) async {
        if (call.method == 'onAudioBecomingNoisy') {
          debugPrint('[AmbientAudioService] Audio becoming noisy (headphones unplugged). Auto-pausing ambient playback.');
          await onTimerPause();
        }
      });
    } catch (e) {
      debugPrint('[AmbientAudioService] _initNoisyReceiver error: $e');
    }
  }

  final Map<String, AudioPlayer> _players = {};
  final Set<String> _activeTrackIds = {};
  final Map<String, double> _volumes = {};
  double _masterVolume = 0.85;
  bool _isPlaying = false;
  bool _isMuted = false;
  String? _activePresetId;
  bool _contextConfigured = false;
  bool bypassNativeAudio = false;

  // Getters
  Set<String> get activeTrackIds => Set.unmodifiable(_activeTrackIds);
  Map<String, double> get trackVolumes => Map.unmodifiable(_volumes);
  double get masterVolume => _masterVolume;
  bool get isPlaying => _isPlaying && !_isMuted && _activeTrackIds.isNotEmpty;
  bool get isMuted => _isMuted;
  String? get activePresetId => _activePresetId;

  /// Backward-compatibility getter
  String get activeId {
    if (_activeTrackIds.isEmpty) return 'none';
    if (_activeTrackIds.length == 1) return _activeTrackIds.first;
    return 'multi';
  }

  double getTrackVolume(String soundId) {
    return _volumes[soundId] ?? 0.70;
  }

  Future<void> _ensureAudioContext() async {
    if (bypassNativeAudio || _contextConfigured) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
      _contextConfigured = true;
    } catch (_) {}
  }

  AudioPlayer? _getOrCreatePlayer(String soundId) {
    if (bypassNativeAudio) return null;
    return _players.putIfAbsent(soundId, () {
      final p = AudioPlayer();
      p.setReleaseMode(ReleaseMode.loop);
      return p;
    });
  }

  double _effectiveVolume(String soundId) {
    if (_isMuted) return 0.0;
    final trackVol = _volumes[soundId] ?? 0.70;
    return (trackVol * _masterVolume).clamp(0.0, 1.0);
  }

  /// Toggle an ambient track on or off in the multi-track mix.
  Future<void> toggleTrack(String soundId) async {
    if (_activeTrackIds.contains(soundId)) {
      await _stopTrack(soundId);
      _activeTrackIds.remove(soundId);
      _activePresetId = null;
    } else {
      final match = kAmbientSounds.where((s) => s.id == soundId).firstOrNull;
      if (match == null) return;
      _activeTrackIds.add(soundId);
      _activePresetId = null;
      _isPlaying = true;
      await _startTrack(soundId);
    }
    _savePersistedState();
    notifyListeners();
  }

  /// Set volume for a specific channel (0.0 to 1.0).
  Future<void> setTrackVolume(String soundId, double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    _volumes[soundId] = clamped;
    if (_activeTrackIds.contains(soundId)) {
      final player = _players[soundId];
      if (player != null) {
        try {
          await player.setVolume(_effectiveVolume(soundId));
        } catch (_) {}
      }
    }
    _savePersistedState();
    notifyListeners();
  }

  /// Set the overall master volume for all ambient tracks.
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    for (final id in _activeTrackIds) {
      final player = _players[id];
      if (player != null) {
        try {
          await player.setVolume(_effectiveVolume(id));
        } catch (_) {}
      }
    }
    _savePersistedState();
    notifyListeners();
  }

  /// Toggle temporary mute on or off without discarding active mix.
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    for (final id in _activeTrackIds) {
      final player = _players[id];
      if (player != null) {
        try {
          await player.setVolume(_effectiveVolume(id));
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  /// Apply a pre-calibrated multi-track clinical atmosphere.
  Future<void> applyPreset(AmbientPreset preset) async {
    _activePresetId = preset.id;
    // Stop tracks not in preset
    final tracksToStop = _activeTrackIds.where((id) => !preset.trackVolumes.containsKey(id)).toList();
    for (final id in tracksToStop) {
      await _stopTrack(id);
      _activeTrackIds.remove(id);
    }

    // Set volumes and start tracks in preset
    for (final entry in preset.trackVolumes.entries) {
      _volumes[entry.key] = entry.value;
      _activeTrackIds.add(entry.key);
      await _startTrack(entry.key);
    }

    _isPlaying = true;
    _isMuted = false;
    _savePersistedState();
    notifyListeners();
  }

  Future<void> _startTrack(String soundId) async {
    final match = kAmbientSounds.where((s) => s.id == soundId).firstOrNull;
    if (match == null) return;
    if (bypassNativeAudio) return;

    try {
      await _ensureAudioContext();
      final player = _getOrCreatePlayer(soundId);
      if (player != null) {
        await player.setVolume(_effectiveVolume(soundId));
        await player.setReleaseMode(ReleaseMode.loop);
        if (player.state == PlayerState.paused) {
          await player.resume();
        } else if (player.state != PlayerState.playing) {
          await player.play(AssetSource('audio/${match.assetFileName}'));
        }
      }
    } catch (_) {}
  }

  Future<void> _stopTrack(String soundId) async {
    if (bypassNativeAudio) return;
    final player = _players[soundId];
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  /// Legacy single-track play API for backwards compatibility.
  Future<void> playSound(String soundId) async {
    if (soundId == 'none') {
      await clearAll();
      return;
    }

    final match = kAmbientSounds.where((s) => s.id == soundId).firstOrNull;
    if (match == null) return;

    // Stop all other tracks
    for (final id in _activeTrackIds.toList()) {
      if (id != soundId) {
        await _stopTrack(id);
        _activeTrackIds.remove(id);
      }
    }

    _activeTrackIds.add(soundId);
    _activePresetId = null;
    _isPlaying = true;
    _isMuted = false;
    await _startTrack(soundId);
    _savePersistedState();
    notifyListeners();
  }

  /// Starts or resumes playback when timer begins or resumes.
  Future<void> onTimerStartOrResume() async {
    if (_activeTrackIds.isEmpty) return;
    _isPlaying = true;
    for (final soundId in _activeTrackIds) {
      await _startTrack(soundId);
    }
    notifyListeners();
  }

  /// Pauses playback when timer is paused or ends.
  Future<void> onTimerPause() async {
    _isPlaying = false;
    if (!bypassNativeAudio) {
      for (final player in _players.values) {
        try {
          await player.pause();
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  /// Stop all active tracks and reset mix.
  Future<void> clearAll() async {
    _isPlaying = false;
    _activePresetId = null;
    if (!bypassNativeAudio) {
      for (final player in _players.values) {
        try {
          await player.stop();
        } catch (_) {}
      }
    }
    _activeTrackIds.clear();
    _savePersistedState();
    notifyListeners();
  }

  /// Alias for clearAll.
  Future<void> stop() => clearAll();

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeList = prefs.getStringList(_prefActiveTracksKey);
      if (activeList != null && activeList.isNotEmpty) {
        _activeTrackIds.addAll(activeList);
      }

      final volumesJson = prefs.getString(_prefVolumesKey);
      if (volumesJson != null) {
        final decoded = jsonDecode(volumesJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final v = (entry.value as num?)?.toDouble();
          if (v != null) _volumes[entry.key] = v;
        }
      }

      final master = prefs.getDouble(_prefMasterVolumeKey);
      if (master != null) {
        _masterVolume = master.clamp(0.0, 1.0);
      }
    } catch (_) {}
  }

  Future<void> _savePersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefActiveTracksKey, _activeTrackIds.toList());
      await prefs.setString(_prefVolumesKey, jsonEncode(_volumes));
      await prefs.setDouble(_prefMasterVolumeKey, _masterVolume);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    super.dispose();
  }
}
