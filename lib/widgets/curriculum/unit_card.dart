import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

/// Minimalist, sleek Unit Card for clinical curriculum.
///
/// Features strictly requested:
/// - Prominent Unit Index & Title
/// - Clean linear progress bar with completion percentage
/// - Zero tags, zero chips, zero clutter
/// - No timer button on the card (timer is accessed inside the unit page)
class UnitCard extends StatelessWidget {
  final Subject subject;
  final Chapter chapter;
  final int unitIndex;
  final Map<String, dynamic> completedVideos;
  final Map<String, dynamic> completedQBanks;
  final Map<String, dynamic> completedNotes;
  final VoidCallback? onTap;

  const UnitCard({
    super.key,
    required this.subject,
    required this.chapter,
    required this.unitIndex,
    required this.completedVideos,
    required this.completedQBanks,
    required this.completedNotes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = subject.accent;

    final doneVideos = chapter.videos.where((v) => completedVideos.containsKey(v.id)).length;
    final doneQBanks = chapter.qbanks.where((q) => completedQBanks.containsKey(q.id)).length;
    final doneNotes = chapter.notes.where((n) => completedNotes.containsKey(n.id)).length;

    final totalItems = chapter.totalItems;
    final completedItems = doneVideos + doneQBanks + doneNotes;
    final isComplete = totalItems > 0 && completedItems == totalItems;
    final progress = totalItems > 0 ? (completedItems / totalItems).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();

    final unitNumberFormatted = (unitIndex + 1).toString().padLeft(2, '0');

    return ApplePressable(
      pressedScale: 0.98,
      hapticStyle: HapticStyle.selection,
      onTap: onTap ??
          () {
            context.push('/curriculum/${subject.id}/$unitIndex');
          },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isComplete
                ? AppTheme.accentPrimary.withValues(alpha: 0.35)
                : AppTheme.borderLight,
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Compact Unit Badge / Status indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isComplete
                    ? AppTheme.accentSubtle
                    : accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isComplete
                      ? AppTheme.accentPrimary.withValues(alpha: 0.30)
                      : accent.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: isComplete
                    ? Icon(Icons.check_rounded, size: 17, color: AppTheme.accentPrimary)
                    : Text(
                        unitNumberFormatted,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: accent,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Middle: Title in EB Garamond italic + Sleek Micro-progress & details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chapter.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headingStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isComplete ? Colors.grey.shade700 : AppTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: AppTheme.borderLight,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isComplete
                                    ? AppTheme.accentPrimary
                                    : accent,
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isComplete
                            ? 'All done'
                            : '$completedItems/$totalItems',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right: Percent + Chevron
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: isComplete ? AppTheme.accentPrimary : AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
