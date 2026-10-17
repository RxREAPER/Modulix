import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';

class AboutSupportSheet extends ConsumerWidget {
  const AboutSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const AboutSupportSheet(),
    );
  }

  static const String feedbackEmail = 'ezioauditore9553@gmail.com';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
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
                    color: Colors.blueGrey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blueGrey, width: 1.5),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: Colors.blueGrey, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APP INFORMATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        'About & Support',
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                // App Logo Hero Badge
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.inkForeground,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x221C1C1C),
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Modulix',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Text(
                        'Version 1.0.0 (Build 36) · NEET-PG Study Companion',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Support & Feedback Card
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
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.mail_outline_rounded,
                                color: Colors.redAccent, size: 20),
                          ),
                          title: Text('Contact Support & Feedback',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                            feedbackEmail,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue),
                          ),
                          trailing: Icon(Icons.copy_rounded,
                              size: 18, color: AppTheme.mutedText),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Support contact: $feedbackEmail'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: AppTheme.borderLight),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.share_rounded,
                                color: AppTheme.primaryBlue, size: 20),
                          ),
                          title: Text('Share Modulix with Colleagues',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                            'Help peer medicos build focused study habits',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.mutedText),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded,
                              color: AppTheme.mutedText),
                          onTap: () {
                            Share.share(
                              'Level up your NEET-PG clinical prep with Modulix — offline module pacing and deep-work study timers!',
                              subject: 'Modulix NEET-PG Companion',
                            );
                          },
                        ),
                        Divider(height: 1, color: AppTheme.borderLight),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.code_rounded,
                                color: Colors.deepPurple, size: 20),
                          ),
                          title: Text('Open Source Licenses',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground)),
                          subtitle: Text(
                            'Third-party software libraries & credits',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.mutedText),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded,
                              color: AppTheme.mutedText),
                          onTap: () {
                            showLicensePage(
                              context: context,
                              applicationName: 'Modulix',
                              applicationVersion: '1.0.0 (Build 36)',
                              applicationLegalese:
                                  'Copyright © 2026 Modulix. All rights reserved.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Medical Disclaimer Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.current.isDark
                        ? const Color(0xFF2A2415)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.current.isDark
                            ? const Color(0xFF5A4515)
                            : const Color(0xFFFDE68A),
                        width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.health_and_safety_outlined,
                          size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Educational study planner & exam tracking companion. Does not provide clinical medical advice, patient diagnosis, or treatment.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.current.isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF78350F),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Offline Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.offline_pin_outlined,
                          size: 18, color: AppTheme.mutedText),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Crafted with medical rigor. No cloud dependencies, no paywalls, entirely local.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Relocated Danger Zone Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200, width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Danger Zone: Reset Progress',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Wipes all completed video marks, daily task history, and study time logs across all syllabus editions.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: AppTheme.cardWhite,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.delete_forever_rounded,
                            color: Colors.redAccent, size: 16),
                        label: const Text(
                          'Reset Progress...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.redAccent,
                          ),
                        ),
                        onPressed: () => _confirmReset(context, ref),
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

  static void _confirmReset(BuildContext context, WidgetRef ref) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isConfirmed = textCtrl.text.trim().toUpperCase() == 'RESET';

          return AlertDialog(
            backgroundColor: AppTheme.cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.redAccent, size: 24),
                SizedBox(width: 8),
                Text('Danger: Reset Progress',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action CANNOT be undone. Type RESET below to permanently clear your completion records.',
                  style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Type RESET',
                    filled: true,
                    fillColor: AppTheme.current.isDark
                        ? const Color(0xFF2D1515)
                        : Colors.red.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text('Cancel', style: TextStyle(color: AppTheme.mutedText)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isConfirmed ? Colors.redAccent : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isConfirmed
                    ? () async {
                        await ref
                            .read(appStateProvider.notifier)
                            .resetAllProgress();
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('All progress records have been reset'),
                            ),
                          );
                        }
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
}
