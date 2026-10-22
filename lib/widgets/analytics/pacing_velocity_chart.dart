import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

/// Clinical Pacing & Velocity Trajectory Chart using fl_chart.
/// Renders cumulative module completion against target deadline trajectory
/// with 60fps gesture scrubbing and gradient fills.
class PacingVelocityChart extends StatefulWidget {
  final int totalModules;
  final int completedModules;
  final Map<String, int> dailyHistory;
  final double dailyQuota;
  final String? targetDateStr;

  const PacingVelocityChart({
    super.key,
    required this.totalModules,
    required this.completedModules,
    required this.dailyHistory,
    this.dailyQuota = 4.0,
    this.targetDateStr,
  });

  @override
  State<PacingVelocityChart> createState() => _PacingVelocityChartState();
}

class _PacingVelocityChartState extends State<PacingVelocityChart> {
  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.inkForeground;
    final secondary = AppTheme.mutedText;
    final accent = AppTheme.accentPrimary;

    // Past 14 days cumulative progression
    final now = DateTime.now();
    final List<DateTime> datePoints = List.generate(14, (i) {
      return now.subtract(Duration(days: 13 - i));
    });

    // Compute cumulative modules up to each date
    final List<FlSpot> actualSpots = [];
    int runningTotal = (widget.completedModules - 14 * widget.dailyQuota.toInt()).clamp(0, widget.totalModules);
    
    // Smooth recent trajectory points
    for (int i = 0; i < datePoints.length; i++) {
      final key = DateFormat('yyyy-MM-dd').format(datePoints[i]);
      final doneOnDay = widget.dailyHistory[key] ?? 0;
      runningTotal += doneOnDay;
      if (i == datePoints.length - 1) {
        runningTotal = widget.completedModules;
      }
      actualSpots.add(FlSpot(i.toDouble(), runningTotal.toDouble()));
    }

    // Target linear trajectory line
    final double targetPacePerDay = widget.dailyQuota > 0 ? widget.dailyQuota : 4.0;
    final double startTarget = (actualSpots.first.y - 4).clamp(0.0, widget.totalModules.toDouble());
    final List<FlSpot> targetSpots = [
      FlSpot(0, startTarget),
      FlSpot(13, (startTarget + 13 * targetPacePerDay).clamp(0.0, widget.totalModules.toDouble())),
    ];

    // Forecast line (next 5 days projection)
    final double currentSpeed = (actualSpots.last.y - actualSpots.first.y) / 13;
    final List<FlSpot> forecastSpots = [
      actualSpots.last,
      FlSpot(18, (actualSpots.last.y + 5 * currentSpeed).clamp(0.0, widget.totalModules.toDouble())),
    ];

    final maxY = (widget.totalModules > 0 ? widget.totalModules.toDouble() : 100.0)
        .clamp(actualSpots.last.y + 20, double.infinity);

    final bool isOnTrack = currentSpeed >= targetPacePerDay * 0.85;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.cardWhite,
        borderRadius: 20,
        shadowOffset: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pacing Velocity & Trajectory',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Actual completions vs. target deadline trajectory',
                      style: TextStyle(fontSize: 11, color: secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnTrack
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
                child: Text(
                  isOnTrack ? 'Velocity On Track' : 'Pacing Required',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isOnTrack ? const Color(0xFF059669) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 60fps LineChart Canvas
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 18,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).clamp(1.0, double.infinity),
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppTheme.borderLight.withValues(alpha: 0.7),
                    strokeWidth: 1.0,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        if (val == meta.max || val == meta.min) return const SizedBox.shrink();
                        return Text(
                          val.toInt().toString(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: secondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= datePoints.length) {
                          if (idx >= 14) {
                            return Text(
                              '+${idx - 13}d',
                              style: TextStyle(fontSize: 9, color: secondary),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('d MMM').format(datePoints[idx]),
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: secondary),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.inkForeground,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final isActual = barSpot.barIndex == 0;
                        return LineTooltipItem(
                          '${barSpot.y.toInt()} vids\n',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          children: [
                            TextSpan(
                              text: isActual ? 'Actual Cumulative' : 'Target Pace',
                              style: TextStyle(
                                color: isActual ? accent : Colors.grey.shade300,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // 1. Actual Progress Curve (Solid with Gradient Fill)
                  LineChartBarData(
                    spots: actualSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: accent,
                    barWidth: 3.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x == actualSpots.last.x,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: accent,
                          strokeWidth: 2,
                          strokeColor: AppTheme.cardWhite,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),

                  // 2. Target Linear Trajectory (Dashed)
                  LineChartBarData(
                    spots: targetSpots,
                    isCurved: false,
                    color: Colors.grey.shade400,
                    barWidth: 1.8,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),

                  // 3. Projected Velocity Forecast (Dotted)
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    color: isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    barWidth: 2.0,
                    dashArray: [3, 3],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Pacing Legend & Metrics Deck
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.parchmentSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendItem('Actual', accent, isDashed: false),
                _legendItem('Target', Colors.grey.shade500, isDashed: true),
                _legendItem(
                  'Forecast',
                  isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  isDashed: true,
                ),
                Text(
                  '${currentSpeed.toStringAsFixed(1)} vids/day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.inkForeground),
        ),
      ],
    );
  }
}
