import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'theme/app_theme.dart';
import 'models/syllabus.dart';
import 'widgets/progress_ring.dart';
import 'widgets/streak_badge.dart';
import 'widgets/video_tile.dart';
import 'widgets/heatmap_calendar.dart';
import 'widgets/curved_navigation_bar.dart';
import 'screens/onboarding/onboarding_pages.dart';

void main() {
  runApp(const FlowMDWidgetbook());
}

class FlowMDWidgetbook extends StatelessWidget {
  const FlowMDWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: AppTheme.light()),
            WidgetbookTheme(name: 'Dark', data: AppTheme.dark()),
          ],
        ),
        ViewportAddon(Viewports.all),
      ],
      directories: [
        WidgetbookCategory(
          name: 'Components',
          children: [
            // ── ProgressRing ───────────────────────────────────────────
            WidgetbookComponent(
              name: 'ProgressRing',
              useCases: [
                WidgetbookUseCase(
                  name: 'Interactive Progress Ring',
                  builder: (context) {
                    final progress = context.knobs.double.slider(
                      label: 'Progress',
                      initialValue: 0.65,
                      min: 0.0,
                      max: 1.0,
                    );
                    final size = context.knobs.double.slider(
                      label: 'Size',
                      initialValue: 80,
                      min: 40,
                      max: 140,
                    );
                    final stroke = context.knobs.double.slider(
                      label: 'Stroke Width',
                      initialValue: 8,
                      min: 3,
                      max: 16,
                    );

                    return Center(
                      child: ProgressRing(
                        progress: progress,
                        size: size,
                        strokeWidth: stroke,
                        color: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: size * 0.22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // ── StreakBadge ────────────────────────────────────────────
            WidgetbookComponent(
              name: 'StreakBadge',
              useCases: [
                WidgetbookUseCase(
                  name: 'Dynamic Streak',
                  builder: (context) {
                    final streak = context.knobs.int.slider(
                      label: 'Streak Count',
                      initialValue: 7,
                      min: 1,
                      max: 60,
                    );

                    return Center(
                      child: StreakBadge(streak: streak),
                    );
                  },
                ),
              ],
            ),

            // ── VideoTile ──────────────────────────────────────────────
            WidgetbookComponent(
              name: 'VideoTile',
              useCases: [
                WidgetbookUseCase(
                  name: 'Lecture Row',
                  builder: (context) {
                    final title = context.knobs.string(
                      label: 'Title',
                      initialValue: 'How to Approach Anatomy Edition 8',
                    );
                    final durationMins = context.knobs.int.slider(
                      label: 'Duration (mins)',
                      initialValue: 33,
                      min: 1,
                      max: 90,
                    );
                    final isCompleted = context.knobs.boolean(
                      label: 'Completed',
                      initialValue: false,
                    );
                    final sNo = context.knobs.int.slider(
                      label: 'Serial #',
                      initialValue: 1,
                      min: 1,
                      max: 50,
                    );

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: VideoTile(
                          video: Video(
                            id: 'sample_video_1',
                            title: title,
                            subjectId: 'anatomy',
                            chapterName: 'Embryology',
                            durationMins: durationMins,
                            serialNumber: sNo,
                          ),
                          serialNumber: sNo,
                          isCompleted: isCompleted,
                          completedAt: isCompleted ? '2026-09-18T20:00:00Z' : null,
                          accentColor: const Color(0xFF3B82F6),
                          onToggle: () {},
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // ── HeatmapCalendar ────────────────────────────────────────
            WidgetbookComponent(
              name: 'HeatmapCalendar',
              useCases: [
                WidgetbookUseCase(
                  name: '15-Week Activity Grid',
                  builder: (context) {
                    final now = DateTime.now();
                    // Generate realistic mock study history
                    final mockHistory = <String, int>{};
                    for (int i = 0; i < 90; i++) {
                      if (i % 2 == 0 || i % 3 == 0) {
                        final d = now.subtract(Duration(days: i));
                        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                        mockHistory[key] = (i % 7) + 1;
                      }
                    }

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: HeatmapCalendar(
                          dailyHistory: mockHistory,
                          accentColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // ── CurvedAnimatedNavBar (Figma Template) ─────────────────
            WidgetbookComponent(
              name: 'CurvedAnimatedNavBar',
              useCases: [
                WidgetbookUseCase(
                  name: 'Figma Curved Scoop Navigation Bar',
                  builder: (context) {
                    return const _InteractiveNavBarDemo();
                  },
                ),
              ],
            ),
          ],
        ),

        // ── Onboarding Illustrations ──────────────────────────────────
        WidgetbookCategory(
          name: 'Onboarding Pages',
          children: [
            WidgetbookComponent(
              name: 'Step 1: Daily Goals',
              useCases: [
                WidgetbookUseCase(
                  name: 'Calendar Pulse',
                  builder: (context) => OnboardingPage1(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Step 2: Curriculum',
              useCases: [
                WidgetbookUseCase(
                  name: 'Subject Grid Preview',
                  builder: (context) => OnboardingPage2(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Step 3: Analytics',
              useCases: [
                WidgetbookUseCase(
                  name: 'Animated Charts',
                  builder: (context) => OnboardingPage3(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Step 4: Daily Quests',
              useCases: [
                WidgetbookUseCase(
                  name: 'Checklist Tick-off',
                  builder: (context) => OnboardingPage4(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _InteractiveNavBarDemo extends StatefulWidget {
  const _InteractiveNavBarDemo();

  @override
  State<_InteractiveNavBarDemo> createState() => _InteractiveNavBarDemoState();
}

class _InteractiveNavBarDemoState extends State<_InteractiveNavBarDemo> {
  int _selectedIndex = 0;

  static const _demoTabs = [
    CurvedNavItem(svgAsset: 'assets/icons/navbar/home.svg', label: 'Home'),
    CurvedNavItem(svgAsset: 'assets/icons/navbar/chart.svg', label: 'Analytics'),
    CurvedNavItem(svgAsset: 'assets/icons/navbar/clock.svg', label: 'Plan'),
    CurvedNavItem(svgAsset: 'assets/icons/navbar/bell.svg', label: 'Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Active Tab: ${_demoTabs[_selectedIndex].label}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 380,
            child: CurvedAnimatedNavBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: _demoTabs,
            ),
          ),
        ],
      ),
    );
  }
}

