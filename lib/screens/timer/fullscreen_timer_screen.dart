import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/focus_timer_provider.dart';
import '../../widgets/timer/ambient_sound_sheet.dart';
import '../../widgets/timer/medical_wave_visualizer.dart';
import '../../widgets/timer/sketch_flip_digit.dart';
import '../../widgets/animations/apple_pressable.dart';

/// Authentic minimalist Zen Flip Clock matching exact reference image.
///
/// Features:
/// - Pure black background (#000000)
/// - Matte charcoal split-flap mechanical cards (#222326, borderRadius: 26.0)
/// - Mathematical 50/50 split across middle horizontal crease line
/// - Heroic condensed typography with zero duplication
/// - Pure minimal cards: No battery icon, No date, No day
/// - Dynamic Digits: Under 1h => Card 1 = MM, Card 2 = SS (no corner seconds)
///                  1h or more => Card 1 = HH, Card 2 = MM (corner seconds SS)
/// - Subtle topic label displayed cleanly at the top bar
/// - Auto-sleep controls (fading overlay controls out after 3.5s inactivity)
/// - Tap anywhere on screen wakes up controls (does NOT pause timer)
/// - Dedicated Resume / Pause button below the flip cards
/// - 90° Desk Mode in portrait (matching exact physical orientation in photo)
///   with instant toggle to upright portrait or native landscape
class FullscreenTimerScreen extends ConsumerStatefulWidget {
  const FullscreenTimerScreen({super.key});

  @override
  ConsumerState<FullscreenTimerScreen> createState() =>
      _FullscreenTimerScreenState();
}

class _FullscreenTimerScreenState extends ConsumerState<FullscreenTimerScreen> {
  bool _forceRotatedPortrait = true;
  bool _showControls = true;
  Timer? _sleepTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _resetControlsSleepTimer();
  }

  void _resetControlsSleepTimer() {
    _sleepTimer?.cancel();
    if (!_showControls && mounted) {
      setState(() => _showControls = true);
    }
    _sleepTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onTogglePlayPause() {
    _resetControlsSleepTimer();
    ref.read(focusTimerProvider.notifier).startOrPause();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(focusTimerProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final int effectiveSeconds;
    if (t.isBreak) {
      effectiveSeconds = t.breakSecondsElapsed;
    } else if (t.mode == TimerMode.countUp) {
      effectiveSeconds = t.focusSecondsElapsed;
    } else if (t.remainingSeconds == 0 && !t.isRunning) {
      effectiveSeconds = t.pomodoroPresetMins * 60;
    } else {
      effectiveSeconds = t.remainingSeconds;
    }

    final bool hasHours = effectiveSeconds >= 3600;
    final int card1Value;
    final int card2Value;
    final String? cornerSeconds;

    if (hasHours) {
      // >= 1 hour: Card 1 = HH, Card 2 = MM, Corner = SS
      final h = effectiveSeconds ~/ 3600;
      final m = (effectiveSeconds % 3600) ~/ 60;
      final s = effectiveSeconds % 60;
      card1Value = h;
      card2Value = m;
      cornerSeconds = s.toString().padLeft(2, '0');
    } else {
      // < 1 hour: Card 1 = MM, Card 2 = SS, Corner = none
      final m = effectiveSeconds ~/ 60;
      final s = effectiveSeconds % 60;
      card1Value = m;
      card2Value = s;
      cornerSeconds = null;
    }

    final card1Str = card1Value.toString().padLeft(2, '0');
    final card2Str = card2Value.toString().padLeft(2, '0');

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Wakes up / refreshes the controls sleep timer on touch without pausing timer
            _resetControlsSleepTimer();
          },
          onDoubleTap: () => Navigator.pop(context),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top Bar: Cross sign of exit, subtle topic, & rotation toggle ──
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: _buildTopBar(t, isLandscape),
                  ),
                ),

                // ── Center: Majestic Flip Cards (Design preserved 100% intact) ──
                Expanded(
                  child: Center(
                    child: isLandscape
                        ? _buildLandscapeLayout(
                            card1: card1Str,
                            card2: card2Str,
                            cornerSeconds: cornerSeconds,
                          )
                        : _forceRotatedPortrait
                            ? _buildDeskModePortraitLayout(
                                card1: card1Str,
                                card2: card2Str,
                                cornerSeconds: cornerSeconds,
                              )
                            : _buildUprightPortraitLayout(
                                card1: card1Str,
                                card2: card2Str,
                                cornerSeconds: cornerSeconds,
                              ),
                  ),
                ),

                // ── Medical Wave Visualizer ──
                AnimatedOpacity(
                  opacity: _showControls ? 0.75 : 0.12,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
                    child: MedicalWaveVisualizer(
                      height: 18,
                      color: Colors.white.withValues(alpha: 0.55),
                      showBaseline: false,
                    ),
                  ),
                ),

                // ── Bottom: Dedicated Resume / Pause button below ──
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: _buildBottomResumePauseButton(t),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(FocusTimerState t, bool isLandscape) {
    final isAudioActive = AmbientAudioService.instance.isPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            tooltip: 'Exit Fullscreen',
            onPressed: () => Navigator.pop(context),
          ),

          // Subtle Topic Title (Non-distracting, clean)
          if (t.hasTarget)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  t.chapterName.isNotEmpty
                      ? '${t.subjectName} · ${t.topicTitle}'
                      : (t.topicTitle.isNotEmpty ? t.topicTitle : t.subjectName),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAudioActive
                        ? const Color(0xFF0D9488).withValues(alpha: 0.25)
                        : const Color(0xFF1E1F22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAudioActive
                          ? const Color(0xFF14B8A6)
                          : Colors.white.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    isAudioActive ? Icons.graphic_eq_rounded : Icons.volume_off_rounded,
                    color: isAudioActive ? const Color(0xFF2DD4BF) : Colors.white70,
                    size: 20,
                  ),
                ),
                tooltip: 'Ambient Desk Mixer',
                onPressed: () {
                  _resetControlsSleepTimer();
                  AmbientSoundSheet.show(context);
                },
              ),
              if (!isLandscape) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1F22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      _forceRotatedPortrait
                          ? Icons.screen_lock_rotation_rounded
                          : Icons.screen_rotation_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Toggle 90° Desk Mode',
                  onPressed: () {
                    _resetControlsSleepTimer();
                    setState(() {
                      _forceRotatedPortrait = !_forceRotatedPortrait;
                    });
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomResumePauseButton(FocusTimerState t) {
    final isRunning = t.isRunning;
    final isStarted = t.focusSecondsElapsed > 0 ||
        t.breakSecondsElapsed > 0 ||
        (t.remainingSeconds > 0 &&
            t.remainingSeconds < t.pomodoroPresetMins * 60);
    final label = isRunning ? 'PAUSE' : (isStarted ? 'RESUME' : 'START');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Center(
        child: ApplePressable(
          onPressed: _onTogglePlayPause,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: isRunning
                  ? const Color(0xFF222326)
                  : const Color(0xFF2A2B30),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isRunning
                    ? Colors.white.withValues(alpha: 0.22)
                    : const Color(0xFFFBBF24).withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isRunning
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isRunning ? Colors.white : const Color(0xFFFBBF24),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isRunning ? Colors.white : const Color(0xFFFBBF24),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeskModePortraitLayout({
    required String card1,
    required String card2,
    String? cornerSeconds,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // RotatedBox(quarterTurns: 1) rotates child 90 deg clockwise.
        // Viewport height becomes child width; viewport width becomes child height.
        final maxRowWidth = (constraints.maxHeight - 20.0).clamp(120.0, 900.0);
        final maxRowHeight = (constraints.maxWidth - 20.0).clamp(100.0, 420.0);

        final cardW = ((maxRowWidth - 14.0) / 2).clamp(100.0, 340.0);
        final cardH = math.min(maxRowHeight, cardW * 1.05);

        final fontSize = (cardH * 0.68).clamp(60.0, 220.0);
        final textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFDCDCE0),
          letterSpacing: -3.0,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.0,
        );

        final card1Widget = SketchFlipCard(
          key: const ValueKey('card_desk_card1'),
          value: card1,
          width: cardW,
          height: cardH,
          borderRadius: 26.0,
          textStyle: textStyle,
          cardColor: const Color(0xFF222326),
          borderColor: const Color(0xFF161719),
        );

        final card2Widget = SketchFlipCard(
          key: const ValueKey('card_desk_card2'),
          value: card2,
          width: cardW,
          height: cardH,
          borderRadius: 26.0,
          textStyle: textStyle,
          cardColor: const Color(0xFF222326),
          borderColor: const Color(0xFF161719),
          bottomRightWidget: cornerSeconds != null
              ? Text(
                  cornerSeconds,
                  style: TextStyle(
                    fontSize: (cardH * 0.14).clamp(16.0, 36.0),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD4D4D8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.0,
                  ),
                )
              : null,
        );

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: RotatedBox(
            quarterTurns: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Under quarterTurns: 1:
                // Left child (x=0) maps to TOP of screen (Card 1)
                card1Widget,
                const SizedBox(width: 14),
                // Right child (x=W) maps to BOTTOM of screen (Card 2)
                card2Widget,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUprightPortraitLayout({
    required String card1,
    required String card2,
    String? cornerSeconds,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxColHeight = (constraints.maxHeight - 20.0).clamp(120.0, 900.0);
        final maxColWidth = (constraints.maxWidth - 20.0).clamp(100.0, 500.0);

        final cardH = ((maxColHeight - 14.0) / 2).clamp(100.0, 300.0);
        final cardW = math.min(maxColWidth, cardH * 1.15);

        final fontSize = (cardH * 0.68).clamp(60.0, 190.0);
        final textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFDCDCE0),
          letterSpacing: -2.5,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.0,
        );

        final card1Widget = SketchFlipCard(
          key: const ValueKey('card_upright_card1'),
          value: card1,
          width: cardW,
          height: cardH,
          borderRadius: 24.0,
          textStyle: textStyle,
          cardColor: const Color(0xFF222326),
          borderColor: const Color(0xFF161719),
        );

        final card2Widget = SketchFlipCard(
          key: const ValueKey('card_upright_card2'),
          value: card2,
          width: cardW,
          height: cardH,
          borderRadius: 24.0,
          textStyle: textStyle,
          cardColor: const Color(0xFF222326),
          borderColor: const Color(0xFF161719),
          bottomRightWidget: cornerSeconds != null
              ? Text(
                  cornerSeconds,
                  style: TextStyle(
                    fontSize: (cardH * 0.14).clamp(16.0, 34.0),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD4D4D8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.0,
                  ),
                )
              : null,
        );

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              card1Widget,
              const SizedBox(height: 14),
              card2Widget,
            ],
          ),
        );
      },
    );
  }

  Widget _buildLandscapeLayout({
    required String card1,
    required String card2,
    String? cornerSeconds,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxRowWidth = (constraints.maxWidth - 32.0).clamp(120.0, 1200.0);
        final maxRowHeight = (constraints.maxHeight - 20.0).clamp(100.0, 500.0);

        final cardW = ((maxRowWidth - 16.0) / 2).clamp(100.0, 440.0);
        final cardH = math.min(maxRowHeight, cardW * 0.95);

        final fontSize = (cardH * 0.68).clamp(60.0, 240.0);
        final textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFDCDCE0),
          letterSpacing: -3.0,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.0,
        );

        final card1Widget = SketchFlipCard(
          key: const ValueKey('card_landscape_card1'),
          value: card1,
          width: cardW,
          height: cardH,
          borderRadius: 26.0,
          textStyle: textStyle,
          cardColor: const Color(0xFF222326),
          borderColor: const Color(0xFF161719),
        );

        final card2Widget = SketchFlipCard(
          key: const ValueKey('card_landscape_card2'),
          value: card2,
          width: cardW,
          height: cardH,
          borderRadius: 26.0,
          textStyle: textStyle,
          cardColor: const Color(0xFF222326),
          borderColor: const Color(0xFF161719),
          bottomRightWidget: cornerSeconds != null
              ? Text(
                  cornerSeconds,
                  style: TextStyle(
                    fontSize: (cardH * 0.14).clamp(16.0, 38.0),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD4D4D8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.0,
                  ),
                )
              : null,
        );

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              card1Widget,
              const SizedBox(width: 14),
              card2Widget,
            ],
          ),
        );
      },
    );
  }
}
