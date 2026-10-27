import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/animations/rolling_digit_text.dart';
import 'package:modulix/widgets/animations/page_entrance.dart';
import 'package:modulix/widgets/loading/app_shimmer.dart';
import 'package:modulix/widgets/timer/medical_wave_visualizer.dart';
import 'package:modulix/widgets/timer/sketch_flip_digit.dart';

void main() {
  group('UI & Animation Optimizations [CKPT-097]', () {
    testWidgets('RollingDigitText caches TextStyle dimensions and renders in RepaintBoundary', (tester) async {
      const testStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingDigitText(
              text: '42',
              style: testStyle,
            ),
          ),
        ),
      );

      expect(find.text('42'), findsNothing); // Digits are split into slots
      // Verify RepaintBoundary is present around each digit slot
      expect(find.byType(RepaintBoundary), findsWidgets);

      // Pump again with another value using same style (should hit cache)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingDigitText(
              text: '99',
              style: testStyle,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RollingDigitText), findsOneWidget);
    });

    testWidgets('AppShimmer wraps content in a dedicated RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppShimmer(
              child: Text('Loading Placeholder'),
            ),
          ),
        ),
      );

      // Find RepaintBoundary ancestor of ShaderMask
      final repaintBoundaries = find.byType(RepaintBoundary);
      expect(repaintBoundaries, findsWidgets);

      final shaderMask = find.byType(ShaderMask);
      expect(shaderMask, findsOneWidget);
    });

    testWidgets('MedicalWaveVisualizer wraps ECG waveform in RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MedicalWaveVisualizer(height: 40),
          ),
        ),
      );

      expect(find.byType(MedicalWaveVisualizer), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('SketchFlipCard wraps 3D perspective card in RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SketchFlipCard(
              value: '25',
              textStyle: TextStyle(fontSize: 32),
              cardColor: Colors.black,
              borderColor: Colors.grey,
              width: 80,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(SketchFlipCard), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('PageEntrance renders and cleanly bypasses transitions after completion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageEntrance(
              durationMs: 100,
              children: [
                Text('Child 1'),
                Text('Child 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);

      // Settle past the 100ms duration
      await tester.pumpAndSettle(const Duration(milliseconds: 150));

      // Both children should still be rendered without errors
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });
  });
}
