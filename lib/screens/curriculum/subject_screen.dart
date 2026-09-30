import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/curriculum/subject_header_card.dart';
import '../../widgets/curriculum/module_timeline.dart';

class SubjectScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const SubjectScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen> {
  String _activeTab = 'videos'; // 'videos' | 'qbank' | 'notes'

  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(subjectProvider(widget.subjectId));
    final appState = ref.watch(appStateProvider).value;

    return subjectAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: Center(child: Text('Error: $e')),
      ),
      data: (subject) {
        if (subject == null) {
          return const Scaffold(
            backgroundColor: AppTheme.paperBackground,
            body: Center(child: Text('Subject not found')),
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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/curriculum');
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.paperBackground,
            appBar: AppBar(
              backgroundColor: AppTheme.paperBackground,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/curriculum');
                  }
                },
              ),
            title: Text(
              subject.displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkForeground,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.timer_outlined, color: AppTheme.inkForeground),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Large Rectangular Subject Hero Card (tappable to Analytics)
                SubjectHeaderCard(
                  subject: subject,
                  completedVideosCount: completedVideosCount,
                  completedQBanksCount: completedQBanksCount,
                  completedNotesCount: completedNotesCount,
                  onTapAnalytics: () => context.push('/curriculum/${widget.subjectId}/analytics'),
                ),

                const SizedBox(height: 20),

                // 2. 3 Categories Navigation Tab Bar (Videos | Q-Bank | Notes)
                Row(
                  children: [
                    _categoryTab(
                      id: 'videos',
                      label: 'Videos (${subject.totalVideos})',
                      icon: Icons.play_arrow_rounded,
                      activeColor: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    _categoryTab(
                      id: 'qbank',
                      label: 'Q-Bank (${subject.totalQBanks})',
                      icon: Icons.quiz_rounded,
                      activeColor: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 8),
                    _categoryTab(
                      id: 'notes',
                      label: 'Notes / Books',
                      icon: Icons.menu_book_rounded,
                      activeColor: Colors.green.shade800,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 3. Continuous Dotted-Line Module Timeline
                ModuleTimeline(
                  subject: subject,
                  activeTab: _activeTab,
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
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _categoryTab({
    required String id,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _activeTab == id;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.sketchBorderColor : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Color(0x181C1C1C),
                      offset: Offset(2, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppTheme.inkForeground,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.inkForeground,
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
