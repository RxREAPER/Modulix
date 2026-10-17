import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A tactile vector path-drawn checkmark with an elastic spring pop.
/// Draws an authentic ink checkmark from 0% to 100% path length, accompanied
/// by an organic scale overshoot bounce.
class AnimatedCheckStroke extends StatefulWidget {
  final bool checked;
  final double size;
  final Color? color;
  final double strokeWidth;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onCompleted;

  const AnimatedCheckStroke({
    super.key,
    required this.checked,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.4,
    this.duration = const Duration(milliseconds: 320),
    this.curve = const Cubic(0.175, 0.885, 0.32, 1.275),
    this.onCompleted,
  });

  @override
  State<AnimatedCheckStroke> createState() => _AnimatedCheckStrokeState();
}

class _AnimatedCheckStrokeState extends State<AnimatedCheckStroke>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _strokeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.checked ? 1.0 : 0.0,
    );

    _strokeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 1.16)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.16, end: 1.0)
            .chain(CurveTween(curve: const Cubic(0.175, 0.885, 0.32, 1.275))),
        weight: 35,
      ),
    ]).animate(_controller);

    if (widget.checked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCheckStroke oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.checked != widget.checked) {
      if (widget.checked) {
        _controller.forward(from: 0.0).then((_) {
          if (mounted && _controller.status == AnimationStatus.completed) {
            widget.onCompleted?.call();
          }
        });
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppTheme.accentEmerald;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value == 0.0) {
          return SizedBox(width: widget.size, height: widget.size);
        }

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CheckStrokePainter(
              progress: _strokeAnimation.value.clamp(0.0, 1.0),
              color: effectiveColor,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _CheckStrokePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _CheckStrokePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || size.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Normal checkmark coordinate points:
    // P1: Start of short stroke down
    // P2: Vertex / turnaround point
    // P3: End of long stroke up
    final p1 = Offset(w * 0.22, h * 0.52);
    final p2 = Offset(w * 0.42, h * 0.74);
    final p3 = Offset(w * 0.80, h * 0.28);

    final len1 = (p2 - p1).distance;
    final len2 = (p3 - p2).distance;
    final totalLen = len1 + len2;

    final currentLen = totalLen * progress;

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    if (currentLen <= len1) {
      final t1 = currentLen / len1;
      final curPt = Offset(
        p1.dx + (p2.dx - p1.dx) * t1,
        p1.dy + (p2.dy - p1.dy) * t1,
      );
      path.lineTo(curPt.dx, curPt.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t2 = (currentLen - len1) / len2;
      final curPt = Offset(
        p2.dx + (p3.dx - p2.dx) * t2,
        p2.dy + (p3.dy - p2.dy) * t2,
      );
      path.lineTo(curPt.dx, curPt.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckStrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
