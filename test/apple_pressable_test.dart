import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/animations/apple_pressable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApplePressable Tests', () {
    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplePressable(
              onTap: () {},
              child: const Text('Press Me'),
            ),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);
    });

    testWidgets('scales down on pointer down and triggers onTap on pointer up', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ApplePressable(
                pressedScale: 0.90,
                pressedOpacity: 0.85,
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('Button'),
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.text('Button'));
      final transformFinder = find.descendant(
        of: find.byType(ApplePressable),
        matching: find.byType(Transform),
      );

      // Initial state: scale is 1.0
      Transform transform = tester.widget(transformFinder);
      expect(transform.transform.entry(0, 0), closeTo(1.0, 0.01));

      // Pointer down
      final gesture = await tester.startGesture(center);
      await tester.pump(); // Frame 0: establish ticker start
      await tester.pump(const Duration(milliseconds: 100)); // Frame 1: advance 100ms

      // Scale should be compressed
      transform = tester.widget(transformFinder);
      expect(transform.transform.entry(0, 0), closeTo(0.90, 0.02));
      expect(tapped, isFalse);

      // Pointer up
      await gesture.up();
      await tester.pumpAndSettle();

      // Tap action should have fired
      expect(tapped, isTrue);

      // Scale should spring back to 1.0
      transform = tester.widget(transformFinder);
      expect(transform.transform.entry(0, 0), closeTo(1.0, 0.01));
    });

    testWidgets('cancelling gesture springs back without calling onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ApplePressable(
                pressedScale: 0.92,
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('Cancel Button'),
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.text('Cancel Button'));
      final cancelTransformFinder = find.descendant(
        of: find.byType(ApplePressable),
        matching: find.byType(Transform),
      );

      // Pointer down
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      Transform transform = tester.widget(cancelTransformFinder);
      expect(transform.transform.entry(0, 0), closeTo(0.92, 0.02));

      // Cancel gesture
      await gesture.cancel();
      await tester.pumpAndSettle();

      // onTap should NOT be called
      expect(tapped, isFalse);

      // Scale should return to 1.0
      transform = tester.widget(cancelTransformFinder);
      expect(transform.transform.entry(0, 0), closeTo(1.0, 0.01));
    });

    testWidgets('long press triggers onLongPress callback', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ApplePressable(
                onLongPress: () => longPressed = true,
                child: const Text('Long Press Me'),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Long Press Me'));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    testWidgets('renders direct child without gesture detector when callbacks are null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApplePressable(
              child: Text('Disabled'),
            ),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
