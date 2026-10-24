import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/daily_desk_task.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/focus_timer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/study_task_card.dart';
import '../../widgets/planner/keyboard_docked_task_input.dart';
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
    KeyboardDockedTaskInput.show(
      context,
      initialSubject: _selectedSubject ?? MedicalSubject.general,
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
    final timerState = ref.watch(focusTimerProvider);

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
            final isFocusActive = timerState.isRunning && timerState.boundTaskId == task.id;
            return StudyTaskCard(
              id: task.id,
              title: task.title,
              category: task.category,
              subject: task.subject,
              priority: task.priority,
              estimatedMinutes: task.estimatedMinutes,
              actualMinutesSpent: task.actualMinutesSpent,
              estimatedBlocks: task.effectiveEstimatedBlocks,
              completedBlocks: task.effectiveCompletedBlocks,
              isRecurring: task.isRecurring,
              isCompleted: isDone,
              isFocusActive: isFocusActive,
              onToggle: () async {
                final finishedAll = await ref.read(dailyTasksProvider.notifier).toggleTask(task.id);
                if (finishedAll) {
                  HapticFeedback.heavyImpact();
                }
              },
              onStartFocus: () {
                HapticFeedback.mediumImpact();
                ref.read(focusTimerProvider.notifier).startTaskFocus(task);
                context.push('/timer');
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

