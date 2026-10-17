import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_desk_task.dart';
import '../models/syllabus.dart';
import '../theme/app_theme.dart';
import 'animations/apple_pressable.dart';

class TaskSetupSheet extends StatefulWidget {
  final List<DailyDeskTask> currentTasks;
  final ValueChanged<List<DailyDeskTask>> onConfirmTasks;
  final List<Video>? suggestedVideos;

  const TaskSetupSheet({
    super.key,
    required this.currentTasks,
    required this.onConfirmTasks,
    this.suggestedVideos,
  });

  static Future<void> show(
    BuildContext context, {
    required List<DailyDeskTask> currentTasks,
    required ValueChanged<List<DailyDeskTask>> onConfirmTasks,
    List<Video>? suggestedVideos,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 320),
        reverseDuration: Duration(milliseconds: 240),
      ),
      builder: (context) => TaskSetupSheet(
        currentTasks: currentTasks,
        onConfirmTasks: onConfirmTasks,
        suggestedVideos: suggestedVideos,
      ),
    );
  }

  @override
  State<TaskSetupSheet> createState() => _TaskSetupSheetState();
}

class _TaskSetupSheetState extends State<TaskSetupSheet>
    with SingleTickerProviderStateMixin {
  late List<DailyDeskTask> _tasks;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _listScrollController = ScrollController();

  TaskCategory _selectedCategory = TaskCategory.video;
  bool _isModalityPickerOpen = false;
  bool _hasText = false;

  late final AnimationController _pickerAnimController;
  late final Animation<double> _pickerExpandAnim;

  @override
  void initState() {
    super.initState();
    // Do NOT auto-inject syllabus / module planner goals by default
    _tasks = List.from(widget.currentTasks);

    _pickerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _pickerExpandAnim = CurvedAnimation(
      parent: _pickerAnimController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _textController.addListener(() {
      final hasTextNow = _textController.text.trim().isNotEmpty;
      if (hasTextNow != _hasText) {
        setState(() => _hasText = hasTextNow);
      }
    });
  }

  @override
  void dispose() {
    _pickerAnimController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _toggleModalityPicker() {
    HapticFeedback.selectionClick();
    setState(() {
      _isModalityPickerOpen = !_isModalityPickerOpen;
      if (_isModalityPickerOpen) {
        _pickerAnimController.forward();
      } else {
        _pickerAnimController.reverse();
      }
    });
  }

  void _selectCategory(TaskCategory category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
      _isModalityPickerOpen = false;
      _pickerAnimController.reverse();
    });
  }

  void _addTask() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _tasks.add(DailyDeskTask(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: text,
        category: _selectedCategory,
      ));
      _textController.clear();
      _hasText = false;
    });

    // Auto scroll to bottom smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _removeTask(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkForeground.withValues(alpha: 0.12),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, isKeyboardOpen ? 12 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header Section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Plan Today's Desk",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Curate your independent study targets for today.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Task Count Badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.borderLight,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    '${_tasks.length} ${_tasks.length == 1 ? 'Target' : 'Targets'}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkForeground,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppTheme.inkForeground),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Task List or Clean Desk Empty State
            Flexible(
              child: _tasks.isEmpty
                  ? _buildEmptyDeskState()
                  : _buildReorderableTaskList(),
            ),

            const SizedBox(height: 14),

            // Animated Modality Palette (Expands from the dock when tapped)
            SizeTransition(
              sizeFactor: _pickerExpandAnim,
              axisAlignment: -1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.borderLight,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.inkForeground.withValues(alpha: 0.08),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: TaskCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Expanded(
                      child: ApplePressable(
                        pressedScale: 0.92,
                        onTap: () => _selectCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.inkForeground
                                : AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.inkForeground
                                  : AppTheme.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryIcon(cat),
                                size: 15,
                                color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cat.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: isSelected
                                      ? AppTheme.paperBackground
                                      : AppTheme.inkForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Modality Stamp Button Header
            Row(
              children: [
                ApplePressable(
                  pressedScale: 0.94,
                  onTap: _toggleModalityPicker,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isModalityPickerOpen
                          ? AppTheme.inkForeground
                          : AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isModalityPickerOpen
                            ? AppTheme.inkForeground
                            : AppTheme.borderLight,
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categoryIcon(_selectedCategory),
                          size: 14,
                          color: _isModalityPickerOpen
                              ? AppTheme.paperBackground
                              : AppTheme.inkForeground,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _selectedCategory.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _isModalityPickerOpen
                                ? AppTheme.paperBackground
                                : AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _isModalityPickerOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: _isModalityPickerOpen
                                ? AppTheme.paperBackground
                                : AppTheme.inkForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap stamp to change modality',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Full-Width Enter Box Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus ? AppTheme.inkForeground : AppTheme.borderLight,
                  width: _focusNode.hasFocus ? 1.4 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkForeground.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Row(
                children: [
                  // Modality Icon Indicator inside the enter box
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight, width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        _categoryIcon(_selectedCategory),
                        size: 15,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Full-Width Text Input Field with category-aware hint
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      cursorColor: AppTheme.inkForeground,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addTask(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkForeground,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        hintText: _categoryHint(_selectedCategory),
                        hintStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),

                  // Tactile '+' Add Button
                  ApplePressable(
                    pressedScale: 0.88,
                    onTap: _addTask,
                    child: AnimatedScale(
                      scale: _hasText ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutBack,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hasText
                              ? AppTheme.inkForeground
                              : AppTheme.parchmentSurface,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: _hasText
                                ? AppTheme.inkForeground
                                : AppTheme.borderLight,
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: _hasText ? AppTheme.paperBackground : AppTheme.inkForeground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Confirm Button (Place tasks on my desk)
            ApplePressable(
              pressedScale: 0.97,
              onTap: _tasks.isEmpty
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      widget.onConfirmTasks(_tasks);
                      Navigator.pop(context);
                    },
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _tasks.isEmpty
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          widget.onConfirmTasks(_tasks);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.inkForeground,
                    foregroundColor: AppTheme.paperBackground,
                    disabledBackgroundColor: AppTheme.borderLight,
                    disabledForegroundColor: AppTheme.mutedText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _tasks.isEmpty
                            ? 'Add targets to place on desk'
                            : 'Place ${_tasks.length} ${_tasks.length == 1 ? 'Target' : 'Targets'} on Desk',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDeskState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.parchmentSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.borderLight,
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.borderLight,
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: AppTheme.inkForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your desk is clear',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkForeground,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Choose a study mode and stamp your first focus target.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableTaskList() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.32,
      ),
      child: ReorderableListView.builder(
        scrollController: _listScrollController,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        buildDefaultDragHandles: false,
        itemCount: _tasks.length,
        onReorder: _reorderTasks,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Container(
            key: ValueKey(task.id),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.inkForeground.withValues(alpha: 0.05),
                  offset: const Offset(0, 1.5),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                // Category Stamp Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
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
                        _categoryIcon(task.category),
                        size: 11,
                        color: AppTheme.inkForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.category.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Task Title
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Delete Button
                ApplePressable(
                  pressedScale: 0.85,
                  onTap: () => _removeTask(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),

                // Drag Handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.video:
        return Icons.play_circle_outline_rounded;
      case TaskCategory.qbank:
        return Icons.quiz_outlined;
      case TaskCategory.revision:
        return Icons.sync_rounded;
      case TaskCategory.notes:
        return Icons.auto_stories_outlined;
      case TaskCategory.general:
        return Icons.flag_outlined;
    }
  }

  String _categoryHint(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.video:
        return 'Enter lecture or video topic…';
      case TaskCategory.qbank:
        return 'Enter Q-Bank module or topic…';
      case TaskCategory.revision:
        return 'Enter topic for active recall…';
      case TaskCategory.notes:
        return 'Enter notes or pearls to read…';
      case TaskCategory.general:
        return 'Enter daily study target…';
    }
  }
}
