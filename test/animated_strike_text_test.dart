import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/animations/animated_strike_text.dart';

void main() {
  testWidgets('AnimatedStrikeText displays text and animates strikethrough',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedStrikeText(
            text: 'Biochemistry Lecture 1',
            isStruck: false,
          ),
        ),
      ),
    );

    expect(find.text('Biochemistry Lecture 1'), findsOneWidget);

    // Switch to struck: true
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedStrikeText(
            text: 'Biochemistry Lecture 1',
            isStruck: true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Biochemistry Lecture 1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Biochemistry Lecture 1'), findsOneWidget);

    // Switch back to struck: false
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedStrikeText(
            text: 'Biochemistry Lecture 1',
            isStruck: false,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Biochemistry Lecture 1'), findsOneWidget);
  });

  testWidgets('AnimatedStrikeText handles rapid toggle mid-flight and multiline text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: AnimatedStrikeText(
              text: 'Pathology Robbins General Systemic Overview',
              isStruck: false,
              maxLines: 3,
            ),
          ),
        ),
      ),
    );

    // Switch to struck: true
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: AnimatedStrikeText(
              text: 'Pathology Robbins General Systemic Overview',
              isStruck: true,
              maxLines: 3,
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 60));

    // Reverse mid-flight
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: AnimatedStrikeText(
              text: 'Pathology Robbins General Systemic Overview',
              isStruck: false,
              maxLines: 3,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Pathology Robbins General Systemic Overview'), findsOneWidget);
  });

  testWidgets('AnimatedStrikeText renders with TextOverflow.ellipsis and animates sweep',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: AnimatedStrikeText(
              text: 'Very Long Subject Title Exceeding Max Lines Ellipsis Boundary',
              isStruck: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(AnimatedStrikeText), findsOneWidget);
  });

  testWidgets('AnimatedStrikeText inside IntrinsicHeight and IntrinsicWidth renders without assertions',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 150,
                  child: IntrinsicWidth(
                    child: AnimatedStrikeText(
                      text: 'Intrinsic Measurement Video',
                      isStruck: true,
                    ),
                  ),
                ),
                VerticalDivider(width: 1),
                Text('Side Column'),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Intrinsic Measurement Video'), findsOneWidget);
    expect(find.text('Side Column'), findsOneWidget);
  });
}
