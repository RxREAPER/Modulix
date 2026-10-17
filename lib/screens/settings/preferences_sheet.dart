import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../services/notification_service.dart';
import 'appearance_theme_sheet.dart';
import '../../widgets/animations/apple_pressable.dart';

class PreferencesSheet extends ConsumerWidget {
  const PreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const PreferencesSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final appState = appStateAsync.value;

    if (appState == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppTheme.paperBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final notifier = ref.read(appStateProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          left: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          right: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
                  ),
                  child: Icon(Icons.tune_rounded,
                      color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUSTOMIZATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.borderLight),

          // Body
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // ── 1. Profile Section ─────────────────────────────────────
                Text(
                  'PROFILE & CURRICULUM SOURCE',
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
                      // Doctor Name Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.parchmentSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.person_rounded,
                                size: 18, color: AppTheme.inkForeground),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Doctor Name',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.mutedText)),
                                Text(
                                  appState.doctorName,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.inkForeground),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                size: 18, color: AppTheme.primaryBlue),
                            onPressed: () => _editDoctorName(
                                context, notifier, appState.doctorName),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppTheme.borderLight),
                      ),
                      // Active Edition Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.parchmentSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                size: 18, color: AppTheme.inkForeground),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Syllabus Edition',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.mutedText)),
                                Text(
                                  'Curriculum source data',
                                  style: TextStyle(
                                      fontSize: 12, color: AppTheme.mutedText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _pillChoice(
                              label: 'Marrow Edition 8',
                              selected: appState.activeEdition == 'marrow_8',
                              onTap: () => notifier.switchEdition('marrow_8'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pillChoice(
                              label: 'Marrow Edition 6.5',
                              selected: appState.activeEdition == 'marrow_6_5',
                              onTap: () => notifier.switchEdition('marrow_6_5'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 2. Theme & Appearance ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'THEME & APPEARANCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => AppearanceThemeSheet.show(context),
                      child: Text(
                        'Theme Studio →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ApplePressable(
                  pressedScale: 0.98,
                  onTap: () => AppearanceThemeSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: AppTheme.cardWhite,
                      borderRadius: 16,
                      shadowOffset: 2,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: PalettePreset.fromId(appState.palettePresetId).scaffoldBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: PalettePreset.fromId(appState.palettePresetId).borderSubtle,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AccentPigment.fromId(appState.accentColorId).color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                PalettePreset.fromId(appState.palettePresetId).label,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Accent: ${AccentPigment.fromId(appState.accentColorId).label} · ${appState.themePref.name.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.mutedText,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── 3. Start of the Day (Study Rhythm) ─────────────────────
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
                  'Calculates your daily streaks, focus timer resets, and desk pad boundaries',
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
                              const Icon(Icons.wb_twilight_rounded,
                                  size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
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
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Colors.orange, width: 1.2),
                            ),
                            child: Text(
                              '${appState.dayStartHour}:00 AM',
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
                          final isSelected = appState.dayStartHour == hour;
                          return ChoiceChip(
                            label: Text('${hour}:00 AM'),
                            selected: isSelected,
                            onSelected: (_) => notifier.setDayStartHour(hour),
                            selectedColor: AppTheme.inkForeground,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.paperBackground
                                  : AppTheme.inkForeground,
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

                const SizedBox(height: 24),

                // ── 4. Notifications Corner ────────────────────────────────
                Text(
                  'NOTIFICATIONS & REMINDERS',
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
                      // Permission banner
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
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () async {
                                      await NotificationService.instance
                                          .sendTestNotification(
                                              doctorName: appState.doctorName);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Test notification sent!'),
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
                                border: Border.all(
                                    color: Colors.amber.shade700, width: 1),
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
                                      color: AppTheme.primaryBlue
                                          .withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        size: 14, color: AppTheme.primaryBlue),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatTimeStr(
                                          appState.studyReminderTime),
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
                                  border: Border.all(
                                      color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 14, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatTimeStr(
                                          appState.streakReminderTime),
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
                                  border: Border.all(
                                      color: Colors.teal.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 14, color: Colors.teal),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatTimeStr(
                                          appState.moduleTasksReminderTime),
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
                            onChanged: (val) =>
                                notifier.setModuleTasksReminder(val),
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
                            onChanged: (val) =>
                                notifier.setFocusTimerAlerts(val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _pillChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ApplePressable(
      pressedScale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.inkForeground : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.inkForeground : AppTheme.borderLight,
            width: 1.4,
          ),
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

  void _editDoctorName(
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
}
