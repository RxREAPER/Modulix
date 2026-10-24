/// A user-created project grouping [TaskItem]s in the Tasks Hub.
class TaskProject {
  final String id;
  final String name;
  final String colorHex; // e.g. '#3B82F6'
  final String iconName; // Material icon codepoint as hex string, or named preset
  final int sortOrder;
  final DateTime createdAt;

  const TaskProject({
    required this.id,
    required this.name,
    this.colorHex = '#6B7280',
    this.iconName = 'list',
    this.sortOrder = 0,
    required this.createdAt,
  });

  TaskProject copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    int? sortOrder,
    DateTime? createdAt,
  }) =>
      TaskProject(
        id: id ?? this.id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        iconName: iconName ?? this.iconName,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color_hex': colorHex,
        'icon_name': iconName,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  factory TaskProject.fromMap(Map<String, dynamic> map) => TaskProject(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        colorHex: map['color_hex']?.toString() ?? '#6B7280',
        iconName: map['icon_name']?.toString() ?? 'list',
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
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
