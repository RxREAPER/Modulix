import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A fluid, tactiley animated colored-pencil / crayon hatch indicator.
/// Glides between tab targets with an elastic stretch envelope, and renders
/// an authentic hand-sketched squircle with diagonal crayon hatching.
class SketchHatchIndicator extends StatefulWidget {
  final Rect targetRect;
  final Color? hatchColor;
  final double borderRadius;
  final Duration duration;
  final Curve curve;
  final Widget? child;

  const SketchHatchIndicator({
    super.key,
    required this.targetRect,
    this.hatchColor,
    this.borderRadius = 16.0,
    this.duration = const Duration(milliseconds: 320),
    this.curve = const Cubic(0.175, 0.885, 0.32, 1.275),
    this.child,
  });

  @override
  State<SketchHatchIndicator> createState() => _SketchHatchIndicatorState();
}

class _SketchHatchIndicatorState extends State<SketchHatchIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late Rect _fromRect;
  late Rect _toRect;
  Rect? _renderedRect;

  @override
  void initState() {
    super.initState();
    _fromRect = widget.targetRect;
    _toRect = widget.targetRect;
    _renderedRect = widget.targetRect;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(covariant SketchHatchIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetRect != widget.targetRect) {
      if (_controller.isAnimating && _renderedRect != null) {
        _fromRect = Rect.fromCenter(
          center: _renderedRect!.center,
          width: widget.targetRect.width,
          height: widget.targetRect.height,
        );
      } else {
        _fromRect = _renderedRect ?? oldWidget.targetRect;
      }
      _toRect = widget.targetRect;
      _controller.duration = widget.duration;
      _animation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Rect _calculateIntermediateRect(double t) {
    if (_fromRect == _toRect || (t >= 1.0 && !_controller.isAnimating)) {
      return _toRect;
    }

    final dx = _toRect.center.dx - _fromRect.center.dx;
    final linearProgress = _controller.value;

    // Organic stretch envelope peaking midway during transition
    final stretchEnvelope = math.sin(linearProgress * math.pi);
    final maxStretchX = (dx.abs() * 0.22).clamp(0.0, 20.0);
    final stretchAmountX = stretchEnvelope * maxStretchX;

    double left = _fromRect.left + (_toRect.left - _fromRect.left) * t;
    double right = _fromRect.right + (_toRect.right - _fromRect.right) * t;
    final top = _fromRect.top + (_toRect.top - _fromRect.top) * t;
    final bottom = _fromRect.bottom + (_toRect.bottom - _fromRect.bottom) * t;

    if (dx > 0) {
      right += stretchAmountX;
      left -= (stretchAmountX * 0.2);
    } else if (dx < 0) {
      left -= stretchAmountX;
      right += (stretchAmountX * 0.2);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.hatchColor ?? const Color(0xFFF43F5E);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentRect = _controller.isAnimating
            ? _calculateIntermediateRect(_animation.value)
            : _toRect;
        _renderedRect = currentRect;

        final paintWidth = math.max(0.0, currentRect.right + 20);
        final paintHeight = math.max(0.0, currentRect.bottom + 20);

        return CustomPaint(
          size: Size(paintWidth, paintHeight),
          painter: _SketchHatchPainter(
            rect: currentRect,
            color: effectiveColor,
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SketchHatchPainter extends CustomPainter {
  final Rect rect;
  final Color color;
  final double borderRadius;

  const _SketchHatchPainter({
    required this.rect,
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rect.isEmpty || rect.width <= 0 || rect.height <= 0) return;

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // 1. Soft crayon wash fill
    final washPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, washPaint);

    // 2. Diagonal crayon / colored pencil hatching inside the squircle
    canvas.save();
    canvas.clipRRect(rrect);

    const hatchSpacing = 5.2;
    final diagonalCount =
        ((rect.width + rect.height) / hatchSpacing).ceil() + 2;

    final hatchPaint1 = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    final hatchPaint2 = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95
      ..strokeCap = StrokeCap.round;

    final startX = rect.left - rect.height;
    for (int i = 0; i < diagonalCount; i++) {
      final x = startX + (i * hatchSpacing);
      final p1 = Offset(x, rect.bottom + 6);
      final p2 = Offset(x + rect.height + 8, rect.top - 6);

      // Alternate stroke pressure for authentic hand-drawn crayon texture
      final p = (i % 2 == 0) ? hatchPaint1 : hatchPaint2;
      canvas.drawLine(p1, p2, p);
    }
    canvas.restore();

    // 3. Multi-pass hand-sketched squircle contour
    final primaryOutline = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final secondaryOutline = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tertiaryOutline = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Layer 1: Base hand-drawn rounded capsule contour
    canvas.drawRRect(rrect, primaryOutline);

    // Layer 2: Offset jitter stroke
    final jitterRRect1 = RRect.fromRectAndRadius(
      rect.shift(const Offset(0.8, -0.6)),
      Radius.circular(borderRadius + 0.5),
    );
    canvas.drawRRect(jitterRRect1, secondaryOutline);

    // Layer 3: Counter-jitter stroke for pencil density
    final jitterRRect2 = RRect.fromRectAndRadius(
      rect.shift(const Offset(-0.6, 0.7)),
      Radius.circular(borderRadius - 0.4),
    );
    canvas.drawRRect(jitterRRect2, tertiaryOutline);

    // Layer 4: Authentic sketchbook pencil corner overshoots & loops (matching ref_pill.png)
    final cornerTailPaint = Paint()
      ..color = color.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    // Top-left corner overshoot tick & loop
    canvas.drawLine(
      Offset(rect.left + borderRadius * 0.40, rect.top - 1.0),
      Offset(rect.left - 3.2, rect.top + borderRadius * 0.45),
      cornerTailPaint,
    );
    // Top-right corner overshoot tick
    canvas.drawLine(
      Offset(rect.right - borderRadius * 0.45, rect.top - 1.4),
      Offset(rect.right + 3.4, rect.top + borderRadius * 0.40),
      cornerTailPaint,
    );
    // Bottom-left corner overshoot tick
    canvas.drawLine(
      Offset(rect.left - 2.8, rect.bottom - borderRadius * 0.40),
      Offset(rect.left + borderRadius * 0.45, rect.bottom + 2.8),
      cornerTailPaint,
    );
    // Bottom-right corner overshoot tick
    canvas.drawLine(
      Offset(rect.right - borderRadius * 0.45, rect.bottom + 2.8),
      Offset(rect.right + 3.2, rect.bottom - borderRadius * 0.35),
      cornerTailPaint,
    );

    // Subtle edge pencil contour passes (matching ref_pill.png)
    final edgePaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(rect.left + borderRadius * 0.6, rect.top - 0.7),
      Offset(rect.right - borderRadius * 0.6, rect.top + 0.5),
      edgePaint,
    );
    canvas.drawLine(
      Offset(rect.left + borderRadius * 0.5, rect.bottom + 0.8),
      Offset(rect.right - borderRadius * 0.5, rect.bottom - 0.6),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SketchHatchPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
