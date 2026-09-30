import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/focus_timer_provider.dart';

class MiniTimerOverlay extends ConsumerWidget {
  const MiniTimerOverlay({super.key});

  static String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(focusTimerProvider);

    if (!timer.sessionActive) return const SizedBox.shrink();

    final theme = timer.theme;
    final bg = theme.id == 'paper' ? const Color(0xFF1C1C1C) : theme.backgroundColor;
    final accent = theme.accentColor;
    final ink = theme.id == 'paper' ? Colors.white : theme.inkColor;

    return GestureDetector(
      onTap: () => context.push('/timer'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          // Pulsing dot
          _PulsingDot(color: timer.isRunning ? Colors.greenAccent : Colors.orange, paused: !timer.isRunning),
          const SizedBox(width: 10),

          // Subject & task
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(timer.subjectName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ink.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            Text(timer.topicTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w800)),
          ])),

          const SizedBox(width: 8),

          // Timer digits
          Text(
            timer.mode == TimerMode.countUp ? _fmt(timer.focusSecondsElapsed) : _fmt(timer.remainingSeconds),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: accent),
          ),
          const SizedBox(width: 8),

          // Play/Pause
          GestureDetector(
            onTap: () => ref.read(focusTimerProvider.notifier).startOrPause(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: accent.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: accent, size: 16),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool paused;
  const _PulsingDot({required this.color, required this.paused});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (!widget.paused) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot old) {
    super.didUpdateWidget(old);
    if (!widget.paused && !_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    if (widget.paused && _ctrl.isAnimating) { _ctrl.stop(); _ctrl.value = 0.3; }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(_anim.value),
        shape: BoxShape.circle,
      ),
    ),
  );
}
