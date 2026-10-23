import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/curriculum_sort_provider.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../../widgets/curriculum/curriculum_search_bar.dart';
import '../../widgets/curriculum/study_plan_banner.dart';
import '../../widgets/curriculum/square_subject_card.dart';
import '../../widgets/profile/profile_customization.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../services/tour/app_tour_controller.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';

class CurriculumScreen extends ConsumerWidget {
  const CurriculumScreen({super.key});

  Color _yearBadgeColor(String year) {
    switch (year) {
      case '1st Year':
        return const Color(0xFF2563EB); // Royal Blue
      case '2nd Year':
        return const Color(0xFFDC2626); // Crimson
      case '3rd Year':
        return const Color(0xFF0D9488); // Teal
      case 'Final Year':
        return const Color(0xFF7C3AED); // Purple
      case 'Revision':
        return const Color(0xFFD97706); // Amber
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syllabus = ref.watch(activeSyllabusProvider);
    final completionMap = ref.watch(syllabusMetricsProvider);
    final appState = ref.watch(appStateProvider).value;
    final sortMode = ref.watch(curriculumSortProvider);
    final recentTimestamps = ref.watch(recentSubjectsProvider);

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        title: Row(
          children: [
            Text(
              'Library',
              style: AppTheme.headingStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkForeground,
              ),
            ),
          ],
        ),
        actions: [
          if (appState != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ProfileAvatar(
                size: 42,
                colorId: appState.avatarColorId,
                iconId: appState.avatarIconId,
                doctorName: appState.doctorName,
                onTap: () => context.go('/settings?from=/curriculum'),
              ),
            ),
        ],
      ),
      body: syllabus.when(
        loading: () => const CurriculumSkeletonView(),
        error: (e, st) => AppErrorStateView(
          error: e,
          stackTrace: st,
          onRetry: () => ref.refresh(activeSyllabusProvider),
        ),
        data: (subjects) {
          final plan = appState?.currentEdition.plan;

          // Prepare sorted subjects
          final sortedSubjects = List<Subject>.from(subjects);
          if (sortMode == CurriculumSortMode.mostRecent) {
            sortedSubjects.sort((a, b) {
              final timeA = recentTimestamps[a.id] ?? 0;
              final timeB = recentTimestamps[b.id] ?? 0;
              if (timeA != timeB) {
                return timeB.compareTo(timeA); // descending
              }
              return subjects.indexOf(a).compareTo(subjects.indexOf(b));
            });
          }

          // Prepare year groups for year-wise sort
          final Map<String, List<Subject>> yearGroups = {};
          for (final year in kCurriculumYears) {
            yearGroups[year] = [];
          }
          for (final s in subjects) {
            final year = kSubjectYearMap[s.id] ?? 'Final Year';
            yearGroups.putIfAbsent(year, () => []).add(s);
          }

          final List<Widget> slivers = [
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
                    plan != null ? StudyPlanBanner(plan: plan) : const SizedBox.shrink(),

                    const SizedBox(height: 20),

                    // 3. Filter Chips
                    RepaintBoundary(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CurriculumSortFilterChip(
                              label: 'Default',
                              isSelected:
                                  sortMode == CurriculumSortMode.defaultOrder,
                              onTap: () => ref
                                  .read(curriculumSortProvider.notifier)
                                  .setMode(CurriculumSortMode.defaultOrder),
                            ),
                            const SizedBox(width: 8),
                            _CurriculumSortFilterChip(
                              label: 'Most Recent',
                              isSelected:
                                  sortMode == CurriculumSortMode.mostRecent,
                              onTap: () => ref
                                  .read(curriculumSortProvider.notifier)
                                  .setMode(CurriculumSortMode.mostRecent),
                            ),
                            const SizedBox(width: 8),
                            _CurriculumSortFilterChip(
                              label: 'Year Wise',
                              isSelected:
                                  sortMode == CurriculumSortMode.yearWise,
                              onTap: () => ref
                                  .read(curriculumSortProvider.notifier)
                                  .setMode(CurriculumSortMode.yearWise),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
          ];

          // 5. Grid presentation based on active sort mode
          if (sortMode == CurriculumSortMode.yearWise) {
            for (final year in kCurriculumYears) {
              final groupSubjects = yearGroups[year] ?? [];
              if (groupSubjects.isEmpty) continue;

              slivers.add(
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 4.0,
                          height: 18.0,
                          decoration: BoxDecoration(
                            color: _yearBadgeColor(year),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          year,
                          style: AppTheme.headingStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${groupSubjects.length} ${groupSubjects.length == 1 ? "Subject" : "Subjects"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              slivers.add(
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subject = groupSubjects[index];
                        final completion =
                            completionMap?[subject.id] ?? 0.0;

                        final card = SquareSubjectCard(
                          subject: subject,
                          completion: completion,
                          onTap: () =>
                              context.go('/curriculum/${subject.id}'),
                        );

                        if (year == kCurriculumYears.first) {
                          if (index == 0) {
                            return Container(
                              key: TourTargetRegistry.keyFor(TourTargetId.curriculumSubject1),
                              child: card,
                            );
                          }
                          if (index == 1) {
                            return Container(
                              key: TourTargetRegistry.keyFor(TourTargetId.curriculumSubject2),
                              child: card,
                            );
                          }
                        }

                        return card;
                      },
                      childCount: groupSubjects.length,
                    ),
                  ),
                ),
              );
            }

            slivers.add(
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            );
          } else {
            slivers.add(
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subject = sortedSubjects[index];
                      final completion = completionMap?[subject.id] ?? 0.0;

                      final card = SquareSubjectCard(
                        subject: subject,
                        completion: completion,
                        onTap: () =>
                            context.go('/curriculum/${subject.id}'),
                      );

                      if (index == 0) {
                        return Container(
                          key: TourTargetRegistry.keyFor(TourTargetId.curriculumSubject1),
                          child: card,
                        );
                      }
                      if (index == 1) {
                        return Container(
                          key: TourTargetRegistry.keyFor(TourTargetId.curriculumSubject2),
                          child: card,
                        );
                      }

                      return card;
                    },
                    childCount: sortedSubjects.length,
                  ),
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: slivers,
          );
        },
      ),
    );
  }
}

class _CurriculumSortFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurriculumSortFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.94,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.accentPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentPrimary,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.28),
                    offset: const Offset(1.5, 2),
                    blurRadius: 2,
                  ),
                ],
              )
            : BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderLight,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkForeground.withValues(alpha: 0.04),
                    offset: const Offset(1, 1),
                    blurRadius: 0,
                  ),
                ],
              ),
        child: Text(
          label,
          style: AppTypography.compactAction(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.onAccent : AppTheme.inkForeground,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

