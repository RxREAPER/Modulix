import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Authentic Apple Glass Pill indicator for the navigation dock.
/// Features:
/// 1. Frosted translucent glass base with theme-adaptive translucency.
/// 2. Crisp, subtle perimeter glass border.
/// 3. Top-edge glass specular reflection highlight arc.
/// 4. Material Design active indicator dot in accent color.
/// 5. Smooth ambient elevation drop shadow.
class LiquidLensBubble extends StatelessWidget {
  final Rect rect;
  final double totalWidth;
  final double dockHeight;
  final Color accentColor;
  final bool isDark;
  final Widget? activeContent;

  const LiquidLensBubble({
    super.key,
    required this.rect,
    required this.totalWidth,
    required this.dockHeight,
    required this.accentColor,
    required this.isDark,
    this.activeContent,
  });

  @override
  Widget build(BuildContext context) {
    if (rect.isEmpty || rect.width <= 0 || rect.height <= 0) {
      return const SizedBox.shrink();
    }

    final borderRadius = rect.height / 2.0;

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(rect.width, rect.height),
          painter: _AppleGlassPillPainter(
            rect: Rect.fromLTWH(0, 0, rect.width, rect.height),
            accentColor: accentColor,
            borderRadius: borderRadius,
            isDark: isDark,
          ),
          child: activeContent,
        ),
      ),
    );
  }
}


class _AppleGlassPillPainter extends CustomPainter {
  final Rect rect;
  final Color accentColor;
  final double borderRadius;
  final bool isDark;

  const _AppleGlassPillPainter({
    required this.rect,
    required this.accentColor,
    required this.borderRadius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // 1. Dual-Layer Ambient Drop Shadow
    final ambientShadow = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.32 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRRect(rrect.shift(const Offset(0, 3.0)), ambientShadow);

    final keyShadow = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.18 : 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(rrect.shift(const Offset(0, 1.0)), keyShadow);

    // 2. Frosted Apple Glass Fill (Subtle Top-to-Bottom Luminance Gradient)
    final glassFill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        isDark
            ? [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.09),
              ]
            : [
                Colors.white.withValues(alpha: 0.94),
                Colors.white.withValues(alpha: 0.82),
              ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, glassFill);

    // 3. Crisp Glass Border with Top-Lit Specular Gradient
    final glassBorder = Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        isDark
            ? [
                Colors.white.withValues(alpha: 0.28),
                Colors.white.withValues(alpha: 0.10),
              ]
            : [
                Colors.white.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.07),
              ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, glassBorder);

    // 4. Top-Edge Glass Specular Reflection Highlight Arc
    final topHighlightPath = Path()
      ..moveTo(rect.left + borderRadius * 0.7, rect.top + 0.8)
      ..lineTo(rect.right - borderRadius * 0.7, rect.top + 0.8);
    final topHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.38 : 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(topHighlightPath, topHighlightPaint);

    // 5. Material Design Active Indicator Dot
    final dotCenter = Offset(rect.center.dx, rect.bottom - 4.0);
    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _AppleGlassPillPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isDark != isDark;
  }
}
