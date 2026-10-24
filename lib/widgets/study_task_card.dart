import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_desk_task.dart';
import '../theme/app_theme.dart';
import 'animations/animated_check_stroke.dart';
import 'animations/animated_strike_text.dart';
import 'animations/apple_pressable.dart';

class StudyTaskCard extends StatelessWidget {
  final String id;
  final String title;
  final TaskCategory category;
  final MedicalSubject subject;
  final TaskPriority priority;
  final int? estimatedMinutes;
  final int? actualMinutesSpent;
  final int? estimatedBlocks;
  final int completedBlocks;
  final bool isRecurring;
  final String? customSubtitle;
  final bool isCompleted;
  final bool isFocusActive;
  final VoidCallback onToggle;
  final VoidCallback? onStartFocus;
  final VoidCallback? onDismissed;
  final Widget? dragHandle;

  const StudyTaskCard({
    super.key,
    required this.id,
    required this.title,
    this.category = TaskCategory.general,
    this.subject = MedicalSubject.general,
    this.priority = TaskPriority.p3medium,
    this.estimatedMinutes,
    this.actualMinutesSpent,
    this.estimatedBlocks,
    this.completedBlocks = 0,
    this.isRecurring = false,
    this.customSubtitle,
    required this.isCompleted,
    this.isFocusActive = false,
    required this.onToggle,
    this.onStartFocus,
    this.onDismissed,
    this.dragHandle,
  });

  static Color priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.p1urgent:
        return AppTheme.accentPrimary;
      case TaskPriority.p2high:
        return const Color(0xFFEAB308);
      case TaskPriority.p3medium:
        return AppTheme.accentSecondary;
      case TaskPriority.p4low:
        return AppTheme.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ApplePressable(
          pressedScale: 0.97,
          pressedOpacity: 0.94,
          hapticStyle: HapticStyle.selection,
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: AppTheme.sketchDecoration(
              backgroundColor: isCompleted ? AppTheme.parchmentSurface : AppTheme.cardWhite,
              borderRadius: 16,
              shadowOffset: isFocusActive ? 4.5 : (isCompleted ? 1 : 3.5),
              borderColor: isFocusActive
                  ? AppTheme.accentPrimary
                  : (isCompleted ? AppTheme.borderLight : AppTheme.sketchBorderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Square Sketch Checkbox with Tactile Spring Bounce
                AnimatedScale(
                  scale: isCompleted ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.accentPrimary : AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCompleted ? AppTheme.accentPrimary : AppTheme.sketchBorderColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: AnimatedCheckStroke(
                        checked: isCompleted,
                        size: 16,
                        color: AppTheme.onAccent,
                        strokeWidth: 2.2,
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
                      Row(
                        children: [
                          // Priority indicator dot
                          Container(
                            width: 7.5,
                            height: 7.5,
                            margin: const EdgeInsets.only(right: 7),
                            decoration: BoxDecoration(
                              color: isCompleted ? AppTheme.mutedText : priorityColor(priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: AnimatedStrikeText(
                              text: title,
                              isStruck: isCompleted,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w700,
                                color: AppTheme.inkForeground,
                              ),
                              strikeColor: AppTheme.mutedText,
                              strikeThickness: 2.0,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Category Tag Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppTheme.parchmentSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.borderLight,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcon(category),
                                  size: 11,
                                  color: isCompleted ? AppTheme.mutedText : AppTheme.inkForeground,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: isCompleted
                                        ? AppTheme.mutedText
                                        : AppTheme.inkForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Subject Chip (if not general)
                          if (subject != MedicalSubject.general)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isCompleted ? AppTheme.parchmentSurface : AppTheme.accentSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isCompleted ? AppTheme.borderLight : AppTheme.accentPrimary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                subject.shortCode,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: isCompleted ? AppTheme.mutedText : AppTheme.inkForeground,
                                ),
                              ),
                            ),
                          // Focus Blocks Pill
                          Builder(
                            builder: (context) {
                              final effectiveBlocks = estimatedBlocks ??
                                  ((estimatedMinutes != null && estimatedMinutes! > 0)
                                      ? (estimatedMinutes! / 25).ceil().clamp(1, 12)
                                      : 1);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: isFocusActive
                                      ? AppTheme.accentPrimary.withValues(alpha: 0.12)
                                      : AppTheme.parchmentSurface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isFocusActive ? AppTheme.accentPrimary : AppTheme.borderLight,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hourglass_bottom_rounded,
                                      size: 10,
                                      color: isFocusActive ? AppTheme.accentPrimary : AppTheme.mutedText,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      completedBlocks > 0
                                          ? '$completedBlocks/$effectiveBlocks blk'
                                          : '$effectiveBlocks ${effectiveBlocks == 1 ? "blk" : "blks"}',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: isFocusActive ? AppTheme.accentPrimary : AppTheme.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Estimated / Actual Time Pill
                          if (estimatedMinutes != null && estimatedMinutes! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppTheme.parchmentSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded, size: 10, color: AppTheme.mutedText),
                                  const SizedBox(width: 3),
                                  Text(
                                    actualMinutesSpent != null && actualMinutesSpent! > 0
                                        ? '${actualMinutesSpent}m/${estimatedMinutes}m'
                                        : '${estimatedMinutes}m',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Recurring Indicator
                          if (isRecurring)
                            Icon(
                              Icons.repeat_rounded,
                              size: 13,
                              color: AppTheme.mutedText,
                            ),
                          if (customSubtitle != null && customSubtitle!.isNotEmpty)
                            Text(
                              customSubtitle!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dedicated Play / Ticking Focus Action Button
                if (onStartFocus != null && !isCompleted) ...[
                  const SizedBox(width: 10),
                  ApplePressable(
                    onTap: onStartFocus,
                    hapticStyle: HapticStyle.medium,
                    child: isFocusActive
                        ? const _ActiveTickingButton()
                        : Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.parchmentSurface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.sketchBorderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 20,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ),
                  ),
                ],

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
}

class _ActiveTickingButton extends StatefulWidget {
  const _ActiveTickingButton();

  @override
  State<_ActiveTickingButton> createState() => _ActiveTickingButtonState();
}

class _ActiveTickingButtonState extends State<_ActiveTickingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.accentPrimary,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.sketchBorderColor,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPrimary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: RotationTransition(
          turns: _ctrl,
          child: Icon(
            Icons.hourglass_top_rounded,
            size: 17,
            color: AppTheme.onAccent,
          ),
        ),
      ),
    );
  }
}


