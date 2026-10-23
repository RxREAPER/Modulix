// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'package:flutter/material.dart';

/// Modulix Curated Unified Themes (Paired Canvas & Non-Glare Dim Accents)
enum PalettePreset {
  paper(
    id: 'paper',
    label: 'Paper & Ink',
    description: 'Warm tactile parchment with deep archival ink accent',
    isDark: false,
    scaffoldBackground: Color(0xFFF7F5EE),
    cardBackground: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFEFECE1),
    borderSubtle: Color(0xFFBDB39E),
    inkForeground: Color(0xFF1E1E1E),
    mutedText: Color(0xFF6B6860),
    accent: Color(0xFF384F66),
    secondaryAccent: Color(0xFF556F8A),
    tertiaryAccent: Color(0xFF788D7A),
    quaternaryAccent: Color(0xFF9E8E78),
    accentDark: Color(0xFF5B7A98),
    accentSubtle: Color(0xFFEBF1F6),
  ),
  slate(
    id: 'slate',
    label: 'Midnight Slate',
    description: 'Deep obsidian slate night with cool steel accent',
    isDark: true,
    scaffoldBackground: Color(0xFF090D14),
    cardBackground: Color(0xFF111722),
    surfaceSubtle: Color(0xFF182030),
    borderSubtle: Color(0xFF243044),
    inkForeground: Color(0xFFF1F5F9),
    mutedText: Color(0xFF94A3B8),
    accent: Color(0xFF5E81A2),
    secondaryAccent: Color(0xFF3B5773),
    tertiaryAccent: Color(0xFF4E9F9F),
    quaternaryAccent: Color(0xFF7E72B5),
    accentDark: Color(0xFF5E81A2),
    accentSubtle: Color(0xFF162536),
  ),
  atomic_ice(
    id: 'atomic_ice',
    label: 'Atomic Orange + Ice Cream Blue',
    description: 'Ice cream blue canvas with energetic atomic orange accent',
    isDark: false,
    scaffoldBackground: Color(0xFFC8F3FF),
    cardBackground: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFBAEBF8),
    borderSubtle: Color(0xFF5BAFCB),
    inkForeground: Color(0xFF102833),
    mutedText: Color(0xFF346074),
    accent: Color(0xFFFF5C23),
    secondaryAccent: Color(0xFF0288A6),
    tertiaryAccent: Color(0xFF1E8A5A),
    quaternaryAccent: Color(0xFF7A4EB2),
    accentDark: Color(0xFFFF5C23),
    accentSubtle: Color(0xFFFFE8DF),
  ),
  forest_mint(
    id: 'forest_mint',
    label: 'Forest Code + Mint Fog',
    description: 'Fresh mint fog canvas with deep forest code accent',
    isDark: false,
    scaffoldBackground: Color(0xFFE8FFF2),
    cardBackground: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFD2F5E1),
    borderSubtle: Color(0xFF6DBB92),
    inkForeground: Color(0xFF0A261B),
    mutedText: Color(0xFF275F46),
    accent: Color(0xFF075E46),
    secondaryAccent: Color(0xFF108161),
    tertiaryAccent: Color(0xFF2E6B8E),
    quaternaryAccent: Color(0xFF8B6432),
    accentDark: Color(0xFF075E46),
    accentSubtle: Color(0xFFD6F5E5),
  ),
  cosmic_mocha(
    id: 'cosmic_mocha',
    label: 'Cosmic Latte + Mocha Cream',
    description: 'Warm mocha cream canvas with cosmic latte accent',
    isDark: false,
    scaffoldBackground: Color(0xFFEBDCC6),
    cardBackground: Color(0xFFFAF5ED),
    surfaceSubtle: Color(0xFFDFCBB0),
    borderSubtle: Color(0xFFA58B6E),
    inkForeground: Color(0xFF281E15),
    mutedText: Color(0xFF65513F),
    accent: Color(0xFFB7A99A),
    secondaryAccent: Color(0xFF634633),
    tertiaryAccent: Color(0xFF7B523A),
    quaternaryAccent: Color(0xFF4A6B5C),
    accentDark: Color(0xFFB7A99A),
    accentSubtle: Color(0xFFF3ECE4),
  );

  final String id;
  final String label;
  final String description;
  final bool isDark;
  final Color scaffoldBackground;
  final Color cardBackground;
  final Color surfaceSubtle;
  final Color borderSubtle;
  final Color inkForeground;
  final Color mutedText;
  final Color accent;
  final Color secondaryAccent;
  final Color tertiaryAccent;
  final Color quaternaryAccent;
  final Color accentDark;
  final Color accentSubtle;

  const PalettePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.isDark,
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.surfaceSubtle,
    required this.borderSubtle,
    required this.inkForeground,
    required this.mutedText,
    required this.accent,
    required this.secondaryAccent,
    required this.tertiaryAccent,
    required this.quaternaryAccent,
    required this.accentDark,
    required this.accentSubtle,
  });

  // Backward compatibility getters
  static PalettePreset get paper_ink => paper;
  static PalettePreset get midnight_slate => slate;
  static PalettePreset get atomic_orange => atomic_ice;
  static PalettePreset get ice_cream_blue => atomic_ice;
  static PalettePreset get forest_code => forest_mint;
  static PalettePreset get mint_fog => forest_mint;
  static PalettePreset get cosmic_latte => cosmic_mocha;
  static PalettePreset get mocha_cream => cosmic_mocha;

  static PalettePreset fromId(String? id) {
    if (id == 'paper' || id == 'paper_ink' || id == 'classic_light') {
      return PalettePreset.paper;
    }
    if (id == 'slate' ||
        id == 'midnight_slate' ||
        id == 'pure_oled' ||
        id == 'obsidian' ||
        id == 'slate_midnight') {
      return PalettePreset.slate;
    }
    if (id == 'atomic_ice' ||
        id == 'atomic_orange' ||
        id == 'ice_cream_blue' ||
        id == 'nordic_frost' ||
        id == 'nordic' ||
        id == 'rose_dawn' ||
        id == 'rose') {
      return PalettePreset.atomic_ice;
    }
    if (id == 'forest_mint' ||
        id == 'forest_code' ||
        id == 'mint_fog' ||
        id == 'forest_night' ||
        id == 'forest') {
      return PalettePreset.forest_mint;
    }
    if (id == 'cosmic_mocha' ||
        id == 'cosmic_latte' ||
        id == 'mocha_cream' ||
        id == 'sepia_parchment' ||
        id == 'sepia') {
      return PalettePreset.cosmic_mocha;
    }
    return PalettePreset.values.firstWhere(
      (p) => p.id == id,
      orElse: () => PalettePreset.paper,
    );
  }
}

/// Dynamic Accent Pigments (tastefully dimmed, editorial low-chroma tones)
enum AccentPigment {
  cobalt(
    id: 'cobalt',
    label: 'Cobalt',
    color: Color(0xFF43658B),
    colorDark: Color(0xFF6B8FA8),
    colorMuted: Color(0xFFE8EEF4),
  ),
  emerald(
    id: 'emerald',
    label: 'Emerald',
    color: Color(0xFF38745B),
    colorDark: Color(0xFF5E987E),
    colorMuted: Color(0xFFE6F0EB),
  ),
  amethyst(
    id: 'amethyst',
    label: 'Amethyst',
    color: Color(0xFF67568C),
    colorDark: Color(0xFF8B79AC),
    colorMuted: Color(0xFFEFEBF6),
  ),
  amber(
    id: 'amber',
    label: 'Amber',
    color: Color(0xFF966728),
    colorDark: Color(0xFFB88C4E),
    colorMuted: Color(0xFFF7F0E4),
  ),
  coral(
    id: 'coral',
    label: 'Coral',
    color: Color(0xFF9B485A),
    colorDark: Color(0xFFBD6D7E),
    colorMuted: Color(0xFFF8E8EC),
  ),
  teal(
    id: 'teal',
    label: 'Teal',
    color: Color(0xFF347572),
    colorDark: Color(0xFF5A9693),
    colorMuted: Color(0xFFE5F1F0),
  );

  final String id;
  final String label;
  final Color color;
  final Color colorDark;
  final Color colorMuted;

  const AccentPigment({
    required this.id,
    required this.label,
    required this.color,
    required this.colorDark,
    required this.colorMuted,
  });

  static AccentPigment fromId(String? id) {
    if (id == 'indigo') return AccentPigment.cobalt;
    if (id == 'emerald') return AccentPigment.emerald;
    if (id == 'crimson') return AccentPigment.coral;
    if (id == 'amber') return AccentPigment.amber;
    if (id == 'violet') return AccentPigment.amethyst;
    if (id == 'cyan') return AccentPigment.teal;
    if (id == 'rose') return AccentPigment.coral;
    return AccentPigment.values.firstWhere(
      (a) => a.id == id,
      orElse: () => AccentPigment.cobalt,
    );
  }
}

/// ThemeExtension delivering dynamic colors to any widget context
class ModulixThemeExtension extends ThemeExtension<ModulixThemeExtension> {
  final PalettePreset preset;
  final AccentPigment accentPigment;
  final Color scaffoldBackground;
  final Color cardBackground;
  final Color surfaceSubtle;
  final Color borderSubtle;
  final Color inkForeground;
  final Color mutedText;
  final Color accent;
  final Color secondaryAccent;
  final Color tertiaryAccent;
  final Color quaternaryAccent;
  final Color accentSubtle;
  final bool isDark;

  const ModulixThemeExtension({
    required this.preset,
    required this.accentPigment,
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.surfaceSubtle,
    required this.borderSubtle,
    required this.inkForeground,
    required this.mutedText,
    required this.accent,
    required this.secondaryAccent,
    required this.tertiaryAccent,
    required this.quaternaryAccent,
    required this.accentSubtle,
    required this.isDark,
  });

  factory ModulixThemeExtension.from({
    required PalettePreset preset,
    AccentPigment? accent,
  }) {
    final activeAccent = accent != null
        ? (preset.isDark ? accent.colorDark : accent.color)
        : (preset.isDark ? preset.accentDark : preset.accent);
    final activeAccentSubtle = accent != null
        ? (preset.isDark
            ? activeAccent.withValues(alpha: 0.14)
            : accent.colorMuted)
        : preset.accentSubtle;

    return ModulixThemeExtension(
      preset: preset,
      accentPigment: accent ?? AccentPigment.fromId(preset.id),
      scaffoldBackground: preset.scaffoldBackground,
      cardBackground: preset.cardBackground,
      surfaceSubtle: preset.surfaceSubtle,
      borderSubtle: preset.borderSubtle,
      inkForeground: preset.inkForeground,
      mutedText: preset.mutedText,
      accent: activeAccent,
      secondaryAccent: preset.secondaryAccent,
      tertiaryAccent: preset.tertiaryAccent,
      quaternaryAccent: preset.quaternaryAccent,
      accentSubtle: activeAccentSubtle,
      isDark: preset.isDark,
    );
  }

  static const defaultPaper = ModulixThemeExtension(
    preset: PalettePreset.paper,
    accentPigment: AccentPigment.cobalt,
    scaffoldBackground: Color(0xFFF7F5EE),
    cardBackground: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFEFECE1),
    borderSubtle: Color(0xFFD6CEBC),
    inkForeground: Color(0xFF1E1E1E),
    mutedText: Color(0xFF6B6860),
    accent: Color(0xFF384F66),
    secondaryAccent: Color(0xFF556F8A),
    tertiaryAccent: Color(0xFF788D7A),
    quaternaryAccent: Color(0xFF9E8E78),
    accentSubtle: Color(0xFFEBF1F6),
    isDark: false,
  );

  @override
  ModulixThemeExtension copyWith({
    PalettePreset? preset,
    AccentPigment? accentPigment,
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? surfaceSubtle,
    Color? borderSubtle,
    Color? inkForeground,
    Color? mutedText,
    Color? accent,
    Color? secondaryAccent,
    Color? tertiaryAccent,
    Color? quaternaryAccent,
    Color? accentSubtle,
    bool? isDark,
  }) {
    return ModulixThemeExtension(
      preset: preset ?? this.preset,
      accentPigment: accentPigment ?? this.accentPigment,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      inkForeground: inkForeground ?? this.inkForeground,
      mutedText: mutedText ?? this.mutedText,
      accent: accent ?? this.accent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      tertiaryAccent: tertiaryAccent ?? this.tertiaryAccent,
      quaternaryAccent: quaternaryAccent ?? this.quaternaryAccent,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  ModulixThemeExtension lerp(
      ThemeExtension<ModulixThemeExtension>? other, double t) {
    if (other is! ModulixThemeExtension) return this;
    return ModulixThemeExtension(
      preset: t < 0.5 ? preset : other.preset,
      accentPigment: t < 0.5 ? accentPigment : other.accentPigment,
      scaffoldBackground:
          Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      inkForeground: Color.lerp(inkForeground, other.inkForeground, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondaryAccent:
          Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      tertiaryAccent:
          Color.lerp(tertiaryAccent, other.tertiaryAccent, t)!,
      quaternaryAccent:
          Color.lerp(quaternaryAccent, other.quaternaryAccent, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }

  /// Context-aware sketch card decoration matching active theme palette
  BoxDecoration sketchBox({
    Color? backgroundColor,
    double borderRadius = 18.0,
    double borderWidth = 1.4,
    Color? borderColor,
    double shadowOffset = 2.0,
    double blurRadius = 0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? borderSubtle,
        width: borderWidth,
      ),
      boxShadow: [
        if (shadowOffset > 0)
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : inkForeground.withValues(alpha: 0.12),
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: blurRadius,
          ),
      ],
    );
  }

  /// Clean subtle border card decoration
  BoxDecoration parchmentBox({
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 12.0,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? borderSubtle,
        width: borderWidth,
      ),
    );
  }

  /// Interactive accent pill decoration for segmented controls, filters, and chips
  BoxDecoration accentPillDecoration({
    required bool isSelected,
    double borderRadius = 12.0,
  }) {
    return BoxDecoration(
      color: isSelected ? accent : surfaceSubtle,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isSelected ? accent : borderSubtle,
        width: isSelected ? 1.4 : 1.0,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ]
          : null,
    );
  }

  /// High-contrast foreground text color on top of the accent color
  Color get onAccentColor =>
      accent.computeLuminance() > 0.45 ? const Color(0xFF1E1610) : Colors.white;

  /// Subtle elevation shadow matching palette brightness
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : inkForeground.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Extension for convenient access via `context.modulixTheme`
extension ModulixThemeContext on BuildContext {
  ModulixThemeExtension get modulixTheme =>
      Theme.of(this).extension<ModulixThemeExtension>() ??
      ModulixThemeExtension.defaultPaper;
}

/// ThemeData Factory
class ModulixThemeFactory {
  static ThemeData build({
    required PalettePreset preset,
    AccentPigment? accent,
  }) {
    final ext = ModulixThemeExtension.from(preset: preset, accent: accent);
    final brightness = preset.isDark ? Brightness.dark : Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: ext.accent,
      onPrimary: ext.accent.computeLuminance() > 0.45 ? const Color(0xFF1E1610) : Colors.white,
      secondary: ext.accent,
      onSecondary: ext.accent.computeLuminance() > 0.45 ? const Color(0xFF1E1610) : Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: ext.scaffoldBackground,
      onSurface: ext.inkForeground,
      surfaceContainerHighest: ext.cardBackground,
      outline: ext.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: ext.scaffoldBackground,
      extensions: [ext],
      cardTheme: CardThemeData(
        color: ext.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ext.borderSubtle, width: 1.2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ext.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ext.inkForeground,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: ext.inkForeground),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ext.cardBackground,
        indicatorColor: ext.accentSubtle,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ext.inkForeground,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: ext.accent, size: 24);
          }
          return IconThemeData(color: ext.mutedText, size: 22);
        }),
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ext.inkForeground,
          foregroundColor: ext.scaffoldBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ext.surfaceSubtle,
        selectedColor: ext.accent,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: ext.inkForeground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: ext.borderSubtle, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.borderSubtle, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.borderSubtle, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.accent, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ext.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}


/// Backward compatibility aliases for FlowMD tokens
typedef FlowMDThemeExtension = ModulixThemeExtension;
typedef FlowMDThemeFactory = ModulixThemeFactory;

extension FlowMDThemeLegacyContext on BuildContext {
  ModulixThemeExtension get flowMDTheme => modulixTheme;
}
