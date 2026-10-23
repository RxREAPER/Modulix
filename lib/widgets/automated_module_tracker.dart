import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/subjects_metadata.dart';
import '../models/app_state.dart';
import '../models/syllabus.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'package:animations/animations.dart';
import '../screens/curriculum/module_tasks_screen.dart';
import 'curriculum/subject_sketch_icon.dart';
import 'in_situ_hint_pill.dart';
import 'animations/apple_pressable.dart';


/// Clean Home Screen stationery banner that directly links to the full
/// dedicated Module Tasks Screen (/module-tasks) without cramping the Home layout.
class AutomatedModuleTracker extends ConsumerWidget {
  static String? _lastCheckedKey;
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

    // Schedule background persistence and rollover check only when needed
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
        // Section Header (clean, without redundant outer View Details button)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Module Based Tasks',
              style: AppTheme.headingStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkForeground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              !isConfigured
                  ? 'Tap to setup daily curriculum pace'
                  : isAllDone
                      ? 'All modules completed · Great pace today, Doctor'
                      : '$completedBatchCount of $totalBatchCount completed${uncompletedStaleCount > 0 ? ' · $uncompletedStaleCount stale' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: (isConfigured && isAllDone) ? FontWeight.w700 : FontWeight.w500,
                color: (isConfigured && isAllDone) ? const Color(0xFF059669) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 1.2,
          color: AppTheme.parchmentBorder.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 14),

        // UI Box below the divider
        if (!isConfigured)
          _buildEmptyModuleState(context)
        else
          _buildConfiguredModuleCard(
            context: context,
            subjectId: plan.targetSubject,
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
    return ApplePressable(
      pressedScale: 0.97,
      pressedOpacity: 0.93,
      hapticStyle: HapticStyle.light,
      onTap: () => context.push('/plan'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: AppTheme.sketchDecoration(
          backgroundColor: AppTheme.cardWhite,
          borderRadius: 18,
          shadowOffset: 3,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accentSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_graph_rounded,
                          size: 19,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calibrate Study Plan & Pace',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'First Study Session Setup',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight, width: 1.0),
                  ),
                  child: Text(
                    'STEP 1 OF 3',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22, thickness: 1, color: Color(0xFFF4F4F5)),
            Text(
              'Set your target exam date to activate automated daily video pacing and queue progression.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkForeground,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _quickFeaturePill(Icons.event_available_rounded, 'Exam Date'),
                const SizedBox(width: 6),
                _quickFeaturePill(Icons.speed_rounded, 'Daily Quota'),
                const SizedBox(width: 6),
                _quickFeaturePill(Icons.playlist_play_rounded, 'Auto Batches'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.inkForeground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 16, color: AppTheme.paperBackground),
                      const SizedBox(width: 8),
                      Text(
                        'Configure Study Plan',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.paperBackground,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: AppTheme.paperBackground),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _quickFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppTheme.parchmentSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.mutedText),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguredModuleCard({
    required BuildContext context,
    required String subjectId,
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

    final meta = subjectMeta(subjectId);
    final isAllDone = batchVideos.isNotEmpty && completedBatchCount >= batchVideos.length;

    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 360),
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: AppTheme.paperBackground,
      middleColor: AppTheme.cardWhite,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      openShape: const RoundedRectangleBorder(),
      openBuilder: (context, _) => const ModuleTasksScreen(),
      closedBuilder: (context, openContainer) {
        return ApplePressable(
          pressedScale: 0.97,
          pressedOpacity: 0.93,
          hapticStyle: HapticStyle.light,
          onTap: openContainer,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
          decoration: AppTheme.sketchDecoration(
            backgroundColor: AppTheme.cardWhite,
            borderRadius: 18,
            shadowOffset: 3.0,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Subject icon + Name/Unit on left, Pace badge on right (Day resets at style)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: meta.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: SubjectSketchIcon(
                            subjectId: subjectId,
                            color: meta.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subjectName,
                                style: AppTypography.cardTitle(fontSize: 16.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedUnitDisplay,
                                style: AppTypography.cardSubtitle(fontSize: 11.5),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: paceStatusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: paceStatusColor, width: 1.1),
                    ),
                    child: Text(
                      paceStatusText.toUpperCase(),
                      style: AppTypography.microBadge(
                        color: paceStatusColor,
                        fontSize: 10,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),

              Divider(
                  height: 24, thickness: 1, color: AppTheme.borderLight),

              if (uncompletedStaleCount > 0) ...[
                const InSituHintPill(
                  prefKey: 'hint_behind_pace_seen',
                  message: 'Tap Recalibrate to re-balance your daily video quota',
                  icon: Icons.tune_rounded,
                  margin: EdgeInsets.only(bottom: 12),
                ),
              ],

              // Progress Counters Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedBatchCount of ${batchVideos.length} done today',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkForeground,
                      letterSpacing: -0.1,
                    ),
                  ),
                  Text(
                    '$progressPercent% scope completed',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Tactile sketch progress bar
              Container(
                height: 7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(3.5),
                  border: Border.all(
                      color: AppTheme.sketchBorderColor, width: 1.0),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: todayProgressFraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: completedBatchCount >= targetQuota && targetQuota > 0
                          ? AppTheme.accentPrimary
                          : AppTheme.accentPrimary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Integrated Inner Queue Navigation Bar (The inner part of the card)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? AppTheme.accentSubtle
                      : AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAllDone
                        ? AppTheme.accentPrimary.withValues(alpha: 0.4)
                        : AppTheme.borderLight,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAllDone
                          ? Icons.check_circle_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 15,
                      color: isAllDone
                          ? AppTheme.accentPrimary
                          : AppTheme.accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAllDone
                            ? "All today's modules finished!"
                            : (nextVideo != null
                                ? 'Next: #${nextVideo.serialNumber} ${nextVideo.title}'
                                : 'Open task queue'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isAllDone
                              ? AppTheme.accentPrimary
                              : AppTheme.inkForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Queue',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            color: isAllDone
                                ? const Color(0xFF059669)
                                : AppTheme.primaryBlue,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: isAllDone
                              ? const Color(0xFF059669)
                              : AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
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
