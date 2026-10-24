import 'daily_desk_task.dart';

class PlanTaskFilter {
  final MedicalSubject? subjectFilter;
  final TaskPriority? priorityFilter;
  final TaskCategory? categoryFilter;
  final String? dateFilter;
  final bool hideCompleted;

  const PlanTaskFilter({
    this.subjectFilter,
    this.priorityFilter,
    this.categoryFilter,
    this.dateFilter,
    this.hideCompleted = false,
  });

  PlanTaskFilter copyWith({
    MedicalSubject? Function()? subjectFilter,
    TaskPriority? Function()? priorityFilter,
    TaskCategory? Function()? categoryFilter,
    String? Function()? dateFilter,
    bool? hideCompleted,
  }) {
    return PlanTaskFilter(
      subjectFilter: subjectFilter != null ? subjectFilter() : this.subjectFilter,
      priorityFilter: priorityFilter != null ? priorityFilter() : this.priorityFilter,
      categoryFilter: categoryFilter != null ? categoryFilter() : this.categoryFilter,
      dateFilter: dateFilter != null ? dateFilter() : this.dateFilter,
      hideCompleted: hideCompleted ?? this.hideCompleted,
    );
  }

  bool get hasActiveFilter =>
      subjectFilter != null ||
      priorityFilter != null ||
      categoryFilter != null ||
      hideCompleted;
}
