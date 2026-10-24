import 'package:flutter/material.dart';

/// Standalone design system for the Tasks Hub section.
/// This theme is **completely isolated** from the global Modulix [AppTheme]
/// and [ModulixThemeExtension]. It always renders a clean, pure-white,
/// minimalist surface regardless of the active Modulix palette preset.
class TasksTheme {
  TasksTheme._();

  // ─── Backgrounds ─────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9FAFB);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ─── Borders & Dividers ──────────────────────────────────────────
  static const Color divider = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);

  // ─── Typography ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ─── Accent (Fixed tomato-red, not affected by theme studio) ─────
  static const Color accent = Color(0xFFEF4444);
  static const Color accentLight = Color(0xFFFEE2E2);
  static const Color accentMuted = Color(0xFFFCA5A5);

  // ─── Priority colours ─────────────────────────────────────────────
  static const Color priorityP1 = Color(0xFFEF4444);
  static const Color priorityP2 = Color(0xFFF97316);
  static const Color priorityP3 = Color(0xFF3B82F6);
  static const Color priorityP4 = Color(0xFF9CA3AF);

  // ─── Geometry ────────────────────────────────────────────────────
  static const double radiusCard = 16.0;
  static const double radiusInput = 12.0;
  static const double radiusChip = 8.0;
  static const double radiusButton = 14.0;

  // ─── Spacing ─────────────────────────────────────────────────────
  static const double pagePadding = 20.0;
  static const double sectionSpacing = 28.0;

  // ─── Elevation / Shadows ─────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF111827).withValues(alpha: 0.04),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
      ];

  static List<BoxShadow> get sheetShadow => [
        BoxShadow(
          color: const Color(0xFF111827).withValues(alpha: 0.10),
          offset: const Offset(0, -4),
          blurRadius: 20,
        ),
      ];

  // ─── TextStyles ──────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textTertiary,
    letterSpacing: 0.6,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle labelAccent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: accent,
    height: 1.4,
  );

  static const TextStyle metaChip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.1,
    height: 1.3,
  );

  // ─── MaterialApp ThemeData for the subtree ───────────────────────
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          brightness: Brightness.light,
          primary: accent,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: Colors.white,
          surface: background,
          onSurface: textPrimary,
          error: priorityP1,
        ),
        scaffoldBackgroundColor: background,
        dividerColor: divider,
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: CircleBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(fontSize: 15, color: textTertiary),
        ),
      );

  // ─── Priority helpers ─────────────────────────────────────────────
  static Color priorityColor(int level) => switch (level) {
        1 => priorityP1,
        2 => priorityP2,
        3 => priorityP3,
        _ => priorityP4,
      };

  static String priorityLabel(int level) => switch (level) {
        1 => 'Urgent',
        2 => 'High',
        3 => 'Medium',
        _ => 'Low',
      };
}
