import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../theme/modulix_theme.dart';

class AppGuideScreen extends ConsumerWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = context.modulixTheme;

    return Scaffold(
      backgroundColor: activeTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: activeTheme.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: activeTheme.inkForeground.withValues(alpha: 0.1),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: activeTheme.inkForeground,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'App Guide & Reference',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: activeTheme.inkForeground,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          // Header Subtitle
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARCHITECTURAL PILLARS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: activeTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Comprehensive reference manual for Modulix study tools, pacing workflows, and clinical tracking systems.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: activeTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),

          // Interactive App Tour Launcher Banner
          _InteractiveTourBanner(
            onStartTour: () {
              HapticFeedback.mediumImpact();
              ref.read(appTourProvider.notifier).startTour(context);
            },
          ),
          const SizedBox(height: 18),

          // 1. Focus Timer Suite
          _GuideFeatureCard(
            category: 'FOCUS SUITE',
            title: 'Focus Timer Suite',
            icon: Icons.timer_outlined,
            accentColor: const Color(0xFFEA580C),
            previewAssetPath: 'assets/gifs/guide_timer.webp',
            bullets: const [
              'Pomodoro intervals with customizable study blocks and structured rest breaks.',
              'Dynamic live wallpapers and ambient soundscapes to induce deep focus.',
              'Dedicated task-linked clocks and quick presets for rapid session initiation.',
              'Floating mini-dock and landscape flip clock for distraction-free desk study.',
            ],
            actionLabel: 'Launch Focus Timer',
            onActionPressed: () {
              HapticFeedback.lightImpact();
              context.push('/timer');
            },
          ),
          const SizedBox(height: 16),

          // 2. Tasks & Projects Management
          _GuideFeatureCard(
            category: 'TASK ENGINE',
            title: 'Tasks & Projects Management',
            icon: Icons.check_circle_outline_rounded,
            accentColor: const Color(0xFF2563EB),
            previewAssetPath: 'assets/gifs/guide_tasks.webp',
            bullets: const [
              'Daily desk tasks categorized by clinical modalities: MCQ, Revision, Notes, Video.',
              'Project and stream grouping for focused clerkship, clinical wards, and Grand Tests.',
              'Tactile haptic checkoff feedback with instant progress bar calculation.',
              '5:00 AM study day boundary ensuring late-night sessions log to the correct study date.',
            ],
            actionLabel: 'Manage Tasks & Projects',
            onActionPressed: () {
              HapticFeedback.lightImpact();
              context.push('/daily-tasks');
            },
          ),
          const SizedBox(height: 16),

          // 3. Module Planner & Deadlines
          _GuideFeatureCard(
            category: 'PACING ENGINE',
            title: 'Module Planner & Deadlines',
            icon: Icons.auto_graph_rounded,
            accentColor: const Color(0xFF7C3AED),
            previewAssetPath: 'assets/gifs/guide_planner.webp',
            bullets: const [
              'Set high-stakes exam targets including NEET-PG, INI-CET, and University finals.',
              'Dynamic daily module quotas with automatic recalibration if study days are missed.',
              'Home desk suggested module queue advances in real time as items complete.',
              'Accurate finish ETA projections preventing last-minute curriculum crunches.',
            ],
            actionLabel: 'Open Module Planner',
            onActionPressed: () {
              HapticFeedback.lightImpact();
              context.push('/plan');
            },
          ),
          const SizedBox(height: 16),

          // 4. Syllabus & Curriculum Tracker
          _GuideFeatureCard(
            category: 'CURRICULUM',
            title: 'Syllabus & Curriculum Tracker',
            icon: Icons.menu_book_rounded,
            accentColor: const Color(0xFF0D9488),
            previewAssetPath: 'assets/gifs/guide_curriculum.webp',
            bullets: const [
              'Multi-track support for standard Edition 8 (848 modules) and classic Edition 6.5 (792 modules).',
              'Comprehensive 19 MBBS subjects structured with units, chapters, and high-yield topics.',
              'Tri-modal completion tracking across Videos, Q-Banks, and Revision Notes.',
              'Single-tap bulk completion to quickly synchronize your existing offline progress.',
            ],
            actionLabel: 'Browse Curriculum',
            onActionPressed: () {
              HapticFeedback.lightImpact();
              context.go('/curriculum');
            },
          ),
          const SizedBox(height: 16),

          // 5. Global Focus Leaderboard
          _GuideFeatureCard(
            category: 'GLOBAL ARENA',
            title: 'Global Focus Leaderboard',
            icon: Icons.leaderboard_outlined,
            accentColor: const Color(0xFFD97706),
            previewAssetPath: 'assets/gifs/guide_leaderboard.webp',
            bullets: const [
              'Real Doctor Name identity with deterministic non-colliding fallback handles.',
              'Verified focus tracking across Daily, Weekly, Monthly, and All-Time leaderboards.',
              'Podium recognition with golden crowns and study streak milestones.',
              'Strict anti-cheat verification guaranteeing genuine medical aspirant standings.',
            ],
            actionLabel: 'View Leaderboard',
            onActionPressed: () {
              HapticFeedback.lightImpact();
              context.push('/analytics/leaderboard');
            },
          ),
          const SizedBox(height: 16),

          // 6. Cloud Sync & Data Sovereignty
          _GuideFeatureCard(
            category: 'DURABILITY & SYNC',
            title: 'Cloud Sync & Data Sovereignty',
            icon: Icons.cloud_sync_outlined,
            accentColor: const Color(0xFF059669),
            previewAssetPath: 'assets/gifs/guide_sync.webp',
            bullets: const [
              '100% offline-first durability powered by high-performance local SQLite storage.',
              'Linear append-only SQLite outbox queues modifications safely without data loss.',
              'Instantaneous Google account synchronization across all connected mobile devices.',
              'Full manual backup export and import for complete personal data ownership.',
            ],
            actionLabel: 'Account & Sync Settings',
            onActionPressed: () {
              HapticFeedback.lightImpact();
              context.push('/settings/account');
            },
          ),
        ],
      ),
    );
  }
}

// Interactive Tour Launcher Banner
class _InteractiveTourBanner extends StatelessWidget {
  final VoidCallback onStartTour;

  const _InteractiveTourBanner({required this.onStartTour});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onStartTour,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0x202DD4BF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: Color(0xFF2DD4BF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Interactive App Tour',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Guided live spotlight tour across all 7 core study screens',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF2DD4BF),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Feature Card Component
class _GuideFeatureCard extends StatelessWidget {
  final String category;
  final String title;
  final IconData icon;
  final Color accentColor;
  final String previewAssetPath;
  final List<String> bullets;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const _GuideFeatureCard({
    required this.category,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.previewAssetPath,
    required this.bullets,
    required this.actionLabel,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: activeTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activeTheme.borderSubtle.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: activeTheme.inkForeground,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Micro-Loop Preview Container
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: activeTheme.borderSubtle.withValues(alpha: 0.15),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 2.0,
                child: Image.asset(
                  previewAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: activeTheme.mutedText.withValues(alpha: 0.08),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 32,
                        color: activeTheme.mutedText.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3-4 Concise Bullet Points
          ...bullets.map((bullet) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: activeTheme.inkForeground.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onActionPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
