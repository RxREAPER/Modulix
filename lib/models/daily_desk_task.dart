import 'dart:convert';

enum TaskCategory {
  video('Video'),
  qbank('Q-Bank'),
  revision('Revision'),
  notes('Notes'),
  general('Goal');

  final String label;
  const TaskCategory(this.label);

  static TaskCategory fromString(String? val) {
    if (val == null) return TaskCategory.general;
    return TaskCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == val.toLowerCase() || c.label.toLowerCase() == val.toLowerCase(),
      orElse: () => TaskCategory.general,
    );
  }
}

class DailyDeskTask {
  final String id;
  final String title;
  final TaskCategory category;

  const DailyDeskTask({
    required this.id,
    required this.title,
    this.category = TaskCategory.general,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
    };
  }

  factory DailyDeskTask.fromMap(Map<String, dynamic> map) {
    return DailyDeskTask(
      id: map['id'] as String? ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? '',
      category: TaskCategory.fromString(map['category'] as String?),
    );
  }

  factory DailyDeskTask.fromString(String raw, int index) {
    String title = raw;
    TaskCategory cat = TaskCategory.general;

    if (raw.startsWith('[REV] ')) {
      cat = TaskCategory.revision;
      title = raw.substring(6);
    } else if (raw.startsWith('[MCQ] ')) {
      cat = TaskCategory.qbank;
      title = raw.substring(6);
    } else if (raw.startsWith('[VID] ')) {
      cat = TaskCategory.video;
      title = raw.substring(6);
    } else if (raw.startsWith('[NOTE] ')) {
      cat = TaskCategory.notes;
      title = raw.substring(7);
    }

    return DailyDeskTask(
      id: 'task_${index}_${title.hashCode}',
      title: title,
      category: cat,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DailyDeskTask.fromJson(String source) =>
      DailyDeskTask.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
