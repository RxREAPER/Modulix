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
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/curriculum/subject_header_card.dart';
import '../../widgets/curriculum/unit_card.dart';
import '../../widgets/in_situ_hint_pill.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';


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

  static double calculateUnitCardOffset({
    required int chapterIndex,
  }) {
    return headerBaseOffset + (chapterIndex * 152.0);
  }
}

class _IndexSheetResult {
  final int unitIndex;
  const _IndexSheetResult(this.unitIndex);
}

class SubjectScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const SubjectScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen> {
  final Map<int, GlobalKey> _unitKeys = {};
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToUnit(int chapterIndex, Subject subject, [String activeTab = 'videos']) {
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
        targetOffset = SubjectScrollHelper.calculateUnitCardOffset(
          chapterIndex: chapterIndex,
        );
      }
    } else {
      targetOffset = SubjectScrollHelper.calculateUnitCardOffset(
        chapterIndex: chapterIndex,
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
    required Subject subject,
    String activeTab = 'videos',
    required Map<String, dynamic> completedVideos,
    required Map<String, dynamic> completedQBanks,
    required Map<String, dynamic> completedNotes,
  }) async {
    HapticFeedback.selectionClick();
    // Strictly align with subject.chapters to eliminate mismatch across module types
    final displayChapters = subject.chapters;

    // Precompute unit stats once to eliminate per-frame recalculations during scrolling
    final unitStats = List.generate(displayChapters.length, (idx) {
      final chapter = displayChapters[idx];
      final totalVideos = chapter.videos.length;
      final doneVideos = chapter.videos.where((v) => completedVideos.containsKey(v.id)).length;
      final totalQBanks = chapter.qbanks.length;
      final doneQBanks = chapter.qbanks.where((q) => completedQBanks.containsKey(q.id)).length;
      final totalNotes = chapter.notes.length;
      final doneNotes = chapter.notes.where((n) => completedNotes.containsKey(n.id)).length;

      final totalCount = totalVideos + totalQBanks + totalNotes;
      final doneCount = doneVideos + doneQBanks + doneNotes;
      final isComplete = totalCount > 0 && doneCount == totalCount;
      final percent = totalCount > 0 ? (doneCount / totalCount) : 0.0;
      return (
        totalCount: totalCount,
        doneCount: doneCount,
        isComplete: isComplete,
        percent: percent,
        totalVideos: totalVideos,
        doneVideos: doneVideos,
        totalQBanks: totalQBanks,
        doneQBanks: doneQBanks,
        totalNotes: totalNotes,
        doneNotes: doneNotes,
      );
    });

    final selectedUnit = await showModalBottomSheet<_IndexSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 200),
        reverseDuration: Duration(milliseconds: 150),
      ),
      builder: (ctx) {
        final categoryColor = AppTheme.accentPrimary;

        return DraggableScrollableSheet(
          initialChildSize: 0.70,
          minChildSize: 0.4,
          maxChildSize: 0.92,
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
                              Icon(Icons.layers_outlined, size: 14, color: categoryColor),
                              const SizedBox(width: 4),
                              Text(
                                'UNITS',
                                style: AppTypography.microBadge(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
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
                            style: AppTypography.dialogTitle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: displayChapters.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (context, idx) {
                        final chapter = displayChapters[idx];
                        final isComplete = unitStats[idx].isComplete;

                        final unitNumberFormatted = (idx + 1).toString().padLeft(2, '0');
                        return ApplePressable(
                          pressedScale: 0.98,
                          pressedOpacity: 0.88,
                          hapticStyle: HapticStyle.selection,
                          onTap: () {
                            Navigator.pop(ctx, _IndexSheetResult(idx));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Row(
                              children: [
                                // Unit Number Tag
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isComplete
                                        ? AppTheme.accentSubtle
                                        : AppTheme.parchmentSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isComplete
                                          ? AppTheme.accentPrimary
                                          : AppTheme.borderLight,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: isComplete
                                        ? Icon(Icons.check_rounded, size: 18, color: AppTheme.accentPrimary)
                                        : Text(
                                            unitNumberFormatted,
                                            style: AppTypography.metricValue(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Title strictly for navigation
                                Expanded(
                                  child: Text(
                                    chapter.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.cardTitle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: isComplete
                                          ? Colors.grey.shade600
                                          : AppTheme.inkForeground,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: Colors.grey.shade400,
                                ),
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
      _scrollToUnit(selectedUnit.unitIndex, subject, activeTab);
      try {
        context.push('/curriculum/${subject.id}/${selectedUnit.unitIndex}');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(subjectProvider(widget.subjectId));
    final appState = ref.watch(appStateProvider).value;

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
        if (subject == null) {
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
              error: RangeError('Subject not found: ${widget.subjectId}'),
              onPrimaryAction: () => context.pop(),
            ),
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

        // Populate unit keys for chapters
        final displayChapters = subject.chapters;
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
                style: AppTheme.headingStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkForeground,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.format_list_bulleted_rounded, color: AppTheme.inkForeground),
                  tooltip: 'Unit Index',
                  onPressed: () => _openIndexSheet(
                    subject: subject,
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
              scrollCacheExtent: const ScrollCacheExtent.pixels(450.0),
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

                        // 2. Units Section Header with Quick Jump
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CLINICAL UNITS (${subject.chapters.length})',
                              style: AppTypography.sectionMicroHeader(
                                fontSize: 10.5,
                                letterSpacing: 0.8,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openIndexSheet(
                                  subject: subject,
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
                                        style: AppTypography.compactAction(
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w600,
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

                        const SizedBox(height: 6),
                        const InSituHintPill(
                          prefKey: 'hint_unit_cards_seen',
                          message: 'Tap any unit to explore Videos, Q-Bank, and Notes • Tap Timer for quick focus',
                          icon: Icons.layers_outlined,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // 3. Virtualized List of Minimalist Unit Cards
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: subject.chapters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final chapter = subject.chapters[index];
                      return KeyedSubtree(
                        key: _unitKeys[index],
                        child: RepaintBoundary(
                          child: UnitCard(
                            subject: subject,
                            chapter: chapter,
                            unitIndex: index,
                            completedVideos: completedVideos,
                            completedQBanks: completedQBanks,
                            completedNotes: completedNotes,
                            onTap: () {
                              context.push('/curriculum/${subject.id}/$index');
                            },
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
  }
}
