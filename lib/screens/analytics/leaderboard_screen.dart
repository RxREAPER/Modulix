import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_rank.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analytics/editorial_podium.dart';
import '../../widgets/analytics/personal_standing_dock.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/rank_badge.dart';
import '../../services/study_presence_service.dart';

/// Modulix Focus Leaderboard Screen.
/// Displays Top 20 standings across Daily, Weekly, Monthly, and Yearly scales,
/// 10-tier career level progress, and personal standings with zero tags.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeDataProvider);
    final leaderboardState = ref.watch(leaderboardProvider);
    final activeScale = leaderboardState.activeScale;
    final entries = leaderboardState.currentEntries;
    final standing = leaderboardState.currentStanding;

    LeaderboardEntry? first;
    LeaderboardEntry? second;
    LeaderboardEntry? third;
    List<LeaderboardEntry> listEntries = [];

    if (entries.isNotEmpty) first = entries[0];
    if (entries.length > 1) second = entries[1];
    if (entries.length > 2) third = entries[2];
    if (entries.length > 3) listEntries = entries.sublist(3);

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Focus Leaderboard',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final presence = ref.watch(studyPresenceProvider);
              final count = presence.activeDoctorsCount;
              if (count <= 0) return const SizedBox.shrink();
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count in focus',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppTheme.accentPrimary,
            backgroundColor: AppTheme.paperBackground,
            onRefresh: () => ref.read(leaderboardProvider.notifier).refreshStandings(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16, 8, 16, standing.isInTop20 ? 40 : 100),
              children: [
                // ── 1. Tactile 4-Way Spring Switcher ─────────────────────────
                _TactileScaleSwitcher(
                  activeScale: activeScale,
                  onScaleChanged: (scale) {
                    HapticFeedback.selectionClick();
                    ref.read(leaderboardProvider.notifier).switchScale(scale);
                  },
                ),
                const SizedBox(height: 12),

                // ── 2. Reset Countdown & Cycle Info Banner ───────────────────
                _ResetReminderBanner(activeScale: activeScale),
                const SizedBox(height: 16),

                // ── 3. Editorial Top 3 Podium ────────────────────────────────
                EditorialPodium(
                  first: first,
                  second: second,
                  third: third,
                ),
                const SizedBox(height: 16),

                // ── 4. Ranks 4 to 20 Section Header ──────────────────────────
                if (listEntries.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOP 20',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        Text(
                          '${activeScale.label} Standings',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── 5. Minimalist Rows (Ranks 4-20) ────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder, width: 0.8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listEntries.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppTheme.cardBorder.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final entry = listEntries[index];
                        return _LeaderboardRow(entry: entry);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── 6. Sticky Personal Standing Dock (If outside Top 20) ───────────
          if (!standing.isInTop20)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PersonalStandingDock(
                standing: standing,
                onStartFocus: () => context.push('/timer'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tactile spring sliding switcher for 4 scales: Daily, Weekly, Monthly, Yearly
class _TactileScaleSwitcher extends StatelessWidget {
  final LeaderboardScale activeScale;
  final ValueChanged<LeaderboardScale> onScaleChanged;

  const _TactileScaleSwitcher({
    required this.activeScale,
    required this.onScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: Row(
        children: LeaderboardScale.values.map((scale) {
          final isSelected = scale == activeScale;
          return Expanded(
            child: ApplePressable(
              onTap: () => onScaleChanged(scale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.inkForeground : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    scale.label,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.paperBackground : AppTheme.mutedText,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Clean Reset Reminder & Schedule Countdown Text (Not in a box)
class _ResetReminderBanner extends StatelessWidget {
  final LeaderboardScale activeScale;

  const _ResetReminderBanner({required this.activeScale});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String countdownText;
    final IconData icon;

    switch (activeScale) {
      case LeaderboardScale.daily:
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final diff = tomorrow.difference(now);
        final hours = diff.inHours;
        final mins = diff.inMinutes % 60;
        countdownText = 'Daily board resets in ${hours}h ${mins}m • Tomorrow at 12:00 AM';
        icon = Icons.access_time_rounded;
        break;

      case LeaderboardScale.weekly:
        final daysUntilMonday = ((8 - now.weekday) % 7);
        final nextMonday = DateTime(now.year, now.month, now.day + (daysUntilMonday == 0 ? 7 : daysUntilMonday));
        final diff = nextMonday.difference(now);
        final days = diff.inDays;
        final hours = diff.inHours % 24;
        final monthName = _monthAbbr(nextMonday.month);
        countdownText = 'Week ends in ${days}d ${hours}h • Resets Monday, $monthName ${nextMonday.day}';
        icon = Icons.date_range_rounded;
        break;

      case LeaderboardScale.monthly:
        final nextMonth = (now.month == 12)
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
        final diff = nextMonth.difference(now);
        final days = diff.inDays;
        final hours = diff.inHours % 24;
        final nextMonthName = _monthName(nextMonth.month);
        countdownText = 'Month ends in ${days}d ${hours}h • Resets $nextMonthName 1';
        icon = Icons.calendar_month_rounded;
        break;

      case LeaderboardScale.yearly:
        final nextYear = DateTime(now.year + 1, 1, 1);
        final diff = nextYear.difference(now);
        final days = diff.inDays;
        countdownText = 'Season ends in $days days • Resets Jan 1, ${nextYear.year}';
        icon = Icons.timer_outlined;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: AppTheme.accentPrimary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              countdownText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: AppTheme.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthAbbr(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[(month - 1).clamp(0, 11)];
  }

  static String _monthName(int month) {
    const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return m[(month - 1).clamp(0, 11)];
  }
}

/// Minimalist leaderboard row for Ranks 4 to 20
class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: entry.isCurrentUser
          ? AppTheme.accentPrimary.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Rank Numeral
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: entry.isCurrentUser
                    ? AppTheme.accentPrimary
                    : AppTheme.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Doctor Avatar
          ProfileAvatar(
            size: 26,
            colorId: entry.avatarColorId,
            iconId: entry.avatarIconId,
            doctorName: entry.displayName,
          ),
          const SizedBox(width: 10),

          // Doctor Name
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    entry.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: entry.isCurrentUser
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: entry.isCurrentUser
                          ? AppTheme.accentPrimary
                          : AppTheme.inkForeground,
                    ),
                  ),
                ),
                if (entry.isCurrentUser) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(You)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Level Micro-Badge
          RankBadge(level: entry.level, showTitle: false, fontSize: 10),
          const SizedBox(width: 14),

          // Verified Duration
          Text(
            entry.formattedDuration,
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: AppTheme.inkForeground,
            ),
          ),
        ],
      ),
    );
  }
}
