import 'package:flutter/material.dart';
import '../../models/user_rank.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import '../rank_badge.dart';

/// Minimalist, unboxed sticky dock displaying personal rank, study hours,
/// and gap to enter Top 20 when user is ranked > 20.
class PersonalStandingDock extends StatelessWidget {
  final UserStanding standing;
  final VoidCallback onStartFocus;

  const PersonalStandingDock({
    super.key,
    required this.standing,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.cardBorder,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkForeground.withValues(alpha: 0.08),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 16, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Rank Display
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YOUR STANDING',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${standing.rank}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    RankBadge(
                      level: standing.level,
                      showTitle: false,
                      fontSize: 10.5,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Vertical divider
            Container(
              height: 32,
              width: 0.8,
              color: AppTheme.cardBorder,
            ),
            const SizedBox(width: 14),

            // Total Focus Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FOCUS DURATION',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${standing.formattedDuration} studied',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: AppTheme.inkForeground,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Focus Timer Start Action
            ApplePressable(
              onTap: onStartFocus,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.inkForeground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: AppTheme.paperBackground,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
