import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/daily_desk_task.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/automated_module_tracker.dart';
import '../../widgets/study_desk_clock.dart';
import '../../widgets/study_task_card.dart';
import '../../widgets/task_setup_sheet.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../widgets/sync_status_badge.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);

    return appStateAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: Text('Error loading Modulix: $e')),
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
                staggerMs: 55,
                durationMs: 450,
                slideY: 16.0,
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
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.inkForeground,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: RepaintBoundary(child: StudyDeskClock()),
                  ),

                  // ③ Today's Tasks Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _HomeTasksSection(),
                  ),

                  // ④ Module Based Tasks Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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

class _HomeTasksSection extends ConsumerWidget {
  const _HomeTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyTasksProvider.notifier).checkDayRollover();
    });

    final dailyTasksState = ref.watch(dailyTasksProvider);
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
                  Text(
                    "Today's tasks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                      letterSpacing: -0.3,
                    ),
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
            if (deskTasks.isNotEmpty)
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
        const SizedBox(height: 14),
        if (deskTasks.isEmpty)
          _buildEmptyTasksState(context, ref, deskTasks)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deskTasks.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.lightImpact();
              ref.read(dailyTasksProvider.notifier).reorderTasks(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final task = deskTasks[index];
              final isDone = completedTaskIds.contains(task.id);

              final taskCard = StudyTaskCard(
                id: task.id,
                title: task.title,
                category: task.category,
                customSubtitle: 'Goal #${index + 1}',
                isCompleted: isDone,
                onToggle: () async {
                  final finishedAll = await ref.read(dailyTasksProvider.notifier).toggleTask(task.id);
                  if (finishedAll) {
                    HapticFeedback.heavyImpact();
                  }
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
                color: AppTheme.parchmentSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.borderLight,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.checklist_rounded,
                size: 42,
                color: AppTheme.inkForeground.withValues(alpha: 0.65),
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
                color: AppTheme.inkForeground,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkForeground.withValues(alpha: 0.15),
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
                      size: 18,
                      color: AppTheme.paperBackground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Set up today's tasks",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.paperBackground,
                        letterSpacing: 0.1,
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
    TaskSetupSheet.show(
      context,
      currentTasks: currentTasks,
      onConfirmTasks: (updatedTasks) {
        ref.read(dailyTasksProvider.notifier).setTasks(updatedTasks);
      },
    );
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

class _FloatingBreath extends StatefulWidget {
  final Widget child;
  const _FloatingBreath({required this.child});

  @override
  State<_FloatingBreath> createState() => _FloatingBreathState();
}

class _FloatingBreathState extends State<_FloatingBreath>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _translateAnimation = Tween<double>(begin: 0.0, end: -5.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}



