import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/time_log_provider.dart';
import '../../services/metrics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/heatmap_calendar.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/animations/rolling_digit_text.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../widgets/in_situ_hint_pill.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';
import '../../widgets/analytics/progress_radial_gauge.dart';
import '../../widgets/analytics/concentric_donut_indicator.dart';
import '../../widgets/analytics/segmented_velocity_pill.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static String _formatDuration(int totalSecs) {
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }


  static Map<String, int> _aggregateDailyCompleted(Map<String, dynamic> completedItems) {
    final map = <String, int>{};
    for (final val in completedItems.values) {
      if (val is String && val.isNotEmpty) {
        final key = val.split('T').first;
        if (key.length == 10) {
          map[key] = (map[key] ?? 0) + 1;
        }
      } else if (val is Map && val['date'] != null) {
        final key = val['date'].toString().split('T').first;
        if (key.length == 10) {
          map[key] = (map[key] ?? 0) + 1;
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final appStateAsync = ref.watch(appStateProvider);
    final syllabusAsync = ref.watch(activeSyllabusProvider);
    final timeLogs = ref.watch(timeLogsProvider);
    final dailyTasksState = ref.watch(dailyTasksProvider);

    final appState = appStateAsync.value;
    final subjects = syllabusAsync.value ?? [];

    if (appStateAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const SafeArea(child: AnalyticsSkeletonView()),
      );
    }

    if (appStateAsync.hasError) {
      return Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: SafeArea(
          child: AppErrorStateView(
            error: appStateAsync.error,
            stackTrace: appStateAsync.stackTrace,
            onRetry: () => ref.refresh(appStateProvider),
          ),
        ),
      );
    }

    if (appState == null) {
      return Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const SafeArea(child: AnalyticsSkeletonView()),
      );
    }

    final edition = appState.currentEdition;
    final plan = edition.plan;
    final streak = MetricsService.computeStreak(
      edition.dailyHistory,
      dayStartHour: appState.dayStartHour,
    );

    // ── 1. Study Plan Summary ──────────────────────────────────────────────
    int planTotalVideos = 0;
    int planCompletedVideos = 0;
    String planSubjectName = plan.targetSubject;

    for (final s in subjects) {
      if (s.id == plan.targetSubject) {
        planSubjectName = s.name;
        for (final ch in s.chapters) {
          if (plan.targetUnits.isNotEmpty &&
              !plan.targetUnits.contains(ch.name)) {
            continue;
          }
          planTotalVideos += ch.videos.length;
          for (final v in ch.videos) {
            if (edition.completedVideos.containsKey(v.id)) {
              planCompletedVideos++;
            }
          }
        }
      }
    }
    final double planProgress =
        planTotalVideos > 0 ? (planCompletedVideos / planTotalVideos) : 0.0;

    // ── 2. Focus Timer Summary (Today) ─────────────────────────────────────
    final effectiveTodayStart =
        MetricsService.studyDayStart(appState.dayStartHour);

    int todayFocusSecs = 0;
    int todayFocusSessions = 0;
    int totalFocusSecs = 0;
    int videoFocusSecs = 0;
    int qbankFocusSecs = 0;
    int notesFocusSecs = 0;

    for (final log in timeLogs) {
      totalFocusSecs += log.durationSecs;
      if (log.timestamp.isAfter(effectiveTodayStart)) {
        todayFocusSecs += log.durationSecs;
        todayFocusSessions++;
      }
      final lowerTitle = log.topicTitle.toLowerCase();
      final lowerType = log.topicType.toLowerCase();
      if (lowerType.contains('qbank') || lowerTitle.contains('mcq')) {
        qbankFocusSecs += log.durationSecs;
      } else if (lowerType.contains('note') || lowerTitle.contains('read')) {
        notesFocusSecs += log.durationSecs;
      } else {
        videoFocusSecs += log.durationSecs;
      }
    }

    // ── 3. Daily Tasks Summary ─────────────────────────────────────────────
    final totalTasks = dailyTasksState.tasks.length;
    final doneTasks = dailyTasksState.completedIds.length;
    final double tasksProgress =
        totalTasks > 0 ? (doneTasks / totalTasks) : 0.0;

    // ── 4. Overall 19 MBBS Subjects Mastery ────────────────────────────────
    int totalMbbsItems = 0;
    int completedMbbsItems = 0;
    for (final s in subjects) {
      for (final ch in s.chapters) {
        totalMbbsItems += ch.videos.length + ch.notes.length;
        for (final v in ch.videos) {
          if (edition.completedVideos.containsKey(v.id)) completedMbbsItems++;
        }
        for (final n in ch.notes) {
          if (edition.completedNotes.containsKey(n.id)) completedMbbsItems++;
        }
      }
      for (final qch in s.qbankChapters) {
        totalMbbsItems += qch.qbanks.length;
        for (final q in qch.qbanks) {
          if (edition.completedQBanks.containsKey(q.id)) completedMbbsItems++;
        }
      }
    }
    final double mbbsProgress =
        totalMbbsItems > 0 ? (completedMbbsItems / totalMbbsItems) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Progress',
          style: AppTheme.headingStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ProfileAvatar(
              size: 42,
              colorId: appState.avatarColorId,
              iconId: appState.avatarIconId,
              doctorName: appState.doctorName,
              onTap: () => context.go('/settings?from=/analytics'),
            ),
          ),
        ],
      ),
      body: FadeSlideEntrance(
        durationMs: 180,
        slideY: 10.0,
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // ── Top Streak & Consistency Row ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _HeroStreakCard(
                    label: 'STUDY STREAK',
                    value: '${streak.current}',
                    unit: 'DAYS ACTIVE',
                    sub: streak.current > 0
                        ? 'Active & burning strong'
                        : 'Start your streak today',
                    color: const Color(0xFFF97316),
                    trailingWidget: const _LiveFlameBadge(
                        color: Color(0xFFF97316), size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroStreakCard(
                    label: 'BEST STREAK',
                    value: '${streak.best}',
                    unit: 'RECORD',
                    sub: 'Personal all-time best',
                    color: const Color(0xFFCA8A04),
                    trailingWidget: const _ShiningMedalBadge(
                        color: Color(0xFFEAB308), size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'PERFORMANCE HUBS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 8),

            const InSituHintPill(
              prefKey: 'hint_analytics_hubs_seen',
              message:
                  'Tap any performance hub to open full-page deep dives and predictive analytics',
              icon: Icons.donut_small_rounded,
              margin: EdgeInsets.only(bottom: 12),
            ),

            // ── Hub Card 1: Module Plan Progress ─────────────────────────────
            _HubCard(
              key: TourTargetRegistry.keyFor(TourTargetId.analyticsModuleHub),
              title: 'Module Plan Progress',
              subtitle: plan.isConfigured
                  ? '$planSubjectName · ${(planProgress * 100).round()}% complete'
                  : 'No active plan configured · Tap to set',
              badge: plan.isConfigured
                  ? '$planCompletedVideos/$planTotalVideos Vids'
                  : 'Setup',
              badgeColor: AppTheme.accentPrimary,
              icon: Icons.track_changes_rounded,
              iconColor: AppTheme.accentPrimary,
              iconBg: AppTheme.accentSubtle,
              progress: planProgress,
              indicatorWidget: ProgressRadialGauge(
                progress: planProgress,
                size: 46,
                strokeWidth: 4.8,
                progressColor: AppTheme.accentPrimary,
                percentageStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: AppTheme.inkForeground,
                ),
              ),
              stat1Label: 'Daily Target',
              stat1Value:
                  plan.isConfigured ? '${plan.videosPerDay ?? 4} vids' : '--',
              stat2Label: 'Deadline',
              stat2Value: plan.isConfigured
                  ? DateFormat('d MMM').format(
                      DateTime.tryParse(plan.targetDate) ?? DateTime.now())
                  : '--',
              onTap: () => context.push('/analytics/plan-insights'),
            ),

            const SizedBox(height: 14),

            // ── Hub Card 2: Focus Timer Analytics ────────────────────────────
            _HubCard(
              key: TourTargetRegistry.keyFor(TourTargetId.analyticsFocusHub),
              title: 'Focus & Deep Work',
              subtitle: todayFocusSecs > 0
                  ? '${_formatDuration(todayFocusSecs)} studied today across $todayFocusSessions sessions'
                  : 'No sessions logged today · Start timer',
              badge:
                  todayFocusSecs > 0 ? _formatDuration(todayFocusSecs) : '0m',
              badgeColor: AppTheme.accentSecondary,
              icon: Icons.timer_outlined,
              iconColor: AppTheme.accentSecondary,
              iconBg: AppTheme.accentSecondary.withValues(alpha: 0.12),
              progress: todayFocusSecs > 0
                  ? (todayFocusSecs / (4 * 3600)).clamp(0.0, 1.0)
                  : 0.0,
              indicatorWidget: ConcentricDonutIndicator(
                progress1: totalFocusSecs > 0
                    ? (videoFocusSecs / totalFocusSecs)
                    : 0.0,
                progress2: totalFocusSecs > 0
                    ? (qbankFocusSecs / totalFocusSecs)
                    : 0.0,
                progress3: totalFocusSecs > 0
                    ? (notesFocusSecs / totalFocusSecs)
                    : 0.0,
                size: 46,
                ringWidth: 3.5,
                ringSpacing: 2.0,
                color1: AppTheme.accentPrimary,
                color2: AppTheme.accentSecondary,
                color3: AppTheme.accentTertiary,
              ),
              stat1Label: 'Today\'s Flow',
              stat1Value: _formatDuration(todayFocusSecs),
              stat2Label: 'All-Time Logs',
              stat2Value: '${timeLogs.length} sessions',
              onTap: () => context.push('/analytics/focus-analytics'),
            ),

            const SizedBox(height: 14),

            // ── Hub Card 3: Daily Tasks Analytics ────────────────────────────
            _HubCard(
              key: TourTargetRegistry.keyFor(TourTargetId.analyticsTasksHub),
              title: 'Daily Tasks Analytics',
              subtitle: totalTasks > 0
                  ? '$doneTasks of $totalTasks tasks checked off today'
                  : 'No tasks scheduled on desk pad',
              badge: totalTasks > 0 ? '$doneTasks/$totalTasks' : '0/0',
              badgeColor: AppTheme.accentEmerald,
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppTheme.accentEmerald,
              iconBg: AppTheme.accentEmerald.withValues(alpha: 0.12),
              progress: tasksProgress,
              indicatorWidget: ProgressRadialGauge(
                progress: tasksProgress,
                size: 46,
                strokeWidth: 4.8,
                progressColor: AppTheme.accentEmerald,
                percentageStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: AppTheme.inkForeground,
                ),
              ),
              customBottomWidget: totalTasks > 0
                  ? SegmentedVelocityPill(
                      totalSegments: totalTasks,
                      completedSegments: doneTasks,
                      activeColor: AppTheme.accentEmerald,
                      velocityLabel: tasksProgress >= 1.0
                          ? '100% Target Met'
                          : '${totalTasks - doneTasks} tasks pending',
                      isPositiveVelocity: tasksProgress >= 0.5,
                    )
                  : null,
              stat1Label: 'Completion Rate',
              stat1Value: '${(tasksProgress * 100).round()}%',
              stat2Label: 'Desk Tasks',
              stat2Value: '$totalTasks planned',
              onTap: () => context.push('/analytics/tasks-analytics'),
            ),

            const SizedBox(height: 14),

            // ── Hub Card 4: Subject Mastery ──────────────────────────────────
            _HubCard(
              title: 'Subject Mastery',
              subtitle:
                  'Complete curriculum tracking across all 19 subjects',
              badge: '${(mbbsProgress * 100).round()}% MBBS',
              badgeColor: AppTheme.accentTertiary,
              icon: Icons.layers_outlined,
              iconColor: AppTheme.accentTertiary,
              iconBg: AppTheme.accentTertiary.withValues(alpha: 0.12),
              progress: mbbsProgress,
              indicatorWidget: ProgressRadialGauge(
                progress: mbbsProgress,
                size: 46,
                strokeWidth: 4.8,
                progressColor: AppTheme.accentTertiary,
                percentageStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: AppTheme.inkForeground,
                ),
              ),
              stat1Label: 'Mastered Items',
              stat1Value: '$completedMbbsItems/$totalMbbsItems',
              stat2Label: 'Curriculum Scope',
              stat2Value: '${subjects.length} Subjects',
              onTap: () => context.push('/analytics/subject-mastery'),
            ),

            const SizedBox(height: 28),

            // ── Study Matrix Section ───────────────────────────
            NeetConsistencyMatrix(
              dailyVideos: edition.dailyHistory,
              dailyQBanks: _aggregateDailyCompleted(edition.completedQBanks),
              dailyNotes: _aggregateDailyCompleted(edition.completedNotes),
              accentColor: AppTheme.accentPrimary,
              weeksCount: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStreakCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String sub;
  final Color color;
  final Widget trailingWidget;

  const _HeroStreakCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
    required this.color,
    required this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: AppTheme.sketchDecoration(
          backgroundColor: AppTheme.cardWhite,
          borderRadius: 18,
          shadowOffset: 3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headingStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkForeground,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                trailingWidget,
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (int.tryParse(value) != null)
                  RollingDigitText.count(
                    count: int.parse(value),
                    style: AppTypography.metricValue(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkForeground,
                    ),
                  )
                else
                  Text(
                    value,
                    style: AppTypography.metricValue(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.metricLabel(
                      fontSize: 10.0,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardSubtitle(
                fontSize: 10.0,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveFlameBadge extends StatefulWidget {
  final Color color;
  final double size;

  const _LiveFlameBadge({
    required this.color,
    this.size = 17,
  });

  @override
  State<_LiveFlameBadge> createState() => _LiveFlameBadgeState();
}

class _LiveFlameBadgeState extends State<_LiveFlameBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.35),
              blurRadius: 6,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Icon(
          Icons.local_fire_department_rounded,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}

class _ShiningMedalBadge extends StatefulWidget {
  final Color color;
  final double size;

  const _ShiningMedalBadge({
    required this.color,
    this.size = 17,
  });

  @override
  State<_ShiningMedalBadge> createState() => _ShiningMedalBadgeState();
}

class _ShiningMedalBadgeState extends State<_ShiningMedalBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.color.withValues(alpha: 0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.22),
              blurRadius: 6,
              spreadRadius: 0.8,
            ),
          ],
        ),
        child: Icon(
          Icons.military_tech_rounded,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final double progress;
  final Widget? indicatorWidget;
  final Widget? customBottomWidget;
  final String stat1Label;
  final String stat1Value;
  final String stat2Label;
  final String stat2Value;
  final VoidCallback onTap;

  const _HubCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.progress,
    this.indicatorWidget,
    this.customBottomWidget,
    required this.stat1Label,
    required this.stat1Value,
    required this.stat2Label,
    required this.stat2Value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.98,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.sketchDecoration(
          backgroundColor: AppTheme.cardWhite,
          borderRadius: 20,
          shadowOffset: 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: iconColor, width: 1.4),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.cardTitle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardSubtitle(
                          fontSize: 11.5,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (indicatorWidget != null)
                  indicatorWidget!
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.current.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.current.isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : AppTheme.borderLight,
                        width: 1.1,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: AppTypography.microBadge(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            if (customBottomWidget != null)
              customBottomWidget!
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppTheme.borderLight,
                  valueColor: AlwaysStoppedAnimation(badgeColor),
                ),
              ),

            const SizedBox(height: 14),

            // Stats row + View Details Action
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat1Label,
                      style: AppTypography.metricLabel(
                        fontSize: 9.5,
                        letterSpacing: 0.5,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stat1Value,
                      style: AppTypography.metricValue(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat2Label,
                      style: AppTypography.metricLabel(
                        fontSize: 9.5,
                        letterSpacing: 0.5,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stat2Value,
                      style: AppTypography.metricValue(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: AppTheme.current.isDark
                      ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
                      : EdgeInsets.zero,
                  decoration: AppTheme.current.isDark
                      ? BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1,
                          ),
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open Page',
                        style: AppTypography.cardAction(
                          fontSize: 11.5,
                          color: AppTheme.current.isDark
                              ? Colors.white.withValues(alpha: 0.88)
                              : AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppTheme.current.isDark
                            ? Colors.white.withValues(alpha: 0.75)
                            : AppTheme.mutedText,
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
  }
}
