import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/app.dart';
import 'package:modulix/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain 1: Startup Lifecycle & State Hydration Tests', () {
    test('StorageService gracefully loads AppState.empty when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      final state = storage.load();
      expect(state.onboardingDone, isFalse);
      expect(state.doctorName, 'Dr');
      expect(state.activeEdition, 'marrow_8');
      expect(state.palettePresetId, 'paper');
      expect(state.dayStartHour, 5);
    });

    test('StorageService automatically migrates legacy flowmd_flutter_app_state key', () async {
      final legacyJson = jsonEncode({
        'onboardingDone': true,
        'doctorName': 'Dr. Sharma',
        'activeEdition': 'marrow_6_5',
        'palettePresetId': 'sepia',
        'accentColorId': 'emerald',
      });

      SharedPreferences.setMockInitialValues({
        'flowmd_flutter_app_state': legacyJson,
      });
      final storage = await StorageService.init();

      final state = storage.load();
      expect(state.onboardingDone, isTrue);
      expect(state.doctorName, 'Dr. Sharma');
      expect(state.activeEdition, 'marrow_6_5');
      expect(state.palettePresetId, 'sepia');
      expect(state.accentColorId, 'emerald');

      // Now save and verify it saves to modern modulix_app_state key
      await storage.save(state);
      final rawModulix = storage.load();
      expect(rawModulix.doctorName, 'Dr. Sharma');
    });

    testWidgets('ModulixApp navigates directly to Home Desk when onboardingDone is true',
        (WidgetTester tester) async {
      final configuredJson = jsonEncode({
        'onboardingDone': true,
        'doctorName': 'Dr. Modulix',
        'activeEdition': 'marrow_8',
        'editions': {
          'marrow_8': {
            'plan': {
              'targetSubject': 'anatomy',
              'targetDate': '2026-12-31',
              'videosPerDay': 4,
            },
          },
        },
      });

      SharedPreferences.setMockInitialValues({
        'modulix_app_state': configuredJson,
      });
      await StorageService.init();

      await tester.pumpWidget(
        const ProviderScope(
          child: ModulixApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verifies HomeScreen is displayed directly
      expect(find.text('Modulix'), findsOneWidget);
      expect(find.text('DAILY COMPANION'), findsOneWidget);
    });
  });
}
