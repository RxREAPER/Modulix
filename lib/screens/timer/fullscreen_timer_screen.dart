import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/focus_timer_provider.dart';

class FullscreenTimerScreen extends ConsumerStatefulWidget {
  const FullscreenTimerScreen({super.key});

  @override
  ConsumerState<FullscreenTimerScreen> createState() => _FullscreenTimerScreenState();
}

class _FullscreenTimerScreenState extends ConsumerState<FullscreenTimerScreen>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _ctrls = {};
  final Map<String, String> _prev = {};

  AnimationController _ctrl(String k) {
    return _ctrls.putIfAbsent(k, () =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 320)));
  }

  void _flip(String k, String d) {
    if (_prev[k] != d) {
      _prev[k] = d;
      _ctrl(k).forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    for (final c in _ctrls.values) { c.dispose(); }
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

    if (hStr != null) { _flip('h0', hStr[0]); _flip('h1', hStr[1]); }
    _flip('m0', mStr[0]); _flip('m1', mStr[1]);
    _flip('s0', sStr[0]); _flip('s1', sStr[1]);

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
                              color: Colors.white.withOpacity(0.85),
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
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.38),
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.38), width: 1.6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
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
    final fontSize = (h * 0.54).clamp(32.0, 120.0);
    return SizedBox(width: w, height: h,
      child: Stack(children: [
        Container(decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(22))),
        Positioned(top: h / 2 - 1.5, left: 0, right: 0,
          child: Container(height: 2.5, color: Colors.black.withOpacity(0.35))),
        Positioned(top: 10, left: 0, right: 0,
          child: Center(child: Text(label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: Colors.white.withOpacity(0.4))))),
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          _digitAnim(k0, digits[0], fontSize),
          _digitAnim(k1, digits[1], fontSize),
        ])),
      ]));
  }

  Widget _digitAnim(String k, String d, double sz) {
    return AnimatedBuilder(animation: _ctrl(k), builder: (_, __) {
      final v = _ctrl(k).value;
      final scale = 1.0 - (v < 0.5 ? v * 0.28 : (1 - v) * 0.28);
      final opacity = (v < 0.5 ? 1 - v * 1.8 : (v - 0.5) * 2.0).clamp(0.0, 1.0);
      return Opacity(opacity: opacity,
        child: Transform(alignment: Alignment.center,
          transform: Matrix4.identity()..scale(1.0, scale),
          child: Text(d, style: TextStyle(fontSize: sz, fontWeight: FontWeight.w800,
            color: Colors.white, height: 1.0))));
    });
  }
}
