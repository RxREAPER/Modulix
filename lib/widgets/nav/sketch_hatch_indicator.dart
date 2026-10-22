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

    final double left = _fromRect.left + (_toRect.left - _fromRect.left) * t;
    final double right = _fromRect.right + (_toRect.right - _fromRect.right) * t;
    final double top = _fromRect.top + (_toRect.top - _fromRect.top) * t;
    final double bottom = _fromRect.bottom + (_toRect.bottom - _fromRect.bottom) * t;

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

    // 1. Soft accent wash fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // 2. Subtle crisp boundary stroke
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ModernPillIndicatorPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
