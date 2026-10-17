import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'nori_character.dart' show NoriMood;
import 'nori_mochi_character.dart';

enum NoriLottieState {
  idle,       // 1. Main design: Black Cat by Popof
  wandering,  // 2. Wandering & Press design: Error Cat
  cheeky,     // 3. Random part design: Bad Cat
}

/// Dynamic 3-state Lottie mascot supporting:
/// 1. Main Idle / Sitting animation (`nori_idle.json` - Black Cat by Popof)
/// 2. Wandering & Press animation (`nori_wandering.json` - Error cat)
/// 3. Random Cheeky animation (`nori_cheeky.json` - Bad Cat)
/// 4. Tactile squash & stretch tap reaction with haptic feedback
/// 5. Dynamic wardrobe props overlay (stethoscope, glasses, crown, etc.)
class NoriLottieCharacter extends StatefulWidget {
  final double size;
  final String propId;
  final NoriMood mood;
  final bool isWalking;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const NoriLottieCharacter({
    super.key,
    this.size = 110,
    this.propId = 'stethoscope',
    this.mood = NoriMood.awake,
    this.isWalking = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<NoriLottieCharacter> createState() => _NoriLottieCharacterState();
}

class _NoriLottieCharacterState extends State<NoriLottieCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _squashCtrl;
  NoriLottieState _currentState = NoriLottieState.idle;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(covariant NoriLottieCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWalking != oldWidget.isWalking) {
      setState(() {
        _currentState = widget.isWalking ? NoriLottieState.wandering : NoriLottieState.idle;
      });
    }
  }

  @override
  void dispose() {
    _squashCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    // 25% chance to trigger cheeky state on tap, or cycle
    setState(() {
      if (_random.nextDouble() < 0.25) {
        _currentState = NoriLottieState.cheeky;
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() => _currentState = widget.isWalking ? NoriLottieState.wandering : NoriLottieState.idle);
          }
        });
      }
    });

    _squashCtrl.forward(from: 0.0);
    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    // Double tap triggers the cheeky / playful state
    setState(() {
      _currentState = NoriLottieState.cheeky;
      Future.delayed(const Duration(milliseconds: 2800), () {
        if (mounted) {
          setState(() => _currentState = widget.isWalking ? NoriLottieState.wandering : NoriLottieState.idle);
        }
      });
    });
    widget.onDoubleTap?.call();
  }

  String get _currentAssetPath {
    switch (_currentState) {
      case NoriLottieState.wandering:
        return 'assets/lottie/nori_wandering.json';
      case NoriLottieState.cheeky:
        return 'assets/lottie/nori_cheeky.json';
      case NoriLottieState.idle:
        return 'assets/lottie/nori_idle.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _squashCtrl,
        builder: (context, child) {
          final curve = Curves.elasticOut.transform(_squashCtrl.value);
          final scaleY = 1.0 - (curve * 0.14);
          final scaleX = 1.0 + (curve * 0.10);

          return Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: widget.size * 1.25,
              height: widget.size,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  // Soft Ground Shadow
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: widget.size * 0.75,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(widget.size * 0.75, 10),
                        ),
                      ),
                    ),
                  ),

                  // Lottie Vector Animation
                  Positioned.fill(
                    child: Lottie.asset(
                      _currentAssetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback gracefully while JSON files are being placed into assets/lottie/
                        return NoriMochiCharacter(
                          size: widget.size,
                          propId: 'none',
                          mood: widget.mood,
                        );
                      },
                    ),
                  ),

                  // Wardrobe Props Overlay
                  if (widget.propId != 'none')
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _LottiePropPainter(
                            propId: widget.propId,
                            size: widget.size,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LottiePropPainter extends CustomPainter {
  final String propId;
  final double size;

  _LottiePropPainter({required this.propId, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final centerX = w * 0.5;

    if (propId == 'stethoscope') {
      final stethPaint = Paint()
        ..color = const Color(0xFF38BDF8) // Bright Cyan Blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final tubePath = Path()
        ..moveTo(centerX - 18, h * 0.55)
        ..cubicTo(centerX - 16, h * 0.74, centerX + 16, h * 0.74, centerX + 18, h * 0.55);
      canvas.drawPath(tubePath, stethPaint);

      // Chestpiece bell
      canvas.drawCircle(
        Offset(centerX, h * 0.72),
        4.5,
        Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(centerX, h * 0.72),
        4.5,
        Paint()..color = const Color(0xFF1E2024)..style = PaintingStyle.stroke..strokeWidth = 1.2,
      );
    } else if (propId == 'glasses') {
      final rimPaint = Paint()
        ..color = const Color(0xFFFE5F55) // Coral rims
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final y = h * 0.40;
      canvas.drawCircle(Offset(centerX - 13, y), 8, rimPaint);
      canvas.drawCircle(Offset(centerX + 13, y), 8, rimPaint);
      canvas.drawLine(Offset(centerX - 5, y), Offset(centerX + 5, y), rimPaint);
    } else if (propId == 'crown') {
      final crownPaint = Paint()
        ..color = const Color(0xFFFFD166)
        ..style = PaintingStyle.fill;
      final crownPath = Path()
        ..moveTo(centerX - 12, h * 0.22)
        ..lineTo(centerX - 16, h * 0.12)
        ..lineTo(centerX - 6, h * 0.16)
        ..lineTo(centerX, h * 0.10)
        ..lineTo(centerX + 6, h * 0.16)
        ..lineTo(centerX + 16, h * 0.12)
        ..lineTo(centerX + 12, h * 0.22)
        ..close();
      canvas.drawPath(crownPath, crownPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LottiePropPainter oldDelegate) =>
      oldDelegate.propId != propId;
}
