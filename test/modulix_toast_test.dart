import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/feedback/modulix_toast.dart';

void main() {
  testWidgets('ModulixToast displays message and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                ModulixToast.showSuccess(
                  context,
                  message: 'Focus session completed',
                  title: 'Well Done',
                );
              },
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Focus session completed'), findsOneWidget);
    expect(find.text('Well Done'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Test dismiss
    ModulixToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Focus session completed'), findsNothing);
  });

  testWidgets('ModulixToast undo action callback triggers properly', (WidgetTester tester) async {
    bool undone = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                ModulixToast.showUndo(
                  context,
                  message: 'Removed "Cardiology"',
                  onUndo: () {
                    undone = true;
                  },
                );
              },
              child: const Text('Trigger Undo Toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger Undo Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Removed "Cardiology"'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(undone, isTrue);
    expect(find.text('Removed "Cardiology"'), findsNothing);
  });
}
