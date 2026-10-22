import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

class AmbientSoundOption {
  final String id;
  final String label;
  final IconData icon;
  final String assetPath;
  final String subtitle;
  const AmbientSoundOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.assetPath,
    required this.subtitle,
  });
}

const kAmbientSounds = [
  AmbientSoundOption(
    id: 'none',
    label: 'Silent',
    icon: Icons.volume_off_rounded,
    assetPath: '',
    subtitle: 'Quiet study',
  ),
  AmbientSoundOption(
    id: 'forest',
    label: 'Forest Canopy',
    icon: Icons.forest_rounded,
    assetPath: '-forest-sound-.mp3',
    subtitle: 'Leaves & birds',
  ),
  AmbientSoundOption(
    id: 'stream',
    label: 'Quiet Stream',
    icon: Icons.water_rounded,
    assetPath: 'quiet-stream-9.mp3',
    subtitle: 'Running water',
  ),
  AmbientSoundOption(
    id: 'fireplace',
    label: 'Cozy Fireplace',
    icon: Icons.local_fire_department_rounded,
    assetPath: 'e-fireplace-.mp3',
    subtitle: 'Warm hearth crackle',
  ),
  AmbientSoundOption(
    id: 'rain',
    label: 'Gentle Rain',
    icon: Icons.water_drop_rounded,
    assetPath: 'lofi.mp3',
    subtitle: 'Soothing rain',
  ),
  AmbientSoundOption(
    id: 'whitenoise',
    label: 'Deep White Noise',
    icon: Icons.waves_rounded,
    assetPath: 'deep-white-noise-7.mp3',
    subtitle: 'Constant static',
  ),
  AmbientSoundOption(
    id: 'brownnoise',
    label: 'Brown Noise',
    icon: Icons.graphic_eq_rounded,
    assetPath: 't-brown-noise-.mp3',
    subtitle: 'Deep low rumble',
  ),
];

/// Animated sound icon that pulses when sound is active
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
            Transform.scale(
              scale: 0.9 + 0.1 * sin(_ctrl.value * pi),
              child: Icon(Icons.graphic_eq_rounded, color: widget.color, size: widget.size),
            ),
          ],
        );
      },
    );
  }
}

class AmbientSoundSheet extends StatefulWidget {
  final String activeSoundId;
  final ValueChanged<String> onSelectSound;

  const AmbientSoundSheet({super.key, required this.activeSoundId, required this.onSelectSound});

  static Future<void> show(
    BuildContext context, {
    required String activeSoundId,
    required ValueChanged<String> onSelectSound,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 300),
        reverseDuration: Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
      builder: (_) => AmbientSoundSheet(activeSoundId: activeSoundId, onSelectSound: onSelectSound),
    );
  }

  @override
  State<AmbientSoundSheet> createState() => _AmbientSoundSheetState();
}

class _AmbientSoundSheetState extends State<AmbientSoundSheet> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    final selectedIndex = kAmbientSounds.indexWhere((s) => s.id == widget.activeSoundId);
    double initialOffset = 0.0;
    if (selectedIndex > 0) {
      // 124 item width + 12 separator = 136.0 width per item
      initialOffset = (selectedIndex * 136.0) - 20.0;
      if (initialOffset < 0) initialOffset = 0.0;
    }
    _scrollCtrl = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
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

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(0, 14, 0, MediaQuery.of(context).viewInsets.bottom + 36),
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
          const SizedBox(height: 18),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SoundHumIcon(
                      isActive: widget.activeSoundId != 'none',
                      color: accent,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambient Sounds',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
                    ),
                    Text(
                      'Swipe horizontally to choose focus sound',
                      style: TextStyle(fontSize: 11, color: secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Horizontal X-axis scrollable list
          SizedBox(
            height: 140,
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: kAmbientSounds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final snd = kAmbientSounds[index];
                final isSelected = snd.id == widget.activeSoundId;

                return ApplePressable(
                  pressedScale: 0.94,
                  onTap: () {
                    widget.onSelectSound(snd.id);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 124,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withValues(alpha: 0.08) : cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? accent : border,
                        width: isSelected ? 2.0 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? accent.withValues(alpha: 0.18)
                              : const Color(0x080F172A),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accent.withValues(alpha: 0.15)
                                    : AppTheme.parchmentSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  snd.icon,
                                  size: 22,
                                  color: isSelected ? accent : ink,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent,
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          snd.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? accent : ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          snd.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10.5, color: secondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
