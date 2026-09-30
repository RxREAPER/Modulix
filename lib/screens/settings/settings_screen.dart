import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import 'learn_the_app_sheet.dart';
import 'data_privacy_sheet.dart';
import 'about_support_sheet.dart';



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        centerTitle: false,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Settings & Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.inkForeground,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: const [
          _DoctorProfileCard(),
          SizedBox(height: 20),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.inkForeground : Colors.white,
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
              color: selected ? Colors.white : AppTheme.inkForeground,
            ),
          ),
        ),
      ),
    );
  }

  static void editDoctorName(BuildContext context, AppStateNotifier notifier, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.sketchBorderColor, width: 1.8),
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
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkForeground,
              foregroundColor: Colors.white,
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.redAccent, size: 24),
                SizedBox(width: 8),
                Text('Danger: Reset Progress',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
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
                    fillColor: Colors.red.shade50,
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
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.mutedText)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConfirmed ? Colors.redAccent : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isConfirmed
                    ? () async {
                        await ref.read(appStateProvider.notifier).resetAllProgress();
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All progress records have been reset'),
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

    final doctorName = appState.doctorName.isNotEmpty ? appState.doctorName : 'Doctor';
    final initialLetter = doctorName.replaceAll(RegExp(r'^(Dr\.?|Dr\s+)', caseSensitive: false), '').trim();
    final avatarLetter = initialLetter.isNotEmpty ? initialLetter[0].toUpperCase() : 'D';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: Colors.white,
        borderRadius: 20,
        shadowOffset: 3,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.inkForeground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x181C1C1C),
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
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
                  doctorName,
                  style: const TextStyle(
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
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Offline Sovereign',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                size: 20, color: AppTheme.primaryBlue),
            onPressed: () => SettingsScreen.editDoctorName(context, ref.read(appStateProvider.notifier), appState.doctorName),
          ),
        ],
      ),
    );
  }
}

// ── 2. Syllabus Edition Selection ────────────────────────────────
class _SyllabusEditionSection extends ConsumerWidget {
  const _SyllabusEditionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEdition = ref.watch(appStateProvider.select((s) => s.valueOrNull?.activeEdition));
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
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
    final dayStartHour = ref.watch(appStateProvider.select((s) => s.valueOrNull?.dayStartHour ?? 5));
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'START OF THE STUDY DAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppTheme.inkForeground,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configures your daily streak rollover, focus timer resets, and desk pad boundaries',
          style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.sketchDecoration(
            backgroundColor: Colors.white,
            borderRadius: 18,
            shadowOffset: 3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                      color: isSelected ? Colors.white : AppTheme.inkForeground,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyReminderEnabled = ref.watch(appStateProvider.select((s) => s.valueOrNull?.dailyReminderEnabled ?? false));
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
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
            backgroundColor: Colors.white,
            borderRadius: 18,
            shadowOffset: 3,
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Daily Study Reminder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkForeground,
                  ),
                ),
                subtitle: const Text(
                  'Prompt to open FlowMD and hit your targets',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.mutedText),
                ),
                activeTrackColor: AppTheme.primaryBlue,
                value: dailyReminderEnabled,
                onChanged: (val) => notifier.setDailyReminder(val),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Streak at Risk Alert',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkForeground,
                  ),
                ),
                subtitle: const Text(
                  'Alert at 8:00 PM if no progress registered',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.mutedText),
                ),
                activeTrackColor: Colors.orange,
                value: true,
                onChanged: (val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Streak alerts active! More notification settings arriving in next release.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 6. Resource Hubs (Learn the App, Data & Privacy, About) ──────
class _ResourceHubsSection extends StatelessWidget {
  const _ResourceHubsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RESOURCES & SOVEREIGNTY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 12),

        // Learn the App Card
        _SleekHubCard(
          title: 'Learn the App',
          subtitle: 'Interactive guide & tips for module tracking & timer modes',
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
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.sketchDecoration(
          backgroundColor: Colors.white,
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }
}
