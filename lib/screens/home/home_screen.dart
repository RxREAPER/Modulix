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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);

    return appStateAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: Text('Error loading FlowMD: $e')),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.inkForeground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'F',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FlowMD',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.inkForeground,
                                ),
                              ),
                              Text(
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
                      InkWell(
                        onTap: () => context.push('/settings'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.inkForeground,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppTheme.inkForeground,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Greeting Section
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
                    style: const TextStyle(
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

                  const SizedBox(height: 24),

                  // Hero Study Desk Clock & Nori Mascot (Isolated with RepaintBoundary)
                  const RepaintBoundary(
                    child: StudyDeskClock(),
                  ),

                  const SizedBox(height: 28),

                  // Today's Tasks Section (Isolated in _HomeTasksSection)
                  const _HomeTasksSection(),

                  const SizedBox(height: 28),

                  // Module Based Tasks Section (Isolated with RepaintBoundary)
                  const _HomeModuleTrackerSection(),
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
    final progressFraction = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

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
                  const Text(
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
              Container(
                decoration: AppTheme.sketchDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: 10,
                  borderWidth: 1.4,
                  shadowOffset: 1.5,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openTaskSheet(context, ref, deskTasks),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 15, color: AppTheme.inkForeground),
                          SizedBox(width: 4),
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
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.lightImpact();
              ref.read(dailyTasksProvider.notifier).reorderTasks(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final task = deskTasks[index];
              final isDone = completedTaskIds.contains(task.id);

              return StudyTaskCard(
                key: ValueKey(task.id),
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
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F2FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_outlined,
                    size: 42,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const Positioned(
                right: 2,
                top: 0,
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppTheme.highlightStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Your page is clear',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sketch out a few goals for today. Nori will keep you company.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openTaskSheet(context, ref, currentTasks),
            icon: const Icon(Icons.playlist_add_check, size: 20),
            label: const Text(
              "Set up today's tasks",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
    final suggestedVideos = ref.read(suggestedVideosProvider);
    TaskSetupSheet.show(
      context,
      suggestedVideos: suggestedVideos,
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



