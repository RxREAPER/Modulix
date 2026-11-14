import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/app.dart';
import 'package:modulix/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final appStateJson = jsonEncode({
    'onboardingDone': true,
    'doctorName': 'Dr. Test',
    'activeEdition': 'marrow_8',
    'palettePresetId': 'paper',
    'accentColorId': 'royalBlue',
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'modulix_app_state': appStateJson,
      'seen_first_desk_intro': false,
    });
    await StorageService.init();
  });

  group('Home Desk Empty Tasks Target', () {
    testWidgets('renders empty desk prompt when no tasks are scheduled', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ModulixApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Add your first daily task or project...'), findsOneWidget);
      expect(find.text('No targets'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });
}
