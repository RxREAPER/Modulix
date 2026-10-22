import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Authentic 3D split-flap mechanical card (supports full 2-digit pairs like '23' or '07')
class SketchFlipCard extends StatefulWidget {
  final String value;
  final TextStyle textStyle;
  final Color cardColor;
  final Color borderColor;
  final double width;
  final double height;
  final double borderRadius;
  final Duration duration;
  final Widget? bottomLeftWidget;
  final Widget? bottomRightWidget;
  final Widget? topRightWidget;
  final Widget? topLeftWidget;

  const SketchFlipCard({
    super.key,
    required this.value,
    required this.textStyle,
    required this.cardColor,
    required this.borderColor,
    required this.width,
    required this.height,
    this.borderRadius = 22.0,
    this.duration = const Duration(milliseconds: 360),
    this.bottomLeftWidget,
    this.bottomRightWidget,
    this.topRightWidget,
    this.topLeftWidget,
  });

  @override
  State<SketchFlipCard> createState() => _SketchFlipCardState();
}

class _SketchFlipCardState extends State<SketchFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _oldValue = '00';
  String _currentValue = '00';

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _oldValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _oldValue = _currentValue;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SketchFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = _currentValue;
      _currentValue = widget.value;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final halfHeight = widget.height / 2;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final val = _animation.value;
        final isAnimating = _controller.isAnimating || (val > 0.0 && val < 1.0);

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Static Upper Half (New value revealed underneath)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: halfHeight,
                child: _buildHalfCard(
                  text: _currentValue,
                  isUpper: true,
                  halfHeight: halfHeight,
                ),
              ),

              // 2. Static Lower Half (Old value until covered)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: halfHeight,
                child: _buildHalfCard(
                  text: isAnimating ? _oldValue : _currentValue,
                  isUpper: false,
                  halfHeight: halfHeight,
                  shadowOpacity: isAnimating && val <= 0.5 ? val * 0.45 : 0.0,
                ),
              ),

              // 3. Falling Upper Flap (Rotates 0 -> -90 deg around bottomCenter)
              if (isAnimating && val <= 0.5)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: halfHeight,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0024)
                      ..rotateX(-val * math.pi),
                    child: _buildHalfCard(
                      text: _oldValue,
                      isUpper: true,
                      halfHeight: halfHeight,
                      shadowOpacity: val * 0.75,
                    ),
                  ),
                ),

              // 4. Landing Lower Flap (Rotates 90 -> 0 deg around topCenter)
              if (isAnimating && val > 0.5)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: halfHeight,
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0024)
                      ..rotateX((1.0 - val) * math.pi),
                    child: _buildHalfCard(
                      text: _currentValue,
                      isUpper: false,
                      halfHeight: halfHeight,
                      shadowOpacity: (1.0 - val) * 0.75,
                    ),
                  ),
                ),

              // 5. Middle Split Crease Line
              Positioned(
                top: halfHeight - 1.0,
                left: 0,
                right: 0,
                height: 2.0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),

              // Left hinge notch
              Positioned(
                top: halfHeight - 4,
                left: 0,
                child: Container(
                  width: 4,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                  ),
                ),
              ),

              // Right hinge notch
              Positioned(
                top: halfHeight - 4,
                right: 0,
                child: Container(
                  width: 4,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                  ),
                ),
              ),

              // Corner Overlays (e.g. Tiny Seconds Block in Bottom-Left corner)
              if (widget.bottomLeftWidget != null)
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: widget.bottomLeftWidget!,
                ),
              if (widget.bottomRightWidget != null)
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: widget.bottomRightWidget!,
                ),
              if (widget.topLeftWidget != null)
                Positioned(
                  top: 12,
                  left: 16,
                  child: widget.topLeftWidget!,
                ),
              if (widget.topRightWidget != null)
                Positioned(
                  top: 12,
                  right: 16,
                  child: widget.topRightWidget!,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHalfCard({
    required String text,
    required bool isUpper,
    required double halfHeight,
    double shadowOpacity = 0.0,
  }) {
    final r = Radius.circular(widget.borderRadius);
    return ClipRRect(
      borderRadius: isUpper
          ? BorderRadius.vertical(top: r)
          : BorderRadius.vertical(bottom: r),
      child: SizedBox(
        width: widget.width,
        height: halfHeight,
        child: OverflowBox(
          alignment: isUpper ? Alignment.topCenter : Alignment.bottomCenter,
          minWidth: widget.width,
          maxWidth: widget.width,
          minHeight: widget.height,
          maxHeight: widget.height,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: widget.borderColor, width: 1.0),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    text,
                    style: widget.textStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (shadowOpacity > 0.0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: shadowOpacity.clamp(0.0, 0.85)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Backwards compatibility alias for single digit usage
class SketchFlipDigit extends StatelessWidget {
  final String digit;
  final TextStyle textStyle;
  final Color cardColor;
  final Color borderColor;
  final double width;
  final double height;
  final Duration duration;

  const SketchFlipDigit({
    super.key,
    required this.digit,
    required this.textStyle,
    required this.cardColor,
    required this.borderColor,
    this.width = 54,
    this.height = 76,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  Widget build(BuildContext context) {
    return SketchFlipCard(
      value: digit,
      textStyle: textStyle,
      cardColor: cardColor,
      borderColor: borderColor,
      width: width,
      height: height,
      borderRadius: 14.0,
      duration: duration,
    );
  }
}
