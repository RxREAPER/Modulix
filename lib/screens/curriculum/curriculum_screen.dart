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

                    // 3. Section Title & Filter Chips
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sortMode == CurriculumSortMode.yearWise
                                    ? 'Curriculum by Year'
                                    : (sortMode == CurriculumSortMode.mostRecent
                                        ? 'Recent Subjects'
                                        : 'All ${subjects.length} Subjects'),
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
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _CurriculumSortFilterChip(
                                    label: 'Default',
                                    icon: Icons.grid_view_rounded,
                                    isSelected:
                                        sortMode == CurriculumSortMode.defaultOrder,
                                    onTap: () => ref
                                        .read(curriculumSortProvider.notifier)
                                        .setMode(CurriculumSortMode.defaultOrder),
                                  ),
                                  const SizedBox(width: 8),
                                  _CurriculumSortFilterChip(
                                    label: 'Most Recent',
                                    icon: Icons.history_rounded,
                                    isSelected:
                                        sortMode == CurriculumSortMode.mostRecent,
                                    onTap: () => ref
                                        .read(curriculumSortProvider.notifier)
                                        .setMode(CurriculumSortMode.mostRecent),
                                  ),
                                  const SizedBox(width: 8),
                                  _CurriculumSortFilterChip(
                                    label: 'Year Wise',
                                    icon: Icons.school_rounded,
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
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _yearBadgeColor(year).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _yearBadgeColor(year),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            year.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: _yearBadgeColor(year),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${groupSubjects.length} ${groupSubjects.length == 1 ? "Subject" : "Subjects"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
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
            cacheExtent: 450.0,
            slivers: slivers,
          );
        },
      ),
    );
  }
}

class _CurriculumSortFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurriculumSortFilterChip({
    required this.label,
    required this.icon,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.onAccent : AppTheme.inkForeground,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.onAccent : AppTheme.inkForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

