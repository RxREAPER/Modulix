import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_state.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Static notification IDs
  static const int idStudyReminder = 1001;
  static const int idStreakReminder = 1002;
  static const int idModuleTasksBriefing = 1003;
  static const int idFocusTimerRunning = 2000;
  static const int idFocusTimerEnd = 2001;
  static const int idTaskCompleteInstant = 3001;
  static const int idTestNotification = 9999;

  // Channel IDs
  static const String channelStudyReminders = 'flowmd_study_reminders';
  static const String channelStreakReminders = 'flowmd_streak_reminders';
  static const String channelModuleTasks = 'flowmd_module_tasks';
  static const String channelFocusTimer = 'flowmd_focus_timer';

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      if (!kIsWeb) {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      }
    } catch (e) {
      debugPrint('[NotificationService] Timezone init error: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open FlowMD',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Notification clicked: ${response.payload}');
        },
      );

      // Create Android Notification Channels
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelStudyReminders,
              'Daily Study Reminders',
              description: 'Reminders to start your scheduled NEET-PG study blocks',
              importance: Importance.high,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelStreakReminders,
              'Streak at Risk Alerts',
              description: 'Evening warnings when your study streak is about to reset',
              importance: Importance.high,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelModuleTasks,
              'Module Daily Tasks',
              description: 'Morning curriculum task queue and milestone celebrations',
              importance: Importance.defaultImportance,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelFocusTimer,
              'Focus Timer & Breaks',
              description: 'High-priority alerts when focus sessions and breaks finish',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Init failed: $e');
    }
  }

  /// Request permissions on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission() ?? false;
        try {
          await androidImpl?.requestExactAlarmsPermission();
        } catch (_) {}
        return granted;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
        return granted;
      }
    } catch (e) {
      debugPrint('[NotificationService] Request permission error: $e');
    }
    return true;
  }

  /// Check permission status
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.areNotificationsEnabled() ?? false;
      }
    } catch (e) {
      debugPrint('[NotificationService] hasPermission check error: $e');
    }
    return true;
  }

  /// Helper to calculate next scheduled instance of a given time (e.g. 09:00)
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule Daily Study Reminder
  Future<void> scheduleDailyStudyReminder({
    required TimeOfDay time,
    required String doctorName,
    required String subjectName,
  }) async {
    if (!_initialized) await init();
    try {
      final scheduledDate = _nextInstanceOfTime(time.hour, time.minute);
      final docTitle = doctorName.isEmpty ? 'Doctor' : doctorName;
      final subjectTxt = subjectName.isNotEmpty ? subjectName : 'today\'s curriculum';

      await _plugin.zonedSchedule(
        idStudyReminder,
        'Time to Study, $docTitle',
        'Your daily targets for $subjectTxt are waiting. Let\'s make today count!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelStudyReminders,
            'Daily Study Reminders',
            channelDescription: 'Reminders to start your scheduled NEET-PG study blocks',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleDailyStudyReminder error: $e');
    }
  }

  /// Schedule Streak at Risk Reminder (e.g. 8:00 PM)
  Future<void> scheduleStreakReminder({
    required TimeOfDay time,
    required int currentStreak,
  }) async {
    if (!_initialized) await init();
    try {
      final scheduledDate = _nextInstanceOfTime(time.hour, time.minute);
      final streakTxt = currentStreak > 0 ? '$currentStreak-day streak' : 'study momentum';

      await _plugin.zonedSchedule(
        idStreakReminder,
        'Don\'t break your $streakTxt!',
        'You haven\'t logged study progress today. Complete a topic before midnight to keep your flame burning!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelStreakReminders,
            'Streak at Risk Alerts',
            channelDescription: 'Evening warnings when your study streak is about to reset',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleStreakReminder error: $e');
    }
  }

  /// Schedule Module Tasks Morning Briefing (e.g. 8:00 AM)
  Future<void> scheduleModuleTasksBriefing({
    required TimeOfDay time,
    required int taskCount,
    required String subjectName,
  }) async {
    if (!_initialized) await init();
    try {
      final scheduledDate = _nextInstanceOfTime(time.hour, time.minute);
      final countTxt = taskCount > 0 ? '$taskCount topics' : 'new targets';
      final subjTxt = subjectName.isNotEmpty ? ' in $subjectName' : '';

      await _plugin.zonedSchedule(
        idModuleTasksBriefing,
        'Today\'s Study Queue is Ready',
        'You have $countTxt scheduled$subjTxt. Tap to review your desk.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelModuleTasks,
            'Module Daily Tasks',
            channelDescription: 'Morning curriculum task queue and milestone celebrations',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleModuleTasksBriefing error: $e');
    }
  }

  /// Instant notification when a daily task batch / quota is achieved
  Future<void> showModuleTaskCompletedNotification({
    required String subjectName,
    required int count,
  }) async {
    if (!_initialized) await init();
    try {
      await _plugin.show(
        idTaskCompleteInstant,
        'Daily Goal Crushed!',
        'You completed $count topics in $subjectName today. High-yield progress!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelModuleTasks,
            'Module Daily Tasks',
            channelDescription: 'Morning curriculum task queue and milestone celebrations',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showModuleTaskCompleted error: $e');
    }
  }

  /// Instant notification when a focus timer starts
  Future<void> showFocusTimerStarted({
    required String topicTitle,
    required int minutes,
  }) async {
    if (!_initialized) await init();
    try {
      final title = topicTitle.trim().isNotEmpty ? topicTitle.trim() : 'Study Session';
      final minTxt = minutes > 0 ? '$minutes min' : 'active';
      await _plugin.show(
        idFocusTimerRunning,
        'Focus Session Started',
        'Focusing on "$title" ($minTxt). Stay locked in!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelFocusTimer,
            'Focus Timer & Breaks',
            channelDescription: 'High-priority alerts when focus sessions and breaks finish',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showFocusTimerStarted error: $e');
    }
  }

  /// Instant notification when a break starts
  Future<void> showBreakStarted({
    required int minutes,
  }) async {
    if (!_initialized) await init();
    try {
      final minTxt = minutes > 0 ? '$minutes min' : '5 min';
      await _plugin.show(
        idFocusTimerRunning,
        'Break Started',
        'Your $minTxt break has started. Step away from your desk and recharge.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelFocusTimer,
            'Focus Timer & Breaks',
            channelDescription: 'High-priority alerts when focus sessions and breaks finish',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showBreakStarted error: $e');
    }
  }

  /// Instant notification when a focus timer session completes
  Future<void> showFocusTimerCompleted({
    required String topicTitle,
  }) async {
    if (!_initialized) await init();
    try {
      final title = topicTitle.trim().isNotEmpty ? topicTitle.trim() : 'Study Session';
      await _plugin.show(
        idFocusTimerEnd,
        'Focus Session Complete!',
        'Great focus on "$title"! Time for a well-deserved break.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelFocusTimer,
            'Focus Timer & Breaks',
            channelDescription: 'High-priority alerts when focus sessions and breaks finish',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showFocusTimerCompleted error: $e');
    }
  }

  /// Instant notification when a break finishes
  Future<void> showBreakCompleted({
    required String topicTitle,
  }) async {
    if (!_initialized) await init();
    try {
      final title = topicTitle.trim().isNotEmpty ? topicTitle.trim() : 'Study Session';
      await _plugin.show(
        idFocusTimerEnd,
        'Break Finished!',
        'Break time is over. Ready to resume studying "$title"?',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelFocusTimer,
            'Focus Timer & Breaks',
            channelDescription: 'High-priority alerts when focus sessions and breaks finish',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showBreakCompleted error: $e');
    }
  }

  /// Cancel running focus timer notification
  Future<void> cancelFocusTimerRunning() async {
    try {
      await _plugin.cancel(idFocusTimerRunning);
    } catch (e) {
      debugPrint('[NotificationService] cancelFocusTimerRunning error: $e');
    }
  }

  /// Schedule Focus Timer Completion Notification
  Future<void> scheduleFocusTimerEnd({
    required Duration duration,
    required String topicTitle,
    required bool isBreak,
  }) async {
    if (!_initialized) await init();
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(duration);
      final title = isBreak ? 'Break Finished!' : 'Focus Session Complete!';
      final body = isBreak
          ? 'Ready to get back to "$topicTitle"? Tap to resume study.'
          : 'Great focus on "$topicTitle"! Time for a well-deserved 5-minute break.';

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelFocusTimer,
          'Focus Timer & Breaks',
          channelDescription: 'High-priority alerts when focus sessions and breaks finish',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        await _plugin.zonedSchedule(
          idFocusTimerEnd,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('[NotificationService] exact schedule error, falling back to inexact: $e');
        await _plugin.zonedSchedule(
          idFocusTimerEnd,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] scheduleFocusTimerEnd error: $e');
    }
  }

  /// Cancel scheduled focus timer notification
  Future<void> cancelFocusTimerEnd() async {
    try {
      await _plugin.cancel(idFocusTimerEnd);
    } catch (e) {
      debugPrint('[NotificationService] cancelFocusTimerEnd error: $e');
    }
  }

  /// Instant test notification for user verification
  Future<void> sendTestNotification({String? doctorName}) async {
    if (!_initialized) await init();
    try {
      final doc = (doctorName != null && doctorName.trim().isNotEmpty)
          ? doctorName.trim()
          : 'Doctor';

      await _plugin.show(
        idTestNotification,
        'FlowMD Notifications Active!',
        'Hello $doc! Study reminders, streak alerts, and focus timer notifications are all ready.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelFocusTimer,
            'Focus Timer & Breaks',
            channelDescription: 'High-priority alerts when focus sessions and breaks finish',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] sendTestNotification error: $e');
    }
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[NotificationService] cancelAll error: $e');
    }
  }

  /// Synchronize all scheduled reminders based on user AppState
  Future<void> syncAllReminders(AppState state, {int remainingModules = 0}) async {
    if (!_initialized) await init();

    // 1. Study reminder
    if (state.dailyReminderEnabled) {
      final parts = state.studyReminderTime.split(':');
      final hour = int.tryParse(parts.first) ?? 9;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      await scheduleDailyStudyReminder(
        time: TimeOfDay(hour: hour, minute: minute),
        doctorName: state.doctorName,
        subjectName: state.currentEdition.plan.targetSubject,
      );
    } else {
      await _plugin.cancel(idStudyReminder);
    }

    // 2. Streak reminder
    if (state.streakReminderEnabled) {
      final parts = state.streakReminderTime.split(':');
      final hour = int.tryParse(parts.first) ?? 20;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      await scheduleStreakReminder(
        time: TimeOfDay(hour: hour, minute: minute),
        currentStreak: 1,
      );
    } else {
      await _plugin.cancel(idStreakReminder);
    }

    // 3. Module tasks briefing
    if (state.moduleTasksReminderEnabled) {
      final parts = state.moduleTasksReminderTime.split(':');
      final hour = int.tryParse(parts.first) ?? 8;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      await scheduleModuleTasksBriefing(
        time: TimeOfDay(hour: hour, minute: minute),
        taskCount: state.currentEdition.plan.videosPerDay ?? remainingModules,
        subjectName: state.currentEdition.plan.targetSubject,
      );
    } else {
      await _plugin.cancel(idModuleTasksBriefing);
    }
  }
}
