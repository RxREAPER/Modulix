import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_desk_task.dart';
import '../theme/app_theme.dart';

class StudyTaskCard extends StatelessWidget {
  final String id;
  final String title;
  final TaskCategory category;
  final String? customSubtitle;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback? onDismissed;
  final Widget? dragHandle;

  const StudyTaskCard({
    super.key,
    required this.id,
    required this.title,
    this.category = TaskCategory.general,
    this.customSubtitle,
    required this.isCompleted,
    required this.onToggle,
    this.onDismissed,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onToggle();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: AppTheme.sketchDecoration(
              backgroundColor: isCompleted ? const Color(0xFFF6F6F5) : Colors.white,
              borderRadius: 16,
              shadowOffset: isCompleted ? 1 : 3.5,
              borderColor: isCompleted ? Colors.grey.shade400 : AppTheme.sketchBorderColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Square Sketch Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.inkForeground : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted ? AppTheme.inkForeground : AppTheme.sketchBorderColor,
                      width: 2,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: isCompleted ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutBack,
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Title & Details with bolder markups
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w700,
                          color: isCompleted ? Colors.grey.shade400 : AppTheme.inkForeground,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          decorationThickness: 2.2,
                          decorationColor: isCompleted ? Colors.grey.shade500 : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Category Tag Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFFF4F4F5)
                                  : const Color(0xFFF3F1EA),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCompleted
                                    ? const Color(0xFFE4E4E7)
                                    : const Color(0xFFD6D2C4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcon(category),
                                  size: 11,
                                  color: isCompleted ? Colors.grey.shade400 : const Color(0xFF4A463F),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: isCompleted
                                        ? Colors.grey.shade500
                                        : const Color(0xFF4A463F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (customSubtitle != null && customSubtitle!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              customSubtitle!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                if (dragHandle != null) ...[
                  const SizedBox(width: 8),
                  dragHandle!,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (onDismissed == null) {
      return cardContent;
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDismissed!();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2), // soft pastel red
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.sketchBorderColor,
            width: 1.8,
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
          ],
        ),
      ),
      child: cardContent,
    );
  }

  IconData _categoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.video:
        return Icons.play_circle_outline_rounded;
      case TaskCategory.qbank:
        return Icons.quiz_outlined;
      case TaskCategory.revision:
        return Icons.replay_rounded;
      case TaskCategory.notes:
        return Icons.edit_note_rounded;
      case TaskCategory.general:
        return Icons.flag_outlined;
    }
  }

  Color _categoryColor(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.revision:
        return const Color(0xFFD97706); // Amber
      case TaskCategory.qbank:
        return const Color(0xFF7C3AED); // Purple
      case TaskCategory.video:
        return const Color(0xFF2563EB); // Blue
      case TaskCategory.notes:
        return const Color(0xFF059669); // Emerald
      case TaskCategory.general:
        return const Color(0xFF4B5563); // Grey
    }
  }
}
