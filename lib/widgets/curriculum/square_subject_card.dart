import 'package:flutter/material.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';
import '../animations/apple_pressable.dart';
import 'subject_sketch_icon.dart';

class SquareSubjectCard extends StatelessWidget {
  final Subject subject;
  final double completion;
  final VoidCallback onTap;

  const SquareSubjectCard({
    super.key,
    required this.subject,
    required this.completion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = subjectMeta(subject.id);
    final percent = (completion * 100).round();
    final totalHours = subject.totalHours;

    return RepaintBoundary(
      child: ApplePressable(
        onTap: onTap,
        pressedScale: 0.96,
        pressedOpacity: 0.88,
        borderRadius: BorderRadius.circular(20),
        child: Container(
        decoration: AppTheme.sketchDecoration(
          backgroundColor: AppTheme.cardWhite,
          borderRadius: 20,
          shadowOffset: 4.0,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Icon Bubble with medical badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: meta.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: meta.accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: SubjectSketchIcon(
                      subjectId: subject.id,
                      color: meta.accent,
                      size: 26,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: percent == 100
                        ? AppTheme.accentSubtle
                        : AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: percent == 100
                          ? AppTheme.accentPrimary
                          : AppTheme.borderLight,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: percent == 100
                          ? AppTheme.accentPrimary
                          : AppTheme.inkForeground,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Subject Title
            Text(
              subject.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkForeground,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),

            // Total videos & Total hours
            Text(
              '${subject.totalVideos} vids · ${totalHours.toStringAsFixed(1)} hrs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),

            const SizedBox(height: 8),

            // Sketch Progress Bar
            Container(
              height: 7,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.parchmentSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderLight, width: 1.2),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: completion.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animValue,
                    child: Container(
                      decoration: BoxDecoration(
                        color: meta.accent,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
