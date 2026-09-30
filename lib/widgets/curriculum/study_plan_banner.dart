import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';
import 'configure_plan_sheet.dart';

class StudyPlanBanner extends StatefulWidget {
  final StudyPlan plan;

  const StudyPlanBanner({super.key, required this.plan});

  @override
  State<StudyPlanBanner> createState() => _StudyPlanBannerState();
}

class _StudyPlanBannerState extends State<StudyPlanBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = widget.plan.isConfigured;

    return GestureDetector(
      onTap: () => ConfigurePlanSheet.show(context),
      child: AnimatedBuilder(
        animation: _sparkleController,
        builder: (context, child) {
          final t = _sparkleController.value;
          final angle = math.sin(t * math.pi * 2) * 0.15;
          final pulse = 1.0 + math.sin(t * math.pi * 2) * 0.04;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4F46E5), // Indigo
                  Color(0xFF7C3AED), // Deep Purple
                  Color(0xFFEC4899), // Pink accent
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.sketchBorderColor, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x301C1C1C),
                  offset: Offset(4, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated Sparkle Badge
                Transform.scale(
                  scale: pulse,
                  child: Transform.rotate(
                    angle: angle,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFFDF7D),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isConfigured
                                  ? '${widget.plan.targetSubject.toUpperCase()} PACING'
                                  : 'Automate Curriculum Pace',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD1D6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isConfigured ? '${widget.plan.videosPerDay ?? 0} V/D' : 'SETUP',
                              style: const TextStyle(
                                color: AppTheme.inkForeground,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isConfigured
                            ? 'Target: ${widget.plan.targetDate.isNotEmpty ? widget.plan.targetDate.split('T').first : 'Not set'} · Tap to adjust study pace'
                            : 'Set exam deadline & daily pace to track curriculum',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

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
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.inkForeground,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
