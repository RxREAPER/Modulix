import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service bridging to native Android AlarmManager.setAlarmClock.
/// True Doze piercer that guarantees alarms trigger at the exact second even
/// under Deep Doze, with lockscreen/AOD display and zero battery degradation.
class AlarmClockService {
  AlarmClockService._();
  static final AlarmClockService instance = AlarmClockService._();

  static const MethodChannel _channel = MethodChannel('com.modulix.app/alarm_clock');

  /// For unit testing platform channel interactions on desktop hosts
  @visibleForTesting
  bool forcePlatformChannelInTests = false;

  bool get _isAndroidPlatform => (!kIsWeb && Platform.isAndroid) || forcePlatformChannelInTests;

  /// Check whether exact alarms can be scheduled on Android 12+ (API 31+).
  /// Always returns true on pre-Android 12, iOS, and Web.
  Future<bool> canScheduleExactAlarms() async {
    if (!_isAndroidPlatform) return true;
    try {
      final canSchedule = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return canSchedule ?? true;
    } catch (e) {
      debugPrint('[AlarmClockService] canScheduleExactAlarms error: $e');
      return true;
    }
  }

  /// Schedule a native AlarmClockInfo intent.
  /// Pierces Deep Doze and turns on CPU execution at [targetTime].
  Future<bool> scheduleAlarm({
    required DateTime targetTime,
    required String title,
    required bool isBreak,
  }) async {
    final triggerMs = targetTime.millisecondsSinceEpoch;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (triggerMs <= nowMs) {
      debugPrint('[AlarmClockService] targetTime is in the past, skipping alarm.');
      return false;
    }

    if (!_isAndroidPlatform) return true;

    try {
      final success = await _channel.invokeMethod<bool>('scheduleAlarmClock', {
        'triggerMs': triggerMs,
        'title': title,
        'isBreak': isBreak,
      });
      debugPrint('[AlarmClockService] Scheduled native alarm clock for $targetTime (success: $success)');
      return success ?? false;
    } catch (e) {
      debugPrint('[AlarmClockService] scheduleAlarm error: $e');
      return false;
    }
  }

  /// Cancel any currently scheduled native alarm clock.
  Future<bool> cancelAlarm() async {
    if (!_isAndroidPlatform) return true;
    try {
      final success = await _channel.invokeMethod<bool>('cancelAlarmClock');
      debugPrint('[AlarmClockService] Cancelled native alarm clock');
      return success ?? false;
    } catch (e) {
      debugPrint('[AlarmClockService] cancelAlarm error: $e');
      return false;
    }
  }

  /// Opens the system Settings screen for "Alarms & Reminders" on Android 12+ (API 31+).
  Future<bool> openExactAlarmSettings() async {
    if (!_isAndroidPlatform) return true;
    try {
      final success = await _channel.invokeMethod<bool>('openExactAlarmSettings');
      return success ?? false;
    } catch (e) {
      debugPrint('[AlarmClockService] openExactAlarmSettings error: $e');
      return false;
    }
  }
}
