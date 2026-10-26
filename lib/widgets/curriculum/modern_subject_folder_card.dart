import 'package:flutter/material.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';
import '../animations/apple_pressable.dart';
import 'subject_sketch_icon.dart';

/// Modern Project / Dossier Folder Card for Curriculum Library.
/// Inspired by modern fluid mobile interfaces with generous 24px squircle curves,
/// rich tonal clinical gradient atmosphere, and seamless container expansion.
class ModernSubjectFolderCard extends StatelessWidget {
  final Subject subject;
  final double completion;
  final VoidCallback onTap;

  const ModernSubjectFolderCard({
    super.key,
    required this.subject,
    required this.completion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = subjectMeta(subject.id);
    final percent = (completion * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonious gradient colors based on subject's clinical accent
    final primaryColor = meta.accent;
    final secondaryColor = HSLColor.fromColor(primaryColor)
        .withHue((HSLColor.fromColor(primaryColor).hue + 25) % 360)
        .withLightness(isDark ? 0.35 : 0.65)
        .toColor();

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.96,
      pressedOpacity: 0.92,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    primaryColor.withValues(alpha: 0.40),
                    secondaryColor.withValues(alpha: 0.25),
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
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Abstract soft geometric ambient watermarks (Reference Image 2 & 3)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.10),
                ),
              ),
            ),
            Positioned(
              right: 15,
              top: 25,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryColor.withValues(alpha: isDark ? 0.10 : 0.08),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Medical Glyph Icon + Progress Capsule Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular Icon Pod
                      Container(
                        width: 38,
                        height: 38,
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
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SubjectSketchIcon(
                            subjectId: subject.id,
                            size: 22,
                            color: primaryColor,
                          ),
                        ),
                      ),

                      // Capsule Status Pill (Reference Image 2)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: percent == 100
                              ? (isDark
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFFD1FAE5))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: percent == 100
                                ? const Color(0xFF10B981)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : primaryColor.withValues(alpha: 0.25)),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (percent == 100) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: percent == 100
                                    ? (isDark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF065F46))
                                    : (isDark
                                        ? Colors.white
                                        : AppTheme.inkForeground),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Subject Title (Bold, Clean, Expressive)
                  Text(
                    subject.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.inkForeground,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Metadata: Total Lectures & Hours
                  Text(
                    '${subject.totalVideos} Lectures · ${subject.totalHours.toStringAsFixed(1)}h',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.70)
                          : AppTheme.mutedText,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Modern Continuous Progress Track with rounded pill cap
                  Container(
                    height: 5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: completion.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              secondaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
