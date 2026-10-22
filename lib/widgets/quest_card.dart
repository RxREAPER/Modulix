import 'package:flutter/material.dart';
import '../models/syllabus.dart';
import '../models/app_state.dart';
import '../services/metrics_service.dart';
import '../data/subjects_metadata.dart';
import 'curriculum/subject_sketch_icon.dart';
import 'animations/animated_strike_text.dart';
import 'animations/apple_pressable.dart';

/// The main daily quest card shown on the home screen
class QuestCard extends StatefulWidget {
  final EditionState editionState;
  final StudyPlan plan;
  final List<Subject> subjects;
  final ValueChanged<String> onMarkComplete;
  final ValueChanged<String> onMarkIncomplete;
  final int dayStartHour;

  const QuestCard({
    super.key,
    required this.editionState,
    required this.plan,
    required this.subjects,
    required this.onMarkComplete,
    required this.onMarkIncomplete,
    this.dayStartHour = 5,
  });

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  List<Video>? _batch;

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  @override
  void didUpdateWidget(QuestCard old) {
    super.didUpdateWidget(old);
    _loadBatch();
  }

  void _loadBatch() {
    if (!widget.plan.isConfigured) return;
    try {
      final batch = MetricsService.computeDailyBatch(
        widget.editionState,
        widget.plan,
        widget.subjects,
      );
      if (mounted) setState(() => _batch = batch);
    } catch (_) {
      if (mounted) setState(() => _batch = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.plan.isConfigured) {
      return _EmptyQuestCard();
    }

    final batch = _batch;
    if (batch == null) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())));
    }

    if (batch.isEmpty) {
      return _AllDoneCard();
    }

    final today = MetricsService.todayKey(widget.dayStartHour);
    final doneToday = widget.editionState.dailyHistory[today] ?? 0;
    final target = widget.plan.videosPerDay ?? batch.length;
    final meta = subjectMeta(widget.plan.targetSubject);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: meta.accent.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: meta.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: SubjectSketchIcon(
                        subjectId: widget.plan.targetSubject,
                        color: meta.accent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _subjectDisplayName(widget.plan.targetSubject),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          '$doneToday / $target videos today',
                          style: TextStyle(
                              fontSize: 11,
                              color: meta.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // Mini progress
                  Text(
                    '${(doneToday / target * 100).clamp(0, 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: meta.accent,
                    ),
                  ),
                ],
              ),
            ),
            // Video list
            ...batch.take(10).map((video) {
              final isCompleted = widget.editionState.completedVideos
                  .containsKey(video.id);
              return _QuestVideoRow(
                video: video,
                isCompleted: isCompleted,
                onToggle: () {
                  if (isCompleted) {
                    widget.onMarkIncomplete(video.id);
                  } else {
                    widget.onMarkComplete(video.id);
                  }
                },
              );
            }),
            if (batch.length > 10)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '+ ${batch.length - 10} more videos',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _subjectDisplayName(String id) {
    return subjectMeta(id).displayName;
  }
}

class _QuestVideoRow extends StatelessWidget {
  final Video video;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _QuestVideoRow({
    required this.video,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tileColor = videoTileColor(video.id);

    return ApplePressable(
      onTap: onToggle,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Colored number tile
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : tileColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded,
                        color: Colors.green, size: 18)
                    : Text(
                        '${video.serialNumber}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: tileColor,
                            fontSize: 13),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedStrikeText(
                    text: video.title,
                    isStruck: isCompleted,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (video.durationLabel.isNotEmpty)
                    Text(
                      video.durationLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green
                      : cs.outline.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQuestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.track_changes_rounded,
                size: 40, color: cs.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No plan configured',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              'Go to the Plan tab to set a subject and daily target.',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 30,
                color: Color(0xFFCA8A04),
              ),
            ),
            const SizedBox(height: 12),
            const Text('All done for today!',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'You\'ve completed today\'s quest. Come back tomorrow or mark more videos from Curriculum.',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
