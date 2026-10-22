import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

enum ConsistencyMetric {
  videos,
  focusTime,
  tasks,
}

/// A GitHub-style calendar consistency heatmap matrix showing study hours,
/// video count, and streak density across the NEET-PG preparation cycle.
class NeetConsistencyMatrix extends StatefulWidget {
  final Map<String, int>? dailyVideos;
  final Map<String, int>? dailyFocusSecs;
  final Map<String, int>? dailyTasks;
  final Color? accentColor;
  final int weeksCount; // 12, 16, 26, or 52 weeks
  final ConsistencyMetric initialMetric;

  const NeetConsistencyMatrix({
    super.key,
    this.dailyVideos,
    this.dailyFocusSecs,
    this.dailyTasks,
    this.accentColor,
    this.weeksCount = 52,
    this.initialMetric = ConsistencyMetric.videos,
  });

  @override
  State<NeetConsistencyMatrix> createState() => _NeetConsistencyMatrixState();
}

class _NeetConsistencyMatrixState extends State<NeetConsistencyMatrix> {
  late ConsistencyMetric _currentMetric;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _currentMetric = widget.initialMetric;
    _scrollController = ScrollController();
    // Automatically scroll to the most recent week on the right
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, int> get _activeData {
    switch (_currentMetric) {
      case ConsistencyMetric.videos:
        return widget.dailyVideos ?? const {};
      case ConsistencyMetric.focusTime:
        return widget.dailyFocusSecs ?? const {};
      case ConsistencyMetric.tasks:
        return widget.dailyTasks ?? const {};
    }
  }

  String _formatMetricValue(int value) {
    switch (_currentMetric) {
      case ConsistencyMetric.videos:
        return '$value video${value == 1 ? '' : 's'}';
      case ConsistencyMetric.focusTime:
        final h = value ~/ 3600;
        final m = (value % 3600) ~/ 60;
        if (h > 0) return '${h}h ${m}m';
        return '${m}m';
      case ConsistencyMetric.tasks:
        return '$value task${value == 1 ? '' : 's'}';
    }
  }

  Color _getCellColor(int value, int maxValue, Color accent, bool isDark) {
    if (value <= 0 || maxValue <= 0) {
      return isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);
    }
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    if (ratio < 0.25) return accent.withValues(alpha: 0.25);
    if (ratio < 0.50) return accent.withValues(alpha: 0.48);
    if (ratio < 0.75) return accent.withValues(alpha: 0.72);
    return accent;
  }

  void _showDayDetails(BuildContext context, DateTime day, int value) {
    HapticFeedback.selectionClick();
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(day);
    final ink = AppTheme.inkForeground;
    final secondary = AppTheme.mutedText;
    final accent = widget.accentColor ?? AppTheme.accentPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Daily Prep Consistency Snapshot',
                        style: TextStyle(fontSize: 11.5, color: secondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: value > 0 ? accent.withValues(alpha: 0.12) : AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: value > 0 ? accent : AppTheme.borderLight),
                    ),
                    child: Text(
                      value > 0 ? 'Active' : 'Rest Day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: value > 0 ? accent : secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentMetric == ConsistencyMetric.videos
                          ? Icons.play_circle_outline_rounded
                          : _currentMetric == ConsistencyMetric.focusTime
                              ? Icons.timer_outlined
                              : Icons.checklist_rounded,
                      size: 24,
                      color: accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentMetric == ConsistencyMetric.videos
                                ? 'Modules & Videos'
                                : _currentMetric == ConsistencyMetric.focusTime
                                    ? 'Focus Timer Deep Work'
                                    : 'Daily Desk Tasks',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value > 0 ? _formatMetricValue(value) : 'None recorded',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor ?? AppTheme.accentPrimary;
    final ink = AppTheme.inkForeground;
    final secondary = AppTheme.mutedText;

    final data = _activeData;
    final maxCount = data.values.fold(0, (a, b) => a > b ? a : b);
    final totalValue = data.values.fold<int>(0, (a, b) => a + b);

    // Build weeksCount * 7 days
    final totalDays = widget.weeksCount * 7;
    final today = DateTime.now();
    final days = List.generate(totalDays, (i) {
      return today.subtract(Duration(days: totalDays - 1 - i));
    });

    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }

    final hasMultipleMetrics = (widget.dailyFocusSecs != null) || (widget.dailyTasks != null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.cardWhite,
        borderRadius: 18,
        shadowOffset: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title and Multi-Metric Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEET-PG Consistency Matrix',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.weeksCount}-week cycle · Total: ${_formatMetricValue(totalValue)}',
                      style: TextStyle(fontSize: 11, color: secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasMultipleMetrics)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _metricChip(ConsistencyMetric.videos, 'Videos', Icons.play_lesson_rounded),
                    const SizedBox(width: 4),
                    if (widget.dailyFocusSecs != null)
                      _metricChip(ConsistencyMetric.focusTime, 'Time', Icons.timer_rounded),
                    const SizedBox(width: 4),
                    if (widget.dailyTasks != null)
                      _metricChip(ConsistencyMetric.tasks, 'Tasks', Icons.checklist_rounded),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Scrollable Matrix Grid with Weekday Labels
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekday indicators column (M, W, F)
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _weekdayLabel('M'),
                    const SizedBox(height: 15),
                    _weekdayLabel('W'),
                    const SizedBox(height: 15),
                    _weekdayLabel('F'),
                  ],
                ),
              ),

              // Horizontal Scrollable Matrix Grid
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month labels row
                      Row(
                        children: _buildMonthLabels(weeks),
                      ),
                      const SizedBox(height: 6),

                      // Day cell columns
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: weeks.map((week) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: Column(
                              children: week.map((day) {
                                final key = DateFormat('yyyy-MM-dd').format(day);
                                final count = data[key] ?? 0;
                                final isToday = _isSameDay(day, today);
                                final cellColor = _getCellColor(count, maxCount, accent, isDark);

                                return Tooltip(
                                  message: count > 0
                                      ? '${_formatMetricValue(count)} on ${DateFormat('d MMM').format(day)}'
                                      : DateFormat('d MMM').format(day),
                                  child: GestureDetector(
                                    onTap: () => _showDayDetails(context, day, count),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 1.5),
                                      width: 12.5,
                                      height: 12.5,
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        borderRadius: BorderRadius.circular(3),
                                        border: isToday
                                            ? Border.all(color: ink, width: 1.5)
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Legend Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tap any square to inspect day',
                style: TextStyle(fontSize: 10, color: secondary),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Less', style: TextStyle(fontSize: 10, color: secondary)),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) {
                    final color = i == 0
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05))
                        : accent.withValues(alpha: 0.25 * i);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text('More', style: TextStyle(fontSize: 10, color: secondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weekdayLabel(String label) {
    return SizedBox(
      height: 12.5,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _metricChip(ConsistencyMetric metric, String label, IconData icon) {
    final isSelected = _currentMetric == metric;
    final accent = widget.accentColor ?? AppTheme.accentPrimary;

    return ApplePressable(
      pressedScale: 0.94,
      onTap: () {
        setState(() => _currentMetric = metric);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.12) : AppTheme.parchmentSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accent : AppTheme.borderLight,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: isSelected ? accent : AppTheme.mutedText),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? accent : AppTheme.inkForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMonthLabels(List<List<DateTime>> weeks) {
    final labels = <Widget>[];
    String? lastMonth;

    for (final week in weeks) {
      final month = DateFormat('MMM').format(week.first);
      if (month != lastMonth) {
        labels.add(
          SizedBox(
            width: 15.5,
            child: Text(
              month,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedText,
              ),
            ),
          ),
        );
        lastMonth = month;
      } else {
        labels.add(const SizedBox(width: 15.5));
      }
    }
    return labels;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
