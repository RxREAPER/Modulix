import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// GitHub-style contribution heatmap calendar
class HeatmapCalendar extends StatelessWidget {
  final Map<String, int> dailyHistory;
  final Color accentColor;

  const HeatmapCalendar({
    super.key,
    required this.dailyHistory,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxCount =
        dailyHistory.values.fold(0, (a, b) => a > b ? a : b);

    // Build 15 weeks × 7 days grid (105 days)
    final today = DateTime.now();
    final days = List.generate(105, (i) {
      return today.subtract(Duration(days: 104 - i));
    });

    // Group by week
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month labels
            Row(
              children: _buildMonthLabels(weeks, context),
            ),
            const SizedBox(height: 6),
            // Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weeks.map((week) {
                return Expanded(
                  child: Column(
                    children: week.map((day) {
                      final key = DateFormat('yyyy-MM-dd').format(day);
                      final count = dailyHistory[key] ?? 0;
                      final opacity = maxCount == 0
                          ? 0.0
                          : (count / maxCount).clamp(0.1, 1.0);
                      final isToday = _isSameDay(day, today);

                      return Tooltip(
                        message: count > 0
                            ? '$count video${count > 1 ? 's' : ''} on ${DateFormat('d MMM').format(day)}'
                            : DateFormat('d MMM').format(day),
                        child: Container(
                          margin: const EdgeInsets.all(1.5),
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: count == 0
                                ? (isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.06))
                                : accentColor.withOpacity(opacity),
                            borderRadius: BorderRadius.circular(3),
                            border: isToday
                                ? Border.all(color: accentColor, width: 1.5)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Less',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4))),
                const SizedBox(width: 4),
                ...List.generate(5, (i) {
                  final opacity = 0.1 + i * 0.2;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.06))
                          : accentColor.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text('More',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMonthLabels(
      List<List<DateTime>> weeks, BuildContext context) {
    final labels = <Widget>[];
    String? lastMonth;

    for (final week in weeks) {
      final month = DateFormat('MMM').format(week.first);
      if (month != lastMonth) {
        labels.add(Expanded(
          child: Text(month,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4),
              )),
        ));
        lastMonth = month;
      } else {
        labels.add(const Expanded(child: SizedBox.shrink()));
      }
    }
    return labels;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
