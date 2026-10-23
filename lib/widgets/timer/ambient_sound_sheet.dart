import 'package:flutter/material.dart';
import '../../services/ambient_audio_service.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import 'medical_wave_visualizer.dart';

export '../../services/ambient_audio_service.dart';

/// Animated sound icon that pulses when audio is actively playing
class SoundHumIcon extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;
  const SoundHumIcon({super.key, required this.isActive, required this.color, this.size = 20});

  @override
  State<SoundHumIcon> createState() => _SoundHumIconState();
}

class _SoundHumIconState extends State<SoundHumIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulse = Tween<double>(begin: 0.85, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SoundHumIcon old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Icon(Icons.volume_off_rounded, color: widget.color, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * _pulse.value * 1.8,
              height: widget.size * _pulse.value * 1.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.15 * (1 - (_pulse.value - 0.85) / 0.33)),
              ),
            ),
            Icon(Icons.graphic_eq_rounded, color: widget.color, size: widget.size),
          ],
        );
      },
    );
  }
}

/// Interactive Multi-Track Ambient Audio Desk Mixer Sheet.
class AmbientSoundSheet extends StatefulWidget {
  final String activeSoundId;
  final ValueChanged<String>? onSelectSound;

  const AmbientSoundSheet({
    super.key,
    this.activeSoundId = 'none',
    this.onSelectSound,
  });

  static Future<void> show(
    BuildContext context, {
    String activeSoundId = 'none',
    ValueChanged<String>? onSelectSound,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 320),
        reverseDuration: Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      ),
      builder: (_) => AmbientSoundSheet(
        activeSoundId: activeSoundId,
        onSelectSound: onSelectSound,
      ),
    );
  }

  @override
  State<AmbientSoundSheet> createState() => _AmbientSoundSheetState();
}

class _AmbientSoundSheetState extends State<AmbientSoundSheet> {
  final AmbientAudioService _service = AmbientAudioService.instance;
  AmbientCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.paperBackground;
    final cardBg = AppTheme.cardWhite;
    final border = AppTheme.borderLight;
    final ink = AppTheme.inkForeground;
    final secondary = AppTheme.mutedText;
    final accent = AppTheme.primaryBlue;

    final activeTracks = _service.activeTrackIds;
    final isPlaying = _service.isPlaying;
    final isMuted = _service.isMuted;
    final masterVol = _service.masterVolume;
    final activePresetId = _service.activePresetId;

    final filteredSounds = _selectedCategory == null
        ? kAmbientSounds
        : kAmbientSounds.where((s) => s.category == _selectedCategory).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SoundHumIcon(
                    isActive: isPlaying,
                    color: accent,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Multi-Track Desk Mixer',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: activeTracks.isNotEmpty
                                ? accent.withValues(alpha: 0.14)
                                : border.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeTracks.isNotEmpty ? '${activeTracks.length} Active' : 'Silent',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: activeTracks.isNotEmpty ? accent : secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Layer ambient sounds & balance channel volumes',
                      style: TextStyle(fontSize: 11.5, color: secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Mute Button
              IconButton(
                tooltip: isMuted ? 'Unmute' : 'Mute',
                onPressed: activeTracks.isNotEmpty ? () => _service.toggleMute() : null,
                icon: Icon(
                  isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: isMuted ? Colors.orange : (activeTracks.isNotEmpty ? ink : secondary.withValues(alpha: 0.4)),
                  size: 22,
                ),
              ),

              // Clear All Action
              if (activeTracks.isNotEmpty)
                IconButton(
                  tooltip: 'Clear All Tracks',
                  onPressed: () {
                    _service.clearAll();
                    widget.onSelectSound?.call('none');
                  },
                  icon: Icon(Icons.close_rounded, color: secondary, size: 20),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // 1-Tap Atmosphere Presets Carousel
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: kAmbientPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = kAmbientPresets[index];
                final isSelected = activePresetId == preset.id;

                return ApplePressable(
                  pressedScale: 0.94,
                  onTap: () {
                    _service.applyPreset(preset);
                    widget.onSelectSound?.call(preset.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withValues(alpha: 0.12) : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accent : border,
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(preset.icon, size: 14, color: isSelected ? accent : secondary),
                        const SizedBox(width: 6),
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: isSelected ? accent : ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Master Volume Deck
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(
                  isMuted ? Icons.volume_off_rounded : Icons.volume_down_rounded,
                  size: 18,
                  color: secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Master',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ink),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: accent,
                      inactiveTrackColor: border,
                      thumbColor: accent,
                    ),
                    child: Slider(
                      value: masterVol,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) => _service.setMasterVolume(val),
                    ),
                  ),
                ),
                Text(
                  '${(masterVol * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Category Filter Chips
          Row(
            children: [
              _buildFilterChip('All', null, accent),
              const SizedBox(width: 6),
              _buildFilterChip('Weather', AmbientCategory.weather, accent),
              const SizedBox(width: 6),
              _buildFilterChip('Nature', AmbientCategory.nature, accent),
              const SizedBox(width: 6),
              _buildFilterChip('Deep Focus', AmbientCategory.focus, accent),
            ],
          ),

          const SizedBox(height: 12),

          // Sound Channels Scrollable Grid
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: filteredSounds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final snd = filteredSounds[index];
                final isSelected = activeTracks.contains(snd.id);
                final trackVol = _service.getTrackVolume(snd.id);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? accent.withValues(alpha: 0.06) : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? accent : border,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sound Row Header
                      InkWell(
                        onTap: () {
                          _service.toggleTrack(snd.id);
                          widget.onSelectSound?.call(snd.id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accent.withValues(alpha: 0.15)
                                    : AppTheme.parchmentSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  snd.icon,
                                  size: 19,
                                  color: isSelected ? accent : ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snd.label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                      color: isSelected ? accent : ink,
                                    ),
                                  ),
                                  Text(
                                    snd.subtitle,
                                    style: TextStyle(fontSize: 11, color: secondary),
                                  ),
                                ],
                              ),
                            ),

                            // Switch or Checkbox toggle
                            Transform.scale(
                              scale: 0.85,
                              child: Switch.adaptive(
                                value: isSelected,
                                activeTrackColor: accent,
                                onChanged: (_) {
                                  _service.toggleTrack(snd.id);
                                  widget.onSelectSound?.call(snd.id);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dedicated Channel Volume Slider when active
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 38),
                            Icon(Icons.volume_down_rounded, size: 14, color: accent),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: accent,
                                  inactiveTrackColor: border,
                                  thumbColor: accent,
                                ),
                                child: Slider(
                                  value: trackVol,
                                  min: 0.05,
                                  max: 1.0,
                                  onChanged: (val) => _service.setTrackVolume(snd.id, val),
                                ),
                              ),
                            ),
                            Text(
                              '${(trackVol * 100).round()}%',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Live Medical ECG / Waveform Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Text(
                  'Acoustic Wave',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: secondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: MedicalWaveVisualizer(
                    height: 24,
                    color: isPlaying ? accent : secondary,
                    showBaseline: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AmbientCategory? cat, Color accent) {
    final isSelected = _selectedCategory == cat;
    return ApplePressable(
      pressedScale: 0.94,
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? accent : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.inkForeground,
          ),
        ),
      ),
    );
  }
}

