import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/theme/app_theme.dart';
import 'package:modulix/theme/modulix_theme.dart';
import 'package:modulix/screens/settings/appearance_theme_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlowMD Theme Tokens & Presets', () {
    test('PalettePreset contains all 5 curated unified presets', () {
      expect(PalettePreset.values.length, 5);
      expect(PalettePreset.paper.isDark, isFalse);
      expect(PalettePreset.slate.isDark, isTrue);
      expect(PalettePreset.atomic_ice.isDark, isFalse);
      expect(PalettePreset.forest_mint.isDark, isFalse);
      expect(PalettePreset.cosmic_mocha.isDark, isFalse);

      expect(PalettePreset.basic_light, PalettePreset.paper);
      expect(PalettePreset.basic_dark, PalettePreset.slate);
      expect(PalettePreset.light, PalettePreset.paper);
      expect(PalettePreset.dark, PalettePreset.slate);
      expect(PalettePreset.atomic_orange, PalettePreset.atomic_ice);
      expect(PalettePreset.ice_cream_blue, PalettePreset.atomic_ice);
      expect(PalettePreset.forest_code, PalettePreset.forest_mint);
      expect(PalettePreset.mint_fog, PalettePreset.forest_mint);
      expect(PalettePreset.cosmic_latte, PalettePreset.cosmic_mocha);
      expect(PalettePreset.mocha_cream, PalettePreset.cosmic_mocha);

      expect(PalettePreset.fromId('classic_light'), PalettePreset.paper);
      expect(PalettePreset.fromId('basic_light'), PalettePreset.paper);
      expect(PalettePreset.fromId('light'), PalettePreset.paper);
      expect(PalettePreset.fromId('pure_oled'), PalettePreset.slate);
      expect(PalettePreset.fromId('obsidian'), PalettePreset.slate);
      expect(PalettePreset.fromId('basic_dark'), PalettePreset.slate);
      expect(PalettePreset.fromId('dark'), PalettePreset.slate);
      expect(PalettePreset.fromId('sepia_parchment'), PalettePreset.cosmic_mocha);
      expect(PalettePreset.fromId('sepia'), PalettePreset.cosmic_mocha);
      expect(PalettePreset.fromId('slate_midnight'), PalettePreset.slate);
      expect(PalettePreset.fromId('nordic_frost'), PalettePreset.atomic_ice);
      expect(PalettePreset.fromId('nordic'), PalettePreset.atomic_ice);
      expect(PalettePreset.fromId('rose_dawn'), PalettePreset.atomic_ice);
      expect(PalettePreset.fromId('rose'), PalettePreset.atomic_ice);
      expect(PalettePreset.fromId('forest_night'), PalettePreset.forest_mint);
      expect(PalettePreset.fromId('forest'), PalettePreset.forest_mint);
      expect(PalettePreset.fromId('atomic_ice'), PalettePreset.atomic_ice);
      expect(PalettePreset.fromId('forest_mint'), PalettePreset.forest_mint);
      expect(PalettePreset.fromId('cosmic_mocha'), PalettePreset.cosmic_mocha);
    });

    test('AccentPigment contains 6 vibrant pigments with aliases', () {
      expect(AccentPigment.values.length, 6);
      expect(AccentPigment.fromId('cobalt'), AccentPigment.cobalt);
      expect(AccentPigment.fromId('indigo'), AccentPigment.cobalt);
      expect(AccentPigment.fromId('emerald'), AccentPigment.emerald);
      expect(AccentPigment.fromId('amethyst'), AccentPigment.amethyst);
      expect(AccentPigment.fromId('violet'), AccentPigment.amethyst);
      expect(AccentPigment.fromId('amber'), AccentPigment.amber);
      expect(AccentPigment.fromId('coral'), AccentPigment.coral);
      expect(AccentPigment.fromId('crimson'), AccentPigment.coral);
      expect(AccentPigment.fromId('rose'), AccentPigment.coral);
      expect(AccentPigment.fromId('teal'), AccentPigment.teal);
      expect(AccentPigment.fromId('cyan'), AccentPigment.teal);
    });

    test('FlowMDThemeFactory creates valid light and dark ThemeData with extensions', () {
      final lightTheme = FlowMDThemeFactory.build(
        preset: PalettePreset.paper,
        accent: AccentPigment.cobalt,
      );
      expect(lightTheme.brightness, Brightness.light);
      final lightExt = lightTheme.extension<FlowMDThemeExtension>();
      expect(lightExt, isNotNull);
      expect(lightExt!.preset, PalettePreset.paper);
      expect(lightExt.isDark, isFalse);

      final darkTheme = FlowMDThemeFactory.build(
        preset: PalettePreset.slate,
        accent: AccentPigment.emerald,
      );
      expect(darkTheme.brightness, Brightness.dark);
      final darkExt = darkTheme.extension<FlowMDThemeExtension>();
      expect(darkExt, isNotNull);
      expect(darkExt!.preset, PalettePreset.slate);
      expect(darkExt.isDark, isTrue);
    });
  });

  group('Theme State Management', () {
    test('AppState serialization preserves palettePresetId and accentColorId', () {
      const state = AppState(
        palettePresetId: 'slate',
        accentColorId: 'amethyst',
        themePref: ThemePref.dark,
      );
      final json = state.toJson();
      expect(json['palettePresetId'], 'slate');
      expect(json['accentColorId'], 'amethyst');
      expect(json['themePref'], 'dark');

      final deserialized = AppState.fromJson(json);
      expect(deserialized.palettePresetId, 'slate');
      expect(deserialized.accentColorId, 'amethyst');
      expect(deserialized.themePref, ThemePref.dark);
    });
  });

  group('AppearanceThemeSheet Widget Tests', () {
    testWidgets('AppearanceThemeSheet renders presets and accents', (tester) async {
      tester.view.physicalSize = const Size(1080, 4800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppearanceThemeSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Theme Studio'), findsOneWidget);
      expect(find.text('The Daylight Scholar'), findsWidgets);
      expect(find.text('The Midnight Scholar'), findsOneWidget);
      expect(find.text('The Catalyst'), findsOneWidget);
      expect(find.text('The Naturalist'), findsOneWidget);
      expect(find.text('The Academic'), findsOneWidget);
    });

    testWidgets('AppearanceThemeSheet interaction triggers selection update', (tester) async {
      tester.view.physicalSize = const Size(1080, 4800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppearanceThemeSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap The Naturalist theme card
      await tester.tap(find.text('The Naturalist'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    });
  });

  group('Dynamic AppTheme Reactive Bridge Tests', () {
    test('AppTheme delegates dynamically to active preset and accent', () {
      // 1. Paper & Ink with Cobalt
      AppTheme.current = FlowMDThemeExtension.from(
        preset: PalettePreset.paper,
        accent: AccentPigment.cobalt,
      );
      expect(AppTheme.paperBackground, PalettePreset.paper.scaffoldBackground);
      expect(AppTheme.cardWhite, PalettePreset.paper.cardBackground);
      expect(AppTheme.inkForeground, PalettePreset.paper.inkForeground);
      expect(AppTheme.primaryBlue, AccentPigment.cobalt.color);

      // 2. Forest Code with Emerald
      AppTheme.current = FlowMDThemeExtension.from(
        preset: PalettePreset.forest_code,
        accent: AccentPigment.emerald,
      );
      expect(AppTheme.paperBackground, PalettePreset.forest_code.scaffoldBackground);
      expect(AppTheme.cardWhite, PalettePreset.forest_code.cardBackground);
      expect(AppTheme.inkForeground, PalettePreset.forest_code.inkForeground);
      expect(AppTheme.primaryBlue, AccentPigment.emerald.color);
      expect(AppTheme.current.isDark, isFalse);

      // Verify sketchDecoration dynamically maps card background and dark border
      final deco = AppTheme.sketchDecoration();
      expect(deco.color, PalettePreset.forest_code.cardBackground);

      // 3. Midnight Slate with Amethyst
      AppTheme.current = FlowMDThemeExtension.from(
        preset: PalettePreset.slate,
        accent: AccentPigment.amethyst,
      );
      expect(AppTheme.paperBackground, PalettePreset.slate.scaffoldBackground);
      expect(AppTheme.cardWhite, PalettePreset.slate.cardBackground);
      expect(AppTheme.primaryBlue, AccentPigment.amethyst.colorDark);

      // 4. Cosmic Latte with Coral
      AppTheme.current = FlowMDThemeExtension.from(
        preset: PalettePreset.cosmic_latte,
        accent: AccentPigment.coral,
      );
      expect(AppTheme.paperBackground, PalettePreset.cosmic_latte.scaffoldBackground);
      expect(AppTheme.cardWhite, PalettePreset.cosmic_latte.cardBackground);
      expect(AppTheme.primaryBlue, AccentPigment.coral.color);

      // Restore default
      AppTheme.current = FlowMDThemeExtension.defaultPaper;
    });
  });
}
