import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_log.dart';
import '../providers/time_log_provider.dart';
import '../theme/app_theme.dart';

class FocusTimerSheet extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final String? initialTopicId;
  final String? initialTopicTitle;
  final String? initialChapterName;
  final String initialType; // 'video' | 'qbank' | 'notes' | 'standalone'

  const FocusTimerSheet({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.initialTopicId,
    this.initialTopicTitle,
    this.initialChapterName,
    this.initialType = 'standalone',
  });

  static Future<void> show(
    BuildContext context, {
    required String subjectId,
    required String subjectName,
    String? topicId,
    String? topicTitle,
    String? chapterName,
    String type = 'standalone',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (ctx) => FocusTimerSheet(
        subjectId: subjectId,
        subjectName: subjectName,
        initialTopicId: topicId,
        initialTopicTitle: topicTitle,
        initialChapterName: chapterName,
        initialType: type,
      ),
    );
  }

  @override
  ConsumerState<FocusTimerSheet> createState() => _FocusTimerSheetState();
}

class _FocusTimerSheetState extends ConsumerState<FocusTimerSheet> {
  late String _type;
  late TextEditingController _titleController;
  int _secondsElapsed = 0;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _titleController = TextEditingController(
      text: widget.initialTopicTitle ??
          (_type == 'standalone' ? 'Reading Reference Book' : 'Study Module'),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _secondsElapsed++);
      });
      setState(() => _isRunning = true);
    }
  }

  Future<void> _saveAndClose() async {
    _timer?.cancel();
    if (_secondsElapsed > 0) {
      final log = TimeLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: widget.subjectId,
        topicId: widget.initialTopicId,
        topicType: _type,
        topicTitle: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Focus Study Session',
        chapterName: widget.initialChapterName ?? '',
        durationSecs: _secondsElapsed,
        timestamp: DateTime.now(),
      );

      await ref.read(timeLogsProvider.notifier).logTime(log);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged ${_formatTime(_secondsElapsed)} study time to ${widget.subjectName}!',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    final h = m ~/ 60;
    if (h > 0) {
      return '${h}h ${m % 60}m ${s}s';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus Study Timer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  Text(
                    widget.subjectName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _typeChip('video', 'Video Lecture', Icons.play_circle_outline),
                const SizedBox(width: 8),
                _typeChip('qbank', 'Q-Bank / MCQs', Icons.quiz_outlined),
                const SizedBox(width: 8),
                _typeChip('notes', 'Notes / Summary', Icons.note_outlined),
                const SizedBox(width: 8),
                _typeChip('standalone', 'Standalone Reading', Icons.menu_book_outlined),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Title field
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Session / Module Name',
              labelStyle: const TextStyle(fontSize: 12),
              filled: true,
              fillColor: AppTheme.cardWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.sketchBorderColor, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Big Timer Display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            decoration: AppTheme.sketchDecoration(
              backgroundColor: AppTheme.cardWhite,
              borderRadius: 24,
              shadowOffset: 4,
            ),
            child: Column(
              children: [
                Text(
                  _formatTime(_secondsElapsed),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: -1,
                    color: _isRunning ? AppTheme.primaryBlue : AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRunning ? 'FOCUS SESSION ACTIVE' : 'TIMER PAUSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: _isRunning ? Colors.green.shade600 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Controls
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    _isRunning ? 'Pause' : 'Start Focus Timer',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.orange.shade700 : AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _secondsElapsed > 0 ? _saveAndClose : null,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Finish',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.inkForeground,
                  foregroundColor: AppTheme.paperBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type, String label, IconData icon) {
    final isSelected = _type == type;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _type = type),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? AppTheme.paperBackground : AppTheme.inkForeground,
      ),
      selectedColor: AppTheme.inkForeground,
      backgroundColor: AppTheme.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.sketchBorderColor : AppTheme.borderLight,
          width: 1.2,
        ),
      ),
    );
  }
}
