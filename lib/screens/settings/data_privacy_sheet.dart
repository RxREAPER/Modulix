import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/time_log_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class DataPrivacySheet extends ConsumerWidget {
  const DataPrivacySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const DataPrivacySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final appState = appStateAsync.value;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal, width: 1.5),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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

          const Divider(height: 1, color: AppTheme.borderLight),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // 1. Privacy Policy & Terms Legal Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade200, width: 1.4),
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
                      const Text(
                        'Your study data belongs exclusively to you. FlowMD operates completely offline without tracking, third-party analytics, or cloud data collection.',
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
                const Text(
                  'EXPORT & IMPORT BACKUPS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Export your completed videos, daily tasks, study plan and timer history to a portable JSON backup file.',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.upload_file_rounded,
                              color: AppTheme.primaryBlue, size: 20),
                        ),
                        title: const Text('Export Backup File',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkForeground)),
                        subtitle: const Text('Save .json to drive or share to another phone',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.mutedText)),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.mutedText),
                        onTap: () => _exportBackup(context, ref),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.download_rounded,
                              color: Colors.green, size: 20),
                        ),
                        title: const Text('Import Backup File',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkForeground)),
                        subtitle: const Text('Restore from a previously exported .json file',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.mutedText)),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.mutedText),
                        onTap: () => _importBackup(context, ref),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Granular Cleaning
                const Text(
                  'PARTIAL DATA MANAGEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selectively clear isolated history without wiping your whole curriculum progression.',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.timer_off_outlined,
                              color: Colors.orange, size: 20),
                        ),
                        title: const Text('Clear Focus Timer History',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkForeground)),
                        subtitle: const Text('Deletes all recorded study timer session logs',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.mutedText)),
                        onTap: () => _confirmClearLogs(context, ref),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.playlist_remove_rounded,
                              color: Colors.teal, size: 20),
                        ),
                        title: const Text('Clear Desk Pad Tasks',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkForeground)),
                        subtitle: const Text('Wipes today\'s task list and daily task history',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.mutedText)),
                        onTap: () => _confirmClearTasks(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final json = ref.read(appStateProvider.notifier).exportState();
      final dir = await getTemporaryDirectory();
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${dir.path}/flowmd_backup_$date.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'FlowMD Backup $date',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  static Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final imported = StorageService.instance.import(content);
      if (imported == null) throw Exception('Invalid backup format');

      await ref.read(appStateProvider.notifier).importState(imported);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  static void _confirmClearLogs(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.sketchBorderColor, width: 1.8),
        ),
        title: const Text('Clear Focus Timer Logs?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: const Text(
          'This will permanently delete all timer session logs from Analytics. Your video progress remains untouched.',
          style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Focus timer history cleared')),
              );
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.sketchBorderColor, width: 1.8),
        ),
        title: const Text('Clear Desk Tasks?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: const Text(
          'This will wipe your current desk pad checklist and reset your daily task checklist for today.',
          style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedText)),
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

  static void _showLegalDialog(BuildContext context,
      {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.sketchBorderColor, width: 2),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(
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
              foregroundColor: Colors.white,
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

  static const String _privacyPolicyText = 'FLOWMD PRIVACY POLICY\\nLast Updated: September 2026\\n\\n1. Zero Telemetry & Local Storage\\nFlowMD is built with privacy-by-design for medical professionals. We do NOT track, collect, transmit, or monetize your study progress, exam schedules, or usage patterns. All data created within the app is stored strictly on your local device.\\n\\n2. No Third-Party Tracking\\nThe application does not include any third-party tracking SDKs, ad networks, behavioral trackers, or external analytics endpoints.\\n\\n3. Backups & Data Portability\\nWhen you choose to export your study progress, FlowMD compiles a local JSON archive. You retain 100% control over where this file is transferred or stored.\\n\\n4. Device Permissions\\n- Storage/Files: Used exclusively for user-directed JSON backup import and export.\\n- Network/Internet: Used solely for playing ambient study streams if selected. No personal study information is transmitted.';

  static const String _termsConditionsText = 'FLOWMD TERMS AND CONDITIONS OF USE\\nLast Updated: September 2026\\n\\n1. Educational & Planning Utility\\nFlowMD is an independent study companion and planning tracker designed for medical aspirants. It does not replace formal medical education or institutional curricula.\\n\\n2. Intellectual Property & Brand Separation\\nFlowMD is an independent application. Syllabus references (including Marrow Edition 8 & 6.5) are provided strictly as academic taxonomy indices for personal progress tracking under fair reference principles. FlowMD does not distribute copyrighted video lectures, clinical notes, or Q-Bank test items.\\n\\n3. Disclaimer of Warranties\\nThe software is provided "as is", without warranty of any kind, express or implied. FlowMD and its creator shall not be held liable for any exam performance outcomes, scheduling discrepancies, or data loss arising from hardware failures. Users are encouraged to maintain periodic backups using the Export feature.\\n\\n4. Acceptance\\nBy using FlowMD, you acknowledge that your data remains on your physical hardware under your ownership and agree to these terms.';
}
