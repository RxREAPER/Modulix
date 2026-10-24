import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tasks_theme.dart';

/// A row in the Tasks Hub index (Today / Tomorrow / This Week / Project).
/// Shows: icon · label · estimated hours · task count · chevron.
/// Matches the Focus To-Do reference screenshot style exactly.
class TasksBucketRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final double estimatedHours;
  final int taskCount;
  final VoidCallback onTap;
  final bool showDivider;

  const TasksBucketRow({
    super.key,
    required this.icon,
    required this.label,
    required this.estimatedHours,
    required this.taskCount,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final hoursStr = estimatedHours > 0
        ? '${estimatedHours.toStringAsFixed(1).replaceAll('.0', '')}h'
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            splashColor: TasksTheme.accent.withValues(alpha: 0.06),
            highlightColor: TasksTheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TasksTheme.pagePadding,
                vertical: 14,
              ),
              child: Row(
                children: [
                  SizedBox(width: 26, height: 26, child: icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: TasksTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (hoursStr.isNotEmpty) ...[
                    Text(
                      hoursStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: TasksTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (taskCount > 0)
                    Text(
                      '$taskCount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: TasksTheme.textSecondary,
                      ),
                    )
                  else
                    const Text(
                      '0',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: TasksTheme.textTertiary,
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: TasksTheme.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: TasksTheme.pagePadding + 40),
            child: Container(height: 1, color: TasksTheme.divider),
          ),
      ],
    );
  }
}
