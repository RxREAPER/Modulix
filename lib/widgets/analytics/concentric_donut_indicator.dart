import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A 3-ring concentric progress indicator representing multi-category completion
/// (e.g., Videos, QBank, and Notes).
class ConcentricDonutIndicator extends StatefulWidget {
  final double progress1; // Outer ring (0.0 to 1.0)
  final double progress2; // Middle ring (0.0 to 1.0)
  final double progress3; // Inner ring (0.0 to 1.0)
  final double size;
  final double ringWidth;
  final double ringSpacing;
  final Color? color1;
  final Color? color2;
  final Color? color3;
  final Widget? centerChild;

  const ConcentricDonutIndicator({
    super.key,
    required this.progress1,
    required this.progress2,
    required this.progress3,
    this.size = 56,
    this.ringWidth = 4.0,
    this.ringSpacing = 2.5,
    this.color1,
    this.color2,
    this.color3,
    this.centerChild,
  });

  @override
  State<ConcentricDonutIndicator> createState() => _ConcentricDonutIndicatorState();
}

class _ConcentricDonutIndicatorState extends State<ConcentricDonutIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ConcentricDonutIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress1 != widget.progress1 ||
        oldWidget.progress2 != widget.progress2 ||
        oldWidget.progress3 != widget.progress3) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c1 = widget.color1 ?? AppTheme.accentPrimary;
    final c2 = widget.color2 ?? AppTheme.accentSecondary;
    final c3 = widget.color3 ?? AppTheme.accentTertiary;
    final isDark = AppTheme.current.isDark;
    final trackBase = isDark ? Colors.white.withValues(alpha: 0.06) : AppTheme.borderLight;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final t = _animation.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _ConcentricRingsPainter(
                    p1: (widget.progress1.clamp(0.0, 1.0)) * t,
                    p2: (widget.progress2.clamp(0.0, 1.0)) * t,
                    p3: (widget.progress3.clamp(0.0, 1.0)) * t,
                    ringWidth: widget.ringWidth,
                    ringSpacing: widget.ringSpacing,
                    color1: c1,
                    color2: c2,
                    color3: c3,
                    trackColor: trackBase,
                  ),
                ),
                if (widget.centerChild != null)
                  widget.centerChild!
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c1,
                      boxShadow: [
                        BoxShadow(
                          color: c1.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConcentricRingsPainter extends CustomPainter {
  final double p1;
  final double p2;
  final double p3;
  final double ringWidth;
  final double ringSpacing;
  final Color color1;
  final Color color2;
  final Color color3;
  final Color trackColor;

  _ConcentricRingsPainter({
    required this.p1,
    required this.p2,
    required this.p3,
    required this.ringWidth,
    required this.ringSpacing,
    required this.color1,
    required this.color2,
    required this.color3,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width - ringWidth) / 2;

    _drawRing(canvas, center, maxRadius, p1, color1);
    _drawRing(canvas, center, maxRadius - (ringWidth + ringSpacing), p2, color2);
    _drawRing(canvas, center, maxRadius - 2 * (ringWidth + ringSpacing), p3, color3);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
    Color color,
  ) {
    if (radius <= 0) return;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_ConcentricRingsPainter oldDelegate) {
    return oldDelegate.p1 != p1 ||
        oldDelegate.p2 != p2 ||
        oldDelegate.p3 != p3 ||
        oldDelegate.ringWidth != ringWidth ||
        oldDelegate.ringSpacing != ringSpacing ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.color3 != color3 ||
        oldDelegate.trackColor != trackColor;
  }
}
