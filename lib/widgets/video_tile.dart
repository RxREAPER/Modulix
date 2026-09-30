import 'package:flutter/material.dart';
import '../models/syllabus.dart';
import '../data/subjects_metadata.dart';

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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Colored number tile (mirrors Marrow-style thumbnails)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.15)
                      : tileColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check_rounded, color: Colors.green, size: 22)
                      : Text(
                          '$serialNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: tileColor,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? cs.onSurface.withOpacity(0.4)
                            : cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (video.durationLabel.isNotEmpty) ...[
                          Icon(Icons.schedule_rounded,
                              size: 12,
                              color: cs.onSurface.withOpacity(0.35)),
                          const SizedBox(width: 4),
                          Text(
                            video.durationLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(0.4)),
                          ),
                        ],
                        if (isCompleted && completedAt != null) ...[
                          if (video.durationLabel.isNotEmpty)
                            const SizedBox(width: 10),
                          Icon(Icons.check_circle_outline_rounded,
                              size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            _formatCompletionDate(completedAt!),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Toggle checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : cs.outline.withOpacity(0.35),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : null,
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
