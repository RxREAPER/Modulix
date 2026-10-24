import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/daily_desk_task.dart';
import '../../data/subjects_metadata.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

/// Focus To-Do inspired keyboard-docked quick task creation accessory.
/// Pinned directly above the soft keyboard with 1-tap block selectors,
/// medical subject badges, priority flags, and zero screen obstruction.
class KeyboardDockedTaskInput extends ConsumerStatefulWidget {
  final MedicalSubject initialSubject;
  final VoidCallback? onTaskCreated;

  const KeyboardDockedTaskInput({
    super.key,
    this.initialSubject = MedicalSubject.general,
    this.onTaskCreated,
  });

  /// Static helper to display this accessory in a clean bottom sheet docked above keyboard
  static void show(
    BuildContext context, {
    MedicalSubject initialSubject = MedicalSubject.general,
    VoidCallback? onTaskCreated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 260),
        reverseDuration: Duration(milliseconds: 200),
      ),
      builder: (context) => KeyboardDockedTaskInput(
        initialSubject: initialSubject,
        onTaskCreated: onTaskCreated,
      ),
    );
  }

  @override
  ConsumerState<KeyboardDockedTaskInput> createState() =>
      _KeyboardDockedTaskInputState();
}

class _KeyboardDockedTaskInputState
    extends ConsumerState<KeyboardDockedTaskInput> {
  final TextEditingController _titleCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late MedicalSubject _selectedSubject;
  TaskCategory _selectedCategory = TaskCategory.video;
  TaskPriority _selectedPriority = TaskPriority.p2high;
  int _selectedBlocks = 2; // default 2 blocks (50m) or custom
  int? _customEstimatedMinutes = 35; // auto-filled by type
  DateTime _selectedDate = DateTime.now();

  static const _taskTypes = [
    (
      category: TaskCategory.video,
      label: 'Video',
      minutes: 35,
      icon: Icons.play_circle_outline_rounded,
      color: Color(0xFF3B82F6),
    ),
    (
      category: TaskCategory.qbank,
      label: 'Q-Bank',
      minutes: 40,
      icon: Icons.quiz_outlined,
      color: Color(0xFF10B981),
    ),
    (
      category: TaskCategory.notes,
      label: 'Notes',
      minutes: 25,
      icon: Icons.description_outlined,
      color: Color(0xFFF59E0B),
    ),
    (
      category: TaskCategory.revision,
      label: 'Revision',
      minutes: 20,
      icon: Icons.replay_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  static String _subjectKey(MedicalSubject subject) {
    switch (subject) {
      case MedicalSubject.anatomy:
        return 'anatomy';
      case MedicalSubject.physiology:
        return 'physiology';
      case MedicalSubject.biochemistry:
        return 'biochemistry';
      case MedicalSubject.pharmacology:
        return 'pharmacology';
      case MedicalSubject.pathology:
        return 'pathology';
      case MedicalSubject.microbiology:
        return 'microbiology';
      case MedicalSubject.forensicMedicine:
        return 'forensic_medicine';
      case MedicalSubject.communityMedicine:
        return 'community_medicine';
      case MedicalSubject.ent:
        return 'ent';
      case MedicalSubject.ophthalmology:
        return 'ophthalmology';
      case MedicalSubject.psychiatry:
        return 'psychiatry';
      case MedicalSubject.radiology:
        return 'radiology';
      case MedicalSubject.dermatology:
        return 'dermatology';
      case MedicalSubject.surgery:
        return 'surgery';
      case MedicalSubject.orthopedics:
        return 'orthopaedics';
      case MedicalSubject.obgyn:
        return 'obstetrics_and_gynaecology';
      case MedicalSubject.medicine:
        return 'medicine';
      case MedicalSubject.pediatrics:
        return 'paediatrics';
      case MedicalSubject.anesthesia:
        return 'anaesthesia';
      case MedicalSubject.general:
        return 'general';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitTask({bool keepOpenForNext = false}) {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.lightImpact();
    final effectiveEstMinutes = _customEstimatedMinutes ?? (_selectedBlocks * 25);
    final task = DailyDeskTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _selectedCategory,
      subject: _selectedSubject,
      priority: _selectedPriority,
      estimatedMinutes: effectiveEstMinutes,
      estimatedBlocks: _selectedBlocks,
      scheduledDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    ref.read(dailyTasksProvider.notifier).addTask(task);
    widget.onTaskCreated?.call();

    if (keepOpenForNext) {
      _titleCtrl.clear();
      _focusNode.requestFocus();
    } else {
      Navigator.pop(context);
    }
  }

  Color _priorityFlagColor(TaskPriority prio) {
    switch (prio) {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return AnimatedPadding(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppTheme.sketchBorderColor, width: 1.6),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkForeground.withValues(alpha: 0.16),
              offset: const Offset(0, -4),
              blurRadius: 18,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Input Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.borderLight,
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: TextField(
                      controller: _titleCtrl,
                      focusNode: _focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitTask(),
                      cursorColor: AppTheme.inkForeground,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkForeground,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Add a medical study task...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.mutedText,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Submit Button
                ApplePressable(
                  onTap: () => _submitTask(),
                  hapticStyle: HapticStyle.medium,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.sketchBorderColor,
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: AppTheme.onAccent,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 1: Tactile Task Type Selector Pills (Video, Q-Bank, Notes, Revision)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final item in _taskTypes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ApplePressable(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategory = item.category;
                            _customEstimatedMinutes = item.minutes;
                            _selectedBlocks = (item.minutes / 25).ceil().clamp(1, 5);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedCategory == item.category
                                ? item.color.withValues(alpha: 0.14)
                                : AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedCategory == item.category
                                  ? item.color
                                  : AppTheme.borderLight,
                              width: _selectedCategory == item.category ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 14,
                                color: _selectedCategory == item.category
                                    ? item.color
                                    : AppTheme.inkForeground,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${item.label} · ${item.minutes}m',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedCategory == item.category
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _selectedCategory == item.category
                                      ? item.color
                                      : AppTheme.inkForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Row 2: Metadata Controls (Subject with authentic icon, Focus Blocks, Priority, Date)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Subject Selector Pill with authentic library icon & color
                  PopupMenuButton<MedicalSubject>(
                    initialValue: _selectedSubject,
                    onSelected: (sub) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSubject = sub);
                    },
                    color: AppTheme.cardWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppTheme.sketchBorderColor, width: 1.5),
                    ),
                    itemBuilder: (context) => MedicalSubject.values
                        .map(
                          (sub) {
                            final meta = subjectMeta(_subjectKey(sub));
                            return PopupMenuItem(
                              value: sub,
                              child: Row(
                                children: [
                                  Icon(
                                    meta.icon,
                                    size: 16,
                                    color: meta.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    sub.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: sub == _selectedSubject
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: AppTheme.inkForeground,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                        .toList(),
                    child: Builder(
                      builder: (context) {
                        final meta = subjectMeta(_subjectKey(_selectedSubject));
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                meta.icon,
                                size: 14,
                                color: _selectedSubject == MedicalSubject.general
                                    ? AppTheme.inkForeground
                                    : meta.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _selectedSubject.shortCode,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedSubject == MedicalSubject.general
                                      ? AppTheme.inkForeground
                                      : meta.accent,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppTheme.mutedText),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Quick Blocks Selector
                  for (int b = 1; b <= 5; b++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ApplePressable(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedBlocks = b;
                            _customEstimatedMinutes = b * 25;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: _selectedBlocks == b
                                ? AppTheme.accentPrimary
                                : AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedBlocks == b
                                  ? AppTheme.sketchBorderColor
                                  : AppTheme.borderLight,
                              width: _selectedBlocks == b ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_bottom_rounded,
                                size: 11,
                                color: _selectedBlocks == b
                                    ? AppTheme.onAccent
                                    : AppTheme.mutedText,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${b}B',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedBlocks == b
                                      ? AppTheme.onAccent
                                      : AppTheme.inkForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(width: 6),

                  // Priority Flag Pill
                  PopupMenuButton<TaskPriority>(
                    initialValue: _selectedPriority,
                    onSelected: (prio) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPriority = prio);
                    },
                    color: AppTheme.cardWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppTheme.sketchBorderColor, width: 1.5),
                    ),
                    itemBuilder: (context) => TaskPriority.values
                        .map(
                          (prio) => PopupMenuItem(
                            value: prio,
                            child: Row(
                              children: [
                                Icon(Icons.flag_rounded, size: 15, color: _priorityFlagColor(prio)),
                                const SizedBox(width: 8),
                                Text(
                                  prio.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: prio == _selectedPriority
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: AppTheme.inkForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.parchmentSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_rounded, size: 13, color: _priorityFlagColor(_selectedPriority)),
                          const SizedBox(width: 4),
                          Text(
                            _selectedPriority.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppTheme.mutedText),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Date Pill (Today / Tomorrow / Pick)
                  ApplePressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isToday) {
                          _selectedDate = DateTime.now().add(const Duration(days: 1));
                        } else {
                          _selectedDate = DateTime.now();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.parchmentSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.mutedText),
                          const SizedBox(width: 5),
                          Text(
                            isToday ? 'Today' : 'Tomorrow',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
