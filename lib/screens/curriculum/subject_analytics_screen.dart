import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/syllabus.dart';
import '../../models/time_log.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/time_log_provider.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';
import '../../widgets/curriculum/subject_sketch_icon.dart';
import '../../widgets/focus_timer_sheet.dart';

class SubjectAnalyticsScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectAnalyticsScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(subjectProvider(subjectId));
    final timeLogs = ref.watch(timeLogsProvider);
    final subjectLogs = timeLogs.where((l) => l.subjectId == subjectId).toList();

    return subjectAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: Text('Error: $e')),
      ),
      data: (subject) {
        if (subject == null) {
          return Scaffold(
            backgroundColor: AppTheme.paperBackground,
            body: Center(child: Text('Subject not found')),
          );
        }

        final meta = subjectMeta(subjectId);

        // Compute study times by type
        int videoSecs = 0;
        int qbankSecs = 0;
        int notesSecs = 0;
        int standaloneSecs = 0;

        for (final l in subjectLogs) {
          switch (l.topicType) {
            case 'video':
              videoSecs += l.durationSecs;
              break;
            case 'qbank':
              qbankSecs += l.durationSecs;
              break;
            case 'notes':
              notesSecs += l.durationSecs;
              break;
            default:
              standaloneSecs += l.durationSecs;
          }
        }

        final totalSecs = videoSecs + qbankSecs + notesSecs + standaloneSecs;
        final totalHoursDouble = totalSecs / 3600.0;

        final canPop = ModalRoute.of(context)?.canPop ?? false;
        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            try {
              context.go('/curriculum/$subjectId');
            } catch (_) {}
          },
          child: Scaffold(
            backgroundColor: AppTheme.paperBackground,
            appBar: AppBar(
              backgroundColor: AppTheme.paperBackground,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    try {
                      context.go('/curriculum/$subjectId');
                    } catch (_) {}
                  }
                },
              ),
              title: Text(
                '${subject.displayName} Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground,
                ),
              ),
            ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.inkForeground,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.timer_outlined),
            label: const Text(
              'Focus Reading Timer',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => FocusTimerSheet.show(
              context,
              subjectId: subject.id,
              subjectName: subject.displayName,
              type: 'standalone',
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        meta.accent,
                        meta.accent.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.sketchBorderColor, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x241C1C1C),
                        offset: Offset(4, 5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'TOTAL STUDY TIME LOGGED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          SubjectSketchIcon(subjectId: subject.id, color: Colors.white, size: 28),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatHoursMinutes(totalSecs),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Across ${subjectLogs.length} logged study sessions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Distribution Chart
                Text(
                  'Time Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 20,
                  ),
                  child: totalSecs == 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.hourglass_empty_rounded, size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'No focus timer sessions recorded yet',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use the Focus Reading Timer below or tap any module timer icon to start tracking time.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            RepaintBoundary(
                              child: SizedBox(
                                height: 160,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 40,
                                    sections: [
                                      if (videoSecs > 0)
                                        PieChartSectionData(
                                          value: videoSecs.toDouble(),
                                          title: '${((videoSecs / totalSecs) * 100).round()}%',
                                          color: AppTheme.primaryBlue,
                                          radius: 36,
                                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      if (qbankSecs > 0)
                                        PieChartSectionData(
                                          value: qbankSecs.toDouble(),
                                          title: '${((qbankSecs / totalSecs) * 100).round()}%',
                                          color: Colors.teal.shade600,
                                          radius: 36,
                                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      if (notesSecs > 0)
                                        PieChartSectionData(
                                          value: notesSecs.toDouble(),
                                          title: '${((notesSecs / totalSecs) * 100).round()}%',
                                          color: Colors.amber.shade700,
                                          radius: 36,
                                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      if (standaloneSecs > 0)
                                        PieChartSectionData(
                                          value: standaloneSecs.toDouble(),
                                          title: '${((standaloneSecs / totalSecs) * 100).round()}%',
                                          color: Colors.purple.shade600,
                                          radius: 36,
                                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Legend
                            Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _legendItem('Videos', _formatHoursMinutes(videoSecs), AppTheme.primaryBlue),
                                _legendItem('Q-Bank', _formatHoursMinutes(qbankSecs), Colors.teal.shade600),
                                _legendItem('Notes', _formatHoursMinutes(notesSecs), Colors.amber.shade700),
                                _legendItem('Reading', _formatHoursMinutes(standaloneSecs), Colors.purple.shade600),
                              ],
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),

                // Per-Unit Study Logs
                Text(
                  'Unit-by-Unit Study Sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 12),

                ...subject.chapters.map((ch) {
                  final chLogs = subjectLogs.where((l) => l.chapterName == ch.name).toList();
                  final chSecs = chLogs.fold<int>(0, (sum, l) => sum + l.durationSecs);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: AppTheme.cardWhite,
                      borderRadius: 14,
                      shadowOffset: 2.5,
                    ),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: meta.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(Icons.menu_book, color: meta.accent, size: 18),
                        ),
                      ),
                      title: Text(
                        ch.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        chSecs > 0 ? '${_formatHoursMinutes(chSecs)} logged' : 'No time logged yet',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: chSecs > 0 ? AppTheme.primaryBlue : Colors.grey.shade500,
                        ),
                      ),
                      children: chLogs.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Tap the timer icon beside any module in this unit to log your study time.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ),
                            ]
                          : chLogs.map((l) {
                              return ListTile(
                                dense: true,
                                leading: Icon(_typeIcon(l.topicType), size: 16, color: AppTheme.inkForeground),
                                title: Text(l.topicTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                trailing: Text(
                                  _formatHoursMinutes(l.durationSecs),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _legendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'qbank':
        return Icons.quiz_outlined;
      case 'notes':
        return Icons.note_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  String _formatHoursMinutes(int totalSecs) {
    final m = totalSecs ~/ 60;
    final h = m ~/ 60;
    final mins = m % 60;
    if (h > 0) {
      return '${h}h ${mins}m';
    }
    return '${mins}m ${totalSecs % 60}s';
  }
}
