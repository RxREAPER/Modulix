import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modulix/screens/plan/plan_screen.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/syllabus_provider.dart';

class _FakeAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _FakeAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

void main() {
  final testSubject = Subject(
    id: 'anat',
    name: 'Anatomy',
    displayName: 'Anatomy',
    chapters: [
      Chapter(
        name: 'Upper Limb',
        videos: List.generate(
          5,
          (i) => Video(
            id: 'anat_vid_$i',
            title: 'Anatomy Lecture ${i + 1}',
            subjectId: 'anat',
            chapterName: 'Upper Limb',
            durationMins: 30,
            serialNumber: i + 1,
          ),
        ),
      ),
      Chapter(
        name: 'Lower Limb',
        videos: List.generate(
          5,
          (i) => Video(
            id: 'anat_vid_ll_$i',
            title: 'Lower Limb Lecture ${i + 1}',
            subjectId: 'anat',
            chapterName: 'Lower Limb',
            durationMins: 30,
            serialNumber: i + 6,
          ),
        ),
      ),
    ],
    accent: Colors.blue,
  );

  testWidgets('PlanScreen satisfies requirements A through G', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Unconfigured state (new user / no plan)
    final emptyState = AppState.empty;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateProvider.overrideWith(() => _FakeAppStateNotifier(emptyState)),
          activeSyllabusProvider.overrideWithValue(AsyncValue.data([testSubject])),
        ],
        child: const MaterialApp(
          home: PlanScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Requirement A: Info box is removed
    expect(
      find.text('Directly syncs your daily module targets with your active study queue and revision workflow.'),
      findsNothing,
    );

    // Requirement B: Section header is renamed to "2. Deadline Date" and card has "DEADLINE DATE"
    expect(find.text('2. Deadline Date'), findsOneWidget);
    expect(find.text('DEADLINE DATE'), findsOneWidget);
    expect(find.text('Target Exam Date & Pace'), findsNothing);

    // Requirement C: Presets removed and Stepper is present
    expect(find.text('PRESETS:'), findsNothing);
    expect(find.text('Daily Module Target'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Requirement G: Initial state has blank parameters awaiting subject selection
    expect(find.text('Awaiting Date'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);

    // Select the subject
    await tester.tap(find.text('Anatomy'));
    await tester.pumpAndSettle();

    // Requirement E: "All" and "Multiple" toggle exists
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Multiple'), findsOneWidget);

    // Both chapters visible
    expect(find.text('Upper Limb'), findsOneWidget);
    expect(find.text('Lower Limb'), findsOneWidget);

    // Clicking "Multiple" deselects all units on click
    await tester.tap(find.text('Multiple'));
    await tester.pumpAndSettle();

    // Now units show '+' indicating they are unselected
    expect(find.text('+'), findsNWidgets(2));

    // Tap 'Lower Limb' first: it becomes unit #1
    await tester.tap(find.text('Lower Limb'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // Tap 'Upper Limb' second: it becomes unit #2
    await tester.tap(find.text('Upper Limb'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    // Tap 'All' again to select all units
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);

    // Requirement F: Button design exists for both buttons
    expect(find.text('Configure All Parameters Above'), findsOneWidget);
    expect(find.text('Open Module Tasks Queue'), findsOneWidget);
  });
}
