import 'package:flutter/material.dart';
import '../models/syllabus.dart';
import '../data/subjects_metadata.dart';
import '../theme/app_theme.dart';
import 'animations/animated_check_stroke.dart';
import 'animations/animated_strike_text.dart';
import 'animations/apple_pressable.dart';

/// A single lecture row in the chapter video list
class VideoTile extends StatelessWidget {
  final Video video;
  final int serialNumber;
  final bool isCompleted;
  final String? completedAt; // ISO timestamp or null
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback? onStartTimer;

  const VideoTile({
    super.key,
    required this.video,
    required this.serialNumber,
    required this.isCompleted,
    this.completedAt,
    required this.accentColor,
    required this.onToggle,
    this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tileColor = videoTileColor(video.id);

    final isDark = AppTheme.current.isDark;

    return ApplePressable(
      pressedScale: 0.98,
      pressedOpacity: 0.94,
      hapticStyle: HapticStyle.selection,
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCompleted
              ? (isDark ? const Color(0xFF0D281E) : const Color(0xFFE8F5E9))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                : AppTheme.borderLight.withValues(alpha: 0.7),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Serial Node / Completed Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.16)
                    : tileColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981).withValues(alpha: 0.45)
                      : tileColor.withValues(alpha: 0.28),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF10B981))
                    : Text(
                        serialNumber.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: tileColor,
                          fontSize: 12.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Title + duration badge with AnimatedStrikeText sweep
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedStrikeText(
                    text: video.title,
                    isStruck: isCompleted,
                    style: AppTypography.cardTitle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? AppTheme.mutedText : cs.onSurface,
                    ),
                    strikeColor: cs.onSurface.withValues(alpha: 0.4),
                    strikeThickness: 1.8,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (video.durationLabel.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: cs.onSurface.withValues(alpha: 0.50),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                video.durationLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isCompleted && completedAt != null) ...[
                        if (video.durationLabel.isNotEmpty)
                          const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 12,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCompletionDate(completedAt!),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onStartTimer != null) ...[
              ApplePressable(
                onTap: onStartTimer,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: AppTheme.inkForeground.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Circular Toggle Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : cs.outline.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: AnimatedCheckStroke(
                  checked: isCompleted,
                  size: 15,
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompletionDate(String isoTimestamp) {
    try {
      final t = DateTime.parse(isoTimestamp);
      final now = DateTime.now();
      final diff = now.difference(t).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return '${diff}d ago';
      return '${t.day}/${t.month}/${t.year}';
    } catch (_) {
      return '';
    }
  }
}
