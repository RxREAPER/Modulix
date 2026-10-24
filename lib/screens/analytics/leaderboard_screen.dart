import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_rank.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analytics/editorial_podium.dart';
import '../../widgets/analytics/personal_standing_dock.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/rank_badge.dart';

/// Modulix Medical Arena & Competitive Leaderboard Screen.
/// Displays Top 20 standings across Daily, Weekly, and All-Time scales,
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
    final appState = ref.watch(appStateProvider).value;
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
          'Medical Arena',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Leaderboard Identity',
            icon: Icon(Icons.edit_outlined, size: 20, color: AppTheme.inkForeground),
            onPressed: () => _showIdentitySheet(context, appState?.publicDisplayName ?? 'Dr. Colleague'),
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
                // ── 1. Tactile 3-Way Spring Switcher ─────────────────────────
                _TactileScaleSwitcher(
                  activeScale: activeScale,
                  onScaleChanged: (scale) {
                    HapticFeedback.selectionClick();
                    ref.read(leaderboardProvider.notifier).switchScale(scale);
                  },
                ),
                const SizedBox(height: 16),

                // ── 2. Doctor Personal Standing & Career Level Card ──────────
                _DoctorStandingCard(
                  standing: standing,
                  displayName: appState?.publicDisplayName ?? 'Dr. Colleague',
                  onEditName: () => _showIdentitySheet(
                    context,
                    appState?.publicDisplayName ?? 'Dr. Colleague',
                  ),
                ),
                const SizedBox(height: 20),

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
                          'TOP 20 CONTENDERS',
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

  void _showIdentitySheet(BuildContext context, String currentName) {
    final appState = ref.read(appStateProvider).value;
    final controller = TextEditingController(text: currentName);
    bool isAnon = appState?.isLeaderboardAnonymous ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppTheme.cardBorder, width: 0.8),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Arena Public Identity',
                style: AppTheme.headingStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Your display name visible on the global medical leaderboard.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                enabled: !isAnon,
                style: TextStyle(fontSize: 14.5, color: AppTheme.inkForeground),
                decoration: InputDecoration(
                  labelText: 'Public Display Name',
                  labelStyle: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                  filled: true,
                  fillColor: AppTheme.paperBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.cardBorder, width: 0.8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.accentPrimary, width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Anonymous Mode',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.inkForeground),
                ),
                subtitle: Text(
                  'Appear as "Dr. Anonymous" on all leaderboards',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.mutedText),
                ),
                value: isAnon,
                activeThumbColor: AppTheme.accentPrimary,
                onChanged: (val) {
                  setSheetState(() => isAnon = val);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.inkForeground,
                    foregroundColor: AppTheme.paperBackground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final newName = controller.text.trim();
                    if (appState != null) {
                      final updated = appState.copyWith(
                        leaderboardDisplayName: newName.isNotEmpty ? newName : null,
                        isLeaderboardAnonymous: isAnon,
                      );
                      await StorageService.instance.save(updated);
                      ref.read(appStateProvider.notifier).updateState(updated);
                      ref.read(leaderboardProvider.notifier).refreshStandings();
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Public Handle', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tactile spring sliding switcher for 3 scales: Daily, Weekly, All Time
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
                      fontSize: 12.5,
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

/// Doctor Personal Standing & Career Level Card
class _DoctorStandingCard extends StatelessWidget {
  final UserStanding standing;
  final String displayName;
  final VoidCallback onEditName;

  const _DoctorStandingCard({
    required this.standing,
    required this.displayName,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final level = standing.level;
    final progress = level.progressToNext(standing.totalSeconds);
    final remainingSecs = level.secondsRemainingToNext(standing.totalSeconds);
    final remainingHours = (remainingSecs / 3600.0).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkForeground.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name and Level Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onEditName,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 14, color: AppTheme.mutedText),
                  ],
                ),
              ),
              RankBadge(
                level: level,
                showTitle: true,
                fontSize: 11.5,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Standing Metrics
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT RANK',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '#${standing.rank}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIME STUDIED',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    standing.formattedDuration,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: AppTheme.inkForeground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (standing.isInTop20)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Top 20 Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 3: Level Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.5,
              backgroundColor: AppTheme.paperBackground,
              valueColor: AlwaysStoppedAnimation(AppTheme.accentPrimary),
            ),
          ),
          const SizedBox(height: 6),

          // Promotion text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                level.subtitle,
                style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
              ),
              if (level.nextLevel != null)
                Text(
                  '${remainingHours}h to ${level.nextLevel!.title}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkForeground,
                  ),
                )
              else
                Text(
                  'Highest Tier Achieved',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentPrimary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
