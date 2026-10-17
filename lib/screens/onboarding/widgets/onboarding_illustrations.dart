import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/subjects_metadata.dart';
import '../../../models/daily_desk_task.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/curriculum/subject_sketch_icon.dart';
import '../../../widgets/study_task_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 1. WELCOME DESK ILLUSTRATION — Exact Home Screen Study Desk Hero Card
// ══════════════════════════════════════════════════════════════════════════════

class WelcomeDeskIllustration extends StatefulWidget {
  const WelcomeDeskIllustration({super.key});

  @override
  State<WelcomeDeskIllustration> createState() =>
      _WelcomeDeskIllustrationState();
}

class _WelcomeDeskIllustrationState extends State<WelcomeDeskIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _colonCtrl;

  @override
  void initState() {
    super.initState();
    _colonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _colonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft ambient radial glow
          Positioned(
            top: 20,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFEF3C7).withValues(alpha: 0.55),
                    const Color(0xFFFEF3C7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Exact Home Screen Study Desk Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEADBCE), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  offset: Offset(0, 4),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: Color(0x06000000),
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row: Pace Badge & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFC7D2FE), width: 1.0),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: Color(0xFF4F46E5)),
                          SizedBox(width: 5),
                          Text(
                            'MORNING ROTATION',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Thursday, 15 Oct',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Clock & Start Focus Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'STUDY DESK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '08',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: AppTheme.inkForeground,
                                height: 1.0,
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _colonCtrl,
                              builder: (context, _) => Opacity(
                                opacity: _colonCtrl.value > 0.4 ? 1.0 : 0.2,
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    color: AppTheme.inkForeground,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '30',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: AppTheme.inkForeground,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'AM',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Start Focus Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppTheme.inkForeground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              size: 15, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'START FOCUS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. DAILY TASKS ILLUSTRATION — Exact Home Screen Today's Tasks in Action
// ══════════════════════════════════════════════════════════════════════════════

class DailyTasksIllustration extends StatefulWidget {
  const DailyTasksIllustration({super.key});

  @override
  State<DailyTasksIllustration> createState() => _DailyTasksIllustrationState();
}

class _DailyTasksIllustrationState extends State<DailyTasksIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _actionCtrl;

  @override
  void initState() {
    super.initState();
    // 4.2-second complete interaction loop
    _actionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _actionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _actionCtrl,
      builder: (context, _) {
        final t = _actionCtrl.value;

        // Keyframe timeline:
        // 0.00 -> 0.25 (0 to 1050ms): Uncompleted, finger approaches
        // 0.25 -> 0.32 (1050 to 1350ms): Finger taps down
        // 0.32 -> 0.85 (1350 to 3570ms): Task 1 is checked & completed
        // 0.85 -> 1.00 (3570 to 4200ms): Reset back to uncompleted
        final isTaskDone = t >= 0.30 && t < 0.88;
        final completedCount = isTaskDone ? 1 : 0;

        // Tap cursor position & scale
        final double cursorOpacity;
        final double cursorScale;
        final double cursorX;
        final double cursorY;

        if (t < 0.10) {
          cursorOpacity = (t / 0.10).clamp(0.0, 1.0);
          cursorX = 140.0;
          cursorY = 110.0;
          cursorScale = 1.0;
        } else if (t < 0.26) {
          final progress = (t - 0.10) / 0.16;
          cursorOpacity = 1.0;
          cursorX =
              140.0 + (32.0 - 140.0) * Curves.easeOutCubic.transform(progress);
          cursorY =
              110.0 + (74.0 - 110.0) * Curves.easeOutCubic.transform(progress);
          cursorScale = 1.0;
        } else if (t < 0.32) {
          // Tapping down
          cursorOpacity = 1.0;
          cursorX = 32.0;
          cursorY = 74.0;
          cursorScale = 0.82;
        } else if (t < 0.45) {
          // Releasing and lingering
          cursorOpacity = (1.0 - (t - 0.32) / 0.13).clamp(0.0, 1.0);
          cursorX = 32.0;
          cursorY = 74.0;
          cursorScale = 1.0;
        } else {
          cursorOpacity = 0.0;
          cursorX = 32.0;
          cursorY = 74.0;
          cursorScale = 1.0;
        }

        return SizedBox(
          width: 350,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Ambient glow behind tasks
              Positioned(
                top: 10,
                left: 30,
                right: 30,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE0E7FF).withValues(alpha: 0.45),
                        const Color(0xFFE0E7FF).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Exact Today's Tasks Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's tasks",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkForeground,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '$completedCount of 2 completed',
                              key: ValueKey(completedCount),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isTaskDone
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isTaskDone
                                    ? const Color(0xFF059669)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: AppTheme.sketchDecoration(
                          backgroundColor: Colors.white,
                          borderRadius: 10,
                          borderWidth: 1.4,
                          shadowOffset: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 14, color: AppTheme.inkForeground),
                            const SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Real StudyTaskCard 1 (Animated Toggle Target)
                  StudyTaskCard(
                    id: 'preview_task_1',
                    title: 'Study for 4 Hours',
                    category: TaskCategory.general,
                    customSubtitle: 'Goal #1',
                    isCompleted: isTaskDone,
                    onToggle: () {},
                  ),

                  // Real StudyTaskCard 2 (Static In-Progress Target)
                  const StudyTaskCard(
                    id: 'preview_task_2',
                    title: 'Watch 2 Medicine Lectures',
                    category: TaskCategory.video,
                    customSubtitle: 'Goal #2',
                    isCompleted: false,
                    onToggle: _emptyCallback,
                  ),
                ],
              ),

              // Animated Simulated Tap Cursor
              if (cursorOpacity > 0.0)
                Positioned(
                  left: cursorX,
                  top: cursorY,
                  child: Opacity(
                    opacity: cursorOpacity,
                    child: Transform.scale(
                      scale: cursorScale,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                          border: Border.all(
                            color: AppTheme.primaryBlue,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.touch_app_rounded,
                            size: 18,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

void _emptyCallback() {}

// ══════════════════════════════════════════════════════════════════════════════
// 3. CURRICULUM MODULES ILLUSTRATION — Real Subject Card & Live Progress Bars
// ══════════════════════════════════════════════════════════════════════════════

class CurriculumModulesIllustration extends StatefulWidget {
  const CurriculumModulesIllustration({super.key});

  @override
  State<CurriculumModulesIllustration> createState() =>
      _CurriculumModulesIllustrationState();
}

class _CurriculumModulesIllustrationState
    extends State<CurriculumModulesIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    // 4.0-second smooth progress loop
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const subjectId = 'pharmacology';
    final meta = subjectMeta(subjectId);

    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (context, _) {
        final t = _progressCtrl.value;

        // Progress curve: 0 to 0.45 fills, 0.45 to 0.85 holds, 0.85 to 1.0 resets
        final double curveFraction;
        if (t < 0.45) {
          curveFraction = Curves.easeOutCubic.transform(t / 0.45);
        } else if (t < 0.85) {
          curveFraction = 1.0;
        } else {
          curveFraction = 1.0 - Curves.easeInOut.transform((t - 0.85) / 0.15);
        }

        final videoProgress = 0.75 * curveFraction;
        final qbankProgress = 0.90 * curveFraction;
        final totalPercent = (75 * curveFraction).round();

        return SizedBox(
          width: 350,
          child: Container(
            decoration: AppTheme.sketchDecoration(
              backgroundColor: Colors.white,
              borderRadius: 20,
              shadowOffset: 3.5,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row: Flaticon Subject Icon + Title + Percent Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: meta.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: meta.accent.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: SubjectSketchIcon(
                              subjectId: subjectId,
                              size: 26,
                              color: meta.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PHARMACOLOGY',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '24 Chapters · 65.5 hrs · Ed 8',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Live Percentage Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: totalPercent >= 70
                            ? const Color(0xFFDCFCE7)
                            : AppTheme.paperBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: totalPercent >= 70
                              ? const Color(0xFF16A34A)
                              : Colors.grey.shade400,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        '$totalPercent%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: totalPercent >= 70
                              ? const Color(0xFF16A34A)
                              : AppTheme.inkForeground,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Container(
                  height: 1.2,
                  color: AppTheme.parchmentBorder.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 14),

                // 3 Core Modules Breakdown
                // 1. Videos Module
                _ModuleProgressRow(
                  icon: Icons.play_circle_fill_rounded,
                  iconColor: const Color(0xFF6366F1), // Indigo
                  label: 'Video Lectures',
                  statText: '18 / 24 Done',
                  progress: videoProgress,
                  progressColor: const Color(0xFF6366F1),
                ),

                const SizedBox(height: 10),

                // 2. Q-Bank Module
                _ModuleProgressRow(
                  icon: Icons.help_rounded,
                  iconColor: const Color(0xFFF59E0B), // Amber
                  label: 'Q-Bank MCQs',
                  statText: '45 / 50 Solved',
                  progress: qbankProgress,
                  progressColor: const Color(0xFFF59E0B),
                ),

                const SizedBox(height: 10),

                // 3. Notes Module
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 15,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Revision Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFF16A34A), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 11, color: Color(0xFF16A34A)),
                          SizedBox(width: 3),
                          Text(
                            '10 Units Ready',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModuleProgressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String statText;
  final double progress;
  final Color progressColor;

  const _ModuleProgressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.statText,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkForeground,
                ),
              ),
            ),
            Text(
              statText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            color: Colors.grey.shade200,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(color: progressColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. FOCUS TIMER ILLUSTRATION — Exact Focus Screen with Bouncing Equalizer Bars
// ══════════════════════════════════════════════════════════════════════════════

class FocusTimerIllustration extends StatefulWidget {
  const FocusTimerIllustration({super.key});

  @override
  State<FocusTimerIllustration> createState() => _FocusTimerIllustrationState();
}

class _FocusTimerIllustrationState extends State<FocusTimerIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timerLoopCtrl;

  @override
  void initState() {
    super.initState();
    // 3.0-second continuous looping ticker
    _timerLoopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _timerLoopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _timerLoopCtrl,
      builder: (context, _) {
        final t = _timerLoopCtrl.value;

        // Ticking down from 24:58 -> 24:57 -> 24:56
        final seconds = 58 - (t * 3).floor();
        final displayTime = '00:24:${seconds.toString().padLeft(2, '0')}';

        // Staggered sinusoidal heights for 3 audio equalizer bars
        final bar1 = 0.35 + 0.65 * math.sin(t * 2 * math.pi).abs();
        final bar2 = 0.40 + 0.60 * math.sin((t + 0.33) * 2 * math.pi).abs();
        final bar3 = 0.30 + 0.70 * math.sin((t + 0.66) * 2 * math.pi).abs();

        return SizedBox(
          width: 350,
          child: Container(
            decoration: AppTheme.sketchDecoration(
              backgroundColor: const Color(0xFF1E1412),
              borderRadius: 22,
              shadowOffset: 3.5,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Rich Background Image from Modulix's Default Timer Theme
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/background_thumbs/forest_spring_petals_thumb.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Authentic Gradient Overlay (identical to FocusTimerScreen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.22),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Centerpiece & Controls with high-contrast, authentic styling
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Bar: Glass Close 'X', Center-Up 'SET-UP' Pill, and Active Audio Chip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Glass Close button
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.close_rounded,
                                    size: 15, color: Colors.white),
                              ),
                            ),

                            // Centered Glass SET-UP config pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.40),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune_rounded,
                                      size: 13, color: Color(0xFFF97316)),
                                  SizedBox(width: 5),
                                  Text(
                                    'SET-UP',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Active Soundscape with Bouncing Equalizer Bars
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.40),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.headphones_rounded,
                                      size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Lofi Beats',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _EqualizerBar(heightFactor: bar1),
                                      const SizedBox(width: 1.8),
                                      _EqualizerBar(heightFactor: bar2),
                                      const SizedBox(width: 1.8),
                                      _EqualizerBar(heightFactor: bar3),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Subject Target Label
                        const Text(
                          'PHARMACOLOGY · ANS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Autonomic Nervous System · Chapter 1',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Real Timer Heading: Study Time:
                        const Text(
                          'Study Time:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Big Monospace Display
                        Text(
                          displayTime,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: Colors.white,
                            letterSpacing: -1,
                            height: 1.0,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Total Break Readout
                        Text(
                          'Total Break: 00:00:00',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Total Time (Current) Readout
                        Text(
                          'Total Time (Current): $displayTime',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Live Phase Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF34D399),
                              width: 1.0,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department_rounded,
                                  size: 13, color: Color(0xFF34D399)),
                              SizedBox(width: 4),
                              Text(
                                'FOCUSING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Bottom Action Bar: Break, PAUSE, Finish Controls
                        Row(
                          children: [
                            // Glass Break button
                            Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.32),
                                  width: 1.0,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.coffee_outlined,
                                      size: 15, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Break',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Main Active Play/Pause Button
                            Expanded(
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF97316)
                                          .withValues(alpha: 0.40),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pause_rounded,
                                        size: 16, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'PAUSE',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Glass Finish button
                            Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.32),
                                  width: 1.0,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded,
                                      size: 15, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Finish',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }
}

class _EqualizerBar extends StatelessWidget {
  final double heightFactor;
  const _EqualizerBar({required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.6,
      height: 11 * heightFactor.clamp(0.2, 1.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

