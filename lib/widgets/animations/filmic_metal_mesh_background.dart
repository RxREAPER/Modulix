import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Animated Apple Metal / Liquid Chromatic Motion Background.
///
/// Features:
/// 1. True GPU Fragment Shader executing Apple Metal-style fluid wave deformation,
///    directional specular crests, liquid water caustics, and domain warping.
/// 2. Active 24 FPS 35mm cinematic film grain jitter across the entire screen.
/// 3. Seamless theme-accent integration adapting between Dark (obsidian/titanium chrome)
///    and Light (brushed silver/pearl caustics).
/// 4. Mid-to-lower horizon fade preserving high readability for lower tasks while
///    extending the fluid graphic motion deeper past the hero cards.
/// 5. Lifecycle-aware execution: automatically pauses ticker when app is backgrounded.
/// 6. Headless test fallback: falls back gracefully to procedural bezier wave painter
///    if FragmentProgram is unavailable in headless CI test runners.
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  ui.FragmentProgram? _program;
  ui.Image? _fallbackNoiseImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _loadShader();
    _generateFallbackNoiseImage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/liquid_metal.frag');
      debugPrint('[FilmicMetalMeshBackground] Loaded GLSL shader successfully!');
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (e, stack) {
      debugPrint('[FilmicMetalMeshBackground] Shader failed to load: $e\n$stack');
    }
  }

  /// Generates fallback noise texture for headless/non-shader execution
  Future<void> _generateFallbackNoiseImage() async {
    const int size = 128;
    final Uint8List pixels = Uint8List(size * size * 4);
    final random = math.Random(42);

    for (int i = 0; i < size * size; i++) {
      final int offset = i * 4;
      final int value = 120 + random.nextInt(32);
      final int alpha = 4 + random.nextInt(6);
      pixels[offset] = value;
      pixels[offset + 1] = value;
      pixels[offset + 2] = value;
      pixels[offset + 3] = alpha;
    }

    try {
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
          _fallbackNoiseImage = frameInfo.image;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _fallbackNoiseImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    final themeAccent = AppTheme.accentPrimary;
    final canvasColor = AppTheme.paperBackground;

    final Color highlightColor = isDark
        ? const Color(0xFF38BDF8) // Electric cyan / platinum specular sheen
        : const Color(0xFFFFFFFF); // Pure crystalline white specular reflection

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background liquid metal motion canvas in isolated RepaintBoundary
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _FilmicMetalMeshPainter(
                  progress: _controller.value,
                  grainSeed: ((_controller.value * 480).floor() % 1000).toDouble(),
                  isDark: isDark,
                  baseColor: canvasColor,
                  accentColor: themeAccent,
                  highlightColor: highlightColor,
                  program: _program,
                  fallbackNoiseImage: _fallbackNoiseImage,
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
  final double grainSeed;
  final bool isDark;
  final Color baseColor;
  final Color accentColor;
  final Color highlightColor;
  final ui.FragmentProgram? program;
  final ui.Image? fallbackNoiseImage;

  _FilmicMetalMeshPainter({
    required this.progress,
    required this.grainSeed,
    required this.isDark,
    required this.baseColor,
    required this.accentColor,
    required this.highlightColor,
    required this.program,
    required this.fallbackNoiseImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final Rect rect = Offset.zero & size;

    if (program != null) {
      // 1. GPU Fragment Shader Execution (Apple Metal / GLSL pipeline)
      final ui.FragmentShader shader = program!.fragmentShader();
      shader.setFloat(0, size.width);
      shader.setFloat(1, size.height);
      shader.setFloat(2, progress * 24.0); // Elapsed wave time
      shader.setFloat(3, grainSeed);

      // uBaseColor (normalized 0.0 - 1.0)
      shader.setFloat(4, baseColor.r);
      shader.setFloat(5, baseColor.g);
      shader.setFloat(6, baseColor.b);
      shader.setFloat(7, baseColor.a);

      // uAccentColor (normalized 0.0 - 1.0)
      shader.setFloat(8, accentColor.r);
      shader.setFloat(9, accentColor.g);
      shader.setFloat(10, accentColor.b);
      shader.setFloat(11, accentColor.a);

      // uHighlightColor (normalized 0.0 - 1.0)
      shader.setFloat(12, highlightColor.r);
      shader.setFloat(13, highlightColor.g);
      shader.setFloat(14, highlightColor.b);
      shader.setFloat(15, highlightColor.a);

      // uIsDark
      shader.setFloat(16, isDark ? 1.0 : 0.0);

      final Paint shaderPaint = Paint()..shader = shader;
      canvas.drawRect(rect, shaderPaint);
      return;
    }

    // 2. Procedural Fallback (for headless test environments)
    final double t = progress * 2.0 * math.pi;

    // Base background gradient
    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF07090E),
                const Color(0xFF0B0F19),
                baseColor,
              ]
            : [
                const Color(0xFFFFFFFF),
                const Color(0xFFF8FAFC),
                baseColor,
              ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // Multi-octave wave ribbons
    final double waveY1 = size.height * (0.22 + 0.08 * math.sin(t));
    final double waveY2 = size.height * (0.38 + 0.09 * math.cos(t * 0.8));

    final Paint wave1Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.45, waveY1),
        size.width * 0.85,
        [
          accentColor.withValues(alpha: isDark ? 0.45 : 0.28),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(size.width * 0.45, waveY1), size.width * 0.85, wave1Paint);

    final Paint wave2Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.75, waveY2),
        size.width * 0.90,
        [
          isDark
              ? const Color(0xFF0C4A6E).withValues(alpha: 0.40)
              : const Color(0xFFBAE6FD).withValues(alpha: 0.35),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(size.width * 0.75, waveY2), size.width * 0.90, wave2Paint);

    // Horizon fade into base color
    final Paint horizonFadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.52, 0.78, 1.0],
        colors: [
          Colors.transparent,
          Colors.transparent,
          baseColor,
          baseColor,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, horizonFadePaint);

    // Film grain overlay
    if (fallbackNoiseImage != null) {
      final int frame = (progress * 480).floor();
      final double grainDx = ((frame * 37 + 17) % 128).toDouble();
      final double grainDy = ((frame * 59 + 29) % 128).toDouble();
      final Matrix4 grainMatrix = Matrix4.translationValues(grainDx, grainDy, 0.0);

      final Paint noisePaint = Paint()
        ..shader = ImageShader(
          fallbackNoiseImage!,
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
        oldDelegate.grainSeed != grainSeed ||
        oldDelegate.isDark != isDark ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.program != program ||
        oldDelegate.fallbackNoiseImage != fallbackNoiseImage;
  }
}
