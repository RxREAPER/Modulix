import 'dart:async';
import 'dart:math' as math;
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

class _FlipTile extends StatefulWidget {
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
  State<_FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends State<_FlipTile> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  String _currentDigit = '';
  String _previousDigit = '';

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _previousDigit = widget.digit;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _FlipTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _previousDigit = oldWidget.digit;
      _currentDigit = widget.digit;
      _flipController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // Palette calibrated for physical flip clock realism
    final tileBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFCBD5E1);
    final stackEdgeColor = isDark
        ? const Color(0xFF161920)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final metaColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final seamColor = isDark
        ? Colors.black.withValues(alpha: 0.78)
        : const Color(0xFF0F172A).withValues(alpha: 0.88);

    return AspectRatio(
      aspectRatio: 0.95,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── 1. REALISTIC PILE OF CARDS (STACKED LEAVES AT TOP & BOTTOM) ──
          // Top Stack Layer 2 (Furthest behind)
          Positioned(
            top: -5,
            left: 12,
            right: 12,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: stackEdgeColor.withValues(alpha: isDark ? 0.40 : 0.60),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: borderColor.withValues(alpha: 0.35), width: 0.5),
              ),
            ),
          ),
          // Top Stack Layer 1 (Directly behind main card)
          Positioned(
            top: -2.5,
            left: 6,
            right: 6,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: stackEdgeColor.withValues(alpha: isDark ? 0.70 : 0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.65),
              ),
            ),
          ),
          // Bottom Stack Layer 2 (Bottom leaves)
          Positioned(
            bottom: -5,
            left: 12,
            right: 12,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: stackEdgeColor.withValues(alpha: isDark ? 0.40 : 0.60),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border.all(color: borderColor.withValues(alpha: 0.35), width: 0.5),
              ),
            ),
          ),
          // Bottom Stack Layer 1
          Positioned(
            bottom: -2.5,
            left: 6,
            right: 6,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: stackEdgeColor.withValues(alpha: isDark ? 0.70 : 0.85),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.65),
              ),
            ),
          ),

          // ── 2. ACTIVE SPLIT-FLAP TILES WITH 3D MOTION ──
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: tileBg.withValues(alpha: isDark ? 0.90 : 0.94),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor, width: 0.75),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final progress = _flipAnimation.value;
                    final isFlipping = _flipController.isAnimating;
                    final displayDigit = (isFlipping && progress < 0.5)
                        ? _previousDigit
                        : _currentDigit;

                    return Stack(
                      children: [
                        // Top Highlight Line
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

                        // Center Monumental Numeral with subtle 3D perspective pitch on flip
                        Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0018)
                              ..rotateX(isFlipping ? (progress * math.pi) : 0.0),
                            child: Text(
                              displayDigit,
                              style: TextStyle(
                                fontSize: 66,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -1.0,
                                height: 1.0,
                              ),
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
                                // Top flap shadow reflection
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

                        // Top Centered Metadata Label (e.g. 27/10/26 or Tuesday)
                        Positioned(
                          top: 10,
                          left: 12,
                          right: 12,
                          child: Text(
                            widget.topLabel,
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
                        if (widget.bottomLeftLabel != null)
                          Positioned(
                            bottom: 9,
                            left: 12,
                            child: Text(
                              widget.bottomLeftLabel!,
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: metaColor,
                              ),
                            ),
                          ),

                        // Bottom Right Metadata (e.g. Seconds 25)
                        if (widget.bottomRightLabel != null)
                          Positioned(
                            bottom: 9,
                            right: 12,
                            child: Text(
                              widget.bottomRightLabel!,
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: metaColor,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
