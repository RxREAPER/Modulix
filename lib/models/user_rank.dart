import 'package:flutter/foundation.dart';

/// 10-Tier Medical Career Progression Ladder based on verified Focus Timer hours.
enum UserLevel {
  intern(
    tier: 1,
    title: 'Intern',
    shortCode: 'L1',
    requiredHours: 0,
    subtitle: 'Clinical Orientation & Ward Foundation',
  ),
  houseOfficer(
    tier: 2,
    title: 'House Officer',
    shortCode: 'L2',
    requiredHours: 25,
    subtitle: 'Active Ward Work & Clinical Routine',
  ),
  juniorResident(
    tier: 3,
    title: 'Junior Resident',
    shortCode: 'L3',
    requiredHours: 75,
    subtitle: 'Core Specialty Rotations',
  ),
  seniorResident(
    tier: 4,
    title: 'Senior Resident',
    shortCode: 'L4',
    requiredHours: 150,
    subtitle: 'ER Command & Case Presentations',
  ),
  registrar(
    tier: 5,
    title: 'Registrar',
    shortCode: 'L5',
    requiredHours: 300,
    subtitle: 'Clinical Leadership & Decision Making',
  ),
  fellow(
    tier: 6,
    title: 'Fellow',
    shortCode: 'L6',
    requiredHours: 500,
    subtitle: 'Sub-Specialty Mastery',
  ),
  specialist(
    tier: 7,
    title: 'Specialist',
    shortCode: 'L7',
    requiredHours: 750,
    subtitle: 'Independent Clinical Practice',
  ),
  consultant(
    tier: 8,
    title: 'Consultant',
    shortCode: 'L8',
    requiredHours: 1000,
    subtitle: 'Department Lead & Operative Command',
  ),
  assocProfessor(
    tier: 9,
    title: 'Assoc. Professor',
    shortCode: 'L9',
    requiredHours: 1500,
    subtitle: 'Clinical Education & Research Lead',
  ),
  professor(
    tier: 10,
    title: 'Professor',
    shortCode: 'L10',
    requiredHours: 2500,
    subtitle: 'Department Chair & Emeritus Scholar',
  );

  final int tier;
  final String title;
  final String shortCode;
  final int requiredHours;
  final String subtitle;

  const UserLevel({
    required this.tier,
    required this.title,
    required this.shortCode,
    required this.requiredHours,
    required this.subtitle,
  });

  int get requiredSeconds => requiredHours * 3600;

  UserLevel? get nextLevel {
    if (index + 1 < UserLevel.values.length) {
      return UserLevel.values[index + 1];
    }
    return null;
  }

  /// Calculates UserLevel based on cumulative focus seconds.
  static UserLevel fromSeconds(int totalSeconds) {
    final hours = totalSeconds / 3600.0;
    for (int i = UserLevel.values.length - 1; i >= 0; i--) {
      if (hours >= UserLevel.values[i].requiredHours) {
        return UserLevel.values[i];
      }
    }
    return UserLevel.intern;
  }

  /// Progress (0.0 to 1.0) towards the next tier.
  double progressToNext(int totalSeconds) {
    final next = nextLevel;
    if (next == null) return 1.0;
    final currentReq = requiredSeconds;
    final nextReq = next.requiredSeconds;
    final span = nextReq - currentReq;
    if (span <= 0) return 1.0;
    final elapsedInTier = totalSeconds - currentReq;
    return (elapsedInTier / span).clamp(0.0, 1.0);
  }

  /// Seconds remaining to unlock next level.
  int secondsRemainingToNext(int totalSeconds) {
    final next = nextLevel;
    if (next == null) return 0;
    final diff = next.requiredSeconds - totalSeconds;
    return diff > 0 ? diff : 0;
  }
}

/// Timeframe scale for competitive standings.
enum LeaderboardScale {
  daily,
  weekly,
  allTime;

  String get label {
    switch (this) {
      case LeaderboardScale.daily:
        return 'Daily';
      case LeaderboardScale.weekly:
        return 'Weekly';
      case LeaderboardScale.allTime:
        return 'All Time';
    }
  }
}

/// Leaderboard row representing a ranked doctor in the Top 20.
@immutable
class LeaderboardEntry {
  final String id;
  final String displayName;
  final int totalSeconds;
  final int rank;
  final String avatarColorId;
  final String avatarIconId;
  final bool isCurrentUser;
  final UserLevel level;

  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.totalSeconds,
    required this.rank,
    this.avatarColorId = 'indigo',
    this.avatarIconId = 'letter',
    this.isCurrentUser = false,
    required this.level,
  });

  String get formattedDuration {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  LeaderboardEntry copyWith({
    String? id,
    String? displayName,
    int? totalSeconds,
    int? rank,
    String? avatarColorId,
    String? avatarIconId,
    bool? isCurrentUser,
    UserLevel? level,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      rank: rank ?? this.rank,
      avatarColorId: avatarColorId ?? this.avatarColorId,
      avatarIconId: avatarIconId ?? this.avatarIconId,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      level: level ?? this.level,
    );
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final uid = json['id']?.toString() ?? json['user_id']?.toString() ?? '';
    final rawSecs = (json['total_seconds'] as num?)?.toInt() ??
        (json['daily_study_secs'] as num?)?.toInt() ??
        (json['weekly_study_secs'] as num?)?.toInt() ??
        (json['total_study_secs'] as num?)?.toInt() ??
        (json['secs'] as num?)?.toInt() ??
        0;
    final rankVal = (json['rank'] as num?)?.toInt() ?? 0;
    final name = json['display_name']?.toString() ??
        json['doctor_name']?.toString() ??
        json['name']?.toString() ??
        'Dr. Colleague';

    return LeaderboardEntry(
      id: uid,
      displayName: name,
      totalSeconds: rawSecs,
      rank: rankVal,
      avatarColorId: json['avatar_color_id']?.toString() ?? 'indigo',
      avatarIconId: json['avatar_icon_id']?.toString() ?? 'letter',
      isCurrentUser: currentUserId != null && currentUserId.isNotEmpty && uid == currentUserId,
      level: UserLevel.fromSeconds((json['total_study_secs'] as num?)?.toInt() ?? rawSecs),
    );
  }
}

/// Personal standing representation for the logged-in doctor.
@immutable
class UserStanding {
  final int rank;
  final int totalSeconds;
  final LeaderboardScale scale;
  final UserLevel level;
  final double percentile;
  final int secondsToTop20; // 0 if already in Top 20

  const UserStanding({
    required this.rank,
    required this.totalSeconds,
    required this.scale,
    required this.level,
    this.percentile = 0.0,
    this.secondsToTop20 = 0,
  });

  bool get isInTop20 => rank > 0 && rank <= 20;

  String get formattedDuration {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  String get formattedGapToTop20 {
    final h = secondsToTop20 ~/ 3600;
    final m = (secondsToTop20 % 3600) ~/ 60;
    if (h > 0) {
      return '+${h}h ${m}m';
    }
    return '+${m}m';
  }
}
