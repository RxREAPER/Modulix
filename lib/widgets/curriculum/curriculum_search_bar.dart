import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';
import 'subject_sketch_icon.dart';

class CurriculumSearchBar extends StatefulWidget {
  final List<Subject> subjects;

  const CurriculumSearchBar({super.key, required this.subjects});

  @override
  State<CurriculumSearchBar> createState() => _CurriculumSearchBarState();
}

class _CurriculumSearchBarState extends State<CurriculumSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  bool _isSearching = false;

  Animation<double>? _secondaryAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _onSecondaryAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward || status == AnimationStatus.completed) {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    } else if (status == AnimationStatus.dismissed) {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    final secAnim = modalRoute?.secondaryAnimation;
    if (_secondaryAnimation != secAnim) {
      _secondaryAnimation?.removeStatusListener(_onSecondaryAnimationStatus);
      _secondaryAnimation = secAnim;
      _secondaryAnimation?.addStatusListener(_onSecondaryAnimationStatus);
    }
    if (modalRoute != null && !modalRoute.isCurrent) {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
  }

  void _closeAndNavigate(VoidCallback navAction) {
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.clear();
    setState(() {
      _query = '';
      _isSearching = false;
    });
    navAction();
  }

  @override
  void dispose() {
    _secondaryAnimation?.removeStatusListener(_onSecondaryAnimationStatus);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queryLower = _query.trim().toLowerCase();

    // Filter results across subjects, units, videos, qbanks, and notes
    final matchedSubjects = <Subject>[];
    final matchedVideos = <Map<String, dynamic>>[];
    final matchedQBanks = <Map<String, dynamic>>[];
    final matchedNotes = <Map<String, dynamic>>[];
    final matchedChapters = <Map<String, dynamic>>[];

    if (queryLower.isNotEmpty) {
      final isNumericQuery = RegExp(r'^#?\d+$').hasMatch(queryLower);
      final queryNum = isNumericQuery
          ? int.tryParse(queryLower.replaceAll(RegExp(r'[^0-9]'), ''))
          : null;

      for (final s in widget.subjects) {
        if (s.displayName.toLowerCase().contains(queryLower) ||
            s.name.toLowerCase().contains(queryLower)) {
          matchedSubjects.add(s);
        }

        for (int chIdx = 0; chIdx < s.chapters.length; chIdx++) {
          final ch = s.chapters[chIdx];
          if (ch.name.toLowerCase().contains(queryLower)) {
            matchedChapters.add({
              'subject': s,
              'chapterName': ch.name,
              'chapterIndex': chIdx,
              'videosCount': ch.totalVideos,
              'qbanksCount': ch.totalQBanks,
              'notesCount': ch.totalNotes,
            });
          }

          for (final v in ch.videos) {
            final matchesTitle = v.title.toLowerCase().contains(queryLower);
            final matchesId = v.id.toLowerCase().contains(queryLower);
            final matchesNum = (queryNum != null && (v.serialNumber == queryNum || v.assignedNumber == queryNum)) ||
                (isNumericQuery && '#${v.serialNumber}'.toLowerCase().contains(queryLower));
            if (matchesTitle || matchesId || matchesNum) {
              matchedVideos.add({
                'subject': s,
                'chapterName': ch.name,
                'chapterIndex': chIdx,
                'video': v,
              });
            }
          }

          for (final n in ch.notes) {
            final matchesTitle = n.title.toLowerCase().contains(queryLower);
            final matchesId = n.id.toLowerCase().contains(queryLower);
            if (matchesTitle || matchesId) {
              matchedNotes.add({
                'subject': s,
                'chapterName': ch.name,
                'chapterIndex': chIdx,
                'note': n,
              });
            }
          }
        }

        for (final q in s.allQBanks) {
          final matchesTitle = q.title.toLowerCase().contains(queryLower);
          final matchesId = q.id.toLowerCase().contains(queryLower);
          final matchesNum = (queryNum != null && (q.serialNumber == queryNum || q.assignedNumber == queryNum)) ||
              (isNumericQuery && '#${q.assignedNumber ?? q.serialNumber}'.toLowerCase().contains(queryLower));
          if (matchesTitle || matchesId || matchesNum) {
            int chIndex = s.chapters.indexWhere((c) => c.qbanks.any((item) => item.id == q.id));
            if (chIndex == -1) {
              chIndex = s.chapters.indexWhere((c) => c.name.toLowerCase() == q.chapterName.toLowerCase());
            }
            if (chIndex == -1) {
              chIndex = s.chapters.indexWhere((c) =>
                  c.name.toLowerCase().contains(q.chapterName.toLowerCase()) ||
                  q.chapterName.toLowerCase().contains(c.name.toLowerCase()));
            }
            if (chIndex == -1) chIndex = 0;

            matchedQBanks.add({
              'subject': s,
              'chapterName': q.chapterName,
              'chapterIndex': chIndex,
              'qbank': q,
            });
          }
        }
      }
    }

    final hasResults = matchedSubjects.isNotEmpty ||
        matchedChapters.isNotEmpty ||
        matchedVideos.isNotEmpty ||
        matchedQBanks.isNotEmpty ||
        matchedNotes.isNotEmpty;

    final isSearchActive = _focusNode.hasFocus || _isSearching || _query.isNotEmpty;

    return PopScope(
      canPop: !isSearchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _focusNode.unfocus();
        FocusScope.of(context).unfocus();
        setState(() {
          _query = '';
          _controller.clear();
          _isSearching = false;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // The Search Bar Text Field with fluid focus width expansion
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(
            horizontal: (_focusNode.hasFocus || _isSearching) ? 0.0 : 3.0,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (_focusNode.hasFocus || _isSearching)
                  ? AppTheme.accentPrimary.withValues(alpha: 0.6)
                  : AppTheme.borderLight,
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: (_focusNode.hasFocus || _isSearching)
                    ? AppTheme.accentPrimary.withValues(alpha: 0.12)
                    : (AppTheme.current.isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.03)),
                offset: const Offset(0, 2),
                blurRadius: (_focusNode.hasFocus || _isSearching) ? 12 : 4,
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: false,
            onTapOutside: (_) {
              _focusNode.unfocus();
            },
            cursorColor: AppTheme.accentPrimary,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkForeground,
            ),
            onChanged: (val) {
              setState(() {
                _query = val;
                _isSearching = val.isNotEmpty;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search subjects, units, videos, Q-Banks...',
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedText,
              ),
              prefixIcon: AnimatedRotation(
                turns: (_focusNode.hasFocus || _isSearching) ? -0.04 : 0.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.search_rounded,
                  color: (_focusNode.hasFocus || _isSearching)
                      ? AppTheme.accentPrimary
                      : AppTheme.mutedText,
                  size: 22,
                ),
              ),
              suffixIcon: AnimatedScale(
                scale: _query.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: IconButton(
                  icon: Icon(Icons.clear_rounded, size: 20, color: AppTheme.mutedText),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _query = '';
                      _isSearching = false;
                    });
                  },
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        // Smooth dropdown unfold (AnimatedSize)
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _isSearching
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 340),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.current.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      width: 0.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.current.isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.06),
                        offset: const Offset(0, 4),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Material(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: !hasResults
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No matches found for "$_query"',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            children: _buildCascadingResultItems(
                              matchedSubjects: matchedSubjects,
                              matchedChapters: matchedChapters,
                              matchedVideos: matchedVideos,
                              matchedQBanks: matchedQBanks,
                              matchedNotes: matchedNotes,
                            ),
                          ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
  }

  List<Widget> _buildCascadingResultItems({
    required List<Subject> matchedSubjects,
    required List<Map<String, dynamic>> matchedChapters,
    required List<Map<String, dynamic>> matchedVideos,
    required List<Map<String, dynamic>> matchedQBanks,
    required List<Map<String, dynamic>> matchedNotes,
  }) {
    final items = <Widget>[];
    int cascadeIndex = 0;

    // Matched Subjects
    if (matchedSubjects.isNotEmpty) {
      items.add(
        _CascadingItem(
          index: cascadeIndex++,
          query: _query,
          child: _resultHeader('SUBJECTS (${matchedSubjects.length})'),
        ),
      );
      for (final s in matchedSubjects) {
        final meta = subjectMeta(s.id);
        items.add(
          _CascadingItem(
            index: cascadeIndex++,
            query: _query,
            child: ListTile(
              leading: SubjectSketchIcon(
                subjectId: s.id,
                color: meta.accent,
                size: 24,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  _typeBadge('SUBJECT', meta.accent),
                ],
              ),
              subtitle: Text(
                '${s.totalVideos} videos · ${s.totalHours.toStringAsFixed(1)} hrs',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _closeAndNavigate(() => context.push('/curriculum/${s.id}')),
            ),
          ),
        );
      }
    }

    // Matched Chapters / Units
    if (matchedChapters.isNotEmpty) {
      items.add(
        _CascadingItem(
          index: cascadeIndex++,
          query: _query,
          child: _resultHeader('UNITS / CHAPTERS (${matchedChapters.length})'),
        ),
      );
      for (final item in matchedChapters.take(5)) {
        final s = item['subject'] as Subject;
        final chName = item['chapterName'] as String;
        final chIndex = item['chapterIndex'] as int;
        final vCount = item['videosCount'] as int;
        items.add(
          _CascadingItem(
            index: cascadeIndex++,
            query: _query,
            child: ListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.layers_outlined, size: 18, color: AppTheme.primaryBlue),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      chName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  _typeBadge('UNIT', AppTheme.primaryBlue),
                ],
              ),
              subtitle: Text(
                '${s.displayName} · Unit ${chIndex + 1} · $vCount videos',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _closeAndNavigate(() => context.push('/curriculum/${s.id}/$chIndex')),
            ),
          ),
        );
      }
    }

    // Matched Videos
    if (matchedVideos.isNotEmpty) {
      items.add(
        _CascadingItem(
          index: cascadeIndex++,
          query: _query,
          child: _resultHeader('VIDEOS (${matchedVideos.length})'),
        ),
      );
      for (final item in matchedVideos.take(8)) {
        final s = item['subject'] as Subject;
        final v = item['video'] as Video;
        final chIndex = item['chapterIndex'] as int;
        items.add(
          _CascadingItem(
            index: cascadeIndex++,
            query: _query,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: s.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: s.accentColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  '#${v.serialNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: s.accentColor,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      v.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  _typeBadge('VIDEO', s.accentColor),
                ],
              ),
              subtitle: Text(
                '${s.displayName} · ${item['chapterName']} · ${v.durationLabel}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _closeAndNavigate(() => context.push('/curriculum/${s.id}/$chIndex?tab=videos&itemId=${v.id}')),
            ),
          ),
        );
      }
    }

    // Matched Q-Banks
    if (matchedQBanks.isNotEmpty) {
      items.add(
        _CascadingItem(
          index: cascadeIndex++,
          query: _query,
          child: _resultHeader('Q-BANK MODULES (${matchedQBanks.length})'),
        ),
      );
      for (final item in matchedQBanks.take(6)) {
        final s = item['subject'] as Subject;
        final q = item['qbank'] as QBankTopic;
        final chIndex = item['chapterIndex'] as int;
        items.add(
          _CascadingItem(
            index: cascadeIndex++,
            query: _query,
            child: ListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3), width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.quiz_rounded, size: 18, color: Color(0xFFF97316)),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      q.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  _typeBadge('Q-BANK', const Color(0xFFF97316)),
                ],
              ),
              subtitle: Text(
                '${s.displayName} · ${item['chapterName']} · ${q.totalMcqs} MCQs',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _closeAndNavigate(() => context.push('/curriculum/${s.id}/$chIndex?tab=qbank&itemId=${q.id}')),
            ),
          ),
        );
      }
    }

    // Matched Notes
    if (matchedNotes.isNotEmpty) {
      items.add(
        _CascadingItem(
          index: cascadeIndex++,
          query: _query,
          child: _resultHeader('NOTES & TEXTS (${matchedNotes.length})'),
        ),
      );
      for (final item in matchedNotes.take(6)) {
        final s = item['subject'] as Subject;
        final n = item['note'] as NotesItem;
        final chIndex = item['chapterIndex'] as int;
        items.add(
          _CascadingItem(
            index: cascadeIndex++,
            query: _query,
            child: ListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF10B981)),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  _typeBadge('NOTES', const Color(0xFF10B981)),
                ],
              ),
              subtitle: Text(
                '${s.displayName} · ${item['chapterName']} · ${n.pages} pages',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _closeAndNavigate(() => context.push('/curriculum/${s.id}/$chIndex?tab=notes&itemId=${n.id}')),
            ),
          ),
        );
      }
    }

    return items;
  }

  Widget _typeBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.current.isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.5)
          : const Color(0xFFF8FAFC),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.mutedText,
        ),
      ),
    );
  }
}

class _CascadingItem extends StatelessWidget {
  final int index;
  final String? query;
  final Widget child;

  const _CascadingItem({
    required this.index,
    this.query,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('cascading_${query ?? ''}_$index'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: (180 + (index * 24)).clamp(180, 420)),
      curve: Curves.easeOutCubic,
      builder: (context, value, animChild) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 10),
            child: animChild,
          ),
        );
      },
      child: child,
    );
  }
}
