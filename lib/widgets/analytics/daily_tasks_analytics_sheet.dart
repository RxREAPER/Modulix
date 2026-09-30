import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../theme/app_theme.dart';

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
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(checkDay);
      if ((dateHistory[key] ?? 0) > 0) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
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
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal, width: 1.5),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY TASKS ANALYTICS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.teal,
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

          const Divider(height: 1, color: AppTheme.borderLight),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Today's Completion Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 20,
                    shadowOffset: 4,
                  ),
                  child: Row(
                    children: [
                      // Radial Progress
                      SizedBox(
                        width: 82,
                        height: 82,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: completionPct,
                              strokeWidth: 9,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.teal),
                            ),
                            Text(
                              '${(completionPct * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TODAY\'S DESK PAD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCount of $totalTasks Done',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                            Text(
                              totalTasks == 0
                                  ? 'No tasks configured for today'
                                  : (completedCount == totalTasks
                                      ? '🎉 All daily targets cleared!'
                                      : '${totalTasks - completedCount} tasks remaining'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: completedCount == totalTasks && totalTasks > 0
                                    ? Colors.green.shade700
                                    : AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Streak & Consistency Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.sketchDecoration(
                          backgroundColor: Colors.white,
                          borderRadius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TASK STREAK',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.mutedText)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('$streak',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.inkForeground)),
                                const SizedBox(width: 4),
                                const Text('days 🔥',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange)),
                              ],
                            ),
                            const Text('Any task done',
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
                          backgroundColor: Colors.white,
                          borderRadius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ACTIVE DAYS',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.mutedText)),
                            const SizedBox(height: 4),
                            Text('${dateHistory.length}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.inkForeground)),
                            const Text('Days recorded',
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
                const Text(
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderLight, width: 1.2),
                    ),
                    child: const Center(
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone ? Colors.green.shade200 : AppTheme.borderLight,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isDone ? Colors.green : Colors.grey.shade400,
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
