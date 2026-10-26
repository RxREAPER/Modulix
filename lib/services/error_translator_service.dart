import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Clinical-facing translation of technical errors, runtime glitches,
/// or network disconnects. Modulix guarantees that technical jargon
/// and stack traces are never exposed in user-facing body copy.
class DoctorErrorTranslation {
  final String headline;
  final String explanation;
  final String primaryActionLabel;
  final IconData icon;
  final String domain;
  final String technicalDetails;

  const DoctorErrorTranslation({
    required this.headline,
    required this.explanation,
    required this.primaryActionLabel,
    required this.icon,
    required this.domain,
    required this.technicalDetails,
  });
}

/// Centralized translator service implementing the 5 clinical error domains.
class ErrorTranslatorService {
  ErrorTranslatorService._();

  static DoctorErrorTranslation translate(
    dynamic error, {
    StackTrace? stackTrace,
    String? domain,
  }) {
    final errorStr = (error?.toString() ?? '').trim();
    final stackStr = (stackTrace?.toString() ?? '').trim();
    final combinedDetails = [
      if (errorStr.isNotEmpty) 'Error: $errorStr',
      if (stackStr.isNotEmpty) 'StackTrace:\n$stackStr',
    ].join('\n\n');

    final lowerError = errorStr.toLowerCase();
    final explicitDomain = domain?.toLowerCase();

    // ── Domain A: Authentication & Sign-In ──────────────────────────────
    // 1. Session Expiration / JWT 401
    if (lowerError.contains('jwt') ||
        lowerError.contains('401') ||
        lowerError.contains('unauthorized') ||
        lowerError.contains('token expired') ||
        lowerError.contains('session expired') ||
        lowerError.contains('refresh_token_not_found') ||
        lowerError.contains('invalid_token')) {
      return DoctorErrorTranslation(
        headline: 'Session Paused',
        explanation:
            'Your login session expired, but your local study notes and progress are safe. Re-connect your account or keep studying offline.',
        primaryActionLabel: 'Sign In Again',
        icon: Icons.lock_reset_outlined,
        domain: 'Authentication Session',
        technicalDetails: combinedDetails,
      );
    }

    if (explicitDomain == 'auth' ||
        lowerError.contains('google_sign_in') ||
        lowerError.contains('googlesignin') ||
        lowerError.contains('sign_in') ||
        lowerError.contains('signin') ||
        lowerError.contains('auth/')) {
      // Google Error 10 (Play Services / SHA mismatch / Developer Error)
      if (lowerError.contains(': 10') ||
          lowerError.contains('code: 10') ||
          lowerError.contains('code 10') ||
          lowerError.contains('error 10') ||
          lowerError.contains('developer_error') ||
          lowerError.contains('status code 10')) {
        return DoctorErrorTranslation(
          headline: 'Account Setup in Progress',
          explanation:
              'Google Play sign-in is temporarily unavailable on this device. You can keep studying uninterrupted as a guest.',
          primaryActionLabel: 'Continue as Guest',
          icon: Icons.account_circle_outlined,
          domain: 'Authentication',
          technicalDetails: combinedDetails,
        );
      }

      // Google Error 12500 / Cancelled
      if (lowerError.contains('12500') ||
          lowerError.contains('sign-in cancelled') ||
          lowerError.contains('sign_in_canceled') ||
          lowerError.contains('signincanceled') ||
          lowerError.contains('canceled') ||
          lowerError.contains('cancelled')) {
        return DoctorErrorTranslation(
          headline: 'Sign-In Cancelled',
          explanation:
              'You closed the Google sign-in window. Your study progress remains safely saved on this phone.',
          primaryActionLabel: 'Try Again',
          icon: Icons.lock_clock_outlined,
          domain: 'Authentication',
          technicalDetails: combinedDetails,
        );
      }

      // Invalid credential / Wrong password
      if (lowerError.contains('invalid-credential') ||
          lowerError.contains('wrong-password') ||
          lowerError.contains('invalid_grant') ||
          lowerError.contains('invalid-login-credentials') ||
          lowerError.contains('user-not-found')) {
        return DoctorErrorTranslation(
          headline: 'Account Not Recognized',
          explanation:
              'The email or password does not match our records. Please double check and try again.',
          primaryActionLabel: 'Reset Password',
          icon: Icons.password_outlined,
          domain: 'Authentication',
          technicalDetails: combinedDetails,
        );
      }

      // Rate limit / Too many requests
      if (lowerError.contains('too-many-requests') ||
          lowerError.contains('rate_limit') ||
          lowerError.contains('rate-limit')) {
        return DoctorErrorTranslation(
          headline: 'Take a Quick Breath',
          explanation:
              'Too many attempts in a row. For your security, please wait about a minute before trying again.',
          primaryActionLabel: 'Wait & Retry',
          icon: Icons.timer_outlined,
          domain: 'Authentication',
          technicalDetails: combinedDetails,
        );
      }

      // Network request failed in Auth context
      if (lowerError.contains('network') ||
          error is SocketException ||
          lowerError.contains('socketexception')) {
        return DoctorErrorTranslation(
          headline: 'Sign-In Server Offline',
          explanation:
              'Could not reach the authentication service. Check your internet connection or keep studying offline.',
          primaryActionLabel: 'Retry Connection',
          icon: Icons.wifi_off_outlined,
          domain: 'Authentication',
          technicalDetails: combinedDetails,
        );
      }
    }

    // ── Domain B: Cloud Sync & Backup ───────────────────────────────────
    if (error is SocketException ||
        lowerError.contains('socketexception') ||
        lowerError.contains('network-request-failed') ||
        lowerError.contains('connection refused') ||
        lowerError.contains('failed host lookup') ||
        lowerError.contains('network is unreachable') ||
        lowerError.contains('clientexception') ||
        error is TimeoutException ||
        lowerError.contains('timeoutexception')) {
      return DoctorErrorTranslation(
        headline: 'You\'re Offline',
        explanation:
            'No internet connection detected. Modulix has saved your study hours locally and will sync when you\'re back online.',
        primaryActionLabel: 'Keep Studying',
        icon: Icons.cloud_off_outlined,
        domain: 'Cloud & Network',
        technicalDetails: combinedDetails,
      );
    }

    if (lowerError.contains('500') ||
        lowerError.contains('502') ||
        lowerError.contains('503') ||
        lowerError.contains('504') ||
        lowerError.contains('internalservererror') ||
        lowerError.contains('server error')) {
      return DoctorErrorTranslation(
        headline: 'Cloud Sync Queued',
        explanation:
            'The sync servers are taking a brief break. Your notes and study logs are safely stored right here on your phone.',
        primaryActionLabel: 'Keep Studying',
        icon: Icons.sync_problem_outlined,
        domain: 'Cloud & Network',
        technicalDetails: combinedDetails,
      );
    }

    if (error is FormatException ||
        lowerError.contains('formatexception') ||
        lowerError.contains('backup') &&
            (lowerError.contains('corrupt') ||
                lowerError.contains('unreadable') ||
                lowerError.contains('invalid'))) {
      return DoctorErrorTranslation(
        headline: 'File Unreadable',
        explanation:
            'We couldn\'t read this backup file. Don\'t worry, your current study logs are safe and untouched.',
        primaryActionLabel: 'Choose Another File',
        icon: Icons.folder_delete_outlined,
        domain: 'Backup & Restore',
        technicalDetails: combinedDetails,
      );
    }

    if (lowerError.contains('quota') ||
        lowerError.contains('storage full') ||
        lowerError.contains('insufficient storage') ||
        lowerError.contains('quotaexceeded')) {
      return DoctorErrorTranslation(
        headline: 'Cloud Storage Full',
        explanation:
            'Your cloud backup space is full. Your local study logs are still saving normally on this phone.',
        primaryActionLabel: 'Manage Storage',
        icon: Icons.cloud_queue_outlined,
        domain: 'Cloud Storage',
        technicalDetails: combinedDetails,
      );
    }

    // ── Domain C: Curriculum, Syllabus & Content ────────────────────────
    if (error is RangeError ||
        error is IndexError ||
        lowerError.contains('rangeerror') ||
        lowerError.contains('indexerror') ||
        lowerError.contains('out of range') ||
        lowerError.contains('chapter not found') ||
        lowerError.contains('subject not found')) {
      return DoctorErrorTranslation(
        headline: 'Topic Not Found',
        explanation:
            'This lecture unit isn\'t in your current curriculum edition. Browse the full syllabus to find it.',
        primaryActionLabel: 'Browse All Units',
        icon: Icons.auto_stories_outlined,
        domain: 'Curriculum',
        technicalDetails: combinedDetails,
      );
    }

    if (explicitDomain == 'route' ||
        lowerError.contains('goexception') ||
        lowerError.contains('route not found') ||
        lowerError.contains('no route') ||
        lowerError.contains('page not found') ||
        lowerError.contains('404')) {
      return DoctorErrorTranslation(
        headline: 'Page Not Found',
        explanation:
            'We couldn\'t find that screen in your current edition. Let\'s head back to your study desk.',
        primaryActionLabel: 'Return to Home Desk',
        icon: Icons.alt_route_outlined,
        domain: 'Navigation',
        technicalDetails: combinedDetails,
      );
    }

    if (lowerError.contains('zero matches') ||
        lowerError.contains('no modules found') ||
        lowerError.contains('no lectures or q-banks') ||
        lowerError.contains('no search results')) {
      return DoctorErrorTranslation(
        headline: 'No Modules Found',
        explanation:
            'Nothing matched what you searched for in this subject.',
        primaryActionLabel: 'Clear Filters',
        icon: Icons.search_off_outlined,
        domain: 'Search',
        technicalDetails: combinedDetails,
      );
    }

    if (lowerError.contains('no clinical notes') ||
        lowerError.contains('no notes yet') ||
        lowerError.contains('empty notes')) {
      return DoctorErrorTranslation(
        headline: 'No Notes Yet',
        explanation:
            'You haven\'t added any personal notes or mnemonics to this chapter yet.',
        primaryActionLabel: '+ Add First Note',
        icon: Icons.note_add_outlined,
        domain: 'Clinical Notes',
        technicalDetails: combinedDetails,
      );
    }

    // ── Domain D: Focus Timer, Audio & Hardware ─────────────────────────
    if (lowerError.contains('audioplayer') ||
        lowerError.contains('audio') ||
        lowerError.contains('codec') ||
        lowerError.contains('sound') ||
        lowerError.contains('track')) {
      return DoctorErrorTranslation(
        headline: 'Audio Paused',
        explanation:
            'The background sound track couldn\'t be loaded. Your focus timer is still running normally.',
        primaryActionLabel: 'Pick Another Sound',
        icon: Icons.volume_off_outlined,
        domain: 'Focus Timer & Audio',
        technicalDetails: combinedDetails,
      );
    }

    if (lowerError.contains('battery') ||
        lowerError.contains('wakelock') ||
        lowerError.contains('killed') ||
        lowerError.contains('background execution')) {
      return DoctorErrorTranslation(
        headline: 'Timer Recovered',
        explanation:
            'Your device paused the timer to save battery. Modulix safely recovered your logged focus minutes.',
        primaryActionLabel: 'Resume Session',
        icon: Icons.battery_saver_outlined,
        domain: 'Focus Session',
        technicalDetails: combinedDetails,
      );
    }

    if (lowerError.contains('notification') ||
        lowerError.contains('permission denied') ||
        lowerError.contains('permission_denied')) {
      return DoctorErrorTranslation(
        headline: 'Quiet Timer Mode',
        explanation:
            'Timer completion chimes need notification permissions to sound when your screen is locked.',
        primaryActionLabel: 'Enable in Settings',
        icon: Icons.notifications_off_outlined,
        domain: 'System Permissions',
        technicalDetails: combinedDetails,
      );
    }

    // ── Domain E: Runtime Glitches & Unhandled Exceptions ────────────────
    if (lowerError.contains('sqlite') ||
        lowerError.contains('databaseexception') ||
        lowerError.contains('disk i/o') ||
        lowerError.contains('database locked') ||
        lowerError.contains('contention')) {
      return DoctorErrorTranslation(
        headline: 'Data Protected',
        explanation:
            'Your device had a momentary hiccup saving data. Everything is safe and re-indexed.',
        primaryActionLabel: 'Reload Desk',
        icon: Icons.verified_user_outlined,
        domain: 'Database & Storage',
        technicalDetails: combinedDetails,
      );
    }

    // Global Catch-all / RenderFlex / Code Bugs
    return DoctorErrorTranslation(
      headline: 'Study Session Protected',
      explanation:
          'Something went slightly off with the screen display. Don\'t worry, all your notes and study time are safe.',
      primaryActionLabel: 'Reopen Home Desk',
      icon: Icons.shield_outlined,
      domain: 'Runtime Shield',
      technicalDetails: combinedDetails,
    );
  }
}
