import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ParticleType { heart, sparkle, paw }

class NoriParticle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double size;
  final ParticleType type;
  final Color color;
  final DateTime createdAt;
  final double lifespanMs;

  NoriParticle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.type,
    required this.color,
    required this.createdAt,
    this.lifespanMs = 900,
  });

  double get progress {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds;
    return (elapsed / lifespanMs).clamp(0.0, 1.0);
  }

  bool get isDead => progress >= 1.0;
}

class NoriParticleController extends ChangeNotifier {
  final List<NoriParticle> _particles = [];
  final math.Random _random = math.Random();

  List<NoriParticle> get particles => _particles;

  void spawnBurst(double x, double y, {int count = 5}) {
    final now = DateTime.now();
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * 1.4;
      final speed = 40.0 + _random.nextDouble() * 60.0;
      final typeIndex = _random.nextInt(3);
      final type = ParticleType.values[typeIndex];

      Color color;
      if (type == ParticleType.heart) {
        color = const Color(0xFFFE5F55); // Modulix coral
      } else if (type == ParticleType.sparkle) {
        color = const Color(0xFFFFD166); // warm gold
      } else {
        color = const Color(0xFF4F46E5); // indigo
      }

      _particles.add(
        NoriParticle(
          startX: x + (_random.nextDouble() - 0.5) * 20,
          startY: y + (_random.nextDouble() - 0.5) * 10,
          velocityX: math.cos(angle) * speed,
          velocityY: math.sin(angle) * speed,
          size: 10.0 + _random.nextDouble() * 8.0,
          type: type,
          color: color,
          createdAt: now,
          lifespanMs: 700 + _random.nextDouble() * 400,
        ),
      );
    }
    notifyListeners();
  }

  void cleanup() {
    _particles.removeWhere((p) => p.isDead);
    notifyListeners();
  }
}

class NoriParticleOverlay extends StatelessWidget {
  final NoriParticleController controller;

  const NoriParticleOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        controller.cleanup();
        if (controller.particles.isEmpty) return const SizedBox.shrink();

        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(controller.particles),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<NoriParticle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = p.progress;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final currentX = p.startX + (p.velocityX * t * 0.8) + math.sin(t * math.pi * 3) * 6;
      final currentY = p.startY + (p.velocityY * t * 0.8) - (t * 20);
      final scale = 1.0 - 0.3 * t;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.scale(scale);

      if (p.type == ParticleType.heart) {
        _drawHeart(canvas, p.size, paint);
      } else if (p.type == ParticleType.sparkle) {
        _drawSparkle(canvas, p.size, paint);
      } else {
        _drawPaw(canvas, p.size, paint);
      }

      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final w = size;
    final h = size;
    path.moveTo(w / 2, h * 0.8);
    path.cubicTo(w * 0.1, h * 0.5, 0, h * 0.2, w * 0.25, 0);
    path.cubicTo(w * 0.45, 0, w / 2, h * 0.2, w / 2, h * 0.3);
    path.cubicTo(w / 2, h * 0.2, w * 0.55, 0, w * 0.75, 0);
    path.cubicTo(w, h * 0.2, w * 0.9, h * 0.5, w / 2, h * 0.8);
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final half = size / 2;
    path.moveTo(half, 0);
    path.quadraticBezierTo(half, half, size, half);
    path.quadraticBezierTo(half, half, half, size);
    path.quadraticBezierTo(half, half, 0, half);
    path.quadraticBezierTo(half, half, half, 0);
    canvas.drawPath(path, paint);
  }

  void _drawPaw(Canvas canvas, double size, Paint paint) {
    // Main pad
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size / 2, size * 0.65), width: size * 0.6, height: size * 0.45),
      paint,
    );
    // 3 toe dots
    final toeR = size * 0.12;
    canvas.drawCircle(Offset(size * 0.25, size * 0.3), toeR, paint);
    canvas.drawCircle(Offset(size * 0.5, size * 0.2), toeR, paint);
    canvas.drawCircle(Offset(size * 0.75, size * 0.3), toeR, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
