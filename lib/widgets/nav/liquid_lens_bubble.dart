import 'package:flutter/material.dart';

/// Renders the authentic Liquid Glass Magnifying Lens Bubble from the reference video.
/// Features:
/// 1. Optical Clip-Mask: Clips the active row so icons/labels inside turn active color and magnify.
/// 2. Rainbow Caustic Crescent: Spectral dispersion along the bottom curved rim dipping 3px below dock.
/// 3. Glass Specular Highlights: Top-rim reflection and soft translucent frosted wash.
class LiquidLensBubble extends StatelessWidget {
  final Rect rect;
  final double totalWidth;
  final double dockHeight;
  final Color accentColor;
  final bool isDark;
  final Widget activeContent;

  const LiquidLensBubble({
    super.key,
    required this.rect,
    required this.totalWidth,
    required this.dockHeight,
    required this.accentColor,
    required this.isDark,
    required this.activeContent,
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
      height: rect.height + 4.0, // extra 4px for bottom droplet caustic bulge
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
          // 1. Frosted Translucent Glass Pill Base
          Positioned(
            left: 0,
            top: 0,
            width: rect.width,
            height: rect.height,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 8.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // 2. Optical Magnifying Lens Clip (Dual-Layer Alignment)
          Positioned(
            left: 0,
            top: 0,
            width: rect.width,
            height: rect.height,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
              child: OverflowBox(
                minWidth: totalWidth,
                maxWidth: totalWidth,
                minHeight: dockHeight,
                maxHeight: dockHeight,
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: Offset(-rect.left, -(rect.top)),
                  child: SizedBox(
                    width: totalWidth,
                    height: dockHeight,
                    child: activeContent,
                  ),
                ),
              ),
            ),
          ),
        ),

          // 3. Glass Specular & Rainbow Caustic Overlays
          Positioned(
            left: 0,
            top: 0,
            width: rect.width,
            height: rect.height + 4.0,
            child: IgnorePointer(
              child: CustomPaint(
                size: Size(rect.width, rect.height + 4.0),
                painter: _LiquidLensShaderPainter(
                  rect: Rect.fromLTWH(0, 0, rect.width, rect.height),
                  accentColor: accentColor,
                  borderRadius: borderRadius,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _LiquidLensShaderPainter extends CustomPainter {
  final Rect rect;
  final Color accentColor;
  final double borderRadius;
  final bool isDark;

  const _LiquidLensShaderPainter({
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

    // 1. Subtle Outer Glass Border
    final glassBorder = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, glassBorder);

    // 2. Top-Edge Glass Specular Reflection Highlight
    final topHighlightPath = Path()
      ..moveTo(rect.left + borderRadius * 0.8, rect.top + 0.8)
      ..lineTo(rect.right - borderRadius * 0.8, rect.top + 0.8);
    final topHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.40 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(topHighlightPath, topHighlightPaint);

    // 3. Chromatic Rainbow Caustic Crescent along the bottom edge
    // Dipping ~3px below the dock baseline with iridescent dispersion
    final causticRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom + 0.5),
      width: rect.width * 0.82,
      height: 8.0,
    );

    const rainbowGradient = LinearGradient(
      colors: [
        Color(0xFFFF3B30), // Red
        Color(0xFFFF9500), // Orange
        Color(0xFFFFCC00), // Yellow
        Color(0xFF34C759), // Green
        Color(0xFF00C7BE), // Teal
        Color(0xFF007AFF), // Blue
        Color(0xFFAF52DE), // Violet
      ],
      stops: [0.0, 0.16, 0.32, 0.50, 0.68, 0.84, 1.0],
    );

    final causticPaint = Paint()
      ..shader = rainbowGradient.createShader(causticRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);

    final causticPath = Path()
      ..moveTo(rect.center.dx - (rect.width * 0.36), rect.bottom - 0.5)
      ..quadraticBezierTo(
        rect.center.dx,
        rect.bottom + 3.2, // Caustic liquid droplet bulge dipping downward
        rect.center.dx + (rect.width * 0.36),
        rect.bottom - 0.5,
      );

    canvas.drawPath(causticPath, causticPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidLensShaderPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
