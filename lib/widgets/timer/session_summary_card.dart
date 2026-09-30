import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SessionSummaryCard extends StatelessWidget {
  final String subjectName;
  final String topicTitle;
  final int focusSecs;
  final int breakSecs;
  final String modeName;
  final VoidCallback onViewAnalytics;
  final VoidCallback onStartAnother;

  const SessionSummaryCard({
    super.key,
    required this.subjectName,
    required this.topicTitle,
    required this.focusSecs,
    required this.breakSecs,
    required this.modeName,
    required this.onViewAnalytics,
    required this.onStartAnother,
  });

  static Future<void> show(
    BuildContext context, {
    required String subjectName,
    required String topicTitle,
    required int focusSecs,
    required int breakSecs,
    required String modeName,
    required VoidCallback onViewAnalytics,
    required VoidCallback onStartAnother,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SessionSummaryCard(
          subjectName: subjectName,
          topicTitle: topicTitle,
          focusSecs: focusSecs,
          breakSecs: breakSecs,
          modeName: modeName,
          onViewAnalytics: onViewAnalytics,
          onStartAnother: onStartAnother,
        ),
      ),
    );
  }

  String _format(int secs) {
    final m = secs ~/ 60;
    final h = m ~/ 60;
    final s = secs % 60;
    if (h > 0) return '${h}h ${m % 60}m ${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.sketchDecoration(
        backgroundColor: Colors.white,
        borderRadius: 24,
        shadowOffset: 6,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stamp Icon
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Session Finished!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Great focus Doctor. Study time recorded.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 18),

          // Detail box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.paperBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.sketchBorderColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subjectName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      modeName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  topicTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const Divider(height: 20, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('FOCUS TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
                        const SizedBox(height: 2),
                        Text(_format(focusSecs), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Color(0xFF16A34A))),
                      ],
                    ),
                    Container(width: 1, height: 28, color: Colors.grey.shade300),
                    Column(
                      children: [
                        Text('BREAK TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
                        const SizedBox(height: 2),
                        Text(_format(breakSecs), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Colors.grey.shade700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewAnalytics,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.inkForeground,
                    side: const BorderSide(color: AppTheme.sketchBorderColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Analytics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onStartAnother,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.inkForeground,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Another', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
