import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../services/notification_service.dart';
import '../../widgets/profile/profile_customization.dart';
import 'appearance_theme_sheet.dart';
import 'learn_the_app_sheet.dart';
import 'data_privacy_sheet.dart';
import 'about_support_sheet.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/sync_status_badge.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../auth/auth_screen.dart';

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
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: const [
          _DoctorProfileCard(),
          SizedBox(height: 20),
          _CloudSyncSection(),
          SizedBox(height: 20),
          _ThemeAppearanceSection(),
          SizedBox(height: 24),
          _SyllabusEditionSection(),
          SizedBox(height: 24),
          _StartOfDaySection(),
          SizedBox(height: 24),
          _NotificationsSection(),
          SizedBox(height: 28),
          _ResourceHubsSection(),
          SizedBox(height: 32),
          _DangerZoneSection(),
        ],
      ),
    );
  }

  static Widget pillChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.94,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.inkForeground : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.inkForeground : AppTheme.borderLight,
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101C1C1C),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? AppTheme.paperBackground : AppTheme.inkForeground,
            ),
          ),
        ),
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

  static void confirmReset(BuildContext context, WidgetRef ref) {
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
                    fillColor: AppTheme.current.isDark ? const Color(0xFF2D1515) : Colors.red.shade50,
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
                child: Text('Cancel',
                    style: TextStyle(color: AppTheme.mutedText)),
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

// ── 1. Doctor Profile Card ──────────────────────────────────────
class _DoctorProfileCard extends ConsumerWidget {
  const _DoctorProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider).valueOrNull;
    if (appState == null) return const SizedBox.shrink();

    final doctorName =
        appState.doctorName.isNotEmpty ? appState.doctorName : 'Doctor';

    return Container(
      key: TourTargetRegistry.keyFor(TourTargetId.settingsProfileCard),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.cardWhite,
        borderRadius: 20,
        shadowOffset: 3,
      ),
      child: Row(
        children: [
          ProfileAvatar(
            size: 58,
            colorId: appState.avatarColorId,
            iconId: appState.avatarIconId,
            doctorName: doctorName,
            onTap: () => ProfileCustomizeSheet.show(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        appState.activeEdition == 'marrow_8'
                            ? 'Marrow Ed 8'
                            : 'Marrow Ed 6.5',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ProfileCardAction(
            icon: Icons.tune_rounded,
            label: 'Customize',
            onTap: () => ProfileCustomizeSheet.show(context),
          ),
        ],
      ),
    );
  }
}

// Small stacked action chip used in the profile card
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
      pressedScale: 0.92,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.parchmentSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryBlue),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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

// ── Cloud Sync & Multi-Device Section ─────────────────────────────
class _CloudSyncSection extends ConsumerWidget {
  const _CloudSyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentUser = ref.watch(currentUserProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: AppTheme.cardWhite,
        borderRadius: 20,
        shadowOffset: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.accentSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.cloud_sync_rounded,
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
                            'Cloud Sync & Devices',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                          Text(
                            isAuthenticated
                                ? (currentUser?.email ?? 'Logged in')
                                : 'Guest Mode · Local storage only',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const SyncStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          if (isAuthenticated) ...[
            Text(
              'Your study progress, timer history, and daily tasks sync automatically across all your Android devices.',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedText, height: 1.3),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: AppTheme.cardBorder),
                    ),
                    onPressed: syncStatus == SyncStatus.syncing
                        ? null
                        : () => SyncService.instance.syncFull(ref),
                    icon: Icon(Icons.refresh_rounded, size: 16, color: AppTheme.inkForeground),
                    label: Text(
                      'Sync Now',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.inkForeground),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardWhite,
                        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
                        content: const Text(
                          'Your study progress will remain safely on this device and in the cloud.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel', style: TextStyle(color: AppTheme.mutedText)),
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
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Sign in or create a Modulix account to sync your study plan, video checklists, and focus timer records with other devices.',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedText, height: 1.3),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.inkForeground,
                foregroundColor: AppTheme.cardWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => AuthScreen.show(context),
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text(
                'Sign In or Create Account',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Theme & Appearance ───────────────────────────────────────────
class _ThemeAppearanceSection extends ConsumerWidget {
  const _ThemeAppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final appState = appStateAsync.value ?? AppState.empty;
    final activeTheme = context.modulixTheme;

    final preset = PalettePreset.fromId(appState.palettePresetId);
    final themeAccent = preset.isDark ? preset.accentDark : preset.accent;

    return Column(
      key: TourTargetRegistry.keyFor(TourTargetId.settingsThemeSection),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'APPEARANCE & THEME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: activeTheme.mutedText,
              ),
            ),
            ApplePressable(
              onTap: () => context.push('/theme-studio'),
              pressedScale: 0.94,
              child: Text(
                'Studio →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: activeTheme.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ApplePressable(
          onTap: () => context.push('/theme-studio'),
          pressedScale: 0.98,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: AppTheme.sketchDecoration(
              borderRadius: 18,
              shadowOffset: 2.5,
            ),
            child: Row(
              children: [
                // Multi-tier theme preview capsule
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: preset.scaffoldBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: preset.borderSubtle, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: activeTheme.inkForeground.withValues(alpha: 0.08),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: preset.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: preset.borderSubtle, width: 1.0),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: themeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preset.description,
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
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: activeTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeTheme.borderSubtle,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Studio',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: activeTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: activeTheme.accent,
                        size: 13,
                      ),
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

// ── 2. Syllabus Edition Selection ────────────────────────────────
class _SyllabusEditionSection extends ConsumerWidget {
  const _SyllabusEditionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEdition =
        ref.watch(appStateProvider.select((s) => s.valueOrNull?.activeEdition));
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE SYLLABUS EDITION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppTheme.inkForeground,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SettingsScreen.pillChoice(
                label: 'Marrow Edition 8',
                selected: activeEdition == 'marrow_8',
                onTap: () => notifier.switchEdition('marrow_8'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SettingsScreen.pillChoice(
                label: 'Marrow Edition 6.5',
                selected: activeEdition == 'marrow_6_5',
                onTap: () => notifier.switchEdition('marrow_6_5'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 4. Start of the Study Day ────────────────────────────────────
class _StartOfDaySection extends ConsumerWidget {
  const _StartOfDaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayStartHour = ref.watch(
        appStateProvider.select((s) => s.valueOrNull?.dayStartHour ?? 5));
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'START OF THE STUDY DAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppTheme.inkForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configures your daily streak rollover, focus timer resets, and desk pad boundaries',
          style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.sketchDecoration(
            backgroundColor: AppTheme.cardWhite,
            borderRadius: 18,
            shadowOffset: 3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_twilight_rounded,
                          size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Day resets at:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange, width: 1.2),
                    ),
                    child: Text(
                      '$dayStartHour:00 AM',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [3, 4, 5, 6, 7].map((hour) {
                  final isSelected = dayStartHour == hour;
                  return ChoiceChip(
                    label: Text('$hour:00 AM'),
                    selected: isSelected,
                    onSelected: (_) => notifier.setDayStartHour(hour),
                    selectedColor: AppTheme.inkForeground,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.inkForeground
                            : AppTheme.borderLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 5. Notifications & Alerts ────────────────────────────────────
class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  String _formatTimeStr(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2026, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    String currentTimeStr,
    ValueChanged<String> onSelected,
  ) async {
    int initialHour = 9;
    int initialMinute = 0;
    try {
      final parts = currentTimeStr.split(':');
      initialHour = int.parse(parts[0]);
      initialMinute = int.parse(parts[1]);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onSelected('$h:$m');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider).valueOrNull;
    final notifier = ref.read(appStateProvider.notifier);

    if (appState == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTIFICATIONS & ALERTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppTheme.inkForeground,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.sketchDecoration(
            backgroundColor: AppTheme.cardWhite,
            borderRadius: 18,
            shadowOffset: 3,
          ),
          child: Column(
            children: [
              // Permission banner & Test button
              FutureBuilder<bool>(
                future: NotificationService.instance.hasPermission(),
                builder: (ctx, snap) {
                  final hasPerm = snap.data ?? false;
                  if (hasPerm) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Notifications Enabled',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              await NotificationService.instance
                                  .sendTestNotification(
                                      doctorName: appState.doctorName);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Test notification sent!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.notifications_active,
                                size: 14, color: AppTheme.primaryBlue),
                            label: Text(
                              'Test',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return InkWell(
                    onTap: () async {
                      final granted = await NotificationService.instance
                          .requestPermissions();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(granted
                                ? 'Notification permissions granted!'
                                : 'Notification permission requested.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.amber.shade700, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.amber.shade800, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap to enable system notifications',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 1. Daily Study Reminder
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Study Reminder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Prompt to start your syllabus goals',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                  if (appState.dailyReminderEnabled)
                    InkWell(
                      onTap: () => _pickTime(
                        context,
                        appState.studyReminderTime,
                        (t) => notifier.setStudyReminderTime(t),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14, color: AppTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeStr(appState.studyReminderTime),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  CupertinoSwitch(
                    activeColor: AppTheme.primaryBlue,
                    trackColor: AppTheme.borderLight,
                    thumbColor: Colors.white,
                    value: appState.dailyReminderEnabled,
                    onChanged: (val) => notifier.setDailyReminder(val),
                  ),
                ],
              ),
              Divider(height: 16, color: AppTheme.borderLight),

              // 2. Streak at Risk Alert
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streak at Risk Alert',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Evening alert if no progress made today',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                  if (appState.streakReminderEnabled)
                    InkWell(
                      onTap: () => _pickTime(
                        context,
                        appState.streakReminderTime,
                        (t) => notifier.setStreakReminder(true, t),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeStr(appState.streakReminderTime),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  CupertinoSwitch(
                    activeColor: Colors.orange,
                    trackColor: AppTheme.borderLight,
                    thumbColor: Colors.white,
                    value: appState.streakReminderEnabled,
                    onChanged: (val) => notifier.setStreakReminder(val),
                  ),
                ],
              ),
              Divider(height: 16, color: AppTheme.borderLight),

              // 3. Module Daily Tasks Reminder
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Module Daily Tasks',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Morning queue briefing & goal completion',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                  if (appState.moduleTasksReminderEnabled)
                    InkWell(
                      onTap: () => _pickTime(
                        context,
                        appState.moduleTasksReminderTime,
                        (t) => notifier.setModuleTasksReminder(true, t),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.teal.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: Colors.teal),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeStr(appState.moduleTasksReminderTime),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  CupertinoSwitch(
                    activeColor: Colors.teal,
                    trackColor: AppTheme.borderLight,
                    thumbColor: Colors.white,
                    value: appState.moduleTasksReminderEnabled,
                    onChanged: (val) => notifier.setModuleTasksReminder(val),
                  ),
                ],
              ),
              Divider(height: 16, color: AppTheme.borderLight),

              // 4. Focus Timer Alerts
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus Timer Alerts & Sound',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Background alerts for session & break finishes',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    activeColor: AppTheme.primaryBlue,
                    trackColor: AppTheme.borderLight,
                    thumbColor: Colors.white,
                    value: appState.focusTimerAlertsEnabled,
                    onChanged: (val) => notifier.setFocusTimerAlerts(val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 6. Resource Hubs (Learn the App, Data & Privacy, About) ──────
class _ResourceHubsSection extends ConsumerWidget {
  const _ResourceHubsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESOURCES & SOVEREIGNTY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Feature Tour Card
        _SleekHubCard(
          title: 'Interactive Feature Tour',
          subtitle: 'Step-by-step spotlight tour across Desk Clock, Tasks, Curriculum, Analytics & Focus Timer',
          tag: 'GUIDED',
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF2DD4BF),
          iconBg: const Color(0x202DD4BF),
          onTap: () => ref.read(appTourProvider.notifier).startTour(context),
        ),

        const SizedBox(height: 10),

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

        // Learn the App Card
        _SleekHubCard(
          title: 'Learn the App',
          subtitle:
              'Interactive guide & tips for module tracking & timer modes',
          tag: 'GUIDE & TIPS',
          icon: Icons.lightbulb_outline_rounded,
          iconColor: Colors.purple,
          iconBg: Colors.purple.withValues(alpha: 0.12),
          onTap: () => LearnTheAppSheet.show(context),
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

        // About & Support Card
        _SleekHubCard(
          title: 'About & Support',
          subtitle: 'Version 1.0.0, feedback contact & app sharing',
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

// ── 7. Danger Zone ───────────────────────────────────────────────
class _DangerZoneSection extends ConsumerWidget {
  const _DangerZoneSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DANGER ZONE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.red.shade50.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(18),
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
                    'Reset All Study Progress',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Wipes all completed video marks, daily task history, and time logs across all syllabus editions.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade900,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppTheme.cardWhite,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.redAccent, size: 18),
                label: const Text(
                  'Reset Progress...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () => SettingsScreen.confirmReset(context, ref),
              ),
            ],
          ),
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
        decoration: AppTheme.sketchDecoration(
          backgroundColor: AppTheme.cardWhite,
          borderRadius: 16,
          shadowOffset: 2.5,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor, width: 1.3),
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
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
