import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tour/app_tour_controller.dart';
import '../theme/app_theme.dart';
import 'animations/rolling_digit_text.dart';

/// Modern Aesthetic Ambient Desk Clock
///
/// Features:
/// 1. Frosted glass squircle container with specular metallic 0.75px gradient border.
/// 2. Monumental sculpted digital typography with [RollingDigitText] transitions.
/// 3. Ambient breathing colon that softly pulses with the live seconds cycle.
/// Modern Aesthetic Ambient Desk Clock & Unified Centerpiece Card
///
/// Features:
/// 1. Unified centerpiece card integrating Greeting, Date, and Monumental Time.
/// 2. Frosted glass squircle container with specular metallic 0.75px gradient border.
/// 3. Monumental sculpted digital typography with [RollingDigitText] transitions.
/// 4. Pure visual aesthetic focus: NO extra buttons, NO tags, NO clutter.
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
    final timeStr = DateFormat('h:mm').format(_time);
    final amPmStr = DateFormat('a').format(_time).toUpperCase();
    final dateStr = DateFormat('EEEE, d MMMM').format(_time).toUpperCase();
    final doctor = (widget.doctorName != null && widget.doctorName!.trim().isNotEmpty)
        ? widget.doctorName!.trim()
        : 'Doctor';

    return Padding(
      key: TourTargetRegistry.keyFor(TourTargetId.studyDeskClockTarget),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.52)
                  : Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.75),
                width: 0.75,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top inner specular highlight line
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
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

                // Main Content: Greeting + Date + Pure Sculpted Time
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Personal Greeting & Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Focus, $doctor.',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Center Hero Time Display (Pure minimal, no dots, no tags, no progress track)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          // Large sculpted time numerals
                          RollingDigitText(
                            text: timeStr,
                            style: TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                              height: 1.0,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Crisp minimal monochromatic AM/PM capsule
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0),
                                width: 0.75,
                              ),
                            ),
                            child: Text(
                              amPmStr,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
