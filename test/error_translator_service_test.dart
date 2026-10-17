import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:modulix/services/error_translator_service.dart';

void main() {
  group('ErrorTranslatorService - 5 Clinical Domains', () {
    // ── Domain A: Authentication & Sign-In ──
    test('Domain A: Google Play Services / SHA mismatch (Code 10)', () {
      final t = ErrorTranslatorService.translate(
        'PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)',
      );
      expect(t.headline, 'Account Setup in Progress');
      expect(
        t.explanation,
        contains('Google Play authentication is temporarily unavailable'),
      );
      expect(t.primaryActionLabel, 'Continue as Guest');
      expect(t.domain, 'Authentication');
      expect(t.icon, Icons.account_circle_outlined);
    });

    test('Domain A: Google Sign-In Cancelled / 12500', () {
      final t = ErrorTranslatorService.translate(
        'PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 12500: , null, null)',
      );
      expect(t.headline, 'Sign-In Deferred');
      expect(t.explanation, contains('You closed the Google authentication window'));
      expect(t.primaryActionLabel, 'Try Again');
      expect(t.icon, Icons.lock_clock_outlined);
    });

    test('Domain A: Invalid credentials', () {
      final t = ErrorTranslatorService.translate('auth/invalid-credential');
      expect(t.headline, 'Credentials Unrecognized');
      expect(t.primaryActionLabel, 'Reset Password');
      expect(t.icon, Icons.password_outlined);
    });

    test('Domain A: Too many requests cooldown', () {
      final t = ErrorTranslatorService.translate('auth/too-many-requests');
      expect(t.headline, 'Sign-In Cooldown Active');
      expect(t.primaryActionLabel, 'Wait & Retry');
      expect(t.icon, Icons.timer_outlined);
    });

    test('Domain A: Network request failed during Auth', () {
      final t = ErrorTranslatorService.translate(
        'auth/network-request-failed',
        domain: 'auth',
      );
      expect(t.headline, 'Authentication Server Unreachable');
      expect(t.primaryActionLabel, 'Retry Connection');
      expect(t.icon, Icons.wifi_off_outlined);
    });

    // ── Domain B: Cloud Sync & Backup ──
    test('Domain B: SocketException / Offline mode', () {
      final t = ErrorTranslatorService.translate(
        const SocketException('Failed host lookup: api.supabase.co'),
      );
      expect(t.headline, 'Offline Mode Active');
      expect(t.explanation, contains('Modulix has saved your study hours locally'));
      expect(t.primaryActionLabel, 'Got It');
      expect(t.icon, Icons.cloud_off_outlined);
    });

    test('Domain B: HTTP 500/502/503 server maintenance', () {
      final t = ErrorTranslatorService.translate(
        'HTTP 503 Service Unavailable: Server Error',
      );
      expect(t.headline, 'Cloud Sync Queued');
      expect(t.primaryActionLabel, 'Keep Studying');
      expect(t.icon, Icons.sync_problem_outlined);
    });

    test('Domain B: Corrupt Backup FormatException', () {
      final t = ErrorTranslatorService.translate(
        const FormatException('Unexpected character in backup archive'),
      );
      expect(t.headline, 'Backup Archive Unreadable');
      expect(t.primaryActionLabel, 'Choose Another File');
      expect(t.icon, Icons.folder_delete_outlined);
    });

    test('Domain B: Storage Quota Exceeded', () {
      final t = ErrorTranslatorService.translate(
        'GoogleDrive quotaExceeded: storage full',
      );
      expect(t.headline, 'Cloud Storage Filled');
      expect(t.primaryActionLabel, 'Manage Storage');
      expect(t.icon, Icons.cloud_queue_outlined);
    });

    // ── Domain C: Curriculum, Syllabus & Content ──
    test('Domain C: Out of bounds RangeError', () {
      final t = ErrorTranslatorService.translate(
        RangeError('Index 45 out of range for chapters'),
      );
      expect(t.headline, 'Topic Being Refreshed');
      expect(t.explanation, contains('not indexed in the active curriculum'));
      expect(t.primaryActionLabel, 'Browse All Units');
      expect(t.icon, Icons.auto_stories_outlined);
    });

    test('Domain C: Route 404 deep link', () {
      final t = ErrorTranslatorService.translate(
        'GoException: no route for /curriculum/unknown_subject',
        domain: 'route',
      );
      expect(t.headline, 'Destination Not in Syllabus');
      expect(t.primaryActionLabel, 'Return to Home Desk');
      expect(t.icon, Icons.alt_route_outlined);
    });

    test('Domain C: Search zero matches', () {
      final t = ErrorTranslatorService.translate(
        'no search results in subject',
      );
      expect(t.headline, 'No Modules Found');
      expect(t.primaryActionLabel, 'Clear Filters');
      expect(t.icon, Icons.search_off_outlined);
    });

    test('Domain C: Empty clinical notes', () {
      final t = ErrorTranslatorService.translate(
        'no clinical notes yet for this unit',
      );
      expect(t.headline, 'No Clinical Notes Yet');
      expect(t.primaryActionLabel, '+ Add First Note');
      expect(t.icon, Icons.note_add_outlined);
    });

    // ── Domain D: Focus Timer, Audio & Hardware ──
    test('Domain D: Audio codec or playback error', () {
      final t = ErrorTranslatorService.translate(
        'AudioPlayerException: audio codec unsupported',
      );
      expect(t.headline, 'Ambient Audio Paused');
      expect(t.primaryActionLabel, 'Pick Another Sound');
      expect(t.icon, Icons.volume_off_outlined);
    });

    test('Domain D: Battery optimization / session preserved', () {
      final t = ErrorTranslatorService.translate(
        'Wakelock error: device battery killed process',
      );
      expect(t.headline, 'Study Session Preserved');
      expect(t.primaryActionLabel, 'Resume Session');
      expect(t.icon, Icons.battery_saver_outlined);
    });

    test('Domain D: Notification permission denied', () {
      final t = ErrorTranslatorService.translate(
        'PlatformException(permission_denied, notification privileges)',
      );
      expect(t.headline, 'Quiet Timer Enabled');
      expect(t.primaryActionLabel, 'Enable in Settings');
      expect(t.icon, Icons.notifications_off_outlined);
    });

    // ── Domain E: Runtime Glitches & Crash Protection ──
    test('Domain E: SQLite database contention', () {
      final t = ErrorTranslatorService.translate(
        'DatabaseException: disk I/O error or database locked',
      );
      expect(t.headline, 'Data Re-Verified');
      expect(t.primaryActionLabel, 'Reload Desk');
      expect(t.icon, Icons.verified_user_outlined);
    });

    test('Domain E: RenderFlex overflow / code glitch', () {
      final t = ErrorTranslatorService.translate(
        'A RenderFlex overflowed by 42 pixels on the bottom.',
      );
      expect(t.headline, 'Study Session Protected');
      expect(t.explanation, contains('Your logged hours, notes, and task progress remain safely cached'));
      expect(t.primaryActionLabel, 'Reopen Home Desk');
      expect(t.icon, Icons.shield_outlined);
    });

    test('Telemetry integrity: Stack trace preserved in technicalDetails only', () {
      final stack = StackTrace.current;
      final t = ErrorTranslatorService.translate(
        'Null check operator used on a null value',
        stackTrace: stack,
      );
      expect(t.technicalDetails, contains('StackTrace:'));
      expect(t.technicalDetails, contains('Null check operator'));
      // Guarantee body copy doesn't expose technical terms
      expect(t.headline, isNot(contains('Null check')));
      expect(t.explanation, isNot(contains('Null check')));
    });
  });
}
