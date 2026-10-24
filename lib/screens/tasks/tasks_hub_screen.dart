import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/tasks_theme.dart';
import '../../widgets/tasks/add_project_sheet.dart';
import '../../widgets/tasks/tasks_bucket_row.dart';
import '../../widgets/tasks/tasks_quick_add_sheet.dart';
import '../../widgets/tasks/tasks_theme_wrapper.dart';

class TasksHubScreen extends ConsumerWidget {
  const TasksHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(tasksHubProvider);

    return TasksThemeWrapper(
      child: Scaffold(
        backgroundColor: TasksTheme.background,
        body: SafeArea(
          bottom: false,
          child: stateAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: TasksTheme.accent),
            ),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (state) {
              return Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tasks',
                                style: TasksTheme.headlineLarge,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.swap_vert_rounded,
                                  color: TasksTheme.textSecondary,
                                  size: 24,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Time Buckets
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TasksBucketRow(
                              icon: const Icon(
                                Icons.wb_sunny_outlined,
                                color: Color(0xFF22C55E),
                                size: 24,
                              ),
                              label: 'Today',
                              estimatedHours: state.todayEstimatedHours,
                              taskCount: state.todayTasks.length,
                              onTap: () => context.push('/tasks/today'),
                            ),
                            TasksBucketRow(
                              icon: const Icon(
                                Icons.wb_twilight_outlined,
                                color: Color(0xFFF97316),
                                size: 24,
                              ),
                              label: 'Tomorrow',
                              estimatedHours: state.tomorrowEstimatedHours,
                              taskCount: state.tomorrowTasks.length,
                              onTap: () => context.push('/tasks/tomorrow'),
                            ),
                            TasksBucketRow(
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                color: Color(0xFF3B82F6),
                                size: 24,
                              ),
                              label: 'This Week',
                              estimatedHours: state.thisWeekEstimatedHours,
                              taskCount: state.thisWeekTasks.length,
                              onTap: () => context.push('/tasks/this-week'),
                            ),
                          ],
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),

                      // Projects Section Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PROJECTS',
                                style: TasksTheme.sectionLabel,
                              ),
                              Text(
                                '${state.projects.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TasksTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),

                      // Projects List
                      if (state.projects.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Text(
                              'No projects yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: TasksTheme.textTertiary,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final proj = state.projects[index];
                              final pColor = _hexToColor(proj.colorHex);
                              final pTasks = state.tasksForProject(proj.id);
                              final pHours = state.projectEstimatedHours(proj.id);

                              return TasksBucketRow(
                                icon: Icon(
                                  Icons.menu_rounded,
                                  color: pColor,
                                  size: 24,
                                ),
                                label: proj.name,
                                estimatedHours: pHours,
                                taskCount: pTasks.length,
                                onTap: () => context.push('/tasks/project/${proj.id}'),
                              );
                            },
                            childCount: state.projects.length,
                          ),
                        ),

                      // Add Project Button Row
                      SliverToBoxAdapter(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AddProjectSheet(),
                              );
                            },
                            splashColor: TasksTheme.accent.withValues(alpha: 0.08),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: TasksTheme.accent,
                                    size: 22,
                                  ),
                                  SizedBox(width: 14),
                                  Text(
                                    'Add Project',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: TasksTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom spacing for FAB and Nav Bar
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 120),
                      ),
                    ],
                  ),

                  // Floating Quick Add Pill / Circle at bottom
                  Positioned(
                    right: 20,
                    bottom: 90,
                    child: FloatingActionButton(
                      backgroundColor: TasksTheme.accent,
                      elevation: 4,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const TasksQuickAddSheet(),
                        );
                      },
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return TasksTheme.textTertiary;
    }
  }
}
