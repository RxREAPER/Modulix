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

class ModuleTasksScreen extends ConsumerWidget {
  static String? _lastCheckedKey;
  const ModuleTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          style: TextStyle(
            color: AppTheme.inkForeground,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
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
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
        error: (err, _) => Center(
          child: Text('Error loading modules: $err'),
        ),
        data: (appState) {
          if (subjectsAsync.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
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

          // Collect all videos in plan scope
          List<Video> planVideos = [];
          if (targetSubject != null) {
            if (plan.targetUnits.isNotEmpty) {
              for (final unitName in plan.targetUnits) {
                final ch = targetSubject.chapters
                    .where((c) => c.name == unitName)
                    .firstOrNull;
                if (ch != null) {
                  planVideos.addAll(ch.videos);
                }
              }
            } else {
              planVideos = targetSubject.allVideos;
            }
          }

          final totalVideosInScope = planVideos.length;
          final completedInScope = planVideos
              .where((v) => editionState.completedVideos.containsKey(v.id))
              .length;
          final double overallProgress =
              totalVideosInScope > 0 ? (completedInScope / totalVideosInScope) : 0.0;
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
              totalVideosInScope > 0 && completedInScope == totalVideosInScope;

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
              cacheExtent: 450.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
              // PART 1: The New Top Banner
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
                totalVideosInScope: totalVideosInScope,
                completedBatchCount: completedBatchCount,
                totalBatchCount: batchVideos.length,
                paceStatusText: paceStatusText,
                paceStatusColor: paceStatusColor,
                daysRemaining: daysRemaining,
                isUnitScope: isUnitScope,
              ),

              const SizedBox(height: 12),

              // PART 2: Curriculum Deep-Link Text
              _buildCurriculumDeepLink(
                context: context,
                targetSubject: targetSubject,
                subjectName: subjectName,
                isUnitScope: isUnitScope,
                plan: plan,
                currentUnitName: isUnitScope
                    ? (plan.targetUnits.isNotEmpty ? plan.targetUnits.first : null)
                    : batchVideos.firstOrNull?.chapterName,
              ),

              const SizedBox(height: 16),

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

              // PART 3: Today's Modules Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Modules (${batchVideos.length})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '$completedBatchCount of ${batchVideos.length} completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Style A: Curriculum Timeline Modules
              if (batchVideos.isNotEmpty) ...[
                for (int i = 0; i < batchVideos.length; i++) ...[
                  if (i == 0 || batchVideos[i].chapterName != batchVideos[i - 1].chapterName)
                    _buildBlendedUnitHeader(
                      batchVideos[i].chapterName,
                      targetSubject != null
                          ? (targetSubject.chapters
                                  .indexWhere((c) => c.name == batchVideos[i].chapterName) +
                              1)
                          : null,
                    ),
                  _buildTimelineItem(
                    context: context,
                    ref: ref,
                    video: batchVideos[i],
                    isDone: editionState.completedVideos.containsKey(batchVideos[i].id),
                    isStale: staleIds.contains(batchVideos[i].id),
                    targetSubject: targetSubject,
                    subjectName: subjectName,
                  ),
                ],
              ] else if (!isCurrentScopeFullyCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 14,
                    shadowOffset: 2,
                  ),
                  child: Center(
                    child: Text(
                      'No modules pending for today.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.inkForeground,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUnitScope ? 'Unit: $selectedUnitDisplay' : 'Scope: $selectedUnitDisplay',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
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

  /// PART 2: Minimalist card linked directly to selected unit/subject in Curriculum
  Widget _buildCurriculumDeepLink({
    required BuildContext context,
    required Subject? targetSubject,
    required String subjectName,
    required bool isUnitScope,
    required StudyPlan plan,
    String? currentUnitName,
  }) {
    final meta = targetSubject != null ? subjectMeta(targetSubject.id) : null;

    int? targetUnitIndex;
    String resolvedUnitName = '';

    if (targetSubject != null && targetSubject.chapters.isNotEmpty) {
      final unitToFind = currentUnitName ??
          (plan.targetUnits.isNotEmpty ? plan.targetUnits.first : null);
      if (unitToFind != null && unitToFind.isNotEmpty) {
        final idx = targetSubject.chapters.indexWhere(
          (c) =>
              c.name.toLowerCase().trim() == unitToFind.toLowerCase().trim() ||
              c.name.toLowerCase().contains(unitToFind.toLowerCase()) ||
              unitToFind.toLowerCase().contains(c.name.toLowerCase()),
        );
        if (idx != -1) {
          targetUnitIndex = idx;
          resolvedUnitName = targetSubject.chapters[idx].name;
        }
      }
      if (targetUnitIndex == null && targetSubject.chapters.isNotEmpty) {
        targetUnitIndex = 0;
        resolvedUnitName = targetSubject.chapters[0].name;
      }
    }

    final String labelText = resolvedUnitName.isNotEmpty
        ? 'View all modules in $resolvedUnitName'
        : (isUnitScope && plan.targetUnits.isNotEmpty
            ? 'View all modules in ${plan.targetUnits.first}'
            : 'View all modules in $subjectName');

    return ApplePressable(
      onTap: () {
        if (targetSubject != null && targetUnitIndex != null) {
          context.go('/curriculum/${targetSubject.id}/$targetUnitIndex');
        } else if (targetSubject != null) {
          context.go('/curriculum/${targetSubject.id}');
        } else {
          context.go('/curriculum');
        }
      },
      pressedScale: 0.98,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: AppTheme.sketchDecoration(
          backgroundColor: AppTheme.cardWhite,
          borderRadius: 14,
          borderWidth: 1.2,
          shadowOffset: 2.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (meta?.accent ?? AppTheme.primaryBlue).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: SubjectSketchIcon(
                subjectId: targetSubject?.id ?? '',
                size: 20,
                color: meta?.accent ?? AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: meta?.accent ?? AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: meta?.accent ?? AppTheme.primaryBlue,
                ),
              ],
            ),
          ],
        ),
      ),
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
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: highlightColor ?? AppTheme.inkForeground,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBlendedUnitHeader(String unitName, int? unitNumber) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.parchmentSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderLight, width: 1),
            ),
            child: Text(
              unitNumber != null ? 'UNIT $unitNumber' : 'UNIT',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppTheme.inkForeground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              unitName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 1,
            color: AppTheme.parchmentBorder.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  /// PART 3: Minimalist Timeline Module Item with whole-syllabus numbering
  Widget _buildTimelineItem({
    required BuildContext context,
    required WidgetRef ref,
    required Video video,
    required bool isDone,
    required bool isStale,
    required Subject? targetSubject,
    required String subjectName,
  }) {
    final detail = video.durationLabel.isNotEmpty ? video.durationLabel : '${video.durationMins}m';

    // Global numbering assigned from the whole syllabus/subject
    final globalIndex = video.serialNumber > 0
        ? video.serialNumber
        : ((targetSubject?.allVideos.indexWhere((v) => v.id == video.id) ?? -1) + 1);
    final displayNum = globalIndex > 0 ? '$globalIndex' : '${video.serialNumber}';

    return CustomPaint(
      painter: _DottedLinePainter(
        color: AppTheme.sketchBorderColor.withValues(alpha: 0.35),
        centerX: 19.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Circular Number Bubble
          SizedBox(
            width: 38,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                    color: Colors.transparent,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? AppTheme.accentPrimary : AppTheme.cardWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? AppTheme.accentPrimary : AppTheme.sketchBorderColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDone
                                ? AppTheme.accentPrimary.withValues(alpha: 0.35)
                                : const Color(0x101C1C1C),
                            offset: const Offset(1, 1.5),
                            blurRadius: isDone ? 3 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: isDone
                            ? AnimatedCheckStroke(
                                checked: true,
                                size: 14,
                                color: AppTheme.onAccent,
                              )
                            : Text(
                                displayNum,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  color: AppTheme.inkForeground,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Minimalist Task Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ApplePressable(
                pressedScale: 0.98,
                onPressed: () {
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
                child: Container(
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: isDone ? AppTheme.parchmentSurface : AppTheme.cardWhite,
                    borderRadius: 14,
                    borderWidth: 1.2,
                    shadowOffset: 2.0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      // Custom Animated Checkbox
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
                      const SizedBox(width: 10),

                      // Topic Title & Meta Info
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

                      // Module-Mode Focus Timer Shortcut Icon
                      ApplePressable(
                        pressedScale: 0.90,
                        onPressed: () {
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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

class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double centerX;

  _DottedLinePainter({
    required this.color,
    this.centerX = 19.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double startY = 0;
    const dashLength = 4.0;
    const dashGap = 4.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(centerX, startY),
        Offset(centerX, startY + dashLength),
        paint,
      );
      startY += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.centerX != centerX;
}
