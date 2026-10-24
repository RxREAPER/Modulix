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
        createdAt: now,
      );

      final map = proj.toMap();
      final fromMap = TaskProject.fromMap(map);

      expect(fromMap.id, equals('proj-1'));
      expect(fromMap.name, equals('Internal Medicine'));
      expect(fromMap.colorHex, equals('#EF4444'));
      expect(fromMap.sortOrder, equals(1));
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
  });
}
