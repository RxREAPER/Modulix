import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/timer/battery_optimization_sheet.dart';
import 'data_privacy_sheet.dart';
import 'learn_the_app_sheet.dart';
import 'about_support_sheet.dart';

/// Clean, minimalistic Modulix Settings & Profile Screen.
/// Features stylized profile card, account sub-page entry, theme studio preview card,
/// and syllabus edition overview with zero redundant clutter.
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
          icon: Icon(Icons.arrow_back_rounded, color: activeTheme.inkForeground),
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
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: activeTheme.inkForeground,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.paddingOf(context).bottom + 100.0,
        ),
        children: const [
          // 1. Stylized Profile Hero Card (No extra texts)
          _DoctorProfileHero(),
          SizedBox(height: 14),

          // 2. Account Sub-page Card
          _AccountCard(),
          SizedBox(height: 24),

          // 3. Study & Atmosphere (Theme Preview & Syllabus Edition)
          _SettingsGroupHeader(title: 'STUDY & ATMOSPHERE'),
          _ThemeStudioPreviewCard(),
          SizedBox(height: 12),
          _SyllabusEditionCard(),
          SizedBox(height: 24),

          // 4. Preferences
          _SettingsGroupHeader(title: 'PREFERENCES'),
          _PreferencesGroup(),
          SizedBox(height: 24),

          // 5. Resources & About
          _SettingsGroupHeader(title: 'RESOURCES & ABOUT'),
          _ResourcesGroup(),
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
    final activeTheme = context.modulixTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: activeTheme.mutedText,
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
    final activeTheme = context.modulixTheme;
    return Container(
      decoration: BoxDecoration(
        color: activeTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
  final VoidCallback? onTap;

  const _SettingsItemRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;
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
                      color: activeTheme.inkForeground,
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
                        color: activeTheme.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: activeTheme.mutedText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _groupDivider(BuildContext context) {
  final activeTheme = context.modulixTheme;
  return Divider(
    height: 1,
    thickness: 0.8,
    indent: 58,
    endIndent: 16,
    color: activeTheme.borderSubtle,
  );
}

// ── 1. Doctor Profile Stylized Hero Card (NO EXTRA TEXTS) ─────────────────────
class _DoctorProfileHero extends ConsumerWidget {
  const _DoctorProfileHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final activeTheme = context.modulixTheme;
    final appState = ref.watch(appStateProvider).valueOrNull;
    if (appState == null) return const SizedBox.shrink();

    final displayName = appState.publicDisplayName;

    return ApplePressable(
      onTap: () => context.push('/settings/profile'),
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: activeTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.35),
                  width: 1.8,
                ),
              ),
              child: ProfileAvatar(
                size: 52,
                colorId: appState.avatarColorId,
                iconId: appState.avatarIconId,
                doctorName: appState.doctorName,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: activeTheme.inkForeground,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: activeTheme.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. Account Sub-page Entry Card ───────────────────────────────────────────
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = context.modulixTheme;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final user = ref.watch(currentUserProvider);
    final lastSyncedAt = ref.watch(lastSyncedAtProvider);

    String syncSubtitle = 'Tap to manage sync';
    if (isAuthenticated && user != null) {
      if (lastSyncedAt != null) {
        final diff = DateTime.now().difference(lastSyncedAt);
        if (diff.inSeconds < 45) {
          syncSubtitle = 'Synced just now';
        } else if (diff.inMinutes < 60) {
          syncSubtitle = 'Synced ${diff.inMinutes}m ago';
        } else {
          syncSubtitle = 'Synced ${diff.inHours}h ago';
        }
      } else {
        syncSubtitle = 'Connected · Tap to sync';
      }
    } else {
      syncSubtitle = 'Local storage · Tap to sign in';
    }

    return ApplePressable(
      onTap: () => context.push('/settings/account'),
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: activeTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activeTheme.borderSubtle,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isAuthenticated
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : activeTheme.mutedText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAuthenticated ? Icons.cloud_done_rounded : Icons.cloud_outlined,
                color: isAuthenticated ? const Color(0xFF059669) : activeTheme.mutedText,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAuthenticated && user?.email != null
                        ? user!.email!
                        : 'Cloud Sync & Account',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: activeTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    syncSubtitle,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: activeTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
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

// ── 3. Theme Studio Preview Card ─────────────────────────────────────────────
class _ThemeStudioPreviewCard extends ConsumerWidget {
  const _ThemeStudioPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeDataProvider);
    final activeTheme = context.modulixTheme;
    final appState = ref.watch(appStateProvider).valueOrNull ?? AppState.empty;
    final preset = PalettePreset.fromId(appState.palettePresetId);

    return ApplePressable(
      onTap: () => context.push('/settings/theme-studio'),
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: activeTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activeTheme.borderSubtle,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 32,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: preset.scaffoldBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: preset.borderSubtle, width: 1.2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 11,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: preset.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: preset.secondaryAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Studio',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: activeTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${preset.label} · Active Atmosphere',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: activeTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
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

// ── 4. Syllabus Edition Card (NO "Marrow") ────────────────────────────────────
class _SyllabusEditionCard extends ConsumerWidget {
  const _SyllabusEditionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = context.modulixTheme;
    final appState = ref.watch(appStateProvider).valueOrNull ?? AppState.empty;
    final isEdition8 = appState.activeEdition == 'marrow_8';

    return ApplePressable(
      onTap: () => context.push('/settings/syllabus-edition'),
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: activeTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activeTheme.borderSubtle,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_outlined,
                color: AppTheme.accentPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdition8 ? 'Edition 8' : 'Edition 6.5',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: activeTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEdition8
                        ? 'Standard Curriculum · 19 Subjects · 848 Modules'
                        : 'Classic Foundation · 19 Subjects · 792 Modules',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: activeTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
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

// ── 5. Preferences Group ──────────────────────────────────────────────────────
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
        _groupDivider(context),
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

// ── 6. Resources & About Group ────────────────────────────────────────────────
class _ResourcesGroup extends StatelessWidget {
  const _ResourcesGroup();

  @override
  Widget build(BuildContext context) {
    return _InsetGroupContainer(
      children: [
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
        _groupDivider(context),
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
        _groupDivider(context),
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
        _groupDivider(context),
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
