import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/focus_timer_provider.dart';
import '../../widgets/timer/sketch_flip_digit.dart';

class FullscreenTimerScreen extends ConsumerStatefulWidget {
  const FullscreenTimerScreen({super.key});

  @override
  ConsumerState<FullscreenTimerScreen> createState() => _FullscreenTimerScreenState();
}

class _FullscreenTimerScreenState extends ConsumerState<FullscreenTimerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(focusTimerProvider);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final s = t.remainingSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mStr = m.toString().padLeft(2, '0');
    final sStr = sec.toString().padLeft(2, '0');
    final hStr = h > 0 ? h.toString().padLeft(2, '0') : null;

    final bg = t.theme.id == 'paper' ? const Color(0xFF181818) : t.theme.backgroundColor;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background preview (subtle)
          if (t.theme.thumbnailAssetPath != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.14,
                child: Image.asset(
                  t.theme.thumbnailAssetPath!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // ── Centered Clock Body (Guaranteed Dead-Center in Landscape & Portrait) ──
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: isLandscape
                    ? _landscape(t, mStr, sStr, hStr)
                    : _portrait(t, mStr, sStr, hStr),
              ),
            ),
          ),

          // ── Floating Top Bar (Overlayed without pushing the clock) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.subjectName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: t.theme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.topicTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.38),
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating Bottom Controls (Overlayed without pushing the clock) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(focusTimerProvider.notifier).startOrPause(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.38), width: 1.6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                t.isRunning
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t.isRunning ? 'PAUSE' : 'RESUME',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _portrait(
      FocusTimerState t, String mStr, String sStr, String? hStr) {
    final size = MediaQuery.of(context).size;
    final w = (size.width - 48).clamp(240.0, 420.0);
    final h = (size.height * 0.28).clamp(160.0, 260.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hStr != null) ...[
          _tile('Hours', hStr, 'h0', 'h1', w, h * 0.75, t),
          const SizedBox(height: 16),
        ],
        _tile(t.isBreak ? 'Break Min' : 'Minutes', mStr, 'm0', 'm1', w, h, t),
        const SizedBox(height: 16),
        _tile('Seconds', sStr, 's0', 's1', w, h, t),
      ],
    );
  }

  Widget _landscape(
      FocusTimerState t, String mStr, String sStr, String? hStr) {
    final size = MediaQuery.of(context).size;
    // Keep cards squarish with rounded corners exactly like reference screenshot
    final maxH = size.height * 0.72;
    final maxW = (size.width - (hStr != null ? 80 : 64)) / (hStr != null ? 3 : 2);
    final tileSize = maxH < maxW ? maxH : maxW;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hStr != null) ...[
          _tile('H', hStr, 'h0', 'h1', tileSize, tileSize, t),
          const SizedBox(width: 20),
        ],
        _tile(t.isBreak ? 'Break' : 'Min', mStr, 'm0', 'm1', tileSize, tileSize, t),
        const SizedBox(width: 20),
        _tile('Sec', sStr, 's0', 's1', tileSize, tileSize, t),
      ],
    );
  }

  Widget _tile(String label, String digits, String k0, String k1,
      double w, double h, FocusTimerState t) {
    final availableW = w - 24;
    final cardW = (availableW - 8) / 2;
    final cardH = h - 36;
    final fontSize = (cardH * 0.65).clamp(28.0, 120.0);
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.0,
    );

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SketchFlipDigit(
                    key: ValueKey('flip_$k0'),
                    digit: digits[0],
                    width: cardW,
                    height: cardH,
                    textStyle: textStyle,
                    cardColor: const Color(0xFF262628),
                    borderColor: const Color(0xFF3A3A3C),
                  ),
                  const SizedBox(width: 8),
                  SketchFlipDigit(
                    key: ValueKey('flip_$k1'),
                    digit: digits[1],
                    width: cardW,
                    height: cardH,
                    textStyle: textStyle,
                    cardColor: const Color(0xFF262628),
                    borderColor: const Color(0xFF3A3A3C),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
