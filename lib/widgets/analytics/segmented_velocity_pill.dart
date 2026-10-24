import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A segmented progress pill showing discrete blocks of task completion
/// along with an optional velocity trend chip.
class SegmentedVelocityPill extends StatelessWidget {
  final int totalSegments;
  final int completedSegments;
  final Color activeColor;
  final Color? trackColor;
  final String? velocityLabel;
  final bool isPositiveVelocity;

  const SegmentedVelocityPill({
    super.key,
    required this.totalSegments,
    required this.completedSegments,
    required this.activeColor,
    this.trackColor,
    this.velocityLabel,
    this.isPositiveVelocity = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTotal = totalSegments > 0 ? totalSegments : 1;
    final displaySegments = effectiveTotal.clamp(1, 10);
    final filledCount = effectiveTotal > 0
        ? ((completedSegments / effectiveTotal) * displaySegments).round().clamp(0, displaySegments)
        : 0;

    final isDark = AppTheme.current.isDark;
    final track = trackColor ??
        (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(displaySegments, (index) {
            final isFilled = index < filledCount;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(
                  right: index == displaySegments - 1 ? 0 : 3.5,
                ),
                decoration: BoxDecoration(
                  color: isFilled ? activeColor : track,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        if (velocityLabel != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositiveVelocity
                    ? Icons.trending_up_rounded
                    : Icons.trending_flat_rounded,
                size: 13,
                color: isPositiveVelocity ? activeColor : AppTheme.mutedText,
              ),
              const SizedBox(width: 4),
              Text(
                velocityLabel!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isPositiveVelocity ? activeColor : AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
