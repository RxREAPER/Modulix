import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A 24-hour horizontal chronotype heat strip visualizing peak study intensity
/// across 4 medical day-parts (Night 0-6, Morning 6-12, Afternoon 12-18, Evening 18-24).
class ChronotypeHeatStrip extends StatelessWidget {
  final Map<int, int> hourMinutes; // hour (0..23) -> minutes studied
  final Color? activeColor;

  const ChronotypeHeatStrip({
    super.key,
    required this.hourMinutes,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? AppTheme.accentPrimary;
    final maxMins = hourMinutes.values.fold<int>(0, (a, b) => a > b ? a : b);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Aggregate by 4 clinical circadian dayparts
    int nightMins = 0; // 00:00 - 06:00
    int morningMins = 0; // 06:00 - 12:00
    int afternoonMins = 0; // 12:00 - 18:00
    int eveningMins = 0; // 18:00 - 24:00

    for (int h = 0; h < 24; h++) {
      final mins = hourMinutes[h] ?? 0;
      if (h < 6) {
        nightMins += mins;
      } else if (h < 12) {
        morningMins += mins;
      } else if (h < 18) {
        afternoonMins += mins;
      } else {
        eveningMins += mins;
      }
    }

    final peakHour = _getPeakHour();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CHRONOTYPE INTENSITY (24H)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppTheme.mutedText,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Peak: ${_getPeakHourLabel(peakHour)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: effectiveColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dual-encoded 24-hour histogram: variable height + color intensity
        SizedBox(
          height: 36,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (hour) {
              final mins = hourMinutes[hour] ?? 0;
              final intensity = maxMins > 0 ? (mins / maxMins).clamp(0.0, 1.0) : 0.0;
              final isPeak = hour == peakHour && mins > 0;

              // Height encoding: empty is 5px, peak expands up to 28px
              final barHeight = intensity == 0.0 ? 5.0 : (6.0 + (22.0 * intensity));

              Color barColor;
              if (intensity == 0.0) {
                barColor = isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.borderLight;
              } else {
                barColor = effectiveColor.withValues(alpha: 0.35 + (0.65 * intensity));
              }

              return Expanded(
                child: Tooltip(
                  message: '${_formatHour(hour)}: ${mins}m studied',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isPeak)
                          Container(
                            width: 3,
                            height: 3,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: effectiveColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(3),
                            border: isPeak
                                ? Border.all(color: effectiveColor, width: 1.0)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _timeLabel('12 AM'),
            _timeLabel('6 AM'),
            _timeLabel('12 PM'),
            _timeLabel('6 PM'),
            _timeLabel('11 PM'),
          ],
        ),
        const SizedBox(height: 14),

        // Circadian Daypart Breakdown
        Row(
          children: [
            Expanded(child: _daypartCard('Night', '00-06', nightMins, Icons.bedtime_outlined, effectiveColor)),
            const SizedBox(width: 6),
            Expanded(child: _daypartCard('Morning', '06-12', morningMins, Icons.wb_sunny_outlined, effectiveColor)),
            const SizedBox(width: 6),
            Expanded(child: _daypartCard('Afternoon', '12-18', afternoonMins, Icons.wb_twilight_outlined, effectiveColor)),
            const SizedBox(width: 6),
            Expanded(child: _daypartCard('Evening', '18-24', eveningMins, Icons.nights_stay_outlined, effectiveColor)),
          ],
        ),
      ],
    );
  }

  Widget _daypartCard(String name, String hours, int mins, IconData icon, Color accent) {
    final hasActivity = mins > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: hasActivity ? accent.withValues(alpha: 0.07) : AppTheme.parchmentSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasActivity ? accent.withValues(alpha: 0.3) : AppTheme.borderLight,
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 13,
            color: hasActivity ? accent : AppTheme.mutedText,
          ),
          const SizedBox(height: 3),
          Text(
            name,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatMins(mins),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: hasActivity ? accent : AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMins(int mins) {
    if (mins == 0) return '0m';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Widget _timeLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.mutedText,
      ),
    );
  }

  String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  int _getPeakHour() {
    int bestHour = -1;
    int bestMins = 0;
    for (final entry in hourMinutes.entries) {
      if (entry.value > bestMins) {
        bestMins = entry.value;
        bestHour = entry.key;
      }
    }
    return bestHour;
  }

  String _getPeakHourLabel(int bestHour) {
    if (bestHour == -1 || (hourMinutes[bestHour] ?? 0) == 0) return 'None';
    return _formatHour(bestHour);
  }
}
