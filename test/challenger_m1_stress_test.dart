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

class TestWidgetRef implements WidgetRef {
  final ProviderContainer container;
  TestWidgetRef(this.container);

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
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CHALLENGE 1: Streak Calculation Stress Testing', () {
    test('1.1 Count <= 0 edge cases and mixed count histories', () {
      final now = DateTime(2026, 10, 14, 12, 0);

      // All zero or negative counts
      final allZero = {
        '2026-10-14': 0,
        '2026-10-13': 0,
        '2026-10-12': -3,
        '2026-10-11': 0,
      };
      expect(MetricsService.computeStreak(allZero, now: now).current, 0);
      expect(MetricsService.computeStreak(allZero, now: now).best, 0);

      // Mixed: positive today, 0 yesterday, positive 2 days ago
      // Gap on yesterday means current streak must be 1 (today only)
      final zeroGap = {
        '2026-10-14': 2,
        '2026-10-13': 0,
        '2026-10-12': 5,
        '2026-10-11': 3,
      };
      final resZeroGap = MetricsService.computeStreak(zeroGap, now: now);
      expect(resZeroGap.current, 1);
      expect(resZeroGap.best, 2); // 10-11 and 10-12 formed best of 2

      // Negative count in history acts as gap
      final negGap = {
        '2026-10-14': 1,
        '2026-10-13': -1,
        '2026-10-12': 1,
      };
      final resNegGap = MetricsService.computeStreak(negGap, now: now);
      expect(resNegGap.current, 1);
      expect(resNegGap.best, 1);

      // Single day: today
      expect(MetricsService.computeStreak({'2026-10-14': 1}, now: now).current, 1);
      expect(MetricsService.computeStreak({'2026-10-14': 1}, now: now).best, 1);

      // Single day: yesterday
      expect(MetricsService.computeStreak({'2026-10-13': 1}, now: now).current, 1);
      expect(MetricsService.computeStreak({'2026-10-13': 1}, now: now).best, 1);

      // Single day: 2 days ago (streak broken)
      expect(MetricsService.computeStreak({'2026-10-12': 1}, now: now).current, 0);
      expect(MetricsService.computeStreak({'2026-10-12': 1}, now: now).best, 1);
    });

    test('1.2 Gaps of 1 day vs 2 days vs historical streaks months ago', () {
      final now = DateTime(2026, 10, 14, 12, 0);

      // Gap of exactly 1 day (yesterday missing) with no activity today:
      // Last active on 2026-10-12. Oct 13 was missed. Today is Oct 14.
      // Gap between 12 and 14 is 1 missed day (13). Streak must be 0!
      final missedYesterday = {
        '2026-10-10': 1,
        '2026-10-11': 1,
        '2026-10-12': 1,
      };
      final resMissedYesterday = MetricsService.computeStreak(missedYesterday, now: now);
      expect(resMissedYesterday.current, 0);
      expect(resMissedYesterday.best, 3);

      // Gap of 2 days (Oct 13, Oct 12 missed)
      final missedTwoDays = {
        '2026-10-09': 1,
        '2026-10-10': 1,
        '2026-10-11': 1,
      };
      final resMissedTwo = MetricsService.computeStreak(missedTwoDays, now: now);
      expect(resMissedTwo.current, 0);
      expect(resMissedTwo.best, 3);

      // Historical streak of 45 days in Jan-Feb, silence until Oct, then 2 days active (Oct 13, Oct 14)
      final historyWithOldStreak = <String, int>{};
      var dayCursor = DateTime.utc(2026, 1, 1);
      for (int i = 0; i < 45; i++) {
        final key = '${dayCursor.year}-${dayCursor.month.toString().padLeft(2, '0')}-${dayCursor.day.toString().padLeft(2, '0')}';
        historyWithOldStreak[key] = 1;
        dayCursor = dayCursor.add(const Duration(days: 1));
      }
      historyWithOldStreak['2026-10-13'] = 2;
      historyWithOldStreak['2026-10-14'] = 1;

      final resOldStreak = MetricsService.computeStreak(historyWithOldStreak, now: now);
      expect(resOldStreak.current, 2);
      expect(resOldStreak.best, 45);

      // Multiple streaks with gaps:
      // Streak A: 3 days (Oct 1, 2, 3)
      // Gap: Oct 4
      // Streak B: 4 days (Oct 5, 6, 7, 8)
      // Gap: Oct 9, 10
      // Streak C: 4 days (Oct 11, 12, 13, 14)
      final multiStreaks = {
        '2026-10-01': 1, '2026-10-02': 1, '2026-10-03': 1,
        '2026-10-05': 1, '2026-10-06': 1, '2026-10-07': 1, '2026-10-08': 1,
        '2026-10-11': 1, '2026-10-12': 1, '2026-10-13': 1, '2026-10-14': 1,
      };
      final resMulti = MetricsService.computeStreak(multiStreaks, now: now);
      expect(resMulti.current, 4);
      expect(resMulti.best, 4);
    });

    test('1.3 Leap year February 29 and non-leap year boundary', () {
      // Leap year 2028: Feb 28, Feb 29, Mar 1 is a 3-day continuous streak
      final leapHistory = {
        '2028-02-28': 1,
        '2028-02-29': 1,
        '2028-03-01': 1,
      };
      final leapNow = DateTime(2028, 3, 1, 14, 0);
      final leapResult = MetricsService.computeStreak(leapHistory, now: leapNow);
      expect(leapResult.current, 3);
      expect(leapResult.best, 3);

      // Non-leap year 2026: Feb 28 to Mar 1 is a 2-day continuous streak
      final nonLeapHistory = {
        '2026-02-28': 1,
        '2026-03-01': 1,
      };
      final nonLeapNow = DateTime(2026, 3, 1, 14, 0);
      final nonLeapResult = MetricsService.computeStreak(nonLeapHistory, now: nonLeapNow);
      expect(nonLeapResult.current, 2);
      expect(nonLeapResult.best, 2);
    });

    test('1.4 DST spring-forward transitions across hours and boundaries', () {
      // DST spring-forward Sunday March 29, 2026 in Europe
      // Test at different hours on March 29 and March 30
      final history = {
        '2026-03-27': 1,
        '2026-03-28': 1,
        '2026-03-29': 1,
        '2026-03-30': 1,
      };

      // Case A: On March 29 at 03:00 (before 5 AM cutoff) -> study day is March 28
      final early29 = DateTime(2026, 3, 29, 3, 0);
      final resEarly29 = MetricsService.computeStreak(history, now: early29);
      expect(resEarly29.current, 2); // 27, 28 active up to study day March 28
      expect(resEarly29.best, 4);

      // Case B: On March 30 at 05:01 (just past 5 AM cutoff) -> study day is March 30, yesterday is March 29
      final justAfterCutoff30 = DateTime(2026, 3, 30, 5, 1);
      final resAfterCutoff30 = MetricsService.computeStreak(history, now: justAfterCutoff30);
      expect(resAfterCutoff30.current, 4);

      // Case C: On March 30 at 12:00
      final noon30 = DateTime(2026, 3, 30, 12, 0);
      final resNoon30 = MetricsService.computeStreak(history, now: noon30);
      expect(resNoon30.current, 4);

      // Case D: User studied on March 29 (DST day), but hasn't studied yet on March 30
      final historyWithout30 = {
        '2026-03-27': 1,
        '2026-03-28': 1,
        '2026-03-29': 1,
      };
      final resStillActive = MetricsService.computeStreak(historyWithout30, now: noon30);
      expect(resStillActive.current, 3);
      expect(resStillActive.best, 3);
    });

    test('1.5 DST fall-back transitions (25-hour day)', () {
      // DST fall-back Sunday October 25, 2026 in Europe
      final fallHistory = {
        '2026-10-23': 1,
        '2026-10-24': 1,
        '2026-10-25': 1, // 25-hour day
        '2026-10-26': 1,
      };

      // On Oct 26 at 05:05 AM
      final nowAfterFallBack = DateTime(2026, 10, 26, 5, 5);
      final resFall = MetricsService.computeStreak(fallHistory, now: nowAfterFallBack);
      expect(resFall.current, 4);
      expect(resFall.best, 4);

      // User hasn't studied on Oct 26 yet: streak from Oct 25 should still be active
      final historyBefore26 = {
        '2026-10-23': 1,
        '2026-10-24': 1,
        '2026-10-25': 1,
      };
      final resFallActive = MetricsService.computeStreak(historyBefore26, now: nowAfterFallBack);
      expect(resFallActive.current, 3);
      expect(resFallActive.best, 3);
    });

    test('1.6 Custom dayStartHour boundaries (0 AM, 4 AM, 12 PM)', () {
      // Midnight boundary: dayStartHour = 0
      final midnightNow = DateTime(2026, 10, 14, 0, 30);
      expect(MetricsService.todayKey(0, midnightNow), '2026-10-14');

      final beforeMidnight = DateTime(2026, 10, 13, 23, 59);
      expect(MetricsService.todayKey(0, beforeMidnight), '2026-10-13');

      // Noon boundary: dayStartHour = 12
      final morning = DateTime(2026, 10, 14, 11, 0); // 11 AM with 12 PM cutoff -> 2026-10-13
      expect(MetricsService.todayKey(12, morning), '2026-10-13');
      final afternoon = DateTime(2026, 10, 14, 13, 0); // 1 PM with 12 PM cutoff -> 2026-10-14
      expect(MetricsService.todayKey(12, afternoon), '2026-10-14');
    });
  });

  group('CHALLENGE 2: Focus Timer Session Completion Idempotency', () {
    test('2.1 Repeated completions of Q-Bank, Notes, and Video do not uncheck or double-count', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final appNotifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const qbankId = 'qbank_stress_test_1';
      const noteId = 'notes_stress_test_1';
      const videoId = 'video_stress_test_1';

      final today = MetricsService.todayKey(container.read(appStateProvider).value!.dayStartHour);

      // Repeat markQBankComplete 5 times
      for (int i = 0; i < 5; i++) {
        await appNotifier.markQBankComplete(qbankId);
      }
      var appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedQBanks.containsKey(qbankId), isTrue);

      // Repeat markNotesComplete 5 times
      for (int i = 0; i < 5; i++) {
        await appNotifier.markNotesComplete(noteId);
      }
      appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedNotes.containsKey(noteId), isTrue);

      // Repeat markVideoComplete 5 times
      for (int i = 0; i < 5; i++) {
        await appNotifier.markVideoComplete(videoId);
      }
      appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedVideos.containsKey(videoId), isTrue);
      // Daily history count must be exactly 1, not 5!
      expect(appState.currentEdition.dailyHistory[today], 1);
    });

    test('2.2 Focus timer finishSession repeated 3 times on same topic preserves completion', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final appNotifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const qbankId = 'qbank_arrhythmias_repeat';

      // Pre-complete
      await appNotifier.markQBankComplete(qbankId);

      final timerNotifier = container.read(focusTimerProvider.notifier);

      for (int i = 0; i < 3; i++) {
        timerNotifier.setTask(
          subjectId: 'cardiology',
          subjectName: 'Cardiology',
          topicId: qbankId,
          topicTitle: 'Arrhythmias Q-Bank',
          topicType: 'qbank',
        );
        timerNotifier.state = timerNotifier.state.copyWith(focusSecondsElapsed: 300);
        await timerNotifier.finishSession();

        final state = container.read(appStateProvider).value!;
        expect(state.currentEdition.completedQBanks.containsKey(qbankId), isTrue);
      }
    });

    test('2.3 Unmarking video decrements daily history and removes completion', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final appNotifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const videoId = 'video_unmark_test';
      final today = MetricsService.todayKey(container.read(appStateProvider).value!.dayStartHour);

      await appNotifier.markVideoComplete(videoId);
      var state = container.read(appStateProvider).value!;
      expect(state.currentEdition.dailyHistory[today], 1);

      await appNotifier.markVideoIncomplete(videoId);
      state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedVideos.containsKey(videoId), isFalse);
      expect(state.currentEdition.dailyHistory.containsKey(today), isFalse);
    });
  });

  group('CHALLENGE 3: Backup Restore Format Compatibility & Task List Wipe Prevention', () {
    test('3.1 Restores backup with legacy StringList format without crashing or wiping', () async {
      // Simulate legacy backup where flowmd_completed_tasks_v1 was a List<String>
      const task1 = DailyDeskTask(id: 't_legacy_1', title: 'Legacy Video', category: TaskCategory.video);
      final tasksJson = jsonEncode([task1.toMap()]);

      SharedPreferences.setMockInitialValues({
        'flowmd_daily_tasks_v2': tasksJson,
        'flowmd_completed_tasks_v1': <String>['t_legacy_1'],
        'flowmd_tasks_last_date_v1': MetricsService.todayKey(5),
      });

      final notifier = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.completedIds, contains('t_legacy_1'));
    });

    test('3.2 Restore with missing last_active_date does not wipe tasks on restore', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = TestWidgetRef(container);

      // Payload missing 'last_active_date' entirely (legacy export)
      final backupData = {
        'schema_version': 1,
        'app_identifier': 'FlowMD',
        'exported_at': DateTime.now().toIso8601String(),
        'app_state': const AppState(doctorName: 'Dr. NoDate').toJson(),
        'time_logs': <Map<String, dynamic>>[],
        'daily_tasks': {
          'tasks': [
            const DailyDeskTask(id: 'task_survives', title: 'Task Survives', category: TaskCategory.video).toMap(),
          ],
          'completed_ids': ['task_survives'],
          'date_history': {'2026-10-14': 1},
          // last_active_date omitted!
        },
      };

      final ok = await BackupService.restoreFromPayload(ref, jsonEncode(backupData));
      expect(ok, isTrue);

      final dailyState = container.read(dailyTasksProvider);
      expect(dailyState.tasks.length, 1);
      expect(dailyState.tasks.first.id, 'task_survives');
      expect(dailyState.completedIds, contains('task_survives'));
    });

    test('3.3 Day rollover archives completed tasks into history and rolls over unfinished tasks', () async {
      const taskDone = DailyDeskTask(id: 'done_1', title: 'Completed Yesterday', category: TaskCategory.video);
      const taskPending = DailyDeskTask(id: 'pending_1', title: 'Unfinished Task', category: TaskCategory.qbank);

      // Set last active date to yesterday
      const yesterday = '2026-10-13';

      SharedPreferences.setMockInitialValues({
        'flowmd_daily_tasks_v2': jsonEncode([taskDone.toMap(), taskPending.toMap()]),
        'flowmd_completed_tasks_v1': jsonEncode(['done_1']),
        'flowmd_tasks_last_date_v1': yesterday,
        'flowmd_tasks_history_v1': jsonEncode({'2026-10-12': 2}),
      });

      final notifier = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // After rollover:
      // - pending task MUST rollover to today (not wiped!)
      // - done task is removed from desk
      // - yesterday's history is credited with 1 completed task
      // - completedIds for today is reset to empty
      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.first.id, 'pending_1');
      expect(notifier.state.completedIds, isEmpty);
      expect(notifier.state.dateHistory[yesterday], 1);
      expect(notifier.state.dateHistory['2026-10-12'], 2);
    });

    test('3.4 Corrupted or future-version backup payload fails gracefully without corrupting state', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = TestWidgetRef(container);

      // Future version 99
      final futurePayload = jsonEncode({
        'schema_version': 99,
        'app_identifier': 'FlowMD',
      });
      final resFuture = await BackupService.restoreFromPayload(ref, futurePayload);
      expect(resFuture, isFalse);

      // Corrupted JSON string
      final resCorrupt = await BackupService.restoreFromPayload(ref, 'NOT_JSON{[[{');
      expect(resCorrupt, isFalse);

      // Missing app_state
      final resNoAppState = await BackupService.restoreFromPayload(ref, jsonEncode({
        'schema_version': 1,
        'app_identifier': 'FlowMD',
      }));
      expect(resNoAppState, isFalse);
    });
  });
}
