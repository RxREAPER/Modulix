import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nori_particles.dart';

enum NoriMood {
  awake,
  happy,
  sleepy,
  studying,
}

class NoriCharacter extends StatefulWidget {
  final double size;
  final String propId; // 'none' | 'stethoscope' | 'glasses' | 'coffee' | 'headphones' | 'nightcap' | 'crown'
  final NoriMood mood;
  final bool isWalking;
  final int direction; // 1 for right, -1 for left
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final NoriParticleController? particleController;

  const NoriCharacter({
    super.key,
    this.size = 110,
    this.propId = 'stethoscope',
    this.mood = NoriMood.awake,
    this.isWalking = false,
    this.direction = 1,
    this.onTap,
    this.onDoubleTap,
    this.particleController,
  });

  @override
  State<NoriCharacter> createState() => _NoriCharacterState();
}

class _NoriCharacterState extends State<NoriCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _breatheCtrl;
  late final AnimationController _tailCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _bounceCtrl;
  late final AnimationController _steamCtrl;
  late final AnimationController _walkCtrl;

  late final Animation<double> _breatheAnim;
  late final Animation<double> _tailAnim;
  late final Animation<double> _blinkAnim;
  late final Animation<double> _bounceAnim;

  bool _isPetting = false;

  @override
  void initState() {
    super.initState();

    // 1. Organic Breathing (4.2s smooth sine loop)
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _breatheAnim = CurvedAnimation(
      parent: _breatheCtrl,
      curve: Curves.easeInOutSine,
    );

    // 2. Fluid Tail Swish (2.6s smooth sine loop)
    _tailCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _tailAnim = CurvedAnimation(
      parent: _tailCtrl,
      curve: Curves.easeInOutCubic,
    );

    // 3. Realistic Periodic Blinking (5.5s cycle)
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();

    _blinkAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 92),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.08), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 0.08, end: 1.0), weight: 4),
    ]).animate(_blinkCtrl);

    // 4. Elastic Touch / Petting Bounce (550ms spring)
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _bounceAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bounceCtrl,
        curve: Curves.elasticOut,
      ),
    );

    // 5. Rising Steam for Coffee prop (2.2s loop)
    _steamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // 6. Fast walk cycle (300ms loop)
    _walkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.isWalking) {
      _walkCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(NoriCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWalking != oldWidget.isWalking) {
      if (widget.isWalking) {
        _walkCtrl.repeat();
      } else {
        _walkCtrl.animateTo(0.0, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _tailCtrl.dispose();
    _blinkCtrl.dispose();
    _bounceCtrl.dispose();
    _steamCtrl.dispose();
    _walkCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _isPetting = true);
    _bounceCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isPetting = false);
    });

    // Spawn heart and sparkle particles
    widget.particleController?.spawnBurst(widget.size * 0.65, widget.size * 0.45, count: 6);

    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    setState(() => _isPetting = true);
    _bounceCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isPetting = false);
    });

    widget.particleController?.spawnBurst(widget.size * 0.65, widget.size * 0.35, count: 9);

    widget.onDoubleTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breatheAnim,
          _tailAnim,
          _blinkAnim,
          _bounceAnim,
          _steamCtrl,
          _walkCtrl,
        ]),
        builder: (context, _) {
          return SizedBox(
            width: widget.size * 1.35,
            height: widget.size,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Grounding shadow
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: widget.size * 0.95,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

                // Main Character Body + Rig
                Transform.scale(
                  scaleX: widget.direction.toDouble(),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: Size(widget.size * 1.35, widget.size),
                    painter: _NoriMasterPainter(
                      breathe: _breatheAnim.value,
                      tail: _tailAnim.value,
                      blink: _blinkAnim.value,
                      bounce: _bounceAnim.value,
                      steam: _steamCtrl.value,
                      walk: _walkCtrl.value,
                      propId: widget.propId,
                      isPetting: _isPetting,
                      mood: widget.mood,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NoriMasterPainter extends CustomPainter {
  final double breathe; // 0.0 to 1.0
  final double tail; // 0.0 to 1.0
  final double blink; // 0.0 to 1.0
  final double bounce; // 0.0 to 1.0
  final double steam; // 0.0 to 1.0
  final double walk; // 0.0 to 1.0
  final String propId;
  final bool isPetting;
  final NoriMood mood;

  _NoriMasterPainter({
    required this.breathe,
    required this.tail,
    required this.blink,
    required this.bounce,
    required this.steam,
    required this.walk,
    required this.propId,
    required this.isPetting,
    required this.mood,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ink and fill paints
    final strokePaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0x181C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // ── 1. FLUID BEZIER TAIL SWISH ───────────────────────────────────────────
    final tailWag = math.sin((tail - 0.5) * math.pi) * 0.35;
    final tailOrigin = Offset(w * 0.76, h * 0.75);

    final tailPath = Path();
    tailPath.moveTo(tailOrigin.dx, tailOrigin.dy);

    final midX = tailOrigin.dx + (w * 0.16) + (tailWag * 12);
    final midY = tailOrigin.dy - (h * 0.15) - (tailWag * 6);
    final tipX = tailOrigin.dx + (w * 0.26) + (tailWag * 24);
    final tipY = tailOrigin.dy - (h * 0.32) + (tailWag * 10);

    tailPath.quadraticBezierTo(midX, midY, tipX, tipY);

    final tailOutline = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final tailInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(tailPath, tailOutline);
    canvas.drawPath(tailPath, tailInner);

    // ── 1.5. WALKING LEGS ────────────────────────────────────────────────────
    final walkAngle = walk * math.pi * 2;
    final legYOffset = h * 0.80;
    
    final frontLegRot = math.sin(walkAngle) * 0.4;
    final backLegRot = math.sin(walkAngle + math.pi) * 0.4;
    final walkBobY = (math.sin(walkAngle * 2).abs()) * 6.0;
    
    void drawLeg(double x, double rot) {
      canvas.save();
      canvas.translate(x, legYOffset - walkBobY * 0.5);
      canvas.rotate(rot);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 8), width: 14, height: 24),
        const Radius.circular(7),
      );
      canvas.drawRRect(rect, whiteFill);
      canvas.drawRRect(rect, strokePaint);
      canvas.restore();
    }
    
    if (walk > 0) {
      drawLeg(w * 0.42, backLegRot);
      drawLeg(w * 0.58, frontLegRot);
    }

    // ── 2. VOLUMETRIC SQUASH & STRETCH BODY ──────────────────────────────────
    // When breathing in, body expands slightly in width and dips slightly in height
    final double bounceStretch = (1.0 - bounce) * math.sin(bounce * math.pi * 3) * 0.12;
    final double bodyScaleX = 1.0 + (breathe * 0.04) + bounceStretch;
    final double bodyScaleY = 1.0 - (breathe * 0.03) - bounceStretch;

    final bodyCenter = Offset(w * 0.50, h * 0.62 - walkBobY);

    canvas.save();
    canvas.translate(bodyCenter.dx, bodyCenter.dy);
    canvas.scale(bodyScaleX, bodyScaleY);
    canvas.translate(-bodyCenter.dx, -bodyCenter.dy);

    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: bodyCenter, width: w * 0.52, height: h * 0.44),
      topLeft: const Radius.circular(36),
      topRight: const Radius.circular(28),
      bottomLeft: const Radius.circular(30),
      bottomRight: const Radius.circular(38),
    );

    // Drop shadow offset
    canvas.drawRRect(bodyRect.shift(const Offset(2.5, 3)), shadowPaint);
    canvas.drawRRect(bodyRect, whiteFill);
    canvas.drawRRect(bodyRect, strokePaint);

    canvas.restore();

    // ── 3. HEAD & EARS RIG ───────────────────────────────────────────────────
    final headBounceY = (1.0 - bounce) * math.sin(bounce * math.pi * 3) * 8.0;
    final headCenter = Offset(w * 0.48, h * 0.38 - (breathe * 3.0) - headBounceY - walkBobY);

    // Ears with micro-twitch angle
    final earTwitch = isPetting ? 0.08 : (math.sin(tail * math.pi * 2) * 0.03);

    // Left Ear
    canvas.save();
    canvas.translate(headCenter.dx - w * 0.15, headCenter.dy - h * 0.18);
    canvas.rotate(-0.25 + earTwitch);
    _drawEar(canvas, strokePaint, whiteFill);
    canvas.restore();

    // Right Ear
    canvas.save();
    canvas.translate(headCenter.dx + w * 0.15, headCenter.dy - h * 0.18);
    canvas.rotate(0.25 - earTwitch);
    _drawEar(canvas, strokePaint, whiteFill);
    canvas.restore();

    // Head Oval
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: headCenter, width: w * 0.44, height: h * 0.38),
      Radius.circular(w * 0.22),
    );
    canvas.drawRRect(headRect.shift(const Offset(2.0, 2.5)), shadowPaint);
    canvas.drawRRect(headRect, whiteFill);
    canvas.drawRRect(headRect, strokePaint);

    // ── 4. EXPRESSIVE EYES & NOSE ────────────────────────────────────────────
    final eyeY = headCenter.dy - (h * 0.03);
    final leftEyeX = headCenter.dx - (w * 0.09);
    final rightEyeX = headCenter.dx + (w * 0.09);

    if (isPetting || mood == NoriMood.happy) {
      // Happy Squint Arcs (^ ^)
      _drawSquintEye(canvas, leftEyeX, eyeY, strokePaint);
      _drawSquintEye(canvas, rightEyeX, eyeY, strokePaint);
    } else if (mood == NoriMood.sleepy) {
      // Sleepy half-closed eyes
      _drawSleepyEye(canvas, leftEyeX, eyeY, strokePaint);
      _drawSleepyEye(canvas, rightEyeX, eyeY, strokePaint);
    } else {
      // Wide Awake Alert Eyes with Reflection & Blinking
      final eyeScaleY = blink.clamp(0.1, 1.0);
      _drawAwakeEye(canvas, leftEyeX, eyeY, eyeScaleY);
      _drawAwakeEye(canvas, rightEyeX, eyeY, eyeScaleY);
    }

    // Cute Coral Pink Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFFE5F55)
      ..style = PaintingStyle.fill;
    final nosePath = Path();
    final noseY = headCenter.dy + (h * 0.04);
    nosePath.moveTo(headCenter.dx, noseY + 3);
    nosePath.lineTo(headCenter.dx - 3.5, noseY - 2);
    nosePath.lineTo(headCenter.dx + 3.5, noseY - 2);
    nosePath.close();
    canvas.drawPath(nosePath, nosePaint);

    // Cute mouth line
    final mouthPaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    mouthPath.moveTo(headCenter.dx - 4, noseY + 5);
    mouthPath.quadraticBezierTo(headCenter.dx - 2, noseY + 7, headCenter.dx, noseY + 5);
    mouthPath.quadraticBezierTo(headCenter.dx + 2, noseY + 7, headCenter.dx + 4, noseY + 5);
    canvas.drawPath(mouthPath, mouthPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFF1C1C1C).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Left whiskers
    canvas.drawLine(Offset(headCenter.dx - w * 0.16, noseY + 1), Offset(headCenter.dx - w * 0.23, noseY - 2), whiskerPaint);
    canvas.drawLine(Offset(headCenter.dx - w * 0.16, noseY + 4), Offset(headCenter.dx - w * 0.24, noseY + 6), whiskerPaint);

    // Right whiskers
    canvas.drawLine(Offset(headCenter.dx + w * 0.16, noseY + 1), Offset(headCenter.dx + w * 0.23, noseY - 2), whiskerPaint);
    canvas.drawLine(Offset(headCenter.dx + w * 0.16, noseY + 4), Offset(headCenter.dx + w * 0.24, noseY + 6), whiskerPaint);

    // ── 5. THE 6 COSTUMES & PROPS ────────────────────────────────────────────
    switch (propId) {
      case 'stethoscope':
        _drawStethoscope(canvas, headCenter, strokePaint);
        break;
      case 'glasses':
        _drawGlasses(canvas, headCenter, eyeY, leftEyeX, rightEyeX);
        break;
      case 'coffee':
        _drawCoffeeMug(canvas, w * 0.14, h * 0.70, steam);
        break;
      case 'headphones':
        _drawHeadphones(canvas, headCenter, w, h);
        break;
      case 'nightcap':
        _drawNightcap(canvas, headCenter, w, h);
        break;
      case 'crown':
        _drawCrown(canvas, headCenter, w);
        break;
      default:
        break;
    }
  }

  void _drawEar(Canvas canvas, Paint stroke, Paint fill) {
    final earPath = Path();
    earPath.moveTo(-10, 14);
    earPath.lineTo(-6, -14);
    earPath.quadraticBezierTo(0, -18, 6, -14);
    earPath.lineTo(10, 14);
    earPath.close();

    canvas.drawPath(earPath, fill);
    canvas.drawPath(earPath, stroke);

    // Soft pink inner ear
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFFD1D6)
      ..style = PaintingStyle.fill;
    final innerPath = Path();
    innerPath.moveTo(-5, 10);
    innerPath.lineTo(-3, -8);
    innerPath.quadraticBezierTo(0, -11, 3, -8);
    innerPath.lineTo(5, 10);
    innerPath.close();
    canvas.drawPath(innerPath, innerEarPaint);
  }

  void _drawAwakeEye(Canvas canvas, double cx, double cy, double scaleY) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1.0, scaleY);

    final eyePaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 5.0, eyePaint);

    // White specular reflections
    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-1.6, -1.6), 1.6, shinePaint);
    canvas.drawCircle(const Offset(1.8, 1.8), 0.8, shinePaint);

    canvas.restore();
  }

  void _drawSquintEye(Canvas canvas, double cx, double cy, Paint stroke) {
    final squintPaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(cx - 5, cy + 1);
    path.quadraticBezierTo(cx, cy - 4, cx + 5, cy + 1);
    canvas.drawPath(path, squintPaint);
  }

  void _drawSleepyEye(Canvas canvas, double cx, double cy, Paint stroke) {
    final linePaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 4, cy), Offset(cx + 4, cy), linePaint);
  }

  // ── PROP 1: DOCTOR STETHOSCOPE ─────────────────────────────────────────────
  void _drawStethoscope(Canvas canvas, Offset headCenter, Paint stroke) {
    final stethPaint = Paint()
      ..color = const Color(0xFF4F46E5) // Signature indigo tubing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final tubing = Path();
    tubing.moveTo(headCenter.dx - 18, headCenter.dy + 14);
    tubing.cubicTo(
      headCenter.dx - 24, headCenter.dy + 38,
      headCenter.dx + 24, headCenter.dy + 38,
      headCenter.dx + 18, headCenter.dy + 14,
    );
    canvas.drawPath(tubing, stethPaint);

    // Extension down to chest piece
    final extTubing = Path();
    extTubing.moveTo(headCenter.dx, headCenter.dy + 34);
    extTubing.lineTo(headCenter.dx + 6, headCenter.dy + 42);
    canvas.drawPath(extTubing, stethPaint);

    // Silver metallic chest piece
    final bellPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;
    final bellBorder = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final bellCenter = Offset(headCenter.dx + 7, headCenter.dy + 43);
    canvas.drawCircle(bellCenter, 5.0, bellPaint);
    canvas.drawCircle(bellCenter, 5.0, bellBorder);
    canvas.drawCircle(bellCenter, 2.0, Paint()..color = const Color(0xFF94A3B8));
  }

  // ── PROP 2: STUDY READING GLASSES ──────────────────────────────────────────
  void _drawGlasses(Canvas canvas, Offset headCenter, double eyeY, double leftX, double rightX) {
    final framePaint = Paint()
      ..color = const Color(0xFFB45309) // Warm tortoiseshell brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final lensGleam = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    // Left lens
    canvas.drawCircle(Offset(leftX, eyeY), 7.5, lensGleam);
    canvas.drawCircle(Offset(leftX, eyeY), 7.5, framePaint);

    // Right lens
    canvas.drawCircle(Offset(rightX, eyeY), 7.5, lensGleam);
    canvas.drawCircle(Offset(rightX, eyeY), 7.5, framePaint);

    // Nose bridge
    canvas.drawLine(Offset(leftX + 7.5, eyeY), Offset(rightX - 7.5, eyeY), framePaint);
  }

  // ── PROP 3: STEAMING COFFEE MUG ────────────────────────────────────────────
  void _drawCoffeeMug(Canvas canvas, double cx, double cy, double steamVal) {
    final mugPaint = Paint()
      ..color = const Color(0xFFFEF3C7) // warm ceramic cream
      ..style = PaintingStyle.fill;

    final mugBorder = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final mugRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, cy), width: 18, height: 16),
      bottomLeft: const Radius.circular(5),
      bottomRight: const Radius.circular(5),
    );
    canvas.drawRRect(mugRect, mugPaint);
    canvas.drawRRect(mugRect, mugBorder);

    // Handle
    final handlePath = Path();
    handlePath.addArc(Rect.fromCenter(center: Offset(cx + 10, cy), width: 8, height: 10), -math.pi / 2, math.pi);
    canvas.drawPath(handlePath, mugBorder);

    // Animated Rising Steam Curves
    final steamPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5 * (1.0 - (steamVal - 0.5).abs() * 1.5).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final steamPath = Path();
    final steamBaseY = cy - 8 - (steamVal * 8);
    steamPath.moveTo(cx - 2, steamBaseY);
    steamPath.quadraticBezierTo(cx - 5, steamBaseY - 6, cx - 2, steamBaseY - 12);
    canvas.drawPath(steamPath, steamPaint);
  }

  // ── PROP 4: NOISE-CANCELING HEADPHONES ──────────────────────────────────────
  void _drawHeadphones(Canvas canvas, Offset headCenter, double w, double h) {
    final bandPaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    // Over-head band
    final bandPath = Path();
    bandPath.moveTo(headCenter.dx - w * 0.22, headCenter.dy - h * 0.08);
    bandPath.cubicTo(
      headCenter.dx - w * 0.22, headCenter.dy - h * 0.28,
      headCenter.dx + w * 0.22, headCenter.dy - h * 0.28,
      headCenter.dx + w * 0.22, headCenter.dy - h * 0.08,
    );
    canvas.drawPath(bandPath, bandPaint);

    // Padded ear cups
    final cupPaint = Paint()
      ..color = const Color(0xFF10B981) // Emerald green
      ..style = PaintingStyle.fill;
    final cupBorder = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left cup
    final leftCup = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(headCenter.dx - w * 0.22, headCenter.dy - h * 0.04), width: 8, height: 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(leftCup, cupPaint);
    canvas.drawRRect(leftCup, cupBorder);

    // Right cup
    final rightCup = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(headCenter.dx + w * 0.22, headCenter.dy - h * 0.04), width: 8, height: 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(rightCup, cupPaint);
    canvas.drawRRect(rightCup, cupBorder);
  }

  // ── PROP 5: LATE-NIGHT NIGHTCAP ─────────────────────────────────────────────
  void _drawNightcap(Canvas canvas, Offset headCenter, double w, double h) {
    final capFill = Paint()
      ..color = const Color(0xFF6366F1) // Night indigo
      ..style = PaintingStyle.fill;
    final capBorder = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final capPath = Path();
    capPath.moveTo(headCenter.dx - w * 0.16, headCenter.dy - h * 0.14);
    capPath.quadraticBezierTo(headCenter.dx, headCenter.dy - h * 0.28, headCenter.dx + w * 0.22, headCenter.dy - h * 0.14);
    capPath.lineTo(headCenter.dx + w * 0.28, headCenter.dy + h * 0.02); // drooping tip
    capPath.close();

    canvas.drawPath(capPath, capFill);
    canvas.drawPath(capPath, capBorder);

    // Pompom at tip
    canvas.drawCircle(Offset(headCenter.dx + w * 0.28, headCenter.dy + h * 0.02), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(headCenter.dx + w * 0.28, headCenter.dy + h * 0.02), 4.5, capBorder);
  }

  // ── PROP 6: GOLDEN LAUREL CROWN ────────────────────────────────────────────
  void _drawCrown(Canvas canvas, Offset headCenter, double w) {
    final goldPaint = Paint()
      ..color = const Color(0xFFFFD166) // Radiant gold
      ..style = PaintingStyle.fill;
    final goldBorder = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final crownPath = Path();
    final topY = headCenter.dy - 24;
    crownPath.moveTo(headCenter.dx - 14, topY + 6);
    crownPath.lineTo(headCenter.dx - 12, topY - 4);
    crownPath.lineTo(headCenter.dx - 5, topY + 2);
    crownPath.lineTo(headCenter.dx, topY - 8);
    crownPath.lineTo(headCenter.dx + 5, topY + 2);
    crownPath.lineTo(headCenter.dx + 12, topY - 4);
    crownPath.lineTo(headCenter.dx + 14, topY + 6);
    crownPath.close();

    canvas.drawPath(crownPath, goldPaint);
    canvas.drawPath(crownPath, goldBorder);

    // Center jewel
    canvas.drawCircle(Offset(headCenter.dx, topY - 2), 2.0, Paint()..color = const Color(0xFFFE5F55));
  }

  @override
  bool shouldRepaint(covariant _NoriMasterPainter oldDelegate) => true;
}
