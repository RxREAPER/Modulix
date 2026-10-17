import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Lightweight wrapper that displays a subtle breathing glow ring around
/// hidden or high-leverage interactive controls until the user first interacts with them.
class DiscoveryPulse extends StatefulWidget {
  final String prefKey;
  final Widget child;
  final Color? pulseColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const DiscoveryPulse({
    super.key,
    required this.prefKey,
    required this.child,
    this.pulseColor,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(3.0),
  });

  @override
  State<DiscoveryPulse> createState() => _DiscoveryPulseState();
}

class _DiscoveryPulseState extends State<DiscoveryPulse>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnim;
  Animation<double>? _opacityAnim;
  bool _isSeen = true;

  @override
  void initState() {
    super.initState();
    _checkPreference();
  }

  Future<void> _checkPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(widget.prefKey) ?? false;
    if (!mounted) return;

    if (!seen) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat(reverse: true);

      _scaleAnim = Tween<double>(begin: 1.0, end: 1.10).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOutCubic),
      );

      _opacityAnim = Tween<double>(begin: 0.25, end: 0.70).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOutCubic),
      );

      setState(() => _isSeen = false);
    }
  }

  Future<void> _markDiscovered() async {
    if (_isSeen) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, true);

    if (!mounted) return;
    _controller?.stop();
    setState(() => _isSeen = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSeen || _controller == null) {
      return widget.child;
    }

    final color = widget.pulseColor ?? AppTheme.primaryBlue;

    return Listener(
      onPointerDown: (_) => _markDiscovered(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _controller!,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnim?.value ?? 1.0,
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius + 3),
                    border: Border.all(
                      color: color.withValues(alpha: _opacityAnim?.value ?? 0.4),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: (_opacityAnim?.value ?? 0.4) * 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: Opacity(
                        opacity: 0.0,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}
