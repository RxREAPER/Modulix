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
                  subtitle: 'Zero-telemetry and offline storage policies',
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
                  subtitle: 'Fair academic reference and usage terms',
                  onTap: () => _showLegalSheet(
                    context,
                    title: 'Terms of Use',
                    content: _termsContent,
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

  static const String _privacyPolicyContent = '''MODULIX PRIVACY POLICY
Last Updated: October 2026

1. Zero Telemetry & Local Data Sovereignty
Modulix is built with privacy-first architecture for medical aspirants and clinicians. We do NOT track, collect, monetize, or transmit your study schedules, completion percentages, or timer history. All study records remain strictly on your local device.

2. No Third-Party Tracking
The application contains zero third-party advertising SDKs, tracking pixels, behavioral profilers, or hidden analytic endpoints.

3. Backups & Data Portability
When you export your study records, Modulix generates a standard JSON archive. You retain complete ownership over where this file is stored, transferred, or shared.

4. Device Permissions
- Storage / Files: Used solely for user-directed JSON backup export and import.
- Network / Internet: Used solely for playing ambient study soundscapes and optional cross-device account sync if you explicitly sign in. No private progress is shared with third parties.

5. Cloud Account Deletion
If you choose to create an optional cloud sync account, you can permanently delete your remote account and erase all synchronized records at any time directly under Account & Sync.''';

  static const String _termsContent = '''MODULIX TERMS AND CONDITIONS OF USE
Last Updated: October 2026

1. Educational & Planning Utility
Modulix is an independent study tracking companion and productivity system designed for medical aspirants preparing for competitive examinations. It does not replace formal medical education or institutional curricula.

2. Intellectual Property & Fair Reference
Modulix is an independent application. Syllabus references (including Edition 8 and Edition 6.5) are provided strictly as academic taxonomy indices for personal progress tracking under fair reference principles. Modulix does not host or distribute copyrighted video lectures, clinical notes, or proprietary question-bank test items.

3. Disclaimer of Warranties
The software is provided "as is", without warranty of any kind. Modulix and its contributors shall not be held liable for examination outcomes, scheduling discrepancies, or data loss caused by hardware failure. Users are encouraged to maintain regular JSON backups using the Export feature.

4. Acceptance
By using Modulix, you acknowledge that your data remains under your ownership and agree to these terms.''';
}
