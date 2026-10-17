import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../animations/animated_check_stroke.dart';
import '../animations/animated_strike_text.dart';
import '../animations/apple_pressable.dart';

class ModuleTimeline extends StatelessWidget {
  final Subject subject;
  final String activeTab; // 'videos' | 'qbank' | 'notes'
  final Map<String, dynamic> completedVideos;
  final Map<String, dynamic> completedQBanks;
  final Map<String, dynamic> completedNotes;
  final ValueChanged<String> onToggleVideo;
  final ValueChanged<String> onToggleQBank;
  final ValueChanged<String> onToggleNotes;
  final Function(List<String> videoIds, String chapterName, bool markDone) onBulkToggleVideos;
  final Function(List<String> qbankIds, bool markDone) onBulkToggleQBanks;
  final Function(List<String> noteIds, bool markDone) onBulkToggleNotes;
  final Map<int, GlobalKey>? unitKeys;
  final int slideDirection;
  final Animation<double>? contentAnimation;

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
    required this.onBulkToggleVideos,
    required this.onBulkToggleQBanks,
    required this.onBulkToggleNotes,
    this.unitKeys,
    this.slideDirection = 1,
    this.contentAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return buildSliver(context);
  }

  Widget buildSliver(BuildContext context) {
    final displayChapters = (activeTab == 'qbank' && subject.qbankChapters.isNotEmpty)
        ? subject.qbankChapters
        : subject.chapters;

    return MultiSliver(
      pushPinnedChildren: false,
      children: [
        for (int chapterIndex = 0; chapterIndex < displayChapters.length; chapterIndex++)
          _TimelineChapterSection(
            key: ValueKey('sec_${subject.id}_${activeTab}_$chapterIndex'),
            unitKey: unitKeys?[chapterIndex],
            chapter: displayChapters[chapterIndex],
            chapterIndex: chapterIndex,
            activeTab: activeTab,
            completedVideos: completedVideos,
            completedQBanks: completedQBanks,
            completedNotes: completedNotes,
            onToggleVideo: onToggleVideo,
            onToggleQBank: onToggleQBank,
            onToggleNotes: onToggleNotes,
            onBulkToggleVideos: onBulkToggleVideos,
            onBulkToggleQBanks: onBulkToggleQBanks,
            onBulkToggleNotes: onBulkToggleNotes,
          ),
      ],
    );
  }
}

class _TimelineChapterSection extends StatefulWidget {
  final Key? unitKey;
  final Chapter chapter;
  final int chapterIndex;
  final String activeTab;
  final Map<String, dynamic> completedVideos;
  final Map<String, dynamic> completedQBanks;
  final Map<String, dynamic> completedNotes;
  final ValueChanged<String> onToggleVideo;
  final ValueChanged<String> onToggleQBank;
  final ValueChanged<String> onToggleNotes;
  final Function(List<String> videoIds, String chapterName, bool markDone) onBulkToggleVideos;
  final Function(List<String> qbankIds, bool markDone) onBulkToggleQBanks;
  final Function(List<String> noteIds, bool markDone) onBulkToggleNotes;

  const _TimelineChapterSection({
    super.key,
    this.unitKey,
    required this.chapter,
    required this.chapterIndex,
    required this.activeTab,
    required this.completedVideos,
    required this.completedQBanks,
    required this.completedNotes,
    required this.onToggleVideo,
    required this.onToggleQBank,
    required this.onToggleNotes,
    required this.onBulkToggleVideos,
    required this.onBulkToggleQBanks,
    required this.onBulkToggleNotes,
  });

  @override
  State<_TimelineChapterSection> createState() => _TimelineChapterSectionState();
}

class _TimelineChapterSectionState extends State<_TimelineChapterSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final activeTab = widget.activeTab;

    int total = 0;
    int done = 0;
    VoidCallback onBulk = () {};
    int rowCount = 0;

    if (activeTab == 'videos') {
      total = chapter.videos.length;
      done = chapter.videos.where((v) => widget.completedVideos.containsKey(v.id)).length;
      final allDone = total > 0 && done == total;
      final videoIds = chapter.videos.map((v) => v.id).toList();
      onBulk = () => widget.onBulkToggleVideos(videoIds, chapter.name, !allDone);
      rowCount = chapter.videos.length;
    } else if (activeTab == 'qbank') {
      total = chapter.qbanks.length;
      done = chapter.qbanks.where((q) => widget.completedQBanks.containsKey(q.id)).length;
      final allDone = total > 0 && done == total;
      final qbankIds = chapter.qbanks.map((q) => q.id).toList();
      onBulk = () => widget.onBulkToggleQBanks(qbankIds, !allDone);
      rowCount = chapter.qbanks.length;
    } else {
      total = chapter.notes.length;
      done = chapter.notes.where((n) => widget.completedNotes.containsKey(n.id)).length;
      final allDone = total > 0 && done == total;
      final noteIds = chapter.notes.map((n) => n.id).toList();
      onBulk = () => widget.onBulkToggleNotes(noteIds, !allDone);
      rowCount = chapter.notes.length;
    }

    final allDone = total > 0 && done == total;

    return MultiSliver(
      pushPinnedChildren: false,
      children: [
        SliverToBoxAdapter(
          child: _buildBlendedUnitHeader(
            key: widget.unitKey,
            unitName: chapter.name,
            unitNumber: widget.chapterIndex + 1,
            doneCount: done,
            totalCount: total,
            isAllDone: allDone,
            durationLabel: chapter.durationLabel,
            onBulkToggle: onBulk,
            isExpanded: _isExpanded,
            onToggleAccordion: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ),
        if (_isExpanded && rowCount > 0)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if (activeTab == 'videos') {
                  final video = chapter.videos[i];
                  final isDone = widget.completedVideos.containsKey(video.id);
                  return _buildTimelineRow(
                    context: context,
                    id: video.id,
                    isFirst: i == 0,
                    isLast: i == chapter.videos.length - 1,
                    number: video.assignedNumber ?? video.serialNumber,
                    isDone: isDone,
                    title: video.title,
                    detail: video.durationLabel,
                    secondaryDetail: isDone ? _formatDate(widget.completedVideos[video.id]) : null,
                    badgeColor: const Color(0xFFFFFBEB),
                    badgeIcon: Icons.play_arrow_rounded,
                    onToggle: () => widget.onToggleVideo(video.id),
                    onStartTimer: () => context.push(
                      '/timer',
                      extra: {
                        'subjectId': video.subjectId,
                        'topicId': video.id,
                        'topicTitle': video.title,
                        'chapterName': chapter.name,
                        'topicType': 'video',
                        'durationMins': video.durationMins > 0 ? video.durationMins : 15,
                      },
                    ),
                  );
                } else if (activeTab == 'qbank') {
                  final q = chapter.qbanks[i];
                  final isDone = widget.completedQBanks.containsKey(q.id);
                  return _buildTimelineRow(
                    context: context,
                    id: q.id,
                    isFirst: i == 0,
                    isLast: i == chapter.qbanks.length - 1,
                    number: q.assignedNumber ?? q.serialNumber,
                    isDone: isDone,
                    title: q.title,
                    detail: '${q.totalMcqs} MCQs',
                    secondaryDetail: isDone ? _formatDate(widget.completedQBanks[q.id]) : null,
                    badgeColor: const Color(0xFFEFF6FF),
                    badgeIcon: Icons.quiz_rounded,
                    onToggle: () => widget.onToggleQBank(q.id),
                    onStartTimer: () => context.push(
                      '/timer',
                      extra: {
                        'subjectId': q.subjectId,
                        'topicId': q.id,
                        'topicTitle': q.title,
                        'chapterName': chapter.name,
                        'topicType': 'qbank',
                        'durationMins': 30,
                      },
                    ),
                  );
                } else {
                  final note = chapter.notes[i];
                  final isDone = widget.completedNotes.containsKey(note.id);
                  return _buildTimelineRow(
                    context: context,
                    id: note.id,
                    isFirst: i == 0,
                    isLast: i == chapter.notes.length - 1,
                    number: i + 1,
                    isDone: isDone,
                    title: note.title,
                    detail: 'Notes Module',
                    secondaryDetail: isDone ? _formatDate(widget.completedNotes[note.id]) : null,
                    badgeColor: const Color(0xFFF0FDF4),
                    badgeIcon: Icons.menu_book_rounded,
                    onToggle: () => widget.onToggleNotes(note.id),
                    onStartTimer: () => context.push(
                      '/timer',
                      extra: {
                        'subjectId': note.subjectId,
                        'topicId': note.id,
                        'topicTitle': note.title,
                        'chapterName': chapter.name,
                        'topicType': 'notes',
                        'durationMins': 20,
                      },
                    ),
                  );
                }
              },
              childCount: rowCount,
            ),
          ),
      ],
    );
  }

  Widget _buildBlendedUnitHeader({
    required Key? key,
    required String unitName,
    required int unitNumber,
    required int doneCount,
    required int totalCount,
    required bool isAllDone,
    String? durationLabel,
    required VoidCallback onBulkToggle,
    required bool isExpanded,
    required VoidCallback onToggleAccordion,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(top: 16, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Unit Badges & Bulk Action Button & Accordion Toggle
          Row(
            children: [
              ApplePressable(
                pressedScale: 0.94,
                onPressed: onToggleAccordion,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppTheme.parchmentSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight, width: 1),
                        ),
                        child: Text(
                          'UNIT $unitNumber',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.0 : -0.25,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (durationLabel != null && durationLabel.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 10, color: AppTheme.inkForeground),
                      const SizedBox(width: 3.5),
                      Text(
                        durationLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Mark Unit Done bulk action button
              ApplePressable(
                pressedScale: 0.94,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onBulkToggle();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isAllDone
                        ? AppTheme.accentSubtle
                        : AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAllDone ? AppTheme.accentPrimary : AppTheme.borderLight,
                      width: 1.2,
                    ),
                    boxShadow: isAllDone
                        ? [
                            BoxShadow(
                              color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                              offset: const Offset(1, 1.5),
                              blurRadius: 0,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllDone ? Icons.check_circle_rounded : Icons.done_all_rounded,
                        size: 13,
                        color: isAllDone ? AppTheme.accentPrimary : AppTheme.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAllDone
                            ? 'Done ($doneCount/$totalCount)'
                            : 'Mark unit done ($doneCount/$totalCount)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isAllDone ? AppTheme.accentPrimary : AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Dedicated Line for Unit Name: 100% visible, elegant & legible across all 20 subjects
          GestureDetector(
            onTap: onToggleAccordion,
            behavior: HitTestBehavior.opaque,
            child: Text(
              unitName,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppTheme.inkForeground,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: AppTheme.borderLight, thickness: 1, height: 1),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required BuildContext context,
    required String id,
    required bool isFirst,
    required bool isLast,
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
    return RepaintBoundary(
      child: CustomPaint(
        painter: _TimelineConnectorPainter(
          isFirst: isFirst,
          isLast: isLast,
          color: AppTheme.sketchBorderColor.withValues(alpha: 0.35),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left continuous connector bubble
              SizedBox(
                width: 38,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: TimelineCheckBubble(
                      number: number,
                      isDone: isDone,
                      onTap: onToggle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Right topic box card with elastic swipe-to-complete
              Expanded(
                child: Dismissible(
                  key: ValueKey('swipe_$id'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    HapticFeedback.mediumImpact();
                    onToggle();
                    return false; // Elastically snaps back!
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accentEmerald.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accentEmerald,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Complete',
                          style: TextStyle(
                            color: AppTheme.accentEmerald,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.accentEmerald,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  child: _TimelineCard(
                    title: title,
                    detail: detail,
                    secondaryDetail: secondaryDetail,
                    badgeColor: badgeColor,
                    badgeIcon: badgeIcon,
                    isDone: isDone,
                    onToggle: onToggle,
                    onStartTimer: onStartTimer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal is! String) return '';
    try {
      final d = DateTime.parse(dateVal);
      return '${d.day}/${d.month}';
    } catch (_) {
      return '';
    }
  }
}

class DirectionalSlideFade extends StatelessWidget {
  final double direction;
  final Widget child;

  const DirectionalSlideFade({
    super.key,
    required this.direction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, animChild) {
        final offsetX = (1.0 - value) * (direction >= 0 ? 22.0 : -22.0);
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(offsetX, 0),
            child: animChild,
          ),
        );
      },
      child: child,
    );
  }
}

// Lightweight fluid check bubble with self-contained TweenAnimationBuilder
class TimelineCheckBubble extends StatelessWidget {
  final int number;
  final bool isDone;
  final VoidCallback onTap;

  const TimelineCheckBubble({
    super.key,
    required this.number,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      pressedScale: 0.90,
      pressedOpacity: 0.85,
      hapticStyle: HapticStyle.light,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          tween: Tween<double>(begin: 1.0, end: isDone ? 1.05 : 1.0),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone ? AppTheme.accentPrimary : AppTheme.cardWhite,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppTheme.accentPrimary : AppTheme.sketchBorderColor,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDone
                      ? AppTheme.accentPrimary.withValues(alpha: 0.35)
                      : AppTheme.inkForeground.withValues(alpha: 0.12),
                  offset: const Offset(1.5, 2),
                  blurRadius: isDone ? 4 : 0,
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: isDone ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: isDone ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 160),
                    child: AnimatedCheckStroke(
                      checked: isDone,
                      size: 16,
                      color: AppTheme.onAccent,
                    ),
                  ),
                  if (isDone)
                    const Opacity(
                      opacity: 0.0,
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Interactive topic card with RepaintBoundary and non-animating layout
class _TimelineCard extends StatelessWidget {
  final String title;
  final String detail;
  final String? secondaryDetail;
  final Color badgeColor;
  final IconData badgeIcon;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onStartTimer;

  const _TimelineCard({
    required this.title,
    required this.detail,
    required this.secondaryDetail,
    required this.badgeColor,
    required this.badgeIcon,
    required this.isDone,
    required this.onToggle,
    required this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: isDone ? AppTheme.parchmentSurface : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? AppTheme.accentPrimary.withValues(alpha: 0.6) : AppTheme.sketchBorderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkForeground.withValues(alpha: 0.10),
              offset: const Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Entire Card Body is Tappable to Toggle Done/Incomplete with ApplePressable
            Expanded(
              child: ApplePressable(
                pressedScale: 0.98,
                pressedOpacity: 0.90,
                hapticStyle: HapticStyle.light,
                onTap: onToggle,
                child: Row(
                  children: [
                    // Animated Checkbox
                    _AnimatedCardCheckbox(
                      isDone: isDone,
                      onTap: onToggle,
                    ),
                    const SizedBox(width: 10),

                    // Topic Title & Detail
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedStrikeText(
                            text: title,
                            isStruck: isDone,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkForeground,
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
                                  color: AppTheme.mutedText,
                                ),
                              ),
                              if (secondaryDetail != null && secondaryDetail!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• Completed $secondaryDetail',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.accentPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Focus Timer Trigger Icon (Isolated gesture target)
            IconButton(
              icon: const Icon(Icons.timer_outlined, size: 18),
              tooltip: 'Focus on this module',
              color: AppTheme.inkForeground,
              onPressed: onStartTimer,
            ),
          ],
        ),
      ),
    );
  }
}

// Bouncy animated card checkbox with TweenAnimationBuilder
class _AnimatedCardCheckbox extends StatelessWidget {
  final bool isDone;
  final VoidCallback onTap;

  const _AnimatedCardCheckbox({
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          tween: Tween<double>(begin: 1.0, end: isDone ? 1.08 : 1.0),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isDone ? AppTheme.accentPrimary : AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDone ? AppTheme.accentPrimary : AppTheme.sketchBorderColor,
                width: 1.8,
              ),
            ),
            child: Center(
              child: AnimatedCheckStroke(
                checked: isDone,
                size: 14,
                strokeWidth: 2.0,
                color: AppTheme.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Single-pass lightweight connector painter: ZERO IntrinsicHeight multi-pass overhead!
class _TimelineConnectorPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;

  static const double bubbleCenterY = 22.0;
  static const double bubbleCenterX = 19.0;
  static const double bubbleRadius = 14.0;

  _TimelineConnectorPainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const dashLength = 4.0;
    const dashGap = 3.5;

    // Top connector (from top edge to bubble top edge)
    if (!isFirst) {
      double y = 0;
      const endY = bubbleCenterY - bubbleRadius;
      while (y < endY) {
        final nextY = (y + dashLength).clamp(0.0, endY);
        canvas.drawLine(Offset(bubbleCenterX, y), Offset(bubbleCenterX, nextY), paint);
        y += dashLength + dashGap;
      }
    }

    // Bottom connector (from bubble bottom edge to row bottom)
    if (!isLast) {
      double y = bubbleCenterY + bubbleRadius;
      final endY = size.height;
      while (y < endY) {
        final nextY = (y + dashLength).clamp(bubbleCenterY + bubbleRadius, endY);
        canvas.drawLine(Offset(bubbleCenterX, y), Offset(bubbleCenterX, nextY), paint);
        y += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineConnectorPainter oldDelegate) =>
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast ||
      oldDelegate.color != color;
}
