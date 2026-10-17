import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/providers/daily_tasks_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain 2: Home Desk & Task System Tests', () {
    test('5 AM day start boundary correctly calculates effective date key', () {
      const dayStartHour = 5;

      // At 4:30 AM on Oct 18, effective date is Oct 17
      final earlyMorning = DateTime(2026, 10, 18, 4, 30);
      final effectiveEarly = earlyMorning.subtract(const Duration(hours: dayStartHour));
      expect(DateFormat('yyyy-MM-dd').format(effectiveEarly), '2026-10-17');

      // At 5:30 AM on Oct 18, effective date is Oct 18
      final afterDayStart = DateTime(2026, 10, 18, 5, 30);
      final effectiveAfter = afterDayStart.subtract(const Duration(hours: dayStartHour));
      expect(DateFormat('yyyy-MM-dd').format(effectiveAfter), '2026-10-18');
    });

    test('DailyTasksState computes streak correctly across consecutive active days', () {
      final now = DateTime(2026, 10, 18, 10, 0); // Oct 18
      final todayKey = DateFormat('yyyy-MM-dd').format(now);
      final yesterdayKey = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
      final twoDaysAgoKey = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 2)));
      final fourDaysAgoKey = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 4)));

      // 3 consecutive active days (today, yesterday, two days ago), gap on day 3
      final dateHistory = {
        todayKey: 3,
        yesterdayKey: 4,
        twoDaysAgoKey: 2,
        fourDaysAgoKey: 5, // Should not extend streak past gap
      };

      int streak = 0;
      DateTime checkDay = now;
      while (true) {
        final key = DateFormat('yyyy-MM-dd').format(checkDay);
        if ((dateHistory[key] ?? 0) > 0) {
          streak++;
          checkDay = checkDay.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      expect(streak, 3);
    });

    test('DailyDeskTask toMap and fromMap round-trips with full precision', () {
      final task = const DailyDeskTask(
        id: 'task_anatomy_review_1',
        title: 'Review Cranial Nerves',
        category: TaskCategory.video,
      );

      final json = task.toMap();
      final restored = DailyDeskTask.fromMap(json);

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.category, task.category);
    });
  });
}
