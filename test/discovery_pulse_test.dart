import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/widgets/discovery_pulse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiscoveryPulse Tests', () {
    testWidgets('renders child without pulse when already seen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'test_pulse_seen': true,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscoveryPulse(
              prefKey: 'test_pulse_seen',
              child: Text('Hidden Feature Action'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hidden Feature Action'), findsOneWidget);
      // Under DiscoveryPulse, no Stack should exist
      final pulseStack = find.descendant(
        of: find.byType(DiscoveryPulse),
        matching: find.byType(Stack),
      );
      expect(pulseStack, findsNothing);
    });

    testWidgets('renders breathing pulse when unseen', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscoveryPulse(
              prefKey: 'test_pulse_seen',
              child: Text('Hidden Feature Action'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      final pulseStack = find.descendant(
        of: find.byType(DiscoveryPulse),
        matching: find.byType(Stack),
      );
      expect(pulseStack, findsOneWidget);
    });

    testWidgets('pointer interaction dismisses pulse and writes to SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryPulse(
              prefKey: 'test_pulse_seen',
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      final pulseStackBefore = find.descendant(
        of: find.byType(DiscoveryPulse),
        matching: find.byType(Stack),
      );
      expect(pulseStackBefore, findsOneWidget);

      // Tap on the button
      await tester.tap(find.text('Tap Me').first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Check SharedPreferences was updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('test_pulse_seen'), isTrue);

      final pulseStackAfter = find.descendant(
        of: find.byType(DiscoveryPulse),
        matching: find.byType(Stack),
      );
      expect(pulseStackAfter, findsNothing);
    });
  });
}
