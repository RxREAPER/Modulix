import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/widgets/in_situ_hint_pill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InSituHintPill Tests', () {
    testWidgets('renders SizedBox.shrink when preference key is already true', (tester) async {
      SharedPreferences.setMockInitialValues({
        'hint_swipe_video_seen': true,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InSituHintPill(
              prefKey: 'hint_swipe_video_seen',
              message: 'Swipe a video left to mark it complete',
              icon: Icons.swipe_left_alt_rounded,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Swipe a video left to mark it complete'), findsNothing);
      expect(find.byIcon(Icons.swipe_left_alt_rounded), findsNothing);
    });

    testWidgets('renders hint pill with animation when preference is not set', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InSituHintPill(
              prefKey: 'hint_swipe_video_seen',
              message: 'Swipe a video left to mark it complete',
              icon: Icons.swipe_left_alt_rounded,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Swipe a video left to mark it complete'), findsOneWidget);
      expect(find.byIcon(Icons.swipe_left_alt_rounded), findsOneWidget);
    });

    testWidgets('tapping hint pill dismisses it and writes true to SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InSituHintPill(
              prefKey: 'hint_behind_pace_seen',
              message: 'Tap Recalibrate to re-balance your daily video quota',
              icon: Icons.tune_rounded,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tap Recalibrate to re-balance your daily video quota'), findsOneWidget);

      // Tap on the pill to dismiss
      await tester.tap(find.text('Tap Recalibrate to re-balance your daily video quota'));
      await tester.pumpAndSettle();

      // Should be dismissed and no longer visible
      expect(find.text('Tap Recalibrate to re-balance your daily video quota'), findsNothing);

      // Check SharedPreferences was updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hint_behind_pace_seen'), isTrue);
    });
  });
}
