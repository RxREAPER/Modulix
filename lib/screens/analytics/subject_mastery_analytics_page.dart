import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/subjects_metadata.dart';
import '../../models/syllabus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/analytics/progress_radial_gauge.dart';
import '../../widgets/curriculum/subject_sketch_icon.dart';

class SubjectMasteryAnalyticsPage extends ConsumerStatefulWidget {
  const SubjectMasteryAnalyticsPage({super.key});

  @override
  ConsumerState<SubjectMasteryAnalyticsPage> createState() =>
      _SubjectMasteryAnalyticsPageState();
}

class _SubjectMasteryAnalyticsPageState
    extends ConsumerState<SubjectMasteryAnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider).valueOrNull;
    final syllabusAsync = ref.watch(activeSyllabusProvider);
    final subjects = syllabusAsync.value ?? [];

    if (appState == null) {
      return Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final edition = appState.currentEdition;
    final completedVideos = edition.completedVideos;
    final completedQBanks = edition.completedQBanks;
    final completedNotes = edition.completedNotes;

    int totalAllVideos = 0;
    int completedAllVideos = 0;
    int totalAllQBanks = 0;
    int completedAllQBanks = 0;
    int totalAllNotes = 0;
    int completedAllNotes = 0;

    final List<Map<String, dynamic>> subjectCards = [];

    // Preserves syllabus order from 1st Year (Pre-Clinical) to Final Year (Clinical)
    for (final s in subjects) {
      int sVideos = 0;
      int sVideosDone = 0;
      int sQBanks = 0;
      int sQBanksDone = 0;
      int sNotes = 0;
      int sNotesDone = 0;

      for (final ch in s.chapters) {
        sVideos += ch.videos.length;
        for (final v in ch.videos) {
          if (completedVideos.containsKey(v.id)) sVideosDone++;
        }
        sNotes += ch.notes.length;
        for (final n in ch.notes) {
          if (completedNotes.containsKey(n.id)) sNotesDone++;
        }
      }

      for (final qch in s.qbankChapters) {
        sQBanks += qch.qbanks.length;
        for (final q in qch.qbanks) {
          if (completedQBanks.containsKey(q.id)) sQBanksDone++;
        }
      }

      totalAllVideos += sVideos;
      completedAllVideos += sVideosDone;
      totalAllQBanks += sQBanks;
      completedAllQBanks += sQBanksDone;
      totalAllNotes += sNotes;
      completedAllNotes += sNotesDone;

      final int sTotal = sVideos + sQBanks + sNotes;
      final int sDone = sVideosDone + sQBanksDone + sNotesDone;
      final double sPct = sTotal > 0 ? (sDone / sTotal) : 0.0;

      subjectCards.add({
        'subject': s,
        'videos': sVideos,
        'videosDone': sVideosDone,
        'qbanks': sQBanks,
        'qbanksDone': sQBanksDone,
        'notes': sNotes,
        'notesDone': sNotesDone,
        'total': sTotal,
        'done': sDone,
        'pct': sPct,
      });
    }

    final int grandTotal = totalAllVideos + totalAllQBanks + totalAllNotes;
    final int grandDone = completedAllVideos + completedAllQBanks + completedAllNotes;
    final double overallProgress = grandTotal > 0 ? (grandDone / grandTotal) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/analytics');
            }
          },
        ),
        title: Text(
          'Subject Mastery',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
      ),
      body: FadeSlideEntrance(
        durationMs: 180,
        slideY: 12.0,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── 1. Hero Overall MBBS Progress Card ─────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.sketchDecoration(
                backgroundColor: AppTheme.cardWhite,
                borderRadius: 22,
                shadowOffset: 4,
              ),
              child: Row(
                children: [
                  ProgressRadialGauge(
                    progress: overallProgress,
                    size: 88,
                    strokeWidth: 8,
                    progressColor: AppTheme.accentPrimary,
                    percentageStyle: AppTypography.metricValue(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL CURRICULUM COVERAGE',
                          style: AppTypography.sectionMicroHeader(
                            fontSize: 10.0,
                            letterSpacing: 1.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$grandDone of $grandTotal Items Mastered',
                          style: AppTypography.cardTitle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _miniMetric('Videos', '$completedAllVideos/$totalAllVideos', AppTheme.accentPrimary),
                            _miniMetric('QBank', '$completedAllQBanks/$totalAllQBanks', AppTheme.accentSecondary),
                            _miniMetric('Notes', '$completedAllNotes/$totalAllNotes', AppTheme.accentTertiary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── 2. Subject Cards List (1st Year to Final Year) ─────────────
            ...subjectCards.map((item) {
              final s = item['subject'] as Subject;
              final double pct = item['pct'] as double;
              final int vDone = item['videosDone'] as int;
              final int vTot = item['videos'] as int;
              final int qDone = item['qbanksDone'] as int;
              final int qTot = item['qbanks'] as int;
              final int nDone = item['notesDone'] as int;
              final int nTot = item['notes'] as int;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ApplePressable(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/curriculum/${s.id}');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: AppTheme.cardWhite,
                      borderRadius: 20,
                      shadowOffset: 3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SubjectSketchIcon(
                              subjectId: s.id,
                              color: subjectMeta(s.id).accent,
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                s.name,
                                style: AppTheme.headingStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.inkForeground,
                                ),
                              ),
                            ),
                            ProgressRadialGauge(
                              progress: pct,
                              size: 44,
                              strokeWidth: 4.5,
                              progressColor: AppTheme.accentPrimary,
                              percentageStyle: AppTypography.metricValue(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Resource pills row with Wrap protection
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _resourceTag('Videos', '$vDone/$vTot', AppTheme.accentPrimary),
                                  _resourceTag('QBank', '$qDone/$qTot', AppTheme.accentSecondary),
                                  _resourceTag('Notes', '$nDone/$nTot', AppTheme.accentTertiary),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Curriculum',
                                  style: AppTypography.compactAction(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentPrimary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppTheme.accentPrimary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.metricLabel(fontSize: 9.5, color: AppTheme.mutedText)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.metricValue(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.inkForeground)),
      ],
    );
  }

  Widget _resourceTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.microBadge(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
