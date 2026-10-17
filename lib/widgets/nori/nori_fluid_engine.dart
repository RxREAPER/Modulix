import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'nori_speech_bubble.dart';
import 'nori_state_machine.dart';

export 'nori_state_machine.dart';

/// Shimeji locomotion and behavioral modes for Nori.
enum ShimejiMode {
  floorWalk, // Walking along bottom edge of card
  floorStudy, // Diligent desk study session (book, spectacles, tail swish)
  floorSleep, // Curled up sleeping loaf (gentle biological breathing)
  wallClimbUp, // Climbing up side wall (rotated ±90°)
  wallClimbDown, // Climbing down side wall
  ceilingCrawl, // Crawling along top ceiling (rotated 180°)
  falling, // Airborne drop with gravity acceleration
  landingBounce, // Squish bounce upon floor landing
  loveReaction, // Joyful heart celebration on tap/petting
  dragged, // Picked up by user finger, dangling
}

/// Fluid, stateful Shimeji physics & continuous companion engine for Nori.
class NoriFluidEngine extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final NoriAction? forcedAction;
  final bool enablePhysics;
  final bool enableIdleAi;

  const NoriFluidEngine({
    super.key,
    this.size = 68.0,
    this.onTap,
    this.onDoubleTap,
    this.forcedAction,
    this.enablePhysics = true,
    this.enableIdleAi = true,
  });

  @override
  State<NoriFluidEngine> createState() => NoriFluidEngineState();
}

class NoriFluidEngineState extends State<NoriFluidEngine>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // Terrarium Card Box Bounds
  double _boxWidth = 340.0;
  double _boxHeight = 148.0;

  // Kinematics & Position
  double _x = 90.0;
  double _y = 80.0;
  double _vx = 0.0;
  double _vy = 0.0;

  // Orientation & Edge Anchors
  int _facing = 1; // 1 = Moving Right, -1 = Moving Left
  int _wallSide = 1; // 1 = Right Wall, -1 = Left Wall

  // Shimeji Behavioral State Machine
  ShimejiMode _mode = ShimejiMode.floorWalk;
  int _currentFrame = 0;
  double _frameTimer = 0.0;

  // Activity Timers (Continuation Loop)
  double _modeDuration = 0.0;
  double _bounceTimer = 0.0;

  // Floating Speech Bubble
  String? _speechText;
  String? _speechBadge;
  Timer? _speechTimer;

  // Drag Interaction
  bool _isDragging = false;
  Offset _dragStartBoxPos = Offset.zero;
  Offset _dragStartGlobalPos = Offset.zero;
  Offset _lastDragPos = Offset.zero;
  DateTime _lastDragTime = DateTime.now();

  Duration _lastElapsed = Duration.zero;

  // Frame counts and speeds per motion action
  static const int _walkFrames = 4;
  static const double _walkFps = 7.0;

  static const int _studyFrames = 4;
  static const double _studyFps = 3.5;

  static const int _sleepFrames = 3;
  static const double _sleepFps = 2.5;

  static const int _loveFrames = 3;
  static const double _loveFps = 3.0;

  @override
  void initState() {
    super.initState();

    _applyForcedAction(widget.forcedAction);

    _ticker = createTicker(_onTick);
    _ticker.start();

    // Start with a natural drop to the card floor
    if (widget.enablePhysics && widget.forcedAction == null) {
      _mode = ShimejiMode.falling;
      _vy = 90.0;
    }
  }

  void _applyForcedAction(NoriAction? action) {
    if (action == null) return;
    switch (action) {
      case NoriAction.studying:
        _mode = ShimejiMode.floorStudy;
        break;
      case NoriAction.sleepy:
      case NoriAction.yawningLoaf:
      case NoriAction.rollingSleep:
      case NoriAction.tired:
      case NoriAction.bored:
      case NoriAction.sad:
        _mode = ShimejiMode.floorSleep;
        break;
      case NoriAction.walking:
      case NoriAction.running:
        _mode = ShimejiMode.floorWalk;
        break;
      case NoriAction.celebrating:
      case NoriAction.celebratingAlt:
      case NoriAction.love:
      case NoriAction.excited:
      case NoriAction.playful:
      case NoriAction.welcoming:
      case NoriAction.eating:
        _mode = ShimejiMode.loveReaction;
        break;
    }
    _currentFrame = 0;
    _frameTimer = 0.0;
    _modeDuration = 0.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAllFrames();
  }

  void _precacheAllFrames() {
    for (int i = 0; i < 4; i++) {
      precacheImage(AssetImage("assets/sprites/nori_v2/study/$i.png"), context);
      precacheImage(AssetImage("assets/sprites/nori_v2/walk/$i.png"), context);
    }
    for (int i = 0; i < 3; i++) {
      precacheImage(AssetImage("assets/sprites/nori_v2/sleep/$i.png"), context);
      precacheImage(AssetImage("assets/sprites/nori_v2/love/$i.png"), context);
    }
    precacheImage(const AssetImage("assets/sprites/nori_v2/idle/0.png"), context);
  }

  @override
  void didUpdateWidget(covariant NoriFluidEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forcedAction != oldWidget.forcedAction && widget.forcedAction != null) {
      setState(() {
        _applyForcedAction(widget.forcedAction);
      });
    }
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  double get _maxX => math.max(0.0, _boxWidth - widget.size);
  double get _maxY => math.max(0.0, _boxHeight - widget.size);

  // Exact padding offsets so paws snug right on card edges
  double get _floorY => _maxY;
  double get _ceilingY => -4.0;
  double get _leftWallX => -6.0;
  double get _rightWallX => _maxX + 6.0;

  // ── PUBLIC MANUAL TRIGGERS ─────────────────────────────────────────────────
  void triggerMode(ShimejiMode mode) {
    setState(() {
      _mode = mode;
      _currentFrame = 0;
      _frameTimer = 0.0;
      _modeDuration = 0.0;
      if (mode == ShimejiMode.floorStudy || mode == ShimejiMode.floorSleep || mode == ShimejiMode.loveReaction) {
        _y = _floorY;
        _vx = 0.0;
        _vy = 0.0;
      }
    });
  }

  void triggerStudy() => triggerMode(ShimejiMode.floorStudy);
  void triggerSleep() => triggerMode(ShimejiMode.floorSleep);
  void triggerWalk() => triggerMode(ShimejiMode.floorWalk);
  void triggerWallClimb({bool rightSide = true}) {
    setState(() {
      _wallSide = rightSide ? 1 : -1;
      _x = rightSide ? _rightWallX : _leftWallX;
      _mode = ShimejiMode.wallClimbUp;
      _currentFrame = 0;
      _frameTimer = 0.0;
      _modeDuration = 0.0;
    });
  }
  void triggerDrop() {
    setState(() {
      _mode = ShimejiMode.falling;
      _vy = 60.0;
      _vx = _facing * 30.0;
      _modeDuration = 0.0;
    });
  }

  // Backwards compatible method
  void setAction(NoriAction action, {bool immediate = false}) {
    _applyForcedAction(action);
  }

  void _showSpeech(
    String text, {
    String? badge,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    _speechTimer?.cancel();
    setState(() {
      _speechText = text;
      _speechBadge = badge;
    });
    _speechTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _speechText = null;
          _speechBadge = null;
        });
      }
    });
  }

  // ── CORE TICK ENGINE ─────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt <= 0.0 || dt > 0.1) return; // Prevent lag spikes

    _modeDuration += dt;
    _updateAnimationFrames(dt);

    if (widget.enablePhysics && !_isDragging) {
      _updatePhysicsAndLocomotion(dt);
    }

    setState(() {});
  }

  void _updateAnimationFrames(double dt) {
    _frameTimer += dt;

    int maxFrames = _walkFrames;
    double fps = _walkFps;

    switch (_mode) {
      case ShimejiMode.floorStudy:
        maxFrames = _studyFrames;
        fps = _studyFps;
        break;
      case ShimejiMode.floorSleep:
        maxFrames = _sleepFrames;
        fps = _sleepFps;
        break;
      case ShimejiMode.loveReaction:
        maxFrames = _loveFrames;
        fps = _loveFps;
        break;
      case ShimejiMode.landingBounce:
        maxFrames = 1;
        fps = 1.0;
        break;
      case ShimejiMode.floorWalk:
      case ShimejiMode.wallClimbUp:
      case ShimejiMode.wallClimbDown:
      case ShimejiMode.ceilingCrawl:
      case ShimejiMode.falling:
      case ShimejiMode.dragged:
        maxFrames = _walkFrames;
        fps = _walkFps;
        break;
    }

    final frameInterval = 1.0 / fps;
    if (_frameTimer >= frameInterval) {
      _frameTimer -= frameInterval;
      _currentFrame = (_currentFrame + 1) % maxFrames;
    }
  }

  // ── PHYSICS & CONTINUATION LIFECYCLE ─────────────────────────────────────
  void _updatePhysicsAndLocomotion(double dt) {
    // If user has set a fixed forced action, honor it and avoid autonomous roaming
    if (widget.forcedAction != null) {
      _y = _floorY;
      _x = _x.clamp(0.0, _maxX);
      return;
    }

    switch (_mode) {
      case ShimejiMode.floorWalk:
        _handleFloorWalk(dt);
        break;
      case ShimejiMode.floorStudy:
        _handleFloorStudy(dt);
        break;
      case ShimejiMode.floorSleep:
        _handleFloorSleep(dt);
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
      case ShimejiMode.falling:
        _handleFalling(dt);
        break;
      case ShimejiMode.landingBounce:
        _handleLandingBounce(dt);
        break;
      case ShimejiMode.loveReaction:
        _handleLoveReaction(dt);
        break;
      case ShimejiMode.dragged:
        break;
    }
  }

  // ── FLOOR WALKING & ACTIVITY INITIATION ──────────────────────────────────
  void _handleFloorWalk(double dt) {
    _y = _floorY;
    const speed = 52.0; // px/sec
    _x += _facing * speed * dt;

    // Check Wall Collisions (Reaching edges of Hero Card)
    if (_facing == 1 && _x >= _rightWallX) {
      _x = _rightWallX;
      _onHitWall(rightSide: true);
    } else if (_facing == -1 && _x <= _leftWallX) {
      _x = _leftWallX;
      _onHitWall(rightSide: false);
    } else if (_modeDuration > 3.8 && widget.enableIdleAi) {
      // Activity Continuation: After strolling across the floor, decide next activity!
      final rand = math.Random().nextDouble();
      if (rand < 0.016 && _x > 30.0 && _x < _maxX - 30.0) {
        // Stop & begin a diligent desk study session!
        _mode = ShimejiMode.floorStudy;
        _modeDuration = 0.0;
        _currentFrame = 0;
        _showSpeech("Focus time! Reviewing high-yield concepts", badge: "STUDY");
      }
    }
  }

  void _onHitWall({required bool rightSide}) {
    _wallSide = rightSide ? 1 : -1;
    final r = math.Random().nextDouble();

    if (r < 0.58) {
      // 58% Chance: CLIMB UP THE WALL! (Shimeji Perimeter Traversal)
      _mode = ShimejiMode.wallClimbUp;
      _x = rightSide ? _rightWallX : _leftWallX;
      _modeDuration = 0.0;
    } else if (r < 0.85) {
      // 27% Chance: Turn around and walk opposite
      _facing = -_wallSide;
      _mode = ShimejiMode.floorWalk;
      _modeDuration = 0.0;
    } else {
      // 15% Chance: Settle down right here to study
      _mode = ShimejiMode.floorStudy;
      _modeDuration = 0.0;
      _currentFrame = 0;
    }
  }

  // ── DESK STUDY SESSION (~12-14 seconds) ───────────────────────────────────
  void _handleFloorStudy(double dt) {
    _y = _floorY;
    _vx = 0.0;
    _vy = 0.0;

    if (!widget.enableIdleAi) return;

    // Diligent study session for ~12 seconds
    if (_modeDuration > 12.0) {
      // Study session complete -> transition to a cozy nap (Sleep Loaf)
      _mode = ShimejiMode.floorSleep;
      _modeDuration = 0.0;
      _currentFrame = 0;
      _showSpeech("Power nap... resting eyes", badge: "REST");
    }
  }

  // ── SLEEP LOAF REST (~8-10 seconds) ──────────────────────────────────────
  void _handleFloorSleep(double dt) {
    _y = _floorY;
    _vx = 0.0;
    _vy = 0.0;

    if (!widget.enableIdleAi) return;

    // Nap for ~8 seconds, then wake up refreshed and resume patrol
    if (_modeDuration > 8.0) {
      _mode = ShimejiMode.floorWalk;
      _modeDuration = 0.0;
      _currentFrame = 0;
      _facing = math.Random().nextBool() ? 1 : -1;
      _showSpeech("Refreshed! Let's get moving", badge: "AWAKE");
    }
  }

  // ── LOVE REACTION (Affection / Celebration) ──────────────────────────────
  void _handleLoveReaction(double dt) {
    _y = _floorY;
    if (_modeDuration > 3.6) {
      // Return to walking or studying
      _mode = ShimejiMode.floorWalk;
      _modeDuration = 0.0;
      _currentFrame = 0;
    }
  }

  // ── WALL CLIMBING UP ─────────────────────────────────────────────────────
  void _handleWallClimbUp(double dt) {
    _x = (_wallSide == 1) ? _rightWallX : _leftWallX;
    const climbSpeed = 44.0; // px/sec
    _y -= climbSpeed * dt;

    // Reached top ceiling of the hero card!
    if (_y <= _ceilingY) {
      _y = _ceilingY;
      final r = math.Random().nextDouble();
      if (r < 0.72) {
        // Crawl along ceiling toward opposite side
        _facing = -_wallSide;
        _mode = ShimejiMode.ceilingCrawl;
      } else {
        // Slip and fall playfully with gravity!
        _mode = ShimejiMode.falling;
        _vy = 40.0;
        _vx = -_wallSide * 35.0;
      }
      _modeDuration = 0.0;
    } else if (_modeDuration > 2.0 && math.Random().nextDouble() < 0.008) {
      // Mid-wall slip & drop
      _mode = ShimejiMode.falling;
      _vy = 30.0;
      _vx = -_wallSide * 20.0;
      _modeDuration = 0.0;
    }
  }

  // ── CEILING CRAWL ────────────────────────────────────────────────────────
  void _handleCeilingCrawl(double dt) {
    _y = _ceilingY;
    const crawlSpeed = 42.0; // px/sec
    _x += _facing * crawlSpeed * dt;

    // Check reaching the corner of ceiling
    final reachedCorner = (_facing == 1 && _x >= _rightWallX) ||
        (_facing == -1 && _x <= _leftWallX);

    if (reachedCorner) {
      _wallSide = (_facing == 1) ? 1 : -1;
      _mode = ShimejiMode.wallClimbDown;
      _modeDuration = 0.0;
    } else if (_modeDuration > 2.6 && math.Random().nextDouble() < 0.015) {
      // Playful drop down from ceiling!
      _mode = ShimejiMode.falling;
      _vy = 35.0;
      _vx = _facing * 25.0;
      _modeDuration = 0.0;
    }
  }

  // ── WALL CLIMBING DOWN ───────────────────────────────────────────────────
  void _handleWallClimbDown(double dt) {
    _x = (_wallSide == 1) ? _rightWallX : _leftWallX;
    const climbSpeed = 48.0; // px/sec
    _y += climbSpeed * dt;

    if (_y >= _floorY) {
      _y = _floorY;
      _x = (_wallSide == 1) ? (_maxX - 2.0) : 2.0;
      _facing = -_wallSide;
      _mode = ShimejiMode.floorWalk;
      _modeDuration = 0.0;
    }
  }

  // ── AIRBORNE FALLING & GRAVITY ───────────────────────────────────────────
  void _handleFalling(double dt) {
    const gravity = 820.0; // px/sec²
    _vy += gravity * dt;
    _x += _vx * dt;
    _y += _vy * dt;

    // Bounce off left/right side boundaries
    if (_x <= _leftWallX) {
      _x = _leftWallX;
      _vx = -_vx * 0.45;
    } else if (_x >= _rightWallX) {
      _x = _rightWallX;
      _vx = -_vx * 0.45;
    }

    // Land on card floor
    if (_y >= _floorY) {
      _y = _floorY;
      _vy = 0.0;
      _vx = 0.0;
      _mode = ShimejiMode.landingBounce;
      _bounceTimer = 0.16; // 160ms squash & bounce
      _modeDuration = 0.0;
    }
  }

  // ── LANDING BOUNCE SQUISH ────────────────────────────────────────────────
  void _handleLandingBounce(double dt) {
    _bounceTimer -= dt;
    if (_bounceTimer <= 0.0) {
      final r = math.Random().nextDouble();
      if (r < 0.50) {
        _mode = ShimejiMode.floorStudy;
        _showSpeech("Safely landed! Let's get to work", badge: "STUDY");
      } else {
        _mode = ShimejiMode.floorWalk;
        _facing = math.Random().nextBool() ? 1 : -1;
      }
      _modeDuration = 0.0;
      _currentFrame = 0;
    }
  }

  // ── GESTURE INTERACTIONS ─────────────────────────────────────────────────
  void _onPanStart(DragStartDetails details) {
    HapticFeedback.mediumImpact();
    _isDragging = true;
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
      if (_vx > 25.0) {
        _facing = 1;
      } else if (_vx < -25.0) {
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
    _isDragging = false;
    _mode = ShimejiMode.falling;
    // Release with realistic momentum fling
    _vx = (_vx * 0.35).clamp(-280.0, 280.0);
    _vy = (_vy * 0.35).clamp(-200.0, 360.0);
    _modeDuration = 0.0;
  }

  void _onTap() {
    HapticFeedback.lightImpact();

    // Trigger instant Love Reaction with high-yield medical pearl
    final pearl = NoriSpeechBubble.getRandomPearl();
    _showSpeech(pearl, badge: 'NORI PEARL');

    _mode = ShimejiMode.loveReaction;
    _currentFrame = 0;
    _frameTimer = 0.0;
    _modeDuration = 0.0;

    widget.onTap?.call();
  }

  void _onDoubleTap() {
    HapticFeedback.mediumImpact();
    _showSpeech("Let's crush this session, Safi!", badge: 'FOCUS CHEER');
    // Double tap triggers a joyful leap into the air!
    _mode = ShimejiMode.falling;
    _vy = -310.0;
    _vx = _facing * 45.0;
    _modeDuration = 0.0;

    widget.onDoubleTap?.call();
  }

  // ── BUILD & VISUAL TRANSFORMS ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _boxWidth = constraints.maxWidth;
        _boxHeight = constraints.maxHeight;

        _x = _x.clamp(_leftWallX, _rightWallX);
        _y = _y.clamp(_ceilingY, _floorY);

        // 1. Determine Asset Path based on Active Motion Mode
        String spriteAsset;
        switch (_mode) {
          case ShimejiMode.floorStudy:
            spriteAsset = "assets/sprites/nori_v2/study/${_currentFrame % _studyFrames}.png";
            break;
          case ShimejiMode.floorSleep:
            spriteAsset = "assets/sprites/nori_v2/sleep/${_currentFrame % _sleepFrames}.png";
            break;
          case ShimejiMode.loveReaction:
            spriteAsset = "assets/sprites/nori_v2/love/${_currentFrame % _loveFrames}.png";
            break;
          case ShimejiMode.dragged:
            spriteAsset = "assets/sprites/nori_v2/love/0.png";
            break;
          case ShimejiMode.landingBounce:
            spriteAsset = "assets/sprites/nori_v2/walk/0.png";
            break;
          case ShimejiMode.floorWalk:
          case ShimejiMode.wallClimbUp:
          case ShimejiMode.wallClimbDown:
          case ShimejiMode.ceilingCrawl:
          case ShimejiMode.falling:
            spriteAsset = "assets/sprites/nori_v2/walk/${_currentFrame % _walkFrames}.png";
            break;
        }

        // 2. Geometric Rotation and Scaling based on Shimeji Traversal
        // Base walk frame is naturally oriented horizontally facing RIGHT.
        double rotation = 0.0;
        double scaleX = 1.0;
        double scaleY = 1.0;

        switch (_mode) {
          case ShimejiMode.floorWalk:
          case ShimejiMode.floorStudy:
          case ShimejiMode.floorSleep:
          case ShimejiMode.loveReaction:
          case ShimejiMode.dragged:
            rotation = 0.0;
            scaleX = (_facing == 1) ? 1.0 : -1.0;
            break;

          case ShimejiMode.landingBounce:
            rotation = 0.0;
            scaleX = (_facing == 1 ? 1.14 : -1.14);
            scaleY = 0.86; // Squish compression on impact
            break;

          case ShimejiMode.wallClimbUp:
            if (_wallSide == 1) {
              // Right Wall: Cat heads UP, paws touch right wall
              rotation = -math.pi / 2;
              scaleX = 1.0;
            } else {
              // Left Wall: Cat heads UP, paws touch left wall
              rotation = math.pi / 2;
              scaleX = -1.0;
            }
            break;

          case ShimejiMode.wallClimbDown:
            if (_wallSide == 1) {
              // Right Wall: Cat heads DOWN, paws touch right wall
              rotation = math.pi / 2;
              scaleX = 1.0;
            } else {
              // Left Wall: Cat heads DOWN, paws touch left wall
              rotation = -math.pi / 2;
              scaleX = -1.0;
            }
            break;

          case ShimejiMode.ceilingCrawl:
            // Upside down: paws touch top ceiling
            rotation = math.pi;
            scaleX = (_facing == -1) ? 1.0 : -1.0;
            break;

          case ShimejiMode.falling:
            // Natural fall with slight pitch
            rotation = (_vx * 0.002).clamp(-0.35, 0.35);
            scaleX = (_facing == 1) ? 1.0 : -1.0;
            break;
        }

        // Position speech bubble dynamically relative to Nori's position
        final bubbleLeft = math.max(6.0, math.min(_maxX - 130.0, _x - 45.0));
        final bubbleTop = math.max(0.0, _y - 52.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Floating Native Speech Bubble ────────────────────────────────
            if (_speechText != null)
              Positioned(
                left: bubbleLeft,
                top: bubbleTop,
                width: 175.0,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_speechText),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return Opacity(
                      opacity: val,
                      child: Transform.translate(
                        offset: Offset(0, (1.0 - val) * 6.0),
                        child: child,
                      ),
                    );
                  },
                  child: NoriSpeechBubble(
                    text: _speechText!,
                    badge: _speechBadge,
                    onTap: () {
                      _speechTimer?.cancel();
                      setState(() {
                        _speechText = null;
                        _speechBadge = null;
                      });
                    },
                  ),
                ),
              ),

            // ── Nori Mascot Sprite with Shimeji Geometry ─────────────────────
            Positioned(
              left: _x,
              top: _y,
              width: widget.size,
              height: widget.size,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: _onTap,
                onDoubleTap: _onDoubleTap,
                behavior: HitTestBehavior.opaque,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0)
                    ..rotateZ(rotation),
                  child: Image.asset(
                    spriteAsset,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.none, // Pixel-perfect rendering
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Backwards-compatible ShimejiEngine interface wrapping NoriFluidEngine
typedef ShimejiEngine = NoriFluidEngine;
