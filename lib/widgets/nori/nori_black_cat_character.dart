import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nori_character.dart' show NoriMood;

/// Canonical "Black Cat by Popof" & "Bad Cat" Vector Character Engine
/// Sleek midnight-charcoal body, white chest patch, white paw mittens,
/// luminous golden-amber cartoon eyes, pink inner ears, and white whiskers.
class NoriBlackCatCharacter extends StatefulWidget {
  final double size;
  final String propId;
  final NoriMood mood;
  final bool isWalking;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const NoriBlackCatCharacter({
    super.key,
    this.size = 110,
    this.propId = 'stethoscope',
    this.mood = NoriMood.awake,
    this.isWalking = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<NoriBlackCatCharacter> createState() => _NoriBlackCatCharacterState();
}

class _NoriBlackCatCharacterState extends State<NoriBlackCatCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _breatheCtrl;
  late final AnimationController _tailCtrl;
  late final AnimationController _squashCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _earFlickCtrl;
  Timer? _blinkTimer;
  Timer? _randomActionTimer;

  bool _isPetting = false;
  bool _isCheeky = false; // "Bad Cat" cheeky wink / smirk state

  @override
  void initState() {
    super.initState();

    // 1. Organic Breathing Loop (3.5s)
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    // 2. Playful Tail Pendulum Swish (2.4s)
    _tailCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. Elastic Squash & Stretch Press Reaction (420ms)
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // 4. Humanized Blinking (140ms)
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    // 5. Ear Flick / Bad-Cat Twitch (220ms)
    _earFlickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scheduleBlink();
    _scheduleRandomCheekyAction();
  }

  void _scheduleBlink() {
    final nextMs = 2400 + math.Random().nextInt(3600);
    _blinkTimer = Timer(Duration(milliseconds: nextMs), () {
      if (!mounted) return;
      _blinkCtrl.forward().then((_) {
        if (!mounted) return;
        _blinkCtrl.reverse().then((_) {
          // 35% chance of quick double-blink
          if (math.Random().nextDouble() < 0.35) {
            Future.delayed(const Duration(milliseconds: 70), () {
              if (mounted) {
                _blinkCtrl.forward().then((_) => _blinkCtrl.reverse());
              }
            });
          }
          _scheduleBlink();
        });
      });
    });
  }

  void _scheduleRandomCheekyAction() {
    // "Bad Cat" random playful ear twitch / cheeky wink every 7-14 seconds
    final nextMs = 7000 + math.Random().nextInt(7000);
    _randomActionTimer = Timer(Duration(milliseconds: nextMs), () {
      if (!mounted) return;
      setState(() => _isCheeky = true);
      _earFlickCtrl.forward().then((_) {
        if (mounted) _earFlickCtrl.reverse();
      });
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          setState(() => _isCheeky = false);
          _scheduleRandomCheekyAction();
        }
      });
    });
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPetting = true;
      _isCheeky = math.Random().nextDouble() < 0.40; // 40% chance of cheeky tap response
    });

    _squashCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isPetting = false);
    });

    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    setState(() => _isCheeky = true);
    _earFlickCtrl.forward(from: 0.0).then((_) {
      if (mounted) _earFlickCtrl.reverse();
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _isCheeky = false);
    });
    widget.onDoubleTap?.call();
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _tailCtrl.dispose();
    _squashCtrl.dispose();
    _blinkCtrl.dispose();
    _earFlickCtrl.dispose();
    _blinkTimer?.cancel();
    _randomActionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breatheCtrl,
          _tailCtrl,
          _squashCtrl,
          _blinkCtrl,
          _earFlickCtrl,
        ]),
        builder: (context, _) {
          return SizedBox(
            width: widget.size * 1.25,
            height: widget.size,
            child: CustomPaint(
              size: Size(widget.size * 1.25, widget.size),
              painter: _NoriBlackCatPainter(
                breathe: _breatheCtrl.value,
                tail: _tailCtrl.value,
                squash: _squashCtrl.value,
                blink: _blinkCtrl.value,
                earFlick: _earFlickCtrl.value,
                isPetting: _isPetting,
                isCheeky: _isCheeky,
                mood: widget.mood,
                propId: widget.propId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoriBlackCatPainter extends CustomPainter {
  final double breathe;
  final double tail;
  final double squash;
  final double blink;
  final double earFlick;
  final bool isPetting;
  final bool isCheeky;
  final NoriMood mood;
  final String propId;

  _NoriBlackCatPainter({
    required this.breathe,
    required this.tail,
    required this.squash,
    required this.blink,
    required this.earFlick,
    required this.isPetting,
    required this.isCheeky,
    required this.mood,
    required this.propId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette: Sleek Black Cat with Popof aesthetics
    const bodyColor = Color(0xFF1E2024);     // Deep midnight charcoal
    const whitePatch = Color(0xFFFFFFFF);    // Crisp white chest & paws
    const innerEarColor = Color(0xFFFFB2AC); // Soft pastel pink
    const eyeGold = Color(0xFFFFD166);       // Luminous golden amber
    const eyePupil = Color(0xFF121316);      // Inky pupil
    const nosePink = Color(0xFFFF8A80);      // Sweet coral nose

    final bodyPaint = Paint()..color = bodyColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = whitePatch..style = PaintingStyle.fill;
    final innerEarPaint = Paint()..color = innerEarColor..style = PaintingStyle.fill;
    final nosePaint = Paint()..color = nosePink..style = PaintingStyle.fill;

    // Elastic press reaction curve
    final elasticCurve = Curves.elasticOut.transform(squash);
    final squashY = 1.0 - (elasticCurve * 0.15) + (math.sin(breathe * math.pi) * 0.022);
    final stretchX = 1.0 + (elasticCurve * 0.11) - (math.sin(breathe * math.pi) * 0.015);

    final centerX = w * 0.46;
    final groundY = h * 0.88;

    // ── 1. SOFT FLOOR SHADOW ────────────────────────────────────────────────
    final shadowWidth = (w * 0.62) * stretchX;
    final shadowHeight = 11.0 * squashY;
    final shadowRect = Rect.fromCenter(
      center: Offset(centerX, groundY + 4),
      width: shadowWidth,
      height: shadowHeight,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: 0.16),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(shadowRect),
    );

    // ── 2. SWISHING TAIL (Behind Body) ──────────────────────────────────────
    canvas.save();
    final tailOrigin = Offset(centerX + (w * 0.22), groundY - 8);
    canvas.translate(tailOrigin.dx, tailOrigin.dy);
    final tailAngle = (math.sin(tail * math.pi * 2) * 0.16) + (squash * 0.22);
    canvas.rotate(tailAngle);

    final tailPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        w * 0.16, -h * 0.08,
        w * 0.24, -h * 0.32,
        w * 0.15, -h * 0.46,
      )
      ..cubicTo(
        w * 0.10, -h * 0.48,
        w * 0.06, -h * 0.42,
        w * 0.10, -h * 0.30,
      )
      ..cubicTo(
        w * 0.18, -h * 0.20,
        w * 0.08, -h * 0.04,
        -4, -2,
      )
      ..close();

    canvas.drawPath(tailPath, bodyPaint);
    // Subtle tail tip white accent (like classical tuxedo cats)
    canvas.restore();

    // ── 3. BODY WITH BREATHING & SQUASH ─────────────────────────────────────
    canvas.save();
    canvas.translate(centerX, groundY);
    canvas.scale(stretchX, squashY);
    canvas.translate(-centerX, -groundY);

    // Main Torso (Sleek pear/teardrop silhouette)
    final bodyWidth = w * 0.50;
    final bodyHeight = h * 0.48;
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, groundY - (bodyHeight * 0.46)),
      width: bodyWidth,
      height: bodyHeight,
    );
    canvas.drawOval(bodyRect, bodyPaint);

    // White Chest Bib / Patch (Popof / Tuxedo hallmark)
    final chestRect = Rect.fromCenter(
      center: Offset(centerX, groundY - (bodyHeight * 0.42)),
      width: bodyWidth * 0.52,
      height: bodyHeight * 0.62,
    );
    canvas.drawOval(chestRect, whitePaint);

    // ── 4. HEAD & PERKY EARS ────────────────────────────────────────────────
    final headWidth = w * 0.46;
    final headHeight = h * 0.38;
    final headCenter = Offset(centerX, groundY - bodyHeight - (headHeight * 0.22));

    // Left Ear
    final leftEarFlickAngle = earFlick * 0.20;
    canvas.save();
    canvas.translate(headCenter.dx - (headWidth * 0.26), headCenter.dy - (headHeight * 0.26));
    canvas.rotate(-leftEarFlickAngle);
    final leftEarPath = Path()
      ..moveTo(-headWidth * 0.12, headHeight * 0.06)
      ..lineTo(-headWidth * 0.16, -headHeight * 0.44)
      ..lineTo(headWidth * 0.04, -headHeight * 0.12)
      ..close();
    canvas.drawPath(leftEarPath, bodyPaint);

    // Left Inner Ear (Pink)
    final leftInnerEar = Path()
      ..moveTo(-headWidth * 0.10, headHeight * 0.02)
      ..lineTo(-headWidth * 0.14, -headHeight * 0.36)
      ..lineTo(headWidth * 0.01, -headHeight * 0.12)
      ..close();
    canvas.drawPath(leftInnerEar, innerEarPaint);
    canvas.restore();

    // Right Ear
    canvas.save();
    canvas.translate(headCenter.dx + (headWidth * 0.26), headCenter.dy - (headHeight * 0.26));
    canvas.rotate(leftEarFlickAngle * 0.5);
    final rightEarPath = Path()
      ..moveTo(headWidth * 0.12, headHeight * 0.06)
      ..lineTo(headWidth * 0.16, -headHeight * 0.44)
      ..lineTo(-headWidth * 0.04, -headHeight * 0.12)
      ..close();
    canvas.drawPath(rightEarPath, bodyPaint);

    // Right Inner Ear (Pink)
    final rightInnerEar = Path()
      ..moveTo(headWidth * 0.10, headHeight * 0.02)
      ..lineTo(headWidth * 0.14, -headHeight * 0.36)
      ..lineTo(-headWidth * 0.01, -headHeight * 0.12)
      ..close();
    canvas.drawPath(rightInnerEar, innerEarPaint);
    canvas.restore();

    // Head Oval
    final headRect = Rect.fromCenter(
      center: headCenter,
      width: headWidth,
      height: headHeight,
    );
    canvas.drawOval(headRect, bodyPaint);

    // ── 5. LUMINOUS CARTOON EYES ────────────────────────────────────────────
    final eyeSpacing = headWidth * 0.24;
    final eyeY = headCenter.dy - (headHeight * 0.04);
    final eyeRadius = headWidth * 0.125;

    final isSleepy = (mood == NoriMood.sleepy) && !isPetting;

    // Draw Left Eye
    _drawEye(
      canvas: canvas,
      center: Offset(headCenter.dx - eyeSpacing, eyeY),
      radius: eyeRadius,
      isClosed: isSleepy || (blink > 0.4),
      isWinking: false,
      eyeGold: eyeGold,
      eyePupil: eyePupil,
    );

    // Draw Right Eye (handles cheeky wink for "Bad Cat" state)
    _drawEye(
      canvas: canvas,
      center: Offset(headCenter.dx + eyeSpacing, eyeY),
      radius: eyeRadius,
      isClosed: isSleepy || (blink > 0.4) || (isCheeky && !isSleepy),
      isWinking: isCheeky && !isSleepy,
      eyeGold: eyeGold,
      eyePupil: eyePupil,
    );

    // ── 6. CUTE NOSE, MOUTH & WHITE WHISKERS ─────────────────────────────────
    final noseY = headCenter.dy + (headHeight * 0.12);

    // Pink button nose
    final nosePath = Path()
      ..moveTo(headCenter.dx - 4, noseY - 2)
      ..lineTo(headCenter.dx + 4, noseY - 2)
      ..lineTo(headCenter.dx, noseY + 3)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Little cat mouth curves
    final mouthPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(headCenter.dx, noseY + 3)
      ..lineTo(headCenter.dx, noseY + 7);
    canvas.drawPath(mouthPath, mouthPaint);

    final leftSmile = Path()
      ..moveTo(headCenter.dx, noseY + 7)
      ..quadraticBezierTo(headCenter.dx - 5, noseY + 11, headCenter.dx - 9, noseY + 7);
    canvas.drawPath(leftSmile, mouthPaint);

    final rightSmile = Path()
      ..moveTo(headCenter.dx, noseY + 7)
      ..quadraticBezierTo(headCenter.dx + 5, noseY + 11, headCenter.dx + 9, noseY + 7);
    canvas.drawPath(rightSmile, mouthPaint);

    // Crisp White Whiskers (Pop beautifully against black fur)
    final whiskerPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Left Whiskers
    final whiskerLeftX = headCenter.dx - (headWidth * 0.22);
    canvas.drawLine(Offset(whiskerLeftX, noseY), Offset(whiskerLeftX - 16, noseY - 4), whiskerPaint);
    canvas.drawLine(Offset(whiskerLeftX, noseY + 5), Offset(whiskerLeftX - 16, noseY + 6), whiskerPaint);

    // Right Whiskers
    final whiskerRightX = headCenter.dx + (headWidth * 0.22);
    canvas.drawLine(Offset(whiskerRightX, noseY), Offset(whiskerRightX + 16, noseY - 4), whiskerPaint);
    canvas.drawLine(Offset(whiskerRightX, noseY + 5), Offset(whiskerRightX + 16, noseY + 6), whiskerPaint);

    // ── 7. WHITE PAW MITTENS (Front Paws) ───────────────────────────────────
    final pawRadiusX = bodyWidth * 0.13;
    final pawRadiusY = bodyHeight * 0.15;
    final pawY = groundY - (pawRadiusY * 0.7);

    // Left White Paw
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - (bodyWidth * 0.20), pawY),
        width: pawRadiusX * 2,
        height: pawRadiusY * 2,
      ),
      whitePaint,
    );

    // Right White Paw
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + (bodyWidth * 0.20), pawY),
        width: pawRadiusX * 2,
        height: pawRadiusY * 2,
      ),
      whitePaint,
    );

    // Toe dividers on white paws
    final toePaint = Paint()
      ..color = const Color(0xFF1E2024).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(centerX - (bodyWidth * 0.20) - 2, pawY - 2), Offset(centerX - (bodyWidth * 0.20) - 2, pawY + 4), toePaint);
    canvas.drawLine(Offset(centerX - (bodyWidth * 0.20) + 2, pawY - 2), Offset(centerX - (bodyWidth * 0.20) + 2, pawY + 4), toePaint);

    canvas.drawLine(Offset(centerX + (bodyWidth * 0.20) - 2, pawY - 2), Offset(centerX + (bodyWidth * 0.20) - 2, pawY + 4), toePaint);
    canvas.drawLine(Offset(centerX + (bodyWidth * 0.20) + 2, pawY - 2), Offset(centerX + (bodyWidth * 0.20) + 2, pawY + 4), toePaint);

    // ── 8. WARDROBE MEDICAL PROPS ───────────────────────────────────────────
    _drawProp(canvas, headCenter, headWidth, headHeight, groundY, centerX);

    canvas.restore();
  }

  void _drawEye({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required bool isClosed,
    required bool isWinking,
    required Color eyeGold,
    required Color eyePupil,
  }) {
    if (isClosed) {
      // Gentle happy sleepy / winking curve
      final sleepPaint = Paint()
        ..color = const Color(0xFFFFD166) // Soft golden glowing lash
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(center.dx - radius, center.dy)
        ..quadraticBezierTo(center.dx, center.dy + (radius * 0.7), center.dx + radius, center.dy);
      canvas.drawPath(path, sleepPaint);
    } else {
      // Big, luminous golden cartoon eye with catchlight
      final eyePaint = Paint()..color = eyeGold..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 1.8, height: radius * 2.1),
        eyePaint,
      );

      // Glossy dark pupil
      final pupilPaint = Paint()..color = eyePupil..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx + 0.5, center.dy), width: radius * 0.9, height: radius * 1.5),
        pupilPaint,
      );

      // Sparkle Catchlight (Duolingo / Anime glint)
      final glintPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx - (radius * 0.35), center.dy - (radius * 0.40)), radius * 0.38, glintPaint);
      canvas.drawCircle(Offset(center.dx + (radius * 0.25), center.dy + (radius * 0.25)), radius * 0.16, glintPaint);
    }
  }

  void _drawProp(Canvas canvas, Offset headCenter, double headWidth, double headHeight, double groundY, double centerX) {
    if (propId == 'stethoscope') {
      final stethPaint = Paint()
        ..color = const Color(0xFF00E5FF) // Electric Cyan - pops intensely on black fur!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final stethY = headCenter.dy + (headHeight * 0.36);
      final tubePath = Path()
        ..moveTo(headCenter.dx - (headWidth * 0.32), stethY)
        ..cubicTo(
          headCenter.dx - (headWidth * 0.22), stethY + 20,
          headCenter.dx + (headWidth * 0.22), stethY + 20,
          headCenter.dx + (headWidth * 0.32), stethY,
        );
      canvas.drawPath(tubePath, stethPaint);

      // Metallic chestpiece bell
      final bellCenter = Offset(headCenter.dx, stethY + 18);
      canvas.drawCircle(bellCenter, 5.0, Paint()..color = const Color(0xFFE2E8F0)..style = PaintingStyle.fill);
      canvas.drawCircle(bellCenter, 5.0, Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = 1.3);
      canvas.drawCircle(bellCenter, 2.0, Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.fill);
    } else if (propId == 'glasses') {
      final rimPaint = Paint()
        ..color = const Color(0xFFFF6B6B) // Bright coral rims
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;

      final eyeY = headCenter.dy - (headHeight * 0.04);
      final spacing = headWidth * 0.24;
      final glassRadius = headWidth * 0.17;

      canvas.drawCircle(Offset(headCenter.dx - spacing, eyeY), glassRadius, rimPaint);
      canvas.drawCircle(Offset(headCenter.dx + spacing, eyeY), glassRadius, rimPaint);
      canvas.drawLine(
        Offset(headCenter.dx - spacing + glassRadius, eyeY),
        Offset(headCenter.dx + spacing - glassRadius, eyeY),
        rimPaint,
      );
    } else if (propId == 'crown') {
      final crownPaint = Paint()..color = const Color(0xFFFFD166)..style = PaintingStyle.fill;
      final crownBorder = Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 1.2;

      final crownY = headCenter.dy - (headHeight * 0.50);
      final crownPath = Path()
        ..moveTo(headCenter.dx - 14, crownY)
        ..lineTo(headCenter.dx - 18, crownY - 12)
        ..lineTo(headCenter.dx - 7, crownY - 6)
        ..lineTo(headCenter.dx, crownY - 15)
        ..lineTo(headCenter.dx + 7, crownY - 6)
        ..lineTo(headCenter.dx + 18, crownY - 12)
        ..lineTo(headCenter.dx + 14, crownY)
        ..close();
      canvas.drawPath(crownPath, crownPaint);
      canvas.drawPath(crownPath, crownBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _NoriBlackCatPainter oldDelegate) {
    return oldDelegate.breathe != breathe ||
        oldDelegate.tail != tail ||
        oldDelegate.squash != squash ||
        oldDelegate.blink != blink ||
        oldDelegate.earFlick != earFlick ||
        oldDelegate.isPetting != isPetting ||
        oldDelegate.isCheeky != isCheeky ||
        oldDelegate.mood != mood ||
        oldDelegate.propId != propId;
  }
}
