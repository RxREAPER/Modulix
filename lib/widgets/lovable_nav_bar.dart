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

/// Modern floating stadium capsule bottom navigation dock.
/// Inspired by high-end design systems:
/// - Floating stadium capsule dock with multi-layer ambient elevation shadows.
/// - Horizontally expanding active tab pill revealing [ Icon + Label ] with smooth cubic transition.
/// - Inactive tabs showing minimalist outline icons only, centered with muted opacity.
/// - Elevated Center Focus Timer Hero Button with radial disk contrast, breathing
///   holographic aura glow during active sessions, and live status jewel.
/// - Uniform vector icon strokes and proportions across all tabs.
/// - Entrance drop-and-expand motion and automatic subpage drop transitions.
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
    const dockHeight = 62.0;
    const horizontalMargin = 16.0;
    final accentColor = AppTheme.accentPrimary;
    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF64748B);

    final hasTasksTab = widget.items.length >= 5;

    // Map tab currentIndex to slot index:
    // Standard 5 slots:
    // Slot 0: Tab 0 (Home)
    // Slot 1: Tab 1 (Library)
    // Slot 2: Center Focus Hero
    // Slot 3: Tab 2 (Progress)
    // Slot 4: Tab 3 (Profile)
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

        // Droplet horizontal & vertical morph
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
            padding: const EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 12.0),
            child: Container(
              height: dockHeight,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B1D22)
                    : Colors.white,
                borderRadius: BorderRadius.circular(31.0),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C2F38)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(31.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final regularCount = hasTasksTab ? 5 : 4;
                    const heroWidth = 52.0;
                    final availableForTabs = totalWidth - heroWidth;

                    // Compute dynamic slot centers for SketchHatchIndicator
                    final totalFlex = 180.0 + ((regularCount - 1) * 100.0);
                    final wActive = (availableForTabs * 180.0) / totalFlex;
                    final wInactive = (availableForTabs * 100.0) / totalFlex;

                    Rect? pillRect;
                    if (activeSlot != null) {
                      double centerDx = 0.0;
                      double targetWidth = math.min(wActive - 8.0, 110.0);

                      if (hasTasksTab) {
                        // 6 slots: 0, 1, 2, Hero(3), 4, 5
                        if (activeSlot == 0) {
                          centerDx = wActive / 2;
                        } else if (activeSlot == 1) {
                          centerDx = wInactive + (wActive / 2);
                        } else if (activeSlot == 2) {
                          centerDx = (2 * wInactive) + (wActive / 2);
                        } else if (activeSlot == 3) {
                          centerDx = (3 * wInactive) + (heroWidth / 2);
                          targetWidth = 48.0;
                        } else if (activeSlot == 4) {
                          centerDx = (3 * wInactive) + heroWidth + (wActive / 2);
                        } else if (activeSlot == 5) {
                          centerDx = (3 * wInactive) + heroWidth + wInactive + (wActive / 2);
                        }
                      } else {
                        // 5 slots: 0, 1, Hero(2), 3, 4
                        if (activeSlot == 0) {
                          centerDx = wActive / 2;
                        } else if (activeSlot == 1) {
                          centerDx = wInactive + (wActive / 2);
                        } else if (activeSlot == 2) {
                          centerDx = (2 * wInactive) + (heroWidth / 2);
                          targetWidth = 48.0;
                        } else if (activeSlot == 3) {
                          centerDx = (2 * wInactive) + heroWidth + (wActive / 2);
                        } else if (activeSlot == 4) {
                          centerDx = (3 * wInactive) + heroWidth + (wActive / 2);
                        }
                      }

                      pillRect = Rect.fromCenter(
                        center: Offset(centerDx, dockHeight / 2),
                        width: targetWidth,
                        height: 44.0,
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
                          // 6 Slots Layout
                          Row(
                            children: [
                              _ExpandingNavItem(
                                key: const Key('nav_tab_0'),
                                sketchType: _resolveSketchType(widget.items[0], 0),
                                label: widget.items[0].label,
                                isSelected: activeSlot == 0,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                height: dockHeight,
                                onTap: () => _handleTabTap(0),
                              ),
                              _ExpandingNavItem(
                                key: const Key('nav_tab_1'),
                                sketchType: _resolveSketchType(widget.items[1], 1),
                                label: widget.items[1].label,
                                isSelected: activeSlot == 1,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                height: dockHeight,
                                onTap: () => _handleTabTap(1),
                              ),
                              _ExpandingNavItem(
                                key: const Key('nav_tab_2'),
                                sketchType: _resolveSketchType(widget.items[2], 2),
                                label: widget.items[2].label,
                                isSelected: activeSlot == 2,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                height: dockHeight,
                                onTap: () => _handleTabTap(2),
                              ),
                              _HeroFocusTimerItem(
                                key: const Key('nav_center_timer_button'),
                                isSelected: activeSlot == 3,
                                isSessionActive: widget.isSessionActive,
                                haloAnimation: _haloController,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                width: heroWidth,
                                height: dockHeight,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onTimerTap();
                                },
                              ),
                              _ExpandingNavItem(
                                key: const Key('nav_tab_3'),
                                sketchType: _resolveSketchType(widget.items[3], 3),
                                label: widget.items[3].label,
                                isSelected: activeSlot == 4,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                height: dockHeight,
                                onTap: () => _handleTabTap(3),
                              ),
                              _ExpandingNavItem(
                                key: const Key('nav_tab_4'),
                                sketchType: _resolveSketchType(widget.items[4], 4),
                                label: widget.items[4].label,
                                isSelected: activeSlot == 5,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                height: dockHeight,
                                onTap: () => _handleTabTap(4),
                              ),
                            ],
                          )
                        else
                          // Standard 5 Slots Layout
                          Row(
                            children: [
                              _ExpandingNavItem(
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
                                height: dockHeight,
                                onTap: () => _handleTabTap(0),
                              ),
                              _ExpandingNavItem(
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
                                height: dockHeight,
                                onTap: () => _handleTabTap(1),
                              ),
                              _HeroFocusTimerItem(
                                key: const Key('nav_center_timer_button'),
                                isSelected: activeSlot == 2,
                                isSessionActive: widget.isSessionActive,
                                haloAnimation: _haloController,
                                activeColor: accentColor,
                                inactiveColor: inactiveColor,
                                width: heroWidth,
                                height: dockHeight,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onTimerTap();
                                },
                              ),
                              _ExpandingNavItem(
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
                                height: dockHeight,
                                onTap: () => _handleTabTap(2),
                              ),
                              _ExpandingNavItem(
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
                                height: dockHeight,
                                onTap: () => _handleTabTap(3),
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

/// Horizontally expanding active tab pill:
/// When active: expands smoothly with [ Icon + Label ] in accent pill container.
/// When inactive: condenses to clean outline icon centered in slot.
/// Uses Expanded with smooth animated flex to guarantee zero layout overflow.
class _ExpandingNavItem extends StatelessWidget {
  final SketchNavIconType sketchType;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final VoidCallback onTap;

  const _ExpandingNavItem({
    super.key,
    required this.sketchType,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: isSelected ? 1.0 : 0.0,
        end: isSelected ? 1.0 : 0.0,
      ),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        // Interpolate flex factor smoothly from 100 to 180
        final flex = (100 + (animValue * 80)).round().clamp(100, 180);

        return Expanded(
          flex: flex,
          child: Semantics(
            label: label,
            selected: isSelected,
            button: true,
            child: SizedBox(
              height: height,
              child: ApplePressable(
                pressedScale: 0.95,
                pressedOpacity: 0.90,
                hapticStyle: HapticStyle.none,
                onTap: onTap,
                borderRadius: BorderRadius.circular(24.0),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.0 * animValue,
                      vertical: 7.0,
                    ),
                    decoration: BoxDecoration(
                      color: animValue > 0.05
                          ? activeColor.withValues(
                              alpha: (isDark ? 0.18 : 0.12) * animValue,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(
                        color: animValue > 0.05
                            ? activeColor.withValues(
                                alpha: (isDark ? 0.28 : 0.20) * animValue,
                              )
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SketchNavIcon(
                          type: sketchType,
                          color: isSelected ? activeColor : inactiveColor,
                          size: 21.0,
                          isSelected: isSelected,
                          strokeWidth: 1.85,
                        ),
                        if (animValue > 0.15) ...[
                          const SizedBox(width: 5),
                          Flexible(
                            child: ClipRect(
                              child: Opacity(
                                opacity: ((animValue - 0.15) / 0.85).clamp(0.0, 1.0),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                    color: activeColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Center Focus Timer Hero Button:
/// - Elevated circular hero disk with distinct gradient fill, accent rim, and elevation shadow.
/// - Breathing holographic aura ring pulsing outward during active sessions.
/// - Inner radiant core glow.
/// - Live status jewel indicator at top-right (emerald green when live, accent when idle).
class _HeroFocusTimerItem extends StatelessWidget {
  final bool isSelected;
  final bool isSessionActive;
  final Animation<double> haloAnimation;
  final Color activeColor;
  final Color inactiveColor;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _HeroFocusTimerItem({
    super.key,
    required this.isSelected,
    required this.isSessionActive,
    required this.haloAnimation,
    required this.activeColor,
    required this.inactiveColor,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    const heroSize = 46.0;

    return Semantics(
      label: 'Focus Timer',
      selected: isSelected,
      button: true,
      child: SizedBox(
        width: width,
        height: height,
        child: ApplePressable(
          pressedScale: 0.92,
          pressedOpacity: 0.90,
          hapticStyle: HapticStyle.none,
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.0),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Breathing Holographic Halo Ring when session is active
                if (isSessionActive)
                  AnimatedBuilder(
                    animation: haloAnimation,
                    builder: (context, child) {
                      final scale = 1.0 + (haloAnimation.value * 0.32);
                      final opacity = (1.0 - haloAnimation.value) * 0.45;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: heroSize,
                          height: heroSize,
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

                // 2. Elevated Hero Disk
                Container(
                  width: heroSize,
                  height: heroSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF2B2E38), const Color(0xFF1B1D23)]
                          : [Colors.white, const Color(0xFFF1F5F9)],
                    ),
                    border: Border.all(
                      color: isSessionActive
                          ? activeColor
                          : (isSelected
                              ? activeColor
                              : activeColor.withValues(alpha: isDark ? 0.35 : 0.25)),
                      width: (isSessionActive || isSelected) ? 1.8 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSessionActive
                            ? activeColor.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: isSessionActive ? 12.0 : 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner radiant glow when session is active
                      if (isSessionActive)
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                activeColor.withValues(alpha: 0.28),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                      // Center Hourglass Vector Icon
                      SketchNavIcon(
                        type: SketchNavIconType.focus,
                        color: (isSessionActive || isSelected)
                            ? activeColor
                            : (isDark ? Colors.white : AppTheme.inkForeground),
                        size: 21.0,
                        isSelected: isSessionActive || isSelected,
                        strokeWidth: 1.85,
                      ),

                      // Live Status Jewel at top-right
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 7.0,
                          height: 7.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSessionActive
                                ? const Color(0xFF10B981)
                                : activeColor.withValues(alpha: 0.85),
                            boxShadow: [
                              BoxShadow(
                                color: (isSessionActive
                                        ? const Color(0xFF10B981)
                                        : activeColor)
                                    .withValues(alpha: 0.6),
                                blurRadius: 4.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
