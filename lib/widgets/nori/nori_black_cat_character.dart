import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nori_character.dart' show NoriMood;

/// Hand-Drawn "Dieter" Shimeji Chibi Tuxedo Cat
///
/// Features bold ink outlines, organic bezier anatomy, tuxedo coat
/// (charcoal body, white muzzle blaze, white chest ruff, white socks),
/// expressive chartreuse cartoon eyes, and smooth frame-accurate animations:
/// - Standing / walking 4-paw stride cycle
/// - Sitting / loafing posture
/// - Look-around eye glance
/// - Cute paw-wave & happy '^ ^' eyes on tap
class NoriBlackCatCharacter extends StatefulWidget {
  final double size;
  final String propId;
  final NoriMood mood;
  final bool isWalking;
  final int direction; // 1 = facing right, -1 = facing left
  final double sitProgress; // 0.0 = standing, 1.0 = sitting
  final double lookDirection; // -1.0 (left) to 1.0 (right)
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const NoriBlackCatCharacter({
    super.key,
    this.size = 85,
    this.propId = 'none',
    this.mood = NoriMood.awake,
    this.isWalking = false,
    this.direction = 1,
    this.sitProgress = 0.0,
    this.lookDirection = 0.0,
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
  late final AnimationController _walkCtrl;
  late final AnimationController _squashCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _earFlickCtrl;
  late final AnimationController _pawWaveCtrl;

  Timer? _blinkTimer;
  Timer? _randomActionTimer;

  bool _isHappy = false;

  @override
  void initState() {
    super.initState();

    // 1. Organic Breathing loop (3.2s)
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // 2. Natural Tail Swish (2.4s)
    _tailCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. Four-legged Walk Cycle (520ms full stride loop)
    _walkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    if (widget.isWalking) {
      _walkCtrl.repeat();
    }

    // 4. Elastic Squash & Stretch Bounce on tap (420ms)
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // 5. Natural Blink (130ms)
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );

    // 6. Ear Flick (180ms)
    _earFlickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // 7. Paw wave on tap (550ms)
    _pawWaveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _scheduleBlink();
    _scheduleRandomEarFlick();
  }

  @override
  void didUpdateWidget(covariant NoriBlackCatCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWalking != oldWidget.isWalking) {
      if (widget.isWalking) {
        if (!_walkCtrl.isAnimating) _walkCtrl.repeat();
      } else {
        _walkCtrl.animateTo(0.0, duration: const Duration(milliseconds: 180));
      }
    }
  }

  void _scheduleBlink() {
    final nextMs = 2200 + math.Random().nextInt(3400);
    _blinkTimer = Timer(Duration(milliseconds: nextMs), () {
      if (!mounted) return;
      _blinkCtrl.forward().then((_) {
        if (!mounted) return;
        _blinkCtrl.reverse().then((_) {
          // 30% chance of double-blink
          if (math.Random().nextDouble() < 0.30) {
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

  void _scheduleRandomEarFlick() {
    final nextMs = 5000 + math.Random().nextInt(6000);
    _randomActionTimer = Timer(Duration(milliseconds: nextMs), () {
      if (!mounted) return;
      _earFlickCtrl.forward().then((_) {
        if (mounted) _earFlickCtrl.reverse();
      });
      _scheduleRandomEarFlick();
    });
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _isHappy = true);

    _squashCtrl.forward(from: 0.0);
    _pawWaveCtrl.forward(from: 0.0);
    _earFlickCtrl.forward(from: 0.0).then((_) {
      if (mounted) _earFlickCtrl.reverse();
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _isHappy = false);
    });

    widget.onTap?.call();
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _tailCtrl.dispose();
    _walkCtrl.dispose();
    _squashCtrl.dispose();
    _blinkCtrl.dispose();
    _earFlickCtrl.dispose();
    _pawWaveCtrl.dispose();
    _blinkTimer?.cancel();
    _randomActionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: widget.onDoubleTap ?? _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breatheCtrl,
          _tailCtrl,
          _walkCtrl,
          _squashCtrl,
          _blinkCtrl,
          _earFlickCtrl,
          _pawWaveCtrl,
        ]),
        builder: (context, _) {
          final width = widget.size * 1.25;
          final height = widget.size;

          return SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              size: Size(width, height),
              painter: _DieterShimejiCatPainter(
                breathe: _breatheCtrl.value,
                tail: _tailCtrl.value,
                walkCycle: _walkCtrl.value,
                squash: _squashCtrl.value,
                blink: _blinkCtrl.value,
                earFlick: _earFlickCtrl.value,
                pawWave: _pawWaveCtrl.value,
                isHappy: _isHappy || widget.mood == NoriMood.happy,
                isWalking: widget.isWalking,
                direction: widget.direction,
                sitProgress: widget.sitProgress,
                lookDirection: widget.lookDirection,
                mood: widget.mood,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DieterShimejiCatPainter extends CustomPainter {
  final double breathe;
  final double tail;
  final double walkCycle;
  final double squash;
  final double blink;
  final double earFlick;
  final double pawWave;
  final bool isHappy;
  final bool isWalking;
  final int direction;
  final double sitProgress;
  final double lookDirection;
  final NoriMood mood;

  _DieterShimejiCatPainter({
    required this.breathe,
    required this.tail,
    required this.walkCycle,
    required this.squash,
    required this.blink,
    required this.earFlick,
    required this.pawWave,
    required this.isHappy,
    required this.isWalking,
    required this.direction,
    required this.sitProgress,
    required this.lookDirection,
    required this.mood,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette: Hand-Drawn Ink & Tuxedo Colors
    const inkColor = Color(0xFF16181F); // Bold, rich comic ink outline
    const furBlack = Color(0xFF22252C); // Velvety deep charcoal fur
    const furBlackShade = Color(0xFF181A20); // Shadow for far-side limbs
    const furWhite = Color(0xFFFFFFFF); // Clean white markings
    const innerEarPink = Color(0xFFFF9EA6); // Soft warm pink inner ear
    const nosePink = Color(0xFFFF8595); // Cute coral-pink button nose
    const eyeIrisGreen = Color(0xFFD2EE36); // Luminous chartreuse green/amber
    const eyePupilDark = Color(0xFF13151B); // Inky pupil

    final inkPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final furPaint = Paint()..color = furBlack..style = PaintingStyle.fill;
    final farFurPaint = Paint()..color = furBlackShade..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = furWhite..style = PaintingStyle.fill;
    final innerEarPaint = Paint()..color = innerEarPink..style = PaintingStyle.fill;
    final nosePaint = Paint()..color = nosePink..style = PaintingStyle.fill;

    // Center & Ground references
    final centerX = w * 0.48;
    final groundY = h * 0.90;

    // Squash & Stretch physics
    final elasticCurve = Curves.elasticOut.transform(squash);
    final squashY = 1.0 - (elasticCurve * 0.16) + (math.sin(breathe * math.pi) * 0.02);
    final stretchX = 1.0 + (elasticCurve * 0.12) - (math.sin(breathe * math.pi) * 0.015);

    // Walking vertical bob (2 bobs per full stride cycle)
    final walkBob = isWalking ? math.sin(walkCycle * math.pi * 2).abs() * 2.8 : 0.0;

    // ── 0. HORIZONTAL MIRRORING (Direction) ───────────────────────────────────
    canvas.save();
    if (direction < 0) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    // ── 1. SOFT FLOOR CONTACT SHADOW ─────────────────────────────────────────
    final shadowWidth = (w * 0.60) * stretchX;
    final shadowHeight = 9.0 * squashY;
    final shadowRect = Rect.fromCenter(
      center: Offset(centerX, groundY + 2),
      width: shadowWidth,
      height: shadowHeight,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(shadowRect),
    );

    // ── 2. TAIL (Behind Body) ────────────────────────────────────────────────
    _drawCurvedTail(
      canvas: canvas,
      inkPaint: inkPaint,
      furPaint: furPaint,
      origin: Offset(centerX - (w * 0.20), groundY - (h * 0.28) - walkBob),
      tailProgress: tail,
      isWalking: isWalking,
      isHappy: isHappy,
      sitProgress: sitProgress,
      w: w,
      h: h,
    );

    // Apply squash and breathing scaling around ground anchor
    canvas.save();
    canvas.translate(centerX, groundY);
    canvas.scale(stretchX, squashY);
    canvas.translate(-centerX, -groundY);

    // ── 3. FAR LEGS (Drawn behind body in darker fur shade) ───────────────────
    _drawFarLegs(
      canvas: canvas,
      inkPaint: inkPaint,
      furPaint: farFurPaint,
      whitePaint: whitePaint,
      centerX: centerX,
      groundY: groundY,
      walkCycle: walkCycle,
      isWalking: isWalking,
      sitProgress: sitProgress,
      walkBob: walkBob,
      w: w,
      h: h,
    );

    // ── 4. MAIN TORSO & WHITE BELLY / BIB ─────────────────────────────────────
    _drawTorso(
      canvas: canvas,
      inkPaint: inkPaint,
      furPaint: furPaint,
      whitePaint: whitePaint,
      centerX: centerX,
      groundY: groundY,
      sitProgress: sitProgress,
      walkBob: walkBob,
      w: w,
      h: h,
    );

    // ── 5. NEAR LEGS (Foreground with White Socks) ───────────────────────────
    _drawNearLegs(
      canvas: canvas,
      inkPaint: inkPaint,
      furPaint: furPaint,
      whitePaint: whitePaint,
      centerX: centerX,
      groundY: groundY,
      walkCycle: walkCycle,
      isWalking: isWalking,
      pawWave: pawWave,
      sitProgress: sitProgress,
      walkBob: walkBob,
      w: w,
      h: h,
    );

    // ── 6. HEAD, CHEEKS, EARS & FACE ─────────────────────────────────────────
    _drawHead(
      canvas: canvas,
      inkPaint: inkPaint,
      furPaint: furPaint,
      whitePaint: whitePaint,
      innerEarPaint: innerEarPaint,
      nosePaint: nosePaint,
      centerX: centerX,
      groundY: groundY,
      walkBob: walkBob,
      sitProgress: sitProgress,
      blink: blink,
      earFlick: earFlick,
      isHappy: isHappy,
      lookDirection: lookDirection,
      eyeIrisGreen: eyeIrisGreen,
      eyePupilDark: eyePupilDark,
      w: w,
      h: h,
    );

    canvas.restore(); // restore squash/stretch
    canvas.restore(); // restore direction mirror
  }

  // ─── TAIL DRAWING ─────────────────────────────────────────────────────────
  void _drawCurvedTail({
    required Canvas canvas,
    required Paint inkPaint,
    required Paint furPaint,
    required Offset origin,
    required double tailProgress,
    required bool isWalking,
    required bool isHappy,
    required double sitProgress,
    required double w,
    required double h,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // Tail swish physics: faster when happy or walking
    final swishSpeed = isHappy ? 3.5 : (isWalking ? 2.2 : 1.0);
    final swishAngle = math.sin(tailProgress * math.pi * 2 * swishSpeed) * (isHappy ? 0.28 : 0.16);

    // When sitting, tail curls lower along the floor
    final sitAngleOffset = sitProgress * 0.35;
    canvas.rotate(swishAngle + sitAngleOffset);

    final tailPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        -w * 0.12, -h * 0.10,
        -w * 0.22, -h * 0.35,
        -w * 0.12, -h * 0.52,
      )
      ..cubicTo(
        -w * 0.05, -h * 0.58,
        0, -h * 0.52,
        -w * 0.06, -h * 0.40,
      )
      ..cubicTo(
        -w * 0.12, -h * 0.25,
        -w * 0.06, -h * 0.08,
        4, 2,
      )
      ..close();

    canvas.drawPath(tailPath, furPaint);
    canvas.drawPath(tailPath, inkPaint);

    canvas.restore();
  }

  // ─── FAR LEGS (Drawn behind torso) ────────────────────────────────────────
  void _drawFarLegs({
    required Canvas canvas,
    required Paint inkPaint,
    required Paint furPaint,
    required Paint whitePaint,
    required double centerX,
    required double groundY,
    required double walkCycle,
    required bool isWalking,
    required double sitProgress,
    required double walkBob,
    required double w,
    required double h,
  }) {
    if (sitProgress > 0.85) return; // Hidden behind body when fully sitting

    // Far Back Leg (steps in opposite phase of near back leg)
    final farBackSwing = isWalking ? math.sin((walkCycle + 0.5) * math.pi * 2) * 6.0 : 0.0;
    final farBackX = centerX - (w * 0.18) + farBackSwing;
    final farBackLegPath = Path()
      ..moveTo(centerX - (w * 0.14), groundY - (h * 0.30) - walkBob)
      ..lineTo(farBackX - 4, groundY - 4)
      ..lineTo(farBackX + 6, groundY - 4)
      ..lineTo(centerX - (w * 0.06), groundY - (h * 0.22) - walkBob)
      ..close();
    canvas.drawPath(farBackLegPath, furPaint);
    canvas.drawPath(farBackLegPath, inkPaint);

    // Far Back White Sock
    final farBackSock = Path()
      ..moveTo(farBackX - 4, groundY - 7)
      ..lineTo(farBackX - 4, groundY - 2)
      ..quadraticBezierTo(farBackX + 1, groundY, farBackX + 6, groundY - 2)
      ..lineTo(farBackX + 6, groundY - 7)
      ..close();
    canvas.drawPath(farBackSock, whitePaint);
    canvas.drawPath(farBackSock, inkPaint);

    // Far Front Leg (steps in counter-phase of near front leg)
    final farFrontSwing = isWalking ? -math.sin(walkCycle * math.pi * 2) * 7.0 : 0.0;
    final farFrontX = centerX + (w * 0.15) + farFrontSwing;
    final farFrontLegPath = Path()
      ..moveTo(centerX + (w * 0.10), groundY - (h * 0.32) - walkBob)
      ..lineTo(farFrontX - 4, groundY - 4)
      ..lineTo(farFrontX + 5, groundY - 4)
      ..lineTo(centerX + (w * 0.18), groundY - (h * 0.28) - walkBob)
      ..close();
    canvas.drawPath(farFrontLegPath, furPaint);
    canvas.drawPath(farFrontLegPath, inkPaint);

    // Far Front White Sock
    final farFrontSock = Path()
      ..moveTo(farFrontX - 4, groundY - 8)
      ..lineTo(farFrontX - 4, groundY - 2)
      ..quadraticBezierTo(farFrontX + 0.5, groundY, farFrontX + 5, groundY - 2)
      ..lineTo(farFrontX + 5, groundY - 8)
      ..close();
    canvas.drawPath(farFrontSock, whitePaint);
    canvas.drawPath(farFrontSock, inkPaint);
  }

  // ─── MAIN TORSO & TUXEDO CHEST BIB ────────────────────────────────────────
  void _drawTorso({
    required Canvas canvas,
    required Paint inkPaint,
    required Paint furPaint,
    required Paint whitePaint,
    required double centerX,
    required double groundY,
    required double sitProgress,
    required double walkBob,
    required double w,
    required double h,
  }) {
    final torsoPath = Path();

    // Interpolate torso shape between standing and sitting posture
    if (sitProgress < 0.5) {
      // Standing cat torso (Dieter style arch with rounded haunches)
      final backY = groundY - (h * 0.38) - walkBob;
      torsoPath.moveTo(centerX - (w * 0.22), backY + 4);
      // Gentle curve over the spine
      torsoPath.quadraticBezierTo(centerX - (w * 0.04), backY - 2, centerX + (w * 0.16), backY + 2);
      // Down front chest
      torsoPath.quadraticBezierTo(centerX + (w * 0.26), groundY - (h * 0.25) - walkBob, centerX + (w * 0.18), groundY - (h * 0.15) - walkBob);
      // Underbelly
      torsoPath.quadraticBezierTo(centerX, groundY - (h * 0.12) - walkBob, centerX - (w * 0.16), groundY - (h * 0.18) - walkBob);
      // Round rump
      torsoPath.quadraticBezierTo(centerX - (w * 0.26), groundY - (h * 0.26) - walkBob, centerX - (w * 0.22), backY + 4);
      torsoPath.close();
    } else {
      // Sitting cat torso (Dieter upright loaf posture)
      final sitY = groundY - (h * 0.42);
      torsoPath.moveTo(centerX - (w * 0.18), sitY);
      torsoPath.quadraticBezierTo(centerX, sitY - 4, centerX + (w * 0.16), sitY + 2);
      torsoPath.quadraticBezierTo(centerX + (w * 0.24), groundY - (h * 0.20), centerX + (w * 0.14), groundY - 4);
      torsoPath.lineTo(centerX - (w * 0.18), groundY - 4);
      torsoPath.quadraticBezierTo(centerX - (w * 0.28), groundY - (h * 0.18), centerX - (w * 0.18), sitY);
      torsoPath.close();
    }

    canvas.drawPath(torsoPath, furPaint);
    canvas.drawPath(torsoPath, inkPaint);

    // Fluffy White Chest Bib / Tuxedo Ruff
    final bibPath = Path();
    final bibTopY = groundY - (h * 0.40) - walkBob;
    bibPath.moveTo(centerX + (w * 0.08), bibTopY);
    bibPath.quadraticBezierTo(centerX + (w * 0.24), bibTopY + (h * 0.08), centerX + (w * 0.20), groundY - (h * 0.16) - walkBob);
    bibPath.quadraticBezierTo(centerX + (w * 0.12), groundY - (h * 0.12) - walkBob, centerX + (w * 0.04), groundY - (h * 0.16) - walkBob);
    bibPath.quadraticBezierTo(centerX + (w * 0.06), bibTopY + (h * 0.12), centerX + (w * 0.08), bibTopY);
    bibPath.close();

    canvas.drawPath(bibPath, whitePaint);
    canvas.drawPath(bibPath, inkPaint);
  }

  // ─── NEAR LEGS (Foreground with White Socks) ──────────────────────────────
  void _drawNearLegs({
    required Canvas canvas,
    required Paint inkPaint,
    required Paint furPaint,
    required Paint whitePaint,
    required double centerX,
    required double groundY,
    required double walkCycle,
    required bool isWalking,
    required double pawWave,
    required double sitProgress,
    required double walkBob,
    required double w,
    required double h,
  }) {
    if (sitProgress > 0.85) {
      // Sitting paws neatly in front
      final leftPawX = centerX - 2;
      final rightPawX = centerX + (w * 0.10);

      // Left sitting paw
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(leftPawX - 5, groundY - 14, 11, 14), const Radius.circular(5)),
        whitePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(leftPawX - 5, groundY - 14, 11, 14), const Radius.circular(5)),
        inkPaint,
      );

      // Right sitting paw (or waving if pawWave > 0)
      if (pawWave > 0) {
        final waveLift = math.sin(pawWave * math.pi) * 16.0;
        final wavePath = Path()
          ..moveTo(rightPawX - 3, groundY - 14)
          ..quadraticBezierTo(rightPawX + 8, groundY - 14 - waveLift * 0.6, rightPawX + 6, groundY - 12 - waveLift)
          ..quadraticBezierTo(rightPawX + 1, groundY - 8 - waveLift, rightPawX - 2, groundY - 14);
        canvas.drawPath(wavePath, whitePaint);
        canvas.drawPath(wavePath, inkPaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(rightPawX - 5, groundY - 14, 11, 14), const Radius.circular(5)),
          whitePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(rightPawX - 5, groundY - 14, 11, 14), const Radius.circular(5)),
          inkPaint,
        );
      }
      return;
    }

    // Near Back Leg with muscular haunch curve
    final nearBackSwing = isWalking ? math.sin(walkCycle * math.pi * 2) * 7.0 : 0.0;
    final nearBackLift = isWalking && math.sin(walkCycle * math.pi * 2) > 0
        ? math.sin(walkCycle * math.pi * 2) * 5.0
        : 0.0;
    final nearBackX = centerX - (w * 0.12) + nearBackSwing;
    final nearBackY = groundY - nearBackLift;

    final backLegPath = Path()
      ..moveTo(centerX - (w * 0.20), groundY - (h * 0.32) - walkBob)
      ..quadraticBezierTo(centerX - (w * 0.16), groundY - (h * 0.18) - walkBob, nearBackX - 4, nearBackY - 4)
      ..lineTo(nearBackX + 6, nearBackY - 4)
      ..quadraticBezierTo(centerX - (w * 0.04), groundY - (h * 0.20) - walkBob, centerX - (w * 0.08), groundY - (h * 0.32) - walkBob)
      ..close();
    canvas.drawPath(backLegPath, furPaint);
    canvas.drawPath(backLegPath, inkPaint);

    // Near Back White Sock
    final backSockPath = Path()
      ..moveTo(nearBackX - 4, nearBackY - 8)
      ..lineTo(nearBackX - 4, nearBackY - 2)
      ..quadraticBezierTo(nearBackX + 1, nearBackY, nearBackX + 6, nearBackY - 2)
      ..lineTo(nearBackX + 6, nearBackY - 8)
      ..close();
    canvas.drawPath(backSockPath, whitePaint);
    canvas.drawPath(backSockPath, inkPaint);

    // Near Front Leg (or cute waving mitten on tap!)
    if (pawWave > 0) {
      final waveLift = math.sin(pawWave * math.pi) * 18.0;
      final frontLegX = centerX + (w * 0.14);
      final waveLegPath = Path()
        ..moveTo(frontLegX - 4, groundY - (h * 0.28) - walkBob)
        ..quadraticBezierTo(frontLegX + 8, groundY - 14 - waveLift * 0.5, frontLegX + 10, groundY - 10 - waveLift)
        ..quadraticBezierTo(frontLegX + 2, groundY - 6 - waveLift, frontLegX - 2, groundY - (h * 0.25) - walkBob)
        ..close();
      canvas.drawPath(waveLegPath, furPaint);
      canvas.drawPath(waveLegPath, inkPaint);

      // Waving white mitten
      final mittenRect = Rect.fromCenter(
        center: Offset(frontLegX + 8, groundY - 12 - waveLift),
        width: 12,
        height: 12,
      );
      canvas.drawOval(mittenRect, whitePaint);
      canvas.drawOval(mittenRect, inkPaint);
    } else {
      final nearFrontSwing = isWalking ? math.sin((walkCycle + 0.5) * math.pi * 2) * 7.0 : 0.0;
      final nearFrontLift = isWalking && math.sin((walkCycle + 0.5) * math.pi * 2) > 0
          ? math.sin((walkCycle + 0.5) * math.pi * 2) * 5.0
          : 0.0;
      final nearFrontX = centerX + (w * 0.12) + nearFrontSwing;
      final nearFrontY = groundY - nearFrontLift;

      final frontLegPath = Path()
        ..moveTo(centerX + (w * 0.06), groundY - (h * 0.30) - walkBob)
        ..lineTo(nearFrontX - 4, nearFrontY - 4)
        ..lineTo(nearFrontX + 5, nearFrontY - 4)
        ..lineTo(centerX + (w * 0.16), groundY - (h * 0.28) - walkBob)
        ..close();
      canvas.drawPath(frontLegPath, furPaint);
      canvas.drawPath(frontLegPath, inkPaint);

      // Near Front White Sock
      final frontSockPath = Path()
        ..moveTo(nearFrontX - 4, nearFrontY - 8)
        ..lineTo(nearFrontX - 4, nearFrontY - 2)
        ..quadraticBezierTo(nearFrontX + 0.5, nearFrontY, nearFrontX + 5, nearFrontY - 2)
        ..lineTo(nearFrontX + 5, nearFrontY - 8)
        ..close();
      canvas.drawPath(frontSockPath, whitePaint);
      canvas.drawPath(frontSockPath, inkPaint);
    }
  }

  // ─── HEAD, CHEEK TUFTS, EARS & EXPRESSION ─────────────────────────────────
  void _drawHead({
    required Canvas canvas,
    required Paint inkPaint,
    required Paint furPaint,
    required Paint whitePaint,
    required Paint innerEarPaint,
    required Paint nosePaint,
    required double centerX,
    required double groundY,
    required double walkBob,
    required double sitProgress,
    required double blink,
    required double earFlick,
    required bool isHappy,
    required double lookDirection,
    required Color eyeIrisGreen,
    required Color eyePupilDark,
    required double w,
    required double h,
  }) {
    // Head position: chibi proportions (large, expressive cartoon head)
    final headBaseY = sitProgress > 0.5
        ? groundY - (h * 0.58)
        : groundY - (h * 0.54) - walkBob;
    final headCenter = Offset(centerX + (w * 0.14), headBaseY);
    final headW = w * 0.44;
    final headH = h * 0.40;

    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);

    // Subtle head tilt / glance
    final headTilt = (lookDirection * 0.08) + (isWalking ? math.sin(walkCycle * math.pi * 2) * 0.03 : 0.0);
    canvas.rotate(headTilt);

    // ── EARS (Drawn with organic fluffy base) ─────────────────────────────────
    final earY = -headH * 0.36;

    // Left Ear (Far ear)
    final leftEarPath = Path()
      ..moveTo(-headW * 0.28, earY + 4)
      ..lineTo(-headW * 0.36, earY - (headH * 0.42))
      ..lineTo(-headW * 0.06, earY - (headH * 0.12))
      ..close();
    canvas.drawPath(leftEarPath, furPaint);
    canvas.drawPath(leftEarPath, inkPaint);

    final leftInnerEar = Path()
      ..moveTo(-headW * 0.25, earY + 2)
      ..lineTo(-headW * 0.32, earY - (headH * 0.32))
      ..lineTo(-headW * 0.09, earY - (headH * 0.12))
      ..close();
    canvas.drawPath(leftInnerEar, innerEarPaint);

    // Right Ear (Near ear with lively ear flick animation!)
    final rightEarFlickRot = earFlick * 0.24;
    canvas.save();
    canvas.translate(headW * 0.22, earY);
    canvas.rotate(rightEarFlickRot);

    final rightEarPath = Path()
      ..moveTo(-headW * 0.08, 4)
      ..lineTo(headW * 0.16, -(headH * 0.44))
      ..lineTo(headW * 0.20, 2)
      ..close();
    canvas.drawPath(rightEarPath, furPaint);
    canvas.drawPath(rightEarPath, inkPaint);

    final rightInnerEar = Path()
      ..moveTo(-headW * 0.05, 2)
      ..lineTo(headW * 0.13, -(headH * 0.34))
      ..lineTo(headW * 0.16, 1)
      ..close();
    canvas.drawPath(rightInnerEar, innerEarPaint);
    canvas.restore();

    // ── HEAD SHAPE WITH DIETER CHEEK TUFTS ────────────────────────────────────
    final headPath = Path();
    // Rounded crown between ears
    headPath.moveTo(-headW * 0.26, -headH * 0.32);
    headPath.quadraticBezierTo(0, -headH * 0.42, headW * 0.26, -headH * 0.32);
    // Right cheek with fluffy tufts
    headPath.quadraticBezierTo(headW * 0.42, -headH * 0.12, headW * 0.52, headH * 0.08); // top tuft
    headPath.lineTo(headW * 0.44, headH * 0.10);
    headPath.lineTo(headW * 0.50, headH * 0.22); // bottom cheek tuft
    headPath.quadraticBezierTo(headW * 0.34, headH * 0.44, 0, headH * 0.44); // chin
    // Left cheek with fluffy tufts
    headPath.quadraticBezierTo(-headW * 0.34, headH * 0.44, -headW * 0.50, headH * 0.22); // bottom cheek tuft
    headPath.lineTo(-headW * 0.44, headH * 0.10);
    headPath.lineTo(-headW * 0.52, headH * 0.08); // top tuft
    headPath.quadraticBezierTo(-headW * 0.42, -headH * 0.12, -headW * 0.26, -headH * 0.32);
    headPath.close();

    canvas.drawPath(headPath, furPaint);
    canvas.drawPath(headPath, inkPaint);

    // ── DIETER ASYMMETRICAL WHITE MUZZLE BLAZE ───────────────────────────────
    // Dieter cat hallmark: charming white patch across the muzzle & right cheek!
    final muzzleBlaze = Path()
      ..moveTo(-headW * 0.18, headH * 0.08)
      ..quadraticBezierTo(0, -headH * 0.05, headW * 0.28, headH * 0.04)
      ..quadraticBezierTo(headW * 0.44, headH * 0.18, headW * 0.32, headH * 0.38)
      ..quadraticBezierTo(0, headH * 0.44, -headW * 0.18, headH * 0.38)
      ..close();
    canvas.drawPath(muzzleBlaze, whitePaint);
    canvas.drawPath(muzzleBlaze, inkPaint);

    // ── PINK BUTTON NOSE & CUTE ':3' CAT MOUTH ───────────────────────────────
    final noseY = headH * 0.14;
    final noseCenter = Offset(headW * 0.05, noseY);

    // Pink heart/triangle nose
    final nosePath = Path()
      ..moveTo(noseCenter.dx - 3.5, noseCenter.dy - 1.5)
      ..lineTo(noseCenter.dx + 3.5, noseCenter.dy - 1.5)
      ..lineTo(noseCenter.dx, noseCenter.dy + 3.0)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Cat mouth curves
    final mouthY = noseCenter.dy + 3.0;
    final mouthPath = Path()
      ..moveTo(noseCenter.dx, mouthY)
      ..lineTo(noseCenter.dx, mouthY + 3.0);
    canvas.drawPath(mouthPath, inkPaint);

    final leftSmile = Path()
      ..moveTo(noseCenter.dx, mouthY + 3.0)
      ..quadraticBezierTo(noseCenter.dx - 4.5, mouthY + 6.5, noseCenter.dx - 8.0, mouthY + 3.5);
    canvas.drawPath(leftSmile, inkPaint);

    final rightSmile = Path()
      ..moveTo(noseCenter.dx, mouthY + 3.0)
      ..quadraticBezierTo(noseCenter.dx + 4.5, mouthY + 6.5, noseCenter.dx + 8.0, mouthY + 3.5);
    canvas.drawPath(rightSmile, inkPaint);

    // ── WHISKERS (Fine White Ink strokes) ────────────────────────────────────
    final whiskerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    // Left Whiskers
    final wLeft = -headW * 0.22;
    canvas.drawLine(Offset(wLeft, noseY), Offset(wLeft - 14, noseY - 3), whiskerPaint);
    canvas.drawLine(Offset(wLeft, noseY + 5), Offset(wLeft - 13, noseY + 5), whiskerPaint);

    // Right Whiskers
    final wRight = headW * 0.32;
    canvas.drawLine(Offset(wRight, noseY), Offset(wRight + 14, noseY - 3), whiskerPaint);
    canvas.drawLine(Offset(wRight, noseY + 5), Offset(wRight + 13, noseY + 5), whiskerPaint);

    // ── EXPRESSIVE CARTOON EYES ──────────────────────────────────────────────
    final eyeSpacing = headW * 0.22;
    final eyeY = -headH * 0.04;
    final eyeRadius = headW * 0.12;

    final isSleepy = (mood == NoriMood.sleepy) && !isHappy;
    final isClosed = isSleepy || (blink > 0.4);

    // Left Eye
    _drawEye(
      canvas: canvas,
      center: Offset(-eyeSpacing + (headW * 0.04), eyeY),
      radius: eyeRadius,
      isClosed: isClosed,
      isHappy: isHappy,
      lookOffset: lookDirection,
      eyeIrisGreen: eyeIrisGreen,
      eyePupilDark: eyePupilDark,
      inkPaint: inkPaint,
    );

    // Right Eye
    _drawEye(
      canvas: canvas,
      center: Offset(eyeSpacing + (headW * 0.04), eyeY),
      radius: eyeRadius,
      isClosed: isClosed,
      isHappy: isHappy,
      lookOffset: lookDirection,
      eyeIrisGreen: eyeIrisGreen,
      eyePupilDark: eyePupilDark,
      inkPaint: inkPaint,
    );

    canvas.restore(); // restore head transform
  }

  void _drawEye({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required bool isClosed,
    required bool isHappy,
    required double lookOffset,
    required Color eyeIrisGreen,
    required Color eyePupilDark,
    required Paint inkPaint,
  }) {
    if (isHappy) {
      // Anime happy smiling eyes: '^' curve with thick expressive ink
      final smileEye = Path()
        ..moveTo(center.dx - radius, center.dy + 2)
        ..quadraticBezierTo(center.dx, center.dy - radius * 0.9, center.dx + radius, center.dy + 2);
      final happyPaint = Paint()
        ..color = const Color(0xFF16181F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(smileEye, happyPaint);
      return;
    }

    if (isClosed) {
      // Gentle closed sleeping arc
      final sleepPath = Path()
        ..moveTo(center.dx - radius, center.dy)
        ..quadraticBezierTo(center.dx, center.dy + radius * 0.7, center.dx + radius, center.dy);
      canvas.drawPath(sleepPath, inkPaint);
      return;
    }

    // Awake cartoon eye with luminous chartreuse green iris
    final eyeRect = Rect.fromCenter(
      center: center,
      width: radius * 1.8,
      height: radius * 2.1,
    );

    // Iris
    final irisPaint = Paint()..color = eyeIrisGreen..style = PaintingStyle.fill;
    canvas.drawOval(eyeRect, irisPaint);
    canvas.drawOval(eyeRect, inkPaint);

    // Pupil (follows lookDirection glance)
    final pupilX = center.dx + (lookOffset * 2.2);
    final pupilRect = Rect.fromCenter(
      center: Offset(pupilX, center.dy),
      width: radius * 0.80,
      height: radius * 1.55,
    );
    final pupilPaint = Paint()..color = eyePupilDark..style = PaintingStyle.fill;
    canvas.drawOval(pupilRect, pupilPaint);

    // Sparkle catchlights
    final sparklePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - radius * 0.30, center.dy - radius * 0.35), radius * 0.32, sparklePaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.22, center.dy + radius * 0.25), radius * 0.14, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant _DieterShimejiCatPainter old) {
    return old.breathe != breathe ||
        old.tail != tail ||
        old.walkCycle != walkCycle ||
        old.squash != squash ||
        old.blink != blink ||
        old.earFlick != earFlick ||
        old.pawWave != pawWave ||
        old.isHappy != isHappy ||
        old.isWalking != isWalking ||
        old.direction != direction ||
        old.sitProgress != sitProgress ||
        old.lookDirection != lookDirection ||
        old.mood != mood;
  }
}
