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

    return ApplePressable(
      onTap: () => context.push('/plan'),
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3B82F6), // Vibrant Blue
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.sketchBorderColor, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x301C1C1C),
              offset: Offset(3.5, 4.5),
              blurRadius: 0,
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

                // Forward circular action button
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x20000000),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.inkForeground,
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
