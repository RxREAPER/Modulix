import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/daily_tasks_provider.dart';
import 'package:modulix/screens/planner/planner_screen.dart';
import 'package:modulix/widgets/study_task_card.dart';

class _MockAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _MockAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

class _MockDailyTasksNotifier extends DailyTasksNotifier {
  _MockDailyTasksNotifier(DailyTasksState initial) : super(null) {
    state = initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Medical Desk Planner Model & Deserialization Tests', () {
    test('DailyDeskTask serializes and deserializes all MedicalSubject and TaskPriority values', () {
      for (final subject in MedicalSubject.values) {
        for (final priority in TaskPriority.values) {
          final task = DailyDeskTask(
            id: 'task_${subject.name}_${priority.name}',
            title: 'Study ${subject.shortCode}',
            category: TaskCategory.video,
            subject: subject,
            priority: priority,
            estimatedMinutes: 45,
            actualMinutesSpent: 20,
            isRecurring: true,
            scheduledDate: '2026-10-24',
          );

          final map = task.toMap();
          final restored = DailyDeskTask.fromMap(map);

          expect(restored.id, task.id);
          expect(restored.title, task.title);
          expect(restored.subject, subject);
          expect(restored.priority, priority);
          expect(restored.estimatedMinutes, 45);
          expect(restored.actualMinutesSpent, 20);
          expect(restored.isRecurring, isTrue);
          expect(restored.scheduledDate, '2026-10-24');
        }
      }
    });

    test('DailyDeskTask handles legacy maps gracefully without crashes', () {
      final legacyMap = {
        'id': 'legacy_task_1',
        'title': 'Anatomy Dissection',
        'category': 'video',
      };

      final restored = DailyDeskTask.fromMap(legacyMap);
      expect(restored.id, 'legacy_task_1');
      expect(restored.subject, MedicalSubject.general);
      expect(restored.priority, TaskPriority.p3medium);
      expect(restored.estimatedMinutes, isNull);
      expect(restored.actualMinutesSpent, isNull);
      expect(restored.isRecurring, isFalse);
    });

    test('DailyDeskTask copyWith updates fields immutably', () {
      const task = DailyDeskTask(
        id: 'task_1',
        title: 'Physiology Lecture',
        category: TaskCategory.notes,
        subject: MedicalSubject.physiology,
        priority: TaskPriority.p2high,
        estimatedMinutes: 60,
      );

      final updated = task.copyWith(
        actualMinutesSpent: 35,
        priority: TaskPriority.p1urgent,
      );

      expect(updated.id, 'task_1');
      expect(updated.actualMinutesSpent, 35);
      expect(updated.priority, TaskPriority.p1urgent);
      expect(task.priority, TaskPriority.p2high);
    });
  });

  group('StudyTaskCard Medical Attributes Widget Tests', () {
    testWidgets('renders priority dot, subject short code, duration and recurring icon', (tester) async {
      const task = DailyDeskTask(
        id: 'task_pharm_card',
        title: 'Autonomic Pharmacology',
        category: TaskCategory.qbank,
        subject: MedicalSubject.pharmacology,
        priority: TaskPriority.p1urgent,
        estimatedMinutes: 50,
        actualMinutesSpent: 25,
        isRecurring: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyTaskCard(
              id: task.id,
              title: task.title,
              category: task.category,
              subject: task.subject,
              priority: task.priority,
              estimatedMinutes: task.estimatedMinutes,
              actualMinutesSpent: task.actualMinutesSpent,
              isRecurring: task.isRecurring,
              isCompleted: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Autonomic Pharmacology'), findsOneWidget);
      expect(find.text('PHARM'), findsOneWidget);
      expect(find.textContaining('25m/50m'), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    });
  });

  group('PlannerScreen Widget Tests', () {
    testWidgets('renders velocity overview, subject filter chips, and priority sections', (tester) async {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final tasks = [
        DailyDeskTask(
          id: 'task_p1',
          title: 'Emergency Medicine Protocols',
          category: TaskCategory.video,
          subject: MedicalSubject.medicine,
          priority: TaskPriority.p1urgent,
          estimatedMinutes: 40,
          scheduledDate: todayStr,
        ),
        DailyDeskTask(
          id: 'task_p2',
          title: 'Pathology Slides',
          category: TaskCategory.qbank,
          subject: MedicalSubject.pathology,
          priority: TaskPriority.p2high,
          estimatedMinutes: 30,
          scheduledDate: todayStr,
        ),
      ];

      final dailyState = DailyTasksState(
        tasks: tasks,
        completedIds: const {},
        dateHistory: {todayStr: 2},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => _MockAppStateNotifier(AppState.empty)),
            dailyTasksProvider.overrideWith((ref) => _MockDailyTasksNotifier(dailyState)),
          ],
          child: const MaterialApp(
            home: PlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Study Task Planner'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Emergency Medicine Protocols'), findsOneWidget);
      expect(find.text('Pathology Slides'), findsOneWidget);
      expect(find.text('All Subjects'), findsOneWidget);
      expect(find.text('Medicine'), findsOneWidget);
      expect(find.text('PATH'), findsOneWidget);
    });

    test('DailyDeskTask block calculation and Focus To-Do fields serialization', () {
      const taskWithMins = DailyDeskTask(
        id: 'task_blocks_1',
        title: 'Pharmacology ANS',
        category: TaskCategory.video,
        estimatedMinutes: 50, // 50 ~/ 25 = 2 blocks
        actualMinutesSpent: 25, // 25 ~/ 25 = 1 block
      );

      expect(taskWithMins.effectiveEstimatedBlocks, 2);
      expect(taskWithMins.effectiveCompletedBlocks, 1);

      const taskWithExplicitBlocks = DailyDeskTask(
        id: 'task_blocks_2',
        title: 'Biochemistry Glycolysis',
        category: TaskCategory.revision,
        estimatedBlocks: 4,
        completedBlocks: 2,
        scheduledTimeSlot: '09:00 - 10:40',
      );

      expect(taskWithExplicitBlocks.effectiveEstimatedBlocks, 4);
      expect(taskWithExplicitBlocks.effectiveCompletedBlocks, 2);

      final map = taskWithExplicitBlocks.toMap();
      final restored = DailyDeskTask.fromMap(map);
      expect(restored.estimatedBlocks, 4);
      expect(restored.completedBlocks, 2);
      expect(restored.scheduledTimeSlot, '09:00 - 10:40');
    });
  });
}
