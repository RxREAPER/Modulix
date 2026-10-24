import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/subjects_metadata.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/tasks_theme.dart';
import '../../widgets/tasks/project_setup_catalogue_sheet.dart';
import '../../widgets/tasks/tasks_bucket_row.dart';
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
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Text(
                            'Tasks',
                            style: TasksTheme.headlineLarge,
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
                                '${state.activeProjects.length}',
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
                      if (state.activeProjects.isEmpty)
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
                              final proj = state.activeProjects[index];
                              final meta = proj.subjectId != null
                                  ? subjectMeta(proj.subjectId!)
                                  : null;
                              final pColor = meta?.accent ?? _hexToColor(proj.colorHex);
                              final pIcon = meta?.icon ??
                                  (proj.isModuleBased
                                      ? Icons.view_timeline_outlined
                                      : Icons.menu_book_rounded);
                              final pTasks = state.activeTasksForProject(proj.id);
                              final pHours = state.projectEstimatedHours(proj.id);

                              return TasksBucketRow(
                                icon: Icon(
                                  pIcon,
                                  color: pColor,
                                  size: 24,
                                ),
                                label: proj.name,
                                estimatedHours: pHours,
                                taskCount: pTasks.length,
                                onTap: () => context.push('/tasks/project/${proj.id}'),
                              );
                            },
                            childCount: state.activeProjects.length,
                          ),
                        ),

                      // Add Project Button Row
                      SliverToBoxAdapter(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ProjectSetupCatalogueSheet.show(context);
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

                      // Archived Projects Section if any
                      if (state.archivedProjects.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'ARCHIVED PROJECTS (${state.archivedProjects.length})',
                              style: TasksTheme.sectionLabel,
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final proj = state.archivedProjects[index];
                              return TasksBucketRow(
                                icon: const Icon(
                                  Icons.archive_outlined,
                                  color: TasksTheme.textTertiary,
                                  size: 22,
                                ),
                                label: proj.name,
                                estimatedHours: 0.0,
                                taskCount: 0,
                                onTap: () => context.push('/tasks/project/${proj.id}'),
                              );
                            },
                            childCount: state.archivedProjects.length,
                          ),
                        ),
                      ],

                      // Bottom spacing for Nav Bar
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 36),
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
