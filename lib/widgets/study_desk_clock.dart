import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        crossAxisAlignment: CrossAxisAlignment.center,
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

          // Interlocking Industrial Mechanical Coupling Hook & Bracket
          _MechanicalBridgeCoupler(isDark: isDark),

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

/// Realistic Industrial Mechanical Coupler Hook connecting both clock modules
class _MechanicalBridgeCoupler extends StatelessWidget {
  final bool isDark;

  const _MechanicalBridgeCoupler({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bracketColor = isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8);
    final screwColor = isDark ? const Color(0xFF64748B) : const Color(0xFF475569);
    final latchColor = isDark ? const Color(0xFF475569) : const Color(0xFF64748B);
    final highlight = isDark ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.85);

    return SizedBox(
      width: 16,
      height: 154,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── VERTICAL CHASSIS RAIL LINK ──
          Positioned(
            top: 24,
            bottom: 24,
            child: Container(
              width: 3.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // ── TOP CHASSIS MOUNT BRACKET ──
          Positioned(
            top: 22,
            child: _buildMountBracket(bracketColor, screwColor, highlight),
          ),

          // ── BOTTOM CHASSIS MOUNT BRACKET ──
          Positioned(
            bottom: 22,
            child: _buildMountBracket(bracketColor, screwColor, highlight),
          ),

          // ── CENTRAL INTERLOCKING MECHANICAL HOOK & HINGE COUPLING ──
          Center(
            child: Container(
              width: 22,
              height: 26,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF475569), const Color(0xFF1E293B)]
                      : [const Color(0xFFF1F5F9), const Color(0xFF94A3B8)],
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.white,
                  width: 0.75,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Horizontal mechanical pin axle
                  Container(
                    height: 2.5,
                    width: 18,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  // Left Hook Jaw
                  Positioned(
                    left: 2,
                    child: Container(
                      width: 4,
                      height: 12,
                      decoration: BoxDecoration(
                        color: latchColor,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: highlight, width: 0.5),
                      ),
                    ),
                  ),
                  // Right Catch Loop
                  Positioned(
                    right: 2,
                    child: Container(
                      width: 4,
                      height: 12,
                      decoration: BoxDecoration(
                        color: latchColor,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: highlight, width: 0.5),
                      ),
                    ),
                  ),
                  // Center Mechanical Hex Rivet
                  Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFFCBD5E1) : Colors.white,
                      border: Border.all(
                        color: isDark ? Colors.black.withValues(alpha: 0.6) : const Color(0xFF475569),
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMountBracket(Color bracketColor, Color screwColor, Color highlight) {
    return Container(
      width: 18,
      height: 9,
      decoration: BoxDecoration(
        color: bracketColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: highlight, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(shape: BoxShape.circle, color: screwColor),
          ),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(shape: BoxShape.circle, color: screwColor),
          ),
        ],
      ),
    );
  }
}

/// Authentic Mechanical Split-Flap Tile with True 3D Fold Animation & Kinematics
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
      duration: const Duration(milliseconds: 460),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );
    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.lightImpact();
      }
    });
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

  void _triggerManualFlip() {
    HapticFeedback.mediumImpact();
    _previousDigit = _currentDigit;
    _flipController.forward(from: 0.0);
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
        ? Colors.black.withValues(alpha: 0.85)
        : const Color(0xFF0F172A).withValues(alpha: 0.88);

    return AspectRatio(
      aspectRatio: 0.95,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final totalHeight = constraints.maxHeight;
          final halfHeight = totalHeight / 2;

          return GestureDetector(
            onTap: _triggerManualFlip,
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

                // ── 2. STATIC UPPER FLAP (Shows currentDigit top half) ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: halfHeight,
                  child: _FlapHalf(
                    digit: _currentDigit,
                    isTop: true,
                    width: totalWidth,
                    totalHeight: totalHeight,
                    textColor: textColor,
                    tileBg: tileBg,
                    borderColor: borderColor,
                    label: widget.topLabel,
                    metaColor: metaColor,
                    isDark: isDark,
                  ),
                ),

                // ── 3. STATIC LOWER FLAP (Shows previousDigit bottom while flipping, or currentDigit when idle) ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: halfHeight,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, _) {
                      final isFlipping = _flipController.isAnimating;
                      final digitToShow = isFlipping ? _previousDigit : _currentDigit;
                      return _FlapHalf(
                        digit: digitToShow,
                        isTop: false,
                        width: totalWidth,
                        totalHeight: totalHeight,
                        textColor: textColor,
                        tileBg: tileBg,
                        borderColor: borderColor,
                        bottomMeta: widget.bottomLeftLabel ?? widget.bottomRightLabel,
                        metaColor: metaColor,
                        isDark: isDark,
                      );
                    },
                  ),
                ),

                // ── 4. MECHANICAL 3D FOLDING FLAPS ──
                AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, _) {
                    final progress = _flipAnimation.value;
                    final isFlipping = _flipController.isAnimating;

                    if (!isFlipping) return const SizedBox.shrink();

                    if (progress < 0.5) {
                      // Upper Flap Folding Forward/Down (0 -> -90 deg)
                      final angle = -progress * math.pi; // 0 to -pi/2
                      return Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: halfHeight,
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0022)
                            ..rotateX(angle),
                          child: Stack(
                            children: [
                              _FlapHalf(
                                digit: _previousDigit,
                                isTop: true,
                                width: totalWidth,
                                totalHeight: totalHeight,
                                textColor: textColor,
                                tileBg: tileBg,
                                borderColor: borderColor,
                                label: widget.topLabel,
                                metaColor: metaColor,
                                isDark: isDark,
                              ),
                              // Dynamic shadow as flap tilts away from top light
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                    color: Colors.black.withValues(
                                      alpha: (progress * 2).clamp(0.0, 0.72),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Lower Flap Dropping Down onto bottom panel (+90 -> 0 deg)
                      final angle = (1.0 - progress) * math.pi; // pi/2 down to 0
                      return Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: halfHeight,
                        child: Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0022)
                            ..rotateX(angle),
                          child: Stack(
                            children: [
                              _FlapHalf(
                                digit: _currentDigit,
                                isTop: false,
                                width: totalWidth,
                                totalHeight: totalHeight,
                                textColor: textColor,
                                tileBg: tileBg,
                                borderColor: borderColor,
                                bottomMeta: widget.bottomLeftLabel ?? widget.bottomRightLabel,
                                metaColor: metaColor,
                                isDark: isDark,
                              ),
                              // Shadow dissipates as flap slaps flat against cushion
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                                    color: Colors.black.withValues(
                                      alpha: ((1.0 - progress) * 2).clamp(0.0, 0.72),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),

                // ── 5. PHYSICAL SPLIT SEAM CUT & MECHANICAL HINGE NOTCHES ──
                Positioned(
                  left: 0,
                  right: 0,
                  child: _buildSplitSeamAndHinges(seamColor, isDark),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSplitSeamAndHinges(Color seamColor, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // The physical slit cut line
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
            color: Colors.black.withValues(alpha: 0.30),
          ),
        ),
        // Bottom flap specular highlight line
        Transform.translate(
          offset: const Offset(0, 1.5),
          child: Container(
            height: 0.75,
            width: double.infinity,
            color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.65),
          ),
        ),
        // Left hinge notch
        Positioned(
          left: 0,
          child: Container(
            width: 4,
            height: 6,
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
            width: 4,
            height: 6,
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
    );
  }
}

/// Specialized Single Flap Half (Top or Bottom) for pixel-precise numeral cutting
class _FlapHalf extends StatelessWidget {
  final String digit;
  final bool isTop;
  final double width;
  final double totalHeight;
  final Color textColor;
  final Color tileBg;
  final Color borderColor;
  final String? label;
  final String? bottomMeta;
  final Color metaColor;
  final bool isDark;

  const _FlapHalf({
    required this.digit,
    required this.isTop,
    required this.width,
    required this.totalHeight,
    required this.textColor,
    required this.tileBg,
    required this.borderColor,
    this.label,
    this.bottomMeta,
    required this.metaColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final halfHeight = totalHeight / 2;

    return Container(
      width: width,
      height: halfHeight,
      decoration: BoxDecoration(
        color: tileBg.withValues(alpha: isDark ? 0.92 : 0.96),
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(22))
            : const BorderRadius.vertical(bottom: Radius.circular(22)),
        border: Border.all(color: borderColor, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: Offset(0, isTop ? -2 : 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(21))
            : const BorderRadius.vertical(bottom: Radius.circular(21)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Stack(
            children: [
              // Top specular highlight (only on top half)
              if (isTop)
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
                          isDark ? Colors.white.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.90),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // Half-Numeral: perfectly aligned to the split boundary
              Positioned(
                top: isTop ? 0 : -halfHeight,
                left: 0,
                right: 0,
                height: totalHeight,
                child: Center(
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
              ),

              // Top metadata label (date / day)
              if (isTop && label != null)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: metaColor,
                    ),
                  ),
                ),

              // Bottom metadata (AM/PM or live seconds)
              if (!isTop && bottomMeta != null)
                Positioned(
                  bottom: 9,
                  left: 12,
                  right: 12,
                  child: Text(
                    bottomMeta!,
                    textAlign: bottomMeta!.length <= 2 && RegExp(r'^\d+$').hasMatch(bottomMeta!)
                        ? TextAlign.right
                        : TextAlign.left,
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
    );
  }
}

