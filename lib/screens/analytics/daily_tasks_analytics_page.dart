import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/task_item.dart';
import '../../models/task_project.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/focus_timer_provider.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/analytics/progress_radial_gauge.dart';
import '../../widgets/analytics/segmented_velocity_pill.dart';
import '../../widgets/analytics/chronotype_timeline_grid.dart';

class DailyTasksAnalyticsPage extends ConsumerWidget {
  const DailyTasksAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final dayStartHour = ref.watch(
      appStateProvider.select((s) => s.valueOrNull?.dayStartHour ?? 5),
    );
    final tasksHubAsync = ref.watch(tasksHubProvider);
    final timerState = ref.watch(focusTimerProvider);
    final isDark = AppTheme.current.isDark;

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: ApplePressable(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/analytics');
            }
          },
          child: Container(
            alignment: Alignment.center,
            child: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground, size: 22),
          ),
        ),
        title: Text(
          'Tasks Analytics',
          style: AppTheme.headingStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
        actions: [
          ApplePressable(
            onTap: () => context.push('/daily-tasks'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.current.isDark
                    ? const Color(0xFF1C1C1E)
                    : AppTheme.inkForeground,
                borderRadius: BorderRadius.circular(8),
                border: AppTheme.current.isDark
                    ? Border.all(color: const Color(0xFF2C2C2E), width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 12,
                    color: AppTheme.current.isDark
                        ? Colors.white
                        : AppTheme.paperBackground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Daily tasks',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.current.isDark
                          ? Colors.white
                          : AppTheme.paperBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: tasksHubAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => Center(
          child: Text('Error loading tasks analytics', style: TextStyle(color: AppTheme.mutedText)),
        ),
        data: (hubState) {
          final todayTasks = hubState.todayTasks;
          final todayCompleted = hubState.todayCompletedTasks;
          final allTodayTasks = [...todayTasks, ...todayCompleted];
          final totalTasks = allTodayTasks.length;
          final completedCount = todayCompleted.length;
          final pendingCount = todayTasks.length;
          final completionPct = totalTasks > 0 ? (completedCount / totalTasks).clamp(0.0, 1.0) : 0.0;

          final activeProjects = hubState.activeProjects;
          final standaloneTasks = allTodayTasks.where((t) => t.projectId == null || t.projectId!.isEmpty).toList();

          int estRemainingMins = 0;
          for (final t in todayTasks) {
            estRemainingMins += (t.estimatedMinutes ?? 25);
          }

          // Streak calculation based on recent days
          final now = DateTime.now().subtract(Duration(hours: dayStartHour));
          final List<Map<String, dynamic>> pastDays = [];
          for (int i = 13; i >= 0; i--) {
            final d = now.subtract(Duration(days: i));
            final k = DateFormat('yyyy-MM-dd').format(d);
            final dayCount = hubState.tasks.where((t) {
              if (!t.isCompleted || t.completedAt == null) return false;
              final compDateKey = DateFormat('yyyy-MM-dd').format(t.completedAt!);
              return compDateKey == k;
            }).length;

            pastDays.add({
              'date': d,
              'key': k,
              'count': dayCount,
              'label': DateFormat('E').format(d)[0],
              'isToday': i == 0,
            });
          }

          final maxDayCount = pastDays.fold<int>(1, (max, d) => (d['count'] as int) > max ? (d['count'] as int) : max);
          int streak = 0;
          for (int i = pastDays.length - 1; i >= 0; i--) {
            if ((pastDays[i]['count'] as int) > 0) {
              streak++;
            } else if (i != pastDays.length - 1) {
              break;
            }
          }

          return FadeSlideEntrance(
            durationMs: 180,
            slideY: 12.0,
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 100),
              children: [
                // ── 1. Hero Completion Card ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                      width: 0.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ProgressRadialGauge(
                        progress: completionPct,
                        size: 84,
                        strokeWidth: 7,
                        progressColor: const Color(0xFF10B981),
                        percentageStyle: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Study Rituals',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCount of $totalTasks Done Today',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              pendingCount > 0
                                  ? '$pendingCount targets · ~${estRemainingMins}m focus'
                                  : (totalTasks > 0 ? 'All scheduled rituals completed' : 'No rituals scheduled today'),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SegmentedVelocityPill(
                              totalSegments: totalTasks > 0 ? totalTasks : 1,
                              completedSegments: completedCount,
                              activeColor: const Color(0xFF10B981),
                              velocityLabel: completionPct >= 1.0
                                  ? '100% Target Met'
                                  : (pendingCount > 0 ? '$pendingCount remaining' : 'No tasks'),
                              isPositiveVelocity: completionPct >= 0.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 2. Project Specific Details ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Study Projects (${activeProjects.length})',
                      style: AppTheme.headingStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    ApplePressable(
                      onTap: () => context.push('/daily-tasks'),
                      child: Text(
                        'Manage →',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (activeProjects.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No study projects active · Set up a project in Daily tasks',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.mutedText),
                    ),
                  )
                else
                  for (final project in activeProjects)
                    _buildProjectAnalyticsCard(
                      project: project,
                      tasks: hubState.tasksForProject(project.id),
                      timerState: timerState,
                      ref: ref,
                      isDark: isDark,
                    ),

                const SizedBox(height: 24),

                // ── 3. Standalone Tasks Section ───────────────────────────────
                Text(
                  'Standalone Tasks (${standaloneTasks.length})',
                  style: AppTheme.headingStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 10),

                if (standaloneTasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        width: 0.6,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No standalone tasks for today',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.mutedText),
                    ),
                  )
                else
                  for (final task in standaloneTasks)
                    _buildAnalyticsTaskRow(
                      task: task,
                      timerState: timerState,
                      ref: ref,
                      context: context,
                      isDark: isDark,
                    ),

                const SizedBox(height: 24),

                // ── 4. Chronotype 24H Timeline Grid ──────────────────────────
                const ChronotypeTimelineGrid(),

                const SizedBox(height: 24),

                // ── 5. 14-Day Consistency Matrix ─────────────────────────────
                Text(
                  '14-Day Activity Matrix',
                  style: AppTheme.headingStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Task Consistency',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              streak > 0 ? '$streak-DAY STREAK' : 'START STREAK',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: pastDays.map((d) {
                          final count = d['count'] as int;
                          final isToday = d['isToday'] as bool;
                          final double height = count > 0
                              ? (18 + (46 * (count / maxDayCount))).clamp(18.0, 64.0)
                              : 6.0;

                          return Expanded(
                            child: Column(
                              children: [
                                Text(
                                  count > 0 ? '$count' : '',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: isToday ? const Color(0xFF10B981) : AppTheme.mutedText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: height,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    gradient: count > 0
                                        ? LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: isToday
                                                ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                                                : [const Color(0xFF10B981).withValues(alpha: 0.45), const Color(0xFF10B981).withValues(alpha: 0.75)],
                                          )
                                        : null,
                                    color: count > 0
                                        ? null
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  d['label'] as String,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                                    color: isToday ? const Color(0xFF10B981) : AppTheme.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectAnalyticsCard({
    required TaskProject project,
    required List<TaskItem> tasks,
    required FocusTimerState timerState,
    required WidgetRef ref,
    required bool isDark,
  }) {
    final totalCount = tasks.length;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final remainingCount = totalCount - completedCount;
    final progressRatio = totalCount == 0 ? 0.0 : (completedCount / totalCount);
    final progressPercent = (progressRatio * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (project.subjectName ?? 'Subject').toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            project.unitName ?? project.name,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 10),

          // Continuous 5px rounded gradient progress track
          ClipRRect(
            borderRadius: BorderRadius.circular(2.5),
            child: Container(
              height: 5,
              width: double.infinity,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressRatio.clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Analytics metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount / $totalCount tasks · $progressPercent%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.inkForeground,
                ),
              ),
              Text(
                remainingCount > 0 ? '$remainingCount remaining' : 'Complete',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),

          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(tasksHubProvider.notifier).toggleTaskComplete(task.id);
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isCompleted
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          border: Border.all(
                            color: task.isCompleted
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                            width: 1.5,
                          ),
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: task.isCompleted ? FontWeight.w400 : FontWeight.w500,
                          color: task.isCompleted ? AppTheme.mutedText : AppTheme.inkForeground,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: AppTheme.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsTaskRow({
    required TaskItem task,
    required FocusTimerState timerState,
    required WidgetRef ref,
    required BuildContext context,
    required bool isDark,
  }) {
    final isDone = task.isCompleted;
    final isFocusActive = timerState.isRunning && timerState.boundTaskId == task.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0).withValues(alpha: 0.5))
              : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(tasksHubProvider.notifier).toggleTaskComplete(task.id);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? const Color(0xFF10B981) : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isDone ? FontWeight.w400 : FontWeight.w500,
                color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppTheme.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ApplePressable(
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(focusTimerProvider.notifier).startTaskItemFocus(task);
              context.push('/timer');
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFocusActive
                    ? AppTheme.accentPrimary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.play_arrow_rounded,
                size: 19,
                color: isFocusActive
                    ? Colors.white
                    : (isDark ? Colors.white : AppTheme.inkForeground),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
