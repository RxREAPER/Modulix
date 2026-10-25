import 'package:flutter/material.dart';

enum SketchNavIconType {
  home,
  curriculum,
  library,
  analytics,
  progress,
  tasks,
  profile,
  stopwatch,
  focus,
  pomodoro,
}

/// A modern minimalist line-art vector icon faithfully reproducing the
/// reference design (House, Books, Hourglass, Trophy, Profile, Checklist).
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
    this.strokeWidth = 1.8,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ModernNavIconPainter(
        type: type,
        color: color,
        isSelected: isSelected,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _ModernNavIconPainter extends CustomPainter {
  final SketchNavIconType type;
  final Color color;
  final bool isSelected;
  final double strokeWidth;

  const _ModernNavIconPainter({
    required this.type,
    required this.color,
    required this.isSelected,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case SketchNavIconType.home:
        _paintHome(canvas, w, h, p);
        break;
      case SketchNavIconType.curriculum:
      case SketchNavIconType.library:
        _paintLibrary(canvas, w, h, p);
        break;
      case SketchNavIconType.stopwatch:
      case SketchNavIconType.focus:
      case SketchNavIconType.pomodoro:
        _paintFocus(canvas, w, h, p);
        break;
      case SketchNavIconType.analytics:
      case SketchNavIconType.progress:
        _paintProgress(canvas, w, h, p);
        break;
      case SketchNavIconType.profile:
        _paintProfile(canvas, w, h, p);
        break;
      case SketchNavIconType.tasks:
        _paintTasks(canvas, w, h, p);
        break;
    }
  }

  // ── 0. Tasks / Checklist (Clipboard frame with clip and checks) ─────────────
  void _paintTasks(Canvas canvas, double w, double h, Paint p) {
    // Outer clipboard frame
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.16, w * 0.60, h * 0.70),
      const Radius.circular(3.0),
    );
    canvas.drawRRect(rect, p);

    // Top clip
    final clip = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.36, h * 0.10, w * 0.28, h * 0.10),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(clip, p);

    // Check item 1
    final check1 = Path()
      ..moveTo(w * 0.30, h * 0.40)
      ..lineTo(w * 0.38, h * 0.48)
      ..lineTo(w * 0.50, h * 0.34);
    canvas.drawPath(check1, p);
    canvas.drawLine(Offset(w * 0.56, h * 0.41), Offset(w * 0.70, h * 0.41), p);

    // Check item 2
    final check2 = Path()
      ..moveTo(w * 0.30, h * 0.62)
      ..lineTo(w * 0.38, h * 0.70)
      ..lineTo(w * 0.50, h * 0.56);
    canvas.drawPath(check2, p);
    canvas.drawLine(Offset(w * 0.56, h * 0.63), Offset(w * 0.70, h * 0.63), p);
  }

  // ── 1. Home (Pitched roof house with doorway) ───────────────────────────────
  void _paintHome(Canvas canvas, double w, double h, Paint p) {
    // Gable Roof
    final roof = Path()
      ..moveTo(w * 0.12, h * 0.46)
      ..lineTo(w * 0.50, h * 0.14)
      ..lineTo(w * 0.88, h * 0.46);
    canvas.drawPath(roof, p);

    // Walls & Arch Doorway
    final body = Path()
      ..moveTo(w * 0.22, h * 0.46)
      ..lineTo(w * 0.22, h * 0.86)
      ..lineTo(w * 0.40, h * 0.86)
      ..lineTo(w * 0.40, h * 0.58)
      ..cubicTo(w * 0.40, h * 0.52, w * 0.60, h * 0.52, w * 0.60, h * 0.58)
      ..lineTo(w * 0.60, h * 0.86)
      ..lineTo(w * 0.78, h * 0.86)
      ..lineTo(w * 0.78, h * 0.46);
    canvas.drawPath(body, p);
  }

  // ── 2. Library (Clean books: 2 upright standing, 1 tilted leaning) ──────────
  void _paintLibrary(Canvas canvas, double w, double h, Paint p) {
    // Book 1 (Left upright book)
    final book1 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.15, h * 0.26, w * 0.33, h * 0.85),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(book1, p);
    // Vertical bookmark ribbon hanging down from top of book 1
    canvas.drawLine(
      Offset(w * 0.24, h * 0.26),
      Offset(w * 0.24, h * 0.44),
      p,
    );

    // Book 2 (Middle upright book, taller)
    final book2 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.35, h * 0.16, w * 0.53, h * 0.85),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(book2, p);
    // Single clean horizontal spine band on book 2
    canvas.drawLine(
      Offset(w * 0.35, h * 0.32),
      Offset(w * 0.53, h * 0.32),
      p,
    );

    // Book 3 (Right book tilted leaning to the right ~14 degrees)
    canvas.save();
    canvas.translate(w * 0.55, h * 0.85);
    canvas.rotate(0.24); // lean angle
    const leaningHeightRatio = 0.62;
    const leaningWidthRatio = 0.17;
    final book3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, -h * leaningHeightRatio, w * leaningWidthRatio, h * leaningHeightRatio),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(book3, p);
    // Clean spine band on leaning book
    canvas.drawLine(
      Offset(0, -h * 0.44),
      Offset(w * leaningWidthRatio, -h * 0.44),
      p,
    );
    canvas.restore();
  }

  // ── 3. Focus (Hourglass with top/bottom bars and falling sand stream) ────────
  void _paintFocus(Canvas canvas, double w, double h, Paint p) {
    // Top and Bottom Horizontal Caps
    final topBar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.16),
        width: w * 0.58,
        height: h * 0.06,
      ),
      const Radius.circular(1.5),
    );
    final bottomBar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.84),
        width: w * 0.58,
        height: h * 0.06,
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(topBar, p);
    canvas.drawRRect(bottomBar, p);

    // Hourglass Glass Contour
    final glass = Path();
    glass.moveTo(w * 0.28, h * 0.19);
    glass.cubicTo(w * 0.29, h * 0.35, w * 0.44, h * 0.46, w * 0.45, h * 0.50);
    glass.cubicTo(w * 0.44, h * 0.54, w * 0.29, h * 0.65, w * 0.28, h * 0.81);
    glass.moveTo(w * 0.72, h * 0.19);
    glass.cubicTo(w * 0.71, h * 0.35, w * 0.56, h * 0.46, w * 0.55, h * 0.50);
    glass.cubicTo(w * 0.56, h * 0.54, w * 0.71, h * 0.65, w * 0.72, h * 0.81);
    canvas.drawPath(glass, p);

    // Upper Sand Reservoir
    final upperSand = Path()
      ..moveTo(w * 0.34, h * 0.31)
      ..lineTo(w * 0.66, h * 0.31)
      ..lineTo(w * 0.50, h * 0.45)
      ..close();
    canvas.drawPath(upperSand, p);

    // Falling Sand Stream
    canvas.drawLine(
      Offset(w * 0.50, h * 0.48),
      Offset(w * 0.50, h * 0.58),
      p,
    );

    // Lower Sand Mound
    final lowerSand = Path()
      ..moveTo(w * 0.33, h * 0.80)
      ..cubicTo(w * 0.38, h * 0.70, w * 0.62, h * 0.70, w * 0.67, h * 0.80);
    canvas.drawPath(lowerSand, p);
  }

  // ── 4. Progress (Ascending 3-Bar Analytics Chart with Trend Curve) ───────────
  void _paintProgress(Canvas canvas, double w, double h, Paint p) {
    // Horizontal baseline
    canvas.drawLine(
      Offset(w * 0.14, h * 0.85),
      Offset(w * 0.86, h * 0.85),
      p,
    );

    // Bar 1 (Left - 35% height)
    final bar1 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.18, h * 0.54, w * 0.34, h * 0.85),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(bar1, p);

    // Bar 2 (Middle - 60% height)
    final bar2 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.42, h * 0.36, w * 0.58, h * 0.85),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(bar2, p);

    // Bar 3 (Right - 85% height)
    final bar3 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.66, h * 0.18, w * 0.82, h * 0.85),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(bar3, p);

    // Upward trend spark accent above Bar 3
    final spark = Path()
      ..moveTo(w * 0.74, h * 0.12)
      ..lineTo(w * 0.82, h * 0.06)
      ..lineTo(w * 0.82, h * 0.14);
    canvas.drawPath(spark, p);
  }

  // ── 5. Profile (Minimalist Head and Shoulder Bust Outline) ───────────────────
  void _paintProfile(Canvas canvas, double w, double h, Paint p) {
    // Head Circle
    canvas.drawCircle(Offset(w * 0.50, h * 0.30), w * 0.17, p);

    // Torso / Shoulder Arc with smooth rounded baseline
    final body = Path()
      ..moveTo(w * 0.18, h * 0.84)
      ..cubicTo(w * 0.18, h * 0.62, w * 0.34, h * 0.54, w * 0.50, h * 0.54)
      ..cubicTo(w * 0.66, h * 0.54, w * 0.82, h * 0.62, w * 0.82, h * 0.84)
      ..close();
    canvas.drawPath(body, p);
  }

  @override
  bool shouldRepaint(covariant _ModernNavIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
