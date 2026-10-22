import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/syllabus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../services/metrics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/analytics/progress_radial_gauge.dart';
import '../../widgets/analytics/pacing_velocity_chart.dart';

class StudyPlanAnalyticsPage extends ConsumerStatefulWidget {
  const StudyPlanAnalyticsPage({super.key});

  @override
  ConsumerState<StudyPlanAnalyticsPage> createState() =>
      _StudyPlanAnalyticsPageState();
}

class _StudyPlanAnalyticsPageState
    extends ConsumerState<StudyPlanAnalyticsPage> {
  int _selectedFilterIndex = 0; // 0: All, 1: In Progress, 2: Completed, 3: Pending
  double _simulatorPace = 4.0;
  bool _simulatorInitialized = false;

  @override
  Widget build(BuildContext context) {
    final appStateAsync = ref.watch(appStateProvider);
    final syllabusAsync = ref.watch(activeSyllabusProvider);

    final appState = appStateAsync.value;
    final subjects = syllabusAsync.value ?? [];

    if (appState == null) {
      return Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final edition = appState.currentEdition;
    final plan = edition.plan;

    if (!_simulatorInitialized && plan.videosPerDay != null) {
      _simulatorPace = plan.videosPerDay!.toDouble().clamp(1.0, 12.0);
      _simulatorInitialized = true;
    }

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
        if (plan.targetUnits.isNotEmpty &&
            !plan.targetUnits.contains(ch.name)) {
          continue;
        }
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

    final double progress =
        totalVideos > 0 ? completedVideos / totalVideos : 0.0;
    final int remainingVideos = totalVideos - completedVideos;
    final double remainingHours = (totalMins - completedMins) / 60;

    ETAResult? eta;
    if (plan.isConfigured) {
      final now = DateTime.now();
      eta = MetricsService.calculateETA(
        remainingVideos,
        plan.videosPerDay ?? 4,
        plan.targetDate,
        now: now,
      );
    }

    // Filter chapters
    final filteredChapters = chapterStats.where((ch) {
      final pct = ch['percent'] as double;
      switch (_selectedFilterIndex) {
        case 1:
          return pct > 0.0 && pct < 1.0; // In Progress
        case 2:
          return pct >= 1.0; // Completed
        case 3:
          return pct == 0.0; // Pending
        default:
          return true; // All
      }
    }).toList();

    // Projected completion with simulator
    final int simulatedDaysRemaining = _simulatorPace > 0
        ? (remainingVideos / _simulatorPace).ceil()
        : 999;
    final simulatedProjectedDate =
        DateTime.now().add(Duration(days: simulatedDaysRemaining));

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/analytics');
            }
          },
        ),
        title: Text(
          'Study Plan Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.inkForeground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentPrimary, width: 1.2),
                ),
                child: Text(
                  targetSub?.name ?? 'Plan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeSlideEntrance(
        durationMs: 180,
        slideY: 12.0,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── 1. Hero Radial Progress Card ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.sketchDecoration(
                backgroundColor: AppTheme.cardWhite,
                borderRadius: 22,
                shadowOffset: 4,
              ),
              child: Row(
                children: [
                  ProgressRadialGauge(
                    progress: progress,
                    size: 88,
                    strokeWidth: 8,
                    progressColor: AppTheme.accentPrimary,
                    percentageStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.isConfigured ? 'SYLLABUS PROGRESS' : 'PLAN INACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedVideos of $totalVideos Videos Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${remainingHours.toStringAsFixed(1)} hours ($remainingVideos vids) remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (eta != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: eta.isOnTrack
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              eta.isOnTrack ? 'On Track for Deadline' : 'Behind Scheduled Pace',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: eta.isOnTrack
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Pacing Velocity & Trajectory Chart ──────────────────────
            PacingVelocityChart(
              totalModules: totalVideos,
              completedModules: completedVideos,
              dailyHistory: edition.dailyHistory,
              dailyQuota: plan.videosPerDay?.toDouble() ?? 4.0,
              targetDateStr: plan.targetDate,
            ),

            const SizedBox(height: 20),

            // ── 3. Interactive What-If Velocity Simulator ──────────────────
            Text(
              'WHAT-IF VELOCITY SIMULATOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.sketchDecoration(
                backgroundColor: AppTheme.cardWhite,
                borderRadius: 20,
                shadowOffset: 3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pace Slider',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.parchmentSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderLight, width: 1),
                        ),
                        child: Text(
                          '${_simulatorPace.round()} vids/day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.accentPrimary,
                      inactiveTrackColor: AppTheme.borderLight,
                      thumbColor: AppTheme.inkForeground,
                      trackHeight: 4,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    ),
                    child: Slider(
                      value: _simulatorPace,
                      min: 1.0,
                      max: 12.0,
                      divisions: 11,
                      onChanged: (val) {
                        setState(() {
                          _simulatorPace = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 18, color: AppTheme.accentPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'At ${_simulatorPace.round()} vids/day: Finish in $simulatedDaysRemaining days (${DateFormat('d MMM yyyy').format(simulatedProjectedDate)})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plan.isConfigured && _simulatorPace.round() != plan.videosPerDay) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ApplePressable(
                        onTap: () {
                          ref.read(appStateProvider.notifier).updatePlan(
                                plan.copyWith(
                                  videosPerDay: _simulatorPace.round(),
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Target pace set to ${_simulatorPace.round()} vids/day'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.inkForeground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Update Active Plan Pace to ${_simulatorPace.round()} vids/day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.paperBackground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. Unit & Chapter Matrix with Filter Tabs ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UNIT BREAKDOWN (${filteredChapters.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.mutedText,
                  ),
                ),
                Text(
                  targetSub != null ? '${targetSub.chapters.length} units total' : '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _filterChip(0, 'All'),
                  _filterChip(1, 'In Progress'),
                  _filterChip(2, 'Completed'),
                  _filterChip(3, 'Pending'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Chapter list
            if (filteredChapters.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.sketchDecoration(
                  backgroundColor: AppTheme.cardWhite,
                  borderRadius: 18,
                ),
                alignment: Alignment.center,
                child: Text(
                  'No units matching selected filter',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedText,
                  ),
                ),
              )
            else
              ...filteredChapters.map((ch) {
                final String name = ch['name'] as String;
                final int total = ch['total'] as int;
                final int done = ch['done'] as int;
                final double chPct = ch['percent'] as double;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 18,
                    shadowOffset: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ),
                          Text(
                            '$done/$total vids (${(chPct * 100).round()}%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: chPct >= 1.0
                                  ? const Color(0xFF10B981)
                                  : AppTheme.inkForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: chPct,
                          minHeight: 5,
                          backgroundColor: AppTheme.current.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.borderLight,
                          valueColor: AlwaysStoppedAnimation(
                            chPct >= 1.0
                                ? const Color(0xFF10B981)
                                : AppTheme.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.inkForeground : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.inkForeground : AppTheme.borderLight,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
          ),
        ),
      ),
    );
  }
}
