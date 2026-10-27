import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/services/battery_optimization_service.dart';
import 'package:modulix/providers/focus_timer_provider.dart';
import 'package:modulix/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('BatteryOptimizationService & Brand Advice Tests', () {
    test('Default brand advice fallback is returned on non-Android/desktop/web', () async {
      final service = BatteryOptimizationService.instance;
      final profile = await service.getHardwareProfile();

      expect(profile.manufacturer, equals('generic'));
      expect(profile.model, equals('generic'));
      expect(profile.isAndroid14OrHigher, isFalse);

      final advice = await service.getBrandAdvice();
      expect(advice.title, contains('Standard Android Battery Optimization'));
      expect(advice.isAggressiveOem, isFalse);
      expect(advice.steps, isNotEmpty);
    });

    test('isIgnoringBatteryOptimizations defaults safely to true on desktop/testing', () async {
      final service = BatteryOptimizationService.instance;
      final isIgnoring = await service.isIgnoringBatteryOptimizations();
      expect(isIgnoring, isTrue);
    });
  });

  group('FocusTimer Disk Session Anchor Persistence Tests', () {
    test('Session anchor restores correctly after app restart when paused', () async {
      final now = DateTime.now();
      final anchorMap = {
        'sessionActive': true,
        'isRunning': false,
        'savedAtMs': now.millisecondsSinceEpoch,
        'startTimeMs': now.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
        'mode': 'pomodoro',
        'phase': 'focusing',
        'subjectId': 'cardiology',
        'subjectName': 'Cardiology',
        'topicTitle': 'Heart Failure & ECG',
        'pomodoroPresetMins': 25,
        'remainingSeconds': 900,
        'focusSecondsElapsed': 600,
        'breakSecondsElapsed': 0,
        'hasTarget': true,
      };

      SharedPreferences.setMockInitialValues({
        'focus_timer_active_session_anchor_v1': jsonEncode(anchorMap),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(focusTimerProvider.notifier);
      await notifier.restoreSessionFromDisk();
      final state = container.read(focusTimerProvider);

      expect(state.sessionActive, isTrue);
      expect(state.isRunning, isFalse);
      expect(state.subjectName, equals('Cardiology'));
      expect(state.topicTitle, equals('Heart Failure & ECG'));
      expect(state.remainingSeconds, equals(900));
      expect(state.focusSecondsElapsed, equals(600));
    });

    test('Active countdown session restores with accurate elapsed time computed from wall-clock', () async {
      final now = DateTime.now();
      // Target end was set to 5 minutes into the future
      final targetEnd = now.add(const Duration(minutes: 5));
      final startTime = now.subtract(const Duration(minutes: 20));

      final anchorMap = {
        'sessionActive': true,
        'isRunning': true,
        'savedAtMs': now.subtract(const Duration(seconds: 30)).millisecondsSinceEpoch,
        'startTimeMs': startTime.millisecondsSinceEpoch,
        'targetEndTimeMs': targetEnd.millisecondsSinceEpoch,
        'mode': 'pomodoro',
        'phase': 'focusing',
        'subjectId': 'pharmacology',
        'subjectName': 'Pharmacology',
        'topicTitle': 'Antihypertensives',
        'pomodoroPresetMins': 25,
        'remainingSeconds': 330,
        'focusSecondsElapsed': 1170,
        'breakSecondsElapsed': 0,
        'hasTarget': true,
      };

      SharedPreferences.setMockInitialValues({
        'focus_timer_active_session_anchor_v1': jsonEncode(anchorMap),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(focusTimerProvider.notifier);
      await notifier.restoreSessionFromDisk();
      final state = container.read(focusTimerProvider);

      expect(state.sessionActive, isTrue);
      expect(state.isRunning, isTrue);
      expect(state.subjectName, equals('Pharmacology'));
      expect(state.topicTitle, equals('Antihypertensives'));
      // Remaining seconds should be approximately 300 (5 mins) based on targetEnd - now
      expect(state.remainingSeconds, closeTo(300, 3));
      // Focus elapsed seconds should have increased by ~30 seconds
      expect(state.focusSecondsElapsed, closeTo(1200, 3));
    });

    test('Session completed in background triggers auto-finalization and clears disk anchor', () async {
      final now = DateTime.now();
      // Target end was in the past (e.g. 5 minutes ago)
      final targetEnd = now.subtract(const Duration(minutes: 5));
      final startTime = now.subtract(const Duration(minutes: 30));

      final anchorMap = {
        'sessionActive': true,
        'isRunning': true,
        'savedAtMs': now.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
        'startTimeMs': startTime.millisecondsSinceEpoch,
        'targetEndTimeMs': targetEnd.millisecondsSinceEpoch,
        'mode': 'pomodoro',
        'phase': 'focusing',
        'subjectId': 'surgery',
        'subjectName': 'Surgery',
        'topicTitle': 'Acute Abdomen',
        'pomodoroPresetMins': 25,
        'remainingSeconds': 100,
        'focusSecondsElapsed': 1400,
        'breakSecondsElapsed': 0,
        'hasTarget': true,
      };

      SharedPreferences.setMockInitialValues({
        'focus_timer_active_session_anchor_v1': jsonEncode(anchorMap),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(focusTimerProvider.notifier);
      await notifier.restoreSessionFromDisk();

      // After auto-completion, the disk anchor key should be cleared
      final prefs = await SharedPreferences.getInstance();
      final anchorString = prefs.getString('focus_timer_active_session_anchor_v1');
      expect(anchorString, isNull);
    });
  });
}
