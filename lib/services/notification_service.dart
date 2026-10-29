import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_state.dart';
import 'metrics_service.dart';

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
  static const int idTestNotification = 9999;

  // Channel IDs (bumped to _v2 to ensure max importance & vibration on updated devices)
  static const String channelStudyReminders = 'flowmd_study_reminders_v2';
  static const String channelStreakReminders = 'flowmd_streak_reminders_v2';
  static const String channelFocusTimer = 'flowmd_focus_timer_v2';
  static const String channelFocusTimerLive = 'flowmd_focus_timer_live_v2';

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      if (!kIsWeb) {
        try {
          final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
          tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
        } catch (tzError) {
          debugPrint('[NotificationService] Timezone lookup error: $tzError');
        }
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
      defaultActionName: 'Open Modulix',
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
          // Remove legacy v1/v2 channels so system resets to new max priority and sound
          try {
            await androidImpl.deleteNotificationChannel('flowmd_study_reminders');
            await androidImpl.deleteNotificationChannel('flowmd_streak_reminders');
            await androidImpl.deleteNotificationChannel('flowmd_module_tasks');
            await androidImpl.deleteNotificationChannel('flowmd_module_tasks_v2');
            await androidImpl.deleteNotificationChannel('flowmd_focus_timer');
          } catch (_) {}

          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelStudyReminders,
              'Daily Study Reminders',
              description: 'Reminders to start your scheduled NEET-PG study blocks',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelStreakReminders,
              'Streak at Risk Alerts',
              description: 'Evening warnings when your study streak is about to reset',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
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
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelFocusTimerLive,
              'Live Focus & Break Timer',
              description: 'Real-time countdown and stopwatch in notification shade while studying',
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
              showBadge: false,
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

  /// Safely schedule an alarm with exact mode first, and resilient fallback to inexact mode.
  /// Guarantees that notifications are scheduled across all Android versions (8 through 16) and OEM policies.
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      debugPrint('[NotificationService] Scheduled notification $id (exact) for $scheduledDate');
    } catch (e) {
      debugPrint('[NotificationService] Exact schedule failed for $id, falling back to inexact: $e');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        debugPrint('[NotificationService] Scheduled notification $id (inexact fallback) for $scheduledDate');
      } catch (fallbackError) {
        debugPrint('[NotificationService] Inexact schedule failed for $id: $fallbackError');
      }
    }
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

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelStudyReminders,
          'Daily Study Reminders',
          channelDescription: 'Reminders to start your scheduled NEET-PG study blocks',
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

      await _safeZonedSchedule(
        id: idStudyReminder,
        title: 'Time to Study, $docTitle',
        body: 'Your daily targets for $subjectTxt are waiting. Let\'s make today count!',
        scheduledDate: scheduledDate,
        details: details,
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

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelStreakReminders,
          'Streak at Risk Alerts',
          channelDescription: 'Evening warnings when your study streak is about to reset',
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

      await _safeZonedSchedule(
        id: idStreakReminder,
        title: 'Don\'t break your $streakTxt!',
        body: 'You haven\'t logged study progress today. Complete a topic before midnight to keep your flame burning!',
        scheduledDate: scheduledDate,
        details: details,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleStreakReminder error: $e');
    }
  }



  /// Shows or updates the ongoing live real-time chronometer notification
  Future<void> showRealtimeTimerNotification({
    required String title,
    required String subtitle,
    required bool isBreak,
    required bool isCountdown,
    required int whenMillis,
    Color? color,
  }) async {
    if (!_initialized) await init();
    try {
      final effectiveTitle = title.trim().isNotEmpty ? title.trim() : (isBreak ? 'Recharge Break' : 'Focus Session');
      final effectiveSub = subtitle.trim().isNotEmpty ? subtitle.trim() : (isBreak ? 'Taking a short rest' : 'Study block active');

      final androidDetails = AndroidNotificationDetails(
        channelFocusTimerLive,
        'Live Focus & Break Timer',
        channelDescription: 'Real-time countdown and stopwatch in notification shade while studying',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: true,
        usesChronometer: true,
        chronometerCountDown: isCountdown,
        when: whenMillis,
        color: color ?? (isBreak ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
        category: AndroidNotificationCategory.stopwatch,
        icon: '@mipmap/ic_launcher',
        subText: isBreak ? 'Break' : 'Focusing',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      await _plugin.show(
        idFocusTimerRunning,
        effectiveTitle,
        effectiveSub,
        NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        ),
        payload: '/timer',
      );
    } catch (e) {
      debugPrint('[NotificationService] showRealtimeTimerNotification error: $e');
    }
  }

  /// Instant notification when a focus timer starts (delegates to real-time chronometer)
  Future<void> showFocusTimerStarted({
    required String topicTitle,
    required int minutes,
  }) async {
    final targetMs = DateTime.now().millisecondsSinceEpoch + (minutes > 0 ? minutes : 25) * 60 * 1000;
    await showRealtimeTimerNotification(
      title: topicTitle.isNotEmpty ? topicTitle : 'Focus Session',
      subtitle: minutes > 0 ? '$minutes min session' : 'Active session',
      isBreak: false,
      isCountdown: true,
      whenMillis: targetMs,
    );
  }

  /// Instant notification when a break starts (delegates to real-time chronometer)
  Future<void> showBreakStarted({
    required int minutes,
  }) async {
    final targetMs = DateTime.now().millisecondsSinceEpoch + (minutes > 0 ? minutes : 5) * 60 * 1000;
    await showRealtimeTimerNotification(
      title: 'Recharge Break',
      subtitle: minutes > 0 ? '$minutes min break' : '5 min break',
      isBreak: true,
      isCountdown: true,
      whenMillis: targetMs,
    );
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

      await _safeZonedSchedule(
        id: idFocusTimerEnd,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        details: details,
      );
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
        'Modulix Notifications Active!',
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

  /// Determines whether the doctor has already logged study progress today.
  static bool hasStudiedToday(AppState state) {
    final now = DateTime.now();
    final adjusted = now.hour < state.dayStartHour
        ? now.subtract(const Duration(days: 1))
        : now;
    final todayKey =
        '${adjusted.year}-${adjusted.month.toString().padLeft(2, '0')}-${adjusted.day.toString().padLeft(2, '0')}';
    final count = state.currentEdition.dailyHistory[todayKey] ?? 0;
    return count > 0;
  }

  Future<void> _safeCancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('[NotificationService] Cancel error for $id: $e');
    }
  }

  /// Synchronize all scheduled reminders based on user AppState.
  /// Features Smart Streak Suppression: if progress is logged today, streak warnings are cancelled.
  Future<void> syncAllReminders(AppState state, {bool? hasStudiedToday, int remainingModules = 0}) async {
    if (!_initialized) await init();

    // 1. Daily Study Reminder (Fixed 08:30 AM morning kickoff)
    if (state.dailyReminderEnabled) {
      final parts = state.studyReminderTime.split(':');
      final hour = int.tryParse(parts.first) ?? 8;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30;
      await scheduleDailyStudyReminder(
        time: TimeOfDay(hour: hour, minute: minute),
        doctorName: state.doctorName,
        subjectName: state.currentEdition.plan.targetSubject,
      );
    } else {
      await _safeCancel(idStudyReminder);
    }

    // 2. Streak Protection Alert (Fixed 20:30 PM evening streak guard)
    // Smart Suppression: If user has already completed topics today, suppress alert
    final studied = hasStudiedToday ?? NotificationService.hasStudiedToday(state);
    if (state.streakReminderEnabled && !studied) {
      final parts = state.streakReminderTime.split(':');
      final hour = int.tryParse(parts.first) ?? 20;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30;
      final currentStreak = MetricsService.computeStreak(
        state.currentEdition.dailyHistory,
        dayStartHour: state.dayStartHour,
      ).current;
      await scheduleStreakReminder(
        time: TimeOfDay(hour: hour, minute: minute),
        currentStreak: currentStreak,
      );
    } else {
      await _safeCancel(idStreakReminder);
    }

    // Cancel legacy module tasks briefing
    await _safeCancel(idModuleTasksBriefing);
  }
}
