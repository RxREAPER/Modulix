import 'package:flutter/material.dart';

/// A vertical drum / odometer rolling animation widget for numbers, counters,
/// live desk clock digits, quota counters, and timer strings.
/// Non-digit characters (such as colons, slashes, and percent signs) are displayed
/// statically, while each numeric digit smoothly rolls vertically to its new value.
class RollingDigitText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final MainAxisSize mainAxisSize;

  const RollingDigitText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 380),
    this.curve = const Cubic(0.175, 0.885, 0.32, 1.275),
    this.mainAxisSize = MainAxisSize.min,
  });

  /// Convenience constructor for integer counts.
  factory RollingDigitText.count({
    Key? key,
    required int count,
    TextStyle? style,
    Duration duration = const Duration(milliseconds: 380),
    Curve curve = const Cubic(0.175, 0.885, 0.32, 1.275),
    MainAxisSize mainAxisSize = MainAxisSize.min,
  }) {
    return RollingDigitText(
      key: key,
      text: count.toString(),
      style: style,
      duration: duration,
      curve: curve,
      mainAxisSize: mainAxisSize,
    );
  }

  static final Map<TextStyle, Size> _dimensionCache = {};

  static Size _getDigitSize(TextStyle style) {
    return _dimensionCache.putIfAbsent(style, () {
      final textPainter = TextPainter(
        text: TextSpan(text: '8', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final size = Size(textPainter.width, textPainter.height);
      textPainter.dispose();
      return size;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final digitSize = _getDigitSize(effectiveStyle);
    final digitHeight = digitSize.height;
    final digitWidth = digitSize.width;

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.none,
      child: Row(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(text.length, (i) {
          final char = text[i];
          final digit = int.tryParse(char);
          if (digit == null) {
            // Non-digit character (e.g. ':', '/', '%', ' ')
            return Text(char, style: effectiveStyle);
          }
          return _RollingDigitSlot(
            key: ValueKey('digit_${text.length - 1 - i}'),
            targetDigit: digit,
            style: effectiveStyle,
            digitWidth: digitWidth,
            digitHeight: digitHeight,
            duration: duration,
            curve: curve,
          );
        }),
      ),
    );
  }
}

class _RollingDigitSlot extends StatefulWidget {
  final int targetDigit;
  final TextStyle style;
  final double digitWidth;
  final double digitHeight;
  final Duration duration;
  final Curve curve;

  const _RollingDigitSlot({
    super.key,
    required this.targetDigit,
    required this.style,
    required this.digitWidth,
    required this.digitHeight,
    required this.duration,
    required this.curve,
  });

  @override
  State<_RollingDigitSlot> createState() => _RollingDigitSlotState();
}

class _RollingDigitSlotState extends State<_RollingDigitSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _animation;
  late double _fromValue;
  late double _toValue;

  @override
  void initState() {
    super.initState();
    _fromValue = widget.targetDigit.toDouble();
    _toValue = widget.targetDigit.toDouble();

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
  void didUpdateWidget(covariant _RollingDigitSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDigit != widget.targetDigit) {
      if (_controller.isAnimating) {
        _fromValue = _fromValue + (_toValue - _fromValue) * _animation.value;
      } else {
        _fromValue = _toValue;
      }
      double newTarget = widget.targetDigit.toDouble();

      // Handle roll-over wrap naturally (e.g., 9 -> 0 rolls forward to 10)
      if (oldWidget.targetDigit == 9 && widget.targetDigit == 0) {
        newTarget = 10.0;
      } else if (oldWidget.targetDigit == 0 && widget.targetDigit == 9) {
        _fromValue = 10.0;
      }

      _toValue = newTarget;
      _controller.duration = widget.duration;
      if (oldWidget.curve != widget.curve) {
        _animation.dispose();
        _animation = CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        );
      }
      _controller.forward(from: 0.0).then((_) {
        if (mounted && _toValue >= 10.0) {
          // Normalize back to 0 cleanly with setState
          setState(() {
            _fromValue = (_toValue % 10);
            _toValue = _fromValue;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 0 through 9, plus 0 and 1 for seamless forward wrap
    const digitsList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1];

    return RepaintBoundary(
      child: SizedBox(
        width: widget.digitWidth,
        height: widget.digitHeight,
        child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final currentDigitValue = _controller.isAnimating
                ? _fromValue + (_toValue - _fromValue) * _animation.value
                : _toValue;

            return Transform.translate(
              offset: Offset(0, -currentDigitValue * widget.digitHeight),
              child: child,
            );
          },
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: digitsList.map((d) {
                return SizedBox(
                  width: widget.digitWidth,
                  height: widget.digitHeight,
                  child: Center(
                    child: Text(
                      '$d',
                      style: widget.style,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ),
  );
}
}
