import 'package:flutter/material.dart';
import 'analytics/neet_consistency_matrix.dart';

export 'analytics/neet_consistency_matrix.dart';

/// GitHub-style contribution heatmap calendar (powered by NeetConsistencyMatrix)
class HeatmapCalendar extends StatelessWidget {
  final Map<String, int> dailyHistory;
  final Color accentColor;
  final int weeksCount;

  const HeatmapCalendar({
    super.key,
    required this.dailyHistory,
    required this.accentColor,
    this.weeksCount = 15,
  });

  @override
  Widget build(BuildContext context) {
    return NeetConsistencyMatrix(
      dailyVideos: dailyHistory,
      accentColor: accentColor,
      weeksCount: weeksCount,
    );
  }
}
