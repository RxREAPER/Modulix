import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class PaceEngineAnimationWidget extends StatefulWidget {
  const PaceEngineAnimationWidget({super.key});

  @override
  State<PaceEngineAnimationWidget> createState() =>
      _PaceEngineAnimationWidgetState();
}

class _PaceEngineAnimationWidgetState extends State<PaceEngineAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value; // 0.0 to 1.0

        // Phase 1 (0.0 to 0.30): Pace slow (2.0 v/d), BEHIND
        // Phase 2 (0.30 to 0.65): Target adjusts up to 4.5 v/d
        // Phase 3 (0.65 to 1.00): ON TRACK, suggested batch active

        final double sliderProgress = t < 0.30
            ? 0.0
            : (t < 0.65 ? (t - 0.30) / 0.35 : 1.0);

        final double vPerDay = 2.0 + 2.5 * sliderProgress;
        final bool isOnTrack = sliderProgress > 0.6;
        final double progress = 0.58 + 0.18 * sliderProgress;

        return Container(
          height: 195,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.sketchBorderColor, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x221C1C1C),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FlowMD StudyPlanAnalyticsSheet Header + Ring + Target Info
              Row(
                children: [
                  // Real FlowMD Circular Progress Ring
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                              isOnTrack ? AppTheme.primaryBlue : Colors.orange),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TARGET: 15 NOV 2026',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '142 / 180',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        Text(
                          'Videos completed · ${(vPerDay).toStringAsFixed(1)} v/day configured',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Exact FlowMD ETA & Pace Banner from StudyPlanAnalyticsSheet
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: (isOnTrack ? Colors.green : Colors.orange).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnTrack ? Colors.green : Colors.orange,
                    width: 1.3,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnTrack ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      color: isOnTrack ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnTrack ? 'On Track · Pace: 4.5 v/day' : 'Behind Pace · Need 4.5 v/day',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: isOnTrack ? Colors.green.shade800 : Colors.orange.shade900,
                            ),
                          ),
                          Text(
                            isOnTrack
                                ? 'Projected Finish: 15 Nov 2026 (On schedule)'
                                : 'Estimated Delay: 9 days (Recalibrating...)',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: isOnTrack ? Colors.green.shade700 : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Real Daily Suggested Batch Preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.playlist_play_rounded, size: 14, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOnTrack
                            ? 'Daily suggested batch dynamically generated on study desk'
                            : 'Adjust videos per day to restore On Track status',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isOnTrack ? AppTheme.inkForeground : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
