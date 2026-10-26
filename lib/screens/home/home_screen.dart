import 'dart:ui' as ui;
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
import '../../widgets/animations/filmic_metal_mesh_background.dart';
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
        final todayFormatted = DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase();

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
                    // ① Top Header + Greeting (clean, unboxed modern layout)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                              // Integrated right actions
                              Row(
                                children: [
                                  const SyncStatusBadge(compact: true),
                                  const SizedBox(width: 10),
                                  ProfileAvatar(
                                    size: 40,
                                    colorId: state.avatarColorId,
                                    iconId: state.avatarIconId,
                                    doctorName: doctorName,
                                    onTap: () => context.go('/settings?from=/'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            todayFormatted,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Focus, $doctorName.',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkForeground,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ② Hero Modern Ambient Clock
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: RepaintBoundary(child: StudyDeskClock()),
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
                        style: TextStyle(
                          fontSize: 20,
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
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : AppTheme.parchmentSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppTheme.borderLight,
                              width: 0.75,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
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
                          : (isDark ? const Color(0xFF94A3B8) : AppTheme.mutedText),
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
                  color: isDark ? const Color(0xFF1E293B) : AppTheme.inkForeground,
                  borderRadius: BorderRadius.circular(10),
                  border: isDark
                      ? Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.75)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 15,
                      color: isDark ? Colors.white : AppTheme.paperBackground,
                    ),
                    const SizedBox(width: 4),
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

        // Unboxed Frosted Glass Rows
        if (allTasks.isEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: ApplePressable(
                onTap: () => context.push('/daily-tasks'),
                child: Container(
                  key: TourTargetRegistry.keyFor(TourTargetId.todaysTasksTarget),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.40)
                        : Colors.white.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.70),
                      width: 0.75,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFF38BDF8) : AppTheme.accentPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add your first daily task or project...',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
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
                  for (int i = 0; i < standaloneTasks.length; i++)
                    _buildHomeTaskRow(
                      context: context,
                      ref: ref,
                      task: standaloneTasks[i],
                      timerState: timerState,
                      isFirst: i == 0 && projectGroups.isEmpty,
                      isProjectTask: false,
                    ),

                  // 2. Project Task Groups
                  for (final entry in projectGroups.entries) ...[
                    Builder(
                      builder: (ctx) {
                        final project = tasksState?.projectById(entry.key);
                        final label = (project?.unitName ?? project?.name ?? entry.value.first.note ?? 'Project').toUpperCase();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 6),
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
                                      fontSize: 10.5,
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
