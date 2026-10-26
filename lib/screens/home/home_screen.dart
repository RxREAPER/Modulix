import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../models/task_item.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../providers/focus_timer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/automated_module_tracker.dart';
import '../../widgets/study_desk_clock.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../widgets/sync_status_badge.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';
import '../../widgets/feedback/modulix_toast.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final appStateAsync = ref.watch(appStateProvider);

    return appStateAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const SafeArea(child: DeskTasksSkeletonView()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: SafeArea(
          child: AppErrorStateView(
            error: e,
            stackTrace: st,
            onRetry: () => ref.refresh(appStateProvider),
          ),
        ),
      ),
      data: (state) {
        final doctorName = state.doctorName.isNotEmpty ? state.doctorName : 'Doctor';
        final todayFormatted = DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase();

        return Scaffold(
          backgroundColor: AppTheme.paperBackground,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.only(
                top: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 100.0,
              ),
              child: PageEntrance(
                staggerMs: 35,
                durationMs: 220,
                slideY: 12.0,
                children: [
                  // ① Top Header + Greeting (single block — they're small)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppTheme.inkForeground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'M',
                                      style: TextStyle(
                                        color: AppTheme.paperBackground,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Modulix',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.inkForeground,
                                      ),
                                    ),
                                    const Text(
                                      'DAILY COMPANION',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const SyncStatusBadge(compact: true),
                                const SizedBox(width: 10),
                                ProfileAvatar(
                                  size: 46,
                                  colorId: state.avatarColorId,
                                  iconId: state.avatarIconId,
                                  doctorName: doctorName,
                                  onTap: () => context.go('/settings?from=/'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          todayFormatted,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Focus, $doctorName.',
                          style: AppTheme.headingStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Transform.rotate(
                          angle: -0.02,
                          child: Container(
                            width: 90,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.highlightCoral,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ② Hero Study Desk Clock (Full Width Integration)
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: RepaintBoundary(child: StudyDeskClock()),
                  ),

                  // ③ Today's Tasks Section
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: RepaintBoundary(child: _HomeTasksSection()),
                  ),

                  // ④ Module Based Tasks Section
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: RepaintBoundary(child: _HomeModuleTrackerSection()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeTasksSection extends ConsumerWidget {
  const _HomeTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final tasksState = ref.watch(tasksHubProvider).valueOrNull;
    final timerState = ref.watch(focusTimerProvider);
    final isDark = AppTheme.current.isDark;

    final todayTasks = tasksState?.todayTasks ?? const [];
    final completedTasks = tasksState?.todayCompletedTasks ?? const [];
    final allTasks = [...todayTasks, ...completedTasks];

    final totalCount = allTasks.length;
    final completedCount = completedTasks.length;
    final isAllDone = totalCount > 0 && completedCount == totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "Daily tasks" with clean counter and navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Daily tasks',
                        style: AppTheme.headingStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ApplePressable(
                        pressedScale: 0.90,
                        onTap: () => context.push('/daily-tasks'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight, width: 1),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalCount == 0
                        ? 'Plan your daily targets'
                        : isAllDone
                            ? 'All goals completed today'
                            : '$completedCount of $totalCount completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isAllDone ? FontWeight.w700 : FontWeight.w500,
                      color: isAllDone
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                          : AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            ApplePressable(
              pressedScale: 0.94,
              onTap: () => context.push('/daily-tasks'),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppTheme.inkForeground,
                  borderRadius: BorderRadius.circular(8),
                  border: isDark
                      ? Border.all(color: const Color(0xFF2C2C2E), width: 1)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: isDark ? Colors.white : AppTheme.paperBackground,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.paperBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Unboxed Vertical Text Continuations (NO CARDS)
        if (allTasks.isEmpty)
          ApplePressable(
            onTap: () => context.push('/daily-tasks'),
            child: Padding(
              key: TourTargetRegistry.keyFor(TourTargetId.todaysTasksTarget),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '+ Add your first daily task or project...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          )
        else ...[
          // Grouping: Standalone Normal Tasks vs Project-Specific Tasks
          Builder(
            builder: (context) {
              final standaloneTasks = allTasks.where((t) => t.projectId == null || t.projectId!.isEmpty).toList();
              final Map<String, List<TaskItem>> projectGroups = {};
              for (final t in allTasks) {
                if (t.projectId != null && t.projectId!.isNotEmpty) {
                  projectGroups.putIfAbsent(t.projectId!, () => []).add(t);
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Standalone Normal Tasks
                  if (standaloneTasks.isNotEmpty) ...[
                    if (projectGroups.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              'STANDALONE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.9,
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: AppTheme.borderLight.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (int i = 0; i < standaloneTasks.length; i++)
                      _buildHomeTaskRow(
                        context: context,
                        ref: ref,
                        task: standaloneTasks[i],
                        timerState: timerState,
                        isFirst: i == 0 && projectGroups.isEmpty,
                        isProjectTask: false,
                      ),
                  ],

                  // 2. Project Task Groups (Subtle Intra-Project Differentiation)
                  for (final entry in projectGroups.entries) ...[
                    Builder(
                      builder: (ctx) {
                        final project = tasksState?.projectById(entry.key);
                        final label = (project?.unitName ?? project?.name ?? entry.value.first.note ?? 'Project').toUpperCase();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.9,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: AppTheme.borderLight.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final task in entry.value)
                              _buildHomeTaskRow(
                                context: context,
                                ref: ref,
                                task: task,
                                timerState: timerState,
                                isFirst: false,
                                isProjectTask: true,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHomeTaskRow({
    required BuildContext context,
    required WidgetRef ref,
    required TaskItem task,
    required FocusTimerState timerState,
    required bool isFirst,
    required bool isProjectTask,
  }) {
    final isDone = task.isCompleted;
    final isFocusActive = timerState.isRunning && timerState.boundTaskId == task.id;

    final row = Padding(
      padding: EdgeInsets.only(
        top: 9,
        bottom: 9,
        left: isProjectTask ? 6 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Subtle vertical notch for project tasks
          if (isProjectTask) ...[
            Container(
              width: 1.5,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Check-off circle on left
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final willBeDone = !isDone;
              ref.read(tasksHubProvider.notifier).toggleTaskComplete(task.id);
              if (willBeDone) {
                ModulixToast.showUndo(
                  context,
                  message: 'Completed "${task.title}"',
                  onUndo: () {
                    ref.read(tasksHubProvider.notifier).toggleTaskComplete(task.id);
                  },
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppTheme.inkForeground : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? AppTheme.inkForeground
                        : AppTheme.mutedText.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AppTheme.paperBackground,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 11),

          // Continuous text in middle
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isDone ? FontWeight.w400 : FontWeight.w500,
                color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppTheme.mutedText,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Play button on right
          ApplePressable(
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(focusTimerProvider.notifier).startTaskItemFocus(task);
              context.push('/timer');
              ModulixToast.showInfo(
                context,
                message: 'Focus session initialized · ${task.title}',
                icon: Icons.play_arrow_rounded,
              );
            },
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              child: Icon(
                Icons.play_arrow_rounded,
                size: 21,
                color: isFocusActive ? AppTheme.accentPrimary : AppTheme.inkForeground,
              ),
            ),
          ),
        ],
      ),
    );

    final dismissibleRow = Dismissible(
      key: ValueKey('home_task_dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        final taskToDelete = task;
        ref.read(tasksHubProvider.notifier).deleteTask(task.id);
        ModulixToast.showUndo(
          context,
          message: 'Task removed',
          onUndo: () {
            ref.read(tasksHubProvider.notifier).addTask(taskToDelete);
          },
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.withValues(alpha: 0.12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: 20,
          color: Colors.redAccent,
        ),
      ),
      child: row,
    );

    if (isFirst) {
      return KeyedSubtree(
        key: ValueKey(task.id),
        child: Container(
          key: TourTargetRegistry.keyFor(TourTargetId.todaysTasksTarget),
          child: dismissibleRow,
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey(task.id),
      child: dismissibleRow,
    );
  }
}

class _HomeModuleTrackerSection extends ConsumerWidget {
  const _HomeModuleTrackerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final appState = ref.watch(appStateProvider).valueOrNull;
    final subjects = ref.watch(activeSyllabusProvider).valueOrNull ?? const [];

    if (appState == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: AutomatedModuleTracker(
        editionState: appState.currentEdition,
        editionName: appState.activeEdition,
        subjects: subjects,
      ),
    );
  }
}



