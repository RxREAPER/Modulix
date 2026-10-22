import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A 24-hour horizontal chronotype heat strip visualizing peak study intensity
/// across 4 medical day-parts (Night 0-6, Morning 6-12, Afternoon 12-18, Evening 18-24).
class ChronotypeHeatStrip extends StatelessWidget {
  final Map<int, int> hourMinutes; // hour (0..23) -> minutes studied
  final Color activeColor;

  const ChronotypeHeatStrip({
    super.key,
    required this.hourMinutes,
    this.activeColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    final maxMins = hourMinutes.values.fold<int>(0, (a, b) => a > b ? a : b);
    final isDark = AppTheme.current.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CHRONOTYPE INTENSITY (24H)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppTheme.mutedText,
              ),
            ),
            Text(
              'Peak: ${_getPeakHourLabel()}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(24, (hour) {
            final mins = hourMinutes[hour] ?? 0;
            final intensity = maxMins > 0 ? (mins / maxMins).clamp(0.0, 1.0) : 0.0;
            
            Color blockColor;
            if (intensity == 0.0) {
              blockColor = isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppTheme.borderLight;
            } else {
              blockColor = activeColor.withValues(alpha: 0.2 + (0.8 * intensity));
            }

            return Expanded(
              child: Tooltip(
                message: '${_formatHour(hour)}: ${mins}m studied',
                child: Container(
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 1.0),
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
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
      ],
    );
  }

  Widget _timeLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 8,
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

  String _getPeakHourLabel() {
    int bestHour = -1;
    int bestMins = 0;
    for (final entry in hourMinutes.entries) {
      if (entry.value > bestMins) {
        bestMins = entry.value;
        bestHour = entry.key;
      }
    }
    if (bestHour == -1 || bestMins == 0) return 'None';
    return _formatHour(bestHour);
  }
}
