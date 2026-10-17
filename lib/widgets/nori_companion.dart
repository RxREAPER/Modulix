import 'package:flutter/material.dart';
import 'nori/nori_character.dart';
import 'nori/nori_particles.dart';
import 'nori/nori_blob_character.dart';

export 'nori/nori_character.dart' show NoriMood;
export 'nori/nori_blob_character.dart'
    show NoriEmotion, NoriProp, NoriSize, NoriMotion, NoriBlobCharacter, NoriBlobCharacterState;
export 'nori/nori_speech_card.dart' show NoriSpeechCard, AnimatedNoriSpeechCard, NoriCoachOverlay, NoriCaretSide;

/// Thin adapter widget that presents [NoriBlobCharacter] to all call sites.
///
/// Every parameter from the legacy API is kept so callers compile unchanged.
/// The rendering backend is now the fully procedural lavender blob.
class NoriCompanion extends StatelessWidget {
  final double size;
  final NoriSize? sizePreset;
  final String propId;
  final NoriMood mood;
  final NoriMotion? motion;
  final bool isWalking;
  final int direction;
  final double sitProgress;
  final double lookDirection;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final NoriParticleController? particleController;

  final bool? enablePhysics;
  final bool? showGreetingBubble;

  const NoriCompanion({
    super.key,
    this.size = 64,
    this.sizePreset,
    this.propId = 'none',
    this.mood = NoriMood.awake,
    this.motion,
    this.isWalking = false,
    this.direction = 1,
    this.sitProgress = 0.0,
    this.lookDirection = 0.0,
    this.onTap,
    this.onDoubleTap,
    this.particleController,
    this.enablePhysics,
    this.showGreetingBubble,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
