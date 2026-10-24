import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/focus_timer_provider.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/tasks_theme.dart';
import '../../widgets/tasks/task_row.dart';
import '../../widgets/tasks/tasks_quick_add_sheet.dart';
import '../../widgets/tasks/tasks_theme_wrapper.dart';

class ThisWeekPage extends ConsumerWidget {
  const ThisWeekPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksHubProvider);

    return TasksThemeWrapper(
      child: Scaffold(
        backgroundColor: TasksTheme.background,
        appBar: AppBar(
          title: const Text('This Week'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_vert_rounded, size: 22),
              onPressed: () {},
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: TasksTheme.accent,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => TasksQuickAddSheet(
                initialDueDate: DateTime.now().add(const Duration(days: 2)),
              ),
            );
          },
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
        body: tasksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: TasksTheme.accent),
          ),
          error: (err, _) => Center(
            child: Text('Error: $err', style: const TextStyle(color: TasksTheme.textSecondary)),
          ),
          data: (state) {
            final tasks = state.thisWeekTasks;
            if (tasks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 54, color: TasksTheme.textTertiary),
                    SizedBox(height: 12),
                    Text(
                      'No tasks scheduled for this week',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: TasksTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap + to schedule an upcoming task',
                      style: TextStyle(
                        fontSize: 13,
                        color: TasksTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Container(height: 1, color: TasksTheme.divider),
              ),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskRow(
                  task: task,
                  onToggle: () => ref.read(tasksHubProvider.notifier).toggleComplete(task.id),
                  onPlay: () {
                    ref.read(focusTimerProvider.notifier).startTaskItemFocus(task);
                    context.push('/timer');
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
