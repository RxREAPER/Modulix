import 'dart:convert';
import 'package:flutter/material.dart';
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

  group('Home Desk First-Time Bubble Prompt', () {
    testWidgets('renders compact 2-line clinical copy when seen_first_desk_intro is false', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ModulixApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Check for 2-line clinical copy
      expect(find.text('Isolate 3–4 high-yield objectives for today.'), findsOneWidget);
      expect(find.text('Streaks hold until 5:00 AM post-duty.'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('dismissing bubble prompt hides it', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ModulixApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Isolate 3–4 high-yield objectives for today.'), findsOneWidget);

      // Ensure visible in viewport and tap the dismiss (X) button
      await tester.ensureVisible(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      // The prompt should be dismissed
      expect(find.text('Isolate 3–4 high-yield objectives for today.'), findsNothing);
      expect(find.text("Today's desk is quiet"), findsOneWidget);
    });
  });
}
