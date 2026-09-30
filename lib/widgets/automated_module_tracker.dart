import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';
import '../models/syllabus.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'curriculum/configure_plan_sheet.dart';

/// Clean Home Screen stationery banner that directly links to the full
/// dedicated Module Tasks Screen (/module-tasks) without cramping the Home layout.
class AutomatedModuleTracker extends ConsumerWidget {
  final EditionState editionState;
  final String editionName;
  final List<Subject> subjects;

  const AutomatedModuleTracker({
    super.key,
    required this.editionState,
    required this.editionName,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = editionState.plan;
    final isConfigured = plan.isConfigured;

    // Resolve target subject
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

    final totalVideos = planVideos.length;
    final completedVideosCount =
        planVideos.where((v) => editionState.completedVideos.containsKey(v.id)).length;
    final double overallProgress =
        totalVideos > 0 ? (completedVideosCount / totalVideos) : 0.0;
    final int progressPercent = (overallProgress * 100).round();

    // Day Window Calculation linked to start of the day setting
    final appState = ref.watch(appStateProvider).valueOrNull;
    final dayStartHour = appState?.dayStartHour ?? 5;
    final now = DateTime.now().subtract(Duration(hours: dayStartHour));
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final targetQuota = plan.videosPerDay ?? 4;

    // Daily batch determination with 2+2=4 quota capping & rollover
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

    // Schedule background persistence and rollover check
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

    // Selected Unit label
    final bool isUnitScope = plan.targetUnits.isNotEmpty;
    final String selectedUnitDisplay =
        isUnitScope ? plan.targetUnits.join(', ') : 'All Units';

    // Count of uncompleted stale tasks in today's batch
    final uncompletedStaleCount = batchVideos
        .where((v) => staleIds.contains(v.id) && !editionState.completedVideos.containsKey(v.id))
        .length;

    // Dynamic pace status
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

    final double todayProgressFraction =
        batchVideos.isNotEmpty ? (completedBatchCount / batchVideos.length) : 0.0;
    final totalBatchCount = batchVideos.length;
    final isAllDone = totalBatchCount > 0 && completedBatchCount == totalBatchCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row matching Today's tasks exactly
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Module Based Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !isConfigured
                        ? 'Tap to setup daily curriculum pace'
                        : isAllDone
                            ? 'All modules completed · Great pace today, Doctor'
                            : '$completedBatchCount of $totalBatchCount completed' +
                                (uncompletedStaleCount > 0 ? ' · $uncompletedStaleCount stale' : ''),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: (isConfigured && isAllDone) ? FontWeight.w700 : FontWeight.w500,
                      color: (isConfigured && isAllDone) ? const Color(0xFF059669) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
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
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (!isConfigured) {
                      ConfigurePlanSheet.show(context);
                    } else {
                      context.push('/module-tasks');
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppTheme.inkForeground,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 1.2,
          color: AppTheme.parchmentBorder.withOpacity(0.7),
        ),
        const SizedBox(height: 14),

        // UI Box below the divider
        if (!isConfigured)
          _buildEmptyModuleState(context)
        else
          _buildConfiguredModuleCard(
            context: context,
            subjectName: subjectName,
            selectedUnitDisplay: selectedUnitDisplay,
            completedBatchCount: completedBatchCount,
            batchVideos: batchVideos,
            uncompletedStaleCount: uncompletedStaleCount,
            paceStatusText: paceStatusText,
            paceStatusColor: paceStatusColor,
            todayProgressFraction: todayProgressFraction,
            targetQuota: targetQuota,
            progressPercent: progressPercent,
          ),
      ],
    );
  }

  Widget _buildEmptyModuleState(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          ConfigurePlanSheet.show(context);
        },
        child: Container(
          width: double.infinity,
          decoration: AppTheme.sketchDecoration(
            backgroundColor: Colors.white,
            borderRadius: 16,
            shadowOffset: 2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.parchmentBorder,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 22,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No active module plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkForeground,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Set up a daily curriculum pace to track your modules step by step.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ConfigurePlanSheet.show(context),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text(
                  'Set up module plan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguredModuleCard({
    required BuildContext context,
    required String subjectName,
    required String selectedUnitDisplay,
    required int completedBatchCount,
    required List<Video> batchVideos,
    required int uncompletedStaleCount,
    required String paceStatusText,
    required Color paceStatusColor,
    required double todayProgressFraction,
    required int targetQuota,
    required int progressPercent,
  }) {
    final nextVideo = batchVideos
        .where((v) => !editionState.completedVideos.containsKey(v.id))
        .firstOrNull;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/module-tasks');
        },
        child: Container(
          width: double.infinity,
          decoration: AppTheme.sketchDecoration(
            backgroundColor: Colors.white,
            borderRadius: 16,
            borderWidth: 1.5,
            shadowOffset: 3.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Subject + Unit, Pace Status Badge
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
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkForeground,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedUnitDisplay,
                          style: TextStyle(
                            fontSize: 12,
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: paceStatusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: paceStatusColor, width: 1),
                    ),
                    child: Text(
                      paceStatusText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: paceStatusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress Counters Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedBatchCount of ${batchVideos.length} done',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  Text(
                    '$progressPercent% unit scope done',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Tactile sketch progress bar
              Container(
                height: 7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F1EA),
                  borderRadius: BorderRadius.circular(3.5),
                  border: Border.all(color: AppTheme.sketchBorderColor, width: 1.1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: todayProgressFraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: completedBatchCount >= targetQuota && targetQuota > 0
                          ? const Color(0xFF059669)
                          : AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),

              if (nextVideo != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 14,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Up next: #${nextVideo.serialNumber} ${nextVideo.title}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
