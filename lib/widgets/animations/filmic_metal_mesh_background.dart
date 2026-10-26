import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Animated Apple Metal-inspired filmic mesh background.
///
/// Features:
/// 1. Continuous 60 FPS organic Lissajous orb drift over an 18-second harmonic cycle.
/// 2. Multi-node chromatic orbs (deep midnight indigo, celestial cobalt, and radiant cyan in dark mode;
///    titanium pearl, warm silver, and sky mist in light mode).
/// 3. Metallic specular sweep across the surface mimicking brushed aerospace titanium.
/// 4. Hardware-accelerated procedural film-grain noise overlay with [BlendMode.overlay].
/// 5. Isolated [RepaintBoundary] so only the canvas repaints, preserving full UI performance.
class FilmicMetalMeshBackground extends StatefulWidget {
  final Widget child;

  const FilmicMetalMeshBackground({
    super.key,
    required this.child,
  });

  @override
  State<FilmicMetalMeshBackground> createState() => _FilmicMetalMeshBackgroundState();
}

class _FilmicMetalMeshBackgroundState extends State<FilmicMetalMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _noiseImage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _generateNoiseImage();
  }

  /// Generates a small 128x128 film grain noise texture once for hardware-accelerated tiling
  Future<void> _generateNoiseImage() async {
    const int size = 128;
    final Uint8List pixels = Uint8List(size * size * 4);
    final random = math.Random(42);

    for (int i = 0; i < size * size; i++) {
      final int offset = i * 4;
      // High-frequency whisper-soft brushed metal film grain
      final int value = 120 + random.nextInt(32);
      final int alpha = 4 + random.nextInt(6); // 1.5% - 3.5% opacity for silky texture
      pixels[offset] = value;
      pixels[offset + 1] = value;
      pixels[offset + 2] = value;
      pixels[offset + 3] = alpha;
    }

    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: size,
      height: size,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _noiseImage = frameInfo.image;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _noiseImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    final themeAccent = AppTheme.accentPrimary;
    final canvasColor = AppTheme.paperBackground;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background mesh canvas in isolated RepaintBoundary
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _FilmicMetalMeshPainter(
                  progress: _controller.value,
                  isDark: isDark,
                  themeAccent: themeAccent,
                  canvasColor: canvasColor,
                  noiseImage: _noiseImage,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // Foreground content layer
        widget.child,
      ],
    );
  }
}

class _FilmicMetalMeshPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color themeAccent;
  final Color canvasColor;
  final ui.Image? noiseImage;

  _FilmicMetalMeshPainter({
    required this.progress,
    required this.isDark,
    required this.themeAccent,
    required this.canvasColor,
    required this.noiseImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double t = progress * 2.0 * math.pi;
    final Rect rect = Offset.zero & size;

    // 1. Base metal canvas gradient
    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF07090E),
                const Color(0xFF0B0F19),
                canvasColor,
              ]
            : [
                const Color(0xFFFFFFFF),
                const Color(0xFFF8FAFC),
                canvasColor,
              ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Harmonic Lissajous orbs (concentrated in top 60% of viewport)
    // Orb 1: Upper-left theme accent drift
    final double orb1X = size.width * (0.35 + 0.18 * math.sin(t));
    final double orb1Y = size.height * (0.20 + 0.10 * math.cos(t * 0.8));
    final double orb1Radius = size.width * 0.80;
    final Paint orb1Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(orb1X, orb1Y),
        orb1Radius,
        [
          themeAccent.withValues(alpha: isDark ? 0.38 : 0.22),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(orb1X, orb1Y), orb1Radius, orb1Paint);

    // Orb 2: Upper-right celestial shimmer complement
    final double orb2X = size.width * (0.75 + 0.16 * math.cos(t * 0.7));
    final double orb2Y = size.height * (0.28 + 0.12 * math.sin(t * 1.1));
    final double orb2Radius = size.width * 0.85;
    final Paint orb2Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(orb2X, orb2Y),
        orb2Radius,
        [
          isDark
              ? const Color(0xFF0C4A6E).withValues(alpha: 0.35)
              : const Color(0xFFBAE6FD).withValues(alpha: 0.40),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(orb2X, orb2Y), orb2Radius, orb2Paint);

    // Orb 3: Mid-tier ambient glow (drifts near 45% height)
    final double orb3X = size.width * (0.48 + 0.20 * math.sin(t * 0.9 + 1.2));
    final double orb3Y = size.height * (0.42 + 0.10 * math.cos(t * 0.6));
    final double orb3Radius = size.width * 0.75;
    final Paint orb3Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(orb3X, orb3Y),
        orb3Radius,
        [
          isDark
              ? const Color(0xFF1E1B4B).withValues(alpha: 0.40)
              : themeAccent.withValues(alpha: 0.16),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(orb3X, orb3Y), orb3Radius, orb3Paint);

    // 3. Apple-style metallic specular sheen sweep (upper atmosphere)
    final double sweepOffset = (progress * 2.0 - 0.5);
    final Paint sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + sweepOffset, -1.0),
        end: Alignment(1.0 + sweepOffset, 0.4),
        colors: [
          Colors.transparent,
          isDark
              ? Colors.white.withValues(alpha: 0.030)
              : Colors.white.withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.35, 0.50, 0.65],
      ).createShader(rect)
      ..blendMode = isDark ? BlendMode.plus : BlendMode.softLight;
    canvas.drawRect(rect, sheenPaint);

    // 4. Mid-Screen Horizon Dissolve (fading gradient into solid canvasColor between 45% and 62% height)
    final Paint horizonFadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.42, 0.62, 1.0],
        colors: [
          Colors.transparent,
          Colors.transparent,
          canvasColor,
          canvasColor,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, horizonFadePaint);

    // 5. Active 24 FPS Cinema Film Grain Jitter Overlay
    // Translates the texture matrix at 24 discrete frames per second across 35mm film cadence
    if (noiseImage != null) {
      final int frame = (progress * 480).floor(); // 24 FPS across 20-second repeat loop
      final double grainDx = ((frame * 37 + 17) % 128).toDouble();
      final double grainDy = ((frame * 59 + 29) % 128).toDouble();
      final Matrix4 grainMatrix = Matrix4.translationValues(grainDx, grainDy, 0.0);

      final Paint noisePaint = Paint()
        ..shader = ImageShader(
          noiseImage!,
          TileMode.repeated,
          TileMode.repeated,
          grainMatrix.storage,
        )
        ..blendMode = isDark ? BlendMode.overlay : BlendMode.softLight;
      canvas.drawRect(rect, noisePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmicMetalMeshPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.themeAccent != themeAccent ||
        oldDelegate.canvasColor != canvasColor ||
        oldDelegate.noiseImage != noiseImage;
  }
}
