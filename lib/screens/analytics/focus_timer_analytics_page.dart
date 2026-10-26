import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/time_log_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/metrics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/analytics/concentric_donut_indicator.dart';
import '../../widgets/analytics/chronotype_timeline_grid.dart';
import '../../widgets/analytics/subject_time_distribution_card.dart';

class FocusTimerAnalyticsPage extends ConsumerStatefulWidget {
  const FocusTimerAnalyticsPage({super.key});

  @override
  ConsumerState<FocusTimerAnalyticsPage> createState() =>
      _FocusTimerAnalyticsPageState();
}

class _FocusTimerAnalyticsPageState
    extends ConsumerState<FocusTimerAnalyticsPage> {
  int _selectedDaysIndex = 0; // 0: 7 Days, 1: 30 Days, 2: All Time
  int? _touchedBarIndex;

  static String _formatDuration(int totalSecs) {
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeDataProvider);
    final timeLogs = ref.watch(timeLogsProvider);
    final isDark = AppTheme.current.isDark;
    final dayStartHour =
        ref.watch(appStateProvider.select((s) => s.valueOrNull?.dayStartHour ?? 5));

    final effectiveTodayStart = MetricsService.studyDayStart(dayStartHour);

    int todaySecs = 0;
    int totalSecs = 0;
    int videoSecs = 0;
    int qbankSecs = 0;
    int notesSecs = 0;

    for (final log in timeLogs) {
      totalSecs += log.durationSecs;
      if (log.timestamp.isAfter(effectiveTodayStart)) {
        todaySecs += log.durationSecs;
      }

      final lowerTitle = log.topicTitle.toLowerCase();
      final lowerType = log.topicType.toLowerCase();
      if (lowerType.contains('qbank') ||
          lowerTitle.contains('mcq') ||
          lowerTitle.contains('qbank')) {
        qbankSecs += log.durationSecs;
      } else if (lowerType.contains('note') ||
          lowerTitle.contains('note') ||
          lowerTitle.contains('read')) {
        notesSecs += log.durationSecs;
      } else {
        videoSecs += log.durationSecs;
      }
    }

    final int daysCount = switch (_selectedDaysIndex) {
      0 => 7,
      1 => 30,
      _ => 90,
    };

    // Calculate daily bars
    final now = DateTime.now();
    final List<Map<String, dynamic>> dailyData = [];

    for (int i = daysCount - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day, dayStartHour);
      final dayEnd = dayStart.add(const Duration(days: 1));

      int daySecs = 0;
      for (final log in timeLogs) {
        if (log.timestamp.isAfter(dayStart) && log.timestamp.isBefore(dayEnd)) {
          daySecs += log.durationSecs;
        }
      }

      dailyData.add({
        'label': DateFormat('E').format(date),
        'dateStr': DateFormat('d MMM').format(date),
        'hours': (daySecs / 3600.0),
        'secs': daySecs,
      });
    }

    final double maxHours = dailyData.fold<double>(
      4.0,
      (max, d) => (d['hours'] as double) > max ? (d['hours'] as double) : max,
    );

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
          'Focus & Deep Work',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
                  _formatDuration(todaySecs),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 100),
          children: [
            // ── 1. Hero Concentric Progress Card ───────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.0,
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
                  ConcentricDonutIndicator(
                    progress1: totalSecs > 0 ? (videoSecs / totalSecs) : 0.0,
                    progress2: totalSecs > 0 ? (qbankSecs / totalSecs) : 0.0,
                    progress3: totalSecs > 0 ? (notesSecs / totalSecs) : 0.0,
                    size: 88,
                    ringWidth: 6.0,
                    ringSpacing: 3.0,
                    color1: const Color(0xFF007AFF),
                    color2: const Color(0xFF10B981),
                    color3: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEEP WORK VOLUME',
                          style: AppTypography.sectionMicroHeader(
                            fontSize: 10.0,
                            letterSpacing: 1.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(totalSecs),
                          style: AppTypography.metricValue(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${timeLogs.length} logged sessions across all subjects',
                          style: AppTypography.cardSubtitle(
                            fontSize: 12.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _modeIndicator('Videos', const Color(0xFF007AFF)),
                            const SizedBox(width: 10),
                            _modeIndicator('Q-Bank', const Color(0xFF10B981)),
                            const SizedBox(width: 10),
                            _modeIndicator('Notes', const Color(0xFFF59E0B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Interactive Time Distribution Bar Chart ─────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STUDY DURATION',
                  style: AppTypography.sectionMicroHeader(
                    fontSize: 10.5,
                    letterSpacing: 1.1,
                    color: AppTheme.mutedText,
                  ),
                ),
                // Timeframe selector
                Row(
                  children: [
                    _timeframePill(0, '7D', isDark),
                    const SizedBox(width: 6),
                    _timeframePill(1, '30D', isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.0,
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
                        _selectedDaysIndex == 0
                            ? 'Past 7 Days Pacing'
                            : (_selectedDaysIndex == 1
                                ? 'Past 30 Days Pacing'
                                : 'All-Time Pacing'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Text(
                        'Goal: 4h / day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 170,
                    child: RepaintBoundary(
                      child: _selectedDaysIndex == 0
                          ? BarChart(
                              BarChartData(
                                maxY: (maxHours * 1.15).ceilToDouble(),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final item = dailyData[group.x.toInt()];
                                      return BarTooltipItem(
                                        '${item['dateStr']}\n${_formatDuration(item['secs'] as int)}',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      );
                                    },
                                  ),
                                  touchCallback: (event, response) {
                                    if (response?.spot != null &&
                                        event is! FlTapUpEvent &&
                                        event is! FlPanEndEvent) {
                                      setState(() {
                                        _touchedBarIndex =
                                            response!.spot!.touchedBarGroupIndex;
                                      });
                                    } else if (event is FlTapUpEvent ||
                                        event is FlPanEndEvent) {
                                      setState(() {
                                        _touchedBarIndex = null;
                                      });
                                    }
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      interval: 2,
                                      getTitlesWidget: (val, _) => Text(
                                        '${val.toInt()}h',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, _) {
                                        final idx = val.toInt();
                                        if (idx < 0 || idx >= dailyData.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            dailyData[idx]['label'] as String,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.mutedText,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 2,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: AppTheme.borderLight,
                                    strokeWidth: 0.8,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(dailyData.length, (i) {
                                  final h = dailyData[i]['hours'] as double;
                                  final isSelected = _touchedBarIndex == i;
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: h,
                                        width: 16,
                                        color: isSelected
                                            ? AppTheme.inkForeground
                                            : (h >= 4.0
                                                ? const Color(0xFF10B981)
                                                : AppTheme.accentPrimary),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: (dailyData.length - 1).toDouble(),
                                minY: 0,
                                maxY: (maxHours * 1.25).clamp(4.0, 24.0),
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final idx = spot.x.toInt();
                                        if (idx < 0 || idx >= dailyData.length) return null;
                                        final item = dailyData[idx];
                                        return LineTooltipItem(
                                          '${item['dateStr']}\n${_formatDuration(item['secs'] as int)}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                extraLinesData: ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(
                                      y: 4.0,
                                      color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                      strokeWidth: 1.2,
                                      dashArray: [5, 4],
                                      label: HorizontalLineLabel(
                                        show: true,
                                        alignment: Alignment.topRight,
                                        padding: const EdgeInsets.only(right: 6, bottom: 2),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF10B981),
                                        ),
                                        labelResolver: (_) => 'Goal 4h',
                                      ),
                                    ),
                                  ],
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      interval: 2,
                                      getTitlesWidget: (val, _) => Text(
                                        '${val.toInt()}h',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: _selectedDaysIndex == 1 ? 5 : 15,
                                      getTitlesWidget: (val, _) {
                                        final idx = val.toInt();
                                        if (idx < 0 || idx >= dailyData.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            dailyData[idx]['dateStr'] as String,
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.mutedText,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 2,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: AppTheme.borderLight,
                                    strokeWidth: 0.8,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(
                                      dailyData.length,
                                      (i) => FlSpot(i.toDouble(), dailyData[i]['hours'] as double),
                                    ),
                                    isCurved: true,
                                    curveSmoothness: 0.28,
                                    preventCurveOverShooting: true,
                                    color: AppTheme.accentPrimary,
                                    barWidth: 2.6,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.accentPrimary.withValues(alpha: 0.28),
                                          AppTheme.accentPrimary.withValues(alpha: 0.02),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. Chronotype 24H Timeline Grid ────────────────────────────
            const ChronotypeTimelineGrid(),

            const SizedBox(height: 20),

            // ── 4. MBBS Subject Time Distribution ──────────────────────────
            const SubjectTimeDistributionCard(),

            const SizedBox(height: 20),

            // ── 4. Recent Focus Sessions Log ───────────────────────────────
            Text(
              'RECENT SESSIONS (${timeLogs.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 8),

            if (timeLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No sessions logged yet. Start the focus timer to track deep work.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedText,
                  ),
                ),
              )
            else
              ...timeLogs.reversed.take(15).map((log) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : AppTheme.inkForeground).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.topicTitle.isNotEmpty
                                  ? log.topicTitle
                                  : (log.chapterName.isNotEmpty
                                      ? log.chapterName
                                      : 'Focus Session'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('d MMM, h:mm a').format(log.timestamp)}${log.chapterName.isNotEmpty ? ' · ${log.chapterName}' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _formatDuration(log.durationSecs),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: Color(0xFF10B981),
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

  Widget _modeIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.cardMeta(
            fontSize: 10.5,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _timeframePill(int index, String label, bool isDark) {
    final isSelected = _selectedDaysIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDaysIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : AppTheme.inkForeground)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.compactAction(
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : AppTheme.mutedText,
          ),
        ),
      ),
    );
  }
}
