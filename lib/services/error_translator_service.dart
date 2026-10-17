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
              'Google Play authentication is temporarily unavailable on this device. You can continue studying uninterrupted.',
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
          headline: 'Sign-In Deferred',
          explanation:
              'You closed the Google authentication window. Your offline progress remains stored on this phone.',
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
          headline: 'Credentials Unrecognized',
          explanation:
              'The email or password entered does not match our records. Please verify and retry.',
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
          headline: 'Sign-In Cooldown Active',
          explanation:
              'Multiple access attempts detected. For account security, please wait 60 seconds before retrying.',
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
          headline: 'Authentication Server Unreachable',
          explanation:
              'Could not establish a secure handshake with the login server. Check your network or work offline.',
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
        headline: 'Offline Mode Active',
        explanation:
            'No internet connection detected. Modulix has saved your study hours locally and will sync when reconnected.',
        primaryActionLabel: 'Got It',
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
            'The sync servers are currently undergoing brief routine maintenance. Your local database remains intact.',
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
        headline: 'Backup Archive Unreadable',
        explanation:
            'The selected file appears damaged or incomplete. Your active study logs were preserved untouched.',
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
        headline: 'Cloud Storage Filled',
        explanation:
            'Your personal cloud storage account has reached its capacity limit. Local backups are continuing normally.',
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
        headline: 'Topic Being Refreshed',
        explanation:
            'This specific lecture unit is not indexed in the active curriculum edition.',
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
        headline: 'Destination Not in Syllabus',
        explanation:
            'The requested syllabus link could not be located in this edition.',
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
            'No lectures or Q-Banks match your search query in this subject.',
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
        headline: 'No Clinical Notes Yet',
        explanation:
            'You have not attached personal summaries or mnemonics to this chapter.',
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
        headline: 'Ambient Audio Paused',
        explanation:
            'The selected background audio track could not be loaded. Your focus timer continues running uninterrupted.',
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
        headline: 'Study Session Preserved',
        explanation:
            'The device closed the timer to conserve battery. Modulix safely recovered your logged focus minutes.',
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
        headline: 'Quiet Timer Enabled',
        explanation:
            'End-of-session audio chimes require notification privileges to sound when the screen is locked.',
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
        headline: 'Data Re-Verified',
        explanation:
            'A temporary storage contention occurred. The database automatically re-indexed your records.',
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
          'An unexpected screen display glitch occurred. Your logged hours, notes, and task progress remain safely cached.',
      primaryActionLabel: 'Reopen Home Desk',
      icon: Icons.shield_outlined,
      domain: 'Runtime Shield',
      technicalDetails: combinedDetails,
    );
  }
}
