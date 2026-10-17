import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../theme/app_theme.dart';
import 'analytics_progress_hero_card.dart';

class DailyTasksAnalyticsSheet extends ConsumerWidget {
  const DailyTasksAnalyticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const DailyTasksAnalyticsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayStartHour = ref.watch(appStateProvider.select((s) => s.valueOrNull?.dayStartHour ?? 5));
    final tasksState = ref.watch(dailyTasksProvider);
    final tasks = tasksState.tasks;
    final completedIds = tasksState.completedIds;
    final dateHistory = tasksState.dateHistory;

    final totalTasks = tasks.length;
    final completedCount = tasks.where((t) => completedIds.contains(t.id)).length;
    final completionPct = totalTasks > 0 ? (completedCount / totalTasks).clamp(0.0, 1.0) : 0.0;

    // Calculate streak (consecutive days with at least 1 completed task)
    int streak = 0;
    final now = DateTime.now().subtract(Duration(hours: dayStartHour));
    DateTime checkDay = now;

    // Check if today has at least 1 done
    final todayKey = DateFormat('yyyy-MM-dd').format(checkDay);
    if ((dateHistory[todayKey] ?? 0) > 0 || completedCount > 0) {
      streak = 1;
      checkDay = DateTime(now.year, now.month, now.day - 1);
    } else {
      // Today has 0 completed tasks: start backward traversal from yesterday
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          left: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          right: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accentPrimary, width: 1.5),
                  ),
                  child: Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.accentPrimary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY TASKS ANALYTICS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                      Text(
                        'Desk Pad Consistency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.borderLight),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Today's Completion Card
                AnalyticsProgressHeroCard(
                  progress: completionPct,
                  progressColor: AppTheme.accentPrimary,
                  tagLabel: "Today's Desk Pad",
                  primaryValue: '$completedCount of $totalTasks Done',
                  secondaryLabel: totalTasks == 0
                      ? 'No tasks configured for today'
                      : (completedCount == totalTasks
                          ? 'All daily targets cleared!'
                          : '${totalTasks - completedCount} tasks remaining'),
                ),

                const SizedBox(height: 20),

                // Streak & Consistency Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.sketchDecoration(
                          backgroundColor: AppTheme.cardWhite,
                          borderRadius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TASK STREAK',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.mutedText)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('$streak',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.inkForeground)),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 15,
                                  color: AppTheme.accentPrimary,
                                ),
                                const SizedBox(width: 2),
                                Text('days',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accentPrimary)),
                              ],
                            ),
                            Text('Any task done',
                                style: TextStyle(
                                    fontSize: 10, color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.sketchDecoration(
                          backgroundColor: AppTheme.cardWhite,
                          borderRadius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ACTIVE DAYS',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.mutedText)),
                            const SizedBox(height: 4),
                            Text('${dateHistory.length}',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.inkForeground)),
                            Text('Days recorded',
                                style: TextStyle(
                                    fontSize: 10, color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Today's Tasks Status List
                Text(
                  'TODAY\'S TASKS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 10),

                if (tasks.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderLight, width: 1.2),
                    ),
                    child: Center(
                      child: Text(
                        'No tasks on your desk pad today.\nAdd tasks from the Home screen!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                      ),
                    ),
                  ),
                ] else ...[
                  ...List.generate(tasks.length, (i) {
                    final t = tasks[i];
                    final isDone = completedIds.contains('task_$i');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone ? AppTheme.accentPrimary.withValues(alpha: 0.35) : AppTheme.borderLight,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isDone ? AppTheme.accentPrimary : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isDone ? FontWeight.w600 : FontWeight.w700,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: isDone
                                    ? AppTheme.mutedText
                                    : AppTheme.inkForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
