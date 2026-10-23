import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/subjects_metadata.dart';
import '../../models/app_state.dart';
import '../../models/syllabus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/curriculum/subject_sketch_icon.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/animations/animated_strike_text.dart';
import '../../widgets/animations/animated_check_stroke.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';
import '../../widgets/curriculum/unit_card.dart';

class ModuleTasksScreen extends ConsumerStatefulWidget {
  const ModuleTasksScreen({super.key});

  @override
  ConsumerState<ModuleTasksScreen> createState() => _ModuleTasksScreenState();
}

class _ModuleTasksScreenState extends ConsumerState<ModuleTasksScreen> {
  static String? _lastCheckedKey;

  @override
  Widget build(BuildContext context) {
    final appStateAsync = ref.watch(appStateProvider);
    final subjectsAsync = ref.watch(activeSyllabusProvider);

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          try {
            context.go('/');
          } catch (_) {}
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.paperBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.paperBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go('/');
                } catch (_) {}
              }
            },
          ),
        title: Text(
          'Module Based Tasks',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ApplePressable(
              onTap: () => context.push('/plan'),
              pressedScale: 0.94,
              borderRadius: BorderRadius.circular(10),
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
                    Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: AppTheme.inkForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Setup',
                      style: AppTypography.buttonLabel(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.2),
          child: Container(
            height: 1.2,
            color: AppTheme.parchmentBorder.withValues(alpha: 0.7),
          ),
        ),
      ),
      body: appStateAsync.when(
        loading: () => const ModuleTimelineSkeletonView(),
        error: (err, st) => AppErrorStateView(
          error: err,
          stackTrace: st,
          onRetry: () => ref.refresh(appStateProvider),
        ),
        data: (appState) {
          if (subjectsAsync.isLoading) {
            return const ModuleTimelineSkeletonView();
          }

          final subjects = subjectsAsync.valueOrNull ?? [];
          final activeEdition = appState.activeEdition;
          final editionState = appState.editions[activeEdition] ?? const EditionState();
          final plan = editionState.plan;

          if (!plan.isConfigured) {
            return _buildUnconfiguredState(context);
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

          // Scope Chapters Resolution
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

          // Active Chapter resolution for Unit View
          Chapter? activeChapter;
          int activeChapterIndex = 0;
          if (targetChapters.isNotEmpty) {
            final uncompletedChapter = targetChapters.where((c) {
              final doneV = c.videos.where((v) => editionState.completedVideos.containsKey(v.id)).length;
              final doneQ = c.qbanks.where((q) => editionState.completedQBanks.containsKey(q.id)).length;
              final doneN = c.notes.where((n) => editionState.completedNotes.containsKey(n.id)).length;
              return (doneV + doneQ + doneN) < c.totalItems;
            }).firstOrNull;

            activeChapter = uncompletedChapter ?? targetChapters.first;
            activeChapterIndex = targetSubject?.chapters.indexOf(activeChapter) ?? 0;
            if (activeChapterIndex < 0) activeChapterIndex = 0;
          }

          // In-scope Modules
          final planVideos = targetChapters.expand((c) => c.videos).toList();
          final planQBanks = targetChapters.expand((c) => c.qbanks).toList();
          final planNotes = targetChapters.expand((c) => c.notes).toList();

          final completedVideosCount = planVideos
              .where((v) => editionState.completedVideos.containsKey(v.id))
              .length;
          final completedQBanksCount = planQBanks
              .where((q) => editionState.completedQBanks.containsKey(q.id))
              .length;
          final completedNotesCount = planNotes
              .where((n) => editionState.completedNotes.containsKey(n.id))
              .length;

          final totalItemsInScope = planVideos.length + planQBanks.length + planNotes.length;
          final completedInScope = completedVideosCount + completedQBanksCount + completedNotesCount;
          final double overallProgress =
              totalItemsInScope > 0 ? (completedInScope / totalItemsInScope) : 0.0;
          final int progressPercent = (overallProgress * 100).round();

          // Day Window Calculation linked to start of the day setting
          final dayStartHour = appState.dayStartHour;
          final now = DateTime.now().subtract(Duration(hours: dayStartHour));
          final todayKey =
              '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          final targetQuota = plan.videosPerDay ?? 4;

          // Resolve Daily Batch with 2+2=4 quota capping & rollover
          final planVideoIds = planVideos.map((v) => v.id).toSet();
          List<String> effectiveBatchIds = List<String>.from(editionState.queueBatchVideoIds);
          final staleIds = editionState.staleBatchVideoIds;

          final bool isBatchValid = effectiveBatchIds.isNotEmpty &&
              effectiveBatchIds.every((id) => planVideoIds.contains(id)) &&
              effectiveBatchIds.length == targetQuota;

          if (!isBatchValid && planVideos.isNotEmpty) {
            final uncompleted = planVideos
                .where((v) => !editionState.completedVideos.containsKey(v.id))
                .toList();
            effectiveBatchIds = uncompleted.take(targetQuota).map((v) => v.id).toList();
          }

          // Refresh batch only when needed
          if (_lastCheckedKey != todayKey || !isBatchValid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _lastCheckedKey = todayKey;
              _checkAndRefreshDailyBatch(
                ref: ref,
                editionState: editionState,
                planVideos: planVideos,
                targetQuota: targetQuota,
                todayKey: todayKey,
              );
            });
          }

          final batchVideos = effectiveBatchIds
              .map((id) => planVideos.where((v) => v.id == id).firstOrNull)
              .whereType<Video>()
              .toList();

          final completedBatchCount =
              batchVideos.where((v) => editionState.completedVideos.containsKey(v.id)).length;

          // Scope Completion States
          final bool isUnitScope = plan.targetUnits.isNotEmpty;
          final String unitDisplayName =
              isUnitScope ? plan.targetUnits.join(', ') : 'All Units';
          final bool isCurrentScopeFullyCompleted =
              totalItemsInScope > 0 && completedInScope == totalItemsInScope;

          final uncompletedStaleCount = batchVideos
              .where((v) => staleIds.contains(v.id) && !editionState.completedVideos.containsKey(v.id))
              .length;

          // Pace calculation
          final String paceStatusText;
          final Color paceStatusColor;
          if (completedBatchCount >= targetQuota && targetQuota > 0) {
            paceStatusText = 'Target Met';
            paceStatusColor = const Color(0xFF059669);
          } else if (uncompletedStaleCount > 0) {
            paceStatusText = '$uncompletedStaleCount Stale';
            paceStatusColor = const Color(0xFFD97706);
          } else if (completedBatchCount > 0) {
            paceStatusText = '${targetQuota - completedBatchCount} left';
            paceStatusColor = const Color(0xFF2563EB);
          } else {
            paceStatusText = 'On Track';
            paceStatusColor = const Color(0xFF4A463F);
          }

          int daysRemaining = 0;
          if (plan.targetDate.isNotEmpty) {
            try {
              final targetDt = DateTime.parse(plan.targetDate);
              final now = DateTime.now();
              daysRemaining = DateTime.utc(targetDt.year, targetDt.month, targetDt.day)
                  .difference(DateTime.utc(now.year, now.month, now.day))
                  .inDays
                  .clamp(0, 9999);
            } catch (_) {}
          }

          return FadeSlideEntrance(
            durationMs: 180,
            slideY: 10.0,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // PART 1: The Top Banner
                _buildTopBanner(
                  context: context,
                  subjectName: subjectName,
                  editionName: activeEdition,
                  plan: plan,
                  targetSubject: targetSubject,
                  selectedUnitDisplay: unitDisplayName,
                  unitProgress: overallProgress,
                  unitProgressPercent: progressPercent,
                  completedInScope: completedInScope,
                  totalVideosInScope: totalItemsInScope,
                  completedBatchCount: completedBatchCount,
                  totalBatchCount: batchVideos.length,
                  paceStatusText: paceStatusText,
                  paceStatusColor: paceStatusColor,
                  daysRemaining: daysRemaining,
                  isUnitScope: isUnitScope,
                ),

                const SizedBox(height: 16),

                // PART 2: The New Module View (Today's Video Modules)
                _buildModuleSection(
                  context: context,
                  ref: ref,
                  targetSubject: targetSubject,
                  subjectName: subjectName,
                  batchVideos: batchVideos,
                  planQBanks: planQBanks,
                  planNotes: planNotes,
                  editionState: editionState,
                  staleIds: staleIds,
                  isCurrentScopeFullyCompleted: isCurrentScopeFullyCompleted,
                ),

                const SizedBox(height: 18),

                // Completion Notice Card if unit/scope is complete
                if (isCurrentScopeFullyCompleted) ...[
                  _buildCompletionCard(
                    context: context,
                    isUnitScope: isUnitScope,
                    unitName: unitDisplayName,
                    subjectName: subjectName,
                  ),
                  const SizedBox(height: 16),
                ],

                // PART 3: The Target Units View
                if (targetSubject != null && targetChapters.isNotEmpty) ...[
                  _buildUnitSection(
                    context: context,
                    targetSubject: targetSubject,
                    targetChapters: targetChapters,
                    activeChapter: activeChapter ?? targetChapters.first,
                    activeChapterIndex: activeChapterIndex,
                    isUnitScope: isUnitScope,
                    editionState: editionState,
                  ),
                  const SizedBox(height: 18),
                ],

                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    ),
  );
}

  /// PART 1: Top Banner with Subject, small Unit text, plan details, and Unit Progress Bar
  Widget _buildTopBanner({
    required BuildContext context,
    required String subjectName,
    required String editionName,
    required StudyPlan plan,
    required Subject? targetSubject,
    required String selectedUnitDisplay,
    required double unitProgress,
    required int unitProgressPercent,
    required int completedInScope,
    required int totalVideosInScope,
    required int completedBatchCount,
    required int totalBatchCount,
    required String paceStatusText,
    required Color paceStatusColor,
    required int daysRemaining,
    required bool isUnitScope,
  }) {
    final meta = targetSubject != null ? subjectMeta(targetSubject.id) : null;

    return Container(
      key: TourTargetRegistry.keyFor(TourTargetId.moduleTasksScreenHeader),
      width: double.infinity,
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.cardWhite,
        borderRadius: 18,
        borderWidth: 1.4,
        shadowOffset: 2.5,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Selected Subject with accent icon & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (meta != null) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: meta.accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: SubjectSketchIcon(
                          subjectId: plan.targetSubject,
                          color: meta.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjectName,
                            style: AppTheme.headingStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUnitScope ? 'Unit: $selectedUnitDisplay' : 'Scope: $selectedUnitDisplay',
                            style: AppTypography.cardSubtitle(
                              fontSize: 11.5,
                              color: AppTheme.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: paceStatusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: paceStatusColor, width: 1.2),
                ),
                child: Text(
                  paceStatusText.toUpperCase(),
                  style: AppTypography.microBadge(
                    fontSize: 10.0,
                    letterSpacing: 0.5,
                    color: paceStatusColor,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24, thickness: 1, color: Color(0xFFF4F4F5)),

          // Row 2: Clean 3-Column Plan Metrics
          Row(
            children: [
              Expanded(
                child: _planMetric(
                  label: 'DAILY GOAL',
                  value: '${plan.videosPerDay ?? 4}',
                  unit: 'vids/day',
                ),
              ),
              Container(width: 1.0, height: 26, color: const Color(0xFFE5E7EB)),
              Expanded(
                child: _planMetric(
                  label: 'DONE TODAY',
                  value: '$completedBatchCount/$totalBatchCount',
                  unit: 'completed',
                  highlightColor: completedBatchCount >= totalBatchCount && totalBatchCount > 0
                      ? const Color(0xFF059669)
                      : null,
                ),
              ),
              if (daysRemaining > 0) ...[
                Container(width: 1.0, height: 26, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: _planMetric(
                    label: 'TARGET',
                    value: '$daysRemaining',
                    unit: 'days left',
                  ),
                ),
              ],
            ],
          ),

          const Divider(height: 24, thickness: 1, color: Color(0xFFF4F4F5)),

          // Row 3: Subject / Unit Progress Bar & Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnitScope ? 'Unit Progress' : 'Subject Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground,
                ),
              ),
              Text(
                '$unitProgressPercent% ($completedInScope of $totalVideosInScope)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 7,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.parchmentSurface,
              borderRadius: BorderRadius.circular(3.5),
              border: Border.all(color: AppTheme.sketchBorderColor, width: 1.0),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: unitProgress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: meta?.accent ?? AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PART 2: The New Unit View
  Widget _buildUnitSection({
    required BuildContext context,
    required Subject targetSubject,
    required List<Chapter> targetChapters,
    required Chapter activeChapter,
    required int activeChapterIndex,
    required bool isUnitScope,
    required EditionState editionState,
  }) {
    final meta = subjectMeta(targetSubject.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 13,
                  decoration: BoxDecoration(
                    color: meta.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  isUnitScope
                      ? (targetChapters.length > 1
                          ? 'Target Units (${targetChapters.length})'
                          : 'Target Unit')
                      : 'Active Unit',
                  style: AppTheme.headingStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkForeground,
                  ),
                ),
              ],
            ),
            ApplePressable(
              pressedScale: 0.94,
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/curriculum/${targetSubject.id}');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'All Units',
                      style: AppTypography.compactAction(
                        fontSize: 11.5,
                        color: meta.accent,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: meta.accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Display UnitCard(s)
        if (isUnitScope) ...[
          for (int i = 0; i < targetChapters.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final chIdx = targetSubject.chapters.indexOf(targetChapters[i]);
                return UnitCard(
                  subject: targetSubject,
                  chapter: targetChapters[i],
                  unitIndex: chIdx >= 0 ? chIdx : i,
                  completedVideos: editionState.completedVideos,
                  completedQBanks: editionState.completedQBanks,
                  completedNotes: editionState.completedNotes,
                );
              },
            ),
          ],
        ] else ...[
          UnitCard(
            subject: targetSubject,
            chapter: activeChapter,
            unitIndex: activeChapterIndex,
            completedVideos: editionState.completedVideos,
            completedQBanks: editionState.completedQBanks,
            completedNotes: editionState.completedNotes,
          ),
        ],
      ],
    );
  }

  Widget _planMetric({
    required String label,
    required String value,
    required String unit,
    Color? highlightColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.metricLabel(
            fontSize: 9.0,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTypography.metricValue(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: highlightColor ?? AppTheme.inkForeground,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                unit,
                style: AppTypography.cardMeta(
                  fontSize: 9.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// PART 2: Today's Video Modules View
  Widget _buildModuleSection({
    required BuildContext context,
    required WidgetRef ref,
    required Subject? targetSubject,
    required String subjectName,
    required List<Video> batchVideos,
    required List<QBankTopic> planQBanks,
    required List<NotesItem> planNotes,
    required EditionState editionState,
    required List<String> staleIds,
    required bool isCurrentScopeFullyCompleted,
  }) {
    final completedVideosCount =
        batchVideos.where((v) => editionState.completedVideos.containsKey(v.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Counters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Modules",
              style: AppTheme.headingStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkForeground,
              ),
            ),
            Text(
              '$completedVideosCount of ${batchVideos.length} completed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Video Module Cards
        if (batchVideos.isNotEmpty) ...[
          for (int i = 0; i < batchVideos.length; i++)
            _buildVideoTaskTile(
              context: context,
              ref: ref,
              video: batchVideos[i],
              index: i,
              isDone: editionState.completedVideos.containsKey(batchVideos[i].id),
              isStale: staleIds.contains(batchVideos[i].id),
              targetSubject: targetSubject,
              subjectName: subjectName,
            ),
        ] else if (!isCurrentScopeFullyCompleted)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.sketchDecoration(
              backgroundColor: AppTheme.cardWhite,
              borderRadius: 14,
              shadowOffset: 2,
            ),
            child: Center(
              child: Text(
                'No video modules pending for today.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoTaskTile({
    required BuildContext context,
    required WidgetRef ref,
    required Video video,
    required int index,
    required bool isDone,
    required bool isStale,
    required Subject? targetSubject,
    required String subjectName,
  }) {
    final detail = video.durationLabel.isNotEmpty ? video.durationLabel : '${video.durationMins}m';
    final globalIndex = video.serialNumber > 0
        ? video.serialNumber
        : ((targetSubject?.allVideos.indexWhere((v) => v.id == video.id) ?? -1) + 1);
    final displayNum = globalIndex > 0 ? '$globalIndex' : '${index + 1}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ApplePressable(
        pressedScale: 0.98,
        onTap: () {
          HapticFeedback.selectionClick();
          if (isDone) {
            ref.read(appStateProvider.notifier).markVideoIncomplete(video.id);
          } else {
            ref.read(appStateProvider.notifier).markVideoComplete(video.id);
          }

          final deskTasks = ref.read(dailyTasksProvider).tasks;
          final matching = deskTasks.where((t) => t.id == 'vid_${video.id}').toList();
          if (matching.isNotEmpty) {
            final deskCompleted = ref.read(dailyTasksProvider).completedIds;
            final isDeskDone = deskCompleted.contains('vid_${video.id}');
            if (isDone && isDeskDone) {
              ref.read(dailyTasksProvider.notifier).toggleTask('vid_${video.id}');
            } else if (!isDone && !isDeskDone) {
              ref.read(dailyTasksProvider.notifier).toggleTask('vid_${video.id}');
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: AppTheme.sketchDecoration(
            backgroundColor: isDone ? AppTheme.parchmentSurface : AppTheme.cardWhite,
            borderRadius: 16,
            borderWidth: 1.2,
            shadowOffset: 2.0,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Sequential number badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green.withValues(alpha: 0.16)
                      : AppTheme.accentPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: isDone
                      ? Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    displayNum,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDone ? Colors.green.shade800 : AppTheme.accentPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedStrikeText(
                      text: video.title,
                      isStruck: isDone,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                      ),
                      strikeColor: AppTheme.mutedText,
                      strikeThickness: 1.8,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: AppTheme.mutedText,
                          ),
                        ),
                        if (isStale && !isDone) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFD97706), width: 0.9),
                            ),
                            child: const Text(
                              'Stale',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                        if (isDone) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• Completed',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Focus Timer Shortcut
              ApplePressable(
                pressedScale: 0.90,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(
                    '/timer',
                    extra: {
                      'subjectId': targetSubject?.id ?? video.subjectId,
                      'subjectName': targetSubject?.displayName ?? subjectName,
                      'topicId': video.id,
                      'topicTitle': video.title,
                      'chapterName': video.chapterName,
                      'topicType': 'video',
                      'durationMins': video.durationMins > 0 ? video.durationMins : 15,
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.timer_outlined,
                    size: 19,
                    color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Animated Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.accentPrimary : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(6.5),
                  border: Border.all(
                    color: isDone ? AppTheme.accentPrimary : AppTheme.sketchBorderColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: AnimatedCheckStroke(
                    checked: isDone,
                    size: 15,
                    color: AppTheme.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildQBankTaskTile({
    required BuildContext context,
    required WidgetRef ref,
    required QBankTopic qbank,
    required bool isDone,
    required Subject? targetSubject,
    required String subjectName,
  }) {
    const badgeColor = Color(0xFFF97316);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ApplePressable(
        pressedScale: 0.98,
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(appStateProvider.notifier).toggleQBankComplete(qbank.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: AppTheme.sketchDecoration(
            backgroundColor: isDone ? AppTheme.parchmentSurface : AppTheme.cardWhite,
            borderRadius: 16,
            borderWidth: 1.2,
            shadowOffset: 2.0,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Q-Bank Icon Badge (NO SERIAL NUMBER!)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green.withValues(alpha: 0.16)
                      : badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: isDone
                      ? Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.quiz_rounded,
                    size: 20,
                    color: isDone ? Colors.green.shade800 : badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedStrikeText(
                      text: qbank.title,
                      isStruck: isDone,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                      ),
                      strikeColor: AppTheme.mutedText,
                      strikeThickness: 1.8,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${qbank.totalMcqs} MCQs',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: AppTheme.mutedText,
                          ),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '• Completed',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Focus Timer Shortcut
              ApplePressable(
                pressedScale: 0.90,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(
                    '/timer',
                    extra: {
                      'subjectId': targetSubject?.id ?? qbank.subjectId,
                      'subjectName': targetSubject?.displayName ?? subjectName,
                      'topicId': qbank.id,
                      'topicTitle': qbank.title,
                      'chapterName': qbank.chapterName,
                      'topicType': 'qbank',
                      'durationMins': (qbank.totalMcqs * 1.5).round().clamp(10, 60),
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.timer_outlined,
                    size: 19,
                    color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Animated Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.accentPrimary : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(6.5),
                  border: Border.all(
                    color: isDone ? AppTheme.accentPrimary : AppTheme.sketchBorderColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: AnimatedCheckStroke(
                    checked: isDone,
                    size: 15,
                    color: AppTheme.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildNotesTaskTile({
    required BuildContext context,
    required WidgetRef ref,
    required NotesItem note,
    required bool isDone,
    required Subject? targetSubject,
    required String subjectName,
  }) {
    const badgeColor = Color(0xFF10B981);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ApplePressable(
        pressedScale: 0.98,
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(appStateProvider.notifier).toggleNotesComplete(note.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: AppTheme.sketchDecoration(
            backgroundColor: isDone ? AppTheme.parchmentSurface : AppTheme.cardWhite,
            borderRadius: 16,
            borderWidth: 1.2,
            shadowOffset: 2.0,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Notes Icon Badge (NO SERIAL NUMBER!)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green.withValues(alpha: 0.16)
                      : badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: isDone
                      ? Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 20,
                    color: isDone ? Colors.green.shade800 : badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedStrikeText(
                      text: note.title,
                      isStruck: isDone,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                      ),
                      strikeColor: AppTheme.mutedText,
                      strikeThickness: 1.8,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'High-Yield Notes',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: AppTheme.mutedText,
                          ),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '• Completed',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Focus Timer Shortcut
              ApplePressable(
                pressedScale: 0.90,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(
                    '/timer',
                    extra: {
                      'subjectId': targetSubject?.id ?? note.subjectId,
                      'subjectName': targetSubject?.displayName ?? subjectName,
                      'topicId': note.id,
                      'topicTitle': note.title,
                      'chapterName': note.chapterName,
                      'topicType': 'notes',
                      'durationMins': 20,
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.timer_outlined,
                    size: 19,
                    color: isDone ? AppTheme.mutedText : AppTheme.inkForeground,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Animated Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.accentPrimary : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(6.5),
                  border: Border.all(
                    color: isDone ? AppTheme.accentPrimary : AppTheme.sketchBorderColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: AnimatedCheckStroke(
                    checked: isDone,
                    size: 15,
                    color: AppTheme.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnconfiguredState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          key: TourTargetRegistry.keyFor(TourTargetId.moduleTasksScreenHeader),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: AppTheme.sketchDecoration(
            backgroundColor: AppTheme.cardWhite,
            borderRadius: 16,
            shadowOffset: 2,
            borderWidth: 1.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight, width: 1.4),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 30,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Study Plan Configured',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure your target subject, unit scope, and daily module goal in Setup to view your automated daily study queue.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push('/plan'),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Open Setup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.paperBackground,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard({
    required BuildContext context,
    required bool isUnitScope,
    required String unitName,
    required String subjectName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.current.isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.3)
            : const Color(0xFFF0FDF4),
        borderRadius: 16,
        shadowOffset: 2.5,
        borderWidth: 1.6,
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, size: 34, color: Color(0xFF059669)),
          const SizedBox(height: 10),
          Text(
            isUnitScope ? '$unitName is completed!' : 'All modules in $subjectName completed!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.inkForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isUnitScope
                ? 'Great progress! Select your next unit in Setup to continue your daily curriculum flow.'
                : 'Outstanding work doctor! Configure your next target subject in Setup to continue your daily curriculum flow.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.mutedText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => context.push('/plan'),
            icon: const Icon(Icons.tune_rounded, size: 15),
            label: const Text('Open Setup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: AppTheme.paperBackground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Rollover check: 2 stale + 2 fresh = 4 total capped at user quota
  Future<void> _checkAndRefreshDailyBatch({
    required WidgetRef ref,
    required EditionState editionState,
    required List<Video> planVideos,
    required int targetQuota,
    required String todayKey,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBatchDate = (prefs.getString('modulix_module_batch_date') ?? prefs.getString('flowmd_module_batch_date'));
      final currentBatchIds = editionState.queueBatchVideoIds;

      final planVideoIds = planVideos.map((v) => v.id).toSet();
      final bool isBatchValid = currentBatchIds.isNotEmpty &&
          currentBatchIds.every((id) => planVideoIds.contains(id)) &&
          currentBatchIds.length == targetQuota;

      if (savedBatchDate != todayKey) {
        // Day rollover! Uncompleted modules from yesterday become stale
        final uncompletedFromYesterday = currentBatchIds
            .where((id) => !editionState.completedVideos.containsKey(id) && planVideoIds.contains(id))
            .toList();

        final staleCount = uncompletedFromYesterday.length;
        final neededFresh = (targetQuota - staleCount).clamp(0, targetQuota);

        final freshCandidates = planVideos
            .where((v) =>
                !editionState.completedVideos.containsKey(v.id) &&
                !uncompletedFromYesterday.contains(v.id))
            .toList();

        final freshBatchIds = freshCandidates.take(neededFresh).map((v) => v.id).toList();
        final newBatch = [...uncompletedFromYesterday, ...freshBatchIds];

        await prefs.setString('modulix_module_batch_date', todayKey);
        await ref.read(appStateProvider.notifier).setBatch(newBatch, uncompletedFromYesterday);
      } else if (!isBatchValid) {
        // Same day but invalid batch (e.g. freshly configured or plan modified)
        final uncompleted = planVideos
            .where((v) => !editionState.completedVideos.containsKey(v.id))
            .toList();
        final newBatch = uncompleted.take(targetQuota).map((v) => v.id).toList();

        await prefs.setString('modulix_module_batch_date', todayKey);
        await ref.read(appStateProvider.notifier).setBatch(newBatch, []);
      }
    } catch (_) {}
  }
}
