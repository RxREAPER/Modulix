import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Professional UI Typography Engine for Modulix.
/// 
/// Follows Apple HIG and Linear/Things 3 design principles:
/// - Editorial Layer (EB Garamond Italic) for high-level screen anchors & section titles.
/// - Interface / Data Layer (Calibrated Sans) for functional cards, metrics, and micro-copy.
class AppTypography {
  // ── 1. Editorial / Marquee Headings (EB Garamond Italic) ──────────────

  /// Large top-level page titles (e.g., "Library", "Progress", "Settings")
  static TextStyle pageTitle({Color? color}) {
    return AppTheme.headingStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: color ?? AppTheme.inkForeground,
      letterSpacing: -0.4,
    );
  }

  /// Section marquee headings above cards (e.g., "Today's tasks", "Module Based Tasks")
  static TextStyle sectionHeading({Color? color, double fontSize = 21.0}) {
    return AppTheme.headingStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color ?? AppTheme.inkForeground,
      letterSpacing: -0.2,
    );
  }

  // ── 2. Card Content & Titles (Refined Modern Sans) ────────────────────

  /// Primary headline inside interactive cards (e.g., Subject Name, Hub Title)
  static TextStyle cardTitle({
    Color? color,
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppTheme.inkForeground,
      letterSpacing: -0.3,
      height: 1.25,
    );
  }

  /// Secondary subtitle or context line inside cards
  static TextStyle cardSubtitle({Color? color, double fontSize = 12.0}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color ?? AppTheme.mutedText,
      letterSpacing: 0.0,
      height: 1.35,
    );
  }

  /// Tertiary small metadata or counts (e.g., "84 vids · 47.7 hrs")
  static TextStyle cardMeta({Color? color, double fontSize = 11.0}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color ?? AppTheme.mutedText,
      letterSpacing: 0.1,
    );
  }

  // ── 3. Metrics, Numbers & Tabular Data ────────────────────────────────

  /// Prominent numeric values inside cards (e.g., streaks, totals, quotas)
  static TextStyle metricValue({
    Color? color,
    double fontSize = 20.0,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppTheme.inkForeground,
      letterSpacing: -0.4,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Context label accompanying a metric value (e.g., "DAILY TARGET", "DEADLINE")
  static TextStyle metricLabel({
    Color? color,
    double fontSize = 10.0,
    double letterSpacing = 0.5,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color ?? AppTheme.mutedText,
      letterSpacing: letterSpacing,
    );
  }

  // ── 4. Badges, Micro-Caps & Actions ───────────────────────────────────

  /// Status pills, completion badges, and category tags (e.g., "ON TRACK", "4%")
  static TextStyle microBadge({
    Color? color,
    double fontSize = 10.0,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = 0.6,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppTheme.inkForeground,
      letterSpacing: letterSpacing,
    );
  }

  /// Interactive link/action inside cards (e.g., "Open Page", "Open Queue")
  static TextStyle cardAction({
    Color? color,
    double fontSize = 11.5,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppTheme.inkForeground,
      letterSpacing: 0.1,
    );
  }
}
