import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/time_log_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/metrics_service.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

/// Focus To-Do inspired 24-Hour Timeline Grid (Chronotype Study Records).
/// Visually renders 24 vertical hourly bars showing exact study blocks
/// logged throughout the day (00:00 to 24:00) with interactive inspection.
class ChronotypeTimelineGrid extends ConsumerStatefulWidget {
  const ChronotypeTimelineGrid({super.key});

  @override
  ConsumerState<ChronotypeTimelineGrid> createState() =>
      _ChronotypeTimelineGridState();
}

class _ChronotypeTimelineGridState
    extends ConsumerState<ChronotypeTimelineGrid> {
  int? _selectedHour;

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(appThemeDataProvider);
    final ext = themeData.extension;
    final timeLogs = ref.watch(timeLogsProvider);
    final dayStartHour = ref.watch(
      appStateProvider.select((s) => s.valueOrNull?.dayStartHour ?? 5),
    );

    final todayStart = MetricsService.studyDayStart(dayStartHour);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final now = DateTime.now();
    final currentHour = now.hour;

    // Aggregate study minutes per hour of day (0..23)
    final Map<int, int> hourMinutes = {};
    final Map<int, List<String>> hourTopics = {};

    int todayTotalMinutes = 0;
    for (final log in timeLogs) {
      if (log.timestamp.isAfter(todayStart) &&
          log.timestamp.isBefore(todayEnd)) {
        final h = log.timestamp.hour;
        final mins = log.durationSecs ~/ 60;
        hourMinutes[h] = (hourMinutes[h] ?? 0) + mins;
        hourTopics.putIfAbsent(h, () => []).add(log.topicTitle);
        todayTotalMinutes += mins;
      }
    }

    final maxMinsInAnyHour = hourMinutes.values.fold<int>(
      60,
      (max, m) => m > max ? m : max,
    );

    final activeHoursCount = hourMinutes.values.where((m) => m > 0).length;

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
          // Header Row
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
                      Icons.view_timeline_rounded,
                      size: 16,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHRONOTYPE TIMELINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      Text(
                        '24-Hour Study Records',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  todayTotalMinutes > 0
                      ? '$activeHoursCount hrs (${todayTotalMinutes ~/ 60}h ${todayTotalMinutes % 60}m)'
                      : '0 active hrs',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 24-Hour Vertical Bar Chart
          SizedBox(
            height: 100,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = (constraints.maxWidth - (23 * 2.5)) / 24;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(24, (hour) {
                    final mins = hourMinutes[hour] ?? 0;
                    final isCurrent = hour == currentHour;
                    final isSelected = _selectedHour == hour;
                    final hasStudy = mins > 0;

                    final barHeight = hasStudy
                        ? ((mins / maxMinsInAnyHour) * 75).clamp(8.0, 75.0)
                        : 4.0;

                    final barColor = isSelected
                        ? AppTheme.accentPrimary
                        : (hasStudy
                            ? (isCurrent
                                ? AppTheme.accentPrimary
                                : ext.accent.withValues(alpha: 0.85))
                            : AppTheme.borderLight.withValues(alpha: 0.5));

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedHour = _selectedHour == hour ? null : hour;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            width: barWidth.clamp(6.0, 14.0),
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(3),
                              border: isCurrent
                                  ? Border.all(
                                      color: AppTheme.inkForeground,
                                      width: 1.0,
                                    )
                                  : null,
                              boxShadow: hasStudy
                                  ? [
                                      BoxShadow(
                                        color: barColor.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Hour marker (shown every 3 hours: 0, 3, 6, 9, 12, 15, 18, 21)
                          Text(
                            hour % 4 == 0 ? '$hour' : '',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                              color: isCurrent
                                  ? AppTheme.accentPrimary
                                  : AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Detail Inspection Box when an hour is tapped
          if (_selectedHour != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.parchmentSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.borderLight,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: AppTheme.accentPrimary),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedHour!.toString().padLeft(2, '0')}:00 – ${(_selectedHour! + 1).toString().padLeft(2, '0')}:00 :',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hourMinutes[_selectedHour!] != null && hourMinutes[_selectedHour!]! > 0
                        ? '${hourMinutes[_selectedHour!]} min focused'
                        : 'No focus logged',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hourMinutes[_selectedHour!] != null && hourMinutes[_selectedHour!]! > 0
                          ? AppTheme.accentPrimary
                          : AppTheme.mutedText,
                    ),
                  ),
                  const Spacer(),
                  ApplePressable(
                    onTap: () => setState(() => _selectedHour = null),
                    child: Icon(Icons.close_rounded, size: 14, color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Subtle legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '00:00 (Night)',
                  style: TextStyle(fontSize: 10, color: AppTheme.mutedText, fontWeight: FontWeight.w600),
                ),
                Text(
                  '12:00 (Noon)',
                  style: TextStyle(fontSize: 10, color: AppTheme.mutedText, fontWeight: FontWeight.w600),
                ),
                Text(
                  '23:00 (Late)',
                  style: TextStyle(fontSize: 10, color: AppTheme.mutedText, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
