import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/feedback/modulix_toast.dart';
import '../../widgets/timer/battery_optimization_sheet.dart';

/// Minimalist Notifications Sub-page.
/// Features a soft-ask permission banner, clean On/Off toggles for timer alarms and
/// daily study routines, delivery test button, and hardware battery optimization.
class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  bool _hasPermission = true;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.hasPermission();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    HapticFeedback.mediumImpact();
    final granted = await NotificationService.instance.requestPermissions();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (granted) {
        ModulixToast.showSuccess(
          context,
          message: 'Notification permission granted',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;
    final appState = ref.watch(appStateProvider).valueOrNull;
    final notifier = ref.read(appStateProvider.notifier);

    if (appState == null) {
      return Scaffold(
        backgroundColor: activeTheme.scaffoldBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          'Notifications',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: activeTheme.inkForeground,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
        children: [
          // Soft-ask Permission Banner (shown if system notifications are disabled)
          if (!_checkingPermission && !_hasPermission && !kIsWeb && Platform.isAndroid) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: activeTheme.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 20,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Notifications Disabled',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: activeTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Device notifications are currently turned off. Enable them so your focus timer chimes and study targets reach you on time.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: activeTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ApplePressable(
                    onTap: _requestPermission,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Allow Notifications',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Section 1: Focus & Break Timer
          Text(
            'FOCUS & BREAK TIMER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: activeTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.0),
            ),
            child: Column(
              children: [
                _ToggleRow(
                  title: 'Timer Alarms & Sound',
                  subtitle: 'High-priority chime when focus blocks and breaks finish',
                  value: appState.focusTimerAlertsEnabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    notifier.setFocusTimerAlerts(val);
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: activeTheme.borderSubtle),
                _ToggleRow(
                  title: 'Live Shade Stopwatch',
                  subtitle: 'Ongoing timer countdown in notification drawer while studying',
                  value: appState.liveTimerNotificationEnabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    notifier.setLiveTimerNotification(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 2: Daily Study Routine
          Text(
            'DAILY STUDY ROUTINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: activeTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.0),
            ),
            child: Column(
              children: [
                _ToggleRow(
                  title: 'Morning Study Kickoff',
                  subtitle: 'Daily 08:30 AM prompt to start your curriculum targets',
                  value: appState.dailyReminderEnabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    notifier.setDailyReminder(val);
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: activeTheme.borderSubtle),
                _ToggleRow(
                  title: 'Evening Streak Guard',
                  subtitle: 'Smart 08:30 PM alert suppressed automatically if already studied',
                  value: appState.streakReminderEnabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    notifier.setStreakReminder(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 3: Diagnostics & Reliability
          Text(
            'DIAGNOSTICS & RELIABILITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: activeTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.0),
            ),
            child: Column(
              children: [
                ApplePressable(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await NotificationService.instance.sendTestNotification(
                      doctorName: appState.doctorName,
                    );
                    if (context.mounted) {
                      ModulixToast.showSuccess(
                        context,
                        message: 'Test notification dispatched',
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          color: AppTheme.accentPrimary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Send Test Notification',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: activeTheme.inkForeground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Verify instant delivery and sound on your hardware',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: activeTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.send_rounded,
                          size: 16,
                          color: activeTheme.mutedText,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: activeTheme.borderSubtle),
                ApplePressable(
                  onTap: () => BatteryOptimizationSheet.show(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.battery_charging_full_rounded,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Battery Optimization',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: activeTheme.inkForeground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prevent OnePlus, Xiaomi and Samsung from killing background timers',
                                style: TextStyle(
                                  fontSize: 12,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: activeTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: activeTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppTheme.accentPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
