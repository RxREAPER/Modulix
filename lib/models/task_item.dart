import 'dart:convert';

/// Priority levels for [TaskItem].
enum TaskItemPriority {
  p1urgent,
  p2high,
  p3medium,
  p4low;

  int get level => switch (this) {
        TaskItemPriority.p1urgent => 1,
        TaskItemPriority.p2high => 2,
        TaskItemPriority.p3medium => 3,
        TaskItemPriority.p4low => 4,
      };

  String get label => switch (this) {
        TaskItemPriority.p1urgent => 'Urgent',
        TaskItemPriority.p2high => 'High',
        TaskItemPriority.p3medium => 'Medium',
        TaskItemPriority.p4low => 'Low',
      };

  static TaskItemPriority fromLevel(int? level) => switch (level) {
        1 => TaskItemPriority.p1urgent,
        2 => TaskItemPriority.p2high,
        3 => TaskItemPriority.p3medium,
        _ => TaskItemPriority.p4low,
      };
}

/// A sub-task nested inside a [TaskItem].
class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({String? id, String? title, bool? isCompleted}) => SubTask(
        id: id ?? this.id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted ? 1 : 0,
      };

  factory SubTask.fromMap(Map<String, dynamic> map) => SubTask(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        isCompleted: (map['isCompleted'] as num?)?.toInt() == 1,
      );
}

/// Core task entity for the Tasks Hub.
/// Completely independent of [DailyDeskTask].
class TaskItem {
  final String id;
  final String title;
  final String? note;
  final DateTime? dueDate;
  final int? dueHour;   // 0-23, nullable means no specific time
  final int? dueMinute; // 0-59
  final String? projectId;
  final TaskItemPriority priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<SubTask> subTasks;
  final List<String> tags;
  final int? estimatedMinutes;
  final String? moduleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.title,
    this.note,
    this.dueDate,
    this.dueHour,
    this.dueMinute,
    this.projectId,
    this.priority = TaskItemPriority.p4low,
    this.isCompleted = false,
    this.completedAt,
    this.subTasks = const [],
    this.tags = const [],
    this.estimatedMinutes,
    this.moduleId,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    Object? note = _sentinel,
    Object? dueDate = _sentinel,
    Object? dueHour = _sentinel,
    Object? dueMinute = _sentinel,
    Object? projectId = _sentinel,
    TaskItemPriority? priority,
    bool? isCompleted,
    Object? completedAt = _sentinel,
    List<SubTask>? subTasks,
    List<String>? tags,
    Object? estimatedMinutes = _sentinel,
    Object? moduleId = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TaskItem(
        id: id ?? this.id,
        title: title ?? this.title,
        note: note == _sentinel ? this.note : note as String?,
        dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
        dueHour: dueHour == _sentinel ? this.dueHour : dueHour as int?,
        dueMinute: dueMinute == _sentinel ? this.dueMinute : dueMinute as int?,
        projectId: projectId == _sentinel ? this.projectId : projectId as String?,
        priority: priority ?? this.priority,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt == _sentinel ? this.completedAt : completedAt as DateTime?,
        subTasks: subTasks ?? this.subTasks,
        tags: tags ?? this.tags,
        estimatedMinutes: estimatedMinutes == _sentinel
            ? this.estimatedMinutes
            : estimatedMinutes as int?,
        moduleId: moduleId == _sentinel ? this.moduleId : moduleId as String?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // ─── Computed helpers ───────────────────────────────────────────
  bool get isToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }

  bool get isThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return !d.isBefore(today) && d.isBefore(weekEnd);
  }

  int get completedSubTasks => subTasks.where((s) => s.isCompleted).length;

  // ─── Serialisation ──────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'note': note,
        'due_date': dueDate?.toIso8601String(),
        'due_hour': dueHour,
        'due_minute': dueMinute,
        'project_id': projectId,
        'priority': priority.level,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.toIso8601String(),
        'sub_tasks': jsonEncode(subTasks.map((s) => s.toMap()).toList()),
        'tags': jsonEncode(tags),
        'estimated_minutes': estimatedMinutes,
        'module_id': moduleId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    List<SubTask> subTasks = [];
    try {
      final raw = map['sub_tasks'];
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        subTasks = decoded
            .map((e) => SubTask.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    List<String> tags = [];
    try {
      final raw = map['tags'];
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        tags = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return TaskItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      note: map['note']?.toString(),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      dueHour: (map['due_hour'] as num?)?.toInt(),
      dueMinute: (map['due_minute'] as num?)?.toInt(),
      projectId: map['project_id']?.toString(),
      priority: TaskItemPriority.fromLevel((map['priority'] as num?)?.toInt()),
      isCompleted: (map['is_completed'] as num?)?.toInt() == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'].toString())
          : null,
      subTasks: subTasks,
      tags: tags,
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt(),
      moduleId: map['module_id']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// Sentinel for nullable copyWith fields
class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();
