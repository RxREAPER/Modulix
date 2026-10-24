import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Highly animated, cheerful and colourful trophy for 1st, 2nd, and 3rd place champions.
/// Features a gleaming light sweep, floating celebratory sparkles, soft metallic glow,
/// and gentle bobbing motion to make podium leaders feel prestigious and celebrated.
class CheerfulAnimatedTrophy extends StatefulWidget {
  final int rank; // 1 = Gold, 2 = Silver, 3 = Bronze
  final double size;

  const CheerfulAnimatedTrophy({
    super.key,
    required this.rank,
    this.size = 64.0,
  });

  @override
  State<CheerfulAnimatedTrophy> createState() => _CheerfulAnimatedTrophyState();
}

class _CheerfulAnimatedTrophyState extends State<CheerfulAnimatedTrophy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Smooth floating bob: up & down 3px
        final bob = math.sin(t * 2 * math.pi) * 3.0;

        return Transform.translate(
          offset: Offset(0, bob),
          child: SizedBox(
            width: widget.size * 1.25,
            height: widget.size * 1.25,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Radiant Ambient Halo
                _buildAmbientHalo(widget.rank, widget.size, t),

                // 2. Floating Celebratory Sparkles
                ..._buildSparkles(widget.rank, widget.size, t),

                // 3. Custom Painted Stylized Trophy with Gleam
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _TrophyPainter(
                    rank: widget.rank,
                    gleamProgress: t,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmbientHalo(int rank, double size, double t) {
    Color haloColor;
    switch (rank) {
      case 1:
        haloColor = const Color(0xFFF59E0B); // Amber Gold
        break;
      case 2:
        haloColor = const Color(0xFF94A3B8); // Slate Silver
        break;
      case 3:
      default:
        haloColor = const Color(0xFFEA580C); // Warm Bronze
        break;
    }

    final pulse = 0.15 + (math.sin(t * 2 * math.pi) * 0.08);

    return Container(
      width: size * 0.9,
      height: size * 0.9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: haloColor.withValues(alpha: pulse),
            blurRadius: size * 0.45,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles(int rank, double size, double t) {
    Color sparkleColor;
    switch (rank) {
      case 1:
        sparkleColor = const Color(0xFFFFE066);
        break;
      case 2:
        sparkleColor = const Color(0xFFE2E8F0);
        break;
      case 3:
      default:
        sparkleColor = const Color(0xFFFFEDD5);
        break;
    }

    // Sparkle 1: Top-Right
    final s1Phase = (t + 0.1) % 1.0;
    final s1Scale = (math.sin(s1Phase * math.pi)).clamp(0.0, 1.0);

    // Sparkle 2: Top-Left
    final s2Phase = (t + 0.55) % 1.0;
    final s2Scale = (math.sin(s2Phase * math.pi)).clamp(0.0, 1.0);

    // Sparkle 3: Bottom-Right
    final s3Phase = (t + 0.8) % 1.0;
    final s3Scale = (math.sin(s3Phase * math.pi)).clamp(0.0, 1.0);

    return [
      Positioned(
        top: size * 0.12,
        right: size * 0.12,
        child: Transform.scale(
          scale: s1Scale * 1.1,
          child: Transform.rotate(
            angle: t * math.pi,
            child: _SparkleStar(color: sparkleColor, size: size * 0.22),
          ),
        ),
      ),
      Positioned(
        top: size * 0.18,
        left: size * 0.10,
        child: Transform.scale(
          scale: s2Scale * 0.95,
          child: Transform.rotate(
            angle: -t * math.pi * 1.2,
            child: _SparkleStar(color: sparkleColor, size: size * 0.19),
          ),
        ),
      ),
      if (rank == 1) // Extra celebration for 1st place!
        Positioned(
          bottom: size * 0.22,
          right: size * 0.08,
          child: Transform.scale(
            scale: s3Scale * 0.85,
            child: Transform.rotate(
              angle: t * 1.5 * math.pi,
              child: _SparkleStar(color: sparkleColor, size: size * 0.16),
            ),
          ),
        ),
    ];
  }
}

/// 4-point twinkling star
class _SparkleStar extends StatelessWidget {
  final Color color;
  final double size;

  const _SparkleStar({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparkleStarPainter(color: color),
    );
  }
}

class _SparkleStarPainter extends CustomPainter {
  final Color color;

  _SparkleStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width / 2;
    final ry = size.height / 2;
    final innerR = rx * 0.25;

    path.moveTo(cx, cy - ry);
    path.quadraticBezierTo(cx, cy, cx + innerR, cy);
    path.lineTo(cx + rx, cy);
    path.quadraticBezierTo(cx, cy, cx, cy + innerR);
    path.lineTo(cx, cy + ry);
    path.quadraticBezierTo(cx, cy, cx - innerR, cy);
    path.lineTo(cx - rx, cy);
    path.quadraticBezierTo(cx, cy, cx, cy - innerR);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TrophyPainter extends CustomPainter {
  final int rank;
  final double gleamProgress;

  _TrophyPainter({
    required this.rank,
    required this.gleamProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette per rank
    final List<Color> mainGradientColors;
    final List<Color> rimColors;
    final List<Color> baseColors;
    final Color strokeColor;

    switch (rank) {
      case 1:
        // Vivid Royal Amber Gold
        mainGradientColors = const [
          Color(0xFFFFEE66),
          Color(0xFFFBBF24),
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ];
        rimColors = const [
          Color(0xFFFFFBEB),
          Color(0xFFFCD34D),
          Color(0xFFD97706),
        ];
        baseColors = const [
          Color(0xFF78350F),
          Color(0xFF92400E),
          Color(0xFF451A03),
        ];
        strokeColor = const Color(0xFFB45309);
        break;
      case 2:
        // Radiant Polished Silver & Ice Sheen
        mainGradientColors = const [
          Color(0xFFFFFFFF),
          Color(0xFFE2E8F0),
          Color(0xFFCBD5E1),
          Color(0xFF94A3B8),
        ];
        rimColors = const [
          Color(0xFFFFFFFF),
          Color(0xFFF1F5F9),
          Color(0xFF64748B),
        ];
        baseColors = const [
          Color(0xFF334155),
          Color(0xFF475569),
          Color(0xFF1E293B),
        ];
        strokeColor = const Color(0xFF64748B);
        break;
      case 3:
      default:
        // Warm Lustrous Burnished Copper Bronze
        mainGradientColors = const [
          Color(0xFFFFEDD5),
          Color(0xFFFB923C),
          Color(0xFFEA580C),
          Color(0xFFC2410C),
        ];
        rimColors = const [
          Color(0xFFFFF7ED),
          Color(0xFFFDBA74),
          Color(0xFF9A3412),
        ];
        baseColors = const [
          Color(0xFF431407),
          Color(0xFF7C2D12),
          Color(0xFF2E0C05),
        ];
        strokeColor = const Color(0xFF9A3412);
        break;
    }

    // ── 1. Pedestal Base ───────────────────────────────────────────────
    final baseRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.52,
      height: h * 0.16,
    );
    final baseRRect = RRect.fromRectAndRadius(baseRect, const Radius.circular(5));
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: baseColors,
      ).createShader(baseRect);
    canvas.drawRRect(baseRRect, basePaint);

    // Rank Number Plate on Base
    final plateRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.32,
      height: h * 0.10,
    );
    final plateRRect = RRect.fromRectAndRadius(plateRect, const Radius.circular(3));
    final platePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [mainGradientColors.first, mainGradientColors[1]],
      ).createShader(plateRect);
    canvas.drawRRect(plateRRect, platePaint);

    // Rank text on plate
    final textSpan = TextSpan(
      text: '$rank',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: h * 0.08,
        fontWeight: FontWeight.w900,
        color: baseColors.first,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(w * 0.5 - (textPainter.width / 2), h * 0.88 - (textPainter.height / 2)),
    );

    // ── 2. Stem ────────────────────────────────────────────────────────
    final stemPath = Path();
    stemPath.moveTo(w * 0.44, h * 0.62);
    stemPath.lineTo(w * 0.42, h * 0.80);
    stemPath.lineTo(w * 0.58, h * 0.80);
    stemPath.lineTo(w * 0.56, h * 0.62);
    stemPath.close();

    final stemPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [mainGradientColors[1], mainGradientColors.last],
      ).createShader(Rect.fromLTWH(w * 0.42, h * 0.62, w * 0.16, h * 0.18));
    canvas.drawPath(stemPath, stemPaint);

    // ── 3. Handles (Curved Wings) ──────────────────────────────────────
    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [mainGradientColors.first, mainGradientColors.last],
      ).createShader(Rect.fromLTWH(0, h * 0.15, w, h * 0.5));

    // Left handle
    final leftHandlePath = Path();
    leftHandlePath.moveTo(w * 0.32, h * 0.28);
    leftHandlePath.cubicTo(
      w * 0.06, h * 0.22,
      w * 0.06, h * 0.54,
      w * 0.36, h * 0.56,
    );
    canvas.drawPath(leftHandlePath, handlePaint);

    // Right handle
    final rightHandlePath = Path();
    rightHandlePath.moveTo(w * 0.68, h * 0.28);
    rightHandlePath.cubicTo(
      w * 0.94, h * 0.22,
      w * 0.94, h * 0.54,
      w * 0.64, h * 0.56,
    );
    canvas.drawPath(rightHandlePath, handlePaint);

    // ── 4. Main Trophy Cup Body ────────────────────────────────────────
    final cupPath = Path();
    cupPath.moveTo(w * 0.24, h * 0.20);
    cupPath.lineTo(w * 0.76, h * 0.20);
    cupPath.cubicTo(
      w * 0.76, h * 0.52,
      w * 0.66, h * 0.64,
      w * 0.50, h * 0.64,
    );
    cupPath.cubicTo(
      w * 0.34, h * 0.64,
      w * 0.24, h * 0.52,
      w * 0.24, h * 0.20,
    );
    cupPath.close();

    final cupRect = Rect.fromLTWH(w * 0.24, h * 0.20, w * 0.52, h * 0.44);
    final cupPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: mainGradientColors,
      ).createShader(cupRect);
    canvas.drawPath(cupPath, cupPaint);

    // ── 5. Gleam Sweep Animation across Cup ────────────────────────────
    canvas.save();
    canvas.clipPath(cupPath);

    // Sweep x goes from -0.3 to 1.3
    final sweepX = w * (-0.3 + (gleamProgress * 1.6));
    final gleamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(sweepX - (w * 0.2), h * 0.15, w * 0.4, h * 0.5));

    final gleamPath = Path()
      ..moveTo(sweepX - (w * 0.1), h * 0.15)
      ..lineTo(sweepX + (w * 0.1), h * 0.15)
      ..lineTo(sweepX + (w * 0.3), h * 0.70)
      ..lineTo(sweepX + (w * 0.1), h * 0.70)
      ..close();
    canvas.drawPath(gleamPath, gleamPaint);
    canvas.restore();

    // ── 6. Top Rim Oval ────────────────────────────────────────────────
    final rimRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.20),
      width: w * 0.52,
      height: h * 0.10,
    );
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: rimColors,
      ).createShader(rimRect);
    canvas.drawOval(rimRect, rimPaint);

    // Inner shadow in rim opening
    final innerRimRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.20),
      width: w * 0.44,
      height: h * 0.06,
    );
    final innerRimPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.35);
    canvas.drawOval(innerRimRect, innerRimPaint);

    // ── 7. Embossed Star or Crown Insignia on Cup Face ────────────────
    final insigniaCenter = Offset(w * 0.5, h * 0.40);
    final insigniaSize = w * 0.16;

    final insigniaPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 4 * math.pi / 5) - (math.pi / 2);
      final x = insigniaCenter.dx + (insigniaSize * 0.5 * math.cos(outerAngle));
      final y = insigniaCenter.dy + (insigniaSize * 0.5 * math.sin(outerAngle));
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, insigniaPaint);
  }

  @override
  bool shouldRepaint(covariant _TrophyPainter oldDelegate) =>
      oldDelegate.rank != rank || oldDelegate.gleamProgress != gleamProgress;
}
