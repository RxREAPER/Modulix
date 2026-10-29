import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/services/notification_service.dart';
import 'package:modulix/providers/focus_timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService configuration & channel tests', () {
    test('Notification channels and IDs are defined correctly', () {
      expect(NotificationService.channelStudyReminders, 'flowmd_study_reminders_v2');
      expect(NotificationService.channelStreakReminders, 'flowmd_streak_reminders_v2');
      expect(NotificationService.channelFocusTimer, 'flowmd_focus_timer_v2');
      expect(NotificationService.channelFocusTimerLive, 'flowmd_focus_timer_live_v2');

      expect(NotificationService.idStudyReminder, 1001);
      expect(NotificationService.idStreakReminder, 1002);
      expect(NotificationService.idFocusTimerRunning, 2000);
      expect(NotificationService.idFocusTimerEnd, 2001);
      expect(NotificationService.idTestNotification, 9999);
    });

    test('NotificationService singleton returns identical instance', () {
      final s1 = NotificationService.instance;
      final s2 = NotificationService.instance;
      expect(identical(s1, s2), isTrue);
    });

    test('NotificationService.hasStudiedToday accurately detects progress', () {
      const emptyState = AppState();
      expect(NotificationService.hasStudiedToday(emptyState), isFalse);
    });
  });

  group('AppState notification preferences serialization tests', () {
    test('Default AppState has notification defaults configured', () {
      const state = AppState();
      expect(state.dailyReminderEnabled, isTrue);
      expect(state.studyReminderTime, '08:30');
      expect(state.streakReminderEnabled, isTrue);
      expect(state.streakReminderTime, '20:30');
      expect(state.focusTimerAlertsEnabled, isTrue);
      expect(state.liveTimerNotificationEnabled, isTrue);
    });

    test('AppState toJson and fromJson round-trips notification preferences', () {
      final state = const AppState().copyWith(
        dailyReminderEnabled: false,
        studyReminderTime: '07:30',
        streakReminderEnabled: true,
        streakReminderTime: '21:15',
        focusTimerAlertsEnabled: false,
        liveTimerNotificationEnabled: false,
      );

      final json = state.toJson();
      expect(json['dailyReminderEnabled'], isFalse);
      expect(json['studyReminderTime'], '07:30');
      expect(json['streakReminderEnabled'], isTrue);
      expect(json['streakReminderTime'], '21:15');
      expect(json['focusTimerAlertsEnabled'], isFalse);
      expect(json['liveTimerNotificationEnabled'], isFalse);

      final recovered = AppState.fromJson(json);
      expect(recovered.dailyReminderEnabled, isFalse);
      expect(recovered.studyReminderTime, '07:30');
      expect(recovered.streakReminderEnabled, isTrue);
      expect(recovered.streakReminderTime, '21:15');
      expect(recovered.focusTimerAlertsEnabled, isFalse);
      expect(recovered.liveTimerNotificationEnabled, isFalse);
    });

    test('AppState.fromJson handles legacy JSON payloads without new notification fields gracefully', () {
      final legacyJson = {
        'onboardingDone': true,
        'doctorName': 'Dr. Legacy',
        'activeEdition': 'marrow_8',
        'themePref': 'dark',
        'accentColorId': 'emerald',
        'dayStartHour': 5,
        'dailyReminderEnabled': true,
        'editions': {},
      };

      final state = AppState.fromJson(legacyJson);
      expect(state.doctorName, 'Dr. Legacy');
      expect(state.studyReminderTime, '08:30');
      expect(state.streakReminderEnabled, isTrue);
      expect(state.streakReminderTime, '20:30');
      expect(state.focusTimerAlertsEnabled, isTrue);
      expect(state.liveTimerNotificationEnabled, isTrue);
    });
  });

  group('FocusTimerState & notification coordination', () {
    test('FocusTimerNotifier starts and cancels timer without errors', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(focusTimerProvider.notifier);
      final initial = container.read(focusTimerProvider);
      expect(initial.isRunning, isFalse);

      // Start focus timer
      notifier.startOrPause();
      final running = container.read(focusTimerProvider);
      expect(running.isRunning, isTrue);
      expect(running.phase, TimerPhase.focusing);

      // Pause focus timer
      notifier.startOrPause();
      final paused = container.read(focusTimerProvider);
      expect(paused.isRunning, isFalse);

      // Reset focus timer
      notifier.reset();
      final resetState = container.read(focusTimerProvider);
      expect(resetState.isRunning, isFalse);
      expect(resetState.phase, TimerPhase.idle);
    });

    test('FocusTimerNotifier toggles break and re-sets duration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(focusTimerProvider.notifier);
      notifier.toggleBreak();
      final breakState = container.read(focusTimerProvider);
      expect(breakState.phase, TimerPhase.onBreak);
      expect(breakState.breakSecondsElapsed, 0);

      notifier.toggleBreak();
      final focusState = container.read(focusTimerProvider);
      expect(focusState.phase, TimerPhase.focusing);
      expect(focusState.remainingSeconds, 25 * 60);
    });
  });
}
