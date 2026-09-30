import 'package:flutter/material.dart';
import '../../models/syllabus.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';

class SquareSubjectCard extends StatefulWidget {
  final Subject subject;
  final double completion;
  final VoidCallback onTap;

  const SquareSubjectCard({
    super.key,
    required this.subject,
    required this.completion,
    required this.onTap,
  });

  @override
  State<SquareSubjectCard> createState() => _SquareSubjectCardState();
}

class _SquareSubjectCardState extends State<SquareSubjectCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final meta = subjectMeta(widget.subject.id);
    final percent = (widget.completion * 100).round();
    final totalHours = widget.subject.totalHours;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: AppTheme.sketchDecoration(
            backgroundColor: Colors.white,
            borderRadius: 20,
            shadowOffset: _isPressed ? 1.5 : 4.0,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Icon Bubble with medical badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: meta.accent.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: meta.accent.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        meta.icon,
                        color: meta.accent,
                        size: 24,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: percent == 100
                          ? const Color(0xFFDCFCE7)
                          : AppTheme.paperBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: percent == 100
                            ? const Color(0xFF16A34A)
                            : Colors.grey.shade400,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: percent == 100
                            ? const Color(0xFF16A34A)
                            : AppTheme.inkForeground,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Subject Title
              Text(
                widget.subject.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),

              // Total videos & Total hours
              Text(
                '${widget.subject.totalVideos} vids · ${totalHours.toStringAsFixed(1)} hrs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 8),

              // Sketch Progress Bar
              Container(
                height: 7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.paperBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.sketchBorderColor, width: 1.2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.completion.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: meta.accent,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
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
