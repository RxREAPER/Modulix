import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nori_character.dart' show NoriMood;

/// Canonical "Design 1": Chubby White Mochi Cat (Duolingo / Sanrio Grade)
class NoriMochiCharacter extends StatefulWidget {
  final double size;
  final String propId;
  final NoriMood mood;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const NoriMochiCharacter({
    super.key,
    this.size = 110,
    this.propId = 'stethoscope',
    this.mood = NoriMood.awake,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<NoriMochiCharacter> createState() => _NoriMochiCharacterState();
}

class _NoriMochiCharacterState extends State<NoriMochiCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _breatheCtrl;
  late final AnimationController _tailCtrl;
  late final AnimationController _squashCtrl;
  late final AnimationController _blinkCtrl;
  Timer? _blinkTimer;

  bool _isPetting = false;

  @override
  void initState() {
    super.initState();

    // 1. Organic Breathing Loop (3.8s)
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);

    // 2. Secondary Tail Swish (2.6s)
    _tailCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // 3. Elastic Squash & Stretch Tap Reaction (450ms)
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // 4. Humanized Blinking Engine
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scheduleBlink();
  }

  void _scheduleBlink() {
    final nextMs = 2600 + math.Random().nextInt(3400);
    _blinkTimer = Timer(Duration(milliseconds: nextMs), () {
      if (!mounted) return;
      _blinkCtrl.forward().then((_) {
        if (!mounted) return;
        _blinkCtrl.reverse().then((_) {
          // 30% chance of double-blink
          if (math.Random().nextDouble() < 0.3) {
            Future.delayed(const Duration(milliseconds: 80), () {
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

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _isPetting = true);
    _squashCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isPetting = false);
    });
    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    setState(() => _isPetting = true);
    _squashCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isPetting = false);
    });
    widget.onDoubleTap?.call();
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _tailCtrl.dispose();
    _squashCtrl.dispose();
    _blinkCtrl.dispose();
    _blinkTimer?.cancel();
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
        ]),
        builder: (context, _) {
          return SizedBox(
            width: widget.size * 1.25,
            height: widget.size,
            child: CustomPaint(
              size: Size(widget.size * 1.25, widget.size),
              painter: _NoriMochiPainter(
                breathe: _breatheCtrl.value,
                tail: _tailCtrl.value,
                squash: _squashCtrl.value,
                blink: _blinkCtrl.value,
                propId: widget.propId,
                mood: widget.mood,
                isPetting: _isPetting,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoriMochiPainter extends CustomPainter {
  final double breathe;
  final double tail;
  final double squash;
  final double blink;
  final String propId;
  final NoriMood mood;
  final bool isPetting;

  _NoriMochiPainter({
    required this.breathe,
    required this.tail,
    required this.squash,
    required this.blink,
    required this.propId,
    required this.mood,
    required this.isPetting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette: Clean Cream White Mochi
    final inkOutline = Paint()
      ..color = const Color(0xFF1E2024)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mochiWhite = Paint()
      ..color = const Color(0xFFFFFDF8) // Warm milky white
      ..style = PaintingStyle.fill;

    final innerEarPink = Paint()
      ..color = const Color(0xFFFFB2AC) // Sweet coral pink
      ..style = PaintingStyle.fill;

    final blushColor = Paint()
      ..color = const Color(0xFFFF7C76).withValues(alpha: isPetting ? 0.50 : 0.28)
      ..style = PaintingStyle.fill;

    // Elastic bounce physics
    final elasticCurve = Curves.elasticOut.transform(squash);
    final squashY = 1.0 - (elasticCurve * 0.16) + (math.sin(breathe * math.pi) * 0.022);
    final stretchX = 1.0 + (elasticCurve * 0.12) - (math.sin(breathe * math.pi) * 0.015);

    final centerX = w * 0.50;
    final groundY = h * 0.88;

    // ── 1. SOFT GROUND SHADOW (100% transparent background) ───────────────────
    final shadowWidth = (w * 0.64) * stretchX;
    final shadowRect = Rect.fromCenter(
      center: Offset(centerX, groundY + 4),
      width: shadowWidth,
      height: 7.0 * squashY,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = const Color(0x18000000),
    );

    canvas.save();
    canvas.translate(centerX, groundY);
    canvas.scale(stretchX, squashY);
    canvas.translate(-centerX, -groundY);

    // ── 2. TAIL SWISH ────────────────────────────────────────────────────────
    final tailAngle = math.sin(tail * math.pi * 2) * 0.25 + (isPetting ? 0.35 : 0.0);
    final tailBase = Offset(centerX + (w * 0.26), groundY - (h * 0.18));

    final tailPath = Path();
    tailPath.moveTo(tailBase.dx, tailBase.dy);
    tailPath.cubicTo(
      tailBase.dx + 22 + (tailAngle * 20),
      tailBase.dy - 8,
      tailBase.dx + 32 + (tailAngle * 35),
      tailBase.dy - 38 - (tailAngle * 12),
      tailBase.dx + 18 + (tailAngle * 28),
      tailBase.dy - 56,
    );

    final tailOutline = Paint()
      ..color = const Color(0xFF1E2024)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.8
      ..strokeCap = StrokeCap.round;

    final tailFill = Paint()
      ..color = const Color(0xFFFFFDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(tailPath, tailOutline);
    canvas.drawPath(tailPath, tailFill);

    // ── 3. CHUBBY MOCHI BODY ─────────────────────────────────────────────────
    final bodyCenter = Offset(centerX, groundY - (h * 0.27));
    final bodyRect = Rect.fromCenter(
      center: bodyCenter,
      width: w * 0.56,
      height: h * 0.46,
    );
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(36));

    canvas.drawRRect(bodyRRect, mochiWhite);
    canvas.drawRRect(bodyRRect, inkOutline);

    // Back feet
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - (w * 0.23), groundY - 3), width: 20, height: 13),
      mochiWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - (w * 0.23), groundY - 3), width: 20, height: 13),
      inkOutline,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX + (w * 0.23), groundY - 3), width: 20, height: 13),
      mochiWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX + (w * 0.23), groundY - 3), width: 20, height: 13),
      inkOutline,
    );

    // Front tucked paws
    final leftPaw = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 16, groundY - 14, 14, 15),
      const Radius.circular(7),
    );
    canvas.drawRRect(leftPaw, mochiWhite);
    canvas.drawRRect(leftPaw, inkOutline);

    final rightPaw = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + 2, groundY - 14, 14, 15),
      const Radius.circular(7),
    );
    canvas.drawRRect(rightPaw, mochiWhite);
    canvas.drawRRect(rightPaw, inkOutline);

    // ── 4. HEAD & EARS ───────────────────────────────────────────────────────
    final headCenter = Offset(centerX, groundY - (h * 0.52));
    final headWidth = w * 0.55;
    final headHeight = h * 0.43;

    // Left Ear
    final leftEar = Path()
      ..moveTo(headCenter.dx - (headWidth * 0.36), headCenter.dy - (headHeight * 0.12))
      ..lineTo(headCenter.dx - (headWidth * 0.43), headCenter.dy - (headHeight * 0.62))
      ..lineTo(headCenter.dx - (headWidth * 0.10), headCenter.dy - (headHeight * 0.38))
      ..close();
    canvas.drawPath(leftEar, mochiWhite);
    canvas.drawPath(leftEar, inkOutline);

    // Left Inner Pink
    final leftInner = Path()
      ..moveTo(headCenter.dx - (headWidth * 0.32), headCenter.dy - (headHeight * 0.16))
      ..lineTo(headCenter.dx - (headWidth * 0.38), headCenter.dy - (headHeight * 0.52))
      ..lineTo(headCenter.dx - (headWidth * 0.14), headCenter.dy - (headHeight * 0.35))
      ..close();
    canvas.drawPath(leftInner, innerEarPink);

    // Right Ear
    final rightEar = Path()
      ..moveTo(headCenter.dx + (headWidth * 0.36), headCenter.dy - (headHeight * 0.12))
      ..lineTo(headCenter.dx + (headWidth * 0.43), headCenter.dy - (headHeight * 0.62))
      ..lineTo(headCenter.dx + (headWidth * 0.10), headCenter.dy - (headHeight * 0.38))
      ..close();
    canvas.drawPath(rightEar, mochiWhite);
    canvas.drawPath(rightEar, inkOutline);

    // Right Inner Pink
    final rightInner = Path()
      ..moveTo(headCenter.dx + (headWidth * 0.32), headCenter.dy - (headHeight * 0.16))
      ..lineTo(headCenter.dx + (headWidth * 0.38), headCenter.dy - (headHeight * 0.52))
      ..lineTo(headCenter.dx + (headWidth * 0.14), headCenter.dy - (headHeight * 0.35))
      ..close();
    canvas.drawPath(rightInner, innerEarPink);

    // Head Base
    final headRect = Rect.fromCenter(
      center: headCenter,
      width: headWidth,
      height: headHeight,
    );
    final headRRect = RRect.fromRectAndRadius(headRect, const Radius.circular(30));
    canvas.drawRRect(headRRect, mochiWhite);
    canvas.drawRRect(headRRect, inkOutline);

    // ── 5. SWEET CARTOON FACE ────────────────────────────────────────────────
    final eyeY = headCenter.dy - 3;
    final leftEyeX = headCenter.dx - (headWidth * 0.22);
    final rightEyeX = headCenter.dx + (headWidth * 0.22);

    if (isPetting || mood == NoriMood.happy) {
      // Happy Squint Eyes (^ ^)
      _drawSquint(canvas, leftEyeX, eyeY, inkOutline);
      _drawSquint(canvas, rightEyeX, eyeY, inkOutline);
    } else if (mood == NoriMood.sleepy) {
      // Sleeping Half-Moons
      _drawSleep(canvas, leftEyeX, eyeY, inkOutline);
      _drawSleep(canvas, rightEyeX, eyeY, inkOutline);
    } else {
      // Big Anime Cartoon Eyes
      final eyeScaleY = (1.0 - blink).clamp(0.08, 1.0);
      _drawCartoonEye(canvas, leftEyeX, eyeY, eyeScaleY);
      _drawCartoonEye(canvas, rightEyeX, eyeY, eyeScaleY);
    }

    // Soft Blush Ovals
    canvas.drawOval(
      Rect.fromCenter(center: Offset(leftEyeX - 5, eyeY + 11), width: 13, height: 7),
      blushColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rightEyeX + 5, eyeY + 11), width: 13, height: 7),
      blushColor,
    );

    // Cute Coral Nose
    final noseY = headCenter.dy + 7;
    final nosePath = Path()
      ..moveTo(headCenter.dx, noseY + 2.4)
      ..lineTo(headCenter.dx - 3.0, noseY - 1.8)
      ..lineTo(headCenter.dx + 3.0, noseY - 1.8)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFFF6B6B));

    // Cat W-Mouth
    final mouthPath = Path()
      ..moveTo(headCenter.dx - 4.2, noseY + 3.8)
      ..quadraticBezierTo(headCenter.dx - 2.2, noseY + 6.2, headCenter.dx, noseY + 3.8)
      ..quadraticBezierTo(headCenter.dx + 2.2, noseY + 6.2, headCenter.dx + 4.2, noseY + 3.8);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF1E2024)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFF1E2024).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Left Whiskers
    canvas.drawLine(Offset(headCenter.dx - (headWidth * 0.30), noseY), Offset(headCenter.dx - (headWidth * 0.46), noseY - 3), whiskerPaint);
    canvas.drawLine(Offset(headCenter.dx - (headWidth * 0.30), noseY + 4), Offset(headCenter.dx - (headWidth * 0.46), noseY + 6), whiskerPaint);

    // Right Whiskers
    canvas.drawLine(Offset(headCenter.dx + (headWidth * 0.30), noseY), Offset(headCenter.dx + (headWidth * 0.46), noseY - 3), whiskerPaint);
    canvas.drawLine(Offset(headCenter.dx + (headWidth * 0.30), noseY + 4), Offset(headCenter.dx + (headWidth * 0.46), noseY + 6), whiskerPaint);

    // ── 6. ACCESSORIES / PROPS ───────────────────────────────────────────────
    _drawAccessories(canvas, headCenter, headWidth, propId, inkOutline);

    canvas.restore();
  }

  void _drawCartoonEye(Canvas canvas, double cx, double cy, double scaleY) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1.0, scaleY);

    // Deep ink pupil
    final pupilRect = Rect.fromCenter(center: Offset.zero, width: 13, height: 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pupilRect, const Radius.circular(6.5)),
      Paint()..color = const Color(0xFF1A1D20),
    );

    // White gloss reflections
    canvas.drawCircle(const Offset(-2.5, -3.5), 3.0, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(2.2, 2.5), 1.4, Paint()..color = Colors.white);

    canvas.restore();
  }

  void _drawSquint(Canvas canvas, double cx, double cy, Paint stroke) {
    final path = Path()
      ..moveTo(cx - 5.5, cy + 2)
      ..quadraticBezierTo(cx, cy - 4.5, cx + 5.5, cy + 2);
    canvas.drawPath(path, stroke);
  }

  void _drawSleep(Canvas canvas, double cx, double cy, Paint stroke) {
    final path = Path()
      ..moveTo(cx - 5.5, cy - 2)
      ..quadraticBezierTo(cx, cy + 4.5, cx + 5.5, cy - 2);
    canvas.drawPath(path, stroke);
  }

  void _drawAccessories(Canvas canvas, Offset headCenter, double headWidth, String id, Paint stroke) {
    switch (id) {
      case 'stethoscope':
        final stethPaint = Paint()
          ..color = const Color(0xFF1E88E5) // Clean medical blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

        final tubePath = Path()
          ..moveTo(headCenter.dx - (headWidth * 0.24), headCenter.dy + 22)
          ..quadraticBezierTo(headCenter.dx, headCenter.dy + 40, headCenter.dx + (headWidth * 0.24), headCenter.dy + 22);
        canvas.drawPath(tubePath, stethPaint);

        // Silver Bell
        canvas.drawCircle(Offset(headCenter.dx, headCenter.dy + 37), 5.2, Paint()..color = const Color(0xFFE0E0E0));
        canvas.drawCircle(Offset(headCenter.dx, headCenter.dy + 37), 5.2, Paint()..color = const Color(0xFF1E88E5)..style = PaintingStyle.stroke..strokeWidth = 1.4);
        break;

      case 'glasses':
        final framePaint = Paint()
          ..color = const Color(0xFF3E2723) // Deep brown
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final leftGlass = Rect.fromCircle(center: Offset(headCenter.dx - (headWidth * 0.22), headCenter.dy - 3), radius: 8.5);
        final rightGlass = Rect.fromCircle(center: Offset(headCenter.dx + (headWidth * 0.22), headCenter.dy - 3), radius: 8.5);
        canvas.drawOval(leftGlass, framePaint);
        canvas.drawOval(rightGlass, framePaint);
        canvas.drawLine(
          Offset(headCenter.dx - (headWidth * 0.10), headCenter.dy - 3),
          Offset(headCenter.dx + (headWidth * 0.10), headCenter.dy - 3),
          framePaint,
        );
        break;

      case 'nightcap':
        final cap = Path()
          ..moveTo(headCenter.dx - (headWidth * 0.32), headCenter.dy - (headWidth * 0.32))
          ..quadraticBezierTo(headCenter.dx, headCenter.dy - (headWidth * 0.62), headCenter.dx + (headWidth * 0.42), headCenter.dy - (headWidth * 0.12))
          ..lineTo(headCenter.dx + (headWidth * 0.32), headCenter.dy - (headWidth * 0.24))
          ..close();
        canvas.drawPath(cap, Paint()..color = const Color(0xFF5C6BC0));
        canvas.drawCircle(Offset(headCenter.dx + (headWidth * 0.42), headCenter.dy - (headWidth * 0.12)), 5.5, Paint()..color = Colors.white);
        break;

      case 'crown':
        final crown = Path()
          ..moveTo(headCenter.dx - 11, headCenter.dy - (headWidth * 0.38))
          ..lineTo(headCenter.dx - 13, headCenter.dy - (headWidth * 0.50))
          ..lineTo(headCenter.dx - 5, headCenter.dy - (headWidth * 0.43))
          ..lineTo(headCenter.dx, headCenter.dy - (headWidth * 0.54))
          ..lineTo(headCenter.dx + 5, headCenter.dy - (headWidth * 0.43))
          ..lineTo(headCenter.dx + 13, headCenter.dy - (headWidth * 0.50))
          ..lineTo(headCenter.dx + 11, headCenter.dy - (headWidth * 0.38))
          ..close();
        canvas.drawPath(crown, Paint()..color = const Color(0xFFFFCA28));
        canvas.drawPath(crown, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NoriMochiPainter old) => true;
}
