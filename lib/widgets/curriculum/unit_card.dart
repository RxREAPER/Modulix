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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete
                ? AppTheme.accentPrimary.withValues(alpha: 0.35)
                : AppTheme.borderLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ① Top Row: Unit Pill + Trailing Chevron
            Row(
              children: [
                // Unit Index Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppTheme.accentSubtle
                        : accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isComplete
                          ? AppTheme.accentPrimary.withValues(alpha: 0.28)
                          : accent.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComplete) ...[
                        Icon(Icons.check_rounded, size: 12, color: AppTheme.accentPrimary),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'UNIT $unitNumberFormatted',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          fontFamily: 'monospace',
                          color: isComplete ? AppTheme.accentPrimary : accent,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Trailing Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ② Unit Title
            Text(
              chapter.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isComplete ? Colors.grey.shade700 : AppTheme.inkForeground,
              ),
            ),

            const SizedBox(height: 14),

            // ③ Sleek Progress Bar & Completion Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isComplete
                            ? AppTheme.accentPrimary
                            : accent,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isComplete
                          ? 'All completed'
                          : totalItems > 0
                              ? '$completedItems of $totalItems completed'
                              : '0 modules',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: isComplete ? AppTheme.accentPrimary : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
