import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/focus_timer_provider.dart';
import '../../services/ambient_audio_service.dart';
import '../../widgets/timer/ambient_sound_sheet.dart';
import '../../widgets/timer/timer_background_picker.dart';
import '../../widgets/timer/task_picker_sheet.dart';
import 'fullscreen_timer_screen.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  final String? initialSubjectName;
  final String? initialTopicId;
  final String? initialTopicTitle;
  final String? initialChapterName;
  final String initialTopicType;
  final int? initialDurationMins;

  const FocusTimerScreen({
    super.key,
    this.initialSubjectId,
    this.initialSubjectName,
    this.initialTopicId,
    this.initialTopicTitle,
    this.initialChapterName,
    this.initialTopicType = 'standalone',
    this.initialDurationMins,
  });

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Enter fullscreen automatically
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Seed task from external caller (e.g. module timeline)
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSetTask());
  }

  @override
  void dispose() {
    // Restore system UI only when leaving the timer
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _maybeSetTask() {
    if (_initialized) return;
    _initialized = true;
    if (widget.initialSubjectId != null) {
      ref.read(focusTimerProvider.notifier).setTask(
        subjectId: widget.initialSubjectId!,
        subjectName: widget.initialSubjectName ?? widget.initialSubjectId!,
        topicId: widget.initialTopicId,
        topicTitle: widget.initialTopicTitle ?? 'Study Session',
        chapterName: widget.initialChapterName ?? '',
        topicType: widget.initialTopicType,
        durationMins: widget.initialDurationMins,
      );
    }
  }

  String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _fmtFull(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  void _handleFinish(BuildContext ctx) async {
    final notifier = ref.read(focusTimerProvider.notifier);
    final timerState = ref.read(focusTimerProvider);
    final log = await notifier.finishSession();

    if (!mounted) return;

    // Show session summary dialog
    await showDialog(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.65),
      barrierDismissible: false,
      builder: (dCtx) => _SessionDoneDialog(
        subjectName: timerState.subjectName,
        topicTitle: timerState.topicTitle,
        focusSecs: timerState.focusSecondsElapsed,
        breakSecs: timerState.breakSecondsElapsed,
        modeName: _modeName(timerState.mode),
        onViewAnalytics: () {
          Navigator.of(dCtx).pop();
          context.go('/curriculum/${timerState.subjectId}/analytics');
        },
        onStartAnother: () {
          Navigator.of(dCtx).pop();
          notifier.reset();
        },
      ),
    );
  }

  String _modeName(TimerMode m) {
    switch (m) {
      case TimerMode.pomodoro: return 'Pomodoro';
      case TimerMode.countUp: return 'Count-Up';
      case TimerMode.moduleLinked: return 'Module-Linked';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(focusTimerProvider);
    final notifier = ref.read(focusTimerProvider.notifier);
    final theme = timer.theme;
    final sndActive = timer.activeSoundId != 'none';

    final displaySecs = timer.mode == TimerMode.countUp
        ? timer.focusSecondsElapsed
        : timer.remainingSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
      body: Stack(fit: StackFit.expand, children: [
        // Live GIF Background - rich, vibrant, immersive
        if (theme.gifUrl != null)
          Positioned.fill(
            child: Image.network(
              theme.gifUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),

        // Dark vignette overlay only at top and bottom edges so user sees the vivid background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.transparent,
                  Colors.black.withOpacity(0.65),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // UI
        SafeArea(child: Column(children: [
          // ── TOP BAR ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              // Background Picker
              _GlassBtn(
                icon: Icons.palette_outlined,
                color: theme.inkColor,
                onTap: () => TimerBackgroundPicker.show(context,
                  activeTheme: theme,
                  onSelectTheme: notifier.setTheme),
              ),
              const SizedBox(width: 8),
              // Ambient Sound
              _GlassBtn(
                icon: sndActive ? Icons.graphic_eq_rounded : Icons.volume_off_rounded,
                color: sndActive ? theme.accentColor : theme.inkColor,
                pulsing: sndActive,
                onTap: () => AmbientSoundSheet.show(context,
                  activeSoundId: timer.activeSoundId,
                  onSelectSound: (id) {
                    notifier.setSound(id);
                    AmbientAudioService.instance.playSound(id);
                  }),
              ),
              const SizedBox(width: 8),
              // Fullscreen Flip Clock
              _GlassBtn(
                icon: Icons.fullscreen_rounded,
                color: theme.inkColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FullscreenTimerScreen())),
              ),
              const Spacer(),
              // Prominent close cross at the top right
              _GlassBtn(
                icon: Icons.close_rounded,
                color: Colors.white,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // ── TASK CARD ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => TaskPickerSheet.show(context, onSelect: (task) {
                notifier.setTask(
                  subjectId: task.subjectId, subjectName: task.subjectName,
                  topicId: task.topicId, topicTitle: task.topicTitle,
                  chapterName: task.chapterName, topicType: task.topicType,
                  durationMins: task.presetDurationMins,
                );
              }),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.32),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      Icon(_topicIcon(timer.topicType), color: theme.accentColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(timer.subjectName.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                            letterSpacing: 1.0, color: theme.accentColor)),
                        Text(timer.topicTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.inkColor)),
                      ])),
                      Icon(Icons.tune_rounded, color: theme.inkColor.withOpacity(0.5), size: 16),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── MODE BUTTON ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ModeButton(mode: timer.mode, theme: theme, onChanged: notifier.changeMode),
          ),

          // ── PRESETS ────────────────────────────────────────────────────
          if (timer.mode == TimerMode.pomodoro) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [15, 25, 45, 60].map((mins) {
                final sel = timer.pomodoroPresetMins == mins;
                return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: GestureDetector(
                    onTap: () => notifier.setPomodoroPreset(mins),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel
                                ? theme.accentColor.withOpacity(0.85)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.25),
                              width: 1.4,
                            ),
                          ),
                          child: Text('${mins}m', style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800,
                            color: sel ? Colors.white : theme.inkColor)),
                        ),
                      ),
                    ),
                  ));
              }).toList()),
          ] else if (timer.mode == TimerMode.moduleLinked) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _GlassBtn(icon: Icons.remove, color: theme.inkColor, onTap: () => notifier.setModulePreset(timer.modulePresetMins - 5)),
              const SizedBox(width: 12),
              Text('${timer.modulePresetMins}m', style: TextStyle(color: theme.inkColor, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              _GlassBtn(icon: Icons.add, color: theme.inkColor, onTap: () => notifier.setModulePreset(timer.modulePresetMins + 5)),
            ]),
          ],

          const Spacer(),

          // ── BIG TIMER DISPLAY ─────────────────────────────────────────
          Text(
            _fmtFull(displaySecs),
            style: TextStyle(
              fontSize: 76,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: theme.inkColor,
              letterSpacing: -2,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 6),

          // Phase label
          Text(
            timer.isBreak ? '☕  BREAK' : timer.isRunning ? '🔥  FOCUSING' : '○  READY',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4,
              color: timer.isBreak ? Colors.orange.shade400
                  : timer.isRunning ? Colors.green.shade400
                  : theme.inkColor.withOpacity(0.4)),
          ),

          const SizedBox(height: 18),

          // ── BREAK + TOTAL (plain text, no box) ───────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Break  ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: theme.inkColor.withOpacity(0.4))),
            Text(_fmt(timer.breakSecondsElapsed),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                fontFamily: 'monospace', color: theme.inkColor.withOpacity(0.6))),
            Text('   ·   Total  ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: theme.inkColor.withOpacity(0.4))),
            Text(_fmt(timer.focusSecondsElapsed + timer.breakSecondsElapsed),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                fontFamily: 'monospace', color: theme.accentColor)),
          ]),

          const Spacer(),

          // ── BOTTOM CONTROLS ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(children: [
              // Break toggle
              _ControlBtn(
                icon: timer.isBreak ? Icons.coffee_rounded : Icons.coffee_outlined,
                label: timer.isBreak ? 'End Break' : 'Break',
                color: timer.isBreak ? theme.accentColor : theme.inkColor.withOpacity(0.7),
                bg: theme.inkColor.withOpacity(0.08),
                onTap: notifier.toggleBreak,
              ),
              const SizedBox(width: 12),

              // Main play/pause — bigger with visible glass border
              Expanded(child: GestureDetector(
                onTap: notifier.startOrPause,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: timer.isRunning
                            ? theme.inkColor.withOpacity(0.85)
                            : theme.accentColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (timer.isRunning ? theme.inkColor : theme.accentColor).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white, size: 26),
                        const SizedBox(width: 6),
                        Text(timer.isRunning ? 'PAUSE' : 'START',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8)),
                      ]),
                    ),
                  ),
                ),
              )),

              const SizedBox(width: 12),

              // Finish
              _ControlBtn(
                icon: Icons.check_rounded,
                label: 'Finish',
                color: timer.sessionActive ? Colors.green.shade400 : theme.inkColor.withOpacity(0.3),
                bg: theme.inkColor.withOpacity(0.08),
                onTap: timer.sessionActive ? () => _handleFinish(context) : null,
              ),
            ]),
          ),
        ])),
      ]),
    ),
  );
}

  IconData _topicIcon(String type) {
    switch (type) {
      case 'video': return Icons.play_arrow_rounded;
      case 'qbank': return Icons.quiz_outlined;
      case 'notes': return Icons.menu_book_outlined;
      default: return Icons.task_alt_rounded;
    }
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool pulsing;

  const _GlassBtn({required this.icon, required this.color, this.onTap, this.pulsing = false});

  @override
  Widget build(BuildContext context) {
    Widget iconW = Icon(icon, color: color, size: 20);
    if (pulsing) {
      iconW = SoundHumIcon(isActive: true, color: color, size: 20);
    }
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: iconW),
          ),
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const _ControlBtn({required this.icon, required this.label, required this.color, required this.bg, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 66, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ),
    ),
  );
}

class _ModeButton extends StatelessWidget {
  final TimerMode mode;
  final dynamic theme;
  final ValueChanged<TimerMode> onChanged;

  const _ModeButton({required this.mode, required this.theme, required this.onChanged});

  String get _label {
    switch (mode) {
      case TimerMode.pomodoro: return '⏱  Pomodoro';
      case TimerMode.countUp: return '⬆  Count-Up';
      case TimerMode.moduleLinked: return '📌  Module-Linked';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          sheetAnimationStyle: const AnimationStyle(
            duration: Duration(milliseconds: 280),
            reverseDuration: Duration(milliseconds: 220),
          ),
          builder: (_) => _ModePicker(current: mode, theme: theme, onSelect: (m) {
            onChanged(m);
            Navigator.pop(context);
          }),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.inkColor)),
              Icon(Icons.keyboard_arrow_down_rounded, color: theme.inkColor.withOpacity(0.7), size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  final TimerMode current;
  final dynamic theme;
  final ValueChanged<TimerMode> onSelect;

  const _ModePicker({required this.current, required this.theme, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.inkColor.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 5,
          decoration: BoxDecoration(color: theme.inkColor.withOpacity(0.2), borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 18),
        ...[
          (TimerMode.pomodoro, '⏱', 'Pomodoro', 'Countdown with preset lengths 15/25/45/60 min'),
          (TimerMode.countUp, '⬆', 'Count-Up', "Open stopwatch — tracks how long you've studied"),
          (TimerMode.moduleLinked, '📌', 'Module-Linked', 'Pre-seeded from a specific video/QBank/Notes'),
        ].map(((TimerMode m, String emoji, String name, String desc) r) {
          final sel = r.$1 == current;
          return GestureDetector(
            onTap: () => onSelect(r.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? theme.accentColor.withOpacity(0.15) : theme.inkColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? theme.accentColor.withOpacity(0.6) : Colors.transparent,
                  width: 1.5),
              ),
              child: Row(children: [
                Text(r.$2, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$3, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.inkColor)),
                  Text(r.$4, style: TextStyle(fontSize: 11, color: theme.inkColor.withOpacity(0.55))),
                ])),
                if (sel) Icon(Icons.check_circle_rounded, color: theme.accentColor),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// In-file session done dialog to avoid navigation context issues
class _SessionDoneDialog extends StatelessWidget {
  final String subjectName;
  final String topicTitle;
  final int focusSecs;
  final int breakSecs;
  final String modeName;
  final VoidCallback onViewAnalytics;
  final VoidCallback onStartAnother;

  const _SessionDoneDialog({
    required this.subjectName, required this.topicTitle, required this.focusSecs,
    required this.breakSecs, required this.modeName,
    required this.onViewAnalytics, required this.onStartAnother,
  });

  String _fmt(int s) {
    final m = s ~/ 60; final sec = s % 60;
    return '${m}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCFBF8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x221C1C1C), offset: Offset(4, 6), blurRadius: 0)],
          border: Border.all(color: const Color(0xFF1C1C1C), width: 1.8),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 54, height: 54,
            decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 32)),
          const SizedBox(height: 14),
          const Text('Session Done!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C))),
          const SizedBox(height: 4),
          Text(topicTitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
          const SizedBox(height: 16),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [
              Text('FOCUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
              Text(_fmt(focusSecs), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Color(0xFF16A34A))),
            ]),
            const SizedBox(width: 28),
            Column(children: [
              Text('BREAK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
              Text(_fmt(breakSecs), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Colors.grey.shade600)),
            ]),
          ]),

          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: onViewAnalytics,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1C1C1C),
                side: const BorderSide(color: Color(0xFF1C1C1C), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: onStartAnother,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C1C), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Again', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            )),
          ]),
        ]),
      ),
    );
  }
}
