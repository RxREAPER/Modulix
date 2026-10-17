import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/animations/rolling_digit_text.dart';

void main() {
  testWidgets('RollingDigitText displays text and handles non-digits',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(
            text: '25:00',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );

    // Should find the colon
    expect(find.text(':'), findsOneWidget);
    expect(find.byType(RollingDigitText), findsOneWidget);
  });

  testWidgets('RollingDigitText rolls vertically when text updates',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(
            text: '12',
          ),
        ),
      ),
    );

    expect(find.byType(RollingDigitText), findsOneWidget);

    // Change to '13'
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(
            text: '13',
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.byType(RollingDigitText), findsOneWidget);
  });

  testWidgets('RollingDigitText.count factory works cleanly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RollingDigitText.count(
            count: 99,
          ),
        ),
      ),
    );

    expect(find.byType(RollingDigitText), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RollingDigitText.count(
            count: 100,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.byType(RollingDigitText), findsOneWidget);
  });

  testWidgets('RollingDigitText rolls 9 -> 0 rollover and subsequent 0 -> 1 without jump',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(text: '9'),
        ),
      ),
    );
    expect(find.text('9'), findsWidgets);

    // Roll to 0 (forward rollover to index 10)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(text: '0'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsWidgets);

    // Roll from 0 to 1
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(text: '1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('RollingDigitText handles backwards decrement 0 -> 9 and empty text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(text: '0'),
        ),
      ),
    );
    expect(find.text('0'), findsWidgets);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(text: '9'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pumpAndSettle();
    expect(find.text('9'), findsWidgets);

    // Empty text
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingDigitText(text: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RollingDigitText), findsOneWidget);
  });
}
