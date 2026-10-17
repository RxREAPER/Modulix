import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class InSituHintPill extends StatefulWidget {
  final String prefKey;
  final String message;
  final IconData icon;
  final EdgeInsetsGeometry? margin;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const InSituHintPill({
    super.key,
    required this.prefKey,
    required this.message,
    required this.icon,
    this.margin,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<InSituHintPill> createState() => _InSituHintPillState();
}

class _InSituHintPillState extends State<InSituHintPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  bool _isSeen = true; // Default to true while loading prefs
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _scaleAnim = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _checkPreference();
  }

  Future<void> _checkPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(widget.prefKey) ?? false;
    if (!mounted) return;

    if (seen) {
      setState(() => _isSeen = true);
    } else {
      setState(() => _isSeen = false);
      _controller.forward();
    }
  }

  Future<void> _dismiss() async {
    if (_dismissing || _isSeen) return;
    _dismissing = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, true);

    if (!mounted) return;
    await _controller.reverse();

    if (mounted) {
      setState(() {
        _isSeen = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSeen) {
      return const SizedBox.shrink();
    }

    final bg = widget.backgroundColor ?? AppTheme.primaryBlue.withValues(alpha: 0.08);
    final border = widget.borderColor ?? AppTheme.primaryBlue.withValues(alpha: 0.25);
    final text = widget.textColor ?? AppTheme.primaryBlue;

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: child,
            ),
          ),
        ),
        child: Container(
          margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: text),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.close_rounded,
                size: 13,
                color: text.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
