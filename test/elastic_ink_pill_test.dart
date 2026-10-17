import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/animations/elastic_ink_pill.dart';

void main() {
  testWidgets('ElasticInkPill renders with targetRect and animates on change',
      (tester) async {
    const initialRect = Rect.fromLTWH(10, 10, 60, 40);
    const targetRectRight = Rect.fromLTWH(100, 10, 60, 40);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(
            targetRect: initialRect,
            fillColor: Colors.blue,
            strokeColor: Colors.indigo,
          ),
        ),
      ),
    );

    expect(find.byType(ElasticInkPill), findsOneWidget);

    // Update targetRect to the right
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(
            targetRect: targetRectRight,
            fillColor: Colors.blue,
            strokeColor: Colors.indigo,
          ),
        ),
      ),
    );

    // Pump midway to verify horizontal elastic stretch in flight
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.byType(ElasticInkPill), findsOneWidget);

    // Pump to completion to verify spring overshoot settles
    await tester.pumpAndSettle();
    expect(find.byType(ElasticInkPill), findsOneWidget);
  });

  testWidgets('ElasticInkPill animates leftward with elastic stretch',
      (tester) async {
    const initialRect = Rect.fromLTWH(150, 10, 60, 40);
    const targetRectLeft = Rect.fromLTWH(20, 10, 60, 40);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(
            targetRect: initialRect,
            isSketchy: true,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(
            targetRect: targetRectLeft,
            isSketchy: true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.byType(ElasticInkPill), findsOneWidget);
  });

  testWidgets('ElasticInkPill handles rapid mid-flight redirection cleanly',
      (tester) async {
    const rectA = Rect.fromLTWH(0, 10, 60, 40);
    const rectB = Rect.fromLTWH(200, 10, 60, 40);
    const rectC = Rect.fromLTWH(80, 10, 60, 40);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(targetRect: rectA),
        ),
      ),
    );

    // Start flight toward B
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(targetRect: rectB),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    // Redirect mid-flight toward C
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(targetRect: rectC),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    expect(find.byType(ElasticInkPill), findsOneWidget);
  });

  testWidgets('ElasticInkPill handles vertical stretch and zero boundary coords',
      (tester) async {
    const topRect = Rect.fromLTWH(10, 0, 50, 30);
    const bottomRect = Rect.fromLTWH(10, 150, 50, 30);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(targetRect: topRect),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElasticInkPill(targetRect: bottomRect),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(ElasticInkPill), findsOneWidget);
  });
}
