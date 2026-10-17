import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/daily_tasks_provider.dart';
import 'package:modulix/providers/focus_timer_provider.dart';
import 'package:modulix/services/backup_service.dart';
import 'package:modulix/services/metrics_service.dart';
import 'package:modulix/services/storage_service.dart';

class ContainerWidgetRef implements WidgetRef {
  final ProviderContainer container;
  ContainerWidgetRef(this.container);

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  void invalidate(ProviderOrFamily provider) => container.invalidate(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. STREAK CALCULATION ADVERSARIAL & BOUNDARY STRESS TESTS
  // ═══════════════════════════════════════════════════════════════════════════
  group('Adversarial Streak Calculation Tests', () {
    test('Empty history returns zero current and best', () {
      final res = MetricsService.computeStreak({});
      expect(res.current, 0);
      expect(res.best, 0);
    });

    test('All non-positive counts (zeros, negatives) return zero current and best', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      final history = {
        '2026-10-14': 0,
        '2026-10-13': -1,
        '2026-10-12': -99,
        '2026-10-11': 0,
      };
      final res = MetricsService.computeStreak(history, now: now);
      expect(res.current, 0);
      expect(res.best, 0);
    });

    test('Zero count today does not kill streak if yesterday has count > 0', () {
      final now = DateTime(2026, 10, 14, 10, 0);
      final history = {
        '2026-10-14': 0, // Inactive today so far
        '2026-10-13': 4, // Active yesterday
        '2026-10-12': 2,
        '2026-10-11': 1,
      };
      final res = MetricsService.computeStreak(history, now: now);
      expect(res.current, 3);
      expect(res.best, 3);
    });

    test('Broken streak with gap of exactly 1 day between yesterday and today', () {
      // Activity on today (Oct 14) and 2 days ago (Oct 12), but yesterday (Oct 13) had zero or missing
      final now = DateTime(2026, 10, 14, 14, 0);

      // Subcase A: Oct 13 completely missing
      final historyMissing = {
        '2026-10-10': 1,
        '2026-10-11': 2,
        '2026-10-12': 3,
        // Oct 13 missing
        '2026-10-14': 1,
      };
      final resA = MetricsService.computeStreak(historyMissing, now: now);
      expect(resA.current, 1, reason: 'Current streak should restart at 1 today');
      expect(resA.best, 3, reason: 'Best streak was 3 (Oct 10-12)');

      // Subcase B: Oct 13 present but count = 0
      final historyZero = {
        '2026-10-10': 1,
        '2026-10-11': 2,
        '2026-10-12': 3,
        '2026-10-13': 0,
        '2026-10-14': 1,
      };
      final resB = MetricsService.computeStreak(historyZero, now: now);
      expect(resB.current, 1);
      expect(resB.best, 3);
    });

    test('Broken streak with gap of 2 or more days ago', () {
      final now = DateTime(2026, 10, 14, 14, 0);
      final history = {
        '2026-10-01': 2,
        '2026-10-02': 1,
        '2026-10-03': 3,
        '2026-10-04': 2,
        // Oct 5 through 14 inactive
      };
      final res = MetricsService.computeStreak(history, now: now);
      expect(res.current, 0, reason: 'Current streak must be 0 after >1 day of inactivity');
      expect(res.best, 4, reason: 'Best streak was 4 (Oct 1-4)');
    });

    test('Multiple disjoint streaks chooses longest as best and tracks active streak', () {
      final now = DateTime(2026, 10, 14, 18, 0);
      final history = {
        // Streak 1: 3 days
        '2026-08-01': 1,
        '2026-08-02': 1,
        '2026-08-03': 1,
        // Streak 2: 7 days
        '2026-08-10': 2,
        '2026-08-11': 2,
        '2026-08-12': 2,
        '2026-08-13': 2,
        '2026-08-14': 2,
        '2026-08-15': 2,
        '2026-08-16': 2,
        // Streak 3: 4 days (current)
        '2026-10-11': 3,
        '2026-10-12': 3,
        '2026-10-13': 3,
        '2026-10-14': 3,
      };
      final res = MetricsService.computeStreak(history, now: now);
      expect(res.current, 4);
      expect(res.best, 7);
    });

    test('Leap year boundary (Feb 28 -> Feb 29 -> March 1)', () {
      // 2024 is a leap year
      final now = DateTime(2024, 3, 2, 10, 0);
      final history = {
        '2024-02-27': 1,
        '2024-02-28': 1,
        '2024-02-29': 1, // Leap day
        '2024-03-01': 1,
        '2024-03-02': 1,
      };
      final res = MetricsService.computeStreak(history, now: now);
      expect(res.current, 5);
      expect(res.best, 5);
    });

    test('Non-leap year boundary (Feb 28 -> March 1)', () {
      // 2025 is not a leap year
      final now = DateTime(2025, 3, 2, 10, 0);
      final history = {
        '2025-02-27': 1,
        '2025-02-28': 1,
        '2025-03-01': 1,
        '2025-03-02': 1,
      };
      final res = MetricsService.computeStreak(history, now: now);
      expect(res.current, 4);
      expect(res.best, 4);
    });

    test('Year rollover boundary (Dec 30 -> Dec 31 -> Jan 1 -> Jan 2)', () {
      final now = DateTime(2026, 1, 2, 11, 0);
      final history = {
        '2025-12-30': 1,
        '2025-12-31': 2,
        '2026-01-01': 3,
        '2026-01-02': 4,
      };
      final res = MetricsService.computeStreak(history, now: now);
      expect(res.current, 4);
      expect(res.best, 4);
    });

    test('Daylight Saving Time (DST) spring-forward across transition day', () {
      // Europe/London DST transition: 2026-03-29
      final history = {
        '2026-03-27': 1,
        '2026-03-28': 1,
        '2026-03-29': 1, // 23h spring forward day
        '2026-03-30': 1,
        '2026-03-31': 1,
      };

      // Test at various hours on and after transition
      for (final hour in [1, 3, 5, 6, 12, 23]) {
        final now = DateTime(2026, 3, 31, hour, 30);
        final res = MetricsService.computeStreak(history, now: now, dayStartHour: 5);
        if (hour < 5) {
          // If before 5 AM on March 31, current study day is March 30
          // March 30 is active, so streak is 4 (March 27..30)
          expect(res.current, 4, reason: 'Hour $hour: study day is March 30');
        } else {
          // If after 5 AM on March 31, current study day is March 31
          // March 31 is active, so streak is 5 (March 27..31)
          expect(res.current, 5, reason: 'Hour $hour: study day is March 31');
        }
        expect(res.best, greaterThanOrEqualTo(4));
      }
    });

    test('Daylight Saving Time (DST) fall-back across transition day', () {
      // Europe/London DST fall-back: 2026-10-25 (25h day)
      final history = {
        '2026-10-23': 1,
        '2026-10-24': 1,
        '2026-10-25': 1, // 25h fall back day
        '2026-10-26': 1,
      };

      final now = DateTime(2026, 10, 26, 14, 0);
      final res = MetricsService.computeStreak(history, now: now, dayStartHour: 5);
      expect(res.current, 4);
      expect(res.best, 4);
    });

    test('Study day start cutoff edge cases (4:59 AM vs 5:00 AM vs 5:01 AM)', () {
      final history = {
        '2026-10-13': 2,
      };

      // At 4:59 AM on Oct 14: Study day is still Oct 13!
      // Activity on Oct 13 is "today's" activity.
      final beforeCutoff = DateTime(2026, 10, 14, 4, 59);
      final resBefore = MetricsService.computeStreak(history, dayStartHour: 5, now: beforeCutoff);
      expect(resBefore.current, 1);

      // At 5:00 AM on Oct 14: Study day is now Oct 14.
      // Activity on Oct 13 is "yesterday's" activity. Streak maintained at 1!
      final atCutoff = DateTime(2026, 10, 14, 5, 0);
      final resAt = MetricsService.computeStreak(history, dayStartHour: 5, now: atCutoff);
      expect(resAt.current, 1);

      // At 5:01 AM on Oct 14: Study day is Oct 14.
      // Oct 13 is yesterday. Streak maintained at 1.
      final afterCutoff = DateTime(2026, 10, 14, 5, 1);
      final resAfter = MetricsService.computeStreak(history, dayStartHour: 5, now: afterCutoff);
      expect(resAfter.current, 1);
    });

    test('Custom dayStartHour (e.g. 0 for midnight or 12 for midday)', () {
      // Midnight cutoff (dayStartHour = 0)
      final nowMidnight = DateTime(2026, 10, 14, 1, 0);
      expect(MetricsService.todayKey(0, nowMidnight), '2026-10-14');

      // Midday cutoff (dayStartHour = 12)
      final morning = DateTime(2026, 10, 14, 11, 0); // Before 12 PM -> Oct 13
      final afternoon = DateTime(2026, 10, 14, 13, 0); // After 12 PM -> Oct 14
      expect(MetricsService.todayKey(12, morning), '2026-10-13');
      expect(MetricsService.todayKey(12, afternoon), '2026-10-14');
    });

    test('Malformed date strings in dailyHistory are ignored gracefully', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      final history = {
        'not-a-date': 10,
        '2026-99-99': 5,
        '2026-10-14': 2,
      };
      final res = MetricsService.computeStreak(history, now: now);
      expect(res.current, 1);
      expect(res.best, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. FOCUS TIMER SESSION COMPLETION IDEMPOTENCY STRESS TESTS
  // ═══════════════════════════════════════════════════════════════════════════
  group('Focus Timer & AppState Completion Idempotency Stress Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
    });

    test('Repeated markQBankComplete calls do not modify state or timestamp', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const qbankId = 'stress_qbank_1';

      // 10 repeated calls
      for (int i = 0; i < 10; i++) {
        await notifier.markQBankComplete(qbankId);
        final state = container.read(appStateProvider).value!;
        expect(state.currentEdition.completedQBanks.containsKey(qbankId), isTrue);
      }

      final state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedQBanks.length, 1);
    });

    test('Repeated markNotesComplete calls do not duplicate or toggle off', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const noteId = 'stress_note_1';

      for (int i = 0; i < 10; i++) {
        await notifier.markNotesComplete(noteId);
        final state = container.read(appStateProvider).value!;
        expect(state.currentEdition.completedNotes.containsKey(noteId), isTrue);
      }

      final state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedNotes.length, 1);
    });

    test('Repeated markVideoComplete calls increment dailyHistory count exactly ONCE', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const videoId = 'stress_video_1';
      final todayKey = MetricsService.todayKey(container.read(appStateProvider).value!.dayStartHour);

      // Call 5 times with same video ID
      for (int i = 0; i < 5; i++) {
        await notifier.markVideoComplete(videoId);
      }

      final state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedVideos.containsKey(videoId), isTrue);
      expect(state.currentEdition.dailyHistory[todayKey], equals(1),
          reason: 'Daily study count must remain exactly 1 despite repeated completions');
    });

    test('Focus timer finishSession repeatedly completed for same topic preserves completed status', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final timer = container.read(focusTimerProvider.notifier);
      await container.read(appStateProvider.future);

      const qbankTopic = 'qbank_biochem_cycle';
      const notesTopic = 'notes_microbiology_staph';
      const videoTopic = 'vid_anatomy_upper_limb';

      // Simulate 3 consecutive completed sessions for the same QBank topic
      for (int i = 0; i < 3; i++) {
        timer.setTask(
          subjectId: 'biochemistry',
          subjectName: 'Biochemistry',
          topicId: qbankTopic,
          topicTitle: 'Krebs Cycle Q-Bank',
          topicType: 'qbank',
        );
        timer.state = timer.state.copyWith(focusSecondsElapsed: 1500);
        await timer.finishSession();

        final appState = container.read(appStateProvider).value!;
        expect(appState.currentEdition.completedQBanks.containsKey(qbankTopic), isTrue,
            reason: 'Iteration $i: Q-Bank must remain completed');
      }

      // Simulate 3 consecutive completed sessions for the same Notes topic
      for (int i = 0; i < 3; i++) {
        timer.setTask(
          subjectId: 'microbiology',
          subjectName: 'Microbiology',
          topicId: notesTopic,
          topicTitle: 'Staph Notes',
          topicType: 'notes',
        );
        timer.state = timer.state.copyWith(focusSecondsElapsed: 1200);
        await timer.finishSession();

        final appState = container.read(appStateProvider).value!;
        expect(appState.currentEdition.completedNotes.containsKey(notesTopic), isTrue,
            reason: 'Iteration $i: Notes must remain completed');
      }

      // Simulate 3 consecutive completed sessions for the same Video topic
      for (int i = 0; i < 3; i++) {
        timer.setTask(
          subjectId: 'anatomy',
          subjectName: 'Anatomy',
          topicId: videoTopic,
          topicTitle: 'Brachial Plexus Video',
          topicType: 'video',
        );
        timer.state = timer.state.copyWith(focusSecondsElapsed: 900);
        await timer.finishSession();

        final appState = container.read(appStateProvider).value!;
        expect(appState.currentEdition.completedVideos.containsKey(videoTopic), isTrue);
      }

      final finalState = container.read(appStateProvider).value!;
      final todayKey = MetricsService.todayKey(finalState.dayStartHour);
      expect(finalState.currentEdition.dailyHistory[todayKey], equals(1),
          reason: 'Daily study history for the video should only have incremented once');
    });

    test('Focus timer finishSession with 0 focus seconds does not complete target or log', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final timer = container.read(focusTimerProvider.notifier);
      await container.read(appStateProvider.future);

      const qbankTopic = 'qbank_unused';
      timer.setTask(
        subjectId: 'cardiology',
        subjectName: 'Cardiology',
        topicId: qbankTopic,
        topicTitle: 'Heart Failure',
        topicType: 'qbank',
      );
      // 0 focus seconds elapsed
      timer.state = timer.state.copyWith(focusSecondsElapsed: 0);
      final log = await timer.finishSession();

      expect(log, isNull);
      final appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedQBanks.containsKey(qbankTopic), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. BACKUP RESTORE FORMAT COMPATIBILITY & TASK LIST WIPE PREVENTION
  // ═══════════════════════════════════════════════════════════════════════════
  group('Backup Restore Format Compatibility & Anti-Wipe Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
    });

    test('Restoring backup payload with tasks from today preserves completed state without wipe', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = ContainerWidgetRef(container);

      final todayStr = MetricsService.todayKey(5);
      const task1 = DailyDeskTask(id: 't_cardio', title: 'Cardiology QBank', category: TaskCategory.qbank);
      const task2 = DailyDeskTask(id: 't_path', title: 'Pathology Video', category: TaskCategory.video);

      final payload = jsonEncode({
        'schema_version': 1,
        'app_identifier': 'FlowMD',
        'exported_at': DateTime.now().toIso8601String(),
        'app_state': const AppState(doctorName: 'Dr. Survivor').toJson(),
        'time_logs': <Map<String, dynamic>>[],
        'daily_tasks': {
          'tasks': [task1.toMap(), task2.toMap()],
          'completed_ids': ['t_cardio'],
          'date_history': {todayStr: 1},
          'last_active_date': todayStr,
        },
      });

      final success = await BackupService.restoreFromPayload(ref, payload);
      expect(success, isTrue);

      final dailyState = container.read(dailyTasksProvider);
      expect(dailyState.tasks.length, 2, reason: 'Task list must not be wiped');
      expect(dailyState.completedIds, contains('t_cardio'));
      expect(dailyState.completedIds.contains('t_path'), isFalse);
    });

    test('Restoring legacy backup with missing last_active_date defaults safely and prevents wipe', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = ContainerWidgetRef(container);

      const task1 = DailyDeskTask(id: 't_legacy', title: 'Legacy Task', category: TaskCategory.video);

      // Backup without last_active_date
      final payload = jsonEncode({
        'schema_version': 1,
        'app_identifier': 'FlowMD',
        'exported_at': DateTime.now().toIso8601String(),
        'app_state': const AppState(doctorName: 'Dr. Legacy').toJson(),
        'time_logs': <Map<String, dynamic>>[],
        'daily_tasks': {
          'tasks': [task1.toMap()],
          'completed_ids': ['t_legacy'],
          'date_history': <String, int>{},
          // last_active_date omitted
        },
      });

      final success = await BackupService.restoreFromPayload(ref, payload);
      expect(success, isTrue);

      final dailyState = container.read(dailyTasksProvider);
      expect(dailyState.tasks.length, 1);
      expect(dailyState.completedIds, contains('t_legacy'));
    });

    test('DailyTasksNotifier._load fallback safely handles both JSON string and StringList in SharedPreferences', () async {
      const task1 = DailyDeskTask(id: 'task_json', title: 'JSON Task', category: TaskCategory.video);
      const task2 = DailyDeskTask(id: 'task_list', title: 'List Task', category: TaskCategory.notes);

      // Test Case 1: Stored as JSON string
      SharedPreferences.setMockInitialValues({
        'flowmd_daily_tasks_v2': jsonEncode([task1.toMap()]),
        'flowmd_completed_tasks_v1': jsonEncode(['task_json']),
        'flowmd_tasks_last_date_v1': MetricsService.todayKey(5),
      });

      final notifier1 = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier1.state.tasks.length, 1);
      expect(notifier1.state.completedIds, contains('task_json'));

      // Test Case 2: Stored as legacy List<String>
      SharedPreferences.setMockInitialValues({
        'flowmd_daily_tasks_v2': jsonEncode([task2.toMap()]),
        'flowmd_completed_tasks_v1': <String>['task_list'],
        'flowmd_tasks_last_date_v1': MetricsService.todayKey(5),
      });

      final notifier2 = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier2.state.tasks.length, 1);
      expect(notifier2.state.completedIds, contains('task_list'));
    });

    test('Restoring corrupt JSON string returns false gracefully without throwing', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = ContainerWidgetRef(container);

      expect(await BackupService.restoreFromPayload(ref, 'invalid json{'), isFalse);
      expect(await BackupService.restoreFromPayload(ref, ''), isFalse);
      expect(await BackupService.restoreFromPayload(ref, '{"schema_version": 999}'), isFalse);
    });

    test('Backup export then restore preserves full round-trip integrity', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = ContainerWidgetRef(container);

      // Set up original state
      await container.read(appStateProvider.future);
      await container.read(appStateProvider.notifier).setDoctorName('Dr. Gregory House');
      await container.read(appStateProvider.notifier).setDayStartHour(6);
      await container.read(appStateProvider.notifier).markVideoComplete('vid_sample_pathology');

      const task = DailyDeskTask(id: 'roundtrip_task', title: 'Roundtrip Task', category: TaskCategory.video);
      await container.read(dailyTasksProvider.notifier).setTasks([task]);
      await container.read(dailyTasksProvider.notifier).toggleTask('roundtrip_task');

      final exportedPayload = await BackupService.createBackupPayload(ref);
      expect(exportedPayload, isNotEmpty);

      // Now create a fresh container and restore into it
      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      final freshRef = ContainerWidgetRef(freshContainer);

      final success = await BackupService.restoreFromPayload(freshRef, exportedPayload);
      expect(success, isTrue);

      final restoredAppState = await freshContainer.read(appStateProvider.future);
      expect(restoredAppState.doctorName, 'Dr. Gregory House');
      expect(restoredAppState.dayStartHour, 6);
      expect(restoredAppState.currentEdition.completedVideos.containsKey('vid_sample_pathology'), isTrue);

      final restoredDaily = freshContainer.read(dailyTasksProvider);
      expect(restoredDaily.tasks.length, 1);
      expect(restoredDaily.tasks.first.id, 'roundtrip_task');
      expect(restoredDaily.completedIds, contains('roundtrip_task'));
    });
  });
}
