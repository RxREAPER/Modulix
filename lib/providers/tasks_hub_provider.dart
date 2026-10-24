import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/syllabus.dart' show Video;
import '../models/task_item.dart';
import '../models/task_project.dart';
import '../services/database_service.dart';

String _generateId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';

/// State container for the Tasks Hub.
class TasksHubState {
  final List<TaskItem> tasks;
  final List<TaskProject> projects;

  const TasksHubState({
    this.tasks = const [],
    this.projects = const [],
  });

  TasksHubState copyWith({
    List<TaskItem>? tasks,
    List<TaskProject>? projects,
  }) =>
      TasksHubState(
        tasks: tasks ?? this.tasks,
        projects: projects ?? this.projects,
      );

  // ─── Project buckets ───────────────────────────────────────────
  List<TaskProject> get activeProjects =>
      projects.where((p) => !p.isArchived).toList();

  List<TaskProject> get archivedProjects =>
      projects.where((p) => p.isArchived).toList();

  // ─── Computed task buckets ─────────────────────────────────────
  List<TaskItem> get todayTasks =>
      tasks.where((t) => !t.isCompleted && t.isToday).toList()
        ..sort(_byPriority);

  List<TaskItem> get todayCompletedTasks =>
      tasks.where((t) => t.isCompleted && t.isToday).toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));

  List<TaskItem> get tomorrowTasks =>
      tasks.where((t) => !t.isCompleted && t.isTomorrow).toList()
        ..sort(_byPriority);

  List<TaskItem> get tomorrowCompletedTasks =>
      tasks.where((t) => t.isCompleted && t.isTomorrow).toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));

  List<TaskItem> get thisWeekTasks =>
      tasks.where((t) => !t.isCompleted && t.isThisWeek).toList()
        ..sort((a, b) {
          if (a.dueDate != null && b.dueDate != null) {
            final cmp = a.dueDate!.compareTo(b.dueDate!);
            if (cmp != 0) return cmp;
          }
          return _byPriority(a, b);
        });

  List<TaskItem> get thisWeekCompletedTasks =>
      tasks.where((t) => t.isCompleted && t.isThisWeek).toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));

  List<TaskItem> tasksForProject(String projectId) =>
      tasks.where((t) => t.projectId == projectId).toList()
        ..sort(_byPriority);

  List<TaskItem> activeTasksForProject(String projectId) =>
      tasks.where((t) => t.projectId == projectId && !t.isCompleted).toList()
        ..sort(_byPriority);

  List<TaskItem> completedTasksForProject(String projectId) =>
      tasks.where((t) => t.projectId == projectId && t.isCompleted).toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));

  // ─── Estimated hours per bucket ───────────────────────────────
  double get todayEstimatedHours =>
      _toHours(todayTasks.fold(0, (s, t) => s + (t.estimatedMinutes ?? 25)));

  double get tomorrowEstimatedHours =>
      _toHours(tomorrowTasks.fold(0, (s, t) => s + (t.estimatedMinutes ?? 25)));

  double get thisWeekEstimatedHours =>
      _toHours(thisWeekTasks.fold(0, (s, t) => s + (t.estimatedMinutes ?? 25)));

  double projectEstimatedHours(String projectId) => _toHours(
      activeTasksForProject(projectId)
          .fold(0, (s, t) => s + (t.estimatedMinutes ?? 25)));

  static double _toHours(int mins) =>
      double.parse((mins / 60.0).toStringAsFixed(1));

  static int _byPriority(TaskItem a, TaskItem b) =>
      a.priority.level.compareTo(b.priority.level);
}

/// Riverpod AsyncNotifier managing [TasksHubState].
class TasksHubNotifier extends AsyncNotifier<TasksHubState> {
  @override
  Future<TasksHubState> build() async {
    final tasks = await _loadTasks();
    final projects = await _loadProjects();
    return TasksHubState(tasks: tasks, projects: projects);
  }

  // ─── Task CRUD ────────────────────────────────────────────────

  Future<void> addTask(TaskItem task) async {
    final db = await DatabaseService.instance.database;
    await db.insert('task_items', task.toMap());
    final tasks = <TaskItem>[...(state.value?.tasks ?? []), task];
    state = AsyncData(state.value!.copyWith(tasks: tasks));
  }

  Future<void> addTasksBatch(List<TaskItem> newTasks) async {
    if (newTasks.isEmpty) return;
    final db = await DatabaseService.instance.database;
    final batch = db.batch();
    for (final task in newTasks) {
      batch.insert('task_items', task.toMap());
    }
    await batch.commit(noResult: true);
    final tasks = <TaskItem>[...(state.value?.tasks ?? []), ...newTasks];
    state = AsyncData(state.value!.copyWith(tasks: tasks));
  }

  Future<void> updateTask(TaskItem task) async {
    final db = await DatabaseService.instance.database;
    final updated = task.copyWith(updatedAt: DateTime.now());
    await db.update(
      'task_items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    final tasks = <TaskItem>[
      for (final t in state.value!.tasks)
        if (t.id == task.id) updated else t,
    ];
    state = AsyncData(state.value!.copyWith(tasks: tasks));
  }

  Future<void> toggleComplete(String taskId) async {
    final existing = state.value?.tasks.where((t) => t.id == taskId).firstOrNull;
    if (existing == null) return;
    final now = DateTime.now();
    final updated = existing.copyWith(
      isCompleted: !existing.isCompleted,
      completedAt: !existing.isCompleted ? now : null,
      updatedAt: now,
    );
    await updateTask(updated);
  }

  Future<void> toggleTaskComplete(String taskId) => toggleComplete(taskId);

  Future<void> deleteTask(String taskId) async {
    final db = await DatabaseService.instance.database;
    await db.delete('task_items', where: 'id = ?', whereArgs: [taskId]);
    final tasks = state.value!.tasks.where((t) => t.id != taskId).toList();
    state = AsyncData(state.value!.copyWith(tasks: tasks));
  }

  // ─── Project Creation Pipelines ──────────────────────────────

  /// Creates a Module-based project with auto-scheduled video module tasks.
  Future<TaskProject> createModuleProject({
    required String name,
    required String subjectId,
    required String subjectName,
    required String unitName,
    required List<Video> videos,
    DateTime? deadline,
    int perDayModules = 2,
  }) async {
    final projId = _generateId('proj');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pace = perDayModules > 0 ? perDayModules : 1;

    final project = TaskProject(
      id: projId,
      name: name,
      mode: 'module',
      subjectId: subjectId,
      subjectName: subjectName,
      unitName: unitName,
      deadline: deadline,
      perDayModules: pace,
      sortOrder: state.value?.projects.length ?? 0,
      createdAt: now,
    );

    // Build tasks scheduled across days
    final newTasks = <TaskItem>[];
    for (int i = 0; i < videos.length; i++) {
      final v = videos[i];
      final dayOffset = i ~/ pace;
      final taskDueDate = today.add(Duration(days: dayOffset));
      final int estMins = v.totalMinutes.round() > 0 ? v.totalMinutes.round() : 25;

      newTasks.add(
        TaskItem(
          id: _generateId('task'),
          title: v.title.trim().isNotEmpty ? v.title.trim() : 'Module ${v.serialNumber}',
          note: '$subjectName · $unitName',
          dueDate: taskDueDate,
          projectId: projId,
          priority: TaskItemPriority.p3medium,
          estimatedMinutes: estMins,
          moduleId: v.id,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final db = await DatabaseService.instance.database;
    await db.insert('task_projects', project.toMap());

    if (newTasks.isNotEmpty) {
      final batch = db.batch();
      for (final t in newTasks) {
        batch.insert('task_items', t.toMap());
      }
      await batch.commit(noResult: true);
    }

    final updatedProjects = <TaskProject>[...(state.value?.projects ?? []), project];
    final updatedTasks = <TaskItem>[...(state.value?.tasks ?? []), ...newTasks];
    state = AsyncData(state.value!.copyWith(projects: updatedProjects, tasks: updatedTasks));

    return project;
  }

  /// Creates a Self-Study project with an initially empty task queue.
  Future<TaskProject> createSelfStudyProject({
    required String name,
    required String subjectId,
    required String subjectName,
    String? unitName,
    DateTime? deadline,
  }) async {
    final projId = _generateId('proj');
    final now = DateTime.now();

    final project = TaskProject(
      id: projId,
      name: name,
      mode: 'self_study',
      subjectId: subjectId,
      subjectName: subjectName,
      unitName: unitName,
      deadline: deadline,
      sortOrder: state.value?.projects.length ?? 0,
      createdAt: now,
    );

    final db = await DatabaseService.instance.database;
    await db.insert('task_projects', project.toMap());

    final updatedProjects = <TaskProject>[...(state.value?.projects ?? []), project];
    state = AsyncData(state.value!.copyWith(projects: updatedProjects));

    return project;
  }

  // ─── Project Management ───────────────────────────────────────

  Future<void> addProject(TaskProject project) async {
    final db = await DatabaseService.instance.database;
    await db.insert('task_projects', project.toMap());
    final projects = <TaskProject>[...(state.value?.projects ?? []), project];
    state = AsyncData(state.value!.copyWith(projects: projects));
  }

  Future<void> updateProject(TaskProject project) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'task_projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
    final projects = <TaskProject>[
      for (final p in state.value!.projects)
        if (p.id == project.id) project else p,
    ];
    state = AsyncData(state.value!.copyWith(projects: projects));
  }

  Future<void> toggleArchiveProject(String projectId) async {
    final proj = state.value?.projects.where((p) => p.id == projectId).firstOrNull;
    if (proj == null) return;
    final updated = proj.copyWith(isArchived: !proj.isArchived);
    await updateProject(updated);
  }

  Future<void> deleteProject(String projectId) async {
    final db = await DatabaseService.instance.database;
    await db.delete('task_items', where: 'project_id = ?', whereArgs: [projectId]);
    await db.delete('task_projects', where: 'id = ?', whereArgs: [projectId]);

    final projects = state.value!.projects.where((p) => p.id != projectId).toList();
    final tasks = state.value!.tasks.where((t) => t.projectId != projectId).toList();
    state = AsyncData(state.value!.copyWith(projects: projects, tasks: tasks));
  }

  // ─── Factory helpers ──────────────────────────────────────────

  TaskItem buildNewTask({
    required String title,
    String? note,
    DateTime? dueDate,
    String? projectId,
    TaskItemPriority priority = TaskItemPriority.p4low,
    int? estimatedMinutes,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return TaskItem(
      id: _generateId('task'),
      title: title,
      note: note,
      dueDate: dueDate,
      projectId: projectId,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
  }

  TaskProject buildNewProject({
    required String name,
    String colorHex = '#6B7280',
    String iconName = 'list',
  }) {
    final projects = state.value?.projects ?? [];
    return TaskProject(
      id: _generateId('proj'),
      name: name,
      colorHex: colorHex,
      iconName: iconName,
      sortOrder: projects.length,
      createdAt: DateTime.now(),
    );
  }

  // ─── Private loaders ─────────────────────────────────────────

  Future<List<TaskItem>> _loadTasks() async {
    try {
      final db = await DatabaseService.instance.database;
      final rows = await db.query('task_items', orderBy: 'created_at DESC');
      return rows.map(TaskItem.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TaskProject>> _loadProjects() async {
    try {
      final db = await DatabaseService.instance.database;
      final rows =
          await db.query('task_projects', orderBy: 'sort_order ASC, created_at ASC');
      return rows.map(TaskProject.fromMap).toList();
    } catch (_) {
      return [];
    }
  }
}

final tasksHubProvider =
    AsyncNotifierProvider<TasksHubNotifier, TasksHubState>(
  TasksHubNotifier.new,
);
