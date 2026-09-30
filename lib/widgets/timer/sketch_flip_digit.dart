import 'dart:math' as math;
import 'package:flutter/material.dart';

class SketchFlipDigit extends StatefulWidget {
  final String digit;
  final TextStyle textStyle;
  final Color cardColor;
  final Color borderColor;
  final double width;
  final double height;

  const SketchFlipDigit({
    super.key,
    required this.digit,
    required this.textStyle,
    required this.cardColor,
    required this.borderColor,
    this.width = 54,
    this.height = 76,
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
      duration: const Duration(milliseconds: 380),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant SketchFlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _oldDigit = oldWidget.digit;
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        final angle = val * math.pi;
        final displayDigit = val < 0.5 ? _oldDigit : _currentDigit;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(angle < math.pi / 2 ? -angle : (math.pi - angle)),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.borderColor, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x241C1C1C),
                  offset: Offset(2.5, 3.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Middle split crease line
                Positioned(
                  left: 0,
                  right: 0,
                  top: widget.height / 2 - 0.75,
                  child: Container(
                    height: 1.5,
                    color: widget.borderColor.withOpacity(0.25),
                  ),
                ),
                // Number
                Text(
                  displayDigit,
                  style: widget.textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
