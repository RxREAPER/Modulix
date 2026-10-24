import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/tasks_theme.dart';
import '../../widgets/tasks/add_project_sheet.dart';
import '../../widgets/tasks/task_row.dart';
import '../../widgets/tasks/tasks_quick_add_sheet.dart';
import '../../widgets/tasks/tasks_theme_wrapper.dart';

class ProjectPage extends ConsumerWidget {
  final String projectId;

  const ProjectPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksHubProvider);

    return TasksThemeWrapper(
      child: tasksAsync.when(
        loading: () => Scaffold(
          backgroundColor: TasksTheme.background,
          appBar: AppBar(title: const Text('Project')),
          body: const Center(
            child: CircularProgressIndicator(color: TasksTheme.accent),
          ),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: TasksTheme.background,
          appBar: AppBar(title: const Text('Project')),
          body: Center(child: Text('Error: $err')),
        ),
        data: (state) {
          final project = state.projects.where((p) => p.id == projectId).firstOrNull;
          final title = project?.name ?? 'Project';
          final tasks = state.tasksForProject(projectId);

          return Scaffold(
            backgroundColor: TasksTheme.background,
            appBar: AppBar(
              title: Text(title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                if (project != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 22),
                    onSelected: (val) {
                      if (val == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddProjectSheet(existing: project),
                        );
                      } else if (val == 'delete') {
                        ref.read(tasksHubProvider.notifier).deleteProject(projectId);
                        Navigator.of(context).maybePop();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Project')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Project', style: TextStyle(color: TasksTheme.accent)),
                      ),
                    ],
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
                    initialProjectId: projectId,
                  ),
                );
              },
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
            body: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_open_outlined, size: 54, color: TasksTheme.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks in $title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: TasksTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + to add a task to this project',
                          style: TextStyle(
                            fontSize: 13,
                            color: TasksTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
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
                        onToggle: () =>
                            ref.read(tasksHubProvider.notifier).toggleComplete(task.id),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
