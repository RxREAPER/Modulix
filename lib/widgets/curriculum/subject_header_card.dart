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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = meta.accent;
    final secondaryColor = HSLColor.fromColor(primaryColor)
        .withHue((HSLColor.fromColor(primaryColor).hue + 25) % 360)
        .withLightness(isDark ? 0.35 : 0.65)
        .toColor();

    return ApplePressable(
      onTap: onTapAnalytics,
      pressedScale: 0.98,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    primaryColor.withValues(alpha: 0.35),
                    secondaryColor.withValues(alpha: 0.20),
                    const Color(0xFF141923),
                  ]
                : [
                    primaryColor.withValues(alpha: 0.16),
                    secondaryColor.withValues(alpha: 0.08),
                    Colors.white,
                  ],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: isDark
                ? primaryColor.withValues(alpha: 0.28)
                : primaryColor.withValues(alpha: 0.20),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Ambient watermark circles
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Medical Icon Badge + Title + Analytics CTA
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? primaryColor.withValues(alpha: 0.25)
                              : Colors.white,
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SubjectSketchIcon(
                            subjectId: subject.id,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.displayName,
                              style: AppTypography.cardTitle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${subject.chapters.length} Units · ${subject.totalHours.toStringAsFixed(1)} Total Hours',
                              style: AppTypography.cardSubtitle(
                                fontSize: 12.0,
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Analytics Capsule Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.30),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bar_chart_rounded, size: 14, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Analytics',
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3-Column Metrics Capsule
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141923).withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : primaryColor.withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricItem(
                          label: 'VIDEOS',
                          value: '$completedVideosCount / $totalVids',
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        _metricItem(
                          label: 'Q-BANK TOPICS',
                          value: '$completedQBanksCount / $totalQBanks',
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        _metricItem(
                          label: 'COMPLETION',
                          value: '$percent%',
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Linear Progress Track
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : primaryColor.withValues(alpha: 0.12),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(totalVids - completedVideosCount)} left',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
