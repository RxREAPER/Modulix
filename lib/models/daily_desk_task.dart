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
    if (val == null || val.isEmpty) return TaskCategory.general;
    return TaskCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == val.toLowerCase() || c.label.toLowerCase() == val.toLowerCase(),
      orElse: () => TaskCategory.general,
    );
  }
}

enum MedicalSubject {
  anatomy('Anatomy', 'ANAT'),
  physiology('Physiology', 'PHYS'),
  biochemistry('Biochemistry', 'BIOCH'),
  pharmacology('Pharmacology', 'PHARM'),
  pathology('Pathology', 'PATH'),
  microbiology('Microbiology', 'MICRO'),
  forensicMedicine('Forensic Med', 'FMT'),
  communityMedicine('Community Med', 'PSM'),
  ent('ENT', 'ENT'),
  ophthalmology('Ophthalmology', 'OPHTH'),
  psychiatry('Psychiatry', 'PSYCH'),
  radiology('Radiology', 'RADIO'),
  dermatology('Dermatology', 'DERMA'),
  surgery('Surgery', 'SURG'),
  orthopedics('Orthopedics', 'ORTHO'),
  obgyn('OB-GYN', 'OBGYN'),
  medicine('Medicine', 'MED'),
  pediatrics('Pediatrics', 'PEDIA'),
  anesthesia('Anesthesia', 'ANESTH'),
  general('General', 'GEN');

  final String label;
  final String shortCode;
  const MedicalSubject(this.label, this.shortCode);

  static MedicalSubject fromString(String? val) {
    if (val == null || val.isEmpty) return MedicalSubject.general;
    final normalized = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return MedicalSubject.values.firstWhere(
      (s) {
        final nameNorm = s.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final labelNorm = s.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final shortNorm = s.shortCode.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        return nameNorm == normalized || labelNorm == normalized || shortNorm == normalized;
      },
      orElse: () => MedicalSubject.general,
    );
  }
}

enum TaskPriority {
  p1urgent('Urgent', 1),
  p2high('High', 2),
  p3medium('Medium', 3),
  p4low('Low', 4);

  final String label;
  final int level;
  const TaskPriority(this.label, this.level);

  static TaskPriority fromString(String? val) {
    if (val == null || val.isEmpty) return TaskPriority.p3medium;
    final normalized = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return TaskPriority.values.firstWhere(
      (p) {
        final nameNorm = p.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final labelNorm = p.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        return nameNorm == normalized || labelNorm == normalized || normalized == 'p${p.level}';
      },
      orElse: () => TaskPriority.p3medium,
    );
  }
}

class DailyDeskTask {
  final String id;
  final String title;
  final TaskCategory category;
  final MedicalSubject subject;
  final TaskPriority priority;
  final String? scheduledDate;
  final int? estimatedMinutes;
  final int? actualMinutesSpent;
  final int? estimatedBlocks;
  final int completedBlocks;
  final String? scheduledTimeSlot;
  final bool isRecurring;
  final String? linkedFocusTopicId;

  const DailyDeskTask({
    required this.id,
    required this.title,
    this.category = TaskCategory.general,
    this.subject = MedicalSubject.general,
    this.priority = TaskPriority.p3medium,
    this.scheduledDate,
    this.estimatedMinutes,
    this.actualMinutesSpent,
    this.estimatedBlocks,
    this.completedBlocks = 0,
    this.scheduledTimeSlot,
    this.isRecurring = false,
    this.linkedFocusTopicId,
  });

  /// The effective estimated focus blocks (each block default is 25 minutes)
  int get effectiveEstimatedBlocks {
    if (estimatedBlocks != null && estimatedBlocks! > 0) return estimatedBlocks!;
    if (estimatedMinutes != null && estimatedMinutes! > 0) {
      return (estimatedMinutes! / 25).ceil().clamp(1, 12);
    }
    return 1;
  }

  /// The effective completed focus blocks
  int get effectiveCompletedBlocks {
    if (completedBlocks > 0) return completedBlocks;
    if (actualMinutesSpent != null && actualMinutesSpent! > 0) {
      return actualMinutesSpent! ~/ 25;
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'subject': subject.name,
      'priority': priority.name,
      if (scheduledDate != null) 'scheduledDate': scheduledDate,
      if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
      if (actualMinutesSpent != null) 'actualMinutesSpent': actualMinutesSpent,
      'estimatedBlocks': effectiveEstimatedBlocks,
      'completedBlocks': completedBlocks,
      if (scheduledTimeSlot != null) 'scheduledTimeSlot': scheduledTimeSlot,
      'isRecurring': isRecurring,
      if (linkedFocusTopicId != null) 'linkedFocusTopicId': linkedFocusTopicId,
    };
  }

  factory DailyDeskTask.fromMap(Map<String, dynamic> map) {
    final estMins = (map['estimatedMinutes'] as num?)?.toInt();
    final estBlocks = (map['estimatedBlocks'] as num?)?.toInt() ??
        (estMins != null && estMins > 0 ? (estMins / 25).ceil() : null);
    final compBlocks = (map['completedBlocks'] as num?)?.toInt() ?? 0;

    return DailyDeskTask(
      id: map['id']?.toString() ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? '',
      category: TaskCategory.fromString(map['category']?.toString()),
      subject: MedicalSubject.fromString(map['subject']?.toString()),
      priority: TaskPriority.fromString(map['priority']?.toString()),
      scheduledDate: map['scheduledDate']?.toString(),
      estimatedMinutes: estMins,
      actualMinutesSpent: (map['actualMinutesSpent'] as num?)?.toInt(),
      estimatedBlocks: estBlocks,
      completedBlocks: compBlocks,
      scheduledTimeSlot: map['scheduledTimeSlot']?.toString(),
      isRecurring: map['isRecurring'] == true,
      linkedFocusTopicId: map['linkedFocusTopicId']?.toString(),
    );
  }

  DailyDeskTask copyWith({
    String? id,
    String? title,
    TaskCategory? category,
    MedicalSubject? subject,
    TaskPriority? priority,
    String? scheduledDate,
    int? estimatedMinutes,
    int? actualMinutesSpent,
    int? estimatedBlocks,
    int? completedBlocks,
    String? scheduledTimeSlot,
    bool? isRecurring,
    String? linkedFocusTopicId,
  }) {
    return DailyDeskTask(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      priority: priority ?? this.priority,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutesSpent: actualMinutesSpent ?? this.actualMinutesSpent,
      estimatedBlocks: estimatedBlocks ?? this.estimatedBlocks,
      completedBlocks: completedBlocks ?? this.completedBlocks,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      isRecurring: isRecurring ?? this.isRecurring,
      linkedFocusTopicId: linkedFocusTopicId ?? this.linkedFocusTopicId,
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
      subject: MedicalSubject.general,
      priority: TaskPriority.p3medium,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DailyDeskTask.fromJson(String source) =>
      DailyDeskTask.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
