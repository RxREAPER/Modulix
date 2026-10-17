import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/syllabus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/curriculum_sort_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/elastic_ink_pill.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/curriculum/subject_header_card.dart';
import '../../widgets/curriculum/module_timeline.dart';
import '../../widgets/in_situ_hint_pill.dart';


class SubjectScrollHelper {
  static const double headerBaseOffset = 295.0;
  static const double unitHeaderHeightNormal = 90.0;
  static const double unitHeaderHeightLong = 110.0;
  static const double itemHeightNormal = 81.0;
  static const double itemHeightLong = 86.0;

  static double calculateUnitOffset({
    required int chapterIndex,
    required Subject subject,
    required String activeTab,
  }) {
    final displayChapters = (activeTab == 'qbank' && subject.qbankChapters.isNotEmpty)
        ? subject.qbankChapters
        : subject.chapters;

    double offset = headerBaseOffset;
    for (int i = 0; i < chapterIndex && i < displayChapters.length; i++) {
      final ch = displayChapters[i];
      final isLongHeader = ch.name.length > 32;
      offset += isLongHeader ? unitHeaderHeightLong : unitHeaderHeightNormal;

      if (activeTab == 'videos') {
        for (final video in ch.videos) {
          offset += video.title.length > 32 ? itemHeightLong : itemHeightNormal;
        }
      } else if (activeTab == 'qbank') {
        for (final q in ch.qbanks) {
          offset += q.title.length > 32 ? itemHeightLong : itemHeightNormal;
        }
      } else {
        for (final note in ch.notes) {
          offset += note.title.length > 32 ? itemHeightLong : itemHeightNormal;
        }
      }
    }
    return offset;
  }
}

class SubjectScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const SubjectScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen>
    with SingleTickerProviderStateMixin {
  String _activeTab = 'videos'; // 'videos' | 'qbank' | 'notes'
  int _slideDirection = 1;
  final Map<int, GlobalKey> _unitKeys = {};
  late final ScrollController _scrollController;
  late final AnimationController _tabContentController;
  late final Animation<double> _tabFadeAnimation;
  late final Animation<double> _tabSlideAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabContentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _tabFadeAnimation = CurvedAnimation(
      parent: _tabContentController,
      curve: Curves.easeOutCubic,
    );
    _tabSlideAnimation = CurvedAnimation(
      parent: _tabContentController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          ref.read(recentSubjectsProvider.notifier).recordVisit(widget.subjectId);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabContentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToUnit(int chapterIndex, Subject subject, String activeTab) {
    if (!_scrollController.hasClients) return;

    // 1. Determine target offset
    final key = _unitKeys[chapterIndex];
    double targetOffset;

    final currentContext = key?.currentContext;
    if (currentContext != null) {
      final box = currentContext.findRenderObject() as RenderBox?;
      final scrollable = Scrollable.of(currentContext).context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && scrollable != null) {
        final relDy = box.localToGlobal(Offset.zero, ancestor: scrollable).dy;
        targetOffset = _scrollController.offset + relDy;
      } else {
        targetOffset = SubjectScrollHelper.calculateUnitOffset(
          chapterIndex: chapterIndex,
          subject: subject,
          activeTab: activeTab,
        );
      }
    } else {
      targetOffset = SubjectScrollHelper.calculateUnitOffset(
        chapterIndex: chapterIndex,
        subject: subject,
        activeTab: activeTab,
      );
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedTarget = targetOffset.clamp(0.0, maxScroll);
    final distance = (clampedTarget - _scrollController.offset).abs();

    if (distance < 2.0) return;

    // 2. Distance-proportional smooth duration (natural physics easing)
    // Short leaps: ~380ms. Long sweeps: up to ~620ms.
    final durationMs = (380 + (distance / 14.0)).clamp(380.0, 620.0).toInt();

    // 3. Single-pass smooth animation using fastOutSlowIn
    _scrollController
        .animateTo(
      clampedTarget,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.fastOutSlowIn,
    )
        .then((_) {
      _fineTuneScrollToKey(chapterIndex);
    });
  }

  void _fineTuneScrollToKey(int chapterIndex, [int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final postKey = _unitKeys[chapterIndex];
      final renderBox = postKey?.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final scrollableBox =
            Scrollable.of(postKey!.currentContext!).context.findRenderObject() as RenderBox?;
        if (scrollableBox != null) {
          final dy = renderBox.localToGlobal(Offset.zero, ancestor: scrollableBox).dy;
          // If already aligned within 6.0 pixels, do not trigger a second animation!
          // This eliminates the double-scroll stutter completely.
          if (dy.abs() <= 6.0) return;

          final correctionTarget = (_scrollController.offset + dy)
              .clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.animateTo(
            correctionTarget,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
          );
          return;
        }
      } else if (attempt < 2) {
        _fineTuneScrollToKey(chapterIndex, attempt + 1);
      }
    });
  }

  Future<void> _openIndexSheet({
    required BuildContext context,
    required Subject subject,
    required String activeTab,
    required Map<String, dynamic> completedVideos,
    required Map<String, dynamic> completedQBanks,
    required Map<String, dynamic> completedNotes,
  }) async {
    HapticFeedback.selectionClick();
    final displayChapters = (activeTab == 'qbank' && subject.qbankChapters.isNotEmpty)
        ? subject.qbankChapters
        : subject.chapters;

    // Precompute unit stats once to eliminate per-frame recalculations during scrolling
    final unitStats = List.generate(displayChapters.length, (idx) {
      final chapter = displayChapters[idx];
      int totalCount = 0;
      int doneCount = 0;
      if (activeTab == 'videos') {
        totalCount = chapter.videos.length;
        doneCount = chapter.videos.where((v) => completedVideos.containsKey(v.id)).length;
      } else if (activeTab == 'qbank') {
        totalCount = chapter.qbanks.length;
        doneCount = chapter.qbanks.where((q) => completedQBanks.containsKey(q.id)).length;
      } else {
        totalCount = chapter.notes.length;
        doneCount = chapter.notes.where((n) => completedNotes.containsKey(n.id)).length;
      }
      final isComplete = totalCount > 0 && doneCount == totalCount;
      final percent = totalCount > 0 ? (doneCount / totalCount) : 0.0;
      return (totalCount: totalCount, doneCount: doneCount, isComplete: isComplete, percent: percent);
    });

    final selectedUnit = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 200),
        reverseDuration: Duration(milliseconds: 150),
      ),
      builder: (ctx) {
        final categoryTitle = activeTab == 'videos'
            ? 'Videos'
            : activeTab == 'qbank'
                ? 'Q-Bank Topics'
                : 'Notes';

        final categoryColor = AppTheme.accentPrimary;

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.90,
          builder: (_, scrollController) {
            return RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
              child: Column(
                children: [
                  // Top Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with category badge & unit count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.format_list_bulleted_rounded, size: 14, color: categoryColor),
                              const SizedBox(width: 4),
                              Text(
                                categoryTitle.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Unit Index (${displayChapters.length} Units)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  // List of Units
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      cacheExtent: 350.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: displayChapters.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (context, idx) {
                        final chapter = displayChapters[idx];
                        final stat = unitStats[idx];
                        final totalCount = stat.totalCount;
                        final doneCount = stat.doneCount;
                        final isComplete = stat.isComplete;
                        final percent = stat.percent;

                        return ApplePressable(
                          pressedScale: 0.97,
                          pressedOpacity: 0.88,
                          hapticStyle: HapticStyle.selection,
                          onTap: () {
                            Navigator.pop(ctx, idx);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Row(
                              children: [
                                // Unit Number Tag
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isComplete
                                        ? AppTheme.accentSubtle
                                        : AppTheme.parchmentSurface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isComplete
                                          ? AppTheme.accentPrimary
                                          : AppTheme.borderLight,
                                    ),
                                  ),
                                  child: Center(
                                    child: isComplete
                                        ? Icon(Icons.check, size: 16, color: AppTheme.accentPrimary)
                                        : Text(
                                            '${idx + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'monospace',
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title and progress bar
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chapter.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isComplete
                                              ? Colors.grey.shade600
                                              : AppTheme.inkForeground,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        height: 4,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppTheme.borderLight,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: percent.clamp(0.0, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isComplete ? AppTheme.accentPrimary : categoryColor,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Count badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isComplete
                                        ? AppTheme.accentSubtle
                                        : AppTheme.parchmentSurface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$doneCount/$totalCount',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                          color: isComplete
                                              ? AppTheme.accentPrimary
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                      if (chapter.durationLabel.isNotEmpty) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '· ${chapter.durationLabel}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

    if (selectedUnit != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) {
        _scrollToUnit(selectedUnit, subject, activeTab);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(subjectProvider(widget.subjectId));
    final appState = ref.watch(appStateProvider).value;

    return subjectAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: Text('Error: $e')),
      ),
      data: (subject) {
        if (subject == null) {
          return Scaffold(
            backgroundColor: AppTheme.paperBackground,
            body: const Center(child: Text('Subject not found')),
          );
        }

        final currentEdition = appState?.currentEdition;
        final completedVideos = currentEdition?.completedVideos ?? {};
        final completedQBanks = currentEdition?.completedQBanks ?? {};
        final completedNotes = currentEdition?.completedNotes ?? {};

        final completedVideosCount = subject.allVideos
            .where((v) => completedVideos.containsKey(v.id))
            .length;
        final completedQBanksCount = subject.allQBanks
            .where((q) => completedQBanks.containsKey(q.id))
            .length;
        final completedNotesCount = subject.allNotes
            .where((n) => completedNotes.containsKey(n.id))
            .length;

        // Populate unit keys for active tab chapters
        final displayChapters = (_activeTab == 'qbank' && subject.qbankChapters.isNotEmpty)
            ? subject.qbankChapters
            : subject.chapters;
        if (_unitKeys.length > displayChapters.length) {
          _unitKeys.removeWhere((k, _) => k >= displayChapters.length);
        }
        for (int i = 0; i < displayChapters.length; i++) {
          _unitKeys.putIfAbsent(i, () => GlobalKey());
        }

        final canPop = ModalRoute.of(context)?.canPop ?? false;
        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            try {
              context.go('/curriculum');
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
                      context.go('/curriculum');
                    } catch (_) {}
                  }
                },
              ),
              title: Text(
                subject.displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.format_list_bulleted_rounded, color: AppTheme.inkForeground),
                  tooltip: 'Unit Index',
                  onPressed: () => _openIndexSheet(
                    context: context,
                    subject: subject,
                    activeTab: _activeTab,
                    completedVideos: completedVideos,
                    completedQBanks: completedQBanks,
                    completedNotes: completedNotes,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.timer_outlined, color: AppTheme.inkForeground),
                  tooltip: 'Start Focus Reading Timer',
                  onPressed: () => context.push(
                    '/timer',
                    extra: {
                      'subjectId': subject.id,
                      'subjectName': subject.displayName,
                      'topicType': 'standalone',
                    },
                  ),
                ),
              ],
            ),
            body: CustomScrollView(
              controller: _scrollController,
              cacheExtent: 450.0,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Large Rectangular Subject Hero Card (tappable to Analytics)
                        SubjectHeaderCard(
                          subject: subject,
                          completedVideosCount: completedVideosCount,
                          completedQBanksCount: completedQBanksCount,
                          completedNotesCount: completedNotesCount,
                          onTapAnalytics: () => context.go('/curriculum/${widget.subjectId}/analytics'),
                        ),

                        const SizedBox(height: 18),

                        // 2. 3 Categories Navigation Tab Bar (Videos | Q-Bank | Notes)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const double spacing = 8.0;
                            const double tabHeight = 44.0;
                            final double tabWidth = (constraints.maxWidth - (spacing * 2)) / 3;
                            final int activeIndex = switch (_activeTab) {
                              'qbank' => 1,
                              'notes' => 2,
                              _ => 0,
                            };
                            final Rect pillRect = Rect.fromLTWH(
                              activeIndex * (tabWidth + spacing),
                              0,
                              tabWidth,
                              tabHeight,
                            );

                            return SizedBox(
                              height: tabHeight,
                              child: Stack(
                                children: [
                                  // Background slots
                                  Row(
                                    children: [
                                      for (int i = 0; i < 3; i++) ...[
                                        if (i > 0) const SizedBox(width: spacing),
                                        Expanded(
                                          child: Container(
                                            height: tabHeight,
                                            decoration: BoxDecoration(
                                              color: AppTheme.cardWhite,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: AppTheme.borderLight,
                                                width: 1.6,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Fluid Elastic Ink Pill indicator
                                  ElasticInkPill(
                                    targetRect: pillRect,
                                    fillColor: AppTheme.accentPrimary,
                                    strokeColor: AppTheme.sketchBorderColor,
                                    strokeWidth: 1.6,
                                    borderRadius: 14.0,
                                    isSketchy: true,
                                  ),
                                  // Interactive category tabs
                                  Row(
                                    children: [
                                      _categoryTab(
                                        id: 'videos',
                                        index: 0,
                                        label: 'Videos',
                                        count: subject.totalVideos,
                                        icon: Icons.play_arrow_rounded,
                                      ),
                                      const SizedBox(width: spacing),
                                      _categoryTab(
                                        id: 'qbank',
                                        index: 1,
                                        label: 'Q-Bank',
                                        count: subject.totalQBanks,
                                        icon: Icons.quiz_rounded,
                                      ),
                                      const SizedBox(width: spacing),
                                      _categoryTab(
                                        id: 'notes',
                                        index: 2,
                                        label: 'Notes',
                                        count: subject.totalNotes,
                                        icon: Icons.menu_book_rounded,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // Quick Jump to Unit (Index) Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MODULES & TOPICS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openIndexSheet(
                                  context: context,
                                  subject: subject,
                                  activeTab: _activeTab,
                                  completedVideos: completedVideos,
                                  completedQBanks: completedQBanks,
                                  completedNotes: completedNotes,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.format_list_bulleted_rounded, size: 13, color: Colors.grey.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Jump to Unit (Index) ▾',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_activeTab == 'videos') ...[
                          const SizedBox(height: 6),
                          const InSituHintPill(
                            prefKey: 'hint_swipe_video_seen',
                            message: 'Swipe a video left to mark it complete',
                            icon: Icons.swipe_left_alt_rounded,
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // 3. Fully Virtualized Slivers for Timeline Items
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 240),
                  sliver: SliverFadeTransition(
                    opacity: _tabFadeAnimation,
                    sliver: ModuleTimeline(
                      key: ValueKey('${subject.id}_$_activeTab'),
                      subject: subject,
                      activeTab: _activeTab,
                      unitKeys: _unitKeys,
                      slideDirection: _slideDirection,
                      contentAnimation: _tabSlideAnimation,
                      completedVideos: completedVideos,
                      completedQBanks: completedQBanks,
                      completedNotes: completedNotes,
                      onToggleVideo: (vid) {
                        final notifier = ref.read(appStateProvider.notifier);
                        if (completedVideos.containsKey(vid)) {
                          notifier.markVideoIncomplete(vid);
                        } else {
                          notifier.markVideoComplete(vid);
                        }
                      },
                      onToggleQBank: (qid) {
                        ref.read(appStateProvider.notifier).toggleQBankComplete(qid);
                      },
                      onToggleNotes: (nid) {
                        ref.read(appStateProvider.notifier).toggleNotesComplete(nid);
                      },
                      onBulkToggleVideos: (videoIds, chapterName, markDone) {
                        final notifier = ref.read(appStateProvider.notifier);
                        if (markDone) {
                          notifier.markVideosBulk(videoIds, chapterName);
                        } else {
                          notifier.unmarkVideosBulk(videoIds, chapterName);
                        }
                      },
                      onBulkToggleQBanks: (qbankIds, markDone) {
                        final notifier = ref.read(appStateProvider.notifier);
                        if (markDone) {
                          notifier.markQBanksBulk(qbankIds);
                        } else {
                          notifier.unmarkQBanksBulk(qbankIds);
                        }
                      },
                      onBulkToggleNotes: (noteIds, markDone) {
                        final notifier = ref.read(appStateProvider.notifier);
                        if (markDone) {
                          notifier.markNotesBulk(noteIds);
                        } else {
                          notifier.unmarkNotesBulk(noteIds);
                        }
                      },
                    ).buildSliver(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _categoryTab({
    required String id,
    required int index,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _activeTab == id;

    return Expanded(
      child: ApplePressable(
        pressedScale: 0.94,
        onTap: () {
          HapticFeedback.selectionClick();
          if (_activeTab != id) {
            final oldIndex = switch (_activeTab) {
              'qbank' => 1,
              'notes' => 2,
              _ => 0,
            };
            setState(() {
              _slideDirection = index > oldIndex ? 1 : -1;
              _activeTab = id;
              _unitKeys.clear();
            });
            _tabContentController.forward(from: 0.0);

            if (_scrollController.hasClients &&
                _scrollController.offset > SubjectScrollHelper.headerBaseOffset) {
              _scrollController.animateTo(
                SubjectScrollHelper.headerBaseOffset,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              );
            }
          }
        },
        child: Container(
          height: 44.0,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    icon,
                    key: ValueKey('$id-$isSelected'),
                    size: 15,
                    color: isSelected ? AppTheme.onAccent : AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(width: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isSelected ? AppTheme.onAccent : AppTheme.inkForeground,
                  ),
                  child: Text(label),
                ),
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.onAccent.withValues(alpha: 0.25)
                        : AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: isSelected ? AppTheme.onAccent : AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
