import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../data/subjects_metadata.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/page_entrance.dart';
import '../../widgets/video_tile.dart';

class ChapterScreen extends ConsumerWidget {
  final String subjectId;
  final int chapterIndex;

  const ChapterScreen({
    super.key,
    required this.subjectId,
    required this.chapterIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(subjectProvider(subjectId));
    final appState = ref.watch(appStateProvider).value;
    final meta = subjectMeta(subjectId);

    return subjectAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (subject) {
        if (subject == null ||
            chapterIndex < 0 ||
            chapterIndex >= subject.chapters.length) {
          return const Scaffold(body: Center(child: Text('Chapter not found')));
        }
        final chapter = subject.chapters[chapterIndex];
        final completedVideos = appState?.currentEdition.completedVideos ?? {};

        final done = chapter.videos
            .where((v) => completedVideos.containsKey(v.id))
            .length;

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
              elevation: 0,
              scrolledUnderElevation: 0,
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
                chapter.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.inkForeground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: chapter.totalVideos == 0
                    ? 0
                    : done / chapter.totalVideos,
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
                // Stats row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      _StatChip(
                          label: '$done / ${chapter.totalVideos} done',
                          icon: Icons.check_circle_outline_rounded,
                          color: meta.accent),
                      const SizedBox(width: 8),
                      _StatChip(
                          label: '${chapter.totalVideos - done} remaining',
                          icon: Icons.radio_button_unchecked_rounded,
                          color: Colors.grey),
                      if (chapter.durationLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _StatChip(
                            label: chapter.durationLabel,
                            icon: Icons.schedule_rounded,
                            color: AppTheme.inkForeground),
                      ],
                    ],
                  ),
                ),
                // Video list
                Expanded(
                  child: ListView.builder(
                    cacheExtent: 450.0,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: chapter.videos.length,
                    itemBuilder: (context, i) {
                      final video = chapter.videos[i];
                      final isCompleted =
                          completedVideos.containsKey(video.id);
                      final completedAt = completedVideos[video.id];

                      final globalNumber = video.serialNumber > 0
                          ? video.serialNumber
                          : (subject.allVideos.indexWhere((v) => v.id == video.id) + 1);

                      return VideoTile(
                        video: video,
                        serialNumber: globalNumber > 0 ? globalNumber : (i + 1),
                        isCompleted: isCompleted,
                        completedAt: completedAt is String ? completedAt : null,
                        accentColor: meta.accent,
                        onToggle: () {
                          if (isCompleted) {
                            ref.read(appStateProvider.notifier)
                                .markVideoIncomplete(video.id);
                          } else {
                            ref.read(appStateProvider.notifier)
                                .markVideoComplete(video.id);
                          }
                        },
                      );
                    },
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
