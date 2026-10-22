import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TimerDockAnimationWidget extends StatefulWidget {
  const TimerDockAnimationWidget({super.key});

  @override
  State<TimerDockAnimationWidget> createState() =>
      _TimerDockAnimationWidgetState();
}

class _TimerDockAnimationWidgetState extends State<TimerDockAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
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

        // Phase 1 (0.0 to 0.28): Full Modulix FocusTimerScreen visible
        // Phase 2 (0.28 to 0.50): Pointer taps X, screen smoothly slides down
        // Phase 3 (0.50 to 0.85): MiniTimerOverlay docked above LovableNavBar
        // Phase 4 (0.85 to 1.00): Expands back up

        final double shrinkVal = t < 0.28
            ? 0.0
            : (t < 0.50
                ? (t - 0.28) / 0.22
                : (t < 0.85 ? 1.0 : 1.0 - (t - 0.85) / 0.15));

        final bool isDocked = shrinkVal > 0.5;

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
          child: Stack(
            children: [
              // ── 1. App background behind docked timer (Modulix Curriculum screen) ──
              Positioned.fill(
                child: Opacity(
                  opacity: shrinkVal.clamp(0.0, 1.0),
                  child: Container(
                    color: AppTheme.paperBackground,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App bar row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Curriculum',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Marrow Ed 8',
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryBlue)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Mock subject card
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: AppTheme.sketchDecoration(
                            backgroundColor: Colors.white,
                            borderRadius: 12,
                            shadowOffset: 2,
                            borderWidth: 1.4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.favorite_rounded,
                                    size: 16, color: Colors.red),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Medicine & Cardiology',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.inkForeground)),
                                    Text('18 of 42 chapters done',
                                        style: TextStyle(
                                            fontSize: 8,
                                            color: AppTheme.mutedText)),
                                  ],
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

              // ── 2. Exact Modulix FocusTimerScreen ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 45 * shrinkVal,
                child: Opacity(
                  opacity: (1.0 - shrinkVal).clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF141416),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Column(
                      children: [
                        // Modulix FocusTimer top bar
                        Row(
                          children: [
                            _miniGlassBtn(Icons.palette_outlined),
                            const SizedBox(width: 6),
                            _miniGlassBtn(Icons.graphic_eq_rounded,
                                isAccent: true),
                            const SizedBox(width: 6),
                            _miniGlassBtn(Icons.fullscreen_rounded),
                            const Spacer(),
                            // Real close cross
                            _miniGlassBtn(Icons.close_rounded,
                                isClose: true,
                                isHighlight: t >= 0.20 && t < 0.35),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Real Task Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.32),
                                width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: AppTheme.primaryBlue, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CARDIOLOGY',
                                        style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.primaryBlue,
                                            letterSpacing: 0.8)),
                                    const Text('Heart Failure Clinical Management',
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.tune_rounded,
                                  color: Colors.white54, size: 12),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Monospace Timer Digits
                        const Text(
                          '24:58',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          'Break 00:00 · Total 24:58',
                          style: TextStyle(
                              fontSize: 8,
                              color: Colors.white54,
                              fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        // Real bottom controls
                        Row(
                          children: [
                            _miniControlBtn('Break', Icons.coffee_outlined),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 1.4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pause_rounded,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('PAUSE',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            letterSpacing: 0.6)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _miniControlBtn('Finish', Icons.check_rounded,
                                isFinish: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 3. Exact Modulix MiniTimerOverlay (Docks above bottom nav) ──
              if (shrinkVal > 0.25)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 40,
                  child: Opacity(
                    opacity: ((shrinkVal - 0.25) / 0.75).clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x35000000),
                              blurRadius: 10,
                              offset: Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Green pulsing dot
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('CARDIOLOGY',
                                    style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6)),
                                Text('Heart Failure Clinical Management',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '24:54',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                                shape: BoxShape.circle),
                            child: Icon(Icons.pause_rounded,
                                color: AppTheme.primaryBlue, size: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── 4. Exact Modulix LovableNavBar at the bottom ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(
                            color: AppTheme.sketchBorderColor, width: 1.6)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _miniNavIcon(Icons.home_outlined, false),
                            _miniNavIcon(Icons.menu_book_rounded, isDocked),
                            const SizedBox(
                                width: 32), // space for center button
                            _miniNavIcon(Icons.bar_chart_outlined, false),
                            _miniNavIcon(Icons.person_outline, false),
                          ],
                        ),
                      ),
                      // Elevated Center Timer Button (Modulix signature)
                      Positioned(
                        top: -12,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: !isDocked
                                ? AppTheme.primaryBlue
                                : AppTheme.inkForeground,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x301C1C1C),
                                  offset: Offset(0, 2),
                                  blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.timer_outlined,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Touch tap indicator on close cross
              if (t >= 0.18 && t < 0.35)
                Positioned(
                  top: 4,
                  right: 10,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.35),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),

              // Live Status Badge
              Positioned(
                top: 6,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDocked
                        ? Colors.green.withValues(alpha: 0.9)
                        : Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Text(
                    isDocked ? 'DOCKED ABOVE NAV BAR' : 'TAP TO MINIMIZE',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _miniGlassBtn(IconData icon,
      {bool isAccent = false, bool isClose = false, bool isHighlight = false}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isHighlight
            ? Colors.redAccent.withValues(alpha: 0.4)
            : (isAccent
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08)),
        shape: BoxShape.circle,
        border: Border.all(
            color:
                isHighlight ? Colors.redAccent : Colors.white.withValues(alpha: 0.35),
            width: 1.2),
      ),
      child: Icon(icon,
          size: 12, color: isAccent ? AppTheme.primaryBlue : Colors.white),
    );
  }

  static Widget _miniControlBtn(String label, IconData icon,
      {bool isFinish = false}) {
    return Container(
      width: 38,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 13, color: isFinish ? Colors.greenAccent : Colors.white70),
          Text(label,
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: isFinish ? Colors.greenAccent : Colors.white70)),
        ],
      ),
    );
  }

  static Widget _miniNavIcon(IconData icon, bool active) {
    return Icon(icon,
        size: 15, color: active ? AppTheme.primaryBlue : Colors.grey.shade500);
  }
}
