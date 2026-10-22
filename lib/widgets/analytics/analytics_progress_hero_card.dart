import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A modern, refined progress hero card shared between Daily Tasks Analytics
/// and Module Plan Analytics.
class AnalyticsProgressHeroCard extends StatelessWidget {
  final double progress; // 0.0 .. 1.0
  final Color progressColor;
  final String tagLabel;
  final Color? tagColor;
  final String primaryValue;
  final String secondaryLabel;
  final Widget? statusBanner;

  const AnalyticsProgressHeroCard({
    super.key,
    required this.progress,
    required this.progressColor,
    required this.tagLabel,
    this.tagColor,
    required this.primaryValue,
    required this.secondaryLabel,
    this.statusBanner,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentInt = (clampedProgress * 100).round();
    final effectiveTagColor = tagColor ?? progressColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.cardWhite,
        borderRadius: 22,
        shadowOffset: 3.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Circular Gauge with generous breathing space ──
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _RadialGaugePainter(
                    progress: clampedProgress,
                    progressColor: progressColor,
                    trackColor: AppTheme.borderLight,
                    strokeWidth: 8.5,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$percentInt',
                              style: TextStyle(
                                fontSize: percentInt == 100 ? 22 : 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: AppTheme.inkForeground,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: progressColor,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // ── Primary Details & Metrics ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Small Tag Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: effectiveTagColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tagLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: effectiveTagColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Large Bold Metric
                    Text(
                      primaryValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.inkForeground,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Secondary Subtitle
                    Text(
                      secondaryLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Optional Status Banner (e.g. Pace Alert or Celebration) ──
          if (statusBanner != null) ...[
            const SizedBox(height: 14),
            statusBanner!,
          ],
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  const _RadialGaugePainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Active Progress Arc
    final activePaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
