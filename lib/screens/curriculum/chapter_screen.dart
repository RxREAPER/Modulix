import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/syllabus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../data/subjects_metadata.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/animated_check_stroke.dart';
import '../../widgets/animations/animated_strike_text.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/discovery_pulse.dart';
import '../../widgets/video_tile.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';

class ChapterScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final int chapterIndex;
  final String? initialTab;
  final String? targetItemId;

  const ChapterScreen({
    super.key,
    required this.subjectId,
    required this.chapterIndex,
    this.initialTab,
    this.targetItemId,
  });

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  String? _activeTab;
  late final ScrollController _scrollController;
  bool _hasAutoScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.initialTab != null) {
      final tab = widget.initialTab!.toLowerCase();
      if (tab == 'qbank' || tab == 'qbanks') {
        _activeTab = 'qbank';
      } else if (tab == 'notes' || tab == 'note') {
        _activeTab = 'notes';
      } else if (tab == 'videos' || tab == 'video') {
        _activeTab = 'videos';
      }
    }
  }

  @override
  void didUpdateWidget(ChapterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null && widget.initialTab != oldWidget.initialTab) {
      final tab = widget.initialTab!.toLowerCase();
      if (tab == 'qbank' || tab == 'qbanks') {
        _activeTab = 'qbank';
      } else if (tab == 'notes' || tab == 'note') {
        _activeTab = 'notes';
      } else if (tab == 'videos' || tab == 'video') {
        _activeTab = 'videos';
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(subjectProvider(widget.subjectId));
    final appState = ref.watch(appStateProvider).value;
    final meta = subjectMeta(widget.subjectId);

    return subjectAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const SafeArea(child: ModuleTimelineSkeletonView()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: SafeArea(
          child: AppErrorStateView(
            error: e,
            stackTrace: st,
            onRetry: () => ref.refresh(subjectProvider(widget.subjectId)),
          ),
        ),
      ),
      data: (subject) {
        if (subject == null ||
            widget.chapterIndex < 0 ||
            widget.chapterIndex >= subject.chapters.length) {
          return Scaffold(
            backgroundColor: AppTheme.paperBackground,
            appBar: AppBar(
              backgroundColor: AppTheme.paperBackground,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
                onPressed: () => context.pop(),
              ),
            ),
            body: AppErrorStateView(
              headline: 'Chapter not found',
              error: RangeError('Chapter index ${widget.chapterIndex} out of bounds'),
              onPrimaryAction: () => context.pop(),
            ),
          );
        }
        final chapter = subject.chapters[widget.chapterIndex];
        final completedVideos = appState?.currentEdition.completedVideos ?? {};
        final completedQBanks = appState?.currentEdition.completedQBanks ?? {};
        final completedNotes = appState?.currentEdition.completedNotes ?? {};

        final doneVideos = chapter.videos
            .where((v) => completedVideos.containsKey(v.id))
            .length;
        final doneQBanks = chapter.qbanks
            .where((q) => completedQBanks.containsKey(q.id))
            .length;
        final doneNotes = chapter.notes
            .where((n) => completedNotes.containsKey(n.id))
            .length;

        final hasVideos = chapter.videos.isNotEmpty;
        final hasQBanks = chapter.qbanks.isNotEmpty;
        final hasNotes = chapter.notes.isNotEmpty;

        final activeTab = _activeTab ??
            (hasVideos
                ? 'videos'
                : (hasQBanks ? 'qbank' : (hasNotes ? 'notes' : 'videos')));

        final double progressValue;
        if (activeTab == 'videos') {
          progressValue = chapter.totalVideos == 0 ? 0.0 : doneVideos / chapter.totalVideos;
        } else if (activeTab == 'qbank') {
          progressValue = chapter.totalQBanks == 0 ? 0.0 : doneQBanks / chapter.totalQBanks;
        } else {
          progressValue = chapter.totalNotes == 0 ? 0.0 : doneNotes / chapter.totalNotes;
        }

        final categoryCount =
            (hasVideos ? 1 : 0) + (hasQBanks ? 1 : 0) + (hasNotes ? 1 : 0);

        if (!_hasAutoScrolled && widget.targetItemId != null) {
          _hasAutoScrolled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            int targetIdx = -1;
            if (activeTab == 'qbank') {
              targetIdx = chapter.qbanks.indexWhere((q) => q.id == widget.targetItemId);
            } else if (activeTab == 'notes') {
              targetIdx = chapter.notes.indexWhere((n) => n.id == widget.targetItemId);
            } else {
              targetIdx = chapter.videos.indexWhere((v) => v.id == widget.targetItemId);
            }
            if (targetIdx > 0 && _scrollController.hasClients) {
              final targetOffset = (targetIdx * 82.0).clamp(0.0, _scrollController.position.maxScrollExtent);
              _scrollController.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
              );
            }
          });
        }

        final canPop = ModalRoute.of(context)?.canPop ?? false;
        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            try {
              context.go('/curriculum/${widget.subjectId}');
            } catch (_) {}
          },
          child: Scaffold(
            backgroundColor: AppTheme.paperBackground,
            appBar: AppBar(
              backgroundColor: AppTheme.paperBackground,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    try {
                      context.go('/curriculum/${widget.subjectId}');
                    } catch (_) {}
                  }
                },
              ),
              title: Text(
                chapter.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.inkForeground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.timer_outlined, size: 20),
                  tooltip: 'Focus on this unit',
                  color: AppTheme.inkForeground,
                  onPressed: () {
                    context.push('/timer', extra: {
                      'subjectId': subject.id,
                      'subjectName': subject.displayName,
                      'topicTitle': chapter.name,
                      'chapterName': chapter.name,
                      'topicType': 'unit',
                      'durationMins': chapter.totalMinutes > 0
                          ? chapter.totalMinutes.round()
                          : 30,
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: DiscoveryPulse(
                      prefKey: 'pulse_bulk_complete_seen',
                      pulseColor: meta.accent,
                      borderRadius: 10,
                      child: ApplePressable(
                        pressedScale: 0.94,
                        onPressed: () => _confirmBulkComplete(
                          context,
                          ref,
                          subject,
                          chapter,
                          activeTab,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: meta.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: meta.accent.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.done_all_rounded,
                                  size: 15, color: meta.accent),
                              const SizedBox(width: 4),
                              Text(
                                'Bulk',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: meta.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: meta.accent.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(meta.accent),
                  minHeight: 3,
                ),
              ),
            ),
            body: FadeSlideEntrance(
              durationMs: 180,
              slideY: 10.0,
              child: Column(
                children: [
                  if (categoryCount > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.parchmentSurface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.borderLight, width: 1),
                        ),
                        child: Row(
                          children: [
                            if (hasVideos)
                              Expanded(
                                child: _ModuleTabPill(
                                  title: 'Videos (${chapter.totalVideos})',
                                  icon: Icons.play_circle_outline_rounded,
                                  isSelected: activeTab == 'videos',
                                  accentColor: meta.accent,
                                  onTap: () =>
                                      setState(() => _activeTab = 'videos'),
                                ),
                              ),
                            if (hasQBanks) ...[
                              if (hasVideos) const SizedBox(width: 4),
                              Expanded(
                                child: _ModuleTabPill(
                                  title: 'Q-Bank (${chapter.totalQBanks})',
                                  icon: Icons.quiz_outlined,
                                  isSelected: activeTab == 'qbank',
                                  accentColor: meta.accent,
                                  onTap: () =>
                                      setState(() => _activeTab = 'qbank'),
                                ),
                              ),
                            ],
                            if (hasNotes) ...[
                              if (hasVideos || hasQBanks)
                                const SizedBox(width: 4),
                              Expanded(
                                child: _ModuleTabPill(
                                  title: 'Notes (${chapter.totalNotes})',
                                  icon: Icons.menu_book_rounded,
                                  isSelected: activeTab == 'notes',
                                  accentColor: meta.accent,
                                  onTap: () =>
                                      setState(() => _activeTab = 'notes'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      children: [
                        if (activeTab == 'videos') ...[
                          _StatChip(
                            label: '$doneVideos / ${chapter.totalVideos} done',
                            icon: Icons.check_circle_outline_rounded,
                            color: meta.accent,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label:
                                '${chapter.totalVideos - doneVideos} remaining',
                            icon: Icons.radio_button_unchecked_rounded,
                            color: Colors.grey,
                          ),
                          if (chapter.durationLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _StatChip(
                              label: chapter.durationLabel,
                              icon: Icons.schedule_rounded,
                              color: AppTheme.inkForeground,
                            ),
                          ],
                        ] else if (activeTab == 'qbank') ...[
                          _StatChip(
                            label:
                                '$doneQBanks / ${chapter.totalQBanks} done',
                            icon: Icons.check_circle_outline_rounded,
                            color: meta.accent,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: '${chapter.totalMcqs} MCQs',
                            icon: Icons.quiz_outlined,
                            color: AppTheme.inkForeground,
                          ),
                        ] else ...[
                          _StatChip(
                            label: '$doneNotes / ${chapter.totalNotes} done',
                            icon: Icons.check_circle_outline_rounded,
                            color: meta.accent,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label:
                                '${chapter.totalNotes} module${chapter.totalNotes == 1 ? '' : 's'}',
                            icon: Icons.menu_book_rounded,
                            color: AppTheme.inkForeground,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Module list
                  Expanded(
                    child: _buildActiveTabList(
                      context: context,
                      ref: ref,
                      subject: subject,
                      chapter: chapter,
                      meta: meta,
                      activeTab: activeTab,
                      completedVideos: completedVideos,
                      completedQBanks: completedQBanks,
                      completedNotes: completedNotes,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTabList({
    required BuildContext context,
    required WidgetRef ref,
    required Subject subject,
    required Chapter chapter,
    required SubjectMeta meta,
    required String activeTab,
    required Map<String, dynamic> completedVideos,
    required Map<String, dynamic> completedQBanks,
    required Map<String, dynamic> completedNotes,
  }) {
    if (activeTab == 'qbank') {
      if (chapter.qbanks.isEmpty) {
        return const Center(
          child: Text(
            'No Q-Bank topics in this unit',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        );
      }
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: chapter.qbanks.length,
        itemBuilder: (context, i) {
          final qbank = chapter.qbanks[i];
          final isCompleted = completedQBanks.containsKey(qbank.id);
          final completedAt = completedQBanks[qbank.id];
          final isTarget = widget.targetItemId != null && widget.targetItemId == qbank.id;

          final tile = _QBankTopicTile(
            topic: qbank,
            serialNumber:
                qbank.serialNumber > 0 ? qbank.serialNumber : (i + 1),
            isCompleted: isCompleted,
            completedAt: completedAt is String ? completedAt : null,
            accentColor: meta.accent,
            onToggle: () {
              ref.read(appStateProvider.notifier).toggleQBankComplete(qbank.id);
            },
            onStartTimer: () {
              context.push('/timer', extra: {
                'subjectId': subject.id,
                'subjectName': subject.displayName,
                'topicId': qbank.id,
                'topicTitle': qbank.title,
                'chapterName': chapter.name,
                'topicType': 'qbank',
                'durationMins':
                    (qbank.totalMcqs * 1.5).round().clamp(10, 60),
              });
            },
          );

          if (!isTarget) return tile;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: meta.accent, width: 2.0),
              color: meta.accent.withValues(alpha: 0.08),
            ),
            child: tile,
          );
        },
      );
    } else if (activeTab == 'notes') {
      if (chapter.notes.isEmpty) {
        return const Center(
          child: Text(
            'No notes in this unit',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        );
      }
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: chapter.notes.length,
        itemBuilder: (context, i) {
          final note = chapter.notes[i];
          final isCompleted = completedNotes.containsKey(note.id);
          final completedAt = completedNotes[note.id];
          final isTarget = widget.targetItemId != null && widget.targetItemId == note.id;

          final tile = _NotesItemTile(
            note: note,
            serialNumber: i + 1,
            isCompleted: isCompleted,
            completedAt: completedAt is String ? completedAt : null,
            accentColor: meta.accent,
            onToggle: () {
              ref.read(appStateProvider.notifier).toggleNotesComplete(note.id);
            },
            onStartTimer: () {
              context.push('/timer', extra: {
                'subjectId': subject.id,
                'subjectName': subject.displayName,
                'topicId': note.id,
                'topicTitle': note.title,
                'chapterName': chapter.name,
                'topicType': 'notes',
                'durationMins': 20,
              });
            },
          );

          if (!isTarget) return tile;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: meta.accent, width: 2.0),
              color: meta.accent.withValues(alpha: 0.08),
            ),
            child: tile,
          );
        },
      );
    }

    // Default: Videos
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: chapter.videos.length,
      itemBuilder: (context, i) {
        final video = chapter.videos[i];
        final isCompleted = completedVideos.containsKey(video.id);
        final completedAt = completedVideos[video.id];
        final isTarget = widget.targetItemId != null && widget.targetItemId == video.id;

        final globalNumber = video.serialNumber > 0
            ? video.serialNumber
            : (subject.allVideos.indexWhere((v) => v.id == video.id) + 1);

        final tile = VideoTile(
          video: video,
          serialNumber: globalNumber > 0 ? globalNumber : (i + 1),
          isCompleted: isCompleted,
          completedAt: completedAt is String ? completedAt : null,
          accentColor: meta.accent,
          onToggle: () {
            if (isCompleted) {
              ref
                  .read(appStateProvider.notifier)
                  .markVideoIncomplete(video.id);
            } else {
              ref.read(appStateProvider.notifier).markVideoComplete(video.id);
            }
          },
          onStartTimer: () {
            context.push('/timer', extra: {
              'subjectId': subject.id,
              'subjectName': subject.displayName,
              'topicId': video.id,
              'topicTitle': video.title,
              'chapterName': chapter.name,
              'topicType': 'video',
              'durationMins': video.durationMins > 0 ? video.durationMins : 30,
            });
          },
        );

        if (!isTarget) return tile;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: meta.accent, width: 2.0),
            color: meta.accent.withValues(alpha: 0.08),
          ),
          child: tile,
        );
      },
    );
  }

  void _confirmBulkComplete(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
    Chapter chapter,
    String currentTab,
  ) {
    HapticFeedback.lightImpact();
    final String title;
    final String content;
    final VoidCallback onConfirm;

    if (currentTab == 'qbank') {
      title = 'Bulk Complete Q-Bank';
      content =
          'Mark all ${chapter.qbanks.length} Q-Bank topics in "${chapter.name}" as completed?';
      onConfirm = () {
        final qbankIds = chapter.qbanks.map((q) => q.id).toList();
        ref.read(appStateProvider.notifier).markQBanksBulk(qbankIds);
      };
    } else if (currentTab == 'notes') {
      title = 'Bulk Complete Notes';
      content =
          'Mark all ${chapter.notes.length} notes in "${chapter.name}" as completed?';
      onConfirm = () {
        final noteIds = chapter.notes.map((n) => n.id).toList();
        ref.read(appStateProvider.notifier).markNotesBulk(noteIds);
      };
    } else {
      title = 'Bulk Complete';
      content =
          'Mark all ${chapter.videos.length} lectures in "${chapter.name}" as completed?';
      onConfirm = () {
        final videoIds = chapter.videos.map((v) => v.id).toList();
        ref.read(appStateProvider.notifier).bulkCompleteChapter(
              chapter.name,
              videoIds,
            );
      };
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.sketchBorderColor, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.done_all_rounded, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.inkForeground,
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkForeground,
              foregroundColor: AppTheme.paperBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              onConfirm();
            },
            child: const Text(
              'Mark Complete',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTabPill extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModuleTabPill({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      pressedScale: 0.96,
      hapticStyle: HapticStyle.selection,
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.inkForeground.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? accentColor : AppTheme.mutedText,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      isSelected ? AppTheme.inkForeground : AppTheme.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QBankTopicTile extends StatelessWidget {
  final QBankTopic topic;
  final int serialNumber;
  final bool isCompleted;
  final String? completedAt;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onStartTimer;

  const _QBankTopicTile({
    required this.topic,
    required this.serialNumber,
    required this.isCompleted,
    this.completedAt,
    required this.accentColor,
    required this.onToggle,
    required this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const badgeColor = Color(0xFF8B5CF6);

    return ApplePressable(
      pressedScale: 0.97,
      pressedOpacity: 0.94,
      hapticStyle: HapticStyle.selection,
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.16)
                      : badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: isCompleted
                      ? Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.quiz_rounded,
                    size: 20,
                    color: isCompleted ? Colors.green.shade800 : badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedStrikeText(
                      text: topic.title,
                      isStruck: isCompleted,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      strikeColor: cs.onSurface.withValues(alpha: 0.5),
                      strikeThickness: 1.8,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.totalMcqs} MCQs',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        if (isCompleted && completedAt != null) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCompletionDate(completedAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.timer_outlined, size: 18),
                tooltip: 'Focus on this topic',
                color: AppTheme.inkForeground.withValues(alpha: 0.65),
                onPressed: onStartTimer,
              ),
              const SizedBox(width: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : cs.outline.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedCheckStroke(
                    checked: isCompleted,
                    size: 16,
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesItemTile extends StatelessWidget {
  final NotesItem note;
  final int serialNumber;
  final bool isCompleted;
  final String? completedAt;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onStartTimer;

  const _NotesItemTile({
    required this.note,
    required this.serialNumber,
    required this.isCompleted,
    this.completedAt,
    required this.accentColor,
    required this.onToggle,
    required this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const badgeColor = Color(0xFF0D9488);

    return ApplePressable(
      pressedScale: 0.97,
      pressedOpacity: 0.94,
      hapticStyle: HapticStyle.selection,
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.16)
                      : badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: isCompleted
                      ? Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 20,
                    color: isCompleted ? Colors.green.shade800 : badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedStrikeText(
                      text: note.title,
                      isStruck: isCompleted,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      strikeColor: cs.onSurface.withValues(alpha: 0.5),
                      strikeThickness: 1.8,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${note.pages} pages',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        if (isCompleted && completedAt != null) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCompletionDate(completedAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.timer_outlined, size: 18),
                tooltip: 'Focus on this note',
                color: AppTheme.inkForeground.withValues(alpha: 0.65),
                onPressed: onStartTimer,
              ),
              const SizedBox(width: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : cs.outline.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedCheckStroke(
                    checked: isCompleted,
                    size: 16,
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

String _formatCompletionDate(String isoTimestamp) {
  try {
    final t = DateTime.parse(isoTimestamp);
    final now = DateTime.now();
    final diff = now.difference(t).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    return '${t.day}/${t.month}';
  } catch (_) {
    return '';
  }
}
