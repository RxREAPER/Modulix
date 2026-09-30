import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queryLower = _query.trim().toLowerCase();

    // Filter results across subjects, units, videos, and qbanks
    final matchedSubjects = <Subject>[];
    final matchedVideos = <Map<String, dynamic>>[];
    final matchedQBanks = <Map<String, dynamic>>[];
    final matchedChapters = <Map<String, dynamic>>[];

    if (queryLower.isNotEmpty) {
      for (final s in widget.subjects) {
        if (s.displayName.toLowerCase().contains(queryLower) ||
            s.name.toLowerCase().contains(queryLower)) {
          matchedSubjects.add(s);
        }

        for (final ch in s.chapters) {
          if (ch.name.toLowerCase().contains(queryLower)) {
            matchedChapters.add({
              'subject': s,
              'chapterName': ch.name,
              'videosCount': ch.totalVideos,
            });
          }

          for (final v in ch.videos) {
            if (v.title.toLowerCase().contains(queryLower)) {
              matchedVideos.add({
                'subject': s,
                'chapterName': ch.name,
                'video': v,
              });
            }
          }

          for (final q in ch.qbanks) {
            if (q.title.toLowerCase().contains(queryLower)) {
              matchedQBanks.add({
                'subject': s,
                'chapterName': ch.name,
                'qbank': q,
              });
            }
          }
        }
      }
    }

    final hasResults = matchedSubjects.isNotEmpty ||
        matchedChapters.isNotEmpty ||
        matchedVideos.isNotEmpty ||
        matchedQBanks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The Search Bar Text Field
        Container(
          decoration: AppTheme.sketchDecoration(
            backgroundColor: Colors.white,
            borderRadius: 16,
            shadowOffset: 3,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
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
                color: Colors.grey.shade500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.inkForeground,
                size: 22,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _query = '';
                          _isSearching = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        // Live Search Results Dropdown Overlay
        if (_isSearching) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 340),
            decoration: AppTheme.sketchDecoration(
              backgroundColor: Colors.white,
              borderRadius: 16,
              shadowOffset: 4,
            ),
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
                    children: [
                      // Matched Subjects
                      if (matchedSubjects.isNotEmpty) ...[
                        _resultHeader('SUBJECTS (${matchedSubjects.length})'),
                        ...matchedSubjects.map((s) {
                          final meta = subjectMeta(s.id);
                          return ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: meta.accent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(meta.icon, color: meta.accent, size: 16),
                            ),
                            title: Text(
                              s.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${s.totalVideos} videos · ${s.totalHours.toStringAsFixed(1)} hrs',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              _controller.clear();
                              setState(() => _isSearching = false);
                              context.push('/curriculum/${s.id}');
                            },
                          );
                        }),
                      ],

                      // Matched Chapters / Units
                      if (matchedChapters.isNotEmpty) ...[
                        _resultHeader('UNITS / CHAPTERS (${matchedChapters.length})'),
                        ...matchedChapters.take(5).map((item) {
                          final s = item['subject'] as Subject;
                          final chName = item['chapterName'] as String;
                          final vCount = item['videosCount'] as int;
                          return ListTile(
                            leading: const Icon(Icons.bookmark_border_rounded, size: 20, color: AppTheme.primaryBlue),
                            title: Text(
                              chName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${s.displayName} · $vCount videos',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            onTap: () {
                              _controller.clear();
                              setState(() => _isSearching = false);
                              context.push('/curriculum/${s.id}');
                            },
                          );
                        }),
                      ],

                      // Matched Videos
                      if (matchedVideos.isNotEmpty) ...[
                        _resultHeader('VIDEOS (${matchedVideos.length})'),
                        ...matchedVideos.take(8).map((item) {
                          final s = item['subject'] as Subject;
                          final v = item['video'] as Video;
                          return ListTile(
                            leading: const Icon(Icons.play_circle_outline_rounded, size: 20, color: Colors.redAccent),
                            title: Text(
                              v.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${s.displayName} · ${v.chapterName} · ${v.durationLabel}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            onTap: () {
                              _controller.clear();
                              setState(() => _isSearching = false);
                              context.push('/curriculum/${s.id}');
                            },
                          );
                        }),
                      ],

                      // Matched Q-Banks
                      if (matchedQBanks.isNotEmpty) ...[
                        _resultHeader('Q-BANK MODULES (${matchedQBanks.length})'),
                        ...matchedQBanks.take(6).map((item) {
                          final s = item['subject'] as Subject;
                          final q = item['qbank'] as QBankTopic;
                          return ListTile(
                            leading: const Icon(Icons.quiz_outlined, size: 20, color: Colors.teal),
                            title: Text(
                              q.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${s.displayName} · ${q.chapterName} · ${q.totalMcqs} MCQs',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            onTap: () {
                              _controller.clear();
                              setState(() => _isSearching = false);
                              context.push('/curriculum/${s.id}');
                            },
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  Widget _resultHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey.shade100,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}
