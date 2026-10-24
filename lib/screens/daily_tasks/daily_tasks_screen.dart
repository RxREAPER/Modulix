import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/syllabus.dart' show Subject, Chapter;
import '../../models/task_item.dart';
import '../../models/task_project.dart';
import '../../providers/focus_timer_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';

class DailyTasksScreen extends ConsumerStatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  ConsumerState<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends ConsumerState<DailyTasksScreen> {
  int _selectedTabIndex = 0; // 0: Tasks, 1: Projects
  final TextEditingController _taskTextController = TextEditingController();
  final FocusNode _taskFocusNode = FocusNode();

  String? _activeAddingProjectId;
  final TextEditingController _projectTaskController = TextEditingController();
  final FocusNode _projectTaskFocusNode = FocusNode();

  @override
  void dispose() {
    _taskTextController.dispose();
    _taskFocusNode.dispose();
    _projectTaskController.dispose();
    _projectTaskFocusNode.dispose();
    super.dispose();
  }

  void _submitTask() {
    final text = _taskTextController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final task = TaskItem(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      title: text,
      dueDate: today,
      createdAt: now,
      updatedAt: now,
    );

    HapticFeedback.lightImpact();
    ref.read(tasksHubProvider.notifier).addTask(task);
    _taskTextController.clear();
  }

  void _submitProjectTask(TaskProject project) {
    final text = _projectTaskController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final task = TaskItem(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      title: text,
      projectId: project.id,
      note: '${project.subjectName ?? ""} · ${project.unitName ?? ""}',
      dueDate: today,
      createdAt: now,
      updatedAt: now,
    );

    HapticFeedback.lightImpact();
    ref.read(tasksHubProvider.notifier).addTask(task);
    _projectTaskController.clear();
    setState(() => _activeAddingProjectId = null);
  }

  @override
  Widget build(BuildContext context) {
    final tasksStateAsync = ref.watch(tasksHubProvider);
    final timerState = ref.watch(focusTimerProvider);

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: ApplePressable(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          child: Container(
            alignment: Alignment.center,
            child: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground, size: 22),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Text(
                'Daily tasks',
                style: AppTheme.headingStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkForeground,
                ),
              ),
              const Spacer(),
              _buildTactileSwitcher(),
            ],
          ),
        ),
      ),
      body: tasksStateAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (err, _) => Center(
          child: Text('Error loading tasks', style: TextStyle(color: AppTheme.mutedText)),
        ),
        data: (state) {
          if (_selectedTabIndex == 0) {
            return _buildTasksView(state, timerState);
          } else {
            return _buildProjectsView(state, timerState);
          }
        },
      ),
    );
  }

  Widget _buildTactileSwitcher() {
    return Container(
      width: 164,
      height: 34,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: AppTheme.parchmentSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight, width: 1),
      ),
      child: Stack(
        children: [
          // Smooth Animated Sliding Indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: _selectedTabIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.inkForeground,
                  borderRadius: BorderRadius.circular(7.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.inkForeground.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Interactive Segment Touch Targets with Icons
          Row(
            children: [
              Expanded(
                child: ApplePressable(
                  onTap: () {
                    if (_selectedTabIndex != 0) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTabIndex = 0);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 13,
                        color: _selectedTabIndex == 0 ? AppTheme.paperBackground : AppTheme.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTabIndex == 0 ? AppTheme.paperBackground : AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ApplePressable(
                  onTap: () {
                    if (_selectedTabIndex != 1) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTabIndex = 1);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 13,
                        color: _selectedTabIndex == 1 ? AppTheme.paperBackground : AppTheme.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Projects',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTabIndex == 1 ? AppTheme.paperBackground : AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // METHOD 1: NORMAL TASKS (Text, Check-off Left, Play Right)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTasksView(TasksHubState state, FocusTimerState timerState) {
    final todayTasks = state.todayTasks;
    final completedTasks = state.todayCompletedTasks;

    return Column(
      children: [
        // Sleek Minimalist Unboxed Input (Organic on Paper)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderLight.withValues(alpha: 0.8),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 19,
                  color: AppTheme.mutedText.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _taskTextController,
                    focusNode: _taskFocusNode,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.inkForeground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a daily task...',
                      hintStyle: TextStyle(
                        fontSize: 14.5,
                        color: AppTheme.mutedText.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _submitTask(),
                  ),
                ),
                ApplePressable(
                  onTap: _submitTask,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.inkForeground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 13,
                      color: AppTheme.paperBackground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Unboxed Vertical Task List
        Expanded(
          child: (todayTasks.isEmpty && completedTasks.isEmpty)
              ? Center(
                  child: Text(
                    'No daily tasks yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.mutedText,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  children: [
                    // Active Tasks
                    for (final task in todayTasks)
                      _buildTaskRow(
                        task: task,
                        isDone: false,
                        timerState: timerState,
                      ),

                    // Completed Section
                    if (completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'COMPLETED (${completedTasks.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              height: 1,
                              thickness: 0.6,
                              color: AppTheme.borderLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (final task in completedTasks)
                        _buildTaskRow(
                          task: task,
                          isDone: true,
                          timerState: timerState,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTaskRow({
    required TaskItem task,
    required bool isDone,
    required FocusTimerState timerState,
  }) {
    final isFocusActive = timerState.isRunning && timerState.boundTaskId == task.id;

    return Dismissible(
      key: ValueKey('task_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        ref.read(tasksHubProvider.notifier).deleteTask(task.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.mutedText),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.borderLight.withValues(alpha: 0.5),
              width: 0.6,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Check-off to the left
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(tasksHubProvider.notifier).toggleTaskComplete(task.id);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppTheme.inkForeground : Colors.transparent,
                    border: Border.all(
                      color: isDone
                          ? AppTheme.inkForeground
                          : AppTheme.mutedText.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: AppTheme.paperBackground,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Task text in middle
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isDone ? FontWeight.w400 : FontWeight.w500,
                  color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: AppTheme.mutedText,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Play button to the right
            ApplePressable(
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(focusTimerProvider.notifier).startTaskItemFocus(task);
                context.push('/timer');
              },
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 21,
                  color: isFocusActive ? AppTheme.accentPrimary : AppTheme.inkForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // METHOD 2: PROJECTS (Subject + Unit Selection + Project Analytics)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildProjectsView(TasksHubState state, FocusTimerState timerState) {
    final projects = state.activeProjects;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      children: [
        // Action Bar: + New project
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${projects.length} ${projects.length == 1 ? "project" : "projects"}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),
            ApplePressable(
              onTap: () => _openNewProjectSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.inkForeground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: AppTheme.paperBackground),
                    const SizedBox(width: 4),
                    Text(
                      'New project',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.paperBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No projects yet · Tap New project to start',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          )
        else
          for (final proj in projects)
            _buildProjectCard(
              project: proj,
              tasks: state.tasksForProject(proj.id),
              timerState: timerState,
            ),
      ],
    );
  }

  Widget _buildProjectCard({
    required TaskProject project,
    required List<TaskItem> tasks,
    required FocusTimerState timerState,
  }) {
    final totalCount = tasks.length;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final progressRatio = totalCount == 0 ? 0.0 : (completedCount / totalCount);
    final progressPercent = (progressRatio * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Title & Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (project.subjectName ?? 'Subject').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.unitName ?? project.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete project option
              ApplePressable(
                onTap: () => _confirmDeleteProject(project),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.more_horiz_rounded, size: 20, color: AppTheme.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // PROJECT ANALYTICS
          // Sleek 2.5px progress line
          Container(
            height: 2.5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressRatio.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.inkForeground,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Analytics metrics text & + Add task action
          Row(
            children: [
              Text(
                '$completedCount / $totalCount tasks · $progressPercent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.inkForeground,
                ),
              ),
              const Spacer(),
              ApplePressable(
                onTap: () {
                  setState(() {
                    if (_activeAddingProjectId == project.id) {
                      _activeAddingProjectId = null;
                    } else {
                      _activeAddingProjectId = project.id;
                      _projectTaskController.clear();
                      Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _projectTaskFocusNode.requestFocus(),
                      );
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _activeAddingProjectId == project.id ? Icons.close_rounded : Icons.add_rounded,
                        size: 13,
                        color: AppTheme.inkForeground,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _activeAddingProjectId == project.id ? 'Cancel' : 'Add task',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Organic Inline Input for Project
          if (_activeAddingProjectId == project.id) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.inkForeground.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.mutedText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _projectTaskController,
                      focusNode: _projectTaskFocusNode,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.inkForeground,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add task to ${project.unitName ?? project.name}...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.mutedText.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _submitProjectTask(project),
                    ),
                  ),
                  ApplePressable(
                    onTap: () => _submitProjectTask(project),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.inkForeground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 12,
                        color: AppTheme.paperBackground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Empty state for project without tasks
          if (tasks.isEmpty && _activeAddingProjectId != project.id)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No custom tasks yet · Tap Add task above to start',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.mutedText,
                ),
              ),
            ),

          // List of Project Tasks (Text, Check-off Left, Play Right)
          for (final task in tasks)
            _buildTaskRow(
              task: task,
              isDone: task.isCompleted,
              timerState: timerState,
            ),
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 0.6, color: AppTheme.borderLight),
        ],
      ),
    );
  }

  void _confirmDeleteProject(TaskProject project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        title: Text(
          'Delete project',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.inkForeground),
        ),
        content: Text(
          'Remove "${project.name}" and its tasks?',
          style: TextStyle(fontSize: 14, color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mutedText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              await ref.read(tasksHubProvider.notifier).deleteProject(project.id);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROJECT CREATION FLOW (Subject Selection -> Unit Selection)
  // ═══════════════════════════════════════════════════════════════════

  void _openNewProjectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NewProjectModal(),
    );
  }
}

class _NewProjectModal extends ConsumerStatefulWidget {
  const _NewProjectModal();

  @override
  ConsumerState<_NewProjectModal> createState() => _NewProjectModalState();
}

class _NewProjectModalState extends ConsumerState<_NewProjectModal> {
  Subject? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final syllabusAsync = ref.watch(activeSyllabusProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedSubject == null
                      ? 'Select subject'
                      : 'Select unit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkForeground,
                  ),
                ),
                if (_selectedSubject != null)
                  ApplePressable(
                    onTap: () {
                      setState(() {
                        _selectedSubject = null;
                      });
                    },
                    child: Text(
                      'Back',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.mutedText),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.6, color: AppTheme.borderLight),

          Expanded(
            child: syllabusAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => Center(
                child: Text('Failed to load syllabus', style: TextStyle(color: AppTheme.mutedText)),
              ),
              data: (subjects) {
                if (_selectedSubject == null) {
                  // STEP 1: Select Subject
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: subjects.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppTheme.borderLight.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final sub = subjects[index];
                      return ApplePressable(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedSubject = sub);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sub.displayName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.inkForeground,
                                  ),
                                ),
                              ),
                              Text(
                                '${sub.chapters.length} units',
                                style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.mutedText),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // STEP 2: Select Unit
                  final chapters = _selectedSubject!.chapters;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: chapters.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppTheme.borderLight.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final ch = chapters[index];
                      return ApplePressable(
                        onTap: () => _confirmCreateProject(ch),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ch.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.inkForeground,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ch.videos.length} video modules',
                                      style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.add_rounded, size: 20, color: AppTheme.inkForeground),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCreateProject(Chapter chapter) async {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);

    await ref.read(tasksHubProvider.notifier).createSelfStudyProject(
      name: '${_selectedSubject!.displayName} · ${chapter.name}',
      subjectId: _selectedSubject!.id,
      subjectName: _selectedSubject!.displayName,
      unitName: chapter.name,
    );
  }
}
