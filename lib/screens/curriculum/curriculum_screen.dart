import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/curriculum/curriculum_search_bar.dart';
import '../../widgets/curriculum/study_plan_banner.dart';
import '../../widgets/curriculum/square_subject_card.dart';

class CurriculumScreen extends ConsumerWidget {
  const CurriculumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syllabus = ref.watch(activeSyllabusProvider);
    final completionMap = ref.watch(syllabusMetricsProvider);
    final appState = ref.watch(appStateProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        title: const Row(
          children: [
            Text(
              'Curriculum',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkForeground,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (appState != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _EditionToggle(activeEdition: appState.activeEdition),
            ),
        ],
      ),
      body: syllabus.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subjects) {
          final plan = appState?.currentEdition.plan;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Top Pinned / Header Controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Live Search Bar
                      CurriculumSearchBar(subjects: subjects),

                      const SizedBox(height: 16),

                      // 2. Animated Configure Study Plan Banner
                      if (plan != null) StudyPlanBanner(plan: plan),

                      const SizedBox(height: 20),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All 19 Subjects',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                          Text(
                            'NEET-PG Syllabus',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. 2-Column Square Subject Cards Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subject = subjects[index];
                      final completion = completionMap?[subject.id] ?? 0.0;

                      return SquareSubjectCard(
                        subject: subject,
                        completion: completion,
                        onTap: () => context.push('/curriculum/${subject.id}'),
                      );
                    },
                    childCount: subjects.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditionToggle extends ConsumerWidget {
  final String activeEdition;
  const _EditionToggle({required this.activeEdition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final next = activeEdition == 'marrow_8' ? 'marrow_6_5' : 'marrow_8';
        await ref.read(appStateProvider.notifier).switchEdition(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.highlightCoral,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.sketchBorderColor, width: 1.5),
        ),
        child: Text(
          activeEdition == 'marrow_8' ? 'Edition 8.0' : 'Edition 6.5',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.inkForeground,
          ),
        ),
      ),
    );
  }
}
