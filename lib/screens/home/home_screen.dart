import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../widgets/animations/filmic_metal_mesh_background.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';
import '../../widgets/feedback/modulix_toast.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final appStateAsync = ref.watch(appStateProvider);
    final isDark = AppTheme.current.isDark;

    return appStateAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: FilmicMetalMeshBackground(
          child: SafeArea(child: DeskTasksSkeletonView()),
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Colors.transparent,
        body: FilmicMetalMeshBackground(
          child: SafeArea(
            child: AppErrorStateView(
              error: e,
              stackTrace: st,
              onRetry: () => ref.refresh(appStateProvider),
            ),
          ),
        ),
      ),
      data: (state) {
        final doctorName = state.doctorName.isNotEmpty ? state.doctorName : 'Doctor';

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: FilmicMetalMeshBackground(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.only(
                  top: 14,
                  bottom: MediaQuery.paddingOf(context).bottom + 100.0,
                ),
                child: PageEntrance(
                  staggerMs: 35,
                  durationMs: 220,
                  slideY: 12.0,
                  children: [
                    // ① Sleek Brand Bar (without sync tag)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Sleek brand mark
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : AppTheme.inkForeground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
                                    width: 0.75,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? const Color(0xFF38BDF8).withValues(alpha: 0.20)
                                          : Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'M',
                                    style: TextStyle(
                                      color: AppTheme.paperBackground,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'serif',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Modulix',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: AppTheme.inkForeground,
                                ),
                              ),
                            ],
                          ),
                          // Right profile avatar (purged sync tag for pure minimalism)
                          ProfileAvatar(
                            size: 40,
                            colorId: state.avatarColorId,
                            iconId: state.avatarIconId,
                            doctorName: doctorName,
                            onTap: () => context.go('/settings?from=/'),
                          ),
                        ],
                      ),
                    ),

                    // ② Standout Unified Hero Clock Card (with generous breathing room for the gradient)
                    Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: RepaintBoundary(child: StudyDeskClock(doctorName: doctorName)),
                    ),

                    // ③ Today's Tasks Section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: RepaintBoundary(child: _HomeTasksSection()),
                    ),

                    // ④ Module Based Tasks Section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: RepaintBoundary(child: _HomeModuleTrackerSection()),
                    ),
                  ],
                ),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.70),
              width: 0.75,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unified Header: Title, Counter, and Quick Add Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Daily tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ApplePressable(
                        pressedScale: 0.90,
                        onTap: () => context.push('/daily-tasks'),
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppTheme.borderLight,
                              width: 0.75,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9.5,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalCount == 0
                            ? 'No targets'
                            : isAllDone
                                ? 'All done'
                                : '$completedCount of $totalCount completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isAllDone ? FontWeight.w700 : FontWeight.w600,
                          color: isAllDone
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ApplePressable(
                        pressedScale: 0.92,
                        onTap: () => context.push('/daily-tasks'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : AppTheme.inkForeground,
                            borderRadius: BorderRadius.circular(8),
                            border: isDark
                                ? Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.75)
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 13,
                                color: isDark ? Colors.white : AppTheme.paperBackground,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 11,
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
                ],
              ),
              const SizedBox(height: 14),

              // Tasks Content Area inside the Card
              if (allTasks.isEmpty)
                ApplePressable(
                  onTap: () => context.push('/daily-tasks'),
                  child: Container(
                    key: TourTargetRegistry.keyFor(TourTargetId.todaysTasksTarget),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.025),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        width: 0.75,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 15,
                          color: isDark ? const Color(0xFF38BDF8) : AppTheme.accentPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add your first daily task or project...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
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
                        // Standalone Tasks
                        for (int i = 0; i < standaloneTasks.length; i++)
                          _buildHomeTaskRow(
                            context: context,
                            ref: ref,
                            task: standaloneTasks[i],
                            timerState: timerState,
                            isFirst: i == 0 && projectGroups.isEmpty,
                            isProjectTask: false,
                          ),

                        // Project Task Groups
                        for (final entry in projectGroups.entries) ...[
                          Builder(
                            builder: (ctx) {
                              final project = tasksState?.projectById(entry.key);
                              final label = (project?.unitName ?? project?.name ?? entry.value.first.note ?? 'Project').toUpperCase();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, bottom: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark ? const Color(0xFF38BDF8) : AppTheme.accentPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: isDark ? const Color(0xFF94A3B8) : AppTheme.mutedText,
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
          ),
        ),
      ),
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
    final isDark = AppTheme.current.isDark;
    final isDone = task.isCompleted;
    final isFocusActive = timerState.isRunning && timerState.boundTaskId == task.id;

    final rowContent = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? (isDone
                    ? const Color(0xFF0F172A).withValues(alpha: 0.30)
                    : const Color(0xFF0F172A).withValues(alpha: 0.50))
                : (isDone
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.70)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? (isDone ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.12))
                  : (isDone ? Colors.white.withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.85)),
              width: 0.75,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Check-off circle on left with emerald animation
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
                  padding: const EdgeInsets.all(2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFF10B981)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.35)
                                : const Color(0xFF94A3B8)),
                        width: 1.5,
                      ),
                    ),
                    child: isDone
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Task title in continuous typography
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isDone ? FontWeight.w400 : FontWeight.w600,
                    color: isDone
                        ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                        : AppTheme.inkForeground,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Play launcher button on right
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isFocusActive
                        ? (isDark ? const Color(0xFF0369A1) : const Color(0xFF0284C7))
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: isFocusActive
                        ? Colors.white
                        : AppTheme.inkForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final dismissibleRow = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
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
            borderRadius: BorderRadius.circular(16),
            color: Colors.red.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: Colors.redAccent,
          ),
        ),
        child: rowContent,
      ),
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
