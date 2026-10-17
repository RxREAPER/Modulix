import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class FlipClockRotateAnimationWidget extends StatefulWidget {
  const FlipClockRotateAnimationWidget({super.key});

  @override
  State<FlipClockRotateAnimationWidget> createState() =>
      _FlipClockRotateAnimationWidgetState();
}

class _FlipClockRotateAnimationWidgetState
    extends State<FlipClockRotateAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
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

        final bool isLandscape = t >= 0.30 && t < 0.88;
        final double rotProgress = t < 0.25
            ? 0.0
            : (t < 0.38
                ? (t - 0.25) / 0.13
                : (t < 0.85 ? 1.0 : 1.0 - (t - 0.85) / 0.15));

        // Flip angle
        final double flipAngle = (t >= 0.48 && t < 0.75)
            ? ((t - 0.48) / 0.27) * math.pi
            : (t >= 0.75 ? math.pi : 0.0);

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
            alignment: Alignment.center,
            children: [
              // Rotating phone frame
              Transform.rotate(
                angle: rotProgress * (math.pi / 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isLandscape ? 210 : 120,
                  height: isLandscape ? 120 : 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isLandscape ? AppTheme.primaryBlue : Colors.white24,
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Modulix Fullscreen Floating Top Header
                      Positioned(
                        top: 8,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARDIOLOGY',
                                  style: TextStyle(
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                Text(
                                  'Heart Failure Management',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.35)),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 10),
                            ),
                          ],
                        ),
                      ),

                      // Dead-Center Flip Clock Tiles (Modulix signature)
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSquarishTile('24'),
                            const SizedBox(width: 4),
                            const Text(
                              ':',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _buildSquarishTile(
                                flipAngle > math.pi / 2 ? '58' : '59'),
                          ],
                        ),
                      ),

                      // Modulix Floating Bottom Control Pill
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.38),
                                  width: 1.2),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pause_rounded,
                                    color: Colors.white, size: 11),
                                SizedBox(width: 4),
                                Text(
                                  'PAUSE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Badges overlay
              Positioned(
                top: 8,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLandscape ? AppTheme.primaryBlue : Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLandscape ? 'LANDSCAPE FLIP CLOCK' : 'PORTRAIT TIMER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 8,
                right: 10,
                child: Row(
                  children: [
                    Icon(
                      Icons.screen_rotation_rounded,
                      size: 13,
                      color: isLandscape ? Colors.greenAccent : Colors.white60,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLandscape
                          ? 'Dead-centered in landscape'
                          : 'Rotate phone for desk clock',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquarishTile(String digit) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF222226),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Middle crease
          const Positioned(
            left: 0,
            right: 0,
            top: 23,
            child: Divider(height: 1, color: Color(0xFF141416)),
          ),
          Text(
            digit,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
