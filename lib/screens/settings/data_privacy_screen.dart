import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/time_log_provider.dart';
import '../../services/backup_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/feedback/modulix_toast.dart';

/// Minimalist, high-density Data & Privacy sub-page.
/// Focuses purely on local storage transparency, JSON backups, legal texts,
/// and selective local data management.
class DataPrivacyScreen extends ConsumerStatefulWidget {
  const DataPrivacyScreen({super.key});

  @override
  ConsumerState<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends ConsumerState<DataPrivacyScreen> {
  int _dbSizeBytes = 0;
  int _timerLogsCount = 0;
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _loadStorageMetrics();
  }

  Future<void> _loadStorageMetrics() async {
    try {
      final size = await DatabaseService.instance.getDatabaseSizeBytes();
      final logs = await DatabaseService.instance.getAllTimeLogs();
      if (mounted) {
        setState(() {
          _dbSizeBytes = size;
          _timerLogsCount = logs.length;
          _isLoadingMetrics = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMetrics = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;

    return Scaffold(
      backgroundColor: activeTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: activeTheme.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: activeTheme.inkForeground, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
        title: Text(
          'Data & Privacy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: activeTheme.inkForeground,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          // ── 1. Local Storage Metrics ───────────────────────────────────────
          _sectionHeader(context, 'STORAGE'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoadingMetrics ? '...' : _formatBytes(_dbSizeBytes),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: activeTheme.inkForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Local Database',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: activeTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: activeTheme.borderSubtle,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoadingMetrics ? '...' : '$_timerLogsCount sessions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: activeTheme.inkForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Recorded Logs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: activeTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: activeTheme.borderSubtle),
                const SizedBox(height: 12),
                Text(
                  'All study progression and timer records are stored locally on this device without telemetry or third-party tracking.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: activeTheme.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 2. Local Backup & Restore ──────────────────────────────────────
          _sectionHeader(context, 'BACKUP & RESTORE'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
            ),
            child: Column(
              children: [
                _actionRow(
                  context: context,
                  icon: Icons.upload_file_rounded,
                  iconColor: AppTheme.accentPrimary,
                  title: 'Export Backup',
                  subtitle: 'Save study records to a portable JSON file',
                  onTap: () => _handleExportBackup(context),
                ),
                _rowDivider(context),
                _actionRow(
                  context: context,
                  icon: Icons.download_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Import Backup',
                  subtitle: 'Restore records from a previously exported JSON file',
                  onTap: () => _handleImportBackup(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 3. Legal Documents ─────────────────────────────────────────────
          _sectionHeader(context, 'LEGAL'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
            ),
            child: Column(
              children: [
                _actionRow(
                  context: context,
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF0D9488),
                  title: 'Privacy Policy',
                  subtitle: 'Data collection, storage, and your rights',
                  onTap: () => _showLegalSheet(
                    context,
                    title: 'Privacy Policy',
                    content: _privacyPolicyContent,
                  ),
                ),
                _rowDivider(context),
                _actionRow(
                  context: context,
                  icon: Icons.article_outlined,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Terms of Use',
                  subtitle: 'Permitted use, liability, and governing law',
                  onTap: () => _showLegalSheet(
                    context,
                    title: 'Terms of Use',
                    content: _termsContent,
                  ),
                ),
                _rowDivider(context),
                _actionRow(
                  context: context,
                  icon: Icons.copyright_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Copyright & IP Notice',
                  subtitle: 'Ownership, prohibited use, and IP protection',
                  onTap: () => _showLegalSheet(
                    context,
                    title: 'Copyright & IP Notice',
                    content: _copyrightContent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 4. Data Management (Local Danger Zone) ─────────────────────────
          _sectionHeader(context, 'DATA MANAGEMENT'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
            ),
            child: Column(
              children: [
                _actionRow(
                  context: context,
                  icon: Icons.timer_off_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Clear Focus Timer History',
                  subtitle: 'Deletes study timer logs from analytics',
                  onTap: _confirmClearTimerLogs,
                ),
                _rowDivider(context),
                _actionRow(
                  context: context,
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Reset Study Progress',
                  subtitle: 'Wipes completed module marks across syllabus',
                  isDestructive: true,
                  onTap: _confirmResetProgress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    final activeTheme = context.modulixTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: activeTheme.mutedText,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _rowDivider(BuildContext context) {
    final activeTheme = context.modulixTheme;
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 58,
      endIndent: 16,
      color: activeTheme.borderSubtle,
    );
  }

  Widget _actionRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final activeTheme = context.modulixTheme;

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : activeTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: activeTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: activeTheme.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExportBackup(BuildContext context) async {
    HapticFeedback.lightImpact();
    await BackupService.exportAndShare(context, ref);
  }

  Future<void> _handleImportBackup(BuildContext context) async {
    HapticFeedback.lightImpact();
    await BackupService.pickAndRestore(context, ref);
    if (mounted) {
      _loadStorageMetrics();
    }
  }

  void _confirmClearTimerLogs() {
    HapticFeedback.selectionClick();
    final activeTheme = context.modulixTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: activeTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: activeTheme.borderSubtle, width: 1.2),
        ),
        title: Text(
          'Clear Focus Timer Logs?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: activeTheme.inkForeground,
          ),
        ),
        content: Text(
          'This will permanently delete all timer session logs from analytics. Module completion progress remains untouched.',
          style: TextStyle(
            fontSize: 13,
            color: activeTheme.mutedText,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: activeTheme.mutedText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(timeLogsProvider.notifier).clearAll();
              if (!mounted) return;
              _loadStorageMetrics();
              ModulixToast.showSuccess(
                context,
                message: 'Focus timer history cleared',
              );
            },
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );
  }

  void _confirmResetProgress() {
    HapticFeedback.heavyImpact();
    final activeTheme = context.modulixTheme;
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isConfirmed = textCtrl.text.trim().toUpperCase() == 'RESET';

          return AlertDialog(
            backgroundColor: activeTheme.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
            ),
            title: const Text(
              'Reset Study Progress',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action permanently clears all completed video checks and progress records across all syllabus editions. Type RESET below to confirm.',
                  style: TextStyle(
                    fontSize: 13,
                    color: activeTheme.mutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: activeTheme.inkForeground,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type RESET',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: activeTheme.mutedText,
                    ),
                    filled: true,
                    fillColor: activeTheme.scaffoldBackground,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: activeTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFEF4444), width: 1.4),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: activeTheme.mutedText,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConfirmed
                      ? const Color(0xFFEF4444)
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isConfirmed
                    ? () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(appStateProvider.notifier)
                            .resetAllProgress();
                        if (!mounted) return;
                        _loadStorageMetrics();
                        ModulixToast.showSuccess(
                          context,
                          message: 'All study progress records have been reset',
                        );
                      }
                    : null,
                child: const Text('Confirm Reset'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLegalSheet(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    HapticFeedback.lightImpact();
    final activeTheme = context.modulixTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: activeTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: activeTheme.mutedText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: activeTheme.inkForeground,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: activeTheme.mutedText, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: activeTheme.borderSubtle),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: activeTheme.inkForeground,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _privacyPolicyContent =
      '''MODULIX — PRIVACY POLICY

Effective Date: 15 November 2026
Last Updated: 15 November 2026

This Privacy Policy describes how Modulix ("we", "our", or "the Application") collects, uses, stores, and protects information in connection with your use of the Modulix mobile application ("App"). By accessing or using the App, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy.

─────────────────────────────────────
1. INFORMATION WE COLLECT

1.1 Information You Provide
When you create an optional cloud sync account, you voluntarily provide:
- An email address (used for authentication only)
- A display name and optional doctor name (used to personalize your experience)
- Avatar preferences (colour and icon identifier)
- Leaderboard display preferences

1.2 Information Collected Automatically
The App does not deploy advertising SDKs, tracking pixels, or behavioral profilers. Automatically collected information is limited to:
- Study session durations (stored locally on your device)
- Module and chapter completion states (stored locally on your device)
- Application preferences (stored locally on your device)

1.3 Information We Do NOT Collect
We do not collect, infer, or process:
- Your precise geolocation
- Biometric data of any kind
- Browsing history outside the App
- Device contacts, call logs, or SMS
- Financial or payment information
- Any data for advertising or behavioral profiling purposes

─────────────────────────────────────
2. HOW WE USE YOUR INFORMATION

We use the information described above exclusively to:
(a) Provide and improve the App's core functionality (progress tracking, focus timer, analytics)
(b) Synchronise your study data across your registered devices, if you opt into cloud sync
(c) Display anonymised leaderboard standings within the App's community features, if you enable this feature
(d) Respond to support or privacy inquiries submitted by you
(e) Comply with applicable legal obligations

We do not sell, rent, trade, or otherwise disclose your personal information to third parties for commercial purposes.

─────────────────────────────────────
3. LOCAL DATA STORAGE AND SOVEREIGNTY

All study records — including focus timer history, module completion progress, streak data, and syllabus annotations — are stored exclusively in a SQLite database on your physical device. This data is never transmitted without your explicit action (such as cloud sync sign-in or manual backup export).

You retain full ownership of all locally stored data. We act solely as a data processor in relation to any data stored on our servers, and you remain the data controller.

─────────────────────────────────────
4. CLOUD SYNCHRONISATION (OPTIONAL)

Cloud sync is a strictly opt-in feature. If you create an account and enable sync:
- Your study data is transmitted over TLS-encrypted connections to our cloud infrastructure (Supabase, hosted on AWS)
- Data is associated with your account UUID and encrypted in transit and at rest
- A single-active-device lock mechanism prevents simultaneous write conflicts
- You may disable sync and delete your remote account at any time under Settings > Account & Sync

Upon account deletion, all remotely stored data associated with your account is permanently and irreversibly purged from our servers within 30 days.

─────────────────────────────────────
5. DATA SHARING AND THIRD PARTIES

5.1 Service Providers
We engage the following sub-processors solely to operate the App:
- Supabase (database hosting and authentication): Your account data and synced study records are stored on Supabase infrastructure subject to Supabase's Data Processing Agreement.
- Google Play Services: Standard device-level services provided by Android/Google as part of the operating system.

We do not use any third-party advertising networks, analytics brokers, or data-sharing partnerships.

5.2 Legal Disclosure
We may disclose information if required to do so by law or in response to a valid legal process (court order, subpoena, or regulatory request), provided we are permitted to notify you in advance where practicable.

─────────────────────────────────────
6. DATA RETENTION

- Local device data: Retained until you explicitly delete it via the Data Management controls in this screen, or until you uninstall the App.
- Cloud account data: Retained for the duration your account remains active. Deleted within 30 days of account deletion.
- Support correspondence: Retained for a maximum of 24 months from the date of resolution.

─────────────────────────────────────
7. YOUR RIGHTS UNDER APPLICABLE LAW

Depending on your jurisdiction, you may have the right to:
- Access: Obtain a copy of the personal data we hold about you
- Correction: Request correction of inaccurate data
- Erasure: Request deletion of your personal data
- Portability: Receive your data in a machine-readable format (use the Export Backup feature)
- Restriction: Request that we limit processing of your data
- Objection: Object to certain processing activities

To exercise any of these rights, contact us at: modulix.support@gmail.com

─────────────────────────────────────
8. CHILDREN'S PRIVACY

The App is not intended for use by individuals under the age of 13. We do not knowingly collect personal information from children under 13. If you become aware that a child under 13 has provided us with personal information, please contact us immediately at modulix.support@gmail.com and we will take steps to delete such information.

─────────────────────────────────────
9. DEVICE PERMISSIONS

The App may request the following permissions:
- Internet Access: Required for cloud sync, ambient soundscape playback, and version update checks. No private study data is transmitted without your explicit opt-in.
- Storage / Files: Required only for user-initiated JSON backup export and import operations. The App does not access files outside its designated application directory.
- Notifications: Required to deliver focus session completion and scheduled reminder alerts. Notification content is generated locally on your device.

─────────────────────────────────────
10. SECURITY

We implement industry-standard technical and organisational security measures including TLS 1.3 encrypted data transmission, server-side encryption at rest, and enforced authentication tokens. However, no method of electronic storage or transmission is 100% secure. We cannot guarantee absolute security against all possible attacks.

─────────────────────────────────────
11. CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time to reflect changes in our practices or applicable law. The updated version will be published within the App with a revised "Last Updated" date. We encourage you to review this Policy periodically. Continued use of the App after any changes constitutes your acceptance of the revised Policy.

─────────────────────────────────────
12. CONTACT

For privacy inquiries, data requests, or concerns, contact:
Email: modulix.support@gmail.com
Website: https://modulix.pages.dev

Modulix — All rights reserved.''';

  static const String _termsContent =
      '''MODULIX — TERMS OF USE

Effective Date: 15 November 2026
Last Updated: 15 November 2026

PLEASE READ THESE TERMS OF USE ("TERMS") CAREFULLY BEFORE USING THE MODULIX APPLICATION. BY DOWNLOADING, INSTALLING, OR USING THE APP, YOU AGREE TO BE LEGALLY BOUND BY THESE TERMS. IF YOU DO NOT AGREE, YOU MUST IMMEDIATELY CEASE USE AND UNINSTALL THE APP.

─────────────────────────────────────
1. INDEPENDENT PERSONAL PROJECT & SOLO DEVELOPER NATURE

Modulix is an independent personal project conceptualized, created, and maintained by an individual solo developer ("Developer", "RxREAPER") as a non-commercial educational study utility. Modulix is NOT an enterprise corporation, venture-backed company, or institutional platform. By using the App, you explicitly acknowledge this solo developer nature and agree that no individual or personal asset liability shall attach to the developer beyond the express terms set forth herein.

─────────────────────────────────────
2. ACCEPTANCE OF TERMS & ELIGIBILITY

These Terms constitute a legally binding agreement between you ("User") and the Developer of Modulix ("Modulix", "we", "us", "our"). By accessing or using the App, you agree to these Terms in full. You must be at least 13 years of age to use Modulix. By using the App, you represent and warrant that you meet this requirement.

─────────────────────────────────────
3. DESCRIPTION OF SERVICE & CRITICAL DISCLAIMERS

3.1 Productivity & Pacing Companion
Modulix is an independent, offline-first study companion designed to help medical aspirants organize syllabus progress, maintain focus sessions (Pomodoro timer), calculate study streaks, and optionally sync data across personal devices.

3.2 Medical Advice & Life-Safety Disclaimer
MODULIX IS NOT A MEDICAL DEVICE, CLINICAL DIAGNOSTIC AID, OR HEALTHCARE DECISION SUPPORT SYSTEM. The App does NOT provide medical advice, diagnosis, treatment recommendations, drug dosage calculations, or clinical instructions. Never use Modulix in clinical settings, emergency scenarios, or for patient care decisions. Always consult a qualified physician and licensed healthcare institution for medical training and practice.

3.3 Academic & Examination Outcome Disclaimer
Pacing benchmarks, daily completion targets, streak numbers, and completion ETAs are computational approximations provided solely for user self-motivation. The Developer makes NO warranty, representation, or guarantee that using Modulix will result in passing, qualifying, or achieving any specific score, rank, percentile, or admission in NEET-PG, INI-CET, FMGE, USMLE, PLAB, or any academic examination.

─────────────────────────────────────
4. INTELLECTUAL PROPERTY & FAIR USE

4.1 Application Ownership
The Modulix application, including all original source code, algorithms (streak calculation, pacing velocity, medical progression tier hierarchy), UI layouts, graphics, icons, database schemas, and branding, constitutes the exclusive intellectual property of Modulix (RxREAPER) and is protected under the Indian Copyright Act 1957, Trade Marks Act 1999, and international copyright conventions.

4.2 Nominative Fair Use & Third-Party Trademark Non-Affiliation
Modulix references publicly known medical subject outlines and standard academic curriculum topic structures (including those colloquially utilized in competitive test preparation frameworks). These references are made strictly under the doctrine of nominative fair use / fair reference solely for individual progress tracking.

MODULIX DOES NOT HOST, REPRODUCE, STREAM, SCRAPE, STORE, TRANSMIT, OR MAKE AVAILABLE ANY PROPRIETARY VIDEO LECTURES, AUDIO RECORDINGS, QUESTION-BANK ITEMS, EXPLANATIONS, CLINICAL NOTES, SLIDES, OR PIRATED MATERIALS BELONGING TO MARROW, PREPLADDER, CEREBELLUM, DAMS, BHATIA, NBE, USMLE, FIRST AID, OR ANY OTHER THIRD-PARTY CONTENT CREATOR OR COMPANY.

Modulix is completely independent. It is not affiliated with, endorsed by, sponsored by, or associated with any examination board (NBE, NMC, USMLE, NBME) or commercial test-preparation provider. All third-party trademarks, brand names, and exam names belong to their respective holders.

4.3 User Licence
Subject to your compliance with these Terms, you are granted a limited, personal, non-exclusive, non-transferable, non-sublicensable, revocable licence to use the App on your personal device(s) solely for your own non-commercial study tracking.

─────────────────────────────────────
5. PROHIBITED CONDUCT

You expressly agree NOT to:

(a) Copy, reproduce, distribute, publish, or create derivative works based on the App or any part of it without prior written authorisation from Modulix
(b) Reverse engineer, decompile, disassemble, or attempt to derive the source code of the App or any component thereof
(c) Remove, alter, obscure, or circumvent any proprietary notices, copyright notices, trademarks, or security measures within the App
(d) Use the App for any commercial purpose, including reselling access, bundling with paid services, or sub-licensing the App to third parties
(e) Modify or create derivative tools that misrepresent themselves as Modulix or affiliated with Modulix
(f) Use the App in any manner that violates applicable law, regulation, or the rights of any third party
(g) Interfere with or disrupt the App's servers, infrastructure, or cloud synchronisation services
(h) Attempt to gain unauthorised access to the accounts of other users or to Modulix's backend systems
(i) Upload, transmit, or store any malicious code, viruses, or harmful data through the App's backup or sync features
(j) Use the App to develop, train, or improve any competing product or service

Violation of these prohibitions may result in immediate termination of your access and may expose you to civil and criminal liability.

─────────────────────────────────────
6. USER-GENERATED CONTENT AND DATA

All study data, timers, and progress records you create within the App are your own. You retain full ownership of this data. By enabling cloud synchronisation, you grant Modulix a limited, worldwide, royalty-free licence to store, process, and transmit this data solely for the purpose of providing the synchronisation service to you. This licence terminates upon your account deletion.

─────────────────────────────────────
7. DISCLAIMER OF WARRANTIES

TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, ACCURACY, RELIABILITY, OR COMPLETENESS.

WE DO NOT WARRANT THAT:
- THE APP WILL FUNCTION WITHOUT INTERRUPTION, ERROR, OR DEFECT
- THE APP WILL MEET YOUR REQUIREMENTS OR EXPECTATIONS
- DATA STORED IN THE APP WILL BE FREE FROM LOSS OR CORRUPTION
- THE APP WILL BE FREE FROM SECURITY VULNERABILITIES

─────────────────────────────────────
8. LIMITATION OF LIABILITY & SOLO DEVELOPER SHIELD

TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, THE SOLO DEVELOPER, MODULIX, AND ANY CONTRIBUTORS SHALL NOT BE LIABLE FOR:

(a) ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, PUNITIVE, OR CONSEQUENTIAL DAMAGES
(b) LOSS OF DATA, DEVICE MALFUNCTION, BATTERY DRAIN, HARDWARE CORRUPTION, OR SERVICE INTERRUPTIONS
(c) DAMAGES ARISING FROM ACADEMIC RESULTS, EXAMINATION OUTCOMES, OR CLINICAL PRACTICE CONSEQUENCES OF ANY KIND
(d) DAMAGES ARISING FROM THIRD-PARTY SERVICE DROP-OUTS (INCLUDING CLOUDFLARE, SUPABASE, OR OS UPDATES)
(e) DAMAGES RESULTING FROM UNAUTHORISED ACCESS OR SECURITY BREACHES BEYOND REASONABLE CONTROL

ALL LIABILITY IS STRICTLY ATTACHED TO THE APPLICATION AS A NON-COMMERCIAL EDUCATIONAL UTILITY. UNDER NO CIRCUMSTANCES SHALL RECOURSE BE SOUGHT AGAINST THE PERSONAL ASSETS, ACCOUNTS, OR ESTATE OF THE INDIVIDUAL SOLO DEVELOPER. IN ALL CIRCUMSTANCES, MAXIMUM AGGREGATE LIABILITY SHALL NOT EXCEED THE TOTAL AMOUNT ACTUALLY PAID BY YOU (IF ANY) IN THE PRECEDING 12 MONTHS (WHICH IS ZERO FOR FREE APPLICATION USERS).

─────────────────────────────────────
9. INDEMNIFICATION

You agree to indemnify, defend, and hold harmless Modulix and its contributors from and against any and all claims, damages, obligations, losses, liabilities, costs, and expenses (including reasonable legal fees) arising from: (a) your use of the App in violation of these Terms; (b) your violation of any third-party rights; or (c) any claim that your use of the App caused damage to a third party.

─────────────────────────────────────
10. MODIFICATIONS TO THE APP AND TERMS

We reserve the right to modify, suspend, or discontinue the App or any feature at any time without prior notice. We may also update these Terms at any time. The revised Terms will be published within the App with a new effective date. Your continued use of the App after such changes constitutes your acceptance of the updated Terms.

─────────────────────────────────────
11. TERMINATION

We may terminate or suspend your access to the App at any time, with or without cause, and with or without notice, if we determine that you have violated these Terms or if required by law. Upon termination, your licence to use the App immediately ceases. Provisions of these Terms that by their nature should survive termination shall survive, including Sections 4, 5, 7, 8, 9, 12, 13, and 14.

─────────────────────────────────────
12. GOVERNING LAW AND JURISDICTION

These Terms shall be governed by and construed in accordance with the laws of the Republic of India, without regard to its conflict of law principles. Any dispute, controversy, or claim arising out of or relating to these Terms or the App that cannot be resolved through good faith negotiation within 30 days shall be referred to and finally resolved by arbitration in accordance with the Arbitration and Conciliation Act, 1996. The seat of arbitration shall be New Delhi, India. The language of arbitration shall be English.

─────────────────────────────────────
13. SEVERABILITY

If any provision of these Terms is found to be invalid, illegal, or unenforceable by a court of competent jurisdiction, that provision shall be modified to the minimum extent necessary to make it enforceable, or severed if modification is not possible, and the remaining provisions shall continue in full force and effect.

─────────────────────────────────────
14. ENTIRE AGREEMENT

These Terms, together with our Privacy Policy and Copyright & IP Notice, constitute the entire agreement between you and Modulix with respect to the App and supersede all prior agreements, understandings, and communications, whether oral or written.

─────────────────────────────────────
15. CONTACT

For Terms of Use inquiries:
Email: modulix.support@gmail.com
Website: https://modulix.pages.dev

Modulix — All rights reserved.''';

  static const String _copyrightContent =
      '''MODULIX — COPYRIGHT & INTELLECTUAL PROPERTY NOTICE

Effective Date: 15 November 2026
Last Updated: 15 November 2026

─────────────────────────────────────
1. COPYRIGHT OWNERSHIP

Copyright © 2024–2026 Modulix (RxREAPER). All rights reserved.

The Modulix application, in its entirety and in each of its constituent parts, is an original work of authorship and is protected under:
- The Indian Copyright Act, 1957 (as amended)
- The Information Technology Act, 2000
- The Trade Marks Act, 1999
- The Berne Convention for the Protection of Literary and Artistic Works
- The Agreement on Trade-Related Aspects of Intellectual Property Rights (TRIPS)
- All applicable domestic and international intellectual property laws and treaties

─────────────────────────────────────
2. SCOPE OF PROTECTED WORKS

The following original works are protected under copyright and owned exclusively by Modulix:

(a) SOURCE CODE — All Dart/Flutter source code, including application logic, state management, UI rendering, database schemas, synchronisation protocols, and service layer implementations

(b) USER INTERFACE DESIGN — All original screen layouts, component designs, navigation architectures, visual hierarchies, animation sequences, interaction patterns, icon artwork, and colour systems designed for and unique to Modulix

(c) ALGORITHMS & SYSTEMS — The focus session engine, Pomodoro-variant timer logic, medical career progression tier algorithm, leaderboard ranking and rollover system, streak computation engine, offline-first synchronisation protocol with dead-letter queue, and all other proprietary computational methods

(d) WRITTEN CONTENT — All in-app copy, instructional text, tooltip content, error messages, onboarding flow language, and documentation authored for Modulix

(e) BRANDING — The "Modulix" name, application icon, visual identity, and all associated branding assets

(f) DATABASE SCHEMA — The structure, relationships, and design of all SQLite and cloud database schemas, including migration architecture

─────────────────────────────────────
3. WHAT IS NOT CLAIMED

Modulix does not claim copyright over:

(a) Medical knowledge, clinical guidelines, or academic content that is in the public domain
(b) The subject-matter taxonomies of publicly known medical competitive examination syllabi, which are referenced solely as organisational scaffolding for personal progress tracking
(c) Third-party open-source libraries used within the App, which remain subject to their respective licences (Flutter BSD, Riverpod MIT, Supabase Apache 2.0, and others as listed in the application's open-source notices)

─────────────────────────────────────
4. FAIR USE STATEMENT — SYLLABUS REFERENCES

Modulix uses structured chapter and topic indices that reference the general academic taxonomy of widely used medical reference frameworks and examination syllabi. This reference is made strictly under the principle of fair use for the purpose of enabling users to track their personal academic progress. Modulix does not reproduce, distribute, transmit, display, or create derivative works from any copyrighted third-party content. No proprietary question-bank items, lecture videos, clinical notes, or study material belonging to any third party are hosted on, transmitted through, or made accessible via Modulix.

─────────────────────────────────────
5. PROHIBITED ACTS

The following acts are strictly prohibited without prior written authorisation from Modulix:

(a) Reproducing, copying, or distributing any portion of the App, its source code, designs, or written content in any medium or format

(b) Decompiling, disassembling, reverse engineering, or otherwise attempting to derive the source code, algorithms, or database schemas of the App

(c) Creating derivative works, modified versions, forks, or adaptations of the App or any part thereof

(d) Using the Modulix name, logo, branding, or any confusingly similar mark in any product, service, website, or marketing material without explicit written permission

(e) Distributing, selling, sublicensing, or commercially exploiting the App or any component thereof

(f) Claiming authorship or ownership over the App or any of its original works

(g) Using the App's proprietary designs, workflows, or systems as the basis for a competing product

(h) Scraping, extracting, or systematically collecting data from the App's interface or infrastructure

─────────────────────────────────────
6. PERMITTED USE

You are granted a limited licence to:
- Use the App on your personal device(s) for personal, non-commercial study tracking purposes
- Create personal JSON backups of your own study data using the App's built-in export feature

All uses not expressly authorised are prohibited.

─────────────────────────────────────
7. OPEN-SOURCE COMPONENTS

Modulix is built using open-source libraries that remain subject to their respective licences. Attribution and licence information for all open-source components used in this App are available through the standard Flutter "Licenses" disclosure (accessible via About → Open Source Licences). The use of open-source components within Modulix does not alter or diminish our proprietary rights in the original work.

─────────────────────────────────────
8. DMCA AND INFRINGEMENT REPORTING

If you believe that any content within Modulix infringes upon your intellectual property rights, please submit a detailed written notice to:

Email: modulix.support@gmail.com

Your notice must include:
(i) Identification of the copyrighted work claimed to be infringed
(ii) Identification of the allegedly infringing material within the App
(iii) Your contact information
(iv) A statement of good faith belief that the disputed use is not authorised
(v) A statement under penalty of perjury that the information in your notice is accurate and that you are the rights holder or authorised to act on their behalf

We will respond to valid notices promptly in accordance with applicable law.

─────────────────────────────────────
9. ENFORCEMENT

Modulix reserves the right to enforce its intellectual property rights to the fullest extent of the law, including through civil litigation and, where applicable, criminal proceedings. Unauthorised reproduction or use of Modulix's protected works may result in substantial civil and criminal penalties.

─────────────────────────────────────
10. CONTACT

For licensing enquiries, authorisation requests, or IP matters:
Email: modulix.support@gmail.com
Website: https://modulix.pages.dev

Copyright © 2024–2026 Modulix (RxREAPER). All rights reserved.
No portion of this application may be reproduced or distributed without explicit written permission.''';
}

