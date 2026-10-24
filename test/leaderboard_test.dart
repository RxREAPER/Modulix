import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/user_rank.dart';

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
}
