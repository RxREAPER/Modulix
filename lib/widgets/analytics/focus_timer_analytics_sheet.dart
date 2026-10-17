import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/time_log.dart';
import '../../providers/time_log_provider.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import '../animations/page_entrance.dart';

class FocusTimerAnalyticsSheet extends ConsumerStatefulWidget {
  const FocusTimerAnalyticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 200),
        reverseDuration: Duration(milliseconds: 150),
      ),
      builder: (_) => const FocusTimerAnalyticsSheet(),
    );
  }

  @override
  ConsumerState<FocusTimerAnalyticsSheet> createState() => _FocusTimerAnalyticsSheetState();
}

String _formatDuration(int totalSecs) {
  final h = totalSecs ~/ 3600;
  final m = (totalSecs % 3600) ~/ 60;
  if (h > 0) {
    return '${h}h ${m}m';
  }
  return '${m}m';
}

class _FocusTimerAnalyticsSheetState extends ConsumerState<FocusTimerAnalyticsSheet> {
  int? _lastTouchedBarIndex;

  @override
  Widget build(BuildContext context) {
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
      int gSec = 0;

      for (final log in timeLogs) {
        if (DateFormat('yyyy-MM-dd').format(log.timestamp) == key) {
          switch (log.topicType) {
            case 'video':
              vSec += log.durationSecs;
              break;
            case 'qbank':
              qSec += log.durationSecs;
              break;
            case 'notes':
              nSec += log.durationSecs;
              break;
            default:
              gSec += log.durationSecs;
              break;
          }
        }
      }

      weekStats.add(_FocusDayStat(
        dateKey: key,
        dayName: dayName,
        totalSecs: vSec + qSec + nSec + gSec,
        videoSecs: vSec,
        qbankSecs: qSec,
        notesSecs: nSec,
        generalSecs: gSec,
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
      decoration: BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: AppTheme.accentSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accentPrimary, width: 1.5),
                  ),
                  child: Icon(Icons.timer_outlined,
                      color: AppTheme.accentPrimary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOCUS TIME ANALYTICS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.accentPrimary,
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

          Divider(height: 1, color: AppTheme.borderLight),

          Expanded(
            child: FadeSlideEntrance(
              durationMs: 180,
              slideY: 10.0,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                // Today's Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 20,
                    shadowOffset: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                            style: TextStyle(
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
                            style: TextStyle(
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
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
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
                              color: AppTheme.accentSubtle,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TOUCH FOR DETAILS',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppTheme.accentPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 155,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, animValue, _) {
                            return RepaintBoundary(
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
                                      color: AppTheme.accentPrimary.withValues(alpha: 0.4),
                                      strokeWidth: 1.4,
                                      dashArray: [5, 4],
                                      label: HorizontalLineLabel(
                                        show: true,
                                        alignment: Alignment.topRight,
                                        padding: const EdgeInsets.only(right: 4, bottom: 2),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.accentPrimary,
                                        ),
                                        labelResolver: (_) => '4h Goal',
                                      ),
                                    ),
                                  ],
                                ),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                                    if (barTouchResponse != null &&
                                        barTouchResponse.spot != null) {
                                      final touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                      if (touchedIndex != _lastTouchedBarIndex) {
                                        _lastTouchedBarIndex = touchedIndex;
                                        HapticFeedback.selectionClick();
                                      }
                                    } else {
                                      _lastTouchedBarIndex = null;
                                    }
                                  },
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
                                              text: '• Notes: ${_formatDuration(s.notesSecs)}${s.generalSecs > 0 ? '\n' : ''}',
                                              style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 9.5),
                                            ),
                                          if (s.generalSecs > 0)
                                            TextSpan(
                                              text: '• General: ${_formatDuration(s.generalSecs)}',
                                              style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 9.5),
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
                                              color: isToday ? AppTheme.accentPrimary : AppTheme.inkForeground,
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
                                      color: AppTheme.parchmentBorder.withValues(alpha: 0.5),
                                      strokeWidth: 1,
                                      dashArray: [4, 4],
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(weekStats.length, (idx) {
                                  final s = weekStats[idx];
                                  final isToday = s.dateKey == DateFormat('yyyy-MM-dd').format(now);
                                  final staggerStart = idx * 0.08;
                                  final barProgress = ((animValue - staggerStart) / 0.44).clamp(0.0, 1.0);
                                  final barTotal = s.totalHours * barProgress;
                                  final barVideo = s.videoHours * barProgress;
                                  final barQbank = s.qbankHours * barProgress;
                                  final barNotes = s.notesHours * barProgress;

                                  return BarChartGroupData(
                                    x: idx,
                                    barRods: [
                                      BarChartRodData(
                                        toY: barTotal,
                                        width: 18,
                                        borderRadius: BorderRadius.circular(5),
                                        rodStackItems: [
                                          BarChartRodStackItem(0, barVideo, AppTheme.accentPrimary),
                                          BarChartRodStackItem(barVideo, barVideo + barQbank, const Color(0xFFD97706)),
                                          BarChartRodStackItem(barVideo + barQbank, barVideo + barQbank + barNotes, const Color(0xFF059669)),
                                          BarChartRodStackItem(barVideo + barQbank + barNotes, barTotal, const Color(0xFFF59E0B)),
                                        ],
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: maxChartY,
                                          color: isToday
                                              ? AppTheme.accentPrimary.withValues(alpha: 0.06)
                                              : const Color(0xFFF3F1EA),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeOutCubic,
                            ),
                          );
                        },
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendItem('Video', AppTheme.accentPrimary),
                          const SizedBox(width: 8),
                          _legendItem('QBank', const Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          _legendItem('Notes', const Color(0xFF059669)),
                          const SizedBox(width: 8),
                          _legendItem('General', const Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          _legendTarget('4h Goal'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Breakdown by Topic Type
                Text(
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
                      color: AppTheme.accentPrimary,
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
                          backgroundColor: AppTheme.cardWhite,
                          borderRadius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LONGEST SESSION',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.mutedText)),
                            const SizedBox(height: 4),
                            Text(_formatDuration(longestSessionSecs),
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.inkForeground)),
                            Text('Continuous flow',
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
                          backgroundColor: AppTheme.cardWhite,
                          borderRadius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ALL-TIME FOCUS',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.mutedText)),
                            const SizedBox(height: 4),
                            Text(_formatDuration(totalSecs),
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.inkForeground)),
                            Text('${timeLogs.length} total sessions',
                                style: TextStyle(
                                    fontSize: 10, color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Focus Session History
                _buildSessionLogsSection(timeLogs),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  }

  static Widget _buildSessionLogsSection(List<TimeLog> logs) {
    final sortedLogs = List<TimeLog>.from(logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT FOCUS SESSION LOGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppTheme.inkForeground,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1EA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD6D2C4), width: 1),
              ),
              child: Text(
                '${sortedLogs.length} ${sortedLogs.length == 1 ? 'Session' : 'Sessions'}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A463F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sortedLogs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight, width: 1.2),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 28, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No focus sessions recorded yet',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete a focus session from your study desk to start logging.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedLogs.length > 25 ? 25 : sortedLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = sortedLogs[index];
              return _buildSessionLogCard(log);
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  static Widget _buildSessionLogCard(TimeLog log) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (log.topicType) {
      case 'video':
        typeColor = AppTheme.accentPrimary;
        typeIcon = Icons.play_arrow_rounded;
        typeLabel = 'VIDEO';
        break;
      case 'qbank':
        typeColor = const Color(0xFFD97706);
        typeIcon = Icons.quiz_outlined;
        typeLabel = 'Q-BANK';
        break;
      case 'notes':
        typeColor = const Color(0xFF059669);
        typeIcon = Icons.menu_book_outlined;
        typeLabel = 'NOTES';
        break;
      default:
        typeColor = const Color(0xFF6B7280);
        typeIcon = Icons.timer_outlined;
        typeLabel = 'DEEP WORK';
        break;
    }

    final formattedDate = DateFormat('MMM d, h:mm a').format(log.timestamp);
    final formattedDuration = _formatDuration(log.durationSecs);

    return ApplePressable(
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
        ),
        child: Row(
          children: [
            // Type Indicator Icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 14),
            ),
            const SizedBox(width: 10),

            // Title & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.topicTitle.isNotEmpty ? log.topicTitle : 'Focus Session',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: typeColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '• $formattedDate',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Duration Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1EA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
              ),
              child: Text(
                formattedDuration,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: AppTheme.inkForeground,
                ),
              ),
            ),
          ],
        ),
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
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedText)),
                Text(duration,
                    style: TextStyle(
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
          style: TextStyle(
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
            color: AppTheme.accentPrimary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.accentPrimary,
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
  final int generalSecs;

  const _FocusDayStat({
    required this.dateKey,
    required this.dayName,
    required this.totalSecs,
    required this.videoSecs,
    required this.qbankSecs,
    required this.notesSecs,
    this.generalSecs = 0,
  });

  double get totalHours => totalSecs / 3600.0;
  double get videoHours => videoSecs / 3600.0;
  double get qbankHours => qbankSecs / 3600.0;
  double get notesHours => notesSecs / 3600.0;
  double get generalHours => generalSecs / 3600.0;
}

