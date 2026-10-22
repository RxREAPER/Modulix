import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

/// Minimalist, high-yield Unit Card for clinical curriculum.
///
/// Features:
/// - Prominent Unit Index & Title
/// - Direct Unit Focus Timer link
/// - Content breakdown chips (Videos & duration, Q-Bank topics & MCQs, Notes)
/// - Visual completion progress bar & badge
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
    final totalVideos = chapter.totalVideos;
    final totalQBanks = chapter.totalQBanks;
    final totalNotes = chapter.totalNotes;
    final totalMcqs = chapter.totalMcqs;

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
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ① Top Row: Unit Pill + Quick Timer Link + Chevron
            Row(
              children: [
                // Unit Index Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppTheme.accentSubtle
                        : accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isComplete
                          ? AppTheme.accentPrimary.withValues(alpha: 0.3)
                          : accent.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComplete) ...[
                        Icon(Icons.check, size: 12, color: AppTheme.accentPrimary),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'UNIT $unitNumberFormatted',
                        style: TextStyle(
                          fontSize: 10,
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

                // Dedicated Focus Timer Link for this Unit
                ApplePressable(
                  pressedScale: 0.92,
                  hapticStyle: HapticStyle.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push(
                      '/timer',
                      extra: {
                        'subjectId': subject.id,
                        'subjectName': subject.displayName,
                        'topicTitle': chapter.name,
                        'chapterName': chapter.name,
                        'topicType': 'unit',
                        'durationMins': chapter.totalMinutes > 0
                            ? chapter.totalMinutes.round()
                            : 30,
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.borderLight,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: AppTheme.inkForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Timer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

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
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isComplete ? Colors.grey.shade700 : AppTheme.inkForeground,
              ),
            ),

            const SizedBox(height: 10),

            // ③ Content Representation Pills (Videos, Q-Bank, Notes)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Videos Pill
                if (totalVideos > 0)
                  _ContentPill(
                    icon: Icons.play_circle_outline_rounded,
                    label: chapter.durationLabel.isNotEmpty
                        ? '$totalVideos Videos · ${chapter.durationLabel}'
                        : '$totalVideos Videos',
                    doneLabel: doneVideos > 0 ? '$doneVideos/$totalVideos' : null,
                    color: AppTheme.accentPrimary,
                    isDone: totalVideos > 0 && doneVideos == totalVideos,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/curriculum/${subject.id}/$unitIndex?tab=videos');
                    },
                  ),

                // Q-Bank Pill
                if (totalQBanks > 0)
                  _ContentPill(
                    icon: Icons.quiz_outlined,
                    label: totalMcqs > 0
                        ? '$totalQBanks QB · $totalMcqs MCQs'
                        : '$totalQBanks Q-Bank Modules',
                    doneLabel: doneQBanks > 0 ? '$doneQBanks/$totalQBanks' : null,
                    color: const Color(0xFFF97316),
                    isDone: totalQBanks > 0 && doneQBanks == totalQBanks,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/curriculum/${subject.id}/$unitIndex?tab=qbank');
                    },
                  ),

                // Notes Pill
                if (totalNotes > 0)
                  _ContentPill(
                    icon: Icons.menu_book_rounded,
                    label: totalNotes == 1 ? 'High-Yield Note' : '$totalNotes Notes',
                    doneLabel: doneNotes > 0 ? '$doneNotes/$totalNotes' : null,
                    color: const Color(0xFF10B981),
                    isDone: totalNotes > 0 && doneNotes == totalNotes,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/curriculum/${subject.id}/$unitIndex?tab=notes');
                    },
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ④ Progress Bar & Completion Indicator
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
                          ? 'All modules completed'
                          : '$completedItems of $totalItems modules completed',
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

class _ContentPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? doneLabel;
  final Color color;
  final bool isDone;
  final VoidCallback? onTap;

  const _ContentPill({
    required this.icon,
    required this.label,
    this.doneLabel,
    required this.color,
    this.isDone = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pillWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDone
            ? AppTheme.accentSubtle
            : AppTheme.parchmentSurface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isDone
              ? AppTheme.accentPrimary.withValues(alpha: 0.25)
              : AppTheme.borderLight,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : icon,
            size: 12.5,
            color: isDone ? AppTheme.accentPrimary : color,
          ),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isDone ? Colors.grey.shade700 : AppTheme.inkForeground,
            ),
          ),
          if (doneLabel != null && !isDone) ...[
            const SizedBox(width: 4),
            Text(
              '($doneLabel)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: color,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return pillWidget;

    return ApplePressable(
      pressedScale: 0.94,
      hapticStyle: HapticStyle.selection,
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: pillWidget,
    );
  }
}
