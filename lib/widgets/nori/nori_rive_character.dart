import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' as rive;
import '../../services/tour/app_tour_controller.dart';
import 'nori_speech_card.dart';

/// Authentic Duolingo production Rive mascot engine for Nori.
///
/// Drives 100% genuine `.riv` bone-and-mesh state machines extracted from
/// Duolingo, with lavender color grading, Duolingo speech card, and tap physics.
enum NoriRiveState {
  breathe,      // duo_breathe.riv
  celebrate,    // duo_perfect_starry_eyed_03.riv
  party,        // duo_normal_party_butt_02.riv
  love,         // duo_normal_heart_throb_03.riv
  zen,          // duo_zen_04.riv
  buff,         // duo_perfect_buff_03.riv
  streak,       // duo_streak_se_v21.riv
}

class NoriRiveCharacter extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final bool enablePhysics;
  final bool showGreetingBubble;
  final bool applyLavenderPalette;

  const NoriRiveCharacter({
    super.key,
    this.size = 110.0,
    this.onTap,
    this.enablePhysics = true,
    this.showGreetingBubble = true,
    this.applyLavenderPalette = true,
  });

  @override
  State<NoriRiveCharacter> createState() => NoriRiveCharacterState();
}

class NoriRiveCharacterState extends State<NoriRiveCharacter> {
  NoriRiveState _currentState = NoriRiveState.breathe;

  // Active timers for clean disposal
  final List<Timer> _activeTimers = [];

  void _runDelayed(Duration duration, VoidCallback callback) {
    Timer? timer;
    timer = Timer(duration, () {
      _activeTimers.remove(timer);
      if (mounted) callback();
    });
    _activeTimers.add(timer);
  }

  // Loaded Rive instances
  final Map<NoriRiveState, rive.File> _loadedFiles = {};
  final Map<NoriRiveState, rive.RiveWidgetController> _loadedControllers = {};
  bool _loadFailed = false;

  // Speech card
  String? _speechText;
  double _speechAlpha = 0.0;
  Timer? _speechTimer;

  // Circadian dialogue banks (NO emojis, concise — AGENTS.md rule)
  static const List<String> _dialoguesMorning = [
    'Rise & shine!', 'Ready, Doc?', "Let's study!", 'Streak +1!', 'Good morning!',
  ];
  static const List<String> _dialoguesAfternoon = [
    'Take a break?', 'Hydrate!', 'Stay cool!', 'Stretch out!', 'Keep pace!',
  ];
  static const List<String> _dialoguesEvening = [
    'Focus time!', 'Deep work!', 'Keep going!', 'Almost there!', 'Study on!',
  ];
  static const List<String> _dialoguesNight = [
    'Sleep well!', 'Rest up!', 'Quiet time...', 'Night, Doc!', 'Recharge!',
  ];

  String _pickCircadianDialogue() {
    final hour = DateTime.now().hour;
    final rand = math.Random();
    List<String> pool;
    if (hour >= 5 && hour < 12) {
      pool = _dialoguesMorning;
    } else if (hour >= 12 && hour < 17) {
      pool = _dialoguesAfternoon;
    } else if (hour >= 17 && hour < 22) {
      pool = _dialoguesEvening;
    } else {
      pool = _dialoguesNight;
    }
    return pool[rand.nextInt(pool.length)];
  }

  // Lavender tint color matrix
  static const List<double> _lavenderColorMatrix = <double>[
    0.80, 0.22, 0.00, 0.0, 28.0 / 255.0,
    0.62, 0.38, 0.00, 0.0, 22.0 / 255.0,
    0.20, 0.88, 0.12, 0.0, 48.0 / 255.0,
    0.00, 0.00, 0.00, 1.0, 0.0,
  ];

  @override
  void initState() {
    super.initState();
    _loadAllRiveFiles();

    // Wire app tour
    AppTourNotifier.onPlayNoriAnimation = playTourAnimationSequence;

    if (widget.showGreetingBubble) {
      _runDelayed(const Duration(milliseconds: 600), () {
        if (mounted) showSpeech(_pickCircadianDialogue(), durationMs: 2800);
      });
    }
  }

  Future<void> _loadAllRiveFiles() async {
    try {
      final assets = <NoriRiveState, String>{
        NoriRiveState.breathe: 'assets/rive/duo_breathe.riv',
        NoriRiveState.celebrate: 'assets/rive/duo_perfect_starry_eyed_03.riv',
        NoriRiveState.party: 'assets/rive/duo_normal_party_butt_02.riv',
        NoriRiveState.love: 'assets/rive/duo_normal_heart_throb_03.riv',
        NoriRiveState.zen: 'assets/rive/duo_zen_04.riv',
        NoriRiveState.buff: 'assets/rive/duo_perfect_buff_03.riv',
        NoriRiveState.streak: 'assets/rive/duo_streak_se_v21.riv',
      };

      for (final entry in assets.entries) {
        final file = await rive.File.asset(
          entry.value,
          riveFactory: rive.Factory.rive,
        );
        if (file != null) {
          _loadedFiles[entry.key] = file;
          _loadedControllers[entry.key] = rive.RiveWidgetController(file);
        }
      }

      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void showSpeech(String text, {int durationMs = 2800}) {
    if (!mounted) return;
    _speechTimer?.cancel();
    setState(() {
      _speechText = text;
      _speechAlpha = 1.0;
    });
    _speechTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) setState(() => _speechAlpha = 0.0);
    });
  }

  void playState(NoriRiveState state, {Duration? revertAfter}) {
    if (!mounted) return;
    setState(() => _currentState = state);

    if (revertAfter != null) {
      _runDelayed(revertAfter, () {
        if (mounted && _currentState == state) {
          setState(() => _currentState = NoriRiveState.breathe);
        }
      });
    }
  }

  void triggerCelebrate() {
    HapticFeedback.mediumImpact();
    showSpeech('Crushed it!');
    playState(NoriRiveState.celebrate, revertAfter: const Duration(milliseconds: 3200));
  }

  void triggerParty() {
    HapticFeedback.lightImpact();
    showSpeech('Level up!');
    playState(NoriRiveState.party, revertAfter: const Duration(milliseconds: 3000));
  }

  void triggerLove() {
    HapticFeedback.lightImpact();
    showSpeech('You did it!');
    playState(NoriRiveState.love, revertAfter: const Duration(milliseconds: 3000));
  }

  void triggerZen() {
    showSpeech('Zzz...');
    playState(NoriRiveState.zen, revertAfter: const Duration(milliseconds: 3500));
  }

  void playTourAnimationSequence() {
    triggerParty();
    _runDelayed(const Duration(milliseconds: 1400), () {
      triggerCelebrate();
    });
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    final rand = math.Random();
    final roll = rand.nextDouble();

    if (roll < 0.35) {
      triggerParty();
    } else if (roll < 0.65) {
      triggerCelebrate();
    } else {
      triggerLove();
    }
    widget.onTap?.call();
  }

  @override
  void dispose() {
    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();
    _speechTimer?.cancel();
    if (AppTourNotifier.onPlayNoriAnimation == playTourAnimationSequence) {
      AppTourNotifier.onPlayNoriAnimation = null;
    }
    for (final ctrl in _loadedControllers.values) {
      ctrl.dispose();
    }
    for (final file in _loadedFiles.values) {
      file.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeController = _loadedControllers[_currentState] ??
        _loadedControllers[NoriRiveState.breathe];

    Widget content;
    if (_loadFailed || activeController == null) {
      // Clean fallback if running in headless test runner without GPU context
      content = Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFC4B0FF),
        ),
      );
    } else {
      Widget riveWidget = SizedBox(
        width: widget.size,
        height: widget.size,
        child: rive.RiveWidget(
          controller: activeController,
          fit: rive.Fit.contain,
        ),
      );

      if (widget.applyLavenderPalette) {
        riveWidget = ColorFiltered(
          colorFilter: const ColorFilter.matrix(_lavenderColorMatrix),
          child: riveWidget,
        );
      }
      content = riveWidget;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Duo Rive mascot
            GestureDetector(
              onTap: _handleTap,
              child: content,
            ),

            // Duo-style pointing speech card
            if (_speechAlpha > 0.05 && _speechText != null)
              Positioned(
                bottom: widget.size * 0.90,
                child: AnimatedOpacity(
                  opacity: _speechAlpha,
                  duration: const Duration(milliseconds: 180),
                  child: NoriSpeechCard(
                    text: _speechText!,
                    caretSide: NoriCaretSide.bottom,
                    caretOffset: 48,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
