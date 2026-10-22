import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'nori_blob_painter.dart';
import '../../services/tour/app_tour_controller.dart';

export 'nori_blob_painter.dart' show NoriEmotion, NoriProp, NoriSize, NoriMotion;

// ─────────────────────────────────────────────────────────────────────────────
// FX: SHOCKWAVE
// ─────────────────────────────────────────────────────────────────────────────

class _FxShockwave {
  double x, y;
  double radius = 4.0;
  static const double maxRadius = 40.0;
  final Color color;
  double life = 1.0;
  _FxShockwave(this.x, this.y, this.color);
  bool update(double dt) {
    radius += (maxRadius - radius) * 8.5 * dt;
    life -= 2.4 * dt;
    return life > 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FX: SPARK
// ─────────────────────────────────────────────────────────────────────────────

class _FxSpark {
  double x, y, vx, vy;
  final Color color;
  final double size;
  double life = 1.0;
  _FxSpark(this.x, this.y, this.vx, this.vy, this.color, this.size);
  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vx *= math.pow(0.22, dt);
    vy *= math.pow(0.22, dt);
    life -= 2.2 * dt;
    return life > 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FX: ZEN ORB  (floating bubbles for sleepy state)
// ─────────────────────────────────────────────────────────────────────────────

class _FxZenOrb {
  final double startX;
  double x, y, phase, life;
  final double size;
  final Color color;
  _FxZenOrb(this.x, this.y, this.size, this.color)
      : startX = x,
        phase = math.Random().nextDouble() * math.pi * 2,
        life = 1.0;
  bool update(double dt) {
    y -= 12.0 * dt;
    phase += dt * 2.5;
    x = startX + math.sin(phase) * 5.0;
    life -= 0.55 * dt;
    return life > 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FX: STAR FLASH  (4-point diamond vector star)
// ─────────────────────────────────────────────────────────────────────────────

class _FxStarFlash {
  double x, y, size = 2.0;
  static const double maxSize = 18.0;
  final Color color;
  double life = 1.0;
  _FxStarFlash(this.x, this.y, this.color);
  bool update(double dt) {
    size += (maxSize - size) * 9.0 * dt;
    life -= 2.2 * dt;
    return life > 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FX: FLOATING HEART
// ─────────────────────────────────────────────────────────────────────────────

class _FxHeart {
  double x, y;
  double phase;
  double life = 1.0;
  final double size;
  _FxHeart(this.x, this.y, this.size)
      : phase = math.Random().nextDouble() * math.pi * 2;
  bool update(double dt) {
    y -= 20.0 * dt;
    phase += dt * 3.0;
    x += math.sin(phase) * 4.0 * dt;
    life -= 0.85 * dt;
    return life > 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FX CANVAS PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _FxCanvasPainter extends CustomPainter {
  final List<_FxShockwave> shockwaves;
  final List<_FxSpark> sparks;
  final List<_FxZenOrb> zenOrbs;
  final List<_FxStarFlash> starFlashes;
  final List<_FxHeart> hearts;

  const _FxCanvasPainter({
    required this.shockwaves,
    required this.sparks,
    required this.zenOrbs,
    required this.starFlashes,
    required this.hearts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Shockwaves
    for (final sw in shockwaves) {
      canvas.drawCircle(
        Offset(sw.x, sw.y),
        sw.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = sw.color.withValues(alpha: (sw.life * 0.85).clamp(0.0, 1.0)),
      );
    }

    // Sparks
    for (final sp in sparks) {
      canvas.drawCircle(
        Offset(sp.x, sp.y),
        sp.size * sp.life,
        Paint()..color = sp.color.withValues(alpha: sp.life.clamp(0.0, 1.0)),
      );
    }

    // Zen orbs
    for (final orb in zenOrbs) {
      canvas.drawCircle(
        Offset(orb.x, orb.y),
        orb.size,
        Paint()
          ..color = orb.color.withValues(alpha: (orb.life * 0.45).clamp(0.0, 1.0)),
      );
    }

    // Star flashes (4-point diamonds)
    for (final star in starFlashes) {
      final alpha = star.life.clamp(0.0, 1.0);
      final r = star.size;
      final inner = r * 0.28;
      final path = Path()
        ..moveTo(star.x, star.y - r)
        ..lineTo(star.x + inner, star.y - inner)
        ..lineTo(star.x + r, star.y)
        ..lineTo(star.x + inner, star.y + inner)
        ..lineTo(star.x, star.y + r)
        ..lineTo(star.x - inner, star.y + inner)
        ..lineTo(star.x - r, star.y)
        ..lineTo(star.x - inner, star.y - inner)
        ..close();
      canvas.drawPath(path, Paint()..color = star.color.withValues(alpha: alpha));
    }

    // Floating hearts (love state)
    for (final heart in hearts) {
      final alpha = heart.life.clamp(0.0, 1.0);
      final r = heart.size * heart.life;
      final paint = Paint()
        ..color = const Color(0xFFFF6B9D).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(heart.x, heart.y + r * 0.25);
      path.cubicTo(
        heart.x - r, heart.y - r * 0.4,
        heart.x - r * 1.2, heart.y + r * 0.3,
        heart.x, heart.y + r,
      );
      path.cubicTo(
        heart.x + r * 1.2, heart.y + r * 0.3,
        heart.x + r, heart.y - r * 0.4,
        heart.x, heart.y + r * 0.25,
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FxCanvasPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCADIAN PERIOD
// ─────────────────────────────────────────────────────────────────────────────

enum CircadianPeriod { morning, afternoon, evening, night }

// ─────────────────────────────────────────────────────────────────────────────
// NORI BLOB CHARACTER  — the main widget
// ─────────────────────────────────────────────────────────────────────────────

/// Full-featured Duo-style blob companion for Nori.
///
/// Drop-in replacement for [ShimejiEngine] with identical external API
/// (size, onTap) plus extended emotion control via [setEmotion].
class NoriBlobCharacter extends StatefulWidget {
  final double size;
  final NoriSize? sizePreset;
  final VoidCallback? onTap;
  final NoriEmotion? initialEmotion;
  final NoriMotion? motion;
  final NoriProp? prop;
  final bool enablePhysics;
  final bool showGreetingBubble;

  const NoriBlobCharacter({
    super.key,
    this.size = 64.0,
    this.sizePreset,
    this.onTap,
    this.initialEmotion,
    this.motion,
    this.prop,
    this.enablePhysics = true,
    this.showGreetingBubble = true,
  });

  double get effectiveSize => sizePreset?.value ?? size;

  @override
  State<NoriBlobCharacter> createState() => NoriBlobCharacterState();
}

class NoriBlobCharacterState extends State<NoriBlobCharacter>
    with TickerProviderStateMixin {
  // ── Ticker (physics & FX update loop)
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── Box bounds (from LayoutBuilder)
  double _boxWidth = 320.0;
  double _boxHeight = 150.0;

  // ── Position & velocity (for bounce/roam physics)
  double _x = 0.0;
  double _y = 0.0;
  double _vx = 0.0; // drag fling velocity x (currently absorbed by idle roam)
  double _vy = 0.0; // drag fling velocity y
  int _facing = 1;

  // ── Drag
  Offset _dragStartBoxPos = Offset.zero;
  Offset _dragStartGlobalPos = Offset.zero;
  Offset _lastDragPos = Offset.zero;
  DateTime _lastDragTime = DateTime.now();
  bool _isDragging = false;

  // ── Emotion state machine
  late NoriEmotion _currentEmotion;
  late NoriBlobConfig _currentConfig;
  late NoriBlobConfig _targetConfig;
  late NoriBlobConfig _fromConfig;

  // ── Tween progress [0, 1] — driven by _emotionTween
  late final AnimationController _emotionController;

  // ── Breathing loop [0, 1] — drives sine breatheT
  late final AnimationController _breatheController;

  // ── Bounce loop [0, 1] — for happy/excited bob
  late final AnimationController _bounceController;
  NoriEmotion? _bounceEmotion; // which emotion drives the bounce

  // ── Shake controller (streakDanger)
  late final AnimationController _shakeController;

  // ── Speech bubble
  String? _bubbleText;
  double _bubbleOpacity = 0.0;
  DateTime _bubbleHideTime = DateTime.now();

  // ── FX lists
  final List<_FxShockwave> _shockwaves = [];
  final List<_FxSpark> _sparks = [];
  final List<_FxZenOrb> _zenOrbs = [];
  final List<_FxStarFlash> _starFlashes = [];
  final List<_FxHeart> _hearts = [];

  // ── Active timers tracker for clean disposal
  final List<Timer> _activeTimers = [];

  void _runDelayed(Duration duration, VoidCallback callback) {
    Timer? timer;
    timer = Timer(duration, () {
      _activeTimers.remove(timer);
      if (mounted) callback();
    });
    _activeTimers.add(timer);
  }

  // ── Idle AI timer
  int _idleTicks = 0;

  // ─── Dialogue banks (NO emojis, max 4 words — AGENTS.md rule) ─────────────
  static const List<String> _dialoguesMorning = [
    'Rise & shine!', 'Ready, Doc?', "Let's study!", 'Streak +1!', 'Good morning!',
  ];
  static const List<String> _dialoguesAfternoon = [
    'Yawn...', 'Take a break?', 'Hydrate!', 'Stay cool!', 'Stretch out!',
  ];
  static const List<String> _dialoguesEvening = [
    'Focus time!', 'Deep work!', 'Keep going!', 'Almost there!', 'Study on!',
  ];
  static const List<String> _dialoguesNight = [
    'Zzz...', 'Sleep well!', 'Rest up!', 'Quiet time...', 'Night, Doc!',
  ];
  static const List<String> _dialoguesTap = [
    'Hey!', 'Hehe!', 'Streak +1!', 'Nice!', 'Thanks!',
  ];
  static const List<String> _dialoguesCelebrate = [
    'Crushed it!', 'Epic!', 'Level up!', 'Top rank!', 'Nailed it!',
  ];
  static const List<String> _dialoguesStreakDanger = [
    'You forgot me.', 'One day off?', 'Seriously?', 'Come back.', 'Miss me?',
  ];
  static const List<String> _dialoguesSassy = [
    'Really?', "Don't.", 'Do better.', 'I waited.', 'Try harder.',
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE & MOTION MAPPINGS
  // ─────────────────────────────────────────────────────────────────────────

  double get _size => widget.effectiveSize;

  static NoriEmotion emotionForMotion(NoriMotion motion) {
    switch (motion) {
      case NoriMotion.focus:
        return NoriEmotion.studying;
      case NoriMotion.welcome:
        return NoriEmotion.happy;
      case NoriMotion.celebrate:
        return NoriEmotion.celebrating;
      case NoriMotion.party:
        return NoriEmotion.excited;
      case NoriMotion.love:
        return NoriEmotion.love;
      case NoriMotion.zen:
        return NoriEmotion.sleepy;
      case NoriMotion.alert:
        return NoriEmotion.streakDanger;
    }
  }

  void playMotion(NoriMotion motion, {Duration? revertAfter}) {
    final emotion = emotionForMotion(motion);
    setEmotion(emotion);
    if (motion == NoriMotion.welcome) {
      triggerWave();
    } else if (motion == NoriMotion.celebrate || motion == NoriMotion.party) {
      triggerCelebrate();
    } else if (motion == NoriMotion.love) {
      triggerLove();
    } else if (motion == NoriMotion.alert) {
      triggerStreakDanger();
    }

    if (revertAfter != null) {
      _runDelayed(revertAfter, () {
        if (mounted) setEmotion(NoriEmotion.idle);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.motion != null) {
      _currentEmotion = emotionForMotion(widget.motion!);
    } else {
      _currentEmotion = widget.initialEmotion ?? NoriEmotion.idle;
    }
    var baseConfig = NoriBlobConfig.forEmotion(_currentEmotion);
    if (widget.prop != null) {
      baseConfig = baseConfig.copyWith(prop: widget.prop);
    }
    _currentConfig = baseConfig;
    _targetConfig = baseConfig;
    _fromConfig = baseConfig;

    // Emotion tween — short, snappy (240ms), cubic ease-in-out
    _emotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_onEmotionTick);

    // Breathing — 3 s full cycle
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Bounce loop — 480ms half-period  (happy bob)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    // Shake controller — rapid left-right 80ms cycle
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _ticker = createTicker(_onTick)..start();

    // Wire tour callback
    AppTourNotifier.onPlayNoriAnimation = playTourAnimationSequence;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initPosition();
        if (widget.motion != null) {
          playMotion(widget.motion!);
        } else if (widget.showGreetingBubble) {
          showBubble('Hey Safi!', durationMs: 2800);
          _spawnStarFlash(
            _x + _size * 0.5,
            _y + _size * 0.3,
            const Color(0xFFB0C8FF),
          );
          setEmotion(NoriEmotion.happy);
          _runDelayed(const Duration(milliseconds: 900), () {
            if (mounted) setEmotion(widget.initialEmotion ?? NoriEmotion.idle);
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant NoriBlobCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEmotion != null &&
        widget.initialEmotion != oldWidget.initialEmotion) {
      setEmotion(widget.initialEmotion!);
    }
    if (widget.motion != null && widget.motion != oldWidget.motion) {
      playMotion(widget.motion!);
    }
    if (widget.prop != oldWidget.prop) {
      setState(() {
        if (widget.prop != null) {
          _currentConfig = _currentConfig.copyWith(prop: widget.prop);
          _targetConfig = _targetConfig.copyWith(prop: widget.prop);
        }
      });
    }
  }

  void _initPosition() {
    _x = _boxWidth * 0.5 - _size * 0.5;
    _y = _floorY;
  }

  @override
  void dispose() {
    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();
    if (AppTourNotifier.onPlayNoriAnimation == playTourAnimationSequence) {
      AppTourNotifier.onPlayNoriAnimation = null;
    }
    _ticker.dispose();
    _emotionController.dispose();
    _breatheController.dispose();
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOUNDS
  // ─────────────────────────────────────────────────────────────────────────

  double get _maxX => math.max(0.0, _boxWidth - _size);
  double get _maxY => math.max(0.0, _boxHeight - _size);
  double get _floorY => _maxY;
  double get _leftWallX => -_size * 0.25;
  double get _rightWallX => _maxX + _size * 0.25;

  // ─────────────────────────────────────────────────────────────────────────
  // CIRCADIAN
  // ─────────────────────────────────────────────────────────────────────────

  CircadianPeriod get _circadianPeriod {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return CircadianPeriod.morning;
    if (h >= 12 && h < 17) return CircadianPeriod.afternoon;
    if (h >= 17 && h < 22) return CircadianPeriod.evening;
    return CircadianPeriod.night;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMOTION SYSTEM
  // ─────────────────────────────────────────────────────────────────────────

  void _onEmotionTick() {
    setState(() {
      _currentConfig = NoriBlobConfig.lerp(
        _fromConfig,
        _targetConfig,
        Curves.easeInOut.transform(_emotionController.value),
      );
    });
  }

  /// Set Nori's emotion — smoothly tweens from current state.
  void setEmotion(NoriEmotion emotion) {
    if (!mounted) return;

    var newTarget = NoriBlobConfig.forEmotion(emotion);
    if (widget.prop != null) {
      newTarget = newTarget.copyWith(prop: widget.prop);
    }
    _fromConfig = _currentConfig;
    _targetConfig = newTarget;
    _currentEmotion = emotion;

    _emotionController.forward(from: 0.0);

    // Manage ancillary controllers per emotion
    _bounceEmotion = null;
    _shakeController.stop();

    switch (emotion) {
      case NoriEmotion.happy:
      case NoriEmotion.excited:
      case NoriEmotion.celebrating:
      case NoriEmotion.love:
        _bounceEmotion = emotion;
        _bounceController.repeat(reverse: true);
        break;
      case NoriEmotion.streakDanger:
        _shakeController.repeat(reverse: true);
        break;
      default:
        _bounceController.stop();
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC ACTION API  (same surface as ShimejiEngineState)
  // ─────────────────────────────────────────────────────────────────────────

  /// Cheerful bounce + celebration.
  void triggerCelebrate() {
    if (!mounted) return;
    setEmotion(NoriEmotion.celebrating);
    final rand = math.Random();
    showBubble(_dialoguesCelebrate[rand.nextInt(_dialoguesCelebrate.length)]);
    _spawnShockwave(
      _x + _size * 0.5, _y + _size * 0.7,
      const Color(0xFFB0C8FF),
    );
    _spawnSparkBurst(
      _x + _size * 0.5, _y + _size * 0.5,
      const Color(0xFFE8DEFF),
      count: 12,
    );
    _runDelayed(const Duration(milliseconds: 1800), () {
      if (mounted) setEmotion(NoriEmotion.happy);
      _runDelayed(const Duration(milliseconds: 900), () {
        if (mounted) setEmotion(NoriEmotion.idle);
      });
    });
  }

  /// Friendly greeting wave.
  void triggerWave() {
    if (!mounted) return;
    setEmotion(NoriEmotion.happy);
    showBubble('Hey Safi!');
    _spawnStarFlash(
      _x + _size * 0.5, _y + _size * 0.2,
      const Color(0xFFB0C8FF),
    );
  }

  /// Playful bounce.
  void triggerPlayful() {
    if (!mounted) return;
    setEmotion(NoriEmotion.excited);
    showBubble('Play time!');
  }

  /// Streak danger alert.
  void triggerStreakDanger() {
    if (!mounted) return;
    setEmotion(NoriEmotion.streakDanger);
    final rand = math.Random();
    showBubble(_dialoguesStreakDanger[rand.nextInt(_dialoguesStreakDanger.length)],
        durationMs: 3500);
  }

  /// Blunt sassy reaction.
  void triggerSassy() {
    if (!mounted) return;
    setEmotion(NoriEmotion.bluntSassy);
    final rand = math.Random();
    showBubble(_dialoguesSassy[rand.nextInt(_dialoguesSassy.length)],
        durationMs: 3000);
  }

  /// Love burst (e.g., quest complete).
  void triggerLove() {
    if (!mounted) return;
    setEmotion(NoriEmotion.love);
    showBubble('You did it!');
    _spawnHeartBurst(_x + _size * 0.5, _y + _size * 0.2);
  }

  /// Sad / missed day.
  void triggerSad() {
    if (!mounted) return;
    setEmotion(NoriEmotion.sad);
    showBubble('Miss you...');
  }

  /// App tour: wave → excited → celebrate
  void playTourAnimationSequence() {
    triggerWave();
    _runDelayed(const Duration(milliseconds: 1200), () {
      if (mounted) triggerPlayful();
    });
    _runDelayed(const Duration(milliseconds: 2500), () {
      if (mounted) triggerCelebrate();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SPEECH BUBBLE
  // ─────────────────────────────────────────────────────────────────────────

  void showBubble(String text, {int durationMs = 2800}) {
    if (!mounted) return;
    setState(() {
      _bubbleText = text;
      _bubbleOpacity = 1.0;
      _bubbleHideTime = DateTime.now().add(Duration(milliseconds: durationMs));
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FX SPAWNERS
  // ─────────────────────────────────────────────────────────────────────────

  void _spawnShockwave(double x, double y, Color c) =>
      _shockwaves.add(_FxShockwave(x, y, c));

  void _spawnSparkBurst(double x, double y, Color c, {int count = 8}) {
    final rand = math.Random();
    for (int i = 0; i < count; i++) {
      final angle = rand.nextDouble() * math.pi * 2;
      final speed = 40.0 + rand.nextDouble() * 60.0;
      _sparks.add(_FxSpark(
        x, y,
        math.cos(angle) * speed,
        math.sin(angle) * speed,
        c,
        2.2 + rand.nextDouble() * 1.5,
      ));
    }
  }

  void _spawnZenOrb(double x, double y) {
    _zenOrbs.add(_FxZenOrb(
      x + (math.Random().nextDouble() - 0.5) * 18,
      y,
      3.5 + math.Random().nextDouble() * 2.0,
      const Color(0xFFB0C8FF),
    ));
  }

  void _spawnStarFlash(double x, double y, Color c) =>
      _starFlashes.add(_FxStarFlash(x, y, c));

  void _spawnHeartBurst(double x, double y) {
    for (int i = 0; i < 4; i++) {
      _hearts.add(_FxHeart(
        x + (math.Random().nextDouble() - 0.5) * widget.size * 0.8,
        y - math.Random().nextDouble() * widget.size * 0.3,
        8.0 + math.Random().nextDouble() * 6.0,
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TICKER — physics, FX update, idle AI
  // ─────────────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0.0 || dt > 0.12) return;

    // Bubble timeout
    if (_bubbleOpacity > 0.0 && DateTime.now().isAfter(_bubbleHideTime)) {
      setState(() => _bubbleOpacity = 0.0);
    }

    // FX updates
    _shockwaves.removeWhere((s) => !s.update(dt));
    _sparks.removeWhere((s) => !s.update(dt));
    _zenOrbs.removeWhere((s) => !s.update(dt));
    _starFlashes.removeWhere((s) => !s.update(dt));
    _hearts.removeWhere((s) => !s.update(dt));

    // Zen orb emission during sleepy
    if (_currentEmotion == NoriEmotion.sleepy) {
      _idleTicks++;
      if (_idleTicks % 90 == 0) {
        _spawnZenOrb(_x + widget.size * 0.5, _y + widget.size * 0.25);
      }
    }

    // Physics (gentle float/roam when idle)
    if (widget.enablePhysics && !_isDragging && _currentEmotion == NoriEmotion.idle) {
      _idleTicks++;
      _updateIdleRoam(dt);
    }

    setState(() {});
  }

  void _updateIdleRoam(double dt) {
    // Gentle drift velocity
    const speed = 22.0;
    _x += _facing * speed * dt;

    if (_x >= _maxX) {
      _x = _maxX;
      _facing = -1;
    } else if (_x <= 0) {
      _x = 0;
      _facing = 1;
    }

    // Random idle circadian dialogue
    if (_idleTicks % 520 == 0) {
      _pickCircadianDialogue();
    }
  }

  void _pickCircadianDialogue() {
    final rand = math.Random();
    final period = _circadianPeriod;
    List<String> pool;
    NoriEmotion momentaryEmotion;

    switch (period) {
      case CircadianPeriod.morning:
        pool = _dialoguesMorning;
        momentaryEmotion = NoriEmotion.happy;
        break;
      case CircadianPeriod.afternoon:
        pool = _dialoguesAfternoon;
        momentaryEmotion = NoriEmotion.bored;
        break;
      case CircadianPeriod.evening:
        pool = _dialoguesEvening;
        momentaryEmotion = NoriEmotion.studying;
        break;
      case CircadianPeriod.night:
        pool = _dialoguesNight;
        momentaryEmotion = NoriEmotion.sleepy;
        break;
    }

    showBubble(pool[rand.nextInt(pool.length)], durationMs: 3200);
    setEmotion(momentaryEmotion);
    _runDelayed(const Duration(milliseconds: 2500), () {
      if (mounted) setEmotion(NoriEmotion.idle);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INTERACTION
  // ─────────────────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (!widget.enablePhysics) return;
    HapticFeedback.mediumImpact();
    _isDragging = true;
    _dragStartBoxPos = Offset(_x, _y);
    _dragStartGlobalPos = d.globalPosition;
    _lastDragPos = d.globalPosition;
    _lastDragTime = DateTime.now();
    _vx = 0;
    _vy = 0;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final now = DateTime.now();
    final dt = now.difference(_lastDragTime).inMicroseconds / 1e6;
    if (dt > 0.005) {
      _vx = (d.globalPosition.dx - _lastDragPos.dx) / dt;
      _vy = (d.globalPosition.dy - _lastDragPos.dy) / dt;
      _lastDragPos = d.globalPosition;
      _lastDragTime = now;
    }
    final delta = d.globalPosition - _dragStartGlobalPos;
    setState(() {
      _x = (_dragStartBoxPos.dx + delta.dx).clamp(_leftWallX, _rightWallX);
      _y = (_dragStartBoxPos.dy + delta.dy).clamp(-_size * 0.25, _floorY);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    _isDragging = false;
    // Apply fling velocity as a short positional nudge (consumed next idle tick)
    _x = (_x + _vx * 0.04).clamp(0.0, _maxX);
    _y = (_y + _vy * 0.02).clamp(0.0, _floorY);
    _vx = 0.0;
    _vy = 0.0;
    setState(() {});
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _spawnShockwave(
      _x + _size * 0.5, _y + _size * 0.5,
      const Color(0xFFB0C8FF),
    );
    _spawnSparkBurst(
      _x + _size * 0.5, _y + _size * 0.5,
      const Color(0xFFE8DEFF),
    );
    final rand = math.Random();
    showBubble(_dialoguesTap[rand.nextInt(_dialoguesTap.length)],
        durationMs: 2200);

    if (rand.nextDouble() < 0.4) {
      triggerCelebrate();
    } else {
      setEmotion(NoriEmotion.excited);
      _runDelayed(const Duration(milliseconds: 900), () {
        if (mounted) setEmotion(NoriEmotion.idle);
      });
    }

    widget.onTap?.call();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      _boxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : _size;
      _boxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
          ? constraints.maxHeight
          : _size;

      // Clamp position
      _x = _x.clamp(0.0, _maxX);
      _y = _y.clamp(0.0, _floorY);

      // Bounce driver: add vertical oscillation over current bounceOffset
      double extraBounce = 0.0;
      if (_bounceEmotion != null) {
        final bVal = Curves.easeInOut.transform(_bounceController.value);
        switch (_bounceEmotion!) {
          case NoriEmotion.celebrating:
            extraBounce = -bVal * _size * 0.30;
            break;
          case NoriEmotion.excited:
            extraBounce = -bVal * _size * 0.18;
            break;
          default:
            extraBounce = -bVal * _size * 0.10;
        }
      }

      // Shake delta
      final shakeDx = _currentEmotion == NoriEmotion.streakDanger
          ? math.sin(_shakeController.value * math.pi * 2) * 4.0
          : 0.0;

      // Breath phase
      final breatheT = _breatheController.value;

      // Speech bubble caret-safe positioning
      const double bubbleEstWidth = 118.0;
      final double bLeft = (_x + _size * 0.5 - bubbleEstWidth * 0.5)
          .clamp(8.0, math.max(8.0, _boxWidth - bubbleEstWidth - 8.0));
      final double bTop = math.max(6.0, _y + extraBounce - 30.0);

      return SizedBox(
        width: _boxWidth,
        height: _boxHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── LAYER 1: FX Canvas ──────────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FxCanvasPainter(
                    shockwaves: _shockwaves,
                    sparks: _sparks,
                    zenOrbs: _zenOrbs,
                    starFlashes: _starFlashes,
                    hearts: _hearts,
                  ),
                ),
              ),
            ),

            // ── LAYER 2: Speech Bubble (above Nori, never covering body) ────
            if (_bubbleText != null)
              Positioned(
                left: bLeft,
                top: bTop,
                child: AnimatedOpacity(
                  opacity: _bubbleOpacity,
                  duration: const Duration(milliseconds: 200),
                  child: _NoriSpeechPill(text: _bubbleText!),
                ),
              ),

            // ── LAYER 3: Nori Blob ─────────────────────────────────────────
            Positioned(
              left: _x,
              top: _y + extraBounce,
              width: _size,
              height: _size,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: _handleTap,
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_breatheController]),
                  builder: (_, __) => RepaintBoundary(
                    child: CustomPaint(
                      size: Size(_size, _size),
                      painter: NoriBlobPainter(
                        config: _currentConfig,
                        breatheT: breatheT,
                        darkModeOutline: isDark,
                        shakeDx: shakeDx,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEECH PILL (internal inline speech bubble — compact Duo-style)
// ─────────────────────────────────────────────────────────────────────────────

class _NoriSpeechPill extends StatelessWidget {
  final String text;
  const _NoriSpeechPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        // Lavender-tinted dark pill — matches Nori's palette, not app theme
        color: const Color(0xF02D1F5E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x4AC4B0FF),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFEDE9FF),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
