import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/services/analytics_service.dart';
import 'package:modulix/services/crash_reporting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyticsService & CrashReportingService Tests', () {
    test('AnalyticsService initializes in fallback mode and records events safely', () async {
      final analytics = AnalyticsService.instance;
      await analytics.init();

      // Should complete without throwing even when Firebase is not configured
      await analytics.logEvent('test_event', {'param1': 'value1'});
      await analytics.logTimerStarted(mode: 'pomodoro', subject: 'anatomy', durationMins: 25);
      await analytics.logTimerCompleted(mode: 'pomodoro', subject: 'anatomy', durationMins: 25, breakMins: 5);
      await analytics.logModuleCompleted(subject: 'anatomy', type: 'video', topicId: 'vid_1');
      await analytics.logPlanConfigured(subject: 'anatomy', targetDate: '2026-11-01', dailyHours: 4.0);
      await analytics.logOnboardingCompleted(doctorName: 'Dr. Test', edition: 'marrow_8');
      await analytics.logBackupExported();
      await analytics.logBackupRestored();
    });

    test('CrashReportingService records non-fatal errors in local ring buffer', () async {
      final crash = CrashReportingService.instance;
      await crash.init();

      await crash.recordError(Exception('Test non-fatal error'), StackTrace.current, reason: 'unit_test');
      expect(crash.recentErrors.isNotEmpty, true);
      expect(crash.recentErrors.last.contains('Test non-fatal error'), true);
    });
  });
}
