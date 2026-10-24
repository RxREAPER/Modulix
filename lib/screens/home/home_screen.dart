import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/daily_desk_task.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/focus_timer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/automated_module_tracker.dart';
import '../../widgets/study_desk_clock.dart';
import '../../widgets/study_task_card.dart';
import '../../widgets/planner/keyboard_docked_task_input.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../widgets/sync_status_badge.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';


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
              padding: const EdgeInsets.only(top: 16, bottom: 120),
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
                    child: _HomeModuleTrackerSection(),
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

class _HomeTasksSection extends ConsumerStatefulWidget {
  const _HomeTasksSection();

  @override
  ConsumerState<_HomeTasksSection> createState() => _HomeTasksSectionState();
}

class _HomeTasksSectionState extends ConsumerState<_HomeTasksSection> {
  bool _seenFirstDeskIntro = false;

  @override
  void initState() {
    super.initState();
    _checkFirstIntroPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dailyTasksProvider.notifier).checkDayRollover();
      }
    });
  }

  Future<void> _checkFirstIntroPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_first_desk_intro') ?? false;
    final dailyTasksState = ref.read(dailyTasksProvider);
    final hasHistory = dailyTasksState.dateHistory.isNotEmpty || dailyTasksState.tasks.isNotEmpty;

    if (!mounted) return;
    setState(() {
      _seenFirstDeskIntro = seen || hasHistory;
    });
  }

  Future<void> _markFirstDeskIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_first_desk_intro', true);
    if (mounted) {
      setState(() => _seenFirstDeskIntro = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyTasksState = ref.watch(dailyTasksProvider);
    final timerState = ref.watch(focusTimerProvider);
    final deskTasks = dailyTasksState.tasks;
    final completedTaskIds = dailyTasksState.completedIds;

    final totalCount = deskTasks.length;
    final completedCount = deskTasks.where((t) => completedTaskIds.contains(t.id)).length;
    final isAllDone = totalCount > 0 && completedCount == totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        "Today's tasks",
                        style: AppTheme.headingStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ApplePressable(
                        pressedScale: 0.90,
                        onTap: () => context.push('/planner'),
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
                    deskTasks.isEmpty
                        ? 'Plan a focused study day'
                        : isAllDone
                            ? 'All goals completed · Great focus today, Doctor'
                            : '$completedCount of $totalCount completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isAllDone ? FontWeight.w700 : FontWeight.w500,
                      color: isAllDone ? const Color(0xFF059669) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApplePressable(
                  pressedScale: 0.94,
                  onTap: () => context.push('/planner'),
                  child: Container(
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: AppTheme.parchmentSurface,
                      borderRadius: 10,
                      borderWidth: 1.2,
                      shadowOffset: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 13, color: AppTheme.inkForeground),
                        const SizedBox(width: 4),
                        Text(
                          'Planner',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ApplePressable(
                  pressedScale: 0.94,
                  onPressed: () => _openTaskSheet(context, ref, deskTasks),
                  child: Container(
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: AppTheme.cardWhite,
                      borderRadius: 10,
                      borderWidth: 1.4,
                      shadowOffset: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 15, color: AppTheme.inkForeground),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 12,
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
          ],
        ),
        const SizedBox(height: 14),
        if (deskTasks.isEmpty)
          _buildEmptyTasksState(context, ref, deskTasks)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deskTasks.length,
            onReorderItem: (oldIndex, newIndex) {
              HapticFeedback.lightImpact();
              ref.read(dailyTasksProvider.notifier).reorderTasks(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final task = deskTasks[index];
              final isDone = completedTaskIds.contains(task.id);
              final isFocusActive = timerState.isRunning && timerState.boundTaskId == task.id;

              final taskCard = StudyTaskCard(
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
                customSubtitle: null,
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
                  final removedTask = task;
                  final wasCompleted = isDone;
                  ref.read(dailyTasksProvider.notifier).removeTaskAt(index);

                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 4),
                      content: Text('Removed "${removedTask.title}"'),
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: AppTheme.highlightStrong,
                        onPressed: () {
                          ref.read(dailyTasksProvider.notifier).insertTaskAt(index, removedTask, wasCompleted);
                        },
                      ),
                    ),
                  );
                },
                dragHandle: ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              );

              if (index == 0) {
                return KeyedSubtree(
                  key: ValueKey(task.id),
                  child: Container(
                    key: TourTargetRegistry.keyFor(TourTargetId.todaysTasksTarget),
                    child: taskCard,
                  ),
                );
              }

              return KeyedSubtree(
                key: ValueKey(task.id),
                child: taskCard,
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyTasksState(
    BuildContext context,
    WidgetRef ref,
    List<DailyDeskTask> currentTasks,
  ) {
    if (!_seenFirstDeskIntro) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFirstTimeBubblePrompt(context, ref, currentTasks),
          const SizedBox(height: 12),
          _buildQuietDeskCard(context, ref, currentTasks),
        ],
      );
    }
    return _buildQuietDeskCard(context, ref, currentTasks);
  }

  Widget _buildFirstTimeBubblePrompt(
    BuildContext context,
    WidgetRef ref,
    List<DailyDeskTask> currentTasks,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Clinical tip icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates_outlined,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 11),
          // 2-line clinical copy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Isolate 3–4 high-yield objectives for today.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkForeground,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Streaks hold until 5:00 AM post-duty.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Inline [+ Plan] action
          ApplePressable(
            pressedScale: 0.94,
            onPressed: () {
              _markFirstDeskIntroSeen();
              _openTaskSheet(context, ref, currentTasks);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.inkForeground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 14, color: AppTheme.paperBackground),
                  const SizedBox(width: 2),
                  Text(
                    'Plan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.paperBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // One-tap dismissal (X)
          ApplePressable(
            pressedScale: 0.90,
            onPressed: _markFirstDeskIntroSeen,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppTheme.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuietDeskCard(
    BuildContext context,
    WidgetRef ref,
    List<DailyDeskTask> currentTasks,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Soft circular medallion with clean task icon & floating breath
          _FloatingBreath(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.accentSubtle,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.checklist_rounded,
                size: 42,
                color: AppTheme.accentPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Today's desk is quiet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.inkForeground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          ApplePressable(
            pressedScale: 0.94,
            onPressed: () => _openTaskSheet(context, ref, currentTasks),
            child: Container(
              key: TourTargetRegistry.keyFor(TourTargetId.todaysTasksTarget),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9.5),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.playlist_add_check_rounded,
                    size: 17,
                    color: AppTheme.onAccent,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    "Set up today's tasks",
                    style: AppTypography.buttonLabel(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onAccent,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTaskSheet(
    BuildContext context,
    WidgetRef ref,
    List<DailyDeskTask> currentTasks,
  ) {
    KeyboardDockedTaskInput.show(context);
  }
}

class _HomeModuleTrackerSection extends ConsumerWidget {
  const _HomeModuleTrackerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class _FloatingBreath extends StatelessWidget {
  final Widget child;
  const _FloatingBreath({required this.child});

  @override
  Widget build(BuildContext context) => child;
}



