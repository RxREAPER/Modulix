import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../focus_timer_sheet.dart';

class ModuleTimeline extends StatelessWidget {
  final Subject subject;
  final String activeTab; // 'videos' | 'qbank' | 'notes'
  final Map<String, dynamic> completedVideos;
  final Map<String, dynamic> completedQBanks;
  final Map<String, dynamic> completedNotes;
  final ValueChanged<String> onToggleVideo;
  final ValueChanged<String> onToggleQBank;
  final ValueChanged<String> onToggleNotes;

  const ModuleTimeline({
    super.key,
    required this.subject,
    required this.activeTab,
    required this.completedVideos,
    required this.completedQBanks,
    required this.completedNotes,
    required this.onToggleVideo,
    required this.onToggleQBank,
    required this.onToggleNotes,
  });

  @override
  Widget build(BuildContext context) {
    int globalModuleIndex = 1;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subject.chapters.length,
      itemBuilder: (context, chapterIndex) {
        final chapter = subject.chapters[chapterIndex];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blended Unit Header (no number, blends into list gracefully)
            _buildBlendedUnitHeader(chapter.name, chapterIndex + 1),

            // Modules under this unit based on the active tab
            if (activeTab == 'videos') ...[
              ...chapter.videos.map((v) {
                final currentNum = globalModuleIndex++;
                final isDone = completedVideos.containsKey(v.id);
                final completedDateStr = isDone ? completedVideos[v.id] : null;

                return _buildTimelineItem(
                  context: context,
                  number: currentNum,
                  isDone: isDone,
                  title: v.title,
                  detail: v.durationLabel,
                  secondaryDetail: completedDateStr is String ? _formatDate(completedDateStr) : null,
                  badgeColor: const Color(0xFFFFF9E6), // warm yellow
                  badgeIcon: Icons.play_arrow_rounded,
                  onToggle: () => onToggleVideo(v.id),
                  onStartTimer: () => context.push(
                    '/timer',
                    extra: {
                      'subjectId': subject.id,
                      'subjectName': subject.displayName,
                      'topicId': v.id,
                      'topicTitle': v.title,
                      'chapterName': chapter.name,
                      'topicType': 'video',
                      'durationMins': v.durationMins > 0 ? v.durationMins : 15,
                    },
                  ),
                );
              }),
            ] else if (activeTab == 'qbank') ...[
              ...chapter.qbanks.map((q) {
                final currentNum = globalModuleIndex++;
                final isDone = completedQBanks.containsKey(q.id);
                final completedDateStr = isDone ? completedQBanks[q.id] : null;

                return _buildTimelineItem(
                  context: context,
                  number: currentNum,
                  isDone: isDone,
                  title: q.title,
                  detail: '${q.totalMcqs} MCQs',
                  secondaryDetail: completedDateStr is String ? _formatDate(completedDateStr) : null,
                  badgeColor: const Color(0xFFEFF6FF), // cool blue
                  badgeIcon: Icons.quiz_rounded,
                  onToggle: () => onToggleQBank(q.id),
                  onStartTimer: () => context.push(
                    '/timer',
                    extra: {
                      'subjectId': subject.id,
                      'subjectName': subject.displayName,
                      'topicId': q.id,
                      'topicTitle': q.title,
                      'chapterName': chapter.name,
                      'topicType': 'qbank',
                      'durationMins': 30,
                    },
                  ),
                );
              }),
            ] else ...[
              ...chapter.notes.map((n) {
                final currentNum = globalModuleIndex++;
                final isDone = completedNotes.containsKey(n.id);
                final completedDateStr = isDone ? completedNotes[n.id] : null;

                return _buildTimelineItem(
                  context: context,
                  number: currentNum,
                  isDone: isDone,
                  title: n.title,
                  detail: '${n.pages} pages',
                  secondaryDetail: completedDateStr is String ? _formatDate(completedDateStr) : null,
                  badgeColor: const Color(0xFFF0FDF4), // soft green
                  badgeIcon: Icons.menu_book_rounded,
                  onToggle: () => onToggleNotes(n.id),
                  onStartTimer: () => context.push(
                    '/timer',
                    extra: {
                      'subjectId': subject.id,
                      'subjectName': subject.displayName,
                      'topicId': n.id,
                      'topicTitle': n.title,
                      'chapterName': chapter.name,
                      'topicType': 'notes',
                      'durationMins': 20,
                    },
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildBlendedUnitHeader(String unitName, int unitNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'UNIT $unitNumber',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              unitName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required int number,
    required bool isDone,
    required String title,
    required String detail,
    String? secondaryDetail,
    required Color badgeColor,
    required IconData badgeIcon,
    required VoidCallback onToggle,
    required VoidCallback onStartTimer,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Continuous Dotted Line + Circular Number Bubble
          SizedBox(
            width: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dotted line connecting items
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DottedLinePainter(
                      color: AppTheme.sketchBorderColor.withOpacity(0.4),
                    ),
                  ),
                ),
                // Circular Number Bubble
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFF16A34A) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? const Color(0xFF16A34A) : AppTheme.sketchBorderColor,
                      width: 1.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x181C1C1C),
                        offset: Offset(1.5, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : Text(
                            '$number',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppTheme.inkForeground,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Horizontal Topic Box with Details and Custom Checkbox
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDone ? Colors.green.shade400 : AppTheme.sketchBorderColor,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x141C1C1C),
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF16A34A) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone ? const Color(0xFF16A34A) : AppTheme.sketchBorderColor,
                            width: 1.8,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Topic Name & Completion Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDone ? Colors.grey.shade500 : AppTheme.inkForeground,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                detail,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (secondaryDetail != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• Completed $secondaryDetail',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Focus Timer Trigger Icon
                    IconButton(
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      tooltip: 'Focus on this module',
                      color: AppTheme.inkForeground,
                      onPressed: onStartTimer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}';
    } catch (_) {
      return '';
    }
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    double startY = 0;
    const dashLength = 4.0;
    const dashGap = 4.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(centerX, startY),
        Offset(centerX, startY + dashLength),
        paint,
      );
      startY += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
