import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/syllabus_provider.dart';
import 'package:modulix/screens/curriculum/chapter_screen.dart';

class _MockAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _MockAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testSubject = Subject(
    id: 'med',
    name: 'Medicine',
    displayName: 'General Medicine',
    accent: Colors.indigo,
    chapters: [
      Chapter(
        name: 'Cardiology',
        videos: [
          Video(
            id: 'v_card_1',
            title: 'ECG Basics & Normal Waveforms',
            subjectId: 'med',
            chapterName: 'Cardiology',
            durationMins: 30,
            serialNumber: 1,
          ),
          Video(
            id: 'v_card_2',
            title: 'Arrhythmias & AV Blocks',
            subjectId: 'med',
            chapterName: 'Cardiology',
            durationMins: 45,
            serialNumber: 2,
          ),
        ],
        notes: [],
      ),
      Chapter(
        name: 'Pulmonology',
        videos: [
          Video(
            id: 'v_pulm_1',
            title: 'COPD Management',
            subjectId: 'med',
            chapterName: 'Pulmonology',
            durationMins: 25,
            serialNumber: 2,
          ),
        ],
        notes: [],
      ),
    ],
    qbankChapters: [],
  );

  const emptySubject = Subject(
    id: 'empty',
    name: 'Empty Subject',
    displayName: 'Empty Subject',
    accent: Colors.teal,
    chapters: [],
    qbankChapters: [],
  );

  const zeroVideosSubject = Subject(
    id: 'zero_vids',
    name: 'Zero Videos',
    displayName: 'Zero Videos',
    accent: Colors.orange,
    chapters: [
      Chapter(
        name: 'Empty Chapter',
        videos: [],
        notes: [],
      ),
    ],
    qbankChapters: [],
  );

  const dummyAppState = AppState(
    activeEdition: 'marrow_8',
    editions: {
      'marrow_8': EditionState(
        completedVideos: {
          'v_card_1': '2026-10-14T08:00:00Z',
        },
        completedQBanks: {},
        completedNotes: {},
      ),
    },
  );

  Widget createTestWidget({
    required int chapterIndex,
    String subjectId = 'med',
    Subject? subjectOverride = testSubject,
  }) {
    return ProviderScope(
      overrides: [
        appStateProvider.overrideWith(() => _MockAppStateNotifier(dummyAppState)),
        if (subjectOverride != null)
          subjectProvider(subjectId).overrideWithValue(AsyncData(subjectOverride))
        else
          subjectProvider(subjectId).overrideWithValue(const AsyncData(null)),
      ],
      child: MaterialApp(
        home: ChapterScreen(
          subjectId: subjectId,
          chapterIndex: chapterIndex,
        ),
      ),
    );
  }

  group('ChapterScreen Bounds & Safety Tests', () {
    testWidgets('Negative chapterIndex (-1) displays Chapter not found without throwing RangeError', (tester) async {
      await tester.pumpWidget(createTestWidget(chapterIndex: -1));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
      expect(find.text('Cardiology'), findsNothing);
    });

    testWidgets('Negative chapterIndex (-10) displays Chapter not found', (tester) async {
      await tester.pumpWidget(createTestWidget(chapterIndex: -10));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
    });

    testWidgets('Min 64-bit int negative boundary (-9223372036854775808) displays Chapter not found', (tester) async {
      await tester.pumpWidget(createTestWidget(chapterIndex: -9223372036854775808));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
    });

    testWidgets('Exact upper boundary (chapterIndex == chapters.length) displays Chapter not found', (tester) async {
      await tester.pumpWidget(createTestWidget(chapterIndex: testSubject.chapters.length));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
      expect(find.text('Cardiology'), findsNothing);
      expect(find.text('Pulmonology'), findsNothing);
    });

    testWidgets('Out of bounds positive chapterIndex (999) displays Chapter not found', (tester) async {
      await tester.pumpWidget(createTestWidget(chapterIndex: 999));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
    });

    testWidgets('Max 64-bit int upper boundary (9223372036854775807) displays Chapter not found', (tester) async {
      await tester.pumpWidget(createTestWidget(chapterIndex: 9223372036854775807));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
    });

    testWidgets('Empty chapters subject with index 0 safely displays Chapter not found without throwing RangeError', (tester) async {
      await tester.pumpWidget(createTestWidget(
        chapterIndex: 0,
        subjectId: 'empty',
        subjectOverride: emptySubject,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
    });

    testWidgets('Unknown subject (subject == null) displays Chapter not found', (tester) async {
      await tester.pumpWidget(createTestWidget(
        chapterIndex: 0,
        subjectId: 'non_existent_subject',
        subjectOverride: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
    });

    testWidgets('Chapter with 0 videos renders 0 / 0 done and avoids division by zero', (tester) async {
      await tester.pumpWidget(createTestWidget(
        chapterIndex: 0,
        subjectId: 'zero_vids',
        subjectOverride: zeroVideosSubject,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Empty Chapter'), findsOneWidget);
      expect(find.text('0 / 0 done'), findsOneWidget);
      expect(find.text('0 remaining'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Valid lower boundary chapterIndex (0) renders chapter title and videos successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(chapterIndex: 0));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsNothing);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('ECG Basics & Normal Waveforms'), findsOneWidget);
      expect(find.text('1 / 2 done'), findsOneWidget);
      expect(find.text('1 remaining'), findsOneWidget);
    });

    testWidgets('Valid upper boundary chapterIndex (1) renders second chapter', (tester) async {
      await tester.pumpWidget(createTestWidget(chapterIndex: 1));
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsNothing);
      expect(find.text('Pulmonology'), findsOneWidget);
      expect(find.text('COPD Management'), findsOneWidget);
      expect(find.text('0 / 1 done'), findsOneWidget);
      expect(find.text('1 remaining'), findsOneWidget);
    });
  });

  group('Route chapter parameter parsing unit tests', () {
    test('int.tryParse safely falls back to -1 on invalid and adversarial strings', () {
      final invalidInputs = [
        null,
        '',
        ' ',
        '   ',
        '\t',
        '\n',
        'abc',
        'invalid_id',
        'chapter_1',
        '1a',
        'a1',
        '12.34',
        '3.14159',
        '1e10',
        '-',
        '--',
        '+',
        'null',
        'undefined',
        'NaN',
        'Infinity',
        '-Infinity',
        '0xG',
        "' OR '1'='1",
        '<script>alert(1)</script>',
        '%20',
        'true',
        'false',
        '9999999999999999999999999999999999999999999999999999999999999999',
        '-9999999999999999999999999999999999999999999999999999999999999999',
      ];
      for (final input in invalidInputs) {
        final parsed = int.tryParse(input ?? '') ?? -1;
        expect(parsed, equals(-1), reason: 'Failed for input: $input');
      }
    });

    test('int.tryParse handles valid numeric strings correctly', () {
      expect(int.tryParse('0') ?? -1, equals(0));
      expect(int.tryParse('1') ?? -1, equals(1));
      expect(int.tryParse('2') ?? -1, equals(2));
      expect(int.tryParse('100') ?? -1, equals(100));
      expect(int.tryParse('-1') ?? -1, equals(-1));
      expect(int.tryParse('-5') ?? -1, equals(-5));
      expect(int.tryParse('+5') ?? -1, equals(5));
      expect(int.tryParse('012') ?? -1, equals(12));
    });
  });

  group('GoRouter End-to-End Navigation Integration Tests', () {
    testWidgets('GoRouter navigates to valid chapter route /curriculum/med/0', (tester) async {
      final router = GoRouter(
        initialLocation: '/curriculum/med/0',
        routes: [
          GoRoute(
            path: '/curriculum/:subjectId/:chapterIndex',
            builder: (context, state) => ChapterScreen(
              subjectId: state.pathParameters['subjectId'] ?? '',
              chapterIndex:
                  int.tryParse(state.pathParameters['chapterIndex'] ?? '') ??
                      -1,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(dummyAppState)),
            subjectProvider('med').overrideWithValue(const AsyncData(testSubject)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cardiology'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GoRouter handles malformed non-numeric param /curriculum/med/abc gracefully', (tester) async {
      final router = GoRouter(
        initialLocation: '/curriculum/med/abc',
        routes: [
          GoRoute(
            path: '/curriculum/:subjectId/:chapterIndex',
            builder: (context, state) => ChapterScreen(
              subjectId: state.pathParameters['subjectId'] ?? '',
              chapterIndex:
                  int.tryParse(state.pathParameters['chapterIndex'] ?? '') ??
                      -1,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(dummyAppState)),
            subjectProvider('med').overrideWithValue(const AsyncData(testSubject)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GoRouter handles negative param /curriculum/med/-5 gracefully', (tester) async {
      final router = GoRouter(
        initialLocation: '/curriculum/med/-5',
        routes: [
          GoRoute(
            path: '/curriculum/:subjectId/:chapterIndex',
            builder: (context, state) => ChapterScreen(
              subjectId: state.pathParameters['subjectId'] ?? '',
              chapterIndex:
                  int.tryParse(state.pathParameters['chapterIndex'] ?? '') ??
                      -1,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(dummyAppState)),
            subjectProvider('med').overrideWithValue(const AsyncData(testSubject)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GoRouter handles out-of-range positive param /curriculum/med/9999 gracefully', (tester) async {
      final router = GoRouter(
        initialLocation: '/curriculum/med/9999',
        routes: [
          GoRoute(
            path: '/curriculum/:subjectId/:chapterIndex',
            builder: (context, state) => ChapterScreen(
              subjectId: state.pathParameters['subjectId'] ?? '',
              chapterIndex:
                  int.tryParse(state.pathParameters['chapterIndex'] ?? '') ??
                      -1,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(dummyAppState)),
            subjectProvider('med').overrideWithValue(const AsyncData(testSubject)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chapter not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

