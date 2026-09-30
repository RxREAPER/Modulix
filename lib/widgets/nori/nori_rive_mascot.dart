import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'nori_character.dart';

/// Interactive Mascot driven by Rive State Machine with fallback to NoriCharacter.
class NoriRiveMascot extends StatefulWidget {
  final double size;
  final NoriMood mood;
  final bool isWalking;
  final int direction;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const NoriRiveMascot({
    super.key,
    this.size = 110,
    this.mood = NoriMood.awake,
    this.isWalking = false,
    this.direction = 1,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<NoriRiveMascot> createState() => _NoriRiveMascotState();
}

class _NoriRiveMascotState extends State<NoriRiveMascot> {
  rive.File? _riveFile;
  rive.RiveWidgetController? _controller;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadMascot();
  }

  Future<void> _loadMascot() async {
    try {
      final file = await rive.File.asset(
        'assets/rive/nori_mascot.riv',
        riveFactory: rive.Factory.rive,
      );
      if (!mounted) return;
      if (file != null) {
        final ctrl = rive.RiveWidgetController(file);
        setState(() {
          _riveFile = file;
          _controller = ctrl;
        });
      } else {
        setState(() => _loadFailed = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  @override
  void didUpdateWidget(NoriRiveMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null) {
      try {
        final sm = _controller!.stateMachine;
        final walkInput = sm.boolean('isWalking');
        if (walkInput != null) {
          walkInput.value = widget.isWalking;
        }

        final sleepInput = sm.boolean('isSleeping');
        if (sleepInput != null) {
          sleepInput.value = widget.mood == NoriMood.sleepy;
        }
      } catch (_) {}
    }
  }

  void _triggerPet() {
    try {
      _controller?.stateMachine.trigger('Trigger')?.fire();
      _controller?.stateMachine.trigger('pet')?.fire();
    } catch (_) {}
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed || _riveFile == null || _controller == null) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: _triggerPet,
      onDoubleTap: widget.onDoubleTap,
      child: Transform.scale(
        scaleX: widget.direction.toDouble(),
        alignment: Alignment.center,
        child: SizedBox(
          width: widget.size * 1.2,
          height: widget.size,
          child: rive.RiveWidget(
            controller: _controller!,
            fit: rive.Fit.contain,
          ),
        ),
      ),
    );
  }
}
