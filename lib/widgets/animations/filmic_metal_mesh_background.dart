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
  final ui.Image? noiseImage;

  _FilmicMetalMeshPainter({
    required this.progress,
    required this.isDark,
    required this.noiseImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double t = progress * 2.0 * math.pi;

    // 1. Base metal canvas gradient
    final Rect rect = Offset.zero & size;
    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF07090E),
                Color(0xFF0B0F19),
                Color(0xFF090D15),
              ]
            : const [
                Color(0xFFF8FAFC),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Harmonic Lissajous orbs (smooth, organic drift)
    // Orb 1: Upper-left drift (Deep Indigo / Slate)
    final double orb1X = size.width * (0.32 + 0.16 * math.sin(t));
    final double orb1Y = size.height * (0.22 + 0.12 * math.cos(t * 0.8));
    final double orb1Radius = size.width * 0.75;
    final Paint orb1Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(orb1X, orb1Y),
        orb1Radius,
        [
          isDark
              ? const Color(0xFF1E1B4B).withValues(alpha: 0.65)
              : const Color(0xFFE2E8F0).withValues(alpha: 0.70),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(orb1X, orb1Y), orb1Radius, orb1Paint);

    // Orb 2: Upper-right celestial cobalt / azure shimmer
    final double orb2X = size.width * (0.75 + 0.18 * math.cos(t * 0.7));
    final double orb2Y = size.height * (0.35 + 0.15 * math.sin(t * 1.1));
    final double orb2Radius = size.width * 0.85;
    final Paint orb2Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(orb2X, orb2Y),
        orb2Radius,
        [
          isDark
              ? const Color(0xFF0C4A6E).withValues(alpha: 0.50)
              : const Color(0xFFBAE6FD).withValues(alpha: 0.60),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(orb2X, orb2Y), orb2Radius, orb2Paint);

    // Orb 3: Mid-bottom luminous cyan / titanium pearl accent
    final double orb3X = size.width * (0.45 + 0.22 * math.sin(t * 0.9 + 1.2));
    final double orb3Y = size.height * (0.68 + 0.14 * math.cos(t * 0.6));
    final double orb3Radius = size.width * 0.70;
    final Paint orb3Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(orb3X, orb3Y),
        orb3Radius,
        [
          isDark
              ? const Color(0xFF164E63).withValues(alpha: 0.38)
              : const Color(0xFFCFFAFE).withValues(alpha: 0.55),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(orb3X, orb3Y), orb3Radius, orb3Paint);

    // Orb 4: Subtle deep violet / iris glow
    final double orb4X = size.width * (0.20 + 0.15 * math.cos(t * 1.2 + 2.0));
    final double orb4Y = size.height * (0.85 + 0.10 * math.sin(t * 0.75));
    final double orb4Radius = size.width * 0.65;
    final Paint orb4Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(orb4X, orb4Y),
        orb4Radius,
        [
          isDark
              ? const Color(0xFF2E1065).withValues(alpha: 0.32)
              : const Color(0xFFEDE9FE).withValues(alpha: 0.50),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(orb4X, orb4Y), orb4Radius, orb4Paint);

    // 3. Apple-style metallic specular sheen sweep
    final double sweepOffset = (progress * 2.0 - 0.5);
    final Paint sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + sweepOffset, -1.0),
        end: Alignment(1.0 + sweepOffset, 1.0),
        colors: [
          Colors.transparent,
          isDark
              ? Colors.white.withValues(alpha: 0.035)
              : Colors.white.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.35, 0.50, 0.65],
      ).createShader(rect)
      ..blendMode = isDark ? BlendMode.plus : BlendMode.softLight;
    canvas.drawRect(rect, sheenPaint);

    // 4. Procedural film grain noise overlay
    if (noiseImage != null) {
      final Paint noisePaint = Paint()
        ..shader = ImageShader(
          noiseImage!,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.identity().storage,
        )
        ..blendMode = isDark ? BlendMode.overlay : BlendMode.softLight;
      canvas.drawRect(rect, noisePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmicMetalMeshPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.noiseImage != noiseImage;
  }
}
