import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import 'animations/timer_dock_animation.dart';
import 'animations/timer_modes_animation.dart';
import 'animations/flip_clock_animation.dart';
import 'animations/pace_engine_animation.dart';
import 'animations/bulk_complete_animation.dart';

class LearnTheAppSheet extends StatelessWidget {
  const LearnTheAppSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const LearnTheAppSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          left: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          right: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple, width: 1.5),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.purple, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FLOWMD MASTERCLASS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        'Learn the App',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderLight),

          // Scrollable Feature Guides (No top filter pills)
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              children: [
                // ── 1. PACE ENGINE & STUDY PLAN ──────────────────────────────
                _FeatureCard(
                  title: 'Automated Module Tracker',
                  tag: 'PACE ENGINE',
                  icon: Icons.auto_graph_rounded,
                  color: const Color(0xFF4F46E5),
                  initiallyExpanded: true,
                  headline:
                      'Dynamically calculates daily video quotas and shifts your finish ETA as you study.',
                  diagramWidget: const PaceEngineAnimationWidget(),
                  steps: const [
                    'Set your exam deadline and target subject in "Configure Study Plan".',
                    'FlowMD automatically measures remaining videos and sets your daily target pace (e.g. 4.2 v/d).',
                    'Your daily suggested video queue on Home advances as you mark videos complete.',
                    'If life happens and you miss a day, FlowMD alerts you with "Behind Pace" so you can recalibrate without guessing.',
                  ],
                  proTip:
                      'Pro Tip: Inside any chapter, tap "Bulk Mark Complete" to instantly check off lectures you previously watched offline on Marrow.',
                  actionLabel: 'Configure Study Plan',
                  actionIcon: Icons.calendar_month_rounded,
                  onAction: () {
                    Navigator.pop(context);
                    context.push('/plan');
                  },
                ),
                const SizedBox(height: 14),

                // ── 2. THE 3 TIMER MODES ─────────────────────────────────────
                _FeatureCard(
                  title: 'The 3 Focus Timer Modes',
                  tag: 'DEEP WORK MODES',
                  icon: Icons.timer_outlined,
                  color: Colors.orange,
                  initiallyExpanded: false,
                  headline:
                      'Select the exact clinical timer tailored for active recall, marathons, or specific lecture lengths.',
                  diagramWidget: const TimerModesAnimationWidget(),
                  steps: const [
                    '⏱ Pomodoro: Standard countdown (15m, 25m, 45m, 60m) with structured rest breaks for active MCQ practice.',
                    '⬆ Count-Up: Open-ended stopwatch tracking total study hours without bell interruptions.',
                    '📌 Module-Linked: Directly anchors to a syllabus video length (e.g. 38 mins) and automatically marks it finished upon completion.',
                  ],
                  proTip:
                      'Pro Tip: Tap the ambient sound icon to play looping offline rain, lofi, or bird audio with a pulsing rhythm visualizer.',
                  actionLabel: 'Launch Focus Timer',
                  actionIcon: Icons.play_arrow_rounded,
                  onAction: () {
                    Navigator.pop(context);
                    context.push('/timer');
                  },
                ),
                const SizedBox(height: 14),

                // ── 3. FLOATING TIMER DOCKING ────────────────────────────────
                _FeatureCard(
                  title: 'Multitasking & Floating Mini Bar',
                  tag: 'PERSISTENT CLOCK',
                  icon: Icons.picture_in_picture_alt_rounded,
                  color: Colors.teal,
                  initiallyExpanded: false,
                  headline:
                      'Leaving the timer does NOT stop it — a live ticking mini-bar docks above your navigation bar.',
                  diagramWidget: const TimerDockAnimationWidget(),
                  steps: const [
                    'Tap the top-right "X" on the focus timer screen anytime.',
                    'The full screen smoothly docks into a floating ticker bar above the bottom navigation.',
                    'Browse curriculum chapters, check Q-Bank sets, or review notes while your focus time accumulates.',
                    'Tap the mini bar anytime to expand back into full screen.',
                  ],
                  proTip:
                      'Pro Tip: Even if you navigate between tabs, the audio hum and timer remain continuous.',
                  actionLabel: 'Test Mini Timer',
                  actionIcon: Icons.open_in_full_rounded,
                  onAction: () {
                    Navigator.pop(context);
                    context.push('/timer');
                  },
                ),
                const SizedBox(height: 14),

                // ── 4. BEDSIDE FLIP CLOCK ────────────────────────────────────
                _FeatureCard(
                  title: 'Bedside Landscape Flip Clock',
                  tag: 'DISTRACTION-FREE',
                  icon: Icons.screen_rotation_rounded,
                  color: const Color(0xFF6366F1),
                  initiallyExpanded: false,
                  headline:
                      'Rotate your phone sideways for a clean, ambient split-flap bedside desk clock.',
                  diagramWidget: const FlipClockRotateAnimationWidget(),
                  steps: const [
                    'Tap the fullscreen icon at the top of the Focus Timer.',
                    'Rotate your phone into landscape mode — the clock dead-centers automatically.',
                    'Split-flap tiles flip with realistic 3D transitions as seconds tick down.',
                    'Immersive mode hides status bars and bottom navigation to prevent notification interruptions.',
                  ],
                  proTip:
                      'Pro Tip: Tap anywhere on the clock in fullscreen to pause or resume your session.',
                  actionLabel: 'View Flip Clock',
                  actionIcon: Icons.fullscreen_rounded,
                  onAction: () {
                    Navigator.pop(context);
                    context.push('/timer');
                  },
                ),
                const SizedBox(height: 14),

                // ── 5. CHAPTER BULK COMPLETION ───────────────────────────────
                _FeatureCard(
                  title: 'Chapter Bulk-Completion Sync',
                  tag: 'TIME SAVER',
                  icon: Icons.done_all_rounded,
                  color: const Color(0xFF10B981),
                  initiallyExpanded: false,
                  headline:
                      'Sync entire chapters you previously studied offline on Marrow with 1 tap.',
                  diagramWidget: const BulkCompleteAnimationWidget(),
                  steps: const [
                    'Open any subject in Curriculum and tap into a chapter.',
                    'Tap "Bulk Complete" at the top-right of the chapter screen.',
                    'All lectures in that chapter are instantly checked off and credit toward your syllabus completion ring.',
                    'Saves you from tapping 15-20 individual checkboxes for past revision work.',
                  ],
                  proTip:
                      'Pro Tip: You can unmark individual lectures anytime if you still want to re-watch a specific topic.',
                  actionLabel: 'Browse Curriculum',
                  actionIcon: Icons.menu_book_rounded,
                  onAction: () {
                    Navigator.pop(context);
                    context.push('/curriculum');
                  },
                ),
                const SizedBox(height: 14),

                // ── 6. 5:00 AM DAY RESET BOUNDARY ───────────────────────────
                _FeatureCard(
                  title: 'The 5:00 AM Study Day Boundary',
                  tag: 'MEDICO LOGIC',
                  icon: Icons.wb_twilight_rounded,
                  color: Colors.indigo,
                  initiallyExpanded: false,
                  headline:
                      'Designed for doctors studying late into the night — your streak never dies at midnight.',
                  diagramWidget: _buildDayBoundaryDiagram(),
                  steps: const [
                    'Traditional apps cut off at 12:00 AM midnight, punishing doctors who study post-duty or into the early morning.',
                    'FlowMD lets your study day run until 5:00 AM. Study sessions clocked at 1:30 AM or 3:00 AM count towards today\'s streak.',
                    'Your daily desk pad tasks and daily target meters only reset once the 5:00 AM boundary passes.',
                    'You can customize this reset hour (from 3:00 AM to 7:00 AM) in your Settings tab.',
                  ],
                  proTip:
                      'Pro Tip: Checking off ANY task or completing 1 video or timer session before 5:00 AM keeps your streak active.',
                  actionLabel: 'Back to Settings',
                  actionIcon: Icons.settings_outlined,
                  onAction: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 14),

                // ── 7. MEDICO FAQS & TROUBLESHOOTING ────────────────────────
                _FeatureCard(
                  title: 'Frequently Asked Questions',
                  tag: 'FAQ',
                  icon: Icons.help_outline_rounded,
                  color: Colors.blueGrey,
                  initiallyExpanded: false,
                  headline:
                      'Direct answers to common questions about offline storage, edition switching, and data backups.',
                  diagramWidget: null,
                  steps: const [
                    'Does FlowMD send my data to a server?\nNo. FlowMD is 100% offline-sovereign. Everything is stored directly on your phone.',
                    'How do I switch between Marrow 8 and 6.5?\nGo to Settings and tap "Marrow Edition 8" or "Marrow Edition 6.5". Your progress in each edition is kept safely separate!',
                    'What if I take a day off?\nFlowMD automatically shifts your projected finish date. You can re-adjust your daily video target anytime.',
                    'How do I backup my progress?\nIn Settings, tap "Data & Privacy" > "Export Backup File" to share a JSON file to Google Drive, WhatsApp, or email.',
                  ],
                  proTip:
                      'Pro Tip: Need extra help or want to request a feature? Reach out directly to ezioauditore9553@gamil.com in About & Support.',
                  actionLabel: 'Data & Backup',
                  actionIcon: Icons.shield_outlined,
                  onAction: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Diagram: 5 AM Timeline ─────────────────────────────────────────────────
  static Widget _buildDayBoundaryDiagram() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.nightlight_round, size: 14, color: Colors.indigo),
              SizedBox(width: 6),
              Text(
                'Late Night Study Boundary',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _timeNode('11:00 PM', 'Studying', false),
              _connector(true),
              _timeNode('1:30 AM', 'Still Today! ✓', true),
              _connector(false),
              _timeNode('5:00 AM', 'New Day ☀️', false),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _timeNode(String time, String label, bool highlight) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: highlight ? Colors.indigo : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: highlight ? Colors.indigo : Colors.indigo.shade200,
              ),
            ),
            child: Center(
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: highlight ? Colors.white : Colors.indigo,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? Colors.indigo : AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _connector(bool active) {
    return Container(
      width: 14,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: active ? Colors.indigo : Colors.indigo.shade200,
    );
  }
}

// ── Generic Rich Feature Card ────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final String title;
  final String tag;
  final IconData icon;
  final Color color;
  final bool initiallyExpanded;
  final String headline;
  final Widget? diagramWidget;
  final List<String> steps;
  final String proTip;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _FeatureCard({
    required this.title,
    required this.tag,
    required this.icon,
    required this.color,
    required this.initiallyExpanded,
    required this.headline,
    required this.diagramWidget,
    required this.steps,
    required this.proTip,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.sketchDecoration(
        backgroundColor: Colors.white,
        borderRadius: 18,
        shadowOffset: 3,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1.3),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.inkForeground,
            ),
          ),
          subtitle: Text(
            tag,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 12),

            // Headline
            Text(
              headline,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkForeground,
                height: 1.35,
              ),
            ),

            if (diagramWidget != null) ...[
              const SizedBox(height: 12),
              diagramWidget!,
            ],

            const SizedBox(height: 14),

            // Steps
            ...steps.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),

            // Pro Tip Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.amber.shade300, width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      proTip,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.inkForeground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(actionIcon, size: 16),
                label: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
