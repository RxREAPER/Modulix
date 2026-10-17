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
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize native engines
  await rive.RiveNative.init();
  await StorageService.init();
  await NotificationService.instance.init();
  await DatabaseService.instance.database;
  await AuthService.instance.initialize();

  // Initialize Firebase & observability with graceful fallback
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] Running in local offline mode: $e');
  }
  await AnalyticsService.instance.init();
  await CrashReportingService.instance.init();

  runApp(
    const ProviderScope(
      child: ModulixApp(),
    ),
  );
}
