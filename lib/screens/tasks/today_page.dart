import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/focus_timer_provider.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/tasks_theme.dart';
import '../../widgets/tasks/task_row.dart';
import '../../widgets/tasks/tasks_quick_add_sheet.dart';
import '../../widgets/tasks/tasks_theme_wrapper.dart';

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  final Set<String> _animatingTaskIds = {};

  Future<void> _handleToggle(String taskId) async {
    setState(() => _animatingTaskIds.add(taskId));
    await Future.delayed(const Duration(milliseconds: 280));
    if (mounted) {
      await ref.read(tasksHubProvider.notifier).toggleComplete(taskId);
      if (mounted) {
        setState(() => _animatingTaskIds.remove(taskId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksHubProvider);

    return TasksThemeWrapper(
      child: Scaffold(
        backgroundColor: TasksTheme.background,
        appBar: AppBar(
          title: const Text('Today'),
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
                initialDueDate: DateTime.now(),
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
            final activeTasks = state.todayTasks;
            final completedTasks = state.todayCompletedTasks;

            if (activeTasks.isEmpty && completedTasks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 54, color: TasksTheme.textTertiary),
                    SizedBox(height: 12),
                    Text(
                      'No tasks for today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: TasksTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap + to create a task',
                      style: TextStyle(
                        fontSize: 13,
                        color: TasksTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (activeTasks.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = activeTasks[index];
                        final isAnimating = _animatingTaskIds.contains(task.id);

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(task.id),
                          duration: const Duration(milliseconds: 260),
                          tween: Tween<double>(
                            begin: 0.0,
                            end: isAnimating ? 1.0 : 0.0,
                          ),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value * 30.0, value * 15.0),
                              child: Opacity(
                                opacity: (1.0 - value * 0.6).clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TaskRow(
                                task: isAnimating
                                    ? task.copyWith(isCompleted: true)
                                    : task,
                                onToggle: () => _handleToggle(task.id),
                                onPlay: () {
                                  ref
                                      .read(focusTimerProvider.notifier)
                                      .startTaskItemFocus(task);
                                  context.push('/timer');
                                },
                              ),
                              if (index < activeTasks.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(left: 56),
                                  child: Container(height: 1, color: TasksTheme.divider),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: activeTasks.length,
                    ),
                  ),

                if (completedTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        children: [
                          const Text(
                            'COMPLETED',
                            style: TasksTheme.sectionLabel,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${completedTasks.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: TasksTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = completedTasks[index];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TaskRow(
                              task: task,
                              onToggle: () => ref
                                  .read(tasksHubProvider.notifier)
                                  .toggleComplete(task.id),
                            ),
                            if (index < completedTasks.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Container(height: 1, color: TasksTheme.divider),
                              ),
                          ],
                        );
                      },
                      childCount: completedTasks.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
