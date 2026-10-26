import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable Shimmer Container providing smooth glowing animations for loading skeletons.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? const Color(0xFFE5E7EB);
    final highlight = widget.highlightColor ?? const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
              colors: [
                base,
                highlight,
                base,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Simple rounded shimmer placeholder box.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer skeleton for Curriculum MBBS subject list.
class CurriculumSkeletonView extends StatelessWidget {
  const CurriculumSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight, width: 1.2),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 40, height: 40, borderRadius: 10),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 140, height: 16, borderRadius: 4),
                          SizedBox(height: 6),
                          ShimmerBox(width: 90, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                    ShimmerBox(width: 48, height: 22, borderRadius: 12),
                  ],
                ),
                SizedBox(height: 14),
                ShimmerBox(height: 6, borderRadius: 3),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton for Subject / Chapter lecture timeline.
class ModuleTimelineSkeletonView extends StatelessWidget {
  const ModuleTimelineSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight, width: 1.0),
            ),
            child: const Row(
              children: [
                ShimmerBox(width: 24, height: 24, borderRadius: 6),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 180, height: 15, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 100, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
                ShimmerBox(width: 32, height: 16, borderRadius: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton for Home Desk tasks.
class DeskTasksSkeletonView extends StatelessWidget {
  const DeskTasksSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 120, height: 18, borderRadius: 6),
                ShimmerBox(width: 60, height: 18, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < 3; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight, width: 1.0),
                ),
                child: const Row(
                  children: [
                    ShimmerBox(width: 20, height: 20, borderRadius: 4),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 160, height: 14, borderRadius: 4),
                          SizedBox(height: 6),
                          ShimmerBox(width: 80, height: 10, borderRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for Analytics & Study Metrics with zero Cumulative Layout Shift (CLS).
class AnalyticsSkeletonView extends StatelessWidget {
  const AnalyticsSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.paddingOf(context).bottom + 100.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Streak Cards Row (Height ~76)
            const Row(
              children: [
                Expanded(child: ShimmerBox(height: 76, borderRadius: 18)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 76, borderRadius: 18)),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Section Header
            const ShimmerBox(width: 130, height: 11, borderRadius: 4),
            const SizedBox(height: 12),

            // 3. Leaderboard Arena Special Box (Height ~72)
            const ShimmerBox(height: 72, borderRadius: 16),
            const SizedBox(height: 18),

            // 4. Four Performance Hub Cards (Height ~92 each)
            for (int i = 0; i < 4; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight, width: 1.2),
                ),
                child: const Row(
                  children: [
                    ShimmerBox(width: 44, height: 44, borderRadius: 12),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 130, height: 15, borderRadius: 4),
                          SizedBox(height: 7),
                          ShimmerBox(width: 180, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    ShimmerBox(width: 46, height: 46, borderRadius: 23),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 5. NEET Consistency Matrix (Height ~140)
            const ShimmerBox(height: 140, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}
