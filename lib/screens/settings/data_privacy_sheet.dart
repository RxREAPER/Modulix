import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/time_log_provider.dart';
import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../theme/app_theme.dart';

class DataPrivacySheet extends ConsumerWidget {
  const DataPrivacySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 200),
        reverseDuration: Duration(milliseconds: 150),
      ),
      builder: (_) => const DataPrivacySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          left: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          right: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal, width: 1.5),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BACKUP & SOVEREIGNTY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        'Data & Privacy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.borderLight),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // 1. Privacy Policy & Terms Legal Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.current.isDark
                        ? Colors.teal.withValues(alpha: 0.15)
                        : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.current.isDark
                            ? Colors.teal.withValues(alpha: 0.4)
                            : Colors.teal.shade200,
                        width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_rounded,
                              size: 18, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            'LEGAL & DATA SOVEREIGNTY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.teal,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your study data belongs exclusively to you. Modulix operates completely offline without tracking, third-party analytics, or cloud data collection.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkForeground,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.teal),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showLegalDialog(
                                context,
                                title: 'Privacy Policy',
                                content: _privacyPolicyText,
                              ),
                              child: const Text('Privacy Policy',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.teal)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.teal),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showLegalDialog(
                                context,
                                title: 'Terms & Conditions',
                                content: _termsConditionsText,
                              ),
                              child: const Text('Terms of Use',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.teal)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Backup & Restore
                Text(
                  'EXPORT & IMPORT BACKUPS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Export your completed videos, daily tasks, study plan and timer history to a portable JSON backup file.',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.upload_file_rounded,
                                color: AppTheme.primaryBlue, size: 20),
                          ),
                          title: Text('Export Backup File',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                              'Save .json to drive or share to another phone',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.mutedText)),
                          trailing: Icon(Icons.chevron_right_rounded,
                              color: AppTheme.mutedText),
                          onTap: () => _exportBackup(context, ref),
                        ),
                        Divider(height: 1, color: AppTheme.borderLight),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.download_rounded,
                                color: Colors.green, size: 20),
                          ),
                          title: Text('Import Backup File',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                              'Restore from a previously exported .json file',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.mutedText)),
                          trailing: Icon(Icons.chevron_right_rounded,
                              color: AppTheme.mutedText),
                          onTap: () => _importBackup(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Cloud Snapshot Vault
                Text(
                  'CLOUD SNAPSHOT VAULT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GZip-compressed snapshot archives stored securely in your private cloud vault.',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cloud_upload_rounded,
                                color: Colors.indigo, size: 20),
                          ),
                          title: Text('Backup to Cloud Vault',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                              'Compresses and uploads snapshot to private storage',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.mutedText)),
                          trailing: Icon(Icons.chevron_right_rounded,
                              color: AppTheme.mutedText),
                          onTap: () => _backupToCloud(context, ref),
                        ),
                        Divider(height: 1, color: AppTheme.borderLight),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cloud_download_rounded,
                                color: Colors.deepPurple, size: 20),
                          ),
                          title: Text('Restore from Cloud Vault',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                              'View and restore from previous cloud snapshots',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.mutedText)),
                          trailing: Icon(Icons.chevron_right_rounded,
                              color: AppTheme.mutedText),
                          onTap: () => _showCloudSnapshotsDialog(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Granular Cleaning
                Text(
                  'PARTIAL DATA MANAGEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selectively clear isolated history without wiping your whole curriculum progression.',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.timer_off_outlined,
                                color: Colors.orange, size: 20),
                          ),
                          title: Text('Clear Focus Timer History',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                              'Deletes all recorded study timer session logs',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.mutedText)),
                          onTap: () => _confirmClearLogs(context, ref),
                        ),
                        Divider(height: 1, color: AppTheme.borderLight),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.playlist_remove_rounded,
                                color: Colors.teal, size: 20),
                          ),
                          title: Text('Clear Desk Pad Tasks',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                              'Wipes today\'s task list and daily task history',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.mutedText)),
                          onTap: () => _confirmClearTasks(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),

                if (AuthService.instance.isAuthenticated) ...[
                  const SizedBox(height: 24),

                  // 5. Cloud Account & Remote Data Erasure
                  Text(
                    'CLOUD DATA SOVEREIGNTY & ERASURE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Permanently delete your remote account and erase all study completions, time logs, and cloud vault archives from our servers.',
                    style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: AppTheme.cardWhite,
                      borderRadius: 18,
                      shadowOffset: 3,
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_forever_rounded,
                              color: Colors.red, size: 20),
                        ),
                        title: const Text('Delete Cloud Account & Data',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.red)),
                        subtitle: Text(
                            'Permanent remote purge (GDPR Art. 17 & App Store 5.1.1)',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.mutedText)),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Colors.red),
                        onTap: () => _confirmPurgeAccount(context, ref),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    await BackupService.exportAndShare(context, ref);
  }

  static Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    await BackupService.pickAndRestore(context, ref);
  }

  static Future<void> _backupToCloud(BuildContext context, WidgetRef ref) async {
    if (!AuthService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with a Cloud Account to backup to Cloud Vault.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compressing and uploading snapshot to Cloud Vault...'),
        duration: Duration(seconds: 2),
      ),
    );

    final success = await BackupService.uploadSnapshotToCloud(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Compressed snapshot saved to Cloud Vault!'
                : 'Failed to upload snapshot. Check internet connection.',
          ),
          backgroundColor:
              success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
    }
  }

  static void _showCloudSnapshotsDialog(BuildContext context, WidgetRef ref) {
    if (!AuthService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with a Cloud Account to view and restore cloud snapshots.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_done_rounded,
                      color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cloud Vault Snapshots',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 320,
              child: FutureBuilder<List<CloudSnapshot>>(
                future: BackupService.listCloudSnapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 40, color: AppTheme.mutedText),
                          const SizedBox(height: 12),
                          Text(
                            'No cloud snapshots found',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a snapshot using "Backup to Cloud Vault"',
                            style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final dateStr = item.createdAt != null
                          ? DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt!.toLocal())
                          : item.name;

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.archive_outlined,
                            color: Colors.indigo, size: 22),
                        title: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        subtitle: Text(
                          item.formattedSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download_rounded,
                                  color: Colors.teal, size: 20),
                              tooltip: 'Restore this snapshot',
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Restore Cloud Snapshot?'),
                                    content: Text(
                                      'Restore snapshot from $dateStr (${item.formattedSize})? This will merge study progress and update logs.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                        ),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Restore'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final ok = await BackupService.restoreCloudSnapshot(
                                      item.path, ref);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Cloud snapshot successfully restored!'
                                              : 'Failed to restore cloud snapshot.',
                                        ),
                                        backgroundColor: ok
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  color: Colors.red.shade300, size: 20),
                              tooltip: 'Delete snapshot',
                              onPressed: () async {
                                final confirmDel = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Snapshot?'),
                                    content: const Text(
                                      'Permanently remove this backup archive from your cloud vault?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmDel == true) {
                                  await BackupService.deleteCloudSnapshot(item.path);
                                  setDialogState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _confirmClearLogs(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.sketchBorderColor, width: 1.8),
        ),
        title: const Text('Clear Focus Timer Logs?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: Text(
          'This will permanently delete all timer session logs from Analytics. Your video progress remains untouched.',
          style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(timeLogsProvider.notifier).clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Focus timer history cleared')),
                );
              }
            },
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );
  }

  static void _confirmClearTasks(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.sketchBorderColor, width: 1.8),
        ),
        title: const Text('Clear Desk Tasks?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: Text(
          'This will wipe your current desk pad checklist and reset your daily task checklist for today.',
          style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(dailyTasksProvider.notifier).setTasks([]);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Desk pad tasks cleared')),
              );
            },
            child: const Text('Clear Tasks'),
          ),
        ],
      ),
    );
  }

  static void _confirmPurgeAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Cloud Account?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: Text(
          'This will permanently delete all your remote cloud data, focus timer logs, and snapshot archives from Supabase. Your local progress on this phone will be preserved in Guest mode.',
          style: TextStyle(fontSize: 13, color: AppTheme.mutedText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mutedText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purging cloud data and deleting account...'),
                  duration: Duration(seconds: 2),
                ),
              );

              final success = await AuthService.instance.purgeRemoteDataAndAccount();
              if (context.mounted) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Cloud account and remote data successfully deleted.'
                          : 'Failed to purge cloud data. Please check your network connection.',
                    ),
                    backgroundColor:
                        success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text('Delete Cloud Data'),
          ),
        ],
      ),
    );
  }

  static void _showLegalDialog(BuildContext context,
      {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.inkForeground,
                height: 1.45,
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkForeground,
              foregroundColor: AppTheme.paperBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static const String _privacyPolicyText =
      'MODULIX PRIVACY POLICY\\nLast Updated: September 2026\\n\\n1. Zero Telemetry & Local Storage\\nModulix is built with privacy-by-design for medical professionals. We do NOT track, collect, transmit, or monetize your study progress, exam schedules, or usage patterns. All data created within the app is stored strictly on your local device.\\n\\n2. No Third-Party Tracking\\nThe application does not include any third-party tracking SDKs, ad networks, behavioral trackers, or external analytics endpoints.\\n\\n3. Backups & Data Portability\\nWhen you choose to export your study progress, Modulix compiles a local JSON archive. You retain 100% control over where this file is transferred or stored.\\n\\n4. Device Permissions\\n- Storage/Files: Used exclusively for user-directed JSON backup import and export.\\n- Network/Internet: Used solely for playing ambient study streams if selected. No personal study information is transmitted.';

  static const String _termsConditionsText =
      'MODULIX TERMS AND CONDITIONS OF USE\\nLast Updated: September 2026\\n\\n1. Educational & Planning Utility\\nModulix is an independent study companion and planning tracker designed for medical aspirants. It does not replace formal medical education or institutional curricula.\\n\\n2. Intellectual Property & Brand Separation\\nModulix is an independent application. Syllabus references (including Marrow Edition 8 & 6.5) are provided strictly as academic taxonomy indices for personal progress tracking under fair reference principles. Modulix does not distribute copyrighted video lectures, clinical notes, or Q-Bank test items.\\n\\n3. Disclaimer of Warranties\\nThe software is provided "as is", without warranty of any kind, express or implied. Modulix and its creator shall not be held liable for any exam performance outcomes, scheduling discrepancies, or data loss arising from hardware failures. Users are encouraged to maintain periodic backups using the Export feature.\\n\\n4. Acceptance\\nBy using Modulix, you acknowledge that your data remains on your physical hardware under your ownership and agree to these terms.';
}
