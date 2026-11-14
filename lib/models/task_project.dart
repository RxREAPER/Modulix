/// A user-created project grouping [TaskItem]s in the Tasks Hub.
class TaskProject {
  final String id;
  final String name;
  final String colorHex; // e.g. '#3B82F6'
  final String iconName; // Material icon codepoint as hex string, or named preset
  final int sortOrder;
  final String mode; // 'module' | 'self_study'
  final String? subjectId;
  final String? subjectName;
  final String? unitName;
  final DateTime? deadline;
  final int? perDayModules;
  final bool isArchived;
  final DateTime createdAt;

  const TaskProject({
    required this.id,
    required this.name,
    this.colorHex = '#6B7280',
    this.iconName = 'list',
    this.sortOrder = 0,
    this.mode = 'module',
    this.subjectId,
    this.subjectName,
    this.unitName,
    this.deadline,
    this.perDayModules,
    this.isArchived = false,
    required this.createdAt,
  });

  bool get isModuleBased => mode == 'module';
  bool get isSelfStudy => mode == 'self_study';

  /// Human-readable display title, masking technical IDs (e.g. 'PROJ_...')
  String get displayName {
    if (unitName != null &&
        unitName!.trim().isNotEmpty &&
        !unitName!.toUpperCase().startsWith('PROJ_')) {
      return unitName!.trim();
    }
    if (name.trim().isNotEmpty && !name.toUpperCase().startsWith('PROJ_')) {
      return name.trim();
    }
    if (subjectName != null &&
        subjectName!.trim().isNotEmpty &&
        !subjectName!.toUpperCase().startsWith('PROJ_')) {
      return '$subjectName Study Plan';
    }
    return 'Study Project';
  }

  TaskProject copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    int? sortOrder,
    String? mode,
    String? subjectId,
    String? subjectName,
    String? unitName,
    DateTime? deadline,
    int? perDayModules,
    bool? isArchived,
    DateTime? createdAt,
  }) =>
      TaskProject(
        id: id ?? this.id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        iconName: iconName ?? this.iconName,
        sortOrder: sortOrder ?? this.sortOrder,
        mode: mode ?? this.mode,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        unitName: unitName ?? this.unitName,
        deadline: deadline ?? this.deadline,
        perDayModules: perDayModules ?? this.perDayModules,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color_hex': colorHex,
        'icon_name': iconName,
        'sort_order': sortOrder,
        'mode': mode,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'unit_name': unitName,
        'deadline': deadline?.toIso8601String(),
        'per_day_modules': perDayModules,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory TaskProject.fromMap(Map<String, dynamic> map) => TaskProject(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        colorHex: map['color_hex']?.toString() ?? '#6B7280',
        iconName: map['icon_name']?.toString() ?? 'list',
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        mode: map['mode']?.toString() ?? 'module',
        subjectId: map['subject_id']?.toString(),
        subjectName: map['subject_name']?.toString(),
        unitName: map['unit_name']?.toString(),
        deadline: map['deadline'] != null
            ? DateTime.tryParse(map['deadline'].toString())
            : null,
        perDayModules: (map['per_day_modules'] as num?)?.toInt(),
        isArchived: (map['is_archived'] as num?)?.toInt() == 1,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// Preset colour swatches for project creation.
const kProjectColorSwatches = [
  '#EF4444', // red
  '#F97316', // orange
  '#EAB308', // yellow
  '#22C55E', // green
  '#3B82F6', // blue
  '#8B5CF6', // violet
  '#EC4899', // pink
  '#6B7280', // grey
];
