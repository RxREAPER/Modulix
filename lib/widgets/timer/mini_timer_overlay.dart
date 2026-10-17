import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/focus_timer_provider.dart';
import '../../theme/app_theme.dart';

class MiniTimerOverlay extends ConsumerStatefulWidget {
  const MiniTimerOverlay({super.key});

  @override
  ConsumerState<MiniTimerOverlay> createState() => _MiniTimerOverlayState();
}

class _MiniTimerOverlayState extends ConsumerState<MiniTimerOverlay> {
  bool _dockedAtTop = false;
  bool _isDragging = false;
  double? _dragCurrentY;
  double _dragStartY = 0;
  bool _movedSignificantly = false;

  static String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(focusTimerProvider);

    if (!timer.sessionActive) return const SizedBox.shrink();

    final mediaQuery = MediaQuery.of(context);
    final topSpot = mediaQuery.padding.top + 14.0;
    // Bottom spot sits cleanly above bottom navigation bar
    final bottomSpot = mediaQuery.size.height - (kBottomNavigationBarHeight + 84.0);

    final currentY = _isDragging && _dragCurrentY != null
        ? _dragCurrentY!.clamp(topSpot, bottomSpot)
        : (_dockedAtTop ? topSpot : bottomSpot);

    final isBreak = timer.phase == TimerPhase.onBreak;
    final int displaySeconds = isBreak
        ? (timer.mode == TimerMode.countUp
            ? timer.breakSecondsElapsed
            : timer.remainingSeconds)
        : (timer.mode == TimerMode.countUp
            ? timer.focusSecondsElapsed
            : timer.remainingSeconds);

    final theme = timer.theme;
    final accentColor = isBreak
        ? const Color(0xFF2DD4BF)
        : (theme.accentColor != Colors.transparent ? theme.accentColor : const Color(0xFF818CF8));

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      top: currentY,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/timer');
          },
          onVerticalDragStart: (details) {
            _isDragging = true;
            _dragStartY = details.globalPosition.dy;
            _dragCurrentY = currentY;
            _movedSignificantly = false;
          },
          onVerticalDragUpdate: (details) {
            final delta = (details.globalPosition.dy - _dragStartY).abs();
            if (delta > 8 && !_movedSignificantly) {
              _movedSignificantly = true;
            }
            setState(() {
              _dragCurrentY = details.globalPosition.dy - 20;
            });
          },
          onVerticalDragEnd: (details) {
            if (!_movedSignificantly) {
              HapticFeedback.lightImpact();
              setState(() {
                _isDragging = false;
                _dragCurrentY = null;
              });
              context.push('/timer');
              return;
            }

            final midPoint = (topSpot + bottomSpot) / 2;
            final velocity = details.primaryVelocity ?? 0;
            final targetTop = velocity < -250 || (velocity.abs() <= 250 && (_dragCurrentY ?? currentY) < midPoint);

            HapticFeedback.selectionClick();
            setState(() {
              _isDragging = false;
              _dragCurrentY = null;
              _dockedAtTop = targetTop;
            });
          },
          child: AnimatedScale(
            scale: _isDragging ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B), // Sleek deep graphite
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isBreak
                      ? const Color(0xFF0D9488)
                      : (timer.isRunning ? AppTheme.inkForeground : Colors.grey.shade700),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    offset: const Offset(0, 4),
                    blurRadius: 14,
                  ),
                  if (timer.isRunning)
                    BoxShadow(
                      color: accentColor.withOpacity(0.25),
                      offset: const Offset(0, 2),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing status dot indicating focus vs break
                  _CapsulePulsingDot(
                    color: isBreak
                        ? const Color(0xFF2DD4BF)
                        : (timer.isRunning ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24)),
                    isPaused: !timer.isRunning,
                  ),
                  const SizedBox(width: 8),

                  // Elapsed / remaining countdown timer only
                  Text(
                    _fmt(displaySeconds),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: isBreak ? const Color(0xFF5EEAD4) : Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),

                  // Subtle drag indicator pill
                  const SizedBox(width: 7),
                  Icon(
                    _dockedAtTop ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                    size: 15,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsulePulsingDot extends StatefulWidget {
  final Color color;
  final bool isPaused;

  const _CapsulePulsingDot({
    required this.color,
    required this.isPaused,
  });

  @override
  State<_CapsulePulsingDot> createState() => _CapsulePulsingDotState();
}

class _CapsulePulsingDotState extends State<_CapsulePulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    if (!widget.isPaused) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_CapsulePulsingDot old) {
    super.didUpdateWidget(old);
    if (!widget.isPaused && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (widget.isPaused && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0.4;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(widget.isPaused ? 0.4 : _glowAnim.value),
            shape: BoxShape.circle,
            boxShadow: [
              if (!widget.isPaused)
                BoxShadow(
                  color: widget.color.withOpacity(0.6 * _glowAnim.value),
                  blurRadius: 6 * _scaleAnim.value,
                  spreadRadius: 1 * _scaleAnim.value,
                ),
            ],
          ),
        );
      },
    );
  }
}
