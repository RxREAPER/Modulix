import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Style variants for the Modulix brand logo.
enum ModulixLogoStyle {
  /// Pure high-resolution monogram with transparent background.
  /// Automatically tint-aware and reactive to theme brightness.
  monogram,

  /// Archival luxury squircle coaster with natural paper grain.
  /// Ideal for About dialogues, onboarding splash, and settings profile headers.
  coaster,
}

/// The official Modulix "Mx" brand insignia widget.
///
/// Features the classical Roman serif "Mx" monogram with calligraphic
/// interlocking ligature and fine engraved intaglio styling.
class ModulixLogo extends StatelessWidget {
  /// Size of the logo (width and height will be equal).
  final double size;

  /// Optional custom tint color. If null, dynamically conforms to
  /// [AppTheme.inkForeground] or palette brightness.
  final Color? color;

  /// The visual style of the logo. Defaults to [ModulixLogoStyle.monogram].
  final ModulixLogoStyle style;

  /// Optional tap handler.
  final VoidCallback? onTap;

  const ModulixLogo({
    super.key,
    this.size = 28.0,
    this.color,
    this.style = ModulixLogoStyle.monogram,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (style == ModulixLogoStyle.coaster) {
      return _buildCoaster(context);
    }
    return _buildMonogram(context);
  }

  Widget _buildMonogram(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || AppTheme.current.isDark;
    final effectiveColor = color ?? AppTheme.inkForeground;
    
    // Choose the base raster cut optimized for dark or light backgrounds
    final assetPath = isDark
        ? 'assets/icons/brand/modulix_monogram_white.png'
        : 'assets/icons/brand/modulix_monogram_dark.png';

    Widget image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      color: color != null ? effectiveColor : null,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      errorBuilder: (context, error, stackTrace) => _fallbackText(effectiveColor),
    );

    if (onTap != null) {
      image = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: image,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: image),
    );
  }

  Widget _buildCoaster(BuildContext context) {
    Widget image = Image.asset(
      'assets/icons/brand/modulix_app_icon_squircle.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => _fallbackText(AppTheme.inkForeground),
    );

    if (onTap != null) {
      image = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: image,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: image),
    );
  }

  Widget _fallbackText(Color fallbackColor) {
    return Text(
      'Mx',
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: size * 0.7,
        fontWeight: FontWeight.w800,
        color: fallbackColor,
      ),
    );
  }
}
