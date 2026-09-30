import 'package:flutter_test/flutter_test.dart';
import 'package:flowmd_flutter/models/app_state.dart';
import 'package:flowmd_flutter/services/notification_service.dart';
import 'package:flowmd_flutter/providers/focus_timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService configuration & channel tests', () {
    test('Notification channels and IDs are defined correctly', () {
      expect(NotificationService.channelStudyReminders, 'flowmd_study_reminders');
      expect(NotificationService.channelStreakReminders, 'flowmd_streak_reminders');
      expect(NotificationService.channelModuleTasks, 'flowmd_module_tasks');
      expect(NotificationService.channelFocusTimer, 'flowmd_focus_timer');

      expect(NotificationService.idStudyReminder, 1001);
      expect(NotificationService.idStreakReminder, 1002);
      expect(NotificationService.idModuleTasksBriefing, 1003);
      expect(NotificationService.idFocusTimerRunning, 2000);
      expect(NotificationService.idFocusTimerEnd, 2001);
      expect(NotificationService.idTaskCompleteInstant, 3001);
      expect(NotificationService.idTestNotification, 9999);
    });

    test('NotificationService singleton returns identical instance', () {
      final s1 = NotificationService.instance;
      final s2 = NotificationService.instance;
      expect(identical(s1, s2), isTrue);
    });
  });

  group('AppState notification preferences serialization tests', () {
    test('Default AppState has notification defaults configured', () {
      const state = AppState();
      expect(state.dailyReminderEnabled, isTrue);
      expect(state.studyReminderTime, '09:00');
      expect(state.streakReminderEnabled, isTrue);
      expect(state.streakReminderTime, '20:00');
      expect(state.moduleTasksReminderEnabled, isTrue);
      expect(state.moduleTasksReminderTime, '08:00');
      expect(state.focusTimerAlertsEnabled, isTrue);
    });

    test('AppState toJson and fromJson round-trips notification preferences', () {
      final state = const AppState().copyWith(
        dailyReminderEnabled: false,
        studyReminderTime: '07:30',
        streakReminderEnabled: true,
        streakReminderTime: '21:15',
        moduleTasksReminderEnabled: false,
        moduleTasksReminderTime: '08:45',
        focusTimerAlertsEnabled: false,
      );

      final json = state.toJson();
      expect(json['dailyReminderEnabled'], isFalse);
      expect(json['studyReminderTime'], '07:30');
      expect(json['streakReminderEnabled'], isTrue);
      expect(json['streakReminderTime'], '21:15');
      expect(json['moduleTasksReminderEnabled'], isFalse);
      expect(json['moduleTasksReminderTime'], '08:45');
      expect(json['focusTimerAlertsEnabled'], isFalse);

      final recovered = AppState.fromJson(json);
      expect(recovered.dailyReminderEnabled, isFalse);
      expect(recovered.studyReminderTime, '07:30');
      expect(recovered.streakReminderEnabled, isTrue);
      expect(recovered.streakReminderTime, '21:15');
      expect(recovered.moduleTasksReminderEnabled, isFalse);
      expect(recovered.moduleTasksReminderTime, '08:45');
      expect(recovered.focusTimerAlertsEnabled, isFalse);
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
      expect(state.studyReminderTime, '09:00');
      expect(state.streakReminderEnabled, isTrue);
      expect(state.streakReminderTime, '20:00');
      expect(state.moduleTasksReminderEnabled, isTrue);
      expect(state.moduleTasksReminderTime, '08:00');
      expect(state.focusTimerAlertsEnabled, isTrue);
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
      expect(breakState.remainingSeconds, 5 * 60);

      notifier.toggleBreak();
      final focusState = container.read(focusTimerProvider);
      expect(focusState.phase, TimerPhase.focusing);
      expect(focusState.remainingSeconds, 25 * 60);
    });
  });
}
