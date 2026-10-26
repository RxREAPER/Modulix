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
/// 4. Integrated live date capsule and smooth micro-seconds progress track.
/// 5. Pure visual aesthetic focus: NO extra buttons, NO tags, NO clutter.
class StudyDeskClock extends StatefulWidget {
  const StudyDeskClock({super.key});

  @override
  State<StudyDeskClock> createState() => _StudyDeskClockState();
}

class _StudyDeskClockState extends State<StudyDeskClock> with SingleTickerProviderStateMixin {
  late DateTime _time;
  Timer? _timer;
  late final AnimationController _pulseController;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    final timeStr = DateFormat('h:mm').format(_time);
    final amPmStr = DateFormat('a').format(_time).toUpperCase();
    final dateStr = DateFormat('EEEE · d MMMM').format(_time).toUpperCase();
    final double secondsProgress = _time.second / 59.0;

    return Padding(
      key: TourTargetRegistry.keyFor(TourTargetId.studyDeskClockTarget),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.70),
                width: 0.75,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
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

                // Main Clock Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Minimal Date Stamp with subtle live seconds dot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FadeTransition(
                                  opacity: _pulseController,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: isDark
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Center Hero Time Display
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
                          // Crisp AM/PM capsule
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
                                fontSize: 13,
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

                      const SizedBox(height: 16),

                      // Bottom Subtle Seconds Progress Track
                      Container(
                        height: 2.5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: secondsProgress.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? const [
                                        Color(0xFF38BDF8),
                                        Color(0xFF818CF8),
                                      ]
                                    : const [
                                        Color(0xFF0284C7),
                                        Color(0xFF6366F1),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
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
