import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/timer/battery_optimization_sheet.dart';
import 'data_privacy_sheet.dart';
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
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItemRow({
    required this.leading,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;

    return ApplePressable(
      onTap: onTap,
      pressedScale: onTap != null ? 0.98 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: activeTheme.inkForeground,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (onTap != null) ...[
              const SizedBox(width: 6),
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

// ── 2. Account Sub-page Entry Card (Solid Name) ───────────────────────────────
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = context.modulixTheme;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final user = ref.watch(currentUserProvider);

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
              child: Text(
                isAuthenticated && user?.email != null
                    ? user!.email!
                    : 'Account & Sync',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: activeTheme.inkForeground,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: isAuthenticated
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : activeTheme.mutedText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAuthenticated ? 'Connected' : 'Guest',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: isAuthenticated
                      ? const Color(0xFF059669)
                      : activeTheme.mutedText,
                ),
              ),
            ),
            const SizedBox(width: 4),
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

// ── 3. Theme Studio Preview Card (Solid Name) ─────────────────────────────────
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: preset.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.palette_outlined,
                color: preset.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Theme Studio',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: activeTheme.inkForeground,
                ),
              ),
            ),
            SizedBox(
              width: 44,
              height: 32,
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
                    left: 11,
                    child: Container(
                      width: 20,
                      height: 20,
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
                      width: 20,
                      height: 20,
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
            const SizedBox(width: 4),
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

// ── 4. Syllabus Edition Card (Solid Name, NO "Marrow") ────────────────────────
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
              child: Text(
                'Syllabus Edition',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: activeTheme.inkForeground,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isEdition8 ? 'Edition 8' : 'Edition 6.5',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
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

// ── 5. Preferences Group (Solid Names) ────────────────────────────────────────
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
          title: 'Notifications',
          onTap: () => context.push('/settings/notifications'),
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
          title: 'Battery Reliability',
          onTap: () => BatteryOptimizationSheet.show(context),
        ),
      ],
    );
  }
}

// ── 6. Resources & About Group (Solid Names) ──────────────────────────────────
class _ResourcesGroup extends StatelessWidget {
  const _ResourcesGroup();

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;

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
          title: 'Feature Tour',
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
          onTap: () => context.push('/settings/guide'),
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
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: activeTheme.mutedText.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'v1.36.0',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: activeTheme.mutedText,
              ),
            ),
          ),
          onTap: () => AboutSupportSheet.show(context),
        ),
      ],
    );
  }
}
