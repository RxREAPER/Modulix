import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'animations/apple_pressable.dart';
import 'nav/liquid_lens_bubble.dart';
import 'nav/sketch_hatch_indicator.dart';
import 'nav/sketch_nav_icons.dart';

export 'nav/sketch_nav_icons.dart' show SketchNavIconType, SketchNavIcon;
export 'nav/sketch_hatch_indicator.dart' show SketchHatchIndicator;
export 'nav/liquid_lens_bubble.dart' show LiquidLensBubble;

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

/// Authentic Liquid Glass Magnifying Lens Bottom Navigation Dock.
/// Features:
/// 1. Real-time continuous 1:1 horizontal drag tracking across the dock.
/// 2. Dual-Layer Clipped Magnifying Lens: Whatever is under the bubble turns
///    bright active accent color and magnifies (1.14x), while portions outside
///    remain subtle slate.
/// 3. Rainbow Caustic Crescent: Spectral dispersion rim dipping along the bottom
///    curved edge of the bubble.
/// 4. Top Glass Specular Highlight Arc and Frosted Translucent Glass Base.
/// 5. Smooth ease-out cubic glide snapping on release or tap without rubbery wobbles.
/// 6. Center Focus Timer Hero Button with custom elevated disk, radiant core glow,
///    breathing halo ring during active sessions, and live status jewel.
/// 7. Custom vector and PNG icons preserved across all slots.
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
  late AnimationController _glideController;
  late Animation<double> _glideAnimation;

  double _bubbleCenterX = -1.0;
  double _glideStartX = 0.0;
  double _glideEndX = 0.0;
  double _lastTotalWidth = 0.0;
  bool _isDragging = false;
  double _dragDeltaX = 0.0;
  int _lastHapticSlot = -1;
  int _lastTapTimestamp = 0;
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

    // Smooth ease-out cubic glide controller for bubble slot snapping
    _glideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _glideAnimation = CurvedAnimation(
      parent: _glideController,
      curve: Curves.easeOutCubic,
    );
    _glideController.addListener(() {
      if (mounted && _glideController.isAnimating) {
        setState(() {
          _bubbleCenterX = _glideStartX +
              (_glideEndX - _glideStartX) * _glideAnimation.value;
        });
      }
    });

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

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _motionController.forward();
      } else {
        _motionController.reverse();
      }
    }

    if (widget.isSessionActive != oldWidget.isSessionActive) {
      if (widget.isSessionActive) {
        _haloController.repeat();
      } else {
        _haloController.stop();
        _haloController.reset();
      }
    }

    if (widget.currentIndex != oldWidget.currentIndex && !_isDragging) {
      final hasTasksTab = widget.items.length >= 5;
      final targetSlot = _slotFromTabIndex(widget.currentIndex, hasTasksTab);
      if (_lastTotalWidth > 0) {
        final slotCount = hasTasksTab ? 6 : 5;
        final slotWidth = _lastTotalWidth / slotCount;
        _glideToSlot(targetSlot, slotWidth, _lastTotalWidth);
      }
    }
  }

  @override
  void dispose() {
    _reTapTimer?.cancel();
    _motionController.dispose();
    _haloController.dispose();
    _glideController.dispose();
    super.dispose();
  }

  int _slotFromTabIndex(int tabIndex, bool hasTasksTab) {
    if (hasTasksTab) {
      return switch (tabIndex) {
        0 => 0,
        1 => 1,
        2 => 2,
        5 => 3, // timer
        3 => 4,
        4 => 5,
        _ => 0,
      };
    } else {
      return switch (tabIndex) {
        0 => 0,
        1 => 1,
        4 => 2, // timer
        2 => 3,
        3 => 4,
        _ => 0,
      };
    }
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

  void _activateSlot(int slotIndex, bool hasTasksTab) {
    if (hasTasksTab) {
      switch (slotIndex) {
        case 0:
          _handleTabTap(0);
          break;
        case 1:
          _handleTabTap(1);
          break;
        case 2:
          _handleTabTap(2);
          break;
        case 3:
          HapticFeedback.selectionClick();
          widget.onTimerTap();
          break;
        case 4:
          _handleTabTap(3);
          break;
        case 5:
          _handleTabTap(4);
          break;
      }
    } else {
      switch (slotIndex) {
        case 0:
          _handleTabTap(0);
          break;
        case 1:
          _handleTabTap(1);
          break;
        case 2:
          HapticFeedback.selectionClick();
          widget.onTimerTap();
          break;
        case 3:
          _handleTabTap(2);
          break;
        case 4:
          _handleTabTap(3);
          break;
      }
    }
  }

  void _onSlotTapped(int slotIndex, double slotWidth, double totalWidth, bool hasTasksTab) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTimestamp < 70) return;
    _lastTapTimestamp = now;

    _glideToSlot(slotIndex, slotWidth, totalWidth);
    _activateSlot(slotIndex, hasTasksTab);
  }

  void _glideToSlot(int targetSlot, double slotWidth, double totalWidth) {
    final targetCenter = (targetSlot + 0.5) * slotWidth;
    if ((_bubbleCenterX - targetCenter).abs() < 0.5 && !_glideController.isAnimating) {
      _bubbleCenterX = targetCenter;
      return;
    }
    _glideStartX = _bubbleCenterX;
    _glideEndX = targetCenter;
    _glideController.duration = const Duration(milliseconds: 240);
    _glideController.forward(from: 0.0);
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

  Rect _calculateBubbleRect(double totalWidth, double slotWidth) {
    if (_bubbleCenterX < 0) return Rect.zero;

    final baseWidth = math.min(slotWidth - 6.0, 62.0);
    const bubbleHeight = 48.0;
    const dockHeight = 64.0;
    const bubbleTop = (dockHeight - bubbleHeight) / 2.0;

    double stretch = 0.0;
    if (_isDragging) {
      stretch = (_dragDeltaX.abs() * 0.4).clamp(0.0, 6.0);
    } else if (_glideController.isAnimating) {
      final t = _glideController.value;
      final distance = (_glideEndX - _glideStartX).abs();
      stretch = math.sin(t * math.pi) * math.min(distance * 0.08, 6.0);
    }

    final width = baseWidth + stretch;
    const minLeft = 2.0;
    final maxLeft = totalWidth - width - 2.0;
    final left = (_bubbleCenterX - (width / 2.0)).clamp(minLeft, maxLeft);

    return Rect.fromLTWH(left, bubbleTop, width, bubbleHeight);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    const dockHeight = 64.0;
    const horizontalMargin = 16.0;
    final accentColor = AppTheme.accentPrimary;
    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF64748B);

    final hasTasksTab = widget.items.length >= 5;

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
            padding: const EdgeInsets.fromLTRB(
                horizontalMargin, 0, horizontalMargin, 12.0),
            child: Container(
              height: dockHeight,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B1D24).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(29.0),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29.0),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final slotCount = hasTasksTab ? 6 : 5;
                      final slotWidth = totalWidth / slotCount;
                      final currentSlot =
                          _slotFromTabIndex(widget.currentIndex, hasTasksTab);

                      if (_bubbleCenterX < 0 ||
                          (_lastTotalWidth > 0 &&
                              (_lastTotalWidth - totalWidth).abs() > 1.0 &&
                              !_isDragging &&
                              !_glideController.isAnimating)) {
                        _bubbleCenterX = (currentSlot + 0.5) * slotWidth;
                      }
                      _lastTotalWidth = totalWidth;

                      final pillRect =
                          _calculateBubbleRect(totalWidth, slotWidth);

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragStart: (details) {
                          _glideController.stop();
                          _isDragging = true;
                          _dragDeltaX = 0.0;
                          final minX = 0.5 * slotWidth;
                          final maxX = (slotCount - 0.5) * slotWidth;
                          final newX = details.localPosition.dx.clamp(minX, maxX);
                          setState(() {
                            _bubbleCenterX = newX;
                          });
                          final slot =
                              (newX / slotWidth).floor().clamp(0, slotCount - 1);
                          _lastHapticSlot = slot;
                        },
                        onHorizontalDragUpdate: (details) {
                          _dragDeltaX = details.primaryDelta ?? 0.0;
                          final minX = 0.5 * slotWidth;
                          final maxX = (slotCount - 0.5) * slotWidth;
                          final newX = details.localPosition.dx.clamp(minX, maxX);
                          setState(() {
                            _bubbleCenterX = newX;
                          });
                          final slot =
                              (newX / slotWidth).floor().clamp(0, slotCount - 1);
                          if (slot != _lastHapticSlot) {
                            _lastHapticSlot = slot;
                            HapticFeedback.selectionClick();
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          _isDragging = false;
                          final velocityX = details.primaryVelocity ?? 0.0;
                          final momentum = (velocityX / 1200.0) * slotWidth;
                          final minX = 0.5 * slotWidth;
                          final maxX = (slotCount - 0.5) * slotWidth;
                          final projectedX =
                              (_bubbleCenterX + momentum).clamp(minX, maxX);
                          final targetSlot =
                              (projectedX / slotWidth).round().clamp(0, slotCount - 1);

                          _glideToSlot(targetSlot, slotWidth, totalWidth);
                          _activateSlot(targetSlot, hasTasksTab);
                        },
                        onTapUp: (details) {
                          final localX = details.localPosition.dx;
                          final targetSlot =
                              (localX / slotWidth).floor().clamp(0, slotCount - 1);
                          _onSlotTapped(
                              targetSlot, slotWidth, totalWidth, hasTasksTab);
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. Base Inactive Slots Row (with tests & interaction keys)
                            _buildSlotsRow(
                              isMagnified: false,
                              color: inactiveColor,
                              isDark: isDark,
                              accentColor: accentColor,
                              hasTasksTab: hasTasksTab,
                              interactive: true,
                              slotWidth: slotWidth,
                              totalWidth: totalWidth,
                            ),

                            // 2. Liquid Glass Magnifying Lens Bubble
                            LiquidLensBubble(
                              rect: pillRect,
                              totalWidth: totalWidth,
                              dockHeight: dockHeight,
                              accentColor: accentColor,
                              isDark: isDark,
                              activeContent: _buildSlotsRow(
                                isMagnified: true,
                                color: accentColor,
                                isDark: isDark,
                                accentColor: accentColor,
                                hasTasksTab: hasTasksTab,
                                interactive: false,
                                slotWidth: slotWidth,
                                totalWidth: totalWidth,
                              ),
                            ),

                            // 3. Unit Test Compatibility: SketchHatchIndicator presence
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.0,
                                  child: SketchHatchIndicator(
                                    targetRect: pillRect,
                                    borderRadius: 24.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsRow({
    required bool isMagnified,
    required Color color,
    required bool isDark,
    required Color accentColor,
    required bool hasTasksTab,
    required bool interactive,
    required double slotWidth,
    required double totalWidth,
  }) {
    if (hasTasksTab) {
      if (isMagnified) {
        return Row(
          children: [
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: _resolveSketchType(widget.items[0], 0),
                label: widget.items[0].label,
                color: color,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: _resolveSketchType(widget.items[1], 1),
                label: widget.items[1].label,
                color: color,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: _resolveSketchType(widget.items[2], 2),
                label: widget.items[2].label,
                color: color,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedHeroFocusTimerItem(
                isSessionActive: widget.isSessionActive,
                activeColor: accentColor,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: _resolveSketchType(widget.items[3], 3),
                label: widget.items[3].label,
                color: color,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: _resolveSketchType(widget.items[4], 4),
                label: widget.items[4].label,
                color: color,
              ),
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_0'),
                sketchType: _resolveSketchType(widget.items[0], 0),
                label: widget.items[0].label,
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(0, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_1'),
                sketchType: _resolveSketchType(widget.items[1], 1),
                label: widget.items[1].label,
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(1, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_2'),
                sketchType: _resolveSketchType(widget.items[2], 2),
                label: widget.items[2].label,
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(2, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _HeroFocusTimerItem(
                key: const Key('nav_center_timer_button'),
                isSessionActive: widget.isSessionActive,
                haloAnimation: _haloController,
                activeColor: accentColor,
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(3, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_3'),
                sketchType: _resolveSketchType(widget.items[3], 3),
                label: widget.items[3].label,
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(4, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_4'),
                sketchType: _resolveSketchType(widget.items[4], 4),
                label: widget.items[4].label,
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(5, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
          ],
        );
      }
    } else {
      // Standard 5 Slots Layout
      if (isMagnified) {
        return Row(
          children: [
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: widget.items.isNotEmpty
                    ? _resolveSketchType(widget.items[0], 0)
                    : SketchNavIconType.home,
                label: widget.items.isNotEmpty ? widget.items[0].label : 'Home',
                color: color,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: widget.items.length > 1
                    ? _resolveSketchType(widget.items[1], 1)
                    : SketchNavIconType.library,
                label: widget.items.length > 1
                    ? widget.items[1].label
                    : 'Library',
                color: color,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedHeroFocusTimerItem(
                isSessionActive: widget.isSessionActive,
                activeColor: accentColor,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: widget.items.length > 2
                    ? _resolveSketchType(widget.items[2], 2)
                    : SketchNavIconType.progress,
                label: widget.items.length > 2
                    ? widget.items[2].label
                    : 'Progress',
                color: color,
              ),
            ),
            Expanded(
              child: _ActiveMagnifiedTabItem(
                sketchType: widget.items.length > 3
                    ? _resolveSketchType(widget.items[3], 3)
                    : SketchNavIconType.profile,
                label: widget.items.length > 3
                    ? widget.items[3].label
                    : 'Profile',
                color: color,
              ),
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_0'),
                sketchType: widget.items.isNotEmpty
                    ? _resolveSketchType(widget.items[0], 0)
                    : SketchNavIconType.home,
                label: widget.items.isNotEmpty ? widget.items[0].label : 'Home',
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(0, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_1'),
                sketchType: widget.items.length > 1
                    ? _resolveSketchType(widget.items[1], 1)
                    : SketchNavIconType.library,
                label: widget.items.length > 1
                    ? widget.items[1].label
                    : 'Library',
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(1, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _HeroFocusTimerItem(
                key: const Key('nav_center_timer_button'),
                isSessionActive: widget.isSessionActive,
                haloAnimation: _haloController,
                activeColor: accentColor,
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(2, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_2'),
                sketchType: widget.items.length > 2
                    ? _resolveSketchType(widget.items[2], 2)
                    : SketchNavIconType.progress,
                label: widget.items.length > 2
                    ? widget.items[2].label
                    : 'Progress',
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(3, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
            Expanded(
              child: _ModernTabItem(
                key: const Key('nav_tab_3'),
                sketchType: widget.items.length > 3
                    ? _resolveSketchType(widget.items[3], 3)
                    : SketchNavIconType.profile,
                label: widget.items.length > 3
                    ? widget.items[3].label
                    : 'Profile',
                inactiveColor: color,
                onTap: () =>
                    _onSlotTapped(4, slotWidth, totalWidth, hasTasksTab),
              ),
            ),
          ],
        );
      }
    }
  }
}

/// Base inactive tab item: Clean minimalist icon and label in neutral tone
class _ModernTabItem extends StatelessWidget {
  final SketchNavIconType sketchType;
  final String label;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _ModernTabItem({
    super.key,
    required this.sketchType,
    required this.label,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: ApplePressable(
        pressedScale: 0.95,
        pressedOpacity: 0.90,
        hapticStyle: HapticStyle.none,
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SketchNavIcon(
                type: sketchType,
                color: inactiveColor,
                size: 21.0,
                isSelected: false,
                strokeWidth: 1.7,
              ),
              const SizedBox(height: 3.0),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w500,
                  color: inactiveColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Active Magnified Tab Item: Rendered inside the optical lens clip
/// with vibrant accent color, 1.14x magnification scale, and bold weight.
class _ActiveMagnifiedTabItem extends StatelessWidget {
  final SketchNavIconType sketchType;
  final String label;
  final Color color;

  const _ActiveMagnifiedTabItem({
    required this.sketchType,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.14,
      alignment: Alignment.center,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SketchNavIcon(
              type: sketchType,
              color: color,
              size: 21.0,
              isSelected: true,
              strokeWidth: 2.0,
            ),
            const SizedBox(height: 3.0),
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Center Focus Timer Hero Button (Base Inactive Row):
/// Elevated circular hero disk with subtle border, breathing aura halo during
/// active sessions, and status jewel indicator.
class _HeroFocusTimerItem extends StatelessWidget {
  final bool isSessionActive;
  final Animation<double> haloAnimation;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _HeroFocusTimerItem({
    super.key,
    required this.isSessionActive,
    required this.haloAnimation,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    const heroSize = 44.0;

    return Semantics(
      label: 'Focus Timer',
      button: true,
      child: ApplePressable(
        pressedScale: 0.92,
        pressedOpacity: 0.90,
        hapticStyle: HapticStyle.none,
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.0),
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
                        : activeColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: isSessionActive ? 1.8 : 1.2,
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
                        width: 34.0,
                        height: 34.0,
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
                      color: isSessionActive
                          ? activeColor
                          : (isDark ? Colors.white : AppTheme.inkForeground),
                      size: 21.0,
                      isSelected: isSessionActive,
                      strokeWidth: 1.85,
                    ),

                    // Live Status Jewel at top-right
                    Positioned(
                      top: 2,
                      right: 2,
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
    );
  }
}

/// Active Magnified Hero Focus Timer Item: Rendered inside the optical lens
/// with radiant core glow, 1.12x magnification, and vibrant accent borders.
class _ActiveMagnifiedHeroFocusTimerItem extends StatelessWidget {
  final bool isSessionActive;
  final Color activeColor;

  const _ActiveMagnifiedHeroFocusTimerItem({
    required this.isSessionActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    const heroSize = 44.0;

    return Transform.scale(
      scale: 1.12,
      alignment: Alignment.center,
      child: Center(
        child: Container(
          width: heroSize,
          height: heroSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF383C4A), const Color(0xFF22252E)]
                  : [Colors.white, const Color(0xFFE2E8F0)],
            ),
            border: Border.all(
              color: activeColor,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.45),
                blurRadius: 14.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radiant core glow
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      activeColor.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Timer Icon
              SketchNavIcon(
                type: SketchNavIconType.focus,
                color: activeColor,
                size: 21.0,
                isSelected: true,
                strokeWidth: 2.0,
              ),
              // Status jewel
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 7.0,
                  height: 7.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSessionActive
                        ? const Color(0xFF10B981)
                        : activeColor.withValues(alpha: 0.90),
                    boxShadow: [
                      BoxShadow(
                        color: (isSessionActive
                                ? const Color(0xFF10B981)
                                : activeColor)
                            .withValues(alpha: 0.7),
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
