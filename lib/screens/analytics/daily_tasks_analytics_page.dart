import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/daily_desk_task.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/analytics/progress_radial_gauge.dart';
import '../../widgets/analytics/segmented_velocity_pill.dart';

class DailyTasksAnalyticsPage extends ConsumerWidget {
  const DailyTasksAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayStartHour = ref.watch(
        appStateProvider.select((s) => s.valueOrNull?.dayStartHour ?? 5));
    final tasksState = ref.watch(dailyTasksProvider);
    final tasks = tasksState.tasks;
    final completedIds = tasksState.completedIds;
    final dateHistory = tasksState.dateHistory;

    final totalTasks = tasks.length;
    final completedCount =
        tasks.where((t) => completedIds.contains(t.id)).length;
    final completionPct =
        totalTasks > 0 ? (completedCount / totalTasks).clamp(0.0, 1.0) : 0.0;

    // Calculate streak
    int streak = 0;
    final now = DateTime.now().subtract(Duration(hours: dayStartHour));
    DateTime checkDay = now;

    final todayKey = DateFormat('yyyy-MM-dd').format(checkDay);
    if ((dateHistory[todayKey] ?? 0) > 0 || completedCount > 0) {
      streak = 1;
      checkDay = DateTime(now.year, now.month, now.day - 1);
    } else {
      checkDay = DateTime(now.year, now.month, now.day - 1);
    }

    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(checkDay);
      if ((dateHistory[key] ?? 0) > 0) {
        streak++;
        checkDay = DateTime(checkDay.year, checkDay.month, checkDay.day - 1);
      } else {
        break;
      }
    }

    // Category distribution
    final Map<TaskCategory, int> categoryCounts = {};
    final Map<TaskCategory, int> categoryCompleted = {};
    for (final task in tasks) {
      categoryCounts[task.category] = (categoryCounts[task.category] ?? 0) + 1;
      if (completedIds.contains(task.id)) {
        categoryCompleted[task.category] =
            (categoryCompleted[task.category] ?? 0) + 1;
      }
    }

    // Past 14 days history list
    final List<Map<String, dynamic>> pastDays = [];
    for (int i = 13; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = DateFormat('yyyy-MM-dd').format(d);
      final count = i == 0 ? (completedCount > 0 ? completedCount : (dateHistory[k] ?? 0)) : (dateHistory[k] ?? 0);
      pastDays.add({
        'date': d,
        'key': k,
        'count': count,
        'label': DateFormat('E').format(d)[0],
        'isToday': i == 0,
      });
    }

    final maxDayCount =
        pastDays.fold<int>(1, (max, d) => (d['count'] as int) > max ? (d['count'] as int) : max);

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/analytics');
            }
          },
        ),
        title: Text(
          'Daily Tasks & Desk Pad',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentPrimary, width: 1.2),
                ),
                child: Text(
                  '$completedCount/$totalTasks Tasks',
                  style: AppTypography.compactAction(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeSlideEntrance(
        durationMs: 180,
        slideY: 12.0,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── 1. Hero Efficiency Card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.sketchDecoration(
                backgroundColor: AppTheme.cardWhite,
                borderRadius: 22,
                shadowOffset: 4,
              ),
              child: Row(
                children: [
                  ProgressRadialGauge(
                    progress: completionPct,
                    size: 88,
                    strokeWidth: 8,
                    progressColor: AppTheme.accentPrimary,
                    percentageStyle: AppTypography.metricValue(
                      fontSize: 20,
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
                          'DESK PAD COMPLETION',
                          style: AppTypography.sectionMicroHeader(
                            fontSize: 10.0,
                            letterSpacing: 1.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount of $totalTasks Done Today',
                          style: AppTypography.cardTitle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          streak > 0
                              ? '$streak consecutive days active on desk'
                              : 'Complete a task today to begin your streak',
                          style: AppTypography.cardSubtitle(
                            fontSize: 12.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedVelocityPill(
                          totalSegments: totalTasks,
                          completedSegments: completedCount,
                          activeColor: AppTheme.accentEmerald,
                          velocityLabel: completionPct >= 1.0
                              ? '100% Target Reached!'
                              : (totalTasks - completedCount > 0
                                  ? '${totalTasks - completedCount} tasks remaining'
                                  : 'No tasks scheduled'),
                          isPositiveVelocity: completionPct >= 0.5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. 14-Day Consistency Matrix ───────────────────────────────
            Text(
              '14-DAY ACTIVITY MATRIX',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.sketchDecoration(
                backgroundColor: AppTheme.cardWhite,
                borderRadius: 20,
                shadowOffset: 3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Task Activity',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Text(
                        '$streak-day streak',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentAmber,
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
                          ? (20 + (50 * (count / maxDayCount))).clamp(20.0, 70.0)
                          : 6.0;

                      return Expanded(
                        child: Column(
                          children: [
                            Text(
                              count > 0 ? '$count' : '',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: height,
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              decoration: BoxDecoration(
                                color: count > 0
                                    ? (isToday
                                        ? AppTheme.accentPrimary
                                        : AppTheme.accentEmerald)
                                    : (AppTheme.current.isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : AppTheme.borderLight),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              d['label'] as String,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                                color: isToday ? AppTheme.inkForeground : AppTheme.mutedText,
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

            const SizedBox(height: 20),

            // ── 3. Task Category Breakdown ─────────────────────────────────
            Text(
              'TODAY\'S CATEGORY DISTRIBUTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 8),

            if (tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.sketchDecoration(
                  backgroundColor: AppTheme.cardWhite,
                  borderRadius: 18,
                ),
                alignment: Alignment.center,
                child: Text(
                  'No tasks scheduled on desk pad today.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedText,
                  ),
                ),
              )
            else
              ...categoryCounts.entries.map((entry) {
                final category = entry.key;
                final count = entry.value;
                final done = categoryCompleted[category] ?? 0;
                final catPct = count > 0 ? (done / count) : 0.0;

                final (catName, catColor, catIcon) = switch (category) {
                  TaskCategory.video => (
                      'Lectures / Videos',
                      AppTheme.accentPrimary,
                      Icons.play_circle_outline_rounded
                    ),
                  TaskCategory.qbank => (
                      'QBank MCQs',
                      AppTheme.accentSecondary,
                      Icons.quiz_outlined
                    ),
                  TaskCategory.revision => (
                      'Revision & Flashcards',
                      AppTheme.accentTertiary,
                      Icons.refresh_rounded
                    ),
                  TaskCategory.notes => (
                      'Notes & Reading',
                      AppTheme.accentQuaternary,
                      Icons.menu_book_rounded
                    ),
                  TaskCategory.general => (
                      'General Tasks',
                      AppTheme.accentEmerald,
                      Icons.check_circle_outline_rounded
                    ),
                };

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 18,
                    shadowOffset: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(catIcon, size: 18, color: catColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              catName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ),
                          Text(
                            '$done/$count (${(catPct * 100).round()}%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: catPct >= 1.0 ? AppTheme.accentEmerald : AppTheme.inkForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: catPct,
                          minHeight: 5,
                          backgroundColor: AppTheme.current.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.borderLight,
                          valueColor: AlwaysStoppedAnimation(catColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // ── 4. Today's Desk Pad Items ─────────────────────────────────
            Text(
              'TODAY\'S DESK PAD ITEMS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 8),

            if (tasks.isNotEmpty)
              ...tasks.map((task) {
                final isDone = completedIds.contains(task.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isDone
                            ? AppTheme.accentEmerald
                            : AppTheme.mutedText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDone
                                ? AppTheme.mutedText
                                : AppTheme.inkForeground,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
