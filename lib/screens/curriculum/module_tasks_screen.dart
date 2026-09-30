import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_state.dart';
import '../../models/syllabus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/curriculum/configure_plan_sheet.dart';

class ModuleTasksScreen extends ConsumerWidget {
  const ModuleTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final subjectsAsync = ref.watch(activeSyllabusProvider);

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () => context.pop(),
        ),
        title: const Text(
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
            child: Container(
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
                  onTap: () => ConfigurePlanSheet.show(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 15,
                          color: AppTheme.inkForeground,
                        ),
                        SizedBox(width: 4),
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
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.2),
          child: Container(
            height: 1.2,
            color: AppTheme.parchmentBorder.withOpacity(0.7),
          ),
        ),
      ),
      body: appStateAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
        error: (err, _) => Center(
          child: Text('Error loading modules: $err'),
        ),
        data: (appState) {
          if (subjectsAsync.isLoading) {
            return const Center(
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
              planVideos = targetSubject.chapters
                  .where((c) => plan.targetUnits.contains(c.name))
                  .expand((c) => c.videos)
                  .toList();
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

          // Refresh batch if needed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndRefreshDailyBatch(
              ref: ref,
              editionState: editionState,
              planVideos: planVideos,
              targetQuota: targetQuota,
              todayKey: todayKey,
            );
          });

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
              daysRemaining = targetDt.difference(DateTime.now()).inDays.clamp(0, 9999);
            } catch (_) {}
          }

          return ListView(
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
                    style: const TextStyle(
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
                    backgroundColor: Colors.white,
                    borderRadius: 14,
                    shadowOffset: 2,
                  ),
                  child: Center(
                    child: Text(
                      'No modules pending for today.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
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
    return Container(
      width: double.infinity,
      decoration: AppTheme.sketchDecoration(
        backgroundColor: const Color(0xFFFBF9F3),
        borderRadius: 18,
        borderWidth: 1.8,
        shadowOffset: 3.5,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Selected Subject (Large Bold) & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.inkForeground,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Small text: Selected Unit underneath
                    Text(
                      isUnitScope ? 'Unit: $selectedUnitDisplay' : 'Scope: $selectedUnitDisplay',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: paceStatusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: paceStatusColor, width: 1.2),
                ),
                child: Text(
                  paceStatusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: paceStatusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 2: User Plan Details (Daily Goal, Done Today, Target)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.parchmentBorder, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _planMetric(
                    label: 'DAILY GOAL',
                    value: '${plan.videosPerDay ?? 4}',
                    unit: 'vids/day',
                  ),
                ),
                Container(width: 1.2, height: 28, color: AppTheme.parchmentBorder),
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
                  Container(width: 1.2, height: 28, color: AppTheme.parchmentBorder),
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
          ),

          const SizedBox(height: 14),

          // Row 3: Unit Progress Bar & Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnitScope ? 'Unit Progress' : 'Subject Progress',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A463F),
                ),
              ),
              Text(
                '$unitProgressPercent% ($completedInScope of $totalVideosInScope)',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: AppTheme.inkForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.sketchBorderColor, width: 1.1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: unitProgress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PART 2: Graphic stationery card linked directly to selected unit in Curriculum
  Widget _buildCurriculumDeepLink({
    required BuildContext context,
    required Subject? targetSubject,
    required String subjectName,
    required bool isUnitScope,
    required StudyPlan plan,
  }) {
    final linkLabel = isUnitScope
        ? 'Open "${plan.targetUnits.first}" in Curriculum'
        : 'Open $subjectName in Curriculum';

    final int? unitNumber = (targetSubject != null && isUnitScope)
        ? (targetSubject.chapters.indexWhere((c) => plan.targetUnits.contains(c.name)) + 1)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          if (targetSubject != null) {
            if (isUnitScope) {
              final idx = targetSubject.chapters
                  .indexWhere((c) => plan.targetUnits.contains(c.name));
              if (idx != -1) {
                context.push('/curriculum/${targetSubject.id}/$idx');
                return;
              }
            }
            context.push('/curriculum/${targetSubject.id}');
          } else {
            context.go('/curriculum');
          }
        },
        child: Container(
          width: double.infinity,
          decoration: AppTheme.sketchDecoration(
            backgroundColor: const Color(0xFFFBF9F3),
            borderRadius: 14,
            borderWidth: 1.6,
            shadowOffset: 2.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Graphic Bookmark / Stamp with icon & unit number badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
                    width: 1.3,
                  ),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.collections_bookmark_outlined,
                        size: 24,
                        color: AppTheme.primaryBlue,
                      ),
                      if (unitNumber != null && unitNumber > 0)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unitNumber',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CURRICULUM SYLLABUS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppTheme.primaryBlue.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subjectName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      linkLabel,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkForeground,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to jump into complete unit module list & notes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action Graphic Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.sketchBorderColor, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x15000000),
                      offset: Offset(0, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppTheme.inkForeground,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1EA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFD6D2C4), width: 1),
            ),
            child: Text(
              unitNumber != null ? 'UNIT $unitNumber' : 'UNIT',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF4A463F),
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
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: AppTheme.parchmentBorder.withOpacity(0.7),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// PART 3: Style A Curriculum Timeline Module Item with strictly preserved syllabus numbers
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
    // Strictly preserved syllabus module number
    final displayNum = video.serialNumber;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Continuous Dotted Line + Circular Number Bubble
          SizedBox(
            width: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DottedLinePainter(
                      color: AppTheme.sketchBorderColor.withOpacity(0.4),
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFF16A34A) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? const Color(0xFF16A34A) : AppTheme.sketchBorderColor,
                      width: 1.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x181C1C1C),
                        offset: Offset(1.5, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : Text(
                            '$displayNum',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppTheme.inkForeground,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Topic Box with Details, Checkbox and Focus Timer Shortcut
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFF6F6F5)
                      : const Color(0xFFFFF9E6), // curriculum warm yellow
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDone ? Colors.green.shade400 : AppTheme.sketchBorderColor,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x141C1C1C),
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (isDone) {
                          ref.read(appStateProvider.notifier).markVideoIncomplete(video.id);
                        } else {
                          ref.read(appStateProvider.notifier).markVideoComplete(video.id);
                        }

                        // Sync with daily tasks if matching
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
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF16A34A) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone ? const Color(0xFF16A34A) : AppTheme.sketchBorderColor,
                            width: 1.8,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Topic Title & Duration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDone ? Colors.grey.shade500 : AppTheme.inkForeground,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                detail,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              // "Stale" tag for carried over modules
                              if (isStale && !isDone) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Module-Mode Focus Timer Shortcut Icon
                    IconButton(
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      tooltip: 'Focus on this module',
                      color: AppTheme.inkForeground,
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
                    ),
                  ],
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: AppTheme.sketchDecoration(
            backgroundColor: Colors.white,
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
                  color: const Color(0xFFF3F1EA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6D2C4), width: 1.4),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 30,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
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
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ConfigurePlanSheet.show(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Open Setup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
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
        backgroundColor: const Color(0xFFF0FDF4),
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
            style: const TextStyle(
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
                : 'Outstanding work doctor! Configure your next subject or start a revision cycle.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => ConfigurePlanSheet.show(context),
            icon: const Icon(Icons.tune_rounded, size: 15),
            label: const Text('Open Setup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
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
      final savedBatchDate = prefs.getString('flowmd_module_batch_date');
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

        await prefs.setString('flowmd_module_batch_date', todayKey);
        await ref.read(appStateProvider.notifier).setBatch(newBatch, uncompletedFromYesterday);
      } else if (!isBatchValid) {
        // Same day but invalid batch (e.g. freshly configured or plan modified)
        final uncompleted = planVideos
            .where((v) => !editionState.completedVideos.containsKey(v.id))
            .toList();
        final newBatch = uncompleted.take(targetQuota).map((v) => v.id).toList();

        await prefs.setString('flowmd_module_batch_date', todayKey);
        await ref.read(appStateProvider.notifier).setBatch(newBatch, []);
      }
    } catch (_) {}
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
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
      oldDelegate.color != color;
}
