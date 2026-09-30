import 'package:flutter/material.dart';
import 'nori/nori_character.dart';
import 'nori/nori_particles.dart';
import 'nori/nori_black_cat_character.dart';

export 'nori/nori_character.dart' show NoriMood;

class NoriCompanion extends StatelessWidget {
  final double size;
  final String propId;
  final NoriMood mood;
  final bool isWalking;
  final int direction;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final NoriParticleController? particleController;

  const NoriCompanion({
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
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: NoriBlackCatCharacter(
        size: size,
        propId: propId,
        mood: mood,
        isWalking: isWalking,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
      ),
    );
  }
}



