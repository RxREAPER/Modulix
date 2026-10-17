import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SIZE & MOTION PRESETS  (Duolingo design system adaptation)
// ─────────────────────────────────────────────────────────────────────────────

/// Standard size presets for Nori across different screens (Duolingo design system).
enum NoriSize {
  /// Mini indicator for AppBars, badges, and streak flame counters (40.0px).
  mini(40.0),

  /// Compact spotlight for Feature Tour steps, daily goals, and cards (72.0px).
  compact(72.0),

  /// Standard mascot for Study Desk Clock, coach sheets, and overlays (110.0px).
  standard(110.0),

  /// Hero mascot for Onboarding welcome, milestones, and level-ups (220.0px).
  hero(220.0);

  final double value;
  const NoriSize(this.value);
}

/// Screen-adaptive motion presets matching Duolingo's mascot state machines.
enum NoriMotion {
  /// Calm organic breathing sine wave for study desk & active pomodoro timer.
  focus,

  /// Bouncy welcoming greeting hop with happy tilt and open smile for onboarding.
  welcome,

  /// Explosive starry-eyed leap with double jelly bounce for task/session completion.
  celebrate,

  /// Pendulum hip-sway with apex lag and playful wink for party/streak milestones.
  party,

  /// Elastic chest pulse with blushing cheeks and hearts for achievements.
  love,

  /// Weightless levitation float with tranquil closed eyes for sleep/rest periods.
  zen,

  /// Micro-shiver tremor with wide alert eyes when streak is in danger or time is low.
  alert,
}

// ─────────────────────────────────────────────────────────────────────────────
// EMOTION STATES  (mirrors Duo's named state machine)
// ─────────────────────────────────────────────────────────────────────────────

enum NoriEmotion {
  idle,         // Gentle breathe bob, soft smile
  happy,        // Bounce, wide eyes, big U smile, blush
  excited,      // Rapid bounce, star pupils, open-O mouth, blush, sparkles
  celebrating,  // Spin+squash, closed eyes huge grin, blush, shockwave
  sad,          // Droop, heavy-lidded, downward arc, teardrop
  bored,        // Slow drift, half-closed eyes, flat/zigzag mouth
  sleepy,       // Slow sway, closed squint, tiny snore Z's
  studying,     // Still, squinted upward, flat mouth — book prop shown
  streakDanger, // Shake, alarmed wide eyes, open O, sweat drop
  love,         // Pulse, heart pupils, smile, hearts float
  bluntSassy,   // Crossed-arms body lean, one brow raised, smirk
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOB VISUAL CONFIGURATION  (fully interpolatable for smooth tweens)
// ─────────────────────────────────────────────────────────────────────────────

class NoriBlobConfig {
  /// Body horizontal scale multiplier (1.0 = normal, >1 wider, <1 taller)
  final double squishX;

  /// Body vertical scale multiplier
  final double squishY;

  /// Vertical bounce offset in [-1, 1] of body height. Positive = up.
  final double bounceOffset;

  /// Eye openness: 0.0 = fully closed, 1.0 = wide open
  final double eyeOpenness;

  /// Whether pupils are heart-shaped (love state)
  final bool heartPupils;

  /// Whether pupils are star-shaped (excited state)
  final bool starPupils;

  /// Mouth curve: +1.0 = big smile, 0.0 = flat, -1.0 = frown
  final double mouthCurve;

  /// Mouth openness (O shape): 0.0 = closed line, 1.0 = open O
  final double mouthOpen;

  /// Cheek blush alpha [0, 1]
  final double blushAlpha;

  /// Teardrop visible (sad state)
  final bool showTear;

  /// Whether body should jitter/shake (streakDanger)
  final bool shaking;

  /// Body lean angle in radians (bluntSassy = -0.1 rad lean)
  final double bodyLean;

  /// Prop to render over the body
  final NoriProp prop;

  /// Eye brow raise: 0.0 = none, 1.0 = fully raised (bluntSassy = 0.6)
  final double browRaise;

  const NoriBlobConfig({
    this.squishX = 1.0,
    this.squishY = 1.0,
    this.bounceOffset = 0.0,
    this.eyeOpenness = 1.0,
    this.heartPupils = false,
    this.starPupils = false,
    this.mouthCurve = 0.4,
    this.mouthOpen = 0.0,
    this.blushAlpha = 0.0,
    this.showTear = false,
    this.shaking = false,
    this.bodyLean = 0.0,
    this.prop = NoriProp.none,
    this.browRaise = 0.0,
  });

  NoriBlobConfig copyWith({
    double? squishX,
    double? squishY,
    double? bounceOffset,
    double? eyeOpenness,
    bool? heartPupils,
    bool? starPupils,
    double? mouthCurve,
    double? mouthOpen,
    double? blushAlpha,
    bool? showTear,
    bool? shaking,
    double? bodyLean,
    NoriProp? prop,
    double? browRaise,
  }) {
    return NoriBlobConfig(
      squishX: squishX ?? this.squishX,
      squishY: squishY ?? this.squishY,
      bounceOffset: bounceOffset ?? this.bounceOffset,
      eyeOpenness: eyeOpenness ?? this.eyeOpenness,
      heartPupils: heartPupils ?? this.heartPupils,
      starPupils: starPupils ?? this.starPupils,
      mouthCurve: mouthCurve ?? this.mouthCurve,
      mouthOpen: mouthOpen ?? this.mouthOpen,
      blushAlpha: blushAlpha ?? this.blushAlpha,
      showTear: showTear ?? this.showTear,
      shaking: shaking ?? this.shaking,
      bodyLean: bodyLean ?? this.bodyLean,
      prop: prop ?? this.prop,
      browRaise: browRaise ?? this.browRaise,
    );
  }

  /// Linear interpolate between two configs
  static NoriBlobConfig lerp(NoriBlobConfig a, NoriBlobConfig b, double t) {
    return NoriBlobConfig(
      squishX: _lerpD(a.squishX, b.squishX, t),
      squishY: _lerpD(a.squishY, b.squishY, t),
      bounceOffset: _lerpD(a.bounceOffset, b.bounceOffset, t),
      eyeOpenness: _lerpD(a.eyeOpenness, b.eyeOpenness, t),
      heartPupils: t < 0.5 ? a.heartPupils : b.heartPupils,
      starPupils: t < 0.5 ? a.starPupils : b.starPupils,
      mouthCurve: _lerpD(a.mouthCurve, b.mouthCurve, t),
      mouthOpen: _lerpD(a.mouthOpen, b.mouthOpen, t),
      blushAlpha: _lerpD(a.blushAlpha, b.blushAlpha, t),
      showTear: t < 0.5 ? a.showTear : b.showTear,
      shaking: t < 0.5 ? a.shaking : b.shaking,
      bodyLean: _lerpD(a.bodyLean, b.bodyLean, t),
      prop: t < 0.5 ? a.prop : b.prop,
      browRaise: _lerpD(a.browRaise, b.browRaise, t),
    );
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;

  /// Returns the canonical config snapshot for an emotion state
  static NoriBlobConfig forEmotion(NoriEmotion emotion) {
    switch (emotion) {
      case NoriEmotion.idle:
        return const NoriBlobConfig(
          squishX: 1.0,
          squishY: 1.0,
          eyeOpenness: 0.88,
          mouthCurve: 0.35,
          blushAlpha: 0.0,
          prop: NoriProp.stethoscope,
        );
      case NoriEmotion.happy:
        return const NoriBlobConfig(
          squishX: 1.06,
          squishY: 0.96,
          bounceOffset: -0.08,
          eyeOpenness: 1.0,
          mouthCurve: 0.85,
          blushAlpha: 0.7,
        );
      case NoriEmotion.excited:
        return const NoriBlobConfig(
          squishX: 1.10,
          squishY: 0.92,
          bounceOffset: -0.15,
          eyeOpenness: 1.0,
          starPupils: true,
          mouthCurve: 0.0,
          mouthOpen: 0.75,
          blushAlpha: 0.8,
        );
      case NoriEmotion.celebrating:
        return const NoriBlobConfig(
          squishX: 1.18,
          squishY: 0.85,
          bounceOffset: -0.22,
          eyeOpenness: 0.0,
          mouthCurve: 1.0,
          mouthOpen: 0.3,
          blushAlpha: 1.0,
        );
      case NoriEmotion.sad:
        return const NoriBlobConfig(
          squishX: 0.94,
          squishY: 1.06,
          bounceOffset: 0.08,
          eyeOpenness: 0.55,
          mouthCurve: -0.75,
          blushAlpha: 0.0,
          showTear: true,
        );
      case NoriEmotion.bored:
        return const NoriBlobConfig(
          squishX: 0.96,
          squishY: 1.03,
          bounceOffset: 0.04,
          eyeOpenness: 0.45,
          mouthCurve: -0.1,
          blushAlpha: 0.0,
        );
      case NoriEmotion.sleepy:
        return const NoriBlobConfig(
          squishX: 0.98,
          squishY: 1.0,
          bounceOffset: 0.05,
          eyeOpenness: 0.1,
          mouthCurve: 0.1,
          blushAlpha: 0.2,
        );
      case NoriEmotion.studying:
        return const NoriBlobConfig(
          squishX: 1.0,
          squishY: 1.0,
          eyeOpenness: 0.80,
          mouthCurve: 0.1,
          blushAlpha: 0.0,
          prop: NoriProp.book,
        );
      case NoriEmotion.streakDanger:
        return const NoriBlobConfig(
          squishX: 0.95,
          squishY: 1.05,
          eyeOpenness: 1.0,
          mouthCurve: 0.0,
          mouthOpen: 0.6,
          blushAlpha: 0.0,
          shaking: true,
        );
      case NoriEmotion.love:
        return const NoriBlobConfig(
          squishX: 1.04,
          squishY: 0.97,
          bounceOffset: -0.05,
          eyeOpenness: 0.9,
          heartPupils: true,
          mouthCurve: 0.7,
          blushAlpha: 0.9,
        );
      case NoriEmotion.bluntSassy:
        return const NoriBlobConfig(
          squishX: 1.0,
          squishY: 1.0,
          eyeOpenness: 0.7,
          mouthCurve: 0.2,
          blushAlpha: 0.0,
          bodyLean: -0.10,
          browRaise: 0.7,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROP TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum NoriProp {
  none,
  stethoscope,
  book,
  coffee,
  crown,
}

// ─────────────────────────────────────────────────────────────────────────────
// NORI BLOB PALETTE  (fully independent from app theme)
// ─────────────────────────────────────────────────────────────────────────────

class NoriPalette {
  NoriPalette._();

  // ── Body gradient stops (Option 2 pearlescent white/lavender)
  static const Color bodyHighlight = Color(0xFFFFFFFF);   // Specular white top
  static const Color bodyMilk = Color(0xFFFBF9FF);        // Soft milky white
  static const Color bodyMid = Color(0xFFEDE7FC);         // Gentle lavender mid
  static const Color bodyCore = Color(0xFFD9CEF8);        // Periwinkle lavender core
  static const Color bodyShadow = Color(0xFFC3B2EE);      // Shadow/base lavender-periwinkle
  static const Color bodyEdge = Color(0xFFB09DE4);        // Subtle deep edge

  // ── Subsurface blue-shift ambient rim (bottom edge glow)
  static const Color bodyBlueShift = Color(0xFF82AAFF);   // Cool blue-lavender

  // ── Dark mode outline
  static const Color darkOutline = Color(0xFFFFFFFF);

  // ── Eyes (Option 2 glossy espresso bean eyes)
  static const Color eyeWhite = Color(0xFFFFFFFF);
  static const Color pupil = Color(0xFF1D1530);            // Deep glossy espresso violet
  static const Color eyeShine = Color(0xFFFFFFFF);         // Primary specular dot
  static const Color eyeShineSoft = Color(0xA6FFFFFF);     // Secondary specular dot

  // ── Blush (soft coral pink)
  static const Color blush = Color(0xFFFF82A0);

  // ── Mouth
  static const Color mouth = Color(0xFF231838);
  static const Color tongue = Color(0xFFFF7D9E);

  // ── Tear
  static const Color tear = Color(0xFF9BCEFF);

  // ── Props
  static const Color stethoscopeBody = Color(0xFF6750C8);
  static const Color stethoscopeTube = Color(0xFF4A3AA0);
  static const Color bookCover = Color(0xFF6B4F9A);
  static const Color bookPage = Color(0xFFF5F0FF);
  static const Color coffeeBody = Color(0xFF7B5E3A);
  static const Color coffeeSteam = Color(0xFFE8DEFF);

  // ── Heart (love state)
  static const Color heartFill = Color(0xFFFF6B9D);

  // ── Star (excited state)
  static const Color starFill = Color(0xFFFFC947);
}

// ─────────────────────────────────────────────────────────────────────────────
// NORI BLOB CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────────────────────

/// Pure-vector CustomPainter that draws Nori the blob companion.
///
/// All coordinates are normalized to [0, 1] relative to [size] so Nori
/// scales perfectly at any DPI. Feed [config] and [breatheT] (0→1 sine wave)
/// each frame and repaint.
class NoriBlobPainter extends CustomPainter {
  final NoriBlobConfig config;

  /// Breathing animation phase [0, 1]. Drive with a sin-wave AnimationController.
  final double breatheT;

  /// Overall opacity (for fade-in/out)
  final double opacity;

  /// Whether to render dark-mode outline (mirrors darkmode_char_stroke_db_bool)
  final bool darkModeOutline;

  /// Shake delta in pixels (set non-zero from a shakeController when shaking)
  final double shakeDx;

  const NoriBlobPainter({
    required this.config,
    this.breatheT = 0.0,
    this.opacity = 1.0,
    this.darkModeOutline = false,
    this.shakeDx = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Breathing modulation (±2.5% scale)
    final breathe = math.sin(breatheT * math.pi * 2);
    final breatheScaleX = 1.0 - breathe * 0.025;
    final breatheScaleY = 1.0 + breathe * 0.030;

    // ── Duolingo Volume-Preserving squash and stretch (X * Y ~ constant)
    final effSy = config.squishY * breatheScaleY;
    final effSx = (config.squishX * breatheScaleX) / math.sqrt(effSy.clamp(0.4, 2.2));

    // ── Bounce offset in px
    final bouncePx = config.bounceOffset * h;

    // ── Shake
    final shakeOffsetX = config.shaking ? shakeDx : 0.0;

    canvas.save();
    canvas.translate(w / 2 + shakeOffsetX, h / 2 + bouncePx);
    canvas.rotate(config.bodyLean);
    canvas.scale(effSx * opacity + (1.0 - opacity) * effSx, effSy);

    // Center is now (0, 0)
    final rx = w * 0.42;  // Body half-width
    final ry = h * 0.38;  // Body half-height

    _drawBody(canvas, rx, ry, w, h, darkModeOutline);
    _drawBlush(canvas, rx, ry);
    _drawEyes(canvas, rx, ry, w, h);
    _drawMouth(canvas, ry);
    if (config.showTear) _drawTear(canvas, rx, ry);
    _drawProp(canvas, rx, ry, w, h);

    canvas.restore();
  }

  // ── BODY ──────────────────────────────────────────────────────────────────

  void _drawBody(Canvas canvas, double rx, double ry, double w, double h,
      bool darkOutline) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );

    // 1. Plump Pearlescent Mochi Dome Bezier Path
    final path = Path();
    final topY = -ry * 0.95;
    final botY = ry * 0.92;
    final waistY = ry * 0.02;
    final bW = rx * 0.95; // base half-width
    final tW = rx * 0.58; // crown half-width

    path.moveTo(0, botY);
    path.cubicTo(bW * 0.70, botY, bW * 1.08, botY - ry * 0.22, bW, waistY);
    path.cubicTo(bW * 0.95, waistY - ry * 0.52, tW * 1.05, topY + ry * 0.20, tW * 0.60, topY);
    path.cubicTo(tW * 0.30, topY - ry * 0.09, -tW * 0.30, topY - ry * 0.09, -tW * 0.60, topY);
    path.cubicTo(-tW * 1.05, topY + ry * 0.20, -bW * 0.95, waistY - ry * 0.52, -bW, waistY);
    path.cubicTo(-bW * 1.08, botY - ry * 0.22, -bW * 0.70, botY, 0, botY);
    path.close();

    // 2. Pearlescent Radial Gradient (top specular highlight -> milky lavender -> periwinkle contour)
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.35),
        radius: 1.15,
        colors: [
          NoriPalette.bodyHighlight,
          NoriPalette.bodyMilk,
          NoriPalette.bodyMid,
          NoriPalette.bodyCore,
          NoriPalette.bodyShadow,
        ],
        stops: [0.0, 0.30, 0.65, 0.88, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    // 3. Subsurface Ambient Rim Glow (cool blue-lavender on bottom contour)
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          NoriPalette.bodyBlueShift.withValues(alpha: 0.0),
          NoriPalette.bodyBlueShift.withValues(alpha: 0.45),
        ],
        stops: const [0.65, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, rimPaint);

    // 4. Dark mode outline
    if (darkOutline) {
      final outlinePaint = Paint()
        ..color = NoriPalette.darkOutline.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, outlinePaint);
    }

    // 5. Specular Gloss Highlight (organic pearl sheen on top-left crown)
    final specRect = Rect.fromCenter(
      center: Offset(-rx * 0.25, topY + ry * 0.35),
      width: rx * 0.55,
      height: ry * 0.26,
    );
    final specPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(specRect)
      ..style = PaintingStyle.fill;
    canvas.drawOval(specRect, specPaint);
  }

  // ── EYES ──────────────────────────────────────────────────────────────────

  void _drawEyes(Canvas canvas, double rx, double ry, double w, double h) {
    // Eye positions: 48% of rx apart, slightly above body center
    final eyeSpacing = rx * 0.46;
    final eyeY = -ry * 0.08;
    final eyeR = math.min(rx, ry) * 0.17; // Base eye radius

    for (final side in [-1.0, 1.0]) {
      final cx = side * eyeSpacing;
      _drawSingleEye(canvas, Offset(cx, eyeY), eyeR, side < 0);
    }
  }

  void _drawSingleEye(Canvas canvas, Offset center, double r, bool isLeft) {
    final openness = config.eyeOpenness.clamp(0.0, 1.0);

    if (openness < 0.22) {
      // Duolingo curved happy closed eyelid
      final arcPaint = Paint()
        ..color = NoriPalette.mouth
        ..strokeWidth = r * 0.32
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final eyeW = r * 1.1;
      final path = Path()
        ..moveTo(center.dx - eyeW, center.dy)
        ..quadraticBezierTo(center.dx, center.dy - r * 0.6, center.dx + eyeW, center.dy);
      canvas.drawPath(path, arcPaint);
      return;
    }

    // Option 2 Glossy Bean Eye
    final eyeRect = Rect.fromCenter(
      center: center,
      width: r * 1.6,
      height: r * 2.3 * openness.clamp(0.12, 1.0),
    );

    // Deep espresso violet fill
    final eyePaint = Paint()
      ..color = NoriPalette.pupil
      ..style = PaintingStyle.fill;
    canvas.drawOval(eyeRect, eyePaint);

    if (config.heartPupils) {
      _drawHeartPupil(canvas, center, r * 0.70 * openness);
    } else if (config.starPupils) {
      _drawStarPupil(canvas, center, r * 0.75 * openness);
    } else {
      // Option 2 Signature Specular Highlights:
      // 1. Primary Top-Left crisp white circle
      canvas.drawCircle(
        center + Offset(-r * 0.28, -r * 0.45 * openness),
        r * 0.35,
        Paint()..color = NoriPalette.eyeShine,
      );

      // 2. Secondary Bottom-Right soft translucent dot
      canvas.drawCircle(
        center + Offset(r * 0.26, r * 0.38 * openness),
        r * 0.18,
        Paint()..color = NoriPalette.eyeShineSoft,
      );

      // Brow raise for bluntSassy (only left eye gets raised brow)
      if (config.browRaise > 0 && isLeft) {
        _drawRaisedBrow(canvas, center, r);
      }
    }
  }

  void _drawHeartPupil(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = NoriPalette.heartFill
      ..style = PaintingStyle.fill;

    final path = Path();
    final scale = r * 1.1;
    // Normalized heart path centered at (0,0)
    path.moveTo(center.dx, center.dy + scale * 0.3);
    path.cubicTo(
      center.dx - scale, center.dy - scale * 0.4,
      center.dx - scale * 1.2, center.dy + scale * 0.4,
      center.dx, center.dy + scale * 1.1,
    );
    path.cubicTo(
      center.dx + scale * 1.2, center.dy + scale * 0.4,
      center.dx + scale, center.dy - scale * 0.4,
      center.dx, center.dy + scale * 0.3,
    );
    path.close();

    canvas.save();
    canvas.scale(0.55); // keep within eye bounds
    canvas.translate(center.dx * 0.45, center.dy * 0.45);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawStarPupil(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = NoriPalette.starFill
      ..style = PaintingStyle.fill;

    final path = Path();
    const points = 4;
    final outerR = r * 1.05;
    final innerR = r * 0.32;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final rad = i.isEven ? outerR : innerR;
      final x = center.dx + math.cos(angle) * rad;
      final y = center.dy + math.sin(angle) * rad;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRaisedBrow(Canvas canvas, Offset eyeCenter, double r) {
    final brow = Paint()
      ..color = NoriPalette.pupil.withValues(alpha: 0.90)
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final browY = eyeCenter.dy - r * 1.45 - config.browRaise * r * 0.25;
    final path = Path()
      ..moveTo(eyeCenter.dx - r * 0.7, browY + r * 0.18)
      ..quadraticBezierTo(
        eyeCenter.dx,
        browY - r * 0.12,
        eyeCenter.dx + r * 0.7,
        browY,
      );
    canvas.drawPath(path, brow);
  }

  // ── BLUSH ─────────────────────────────────────────────────────────────────

  void _drawBlush(Canvas canvas, double rx, double ry) {
    if (config.blushAlpha <= 0) return;

    final blushPaint = Paint()
      ..color = NoriPalette.blush.withValues(alpha: (config.blushAlpha * 0.65).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    for (final side in [-1.0, 1.0]) {
      final cx = side * rx * 0.64;
      final cy = ry * 0.22;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: rx * 0.32,
          height: ry * 0.16,
        ),
        blushPaint,
      );
    }
  }

  // ── MOUTH ─────────────────────────────────────────────────────────────────

  void _drawMouth(Canvas canvas, double ry) {
    final mouthY = ry * 0.24;
    final mouthW = ry * 0.36;

    if (config.mouthOpen > 0.15) {
      // Joyous open Duolingo mouth with cute pink tongue
      final openH = ry * 0.22 * config.mouthOpen;

      final mouthPath = Path();
      mouthPath.moveTo(-mouthW * 0.55, mouthY);
      mouthPath.quadraticBezierTo(0, mouthY + openH * 2.4, mouthW * 0.55, mouthY);
      mouthPath.close();

      canvas.drawPath(mouthPath, Paint()..color = NoriPalette.mouth);

      // Tongue clip
      canvas.save();
      canvas.clipPath(mouthPath);
      canvas.drawCircle(
        Offset(0, mouthY + openH * 1.6),
        mouthW * 0.38,
        Paint()..color = NoriPalette.tongue,
      );
      canvas.restore();
      return;
    }

    // Delicate gentle curved smile line (Option 2 baseline)
    final paint = Paint()
      ..color = NoriPalette.mouth
      ..strokeWidth = ry * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final curveH = ry * 0.16 * config.mouthCurve;

    final path = Path()
      ..moveTo(-mouthW * 0.5, mouthY)
      ..quadraticBezierTo(0, mouthY + curveH, mouthW * 0.5, mouthY);

    canvas.drawPath(path, paint);
  }

  // ── TEAR ──────────────────────────────────────────────────────────────────

  void _drawTear(Canvas canvas, double rx, double ry) {
    final tearPaint = Paint()
      ..color = NoriPalette.tear.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    // Under left eye
    final cx = -rx * 0.50;
    final startY = ry * 0.10;
    final tearH = ry * 0.28;

    final path = Path()
      ..moveTo(cx, startY)
      ..cubicTo(
        cx - ry * 0.07, startY + tearH * 0.4,
        cx - ry * 0.09, startY + tearH * 0.75,
        cx, startY + tearH,
      )
      ..cubicTo(
        cx + ry * 0.09, startY + tearH * 0.75,
        cx + ry * 0.07, startY + tearH * 0.4,
        cx, startY,
      )
      ..close();

    canvas.drawPath(path, tearPaint);
  }

  // ── PROPS ─────────────────────────────────────────────────────────────────

  void _drawProp(Canvas canvas, double rx, double ry, double w, double h) {
    switch (config.prop) {
      case NoriProp.stethoscope:
        _drawStethoscope(canvas, rx, ry);
        break;
      case NoriProp.book:
        _drawBook(canvas, rx, ry);
        break;
      case NoriProp.coffee:
        _drawCoffeeCup(canvas, rx, ry);
        break;
      case NoriProp.crown:
        _drawCrown(canvas, rx, ry);
        break;
      case NoriProp.none:
        break;
    }
  }

  void _drawStethoscope(Canvas canvas, double rx, double ry) {
    // Tiny stethoscope hanging from neck area, bottom-center of body
    final strokePaint = Paint()
      ..color = NoriPalette.stethoscopeTube
      ..strokeWidth = rx * 0.065
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Chest piece (circle at center-bottom)
    final chestX = rx * 0.25;
    final chestY = ry * 0.62;
    canvas.drawCircle(
      Offset(chestX, chestY),
      rx * 0.10,
      Paint()..color = NoriPalette.stethoscopeBody,
    );

    // Tube from chest piece curving up
    final path = Path()
      ..moveTo(chestX, chestY - rx * 0.10)
      ..cubicTo(
        chestX + rx * 0.05, chestY - ry * 0.30,
        -rx * 0.25, chestY - ry * 0.30,
        -rx * 0.30, chestY - ry * 0.05,
      );
    canvas.drawPath(path, strokePaint);
  }

  void _drawBook(Canvas canvas, double rx, double ry) {
    // Small open book at lower-right of body
    final bx = rx * 0.18;
    final by = ry * 0.52;
    final bw = rx * 0.52;
    final bh = ry * 0.30;

    // Cover
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bx, by), width: bw, height: bh),
        const Radius.circular(3),
      ),
      Paint()..color = NoriPalette.bookCover,
    );

    // Pages (right half lighter)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by - bh / 2, bw / 2 - 1, bh),
        const Radius.circular(2),
      ),
      Paint()..color = NoriPalette.bookPage,
    );

    // Spine line
    canvas.drawLine(
      Offset(bx, by - bh / 2),
      Offset(bx, by + bh / 2),
      Paint()
        ..color = NoriPalette.bookCover
        ..strokeWidth = 2.0,
    );
  }

  void _drawCoffeeCup(Canvas canvas, double rx, double ry) {
    final cx = rx * 0.30;
    final cy = ry * 0.55;
    final cupW = rx * 0.32;
    final cupH = ry * 0.28;

    // Cup body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: cupW, height: cupH),
        const Radius.circular(4),
      ),
      Paint()..color = NoriPalette.coffeeBody,
    );

    // Handle arc
    final handlePaint = Paint()
      ..color = NoriPalette.coffeeBody
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final handlePath = Path()
      ..moveTo(cx + cupW / 2, cy - cupH * 0.2)
      ..arcToPoint(
        Offset(cx + cupW / 2, cy + cupH * 0.2),
        radius: const Radius.circular(8),
        clockwise: false,
      );
    canvas.drawPath(handlePath, handlePaint);

    // Steam
    final steamPaint = Paint()
      ..color = NoriPalette.coffeeSteam.withValues(alpha: 0.65)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final steamPath = Path()
      ..moveTo(cx - 4, cy - cupH / 2 - 2)
      ..relativeQuadraticBezierTo(4, -6, 0, -12)
      ..moveTo(cx + 4, cy - cupH / 2 - 2)
      ..relativeQuadraticBezierTo(-4, -6, 0, -12);
    canvas.drawPath(steamPath, steamPaint);
  }

  void _drawCrown(Canvas canvas, double rx, double ry) {
    // Tiny golden crown tilted jauntily atop Nori's head
    final crownCenter = Offset(rx * 0.22, -ry * 0.94);
    final w = rx * 0.40;
    final h = ry * 0.26;

    final path = Path()
      ..moveTo(crownCenter.dx - w / 2, crownCenter.dy + h / 2)
      ..lineTo(crownCenter.dx - w / 2, crownCenter.dy - h / 2)
      ..lineTo(crownCenter.dx - w / 6, crownCenter.dy)
      ..lineTo(crownCenter.dx, crownCenter.dy - h * 0.75)
      ..lineTo(crownCenter.dx + w / 6, crownCenter.dy)
      ..lineTo(crownCenter.dx + w / 2, crownCenter.dy - h / 2)
      ..lineTo(crownCenter.dx + w / 2, crownCenter.dy + h / 2)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD54F));
    // Crown base rim
    canvas.drawLine(
      Offset(crownCenter.dx - w / 2, crownCenter.dy + h / 2),
      Offset(crownCenter.dx + w / 2, crownCenter.dy + h / 2),
      Paint()
        ..color = const Color(0xFFFFA000)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant NoriBlobPainter old) =>
      old.config != config ||
      old.breatheT != breatheT ||
      old.opacity != opacity ||
      old.darkModeOutline != darkModeOutline ||
      old.shakeDx != shakeDx;
}
