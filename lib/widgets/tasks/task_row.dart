import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/task_item.dart';
import '../../theme/tasks_theme.dart';

/// A single task row — minimalist checkbox circle, title, optional meta.
/// No tags, no under-text annotations. Clean and flat.
class TaskRow extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

  const TaskRow({
    super.key,
    required this.task,
    this.onToggle,
    this.onTap,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: TasksTheme.surface,
        highlightColor: TasksTheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TasksTheme.pagePadding,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggle?.call();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted
                        ? TasksTheme.accent
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted
                          ? TasksTheme.accent
                          : _priorityBorderColor(task.priority),
                      width: 1.8,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: task.isCompleted
                            ? TasksTheme.textTertiary
                            : TasksTheme.textPrimary,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: TasksTheme.textTertiary,
                        height: 1.4,
                      ),
                    ),
                    if (task.subTasks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${task.completedSubTasks}/${task.subTasks.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TasksTheme.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onPlay != null && !task.isCompleted)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onPlay?.call();
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TasksTheme.surface,
                      border: Border.all(color: TasksTheme.border),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: TasksTheme.accent,
                    ),
                  ),
                ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: TasksTheme.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _priorityBorderColor(TaskItemPriority p) => switch (p) {
        TaskItemPriority.p1urgent => TasksTheme.priorityP1,
        TaskItemPriority.p2high => TasksTheme.priorityP2,
        TaskItemPriority.p3medium => TasksTheme.priorityP3,
        TaskItemPriority.p4low => TasksTheme.border,
      };
}
