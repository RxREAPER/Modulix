import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/time_log.dart';
import '../../providers/time_log_provider.dart';
import '../../theme/app_theme.dart';

class FocusTimerAnalyticsSheet extends ConsumerWidget {
  const FocusTimerAnalyticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const FocusTimerAnalyticsSheet(),
    );
  }

  static String _formatDuration(int totalSecs) {
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLogs = ref.watch(timeLogsProvider);

    // Compute today's logs (using 5 AM day boundary)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 5);
    final effectiveTodayStart = now.hour < 5
        ? todayStart.subtract(const Duration(days: 1))
        : todayStart;

    int todaySecs = 0;
    int totalSecs = 0;
    int videoSecs = 0;
    int qbankSecs = 0;
    int notesSecs = 0;
    int otherSecs = 0;
    int longestSessionSecs = 0;

    // Prepare 7-day detailed stats with breakdown for animated fl_chart
    final List<_FocusDayStat> weekStats = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final dayName = DateFormat('E').format(day);

      int vSec = 0;
      int qSec = 0;
      int nSec = 0;

      for (final log in timeLogs) {
        if (DateFormat('yyyy-MM-dd').format(log.timestamp) == key) {
          switch (log.topicType) {
            case 'video':
              vSec += log.durationSecs;
              break;
            case 'qbank':
              qSec += log.durationSecs;
              break;
            default:
              nSec += log.durationSecs;
              break;
          }
        }
      }

      weekStats.add(_FocusDayStat(
        dateKey: key,
        dayName: dayName,
        totalSecs: vSec + qSec + nSec,
        videoSecs: vSec,
        qbankSecs: qSec,
        notesSecs: nSec,
      ));
    }

    for (final log in timeLogs) {
      totalSecs += log.durationSecs;
      if (log.durationSecs > longestSessionSecs) {
        longestSessionSecs = log.durationSecs;
      }
      if (log.timestamp.isAfter(effectiveTodayStart)) {
        todaySecs += log.durationSecs;
      }
      switch (log.topicType) {
        case 'video':
          videoSecs += log.durationSecs;
          break;
        case 'qbank':
          qbankSecs += log.durationSecs;
          break;
        case 'notes':
          notesSecs += log.durationSecs;
          break;
        default:
          otherSecs += log.durationSecs;
          break;
      }
    }

    final double highestHours = weekStats
        .map((s) => s.totalHours)
        .fold(0.0, (a, b) => a > b ? a : b);
    final double maxChartY = ((highestHours > 4.5 ? highestHours * 1.25 : 5.0).ceilToDouble());

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
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange, width: 1.5),
                  ),
                  child: const Icon(Icons.timer_outlined,
                      color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOCUS TIME ANALYTICS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Pomodoro & Deep Work',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
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
                // Today's Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 20,
                    shadowOffset: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TODAY\'S FOCUS TIME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatDuration(todaySecs),
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: AppTheme.inkForeground,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '· ${timeLogs.where((l) => l.timestamp.isAfter(effectiveTodayStart)).length} sessions',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 7-Day Interactive & Animated Bar Chart
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'INTERACTIVE STUDY HOURS (7 DAYS)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TOUCH FOR DETAILS',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 155,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxChartY,
                            minY: 0,
                            groupsSpace: 12,
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: 4.0,
                                  color: AppTheme.primaryBlue.withOpacity(0.4),
                                  strokeWidth: 1.4,
                                  dashArray: [5, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    labelResolver: (_) => '4h Goal',
                                  ),
                                ),
                              ],
                            ),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => AppTheme.inkForeground,
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final s = weekStats[group.x.toInt()];
                                  final isToday = s.dateKey == DateFormat('yyyy-MM-dd').format(now);
                                  return BarTooltipItem(
                                    '${s.dayName}${isToday ? ' (Today)' : ''}\n',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Total: ${_formatDuration(s.totalSecs)}\n',
                                        style: const TextStyle(
                                          color: Color(0xFFFFD1D6),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                      if (s.videoSecs > 0)
                                        TextSpan(
                                          text: '• Video: ${_formatDuration(s.videoSecs)}\n',
                                          style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 9.5),
                                        ),
                                      if (s.qbankSecs > 0)
                                        TextSpan(
                                          text: '• QBank: ${_formatDuration(s.qbankSecs)}\n',
                                          style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 9.5),
                                        ),
                                      if (s.notesSecs > 0)
                                        TextSpan(
                                          text: '• Notes: ${_formatDuration(s.notesSecs)}',
                                          style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 9.5),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26,
                                  interval: 2,
                                  getTitlesWidget: (val, _) {
                                    if (val == 0) return const SizedBox.shrink();
                                    return Text(
                                      '${val.toInt()}h',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'monospace',
                                        color: Colors.grey.shade500,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, _) {
                                    final idx = val.toInt();
                                    if (idx < 0 || idx >= weekStats.length) return const SizedBox.shrink();
                                    final s = weekStats[idx];
                                    final isToday = s.dateKey == DateFormat('yyyy-MM-dd').format(now);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        s.dayName[0],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                                          color: isToday ? AppTheme.primaryBlue : AppTheme.inkForeground,
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
                              getDrawingHorizontalLine: (val) {
                                return FlLine(
                                  color: AppTheme.parchmentBorder.withOpacity(0.5),
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                );
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(weekStats.length, (idx) {
                              final s = weekStats[idx];
                              final isToday = s.dateKey == DateFormat('yyyy-MM-dd').format(now);

                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: s.totalHours,
                                    width: 18,
                                    borderRadius: BorderRadius.circular(5),
                                    rodStackItems: [
                                      BarChartRodStackItem(0, s.videoHours, AppTheme.primaryBlue),
                                      BarChartRodStackItem(s.videoHours, s.videoHours + s.qbankHours, const Color(0xFFD97706)),
                                      BarChartRodStackItem(s.videoHours + s.qbankHours, s.totalHours, const Color(0xFF059669)),
                                    ],
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: maxChartY,
                                      color: isToday
                                          ? AppTheme.primaryBlue.withOpacity(0.06)
                                          : const Color(0xFFF3F1EA),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 650),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendItem('Video', AppTheme.primaryBlue),
                          const SizedBox(width: 10),
                          _legendItem('QBank', const Color(0xFFD97706)),
                          const SizedBox(width: 10),
                          _legendItem('Notes', const Color(0xFF059669)),
                          const SizedBox(width: 10),
                          _legendTarget('4h Goal'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Breakdown by Topic Type
                const Text(
                  'FOCUS DISTRIBUTION BY TYPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _typePill(
                      icon: Icons.play_arrow_rounded,
                      label: 'Videos',
                      duration: _formatDuration(videoSecs),
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    _typePill(
                      icon: Icons.quiz_outlined,
                      label: 'Q-Bank',
                      duration: _formatDuration(qbankSecs),
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _typePill(
                      icon: Icons.menu_book_outlined,
                      label: 'Notes',
                      duration: _formatDuration(notesSecs),
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    _typePill(
                      icon: Icons.timer_outlined,
                      label: 'General',
                      duration: _formatDuration(otherSecs),
                      color: Colors.amber.shade800,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Longest & Total Summary
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
                            const Text('LONGEST SESSION',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.mutedText)),
                            const SizedBox(height: 4),
                            Text(_formatDuration(longestSessionSecs),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.inkForeground)),
                            const Text('Continuous flow',
                                style: TextStyle(
                                    fontSize: 10, color: AppTheme.mutedText)),
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
                            const Text('ALL-TIME FOCUS',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.mutedText)),
                            const SizedBox(height: 4),
                            Text(_formatDuration(totalSecs),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.inkForeground)),
                            Text('${timeLogs.length} total sessions',
                                style: const TextStyle(
                                    fontSize: 10, color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _typePill({
    required IconData icon,
    required String label,
    required String duration,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedText)),
                Text(duration,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: AppTheme.inkForeground)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }

  static Widget _legendTarget(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
}

class _FocusDayStat {
  final String dateKey;
  final String dayName;
  final int totalSecs;
  final int videoSecs;
  final int qbankSecs;
  final int notesSecs;

  const _FocusDayStat({
    required this.dateKey,
    required this.dayName,
    required this.totalSecs,
    required this.videoSecs,
    required this.qbankSecs,
    required this.notesSecs,
  });

  double get totalHours => totalSecs / 3600.0;
  double get videoHours => videoSecs / 3600.0;
  double get qbankHours => qbankSecs / 3600.0;
  double get notesHours => notesSecs / 3600.0;
}

