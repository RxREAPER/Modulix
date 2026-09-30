import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nori_character.dart';

/// 2D Sprite-sheet / Frame-Animated Character Engine
class NoriSpriteCharacter extends StatefulWidget {
  final double size;
  final String propId;
  final NoriMood mood;
  final bool isWalking;
  final int direction;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const NoriSpriteCharacter({
    super.key,
    this.size = 110,
    this.propId = 'stethoscope',
    this.mood = NoriMood.awake,
    this.isWalking = false,
    this.direction = 1,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<NoriSpriteCharacter> createState() => _NoriSpriteCharacterState();
}

class _NoriSpriteCharacterState extends State<NoriSpriteCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _petCtrl;
  bool _isPetting = false;

  @override
  void initState() {
    super.initState();
    _petCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _petCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _isPetting = true);
    _petCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isPetting = false);
    });
    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    setState(() => _isPetting = true);
    _petCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isPetting = false);
    });
    widget.onDoubleTap?.call();
  }

  String _getSpriteAsset() {
    if (_isPetting || widget.mood == NoriMood.happy) {
      return 'assets/sprites/cat/white_petting.png';
    }
    if (widget.isWalking) {
      return 'assets/sprites/cat/white_walk.png';
    }
    return 'assets/sprites/cat/white_sit.png';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scaleX: widget.direction.toDouble(),
        alignment: Alignment.center,
        child: SizedBox(
          width: widget.size * 1.3,
          height: widget.size * 0.95,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Soft Ground Shadow
              Positioned(
                bottom: 0,
                child: Container(
                  width: widget.size * 0.95,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Crisp Transparent Character Sprite
              Positioned(
                bottom: 2,
                child: Image.asset(
                  _getSpriteAsset(),
                  width: widget.size * 1.25,
                  height: widget.size * 0.9,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
