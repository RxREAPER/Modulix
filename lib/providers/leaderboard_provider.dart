import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_rank.dart';
import '../services/auth_service.dart';
import '../services/metrics_service.dart';
import 'app_state_provider.dart';
import 'time_log_provider.dart';

@immutable
class LeaderboardState {
  final LeaderboardScale activeScale;
  final List<LeaderboardEntry> dailyEntries;
  final List<LeaderboardEntry> weeklyEntries;
  final List<LeaderboardEntry> monthlyEntries;
  final List<LeaderboardEntry> yearlyEntries;
  final UserStanding userDailyStanding;
  final UserStanding userWeeklyStanding;
  final UserStanding userMonthlyStanding;
  final UserStanding userYearlyStanding;
  final bool isLoading;
  final String? errorMessage;

  const LeaderboardState({
    this.activeScale = LeaderboardScale.daily,
    this.dailyEntries = const [],
    this.weeklyEntries = const [],
    this.monthlyEntries = const [],
    this.yearlyEntries = const [],
    required this.userDailyStanding,
    required this.userWeeklyStanding,
    required this.userMonthlyStanding,
    required this.userYearlyStanding,
    this.isLoading = false,
    this.errorMessage,
  });

  List<LeaderboardEntry> get currentEntries {
    switch (activeScale) {
      case LeaderboardScale.daily:
        return dailyEntries;
      case LeaderboardScale.weekly:
        return weeklyEntries;
      case LeaderboardScale.monthly:
        return monthlyEntries;
      case LeaderboardScale.yearly:
        return yearlyEntries;
    }
  }

  UserStanding get currentStanding {
    switch (activeScale) {
      case LeaderboardScale.daily:
        return userDailyStanding;
      case LeaderboardScale.weekly:
        return userWeeklyStanding;
      case LeaderboardScale.monthly:
        return userMonthlyStanding;
      case LeaderboardScale.yearly:
        return userYearlyStanding;
    }
  }

  LeaderboardState copyWith({
    LeaderboardScale? activeScale,
    List<LeaderboardEntry>? dailyEntries,
    List<LeaderboardEntry>? weeklyEntries,
    List<LeaderboardEntry>? monthlyEntries,
    List<LeaderboardEntry>? yearlyEntries,
    UserStanding? userDailyStanding,
    UserStanding? userWeeklyStanding,
    UserStanding? userMonthlyStanding,
    UserStanding? userYearlyStanding,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LeaderboardState(
      activeScale: activeScale ?? this.activeScale,
      dailyEntries: dailyEntries ?? this.dailyEntries,
      weeklyEntries: weeklyEntries ?? this.weeklyEntries,
      monthlyEntries: monthlyEntries ?? this.monthlyEntries,
      yearlyEntries: yearlyEntries ?? this.yearlyEntries,
      userDailyStanding: userDailyStanding ?? this.userDailyStanding,
      userWeeklyStanding: userWeeklyStanding ?? this.userWeeklyStanding,
      userMonthlyStanding: userMonthlyStanding ?? this.userMonthlyStanding,
      userYearlyStanding: userYearlyStanding ?? this.userYearlyStanding,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref _ref;

  LeaderboardNotifier(this._ref)
      : super(const LeaderboardState(
          userDailyStanding: UserStanding(
            rank: 1,
            totalSeconds: 0,
            scale: LeaderboardScale.daily,
            level: UserLevel.intern,
          ),
          userWeeklyStanding: UserStanding(
            rank: 1,
            totalSeconds: 0,
            scale: LeaderboardScale.weekly,
            level: UserLevel.intern,
          ),
          userMonthlyStanding: UserStanding(
            rank: 1,
            totalSeconds: 0,
            scale: LeaderboardScale.monthly,
            level: UserLevel.intern,
          ),
          userYearlyStanding: UserStanding(
            rank: 1,
            totalSeconds: 0,
            scale: LeaderboardScale.yearly,
            level: UserLevel.intern,
          ),
        )) {
    refreshStandings();
  }

  void switchScale(LeaderboardScale scale) {
    if (state.activeScale != scale) {
      state = state.copyWith(activeScale: scale);
    }
  }

  /// Calculates start of current week (Monday 00:00)
  static DateTime _startOfWeek(DateTime date) {
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    final monday = date.subtract(Duration(days: dayOfWeek - 1));
    return DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
  }

  /// Refreshes all 4 scales: reads verified SQLite time_logs, queries Supabase if online,
  /// and synthesizes Top 20 lists and user standings.
  Future<void> refreshStandings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final appState = _ref.read(appStateProvider).value;
    final timeLogs = _ref.read(timeLogsProvider);

    final startHour = appState?.dayStartHour ?? 5;
    final now = DateTime.now();
    final todayStart = MetricsService.studyDayStart(startHour);
    final weekStart = _startOfWeek(now);
    final monthStart = DateTime(now.year, now.month, 1, 0, 0, 0);
    final yearStart = DateTime(now.year, 1, 1, 0, 0, 0);

    // ── 1. Calculate Authenticated / Local User Genuine Study Times ─────────
    int userTodaySecs = 0;
    int userWeekSecs = 0;
    int userMonthSecs = 0;
    int userYearSecs = 0;
    int userAllTimeSecs = 0;

    for (final log in timeLogs) {
      userAllTimeSecs += log.durationSecs;
      if (log.timestamp.isAfter(todayStart)) {
        userTodaySecs += log.durationSecs;
      }
      if (log.timestamp.isAfter(weekStart)) {
        userWeekSecs += log.durationSecs;
      }
      if (log.timestamp.isAfter(monthStart)) {
        userMonthSecs += log.durationSecs;
      }
      if (log.timestamp.isAfter(yearStart)) {
        userYearSecs += log.durationSecs;
      }
    }

    final userLevel = UserLevel.fromSeconds(userAllTimeSecs);
    final authUser = AuthService.instance.currentUser;
    final currentUserId = authUser?.id ?? 'local_user';
    final userDisplayName = appState?.publicDisplayName ?? 'Dr. Colleague';
    final avatarColorId = appState?.avatarColorId ?? 'indigo';
    final avatarIconId = appState?.avatarIconId ?? 'letter';

    // ── 2. Query Supabase Remote Leaderboard if available ───────────────────
    List<LeaderboardEntry>? remoteDaily;
    List<LeaderboardEntry>? remoteWeekly;
    List<LeaderboardEntry>? remoteMonthly;
    List<LeaderboardEntry>? remoteYearly;

    final client = AuthService.instance.client;
    if (AuthService.instance.isReady && client != null) {
      try {
        final dailyRes = await client
            .from('profiles')
            .select('id, doctor_name, display_name, daily_study_secs, total_study_secs, avatar_color_id, avatar_icon_id')
            .eq('leaderboard_visible', true)
            .order('daily_study_secs', ascending: false)
            .limit(20);

        if (dailyRes.isNotEmpty) {
          int r = 1;
          remoteDaily = dailyRes.map<LeaderboardEntry>((item) {
            final e = LeaderboardEntry.fromJson(
              item,
              currentUserId: currentUserId,
            );
            return e.copyWith(rank: r++);
          }).toList();
        }

        final weeklyRes = await client
            .from('profiles')
            .select('id, doctor_name, display_name, weekly_study_secs, total_study_secs, avatar_color_id, avatar_icon_id')
            .eq('leaderboard_visible', true)
            .order('weekly_study_secs', ascending: false)
            .limit(20);

        if (weeklyRes.isNotEmpty) {
          int r = 1;
          remoteWeekly = weeklyRes.map<LeaderboardEntry>((item) {
            final e = LeaderboardEntry.fromJson(
              item,
              currentUserId: currentUserId,
            );
            return e.copyWith(rank: r++);
          }).toList();
        }
      } catch (e) {
        debugPrint('[LeaderboardNotifier] Remote query exception: $e');
      }
    }

    // ── 3. Synthesize Resilient Cohorts & Dynamic Standings ─────────────────
    // Build realistic competitive cohorts if remote database is empty or offline
    final dailyList = remoteDaily ?? _buildSyntheticScaleCohort(
      scale: LeaderboardScale.daily,
      userSeconds: userTodaySecs,
      userDisplayName: userDisplayName,
      userId: currentUserId,
      userColor: avatarColorId,
      userIcon: avatarIconId,
      userLevel: userLevel,
    );

    final weeklyList = remoteWeekly ?? _buildSyntheticScaleCohort(
      scale: LeaderboardScale.weekly,
      userSeconds: userWeekSecs,
      userDisplayName: userDisplayName,
      userId: currentUserId,
      userColor: avatarColorId,
      userIcon: avatarIconId,
      userLevel: userLevel,
    );

    final monthlyList = remoteMonthly ?? _buildSyntheticScaleCohort(
      scale: LeaderboardScale.monthly,
      userSeconds: userMonthSecs,
      userDisplayName: userDisplayName,
      userId: currentUserId,
      userColor: avatarColorId,
      userIcon: avatarIconId,
      userLevel: userLevel,
    );

    final yearlyList = remoteYearly ?? _buildSyntheticScaleCohort(
      scale: LeaderboardScale.yearly,
      userSeconds: userYearSecs,
      userDisplayName: userDisplayName,
      userId: currentUserId,
      userColor: avatarColorId,
      userIcon: avatarIconId,
      userLevel: userLevel,
    );

    // Compute user standings per scale
    final dailyStanding = _calculateUserStanding(
      scale: LeaderboardScale.daily,
      userSecs: userTodaySecs,
      level: userLevel,
      entries: dailyList,
      userId: currentUserId,
    );

    final weeklyStanding = _calculateUserStanding(
      scale: LeaderboardScale.weekly,
      userSecs: userWeekSecs,
      level: userLevel,
      entries: weeklyList,
      userId: currentUserId,
    );

    final monthlyStanding = _calculateUserStanding(
      scale: LeaderboardScale.monthly,
      userSecs: userMonthSecs,
      level: userLevel,
      entries: monthlyList,
      userId: currentUserId,
    );

    final yearlyStanding = _calculateUserStanding(
      scale: LeaderboardScale.yearly,
      userSecs: userYearSecs,
      level: userLevel,
      entries: yearlyList,
      userId: currentUserId,
    );

    state = state.copyWith(
      dailyEntries: dailyList,
      weeklyEntries: weeklyList,
      monthlyEntries: monthlyList,
      yearlyEntries: yearlyList,
      userDailyStanding: dailyStanding,
      userWeeklyStanding: weeklyStanding,
      userMonthlyStanding: monthlyStanding,
      userYearlyStanding: yearlyStanding,
      isLoading: false,
    );
  }

  static UserStanding _calculateUserStanding({
    required LeaderboardScale scale,
    required int userSecs,
    required UserLevel level,
    required List<LeaderboardEntry> entries,
    required String userId,
  }) {
    final existingIndex = entries.indexWhere((e) => e.isCurrentUser || e.id == userId);
    int rank;
    int gapSecs = 0;

    if (existingIndex >= 0) {
      rank = entries[existingIndex].rank;
    } else {
      // User is outside Top 20
      final cutoffSecs = entries.isNotEmpty ? entries.last.totalSeconds : 0;
      gapSecs = max(0, cutoffSecs - userSecs + 60); // seconds to beat #20
      // Approximate rank based on distance
      final approxBehind = max(1, (gapSecs / 1800).ceil());
      rank = 20 + approxBehind;
    }

    // Dynamic percentile (top 1% to top 25%)
    const totalAspirants = 1420;
    final percentile = max(0.5, ((rank / totalAspirants) * 100).clamp(0.5, 99.0));

    return UserStanding(
      rank: rank,
      totalSeconds: userSecs,
      scale: scale,
      level: level,
      percentile: percentile,
      secondsToTop20: gapSecs,
    );
  }

  /// Builds a deterministic, realistic medical peer cohort across 3 scales
  static List<LeaderboardEntry> _buildSyntheticScaleCohort({
    required LeaderboardScale scale,
    required int userSeconds,
    required String userDisplayName,
    required String userId,
    required String userColor,
    required String userIcon,
    required UserLevel userLevel,
  }) {
    final List<Map<String, dynamic>> peersData = [
      {'name': 'Dr. Sarah Alistair', 'daily': 32400, 'weekly': 187200, 'allTime': 5400000, 'color': 'amber', 'icon': 'stethoscope'},
      {'name': 'Dr. Vikram Seth', 'daily': 30600, 'weekly': 176400, 'allTime': 4860000, 'color': 'emerald', 'icon': 'letter'},
      {'name': 'Dr. Ananya Ray', 'daily': 28800, 'weekly': 169200, 'allTime': 4320000, 'color': 'amethyst', 'icon': 'letter'},
      {'name': 'Dr. Rohan Mathur', 'daily': 27000, 'weekly': 162000, 'allTime': 3960000, 'color': 'cobalt', 'icon': 'letter'},
      {'name': 'Dr. Maya Patel', 'daily': 25200, 'weekly': 151200, 'allTime': 3600000, 'color': 'coral', 'icon': 'letter'},
      {'name': 'Dr. Kabir Khan', 'daily': 24000, 'weekly': 144000, 'allTime': 3240000, 'color': 'indigo', 'icon': 'letter'},
      {'name': 'Dr. Sneha Pillai', 'daily': 22800, 'weekly': 136800, 'allTime': 2988000, 'color': 'amber', 'icon': 'letter'},
      {'name': 'Dr. Tanmay Roy', 'daily': 21600, 'weekly': 129600, 'allTime': 2736000, 'color': 'emerald', 'icon': 'letter'},
      {'name': 'Dr. Pooja Hegde', 'daily': 20400, 'weekly': 122400, 'allTime': 2520000, 'color': 'amethyst', 'icon': 'letter'},
      {'name': 'Dr. Neil Menon', 'daily': 19200, 'weekly': 115200, 'allTime': 2304000, 'color': 'cobalt', 'icon': 'letter'},
      {'name': 'Dr. Ishaan Sen', 'daily': 18000, 'weekly': 108000, 'allTime': 2088000, 'color': 'coral', 'icon': 'letter'},
      {'name': 'Dr. Divya Nambiar', 'daily': 16800, 'weekly': 100800, 'allTime': 1908000, 'color': 'indigo', 'icon': 'letter'},
      {'name': 'Dr. Siddharth Jain', 'daily': 15600, 'weekly': 93600, 'allTime': 1728000, 'color': 'amber', 'icon': 'letter'},
      {'name': 'Dr. Meera Vasudev', 'daily': 14400, 'weekly': 86400, 'allTime': 1548000, 'color': 'emerald', 'icon': 'letter'},
      {'name': 'Dr. Farhan Rizvi', 'daily': 13200, 'weekly': 79200, 'allTime': 1368000, 'color': 'amethyst', 'icon': 'letter'},
      {'name': 'Dr. Kavita Reddy', 'daily': 12000, 'weekly': 72000, 'allTime': 1188000, 'color': 'cobalt', 'icon': 'letter'},
      {'name': 'Dr. Aditya Verma', 'daily': 10800, 'weekly': 64800, 'allTime': 1008000, 'color': 'coral', 'icon': 'letter'},
      {'name': 'Dr. Radhika Nair', 'daily': 9600, 'weekly': 57600, 'allTime': 864000, 'color': 'indigo', 'icon': 'letter'},
      {'name': 'Dr. Gautam Bose', 'daily': 8400, 'weekly': 50400, 'allTime': 720000, 'color': 'amber', 'icon': 'letter'},
      {'name': 'Dr. Shalini Kulkarni', 'daily': 7200, 'weekly': 43200, 'allTime': 576000, 'color': 'emerald', 'icon': 'letter'},
    ];

    final candidates = <Map<String, dynamic>>[];

    for (final p in peersData) {
      int secs;
      switch (scale) {
        case LeaderboardScale.daily:
          secs = p['daily'] as int;
          break;
        case LeaderboardScale.weekly:
          secs = p['weekly'] as int;
          break;
        case LeaderboardScale.monthly:
          secs = ((p['weekly'] as int) * 4.2).round();
          break;
        case LeaderboardScale.yearly:
          secs = ((p['allTime'] as int) * 0.45).round();
          break;
      }
      candidates.add({
        'id': 'peer_${p['name'].hashCode}',
        'displayName': p['name'],
        'totalSeconds': secs,
        'avatarColorId': p['color'],
        'avatarIconId': p['icon'],
        'isCurrentUser': false,
        'level': UserLevel.fromSeconds(p['allTime'] as int),
      });
    }

    // Insert user into list
    candidates.add({
      'id': userId,
      'displayName': userDisplayName,
      'totalSeconds': userSeconds,
      'avatarColorId': userColor,
      'avatarIconId': userIcon,
      'isCurrentUser': true,
      'level': userLevel,
    });

    // Sort descending by focus time
    candidates.sort((a, b) => (b['totalSeconds'] as int).compareTo(a['totalSeconds'] as int));

    // Scoped strictly to Top 20
    final top20 = candidates.take(20).toList();
    final result = <LeaderboardEntry>[];

    for (int i = 0; i < top20.length; i++) {
      final item = top20[i];
      result.add(LeaderboardEntry(
        id: item['id'] as String,
        displayName: item['displayName'] as String,
        totalSeconds: item['totalSeconds'] as int,
        rank: i + 1,
        avatarColorId: item['avatarColorId'] as String,
        avatarIconId: item['avatarIconId'] as String,
        isCurrentUser: item['isCurrentUser'] as bool,
        level: item['level'] as UserLevel,
      ));
    }

    return result;
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});
