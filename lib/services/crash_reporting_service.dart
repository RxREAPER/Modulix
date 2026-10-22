import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static CrashReportingService? _instance;
  static CrashReportingService get instance =>
      _instance ??= CrashReportingService._();

  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  final List<String> _recentErrors = [];
  List<String> get recentErrors => List.unmodifiable(_recentErrors);

  CrashReportingService._();

  Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _crashlytics = FirebaseCrashlytics.instance;
        _isInitialized = true;

        // Pass all uncaught "fatal" errors from the framework to Crashlytics
        FlutterError.onError = (details) {
          _recordLocal(details.exceptionAsString());
          _crashlytics?.recordFlutterFatalError(details);
        };

        // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          _recordLocal(error.toString());
          _crashlytics?.recordError(error, stack, fatal: true);
          return true;
        };

        debugPrint('[CrashReportingService] Firebase Crashlytics active.');
      } else {
        // Fallback global error logger
        FlutterError.onError = (details) {
          _recordLocal(details.exceptionAsString());
          FlutterError.presentError(details);
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          _recordLocal(error.toString());
          debugPrint('[CrashReporting] Uncaught Async Error: $error\n$stack');
          return true;
        };

        debugPrint(
            '[CrashReportingService] Firebase not initialized; running in local safety mode.');
      }
    } catch (e) {
      debugPrint('[CrashReportingService] Init fallback: $e');
    }
  }

  void _recordLocal(String err) {
    _recentErrors.add('${DateTime.now().toIso8601String()}: $err');
    if (_recentErrors.length > 25) {
      _recentErrors.removeAt(0);
    }
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    _recordLocal(exception.toString());
    if (kDebugMode) {
      debugPrint('[CrashReporting] ⚠️ Exception logged: $exception (reason: $reason)');
    }
    if (_isInitialized && _crashlytics != null) {
      try {
        await _crashlytics!.recordError(exception, stack, reason: reason, fatal: fatal);
      } catch (_) {}
    }
  }

  Future<void> setDoctorName(String doctorName) async {
    if (_isInitialized && _crashlytics != null) {
      try {
        await _crashlytics!.setUserIdentifier(doctorName);
      } catch (_) {}
    }
  }

  Future<void> setCustomKey(String key, Object value) async {
    if (_isInitialized && _crashlytics != null) {
      try {
        await _crashlytics!.setCustomKey(key, value);
      } catch (_) {}
    }
  }
}
