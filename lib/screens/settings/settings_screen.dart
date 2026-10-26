import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/profile/profile_customization.dart';
import 'data_privacy_sheet.dart';
import 'about_support_sheet.dart';
import 'learn_the_app_sheet.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/animations/apple_pressable.dart';

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
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    // Compute status info
    final IconData syncIcon;
    final Color syncIconColor;
    final String syncSubtitle;

    if (isAuthenticated) {
      if (syncStatus == SyncStatus.syncing) {
        syncIcon = Icons.cloud_sync_rounded;
        syncIconColor = AppTheme.accentPrimary;
        syncSubtitle = 'Syncing study sessions...';
      } else if (pendingCount > 0) {
        syncIcon = Icons.cloud_upload_outlined;
        syncIconColor = const Color(0xFFF59E0B);
        syncSubtitle = '$pendingCount sessions waiting backup';
      } else {
        syncIcon = Icons.cloud_done_rounded;
        syncIconColor = AppTheme.accentEmerald;
        syncSubtitle = 'All study sessions backed up';
      }
    } else {
      syncIcon = Icons.cloud_off_rounded;
      syncIconColor = AppTheme.mutedText;
      syncSubtitle = pendingCount > 0
          ? '$pendingCount sessions stored locally'
          : 'Guest Mode · Stored locally';
    }

    return _InsetGroupContainer(
      children: [
        // 1. Cloud Backup
        _SettingsItemRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: syncIconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(syncIcon, color: syncIconColor, size: 20),
          ),
          title: 'Cloud Backup',
          subtitle: syncSubtitle,
          trailing: isAuthenticated
              ? (syncStatus == SyncStatus.syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pendingCount > 0)
                          ApplePressable(
                            onTap: () => SyncService.instance.syncFull(ref),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Back Up',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onAccent,
                                ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ))
              : ApplePressable(
                  onTap: () => context.push('/settings/auth'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onAccent,
                      ),
                    ),
                  ),
                ),
          onTap: () {
            if (isAuthenticated) {
              SyncService.instance.syncFull(ref);
            } else {
              context.push('/settings/auth');
            }
          },
        ),
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
