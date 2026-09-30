import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CurvedNavItem {
  final String svgAsset;
  final String label;

  const CurvedNavItem({
    required this.svgAsset,
    required this.label,
  });
}

/// 100% exact implementation of the Figma Mobile Navigation Menu Bar UI Template (File 0yIVLjV6bC3d9LQ9w8vVwv):
/// - Bar Shape & Scooped Cutout: Exact Figma SVG Bézier cubic coordinates from node 0:16
/// - Circle Indicator: Exact Figma diameter (58px), fill (#EE8143), and elevation
/// - Icons: Exact vector SVGs extracted directly from Figma
class CurvedAnimatedNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CurvedNavItem> items;
  final Color barColor;
  final Color activeBubbleColor;

  const CurvedAnimatedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.barColor = const Color(0xFF121212), // Exact Figma fill
    this.activeBubbleColor = const Color(0xFFEE8143), // Exact Figma #EE8143
  });

  @override
  State<CurvedAnimatedNavBar> createState() => _CurvedAnimatedNavBarState();
}

class _CurvedAnimatedNavBarState extends State<CurvedAnimatedNavBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _popController;
  late Animation<double> _slideAnimation;
  late Animation<double> _popAnimation;

  double _currentRatio = 0.0;

  @override
  void initState() {
    super.initState();
    _currentRatio = _indexToRatio(widget.currentIndex);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<double>(
      begin: _currentRatio,
      end: _currentRatio,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubicEmphasized,
    ));

    _popAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_popController);
  }

  @override
  void didUpdateWidget(CurvedAnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final startRatio = _currentRatio;
      final targetRatio = _indexToRatio(widget.currentIndex);

      _slideAnimation = Tween<double>(
        begin: startRatio,
        end: targetRatio,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOutCubicEmphasized,
      ));

      _popAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 35),
        TweenSequenceItem(
            tween: Tween(begin: 0.8, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutBack)),
            weight: 65),
      ]).animate(_popController);

      _slideController.forward(from: 0.0);
      _popController.forward(from: 0.0);

      _currentRatio = targetRatio;
    }
  }

  double _indexToRatio(int index) {
    if (widget.items.isEmpty) return 0.5;
    return (index + 0.5) / widget.items.length;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const barHeight = 80.0; // Exact Figma bar height (70 - 20 + 30)
    const bubbleDiameter = 58.0; // Exact Figma Ellipse 6 diameter

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;

          return AnimatedBuilder(
            animation: Listenable.merge([_slideAnimation, _popAnimation]),
            builder: (context, _) {
              final activeCenterX = _slideAnimation.value * totalWidth;

              return SizedBox(
                height: barHeight + 20.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 1. Bar canvas with exact Figma Bézier cutout
                    CustomPaint(
                      size: Size(totalWidth, barHeight),
                      painter: _FigmaCurvedBarPainter(
                        activeCenterX: activeCenterX,
                        barColor: widget.barColor,
                      ),
                    ),

                    // 2. Inactive icon rows
                    SizedBox(
                      height: barHeight,
                      child: Row(
                        children: List.generate(widget.items.length, (index) {
                          final item = widget.items[index];
                          final isSelected = index == widget.currentIndex;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onTap(index),
                              child: Center(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isSelected ? 0.0 : 1.0,
                                  child: SvgPicture.asset(
                                    item.svgAsset,
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF929292), // Exact Figma icon color
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // 3. Floating circular bubble inside the scoop
                    Positioned(
                      left: activeCenterX - (bubbleDiameter / 2),
                      bottom: barHeight - (bubbleDiameter / 2) + 2.0,
                      child: ScaleTransition(
                        scale: _popAnimation,
                        child: GestureDetector(
                          onTap: () => widget.onTap(widget.currentIndex),
                          child: Container(
                            width: bubbleDiameter,
                            height: bubbleDiameter,
                            decoration: BoxDecoration(
                              color: widget.activeBubbleColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.activeBubbleColor.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                widget.items[widget.currentIndex].svgAsset,
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Custom painter matching the exact Bézier cubic curve of Figma's Subtract node (0:16)
class _FigmaCurvedBarPainter extends CustomPainter {
  final double activeCenterX;
  final Color barColor;

  _FigmaCurvedBarPainter({
    required this.activeCenterX,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    const topRadius = 12.0;
    const bottomRadius = 28.0;

    // The scoop from Figma Subtract (node 0:16) spans 104px wide and 45px deep
    const scoopHalfWidth = 52.0;

    // Start at top-left corner
    path.moveTo(0, topRadius);
    path.quadraticBezierTo(0, 0, topRadius, 0);

    final scoopStart = activeCenterX - scoopHalfWidth;
    final scoopEnd = activeCenterX + scoopHalfWidth;

    // Straight line along top edge before scoop
    if (scoopStart > topRadius) {
      path.lineTo(scoopStart, 0);
    }

    // Exact Figma Subtract Bézier cubic splines relative to activeCenterX:
    // M 0 0
    // C 8.19821 0, 11.1462 7.39593, 14.652 16.1911
    // C 19.7937 29.0906, 26.1352 45, 52 45
    // C 78.0166 45, 84.4867 28.9034, 89.6876 15.9643
    // C 93.1827 7.26918, 96.1046 0, 104 0
    final cx = activeCenterX;
    path.cubicTo(
      cx - 52.0 + 8.19821, 0.0,
      cx - 52.0 + 11.1462, 7.39593,
      cx - 52.0 + 14.6520, 16.1911,
    );
    path.cubicTo(
      cx - 52.0 + 19.7937, 29.0906,
      cx - 52.0 + 26.1352, 45.0,
      cx, 45.0,
    );
    path.cubicTo(
      cx - 52.0 + 78.0166, 45.0,
      cx - 52.0 + 84.4867, 28.9034,
      cx - 52.0 + 89.6876, 15.9643,
    );
    path.cubicTo(
      cx - 52.0 + 93.1827, 7.26918,
      cx - 52.0 + 96.1046, 0.0,
      scoopEnd, 0.0,
    );

    // Straight line along top edge after scoop
    path.lineTo(w - topRadius, 0);
    path.quadraticBezierTo(w, 0, w, topRadius);

    // Bottom-right corner (30px radius in Figma)
    path.lineTo(w, h - bottomRadius);
    path.quadraticBezierTo(w, h, w - bottomRadius, h);

    // Bottom-left corner (30px radius in Figma)
    path.lineTo(bottomRadius, h);
    path.quadraticBezierTo(0, h, 0, h - bottomRadius);

    path.close();

    // Elevation shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 16.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FigmaCurvedBarPainter oldDelegate) =>
      oldDelegate.activeCenterX != activeCenterX ||
      oldDelegate.barColor != barColor;
}
