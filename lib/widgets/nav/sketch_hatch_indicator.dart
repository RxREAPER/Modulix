import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A sleek, modern fluid indicator that glides smoothly between navigation slots.
/// Refined with professional cubic easing, subtle theme-adaptive tinting,
/// and clean pill geometry without jiggle or wobble.
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
    this.borderRadius = 22.0,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.fastOutSlowIn,
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
      _fromRect = _renderedRect ?? oldWidget.targetRect;
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

    final double fromCenterX = _fromRect.center.dx;
    final double toCenterX = _toRect.center.dx;
    final double currentCenterX = fromCenterX + (toCenterX - fromCenterX) * t;

    // Fluid momentum stretch during transit:
    // Expands pill width by up to 15% at peak velocity, creating organic liquid glass droplet feel
    final double distance = (toCenterX - fromCenterX).abs();
    final double stretch = math.sin(t * math.pi) * math.min(distance * 0.12, 8.0);

    final double width = _toRect.width + stretch;
    final double height = _toRect.height;
    final double top = _fromRect.top + (_toRect.top - _fromRect.top) * t;

    return Rect.fromCenter(
      center: Offset(currentCenterX, top + (height / 2)),
      width: width,
      height: height,
    );
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

        return RepaintBoundary(
          child: CustomPaint(
            size: Size(paintWidth, paintHeight),
            painter: _ModernPillIndicatorPainter(
              rect: currentRect,
              color: effectiveColor,
              borderRadius: widget.borderRadius,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ModernPillIndicatorPainter extends CustomPainter {
  final Rect rect;
  final Color color;
  final double borderRadius;

  const _ModernPillIndicatorPainter({
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

    // 1. Soft liquid glass wash fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // 2. Subtle crisp boundary stroke with glass specular accent
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, strokePaint);

    // 3. Top-edge glass specular reflection highlight
    final highlightPath = Path()
      ..moveTo(rect.left + borderRadius, rect.top + 0.5)
      ..lineTo(rect.right - borderRadius, rect.top + 0.5);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _ModernPillIndicatorPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
