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
import '../../widgets/loading/app_shimmer.dart';
import '../../widgets/feedback/modulix_toast.dart';

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
    ref.watch(appThemeDataProvider);
    final appStateAsync = ref.watch(appStateProvider);
    final syllabusAsync = ref.watch(activeSyllabusProvider);

    final appState = appStateAsync.value;
    final subjects = syllabusAsync.value ?? [];

    if (appState == null) {
      return Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const SafeArea(child: AnalyticsSkeletonView()),
      );
    }

    final edition = appState.currentEdition;
    final plan = edition.plan;
    final isDark = AppTheme.current.isDark;

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

    chapterStats.sort((a, b) {
      final bRemaining = ((b['total'] as num?)?.toInt() ?? 0) - ((b['done'] as num?)?.toInt() ?? 0);
      final aRemaining = ((a['total'] as num?)?.toInt() ?? 0) - ((a['done'] as num?)?.toInt() ?? 0);
      return bRemaining.compareTo(aRemaining);
    });

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
        titleSpacing: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Module Plan Progress',
            style: AppTheme.headingStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkForeground,
            ),
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
                  border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.5), width: 0.6),
                ),
                child: Text(
                  targetSub?.name ?? 'Plan',
                  style: AppTypography.compactAction(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ProgressRadialGauge(
                    progress: progress,
                    size: 88,
                    strokeWidth: 8,
                    progressColor: AppTheme.accentPrimary,
                    percentageStyle: AppTypography.metricValue(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
                          style: AppTypography.sectionMicroHeader(
                            fontSize: 10.0,
                            letterSpacing: 1.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedVideos of $totalVideos Videos Done',
                          style: AppTypography.cardTitle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${remainingHours.toStringAsFixed(1)} hours ($remainingVideos vids) remaining',
                          style: AppTypography.cardSubtitle(
                            fontSize: 12.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (eta != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: eta.isOnTrack
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              eta.isOnTrack ? 'On Track for Deadline' : 'Behind Scheduled Pace',
                              style: AppTypography.microBadge(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w700,
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
              style: AppTypography.sectionMicroHeader(
                fontSize: 10.5,
                letterSpacing: 1.1,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pace Slider',
                        style: AppTypography.cardTitle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppTheme.borderLight.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${_simulatorPace.round()} vids/day',
                          style: AppTypography.metricValue(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
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
                      inactiveTrackColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppTheme.borderLight,
                      thumbColor: isDark ? Colors.white : AppTheme.inkForeground,
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
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppTheme.borderLight.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 18, color: AppTheme.accentPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'At ${_simulatorPace.round()} vids/day: Finish in $simulatedDaysRemaining days (${DateFormat('d MMM yyyy').format(simulatedProjectedDate)})',
                            style: AppTypography.cardSubtitle(
                              fontSize: 12.0,
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
                          ModulixToast.showSuccess(
                            context,
                            message: 'Target pace set to ${_simulatorPace.round()} vids/day',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.inkForeground,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Update Active Plan Pace to ${_simulatorPace.round()} vids/day',
                            style: AppTypography.buttonLabel(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
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
                  style: AppTypography.sectionMicroHeader(
                    fontSize: 10.5,
                    letterSpacing: 1.1,
                    color: AppTheme.mutedText,
                  ),
                ),
                Text(
                  targetSub != null ? '${targetSub.chapters.length} units total' : '',
                  style: AppTypography.cardMeta(
                    fontSize: 10.5,
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
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppTheme.borderLight.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No units matching selected filter',
                  style: AppTypography.cardSubtitle(
                    fontSize: 12.0,
                    color: AppTheme.mutedText,
                  ),
                ),
              )
            else
              ...filteredChapters.map((ch) {
                final String name = ch['name']?.toString() ?? '';
                final int total = (ch['total'] as num?)?.toInt() ?? 0;
                final int done = (ch['done'] as num?)?.toInt() ?? 0;
                final double chPct = (ch['percent'] as num?)?.toDouble() ?? 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      width: 0.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                              style: AppTypography.cardTitle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: chPct >= 1.0
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$done/$total vids (${(chPct * 100).round()}%)',
                              style: AppTypography.metricValue(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: chPct >= 1.0
                                    ? const Color(0xFF10B981)
                                    : AppTheme.inkForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: chPct,
                          minHeight: 6,
                          backgroundColor: isDark
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
    final isDark = AppTheme.current.isDark;
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
          color: isSelected
              ? AppTheme.inkForeground
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.inkForeground
                : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight),
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.compactAction(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
          ),
        ),
      ),
    );
  }
}
