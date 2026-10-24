import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/daily_desk_task.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/study_task_card.dart';
import 'plan_tomorrow_sheet.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  MedicalSubject? _selectedSubject;
  bool _hideCompleted = false;

  void _openQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 320),
        reverseDuration: Duration(milliseconds: 240),
      ),
      builder: (context) => _QuickAddTaskSheet(
        initialSubject: _selectedSubject ?? MedicalSubject.general,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeDataProvider);
    final tasksState = ref.watch(dailyTasksProvider);
    final allTasks = tasksState.tasks;
    final completedIds = tasksState.completedIds;

    // Filter tasks
    var filteredTasks = allTasks;
    if (_selectedSubject != null && _selectedSubject != MedicalSubject.general) {
      filteredTasks = filteredTasks.where((t) => t.subject == _selectedSubject).toList();
    }
    if (_hideCompleted) {
      filteredTasks = filteredTasks.where((t) => !completedIds.contains(t.id)).toList();
    }

    final totalCount = allTasks.length;
    final completedCount = allTasks.where((t) => completedIds.contains(t.id)).length;
    final pendingCount = totalCount - completedCount;

    // Estimated minutes remaining
    int remainingEstMinutes = 0;
    int urgentPendingCount = 0;
    for (final t in allTasks) {
      if (!completedIds.contains(t.id)) {
        remainingEstMinutes += (t.estimatedMinutes ?? 30);
        if (t.priority == TaskPriority.p1urgent) {
          urgentPendingCount++;
        }
      }
    }

    // Group filtered tasks by priority
    final p1Tasks = filteredTasks.where((t) => t.priority == TaskPriority.p1urgent).toList();
    final p2Tasks = filteredTasks.where((t) => t.priority == TaskPriority.p2high).toList();
    final p3Tasks = filteredTasks.where((t) => t.priority == TaskPriority.p3medium).toList();
    final p4Tasks = filteredTasks.where((t) => t.priority == TaskPriority.p4low).toList();

    final todayFormatted = DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todayFormatted,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.mutedText,
              ),
            ),
            Text(
              'Study Task Planner',
              style: AppTheme.headingStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkForeground,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _hideCompleted ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: _hideCompleted ? AppTheme.accentPrimary : AppTheme.inkForeground,
              size: 20,
            ),
            tooltip: _hideCompleted ? 'Showing pending only' : 'Hide completed',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _hideCompleted = !_hideCompleted);
            },
          ),
          ApplePressable(
            pressedScale: 0.94,
            onTap: () => PlanTomorrowSheet.show(context),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.next_plan_outlined, size: 14, color: AppTheme.inkForeground),
                  const SizedBox(width: 4),
                  Text(
                    'Tomorrow',
                    style: TextStyle(
                      fontSize: 11.5,
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
      body: FadeSlideEntrance(
        durationMs: 180,
        slideY: 10.0,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
          children: [
            // ── 1. Hero Velocity Overview Card ───────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sketchDecoration(
                backgroundColor: AppTheme.cardWhite,
                borderRadius: 18,
                shadowOffset: 3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalCount == 0
                                ? 'No tasks on study desk'
                                : completedCount == totalCount
                                    ? 'All targets conquered today'
                                    : '$pendingCount pending study targets',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            urgentPendingCount > 0
                                ? '$urgentPendingCount Urgent (P1) · ~${remainingEstMinutes}m estimated focus'
                                : '~${remainingEstMinutes}m study time scheduled today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: urgentPendingCount > 0 ? AppTheme.accentPrimary : AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.parchmentSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Text(
                          '$completedCount/$totalCount Done',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Segmented mini-bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0,
                      minHeight: 6,
                      backgroundColor: AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completedCount == totalCount && totalCount > 0
                            ? const Color(0xFF059669)
                            : AppTheme.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 2. Medical Subject Filter Chips Row ──────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildSubjectFilterChip(
                    label: 'All Subjects',
                    count: allTasks.length,
                    isSelected: _selectedSubject == null || _selectedSubject == MedicalSubject.general,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSubject = null);
                    },
                  ),
                  ...MedicalSubject.values
                      .where((s) => s != MedicalSubject.general)
                      .map((subj) {
                    final count = allTasks.where((t) => t.subject == subj).length;
                    return _buildSubjectFilterChip(
                      label: subj.label,
                      count: count > 0 ? count : null,
                      isSelected: _selectedSubject == subj,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedSubject = (_selectedSubject == subj) ? null : subj;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 3. Priority Sections ──────────────────────────────────────
            if (filteredTasks.isEmpty)
              _buildEmptyState()
            else ...[
              _buildPrioritySection(
                title: 'P1 URGENT',
                color: AppTheme.accentPrimary,
                tasks: p1Tasks,
                completedIds: completedIds,
              ),
              _buildPrioritySection(
                title: 'P2 HIGH',
                color: const Color(0xFFEAB308),
                tasks: p2Tasks,
                completedIds: completedIds,
              ),
              _buildPrioritySection(
                title: 'P3 MEDIUM',
                color: AppTheme.accentSecondary,
                tasks: p3Tasks,
                completedIds: completedIds,
              ),
              _buildPrioritySection(
                title: 'P4 LOW',
                color: AppTheme.mutedText,
                tasks: p4Tasks,
                completedIds: completedIds,
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: ApplePressable(
        pressedScale: 0.92,
        onTap: () => _openQuickAddSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: AppTheme.sketchDecoration(
            backgroundColor: AppTheme.inkForeground,
            borderRadius: 24,
            shadowOffset: 3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: AppTheme.paperBackground, size: 19),
              const SizedBox(width: 6),
              Text(
                'Add Task',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.paperBackground,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectFilterChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ApplePressable(
        pressedScale: 0.94,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.inkForeground : AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.inkForeground : AppTheme.borderLight,
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.paperBackground.withValues(alpha: 0.2)
                        : AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.paperBackground : AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySection({
    required String title,
    required Color color,
    required List<DailyDeskTask> tasks,
    required Set<String> completedIds,
  }) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.inkForeground,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${tasks.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tasks.map((task) {
            final isDone = completedIds.contains(task.id);
            return StudyTaskCard(
              id: task.id,
              title: task.title,
              category: task.category,
              subject: task.subject,
              priority: task.priority,
              estimatedMinutes: task.estimatedMinutes,
              actualMinutesSpent: task.actualMinutesSpent,
              isRecurring: task.isRecurring,
              isCompleted: isDone,
              onToggle: () async {
                final finishedAll = await ref.read(dailyTasksProvider.notifier).toggleTask(task.id);
                if (finishedAll) {
                  HapticFeedback.heavyImpact();
                }
              },
              onDismissed: () {
                final index = ref.read(dailyTasksProvider).tasks.indexWhere((t) => t.id == task.id);
                if (index != -1) {
                  ref.read(dailyTasksProvider.notifier).removeTaskAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 4),
                      content: Text('Removed "${task.title}"'),
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: AppTheme.highlightStrong,
                        onPressed: () {
                          ref.read(dailyTasksProvider.notifier).insertTaskAt(index, task, isDone);
                        },
                      ),
                    ),
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.cardWhite,
        borderRadius: 18,
        shadowOffset: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, size: 36, color: AppTheme.mutedText),
          const SizedBox(height: 12),
          Text(
            'No targets match your filter',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "+ Add Task" to schedule high-yield clinical goals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddTaskSheet extends ConsumerStatefulWidget {
  final MedicalSubject initialSubject;
  const _QuickAddTaskSheet({required this.initialSubject});

  @override
  ConsumerState<_QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<_QuickAddTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  late MedicalSubject _subject;
  TaskCategory _category = TaskCategory.revision;
  TaskPriority _priority = TaskPriority.p2high;
  int? _estimatedMinutes = 45;
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(dailyTasksProvider.notifier).addTask(
      DailyDeskTask(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        category: _category,
        subject: _subject,
        priority: _priority,
        estimatedMinutes: _estimatedMinutes,
        isRecurring: _isRecurring,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkForeground.withValues(alpha: 0.12),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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

              Text(
                'New Study Task',
                style: AppTheme.headingStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkForeground,
                ),
              ),
              const SizedBox(height: 12),

              // Title Input
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  cursorColor: AppTheme.inkForeground,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkForeground,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Autonomic Nervous System 50 MCQs',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _saveTask(),
                ),
              ),

              const SizedBox(height: 16),

              // Category Modality Chips
              Text(
                'MODALITY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ApplePressable(
                        pressedScale: 0.94,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _category = cat);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.inkForeground : AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppTheme.inkForeground : AppTheme.borderLight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Medical Subject Scroller
              Text(
                'MEDICAL SUBJECT PRESET',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: MedicalSubject.values.map((subj) {
                    final isSelected = _subject == subj;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ApplePressable(
                        pressedScale: 0.94,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _subject = subj);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accentPrimary : AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppTheme.accentPrimary : AppTheme.borderLight,
                            ),
                          ),
                          child: Text(
                            subj.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppTheme.onAccent : AppTheme.inkForeground,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Priority & Estimated Time Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRIORITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: TaskPriority.values.map((prio) {
                            final isSel = _priority == prio;
                            final color = StudyTaskCard.priorityColor(prio);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ApplePressable(
                                pressedScale: 0.88,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _priority = prio);
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: isSel ? 0.25 : 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSel ? color : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EST. DURATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [30, 45, 60, 90].map((mins) {
                            final isSel = _estimatedMinutes == mins;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ApplePressable(
                                pressedScale: 0.94,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _estimatedMinutes = isSel ? null : mins);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppTheme.inkForeground : AppTheme.parchmentSurface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${mins}m',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSel ? AppTheme.paperBackground : AppTheme.inkForeground,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Recurring toggle
              ApplePressable(
                pressedScale: 0.98,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isRecurring = !_isRecurring);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isRecurring ? AppTheme.accentPrimary : AppTheme.borderLight,
                      width: _isRecurring ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 18,
                        color: _isRecurring ? AppTheme.accentPrimary : AppTheme.mutedText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-reappear on desk daily (Recurring)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),
                      Icon(
                        _isRecurring ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: _isRecurring ? AppTheme.accentPrimary : AppTheme.mutedText,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Confirm button
              ApplePressable(
                pressedScale: 0.97,
                onTap: _saveTask,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.inkForeground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Place on Study Desk',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.paperBackground,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
