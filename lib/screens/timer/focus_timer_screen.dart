import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/timer_theme.dart';
import '../../providers/focus_timer_provider.dart';
import '../../widgets/timer/ambient_sound_sheet.dart';
import '../../widgets/timer/timer_background_picker.dart';
import '../../widgets/timer/task_picker_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'fullscreen_timer_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/in_situ_hint_pill.dart';
import '../../widgets/discovery_pulse.dart';
import '../../widgets/timer/medical_wave_visualizer.dart';

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

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> with WidgetsBindingObserver {
  bool _initialized = false;
  VideoPlayerController? _videoCtrl;
  String? _currentVideoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enter fullscreen automatically
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Keep screen awake if enabled
    final keepAwake = ref.read(focusTimerProvider).keepScreenAwake;
    if (keepAwake) {
      WakelockPlus.enable();
    }
    // Seed task from external caller (e.g. module timeline)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeSetTask();
      _syncBackgroundVideo();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureVideoPlaying();
    }
  }

  void _ensureVideoPlaying() {
    final ctrl = _videoCtrl;
    if (ctrl != null && ctrl.value.isInitialized && !ctrl.value.isPlaying) {
      ctrl.play();
    }
  }

  void _syncBackgroundVideo() {
    final theme = ref.read(focusTimerProvider).theme;
    if (theme.videoAssetPath != _currentVideoPath) {
      _currentVideoPath = theme.videoAssetPath;
      if (_videoCtrl != null) {
        _videoCtrl!.dispose();
        _videoCtrl = null;
      }

      if (theme.videoAssetPath != null) {
        final ctrl = VideoPlayerController.asset(
          theme.videoAssetPath!,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        _videoCtrl = ctrl;
        ctrl.initialize().then((_) {
          if (!mounted) return;
          ctrl.setLooping(true);
          ctrl.setVolume(0.0);
          ctrl.play();
          setState(() {});
        }).catchError((e, st) {
          debugPrint('FocusTimer video initialization failed: $e\n$st');
        });
      } else {
        setState(() {});
      }
    } else {
      _ensureVideoPlaying();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _videoCtrl?.dispose();
    _videoCtrl = null;
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

  String _fmtFull(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _handleFinish(BuildContext ctx) async {
    final notifier = ref.read(focusTimerProvider.notifier);
    final timerState = ref.read(focusTimerProvider);
    await notifier.finishSession();

    if (!mounted || !ctx.mounted) return;

    // Show session summary dialog
    await showDialog(
      context: ctx,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      barrierDismissible: false,
      builder: (dCtx) => _SessionDoneDialog(
        subjectName: timerState.hasTarget ? timerState.subjectName : 'General Focus',
        topicTitle: timerState.hasTarget ? timerState.topicTitle : 'Study Session',
        focusSecs: timerState.focusSecondsElapsed,
        breakSecs: timerState.breakSecondsElapsed,
        modeName: _modeName(timerState.mode),
        theme: timerState.theme,
        isLight: timerState.theme.isLight,
        onDone: () {
          Navigator.of(dCtx).pop();
          notifier.reset();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
        onViewAnalytics: () {
          Navigator.of(dCtx).pop();
          notifier.reset();
          context.go('/curriculum/${timerState.subjectId}/analytics');
        },
        onStartAnother: () {
          Navigator.of(dCtx).pop();
          notifier.resetSessionForSameTask();
        },
      ),
    );
  }

  void _showCustomMinutesDialog({
    required BuildContext context,
    required String title,
    required int currentMins,
    required int minMins,
    required int maxMins,
    required ValueChanged<int> onSave,
  }) {
    final controller = TextEditingController(text: currentMins.toString());
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderLight),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.inkForeground),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter exact duration in minutes:',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.inkForeground),
              decoration: InputDecoration(
                suffixText: 'mins',
                suffixStyle: TextStyle(fontSize: 14, color: AppTheme.mutedText, fontWeight: FontWeight.w600),
                filled: true,
                fillColor: AppTheme.parchmentSurface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mutedText, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= minMins && val <= maxMins) {
                onSave(val);
                Navigator.of(dCtx).pop();
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
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
    ref.listen<bool>(
      focusTimerProvider.select((s) => s.keepScreenAwake),
      (prev, next) {
        if (next) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }
      },
    );

    ref.listen<String?>(
      focusTimerProvider.select((s) => s.theme.videoAssetPath),
      (prev, next) {
        if (prev != next) {
          _syncBackgroundVideo();
        }
      },
    );

    final timer = ref.watch(focusTimerProvider);
    final notifier = ref.read(focusTimerProvider.notifier);
    final theme = timer.theme;
    final isLight = theme.isLight;
    final sndActive = timer.activeSoundId != 'none' || AmbientAudioService.instance.isPlaying;

    final displaySecs = !timer.hasTarget
        ? 0
        : (timer.mode == TimerMode.countUp
            ? timer.focusSecondsElapsed
            : timer.remainingSeconds);

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        try {
          context.go('/');
        } catch (_) {}
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── LIVE VIDEO / ASSET BACKGROUND ──────────────────────────
            if (theme.hasVideo && _videoCtrl != null && _videoCtrl!.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoCtrl!.value.size.width,
                    height: _videoCtrl!.value.size.height,
                    child: VideoPlayer(_videoCtrl!),
                  ),
                ),
              )
            else if (theme.thumbnailAssetPath != null)
              Positioned.fill(
                child: Image.asset(
                  theme.thumbnailAssetPath!,
                  fit: BoxFit.cover,
                ),
              ),

            // Subtle dark overlay ONLY when live video/custom background is active
            if (theme.hasVideo || theme.thumbnailAssetPath != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.52),
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.68),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

            // ── ABSOLUTE CENTERPIECE (DEAD-CENTER OF THE SCREEN) ─────────
            // From Unit heading to Phase badge, centered vertically & horizontally
            // ZERO drop shadows as requested
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1 & 2. Subject & Topic (Tappable to configure)
                    ApplePressable(
                      onTap: () => _SessionConfigSheet.show(
                        context,
                        onShowCustomDialog: _showCustomMinutesDialog,
                      ),
                      pressedScale: 0.97,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              timer.hasTarget
                                  ? timer.subjectName
                                  : 'NO TARGET SELECTED',
                              textAlign: TextAlign.center,
                              style: AppTheme.headingStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isLight ? theme.accentColor : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              timer.hasTarget
                                  ? (timer.chapterName.isNotEmpty
                                      ? '${timer.chapterName} · ${timer.topicTitle}'
                                      : timer.topicTitle)
                                  : 'Select a study target & mode to start',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isLight ? const Color(0xFF64748B) : Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. Study Time: Heading
                    Text(
                      'Study Time:',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 4. BIG TIMER DISPLAY (00:00:00) — Dead-Center, Monospace, No Shadows
                    Text(
                        _fmtFull(displaySecs),
                        style: TextStyle(
                          fontSize: 66,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Acoustic ECG / Frequency Waveform Visualizer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 52),
                      child: MedicalWaveVisualizer(
                        height: 22,
                        color: isLight ? theme.accentColor : Colors.tealAccent.shade200,
                        showBaseline: true,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 5. Total Break Readout
                    Text(
                      'Total Break: ${_fmtFull(timer.breakSecondsElapsed)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: isLight ? const Color(0xFF64748B) : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 6. Total Time Readout
                    Text(
                      'Total Time (Current): ${_fmtFull(timer.focusSecondsElapsed + timer.breakSecondsElapsed)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: isLight ? const Color(0xFF64748B) : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 7. Phase Label Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: (!timer.hasTarget
                                ? const Color(0xFF64748B)
                                : (timer.isBreak
                                    ? const Color(0xFFF59E0B)
                                    : (timer.isRunning
                                        ? const Color(0xFF10B981)
                                        : theme.accentColor)))
                            .withValues(alpha: isLight ? 0.12 : 0.20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        !timer.hasTarget
                            ? '○  AWAITING TARGET'
                            : (timer.isBreak
                                ? '●  BREAK'
                                : (timer.isRunning ? '●  FOCUSING' : '○  READY')),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: !timer.hasTarget
                              ? (isLight ? const Color(0xFF64748B) : Colors.white.withValues(alpha: 0.70))
                              : (timer.isBreak
                                  ? (isLight ? const Color(0xFFD97706) : Colors.orange.shade300)
                                  : (timer.isRunning
                                      ? (isLight ? const Color(0xFF059669) : Colors.green.shade300)
                                      : (isLight ? theme.accentColor : Colors.white))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── TOP CONTROLS: CENTER-UP PILL & RIGHT VERTICAL ACTIONS DOCK ─
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // ── CENTER-UP: "SET-UP" Config Pill (True Horizontal Center)
                      Align(
                        alignment: Alignment.topCenter,
                        child: ApplePressable(
                          onTap: () => _SessionConfigSheet.show(
                            context,
                            onShowCustomDialog: _showCustomMinutesDialog,
                          ),
                          pressedScale: 0.94,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isLight ? Colors.white : Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.35),
                                width: 1.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isLight ? const Color(0x14000000) : Colors.black.withValues(alpha: 0.30),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: theme.accentColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SET-UP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── RIGHT VERTICAL DOCK: X, Palette, Sound, Fullscreen ─
                      Align(
                        alignment: Alignment.topRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 1. Close "X" Button (topmost)
                            _GlassBtn(
                              icon: Icons.close_rounded,
                              isLight: isLight,
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                            ),
                            const SizedBox(height: 10),

                            // 2. Background Theme Palette Button (below X)
                            _GlassBtn(
                              icon: Icons.palette_outlined,
                              isLight: isLight,
                              color: isLight ? const Color(0xFF0F172A) : theme.inkColor,
                              onTap: () => TimerBackgroundPicker.show(
                                context,
                                activeTheme: theme,
                                onSelectTheme: (newTheme) {
                                  notifier.setTheme(newTheme);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _syncBackgroundVideo();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 3. Ambient Sound Button (below Palette)
                            _GlassBtn(
                              icon: sndActive ? Icons.graphic_eq_rounded : Icons.volume_off_rounded,
                              isLight: isLight,
                              color: sndActive
                                  ? const Color(0xFF6C3BAA)
                                  : (isLight ? const Color(0xFF0F172A) : theme.inkColor),
                              pulsing: sndActive,
                              onTap: () => AmbientSoundSheet.show(
                                context,
                                activeSoundId: timer.activeSoundId,
                                onSelectSound: (id) {
                                  notifier.setSound(id);
                                  AmbientAudioService.instance.playSound(id);
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 4. Fullscreen Flip Clock Button (below Sound)
                            DiscoveryPulse(
                              prefKey: 'pulse_flip_clock_seen',
                              pulseColor: isLight ? AppTheme.primaryBlue : theme.accentColor,
                              borderRadius: 14,
                              child: _GlassBtn(
                                icon: Icons.fullscreen_rounded,
                                isLight: isLight,
                                color: isLight ? const Color(0xFF0F172A) : theme.inkColor,
                                onTap: () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: true,
                                    transitionDuration: const Duration(milliseconds: 340),
                                    reverseTransitionDuration: const Duration(milliseconds: 240),
                                    pageBuilder: (_, __, ___) => const FullscreenTimerScreen(),
                                    transitionsBuilder: (_, anim, __, child) {
                                      final curved = CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic,
                                        reverseCurve: Curves.easeInCubic,
                                      );
                                      return ScaleTransition(
                                        scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
                                        child: FadeTransition(opacity: curved, child: child),
                                      );
                                    },
                                  ),
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

            // ── IN-SITU HINT PILL: DOCKING & FLIP CLOCK ───────────────────
            Positioned(
              bottom: 84,
              left: 20,
              right: 20,
              child: Center(
                child: InSituHintPill(
                  prefKey: 'hint_focus_timer_dock_seen',
                  message: 'Tap (X) to dock into a floating mini-timer, or tap Fullscreen for bedside flip clock',
                  icon: Icons.picture_in_picture_alt_rounded,
                  backgroundColor: isLight ? Colors.white.withValues(alpha: 0.92) : Colors.black.withValues(alpha: 0.65),
                  borderColor: isLight ? const Color(0xFFCBD5E1) : Colors.white.withValues(alpha: 0.35),
                  textColor: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
            ),

            // ── BOTTOM CONTROLS (BALANCED & ERGONOMIC) ────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
                  child: Row(
                      children: [
                        // Break toggle
                        _ControlBtn(
                          icon: timer.isBreak ? Icons.coffee_rounded : Icons.coffee_outlined,
                          label: timer.isBreak ? 'End Break' : 'Break',
                          isLight: isLight,
                          color: timer.isBreak
                              ? theme.accentColor
                              : (isLight ? const Color(0xFF0F172A) : Colors.white),
                          bg: isLight ? Colors.white : Colors.white.withValues(alpha: 0.12),
                          borderColor: isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.30),
                          onTap: notifier.toggleBreak,
                        ),
                        const SizedBox(width: 12),

                        // Main Play/Pause Button (48 height, dynamic theme accent or slate)
                        Expanded(
                          child: ApplePressable(
                            pressedScale: 0.95,
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              if (!timer.hasTarget && !timer.isRunning) {
                                _SessionConfigSheet.show(
                                  context,
                                  onShowCustomDialog: _showCustomMinutesDialog,
                                );
                                return;
                              }
                              notifier.startOrPause();
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: timer.isRunning
                                    ? const Color(0xFF0F172A)
                                    : theme.accentColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: (timer.isRunning
                                            ? const Color(0xFF0F172A)
                                            : theme.accentColor)
                                        .withValues(alpha: 0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timer.isRunning ? 'PAUSE' : 'START',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Finish Button
                        _ControlBtn(
                          icon: Icons.check_rounded,
                          label: 'Finish',
                          isLight: isLight,
                          color: timer.sessionActive
                              ? theme.accentColor
                              : (isLight ? const Color(0xFF94A3B8) : Colors.white.withValues(alpha: 0.4)),
                          bg: isLight ? Colors.white : Colors.white.withValues(alpha: 0.12),
                          borderColor: isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.30),
                          onTap: timer.sessionActive ? () => _handleFinish(context) : null,
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Unified Session Config Bottom Sheet ───────────────────────────────────────
class _SessionConfigSheet extends ConsumerWidget {
  final Function({
    required BuildContext context,
    required String title,
    required int currentMins,
    required int minMins,
    required int maxMins,
    required ValueChanged<int> onSave,
  }) onShowCustomDialog;

  const _SessionConfigSheet({
    required this.onShowCustomDialog,
  });

  static void show(
    BuildContext context, {
    required Function({
      required BuildContext context,
      required String title,
      required int currentMins,
      required int minMins,
      required int maxMins,
      required ValueChanged<int> onSave,
    }) onShowCustomDialog,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 300),
        reverseDuration: Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
      builder: (_) => _SessionConfigSheet(
        onShowCustomDialog: onShowCustomDialog,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(focusTimerProvider);
    final notifier = ref.read(focusTimerProvider.notifier);
    final theme = timer.theme;

    final bg = AppTheme.paperBackground;
    final cardBg = AppTheme.cardWhite;
    final border = AppTheme.borderLight;
    final ink = AppTheme.inkForeground;
    final secondary = AppTheme.mutedText;
    final accent = theme.accentColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(Icons.tune_rounded, color: accent, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Setup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
                  ),
                  Text(
                    'Pick topic, mode & timer variables',
                    style: TextStyle(fontSize: 11, color: secondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          const InSituHintPill(
            prefKey: 'hint_timer_session_setup_seen',
            message: 'Anchor to a curriculum lecture to auto-sync runtime and check it off',
            icon: Icons.link_rounded,
            margin: EdgeInsets.only(bottom: 12),
          ),

          // ── SECTION 1: Topic ──────────────────────────────────────────────
          _sectionLabel('TOPIC', secondary),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pop(context);
              TaskPickerSheet.show(context, theme: theme, onSelect: (task) {
                notifier.setTask(
                  subjectId: task.subjectId,
                  subjectName: task.subjectName,
                  topicId: task.topicId,
                  topicTitle: task.topicTitle,
                  chapterName: task.chapterName,
                  topicType: task.topicType,
                  durationMins: task.presetDurationMins,
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(_topicIcon(timer.topicType), color: accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timer.hasTarget
                              ? timer.subjectName.toUpperCase().replaceAll(' ', '.')
                              : 'CHOOSE STUDY TARGET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timer.hasTarget
                              ? (timer.chapterName.isNotEmpty
                                  ? '${timer.chapterName} · ${timer.topicTitle}'
                                  : timer.topicTitle)
                              : 'Tap to pick from desk tasks or curriculum',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: secondary, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── SECTION 2: Mode ───────────────────────────────────────────────
          _sectionLabel('FOCUS MODE', secondary),
          const SizedBox(height: 8),
          ...[
            (TimerMode.pomodoro, Icons.timer_outlined, 'Pomodoro', 'Custom focus & break intervals'),
            (TimerMode.countUp, Icons.arrow_upward_rounded, 'Count-Up', 'Open stopwatch — tracks study time'),
            (TimerMode.moduleLinked, Icons.bookmark_border_rounded, 'Module-Linked', 'Synced from video / QBank / notes'),
          ].map(((TimerMode m, IconData icon, String name, String desc) r) {
            final sel = r.$1 == timer.mode;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => notifier.changeMode(r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? accent.withValues(alpha: 0.06) : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? accent : border,
                    width: sel ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(r.$2, size: 20, color: sel ? accent : secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.$3,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: sel ? accent : ink,
                            ),
                          ),
                          Text(
                            r.$4,
                            style: TextStyle(fontSize: 11, color: secondary),
                          ),
                        ],
                      ),
                    ),
                    if (sel)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // ── SECTION 3: Variables (only for pomodoro / module-linked) ─────
          if (timer.mode == TimerMode.pomodoro) ...[
            _sectionLabel('TIMER VARIABLES', secondary),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStepper(
                      context: context,
                      label: 'FOCUS',
                      value: timer.pomodoroMinutes,
                      onDec: () => notifier.adjustPomodoroMinutes(-1),
                      onInc: () => notifier.adjustPomodoroMinutes(1),
                      onTap: () => onShowCustomDialog(
                        context: context,
                        title: 'Focus Duration',
                        currentMins: timer.pomodoroMinutes,
                        minMins: 1,
                        maxMins: 180,
                        onSave: notifier.setPomodoroMinutes,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 12), color: border),
                  Expanded(
                    child: _buildStepper(
                      context: context,
                      label: 'BREAK',
                      value: timer.pomodoroBreakMins,
                      onDec: () => notifier.adjustPomodoroBreakMinutes(-1),
                      onInc: () => notifier.adjustPomodoroBreakMinutes(1),
                      onTap: () => onShowCustomDialog(
                        context: context,
                        title: 'Break Duration',
                        currentMins: timer.pomodoroBreakMins,
                        minMins: 1,
                        maxMins: 60,
                        onSave: notifier.setPomodoroBreakMinutes,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (timer.mode == TimerMode.moduleLinked) ...[
            _sectionLabel('TARGET DURATION', secondary),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.2),
              ),
              child: _buildStepper(
                context: context,
                label: 'MODULE TARGET',
                value: timer.modulePresetMins,
                onDec: () => notifier.setModulePreset(timer.modulePresetMins - 1),
                onInc: () => notifier.setModulePreset(timer.modulePresetMins + 1),
                onTap: () => onShowCustomDialog(
                  context: context,
                  title: 'Module Target Duration',
                  currentMins: timer.modulePresetMins,
                  minMins: 1,
                  maxMins: 180,
                  onSave: notifier.setModulePreset,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── SECTION 4: Keep Screen Awake ───────────────────────────────────
          _sectionLabel('DISPLAY', secondary),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => notifier.setKeepScreenAwake(!timer.keepScreenAwake),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: timer.keepScreenAwake
                          ? accent.withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      timer.keepScreenAwake
                          ? Icons.smartphone_rounded
                          : Icons.screen_lock_portrait_rounded,
                      color: timer.keepScreenAwake ? accent : secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keep Screen Awake',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        Text(
                          'Prevent display from sleeping during session',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: timer.keepScreenAwake,
                    activeTrackColor: accent,
                    inactiveTrackColor: AppTheme.borderLight,
                    thumbColor: Colors.white,
                    onChanged: (val) {
                      notifier.setKeepScreenAwake(val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: color,
        ),
      );

  Widget _buildStepper({
    required BuildContext context,
    required String label,
    required int value,
    required VoidCallback onDec,
    required VoidCallback onInc,
    required VoidCallback onTap,
  }) {
    final ink = AppTheme.inkForeground;
    final secondary = AppTheme.mutedText;
    final border = AppTheme.borderLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: secondary)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SheetStepBtn(icon: Icons.remove_rounded, onTap: onDec),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Center(
                  child: Text(
                    '${value}m',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SheetStepBtn(icon: Icons.add_rounded, onTap: onInc),
          ],
        ),
      ],
    );
  }
}

// Small step button used inside _SessionConfigSheet
class _SheetStepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SheetStepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Center(child: Icon(icon, size: 16, color: AppTheme.inkForeground)),
    ),
  );
}

// ── Helper widget _buildTaskCard stub kept for compile safety ──────────────────
// (All real task-picking logic moved into _SessionConfigSheet above)

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool pulsing;
  final bool isLight;

  const _GlassBtn({
    required this.icon,
    required this.color,
    this.onTap,
    this.pulsing = false,
    this.isLight = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconW = Icon(icon, color: color, size: 20);
    if (pulsing) {
      iconW = SoundHumIcon(isActive: true, color: color, size: 20);
    }
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.90,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight ? const Color(0x0A0F172A) : Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(child: iconW),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool isLight;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.borderColor,
    this.onTap,
    this.isLight = true,
  });

  @override
  Widget build(BuildContext context) => ApplePressable(
    onTap: onTap,
    pressedScale: 0.92,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 72,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0x0A0F172A) : Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    ),
  );
}





class _SessionDoneDialog extends StatelessWidget {
  final String subjectName;
  final String topicTitle;
  final int focusSecs;
  final int breakSecs;
  final String modeName;
  final TimerThemeData theme;
  final bool isLight;
  final VoidCallback onDone;
  final VoidCallback onViewAnalytics;
  final VoidCallback onStartAnother;

  const _SessionDoneDialog({
    required this.subjectName,
    required this.topicTitle,
    required this.focusSecs,
    required this.breakSecs,
    required this.modeName,
    required this.theme,
    required this.isLight,
    required this.onDone,
    required this.onViewAnalytics,
    required this.onStartAnother,
  });

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = theme.accentColor;
    final textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final textSecondary = isLight ? const Color(0xFF64748B) : Colors.white.withValues(alpha: 0.70);
    final border = isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.14);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.82)
                  : const Color(0xFF14141E).withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isLight ? const Color(0x22000000) : Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clean session completion badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    color: accent,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Session Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.22), width: 1.0),
                  ),
                  child: Text(
                    subjectName.isNotEmpty ? subjectName.toUpperCase() : 'FOCUS SESSION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isLight ? accent : Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topicTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Translucent Stat tiles
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF8FAFC) : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: border,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'FOCUS TIME',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt(focusSecs),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: isLight ? accent : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF8FAFC) : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: border,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'BREAK TIME',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt(breakSecs),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Refined semi-translucent "Done" Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLight ? accent : accent.withValues(alpha: 0.75),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isLight ? Colors.transparent : Colors.white.withValues(alpha: 0.20),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Done',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Secondary Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewAnalytics,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          backgroundColor: isLight ? Colors.white : Colors.white.withValues(alpha: 0.06),
                          side: BorderSide(
                            color: border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onStartAnother,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          backgroundColor: isLight ? Colors.white : Colors.white.withValues(alpha: 0.06),
                          side: BorderSide(
                            color: border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Again', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

