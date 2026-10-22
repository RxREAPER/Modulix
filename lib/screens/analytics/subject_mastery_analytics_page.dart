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

class SubjectMasteryAnalyticsPage extends ConsumerStatefulWidget {
  const SubjectMasteryAnalyticsPage({super.key});

  @override
  ConsumerState<SubjectMasteryAnalyticsPage> createState() =>
      _SubjectMasteryAnalyticsPageState();
}

class _SubjectMasteryAnalyticsPageState
    extends ConsumerState<SubjectMasteryAnalyticsPage> {
  int _selectedPhaseIndex = 0; // 0: All (19), 1: Pre-Clinical, 2: Para-Clinical, 3: Clinical

  static const _preClinicalIds = {'anatomy', 'anat', 'physiology', 'physio', 'biochemistry', 'biochem'};
  static const _paraClinicalIds = {'pathology', 'path', 'pharmacology', 'pharm', 'microbiology', 'micro', 'forensic_medicine', 'fmt', 'forensic'};

  String _getPhaseLabel(String subjectId) {
    final lower = subjectId.toLowerCase();
    if (_preClinicalIds.contains(lower)) return '1st Prof · Pre-Clinical';
    if (_paraClinicalIds.contains(lower)) return '2nd Prof · Para-Clinical';
    return '3rd Prof · Clinical';
  }

  bool _matchesPhase(String subjectId, int phaseIndex) {
    if (phaseIndex == 0) return true;
    final lower = subjectId.toLowerCase();
    if (phaseIndex == 1) return _preClinicalIds.contains(lower);
    if (phaseIndex == 2) return _paraClinicalIds.contains(lower);
    if (phaseIndex == 3) {
      return !_preClinicalIds.contains(lower) && !_paraClinicalIds.contains(lower);
    }
    return true;
  }

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

    // Sort subjects by completion descending
    subjectCards.sort((a, b) => (b['pct'] as double).compareTo(a['pct'] as double));

    final int grandTotal = totalAllVideos + totalAllQBanks + totalAllNotes;
    final int grandDone = completedAllVideos + completedAllQBanks + completedAllNotes;
    final double overallProgress = grandTotal > 0 ? (grandDone / grandTotal) : 0.0;

    final filteredCards = subjectCards.where((item) {
      final s = item['subject'] as Subject;
      return _matchesPhase(s.id, _selectedPhaseIndex);
    }).toList();

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
          '19 MBBS Subjects Mastery',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.inkForeground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight, width: 1.2),
                ),
                child: Text(
                  '${(overallProgress * 100).round()}% MBBS Done',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: AppTheme.inkForeground,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                    progressColor: const Color(0xFF6366F1),
                    percentageStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
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
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$grandDone of $grandTotal Items Mastered',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _miniMetric('Videos', '$completedAllVideos/$totalAllVideos', AppTheme.accentPrimary),
                            const SizedBox(width: 12),
                            _miniMetric('QBank', '$completedAllQBanks/$totalAllQBanks', const Color(0xFF3B82F6)),
                            const SizedBox(width: 12),
                            _miniMetric('Notes', '$completedAllNotes/$totalAllNotes', const Color(0xFF10B981)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Phase Filter Switcher ───────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _phasePill(0, 'All (19)'),
                  _phasePill(1, 'Pre-Clinical (3)'),
                  _phasePill(2, 'Para-Clinical (4)'),
                  _phasePill(3, 'Clinical (12)'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 3. Subject Cards List ──────────────────────────────────────
            ...filteredCards.map((item) {
              final s = item['subject'] as Subject;
              final meta = subjectMeta(s.id);
              final double pct = item['pct'] as double;
              final int vDone = item['videosDone'] as int;
              final int vTot = item['videos'] as int;
              final int qDone = item['qbanksDone'] as int;
              final int qTot = item['qbanks'] as int;
              final int nDone = item['notesDone'] as int;
              final int nTot = item['notes'] as int;
              final phaseLabel = _getPhaseLabel(s.id);

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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: meta.bgLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: meta.accent, width: 1.2),
                              ),
                              child: Icon(meta.icon, color: meta.accent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.inkForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    phaseLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ProgressRadialGauge(
                              progress: pct,
                              size: 44,
                              strokeWidth: 4.5,
                              progressColor: meta.accent,
                              percentageStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Resource pills row
                        Row(
                          children: [
                            _resourceTag('Videos', '$vDone/$vTot', AppTheme.accentPrimary),
                            const SizedBox(width: 8),
                            _resourceTag('QBank', '$qDone/$qTot', const Color(0xFF3B82F6)),
                            const SizedBox(width: 8),
                            _resourceTag('Notes', '$nDone/$nTot', const Color(0xFF10B981)),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Curriculum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: meta.accent,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: meta.accent,
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
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.mutedText)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: AppTheme.inkForeground)),
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
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _phasePill(int index, String label) {
    final isSelected = _selectedPhaseIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPhaseIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.inkForeground : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.inkForeground : AppTheme.borderLight,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
          ),
        ),
      ),
    );
  }
}
