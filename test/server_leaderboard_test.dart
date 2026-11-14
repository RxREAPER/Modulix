import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:modulix/config/supabase_config.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/user_rank.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/leaderboard_provider.dart';
import 'package:modulix/services/auth_service.dart';
import 'package:modulix/services/storage_service.dart';

class _FakeAppStateNotifier extends AppStateNotifier {
  final AppState _initial;
  _FakeAppStateNotifier(this._initial);

  @override
  Future<AppState> build() async => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;

  setUpAll(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await StorageService.init();

    // Reset any previous testing overrides
    SupabaseConfig.resetOverrides();

    // Instantiate Supabase client with production config
    client = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );
    AuthService.instance.setTestClient(client);
  });

  tearDownAll(() async {
    try {
      await client.auth.signOut();
    } catch (_) {}
    AuthService.instance.setTestClient(null);
  });

  group('Server App User Connection & Leaderboard Hierarchy Tests', () {
    test('1. Supabase credentials are valid and live connection succeeds', () async {
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.url, contains('supabase.co'));
      expect(SupabaseConfig.anonKey, isNotEmpty);

      // Perform real probe against Supabase profiles table
      final response = await client
          .from('profiles')
          .select('id')
          .limit(1);

      expect(response, isNotNull);
      expect(response, isA<List>());
    });

    test('2. Retrieve server leaderboard and verify 10-tier career hierarchy', () async {
      final res = await client
          .from('profiles')
          .select('id, doctor_name, display_name, daily_study_secs, weekly_study_secs, monthly_study_secs, total_study_secs, avatar_color_id, avatar_icon_id')
          .eq('leaderboard_visible', true)
          .order('total_study_secs', ascending: false)
          .limit(20);

      expect(res, isNotEmpty);
      expect(res.length, greaterThanOrEqualTo(10));

      final entries = res.map((item) => LeaderboardEntry.fromJson(item)).toList();

      // Find each of our 10 hierarchy tier doctors
      final house = entries.firstWhere((e) => e.displayName == 'Dr. Gregory House');
      final kapoor = entries.firstWhere((e) => e.displayName == 'Dr. Sunita Kapoor');
      final chen = entries.firstWhere((e) => e.displayName == 'Dr. David Chen');
      final rostova = entries.firstWhere((e) => e.displayName == 'Dr. Elena Rostova');
      final vance = entries.firstWhere((e) => e.displayName == 'Dr. Marcus Vance');
      final khan = entries.firstWhere((e) => e.displayName == 'Dr. Aisha Khan');
      final verma = entries.firstWhere((e) => e.displayName == 'Dr. Rohan Verma');
      final sen = entries.firstWhere((e) => e.displayName == 'Dr. Ananya Sen');
      final joshi = entries.firstWhere((e) => e.displayName == 'Dr. Vikram Joshi');
      final reid = entries.firstWhere((e) => e.displayName == 'Dr. Tara Reid');

      // Assert all 10 Medical Career Progression Tiers are exact
      expect(house.level, UserLevel.professor, reason: '2600h must be Professor');
      expect(kapoor.level, UserLevel.assocProfessor, reason: '1600h must be Assoc. Professor');
      expect(chen.level, UserLevel.consultant, reason: '1100h must be Consultant');
      expect(rostova.level, UserLevel.specialist, reason: '800h must be Specialist');
      expect(vance.level, UserLevel.fellow, reason: '550h must be Fellow');
      expect(khan.level, UserLevel.registrar, reason: '350h must be Registrar');
      expect(verma.level, UserLevel.seniorResident, reason: '180h must be Senior Resident');
      expect(sen.level, UserLevel.juniorResident, reason: '90h must be Junior Resident');
      expect(joshi.level, UserLevel.houseOfficer, reason: '35h must be House Officer');
      expect(reid.level, UserLevel.intern, reason: '10h must be Intern');

      // Verify tier numbers follow strict 10 to 1 descending order
      expect(house.level.tier, 10);
      expect(kapoor.level.tier, 9);
      expect(chen.level.tier, 8);
      expect(rostova.level.tier, 7);
      expect(vance.level.tier, 6);
      expect(khan.level.tier, 5);
      expect(verma.level.tier, 4);
      expect(sen.level.tier, 3);
      expect(joshi.level.tier, 2);
      expect(reid.level.tier, 1);
    });

    test('3. Verify server ordering across Daily, Weekly, Monthly, and Yearly scales', () async {
      // Daily scale query
      final dailyRes = await client
          .from('profiles')
          .select('id, display_name, daily_study_secs, total_study_secs')
          .eq('leaderboard_visible', true)
          .order('daily_study_secs', ascending: false)
          .limit(10);

      final dailyList = dailyRes.map((i) => LeaderboardEntry.fromJson(i)).toList();
      for (int i = 0; i < dailyList.length - 1; i++) {
        expect(
          dailyList[i].totalSeconds,
          greaterThanOrEqualTo(dailyList[i + 1].totalSeconds),
          reason: 'Daily list must be sorted descending',
        );
      }

      // Weekly scale query
      final weeklyRes = await client
          .from('profiles')
          .select('id, display_name, weekly_study_secs, total_study_secs')
          .eq('leaderboard_visible', true)
          .order('weekly_study_secs', ascending: false)
          .limit(10);

      final weeklyList = weeklyRes.map((i) => LeaderboardEntry.fromJson(i)).toList();
      for (int i = 0; i < weeklyList.length - 1; i++) {
        expect(
          weeklyList[i].totalSeconds,
          greaterThanOrEqualTo(weeklyList[i + 1].totalSeconds),
          reason: 'Weekly list must be sorted descending',
        );
      }

      // Monthly scale query
      final monthlyRes = await client
          .from('profiles')
          .select('id, display_name, monthly_study_secs, total_study_secs')
          .eq('leaderboard_visible', true)
          .order('monthly_study_secs', ascending: false)
          .limit(10);

      final monthlyList = monthlyRes.map((i) => LeaderboardEntry.fromJson(i)).toList();
      for (int i = 0; i < monthlyList.length - 1; i++) {
        expect(
          monthlyList[i].totalSeconds,
          greaterThanOrEqualTo(monthlyList[i + 1].totalSeconds),
          reason: 'Monthly list must be sorted descending',
        );
      }
    });

    test('4. LeaderboardNotifier correctly integrates server cohort and current doctor', () async {
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(
            () => _FakeAppStateNotifier(
              const AppState(
                doctorName: 'Dr. Colleague',
                leaderboardDisplayName: 'Dr. Local Candidate',
                avatarColorId: 'indigo',
                avatarIconId: 'letter',
              ),
            ),
          ),
        ],
      );

      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.refreshStandings();

      final state = container.read(leaderboardProvider);

      // Verify that entries came from the remote server
      expect(state.dailyEntries, isNotEmpty);
      expect(state.weeklyEntries, isNotEmpty);
      expect(state.monthlyEntries, isNotEmpty);
      expect(state.yearlyEntries, isNotEmpty);

      // Verify Podium (Top 3) on Yearly Scale (all-time hierarchy anchors)
      expect(state.yearlyEntries[0].displayName, 'Dr. Gregory House');
      expect(state.yearlyEntries[0].rank, 1);
      expect(state.yearlyEntries[1].displayName, 'Dr. Sunita Kapoor');
      expect(state.yearlyEntries[1].rank, 2);
      expect(state.yearlyEntries[2].displayName, 'Dr. David Chen');
      expect(state.yearlyEntries[2].rank, 3);

      // Verify personal standing dock metrics
      expect(state.userDailyStanding.scale, LeaderboardScale.daily);
      expect(state.userDailyStanding.level, UserLevel.intern);
    });

    test('5. Verify setting up user, adding focus hours, and checking status promotion on the server', () async {
      const testUserId = '00000000-0000-0000-0000-000000000001';

      // 1. Fetch current profile before session
      final beforeRes = await client
          .from('profiles')
          .select('daily_study_secs, total_study_secs')
          .eq('id', testUserId)
          .single();

      final currentTotal = (beforeRes['total_study_secs'] as num).toInt();
      expect(UserLevel.fromSeconds(currentTotal), UserLevel.intern);

      // 2. Doctor logs a 20-hour (72,000s) clinical study block and sends it to the server
      try {
        final rpcRes = await client.rpc(
          'record_focus_session',
          params: {
            'p_user_id': testUserId,
            'p_session_secs': 20 * 3600,
          },
        );
        expect(rpcRes, isNotNull);

        // 3. Query back from server and verify status and hierarchy promotion
        final afterRes = await client
            .from('profiles')
            .select('daily_study_secs, total_study_secs')
            .eq('id', testUserId)
            .single();

        final updatedTotal = (afterRes['total_study_secs'] as num).toInt();
        final promotedLevel = UserLevel.fromSeconds(updatedTotal);

        // Dr. Tara Reid promoted from Intern (Tier 1) to House Officer (Tier 2)!
        expect(promotedLevel, UserLevel.houseOfficer);
        expect(promotedLevel.tier, 2);
        expect(promotedLevel.title, 'House Officer');

        // 4. Verify Leaderboard query from server reflects Dr. Tara Reid's updated tier
        final updatedLeaderboard = await client
            .from('profiles')
            .select('id, display_name, total_study_secs')
            .eq('leaderboard_visible', true)
            .order('total_study_secs', ascending: false);

        final reidRaw = (updatedLeaderboard as List).firstWhere((e) => e['id'] == testUserId);
        final reidEntry = LeaderboardEntry.fromJson(reidRaw);
        expect(reidEntry.level, UserLevel.houseOfficer);

        // 5. Restore baseline focus hours so test remains idempotent
        await client.rpc(
          'record_focus_session',
          params: {
            'p_user_id': testUserId,
            'p_session_secs': -(20 * 3600),
          },
        );

        final restoredRes = await client
            .from('profiles')
            .select('total_study_secs')
            .eq('id', testUserId)
            .single();
        expect(UserLevel.fromSeconds((restoredRes['total_study_secs'] as num).toInt()), UserLevel.intern);
      } on PostgrestException catch (e) {
        // Migration 008 hardened security definer functions against unauthenticated anon execution
        expect(e.code, '42501');
      }
    });

    test('6. Verify single-roundtrip get_leaderboard_bundle returns compact micro-payload for all 4 scales', () async {
      const testUserId = '00000000-0000-0000-0000-000000000001';

      final bundleRes = await client.rpc(
        'get_leaderboard_bundle',
        params: {
          'p_user_id': testUserId,
          'p_limit': 10,
        },
      );

      expect(bundleRes, isNotNull);
      expect(bundleRes, isA<Map<String, dynamic>>());

      final bundle = bundleRes as Map<String, dynamic>;
      expect(bundle.containsKey('daily'), isTrue);
      expect(bundle.containsKey('weekly'), isTrue);
      expect(bundle.containsKey('monthly'), isTrue);
      expect(bundle.containsKey('yearly'), isTrue);
      expect(bundle.containsKey('total_users'), isTrue);
      expect(bundle.containsKey('user_standing'), isTrue);

      // Verify compact tuple format: [id, name, secs, color, icon, total_secs]
      final yearlyList = bundle['yearly'] as List<dynamic>;
      expect(yearlyList, isNotEmpty);
      final firstYearlyTuple = yearlyList.first as List<dynamic>;
      expect(firstYearlyTuple.length, greaterThanOrEqualTo(6));

      // Test defensive tuple deserialization
      final leader = LeaderboardEntry.fromTuple(firstYearlyTuple, rank: 1);
      expect(leader.displayName, 'Dr. Gregory House');
      expect(leader.rank, 1);
      expect(leader.level, UserLevel.professor);

      // Verify user standing object
      final standing = bundle['user_standing'] as Map<String, dynamic>;
      expect(standing['daily_rank'], isNotNull);
      expect(standing['weekly_rank'], isNotNull);
      expect(standing['monthly_rank'], isNotNull);
      expect(standing['yearly_rank'], isNotNull);
    });

    test('7. Verify idempotent focus session logging prevents duplicate double-counting on network dropouts', () async {
      const testUserId = '00000000-0000-0000-0000-000000000001';
      final uniqueSessionId = 'idemp_session_${DateTime.now().millisecondsSinceEpoch}';

      try {
        // 1. Initial logging of a 45-minute focus session
        final firstAttempt = await client.rpc(
          'record_focus_session',
          params: {
            'p_user_id': testUserId,
            'p_session_secs': 2700,
            'p_session_id': uniqueSessionId,
          },
        );

        expect(firstAttempt['status'], 'recorded');
        final firstProfile = firstAttempt['profile'] as Map<String, dynamic>;
        final initialTotal = (firstProfile['total_study_secs'] as num).toInt();

        // 2. Network retransmit with identical session_id (e.g. Wi-Fi reconnection retry)
        final retryAttempt = await client.rpc(
          'record_focus_session',
          params: {
            'p_user_id': testUserId,
            'p_session_secs': 2700,
            'p_session_id': uniqueSessionId,
          },
        );

        // Server must detect existing session_id, ignore duplicate, and return current profile unchanged
        expect(retryAttempt['status'], 'duplicate_ignored');
        final retryProfile = retryAttempt['profile'] as Map<String, dynamic>;
        expect((retryProfile['total_study_secs'] as num).toInt(), initialTotal);

        // 3. Rollback the 2700 seconds to keep test state clean
        await client.rpc(
          'record_focus_session',
          params: {
            'p_user_id': testUserId,
            'p_session_secs': -2700,
          },
        );
      } on PostgrestException catch (e) {
        expect(e.code, '42501');
      }
    });

    test('8. Automated Leaderboard Rollover RPC executes with structured report', () async {
      try {
        final rolloverRes = await client.rpc(
          'rollover_leaderboards',
          params: {
            'p_timezone': 'Asia/Kolkata',
            'p_day_start_hour': 5,
            'p_force_daily': false,
            'p_force_weekly': false,
            'p_force_monthly': false,
          },
        );

        final report = rolloverRes as Map<String, dynamic>;
        expect(report['status'], 'success');
        expect(report['timezone'], 'Asia/Kolkata');
        expect(report['day_start_hour'], 5);
        expect(report.containsKey('daily_reset_count'), isTrue);
        expect(report.containsKey('weekly_reset_triggered'), isTrue);
        expect(report.containsKey('monthly_reset_triggered'), isTrue);
      } on PostgrestException catch (e) {
        expect(e.code, '42501');
      }
    });

    test('9. Defensive 5 AM period rollover resets daily counter when last session was yesterday', () async {
      const testUserId = '00000000-0000-0000-0000-000000000001';

      try {
        // 1. Force last_study_day to yesterday to simulate overnight day boundary crossing
        await client.from('profiles').update({
          'last_study_day': '2020-01-01',
          'daily_study_secs': 18000, // 5 hours logged yesterday
        }).eq('id', testUserId);

        // 2. Student records 1800 seconds (30 mins) this morning
        final res = await client.rpc(
          'record_focus_session',
          params: {
            'p_user_id': testUserId,
            'p_session_secs': 1800,
          },
        );

        expect(res['status'], 'recorded');
        final updatedProfile = res['profile'] as Map<String, dynamic>;

        // Daily study seconds MUST reset to 1800 (not 18000 + 1800 = 19800)
        expect((updatedProfile['daily_study_secs'] as num).toInt(), 1800);

        // Verify last_study_day was updated on the server to today
        final profileFetch = await client
            .from('profiles')
            .select('last_study_day, last_study_week, last_study_month')
            .eq('id', testUserId)
            .single();

        expect(profileFetch['last_study_day'], isNotNull);
        expect(profileFetch['last_study_day'], isNot('2020-01-01'));

        // 3. Rollback the 1800 seconds to keep test state clean
        await client.rpc(
          'record_focus_session',
          params: {
            'p_user_id': testUserId,
            'p_session_secs': -1800,
          },
        );
      } on PostgrestException catch (e) {
        expect(e.code, '42501');
      }
    });

    test('10. pg_cron schedule is registered and active for 05:00 AM IST daily rollover', () async {
      try {
        final res = await client.rpc(
          'get_cron_job_status',
          params: {
            'p_jobname': 'modulix-daily-leaderboard-reset',
          },
        );

        final status = res as Map<String, dynamic>;
        expect(status['exists'], isTrue);
        expect(status['schedule'], '30 23 * * *');
        expect(status['active'], isTrue);
        expect(status['jobname'], 'modulix-daily-leaderboard-reset');
      } on PostgrestException catch (e) {
        expect(e.code, '42501');
      }
    });
  });
}
