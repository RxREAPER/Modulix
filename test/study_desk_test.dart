import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowmd_flutter/widgets/nori_companion.dart';
import 'package:flowmd_flutter/widgets/study_desk_clock.dart';
import 'package:flowmd_flutter/widgets/study_task_card.dart';
import 'package:flowmd_flutter/widgets/automated_module_tracker.dart';
import 'package:flowmd_flutter/screens/curriculum/module_tasks_screen.dart';
import 'package:flowmd_flutter/models/app_state.dart';
import 'package:flowmd_flutter/models/syllabus.dart';
import 'package:flowmd_flutter/providers/app_state_provider.dart';
import 'package:flowmd_flutter/providers/syllabus_provider.dart';
import 'package:flowmd_flutter/screens/analytics/analytics_screen.dart';
import 'package:flowmd_flutter/widgets/analytics/focus_timer_analytics_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _FakeAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

void main() {
  testWidgets('NoriCompanion renders successfully with mascot elements', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NoriCompanion(size: 110),
        ),
      ),
    );

    expect(find.byType(NoriCompanion), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('StudyDeskClock displays time and Nori companion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudyDeskClock(),
        ),
      ),
    );

    expect(find.text('START FOCUS'), findsOneWidget);
    expect(find.text('Wardrobe'), findsOneWidget);
    expect(find.byType(NoriCompanion), findsOneWidget);
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
    expect(find.text('View Details'), findsOneWidget);
  });

  testWidgets('AutomatedModuleTracker renders stationery card matching Today tasks layout with View Details', (tester) async {
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

    final plan = StudyPlan(
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
                editionState: EditionState(plan: plan),
                editionName: 'marrow_8',
                subjects: [testSubject],
              ),
            ),
          ),
        ),
      ),
    );

    // Verify header matching Today's tasks layout with View Details button
    expect(find.text('Module Based Tasks'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('Anatomy'), findsOneWidget);
    expect(find.text('Upper Limb'), findsOneWidget);
    expect(find.text('0 of 4 done'), findsOneWidget);

    // Minimalist verification: No Setup button on Home card, no footer CTA button
    expect(find.text('Setup'), findsNothing);
    expect(find.text("View Today's Modules (4)"), findsNothing);
  });

  testWidgets('ModuleTasksScreen displays top banner with unit progress bar, curriculum link, and exact numbering', (tester) async {
    final testSubject = Subject(
      id: 'anat',
      name: 'Anatomy',
      displayName: 'Anatomy',
      chapters: [
        Chapter(
          name: 'Upper Limb',
          videos: [
            const Video(
              id: 'anat_vid_41',
              title: 'Ulnar Nerve',
              subjectId: 'anat',
              chapterName: 'Upper Limb',
              durationMins: 30,
              serialNumber: 41,
            ),
            const Video(
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

    final plan = StudyPlan(
      targetSubject: 'anat',
      targetDate: '2026-12-31T00:00:00.000Z',
      videosPerDay: 2,
      targetUnits: ['Upper Limb'],
    );

    final state = AppState(
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
          activeSyllabusProvider.overrideWithValue(AsyncValue.data([testSubject])),
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

    // PART 2: Graphic curriculum deep link
    expect(find.text('Open "Upper Limb" in Curriculum'), findsOneWidget);
    expect(find.text('CURRICULUM SYLLABUS'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);

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

    final testSubject = Subject(
      id: 'anat',
      name: 'Anatomy',
      displayName: 'Anatomy',
      chapters: [
        Chapter(
          name: 'Upper Limb',
          videos: [
            const Video(
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

    final plan = StudyPlan(
      targetSubject: 'anat',
      targetDate: '2026-12-31T00:00:00.000Z',
      videosPerDay: 4,
      targetUnits: ['Upper Limb'],
    );

    final state = AppState(
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
          activeSyllabusProvider.overrideWithValue(AsyncValue.data([testSubject])),
        ],
        child: const MaterialApp(
          home: AnalyticsScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & streak cards with live text and NO unicode emojis
    expect(find.text('Analytics'), findsOneWidget);
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
