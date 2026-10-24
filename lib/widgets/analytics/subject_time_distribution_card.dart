import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/time_log_provider.dart';
import '../../theme/app_theme.dart';

/// Focus To-Do inspired Subject Time Distribution Breakdown.
/// Visualizes the percentage and hours spent across the 19 MBBS / NEET-PG subjects.
class SubjectTimeDistributionCard extends ConsumerWidget {
  const SubjectTimeDistributionCard({super.key});

  static const List<Color> _palette = [
    Color(0xFF2563EB), // Blue
    Color(0xFF0D9488), // Teal
    Color(0xFFD97706), // Amber
    Color(0xFF7C3AED), // Purple
    Color(0xFFDC2626), // Red
    Color(0xFF059669), // Green
    Color(0xFFDB2777), // Pink
    Color(0xFF4B5563), // Slate
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final timeLogs = ref.watch(timeLogsProvider);

    final Map<String, int> subjectSeconds = {};
    int grandTotalSecs = 0;

    for (final log in timeLogs) {
      final s = log.subjectId.trim().toLowerCase();
      final key = s.isEmpty || s == 'general' ? 'General' : log.subjectId;
      subjectSeconds[key] = (subjectSeconds[key] ?? 0) + log.durationSecs;
      grandTotalSecs += log.durationSecs;
    }

    final sortedEntries = subjectSeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(6).toList();

    return Container(
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.cardWhite,
        borderRadius: 16,
        shadowOffset: 3,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 16,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEDICAL SPECIALTIES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      Text(
                        'Subject Time Distribution',
                        style: AppTheme.headingStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                grandTotalSecs > 0 ? '${grandTotalSecs ~/ 3600}h total' : '0h total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (grandTotalSecs == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No study time logged yet. Start a focus session!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mutedText,
                  ),
                ),
              ),
            )
          else ...[
            // Segmented Distribution Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: topEntries.asMap().entries.map((item) {
                    final idx = item.key;
                    final entry = item.value;
                    final flex = ((entry.value / grandTotalSecs) * 100).round().clamp(1, 100);
                    final color = _palette[idx % _palette.length];
                    return Flexible(
                      flex: flex,
                      child: Container(
                        color: color,
                        margin: const EdgeInsets.only(right: 1.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Subject Legend Rows
            Column(
              children: topEntries.asMap().entries.map((item) {
                final idx = item.key;
                final entry = item.value;
                final color = _palette[idx % _palette.length];
                final pct = (entry.value / grandTotalSecs * 100).toStringAsFixed(1);
                final hours = entry.value ~/ 3600;
                final mins = (entry.value % 3600) ~/ 60;
                final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.5),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$pct%',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
