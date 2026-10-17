import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'animations/apple_pressable.dart';
import 'nav/sketch_hatch_indicator.dart';
import 'nav/sketch_nav_icons.dart';

export 'nav/sketch_nav_icons.dart' show SketchNavIconType, SketchNavIcon;
export 'nav/sketch_hatch_indicator.dart' show SketchHatchIndicator;

class LovableNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final SketchNavIconType? sketchType;

  const LovableNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.sketchType,
  });
}

/// Floating Sketchy Island bottom navigation dock lifted above the bottom screen edge.
/// Features an authentic multi-pass hand-drawn capsule shell with draftsman guide lines,
/// a fluid sliding crayon / colored-pencil hatch indicator enveloping active icon & label,
/// hand-drawn line-art vector icons, handwritten sketch typography,
/// an elevated center Focus Timer button with an ambient breathing halo ring,
/// and active tab re-tap scroll-to-top support with double-bounce haptic ripple.
class LovableNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onTimerTap;
  final List<LovableNavItem> items;
  final bool isSessionActive;
  final ValueChanged<int>? onReTap;

  const LovableNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onTimerTap,
    required this.items,
    this.isSessionActive = false,
    this.onReTap,
  });

  @override
  State<LovableNavBar> createState() => _LovableNavBarState();
}

class _LovableNavBarState extends State<LovableNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _haloController;
  Timer? _reTapTimer;

  @override
  void initState() {
    super.initState();
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.isSessionActive) {
      _haloController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LovableNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSessionActive != oldWidget.isSessionActive) {
      if (widget.isSessionActive) {
        _haloController.repeat();
      } else {
        _haloController.stop();
        _haloController.reset();
      }
    }
  }

  @override
  void dispose() {
    _reTapTimer?.cancel();
    _haloController.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    if (index == widget.currentIndex) {
      // Re-tap on active tab: trigger double-bounce haptic ripple & callback
      HapticFeedback.selectionClick();
      _reTapTimer?.cancel();
      _reTapTimer = Timer(const Duration(milliseconds: 65), () {
        HapticFeedback.selectionClick();
      });
      if (widget.onReTap != null) {
        widget.onReTap!(index);
      } else {
        widget.onTap(index);
      }
    } else {
      widget.onTap(index);
    }
  }

  SketchNavIconType _resolveSketchType(LovableNavItem item, int index) {
    if (item.sketchType != null) return item.sketchType!;
    final l = item.label.toLowerCase();
    if (l.contains('home')) return SketchNavIconType.home;
    if (l.contains('curriculum')) return SketchNavIconType.curriculum;
    if (l.contains('analytics') || l.contains('chart')) {
      return SketchNavIconType.analytics;
    }
    if (l.contains('profile') || l.contains('settings') || l.contains('user')) {
      return SketchNavIconType.profile;
    }
    switch (index) {
      case 0:
        return SketchNavIconType.home;
      case 1:
        return SketchNavIconType.curriculum;
      case 2:
        return SketchNavIconType.analytics;
      default:
        return SketchNavIconType.profile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    final isTimerActive = widget.currentIndex == 4;
    const dockHeight = 70.0;
    const centerButtonDiameter = 64.0;
    const totalDockHeight = 84.0;
    const horizontalInset = 10.0;

    // Adapt accent color dynamically from active theme
    final accentColor = AppTheme.accentPrimary;
    final activeTextColor = accentColor;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(
          height: totalDockHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Floating Sketchy Capsule Dock (Solid Opaque Paper Background)
              Align(
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  foregroundPainter: _MultiPassSketchPainter(
                    strokeColor: AppTheme.sketchBorderColor,
                    borderRadius: 35.0,
                  ),
                  child: Container(
                    height: dockHeight,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E22)
                          : const Color(0xFFFAF7F2), // 100% Solid Opaque Paper Background
                      borderRadius: BorderRadius.circular(35.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.inkForeground.withValues(
                            alpha: isDark ? 0.40 : 0.08,
                          ),
                          offset: const Offset(0, 4),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: AppTheme.sketchBorderColor
                              .withValues(alpha: 0.10),
                          offset: const Offset(1, 1),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final totalWidth = constraints.maxWidth;
                          final usableWidth =
                              math.max(0.0, totalWidth - (horizontalInset * 2));
                          final slotWidth = usableWidth / 5.0;

                          // Map tab currentIndex (0..3) to 5-slot layout:
                          // Slot 0: Tab 0 (Home)
                          // Slot 1: Tab 1 (Curriculum)
                          // Slot 2: Center Focus Timer Medallion (Elevated Stopwatch)
                          // Slot 3: Tab 2 (Analytics)
                          // Slot 4: Tab 3 (Profile)
                          int? activeSlot;
                          if (widget.currentIndex == 0) {
                            activeSlot = 0;
                          } else if (widget.currentIndex == 1) {
                            activeSlot = 1;
                          } else if (widget.currentIndex == 2) {
                            activeSlot = 3;
                          } else if (widget.currentIndex == 3) {
                            activeSlot = 4;
                          }

                          Rect? pillRect;
                          if (activeSlot != null) {
                            final slotCenter = horizontalInset +
                                ((activeSlot + 0.5) * slotWidth);
                            final pillWidth = math.min(slotWidth - 6.0, 64.0);
                            const pillHeight = 58.0;
                            final pillLeft = slotCenter - (pillWidth / 2);
                            const pillTop = (dockHeight - pillHeight) / 2;

                            pillRect = Rect.fromLTWH(
                              pillLeft,
                              pillTop,
                              pillWidth,
                              pillHeight,
                            );
                          }

                          return Stack(
                            children: [
                              // 2. Sliding Crayon / Colored-Pencil Hatch Squircle Indicator (Rounded capsule borders matching nav)
                              if (pillRect != null)
                                Positioned.fill(
                                  child: SketchHatchIndicator(
                                    targetRect: pillRect,
                                    hatchColor: accentColor,
                                    borderRadius: 26.0,
                                  ),
                                ),

                              // 3. Tab Items Row (5 Equal Slots with comfortable horizontal inset)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: horizontalInset,
                                ),
                                child: Row(
                                  children: [
                                    // Slot 0: Home
                                    Expanded(
                                      child: _BouncyTabItem(
                                        index: 0,
                                        item: widget.items[0],
                                        sketchType: _resolveSketchType(
                                            widget.items[0], 0),
                                        isSelected: widget.currentIndex == 0,
                                        activeColor: activeTextColor,
                                        onTap: () => _handleTabTap(0),
                                      ),
                                    ),

                                    // Slot 1: Curriculum
                                    Expanded(
                                      child: _BouncyTabItem(
                                        index: 1,
                                        item: widget.items[1],
                                        sketchType: _resolveSketchType(
                                            widget.items[1], 1),
                                        isSelected: widget.currentIndex == 1,
                                        activeColor: activeTextColor,
                                        onTap: () => _handleTabTap(1),
                                      ),
                                    ),

                                    // Slot 2: Placeholder spacer for Center Focus Timer
                                    SizedBox(width: slotWidth),

                                    // Slot 3: Analytics
                                    Expanded(
                                      child: _BouncyTabItem(
                                        index: 2,
                                        item: widget.items[2],
                                        sketchType: _resolveSketchType(
                                            widget.items[2], 2),
                                        isSelected: widget.currentIndex == 2,
                                        activeColor: activeTextColor,
                                        onTap: () => _handleTabTap(2),
                                      ),
                                    ),

                                    // Slot 4: Profile
                                    Expanded(
                                      child: _BouncyTabItem(
                                        index: 3,
                                        item: widget.items[3],
                                        sketchType: _resolveSketchType(
                                            widget.items[3], 3),
                                        isSelected: widget.currentIndex == 3,
                                        activeColor: activeTextColor,
                                        onTap: () => _handleTabTap(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Center Elevated Focus Timer Button with Breathing Halo & Solid Ink Medallion
              Positioned(
                top: 4.0,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Ambient breathing halo ring when focus timer is active
                    if (widget.isSessionActive)
                      AnimatedBuilder(
                        animation: _haloController,
                        builder: (context, child) {
                          final scale = 1.0 + (_haloController.value * 0.35);
                          final opacity = (1.0 - _haloController.value) * 0.50;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: centerButtonDiameter + 6.0,
                              height: centerButtonDiameter + 6.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withValues(alpha: opacity),
                                  width: 2.2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Center Elevated Button with Solid Charcoal / Ink Medallion
                    ApplePressable(
                      pressedScale: 0.90,
                      pressedOpacity: 0.92,
                      hapticStyle: HapticStyle.selection,
                      onTap: widget.onTimerTap,
                      child: Container(
                        key: const Key('nav_center_timer_button'),
                        width: centerButtonDiameter,
                        height: centerButtonDiameter,
                        decoration: BoxDecoration(
                          color: isTimerActive
                              ? accentColor
                              : (isDark
                                  ? const Color(0xFF141416)
                                  : const Color(0xFF1E1C1A)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3A3A40)
                                : Colors.white,
                            width: 2.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.inkForeground.withValues(
                                alpha: isDark ? 0.45 : 0.22,
                              ),
                              offset: const Offset(0, 3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _SketchTimerMedallionPainter(
                            strokeColor: Colors.white.withValues(alpha: 0.70),
                          ),
                          child: const Center(
                            child: SketchNavIcon(
                              type: SketchNavIconType.pomodoro,
                              color: Colors.white,
                              size: 42,
                              isSelected: true,
                            ),
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
    );
  }
}

class _BouncyTabItem extends StatefulWidget {
  final int index;
  final LovableNavItem item;
  final SketchNavIconType sketchType;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _BouncyTabItem({
    required this.index,
    required this.item,
    required this.sketchType,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_BouncyTabItem> createState() => _BouncyTabItemState();
}

class _BouncyTabItemState extends State<_BouncyTabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Micro-bounce: scales 1.0 -> 1.20 -> 1.05 with subtle tilt
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.20)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.20, end: 1.05)
            .chain(CurveTween(curve: const Cubic(0.175, 0.885, 0.32, 1.275))),
        weight: 55,
      ),
    ]).animate(_bounceController);

    _tiltAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.08)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.08, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 60,
      ),
    ]).animate(_bounceController);

    if (widget.isSelected) {
      _bounceController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _BouncyTabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _bounceController.forward(from: 0.0);
    } else if (oldWidget.isSelected && !widget.isSelected) {
      _bounceController.reset();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.isSelected ? widget.activeColor : AppTheme.mutedText;

    return ApplePressable(
      pressedScale: 0.88,
      pressedOpacity: 0.85,
      hapticStyle: HapticStyle.none,
      onTap: () {
        if (widget.isSelected) {
          // Re-trigger micro-bounce on re-tap
          _bounceController.forward(from: 0.0);
        }
        widget.onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, child) {
                final scale = widget.isSelected ? _scaleAnimation.value : 1.0;
                final angle = widget.isSelected ? _tiltAnimation.value : 0.0;

                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: angle,
                    child: SketchNavIcon(
                      type: widget.sketchType,
                      color: iconColor,
                      size: 24,
                      isSelected: widget.isSelected,
                      strokeWidth: widget.isSelected ? 1.9 : 1.5,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                color: iconColor,
                fontFamily: 'CabinSketch',
                letterSpacing: 0.35,
              ),
              child: Text(
                widget.item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-pass hand-drawn sketchy contour painter for the outer dock capsule
class _MultiPassSketchPainter extends CustomPainter {
  final Color strokeColor;
  final double borderRadius;

  const _MultiPassSketchPainter({
    required this.strokeColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // 1. Primary Hand-Drawn Capsule Contour
    final primaryPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final baseRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(baseRRect, primaryPaint);

    // 2. Secondary Contour Pass with organic pen jitter & ink density
    final pass2Paint = Paint()
      ..color = strokeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final rrectPass2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.8, -0.6, w - 1.2, h + 0.6),
      Radius.circular(borderRadius + 0.5),
    );
    canvas.drawRRect(rrectPass2, pass2Paint);

    // 3. Tertiary Loose Sketch Loop
    final pass3Paint = Paint()
      ..color = strokeColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95
      ..strokeCap = StrokeCap.round;

    final rrectPass3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(-0.7, 0.7, w + 1.1, h - 0.4),
      Radius.circular(borderRadius - 0.4),
    );
    canvas.drawRRect(rrectPass3, pass3Paint);

    // 4. Horizontal wavy top and bottom edge lines spanning the capsule (passing behind timer)
    canvas.drawLine(
      Offset(borderRadius * 0.4, 0.4),
      Offset(w - borderRadius * 0.4, -0.3),
      pass2Paint,
    );
    canvas.drawLine(
      Offset(borderRadius * 0.7, 1.2),
      Offset(w - borderRadius * 0.6, 0.8),
      pass3Paint,
    );
    canvas.drawLine(
      Offset(borderRadius * 0.5, h - 0.4),
      Offset(w - borderRadius * 0.5, h + 0.4),
      pass2Paint,
    );
    canvas.drawLine(
      Offset(borderRadius * 0.7, h + 1.1),
      Offset(w - borderRadius * 0.7, h - 0.8),
      pass3Paint,
    );

    // 5. Authentic sketchbook pencil loops & scribble tails at the ends (matching ref_dock.png)
    // Left end overshoot loops
    canvas.drawLine(
      Offset(borderRadius * 0.45, -1.0),
      Offset(-3.2, borderRadius * 0.45),
      pass2Paint,
    );
    canvas.drawLine(
      Offset(-3.0, h - borderRadius * 0.45),
      Offset(borderRadius * 0.45, h + 1.8),
      pass2Paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(-3.5, h * 0.20, borderRadius * 1.3, h * 0.60),
      math.pi * 0.55,
      math.pi * 0.90,
      false,
      pass3Paint,
    );

    // Right end overshoot scribble loops
    canvas.drawLine(
      Offset(w - borderRadius * 0.45, -1.2),
      Offset(w + 3.4, borderRadius * 0.40),
      pass2Paint,
    );
    canvas.drawLine(
      Offset(w - borderRadius * 0.45, h + 1.8),
      Offset(w + 3.2, h - borderRadius * 0.40),
      pass2Paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(w - borderRadius * 1.3 + 3.5, h * 0.20, borderRadius * 1.3, h * 0.60),
      -math.pi * 0.45,
      math.pi * 0.90,
      false,
      pass3Paint,
    );
    // Trailing pen flick tails at right end
    canvas.drawLine(
      Offset(w + 0.5, 3.5),
      Offset(w + 5.0, -1.0),
      pass3Paint,
    );
    canvas.drawLine(
      Offset(w + 0.5, h - 3.5),
      Offset(w + 4.8, h + 2.5),
      pass3Paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MultiPassSketchPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Hand-sketched contour ring & felt-marker shading for the center Focus Timer medallion
class _SketchTimerMedallionPainter extends CustomPainter {
  final Color strokeColor;

  const _SketchTimerMedallionPainter({required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.5;

    // 1. Diagonal felt-marker texture lines (///) inside the dark circular medallion
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    final markerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final markerJitterPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const markerSpacing = 4.5;
    final count = ((size.width + size.height) / markerSpacing).ceil() + 2;
    for (int i = 0; i < count; i++) {
      final x = -size.height + (i * markerSpacing);
      final p1 = Offset(x, size.height + 6);
      final p2 = Offset(x + size.height + 6, -6);
      final p = (i % 2 == 0) ? markerPaint : markerJitterPaint;
      canvas.drawLine(p1, p2, p);
    }
    canvas.restore();

    // 2. Outer concentric sketchy rings (gel-pen / white pencil)
    final p1 = Paint()
      ..color = strokeColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(center.translate(0.5, -0.5), radius - 1.2, p1);

    final p2 = Paint()
      ..color = strokeColor.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    canvas.drawCircle(center.translate(-0.5, 0.6), radius - 2.5, p2);

    // 3. Faint outer circular guide line (matching ref_timer.png)
    final guidePaint1 = Paint()
      ..color = strokeColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(center.translate(-0.3, 0.4), radius + 3.8, guidePaint1);

    final guidePaint2 = Paint()
      ..color = strokeColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawCircle(center.translate(0.4, -0.3), radius + 4.6, guidePaint2);

    // 5. Dock top guideline passing horizontally behind the medallion
    final dockLinePaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95;
    canvas.drawLine(
      const Offset(-12, 10.0),
      Offset(size.width + 12, 10.0),
      dockLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SketchTimerMedallionPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor;
  }
}
