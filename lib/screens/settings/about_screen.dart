import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_metadata.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/feedback/modulix_toast.dart';

/// Minimalist, modern About Modulix sub-page.
/// Provides version metadata, official website link, email support,
/// peer recommendation share action, and third-party license notices.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = AppMetadata.fullVersionString;
  static const String websiteUrl = AppMetadata.websiteUrl;
  static const String supportEmail = AppMetadata.supportEmail;

  Future<void> _openWebsite(BuildContext context) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(websiteUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ModulixToast.showInfo(context, message: 'Website: $websiteUrl');
        }
      }
    } catch (_) {
      if (context.mounted) {
        ModulixToast.showInfo(context, message: 'Website: $websiteUrl');
      }
    }
  }

  Future<void> _openEmailSupport(BuildContext context) async {
    HapticFeedback.lightImpact();
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Modulix%20v1.36.0%20Support%20Inquiry',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(const ClipboardData(text: supportEmail));
        if (context.mounted) {
          ModulixToast.showInfo(
            context,
            message: 'Support email copied: $supportEmail',
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: supportEmail));
      if (context.mounted) {
        ModulixToast.showInfo(
          context,
          message: 'Support email copied: $supportEmail',
        );
      }
    }
  }

  void _shareApp(BuildContext context) {
    HapticFeedback.lightImpact();
    Share.share(
      'Track your NEET-PG clinical prep with Modulix: $websiteUrl',
      subject: 'Modulix NEET-PG Study Companion',
    );
  }

  Future<void> _openChangelog(BuildContext context) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('$websiteUrl/#/updates');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
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
          'About Modulix',
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
          // ── Brand Hero Card ────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: activeTheme.inkForeground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: activeTheme.cardBackground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Modulix',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: activeTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appVersion,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: activeTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Precision Pacing & Study Habit Engine',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: activeTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Independent Personal Project · RxREAPER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: activeTheme.mutedText.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Online & Support ───────────────────────────────────────────────
          _sectionHeader(context, 'ONLINE & SUPPORT'),
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
                  icon: Icons.language_rounded,
                  iconColor: AppTheme.accentPrimary,
                  title: 'Official Website',
                  subtitle: 'modulix.pages.dev',
                  onTap: () => _openWebsite(context),
                ),
                _rowDivider(context),
                _actionRow(
                  context: context,
                  icon: Icons.mail_outline_rounded,
                  iconColor: const Color(0xFF0D9488),
                  title: 'Contact Support',
                  subtitle: supportEmail,
                  onTap: () => _openEmailSupport(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Updates & Release ──────────────────────────────────────────────
          _sectionHeader(context, 'UPDATES & RELEASE'),
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
                  icon: Icons.system_update_alt_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Check for Updates',
                  subtitle: 'Discover releases & website downloads',
                  onTap: () => UpdateService.checkForUpdatesManual(context),
                ),
                _rowDivider(context),
                _actionRow(
                  context: context,
                  icon: Icons.history_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Changelog',
                  subtitle: '${AppMetadata.checkpoint} release notes',
                  onTap: () => _openChangelog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Legal & Policies ───────────────────────────────────────────────
          _sectionHeader(context, 'LEGAL & POLICIES'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
            ),
            child: _actionRow(
              context: context,
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF0D9488),
              title: 'Data & Privacy, Terms & Copyright',
              subtitle: 'Fair use disclaimers & IP protection',
              onTap: () => context.push('/settings/privacy'),
            ),
          ),

          const SizedBox(height: 24),

          // ── Community & Share ──────────────────────────────────────────────
          _sectionHeader(context, 'COMMUNITY'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
            ),
            child: _actionRow(
              context: context,
              icon: Icons.share_outlined,
              iconColor: const Color(0xFF6366F1),
              title: 'Share Modulix',
              subtitle: 'Recommend the companion to fellow medical aspirants',
              onTap: () => _shareApp(context),
            ),
          ),
          const SizedBox(height: 32),
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
                      color: activeTheme.inkForeground,
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
}
