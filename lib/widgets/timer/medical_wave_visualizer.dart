import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/ambient_audio_service.dart';

/// Minimalist Medical ECG / Waveform visualizer that breathes and undulates
/// in sync with active ambient focus tracks.
class MedicalWaveVisualizer extends StatefulWidget {
  final Color? color;
  final double height;
  final bool showBaseline;

  const MedicalWaveVisualizer({
    super.key,
    this.color,
    this.height = 36.0,
    this.showBaseline = true,
  });

  @override
  State<MedicalWaveVisualizer> createState() => _MedicalWaveVisualizerState();
}

class _MedicalWaveVisualizerState extends State<MedicalWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final AmbientAudioService _audioService = AmbientAudioService.instance;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _audioService.addListener(_handleAudioStateChanged);
    if (_audioService.isPlaying) {
      _ctrl.repeat();
    }
  }

  void _handleAudioStateChanged() {
    if (!mounted) return;
    if (_audioService.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!_audioService.isPlaying && _ctrl.isAnimating) {
      _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 400));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _audioService.removeListener(_handleAudioStateChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.color ?? const Color(0xFF0D9488); // Clinical Teal
    final isPlaying = _audioService.isPlaying;
    final trackCount = _audioService.activeTrackIds.length;
    final masterVol = _audioService.masterVolume;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _ECGWavePainter(
            progress: _ctrl.value,
            color: waveColor,
            isPlaying: isPlaying,
            intensity: (masterVol * (0.6 + (trackCount * 0.15))).clamp(0.2, 1.0),
            showBaseline: widget.showBaseline,
          ),
        );
      },
    );
  }
}

class _ECGWavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPlaying;
  final double intensity;
  final bool showBaseline;

  _ECGWavePainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
    required this.intensity,
    required this.showBaseline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final width = size.width;

    // Optional subtle isoelectric baseline
    if (showBaseline) {
      final basePaint = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, midY), Offset(width, midY), basePaint);
    }

    if (!isPlaying && progress == 0.0) {
      // Quiet resting state: flat line with soft resting center glow
      final calmPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, midY), Offset(width, midY), calmPaint);
      return;
    }

    final wavePaint = Paint()
      ..color = color.withValues(alpha: isPlaying ? 0.85 : 0.40)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, midY);

    const step = 3.0;
    for (double x = 0; x <= width; x += step) {
      final phase = ((x / width) - progress) % 1.0;
      final normalizedPhase = phase < 0 ? phase + 1.0 : phase;

      double y = midY;
      if (isPlaying) {
        // Multi-frequency harmonic ambient wave + subtle ECG P-QRS-T complex
        if (normalizedPhase > 0.42 && normalizedPhase < 0.58) {
          // ECG complex zone
          final ecgPhase = (normalizedPhase - 0.42) / 0.16; // 0.0 to 1.0
          if (ecgPhase < 0.25) {
            // P wave
            y -= sin(ecgPhase * 4 * pi) * (size.height * 0.16 * intensity);
          } else if (ecgPhase >= 0.30 && ecgPhase <= 0.65) {
            // QRS spike
            final qrsPhase = (ecgPhase - 0.30) / 0.35;
            if (qrsPhase < 0.3) {
              y += (size.height * 0.12 * intensity); // Q dip
            } else if (qrsPhase < 0.7) {
              y -= (size.height * 0.42 * intensity); // R tall peak
            } else {
              y += (size.height * 0.18 * intensity); // S dip
            }
          } else {
            // T wave
            final tPhase = (ecgPhase - 0.65) / 0.35;
            y -= sin(tPhase * pi) * (size.height * 0.22 * intensity);
          }
        } else {
          // Gentle acoustic wave undulating
          final ripple1 = sin((normalizedPhase * 6 * pi) + (progress * 2 * pi)) * (size.height * 0.08 * intensity);
          final ripple2 = cos((normalizedPhase * 3 * pi)) * (size.height * 0.05 * intensity);
          y += ripple1 + ripple2;
        }
      }

      path.lineTo(x, y);
    }

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _ECGWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.intensity != intensity ||
        oldDelegate.color != color;
  }
}
