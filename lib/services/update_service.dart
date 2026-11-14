import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_metadata.dart';
import '../theme/app_theme.dart';
import '../theme/modulix_theme.dart';
import '../widgets/animations/apple_pressable.dart';
import '../widgets/feedback/modulix_toast.dart';

/// Representation of a published GitHub release for Modulix.
class AppReleaseInfo {
  final String tagName;
  final String cleanVersion;
  final String title;
  final String notes;
  final String releaseUrl;
  final bool isUpdateAvailable;

  const AppReleaseInfo({
    required this.tagName,
    required this.cleanVersion,
    required this.title,
    required this.notes,
    required this.releaseUrl,
    required this.isUpdateAvailable,
  });
}

/// Service managing remote version discovery, update notification,
/// and web redirection for new releases without in-app APK downloads.
class UpdateService {
  UpdateService._();

  static const String _lastCheckPrefKey = 'modulix_last_update_check_epoch';
  static const Duration _autoCheckInterval = Duration(hours: 24);

  /// Performs a non-blocking check against GitHub Releases API.
  /// Returns [AppReleaseInfo] if a release was fetched, or null if offline/error.
  static Future<AppReleaseInfo?> fetchLatestRelease() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(Uri.parse(AppMetadata.latestReleaseApiUrl));
      request.headers.set('User-Agent', 'Modulix-App/${AppMetadata.currentVersion}');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final rawTag = json['tag_name']?.toString() ?? '';
      final title = json['name']?.toString() ?? rawTag;
      final notes = json['body']?.toString() ?? '';
      final releaseUrl = json['html_url']?.toString() ?? AppMetadata.websiteUrl;

      final cleanRemoteVersion = rawTag.replaceAll(RegExp(r'[^0-9.]'), '');
      final isNewer = _isVersionGreater(cleanRemoteVersion, AppMetadata.currentVersion);

      return AppReleaseInfo(
        tagName: rawTag,
        cleanVersion: cleanRemoteVersion,
        title: title,
        notes: notes,
        releaseUrl: releaseUrl,
        isUpdateAvailable: isNewer,
      );
    } catch (_) {
      return null;
    }
  }

  /// Visible for unit testing semantic version parsing.
  @visibleForTesting
  static bool isVersionGreaterForTesting(String remote, String current) =>
      _isVersionGreater(remote, current);

  /// Compares semantic versions (e.g. '1.39.0' vs '1.38.0').
  /// Returns true if [remote] is strictly greater than [current].
  static bool _isVersionGreater(String remote, String current) {
    if (remote.isEmpty) return false;
    final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (rParts.length < 3) {
      rParts.add(0);
    }
    while (cParts.length < 3) {
      cParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (rParts[i] > cParts[i]) return true;
      if (rParts[i] < cParts[i]) return false;
    }
    return false;
  }

  /// Quiet check triggered on app launch or resume.
  /// Throttled to run at most once every 24 hours.
  static Future<void> checkOnLaunch(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastCheckPrefKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastCheck < _autoCheckInterval.inMilliseconds) {
        return;
      }

      final info = await fetchLatestRelease();
      await prefs.setInt(_lastCheckPrefKey, now);

      if (info != null && info.isUpdateAvailable && context.mounted) {
        showUpdateSheet(context, info);
      }
    } catch (_) {
      // Background check failure must never interrupt the user.
    }
  }

  /// Explicit check triggered when the user taps "Check for Updates" in Settings.
  static Future<void> checkForUpdatesManual(BuildContext context) async {
    HapticFeedback.lightImpact();
    ModulixToast.showInfo(context, message: 'Checking for updates...');

    final info = await fetchLatestRelease();

    if (!context.mounted) return;

    if (info == null) {
      ModulixToast.showInfo(
        context,
        message: 'Could not connect to update server. Check your connection.',
      );
      return;
    }

    if (info.isUpdateAvailable) {
      showUpdateSheet(context, info);
    } else {
      ModulixToast.showSuccess(
        context,
        message: 'You are on the latest version (${AppMetadata.fullVersionString})',
      );
    }
  }

  /// Opens the official website or release portal in the external system browser.
  static Future<void> openUpdateWebsite({String? customUrl}) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(customUrl ?? AppMetadata.websiteUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Displays an editorial, non-intrusive update prompt bottom sheet.
  /// Strictly redirects to the official website instead of performing in-app downloads.
  static void showUpdateSheet(BuildContext context, AppReleaseInfo info) {
    final activeTheme = context.modulixTheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: activeTheme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeTheme.mutedText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kicker & Version Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'UPDATE AVAILABLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'v${info.cleanVersion}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: activeTheme.inkForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'A new version of Modulix is ready.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: activeTheme.inkForeground,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Current version: ${AppMetadata.fullVersionString}\n'
                'Visit the official website to download the latest signed APK or view the full changelog.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: activeTheme.mutedText,
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ApplePressable(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        openUpdateWebsite();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Visit Website to Update',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ApplePressable(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: activeTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: activeTheme.borderSubtle),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Later',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: activeTheme.mutedText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
