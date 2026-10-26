import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tour/app_tour_controller.dart';
import '../theme/app_theme.dart';

/// Authentic Dual Split-Flap Flip Clock Widget
///
/// Features:
/// 1. Side-by-side split flap tiles (Hours on left, Minutes on right).
/// 2. Midline flap slit with hinge grooves and specular depth gradient.
/// 3. Left card: Top centered date (`dd/MM/yy`), bottom-left period (`AM`/`PM`).
/// 4. Right card: Top centered day of week, bottom-right running live seconds.
/// 5. Adaptive theme styling (crisp paper surface in light, obsidian slate in dark).
class StudyDeskClock extends StatefulWidget {
  final String? doctorName;

  const StudyDeskClock({
    super.key,
    this.doctorName,
  });

  @override
  State<StudyDeskClock> createState() => _StudyDeskClockState();
}

class _StudyDeskClockState extends State<StudyDeskClock> {
  late DateTime _time;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _time = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _time = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;

    // Formatting values matching the reference flip clock
    final hourStr = DateFormat('h').format(_time).padLeft(2, '0');
    final minuteStr = DateFormat('mm').format(_time);
    final amPmStr = DateFormat('a').format(_time).toUpperCase();
    final dateStr = DateFormat('dd/MM/yy').format(_time);
    final dayStr = DateFormat('EEEE').format(_time);
    final secondStr = DateFormat('ss').format(_time);

    return Padding(
      key: TourTargetRegistry.keyFor(TourTargetId.studyDeskClockTarget),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Left Tile: Hours
          Expanded(
            child: _FlipTile(
              digit: hourStr,
              topLabel: dateStr,
              bottomLeftLabel: amPmStr,
              bottomRightLabel: null,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 14),
          // Right Tile: Minutes
          Expanded(
            child: _FlipTile(
              digit: minuteStr,
              topLabel: dayStr,
              bottomLeftLabel: null,
              bottomRightLabel: secondStr,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipTile extends StatelessWidget {
  final String digit;
  final String topLabel;
  final String? bottomLeftLabel;
  final String? bottomRightLabel;
  final bool isDark;

  const _FlipTile({
    required this.digit,
    required this.topLabel,
    this.bottomLeftLabel,
    this.bottomRightLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Colors tuned for flip clock aesthetic matching reference
    final tileBg = isDark
        ? const Color(0xFF1E222A)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);
    final textColor = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF1E293B);
    final metaColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final seamColor = isDark
        ? Colors.black.withValues(alpha: 0.70)
        : const Color(0xFF0F172A).withValues(alpha: 0.85);

    return AspectRatio(
      aspectRatio: 0.95,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: tileBg.withValues(alpha: isDark ? 0.88 : 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor,
                width: 0.75,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Highlight Gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.90),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Center Massive Numeral
                Center(
                  child: Text(
                    digit,
                    style: TextStyle(
                      fontSize: 66,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                ),

                // Horizontal Split Flap Seam Line & Notches
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The slit cut
                        Container(
                          height: 1.5,
                          width: double.infinity,
                          color: seamColor,
                        ),
                        // Top flap slight shadow reflection
                        Transform.translate(
                          offset: const Offset(0, -1),
                          child: Container(
                            height: 1,
                            width: double.infinity,
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                        ),
                        // Bottom flap specular highlight line
                        Transform.translate(
                          offset: const Offset(0, 1.5),
                          child: Container(
                            height: 0.75,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.60),
                          ),
                        ),
                        // Left hinge notch
                        Positioned(
                          left: 0,
                          child: Container(
                            width: 3.5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: seamColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(2),
                                bottomRight: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        // Right hinge notch
                        Positioned(
                          right: 0,
                          child: Container(
                            width: 3.5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: seamColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                bottomLeft: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Centered Metadata Label (e.g. 22/08/24 or Thursday)
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Text(
                    topLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: metaColor,
                    ),
                  ),
                ),

                // Bottom Left Metadata (e.g. PM / AM)
                if (bottomLeftLabel != null)
                  Positioned(
                    bottom: 9,
                    left: 12,
                    child: Text(
                      bottomLeftLabel!,
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: metaColor,
                      ),
                    ),
                  ),

                // Bottom Right Metadata (e.g. Seconds 25)
                if (bottomRightLabel != null)
                  Positioned(
                    bottom: 9,
                    right: 12,
                    child: Text(
                      bottomRightLabel!,
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: metaColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
