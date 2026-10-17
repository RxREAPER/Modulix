import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprung/sprung.dart';

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

  void _releasePress() {
    if (!_isPressed) return;
    if (mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTap = widget.effectiveTap;
    if (effectiveTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (!_isPressed) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) => _releasePress(),
      onTapCancel: () => _releasePress(),
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
        duration: Duration(milliseconds: _isPressed ? 70 : 180),
        curve: _isPressed ? Curves.easeOutCubic : Sprung.underDamped,
        child: AnimatedOpacity(
          opacity: _isPressed ? widget.pressedOpacity : 1.0,
          duration: Duration(milliseconds: _isPressed ? 70 : 180),
          child: widget.child,
        ),
      ),
    );
  }
}
