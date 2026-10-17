import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// An organic, tactiley animated indicator pill that stretches elastically
/// in the direction of travel like liquid ink, then snaps into the target slot
/// with an organic overshoot bounce.
class ElasticInkPill extends StatefulWidget {
  final Rect targetRect;
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final double borderRadius;
  final Duration duration;
  final Curve curve;
  final bool isSketchy;
  final Widget? child;

  const ElasticInkPill({
    super.key,
    required this.targetRect,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.4,
    this.borderRadius = 16.0,
    this.duration = const Duration(milliseconds: 320),
    this.curve = const Cubic(0.175, 0.885, 0.32, 1.275),
    this.isSketchy = true,
    this.child,
  });

  @override
  State<ElasticInkPill> createState() => _ElasticInkPillState();
}

class _ElasticInkPillState extends State<ElasticInkPill>
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
  void didUpdateWidget(covariant ElasticInkPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetRect != widget.targetRect) {
      if (_controller.isAnimating && _renderedRect != null) {
        // Interrupted flight: reset from current center with target dimensions
        // to prevent accumulated stretch distortion.
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
    final dy = _toRect.center.dy - _fromRect.center.dy;
    final linearProgress = _controller.value;
    // Bell curve factor reaching maximum around midway through the flight
    final stretchEnvelope = math.sin(linearProgress * math.pi);

    // Maximum stretch up to 25% of movement delta or 22px
    final maxStretchX = (dx.abs() * 0.25).clamp(0.0, 22.0);
    final maxStretchY = (dy.abs() * 0.25).clamp(0.0, 22.0);
    final stretchAmountX = stretchEnvelope * maxStretchX;
    final stretchAmountY = stretchEnvelope * maxStretchY;

    final leftLerp = _fromRect.left + (_toRect.left - _fromRect.left) * t;
    final rightLerp = _fromRect.right + (_toRect.right - _fromRect.right) * t;
    final topLerp = _fromRect.top + (_toRect.top - _fromRect.top) * t;
    final bottomLerp =
        _fromRect.bottom + (_toRect.bottom - _fromRect.bottom) * t;

    double left = leftLerp;
    double right = rightLerp;
    double top = topLerp;
    double bottom = bottomLerp;

    if (dx > 0) {
      // Traveling right: leading right edge leaps forward, left trailing edge lags
      right += stretchAmountX;
      left -= (stretchAmountX * 0.2);
    } else if (dx < 0) {
      // Traveling left: leading left edge leaps forward, right trailing edge lags
      left -= stretchAmountX;
      right += (stretchAmountX * 0.2);
    }

    if (dy > 0) {
      // Traveling down: leading bottom edge leaps forward, top lags
      bottom += stretchAmountY;
      top -= (stretchAmountY * 0.2);
    } else if (dy < 0) {
      // Traveling up: leading top edge leaps forward, bottom lags
      top -= stretchAmountY;
      bottom += (stretchAmountY * 0.2);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentRect = _controller.isAnimating
            ? _calculateIntermediateRect(_animation.value)
            : _toRect;
        _renderedRect = currentRect;

        final effectiveFill = widget.fillColor ??
            AppTheme.primaryBlue.withValues(alpha: 0.12);
        final effectiveStroke =
            widget.strokeColor ?? AppTheme.primaryBlue;

        final paintWidth = math.max(0.0, currentRect.right);
        final paintHeight = math.max(0.0, currentRect.bottom);

        return CustomPaint(
          size: Size(paintWidth, paintHeight),
          painter: _ElasticInkPillPainter(
            rect: currentRect,
            fillColor: effectiveFill,
            strokeColor: effectiveStroke,
            strokeWidth: widget.strokeWidth,
            borderRadius: widget.borderRadius,
            isSketchy: widget.isSketchy,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ElasticInkPillPainter extends CustomPainter {
  final Rect rect;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double borderRadius;
  final bool isSketchy;

  const _ElasticInkPillPainter({
    required this.rect,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.borderRadius,
    required this.isSketchy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rect.isEmpty || rect.width <= 0 || rect.height <= 0) return;

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // 1. Fill tint wash
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // 2. Primary clean ink stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(rrect, strokePaint);

    // 3. Hand-drawn sketchy secondary contour overlay (subtle ink bleed / jitter)
    if (isSketchy) {
      final secondaryPaint = Paint()
        ..color = strokeColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (strokeWidth * 0.75).clamp(0.6, 1.2)
        ..strokeCap = StrokeCap.round;

      final sketchyRect = rect.shift(const Offset(0.6, -0.4));
      final sketchyRRect = RRect.fromRectAndRadius(
        sketchyRect,
        Radius.circular(borderRadius + 0.5),
      );
      canvas.drawRRect(sketchyRRect, secondaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ElasticInkPillPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isSketchy != isSketchy;
  }
}
