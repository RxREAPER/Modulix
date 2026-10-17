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

class _ApplePressableState extends State<ApplePressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _isPressed = false;

  static const _pressCurve = Curves.easeInOut;
  static const _springReleaseCurve = Cubic(0.175, 0.885, 0.32, 1.275);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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

  void _onPointerDown(PointerDownEvent _) {
    _isPressed = true;
    _ctrl.animateTo(1.0, duration: const Duration(milliseconds: 100), curve: _pressCurve);
  }

  void _onPointerUp(PointerUpEvent _) {
    if (_isPressed) {
      _isPressed = false;
      _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 220), curve: _springReleaseCurve);
    }
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (_isPressed) {
      _isPressed = false;
      _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTap = widget.effectiveTap;
    if (effectiveTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    Widget content = AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final scale = 1.0 - (1.0 - widget.pressedScale) * _ctrl.value;

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: widget.child,
    );

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapCancel: () {
          if (_isPressed) {
            _isPressed = false;
            _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
          }
        },
        onTap: () {
          effectiveTap?.call();
          _triggerHaptic(widget.hapticStyle);
        },
        onLongPress: widget.onLongPress != null ? () {
          widget.onLongPress!();
          _triggerHaptic(HapticStyle.medium);
        } : null,
        child: content,
      ),
    );
  }
}
