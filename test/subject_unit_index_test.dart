import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/syllabus_provider.dart';
import 'package:modulix/screens/curriculum/subject_screen.dart';

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
            title: 'Ischemic Heart Disease and STEMI',
            subjectId: 'med',
            chapterName: 'Cardiology',
            durationMins: 45,
            serialNumber: 2,
          ),
        ],
        notes: [
          NotesItem(
            id: 'n_card_1',
            title: 'Cardiology Comprehensive High-Yield Pearls',
            chapterName: 'Cardiology',
            subjectId: 'med',
          ),
        ],
      ),
      Chapter(
        name: 'Pulmonology',
        videos: [
          Video(
            id: 'v_pulm_1',
            title: 'COPD and Asthma Exacerbation Management Protocols',
            subjectId: 'med',
            chapterName: 'Pulmonology',
            durationMins: 25,
            serialNumber: 3,
          ),
        ],
        notes: [
          NotesItem(
            id: 'n_pulm_1',
            title: 'Pulmonology Clinical Notes',
            chapterName: 'Pulmonology',
            subjectId: 'med',
          ),
        ],
      ),
      Chapter(
        name: 'Nephrology',
        videos: [
          Video(
            id: 'v_neph_1',
            title: 'Acute Kidney Injury',
            subjectId: 'med',
            chapterName: 'Nephrology',
            durationMins: 20,
            serialNumber: 4,
          ),
        ],
        notes: [
          NotesItem(
            id: 'n_neph_1',
            title: 'Nephrology High Yield',
            chapterName: 'Nephrology',
            subjectId: 'med',
          ),
        ],
      ),
    ],
    qbankChapters: [
      Chapter(
        name: 'Cardiology QBank',
        videos: [],
        qbanks: [
          QBankTopic(
            id: 'qb_card_1',
            title: 'Valvular Heart Disease MCQs',
            subjectId: 'med',
            chapterName: 'Cardiology QBank',
            totalMcqs: 25,
            serialNumber: 1,
          ),
          QBankTopic(
            id: 'qb_card_2',
            title: 'Arrhythmias and Pacemakers Practice',
            subjectId: 'med',
            chapterName: 'Cardiology QBank',
            totalMcqs: 30,
            serialNumber: 2,
          ),
        ],
      ),
      Chapter(
        name: 'Pulmonology QBank',
        videos: [],
        qbanks: [
          QBankTopic(
            id: 'qb_pulm_1',
            title: 'Interstitial Lung Diseases and Sarcoidosis Questions',
            subjectId: 'med',
            chapterName: 'Pulmonology QBank',
            totalMcqs: 20,
            serialNumber: 3,
          ),
        ],
      ),
      Chapter(
        name: 'Nephrology QBank',
        videos: [],
        qbanks: [
          QBankTopic(
            id: 'qb_neph_1',
            title: 'Glomerulonephritis MCQs',
            subjectId: 'med',
            chapterName: 'Nephrology QBank',
            totalMcqs: 15,
            serialNumber: 4,
          ),
        ],
      ),
    ],
  );

  group('SubjectScrollHelper Unit Tests', () {
    test('calculateUnitOffset for Unit 0 always starts at headerBaseOffset', () {
      final offsetVideos = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: 0,
        subject: testSubject,
        activeTab: 'videos',
      );
      final offsetQBank = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: 0,
        subject: testSubject,
        activeTab: 'qbank',
      );
      final offsetNotes = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: 0,
        subject: testSubject,
        activeTab: 'notes',
      );

      expect(offsetVideos, equals(SubjectScrollHelper.headerBaseOffset));
      expect(offsetQBank, equals(SubjectScrollHelper.headerBaseOffset));
      expect(offsetNotes, equals(SubjectScrollHelper.headerBaseOffset));
    });

    test('calculateUnitOffset for Unit 1 accurately sums Unit 0 header and items in Videos', () {
      final offset = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: 1,
        subject: testSubject,
        activeTab: 'videos',
      );
      expect(offset, equals(547.0));
    });

    test('calculateUnitOffset handles wrapped title adjustments in Videos', () {
      final offset = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: 2,
        subject: testSubject,
        activeTab: 'videos',
      );
      expect(offset, equals(723.0));
    });

    test('calculateUnitOffset computes accurately for Notes tab', () {
      final offsetUnit1 = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: 1,
        subject: testSubject,
        activeTab: 'notes',
      );
      expect(offsetUnit1, equals(471.0));

      final offsetUnit2 = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: 2,
        subject: testSubject,
        activeTab: 'notes',
      );
      expect(offsetUnit2, equals(642.0));
    });

    test('calculateUnitOffset computes accurately for Q-Bank tab using qbankChapters', () {
      final offset = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: 1,
        subject: testSubject,
        activeTab: 'qbank',
      );
      expect(offset, equals(552.0));
    });
  });

  group('SubjectScreen Unit Index Widget Navigation', () {
    testWidgets('Unit Index sheet displays units and navigates on tap across tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
      });

      final dummyAppState = AppState(
        activeEdition: 'marrow_8',
        editions: {
          'marrow_8': EditionState(
            completedVideos: {'v_card_1': DateTime.now().toIso8601String()},
            completedQBanks: const {},
            completedNotes: const {},
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(dummyAppState)),
            subjectProvider('med').overrideWithValue(const AsyncData(testSubject)),
          ],
          child: const MaterialApp(
            home: SubjectScreen(subjectId: 'med'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen rendered
      expect(find.text('General Medicine'), findsWidgets);
      expect(find.text('MODULES & TOPICS'), findsOneWidget);

      // Open Unit Index sheet from "Jump to Unit (Index) ▾"
      final jumpToUnitBtn = find.text('Jump to Unit (Index) ▾');
      expect(jumpToUnitBtn, findsOneWidget);
      await tester.tap(jumpToUnitBtn);
      await tester.pumpAndSettle();

      // Verify bottom sheet is open with 3 units
      expect(find.text('Unit Index (3 Units)'), findsOneWidget);
      expect(find.text('Cardiology'), findsWidgets);
      expect(find.text('Pulmonology'), findsWidgets);
      expect(find.text('Nephrology'), findsWidgets);

      // Tap Pulmonology in the sheet to trigger navigation
      await tester.tap(find.text('Pulmonology').last);
      await tester.pumpAndSettle();

      // Verify modal is closed
      expect(find.text('Unit Index (3 Units)'), findsNothing);

      // Switch to Q-Bank Tab
      final qbankTab = find.text('Q-Bank');
      expect(qbankTab, findsOneWidget);
      await tester.tap(qbankTab);
      await tester.pumpAndSettle();

      // Open Unit Index sheet for Q-Bank
      final unitIndexAppBarBtn = find.byTooltip('Unit Index');
      expect(unitIndexAppBarBtn, findsOneWidget);
      await tester.tap(unitIndexAppBarBtn);
      await tester.pumpAndSettle();

      // Verify Q-Bank Units
      expect(find.text('Q-BANK TOPICS'), findsWidgets);
      expect(find.text('Cardiology QBank'), findsWidgets);
      expect(find.text('Nephrology QBank'), findsWidgets);

      // Tap Nephrology QBank
      await tester.tap(find.text('Nephrology QBank').last);
      await tester.pumpAndSettle();

      // Verify modal closed and screen stable
      expect(find.text('Unit Index (3 Units)'), findsNothing);

      // Switch to Notes Tab
      final notesTab = find.text('Notes');
      expect(notesTab, findsOneWidget);
      await tester.tap(notesTab);
      await tester.pumpAndSettle();

      // Open Unit Index sheet for Notes
      await tester.tap(unitIndexAppBarBtn);
      await tester.pumpAndSettle();

      expect(find.text('NOTES'), findsWidgets);
      expect(find.text('Cardiology'), findsWidgets);

      // Tap Cardiology
      await tester.tap(find.text('Cardiology').last);
      await tester.pumpAndSettle();

      expect(find.text('Unit Index (3 Units)'), findsNothing);
    });
  });
}
