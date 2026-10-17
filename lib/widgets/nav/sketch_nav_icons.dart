import 'dart:math' as math;
import 'package:flutter/material.dart';

enum SketchNavIconType {
  home,
  curriculum,
  analytics,
  profile,
  stopwatch,
  pomodoro,
}

/// A hand-drawn line-art vector icon that renders authentic multi-pass
/// pen and ink strokes matching the Modulix sketch aesthetic.
class SketchNavIcon extends StatelessWidget {
  final SketchNavIconType type;
  final Color color;
  final double size;
  final bool isSelected;
  final double strokeWidth;

  const SketchNavIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 24.0,
    this.isSelected = false,
    this.strokeWidth = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    if (type == SketchNavIconType.pomodoro) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/icons/navbar/pomodoro_tomato_only_white.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: color,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              painter: _SketchNavIconPainter(
                type: type,
                color: color,
                isSelected: isSelected,
                strokeWidth: strokeWidth,
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SketchNavIconPainter(
          type: type,
          color: color,
          isSelected: isSelected,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SketchNavIconPainter extends CustomPainter {
  final SketchNavIconType type;
  final Color color;
  final bool isSelected;
  final double strokeWidth;

  const _SketchNavIconPainter({
    required this.type,
    required this.color,
    required this.isSelected,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primaryPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final secondaryPaint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, strokeWidth * 0.7)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case SketchNavIconType.home:
        _paintHome(canvas, w, h, primaryPaint, secondaryPaint);
        break;
      case SketchNavIconType.curriculum:
        _paintCurriculum(canvas, w, h, primaryPaint, secondaryPaint);
        break;
      case SketchNavIconType.analytics:
        _paintAnalytics(canvas, w, h, primaryPaint, secondaryPaint);
        break;
      case SketchNavIconType.profile:
        _paintProfile(canvas, w, h, primaryPaint, secondaryPaint);
        break;
      case SketchNavIconType.stopwatch:
        _paintStopwatch(canvas, w, h, primaryPaint, secondaryPaint);
        break;
      case SketchNavIconType.pomodoro:
        _paintPomodoro(canvas, w, h, primaryPaint, secondaryPaint);
        break;
    }
  }

  void _paintHome(Canvas canvas, double w, double h, Paint p1, Paint p2) {
    // 1. Roof Path
    final roof = Path()
      ..moveTo(w * 0.10, h * 0.44)
      ..lineTo(w * 0.50, h * 0.12)
      ..lineTo(w * 0.90, h * 0.44);

    // Subtle sketch jitter for second pass
    final roofJitter = Path()
      ..moveTo(w * 0.08, h * 0.45)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.92, h * 0.45);

    // 2. Chimney
    final chimney = Path()
      ..moveTo(w * 0.70, h * 0.27)
      ..lineTo(w * 0.70, h * 0.15)
      ..lineTo(w * 0.80, h * 0.15)
      ..lineTo(w * 0.80, h * 0.36);

    // 3. Walls
    final walls = Path()
      ..moveTo(w * 0.20, h * 0.44)
      ..lineTo(w * 0.20, h * 0.88)
      ..lineTo(w * 0.80, h * 0.88)
      ..lineTo(w * 0.80, h * 0.44);

    final wallsJitter = Path()
      ..moveTo(w * 0.19, h * 0.45)
      ..lineTo(w * 0.21, h * 0.89)
      ..lineTo(w * 0.79, h * 0.88)
      ..lineTo(w * 0.81, h * 0.43);

    // 4. Door & Knob
    final door = Path()
      ..moveTo(w * 0.42, h * 0.88)
      ..lineTo(w * 0.42, h * 0.58)
      ..lineTo(w * 0.58, h * 0.58)
      ..lineTo(w * 0.58, h * 0.88);

    // Paint secondary sketch passes
    canvas.drawPath(roofJitter, p2);
    canvas.drawPath(wallsJitter, p2);

    // Paint primary strokes
    canvas.drawPath(chimney, p1);
    canvas.drawPath(roof, p1);
    canvas.drawPath(walls, p1);
    canvas.drawPath(door, p1);

    // Doorknob dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.47, h * 0.73), 1.2, dotPaint);
  }

  void _paintCurriculum(Canvas canvas, double w, double h, Paint p1, Paint p2) {
    // Open Book Outline
    final spineTop = Offset(w * 0.50, h * 0.22);
    final spineBottom = Offset(w * 0.50, h * 0.84);

    // Spine
    final spine = Path()
      ..moveTo(spineTop.dx, spineTop.dy)
      ..lineTo(spineBottom.dx, spineBottom.dy);

    // Left Page
    final leftPage = Path()
      ..moveTo(spineTop.dx, spineTop.dy)
      ..cubicTo(w * 0.36, h * 0.16, w * 0.24, h * 0.18, w * 0.12, h * 0.26)
      ..lineTo(w * 0.12, h * 0.78)
      ..cubicTo(w * 0.24, h * 0.70, w * 0.36, h * 0.74, spineBottom.dx, spineBottom.dy);

    // Right Page
    final rightPage = Path()
      ..moveTo(spineTop.dx, spineTop.dy)
      ..cubicTo(w * 0.64, h * 0.16, w * 0.76, h * 0.18, w * 0.88, h * 0.26)
      ..lineTo(w * 0.88, h * 0.78)
      ..cubicTo(w * 0.76, h * 0.70, w * 0.64, h * 0.74, spineBottom.dx, spineBottom.dy);

    // Secondary page rim underneath for thickness
    final pageThickness = Path()
      ..moveTo(w * 0.12, h * 0.82)
      ..cubicTo(w * 0.24, h * 0.74, w * 0.36, h * 0.78, spineBottom.dx, spineBottom.dy + 3.0)
      ..cubicTo(w * 0.64, h * 0.78, w * 0.76, h * 0.74, w * 0.88, h * 0.82);

    canvas.drawPath(leftPage, p2);
    canvas.drawPath(rightPage, p2);
    canvas.drawPath(spine, p1);
    canvas.drawPath(leftPage, p1);
    canvas.drawPath(rightPage, p1);
    canvas.drawPath(pageThickness, p2);

    // Handwritten page lines
    final textLinePaint = Paint()
      ..color = color.withValues(alpha: isSelected ? 0.70 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Left page lines
    canvas.drawLine(Offset(w * 0.20, h * 0.38), Offset(w * 0.42, h * 0.36), textLinePaint);
    canvas.drawLine(Offset(w * 0.19, h * 0.49), Offset(w * 0.43, h * 0.48), textLinePaint);
    canvas.drawLine(Offset(w * 0.21, h * 0.60), Offset(w * 0.41, h * 0.60), textLinePaint);

    // Right page lines
    canvas.drawLine(Offset(w * 0.58, h * 0.36), Offset(w * 0.80, h * 0.38), textLinePaint);
    canvas.drawLine(Offset(w * 0.57, h * 0.48), Offset(w * 0.81, h * 0.49), textLinePaint);
    canvas.drawLine(Offset(w * 0.59, h * 0.60), Offset(w * 0.79, h * 0.60), textLinePaint);
  }

  void _paintAnalytics(Canvas canvas, double w, double h, Paint p1, Paint p2) {
    // 3 Histogram Columns: Left (Medium), Middle (Tall), Right (Short)
    final r1 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.18, h * 0.40, w * 0.36, h * 0.88),
      const Radius.circular(3.5),
    );
    final r2 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.41, h * 0.16, w * 0.59, h * 0.88),
      const Radius.circular(3.5),
    );
    final r3 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.64, h * 0.52, w * 0.82, h * 0.88),
      const Radius.circular(3.5),
    );

    // Colored pencil shading inside bars when active (matching ref_pill.png)
    if (isSelected) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.38)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(r1, fillPaint);
      canvas.drawRRect(r2, fillPaint);
      canvas.drawRRect(r3, fillPaint);

      // Fine diagonal hatch lines inside the bars
      final barHatchPaint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      for (final r in [r1, r2, r3]) {
        canvas.save();
        canvas.clipRRect(r);
        for (double x = r.left - r.height; x < r.right + r.height; x += 3.5) {
          canvas.drawLine(
            Offset(x, r.bottom + 2),
            Offset(x + r.height + 2, r.top - 2),
            barHatchPaint,
          );
        }
        canvas.restore();
      }
    }

    // Sketch contour jitter
    final r1Jitter = r1.shift(const Offset(0.4, -0.4));
    final r2Jitter = r2.shift(const Offset(-0.4, 0.4));
    final r3Jitter = r3.shift(const Offset(0.3, 0.3));

    canvas.drawRRect(r1Jitter, p2);
    canvas.drawRRect(r2Jitter, p2);
    canvas.drawRRect(r3Jitter, p2);

    canvas.drawRRect(r1, p1);
    canvas.drawRRect(r2, p1);
    canvas.drawRRect(r3, p1);
  }

  void _paintProfile(Canvas canvas, double w, double h, Paint p1, Paint p2) {
    // Head circle
    final headCenter = Offset(w * 0.50, h * 0.30);
    final headRadius = w * 0.18;

    // Body / shoulders arc
    final body = Path()
      ..moveTo(w * 0.16, h * 0.86)
      ..cubicTo(w * 0.16, h * 0.62, w * 0.34, h * 0.56, w * 0.42, h * 0.56)
      ..lineTo(w * 0.58, h * 0.56)
      ..cubicTo(w * 0.66, h * 0.56, w * 0.84, h * 0.62, w * 0.84, h * 0.86);

    final bodyJitter = Path()
      ..moveTo(w * 0.14, h * 0.87)
      ..cubicTo(w * 0.15, h * 0.61, w * 0.33, h * 0.55, w * 0.42, h * 0.55)
      ..lineTo(w * 0.58, h * 0.55)
      ..cubicTo(w * 0.67, h * 0.55, w * 0.86, h * 0.61, w * 0.86, h * 0.87);

    // Double contour on head circle
    canvas.drawCircle(headCenter.translate(0.4, -0.3), headRadius, p2);
    canvas.drawPath(bodyJitter, p2);

    canvas.drawCircle(headCenter, headRadius, p1);
    canvas.drawPath(body, p1);

    // Bottom baseline stroke matching ref_prof.png
    canvas.drawLine(
      Offset(w * 0.16, h * 0.86),
      Offset(w * 0.84, h * 0.86),
      p1,
    );
    canvas.drawLine(
      Offset(w * 0.14, h * 0.87),
      Offset(w * 0.86, h * 0.87),
      p2,
    );
  }

  void _paintStopwatch(Canvas canvas, double w, double h, Paint p1, Paint p2) {
    final dialCenter = Offset(w * 0.50, h * 0.55);
    final dialRadius = w * 0.31;

    // 1. Solid White Dial Silhouette
    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(dialCenter, dialRadius, whiteFill);

    // 2. Top Stem & Horizontal T-Bar Crown (12 o'clock)
    final stemRect = Rect.fromCenter(
      center: Offset(dialCenter.dx, dialCenter.dy - dialRadius - 2.8),
      width: w * 0.13,
      height: 5.5,
    );
    canvas.drawRect(stemRect, whiteFill);

    final crownRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(dialCenter.dx, dialCenter.dy - dialRadius - 6.2),
        width: w * 0.34,
        height: 3.4,
      ),
      const Radius.circular(1.6),
    );
    canvas.drawRRect(crownRect, whiteFill);

    // 3. Angled Pusher Button at 1:30 (~45 degrees)
    canvas.save();
    canvas.translate(dialCenter.dx, dialCenter.dy);
    canvas.rotate(0.72); // ~41 degrees
    final pusherRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -dialRadius - 3.8),
        width: w * 0.14,
        height: 4.2,
      ),
      const Radius.circular(1.2),
    );
    canvas.drawRRect(pusherRect, whiteFill);
    canvas.restore();

    // 4. Hand-Sketched Inner Pencil Outline inside the White Stopwatch
    final innerContour = Paint()
      ..color = const Color(0xFF1E1C1A).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(dialCenter, dialRadius - 1.2, innerContour);

    // 5. Vertical Indicator Hand Pointing Down (to 6 o'clock)
    final needlePaint = Paint()
      ..color = const Color(0xFF1E1C1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      dialCenter,
      Offset(dialCenter.dx, dialCenter.dy + (dialRadius * 0.65)),
      needlePaint,
    );

    // Center pivot dot
    final pivotPaint = Paint()
      ..color = const Color(0xFF1E1C1A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dialCenter, 2.4, pivotPaint);
  }

  void _paintPomodoro(Canvas canvas, double w, double h, Paint p1, Paint p2) {
    // 1. Tomato Upper Dome
    final dome = Path()
      ..moveTo(w * 0.16, h * 0.50)
      ..cubicTo(w * 0.16, h * 0.32, w * 0.32, h * 0.22, w * 0.50, h * 0.22)
      ..cubicTo(w * 0.68, h * 0.22, w * 0.84, h * 0.32, w * 0.84, h * 0.50);

    final domeJitter = Path()
      ..moveTo(w * 0.15, h * 0.51)
      ..cubicTo(w * 0.15, h * 0.31, w * 0.32, h * 0.21, w * 0.50, h * 0.21)
      ..cubicTo(w * 0.68, h * 0.21, w * 0.85, h * 0.31, w * 0.85, h * 0.51);

    // 2. Tomato Lower Base
    final base = Path()
      ..moveTo(w * 0.16, h * 0.52)
      ..cubicTo(w * 0.16, h * 0.74, w * 0.32, h * 0.86, w * 0.50, h * 0.86)
      ..cubicTo(w * 0.68, h * 0.86, w * 0.84, h * 0.74, w * 0.84, h * 0.52);

    final baseJitter = Path()
      ..moveTo(w * 0.17, h * 0.53)
      ..cubicTo(w * 0.17, h * 0.75, w * 0.32, h * 0.87, w * 0.50, h * 0.87)
      ..cubicTo(w * 0.68, h * 0.87, w * 0.83, h * 0.75, w * 0.83, h * 0.53);

    // 3. Equator Dial Split Line (gentle downward curve)
    final dialSplit = Path()
      ..moveTo(w * 0.16, h * 0.51)
      ..cubicTo(w * 0.34, h * 0.54, w * 0.66, h * 0.54, w * 0.84, h * 0.51);

    canvas.drawPath(domeJitter, p2);
    canvas.drawPath(baseJitter, p2);
    canvas.drawPath(dome, p1);
    canvas.drawPath(base, p1);
    canvas.drawPath(dialSplit, p1);

    // 4. Dial Calibration Ticks along equator
    final tickPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, strokeWidth * 0.75)
      ..strokeCap = StrokeCap.round;

    final tickCoords = [
      (0.22, 0.04),
      (0.26, 0.05),
      (0.30, 0.055),
      (0.35, 0.06),
      (0.40, 0.065),
      (0.45, 0.07),
      (0.50, 0.095), // Center primary tick (tallest)
      (0.55, 0.07),
      (0.60, 0.065),
      (0.65, 0.06),
      (0.70, 0.055),
      (0.74, 0.05),
      (0.78, 0.04),
    ];

    for (final tick in tickCoords) {
      final tx = w * tick.$1;
      final ty = (h * 0.51) + (h * 0.03 * math.sin(math.pi * (tick.$1 - 0.16) / 0.68));
      canvas.drawLine(
        Offset(tx, ty),
        Offset(tx, ty - (h * tick.$2)),
        tickPaint,
      );
    }

    // 5. Pointer Triangle on Lower Base below Center Tick
    final triTop = Offset(w * 0.50, h * 0.55);
    final triangle = Path()
      ..moveTo(triTop.dx, triTop.dy)
      ..lineTo(triTop.dx - (w * 0.04), triTop.dy + (h * 0.055))
      ..lineTo(triTop.dx + (w * 0.04), triTop.dy + (h * 0.055))
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(triangle, fillPaint);

    // 6. Calyx Leaves radiating from stem base (w*0.50, h*0.22)
    final calyxBase = Offset(w * 0.50, h * 0.22);
    final leaves = [
      Path()
        ..moveTo(calyxBase.dx, calyxBase.dy)
        ..cubicTo(w * 0.40, h * 0.19, w * 0.32, h * 0.24, w * 0.28, h * 0.28)
        ..cubicTo(w * 0.35, h * 0.27, w * 0.44, h * 0.24, calyxBase.dx, calyxBase.dy),
      Path()
        ..moveTo(calyxBase.dx, calyxBase.dy)
        ..cubicTo(w * 0.44, h * 0.16, w * 0.42, h * 0.12, w * 0.40, h * 0.09)
        ..cubicTo(w * 0.46, h * 0.13, calyxBase.dx, calyxBase.dy - 2, calyxBase.dx, calyxBase.dy),
      Path()
        ..moveTo(calyxBase.dx, calyxBase.dy)
        ..cubicTo(w * 0.54, h * 0.16, w * 0.58, h * 0.12, w * 0.60, h * 0.09)
        ..cubicTo(w * 0.54, h * 0.13, calyxBase.dx, calyxBase.dy - 2, calyxBase.dx, calyxBase.dy),
      Path()
        ..moveTo(calyxBase.dx, calyxBase.dy)
        ..cubicTo(w * 0.60, h * 0.19, w * 0.68, h * 0.24, w * 0.72, h * 0.28)
        ..cubicTo(w * 0.65, h * 0.27, w * 0.56, h * 0.24, calyxBase.dx, calyxBase.dy),
    ];
    for (final leaf in leaves) {
      canvas.drawPath(leaf, p1);
      canvas.drawPath(leaf, fillPaint);
    }

    // 7. Curved Tomato Stem
    final stem = Path()
      ..moveTo(calyxBase.dx - 1.2, calyxBase.dy)
      ..cubicTo(calyxBase.dx - 1.0, h * 0.14, calyxBase.dx + 2.0, h * 0.08, calyxBase.dx + 4.0, h * 0.04)
      ..lineTo(calyxBase.dx + 7.0, h * 0.05)
      ..cubicTo(calyxBase.dx + 4.5, h * 0.09, calyxBase.dx + 1.8, h * 0.15, calyxBase.dx + 1.2, calyxBase.dy)
      ..close();
    canvas.drawPath(stem, fillPaint);

    // 8. Curved Hatch Shading on lower right
    final hatchPaint = Paint()
      ..color = color.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, strokeWidth * 0.55)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.62, h * 0.68), Offset(w * 0.72, h * 0.60), hatchPaint);
    canvas.drawLine(Offset(w * 0.58, h * 0.74), Offset(w * 0.70, h * 0.66), hatchPaint);
    canvas.drawLine(Offset(w * 0.52, h * 0.79), Offset(w * 0.66, h * 0.72), hatchPaint);
    canvas.drawLine(Offset(w * 0.44, h * 0.83), Offset(w * 0.58, h * 0.78), hatchPaint);
  }

  @override
  bool shouldRepaint(covariant _SketchNavIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
