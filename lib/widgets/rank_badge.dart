import 'package:flutter/material.dart';
import '../models/user_rank.dart';
import '../theme/app_theme.dart';

/// Minimalist, non-tag typographic micro-indicator for a doctor's career tier.
/// Follows strict editorial ink styling without bulky tag boxes or rainbow fills.
class RankBadge extends StatelessWidget {
  final UserLevel level;
  final bool showTitle;
  final double fontSize;
  final Color? color;

  const RankBadge({
    super.key,
    required this.level,
    this.showTitle = false,
    this.fontSize = 11.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.inkForeground.withValues(alpha: 0.75);

    if (!showTitle) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.35),
            width: 0.75,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          level.shortCode,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 0.3,
            color: effectiveColor,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.35),
              width: 0.75,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            level.shortCode,
            style: TextStyle(
              fontSize: fontSize - 1.0,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              letterSpacing: 0.4,
              color: effectiveColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          level.title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}
