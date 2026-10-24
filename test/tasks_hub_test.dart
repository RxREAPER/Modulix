import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/task_item.dart';
import 'package:modulix/models/task_project.dart';
import 'package:modulix/providers/tasks_hub_provider.dart';

void main() {
  group('TaskItem Model', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime.now();
      final task = TaskItem(
        id: 'task-1',
        title: 'Complete pathology review',
        note: 'Focus on glomerulonephritis',
        dueDate: DateTime(2026, 10, 24),
        dueHour: 14,
        dueMinute: 30,
        projectId: 'proj-1',
        priority: TaskItemPriority.p1urgent,
        estimatedMinutes: 50,
        tags: ['high-yield', 'renal'],
        subTasks: const [
          SubTask(id: 'st-1', title: 'Review Robbins Chapter 14', isCompleted: true),
          SubTask(id: 'st-2', title: 'Answer 20 Q-bank questions', isCompleted: false),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final map = task.toMap();
      final fromMap = TaskItem.fromMap(map);

      expect(fromMap.id, equals('task-1'));
      expect(fromMap.title, equals('Complete pathology review'));
      expect(fromMap.priority, equals(TaskItemPriority.p1urgent));
      expect(fromMap.estimatedMinutes, equals(50));
      expect(fromMap.subTasks.length, equals(2));
      expect(fromMap.subTasks[0].isCompleted, isTrue);
      expect(fromMap.subTasks[1].isCompleted, isFalse);
      expect(fromMap.completedSubTasks, equals(1));
    });

    test('correctly identifies today, tomorrow, and this week', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final fourDaysLater = today.add(const Duration(days: 4));
      final nextMonth = today.add(const Duration(days: 40));

      final todayTask = TaskItem(
        id: '1',
        title: 'Today task',
        dueDate: today,
        createdAt: now,
        updatedAt: now,
      );
      final tomorrowTask = TaskItem(
        id: '2',
        title: 'Tomorrow task',
        dueDate: tomorrow,
        createdAt: now,
        updatedAt: now,
      );
      final weekTask = TaskItem(
        id: '3',
        title: 'Week task',
        dueDate: fourDaysLater,
        createdAt: now,
        updatedAt: now,
      );
      final farTask = TaskItem(
        id: '4',
        title: 'Far task',
        dueDate: nextMonth,
        createdAt: now,
        updatedAt: now,
      );

      expect(todayTask.isToday, isTrue);
      expect(todayTask.isTomorrow, isFalse);
      expect(todayTask.isThisWeek, isTrue);

      expect(tomorrowTask.isToday, isFalse);
      expect(tomorrowTask.isTomorrow, isTrue);
      expect(tomorrowTask.isThisWeek, isTrue);

      expect(weekTask.isToday, isFalse);
      expect(weekTask.isTomorrow, isFalse);
      expect(weekTask.isThisWeek, isTrue);

      expect(farTask.isThisWeek, isFalse);
    });
  });

  group('TaskProject Model', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime.now();
      final proj = TaskProject(
        id: 'proj-1',
        name: 'Internal Medicine',
        colorHex: '#EF4444',
        iconName: 'book',
        sortOrder: 1,
        mode: 'module',
        subjectId: 'internal-medicine',
        subjectName: 'Medicine',
        unitName: 'Cardiology',
        deadline: DateTime(2026, 11, 1),
        perDayModules: 3,
        isArchived: false,
        createdAt: now,
      );

      final map = proj.toMap();
      final fromMap = TaskProject.fromMap(map);

      expect(fromMap.id, equals('proj-1'));
      expect(fromMap.name, equals('Internal Medicine'));
      expect(fromMap.colorHex, equals('#EF4444'));
      expect(fromMap.sortOrder, equals(1));
      expect(fromMap.isModuleBased, isTrue);
      expect(fromMap.isSelfStudy, isFalse);
      expect(fromMap.subjectId, equals('internal-medicine'));
      expect(fromMap.subjectName, equals('Medicine'));
      expect(fromMap.unitName, equals('Cardiology'));
      expect(fromMap.perDayModules, equals(3));
      expect(fromMap.isArchived, isFalse);
    });

    test('serializes self-study project correctly', () {
      final now = DateTime.now();
      final proj = TaskProject(
        id: 'proj-self-1',
        name: 'General Study',
        mode: 'self_study',
        subjectId: 'general',
        subjectName: 'General Study',
        isArchived: true,
        createdAt: now,
      );

      final map = proj.toMap();
      final fromMap = TaskProject.fromMap(map);

      expect(fromMap.isSelfStudy, isTrue);
      expect(fromMap.isModuleBased, isFalse);
      expect(fromMap.isArchived, isTrue);
    });
  });

  group('TasksHubState bucketing and hours', () {
    test('computes estimated hours accurately', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final task1 = TaskItem(
        id: '1',
        title: 'T1',
        dueDate: today,
        estimatedMinutes: 60,
        createdAt: now,
        updatedAt: now,
      );
      final task2 = TaskItem(
        id: '2',
        title: 'T2',
        dueDate: today,
        estimatedMinutes: 90,
        createdAt: now,
        updatedAt: now,
      );

      final state = TasksHubState(tasks: [task1, task2]);

      expect(state.todayTasks.length, equals(2));
      expect(state.todayEstimatedHours, equals(2.5));
    });

    test('separates active and archived projects', () {
      final now = DateTime.now();
      final p1 = TaskProject(id: '1', name: 'Active', isArchived: false, createdAt: now);
      final p2 = TaskProject(id: '2', name: 'Archived', isArchived: true, createdAt: now);

      final state = TasksHubState(projects: [p1, p2]);

      expect(state.activeProjects.length, equals(1));
      expect(state.activeProjects.first.name, equals('Active'));
      expect(state.archivedProjects.length, equals(1));
      expect(state.archivedProjects.first.name, equals('Archived'));
    });

    test('separates active and completed today tasks', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final active = TaskItem(
        id: 'a1',
        title: 'Active Task',
        dueDate: today,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      final completed = TaskItem(
        id: 'c1',
        title: 'Completed Task',
        dueDate: today,
        isCompleted: true,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final state = TasksHubState(tasks: [active, completed]);

      expect(state.todayTasks.length, equals(1));
      expect(state.todayTasks.first.id, equals('a1'));
      expect(state.todayCompletedTasks.length, equals(1));
      expect(state.todayCompletedTasks.first.id, equals('c1'));
    });

    test('verifies module-based scheduling distribution across Today, Tomorrow, and Week', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      const pace = 2;

      // 5 modules
      final moduleTasks = List.generate(5, (i) {
        final dayOffset = i ~/ pace;
        return TaskItem(
          id: 'task_$i',
          title: 'Module ${i + 1}',
          dueDate: today.add(Duration(days: dayOffset)),
          createdAt: now,
          updatedAt: now,
        );
      });

      final state = TasksHubState(tasks: moduleTasks);

      // Day 0 (Today): tasks 0 and 1
      expect(state.todayTasks.map((t) => t.id).toList(), equals(['task_0', 'task_1']));

      // Day 1 (Tomorrow): tasks 2 and 3
      expect(state.tomorrowTasks.map((t) => t.id).toList(), equals(['task_2', 'task_3']));

      // Day 2 (Day after tomorrow): task 4 (isThisWeek should include all 5)
      expect(state.thisWeekTasks.length, equals(5));
    });

    test('verifies tomorrowCompletedTasks and thisWeekCompletedTasks getters', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final threeDaysLater = today.add(const Duration(days: 3));

      final tomorrowCompleted = TaskItem(
        id: 'tc1',
        title: 'Completed Tomorrow Task',
        dueDate: tomorrow,
        isCompleted: true,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final weekCompleted = TaskItem(
        id: 'wc1',
        title: 'Completed Week Task',
        dueDate: threeDaysLater,
        isCompleted: true,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final activeTomorrow = TaskItem(
        id: 'ta1',
        title: 'Active Tomorrow Task',
        dueDate: tomorrow,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final state = TasksHubState(tasks: [tomorrowCompleted, weekCompleted, activeTomorrow]);

      expect(state.tomorrowTasks.length, equals(1));
      expect(state.tomorrowTasks.first.id, equals('ta1'));
      expect(state.tomorrowCompletedTasks.length, equals(1));
      expect(state.tomorrowCompletedTasks.first.id, equals('tc1'));

      expect(state.thisWeekTasks.length, equals(1));
      expect(state.thisWeekTasks.first.id, equals('ta1'));
      expect(state.thisWeekCompletedTasks.length, equals(2));
      expect(state.thisWeekCompletedTasks.map((t) => t.id).toSet(), equals({'tc1', 'wc1'}));
    });
  });
}
