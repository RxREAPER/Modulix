import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // ─── Computed task buckets ─────────────────────────────────────
  List<TaskItem> get todayTasks =>
      tasks.where((t) => !t.isCompleted && t.isToday).toList()
        ..sort(_byPriority);

  List<TaskItem> get tomorrowTasks =>
      tasks.where((t) => !t.isCompleted && t.isTomorrow).toList()
        ..sort(_byPriority);

  List<TaskItem> get thisWeekTasks =>
      tasks.where((t) => !t.isCompleted && t.isThisWeek).toList()
        ..sort(_byPriority);

  List<TaskItem> tasksForProject(String projectId) =>
      tasks.where((t) => t.projectId == projectId).toList()
        ..sort(_byPriority);

  // ─── Estimated hours per bucket ───────────────────────────────
  double get todayEstimatedHours =>
      _toHours(todayTasks.fold(0, (s, t) => s + (t.estimatedMinutes ?? 25)));

  double get tomorrowEstimatedHours =>
      _toHours(tomorrowTasks.fold(0, (s, t) => s + (t.estimatedMinutes ?? 25)));

  double get thisWeekEstimatedHours =>
      _toHours(thisWeekTasks.fold(0, (s, t) => s + (t.estimatedMinutes ?? 25)));

  double projectEstimatedHours(String projectId) => _toHours(
      tasksForProject(projectId)
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

  Future<void> deleteTask(String taskId) async {
    final db = await DatabaseService.instance.database;
    await db.delete('task_items', where: 'id = ?', whereArgs: [taskId]);
    final tasks = state.value!.tasks.where((t) => t.id != taskId).toList();
    state = AsyncData(state.value!.copyWith(tasks: tasks));
  }

  // ─── Project CRUD ─────────────────────────────────────────────

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

  Future<void> deleteProject(String projectId) async {
    final db = await DatabaseService.instance.database;
    await db.delete('task_projects', where: 'id = ?', whereArgs: [projectId]);
    final projects =
        state.value!.projects.where((p) => p.id != projectId).toList();
    state = AsyncData(state.value!.copyWith(projects: projects));
  }

  // ─── Factory helpers ──────────────────────────────────────────

  TaskItem buildNewTask({
    required String title,
    String? note,
    DateTime? dueDate,
    String? projectId,
    TaskItemPriority priority = TaskItemPriority.p4low,
    int? estimatedMinutes,
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
