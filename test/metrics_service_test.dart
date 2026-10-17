import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/services/metrics_service.dart';

void main() {
  group('MetricsService Study Day Key & Timestamp Tests', () {
    test('todayKey formats yyyy-MM-dd respecting dayStartHour and fixed now', () {
      // 3:00 AM on 2026-10-14 with 5 AM cutoff should be 2026-10-13 (previous study day)
      final earlyMorning = DateTime(2026, 10, 14, 3, 0);
      expect(MetricsService.todayKey(5, earlyMorning), '2026-10-13');

      // 6:00 AM on 2026-10-14 with 5 AM cutoff should be 2026-10-14 (current study day)
      final morning = DateTime(2026, 10, 14, 6, 0);
      expect(MetricsService.todayKey(5, morning), '2026-10-14');

      // Custom 4 AM cutoff at 3:30 AM
      final customEarly = DateTime(2026, 10, 14, 3, 30);
      expect(MetricsService.todayKey(4, customEarly), '2026-10-13');

      // Custom 4 AM cutoff at 4:30 AM
      final customLate = DateTime(2026, 10, 14, 4, 30);
      expect(MetricsService.todayKey(4, customLate), '2026-10-14');
    });

    test('studyDayStart returns expected DateTime boundary', () {
      // At 3:00 AM on Oct 14 with 5 AM cutoff, study day started Oct 13 at 5:00 AM
      final earlyMorning = DateTime(2026, 10, 14, 3, 0);
      final earlyStart = MetricsService.studyDayStart(5, earlyMorning);
      expect(earlyStart, DateTime(2026, 10, 13, 5, 0));

      // At 6:00 AM on Oct 14 with 5 AM cutoff, study day started Oct 14 at 5:00 AM
      final morning = DateTime(2026, 10, 14, 6, 0);
      final morningStart = MetricsService.studyDayStart(5, morning);
      expect(morningStart, DateTime(2026, 10, 14, 5, 0));

      // UTC variant preserves UTC flag
      final utcMorning = DateTime.utc(2026, 10, 14, 6, 0);
      final utcStart = MetricsService.studyDayStart(5, utcMorning);
      expect(utcStart.isUtc, isTrue);
      expect(utcStart, DateTime.utc(2026, 10, 14, 5, 0));
    });
  });

  group('MetricsService.computeStreak Tests', () {
    test('returns 0 current and 0 best for empty history', () {
      final result = MetricsService.computeStreak({});
      expect(result.current, 0);
      expect(result.best, 0);
    });

    test('filters out zero and negative counts from history', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      final history = {
        '2026-10-14': 0, // zero count today
        '2026-10-13': -1, // negative count
        '2026-10-12': 0,
      };
      final result = MetricsService.computeStreak(
        history,
        dayStartHour: 5,
        now: now,
      );
      expect(result.current, 0);
      expect(result.best, 0);
    });

    test('computes active streak anchored to today', () {
      final now = DateTime(2026, 10, 14, 12, 0); // today = 2026-10-14
      final history = {
        '2026-10-12': 2,
        '2026-10-13': 3,
        '2026-10-14': 1,
      };
      final result = MetricsService.computeStreak(
        history,
        dayStartHour: 5,
        now: now,
      );
      expect(result.current, 3);
      expect(result.best, 3);
    });

    test('maintains active streak when user studied yesterday but not today yet', () {
      final now = DateTime(2026, 10, 14, 12, 0); // today = 2026-10-14, yesterday = 2026-10-13
      final history = {
        '2026-10-11': 1,
        '2026-10-12': 2,
        '2026-10-13': 3,
      };
      final result = MetricsService.computeStreak(
        history,
        dayStartHour: 5,
        now: now,
      );
      expect(result.current, 3);
      expect(result.best, 3);
    });

    test('breaks streak when latest activity was 2 or more days ago', () {
      final now = DateTime(2026, 10, 14, 12, 0); // today = 2026-10-14, 2 days ago = 2026-10-12
      final history = {
        '2026-10-09': 1,
        '2026-10-10': 2,
        '2026-10-11': 3,
        '2026-10-12': 2,
      };
      final result = MetricsService.computeStreak(
        history,
        dayStartHour: 5,
        now: now,
      );
      expect(result.current, 0);
      expect(result.best, 4); // Historical best preserved
    });

    test('computes current and best streak correctly with gap in history', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      final history = {
        // Old streak of 5 days
        '2026-09-01': 1,
        '2026-09-02': 1,
        '2026-09-03': 1,
        '2026-09-04': 1,
        '2026-09-05': 1,
        // Gap...
        // Current streak of 2 days
        '2026-10-13': 2,
        '2026-10-14': 1,
      };
      final result = MetricsService.computeStreak(
        history,
        dayStartHour: 5,
        now: now,
      );
      expect(result.current, 2);
      expect(result.best, 5);
    });

    test('handles DST spring-forward transitions without breaking streak', () {
      // Daylight saving spring forward in Europe occurs last Sunday of March (2026-03-29)
      final now = DateTime(2026, 3, 30, 12, 0); // today = 2026-03-30
      final history = {
        '2026-03-28': 1,
        '2026-03-29': 1, // DST transition day
        '2026-03-30': 1,
      };
      final result = MetricsService.computeStreak(
        history,
        dayStartHour: 5,
        now: now,
      );
      expect(result.current, 3);
      expect(result.best, 3);
    });

    test('respects custom dayStartHour before and after cutoff', () {
      // At 2:00 AM on 2026-10-14 with 5 AM cutoff, today is 2026-10-13, yesterday is 2026-10-12
      final lateNight = DateTime(2026, 10, 14, 2, 0);
      final history = {
        '2026-10-12': 1,
        '2026-10-13': 2,
      };
      final result = MetricsService.computeStreak(
        history,
        dayStartHour: 5,
        now: lateNight,
      );
      // Since study day is Oct 13, activity on Oct 13 counts as today!
      expect(result.current, 2);
      expect(result.best, 2);
    });
  });

  group('MetricsService.calculateETA Calendar Date Tests', () {
    test('handles empty targetDate safely', () {
      final result = MetricsService.calculateETA(10, 5, '');
      expect(result.daysNeeded, 2);
      expect(result.daysToDeadline, isNull);
      expect(result.isOverdue, isFalse);
      expect(result.isOnTrack, isTrue);
    });

    test('same-day deadline at afternoon time is not overdue and has 0 daysToDeadline', () {
      final afternoon = DateTime(2026, 10, 14, 15, 30);
      final result = MetricsService.calculateETA(
        5,
        5,
        '2026-10-14',
        now: afternoon,
      );
      expect(result.daysToDeadline, 0);
      expect(result.isOverdue, isFalse);
      expect(result.daysNeeded, 1);
      // daysNeeded (1) > daysToDeadline (0) => off-track for finishing today, but NOT overdue
      expect(result.isOnTrack, isFalse);
    });

    test('same-day deadline with 0 remaining videos is on track', () {
      final afternoon = DateTime(2026, 10, 14, 15, 30);
      final result = MetricsService.calculateETA(
        0,
        5,
        '2026-10-14',
        now: afternoon,
      );
      expect(result.daysToDeadline, 0);
      expect(result.isOverdue, isFalse);
      expect(result.daysNeeded, 0);
      expect(result.isOnTrack, isTrue);
    });

    test('day-before deadline avoids premature off-track warning', () {
      // Current time: Oct 14 at 16:30. Deadline: Oct 15 at 00:00 (parsed date).
      // Under old raw DateTime.difference().inDays, difference was ~7.5 hours -> 0 days!
      // Under calendar date difference, difference is exactly 1 calendar day.
      final afternoon = DateTime(2026, 10, 14, 16, 30);
      final result = MetricsService.calculateETA(
        5,
        5,
        '2026-10-15',
        now: afternoon,
      );
      expect(result.daysNeeded, 1);
      expect(result.daysToDeadline, 1);
      expect(result.isOverdue, isFalse);
      expect(result.isOnTrack, isTrue);
    });

    test('past deadline is correctly marked overdue', () {
      final now = DateTime(2026, 10, 14, 10, 0);
      final result = MetricsService.calculateETA(
        10,
        5,
        '2026-10-13',
        now: now,
      );
      expect(result.daysToDeadline, -1);
      expect(result.isOverdue, isTrue);
      expect(result.isOnTrack, isFalse);
    });

    test('future deadline on track when daysNeeded <= daysToDeadline', () {
      final now = DateTime(2026, 10, 14, 10, 0);
      // 20 videos at 5/day = 4 days needed. Deadline is 6 days away (Oct 20).
      final result = MetricsService.calculateETA(
        20,
        5,
        '2026-10-20',
        now: now,
      );
      expect(result.daysNeeded, 4);
      expect(result.daysToDeadline, 6);
      expect(result.isOverdue, isFalse);
      expect(result.isOnTrack, isTrue);
    });

    test('future deadline off track when daysNeeded > daysToDeadline', () {
      final now = DateTime(2026, 10, 14, 10, 0);
      // 20 videos at 5/day = 4 days needed. Deadline is 2 days away (Oct 16).
      final result = MetricsService.calculateETA(
        20,
        5,
        '2026-10-16',
        now: now,
      );
      expect(result.daysNeeded, 4);
      expect(result.daysToDeadline, 2);
      expect(result.isOverdue, isFalse);
      expect(result.isOnTrack, isFalse);
    });
  });
}
