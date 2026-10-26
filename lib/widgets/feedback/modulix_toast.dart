import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

/// Type of feedback toast for semantic icon & color accenting
enum ModulixToastType {
  success,
  info,
  warning,
  error,
  undo,
}

/// Centralized Dynamic Island Top Glass Toast & Undo Popup System for Modulix.
/// Floats gracefully from the top status notch with spring physics,
/// frosted Apple glass translucency, tactile haptics, and responsive layout.
class ModulixToast {
  static OverlayEntry? _activeEntry;
  static Timer? _activeTimer;
  static _ModulixToastWidgetState? _currentState;

  /// Display a generic or action-enabled toast
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData? icon,
    ModulixToastType type = ModulixToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    dismiss();

    final overlay = Navigator.of(context, rootNavigator: true).overlay ??
        Overlay.of(context);

    // Provide light tactile feedback on appearance
    HapticFeedback.lightImpact();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ModulixToastWidget(
        message: message,
        title: title,
        icon: icon,
        type: type,
        actionLabel: actionLabel,
        onAction: () {
          dismiss();
          onAction?.call();
        },
        duration: duration,
        onDismissRequested: dismiss,
        onStateRegistered: (state) => _currentState = state,
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);

    _activeTimer = Timer(duration, () {
      dismiss();
    });
  }

  /// Convenience helper for undoable actions (e.g. task deletions)
  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    String actionLabel = 'Undo',
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    show(
      context,
      message: message,
      type: ModulixToastType.undo,
      icon: Icons.undo_rounded,
      actionLabel: actionLabel,
      onAction: onUndo,
      duration: duration,
    );
  }

  /// Convenience helper for success notifications
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ModulixToastType.success,
      icon: Icons.check_circle_rounded,
      duration: duration,
    );
  }

  /// Convenience helper for error notifications
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ModulixToastType.error,
      icon: Icons.error_outline_rounded,
      duration: duration,
    );
  }

  /// Convenience helper for informational notifications
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ModulixToastType.info,
      icon: Icons.info_outline_rounded,
      duration: duration,
    );
  }

  /// Gracefully dismiss the active toast with exit animation
  static void dismiss() {
    _activeTimer?.cancel();
    _activeTimer = null;

    if (_currentState != null) {
      final state = _currentState!;
      _currentState = null;
      state.animateOut().then((_) {
        _activeEntry?.remove();
        _activeEntry = null;
      });
    } else {
      _activeEntry?.remove();
      _activeEntry = null;
    }
  }
}

class _ModulixToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final IconData? icon;
  final ModulixToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissRequested;
  final void Function(_ModulixToastWidgetState) onStateRegistered;

  const _ModulixToastWidget({
    required this.message,
    this.title,
    this.icon,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismissRequested,
    required this.onStateRegistered,
  });

  @override
  State<_ModulixToastWidget> createState() => _ModulixToastWidgetState();
}

class _ModulixToastWidgetState extends State<_ModulixToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    widget.onStateRegistered(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<double>(begin: -60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  Future<void> animateOut() async {
    if (mounted) {
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.viewPadding.top > 0
        ? mediaQuery.viewPadding.top
        : mediaQuery.padding.top;
    final screenWidth = mediaQuery.size.width;
    final maxToastWidth = math.min(420.0, screenWidth - 32.0);

    final Color accentColor;
    final IconData defaultIcon;

    switch (widget.type) {
      case ModulixToastType.success:
        accentColor = const Color(0xFF30D158);
        defaultIcon = Icons.check_circle_rounded;
        break;
      case ModulixToastType.warning:
        accentColor = const Color(0xFFFF9F0A);
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case ModulixToastType.error:
        accentColor = const Color(0xFFFF453A);
        defaultIcon = Icons.error_outline_rounded;
        break;
      case ModulixToastType.undo:
        accentColor = AppTheme.accentPrimary;
        defaultIcon = Icons.undo_rounded;
        break;
      case ModulixToastType.info:
        accentColor = AppTheme.accentPrimary;
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    final displayIcon = widget.icon ?? defaultIcon;
    final hasAction = widget.actionLabel != null && widget.onAction != null;

    return Positioned(
      top: topPadding + 10.0,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                ),
              ),
            );
          },
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -4.0) {
                widget.onDismissRequested();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 200.0,
                  maxWidth: maxToastWidth,
                  minHeight: 46.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                      offset: const Offset(0, 8),
                      blurRadius: 24.0,
                      spreadRadius: -2.0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 9.0,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF141414).withValues(alpha: 0.88)
                            : Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 1. Semantic Icon Badge
                              Container(
                                width: 26.0,
                                height: 26.0,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    displayIcon,
                                    size: 15.0,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10.0),

                              // 2. Message Content
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.title != null) ...[
                                      Text(
                                        widget.title!,
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.inkForeground,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1.0),
                                    ],
                                    Text(
                                      widget.message,
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? const Color(0xFFF2F2F7)
                                            : const Color(0xFF1C1C1E),
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // 3. Optional Undo / Action Button
                              if (hasAction) ...[
                                const SizedBox(width: 12.0),
                                Container(
                                  height: 22.0,
                                  width: 1.0,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                                const SizedBox(width: 8.0),
                                ApplePressable(
                                  pressedScale: 0.92,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    widget.onAction?.call();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                          alpha: isDark ? 0.22 : 0.12),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      widget.actionLabel!,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: accentColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // 4. Depleting Micro-Progress Bar (for undo countdown)
                          if (hasAction) ...[
                            const SizedBox(height: 6.0),
                            _DepletingProgressBar(
                              duration: widget.duration,
                              color: accentColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linear depleting countdown bar indicating the time window to undo
class _DepletingProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;

  const _DepletingProgressBar({
    required this.duration,
    required this.color,
  });

  @override
  State<_DepletingProgressBar> createState() => _DepletingProgressBarState();
}

class _DepletingProgressBarState extends State<_DepletingProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barController;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _barController,
      builder: (context, _) {
        final remaining = (1.0 - _barController.value).clamp(0.0, 1.0);
        return Container(
          height: 1.8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(1.0),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: remaining,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
        );
      },
    );
  }
}
