import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modulix/theme/app_theme.dart';
import 'package:modulix/theme/modulix_theme.dart';
import 'package:modulix/screens/settings/preferences_sheet.dart';
import 'package:modulix/widgets/task_setup_sheet.dart';
import 'package:modulix/widgets/timer/ambient_sound_sheet.dart';
import 'package:modulix/widgets/timer/session_summary_card.dart';
import 'package:modulix/widgets/animations/apple_pressable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AppTheme.current = FlowMDThemeExtension.defaultPaper;
  });

  group('Cross-Theme Preset Verification', () {
    testWidgets('AppTheme dynamically applies across all 5 unified palette presets without exceptions', (tester) async {
      final presets = PalettePreset.values;

      for (final preset in presets) {
        AppTheme.current = FlowMDThemeExtension.from(
          preset: preset,
          accent: AccentPigment.cobalt,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: FlowMDThemeFactory.build(preset: preset, accent: AccentPigment.cobalt),
            home: Scaffold(
              backgroundColor: AppTheme.paperBackground,
              body: Center(
                child: Container(
                  color: AppTheme.cardWhite,
                  child: Text(
                    preset.label,
                    style: TextStyle(color: AppTheme.inkForeground),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(preset.label), findsOneWidget);
        expect(AppTheme.paperBackground, equals(preset.scaffoldBackground));
        expect(AppTheme.cardWhite, equals(preset.cardBackground));
        expect(AppTheme.inkForeground, equals(preset.inkForeground));
      }
    });
  });

  group('Tactile ApplePressable Component Integrations', () {
    testWidgets('PreferencesSheet renders with ApplePressable pill choice', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PreferencesSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Marrow Edition 8'), findsOneWidget);
      expect(find.text('Marrow Edition 6.5'), findsOneWidget);

      expect(find.byType(ApplePressable), findsWidgets);
    });

    testWidgets('TaskSetupSheet integrates ApplePressable on add button and palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskSetupSheet(
              currentTasks: const [],
              onConfirmTasks: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Plan Today's Desk"), findsOneWidget);
      expect(find.byType(ApplePressable), findsWidgets);

      await tester.tap(find.text('Video'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Q-BANK'));
      await tester.pumpAndSettle();
      expect(find.text('Q-Bank'), findsOneWidget);
    });

    testWidgets('AmbientSoundSheet uses IconData and ApplePressable (zero emojis)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmbientSoundSheet(
              activeSoundId: 'forest',
              onSelectSound: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ambient Sounds'), findsOneWidget);
      expect(find.text('Forest Canopy'), findsOneWidget);
      expect(find.text('Cozy Fireplace'), findsOneWidget);

      expect(find.byType(ApplePressable), findsWidgets);

      expect(find.byIcon(Icons.forest_rounded), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.byIcon(Icons.water_rounded), findsOneWidget);
    });

    testWidgets('SessionSummaryCard renders with ApplePressable buttons', (tester) async {
      bool analyticsTapped = false;
      bool startAnotherTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              subjectName: 'Pathology',
              topicTitle: 'Cell Injury & Necrosis',
              focusSecs: 1500,
              breakSecs: 300,
              modeName: 'Pomodoro',
              onViewAnalytics: () => analyticsTapped = true,
              onStartAnother: () => startAnotherTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session Finished!'), findsOneWidget);
      expect(find.text('PATHOLOGY'), findsOneWidget);
      expect(find.text('View Analytics'), findsOneWidget);
      expect(find.text('Start Another'), findsOneWidget);

      await tester.tap(find.text('View Analytics'));
      await tester.pumpAndSettle();
      expect(analyticsTapped, isTrue);

      await tester.tap(find.text('Start Another'));
      await tester.pumpAndSettle();
      expect(startAnotherTapped, isTrue);
    });
  });

  group('Exhaustive Theme Permutation & Extreme Contrast Switching', () {
    testWidgets('All 5 Palette Presets x 6 Accent Pigments build and switch dynamically without rendering exceptions', (tester) async {
      final presets = PalettePreset.values;
      final accents = AccentPigment.values;

      expect(presets.length, equals(5));
      expect(accents.length, equals(6));

      // Test all 30 combinations
      for (final preset in presets) {
        for (final accent in accents) {
          final themeData = FlowMDThemeFactory.build(preset: preset, accent: accent);
          final extension = FlowMDThemeExtension.from(preset: preset, accent: accent);
          AppTheme.current = extension;

          expect(themeData.brightness, equals(preset.isDark ? Brightness.dark : Brightness.light));
          final expectedAccent = preset.isDark ? accent.colorDark : accent.color;
          expect(AppTheme.accentPrimary, equals(expectedAccent));
          expect(AppTheme.paperBackground, equals(preset.scaffoldBackground));
          expect(AppTheme.cardWhite, equals(preset.cardBackground));
          expect(AppTheme.inkForeground, equals(preset.inkForeground));
        }
      }

      // Rapid extreme contrast switches across presets
      final extremeTransitions = [
        (PalettePreset.paper, AccentPigment.cobalt),
        (PalettePreset.slate, AccentPigment.coral),
        (PalettePreset.atomic_ice, AccentPigment.teal),
        (PalettePreset.forest_mint, AccentPigment.amber),
        (PalettePreset.cosmic_mocha, AccentPigment.emerald),
      ];

      // Confirm legacy string aliases resolve accurately
      expect(AccentPigment.fromId('crimson'), equals(AccentPigment.coral));
      expect(AccentPigment.fromId('violet'), equals(AccentPigment.amethyst));
      expect(AccentPigment.fromId('indigo'), equals(AccentPigment.cobalt));
      expect(AccentPigment.fromId('cyan'), equals(AccentPigment.teal));

      for (final pair in extremeTransitions) {
        final preset = pair.$1;
        final accent = pair.$2;
        AppTheme.current = FlowMDThemeExtension.from(preset: preset, accent: accent);

        await tester.pumpWidget(
          MaterialApp(
            theme: FlowMDThemeFactory.build(preset: preset, accent: accent),
            home: Scaffold(
              backgroundColor: AppTheme.paperBackground,
              body: Center(
                child: ApplePressable(
                  onTap: () {},
                  child: Container(
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: AppTheme.cardWhite,
                      borderRadius: 16,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '${preset.label} + ${accent.label}',
                      style: TextStyle(
                        color: AppTheme.inkForeground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // Mid-transition pump
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(find.text('${preset.label} + ${accent.label}'), findsOneWidget);
        final expectedAccent = preset.isDark ? accent.colorDark : accent.color;
        expect(AppTheme.accentPrimary, equals(expectedAccent));
        expect(AppTheme.paperBackground, equals(preset.scaffoldBackground));
      }
    });
  });
}
