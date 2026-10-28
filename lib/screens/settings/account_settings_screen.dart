import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/feedback/modulix_toast.dart';
import '../../widgets/profile/profile_customization.dart';

/// Minimalist, modern Account Settings sub-page.
/// Shows account email, sync status, tactile Sync Now, and clean Sign Out.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _isManualSyncing = false;

  Future<void> _handleSyncNow() async {
    if (_isManualSyncing) return;
    setState(() => _isManualSyncing = true);
    HapticFeedback.lightImpact();

    try {
      await SyncService.instance.syncFull(ref, forceFull: true);
      if (mounted) {
        ModulixToast.showSuccess(
          context,
          message: 'Cloud sync completed',
        );
      }
    } catch (_) {
      if (mounted) {
        ModulixToast.showError(
          context,
          message: 'Failed to sync with cloud',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManualSyncing = false);
      }
    }
  }

  void _confirmSignOut(BuildContext context) {
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
          'Sign Out',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: activeTheme.inkForeground,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out? Your study progress on this device will remain safely stored locally.',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
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
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.signOut();
              if (context.mounted) {
                ModulixToast.showSuccess(
                  context,
                  message: 'Signed out successfully',
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/settings');
                }
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime? timestamp) {
    if (timestamp == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final user = ref.watch(currentUserProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final lastSyncedAt = ref.watch(lastSyncedAtProvider);
    final appState = ref.watch(appStateProvider).valueOrNull;

    final isSyncing = _isManualSyncing || syncStatus == SyncStatus.syncing;

    return Scaffold(
      backgroundColor: activeTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: activeTheme.scaffoldBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: activeTheme.inkForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          'Account',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: activeTheme.inkForeground,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [
          if (isAuthenticated && user != null) ...[
            // Authenticated Account Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: activeTheme.cardBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: activeTheme.borderSubtle,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ProfileAvatar(
                          size: 52,
                          colorId: appState?.avatarColorId ?? 'indigo',
                          iconId: appState?.avatarIconId ?? 'letter',
                          doctorName: appState?.doctorName ?? 'Doctor',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email ?? 'Connected Account',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: activeTheme.inkForeground,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              appState?.publicDisplayName ?? 'Doctor',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: activeTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: activeTheme.borderSubtle,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last Synced',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: activeTheme.mutedText,
                        ),
                      ),
                      Text(
                        _formatRelativeTime(lastSyncedAt),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: activeTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Primary Sync Now Action Button
            ApplePressable(
              onTap: isSyncing ? null : _handleSyncNow,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSyncing) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Syncing Cloud Parity...',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Sync Now',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clean Sign Out Button
            ApplePressable(
              onTap: () => _confirmSignOut(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Guest Mode Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: activeTheme.cardBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: activeTheme.borderSubtle,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          color: AppTheme.accentPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Storage Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: activeTheme.inkForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Guest Account',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: activeTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your study data and timers are saved safely on this device. Sign in to sync across devices and enter the community leaderboard.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: activeTheme.mutedText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ApplePressable(
                    onTap: () => context.push('/settings/auth'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Sign In / Register',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
