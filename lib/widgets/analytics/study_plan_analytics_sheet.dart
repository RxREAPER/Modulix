import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/app_state.dart';
import '../../models/syllabus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../services/metrics_service.dart';
import '../../theme/app_theme.dart';
import '../curriculum/configure_plan_sheet.dart';

class StudyPlanAnalyticsSheet extends ConsumerWidget {
  const StudyPlanAnalyticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const StudyPlanAnalyticsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final syllabusAsync = ref.watch(activeSyllabusProvider);

    final appState = appStateAsync.value;
    final subjects = syllabusAsync.value ?? [];

    if (appState == null) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppTheme.paperBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final edition = appState.currentEdition;
    final plan = edition.plan;

    Subject? targetSub;
    for (final s in subjects) {
      if (s.id == plan.targetSubject) {
        targetSub = s;
        break;
      }
    }

    int totalVideos = 0;
    int completedVideos = 0;
    double totalMins = 0;
    double completedMins = 0;

    final List<Map<String, dynamic>> chapterStats = [];

    if (targetSub != null) {
      for (final ch in targetSub.chapters) {
        int chTotal = ch.videos.length;
        int chDone = 0;
        for (final v in ch.videos) {
          totalVideos++;
          totalMins += v.totalMinutes;
          if (edition.completedVideos.containsKey(v.id)) {
            completedVideos++;
            completedMins += v.totalMinutes;
            chDone++;
          }
        }
        chapterStats.add({
          'name': ch.name,
          'total': chTotal,
          'done': chDone,
          'percent': chTotal > 0 ? (chDone / chTotal) : 0.0,
        });
      }
    }

    chapterStats.sort((a, b) => ((b['total'] as int) - (b['done'] as int))
        .compareTo((a['total'] as int) - (a['done'] as int)));

    final double progress = totalVideos > 0 ? completedVideos / totalVideos : 0.0;
    final int remainingVideos = totalVideos - completedVideos;
    final double remainingHours = (totalMins - completedMins) / 60;

    ETAResult? eta;
    double rollingVelocity = 0.0;
    int staleRate = 100;
    int staleDone = 0;
    final staleIds = List<String>.from(edition.staleBatchVideoIds);

    if (plan.isConfigured) {
      eta = MetricsService.calculateETA(
        remainingVideos,
        plan.videosPerDay ?? 4,
        plan.targetDate,
      );

      final now = DateTime.now();
      int last7DaysDone = 0;
      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: i));
        final k = DateFormat('yyyy-MM-dd').format(d);
        last7DaysDone += (edition.dailyHistory[k] as int?) ?? 0;
      }
      rollingVelocity = last7DaysDone / 7.0;

      staleDone = staleIds.where((id) => edition.completedVideos.containsKey(id)).length;
      if (staleIds.isNotEmpty) {
        staleRate = ((staleDone / staleIds.length) * 100).round();
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          left: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          right: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
                  ),
                  child: const Icon(Icons.track_changes_rounded,
                      color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MODULE PLAN ANALYTICS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        plan.isConfigured
                            ? (targetSub?.name ?? plan.targetSubject)
                            : 'No Plan Configured',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ConfigurePlanSheet.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.sketchBorderColor, width: 1.4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 14, color: AppTheme.inkForeground),
                        SizedBox(width: 4),
                        Text('Edit',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkForeground)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (!plan.isConfigured) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: 18,
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.event_note_rounded,
                            size: 48, color: AppTheme.mutedText),
                        const SizedBox(height: 12),
                        const Text(
                          'No Target Configured Yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Set your exam deadline, target subject, and daily video pace in Configure Study Plan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ConfigurePlanSheet.show(context);
                          },
                          icon: const Icon(Icons.add_task_rounded, size: 18),
                          label: const Text('Configure Now',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.inkForeground,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: 20,
                      shadowOffset: 4,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 82,
                              height: 82,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 9,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppTheme.primaryBlue),
                                  ),
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                      color: AppTheme.inkForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TARGET: ${DateFormat('d MMM yyyy').format(DateTime.tryParse(plan.targetDate) ?? DateTime.now())}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedVideos / $totalVideos',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.inkForeground,
                                    ),
                                  ),
                                  Text(
                                    'Videos completed · ${remainingHours.toStringAsFixed(1)}h remaining',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (eta != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: (eta.isOnTrack
                                      ? Colors.green
                                      : Colors.orange)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: eta.isOnTrack
                                    ? Colors.green
                                    : Colors.orange,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  eta.isOnTrack
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_amber_rounded,
                                  color: eta.isOnTrack
                                      ? Colors.green.shade700
                                      : Colors.orange.shade800,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    eta.isOnTrack
                                        ? 'On track to finish by ${DateFormat('d MMM yyyy').format(eta.finishDate)}'
                                        : 'Behind pace — need ${eta.videosPerDay} videos/day to hit target',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: eta.isOnTrack
                                          ? Colors.green.shade800
                                          : Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: AppTheme.sketchDecoration(
                            backgroundColor: Colors.white,
                            borderRadius: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DAILY TARGET',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.mutedText)),
                              const SizedBox(height: 4),
                              Text('${plan.videosPerDay ?? 5} vids',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.inkForeground)),
                              Text('${plan.dailyHours.toStringAsFixed(1)}h planned',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.mutedText)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: AppTheme.sketchDecoration(
                            backgroundColor: Colors.white,
                            borderRadius: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('REVISION CYCLES',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.mutedText)),
                              const SizedBox(height: 4),
                              Text('${plan.revisionCycles}x target',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.inkForeground)),
                              const Text('High-yield recall',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.mutedText)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: AppTheme.sketchDecoration(
                            backgroundColor: Colors.white,
                            borderRadius: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('7D VELOCITY',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.mutedText)),
                              const SizedBox(height: 4),
                              Text('${rollingVelocity.toStringAsFixed(1)} vids/d',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryBlue)),
                              Text('Target: ${plan.videosPerDay ?? 4}/day',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.mutedText)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: AppTheme.sketchDecoration(
                            backgroundColor: Colors.white,
                            borderRadius: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STALE CLEARANCE',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.mutedText)),
                              const SizedBox(height: 4),
                              Text('$staleRate%',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: staleRate >= 80 ? const Color(0xFF059669) : const Color(0xFFD97706))),
                              Text('$staleDone of ${staleIds.length} resolved',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.mutedText)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CHAPTER COMPLETION BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...chapterStats.map((ch) {
                    final int total = ch['total'] as int;
                    final int done = ch['done'] as int;
                    final double pct = ch['percent'] as double;
                    final bool isComplete = done == total && total > 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.borderLight, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ch['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isComplete
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: AppTheme.inkForeground,
                                  ),
                                ),
                              ),
                              Text(
                                '$done / $total',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  color: isComplete
                                      ? Colors.green
                                      : AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 5,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation(
                                isComplete
                                    ? Colors.green
                                    : AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
