import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/time_log_provider.dart';
import '../../services/metrics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/heatmap_calendar.dart';
import '../../widgets/analytics/study_plan_analytics_sheet.dart';
import '../../widgets/analytics/focus_timer_analytics_sheet.dart';
import '../../widgets/analytics/daily_tasks_analytics_sheet.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final syllabusAsync = ref.watch(activeSyllabusProvider);
    final timeLogs = ref.watch(timeLogsProvider);
    final dailyTasksState = ref.watch(dailyTasksProvider);

    final appState = appStateAsync.value;
    final subjects = syllabusAsync.value ?? [];

    if (appState == null) {
      return const Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final edition = appState.currentEdition;
    final plan = edition.plan;
    final streak = MetricsService.computeStreak(edition.dailyHistory);

    // ── 1. Study Plan Summary ──────────────────────────────────────────────
    int planTotalVideos = 0;
    int planCompletedVideos = 0;
    String planSubjectName = plan.targetSubject;

    for (final s in subjects) {
      if (s.id == plan.targetSubject) {
        planSubjectName = s.name;
        for (final ch in s.chapters) {
          planTotalVideos += ch.videos.length;
          for (final v in ch.videos) {
            if (edition.completedVideos.containsKey(v.id)) {
              planCompletedVideos++;
            }
          }
        }
      }
    }
    final double planProgress = planTotalVideos > 0
        ? (planCompletedVideos / planTotalVideos)
        : 0.0;

    // ── 2. Focus Timer Summary (Today) ─────────────────────────────────────
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 5);
    final effectiveTodayStart = now.hour < 5
        ? todayStart.subtract(const Duration(days: 1))
        : todayStart;

    int todayFocusSecs = 0;
    int todayFocusSessions = 0;
    for (final log in timeLogs) {
      if (log.timestamp.isAfter(effectiveTodayStart)) {
        todayFocusSecs += log.durationSecs;
        todayFocusSessions++;
      }
    }

    // ── 3. Daily Tasks Summary ─────────────────────────────────────────────
    final totalTasks = dailyTasksState.tasks.length;
    final doneTasks = dailyTasksState.completedIds.length;
    final double tasksProgress =
        totalTasks > 0 ? (doneTasks / totalTasks) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.inkForeground,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                  sub: streak.current > 0 ? 'Active & burning strong' : 'Start your streak today',
                  color: Colors.orange,
                  trailingWidget: const _LiveFlameBadge(color: Colors.orange, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStreakCard(
                  label: 'BEST STREAK',
                  value: '${streak.best}',
                  unit: 'RECORD',
                  sub: 'Personal all-time best',
                  color: AppTheme.primaryBlue,
                  trailingWidget: const _ShiningMedalBadge(color: AppTheme.primaryBlue, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'PERFORMANCE HUBS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 12),

          // ── Hub Card 1: Module Plan Progress ─────────────────────────────
          _HubCard(
            title: 'Module Plan Progress',
            subtitle: plan.isConfigured
                ? '$planSubjectName · ${(planProgress * 100).round()}% complete'
                : 'No active plan configured · Tap to set',
            badge: plan.isConfigured
                ? '${planCompletedVideos}/${planTotalVideos} Vids'
                : 'Setup',
            badgeColor: AppTheme.primaryBlue,
            icon: Icons.track_changes_rounded,
            iconColor: AppTheme.primaryBlue,
            iconBg: AppTheme.primaryBlue.withOpacity(0.12),
            progress: planProgress,
            stat1Label: 'Daily Target',
            stat1Value: plan.isConfigured ? '${plan.videosPerDay ?? 4} vids' : '--',
            stat2Label: 'Deadline',
            stat2Value: plan.isConfigured
                ? DateFormat('d MMM').format(DateTime.tryParse(plan.targetDate) ?? DateTime.now())
                : '--',
            onTap: () => StudyPlanAnalyticsSheet.show(context),
          ),



          const SizedBox(height: 14),

          // ── Hub Card 2: Focus Timer Analytics ────────────────────────────
          _HubCard(
            title: 'Focus & Deep Work',
            subtitle: todayFocusSecs > 0
                ? '${_formatDuration(todayFocusSecs)} studied today across $todayFocusSessions sessions'
                : 'No sessions logged today · Start timer',
            badge: todayFocusSecs > 0 ? _formatDuration(todayFocusSecs) : '0m',
            badgeColor: Colors.orange,
            icon: Icons.timer_outlined,
            iconColor: Colors.orange,
            iconBg: Colors.orange.withOpacity(0.12),
            progress: todayFocusSecs > 0
                ? (todayFocusSecs / (4 * 3600)).clamp(0.0, 1.0)
                : 0.0,
            stat1Label: 'Today\'s Flow',
            stat1Value: _formatDuration(todayFocusSecs),
            stat2Label: 'All-Time Logs',
            stat2Value: '${timeLogs.length} sessions',
            onTap: () => FocusTimerAnalyticsSheet.show(context),
          ),

          const SizedBox(height: 14),

          // ── Hub Card 3: Daily Tasks Analytics ────────────────────────────
          _HubCard(
            title: 'Daily Tasks Analytics',
            subtitle: totalTasks > 0
                ? '$doneTasks of $totalTasks tasks checked off today'
                : 'No tasks scheduled on desk pad',
            badge: totalTasks > 0 ? '$doneTasks/$totalTasks' : '0/0',
            badgeColor: Colors.teal,
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.teal,
            iconBg: Colors.teal.withOpacity(0.12),
            progress: tasksProgress,
            stat1Label: 'Completion Rate',
            stat1Value: '${(tasksProgress * 100).round()}%',
            stat2Label: 'Desk Tasks',
            stat2Value: '$totalTasks planned',
            onTap: () => DailyTasksAnalyticsSheet.show(context),
          ),

          const SizedBox(height: 28),

          // ── Heatmap Calendar Section ─────────────────────────────────────
          const Text(
            '12-WEEK STUDY ACTIVITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.sketchDecoration(
              backgroundColor: Colors.white,
              borderRadius: 20,
              shadowOffset: 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Consistency Matrix',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    Text(
                      '${edition.dailyHistory.values.fold<int>(0, (a, b) => a + b)} completed',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                HeatmapCalendar(
                  dailyHistory: edition.dailyHistory,
                  accentColor: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: Colors.white,
        borderRadius: 18,
        shadowOffset: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.mutedText,
                ),
              ),
              trailingWidget,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: AppTheme.inkForeground,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveFlameBadge extends StatefulWidget {
  final Color color;
  final double size;

  const _LiveFlameBadge({
    required this.color,
    this.size = 20,
  });

  @override
  State<_LiveFlameBadge> createState() => _LiveFlameBadgeState();
}

class _LiveFlameBadgeState extends State<_LiveFlameBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.14).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.12, end: 0.42).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_glowAnimation.value * 0.4),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_glowAnimation.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              Icons.local_fire_department_rounded,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

class _ShiningMedalBadge extends StatefulWidget {
  final Color color;
  final double size;

  const _ShiningMedalBadge({
    required this.color,
    this.size = 20,
  });

  @override
  State<_ShiningMedalBadge> createState() => _ShiningMedalBadgeState();
}

class _ShiningMedalBadgeState extends State<_ShiningMedalBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.15),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  (_shimmerAnimation.value - 0.25).clamp(0.0, 1.0),
                  _shimmerAnimation.value.clamp(0.0, 1.0),
                  (_shimmerAnimation.value + 0.25).clamp(0.0, 1.0),
                ],
                colors: [
                  widget.color,
                  const Color(0xFFFDE047), // Gold shining gleam
                  widget.color,
                ],
              ).createShader(bounds);
            },
            child: Icon(
              Icons.military_tech_rounded,
              color: Colors.white,
              size: widget.size,
            ),
          ),
        );
      },
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
  final String stat1Label;
  final String stat1Value;
  final String stat2Label;
  final String stat2Value;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.progress,
    required this.stat1Label,
    required this.stat1Value,
    required this.stat2Label,
    required this.stat2Value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.sketchDecoration(
          backgroundColor: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor, width: 1.2),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
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
                    Text(stat1Label,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText)),
                    Text(stat1Value,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkForeground)),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stat2Label,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText)),
                    Text(stat2Value,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkForeground)),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: badgeColor),
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
