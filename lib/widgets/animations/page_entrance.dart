import 'package:flutter/material.dart';

/// Lightweight staggered entrance animation for page content.
///
/// Uses a SINGLE [AnimationController] with [Interval] curves to drive
/// all children — no per-child controllers, no physics engine.
/// Runs once on mount, auto-disposes. GPU-composited (opacity + transform only).
class PageEntrance extends StatefulWidget {
  final List<Widget> children;

  /// Delay between each child's animation start (ms). Keep ≤ 60ms for snappiness.
  final int staggerMs;

  /// Total duration of the entire stagger sequence.
  final int durationMs;

  /// Y-axis slide distance in logical pixels (children slide up from this offset).
  final double slideY;

  const PageEntrance({
    super.key,
    required this.children,
    this.staggerMs = 28,
    this.durationMs = 220,
    this.slideY = 12.0,
  });

  @override
  State<PageEntrance> createState() => _PageEntranceState();
}

class _PageEntranceState extends State<PageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    // Window per child: total / (count + 1) so the last child finishes before end.
    final window = 1.0 / (count + 0.5);
    final stagger = (widget.staggerMs / widget.durationMs).clamp(0.0, window);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final start = (i * stagger).clamp(0.0, 1.0 - window);
        final end = (start + window).clamp(0.0, 1.0);

        final curved = CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: const Cubic(0.16, 1.0, 0.3, 1.0)),
        );

        return FadeTransition(
          opacity: curved,
          child: AnimatedBuilder(
            animation: curved,
            child: widget.children[i],
            builder: (_, child) {
              final v = curved.value;
              if (v >= 1.0) return child!;
              return Transform.translate(
                offset: Offset(0, widget.slideY * (1.0 - v)),
                child: child,
              );
            },
          ),
        );
      }),
    );
  }
}

/// Single-item entrance (for wrapping a whole page body or a single block).
class FadeSlideEntrance extends StatefulWidget {
  final Widget child;
  final int durationMs;
  final double slideY;
  final Curve curve;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.durationMs = 180,
    this.slideY = 10.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideEntrance> createState() => _FadeSlideEntranceState();
}

class _FadeSlideEntranceState extends State<FadeSlideEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: AnimatedBuilder(
        animation: _anim,
        child: widget.child,
        builder: (_, child) {
          final v = _anim.value;
          if (v >= 1.0) return child!;
          return Transform.translate(
            offset: Offset(0, widget.slideY * (1.0 - v)),
            child: child,
          );
        },
      ),
    );
  }
}
