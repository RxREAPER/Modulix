import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/tour/app_tour_controller.dart';

/// Interactive Spotlight Overlay that highlights active targets across Modulix
class TourSpotlightOverlay extends ConsumerStatefulWidget {
  const TourSpotlightOverlay({super.key});

  /// Calculate strict non-overlapping card top coordinate
  static double calculateCardTop({
    required Size screenSize,
    required List<Rect> targetRects,
    bool? preferTopCard,
  }) {
    const double estimatedCardHeight = 190.0;
    const double safeTop = 56.0;
    const double safeBottom = 90.0;

    if (targetRects.isEmpty) {
      return (preferTopCard ?? false)
          ? safeTop
          : screenSize.height - estimatedCardHeight - safeBottom;
    }

    final minTargetTop =
        targetRects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
    final maxTargetBottom =
        targetRects.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);

    // If explicit preferTopCard is specified:
    if (preferTopCard == true) {
      return safeTop;
    }
    if (preferTopCard == false) {
      return maxTargetBottom + 14.0;
    }

    // If target is in the upper area (minTargetTop < 320.0), place strictly below target:
    if (minTargetTop < 320.0) {
      return maxTargetBottom + 14.0;
    }

    // Target is lower down (minTargetTop >= 320.0), place strictly at top safe area:
    return safeTop;
  }

  @override
  ConsumerState<TourSpotlightOverlay> createState() => _TourSpotlightOverlayState();
}

class _TourSpotlightOverlayState extends ConsumerState<TourSpotlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tourState = ref.watch(appTourProvider);
    if (!tourState.isActive) {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
      return const SizedBox.shrink();
    }

    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    final stepData = tourState.currentStepData;
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final liveTargets = TourTargetRegistry.getRects(stepData.targetIds);
        return Stack(
          children: [
            // ── 1. SPOTLIGHT CANVAS (DARK BACKDROP WITH CUTOUTS) ─────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Absorb accidental touches outside the card
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    screenSize: screenSize,
                    targets: liveTargets,
                    pulseValue: _pulseController.value,
                  ),
                ),
              ),
            ),

            // ── 2. GUIDED WALKTHROUGH CARD ──────────────────────────────────────
            _buildTourCard(context, stepData, screenSize, tourState, liveTargets),
          ],
        );
      },
    );
  }

  Widget _buildTourCard(
    BuildContext context,
    TourStepData stepData,
    Size screenSize,
    TourState tourState,
    List<Rect> targetRects,
  ) {
    // Determine strict non-overlapping placement so the card never covers highlighted targets
    final cardTop = TourSpotlightOverlay.calculateCardTop(
      screenSize: screenSize,
      targetRects: targetRects,
      preferTopCard: stepData.preferTopCard,
    );

    final progressRatio =
        (tourState.currentStepIndex + 1) / kTourSteps.length;

    return Positioned(
      left: 18.0,
      right: 18.0,
      top: cardTop,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xF20F172A), // Dark slate glass
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x602DD4BF), // Neon turquoise border
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x90000000),
                offset: Offset(0, 10),
                blurRadius: 28,
              ),
              BoxShadow(
                color: Color(0x202DD4BF),
                offset: Offset(0, 0),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Step Tag & Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x202DD4BF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF2DD4BF),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'STEP ${tourState.currentStepIndex + 1} OF ${kTourSteps.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                  ),
                  Text(
                    stepData.category,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Linear Progress Line
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progressRatio,
                  minHeight: 2.5,
                  backgroundColor: const Color(0x25FFFFFF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                ),
              ),

              const SizedBox(height: 10),

              // 2. Title (Line 1 of content)
              Text(
                stepData.title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 4),

              // 3. Description (Lines 2 & 3 of content: concise 2-line explanation)
              Text(
                stepData.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.0,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade300,
                ),
              ),

              // 4. Interactive Action Button (if applicable)
              if (stepData.interactiveActionLabel != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: tourState.isActionRunning
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(appTourProvider.notifier)
                                .runStepInteractiveAction(context);
                          },
                    icon: tourState.isActionRunning
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0F172A),
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(
                      tourState.isActionRunning
                          ? 'Demonstrating...'
                          : stepData.interactiveActionLabel!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // 5. Navigation Controls: Skip Tour, Back, Next / Finish
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(appTourProvider.notifier).endTour(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Skip Tour',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!tourState.isFirstStep) ...[
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(appTourProvider.notifier).prevStep(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade600),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(appTourProvider.notifier).nextStep(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tourState.isLastStep ? 'Finish' : 'Next',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          tourState.isLastStep
                              ? Icons.done_all_rounded
                              : Icons.arrow_forward_rounded,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter that renders darkened backdrop with multiple cutout spotlights
class _SpotlightPainter extends CustomPainter {
  final Size screenSize;
  final List<Rect> targets;
  final double pulseValue;

  _SpotlightPainter({
    required this.screenSize,
    required this.targets,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Compute composite cutout path (Screen minus target shapes)
    Path cutoutPath = Path()..addRect(screenRect);

    final List<RRect> rrects = [];
    for (final target in targets) {
      // Clamp to screen bounds so lines don't bleed off-screen
      final clamped = target.intersect(screenRect);
      if (clamped.width <= 0 || clamped.height <= 0) continue;

      // Hug the target closely with 3.0px padding so lines don't overlay adjacent features
      final inflated = clamped.inflate(3.0);
      final rrect = RRect.fromRectAndRadius(
        inflated,
        const Radius.circular(16),
      );
      rrects.add(rrect);
      cutoutPath = Path.combine(
        PathOperation.difference,
        cutoutPath,
        Path()..addRRect(rrect),
      );
    }

    // 2. Draw darkened backdrop
    final backdropPaint = Paint()
      ..color = const Color(0xCC050814) // Deep midnight black with 80% opacity
      ..style = PaintingStyle.fill;
    canvas.drawPath(cutoutPath, backdropPaint);

    // 3. Draw glowing pulsing neon borders around highlighted targets
    final glowAlpha = (0.50 + 0.50 * pulseValue).clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final rrect in rrects) {
      canvas.drawRRect(rrect, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.targets.length != targets.length ||
        oldDelegate.screenSize != screenSize;
  }
}
