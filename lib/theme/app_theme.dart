import 'package:flutter/material.dart';
import 'modulix_theme.dart';

export 'app_typography.dart';

class AppTheme {
  /// Live theme extension representing the active theme and palette
  static ModulixThemeExtension current = ModulixThemeExtension.defaultPaper;

  // Lovable Study Desk Design Tokens
  static Color get paperBackground => current.scaffoldBackground;
  static Color get inkForeground => current.inkForeground;
  static Color get accentPrimary => current.accent;
  static Color get accentSecondary => current.secondaryAccent;
  static Color get accentTertiary => current.tertiaryAccent;
  static Color get accentQuaternary => current.quaternaryAccent;
  static Color get accentSubtle => current.accentSubtle;
  static Color get onAccent =>
      current.accent.computeLuminance() > 0.45 ? const Color(0xFF1E1610) : Colors.white;
  static Color get primaryBlue => current.accent;
  static Color get highlightCoral => current.accentSubtle;
  static Color get highlightStrong => current.accent;
  static Color get mutedText => current.mutedText;
  static Color get sketchBorderColor => current.borderSubtle;
  static Color get cardWhite => current.cardBackground;
  static Color get cardBackground => current.cardBackground;
  static Color get borderLight => current.borderSubtle;
  static Color get cardBorder => current.borderSubtle;
  static Color get scaffoldBg => current.scaffoldBackground;

  // Clean compatibility tokens for cards and sheets
  static Color get parchmentSurface => current.surfaceSubtle;
  static Color get parchmentBorder => current.borderSubtle;
  static Color get parchmentText => current.inkForeground;
  static Color get subtleText => current.mutedText;
  static Color get vibrantBlue => current.accent;

  static BoxDecoration accentPillDecoration({
    required bool selected,
    double borderRadius = 12.0,
  }) =>
      current.accentPillDecoration(
        isSelected: selected,
        borderRadius: borderRadius,
      );
  static Color get accentEmerald =>
      current.isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  static Color get accentEmeraldBg => current.surfaceSubtle;
  static Color get accentAmber =>
      current.isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color get accentAmberBg => current.surfaceSubtle;

  static BoxDecoration sketchDecoration({
    Color? backgroundColor,
    double borderRadius = 18.0,
    double borderWidth = 1.4,
    Color? borderColor,
    double shadowOffset = 2.0,
  }) {
    final effectiveBg = (backgroundColor == null ||
            backgroundColor == const Color(0xFFFFFFFF))
        ? current.cardBackground
        : backgroundColor;
    final effectiveBorder = borderColor ?? current.borderSubtle;

    return BoxDecoration(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: effectiveBorder, width: borderWidth),
      boxShadow: [
        if (shadowOffset > 0)
          BoxShadow(
            color: current.isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0x0A000000),
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 2,
          ),
      ],
    );
  }

  static BoxDecoration parchmentDecoration({
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 8.0,
    double borderWidth = 1.0,
  }) {
    final effectiveBg = (backgroundColor == null ||
            backgroundColor == const Color(0xFFFFFFFF))
        ? current.cardBackground
        : backgroundColor;
    final effectiveBorder = borderColor ?? current.borderSubtle;

    return BoxDecoration(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: effectiveBorder, width: borderWidth),
    );
  }

  /// Official EB Garamond Italic typography for all screen headings, unit titles, and subjects
  static TextStyle headingStyle({
    double fontSize = 24.0,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'EBGaramond',
      fontStyle: FontStyle.italic,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? inkForeground,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Brand colors
  static const _primaryPurple = Color(0xFF007AFF);
  static const _accentRose = Color(0xFFF43F5E);
  static const _surfaceDark = Color(0xFF0B0F19);
  static const _cardDark = Color(0xFF161B26);
  static const _surfaceLight = Color(0xFFF8F9FA); // Clean basic light background
  static const _cardLight = Color(0xFFFFFFFF);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryPurple,
      brightness: Brightness.light,
      primary: _primaryPurple,
      secondary: _accentRose,
      surface: _surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'SF Pro Display', // falls back to system sans-serif
      scaffoldBackgroundColor: _surfaceLight,
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontFamily: 'EBGaramond',
          fontStyle: FontStyle.italic,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardLight,
        indicatorColor: _primaryPurple.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryPurple, size: 24);
          }
          return IconThemeData(color: Colors.grey.shade500, size: 22);
        }),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _primaryPurple.withValues(alpha: 0.08),
        selectedColor: _primaryPurple,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _primaryPurple.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryPurple, width: 2),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryPurple,
      brightness: Brightness.dark,
      primary: const Color(0xFF9D71DF),
      secondary: _accentRose,
      surface: _surfaceDark,
      surfaceContainerHighest: _cardDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: _surfaceDark,
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontFamily: 'EBGaramond',
          fontStyle: FontStyle.italic,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardDark,
        indicatorColor: const Color(0xFF9D71DF).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF9D71DF), size: 24);
          }
          return const IconThemeData(color: Color(0xFF6B6B7B), size: 22);
        }),
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF9D71DF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF9D71DF), width: 2),
        ),
      ),
    );
  }
}
