import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

enum ConsistencyMetric {
  videos,
  qbanks,
  notes,
  focusTime,
  tasks,
}

/// A GitHub-style calendar consistency heatmap matrix showing study hours,
/// video count, and streak density across the NEET-PG preparation cycle.
class NeetConsistencyMatrix extends StatefulWidget {
  final Map<String, int>? dailyVideos;
  final Map<String, int>? dailyQBanks;
  final Map<String, int>? dailyNotes;
  final Map<String, int>? dailyFocusSecs;
  final Map<String, int>? dailyTasks;
  final Color? accentColor;
  final int weeksCount; // 12, 16, 26, or 52 weeks
  final ConsistencyMetric initialMetric;

  const NeetConsistencyMatrix({
    super.key,
    this.dailyVideos,
    this.dailyQBanks,
    this.dailyNotes,
    this.dailyFocusSecs,
    this.dailyTasks,
    this.accentColor,
    this.weeksCount = 14,
    this.initialMetric = ConsistencyMetric.videos,
  });

  @override
  State<NeetConsistencyMatrix> createState() => _NeetConsistencyMatrixState();
}

class _NeetConsistencyMatrixState extends State<NeetConsistencyMatrix> {
  late ConsistencyMetric _currentMetric;
  late int _selectedWeeksCount;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _currentMetric = widget.initialMetric;
    _selectedWeeksCount = widget.weeksCount;
    _scrollController = ScrollController();
    // Automatically scroll to the most recent week on the right
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant NeetConsistencyMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weeksCount != oldWidget.weeksCount) {
      setState(() {
        _selectedWeeksCount = widget.weeksCount;
      });
      _scrollToEnd();
    }
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
      case ConsistencyMetric.qbanks:
        return widget.dailyQBanks ?? const {};
      case ConsistencyMetric.notes:
        return widget.dailyNotes ?? const {};
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
      case ConsistencyMetric.qbanks:
        return '$value MCQ${value == 1 ? '' : 's'}';
      case ConsistencyMetric.notes:
        return '$value note${value == 1 ? '' : 's'}';
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
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
                        _metricIcon(_currentMetric),
                        size: 24,
                        color: accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _metricCategoryTitle(_currentMetric),
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
          ),
        );
      },
    );
  }

  IconData _metricIcon(ConsistencyMetric m) {
    switch (m) {
      case ConsistencyMetric.videos:
        return Icons.play_circle_outline_rounded;
      case ConsistencyMetric.qbanks:
        return Icons.quiz_outlined;
      case ConsistencyMetric.notes:
        return Icons.description_outlined;
      case ConsistencyMetric.focusTime:
        return Icons.timer_outlined;
      case ConsistencyMetric.tasks:
        return Icons.checklist_rounded;
    }
  }

  String _metricCategoryTitle(ConsistencyMetric m) {
    switch (m) {
      case ConsistencyMetric.videos:
        return 'Modules & Video Lessons';
      case ConsistencyMetric.qbanks:
        return 'Clinical Q-Bank MCQs';
      case ConsistencyMetric.notes:
        return 'High-Yield Clinical Notes';
      case ConsistencyMetric.focusTime:
        return 'Focus Timer Deep Work';
      case ConsistencyMetric.tasks:
        return 'Daily Desk Tasks';
    }
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

    // Compute strictly Monday-aligned calendar weeks
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Align current week start to Monday (weekday 1=Monday ... 7=Sunday)
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final startMonday = thisMonday.subtract(Duration(days: (_selectedWeeksCount - 1) * 7));

    final weeks = List.generate(_selectedWeeksCount, (w) {
      final weekStart = startMonday.add(Duration(days: w * 7));
      return List.generate(7, (d) => weekStart.add(Duration(days: d)));
    });

    final hasMultipleMetrics = (widget.dailyQBanks != null) ||
        (widget.dailyNotes != null) ||
        (widget.dailyFocusSecs != null) ||
        (widget.dailyTasks != null);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and Segmented Duration Capsule
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Study Matrix',
                style: AppTheme.headingStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _durationChip(14, '3M'),
                    _durationChip(26, '6M'),
                    _durationChip(52, '1Y'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '$_selectedWeeksCount-week cycle · Total: ${_formatMetricValue(totalValue)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasMultipleMetrics) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _metricChip(ConsistencyMetric.videos, 'Videos', Icons.play_lesson_rounded),
                  const SizedBox(width: 6),
                  if (widget.dailyQBanks != null) ...[
                    _metricChip(ConsistencyMetric.qbanks, 'Q-Banks', Icons.quiz_rounded),
                    const SizedBox(width: 6),
                  ],
                  if (widget.dailyNotes != null) ...[
                    _metricChip(ConsistencyMetric.notes, 'Notes', Icons.description_rounded),
                    const SizedBox(width: 6),
                  ],
                  if (widget.dailyFocusSecs != null) ...[
                    _metricChip(ConsistencyMetric.focusTime, 'Time', Icons.timer_rounded),
                    const SizedBox(width: 6),
                  ],
                  if (widget.dailyTasks != null) ...[
                    _metricChip(ConsistencyMetric.tasks, 'Tasks', Icons.checklist_rounded),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Scrollable Matrix Grid with Weekday Labels
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekday indicators column strictly matching cell rows 0 to 6
              Padding(
                padding: const EdgeInsets.only(top: 24.0, right: 6.0),
                child: Column(
                  children: [
                    _weekdayLabel('Mon', 19.0),
                    _weekdayLabel('Tue', 19.0),
                    _weekdayLabel('Wed', 19.0),
                    _weekdayLabel('Thu', 19.0),
                    _weekdayLabel('Fri', 19.0),
                    _weekdayLabel('Sat', 19.0),
                    _weekdayLabel('Sun', 19.0),
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
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Column(
                              children: week.map((day) {
                                final isFuture = day.isAfter(today);
                                final key = DateFormat('yyyy-MM-dd').format(day);
                                final count = isFuture ? 0 : (data[key] ?? 0);
                                final isToday = _isSameDay(day, today);
                                final cellColor = isFuture
                                    ? Colors.transparent
                                    : _getCellColor(count, maxCount, accent, isDark);

                                return Tooltip(
                                  message: isFuture
                                      ? ''
                                      : (count > 0
                                          ? '${_formatMetricValue(count)} on ${DateFormat('d MMM').format(day)}'
                                          : DateFormat('d MMM').format(day)),
                                  child: GestureDetector(
                                    onTap: isFuture
                                        ? null
                                        : () => _showDayDetails(context, day, count),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 2.0),
                                      width: 15.0,
                                      height: 15.0,
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        borderRadius: BorderRadius.circular(3.5),
                                        border: isToday
                                            ? Border.all(color: accent, width: 1.5)
                                            : (isFuture
                                                ? Border.all(
                                                    color: isDark
                                                        ? Colors.white.withValues(alpha: 0.03)
                                                        : Colors.black.withValues(alpha: 0.03),
                                                    width: 0.5,
                                                  )
                                                : null),
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

          if (_selectedWeeksCount > 14) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        'Slide horizontally to explore full $_selectedWeeksCount-week timeline',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

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

  Widget _weekdayLabel(String label, double height) {
    return SizedBox(
      height: height,
      width: 25.0,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground.withValues(alpha: 0.65),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _durationChip(int weeks, String label) {
    final isSelected = _selectedWeeksCount == weeks;
    final accent = widget.accentColor ?? AppTheme.accentPrimary;

    return ApplePressable(
      pressedScale: 0.94,
      onTap: () {
        if (_selectedWeeksCount != weeks) {
          setState(() {
            _selectedWeeksCount = weeks;
          });
          _scrollToEnd();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? accent : AppTheme.mutedText,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : AppTheme.parchmentSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.35)
                : AppTheme.borderLight.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? accent : AppTheme.mutedText),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    if (weeks.isEmpty) return labels;

    const columnWidth = 19.0;
    // Anchor week month attribution to Thursday (index 3) per ISO-8601 majority rule
    String currentMonth = DateFormat('MMM').format(weeks.first[3]);
    int weekSpanCount = 0;

    for (int i = 0; i < weeks.length; i++) {
      final m = DateFormat('MMM').format(weeks[i][3]);
      if (m == currentMonth) {
        weekSpanCount++;
      } else {
        final shouldShow = labels.isEmpty ? weekSpanCount >= 3 : weekSpanCount >= 2;
        labels.add(
          SizedBox(
            width: weekSpanCount * columnWidth,
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                shouldShow ? currentMonth : '',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground.withValues(alpha: 0.70),
                ),
              ),
            ),
          ),
        );
        currentMonth = m;
        weekSpanCount = 1;
      }
    }
    if (weekSpanCount > 0) {
      labels.add(
        SizedBox(
          width: weekSpanCount * columnWidth,
          height: 18,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              currentMonth,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkForeground.withValues(alpha: 0.70),
              ),
            ),
          ),
        ),
      );
    }
    return labels;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
