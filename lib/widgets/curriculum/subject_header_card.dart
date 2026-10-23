import 'package:flutter/material.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';
import '../animations/apple_pressable.dart';
import 'subject_sketch_icon.dart';

class SubjectHeaderCard extends StatelessWidget {
  final Subject subject;
  final int completedVideosCount;
  final int completedQBanksCount;
  final int completedNotesCount;
  final VoidCallback onTapAnalytics;

  const SubjectHeaderCard({
    super.key,
    required this.subject,
    required this.completedVideosCount,
    required this.completedQBanksCount,
    required this.completedNotesCount,
    required this.onTapAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final meta = subjectMeta(subject.id);
    final totalVids = subject.totalVideos;
    final totalQBanks = subject.totalQBanks;
    final progress = totalVids > 0 ? (completedVideosCount / totalVids) : 0.0;
    final percent = (progress * 100).round();

    return ApplePressable(
      onTap: onTapAnalytics,
      pressedScale: 0.98,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        decoration: AppTheme.sketchDecoration(
          borderRadius: 22,
          borderWidth: 1.8,
          shadowOffset: 4.0,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Medical Icon Badge + Title + Analytics CTA
            Row(
              children: [
                SubjectSketchIcon(
                  subjectId: subject.id,
                  color: meta.accent,
                  size: 38,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.displayName,
                        style: AppTypography.cardTitle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${subject.chapters.length} Units · ${subject.totalHours.toStringAsFixed(1)} Total Hours',
                        style: AppTypography.cardSubtitle(
                          fontSize: 11.5,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Analytics Badge Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 15, color: AppTheme.inkForeground),
                      const SizedBox(width: 4),
                      Text(
                        'Analytics',
                        style: AppTypography.compactAction(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3-Column Metrics Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.parchmentSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem(
                    label: 'VIDEOS',
                    value: '$completedVideosCount / $totalVids',
                    color: AppTheme.primaryBlue,
                  ),
                  Container(width: 1, height: 28, color: AppTheme.borderLight),
                  _metricItem(
                    label: 'Q-BANK TOPICS',
                    value: '$completedQBanksCount / $totalQBanks',
                    color: AppTheme.accentEmerald,
                  ),
                  Container(width: 1, height: 28, color: AppTheme.borderLight),
                  _metricItem(
                    label: 'COMPLETION',
                    value: '$percent%',
                    color: meta.accent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Linear Progress Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderLight, width: 1.2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: meta.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(totalVids - completedVideosCount)} left',
                  style: AppTypography.cardMeta(
                    fontSize: 11.0,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.metricLabel(
              fontSize: 9.5,
              letterSpacing: 0.6,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.metricValue(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
