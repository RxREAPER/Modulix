import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/theme/app_theme.dart';
import 'package:modulix/theme/modulix_theme.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/widgets/curriculum/subject_sketch_icon.dart';
import 'package:modulix/widgets/curriculum/curriculum_search_bar.dart';
import 'package:modulix/widgets/curriculum/module_timeline.dart';

void main() {
  setUp(() {
    AppTheme.current = FlowMDThemeExtension.from(
      preset: PalettePreset.slate,
      accent: AccentPigment.teal,
    );
  });

  tearDown(() {
    AppTheme.current = FlowMDThemeExtension.defaultPaper;
  });

  group('Pharmacology Icon Dark Mode Tint Verification', () {
    testWidgets('Pharmacology icon is tinted with orange accent on dark modes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SubjectSketchIcon(
              subjectId: 'pharmacology',
              size: 28,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      // Confirmed: tinted with orange accent (0xFFF97316) instead of remaining invisible black
      expect(imageWidget.color, equals(const Color(0xFFF97316)));
    });
  });

  group('Search Bar Border & Accent Integration Verification', () {
    testWidgets('Search bar does not use black sketch border and illuminates with accent', (tester) async {
      const sampleSubject = Subject(
        id: 'anatomy',
        name: 'Anatomy',
        displayName: 'Anatomy',
        accent: Color(0xFF3B82F6),
        chapters: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CurriculumSearchBar(subjects: [sampleSubject]),
          ),
        ),
      );

      // Find the search bar AnimatedContainer
      final containerFinder = find.byType(AnimatedContainer);
      expect(containerFinder, findsOneWidget);

      final containerWidget = tester.widget<AnimatedContainer>(containerFinder);
      final decoration = containerWidget.decoration as BoxDecoration;

      // Inactive border is AppTheme.borderLight (not harsh black inkForeground)
      expect(decoration.border?.top.color, equals(AppTheme.borderLight));

      // Tap to focus the search bar
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final focusedContainer = tester.widget<AnimatedContainer>(containerFinder);
      final focusedDecoration = focusedContainer.decoration as BoxDecoration;

      // Active border illuminates in active secondary accent (Medical Teal)
      expect(focusedDecoration.border?.top.color, equals(AppTheme.accentPrimary));
    });
  });

  group('Subject Sub-Page & Completion Secondary Accent Verification', () {
    testWidgets('TimelineCheckBubble renders active accent when completed', (tester) async {
      bool isDone = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TimelineCheckBubble(
                  number: 1,
                  isDone: isDone,
                  onTap: () => setState(() => isDone = !isDone),
                );
              },
            ),
          ),
        ),
      );

      // Initially incomplete
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Tap to complete
      await tester.tap(find.byType(TimelineCheckBubble));
      await tester.pumpAndSettle();

      // Completed checkmark renders
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Circle container has active accent color
      final containerFinder = find.descendant(
        of: find.byType(TimelineCheckBubble),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder.last);
      final boxDec = container.decoration as BoxDecoration;
      expect(boxDec.color, equals(AppTheme.accentPrimary));
    });
  });
}
