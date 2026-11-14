import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_state.dart';
import '../../models/syllabus.dart';
import '../../models/timer_theme.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/focus_timer_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

class SelectedTaskInfo {
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String topicTitle;
  final String chapterName;
  final String topicType; // 'video' | 'task' | 'standalone'
  final int? presetDurationMins;

  const SelectedTaskInfo({
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    required this.topicTitle,
    this.chapterName = '',
    required this.topicType,
    this.presetDurationMins,
  });
}

class TaskPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<SelectedTaskInfo> onSelect;
  final TimerThemeData? theme;

  const TaskPickerSheet({super.key, required this.onSelect, this.theme});

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<SelectedTaskInfo> onSelect,
    TimerThemeData? theme,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (ctx) => TaskPickerSheet(onSelect: onSelect, theme: theme),
    );
  }

  @override
  ConsumerState<TaskPickerSheet> createState() => _TaskPickerSheetState();
}

class _TaskPickerSheetState extends ConsumerState<TaskPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerTheme = widget.theme ?? ref.watch(focusTimerProvider).theme;
    final accent = timerTheme.accentColor;
    final textPrimary = AppTheme.inkForeground;
    final textSecondary = AppTheme.mutedText;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: AppTheme.cardWhite.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppTheme.borderLight,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              // Grab handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(Icons.track_changes_rounded, color: accent, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Target',
                            style: AppTheme.headingStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Choose a daily task or module target',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.parchmentSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Minimalist Pill Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight, width: 1.0),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Daily Tasks'),
                    Tab(text: 'Module Based Tasks'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 1. Daily Tasks Tab
                    _buildDailyTasksTab(accent, textPrimary, textSecondary),

                    // 2. Module Based Tasks Tab
                    _buildModuleTasksTab(accent, textPrimary, textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTasksTab(Color accent, Color textPrimary, Color textSecondary) {
    final tasksHubAsync = ref.watch(tasksHubProvider);
    final tasksHub = tasksHubAsync.valueOrNull ?? const TasksHubState();
    final todayTasks = tasksHub.todayTasks;
    final completedTasks = tasksHub.todayCompletedTasks;
    final projects = {for (final p in tasksHub.projects) p.id: p};

    if (todayTasks.isEmpty && completedTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist_rounded, size: 40, color: textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No daily tasks scheduled for today',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add tasks from the Daily Tasks page or choose a Module Target in the next tab.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      children: [
        if (todayTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              "TODAY'S TASKS",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: textSecondary,
              ),
            ),
          ),
          ...todayTasks.map((task) {
            final project = task.projectId != null ? projects[task.projectId] : null;
            final durationMins = task.estimatedMinutes ?? 25;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ApplePressable(
                pressedScale: 0.98,
                onPressed: () {
                  widget.onSelect(SelectedTaskInfo(
                    subjectId: task.projectId ?? 'daily_task',
                    subjectName: project?.name ?? 'Daily Task',
                    topicId: task.id,
                    topicTitle: task.title,
                    chapterName: project?.name ?? '',
                    topicType: 'task',
                    presetDurationMins: durationMins,
                  ));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(Icons.play_arrow_rounded, color: accent, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            if (project != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                project.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.parchmentSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight, width: 0.8),
                        ),
                        child: Text(
                          '${durationMins}m',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],

        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              'COMPLETED TODAY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: textSecondary,
              ),
            ),
          ),
          ...completedTasks.map((task) {
            return Opacity(
              opacity: 0.55,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildModuleTasksTab(Color accent, Color textPrimary, Color textSecondary) {
    final appStateAsync = ref.watch(appStateProvider);
    final syllabusAsync = ref.watch(activeSyllabusProvider);

    return appStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error loading study plan: $err', style: TextStyle(color: textSecondary)),
      ),
      data: (appState) {
        final subjects = syllabusAsync.valueOrNull ?? [];
        final activeEdition = appState.activeEdition;
        final editionState = appState.editions[activeEdition] ?? const EditionState();
        final plan = editionState.plan;

        if (!plan.isConfigured) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 40, color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No active module plan configured',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set up a subject study plan to automatically sync daily curriculum batches.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ApplePressable(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/plan');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Configure Plan',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Target Subject Resolution
        Subject? targetSubject;
        for (final s in subjects) {
          if (s.id == plan.targetSubject) {
            targetSubject = s;
            break;
          }
        }

        final subjectName = targetSubject?.name ??
            (plan.targetSubject.isNotEmpty ? plan.targetSubject.toUpperCase() : 'Curriculum');

        // Target Chapters
        List<Chapter> targetChapters = [];
        if (targetSubject != null) {
          if (plan.targetUnits.isNotEmpty) {
            for (final unitName in plan.targetUnits) {
              final ch = targetSubject.chapters
                  .where((c) =>
                      c.name.toLowerCase().trim() == unitName.toLowerCase().trim() ||
                      c.name.toLowerCase().contains(unitName.toLowerCase()) ||
                      unitName.toLowerCase().contains(c.name.toLowerCase()))
                  .firstOrNull;
              if (ch != null) targetChapters.add(ch);
            }
          } else {
            targetChapters = targetSubject.chapters;
          }
        }

        // Resolve plan videos with chapter lookup
        final Map<String, Chapter> videoChapterMap = {};
        final List<Video> planVideos = [];
        for (final chapter in targetChapters) {
          for (final v in chapter.videos) {
            planVideos.add(v);
            videoChapterMap[v.id] = chapter;
          }
        }

        // Daily batch or uncompleted videos
        final targetQuota = plan.videosPerDay ?? 4;
        final planVideoIds = planVideos.map((v) => v.id).toSet();
        List<String> effectiveBatchIds = List<String>.from(editionState.queueBatchVideoIds);

        final bool isBatchValid = effectiveBatchIds.isNotEmpty &&
            effectiveBatchIds.every((id) => planVideoIds.contains(id));

        if (!isBatchValid && planVideos.isNotEmpty) {
          final uncompleted = planVideos
              .where((v) => !editionState.completedVideos.containsKey(v.id))
              .toList();
          effectiveBatchIds = uncompleted.take(targetQuota).map((v) => v.id).toList();
        }

        final batchVideos = effectiveBatchIds
            .map((id) => planVideos.where((v) => v.id == id).firstOrNull)
            .whereType<Video>()
            .toList();

        final remainingVideos = planVideos
            .where((v) =>
                !editionState.completedVideos.containsKey(v.id) &&
                !effectiveBatchIds.contains(v.id))
            .take(10)
            .toList();

        if (batchVideos.isEmpty && remainingVideos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 44, color: Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  Text(
                    'All module targets completed!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You have completed all videos in your current study target.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
          children: [
            if (batchVideos.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Text(
                  "TODAY'S MODULE BATCH (${batchVideos.length})",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: textSecondary,
                  ),
                ),
              ),
              ...batchVideos.map((video) {
                final chapter = videoChapterMap[video.id];
                final isDone = editionState.completedVideos.containsKey(video.id);
                final durationMins = video.durationMins > 0
                    ? video.durationMins
                    : 25;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ApplePressable(
                    pressedScale: 0.98,
                    onPressed: () {
                      widget.onSelect(SelectedTaskInfo(
                        subjectId: targetSubject?.id ?? plan.targetSubject,
                        subjectName: subjectName,
                        topicId: video.id,
                        topicTitle: video.title,
                        chapterName: chapter?.name ?? '',
                        topicType: 'video',
                        presetDurationMins: durationMins,
                      ));
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFFF0FDF4) : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : AppTheme.borderLight,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF10B981)
                                  : accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                  : Icon(Icons.play_arrow_rounded, color: accent, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone ? textSecondary : textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  chapter != null
                                      ? '$subjectName · ${chapter.name}'
                                      : subjectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDone ? textSecondary : accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.parchmentSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderLight, width: 0.8),
                            ),
                            child: Text(
                              '${durationMins}m',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            if (remainingVideos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Text(
                  'UPCOMING TARGETS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: textSecondary,
                  ),
                ),
              ),
              ...remainingVideos.map((video) {
                final chapter = videoChapterMap[video.id];
                final durationMins = video.durationMins > 0
                    ? video.durationMins
                    : 25;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ApplePressable(
                    pressedScale: 0.98,
                    onPressed: () {
                      widget.onSelect(SelectedTaskInfo(
                        subjectId: targetSubject?.id ?? plan.targetSubject,
                        subjectName: subjectName,
                        topicId: video.id,
                        topicTitle: video.title,
                        chapterName: chapter?.name ?? '',
                        topicType: 'video',
                        presetDurationMins: durationMins,
                      ));
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight, width: 0.9),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.video_library_rounded, size: 16, color: accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                if (chapter != null)
                                  Text(
                                    chapter.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${durationMins}m',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}
