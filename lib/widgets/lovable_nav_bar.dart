import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'animations/apple_pressable.dart';
import 'nav/sketch_hatch_indicator.dart';
import 'nav/sketch_nav_icons.dart';

export 'nav/sketch_nav_icons.dart' show SketchNavIconType, SketchNavIcon;
export 'nav/sketch_hatch_indicator.dart' show SketchHatchIndicator;

class LovableNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final SketchNavIconType? sketchType;

  const LovableNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.sketchType,
  });
}

/// Modern floating capsule bottom navigation dock.
/// Features a streamlined minimalist pill matching the reference design,
/// bespoke line-art vector icons (House, Books, Hourglass, Trophy, Profile),
/// theme-adaptive styling, a smooth sliding highlight bubble,
/// entrance drop-and-expand motion on startup, and automatic drop/minimize
/// animation when navigating into subpages.
class LovableNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onTimerTap;
  final List<LovableNavItem> items;
  final bool isSessionActive;
  final ValueChanged<int>? onReTap;
  final bool isVisible;

  const LovableNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onTimerTap,
    required this.items,
    this.isSessionActive = false,
    this.onReTap,
    this.isVisible = true,
  });

  @override
  State<LovableNavBar> createState() => _LovableNavBarState();
}

class _LovableNavBarState extends State<LovableNavBar>
    with TickerProviderStateMixin {
  late AnimationController _motionController;
  late AnimationController _haloController;
  Timer? _reTapTimer;

  @override
  void initState() {
    super.initState();
    // Drop & Expand entrance animation
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
      reverseDuration: const Duration(milliseconds: 300),
    );

    // Ambient pulse controller for active focus sessions
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.isVisible) {
      _motionController.forward(from: 0.0);
    }
    if (widget.isSessionActive) {
      _haloController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LovableNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Minimize or expand dock on page transitions
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _motionController.forward();
      } else {
        _motionController.reverse();
      }
    }

    // Active session ambient glow
    if (widget.isSessionActive != oldWidget.isSessionActive) {
      if (widget.isSessionActive) {
        _haloController.repeat();
      } else {
        _haloController.stop();
        _haloController.reset();
      }
    }
  }

  @override
  void dispose() {
    _reTapTimer?.cancel();
    _motionController.dispose();
    _haloController.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    if (index == widget.currentIndex) {
      HapticFeedback.selectionClick();
      _reTapTimer?.cancel();
      _reTapTimer = Timer(const Duration(milliseconds: 65), () {
        HapticFeedback.selectionClick();
      });
      if (widget.onReTap != null) {
        widget.onReTap!(index);
      } else {
        widget.onTap(index);
      }
    } else {
      HapticFeedback.selectionClick();
      widget.onTap(index);
    }
  }

  SketchNavIconType _resolveSketchType(LovableNavItem item, int index) {
    if (item.sketchType != null) return item.sketchType!;
    final l = item.label.toLowerCase();
    if (l.contains('home')) return SketchNavIconType.home;
    if (l.contains('curriculum') || l.contains('library') || l.contains('book')) {
      return SketchNavIconType.library;
    }
    if (l.contains('analytics') || l.contains('progress') || l.contains('chart') || l.contains('trophy')) {
      return SketchNavIconType.progress;
    }
    if (l.contains('task') || l.contains('todo') || l.contains('checklist')) {
      return SketchNavIconType.tasks;
    }
    if (l.contains('profile') || l.contains('settings') || l.contains('user')) {
      return SketchNavIconType.profile;
    }
    switch (index) {
      case 0:
        return SketchNavIconType.home;
      case 1:
        return SketchNavIconType.library;
      case 2:
        return SketchNavIconType.progress;
      case 3:
        return SketchNavIconType.tasks;
      default:
        return SketchNavIconType.profile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    const dockHeight = 56.0;
    const horizontalMargin = 20.0;
    final accentColor = AppTheme.accentPrimary;
    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF64748B);

    final hasTasksTab = widget.items.length >= 5;
    final totalSlots = hasTasksTab ? 6 : 5;

    // Map tab currentIndex (0..4) to slot layout:
    // Slot 0: Tab 0 (Home)
    // Slot 1: Tab 1 (Library)
    // Slot 2: Tab 2 (Progress)
    // Slot 3: Center Focus (Hourglass)
    // Slot 4: Tab 3 (Tasks)
    // Slot 5: Tab 4 (Profile)
    int? activeSlot;
    if (hasTasksTab) {
      if (widget.currentIndex == 0) {
        activeSlot = 0;
      } else if (widget.currentIndex == 1) {
        activeSlot = 1;
      } else if (widget.currentIndex == 2) {
        activeSlot = 2;
      } else if (widget.currentIndex == 5) {
        activeSlot = 3; // Focus center
      } else if (widget.currentIndex == 3) {
        activeSlot = 4; // Tasks
      } else if (widget.currentIndex == 4) {
        activeSlot = 5; // Profile
      }
    } else {
      if (widget.currentIndex == 0) {
        activeSlot = 0;
      } else if (widget.currentIndex == 1) {
        activeSlot = 1;
      } else if (widget.currentIndex == 4) {
        activeSlot = 2; // Focus tab active
      } else if (widget.currentIndex == 2) {
        activeSlot = 3;
      } else if (widget.currentIndex == 3) {
        activeSlot = 4;
      }
    }

    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, child) {
        final t = _motionController.value;
        if (t <= 0.001 && !widget.isVisible) {
          return const SizedBox.shrink();
        }

        final isReverse = _motionController.status == AnimationStatus.reverse;
        final double curve = isReverse
            ? Curves.easeInOutCubic.transform(t)
            : const Cubic(0.20, 1.28, 0.36, 1.0).transform(t);

        // Vertical drop/rise glide: rises from 92px below edge
        final double yOffset = (1.0 - curve) * 92.0;

        // Droplet horizontal & vertical morph:
        // Condenses horizontally to 0.40 (compact round droplet) when minimized,
        // blooms and expands outward to 1.00 when entering/active.
        final double scaleX = (0.40 + (0.60 * curve)).clamp(0.0, 1.05);
        final double scaleY = (0.62 + (0.38 * curve)).clamp(0.0, 1.02);
        final double opacity = Curves.easeIn.transform(t.clamp(0.0, 1.0));

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform(
            transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          ),
        );
      },
      child: RepaintBoundary(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 10),
            child: Container(
              height: dockHeight,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1F24)
                  : Colors.white,
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2E3038)
                    : AppTheme.sketchBorderColor.withValues(alpha: 0.12),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.07),
                  offset: const Offset(0, 4),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final slotWidth = totalWidth / totalSlots;

                  Rect? pillRect;
                  if (activeSlot != null) {
                    final slotCenter = (activeSlot + 0.5) * slotWidth;
                    final pillWidth = math.min(slotWidth - 4.0, 50.0);
                    const pillHeight = 44.0;
                    final pillLeft = slotCenter - (pillWidth / 2);
                    const pillTop = (dockHeight - pillHeight) / 2;

                    pillRect = Rect.fromLTWH(
                      pillLeft,
                      pillTop,
                      pillWidth,
                      pillHeight,
                    );
                  }

                  return Stack(
                    children: [
                      // Smooth, refined sliding bubble highlight
                      if (pillRect != null)
                        Positioned.fill(
                          child: SketchHatchIndicator(
                            targetRect: pillRect,
                            hatchColor: accentColor,
                            borderRadius: 22.0,
                          ),
                        ),

                      if (hasTasksTab)
                        // 6 Integrated Slots
                        Row(
                          children: [
                            // Slot 0: Home (tab 0)
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_0'),
                                sketchType: _resolveSketchType(widget.items[0], 0),
                                label: widget.items[0].label,
                                isSelected: activeSlot == 0,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(0),
                              ),
                            ),

                            // Slot 1: Library (tab 1)
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_1'),
                                sketchType: _resolveSketchType(widget.items[1], 1),
                                label: widget.items[1].label,
                                isSelected: activeSlot == 1,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(1),
                              ),
                            ),

                            // Slot 2: Progress (tab 2)
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_2'),
                                sketchType: _resolveSketchType(widget.items[2], 2),
                                label: widget.items[2].label,
                                isSelected: activeSlot == 2,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(2),
                              ),
                            ),

                            // Slot 3: Focus (Center Hourglass)
                            Expanded(
                              child: _ModernFocusItem(
                                key: const Key('nav_center_timer_button'),
                                isSelected: activeSlot == 3,
                                isSessionActive: widget.isSessionActive,
                                haloAnimation: _haloController,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onTimerTap();
                                },
                              ),
                            ),

                            // Slot 4: Tasks (tab 3)
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_3'),
                                sketchType: _resolveSketchType(widget.items[3], 3),
                                label: widget.items[3].label,
                                isSelected: activeSlot == 4,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(3),
                              ),
                            ),

                            // Slot 5: Profile (tab 4)
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_4'),
                                sketchType: _resolveSketchType(widget.items[4], 4),
                                label: widget.items[4].label,
                                isSelected: activeSlot == 5,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(4),
                              ),
                            ),
                          ],
                        )
                      else
                        // 5 Integrated Slots (legacy)
                        Row(
                          children: [
                            // Slot 0: Home
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_0'),
                                sketchType: widget.items.isNotEmpty
                                    ? _resolveSketchType(widget.items[0], 0)
                                    : SketchNavIconType.home,
                                label: widget.items.isNotEmpty
                                    ? widget.items[0].label
                                    : 'Home',
                                isSelected: activeSlot == 0,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(0),
                              ),
                            ),

                            // Slot 1: Library
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_1'),
                                sketchType: widget.items.length > 1
                                    ? _resolveSketchType(widget.items[1], 1)
                                    : SketchNavIconType.library,
                                label: widget.items.length > 1
                                    ? widget.items[1].label
                                    : 'Library',
                                isSelected: activeSlot == 1,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(1),
                              ),
                            ),

                            // Slot 2: Focus (Center Hourglass)
                            Expanded(
                              child: _ModernFocusItem(
                                key: const Key('nav_center_timer_button'),
                                isSelected: activeSlot == 2,
                                isSessionActive: widget.isSessionActive,
                                haloAnimation: _haloController,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onTimerTap();
                                },
                              ),
                            ),

                            // Slot 3: Progress
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_2'),
                                sketchType: widget.items.length > 2
                                    ? _resolveSketchType(widget.items[2], 2)
                                    : SketchNavIconType.progress,
                                label: widget.items.length > 2
                                    ? widget.items[2].label
                                    : 'Progress',
                                isSelected: activeSlot == 3,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(2),
                              ),
                            ),

                            // Slot 4: Profile
                            Expanded(
                              child: _ModernTabItem(
                                key: const Key('nav_tab_3'),
                                sketchType: widget.items.length > 3
                                    ? _resolveSketchType(widget.items[3], 3)
                                    : SketchNavIconType.profile,
                                label: widget.items.length > 3
                                    ? widget.items[3].label
                                    : 'Profile',
                                isSelected: activeSlot == 4,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                onTap: () => _handleTabTap(3),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

/// Sleek modern tab item: Minimalist default (icon only), text visible on select
class _ModernTabItem extends StatelessWidget {
  final SketchNavIconType sketchType;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _ModernTabItem({
    super.key,
    required this.sketchType,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? activeColor : inactiveColor;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: ApplePressable(
        pressedScale: 0.97,
        pressedOpacity: 0.92,
        hapticStyle: HapticStyle.none,
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                SketchNavIcon(
                  type: sketchType,
                  color: iconColor,
                  size: isSelected ? 21.0 : 22.0,
                  isSelected: isSelected,
                  strokeWidth: isSelected ? 1.9 : 1.7,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 2),
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
  }
}

/// Center Focus Item (Hourglass with ambient breathing glow when active session)
class _ModernFocusItem extends StatelessWidget {
  final bool isSelected;
  final bool isSessionActive;
  final Animation<double> haloAnimation;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _ModernFocusItem({
    super.key,
    required this.isSelected,
    required this.isSessionActive,
    required this.haloAnimation,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = (isSelected || isSessionActive) ? activeColor : inactiveColor;

    return Semantics(
      label: 'Focus',
      selected: isSelected,
      button: true,
      child: ApplePressable(
        pressedScale: 0.97,
        pressedOpacity: 0.92,
        hapticStyle: HapticStyle.none,
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSessionActive)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: haloAnimation,
                    builder: (context, child) {
                      final scale = 1.0 + (haloAnimation.value * 0.28);
                      final opacity = (1.0 - haloAnimation.value) * 0.40;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activeColor.withValues(alpha: opacity),
                              width: 1.8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SketchNavIcon(
                    type: SketchNavIconType.focus,
                    color: iconColor,
                    size: isSelected ? 21.0 : 22.0,
                    isSelected: isSelected || isSessionActive,
                    strokeWidth: (isSelected || isSessionActive) ? 1.9 : 1.7,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 2),
                    AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 160),
                      child: Text(
                        'Focus',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          color: activeColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
