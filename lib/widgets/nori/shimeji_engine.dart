import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../services/tour/app_tour_controller.dart';

/// All behavioral modes available to Nori Shimeji
enum ShimejiMode {
  floorWalk,
  floorSit,
  floorLookUp,
  floorSpinHead,
  floorLoaf,
  handWaving,
  celebrating,
  sleepy,
  bored,
  playful,
  wallClimbUp,
  wallClimbDown,
  ceilingCrawl,
  jumping,
  falling,
  landingBounce,
  dragged,
}

/// Circadian periods based on local device real-time
enum CircadianPeriod {
  morning,   // 05:00 - 11:59: Energetic, playful, bouncy
  afternoon, // 12:00 - 16:59: Drowsy, bored, lazy loafing
  evening,   // 17:00 - 21:59: Prime study hours, attentive focus
  night,     // 22:00 - 04:59: Asleep, snoozing sprawl, zen orbs
}

/// Native Canvas FX - Vector Shockwave Ring
class _FxShockwave {
  double x;
  double y;
  double radius = 4.0;
  static const double maxRadius = 38.0;
  final Color color;
  double life = 1.0;
  static const double decay = 2.4;

  _FxShockwave({
    required this.x,
    required this.y,
    required this.color,
  });

  bool update(double dt) {
    radius += (maxRadius - radius) * 8.5 * dt;
    life -= decay * dt;
    return life > 0;
  }
}

/// Native Canvas FX - Radiant Spark Dot
class _FxSpark {
  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  final double size;
  double life = 1.0;
  static const double decay = 2.2;

  _FxSpark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vx *= math.pow(0.25, dt);
    vy *= math.pow(0.25, dt);
    life -= decay * dt;
    return life > 0;
  }
}

/// Native Canvas FX - Floating Zen Orb (Sleepy state)
class _FxZenOrb {
  double x;
  final double startX;
  double y;
  double phase;
  final double size;
  final Color color;
  double life;

  _FxZenOrb({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
  })  : startX = x,
        phase = math.Random().nextDouble() * math.pi * 2,
        life = 1.0;

  bool update(double dt) {
    y -= 14.0 * dt;
    phase += dt * 2.8;
    x = startX + math.sin(phase) * 5.0;
    life -= 0.6 * dt;
    return life > 0;
  }
}

/// Native Canvas FX - 4-Point Diamond Star Vector Flash
class _FxStarFlash {
  double x;
  double y;
  double size = 2.0;
  static const double maxSize = 16.0;
  final Color color;
  double life = 1.0;
  static const double decay = 2.2;

  _FxStarFlash({
    required this.x,
    required this.y,
    required this.color,
  });

  bool update(double dt) {
    size += (maxSize - size) * 9.0 * dt;
    life -= decay * dt;
    return life > 0;
  }
}

/// CustomPainter rendering all native vector FX at 60fps
class _FxPainter extends CustomPainter {
  final List<_FxShockwave> shockwaves;
  final List<_FxSpark> sparks;
  final List<_FxZenOrb> zenOrbs;
  final List<_FxStarFlash> starFlashes;

  _FxPainter({
    required this.shockwaves,
    required this.sparks,
    required this.zenOrbs,
    required this.starFlashes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Expanding Shockwaves
    for (final sw in shockwaves) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = sw.color.withValues(alpha: (sw.life * 0.85).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(sw.x, sw.y), sw.radius, paint);
    }

    // 2. Kinetic Spark Dots
    for (final sp in sparks) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = sp.color.withValues(alpha: (sp.life).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(sp.x, sp.y), sp.size * sp.life, paint);
    }

    // 3. Floating Zen Orbs
    for (final orb in zenOrbs) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = orb.color.withValues(alpha: (orb.life * 0.50).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(orb.x, orb.y), orb.size, paint);
    }

    // 4. Diamond Star Vector Flashes
    for (final star in starFlashes) {
      final alpha = (star.life).clamp(0.0, 1.0);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = star.color.withValues(alpha: alpha);

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

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FxPainter oldDelegate) => true;
}

class ShimejiEngine extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const ShimejiEngine({
    super.key,
    this.size = 64.0,
    this.onTap,
  });

  @override
  State<ShimejiEngine> createState() => ShimejiEngineState();
}

class ShimejiEngineState extends State<ShimejiEngine>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // Box Bounds
  double _boxWidth = 320.0;
  double _boxHeight = 150.0;

  // Physics & Position
  double _x = 100.0;
  double _y = 80.0;
  double _vx = 0.0;
  double _vy = 0.0;

  // Orientation
  int _facing = 1; // 1 = right, -1 = left
  int _wallSide = 1; // 1 = right wall, -1 = left wall

  // State
  ShimejiMode _mode = ShimejiMode.handWaving;
  int _currentSpriteIndex = 12;
  int _animationTick = 0;
  int _stateTicks = 0;

  // Drag interaction
  Offset _dragStartBoxPos = Offset.zero;
  Offset _dragStartGlobalPos = Offset.zero;
  Offset _lastDragPos = Offset.zero;
  DateTime _lastDragTime = DateTime.now();

  Duration _lastElapsed = Duration.zero;

  // Speech Bubble State
  String? _bubbleText;
  double _bubbleOpacity = 0.0;
  DateTime _bubbleHideTime = DateTime.now();

  // Native Vector FX lists
  final List<_FxShockwave> _shockwaves = [];
  final List<_FxSpark> _sparks = [];
  final List<_FxZenOrb> _zenOrbs = [];
  final List<_FxStarFlash> _starFlashes = [];

  // Frame sequences verified from official Shimeji sprite mapping
  static const List<int> _seqWalk = [0, 1, 0, 2];
  static const List<int> _seqSpinHead = [4, 5, 6, 7, 8, 9, 10, 3];
  static const List<int> _seqWallClimb = [21, 21, 22, 20, 20, 20, 22, 21];
  static const List<int> _seqCeilingCrawl = [18, 18, 17, 19, 19, 19, 17, 18];
  static const List<int> _seqBounce = [28, 29];
  static const List<int> _seqDragWiggle = [32, 33];

  // Authentic seated greeting: Left paw up, return, right paw up, return
  static const List<int> _seqHandWaving = [12, 13, 12, 14, 12, 13, 12];

  // Acrobatic somersault sequence: crouch -> launch -> flip -> tuck -> land -> leap -> finish
  static const List<int> _seqCelebrating = [28, 40, 41, 42, 43, 44, 28, 26, 29, 0, 3];

  // Circadian state sequences
  static const List<int> _seqSleepy = [11, 15, 16];
  static const List<int> _seqBored = [3, 4, 11];
  static const List<int> _seqPlayful = [28, 26, 27, 29];

  // Short, adorable dialogues (STRICTLY NO EMOJIS, 1-3 words max)
  static const List<String> _dialoguesMorning = [
    'Rise & shine!',
    'Ready, Doc?',
    'Let\'s study!',
    'Streak +1!',
    'Good morning!',
  ];

  static const List<String> _dialoguesAfternoon = [
    'Yawn...',
    'Take a break?',
    'Hydrate!',
    'Stay cool!',
    'Stretch out!',
  ];

  static const List<String> _dialoguesEvening = [
    'Focus time!',
    'Deep work!',
    'Keep going!',
    'Almost there!',
    'Study on!',
  ];

  static const List<String> _dialoguesNight = [
    'Zzz...',
    'Sleep well!',
    'Rest up!',
    'Quiet time...',
    'Night, Doc!',
  ];

  static const List<String> _dialoguesPet = [
    'Purr...',
    'Hehe!',
    'Mew!',
    'Streak +1!',
    'Nice!',
  ];

  static const List<String> _dialoguesCelebrate = [
    'Crushed it!',
    'Epic!',
    'Level up!',
    'Top rank!',
    'Nailed it!',
  ];

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
    _ticker.start();

    // Natural App Startup: Friendly Hand Wave Greeting!
    _mode = ShimejiMode.handWaving;
    _currentSpriteIndex = 12;

    AppTourNotifier.onPlayNoriAnimation = playTourAnimationSequence;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showBubble('Hey Safi!', durationMs: 2800);
        _spawnStarFlash(_x + widget.size * 0.5, _y + 10.0, const Color(0xFF2DD4BF));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache all 45 frames (0000.webp - 0044.webp) to eliminate flicker
    for (int i = 0; i <= 44; i++) {
      final name = i.toString().padLeft(4, '0');
      precacheImage(
        AssetImage('assets/sprites/73wgl0lx/sprites/$name.webp'),
        context,
      );
    }
  }

  @override
  void dispose() {
    if (AppTourNotifier.onPlayNoriAnimation == playTourAnimationSequence) {
      AppTourNotifier.onPlayNoriAnimation = null;
    }
    _ticker.dispose();
    super.dispose();
  }

  double get _maxX => math.max(0.0, _boxWidth - widget.size);
  double get _maxY => math.max(0.0, _boxHeight - widget.size);

  double get _leftWallX => -21.0;
  double get _rightWallX => _maxX + 21.0;
  double get _ceilingY => -20.0;
  double get _floorY => _maxY;

  /// Current circadian period based on local clock
  CircadianPeriod get currentCircadianPeriod {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return CircadianPeriod.morning;
    if (hour >= 12 && hour < 17) return CircadianPeriod.afternoon;
    if (hour >= 17 && hour < 22) return CircadianPeriod.evening;
    return CircadianPeriod.night;
  }

  /// Show a minimalist floating speech bubble
  void showBubble(String text, {int durationMs = 2800}) {
    setState(() {
      _bubbleText = text;
      _bubbleOpacity = 1.0;
      _bubbleHideTime = DateTime.now().add(Duration(milliseconds: durationMs));
    });
  }

  /// Trigger a celebratory somersault with vector shockwave & sparks
  void triggerCelebrate() {
    setState(() {
      _mode = ShimejiMode.celebrating;
      _stateTicks = 0;
      final rand = math.Random();
      showBubble(_dialoguesCelebrate[rand.nextInt(_dialoguesCelebrate.length)]);
      _spawnShockwave(_x + widget.size * 0.5, _floorY + widget.size * 0.8, const Color(0xFFF59E0B));
      _spawnSparkBurst(_x + widget.size * 0.5, _floorY + 10.0, const Color(0xFFF59E0B));
    });
  }

  /// Trigger a friendly seated hand wave
  void triggerWave() {
    setState(() {
      _mode = ShimejiMode.handWaving;
      _stateTicks = 0;
      showBubble('Hey Safi!');
      _spawnStarFlash(_x + widget.size * 0.5, _y + 10.0, const Color(0xFF2DD4BF));
    });
  }

  /// Trigger a playful bounce and hop
  void triggerPlayful() {
    setState(() {
      _mode = ShimejiMode.playful;
      _stateTicks = 0;
      showBubble('Play time!');
    });
  }

  /// Showcase sequence for App Tour: wave -> playful hop -> celebration somersault
  void playTourAnimationSequence() {
    triggerWave();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        triggerPlayful();
      }
    });
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        triggerCelebrate();
      }
    });
  }

  // ── VECTOR FX SPAWNERS ────────────────────────────────────────────────────
  void _spawnShockwave(double x, double y, Color color) {
    _shockwaves.add(_FxShockwave(x: x, y: y, color: color));
  }

  void _spawnSparkBurst(double x, double y, Color color, {int count = 8}) {
    final rand = math.Random();
    for (int i = 0; i < count; i++) {
      final angle = rand.nextDouble() * math.pi * 2;
      final speed = 35.0 + rand.nextDouble() * 55.0;
      _sparks.add(_FxSpark(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: color,
        size: 2.2 + rand.nextDouble() * 1.6,
      ));
    }
  }

  void _spawnZenOrb(double x, double y) {
    _zenOrbs.add(_FxZenOrb(
      x: x + (math.Random().nextDouble() - 0.5) * 20.0,
      y: y,
      size: 3.5 + math.Random().nextDouble() * 2.0,
      color: const Color(0xFFA855F7), // Soft purple zen orb
    ));
  }

  void _spawnStarFlash(double x, double y, Color color) {
    _starFlashes.add(_FxStarFlash(x: x, y: y, color: color));
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt <= 0.0 || dt > 0.1) return; // guard against lag spikes

    _stateTicks++;
    _animationTick++;

    // Update speech bubble timeout
    if (_bubbleOpacity > 0.0 && DateTime.now().isAfter(_bubbleHideTime)) {
      _bubbleOpacity = 0.0;
    }

    // Update FX
    _shockwaves.removeWhere((sw) => !sw.update(dt));
    _sparks.removeWhere((sp) => !sp.update(dt));
    _zenOrbs.removeWhere((orb) => !orb.update(dt));
    _starFlashes.removeWhere((sf) => !sf.update(dt));

    setState(() {
      _updatePhysicsAndAi(dt);
    });
  }

  void _updatePhysicsAndAi(double dt) {
    switch (_mode) {
      case ShimejiMode.handWaving:
        _handleHandWaving();
        break;
      case ShimejiMode.celebrating:
        _handleCelebrating(dt);
        break;
      case ShimejiMode.sleepy:
        _handleSleepy();
        break;
      case ShimejiMode.bored:
        _handleBored();
        break;
      case ShimejiMode.playful:
        _handlePlayful();
        break;
      case ShimejiMode.floorWalk:
        _handleFloorWalk(dt);
        break;
      case ShimejiMode.floorSit:
        _handleFloorSit();
        break;
      case ShimejiMode.floorLookUp:
        _handleFloorLookUp();
        break;
      case ShimejiMode.floorSpinHead:
        _handleFloorSpinHead();
        break;
      case ShimejiMode.floorLoaf:
        _handleFloorLoaf();
        break;
      case ShimejiMode.wallClimbUp:
        _handleWallClimbUp(dt);
        break;
      case ShimejiMode.wallClimbDown:
        _handleWallClimbDown(dt);
        break;
      case ShimejiMode.ceilingCrawl:
        _handleCeilingCrawl(dt);
        break;
      case ShimejiMode.jumping:
      case ShimejiMode.falling:
        _handleAirborne(dt);
        break;
      case ShimejiMode.landingBounce:
        _handleLandingBounce();
        break;
      case ShimejiMode.dragged:
        final isMoving = _vx.abs() > 20 || _vy.abs() > 20;
        if (isMoving) {
          final step = (_animationTick ~/ 6) % _seqDragWiggle.length;
          _currentSpriteIndex = _seqDragWiggle[step];
        } else {
          _currentSpriteIndex = 30; // Pinched pose
        }
        break;
    }
  }

  // ── CORE ACTIONS IMPLEMENTATION ──────────────────────────────────────────

  /// 1. Hand Waving: Smooth Seated Greeting (12 -> 13 -> 12 -> 14 -> 12)
  void _handleHandWaving() {
    _y = _floorY;
    final step = (_stateTicks ~/ 10);
    if (step < _seqHandWaving.length) {
      _currentSpriteIndex = _seqHandWaving[step];
    } else {
      _mode = ShimejiMode.floorSit;
      _stateTicks = 0;
    }
  }

  /// 2. Celebrating: Acrobatic Somersault Flip Sequence
  void _handleCelebrating(dt) {
    final step = (_stateTicks ~/ 7);
    if (step < _seqCelebrating.length) {
      _currentSpriteIndex = _seqCelebrating[step];
      // Elevate sprite during somersault peak (frames 41, 42, 43, 26)
      if (_currentSpriteIndex >= 40 && _currentSpriteIndex <= 43) {
        _y = _floorY - 14.0;
      } else if (_currentSpriteIndex == 26) {
        _y = _floorY - 20.0;
      } else {
        _y = _floorY;
      }
    } else {
      _y = _floorY;
      _mode = ShimejiMode.floorSit;
      _stateTicks = 0;
    }
  }

  /// 3. Sleepy: Cozy snooze sprawl on card floor with zen orbs
  void _handleSleepy() {
    _y = _floorY;
    final step = (_stateTicks ~/ 24) % _seqSleepy.length;
    _currentSpriteIndex = _seqSleepy[step];

    // Periodically emit gentle zen orb
    if (_stateTicks % 50 == 0) {
      _spawnZenOrb(_x + widget.size * 0.5, _y + 6.0);
    }

    if (_stateTicks > 240 && math.Random().nextDouble() < 0.01) {
      // In night hours, stay sleeping longer
      if (currentCircadianPeriod != CircadianPeriod.night || math.Random().nextDouble() < 0.2) {
        _mode = ShimejiMode.floorSit;
        _stateTicks = 0;
      }
    }
  }

  /// 4. Bored: Slump, yawn, and look up
  void _handleBored() {
    _y = _floorY;
    final step = (_stateTicks ~/ 18) % _seqBored.length;
    _currentSpriteIndex = _seqBored[step];

    if (_stateTicks > 150 && math.Random().nextDouble() < 0.015) {
      _mode = ShimejiMode.floorSit;
      _stateTicks = 0;
    }
  }

  /// 5. Playful: Bounce & pounce coil
  void _handlePlayful() {
    _y = _floorY;
    final step = (_stateTicks ~/ 8);
    if (step < _seqPlayful.length) {
      _currentSpriteIndex = _seqPlayful[step];
      if (_currentSpriteIndex == 26) {
        _y = _floorY - 16.0;
      }
    } else {
      _y = _floorY;
      _mode = ShimejiMode.floorWalk;
      _stateTicks = 0;
    }
  }

  // ── FLOOR ROAMING & CIRCADIAN BEHAVIOR ────────────────────────────────────
  void _handleFloorWalk(double dt) {
    _y = _floorY;
    const speed = 55.0; // px/sec
    _x += _facing * speed * dt;

    final frameStep = (_animationTick ~/ 7) % _seqWalk.length;
    _currentSpriteIndex = _seqWalk[frameStep];

    // Check hit walls
    if (_facing == 1 && _x >= _maxX + 8.0) {
      _x = _maxX + 8.0;
      _onHitWall(rightSide: true);
    } else if (_facing == -1 && _x <= -8.0) {
      _x = -8.0;
      _onHitWall(rightSide: false);
    } else if (_stateTicks > 160 && math.Random().nextDouble() < 0.014) {
      _pickRandomFloorAction();
    }
  }

  void _onHitWall({required bool rightSide}) {
    _wallSide = rightSide ? 1 : -1;
    final r = math.Random().nextDouble();

    if (r < 0.50) {
      // 50% chance: Climb wall
      _mode = ShimejiMode.wallClimbUp;
      _x = rightSide ? _rightWallX : _leftWallX;
      _stateTicks = 0;
    } else if (r < 0.80) {
      // 30% chance: Turn around and walk
      _facing = -_wallSide;
      _mode = ShimejiMode.floorWalk;
      _stateTicks = 0;
    } else {
      // 20% chance: Sit by the wall
      _facing = -_wallSide;
      _mode = ShimejiMode.floorSit;
      _stateTicks = 0;
    }
  }

  void _pickRandomFloorAction() {
    _stateTicks = 0;
    final period = currentCircadianPeriod;
    final r = math.Random().nextDouble();

    // Circadian Action Selection Engine:
    if (period == CircadianPeriod.night) {
      // Night: Favor sleeping (60%), loafing (25%), sit (15%)
      if (r < 0.60) {
        _mode = ShimejiMode.sleepy;
        if (math.Random().nextDouble() < 0.3) {
          showBubble(_dialoguesNight[math.Random().nextInt(_dialoguesNight.length)]);
        }
      } else if (r < 0.85) {
        _mode = ShimejiMode.floorLoaf;
      } else {
        _mode = ShimejiMode.floorSit;
      }
    } else if (period == CircadianPeriod.afternoon) {
      // Afternoon: Favor bored (35%), loafing (30%), walk (20%), sit (15%)
      if (r < 0.35) {
        _mode = ShimejiMode.bored;
        if (math.Random().nextDouble() < 0.25) {
          showBubble(_dialoguesAfternoon[math.Random().nextInt(_dialoguesAfternoon.length)]);
        }
      } else if (r < 0.65) {
        _mode = ShimejiMode.floorLoaf;
      } else if (r < 0.85) {
        _mode = ShimejiMode.floorSit;
      } else {
        _facing = -_facing;
        _mode = ShimejiMode.floorWalk;
      }
    } else if (period == CircadianPeriod.morning) {
      // Morning: Favor playful (40%), jumping (25%), walk (25%), spin head (10%)
      if (r < 0.40) {
        _mode = ShimejiMode.playful;
        if (math.Random().nextDouble() < 0.3) {
          showBubble(_dialoguesMorning[math.Random().nextInt(_dialoguesMorning.length)]);
        }
      } else if (r < 0.65) {
        _mode = ShimejiMode.jumping;
        _vy = -340.0;
        _vx = _facing * 40.0;
      } else if (r < 0.85) {
        _facing = -_facing;
        _mode = ShimejiMode.floorWalk;
      } else {
        _mode = ShimejiMode.floorSpinHead;
      }
    } else {
      // Evening: Study Focus - sit (35%), look up (25%), spin head (20%), walk (20%)
      if (r < 0.35) {
        _mode = ShimejiMode.floorSit;
        if (math.Random().nextDouble() < 0.25) {
          showBubble(_dialoguesEvening[math.Random().nextInt(_dialoguesEvening.length)]);
        }
      } else if (r < 0.60) {
        _mode = ShimejiMode.floorLookUp;
      } else if (r < 0.80) {
        _mode = ShimejiMode.floorSpinHead;
      } else {
        _facing = -_facing;
        _mode = ShimejiMode.floorWalk;
      }
    }
  }

  void _handleFloorSit() {
    _y = _floorY;
    _currentSpriteIndex = 3;
    if (_stateTicks > 120 && math.Random().nextDouble() < 0.02) {
      _facing = math.Random().nextBool() ? 1 : -1;
      _mode = ShimejiMode.floorWalk;
      _stateTicks = 0;
    }
  }

  void _handleFloorLookUp() {
    _y = _floorY;
    _currentSpriteIndex = 4;
    if (_stateTicks > 90 && math.Random().nextDouble() < 0.025) {
      _mode = ShimejiMode.floorSit;
      _stateTicks = 0;
    }
  }

  void _handleFloorSpinHead() {
    _y = _floorY;
    final step = (_stateTicks ~/ 8);
    if (step < _seqSpinHead.length) {
      _currentSpriteIndex = _seqSpinHead[step];
    } else {
      _mode = ShimejiMode.floorSit;
      _stateTicks = 0;
    }
  }

  void _handleFloorLoaf() {
    _y = _floorY;
    _currentSpriteIndex = 12; // Loafing cat
    if (_stateTicks > 160 && math.Random().nextDouble() < 0.015) {
      _mode = ShimejiMode.floorWalk;
      _stateTicks = 0;
    }
  }

  // ── WALL CLIMBING ────────────────────────────────────────────────────────
  void _handleWallClimbUp(double dt) {
    _x = (_wallSide == 1) ? _rightWallX : _leftWallX;
    const climbSpeed = 48.0; // px/sec
    _y -= climbSpeed * dt;

    final frameStep = (_animationTick ~/ 8) % _seqWallClimb.length;
    _currentSpriteIndex = _seqWallClimb[frameStep];

    // Reached ceiling!
    if (_y <= _ceilingY) {
      _y = _ceilingY;
      final r = math.Random().nextDouble();
      if (r < 0.75) {
        _facing = -_wallSide;
        _mode = ShimejiMode.ceilingCrawl;
      } else {
        _mode = ShimejiMode.falling;
        _vy = 40.0;
        _vx = -_wallSide * 35.0;
        _facing = -_wallSide;
      }
      _stateTicks = 0;
    } else if (_stateTicks > 90 && math.Random().nextDouble() < 0.010) {
      _mode = ShimejiMode.falling;
      _vy = 30.0;
      _vx = -_wallSide * 20.0;
      _facing = -_wallSide;
      _stateTicks = 0;
    }
  }

  void _handleWallClimbDown(double dt) {
    _x = (_wallSide == 1) ? _rightWallX : _leftWallX;
    const climbSpeed = 50.0;
    _y += climbSpeed * dt;

    final frameStep = (_animationTick ~/ 8) % _seqWallClimb.length;
    _currentSpriteIndex = _seqWallClimb[frameStep];

    if (_y >= _floorY) {
      _y = _floorY;
      _x = (_wallSide == 1) ? (_maxX + 8.0) : -8.0;
      _facing = -_wallSide;
      _mode = ShimejiMode.floorWalk;
      _stateTicks = 0;
    }
  }

  // ── CEILING CRAWL ────────────────────────────────────────────────────────
  void _handleCeilingCrawl(double dt) {
    _y = _ceilingY;
    const crawlSpeed = 42.0;
    _x += _facing * crawlSpeed * dt;

    final frameStep = (_animationTick ~/ 8) % _seqCeilingCrawl.length;
    _currentSpriteIndex = _seqCeilingCrawl[frameStep];

    if (_facing == 1 && _x >= _rightWallX) {
      _x = _rightWallX;
      _wallSide = 1;
      _mode = ShimejiMode.wallClimbDown;
      _stateTicks = 0;
    } else if (_facing == -1 && _x <= _leftWallX) {
      _x = _leftWallX;
      _wallSide = -1;
      _mode = ShimejiMode.wallClimbDown;
      _stateTicks = 0;
    } else if (_stateTicks > 120 && math.Random().nextDouble() < 0.012) {
      _mode = ShimejiMode.falling;
      _vy = 30.0;
      _stateTicks = 0;
    }
  }

  // ── AIRBORNE (Jumping & Falling with Gravity) ─────────────────────────────
  void _handleAirborne(double dt) {
    const gravity = 980.0; // px/sec²
    _vy += gravity * dt;
    _x += _vx * dt;
    _y += _vy * dt;

    if (_vx > 15.0) {
      _facing = 1;
    } else if (_vx < -15.0) {
      _facing = -1;
    }

    if (_vy < -40.0) {
      _currentSpriteIndex = 26; // jumping up
    } else {
      _currentSpriteIndex = 27; // falling down
    }

    if (_x < _leftWallX) {
      _x = _leftWallX;
      _vx = -_vx * 0.4;
    } else if (_x > _rightWallX) {
      _x = _rightWallX;
      _vx = -_vx * 0.4;
    }

    if (_y >= _floorY) {
      _y = _floorY;
      _vy = 0.0;
      _vx = 0.0;
      _mode = ShimejiMode.landingBounce;
      _stateTicks = 0;
    }
  }

  void _handleLandingBounce() {
    _y = _floorY;
    final step = (_stateTicks ~/ 6);
    if (step < _seqBounce.length) {
      _currentSpriteIndex = _seqBounce[step];
    } else {
      _mode = ShimejiMode.floorSit;
      _stateTicks = 0;
    }
  }

  // ── DRAG INTERACTION ─────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails details) {
    HapticFeedback.mediumImpact();
    _mode = ShimejiMode.dragged;
    _dragStartBoxPos = Offset(_x, _y);
    _dragStartGlobalPos = details.globalPosition;
    _lastDragPos = details.globalPosition;
    _lastDragTime = DateTime.now();
    _vx = 0.0;
    _vy = 0.0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final now = DateTime.now();
    final dt = (now.difference(_lastDragTime).inMicroseconds) / 1000000.0;
    if (dt > 0.005) {
      _vx = (details.globalPosition.dx - _lastDragPos.dx) / dt;
      _vy = (details.globalPosition.dy - _lastDragPos.dy) / dt;
      _lastDragPos = details.globalPosition;
      _lastDragTime = now;
      if (_vx > 20.0) {
        _facing = 1;
      } else if (_vx < -20.0) {
        _facing = -1;
      }
    }

    final delta = details.globalPosition - _dragStartGlobalPos;
    setState(() {
      _x = (_dragStartBoxPos.dx + delta.dx).clamp(_leftWallX, _rightWallX);
      _y = (_dragStartBoxPos.dy + delta.dy).clamp(_ceilingY, _floorY);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _mode = ShimejiMode.falling;
    _vx = (_vx * 0.35).clamp(-300.0, 300.0);
    _vy = (_vy * 0.35).clamp(-200.0, 400.0);
    _stateTicks = 0;
  }

  // ── TAP INTERACTION ──────────────────────────────────────────────────────
  void _handleTap() {
    HapticFeedback.lightImpact();

    // Spawn native vector shockwave ring & spark burst (NO EMOJIS, NO CONFETTI)
    _spawnShockwave(_x + widget.size * 0.5, _y + widget.size * 0.5, const Color(0xFF2DD4BF));
    _spawnSparkBurst(_x + widget.size * 0.5, _y + widget.size * 0.5, const Color(0xFF2DD4BF), count: 10);

    // Pick cute 1-2 word response
    final rand = math.Random();
    showBubble(_dialoguesPet[rand.nextInt(_dialoguesPet.length)], durationMs: 2200);

    // Reactive motion:
    if (_mode == ShimejiMode.sleepy || _mode == ShimejiMode.bored) {
      // Wake up with happy sit or jump!
      _mode = ShimejiMode.jumping;
      _vy = -280.0;
      _vx = _facing * 25.0;
    } else if (_mode == ShimejiMode.floorSit || _mode == ShimejiMode.floorWalk) {
      final r = rand.nextDouble();
      if (r < 0.40) {
        // Celebrate flip
        triggerCelebrate();
      } else if (r < 0.75) {
        // Playful jump
        _mode = ShimejiMode.jumping;
        _vy = -320.0;
        _vx = _facing * 30.0;
      } else {
        // Hand wave greeting
        triggerWave();
      }
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _boxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : widget.size;
        _boxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : widget.size;

        // Ensure cat stays within bounds
        _x = _x.clamp(_leftWallX, _rightWallX);
        _y = _y.clamp(_ceilingY, _floorY);

        double scaleX = 1.0;
        const double scaleY = 1.0;

        if (_mode == ShimejiMode.wallClimbUp || _mode == ShimejiMode.wallClimbDown) {
          scaleX = (_wallSide == 1) ? -1.0 : 1.0;
        } else {
          scaleX = (_facing == 1) ? -1.0 : 1.0;
        }

        final spritePath = 'assets/sprites/73wgl0lx/sprites/'
            '${_currentSpriteIndex.toString().padLeft(4, '0')}.webp';

        // Clamp speech bubble position within hero card boundaries
        const double bubbleEstWidth = 110.0;
        final double bubbleLeft = (_x + widget.size * 0.5 - bubbleEstWidth * 0.5)
            .clamp(8.0, math.max(8.0, _boxWidth - bubbleEstWidth - 8.0));
        final double bubbleTop = math.max(6.0, _y - 28.0);

        return SizedBox(
          width: _boxWidth,
          height: _boxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
            // ── LAYER 1: Native Vector Canvas FX ───────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FxPainter(
                    shockwaves: _shockwaves,
                    sparks: _sparks,
                    zenOrbs: _zenOrbs,
                    starFlashes: _starFlashes,
                  ),
                ),
              ),
            ),

            // ── LAYER 2: Ultra-Compact Minimalist Speech Bubble ───────────
            if (_bubbleText != null)
              Positioned(
                left: bubbleLeft,
                top: bubbleTop,
                child: AnimatedOpacity(
                  opacity: _bubbleOpacity,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xE80F172A), // Dark slate pill
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x402DD4BF), // Subtle cyan border
                        width: 1.0,
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
                      _bubbleText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),

            // ── LAYER 3: Animated Mascot Sprite ────────────────────────────
            Positioned(
              left: _x,
              top: _y,
              width: widget.size,
              height: widget.size,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: _handleTap,
                behavior: HitTestBehavior.opaque,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                  child: Image.asset(
                    spritePath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ],
        ));
      },
    );
  }
}
