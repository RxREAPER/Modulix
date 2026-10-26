import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

class StudyPlanBanner extends StatelessWidget {
  final StudyPlan plan;

  const StudyPlanBanner({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final isConfigured = plan.isConfigured;
    final isDark = AppTheme.current.isDark;

    return ApplePressable(
      onTap: () => context.push('/plan'),
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF1D4ED8), // Deep Royal Blue
                    Color(0xFF4338CA), // Deep Indigo
                    Color(0xFF6D28D9), // Deep Violet
                  ]
                : const [
                    Color(0xFF3B82F6), // Vibrant Blue
                    Color(0xFF6366F1), // Indigo
                    Color(0xFF8B5CF6), // Purple
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : AppTheme.sketchBorderColor,
            width: isDark ? 1.2 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Sparkle Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFFDF7D),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Text Content - full rendering without text clipping
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Module-Based Plan',
                        style: AppTypography.cardTitle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isConfigured ? 'ACTIVE' : 'SETUP',
                          style: AppTypography.microBadge(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isConfigured
                        ? 'Target pace & automated daily modules'
                        : 'Set exam deadline & daily module targets',
                    style: AppTypography.cardSubtitle(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Forward circular action button (Fully adaptive to light & dark mode)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white,
                shape: BoxShape.circle,
                border: isDark
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.0,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: isDark ? Colors.white : const Color(0xFF2563EB),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
      }
    }
