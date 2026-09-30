import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TimerModesAnimationWidget extends StatefulWidget {
  const TimerModesAnimationWidget({super.key});

  @override
  State<TimerModesAnimationWidget> createState() => _TimerModesAnimationWidgetState();
}

class _TimerModesAnimationWidgetState extends State<TimerModesAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000), // 2s per mode
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value; // 0.0 to 1.0

        // Mode 0: Pomodoro (0.0 to 0.33)
        // Mode 1: Count-Up (0.33 to 0.66)
        // Mode 2: Module-Linked (0.66 to 1.00)
        final int modeIndex = t < 0.33 ? 0 : (t < 0.66 ? 1 : 2);

        return Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.sketchBorderColor, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x221C1C1C),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top Bar with FlowMD Mode Dropdown Button
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              modeIndex == 0
                                  ? '⏱  Pomodoro'
                                  : (modeIndex == 1 ? '⬆  Count-Up' : '📌  Module-Linked'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.7), size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mode Tag Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: modeIndex == 0
                            ? Colors.orange.withOpacity(0.2)
                            : (modeIndex == 1
                                ? Colors.blue.withOpacity(0.2)
                                : const Color(0xFF8B5CF6).withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: modeIndex == 0
                              ? Colors.orange
                              : (modeIndex == 1 ? Colors.blueAccent : const Color(0xFFA78BFA)),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        modeIndex == 0
                            ? 'INTERVAL DRILLS'
                            : (modeIndex == 1 ? 'MOCK TESTS' : 'LECTURE SYNC'),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: modeIndex == 0
                              ? Colors.orange
                              : (modeIndex == 1 ? Colors.blueAccent : const Color(0xFFA78BFA)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mode-specific Middle Controls & Timer Display
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: modeIndex == 0
                      ? _buildPomodoroContent(t)
                      : (modeIndex == 1
                          ? _buildCountUpContent(t)
                          : _buildModuleLinkedContent(t)),
                ),
              ),

              // Real Bottom Controls Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Row(
                  children: [
                    _miniControlBtn('Break', Icons.coffee_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.4),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pause_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('PAUSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.6)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _miniControlBtn('Finish', Icons.check_rounded, isFinish: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. Pomodoro Content with real interval preset chips
  Widget _buildPomodoroContent(double t) {
    final sub = (t / 0.33);
    final isBreak = sub > 0.65;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Real FlowMD Pomodoro preset chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [15, 25, 45, 60].map((mins) {
            final sel = mins == 25;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primaryBlue.withOpacity(0.85) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.2),
                  width: 1.2,
                ),
              ),
              child: Text(
                '${mins}m',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: sel ? Colors.white : Colors.white70,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        // Timer display
        Text(
          isBreak ? '04:52' : '24:18',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        Text(
          isBreak ? '☕ BREAK INTERVAL (5 MIN REST)' : '🔥 FOCUS INTERVAL (25 MIN SPRINT)',
          style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: isBreak ? Colors.orange : Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  // 2. Count-Up Content
  Widget _buildCountUpContent(double t) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '01:45:22',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        Text(
          'Total 01:45:22 · Open clinical stopwatch',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  // 3. Module-Linked Content
  Widget _buildModuleLinkedContent(double t) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Real task card in focus timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: AppTheme.primaryBlue, size: 12),
              SizedBox(width: 4),
              Text(
                'Cardiology · Heart Failure (38 mins)',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '38:00',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const Text(
          'Auto-marks lecture complete upon timer finish',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: Color(0xFFA78BFA),
          ),
        ),
      ],
    );
  }

  static Widget _miniControlBtn(String label, IconData icon, {bool isFinish = false}) {
    return Container(
      width: 42,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: isFinish ? Colors.greenAccent : Colors.white70),
          Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: isFinish ? Colors.greenAccent : Colors.white70)),
        ],
      ),
    );
  }
}
