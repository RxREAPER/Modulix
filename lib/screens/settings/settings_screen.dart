import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/profile/profile_customization.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'data_privacy_sheet.dart';
import 'about_support_sheet.dart';
import 'learn_the_app_sheet.dart';
import 'sync_diagnostics_sheet.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/timer/battery_optimization_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  final String? from;
  const SettingsScreen({super.key, this.from});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final activeTheme = context.modulixTheme;

    return Scaffold(
      backgroundColor: activeTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: activeTheme.scaffoldBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: activeTheme.inkForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (from != null && from!.isNotEmpty) {
              context.go(from!);
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Settings & Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: activeTheme.inkForeground,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.paddingOf(context).bottom + 100.0),
        children: const [
          _DoctorProfileHero(),
          SizedBox(height: 20),
          _SettingsGroupHeader(title: 'STUDY & ATMOSPHERE'),
          _StudyAtmosphereGroup(),
          SizedBox(height: 20),
          _SettingsGroupHeader(title: 'CLOUD & COMMUNITY'),
          _CloudCommunityGroup(),
          SizedBox(height: 20),
          _SettingsGroupHeader(title: 'PREFERENCES'),
          _PreferencesGroup(),
          SizedBox(height: 20),
          _SettingsGroupHeader(title: 'RESOURCES & ABOUT'),
          _ResourcesGroup(),
        ],
      ),
    );
  }

  static void editDoctorName(
      BuildContext context, AppStateNotifier notifier, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderLight, width: 1.4),
        ),
        title: Text(
          'Edit Doctor Name',
          style: AppTypography.dialogTitle(fontSize: 18.0),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Dr. Arjun',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.buttonLabel(
                fontSize: 13.5,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkForeground,
              foregroundColor: AppTheme.paperBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                notifier.setDoctorName(text);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: AppTypography.buttonLabel(
                fontSize: 13.5,
                color: AppTheme.paperBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void editLeaderboardName(
      BuildContext context, AppStateNotifier notifier, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderLight, width: 1.4),
        ),
        title: Text(
          'Leaderboard Name',
          style: AppTypography.dialogTitle(fontSize: 18.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This name appears on the leaderboard and rankings.',
              style: AppTypography.dialogBody(fontSize: 12.0),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Dr. Safi',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.buttonLabel(
                  fontSize: 13.5, color: AppTheme.mutedText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkForeground,
              foregroundColor: AppTheme.paperBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                notifier.updateLeaderboardIdentity(displayName: text);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: AppTypography.buttonLabel(
                  fontSize: 13.5, color: AppTheme.paperBackground),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Micro Header ──────────────────────────────────────────────────────
class _SettingsGroupHeader extends StatelessWidget {
  final String title;
  const _SettingsGroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.mutedText,
        ),
      ),
    );
  }
}

// ── Inset Group Container (iOS / Linear Style) ────────────────────────────────
class _InsetGroupContainer extends StatelessWidget {
  final List<Widget> children;
  const _InsetGroupContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.8),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ── Reusable Settings Row Item ────────────────────────────────────────────────
class _SettingsItemRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItemRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: onTap != null ? 0.98 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.mutedText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _groupDivider() => Divider(
      height: 1,
      thickness: 0.8,
      indent: 58,
      endIndent: 16,
      color: AppTheme.borderLight.withValues(alpha: 0.6),
    );

// ── Doctor Profile Hero Card ──────────────────────────────────────────────────
class _DoctorProfileHero extends ConsumerWidget {
  const _DoctorProfileHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final appState = ref.watch(appStateProvider).valueOrNull;
    if (appState == null) return const SizedBox.shrink();

    final doctorName =
        appState.doctorName.isNotEmpty ? appState.doctorName : 'Doctor';
    final displayName =
        doctorName.startsWith('Dr') ? doctorName : 'Dr. $doctorName';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.4),
                    width: 2.0,
                  ),
                ),
                child: ProfileAvatar(
                  size: 64,
                  colorId: appState.avatarColorId,
                  iconId: appState.avatarIconId,
                  doctorName: doctorName,
                  onTap: () => ProfileCustomizeSheet.show(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NEET-PG Aspirant · MBBS Desk',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: AppTheme.borderLight.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ApplePressable(
                  onTap: () => ProfileCustomizeSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight, width: 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.palette_outlined,
                            size: 15, color: AppTheme.accentPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Persona Studio',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ApplePressable(
                  onTap: () => SettingsScreen.editDoctorName(
                    context,
                    ref.read(appStateProvider.notifier),
                    doctorName,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight, width: 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 15, color: AppTheme.accentPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Edit Name',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Group 1: Study & Atmosphere ───────────────────────────────────────────────
class _StudyAtmosphereGroup extends ConsumerWidget {
  const _StudyAtmosphereGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final appStateAsync = ref.watch(appStateProvider);
    final appState = appStateAsync.value ?? AppState.empty;

    final activeEdition = appState.activeEdition;
    final isEdition8 = activeEdition == 'marrow_8';

    final preset = PalettePreset.fromId(appState.palettePresetId);
    final themeAccent = preset.isDark ? preset.accentDark : preset.accent;
    final secondaryAccent = preset.secondaryAccent;

    return _InsetGroupContainer(
      children: [
        // 1. Syllabus Edition
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.school_outlined,
              color: AppTheme.accentPrimary,
              size: 20,
            ),
          ),
          title: 'Syllabus Edition',
          subtitle: isEdition8
              ? 'Marrow Edition 8 · 19 Subjects'
              : 'Marrow Edition 6.5 · 19 Subjects',
          onTap: () => context.push('/settings/syllabus-edition'),
        ),
        _groupDivider(),
        // 2. Theme Studio
        _SettingsItemRow(
          leading: SizedBox(
            width: 36,
            height: 28,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: preset.scaffoldBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: preset.borderSubtle, width: 1.2),
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: themeAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: secondaryAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: 'Theme Studio',
          subtitle: '${preset.label} · Active Atmosphere',
          onTap: () => context.push('/settings/theme-studio'),
        ),
      ],
    );
  }
}

// ── Group 2: Cloud & Community ────────────────────────────────────────────────
class _CloudCommunityGroup extends ConsumerWidget {
  const _CloudCommunityGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final appStateAsync = ref.watch(appStateProvider);
    final appState = appStateAsync.value ?? AppState.empty;
    final notifier = ref.read(appStateProvider.notifier);

    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final user = ref.watch(currentUserProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final isRealtime = ref.watch(isRealtimeActiveProvider);
    final lastSyncedAt = ref.watch(lastSyncedAtProvider);

    return _InsetGroupContainer(
      children: [
        if (isAuthenticated && user != null)
          _AuthenticatedAccountCard(
            user: user,
            syncStatus: syncStatus,
            pendingCount: pendingCount,
            isRealtime: isRealtime,
            lastSyncedAt: lastSyncedAt,
          )
        else
          const _GuestAccountCard(),
        _groupDivider(),
        // 2. Leaderboard Toggle
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          title: 'Focus Leaderboard',
          subtitle: 'Compete on daily & weekly boards',
          trailing: Switch.adaptive(
            value: appState.leaderboardVisible,
            activeTrackColor: AppTheme.accentPrimary,
            onChanged: (val) {
              notifier.updateLeaderboardIdentity(visible: val);
            },
          ),
          onTap: () => context.push('/analytics/leaderboard'),
        ),
        if (appState.leaderboardVisible) ...[
          _groupDivider(),
          // 3. Leaderboard Name
          _SettingsItemRow(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.badge_outlined,
                color: AppTheme.accentPrimary,
                size: 20,
              ),
            ),
            title: 'Podium Name',
            subtitle: appState.publicDisplayName,
            trailing: const Icon(Icons.edit_rounded, size: 16),
            onTap: () => SettingsScreen.editLeaderboardName(
              context,
              notifier,
              (appState.leaderboardDisplayName?.isNotEmpty ?? false)
                  ? appState.leaderboardDisplayName!
                  : appState.doctorName,
            ),
          ),
          _groupDivider(),
          // 4. Incognito Mode
          _SettingsItemRow(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.mutedText.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.visibility_off_outlined,
                color: AppTheme.mutedText,
                size: 20,
              ),
            ),
            title: 'Incognito Mode',
            subtitle: 'Conceal as "Dr. Anonymous"',
            trailing: Switch.adaptive(
              value: appState.isLeaderboardAnonymous,
              activeTrackColor: AppTheme.accentPrimary,
              onChanged: (val) {
                notifier.updateLeaderboardIdentity(isAnonymous: val);
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Group 3: Preferences ──────────────────────────────────────────────────────
class _PreferencesGroup extends StatelessWidget {
  const _PreferencesGroup();

  @override
  Widget build(BuildContext context) {
    return _InsetGroupContainer(
      children: [
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentTertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: AppTheme.accentTertiary,
              size: 20,
            ),
          ),
          title: 'Notifications & Routine',
          subtitle: 'Study reminders, streak & routine alerts',
          onTap: () => context.push('/settings/notifications-preferences'),
        ),
        _groupDivider(),
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF059669),
              size: 20,
            ),
          ),
          title: 'Background Reliability & Battery',
          subtitle: 'Prevent timer halts & manage Doze mode',
          onTap: () => BatteryOptimizationSheet.show(context),
        ),
      ],
    );
  }
}

// ── Group 4: Resources & About ────────────────────────────────────────────────
class _ResourcesGroup extends StatelessWidget {
  const _ResourcesGroup();

  @override
  Widget build(BuildContext context) {
    return _InsetGroupContainer(
      children: [
        // 1. Welcome Tour
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.explore_outlined,
              color: AppTheme.accentPrimary,
              size: 20,
            ),
          ),
          title: 'Welcome Tour',
          subtitle: 'Replay feature walkthrough',
          onTap: () => context.push('/onboarding?replay=true'),
        ),
        _groupDivider(),
        // 2. App Guide & Reference
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentSecondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: AppTheme.accentSecondary,
              size: 20,
            ),
          ),
          title: 'App Guide & Reference',
          subtitle: 'Timer tips, pacing engine & shortcuts',
          onTap: () => LearnTheAppSheet.show(context),
        ),
        _groupDivider(),
        // 3. Data & Privacy
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentTertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: AppTheme.accentTertiary,
              size: 20,
            ),
          ),
          title: 'Data & Privacy',
          subtitle: 'Export/import JSON backups & privacy policy',
          onTap: () => DataPrivacySheet.show(context),
        ),
        _groupDivider(),
        // 4. About & Support
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentQuaternary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppTheme.accentQuaternary,
              size: 20,
            ),
          ),
          title: 'About Modulix',
          subtitle: 'v1.19.0 · Medical disclaimer & support',
          onTap: () => AboutSupportSheet.show(context),
        ),
      ],
    );
  }
}

// ── Authenticated Account & Cloud Sync Card ─────────────────────────────────
class _AuthenticatedAccountCard extends ConsumerWidget {
  final User user;
  final SyncStatus syncStatus;
  final int pendingCount;
  final bool isRealtime;
  final DateTime? lastSyncedAt;

  const _AuthenticatedAccountCard({
    required this.user,
    required this.syncStatus,
    required this.pendingCount,
    required this.isRealtime,
    required this.lastSyncedAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = context.modulixTheme;
    final email = user.email ?? 'Authenticated Account';
    final provider =
        user.appMetadata['provider']?.toString().toLowerCase() ?? 'google';
    final isGoogle = provider == 'google';

    final Color statusColor;
    final String statusLabel;

    if (isRealtime) {
      statusColor = const Color(0xFF059669);
      statusLabel = 'Realtime Interlinked';
    } else if (syncStatus == SyncStatus.syncing) {
      statusColor = AppTheme.accentPrimary;
      statusLabel = 'Syncing...';
    } else if (syncStatus == SyncStatus.offline) {
      statusColor = const Color(0xFFD97706);
      statusLabel = 'Offline Mode';
    } else {
      statusColor = const Color(0xFF059669);
      statusLabel = 'Cloud Connected';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Identity Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isGoogle
                      ? const Color(0xFF4285F4).withValues(alpha: 0.12)
                      : AppTheme.accentPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isGoogle
                        ? const Color(0xFF4285F4).withValues(alpha: 0.3)
                        : AppTheme.accentPrimary.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  isGoogle
                      ? Icons.account_circle_rounded
                      : Icons.alternate_email_rounded,
                  color:
                      isGoogle ? const Color(0xFF1A73E8) : AppTheme.accentPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: activeTheme.inkForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isGoogle ? 'Google Account' : 'Email OTP'} · ID: ${user.id.substring(0, math.min(8, user.id.length))}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: activeTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Telemetry Quick Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activeTheme.borderSubtle, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TelemetryMiniItem(
                  label: 'LAST SYNCED',
                  value: _formatRelativeTime(lastSyncedAt),
                  theme: activeTheme,
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: activeTheme.borderSubtle,
                ),
                _TelemetryMiniItem(
                  label: 'OUTBOX QUEUE',
                  value:
                      pendingCount == 0 ? 'Clean (0)' : '$pendingCount queued',
                  valueColor: pendingCount == 0
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                  theme: activeTheme,
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: activeTheme.borderSubtle,
                ),
                ApplePressable(
                  onTap: () => SyncDiagnosticsSheet.show(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Diagnostics',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppTheme.accentPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Action Buttons
          Row(
            children: [
              Expanded(
                child: ApplePressable(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    SyncService.instance.syncFull(ref);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (syncStatus == SyncStatus.syncing)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.8),
                          )
                        else
                          Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: AppTheme.accentPrimary,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          pendingCount > 0
                              ? 'Sync Outbox ($pendingCount)'
                              : 'Sync Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ApplePressable(
                onTap: () => SyncDiagnosticsSheet.show(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: activeTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: activeTheme.borderSubtle, width: 0.8),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: activeTheme.inkForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ApplePressable(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.cardWhite,
                      title: Text('Sign Out',
                          style: AppTypography.dialogTitle(fontSize: 18.0)),
                      content: Text(
                        'Your study progress will remain safely on this device and in the cloud.',
                        style: AppTypography.dialogBody(fontSize: 13.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel',
                              style: AppTypography.buttonLabel(
                                  fontSize: 13.0, color: AppTheme.mutedText)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Sign Out',
                              style: AppTypography.buttonLabel(
                                  fontSize: 13.0, color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await AuthService.instance.signOut();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

// ── Guest Account & Offline Sync Card ───────────────────────────────────────
class _GuestAccountCard extends StatelessWidget {
  const _GuestAccountCard();

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: AppTheme.accentPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest Account · Local Storage',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: activeTheme.inkForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saved on device · Not synced to cloud',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: activeTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your study progress is saved only on this phone. Sign in with Google to enable real-time cross-device sync with the web portal and protect your study history.',
            style: TextStyle(
              fontSize: 12.0,
              height: 1.4,
              color: activeTheme.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ApplePressable(
                  onTap: () => context.push('/settings/auth'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Sign In with Google / Email',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ApplePressable(
                onTap: () => SyncDiagnosticsSheet.show(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: activeTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: activeTheme.borderSubtle, width: 0.8),
                  ),
                  child: Text(
                    'Diagnostics',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: activeTheme.inkForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mini Telemetry Pill Widget ──────────────────────────────────────────────
class _TelemetryMiniItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final ModulixThemeExtension theme;

  const _TelemetryMiniItem({
    required this.label,
    required this.value,
    this.valueColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: theme.mutedText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? theme.inkForeground,
          ),
        ),
      ],
    );
  }
}

