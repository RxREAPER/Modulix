import 'package:flutter/material.dart';
import 'dart:math';

class AmbientSoundOption {
  final String id;
  final String label;
  final String emoji;
  final String assetPath;
  const AmbientSoundOption({required this.id, required this.label, required this.emoji, required this.assetPath});
}

const kAmbientSounds = [
  AmbientSoundOption(id: 'none', label: 'Silent', emoji: '🔇', assetPath: ''),
  AmbientSoundOption(id: 'rain', label: 'Gentle Rain', emoji: '🌧️', assetPath: 'audio/rain.mp3'),
  AmbientSoundOption(id: 'lofi', label: 'Lo-Fi Chill', emoji: '☕', assetPath: 'audio/lofi.mp3'),
  AmbientSoundOption(id: 'waves', label: 'Ocean Waves', emoji: '🌊', assetPath: 'audio/waves.mp3'),
  AmbientSoundOption(id: 'fire', label: 'Cozy Fireplace', emoji: '🔥', assetPath: 'audio/fire.mp3'),
  AmbientSoundOption(id: 'forest', label: 'Forest Birds', emoji: '🌿', assetPath: 'audio/birds.mp3'),
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
            // Outer hum ring
            Container(
              width: widget.size * _pulse.value * 1.8,
              height: widget.size * _pulse.value * 1.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.15 * (1 - (_pulse.value - 0.85) / 0.33)),
              ),
            ),
            // Inner icon
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

class AmbientSoundSheet extends StatelessWidget {
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
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => AmbientSoundSheet(activeSoundId: activeSoundId, onSelectSound: onSelectSound),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 16),
          Row(
            children: [
              SoundHumIcon(isActive: activeSoundId != 'none', color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text('Ambient Focus Sounds', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Nature & ambient sounds to help you focus', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          const SizedBox(height: 18),
          ...kAmbientSounds.map((snd) {
            final isSelected = snd.id == activeSoundId;
            return GestureDetector(
              onTap: () {
                onSelectSound(snd.id);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.white.withOpacity(0.6) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(snd.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Text(snd.label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade300, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    if (isSelected) SoundHumIcon(isActive: true, color: Colors.white, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
