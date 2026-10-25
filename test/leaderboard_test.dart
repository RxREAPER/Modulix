import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/user_rank.dart';
import 'package:modulix/services/metrics_service.dart';

void main() {
  group('UserLevel Progression Hierarchy', () {
    test('Correct level mapped from cumulative hours', () {
      expect(UserLevel.fromSeconds(0), UserLevel.intern);
      expect(UserLevel.fromSeconds(24 * 3600), UserLevel.intern);
      expect(UserLevel.fromSeconds(25 * 3600), UserLevel.houseOfficer);
      expect(UserLevel.fromSeconds(75 * 3600), UserLevel.juniorResident);
      expect(UserLevel.fromSeconds(150 * 3600), UserLevel.seniorResident);
      expect(UserLevel.fromSeconds(300 * 3600), UserLevel.registrar);
      expect(UserLevel.fromSeconds(500 * 3600), UserLevel.fellow);
      expect(UserLevel.fromSeconds(750 * 3600), UserLevel.specialist);
      expect(UserLevel.fromSeconds(1000 * 3600), UserLevel.consultant);
      expect(UserLevel.fromSeconds(1500 * 3600), UserLevel.assocProfessor);
      expect(UserLevel.fromSeconds(2500 * 3600), UserLevel.professor);
      expect(UserLevel.fromSeconds(4000 * 3600), UserLevel.professor);
    });

    test('Progress to next level calculated accurately', () {
      // Junior Resident is 75h to 150h (span of 75h).
      // At 75h, progress is 0.0.
      expect(UserLevel.juniorResident.progressToNext(75 * 3600), 0.0);
      // At 112.5h (halfway), progress is 0.5.
      expect(
        UserLevel.juniorResident.progressToNext((75 + 37.5).toInt() * 3600),
        closeTo(0.5, 0.01),
      );
      // At 150h, progress is 1.0.
      expect(UserLevel.juniorResident.progressToNext(150 * 3600), 1.0);
    });

    test('Professor is terminal level with progress 1.0', () {
      expect(UserLevel.professor.nextLevel, isNull);
      expect(UserLevel.professor.progressToNext(3000 * 3600), 1.0);
      expect(UserLevel.professor.secondsRemainingToNext(3000 * 3600), 0);
    });

    test('Level shortCode formatted as Level X', () {
      expect(UserLevel.intern.shortCode, 'Level 1');
      expect(UserLevel.houseOfficer.shortCode, 'Level 2');
      expect(UserLevel.professor.shortCode, 'Level 10');
    });

    test('LeaderboardScale contains Daily, Weekly, Monthly, and Yearly', () {
      expect(LeaderboardScale.values, [
        LeaderboardScale.daily,
        LeaderboardScale.weekly,
        LeaderboardScale.monthly,
        LeaderboardScale.yearly,
      ]);
      expect(LeaderboardScale.daily.label, 'Daily');
      expect(LeaderboardScale.weekly.label, 'Weekly');
      expect(LeaderboardScale.monthly.label, 'Monthly');
      expect(LeaderboardScale.yearly.label, 'Yearly');
    });
  });

  group('LeaderboardEntry deserialization', () {
    test('Defensive json parsing handles fallback fields', () {
      final json = {
        'id': 'user-123',
        'display_name': 'Dr. Alistair',
        'daily_study_secs': 18000,
        'rank': 4,
        'avatar_color_id': 'amber',
        'avatar_icon_id': 'stethoscope',
      };

      final entry = LeaderboardEntry.fromJson(json, currentUserId: 'user-123');
      expect(entry.id, 'user-123');
      expect(entry.displayName, 'Dr. Alistair');
      expect(entry.totalSeconds, 18000);
      expect(entry.rank, 4);
      expect(entry.isCurrentUser, isTrue);
      expect(entry.formattedDuration, '5h 0m');
      expect(entry.level, UserLevel.intern);
    });
  });

  group('MetricsService 5 AM Study Period Rollovers', () {
    test('Day boundary: 03:00 AM belongs to previous day, 05:01 AM belongs to today', () {
      // 2026-10-26 is Monday
      final earlyMorning = DateTime(2026, 10, 26, 3, 0); // 3:00 AM Monday
      final pastCutoff = DateTime(2026, 10, 26, 5, 1); // 5:01 AM Monday

      expect(MetricsService.todayKey(5, earlyMorning), '2026-10-25');
      expect(MetricsService.todayKey(5, pastCutoff), '2026-10-26');

      expect(MetricsService.studyDayStart(5, earlyMorning), DateTime(2026, 10, 25, 5, 0));
      expect(MetricsService.studyDayStart(5, pastCutoff), DateTime(2026, 10, 26, 5, 0));
    });

    test('Week boundary: Monday 03:00 AM belongs to previous week, 05:01 AM starts new week', () {
      final earlyMonday = DateTime(2026, 10, 26, 3, 0); // 3:00 AM Monday
      final newWeekMonday = DateTime(2026, 10, 26, 5, 1); // 5:01 AM Monday

      // At 3 AM Monday, the week start is Monday of the PREVIOUS week (Oct 19) at 5 AM
      expect(MetricsService.studyWeekStart(5, earlyMonday), DateTime(2026, 10, 19, 5, 0));
      // At 5:01 AM Monday, the week start is TODAY Monday (Oct 26) at 5 AM
      expect(MetricsService.studyWeekStart(5, newWeekMonday), DateTime(2026, 10, 26, 5, 0));
    });

    test('Month boundary: 1st of month 03:00 AM belongs to previous month, 05:01 AM starts new month', () {
      final earlyFirstOfMonth = DateTime(2026, 11, 1, 3, 0); // 3:00 AM Nov 1
      final newMonthPastCutoff = DateTime(2026, 11, 1, 5, 1); // 5:01 AM Nov 1

      // At 3 AM on Nov 1, the study month start is Oct 1 at 5 AM
      expect(MetricsService.studyMonthStart(5, earlyFirstOfMonth), DateTime(2026, 10, 1, 5, 0));
      // At 5:01 AM on Nov 1, the study month start is Nov 1 at 5 AM
      expect(MetricsService.studyMonthStart(5, newMonthPastCutoff), DateTime(2026, 11, 1, 5, 0));
    });
  });
}
