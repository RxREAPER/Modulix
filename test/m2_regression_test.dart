import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/daily_tasks_provider.dart';
import 'package:modulix/providers/syllabus_provider.dart';
import 'package:modulix/screens/analytics/analytics_screen.dart';
import 'package:modulix/screens/curriculum/module_tasks_screen.dart';
import 'package:modulix/widgets/analytics/daily_tasks_analytics_sheet.dart';
import 'package:modulix/widgets/curriculum/curriculum_search_bar.dart';
import 'package:intl/intl.dart';

class _FakeAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _FakeAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

class _FakeDailyTasksNotifier extends DailyTasksNotifier {
  final DailyTasksState _initial;
  _FakeDailyTasksNotifier(this._initial) : super(null) {
    state = _initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleSubjects = [
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
        Chapter(
          name: 'Lower Limb',
          videos: [
            Video(
              id: 'anat_v3',
              title: 'Femoral Triangle',
              subjectId: 'anat',
              chapterName: 'Lower Limb',
              durationMins: 30,
              serialNumber: 3,
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
              title: 'Cell Injury and Death',
              subjectId: 'path',
              chapterName: 'General Pathology',
              durationMins: 40,
              serialNumber: 1,
            ),
            Video(
              id: 'path_v2',
              title: 'Vitamin B12 Deficiency',
              subjectId: 'path',
              chapterName: 'General Pathology',
              durationMins: 35,
              serialNumber: 2,
            ),
          ],
        ),
      ],
      accent: Colors.red,
    ),
  ];

  group('CurriculumSearchBar Refined Matching Tests', () {
    testWidgets('explicit number search matches videos by serial number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurriculumSearchBar(subjects: sampleSubjects),
            ),
          ),
        ),
      );

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Search '#1' - explicitly numeric
      await tester.enterText(searchField, '#1');
      await tester.pumpAndSettle();

      // Should find both serial number 1 videos
      expect(find.text('Introduction to Upper Limb'), findsOneWidget);
      expect(find.text('Cell Injury and Death'), findsOneWidget);
      expect(find.text('Brachial Plexus'), findsNothing);
    });

    testWidgets('alphanumeric search does NOT trigger false positive digit match', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurriculumSearchBar(subjects: sampleSubjects),
            ),
          ),
        ),
      );

      final searchField = find.byType(TextField);

      // Search 'b12' - alphanumeric term containing 1 and 2
      await tester.enterText(searchField, 'b12');
      await tester.pumpAndSettle();

      // Must match 'Vitamin B12 Deficiency' by title
      expect(find.text('Vitamin B12 Deficiency'), findsOneWidget);
      // Must NOT match video #1 or #2 in anatomy due to stripped digits
      expect(find.text('Introduction to Upper Limb'), findsNothing);
      expect(find.text('Brachial Plexus'), findsNothing);
      expect(find.text('Cell Injury and Death'), findsNothing);
    });

    testWidgets('internal video id search matches exact id without cross-matching #1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurriculumSearchBar(subjects: sampleSubjects),
            ),
          ),
        ),
      );

      final searchField = find.byType(TextField);

      // Search 'anat_v1'
      await tester.enterText(searchField, 'anat_v1');
      await tester.pumpAndSettle();

      // Matches anat_v1 directly via v.id
      expect(find.text('Introduction to Upper Limb'), findsOneWidget);
      // Does NOT match path_v1 (which also has serial number 1)
      expect(find.text('Cell Injury and Death'), findsNothing);
    });
  });

  group('AnalyticsScreen targetUnits Filtering Tests', () {
    testWidgets('progress respects targetUnits when active', (tester) async {
      // Plan targets Anatomy with only 'Upper Limb' (2 videos total)
      final stateWithTargetUnits = AppState(
        activeEdition: 'marrow_8',
        editions: {
          'marrow_8': EditionState(
            plan: const StudyPlan(
              targetSubject: 'anat',
              targetUnits: ['Upper Limb'],
              targetDate: '2026-12-31',
              videosPerDay: 1,
            ),
            completedVideos: {
              'anat_v1': DateTime.now().toIso8601String(),
            },
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _FakeAppStateNotifier(stateWithTargetUnits)),
            activeSyllabusProvider.overrideWithValue(const AsyncValue.data(sampleSubjects)),
          ],
          child: const MaterialApp(
            home: AnalyticsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Upper Limb has 2 videos, 1 completed -> 50%
      // Without targetUnits, total would be 3 videos -> 33%
      expect(find.textContaining('50%'), findsWidgets);
      expect(find.textContaining('33%'), findsNothing);
    });
  });

  group('DailyTasksAnalyticsSheet Morning Streak Tests', () {
    testWidgets('displays active streak in the morning when today has zero tasks done', (tester) async {
      final now = DateTime.now();
      final yesterdayKey = DateFormat('yyyy-MM-dd').format(
        DateTime(now.year, now.month, now.day - 1),
      );
      final twoDaysAgoKey = DateFormat('yyyy-MM-dd').format(
        DateTime(now.year, now.month, now.day - 2),
      );

      final tasksState = DailyTasksState(
        tasks: const [
          DailyDeskTask(
            id: 'task_1',
            title: 'Morning Flashcards',
            category: TaskCategory.revision,
          ),
        ],
        completedIds: const {}, // zero completed today
        dateHistory: {
          yesterdayKey: 3,
          twoDaysAgoKey: 2,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTasksProvider.overrideWith((ref) => _FakeDailyTasksNotifier(tasksState)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DailyTasksAnalyticsSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Streak should be 2 consecutive days (yesterday and day before)
      expect(find.text('2'), findsWidgets);
      expect(find.text('TASK STREAK'), findsOneWidget);
    });
  });

  group('ModuleTasksScreen Navigation Robustness Tests', () {
    testWidgets('root Scaffold is wrapped in PopScope with canPop false', (tester) async {
      const state = AppState(
        activeEdition: 'marrow_8',
        editions: {
          'marrow_8': EditionState(
            plan: StudyPlan(
              targetSubject: 'anat',
              targetDate: '2026-12-31',
              videosPerDay: 1,
            ),
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _FakeAppStateNotifier(state)),
            activeSyllabusProvider.overrideWithValue(const AsyncValue.data(sampleSubjects)),
          ],
          child: const MaterialApp(
            home: ModuleTasksScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);

      final popScopeWidget = tester.widget(popScopeFinder) as PopScope;
      expect(popScopeWidget.canPop, isFalse);
    });
  });
}
