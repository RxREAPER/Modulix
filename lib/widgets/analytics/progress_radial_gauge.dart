import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A minimalist circular arc radial progress gauge with rounded caps.
class ProgressRadialGauge extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? trackColor;
  final Widget? centerChild;
  final bool showPercentageText;
  final TextStyle? percentageStyle;

  const ProgressRadialGauge({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth = 5.0,
    this.progressColor,
    this.trackColor,
    this.centerChild,
    this.showPercentageText = true,
    this.percentageStyle,
  });

  @override
  State<ProgressRadialGauge> createState() => _ProgressRadialGaugeState();
}

class _ProgressRadialGaugeState extends State<ProgressRadialGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _oldProgress = widget.progress.clamp(0.0, 1.0);
    _controller.forward();
  }

  @override
  void didUpdateWidget(ProgressRadialGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _oldProgress,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _oldProgress = widget.progress.clamp(0.0, 1.0);
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
    final activeColor = widget.progressColor ?? AppTheme.accentPrimary;
    final track = widget.trackColor ??
        (AppTheme.current.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppTheme.borderLight);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final currentVal = _animation.value;
            final pct = (currentVal * 100).round();

            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RadialArcPainter(
                    progress: currentVal,
                    strokeWidth: widget.strokeWidth,
                    progressColor: activeColor,
                    trackColor: track,
                  ),
                ),
                if (widget.centerChild != null)
                  widget.centerChild!
                else if (widget.showPercentageText)
                  Text(
                    '$pct%',
                    style: widget.percentageStyle ??
                        TextStyle(
                          fontSize: widget.size * 0.24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          fontFamily: 'monospace',
                          color: AppTheme.inkForeground,
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

class _RadialArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  _RadialArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Active arc starting from top (-pi / 2)
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RadialArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
