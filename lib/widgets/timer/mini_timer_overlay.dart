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
                    color: Colors.black.withValues(alpha: 0.28),
                    offset: const Offset(0, 4),
                    blurRadius: 14,
                  ),
                  if (timer.isRunning)
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      offset: const Offset(0, 2),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular progress ring hugging the timer
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: timer.mode == TimerMode.countUp
                          ? (displaySeconds % 60) / 60.0
                          : (timer.pomodoroPresetMins > 0
                              ? ((timer.pomodoroPresetMins * 60 - displaySeconds) /
                                      (timer.pomodoroPresetMins * 60))
                                  .clamp(0.0, 1.0)
                              : 0.0),
                      strokeWidth: 2.2,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bound task subject badge if task is active
                  if (timer.isTaskBound) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        timer.subjectId.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

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
                    color: Colors.white.withValues(alpha: 0.4),
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

