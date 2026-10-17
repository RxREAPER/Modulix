import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/auth_service.dart';
import 'widgets/errors/modulix_error_scaffold.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Install Doctor Crash Shield to replace default grey/red error screens
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ModulixErrorScaffold(details: details);
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    CrashReportingService.instance.recordError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashReportingService.instance.recordError(error, stack);
    return true; // handled
  };

  // Initialize critical local storage & native renderers in parallel
  await Future.wait([
    rive.RiveNative.init(),
    StorageService.init(),
    DatabaseService.instance.database,
  ]);

  // Launch background services concurrently without stalling the first frame
  unawaited(_initBackgroundServices());

  runApp(
    const ProviderScope(
      child: ModulixApp(),
    ),
  );
}

Future<void> _initBackgroundServices() async {
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('[NotificationService] Init error: $e');
  }

  try {
    await AuthService.instance.initialize();
  } catch (e) {
    debugPrint('[AuthService] Init error: $e');
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] Running in local offline mode: $e');
  }

  try {
    await AnalyticsService.instance.init();
    await CrashReportingService.instance.init();
  } catch (e) {
    debugPrint('[Analytics/CrashReporting] Init error: $e');
  }
}
