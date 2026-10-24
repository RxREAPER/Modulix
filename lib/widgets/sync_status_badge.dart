import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/app_state_provider.dart';
import '../screens/auth/auth_screen.dart';
import '../services/sync_service.dart';

/// Interactive sync status chip indicating cloud connection and allowing manual sync / login
class SyncStatusBadge extends ConsumerWidget {
  final bool compact;
  const SyncStatusBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(appThemeDataProvider);
    final ext = themeData.extension;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    if (!isAuthenticated) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          AuthScreen.show(context);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 11,
            vertical: compact ? 4.5 : 5.5,
          ),
          decoration: BoxDecoration(
            color: ext.accentSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ext.accent.withValues(alpha: 0.35),
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_outlined,
                size: compact ? 12 : 14,
                color: ext.accent,
              ),
              const SizedBox(width: 5),
              Text(
                compact ? 'Sync' : 'Sign in to Sync',
                style: TextStyle(
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w700,
                  color: ext.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color badgeColor;
    IconData badgeIcon;
    String badgeLabel;

    switch (syncStatus) {
      case SyncStatus.syncing:
        badgeColor = ext.accent;
        badgeIcon = Icons.sync_rounded;
        badgeLabel = 'Syncing';
        break;
      case SyncStatus.synced:
        badgeColor = ext.isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
        badgeIcon = Icons.cloud_done_rounded;
        badgeLabel = 'Synced';
        break;
      case SyncStatus.offline:
      case SyncStatus.error:
        badgeColor = const Color(0xFFC62828);
        badgeIcon = Icons.cloud_off_rounded;
        badgeLabel = 'Offline';
        break;
      case SyncStatus.idle:
        badgeColor = ext.accent;
        badgeIcon = Icons.cloud_outlined;
        badgeLabel = 'Cloud';
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (syncStatus != SyncStatus.syncing) {
          SyncService.instance.syncFull(ref);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncStatus == SyncStatus.syncing)
              SizedBox(
                width: compact ? 10 : 12,
                height: compact ? 10 : 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: badgeColor,
                ),
              )
            else
              Icon(
                badgeIcon,
                size: compact ? 12 : 14,
                color: badgeColor,
              ),
            const SizedBox(width: 5),
            Text(
              badgeLabel,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
