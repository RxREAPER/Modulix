import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/models/time_log.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/daily_tasks_provider.dart';
import 'package:modulix/providers/syllabus_provider.dart';
import 'package:modulix/providers/time_log_provider.dart';
import 'package:modulix/screens/analytics/analytics_screen.dart';
import 'package:modulix/screens/analytics/study_plan_analytics_page.dart';
import 'package:modulix/screens/analytics/focus_timer_analytics_page.dart';
import 'package:modulix/screens/analytics/daily_tasks_analytics_page.dart';
import 'package:modulix/screens/analytics/subject_mastery_analytics_page.dart';
import 'package:modulix/widgets/analytics/progress_radial_gauge.dart';
import 'package:modulix/widgets/analytics/concentric_donut_indicator.dart';
import 'package:modulix/widgets/analytics/segmented_velocity_pill.dart';
import 'package:modulix/widgets/analytics/chronotype_heat_strip.dart';

class _MockAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _MockAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

class _MockDailyTasksNotifier extends DailyTasksNotifier {
  final DailyTasksState _initial;
  _MockDailyTasksNotifier(this._initial) : super(null) {
    state = _initial;
  }
}

class _MockTimeLogsNotifier extends TimeLogsNotifier {
  _MockTimeLogsNotifier(List<TimeLog> initial) : super() {
    state = initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testSubjects = [
    Subject(
      id: 'anat',
      name: 'Anatomy',
      displayName: 'Anatomy',
      chapters: [
        Chapter(
          name: 'Upper Limb',
          videos: [
            Video(
              id: 'anat_v1',
              title: 'Introduction to Upper Limb',
              subjectId: 'anat',
              chapterName: 'Upper Limb',
              durationMins: 30,
              serialNumber: 1,
            ),
            Video(
              id: 'anat_v2',
              title: 'Brachial Plexus',
              subjectId: 'anat',
              chapterName: 'Upper Limb',
              durationMins: 45,
              serialNumber: 2,
            ),
          ],
        ),
      ],
      accent: Colors.blue,
    ),
    Subject(
      id: 'path',
      name: 'Pathology',
      displayName: 'Pathology',
      chapters: [
        Chapter(
          name: 'General Pathology',
          videos: [
            Video(
              id: 'path_v1',
              title: 'Cell Injury',
              subjectId: 'path',
              chapterName: 'General Pathology',
              durationMins: 40,
              serialNumber: 1,
            ),
          ],
        ),
      ],
      accent: Colors.red,
    ),
  ];

  final testAppState = AppState(
    activeEdition: 'marrow_8',
    editions: {
      'marrow_8': EditionState(
        plan: const StudyPlan(
          targetSubject: 'anat',
          targetUnits: ['Upper Limb'],
          targetDate: '2026-12-31',
          videosPerDay: 4,
        ),
        completedVideos: {
          'anat_v1': DateTime.now().toIso8601String(),
        },
        dailyHistory: {
          '2026-10-22': 2,
          '2026-10-21': 3,
        },
      ),
    },
  );

  final testTimeLogs = [
    TimeLog(
      id: 'log_1',
      subjectId: 'anat',
      topicType: 'video',
      topicTitle: 'Brachial Plexus',
      chapterName: 'Upper Limb',
      durationSecs: 1800,
      timestamp: DateTime.now(),
    ),
  ];

  final testTasksState = DailyTasksState(
    tasks: const [
      DailyDeskTask(
        id: 't_1',
        title: 'Review Upper Limb',
        category: TaskCategory.video,
      ),
      DailyDeskTask(
        id: 't_2',
        title: 'Solve 20 MCQs',
        category: TaskCategory.qbank,
      ),
    ],
    completedIds: const {'t_1'},
  );

  group('Custom Analytics UI Components Tests', () {
    testWidgets('ProgressRadialGauge renders percentage text correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressRadialGauge(progress: 0.75, size: 80),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('ConcentricDonutIndicator renders without exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConcentricDonutIndicator(
              progress1: 0.6,
              progress2: 0.4,
              progress3: 0.2,
              size: 60,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConcentricDonutIndicator), findsOneWidget);
    });

    testWidgets('SegmentedVelocityPill renders discrete segments and velocity label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SegmentedVelocityPill(
              totalSegments: 5,
              completedSegments: 3,
              activeColor: Colors.green,
              velocityLabel: '+15% vs yesterday',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+15% vs yesterday'), findsOneWidget);
    });

    testWidgets('ChronotypeHeatStrip renders 24-hour visual intervals', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChronotypeHeatStrip(
              hourMinutes: {8: 45, 14: 60, 21: 90},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CHRONOTYPE INTENSITY (24H)'), findsOneWidget);
      expect(find.text('12 AM'), findsOneWidget);
      expect(find.text('12 PM'), findsOneWidget);
    });
  });

  group('AnalyticsScreen Overhaul Hub Cards Tests', () {
    testWidgets('AnalyticsScreen renders all 4 Performance Hubs with interactive indicators', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(testAppState)),
            activeSyllabusProvider.overrideWithValue(AsyncValue.data(testSubjects)),
            timeLogsProvider.overrideWith((ref) => _MockTimeLogsNotifier(testTimeLogs)),
            dailyTasksProvider.overrideWith((ref) => _MockDailyTasksNotifier(testTasksState)),
          ],
          child: const MaterialApp(
            home: AnalyticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('PERFORMANCE HUBS'), findsOneWidget);

      // Hub 1
      expect(find.text('Module Plan Progress'), findsOneWidget);
      expect(find.textContaining('50% complete'), findsOneWidget);

      // Hub 2
      expect(find.text('Focus & Deep Work'), findsOneWidget);

      // Hub 3
      expect(find.text('Daily Tasks Analytics'), findsOneWidget);

      // Hub 4: 19 MBBS Subjects Mastery
      expect(find.text('19 MBBS Subjects Mastery'), findsOneWidget);
    });
  });

  group('Dedicated Full Page Views Tests', () {
    testWidgets('StudyPlanAnalyticsPage renders what-if pace slider and unit matrix', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(testAppState)),
            activeSyllabusProvider.overrideWithValue(AsyncValue.data(testSubjects)),
          ],
          child: const MaterialApp(
            home: StudyPlanAnalyticsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Study Plan Insights'), findsOneWidget);
      expect(find.text('WHAT-IF VELOCITY SIMULATOR'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Upper Limb'), findsOneWidget);
    });

    testWidgets('FocusTimerAnalyticsPage renders timeframe selector and recent sessions', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(testAppState)),
            timeLogsProvider.overrideWith((ref) => _MockTimeLogsNotifier(testTimeLogs)),
          ],
          child: const MaterialApp(
            home: FocusTimerAnalyticsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Focus & Deep Work'), findsOneWidget);
      expect(find.text('7D'), findsOneWidget);
      expect(find.text('30D'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Brachial Plexus'), findsOneWidget);
    });

    testWidgets('DailyTasksAnalyticsPage renders 14-day activity matrix and categories', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(testAppState)),
            dailyTasksProvider.overrideWith((ref) => _MockDailyTasksNotifier(testTasksState)),
          ],
          child: const MaterialApp(
            home: DailyTasksAnalyticsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Tasks & Desk Pad'), findsOneWidget);
      expect(find.text('14-DAY ACTIVITY MATRIX'), findsOneWidget);
      expect(find.text('Review Upper Limb'), findsOneWidget);
    });

    testWidgets('SubjectMasteryAnalyticsPage renders phase pills and subject list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(testAppState)),
            activeSyllabusProvider.overrideWithValue(AsyncValue.data(testSubjects)),
          ],
          child: const MaterialApp(
            home: SubjectMasteryAnalyticsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('19 MBBS Subjects Mastery'), findsOneWidget);
      expect(find.text('All (19)'), findsOneWidget);
      expect(find.text('Pre-Clinical (3)'), findsOneWidget);
      expect(find.text('Anatomy'), findsOneWidget);
      expect(find.text('Pathology'), findsOneWidget);
    });
  });
}
