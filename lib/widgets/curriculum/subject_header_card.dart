import 'package:flutter/material.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';

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

    return GestureDetector(
      onTap: onTapAnalytics,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.sketchBorderColor, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x221C1C1C),
              offset: Offset(4, 5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Medical Icon Badge + Title + Analytics CTA
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: meta.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: meta.accent, width: 1.8),
                  ),
                  child: Center(
                    child: Icon(meta.icon, color: meta.accent, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${subject.chapters.length} Units · ${subject.totalHours.toStringAsFixed(1)} Total Hours',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Analytics Badge Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.highlightCoral,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.sketchBorderColor, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 16, color: AppTheme.inkForeground),
                      SizedBox(width: 4),
                      Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
                color: AppTheme.paperBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem(
                    label: 'VIDEOS',
                    value: '$completedVideosCount / $totalVids',
                    color: AppTheme.primaryBlue,
                  ),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
                  _metricItem(
                    label: 'Q-BANK TOPICS',
                    value: '$completedQBanksCount / $totalQBanks',
                    color: Colors.teal.shade700,
                  ),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
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
                      color: AppTheme.paperBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.sketchBorderColor, width: 1.2),
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
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
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
    );
  }
}
