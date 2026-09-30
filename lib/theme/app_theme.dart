import 'package:flutter/material.dart';

class AppTheme {
  // Lovable Study Desk Design Tokens
  static const paperBackground = Color(0xFFFCFBF8);
  static const inkForeground = Color(0xFF1C1C1C);
  static const primaryBlue = Color(0xFF4F46E5);
  static const highlightCoral = Color(0xFFFFD1D6);
  static const highlightStrong = Color(0xFFFE5F55);
  static const mutedText = Color(0xFF71717A);
  static const sketchBorderColor = Color(0xFF1C1C1C);
  static const cardWhite = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE4E4E7);

  // Clean compatibility tokens for cards and sheets
  static const parchmentSurface = Color(0xFFF3F1EA);
  static const parchmentBorder = Color(0xFFE4E4E7);
  static const parchmentText = Color(0xFF4A463F);
  static const subtleText = Color(0xFFA1A1AA);
  static const vibrantBlue = Color(0xFF2563EB);
  static const accentEmerald = Color(0xFF059669);
  static const accentEmeraldBg = Color(0xFFECFDF5);
  static const accentAmber = Color(0xFFD97706);
  static const accentAmberBg = Color(0xFFFFFBEB);

  static BoxDecoration sketchDecoration({
    Color backgroundColor = cardWhite,
    double borderRadius = 18.0,
    double borderWidth = 1.8,
    Color borderColor = sketchBorderColor,
    double shadowOffset = 4.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        if (shadowOffset > 0)
          BoxShadow(
            color: const Color(0x181C1C1C),
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
      ],
    );
  }

  static BoxDecoration parchmentDecoration({
    Color backgroundColor = cardWhite,
    Color borderColor = borderLight,
    double borderRadius = 8.0,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }

  // Brand colors
  static const _primaryPurple = Color(0xFF6C3BAA);
  static const _accentRose = Color(0xFFF43F5E);
  static const _surfaceDark = Color(0xFF12111A);
  static const _cardDark = Color(0xFF1E1C2E);
  static const _surfaceLight = Color(0xFFFCFBF8); // Warm paper background
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
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardLight,
        indicatorColor: _primaryPurple.withOpacity(0.15),
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
        shadowColor: Colors.black.withOpacity(0.08),
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
        backgroundColor: _primaryPurple.withOpacity(0.08),
        selectedColor: _primaryPurple,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _primaryPurple.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
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
          side: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardDark,
        indicatorColor: const Color(0xFF9D71DF).withOpacity(0.2),
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
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF9D71DF), width: 2),
        ),
      ),
    );
  }
}
