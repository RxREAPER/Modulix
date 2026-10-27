import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';

/// Animated Atmospheric Filmic Motion Background.
///
/// Features:
/// 1. True GPU Fragment Shader executing continuous, seamless atmospheric wave flow
///    with zero breaks, zero pops, and zero loop seams.
/// 2. Soft, velvety, atmospheric aesthetic (less liquidy, less metallic).
/// 3. Rich, tactile, multi-scale 35mm analog film grain running at 24 FPS cinema cadence,
///    with dimmed, gentle contrast across the entire viewport.
/// 4. Top 35% Horizon Dissolve: atmospheric color wash smoothly dissolves into the clean
///    canvas color strictly by 35% viewport height, keeping lower tasks pristine and readable.
/// 5. Lifecycle-aware monotonic execution: automatically pauses ticker when app is backgrounded.
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
  late final Ticker _ticker;
  final ValueNotifier<double> _elapsedNotifier = ValueNotifier<double>(0.0);
  double _elapsedSeconds = 0.0;
  Duration _lastElapsed = Duration.zero;
  ui.FragmentProgram? _program;
  ui.Image? _fallbackNoiseImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Continuous monotonic ticker: flows smoothly forever without resetting back to 0
    _ticker = createTicker((elapsed) {
      if (_lastElapsed != Duration.zero) {
        final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
        if (dt > 0.0 && dt < 0.2) {
          _elapsedSeconds += dt;
        }
      }
      _lastElapsed = elapsed;
      _elapsedNotifier.value = _elapsedSeconds;
    })..start();

    _loadShader();
    _generateFallbackNoiseImage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastElapsed = Duration.zero;
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
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
      debugPrint('[FilmicMetalMeshBackground] Shader fallback active: $e\n$stack');
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
      final int alpha = 7 + random.nextInt(9); // Richer, dimmed analog film grain
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
    _ticker.dispose();
    _elapsedNotifier.dispose();
    _fallbackNoiseImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;
    final canvasColor = AppTheme.paperBackground;

    // Dynamically derive theme accent from current Modulix theme palette
    final preset = AppTheme.current.preset;
    final Color themeAccent;
    final Color highlightColor;

    if (preset == PalettePreset.slate) {
      // Basic Dark: Deep sapphire navy with luminous cyan crests
      themeAccent = const Color(0xFF1E40AF);
      highlightColor = const Color(0xFF38BDF8);
    } else if (preset == PalettePreset.paper) {
      // Basic Light: Crisp sky-slate mist with radiant white refraction
      themeAccent = const Color(0xFF60A5FA);
      highlightColor = const Color(0xFFFFFFFF);
    } else if (preset == PalettePreset.atomic_ice) {
      // The Catalyst / Atomic Ice: adapted from the other accent color (secondaryAccent) instead of atomic orange
      themeAccent = preset.secondaryAccent;
      highlightColor = const Color(0xFFFFFFFF);
    } else {
      // Bespoke Palettes (Forest Mint, Cosmic Mocha, etc.): Pure theme reactive
      themeAccent = AppTheme.accentPrimary;
      highlightColor = isDark
          ? AppTheme.current.secondaryAccent
          : const Color(0xFFFFFFFF);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background atmospheric motion canvas in isolated RepaintBoundary driven by ValueNotifier
        RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: _elapsedNotifier,
            builder: (context, elapsed, _) {
              // 24 FPS cinema cadence for film grain jitter
              final double grainSeed = (elapsed * 24.0).floor() % 1000.0;

              return CustomPaint(
                painter: _FilmicMetalMeshPainter(
                  elapsedSeconds: elapsed,
                  grainSeed: grainSeed,
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
  final double elapsedSeconds;
  final double grainSeed;
  final bool isDark;
  final Color baseColor;
  final Color accentColor;
  final Color highlightColor;
  final ui.FragmentProgram? program;
  final ui.Image? fallbackNoiseImage;

  _FilmicMetalMeshPainter({
    required this.elapsedSeconds,
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
      shader.setFloat(2, elapsedSeconds); // Continuous monotonic elapsed wave time (no seams!)
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
    final double t = elapsedSeconds * 0.8;

    // Base background canvas
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

    // Soft atmospheric orbs concentrated in upper 25%
    final double waveY1 = size.height * (0.12 + 0.05 * math.sin(t));
    final double waveY2 = size.height * (0.18 + 0.06 * math.cos(t * 0.7));

    final Paint wave1Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.40, waveY1),
        size.width * 0.75,
        [
          accentColor.withValues(alpha: isDark ? 0.32 : 0.20),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(size.width * 0.40, waveY1), size.width * 0.75, wave1Paint);

    final Paint wave2Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.70, waveY2),
        size.width * 0.80,
        [
          isDark
              ? const Color(0xFF0C4A6E).withValues(alpha: 0.28)
              : const Color(0xFFBAE6FD).withValues(alpha: 0.25),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(size.width * 0.70, waveY2), size.width * 0.80, wave2Paint);

    // Dynamic 60:40 Horizon fade into clean base color (breathing between 55% and 65%)
    final double breathingHorizon = 0.60 + 0.05 * math.sin(t * 0.40);
    final Paint horizonFadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, (breathingHorizon - 0.28).clamp(0.0, 1.0), breathingHorizon.clamp(0.0, 1.0), 1.0],
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
      final int frame = (elapsedSeconds * 24).floor();
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
    return oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.grainSeed != grainSeed ||
        oldDelegate.isDark != isDark ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.program != program ||
        oldDelegate.fallbackNoiseImage != fallbackNoiseImage;
  }
}
