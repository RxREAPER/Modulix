import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/task_item.dart';
import '../../models/user_rank.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/time_log_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../services/metrics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/heatmap_calendar.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/animations/rolling_digit_text.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';
import '../../widgets/analytics/progress_radial_gauge.dart';
import '../../widgets/analytics/concentric_donut_indicator.dart';
import '../../widgets/analytics/animated_trophy.dart';

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

  static Map<String, int> _generateSampleHistory(int daysCount) {
    final map = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < daysCount; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      if (i % 7 != 5) {
        map[dateKey] = (i % 3 == 0) ? 4 : ((i % 2 == 0) ? 3 : 2);
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
    final tasksHubState = ref.watch(tasksHubProvider).valueOrNull;
    final dailyTasksState = ref.watch(dailyTasksProvider);
    final leaderboardState = ref.watch(leaderboardProvider);
    final dailyStanding = leaderboardState.userDailyStanding;

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

    // ── 3. Daily Tasks Summary & Velocity Insights ───────────────────────
    final hubToday = tasksHubState?.todayTasks ?? const <TaskItem>[];
    final hubCompleted = tasksHubState?.todayCompletedTasks ?? const <TaskItem>[];

    List<dynamic> todayTasks = hubToday;
    List<dynamic> todayCompleted = hubCompleted;

    if (todayTasks.isEmpty && todayCompleted.isEmpty && dailyTasksState.tasks.isNotEmpty) {
      todayTasks = dailyTasksState.tasks
          .where((t) => !dailyTasksState.completedIds.contains(t.id))
          .toList();
      todayCompleted = dailyTasksState.tasks
          .where((t) => dailyTasksState.completedIds.contains(t.id))
          .toList();
    }

    final allTodayTasks = [...todayTasks, ...todayCompleted];
    final totalTasks = allTodayTasks.length;
    final doneTasks = todayCompleted.length;
    final pendingTasks = todayTasks.length;
    final double tasksProgress =
        totalTasks > 0 ? (doneTasks / totalTasks) : 0.0;

    final activeProjects = tasksHubState?.activeProjects ?? const [];

    // ── 4. Focus Peak Subject ──────────────────────────────────────────────
    final Map<String, int> focusSubjectSeconds = {};
    for (final log in timeLogs) {
      if (log.topicTitle.isNotEmpty) {
        focusSubjectSeconds[log.topicTitle] =
            (focusSubjectSeconds[log.topicTitle] ?? 0) + log.durationSecs;
      }
    }
    String topFocusSubject = 'MBBS Flow';
    if (focusSubjectSeconds.isNotEmpty) {
      final sortedFocus = focusSubjectSeconds.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topFocusSubject = sortedFocus.first.key;
      if (topFocusSubject.length > 13) {
        topFocusSubject = '${topFocusSubject.substring(0, 12)}…';
      }
    }

    final bool isColdStart = timeLogs.isEmpty &&
        totalFocusSecs == 0 &&
        streak.current == 0 &&
        edition.dailyHistory.isEmpty;

    final sampleHistory = _generateSampleHistory(14 * 7);

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
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.paddingOf(context).bottom + 100.0),
          children: [
            if (isColdStart)
              _AnalyticsColdStartBanner(
                onStartSession: () => context.go('/timer'),
              ),

            // ── ZONE 1: Editorial Momentum Header (Non-card, breathless) ───
            _HeroMomentumHeader(
              streakCurrent: isColdStart ? 12 : streak.current,
              streakBest: isColdStart ? 24 : streak.best,
              todayFocusSecs: isColdStart ? 13500 : todayFocusSecs,
              todaySessions: isColdStart ? 4 : todayFocusSessions,
              topSubject: isColdStart ? 'Anatomy' : topFocusSubject,
              isColdStart: isColdStart,
              onTapFocus: () => context.push('/analytics/focus-analytics'),
            ),

            const SizedBox(height: 18),

            // ── Focus Leaderboard Arena Banner ─────────────────────────────
            _FocusLeaderboardSpecialBox(
              dailyStanding: dailyStanding,
              onTap: () => context.push('/analytics/leaderboard'),
            ),

            const SizedBox(height: 22),

            // ── ZONE 2: Module Planner & Focus Tasks Hub ───────────────────
            // 1. Module Planner Hero Card (Reference Image 2 & 3 style)
            _ModulePlannerHeroCard(
              key: TourTargetRegistry.keyFor(TourTargetId.analyticsModuleHub),
              subjectName: isColdStart ? 'Anatomy' : planSubjectName,
              progress: isColdStart ? 0.45 : planProgress,
              completedVideos: isColdStart ? 36 : planCompletedVideos,
              totalVideos: isColdStart ? 80 : planTotalVideos,
              dailyTarget: isColdStart ? '4 vids' : (plan.isConfigured ? '${plan.videosPerDay ?? 4} vids' : '--'),
              deadline: isColdStart
                  ? '30 Nov'
                  : (plan.isConfigured
                      ? DateFormat('d MMM').format(DateTime.tryParse(plan.targetDate) ?? DateTime.now())
                      : '--'),
              isConfigured: isColdStart || plan.isConfigured,
              onTap: () => context.push('/analytics/plan-insights'),
            ),

            const SizedBox(height: 18),

            // 2. Today's Focus Tasks Section (Reference Image 1 soft pastel pills)
            _TodayFocusTasksSection(
              key: TourTargetRegistry.keyFor(TourTargetId.analyticsTasksHub),
              todayTasks: todayTasks,
              todayCompleted: todayCompleted,
              isColdStart: isColdStart,
              tasksProgress: tasksProgress,
              totalTasks: totalTasks,
              doneTasks: doneTasks,
              pendingTasks: pendingTasks,
              activeProjectsCount: activeProjects.length,
              onOpenDailyTasks: () => context.push('/analytics/tasks-analytics'),
            ),

            const SizedBox(height: 18),

            // 3. Focus & Deep Work Quick Stats Card
            _FocusDeepWorkCard(
              key: TourTargetRegistry.keyFor(TourTargetId.analyticsFocusHub),
              isColdStart: isColdStart,
              todayFocusSecs: todayFocusSecs,
              todaySessions: todayFocusSessions,
              totalFocusSecs: totalFocusSecs,
              videoFocusSecs: videoFocusSecs,
              qbankFocusSecs: qbankFocusSecs,
              notesFocusSecs: notesFocusSecs,
              topSubject: isColdStart ? 'Anatomy' : topFocusSubject,
              onTap: () => context.push('/analytics/focus-analytics'),
            ),

            const SizedBox(height: 24),

            // ── Consistency Matrix Section ─────────────────────────────────
            NeetConsistencyMatrix(
              dailyVideos: isColdStart ? sampleHistory : edition.dailyHistory,
              dailyQBanks: isColdStart
                  ? sampleHistory
                  : _aggregateDailyCompleted(edition.completedQBanks),
              dailyNotes: isColdStart
                  ? sampleHistory
                  : _aggregateDailyCompleted(edition.completedNotes),
              accentColor: AppTheme.accentPrimary,
              weeksCount: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsColdStartBanner extends StatelessWidget {
  final VoidCallback onStartSession;
  const _AnalyticsColdStartBanner({required this.onStartSession});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPrimary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppTheme.accentPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Day 1 Preview',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Sample Data',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ready for your first session?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.inkForeground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a timer today to see your daily study streak, charts, and milestones come alive right here.',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ApplePressable(
            pressedScale: 0.97,
            onPressed: onStartSession,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: AppTheme.onAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Start First Focus Session',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Zone 1: Editorial Momentum Header ─────────────────────────────────────────
class _HeroMomentumHeader extends StatelessWidget {
  final int streakCurrent;
  final int streakBest;
  final int todayFocusSecs;
  final int todaySessions;
  final String topSubject;
  final bool isColdStart;
  final VoidCallback onTapFocus;

  const _HeroMomentumHeader({
    required this.streakCurrent,
    required this.streakBest,
    required this.todayFocusSecs,
    required this.todaySessions,
    required this.topSubject,
    required this.isColdStart,
    required this.onTapFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Streak counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _LiveFlameBadge(color: Color(0xFFF97316), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'STUDY STREAK',
                      style: AppTypography.metricLabel(
                        fontSize: 10.0,
                        letterSpacing: 0.8,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    RollingDigitText.count(
                      count: streakCurrent,
                      style: AppTypography.metricValue(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'DAYS ACTIVE',
                      style: AppTypography.metricLabel(
                        fontSize: 10.0,
                        letterSpacing: 0.5,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'RECORD',
                      style: AppTypography.cardSubtitle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEAB308),
                      ),
                    ),
                    Text(
                      isColdStart ? ': 24 DAYS' : ': $streakBest DAYS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardSubtitle(
                        fontSize: 10.5,
                        color: const Color(0xFFEAB308),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppTheme.borderLight.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 16),
          // Right: Today's Focus Flow
          Expanded(
            child: ApplePressable(
              onTap: onTapFocus,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppTheme.accentPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TODAY\'S FLOW',
                        style: AppTypography.metricLabel(
                          fontSize: 10.0,
                          letterSpacing: 0.8,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AnalyticsScreen._formatDuration(todayFocusSecs),
                    style: AppTypography.metricValue(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$todaySessions session${todaySessions == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardSubtitle(
                      fontSize: 10.5,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Zone 2: Module Planner Hero Card (Reference Image 2 & 3) ───────────────────
class _ModulePlannerHeroCard extends StatelessWidget {
  final String subjectName;
  final double progress;
  final int completedVideos;
  final int totalVideos;
  final String dailyTarget;
  final String deadline;
  final bool isConfigured;
  final VoidCallback onTap;

  const _ModulePlannerHeroCard({
    super.key,
    required this.subjectName,
    required this.progress,
    required this.completedVideos,
    required this.totalVideos,
    required this.dailyTarget,
    required this.deadline,
    required this.isConfigured,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.98,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0284C7), // Sky 600
              Color(0xFF2563EB), // Blue 600
              Color(0xFF3730A3), // Indigo 800
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Label + Target Count Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.track_changes_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Module Plan Progress',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConfigured ? '$completedVideos/$totalVideos Vids' : 'Setup',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Middle: Subject Name + Radial Progress Gauge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConfigured
                            ? '$percent% complete · On track'
                            : 'No plan active · Tap to configure target',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ProgressRadialGauge(
                  progress: progress,
                  size: 52,
                  strokeWidth: 5.0,
                  progressColor: Colors.white,
                  trackColor: Colors.white.withValues(alpha: 0.25),
                  percentageStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 14),

            // Bottom stats & CTA
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY TARGET',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dailyTarget,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEADLINE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deadline,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Insights',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: Colors.white,
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

// ── Zone 2: Task Velocity Section (Editorial Unboxed: No Card, No Tags, Less Text) ──
class _TodayFocusTasksSection extends ConsumerWidget {
  final List<dynamic> todayTasks;
  final List<dynamic> todayCompleted;
  final bool isColdStart;
  final double tasksProgress;
  final int totalTasks;
  final int doneTasks;
  final int pendingTasks;
  final int activeProjectsCount;
  final VoidCallback onOpenDailyTasks;

  const _TodayFocusTasksSection({
    super.key,
    required this.todayTasks,
    required this.todayCompleted,
    required this.isColdStart,
    required this.tasksProgress,
    required this.totalTasks,
    required this.doneTasks,
    required this.pendingTasks,
    required this.activeProjectsCount,
    required this.onOpenDailyTasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.current.isDark;
    final int velocityPercent = isColdStart
        ? 83
        : (totalTasks > 0 ? ((doneTasks / totalTasks) * 100).round() : 0);

    final int displayTotal = isColdStart ? 6 : totalTasks;
    final int displayDone = isColdStart ? 5 : doneTasks;
    final int displayPending = isColdStart ? 1 : pendingTasks;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ApplePressable(
            onTap: onOpenDailyTasks,
            pressedScale: 0.99,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Clean Editorial Header with Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Task analytics',
                        style: AppTheme.headingStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayTotal > 0
                                ? '$displayDone of $displayTotal completed'
                                : 'No tasks scheduled',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppTheme.mutedText,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Sleek Minimal Velocity Track
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 5.0,
                      width: double.infinity,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (velocityPercent / 100.0).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentEmerald,
                                AppTheme.primaryBlue,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Row 3: Minimal Single-Line Pace Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayPending == 0 && displayTotal > 0
                            ? 'All targets complete'
                            : '$velocityPercent% daily velocity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: displayPending == 0 && displayTotal > 0
                              ? AppTheme.accentEmerald
                              : AppTheme.mutedText,
                        ),
                      ),
                      if (displayPending > 0)
                        Text(
                          '$displayPending remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedText,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Focus & Deep Work Quick Stats Card ───────────────────────────────────────
class _FocusDeepWorkCard extends StatelessWidget {
  final bool isColdStart;
  final int todayFocusSecs;
  final int todaySessions;
  final int totalFocusSecs;
  final int videoFocusSecs;
  final int qbankFocusSecs;
  final int notesFocusSecs;
  final String topSubject;
  final VoidCallback onTap;

  const _FocusDeepWorkCard({
    super.key,
    required this.isColdStart,
    required this.todayFocusSecs,
    required this.todaySessions,
    required this.totalFocusSecs,
    required this.videoFocusSecs,
    required this.qbankFocusSecs,
    required this.notesFocusSecs,
    required this.topSubject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    final displayDuration = isColdStart
        ? '3h 45m'
        : (todayFocusSecs > 0
            ? AnalyticsScreen._formatDuration(todayFocusSecs)
            : '0m');

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.98,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                  ]
                : [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Mini label + Concentric Donut Ring
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFF67E8F9),
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Focus & Deep Work',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                ConcentricDonutIndicator(
                  progress1: isColdStart ? 0.50 : (totalFocusSecs > 0 ? (videoFocusSecs / totalFocusSecs) : 0.0),
                  progress2: isColdStart ? 0.30 : (totalFocusSecs > 0 ? (qbankFocusSecs / totalFocusSecs) : 0.0),
                  progress3: isColdStart ? 0.20 : (totalFocusSecs > 0 ? (notesFocusSecs / totalFocusSecs) : 0.0),
                  size: 44,
                  ringWidth: 3.5,
                  ringSpacing: 2.0,
                  color1: const Color(0xFF60A5FA),
                  color2: const Color(0xFF34D399),
                  color3: const Color(0xFFA78BFA),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Big Bold Time Display
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayDuration,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isColdStart
                      ? '4 sessions'
                      : (todaySessions > 0
                          ? '$todaySessions session${todaySessions == 1 ? '' : 's'}'
                          : 'logged today'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.60),
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

/// Distinct, non-card special edition box for the Focus Leaderboard Arena.
class _FocusLeaderboardSpecialBox extends StatelessWidget {
  final UserStanding dailyStanding;
  final VoidCallback onTap;

  const _FocusLeaderboardSpecialBox({
    required this.dailyStanding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Deep Slate 900
              Color(0xFF1E1B4B), // Royal Indigo 950
              Color(0xFF020617), // Midnight Slate 950
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Live Feature Indicator & Trophy
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981), // Emerald pulse
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 6,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'FOCUS LEADERBOARD',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: Color(0xFF38BDF8), // Electric cyan
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheerfulAnimatedTrophy(
                      rank: dailyStanding.rank <= 3 ? dailyStanding.rank : 1,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle: Metrics Dashboard (3-Column Vault Grid)
            Row(
              children: [
                // Daily Rank
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY RANK',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${dailyStanding.rank}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFBBF24), // Vibrant gold
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Career Level
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAREER TIER',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dailyStanding.level.shortCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Studied Time
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dailyStanding.formattedDuration,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
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
