import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/syllabus_provider.dart';
import 'package:modulix/screens/analytics/analytics_screen.dart';
import 'package:modulix/theme/app_theme.dart';
import 'package:modulix/theme/modulix_theme.dart';

class _FakeAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _FakeAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testState = AppState(
    activeEdition: 'marrow_8',
    editions: {
      'marrow_8': EditionState(
        plan: StudyPlan(
          targetSubject: 'anat',
          targetDate: '2026-12-31T00:00:00.000Z',
          videosPerDay: 2,
        ),
      ),
    },
  );

  group('Dimmed Accent Pigments Verification', () {
    test('AccentPigments have dimmed editorial low-chroma tones', () {
      // Cobalt
      expect(AccentPigment.cobalt.color, const Color(0xFF43658B));
      expect(AccentPigment.cobalt.colorDark, const Color(0xFF6B8FA8));

      // Emerald
      expect(AccentPigment.emerald.color, const Color(0xFF38745B));
      expect(AccentPigment.emerald.colorDark, const Color(0xFF5E987E));

      // Amethyst
      expect(AccentPigment.amethyst.color, const Color(0xFF67568C));
      expect(AccentPigment.amethyst.colorDark, const Color(0xFF8B79AC));

      // Amber
      expect(AccentPigment.amber.color, const Color(0xFF966728));
      expect(AccentPigment.amber.colorDark, const Color(0xFFB88C4E));

      // Coral
      expect(AccentPigment.coral.color, const Color(0xFF9B485A));
      expect(AccentPigment.coral.colorDark, const Color(0xFFBD6D7E));

      // Teal
      expect(AccentPigment.teal.color, const Color(0xFF347572));
      expect(AccentPigment.teal.colorDark, const Color(0xFF5A9693));
    });
  });

  group('Analytics Streak & Hub Cards Verification', () {
    testWidgets('Study Streak retains flame icon and Best Streak retains gold medal icon',
        (WidgetTester tester) async {
      AppTheme.current = FlowMDThemeExtension.from(
        preset: PalettePreset.paper,
        accent: AccentPigment.teal,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _FakeAppStateNotifier(testState)),
            activeSyllabusProvider.overrideWithValue(const AsyncValue.data([])),
          ],
          child: MaterialApp(
            theme: FlowMDThemeFactory.build(preset: PalettePreset.paper, accent: AccentPigment.teal),
            home: const Scaffold(
              body: AnalyticsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Study Streak flame icon
      final flameIcon = tester.widget<Icon>(find.byIcon(Icons.local_fire_department_rounded));
      expect(flameIcon.color, const Color(0xFFF97316),
          reason: 'Study streak must retain its authentic flame orange icon color');

      // Verify Best Streak medal icon
      final medalIcon = tester.widget<Icon>(find.byIcon(Icons.military_tech_rounded));
      expect(medalIcon.color, const Color(0xFFEAB308));

      // Verify "View Details" text is present and does not use loud accent color
      final viewDetailsTexts = find.text('View Details');
      expect(viewDetailsTexts, findsWidgets);

      final firstViewDetails = tester.widget<Text>(viewDetailsTexts.first);
      expect(firstViewDetails.style?.color, isNot(AccentPigment.teal.color),
          reason: 'View Details should NOT use accent color');
      expect(firstViewDetails.style?.color, AppTheme.mutedText,
          reason: 'View Details in light mode should use muted text');

      // Verify button capsules (e.g. 0m or 0/0) have native ink text color, not accent color
      final badgeCapsules = find.text('0m');
      expect(badgeCapsules, findsWidgets);
      final badgeText = tester.widget<Text>(badgeCapsules.first);
      expect(badgeText.style?.color, AppTheme.inkForeground,
          reason: 'Badge capsule text must use native inkForeground color, not accent');
    });

    testWidgets('Dark mode renders subtle highlight on View Details without accent color',
        (WidgetTester tester) async {
      AppTheme.current = FlowMDThemeExtension.from(
        preset: PalettePreset.slate,
        accent: AccentPigment.cobalt,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _FakeAppStateNotifier(testState)),
            activeSyllabusProvider.overrideWithValue(const AsyncValue.data([])),
          ],
          child: MaterialApp(
            theme: FlowMDThemeFactory.build(preset: PalettePreset.slate, accent: AccentPigment.cobalt),
            home: const Scaffold(
              body: AnalyticsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final flameIcon = tester.widget<Icon>(find.byIcon(Icons.local_fire_department_rounded));
      expect(flameIcon.color, const Color(0xFFF97316),
          reason: 'Study streak flame icon must stay flame orange even in obsidian dark mode');

      final viewDetailsTexts = find.text('View Details');
      expect(viewDetailsTexts, findsWidgets);
      final firstViewDetails = tester.widget<Text>(viewDetailsTexts.first);
      expect(firstViewDetails.style?.color, isNot(AccentPigment.cobalt.colorDark),
          reason: 'View Details should NOT use accent color in dark mode');
      expect(firstViewDetails.style?.color, Colors.white.withValues(alpha: 0.88),
          reason: 'View Details in dark mode should use crisp light highlight text');
    });
  });
}
