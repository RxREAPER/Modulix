import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/study_desk_clock.dart';
import 'package:modulix/widgets/study_task_card.dart';
import 'package:modulix/widgets/automated_module_tracker.dart';
import 'package:modulix/screens/curriculum/module_tasks_screen.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/syllabus_provider.dart';
import 'package:modulix/screens/analytics/analytics_screen.dart';
import 'package:modulix/widgets/analytics/focus_timer_analytics_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _FakeAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

void main() {
  testWidgets('StudyDeskClock renders modern aesthetic timepiece with no buttons, tags, or timer links', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudyDeskClock(),
        ),
      ),
    );

    expect(find.byType(StudyDeskClock), findsOneWidget);
    // Verifies strict adherence to user mandate: no focus buttons, no pace tags
    expect(find.text('START FOCUS'), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(find.text('STUDY STATION'), findsNothing);

    // Verifies no InkWell / interactive link to focus timer screen
    expect(find.byType(InkWell), findsNothing);

    // Verifies greeting and absence of LIVE badge or progress track
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('Focus, Doctor.'), findsOneWidget);
  });

  testWidgets('StudyTaskCard renders title, subtitle and triggers toggle', (tester) async {
    bool toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudyTaskCard(
            id: 'task_1',
            title: 'Upper Limb Anatomy Lecture 1',
            customSubtitle: 'Study Goal #1',
            isCompleted: false,
            onToggle: () => toggled = true,
          ),
        ),
      ),
    );

    expect(find.text('Upper Limb Anatomy Lecture 1'), findsOneWidget);
    expect(find.text('Study Goal #1'), findsOneWidget);

    await tester.tap(find.byType(StudyTaskCard));
    expect(toggled, isTrue);
  });

  testWidgets('Video.fromMap correctly parses immutable videoNumber and __v id formats', (tester) async {
    final v1 = Video.fromMap({
      'id': 'anatomy__v41',
      'videoNumber': '#41',
      'title': 'Ulnar Nerve',
      'durationMins': 30,
      'durationSecs': 0,
    }, 'anatomy', 'UPPER LIMB');

    expect(v1.serialNumber, 41);
    expect(v1.chapterName, 'UPPER LIMB');

    final v2 = Video.fromMap({
      'id': 'biochemistry__v105',
      'title': 'Lipid Synthesis',
    }, 'biochemistry');
    expect(v2.serialNumber, 105);
  });

  testWidgets('AutomatedModuleTracker renders minimalist unconfigured card', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AutomatedModuleTracker(
                editionState: EditionState(),
                editionName: 'marrow_8',
                subjects: [],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Module Based Tasks'), findsOneWidget);
    expect(find.text('Tap to setup daily curriculum pace'), findsOneWidget);
    expect(find.text('Calibrate Study Plan & Pace'), findsOneWidget);
  });

  testWidgets('AutomatedModuleTracker renders card matching Day resets at layout with inner Open Queue action', (tester) async {
    final testSubject = Subject(
      id: 'anat',
      name: 'Anatomy',
      displayName: 'Anatomy',
      chapters: [
        Chapter(
          name: 'Upper Limb',
          videos: List.generate(
            6,
            (i) => Video(
              id: 'anat_vid_$i',
              title: 'Anatomy Lecture ${i + 1}',
              subjectId: 'anat',
              chapterName: 'Upper Limb',
              durationMins: 20 + i * 5,
              serialNumber: 40 + i,
            ),
          ),
        ),
      ],
      accent: Colors.blue,
    );

    const plan = StudyPlan(
      targetSubject: 'anat',
      targetDate: '2026-12-31T00:00:00.000Z',
      videosPerDay: 4,
      targetUnits: ['Upper Limb'],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AutomatedModuleTracker(
                editionState: const EditionState(plan: plan),
                editionName: 'marrow_8',
                subjects: [testSubject],
              ),
            ),
          ),
        ),
      ),
    );

    // Verify header matching clean layout with inner Open Queue action
    expect(find.text('Module Based Tasks'), findsOneWidget);
    expect(find.text('Open Queue'), findsOneWidget);
    expect(find.text('Anatomy'), findsOneWidget);
    expect(find.text('Upper Limb'), findsOneWidget);
    // Verifies clutter-free card with no extra progress counter texts
    expect(find.text('0 of 4 done today'), findsNothing);

    // Minimalist verification: No Setup button on Home card, no footer CTA button
    expect(find.text('Setup'), findsNothing);
    expect(find.text("View Today's Modules (4)"), findsNothing);
  });

  testWidgets('ModuleTasksScreen displays top banner with unit progress bar, curriculum link, and exact numbering', (tester) async {
    const testSubject = Subject(
      id: 'anat',
      name: 'Anatomy',
      displayName: 'Anatomy',
      chapters: [
        Chapter(
          name: 'Upper Limb',
          videos: [
            Video(
              id: 'anat_vid_41',
              title: 'Ulnar Nerve',
              subjectId: 'anat',
              chapterName: 'Upper Limb',
              durationMins: 30,
              serialNumber: 41,
            ),
            Video(
              id: 'anat_vid_42',
              title: 'Vessels of Upper Limb',
              subjectId: 'anat',
              chapterName: 'Upper Limb',
              durationMins: 35,
              serialNumber: 42,
            ),
          ],
        ),
      ],
      accent: Colors.blue,
    );

    const plan = StudyPlan(
      targetSubject: 'anat',
      targetDate: '2026-12-31T00:00:00.000Z',
      videosPerDay: 2,
      targetUnits: ['Upper Limb'],
    );

    const state = AppState(
      activeEdition: 'marrow_8',
      editions: {
        'marrow_8': EditionState(
          plan: plan,
          staleBatchVideoIds: ['anat_vid_41'], // Stale carried over task
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateProvider.overrideWith(() => _FakeAppStateNotifier(state)),
          activeSyllabusProvider.overrideWithValue(const AsyncValue.data([testSubject])),
        ],
        child: const MaterialApp(
          home: ModuleTasksScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & AppBar Setup button
    expect(find.text('Module Based Tasks'), findsOneWidget);
    expect(find.text('Setup'), findsOneWidget);

    // PART 1: Top Banner with Subject, small Unit text, Daily Goal, Done Today, Unit Progress
    expect(find.text('Anatomy'), findsOneWidget);
    expect(find.text('Unit: Upper Limb'), findsOneWidget);
    expect(find.text('DAILY GOAL'), findsOneWidget);
    expect(find.text('DONE TODAY'), findsOneWidget);
    expect(find.text('Unit Progress'), findsOneWidget);

    // PART 2: Minimalist curriculum deep link
    expect(find.text('All Units'), findsOneWidget);

    // PART 3: Today's Modules list with exact immutable serial numbers (41 and 42)
    expect(find.text('41'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Ulnar Nerve'), findsOneWidget);
    expect(find.text('Vessels of Upper Limb'), findsOneWidget);

    // Stale tag verification
    expect(find.text('Stale'), findsWidgets);

    // Timer shortcut icon buttons
    expect(find.byIcon(Icons.timer_outlined), findsNWidgets(2));
  });

  testWidgets('AnalyticsScreen renders live streak badges, Module Plan Progress, and Dynamic Syllabus ETA & Pace Gauge', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const testSubject = Subject(
      id: 'anat',
      name: 'Anatomy',
      displayName: 'Anatomy',
      chapters: [
        Chapter(
          name: 'Upper Limb',
          videos: [
            Video(
              id: 'anat_vid_41',
              title: 'Ulnar Nerve',
              subjectId: 'anat',
              chapterName: 'Upper Limb',
              durationMins: 30,
              serialNumber: 41,
            ),
          ],
        ),
      ],
      accent: Colors.blue,
    );

    const plan = StudyPlan(
      targetSubject: 'anat',
      targetDate: '2026-12-31T00:00:00.000Z',
      videosPerDay: 4,
      targetUnits: ['Upper Limb'],
    );

    const state = AppState(
      activeEdition: 'marrow_8',
      editions: {
        'marrow_8': EditionState(
          plan: plan,
          dailyHistory: {'2026-09-30': 4, '2026-09-29': 3},
          staleBatchVideoIds: ['anat_vid_41'],
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateProvider.overrideWith(() => _FakeAppStateNotifier(state)),
          activeSyllabusProvider.overrideWithValue(const AsyncValue.data([testSubject])),
        ],
        child: const MaterialApp(
          home: AnalyticsScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & streak cards with live text and NO unicode emojis
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('DAYS ACTIVE'), findsOneWidget);
    expect(find.text('RECORD'), findsOneWidget);
    expect(find.text('days 🔥'), findsNothing);
    expect(find.text('days 🏆'), findsNothing);

    // Verify renamed Hub Cards
    expect(find.text('Module Plan Progress'), findsOneWidget);
    expect(find.text('Daily Tasks Analytics'), findsOneWidget);
  });

  testWidgets('FocusTimerAnalyticsSheet renders interactive animated fl_chart BarChart with legend', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FocusTimerAnalyticsSheet(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Interactive chart title & BarChart widget
    expect(find.text('INTERACTIVE STUDY HOURS (7 DAYS)'), findsOneWidget);
    expect(find.text('TOUCH FOR DETAILS'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);

    // Verify stationery legend items
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('QBank'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('4h Goal'), findsOneWidget);
  });
}
