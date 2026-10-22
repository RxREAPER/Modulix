import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Authentic 3D split-flap mechanical digit flip card
class SketchFlipDigit extends StatefulWidget {
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
  State<SketchFlipDigit> createState() => _SketchFlipDigitState();
}

class _SketchFlipDigitState extends State<SketchFlipDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _oldDigit = '0';
  String _currentDigit = '0';

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _oldDigit = widget.digit;
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
          _oldDigit = _currentDigit;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SketchFlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _oldDigit = _currentDigit;
      _currentDigit = widget.digit;
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

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Static Upper Half (New digit revealed underneath)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: halfHeight,
                child: _buildHalfCard(
                  digit: _currentDigit,
                  isUpper: true,
                  halfHeight: halfHeight,
                ),
              ),

              // 2. Static Lower Half (Old digit until covered)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: halfHeight,
                child: _buildHalfCard(
                  digit: isAnimating ? _oldDigit : _currentDigit,
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
                      ..setEntry(3, 2, 0.0028)
                      ..rotateX(-val * math.pi),
                    child: _buildHalfCard(
                      digit: _oldDigit,
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
                      ..setEntry(3, 2, 0.0028)
                      ..rotateX((1.0 - val) * math.pi),
                    child: _buildHalfCard(
                      digit: _currentDigit,
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
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),

              // Left hinge notch
              Positioned(
                top: halfHeight - 3,
                left: 0,
                child: Container(
                  width: 3,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                  ),
                ),
              ),

              // Right hinge notch
              Positioned(
                top: halfHeight - 3,
                right: 0,
                child: Container(
                  width: 3,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHalfCard({
    required String digit,
    required bool isUpper,
    required double halfHeight,
    double shadowOpacity = 0.0,
  }) {
    return ClipRRect(
      borderRadius: isUpper
          ? const BorderRadius.vertical(top: Radius.circular(14))
          : const BorderRadius.vertical(bottom: Radius.circular(14)),
      child: ClipRect(
        child: Align(
          alignment: isUpper ? Alignment.topCenter : Alignment.bottomCenter,
          heightFactor: 0.5,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.borderColor, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x28000000),
                  offset: Offset(0, 3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    digit,
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
