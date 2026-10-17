import 'package:flutter/material.dart';
import '../models/syllabus.dart';
import '../data/subjects_metadata.dart';
import 'animations/animated_check_stroke.dart';
import 'animations/animated_strike_text.dart';
import 'animations/apple_pressable.dart';

/// A single lecture row in the chapter video list
class VideoTile extends StatelessWidget {
  final Video video;
  final int serialNumber;
  final bool isCompleted;
  final String? completedAt; // ISO timestamp or null
  final Color accentColor;
  final VoidCallback onToggle;

  const VideoTile({
    super.key,
    required this.video,
    required this.serialNumber,
    required this.isCompleted,
    this.completedAt,
    required this.accentColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tileColor = videoTileColor(video.id);

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
              // Colored number tile (mirrors Marrow-style thumbnails) with color morph & check bounce
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.15)
                      : tileColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: isCompleted ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          '$serialNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: tileColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isCompleted ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedCheckStroke(
                          checked: isCompleted,
                          size: 22,
                          color: Colors.green,
                          strokeWidth: 2.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title + meta with AnimatedStrikeText sweep
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
                      strikeColor: cs.onSurface.withValues(alpha: 0.5),
                      strikeThickness: 1.8,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (video.durationLabel.isNotEmpty) ...[
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            video.durationLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                        if (isCompleted && completedAt != null) ...[
                          if (video.durationLabel.isNotEmpty)
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
              // Toggle checkbox with check bounce
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

  String _formatCompletionDate(String isoTimestamp) {
    try {
      final t = DateTime.parse(isoTimestamp);
      final now = DateTime.now();
      final diff = now.difference(t).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return '${diff}d ago';
      return '${t.day}/${t.month}/${t.year}';
    } catch (_) {
      return '';
    }
  }
}
