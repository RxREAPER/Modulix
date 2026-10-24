import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/focus_timer_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';

class NotificationsPreferencesScreen extends ConsumerWidget {
  const NotificationsPreferencesScreen({super.key});

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

    if (appState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dayStartHour = appState.dayStartHour;

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications & Preferences',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          // Section 1: Day Start & Rollover Boundary
          Text(
            'DUTY ROLLOVER BOUNDARY',
            style: AppTypography.sectionMicroHeader(
              fontSize: 10.5,
              letterSpacing: 1.1,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.wb_twilight_rounded,
                              size: 16, color: Colors.orange),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Day Start & Rollover',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$dayStartHour:00 AM',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Preserves late night post-duty study sessions on the previous day until this hour.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [3, 4, 5, 6, 7].map((hour) {
                    final selected = dayStartHour == hour;
                    return ChoiceChip(
                      label: Text(
                        '$hour:00 AM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                          color: selected
                              ? AppTheme.paperBackground
                              : AppTheme.inkForeground,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppTheme.inkForeground,
                      backgroundColor: AppTheme.parchmentSurface,
                      showCheckmark: selected,
                      checkmarkColor: AppTheme.paperBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: selected
                              ? AppTheme.inkForeground
                              : AppTheme.borderLight,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) notifier.setDayStartHour(hour);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Notifications & Reminder Alerts
          Text(
            'REMINDERS & ALERTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Notification Status & Test Button
                Builder(
                  builder: (context) {
                    final anyEnabled = appState.dailyReminderEnabled ||
                        appState.streakReminderEnabled ||
                        appState.moduleTasksReminderEnabled ||
                        appState.focusTimerAlertsEnabled;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              anyEnabled
                                  ? Icons.check_circle_rounded
                                  : Icons.notifications_off_outlined,
                              size: 16,
                              color: anyEnabled
                                  ? Colors.green
                                  : AppTheme.mutedText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              anyEnabled
                                  ? 'Notifications Active'
                                  : 'Notifications Paused',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: anyEnabled
                                    ? Colors.green
                                    : AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            await NotificationService.instance.sendTestNotification(
                              doctorName: appState.doctorName,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification dispatched'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.notifications_active_outlined,
                              size: 14, color: AppTheme.mutedText),
                          label: Text(
                            'Test',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 14),

                // 1. Daily Study Reminder
                _NotificationRow(
                  title: 'Daily Study Reminder',
                  subtitle: 'Prompt to start your syllabus goals',
                  enabled: appState.dailyReminderEnabled,
                  timeDisplay: _formatTimeStr(appState.studyReminderTime),
                  onToggle: (val) => notifier.setDailyReminder(val),
                  onPickTime: () => _pickTime(
                    context,
                    appState.studyReminderTime,
                    (newTime) => notifier.setStudyReminderTime(newTime),
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 14),

                // 2. Streak at Risk Alert
                _NotificationRow(
                  title: 'Streak at Risk Alert',
                  subtitle: 'Evening alert if no progress made today',
                  enabled: appState.streakReminderEnabled,
                  timeDisplay: _formatTimeStr(appState.streakReminderTime),
                  accentColor: Colors.amber.shade800,
                  onToggle: (val) => notifier.setStreakReminder(
                    val,
                    appState.streakReminderTime,
                  ),
                  onPickTime: () => _pickTime(
                    context,
                    appState.streakReminderTime,
                    (newTime) => notifier.setStreakReminder(true, newTime),
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 14),

                // 3. Module Daily Tasks Queue
                _NotificationRow(
                  title: 'Module Daily Tasks Queue',
                  subtitle: 'Morning queue briefing & goal completion',
                  enabled: appState.moduleTasksReminderEnabled,
                  timeDisplay: _formatTimeStr(appState.moduleTasksReminderTime),
                  accentColor: Colors.teal,
                  onToggle: (val) => notifier.setModuleTasksReminder(
                    val,
                    appState.moduleTasksReminderTime,
                  ),
                  onPickTime: () => _pickTime(
                    context,
                    appState.moduleTasksReminderTime,
                    (newTime) => notifier.setModuleTasksReminder(true, newTime),
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 14),

                // 4. Focus Timer Alerts & Sound
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus Timer Alerts & Sound',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Alerts for session completions and rest intervals',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: appState.focusTimerAlertsEnabled,
                      activeTrackColor: AppTheme.primaryBlue,
                      onChanged: (val) => notifier.setFocusTimerAlerts(val),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 14),

                // 5. Keep Screen Awake During Focus
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep Screen Awake During Focus',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Prevents device screen from sleeping while timer or flip clock is running',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: ref.watch(focusTimerProvider.select((s) => s.keepScreenAwake)),
                      activeTrackColor: AppTheme.primaryBlue,
                      onChanged: (val) => ref.read(focusTimerProvider.notifier).setKeepScreenAwake(val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final String timeDisplay;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;
  final Color? accentColor;

  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.timeDisplay,
    required this.onToggle,
    required this.onPickTime,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = accentColor ?? AppTheme.primaryBlue;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ApplePressable(
          onTap: enabled ? onPickTime : null,
          pressedScale: 0.94,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: enabled
                  ? chipColor.withValues(alpha: 0.1)
                  : AppTheme.parchmentSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? chipColor.withValues(alpha: 0.3)
                    : AppTheme.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: enabled ? chipColor : AppTheme.mutedText,
                ),
                const SizedBox(width: 4),
                Text(
                  timeDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: enabled ? chipColor : AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: enabled,
          activeTrackColor: chipColor,
          onChanged: onToggle,
        ),
      ],
    );
  }
}
