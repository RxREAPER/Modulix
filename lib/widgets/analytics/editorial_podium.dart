import 'package:flutter/material.dart';
import '../../models/user_rank.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import '../profile/profile_customization.dart';

/// Modern sleek, minimalist clinical podium for Top 3 doctors.
/// Features staggered heights, subtle ink borders, and pure typography with zero tags.
class EditorialPodium extends StatelessWidget {
  final LeaderboardEntry? first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;
  final ValueChanged<LeaderboardEntry>? onEntryTap;

  const EditorialPodium({
    super.key,
    this.first,
    this.second,
    this.third,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (first == null && second == null && third == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Left)
          Expanded(
            child: second != null
                ? _PodiumColumn(
                    entry: second!,
                    height: 110.0,
                    rankNumeral: '02',
                    isPeak: false,
                    accentColor: AppTheme.inkForeground.withValues(alpha: 0.65),
                    onTap: () => onEntryTap?.call(second!),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // 1st Place (Center Elevated)
          Expanded(
            child: first != null
                ? _PodiumColumn(
                    entry: first!,
                    height: 142.0,
                    rankNumeral: '01',
                    isPeak: true,
                    accentColor: AppTheme.accentPrimary,
                    onTap: () => onEntryTap?.call(first!),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // 3rd Place (Right)
          Expanded(
            child: third != null
                ? _PodiumColumn(
                    entry: third!,
                    height: 94.0,
                    rankNumeral: '03',
                    isPeak: false,
                    accentColor: AppTheme.inkForeground.withValues(alpha: 0.45),
                    onTap: () => onEntryTap?.call(third!),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final String rankNumeral;
  final bool isPeak;
  final Color accentColor;
  final VoidCallback? onTap;

  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.rankNumeral,
    required this.isPeak,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isPeak ? 54.0 : 44.0;

    return ApplePressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Doctor Avatar
          ProfileAvatar(
            size: avatarSize,
            colorId: entry.avatarColorId,
            iconId: entry.avatarIconId,
            doctorName: entry.displayName,
          ),
          const SizedBox(height: 8),

          // Display Name
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isPeak ? 13.5 : 12.0,
              fontWeight: entry.isCurrentUser ? FontWeight.w700 : FontWeight.w600,
              color: entry.isCurrentUser ? AppTheme.accentPrimary : AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 2),

          // Formatted Time Duration
          Text(
            entry.formattedDuration,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isPeak ? 13.0 : 11.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: AppTheme.inkForeground.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),

          // Minimalist Paper Pedestal
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(
                color: isPeak
                    ? AppTheme.accentPrimary.withValues(alpha: 0.5)
                    : AppTheme.cardBorder,
                width: isPeak ? 1.4 : 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.inkForeground.withValues(alpha: 0.08),
                  offset: Offset(0, isPeak ? 4 : 2),
                  blurRadius: isPeak ? 8 : 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                if (isPeak)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 3,
                    child: Container(
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                Center(
                  child: Text(
                    rankNumeral,
                    style: TextStyle(
                      fontFamily: 'EBGaramond',
                      fontSize: isPeak ? 38 : 28,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: accentColor.withValues(alpha: 0.8),
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
