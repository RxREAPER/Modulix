import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_desk_task.dart';
import '../theme/app_theme.dart';
import '../models/syllabus.dart';

class TaskSetupSheet extends StatefulWidget {
  final List<Video> suggestedVideos;
  final List<DailyDeskTask> currentTasks;
  final ValueChanged<List<DailyDeskTask>> onConfirmTasks;

  const TaskSetupSheet({
    super.key,
    required this.suggestedVideos,
    required this.currentTasks,
    required this.onConfirmTasks,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Video> suggestedVideos,
    required List<DailyDeskTask> currentTasks,
    required ValueChanged<List<DailyDeskTask>> onConfirmTasks,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (context) => TaskSetupSheet(
        suggestedVideos: suggestedVideos,
        currentTasks: currentTasks,
        onConfirmTasks: onConfirmTasks,
      ),
    );
  }

  @override
  State<TaskSetupSheet> createState() => _TaskSetupSheetState();
}

class _TaskSetupSheetState extends State<TaskSetupSheet> {
  late List<DailyDeskTask> _tasks;
  final TextEditingController _textController = TextEditingController();
  TaskCategory _selectedCategory = TaskCategory.video;

  @override
  void initState() {
    super.initState();
    if (widget.currentTasks.isNotEmpty) {
      _tasks = List.from(widget.currentTasks);
    } else {
      _tasks = widget.suggestedVideos
          .asMap()
          .entries
          .map((entry) => DailyDeskTask(
                id: 'task_${entry.key}_${entry.value.id}',
                title: entry.value.title,
                category: TaskCategory.video,
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _tasks.add(DailyDeskTask(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          title: text,
          category: _selectedCategory,
        ));
        _textController.clear();
      });
    }
  }

  void _removeTask(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF1C1C1C), width: 2),
            left: BorderSide(color: Color(0xFF1C1C1C), width: 2),
            right: BorderSide(color: Color(0xFF1C1C1C), width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x201C1C1C),
              offset: Offset(0, -6),
              blurRadius: 16,
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, isKeyboardOpen ? 12 : 32),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Set up today's tasks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Add goals & customize tags for your study desk.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.inkForeground),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Quick Category Presets Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    TaskCategory.video,
                    TaskCategory.qbank,
                    TaskCategory.revision,
                    TaskCategory.notes,
                    TaskCategory.general,
                  ].map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          _categoryIcon(cat),
                          size: 14,
                          color: isSelected ? Colors.white : AppTheme.inkForeground,
                        ),
                        label: Text(cat.label),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppTheme.inkForeground,
                        backgroundColor: const Color(0xFFF3F1EA),
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF4A463F),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? AppTheme.inkForeground : const Color(0xFFD6D2C4),
                            width: 1.2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Task List
              if (_tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No tasks selected yet. Type one below!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.28,
                  ),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    shrinkWrap: true,
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.paperBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _categoryIcon(task.category),
                              size: 15,
                              color: AppTheme.inkForeground,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.inkForeground,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () => _removeTask(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // Add Input Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addTask(),
                      decoration: InputDecoration(
                        hintText: 'Add ${_selectedCategory.label} goal…',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.inkForeground,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.inkForeground,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _addTask,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.inkForeground,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _tasks.isEmpty
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          widget.onConfirmTasks(_tasks);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Place tasks on my desk',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        return Icons.replay_rounded;
      case TaskCategory.notes:
        return Icons.edit_note_rounded;
      case TaskCategory.general:
        return Icons.flag_outlined;
    }
  }
}
