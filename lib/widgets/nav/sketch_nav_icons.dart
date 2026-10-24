import 'dart:math' as math;
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
    if (type == SketchNavIconType.tasks) {
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

    final assetPath = switch (type) {
      SketchNavIconType.home => 'assets/icons/navbar/nav_home.png',
      SketchNavIconType.library || SketchNavIconType.curriculum => 'assets/icons/navbar/nav_library.png',
      SketchNavIconType.focus || SketchNavIconType.stopwatch || SketchNavIconType.pomodoro => 'assets/icons/navbar/nav_timer.png',
      SketchNavIconType.progress || SketchNavIconType.analytics => 'assets/icons/navbar/nav_progress.png',
      SketchNavIconType.profile => 'assets/icons/navbar/nav_profile.png',
      SketchNavIconType.tasks => '',
    };

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        color: color,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            painter: _ModernNavIconPainter(
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

  // ── 0. Tasks / Checklist (Clipboard/Checklist with checks) ───────────────────
  void _paintTasks(Canvas canvas, double w, double h, Paint p) {
    // Outer card/clipboard frame with rounded corners
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.14, w * 0.64, h * 0.74),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(rect, p);

    // Top clip
    canvas.drawLine(
      Offset(w * 0.36, h * 0.14),
      Offset(w * 0.64, h * 0.14),
      p..strokeWidth = strokeWidth * 1.4,
    );
    p.strokeWidth = strokeWidth;

    // Check item 1
    final check1 = Path()
      ..moveTo(w * 0.28, h * 0.38)
      ..lineTo(w * 0.35, h * 0.44)
      ..lineTo(w * 0.48, h * 0.32);
    canvas.drawPath(check1, p);
    canvas.drawLine(Offset(w * 0.54, h * 0.38), Offset(w * 0.72, h * 0.38), p);

    // Check item 2
    final check2 = Path()
      ..moveTo(w * 0.28, h * 0.58)
      ..lineTo(w * 0.35, h * 0.64)
      ..lineTo(w * 0.48, h * 0.52);
    canvas.drawPath(check2, p);
    canvas.drawLine(Offset(w * 0.54, h * 0.58), Offset(w * 0.72, h * 0.58), p);

    // Line 3
    canvas.drawLine(Offset(w * 0.28, h * 0.75), Offset(w * 0.72, h * 0.75), p);
  }

  // ── 1. Home (House with pitched roof, eaves, and doorway) ───────────────────
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

  // ── 2. Library (Books: 2 standing vertical, 1 leaning tilted right) ────────
  void _paintLibrary(Canvas canvas, double w, double h, Paint p) {
    // Book 1 (Left upright book)
    final book1 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.14, h * 0.26, w * 0.31, h * 0.84),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(book1, p);
    // Bookmark rectangle on book 1
    final marker = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.36, w * 0.08, h * 0.08),
      const Radius.circular(1.0),
    );
    canvas.drawRRect(marker, p);

    // Book 2 (Middle upright book, slightly taller)
    final book2 = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.31, h * 0.18, w * 0.49, h * 0.84),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(book2, p);
    // Spine horizontal stripes on book 2
    canvas.drawLine(Offset(w * 0.31, h * 0.27), Offset(w * 0.49, h * 0.27), p);
    canvas.drawLine(Offset(w * 0.31, h * 0.32), Offset(w * 0.49, h * 0.32), p);
    canvas.drawLine(Offset(w * 0.31, h * 0.70), Offset(w * 0.49, h * 0.70), p);
    canvas.drawLine(Offset(w * 0.31, h * 0.75), Offset(w * 0.49, h * 0.75), p);

    // Book 3 (Right book tilted leaning to the right)
    canvas.save();
    canvas.translate(w * 0.50, h * 0.84);
    canvas.rotate(0.25); // ~14.5 degrees lean
    final leaningHeight = h * 0.62;
    const leaningWidth = 0.17;
    final book3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, -leaningHeight, w * leaningWidth, leaningHeight),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(book3, p);
    // Stripes on leaning book
    canvas.drawLine(
      Offset(0, -leaningHeight + (h * 0.09)),
      Offset(w * leaningWidth, -leaningHeight + (h * 0.09)),
      p,
    );
    canvas.drawLine(
      Offset(0, -leaningHeight + (h * 0.14)),
      Offset(w * leaningWidth, -leaningHeight + (h * 0.14)),
      p,
    );
    canvas.drawLine(
      Offset(0, -(h * 0.14)),
      Offset(w * leaningWidth, -(h * 0.14)),
      p,
    );
    canvas.drawLine(
      Offset(0, -(h * 0.09)),
      Offset(w * leaningWidth, -(h * 0.09)),
      p,
    );
    canvas.restore();
  }

  // ── 3. Focus (Hourglass with top/bottom bars and falling sand) ───────────────
  void _paintFocus(Canvas canvas, double w, double h, Paint p) {
    // Top and Bottom Horizontal Caps
    final topBar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.17),
        width: w * 0.60,
        height: h * 0.065,
      ),
      const Radius.circular(2.0),
    );
    final bottomBar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.83),
        width: w * 0.60,
        height: h * 0.065,
      ),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(topBar, p);
    canvas.drawRRect(bottomBar, p);

    // Hourglass Glass Contour
    final glass = Path();
    // Left profile
    glass.moveTo(w * 0.28, h * 0.20);
    glass.cubicTo(w * 0.29, h * 0.36, w * 0.44, h * 0.46, w * 0.45, h * 0.50);
    glass.cubicTo(w * 0.44, h * 0.54, w * 0.29, h * 0.64, w * 0.28, h * 0.80);
    // Right profile
    glass.moveTo(w * 0.72, h * 0.20);
    glass.cubicTo(w * 0.71, h * 0.36, w * 0.56, h * 0.46, w * 0.55, h * 0.50);
    glass.cubicTo(w * 0.56, h * 0.54, w * 0.71, h * 0.64, w * 0.72, h * 0.80);
    canvas.drawPath(glass, p);

    // Upper Sand Reservoir
    final upperSand = Path()
      ..moveTo(w * 0.33, h * 0.31)
      ..lineTo(w * 0.67, h * 0.31)
      ..lineTo(w * 0.50, h * 0.46)
      ..close();
    canvas.drawPath(upperSand, p);

    // Falling Sand Stream
    canvas.drawLine(
      Offset(w * 0.50, h * 0.49),
      Offset(w * 0.50, h * 0.60),
      p,
    );

    // Lower Sand Mound
    final lowerSand = Path()
      ..moveTo(w * 0.32, h * 0.79)
      ..cubicTo(w * 0.37, h * 0.68, w * 0.63, h * 0.68, w * 0.68, h * 0.79);
    canvas.drawPath(lowerSand, p);
  }

  // ── 4. Progress (Badge Medallion with Star and Ribbon Tails from 004-badge.png)
  void _paintProgress(Canvas canvas, double w, double h, Paint p) {
    // Left Ribbon Tail
    final leftRibbon = Path()
      ..moveTo(w * 0.32, h * 0.52)
      ..lineTo(w * 0.18, h * 0.86)
      ..lineTo(w * 0.32, h * 0.76) // V-notch center
      ..lineTo(w * 0.44, h * 0.86)
      ..lineTo(w * 0.43, h * 0.60);
    canvas.drawPath(leftRibbon, p);

    // Right Ribbon Tail
    final rightRibbon = Path()
      ..moveTo(w * 0.68, h * 0.52)
      ..lineTo(w * 0.82, h * 0.86)
      ..lineTo(w * 0.68, h * 0.76) // V-notch center
      ..lineTo(w * 0.56, h * 0.86)
      ..lineTo(w * 0.57, h * 0.60);
    canvas.drawPath(rightRibbon, p);

    // Medallion Circle
    final center = Offset(w * 0.50, h * 0.38);
    final radius = w * 0.26;
    canvas.drawCircle(center, radius, p);

    // 5-Pointed Star in Center of Medallion
    final star = Path();
    final cx = center.dx;
    final cy = center.dy;
    final rOuter = w * 0.125;
    final rInner = w * 0.055;
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? rOuter : rInner;
      final angle = (i * 36 - 90) * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    canvas.drawPath(star, p);
  }

  // ── 5. Profile (Minimalist Head and Shoulder Bust Outline) ───────────────────
  void _paintProfile(Canvas canvas, double w, double h, Paint p) {
    // Head Circle
    canvas.drawCircle(Offset(w * 0.50, h * 0.30), w * 0.17, p);

    // Torso / Shoulder Arc with smooth rounded baseline
    final body = Path()
      ..moveTo(w * 0.16, h * 0.84)
      ..cubicTo(w * 0.16, h * 0.60, w * 0.34, h * 0.54, w * 0.50, h * 0.54)
      ..cubicTo(w * 0.66, h * 0.54, w * 0.84, h * 0.60, w * 0.84, h * 0.84)
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
