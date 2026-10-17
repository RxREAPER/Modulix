import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  AnalyticsService._();

  Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _analytics = FirebaseAnalytics.instance;
        _isInitialized = true;
        debugPrint('[AnalyticsService] Firebase Analytics active.');
      } else {
        debugPrint(
            '[AnalyticsService] Firebase not initialized; running in local diagnostic mode.');
      }
    } catch (e) {
      debugPrint('[AnalyticsService] Analytics init fallback: $e');
    }
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (kDebugMode) {
      debugPrint('[Analytics] 📊 $name -> ${parameters ?? {}}');
    }
    if (_isInitialized && _analytics != null) {
      try {
        await _analytics!.logEvent(name: name, parameters: parameters);
      } catch (e) {
        debugPrint('[AnalyticsService] Failed to log event $name: $e');
      }
    }
  }

  Future<void> logScreenView({required String screenName}) async {
    if (kDebugMode) {
      debugPrint('[Analytics] 📱 Screen -> $screenName');
    }
    if (_isInitialized && _analytics != null) {
      try {
        await _analytics!.logScreenView(screenName: screenName);
      } catch (_) {}
    }
  }

  Future<void> logTimerStarted({
    required String mode,
    required String subject,
    required int durationMins,
  }) async {
    await logEvent('focus_timer_started', {
      'mode': mode,
      'subject': subject,
      'duration_mins': durationMins,
    });
  }

  Future<void> logTimerCompleted({
    required String mode,
    required String subject,
    required int durationMins,
    required int breakMins,
  }) async {
    await logEvent('focus_timer_completed', {
      'mode': mode,
      'subject': subject,
      'duration_mins': durationMins,
      'break_mins': breakMins,
    });
  }

  Future<void> logModuleCompleted({
    required String subject,
    required String type,
    required String topicId,
  }) async {
    await logEvent('module_completed', {
      'subject': subject,
      'type': type,
      'topic_id': topicId,
    });
  }

  Future<void> logPlanConfigured({
    required String subject,
    required String targetDate,
    required double dailyHours,
  }) async {
    await logEvent('study_plan_configured', {
      'subject': subject,
      'target_date': targetDate,
      'daily_hours': dailyHours,
    });
  }

  Future<void> logOnboardingCompleted({
    required String doctorName,
    required String edition,
  }) async {
    await logEvent('onboarding_completed', {
      'doctor_name': doctorName,
      'edition': edition,
    });
  }

  Future<void> logBackupExported() async {
    await logEvent('backup_exported', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logBackupRestored() async {
    await logEvent('backup_restored', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
