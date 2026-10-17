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
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/animations/apple_pressable.dart';

class SettingsScreen extends StatelessWidget {
  final String? from;
  const SettingsScreen({super.key, this.from});

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: const [
          _DoctorProfileCard(),
          SizedBox(height: 16),
          _CloudSyncSection(),
          SizedBox(height: 16),
          _ThemeAppearanceSection(),
          SizedBox(height: 16),
          _SyllabusEditionSection(),
          SizedBox(height: 16),
          _NotificationsPreferencesSection(),
          SizedBox(height: 24),
          _ResourceHubsSection(),
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
          side: BorderSide(color: AppTheme.sketchBorderColor, width: 1.8),
        ),
        title: const Text('Edit Doctor Name',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.mutedText)),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── 1. Elevated Doctor Profile Card ─────────────────────────────
class _DoctorProfileCard extends ConsumerWidget {
  const _DoctorProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider).valueOrNull;
    if (appState == null) return const SizedBox.shrink();

    final doctorName =
        appState.doctorName.isNotEmpty ? appState.doctorName : 'Doctor';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 72px avatar with double circular accent border
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                    width: 2.2,
                  ),
                ),
                child: ProfileAvatar(
                  size: 68,
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
                      doctorName.startsWith('Dr') ? doctorName : 'Dr. $doctorName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.inkForeground,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _ProfileCardAction(
                  icon: Icons.palette_outlined,
                  label: 'Customize Persona',
                  onTap: () => ProfileCustomizeSheet.show(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _ProfileCardAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit Name',
                  onTap: () => SettingsScreen.editDoctorName(
                      context, ref.read(appStateProvider.notifier), doctorName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Stacked action chip used in the profile card
class _ProfileCardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileCardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.94,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.parchmentSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryBlue),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. Cloud Sync & Multi-Device Section ─────────────────────────
class _CloudSyncSection extends ConsumerWidget {
  const _CloudSyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentUser = ref.watch(currentUserProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLOUD & SYNC',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 10),
        ApplePressable(
          pressedScale: 0.98,
          onPressed: () {
            if (isAuthenticated) {
              SyncService.instance.syncFull(ref);
            } else {
              context.push('/auth');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.cloud_sync_rounded,
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
                        'Cloud Sync',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isAuthenticated
                            ? (currentUser?.email ?? 'Connected & Synced')
                            : 'Guest Mode • Local only',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isAuthenticated
                              ? Colors.green.shade700
                              : AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isAuthenticated) ...[
                  if (syncStatus == SyncStatus.syncing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    ApplePressable(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.cardWhite,
                            title: const Text('Sign Out',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                            content: const Text(
                              'Your study progress will remain safely on this device and in the cloud.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Cancel',
                                    style: TextStyle(color: AppTheme.mutedText)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sign Out'),
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
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.inkForeground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.paperBackground,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 11,
                          color: AppTheme.paperBackground,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 3. Theme & Appearance (Creative & Minimalist) ────────────────
class _ThemeAppearanceSection extends ConsumerWidget {
  const _ThemeAppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final appState = appStateAsync.value ?? AppState.empty;
    final activeTheme = context.modulixTheme;

    final preset = PalettePreset.fromId(appState.palettePresetId);
    final themeAccent = preset.isDark ? preset.accentDark : preset.accent;
    final secondaryAccent = preset.secondaryAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APPEARANCE & THEME',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: activeTheme.mutedText,
          ),
        ),
        const SizedBox(height: 10),
        ApplePressable(
          onTap: () => context.push('/theme-studio'),
          pressedScale: 0.98,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Creative overlapping animated palette swatch disc cluster
                SizedBox(
                  width: 52,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: preset.scaffoldBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: preset.borderSubtle, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 13,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: themeAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: themeAccent.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: secondaryAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: secondaryAccent.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: activeTheme.inkForeground,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Active Atmosphere • Tap to customize',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: activeTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Studio',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: activeTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: activeTheme.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 4. Dedicated Syllabus Edition Selection ───────────────────────
class _SyllabusEditionSection extends ConsumerWidget {
  const _SyllabusEditionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEdition =
        ref.watch(appStateProvider.select((s) => s.valueOrNull?.activeEdition)) ??
            'marrow_8';
    final isEdition8 = activeEdition == 'marrow_8';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SYLLABUS & CURRICULUM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 10),
        ApplePressable(
          pressedScale: 0.98,
          onPressed: () => context.push('/syllabus-edition'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (isEdition8 ? AppTheme.primaryBlue : Colors.teal)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isEdition8 ? AppTheme.primaryBlue : Colors.teal)
                          .withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: isEdition8 ? AppTheme.primaryBlue : Colors.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isEdition8
                                  ? 'Marrow Edition 8'
                                  : 'Marrow Edition 6.5',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.inkForeground,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isEdition8
                            ? '19 Subjects • 848 Lectures'
                            : '19 Subjects • 792 Lectures',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: AppTheme.mutedText),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 5. Notifications & Preferences Section ────────────────────────
class _NotificationsPreferencesSection extends StatelessWidget {
  const _NotificationsPreferencesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTIFICATIONS & PREFERENCES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 10),
        ApplePressable(
          pressedScale: 0.98,
          onPressed: () => context.push('/notifications-preferences'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications & Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Study reminders, streak alerts & timing',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: AppTheme.mutedText),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 6. Resource Hubs (Welcome, Data & Privacy, About) ─────────────
class _ResourceHubsSection extends ConsumerWidget {
  const _ResourceHubsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESOURCES & LEGAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 12),

        // Welcome Tour Card
        _SleekHubCard(
          title: 'Welcome Tour',
          subtitle: 'Replay feature walkthrough & configure doctor profile',
          tag: 'PROFILE SETUP',
          icon: Icons.explore_outlined,
          iconColor: AppTheme.primaryBlue,
          iconBg: AppTheme.primaryBlue.withValues(alpha: 0.12),
          onTap: () => context.push('/onboarding?replay=true'),
        ),

        const SizedBox(height: 10),

        // Data & Privacy Card
        _SleekHubCard(
          title: 'Data & Privacy',
          subtitle: 'Export/import JSON backups & review privacy legal terms',
          tag: 'SECURITY',
          icon: Icons.shield_outlined,
          iconColor: Colors.teal,
          iconBg: Colors.teal.withValues(alpha: 0.12),
          onTap: () => DataPrivacySheet.show(context),
        ),

        const SizedBox(height: 10),

        // About & Support Card (Now includes relocated Danger Zone)
        _SleekHubCard(
          title: 'About & Support',
          subtitle: 'Version info, medical disclaimer & reset progress',
          tag: 'ABOUT',
          icon: Icons.info_outline_rounded,
          iconColor: Colors.blueGrey,
          iconBg: Colors.blueGrey.withValues(alpha: 0.12),
          onTap: () => AboutSupportSheet.show(context),
        ),
      ],
    );
  }
}

class _SleekHubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _SleekHubCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      pressedScale: 0.98,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.2),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }
}
