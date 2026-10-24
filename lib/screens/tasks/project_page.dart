import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/subjects_metadata.dart';
import '../../models/task_project.dart';
import '../../models/time_log.dart';
import '../../providers/focus_timer_provider.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../services/database_service.dart';
import '../../theme/tasks_theme.dart';
import '../../widgets/tasks/task_row.dart';
import '../../widgets/tasks/tasks_quick_add_sheet.dart';
import '../../widgets/tasks/tasks_theme_wrapper.dart';

class ProjectPage extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends ConsumerState<ProjectPage> {
  Future<List<TimeLog>>? _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    final state = ref.read(tasksHubProvider).valueOrNull;
    final project = state?.projects.where((p) => p.id == widget.projectId).firstOrNull;
    if (project != null && project.subjectId != null) {
      _sessionsFuture = DatabaseService.instance.getTimeLogsForSubject(project.subjectId!);
    }
  }

  void _showEditProjectDialog(TaskProject project) {
    final titleController = TextEditingController(text: project.name);
    DateTime? deadline = project.deadline;
    int pace = project.perDayModules ?? 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            decoration: const BoxDecoration(
              color: TasksTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: TasksTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Edit Project',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: TasksTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(fontSize: 15, color: TasksTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      labelStyle: const TextStyle(color: TasksTheme.textSecondary),
                      filled: true,
                      fillColor: TasksTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: TasksTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: TasksTheme.accent),
                      ),
                    ),
                  ),
                  if (project.isModuleBased) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Pace', style: TextStyle(color: TasksTheme.textPrimary)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                              onPressed: pace > 1 ? () => setSheetState(() => pace--) : null,
                            ),
                            Text('$pace/day', style: const TextStyle(fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                              onPressed: pace < 10 ? () => setSheetState(() => pace++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Deadline', style: TextStyle(color: TasksTheme.textPrimary)),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: deadline ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(() => deadline = picked);
                          }
                        },
                        child: Text(
                          deadline != null
                              ? DateFormat('dd MMM yyyy').format(deadline!)
                              : 'None (Set)',
                          style: const TextStyle(color: TasksTheme.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TasksTheme.accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final newName = titleController.text.trim();
                        if (newName.isEmpty) return;
                        final updated = project.copyWith(
                          name: newName,
                          deadline: deadline,
                          perDayModules: pace,
                        );
                        await ref.read(tasksHubProvider.notifier).updateProject(updated);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(String projectId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TasksTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Project', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text(
          'Delete this project and all its associated tasks?',
          style: TextStyle(fontSize: 14, color: TasksTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: TasksTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(tasksHubProvider.notifier).deleteProject(projectId);
              if (mounted) Navigator.of(context).maybePop();
            },
            child: const Text('Delete', style: TextStyle(color: TasksTheme.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          final project = state.projects.where((p) => p.id == widget.projectId).firstOrNull;
          final title = project?.name ?? 'Project';
          final meta = project?.subjectId != null
              ? subjectMeta(project!.subjectId!)
              : const SubjectMeta(
                  accent: Color(0xFF10B981),
                  bgLight: Color(0xFFECFDF5),
                  bgDark: Color(0xFF064E3B),
                  icon: Icons.menu_book_rounded,
                  displayName: 'General Study',
                );
          final activeTasks = state.activeTasksForProject(widget.projectId);
          final completedTasks = state.completedTasksForProject(widget.projectId);
          final totalTasks = activeTasks.length + completedTasks.length;
          final progressRatio = totalTasks > 0 ? completedTasks.length / totalTasks : 0.0;

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
                        _showEditProjectDialog(project);
                      } else if (val == 'archive') {
                        ref.read(tasksHubProvider.notifier).toggleArchiveProject(widget.projectId);
                      } else if (val == 'delete') {
                        _showDeleteConfirmation(widget.projectId);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Project')),
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(project.isArchived ? 'Unarchive Project' : 'Archive Project'),
                      ),
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
                    initialProjectId: widget.projectId,
                  ),
                );
              },
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Editorial Project Header (Airy, Borderless, Modern)
                if (project != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category / Subject Indicator Row with Borderless Subject Icon
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(meta.icon, size: 22, color: meta.accent),
                              const SizedBox(width: 8),
                              Text(
                                project.isModuleBased
                                    ? 'MODULE BASED'
                                    : 'SELF STUDY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: meta.accent,
                                ),
                              ),
                              if (project.unitName != null && project.unitName!.isNotEmpty) ...[
                                const Text(
                                  '  ·  ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: TasksTheme.textTertiary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    project.unitName!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: TasksTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Project Title
                          Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: TasksTheme.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Fluid Progress Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$totalTasks tasks · ${completedTasks.length} done',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: TasksTheme.textSecondary,
                                ),
                              ),
                              Text(
                                '${(progressRatio * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: meta.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              minHeight: 5,
                              backgroundColor: TasksTheme.surface,
                              color: meta.accent,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Unboxed Horizontal Metrics Strip
                          _buildMetricsStrip(project, meta),
                        ],
                      ),
                    ),
                  ),

                // Active Tasks
                if (activeTasks.isEmpty && completedTasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
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
                    ),
                  )
                else ...[
                  if (activeTasks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Text(
                          'TASKS (${activeTasks.length})',
                          style: TasksTheme.sectionLabel,
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = activeTasks[index];
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TaskRow(
                                task: task,
                                projectTitle: project?.name,
                                onToggle: () => ref
                                    .read(tasksHubProvider.notifier)
                                    .toggleComplete(task.id),
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
                          );
                        },
                        childCount: activeTasks.length,
                      ),
                    ),
                  ],

                  if (completedTasks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text(
                          'COMPLETED (${completedTasks.length})',
                          style: TasksTheme.sectionLabel,
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
                                projectTitle: project?.name,
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsStrip(TaskProject project, SubjectMeta meta) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: TasksTheme.divider),
          bottom: BorderSide(color: TasksTheme.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              label: project.isModuleBased ? 'DAILY PACE' : 'STUDY MODE',
              value: project.isModuleBased
                  ? '${project.perDayModules ?? 2} modules/day'
                  : 'Self Study',
              icon: Icons.speed_rounded,
              accent: meta.accent,
            ),
          ),
          Container(width: 1, height: 28, color: TasksTheme.divider),
          Expanded(
            child: _buildMetricItem(
              label: 'DEADLINE',
              value: project.deadline != null
                  ? DateFormat('dd MMM yyyy').format(project.deadline!)
                  : 'Open-ended',
              icon: Icons.event_rounded,
              accent: meta.accent,
            ),
          ),
          if (_sessionsFuture != null) ...[
            Container(width: 1, height: 28, color: TasksTheme.divider),
            Expanded(
              child: FutureBuilder<List<TimeLog>>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  int totalSecs = 0;
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    for (final log in snapshot.data!) {
                      if (project.unitName != null && project.unitName!.isNotEmpty) {
                        if (log.chapterName.toLowerCase().contains(project.unitName!.toLowerCase())) {
                          totalSecs += log.durationSecs;
                        }
                      } else {
                        totalSecs += log.durationSecs;
                      }
                    }
                  }
                  final hours = totalSecs ~/ 3600;
                  final mins = (totalSecs % 3600) ~/ 60;
                  final timeStr = hours > 0
                      ? '${hours}h ${mins}m'
                      : (mins > 0 ? '${mins}m' : '0m');

                  return _buildMetricItem(
                    label: 'STUDY LOGS',
                    value: timeStr,
                    icon: Icons.timer_outlined,
                    accent: meta.accent,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: TasksTheme.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: TasksTheme.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TasksTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
