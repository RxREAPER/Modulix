import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';
import '../models/syllabus.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'package:animations/animations.dart';
import '../screens/curriculum/module_tasks_screen.dart';
import 'curriculum/subject_sketch_icon.dart';
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

    final double todayProgressFraction =
        batchVideos.isNotEmpty ? (completedBatchCount / batchVideos.length) : 0.0;
    final totalBatchCount = batchVideos.length;
    final isAllDone = totalBatchCount > 0 && completedBatchCount == totalBatchCount;

    if (!isConfigured) {
      return _buildEmptyModuleState(context);
    }

    return _buildConfiguredModuleCard(
      context: context,
      subjectId: plan.targetSubject,
      subjectName: subjectName,
      selectedUnitDisplay: selectedUnitDisplay,
      completedBatchCount: completedBatchCount,
      totalBatchCount: totalBatchCount,
      isAllDone: isAllDone,
      uncompletedStaleCount: uncompletedStaleCount,
      batchVideos: batchVideos,
      todayProgressFraction: todayProgressFraction,
    );
  }

  Widget _buildEmptyModuleState(BuildContext context) {
    final isDark = AppTheme.current.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ApplePressable(
          pressedScale: 0.98,
          pressedOpacity: 0.94,
          hapticStyle: HapticStyle.light,
          onTap: () => context.push('/plan'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.70),
                width: 0.75,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unified Component Header: Title & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Module Based Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkForeground,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                          width: 0.75,
                        ),
                      ),
                      child: Text(
                        'Pacing inactive',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0),
                          width: 0.75,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_graph_rounded,
                          size: 20,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calibrate Study Plan & Pace',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to setup daily curriculum pace',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : AppTheme.inkForeground,
                    borderRadius: BorderRadius.circular(12),
                    border: isDark
                        ? Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.75)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: isDark ? Colors.white : AppTheme.paperBackground,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Configure Study Plan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.paperBackground,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: isDark ? Colors.white : AppTheme.paperBackground,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguredModuleCard({
    required BuildContext context,
    required String subjectId,
    required String subjectName,
    required String selectedUnitDisplay,
    required int completedBatchCount,
    required int totalBatchCount,
    required bool isAllDone,
    required int uncompletedStaleCount,
    required List<Video> batchVideos,
    required double todayProgressFraction,
  }) {
    final isDark = AppTheme.current.isDark;
    final nextVideo = batchVideos
        .where((v) => !editionState.completedVideos.containsKey(v.id))
        .firstOrNull;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: OpenContainer(
          transitionType: ContainerTransitionType.fadeThrough,
          transitionDuration: const Duration(milliseconds: 360),
          closedElevation: 0,
          openElevation: 0,
          closedColor: Colors.transparent,
          openColor: AppTheme.paperBackground,
          middleColor: isDark ? const Color(0xFF0F172A) : AppTheme.cardWhite,
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          openShape: const RoundedRectangleBorder(),
          openBuilder: (context, _) => const ModuleTasksScreen(),
          closedBuilder: (context, openContainer) {
            return ApplePressable(
              pressedScale: 0.98,
              pressedOpacity: 0.94,
              hapticStyle: HapticStyle.light,
              onTap: openContainer,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.50)
                      : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.70),
                    width: 0.75,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Unified Component Header: Title & Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Module Based Tasks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkForeground,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isAllDone
                                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAllDone
                                  ? (isDark ? const Color(0xFF059669) : const Color(0xFF10B981))
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                              width: 0.75,
                            ),
                          ),
                          child: Text(
                            isAllDone
                                ? 'All done'
                                : '$completedBatchCount of $totalBatchCount today',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isAllDone
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Interactive Subject Deck Hero Row: Icon + Subject & Unit + Radial Ring
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                              width: 0.75,
                            ),
                          ),
                          child: Center(
                            child: SubjectSketchIcon(
                              subjectId: subjectId,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF0F172A),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subjectName,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
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
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.mutedText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sleek Segmented Circular Progress Ring
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: todayProgressFraction.clamp(0.0, 1.0),
                                strokeWidth: 3.5,
                                strokeCap: StrokeCap.round,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isAllDone
                                      ? const Color(0xFF10B981)
                                      : AppTheme.accentPrimary,
                                ),
                              ),
                              Text(
                                '${(todayProgressFraction * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Continuous Monochromatic Track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.5),
                      child: Container(
                        height: 4.5,
                        width: double.infinity,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: todayProgressFraction.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isAllDone
                                    ? const [Color(0xFF34D399), Color(0xFF059669)]
                                    : [AppTheme.accentEmerald, AppTheme.accentPrimary],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Fully Visible Next Lesson Tile & Action
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.75,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isAllDone
                                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                isAllDone
                                    ? Icons.check_rounded
                                    : Icons.play_arrow_rounded,
                                size: 18,
                                color: isAllDone
                                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                    : AppTheme.accentPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isAllDone ? 'MODULES COMPLETE' : 'UP NEXT',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  isAllDone
                                      ? "All scheduled videos completed for today!"
                                      : (nextVideo != null
                                          ? '#${nextVideo.serialNumber} ${nextVideo.title}'
                                          : 'Open task queue'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.inkForeground,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppTheme.inkForeground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Queue',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFF8FAFC) : Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: isDark ? const Color(0xFFF8FAFC) : Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
