import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HapticStyle {
  light,
  selection,
  medium,
  none,
}

/// An Apple App Store-style interactive pressable wrapper that provides
/// immediate tactile scaling (100ms compress), high-fidelity elastic snap-back
/// (220ms spring cubic), and subtle opacity dimming on touch-down.
class ApplePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final double pressedOpacity;
  final BorderRadius? borderRadius;
  final bool enableHaptic;
  final HapticStyle hapticStyle;

  const ApplePressable({
    super.key,
    required this.child,
    this.onTap,
    this.onPressed,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.pressedOpacity = 1.0,
    this.borderRadius,
    this.enableHaptic = true,
    this.hapticStyle = HapticStyle.selection,
  });

  VoidCallback? get effectiveTap => onTap ?? onPressed;

  @override
  State<ApplePressable> createState() => _ApplePressableState();
}

class _ApplePressableState extends State<ApplePressable> {
  bool _isPressed = false;

  void _triggerHaptic(HapticStyle style) {
    if (!widget.enableHaptic) return;
    switch (style) {
      case HapticStyle.light:
        HapticFeedback.lightImpact();
        break;
      case HapticStyle.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticStyle.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticStyle.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTap = widget.effectiveTap;
    if (effectiveTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        if (!_isPressed) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (_isPressed) {
          setState(() => _isPressed = false);
        }
      },
      onTapCancel: () {
        if (_isPressed) {
          setState(() => _isPressed = false);
        }
      },
      onTap: () {
        effectiveTap?.call();
        _triggerHaptic(widget.hapticStyle);
      },
      onLongPress: widget.onLongPress != null
          ? () {
              widget.onLongPress!();
              _triggerHaptic(HapticStyle.medium);
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _isPressed ? 100 : 200),
        curve: _isPressed ? Curves.easeInOut : const Cubic(0.175, 0.885, 0.32, 1.275),
        child: widget.child,
      ),
    );
  }
}
