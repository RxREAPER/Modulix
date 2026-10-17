import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/animations/animated_check_stroke.dart';

void main() {
  testWidgets('AnimatedCheckStroke animates checkmark and invokes callback',
      (tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedCheckStroke(
            checked: false,
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedCheckStroke), findsOneWidget);
    expect(completed, isFalse);

    // Switch to checked: true
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedCheckStroke(
            checked: true,
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    // Mid-animation check
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(AnimatedCheckStroke), findsOneWidget);

    // Settle to completion
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('AnimatedCheckStroke does not invoke onCompleted when unchecked mid-animation',
      (tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedCheckStroke(
            checked: false,
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    // Switch to checked: true
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedCheckStroke(
            checked: true,
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    // Mid-animation
    await tester.pump(const Duration(milliseconds: 100));
    expect(completed, isFalse);

    // Cancel: uncheck before completion
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedCheckStroke(
            checked: false,
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(completed, isFalse);
  });
}
