import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_item.dart';
import '../../models/task_project.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/tasks_theme.dart';

/// Minimal quick-add sheet that docks above the soft keyboard.
/// Pure white surface, single-line text input, due date, project selector,
/// and priority picker. No tags, no under-text, no sketch borders.
class TasksQuickAddSheet extends ConsumerStatefulWidget {
  final DateTime? initialDueDate;
  final String? initialProjectId;

  const TasksQuickAddSheet({
    super.key,
    this.initialDueDate,
    this.initialProjectId,
  });

  @override
  ConsumerState<TasksQuickAddSheet> createState() => _TasksQuickAddSheetState();
}

class _TasksQuickAddSheetState extends ConsumerState<TasksQuickAddSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  DateTime? _dueDate;
  String? _projectId;
  TaskItemPriority _priority = TaskItemPriority.p4low;
  String? _selectedType;
  int? _estimatedMinutes;

  static const _taskTypes = [
    (name: 'Video', icon: Icons.play_circle_outline_rounded, duration: 35, color: Color(0xFF3B82F6)),
    (name: 'Q-Bank', icon: Icons.quiz_outlined, duration: 40, color: Color(0xFF10B981)),
    (name: 'Notes', icon: Icons.description_outlined, duration: 25, color: Color(0xFFF59E0B)),
    (name: 'Revision', icon: Icons.replay_rounded, duration: 20, color: Color(0xFF8B5CF6)),
  ];

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDueDate;
    _projectId = widget.initialProjectId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    final notifier = ref.read(tasksHubProvider.notifier);
    final task = notifier.buildNewTask(
      title: title,
      dueDate: _dueDate,
      projectId: _projectId,
      priority: _priority,
      estimatedMinutes: _estimatedMinutes,
      tags: _selectedType != null ? [_selectedType!] : const [],
    );
    await notifier.addTask(task);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(
        tasksHubProvider.select((s) => s.value?.projects ?? []));
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: TasksTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: TasksTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Text input row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.circle_outlined,
                      size: 20, color: TasksTheme.textTertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: TasksTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Add a task...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: TasksTheme.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _submit,
                    icon: const Icon(Icons.arrow_upward_rounded,
                        size: 20, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: TasksTheme.accent,
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // Tactile Task Type Selector Pills (Video, Q-Bank, Notes, Revision)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _taskTypes.map((type) {
                    final isSelected = _selectedType == type.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_selectedType == type.name) {
                              _selectedType = null;
                              _estimatedMinutes = null;
                            } else {
                              _selectedType = type.name;
                              _estimatedMinutes = type.duration;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? type.color.withValues(alpha: 0.12)
                                : TasksTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? type.color.withValues(alpha: 0.5)
                                  : TasksTheme.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type.icon,
                                size: 15,
                                color: isSelected ? type.color : TasksTheme.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${type.name} · ${type.duration}m',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? type.color : TasksTheme.textSecondary,
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

            const Divider(height: 1),

            // Accessory bar
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // Due date
                  _AccessoryChip(
                    icon: Icons.calendar_today_outlined,
                    label: _dueDate == null
                        ? 'Date'
                        : _formatDate(_dueDate!),
                    isActive: _dueDate != null,
                    onTap: _pickDate,
                  ),
                  const SizedBox(width: 6),

                  // Priority
                  _AccessoryChip(
                    icon: Icons.flag_outlined,
                    label: _priority == TaskItemPriority.p4low
                        ? 'Priority'
                        : _priority.label,
                    isActive: _priority != TaskItemPriority.p4low,
                    accentColor: _priority == TaskItemPriority.p4low
                        ? null
                        : TasksTheme.priorityColor(_priority.level),
                    onTap: _pickPriority,
                  ),
                  const SizedBox(width: 6),

                  // Project
                  if (projects.isNotEmpty)
                    _AccessoryChip(
                      icon: Icons.folder_outlined,
                      label: _projectId == null
                          ? 'Project'
                          : (projects
                                  .where((p) => p.id == _projectId)
                                  .firstOrNull
                                  ?.name ??
                              'Project'),
                      isActive: _projectId != null,
                      onTap: () => _pickProject(projects),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: TasksTheme.themeData,
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickPriority() async {
    HapticFeedback.selectionClick();
    const levels = TaskItemPriority.values;
    final result = await showModalBottomSheet<TaskItemPriority>(
      context: context,
      backgroundColor: TasksTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TasksTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...levels.map(
              (p) => ListTile(
                leading: Icon(Icons.flag_rounded,
                    color: TasksTheme.priorityColor(p.level), size: 20),
                title: Text(p.label,
                    style: const TextStyle(fontSize: 15, color: TasksTheme.textPrimary)),
                onTap: () => Navigator.pop(context, p),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _priority = result);
  }

  Future<void> _pickProject(List<TaskProject> projects) async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: TasksTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TasksTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, size: 20, color: TasksTheme.textSecondary),
              title: const Text('No project',
                  style: TextStyle(fontSize: 15, color: TasksTheme.textSecondary)),
              onTap: () => Navigator.pop(context, ''),
            ),
            ...projects.map(
              (p) => ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hexToColor(p.colorHex),
                  ),
                ),
                title: Text(p.name,
                    style: const TextStyle(fontSize: 15, color: TasksTheme.textPrimary)),
                onTap: () => Navigator.pop(context, p.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() => _projectId = result.isEmpty ? null : result);
    }
  }

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dd = DateTime(d.year, d.month, d.day);
    if (dd == today) return 'Today';
    if (dd == tomorrow) return 'Tomorrow';
    return '${d.month}/${d.day}';
  }

  static Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return TasksTheme.textTertiary;
    }
  }
}

class _AccessoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? accentColor;
  final VoidCallback onTap;

  const _AccessoryChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isActive
        ? (accentColor ?? TasksTheme.accent)
        : TasksTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (accentColor ?? TasksTheme.accent).withValues(alpha: 0.08)
              : TasksTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? (accentColor ?? TasksTheme.accent).withValues(alpha: 0.3)
                : TasksTheme.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
