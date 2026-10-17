import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class DailyTasksAnimationWidget extends StatefulWidget {
  const DailyTasksAnimationWidget({super.key});

  @override
  State<DailyTasksAnimationWidget> createState() =>
      _DailyTasksAnimationWidgetState();
}

class _DailyTasksAnimationWidgetState extends State<DailyTasksAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value; // 0.0 to 1.0

        // Phase 1 (0.0 to 0.25): Initial desk pad
        // Phase 2 (0.25 to 0.50): Task 1 checked + strike
        // Phase 3 (0.50 to 0.75): Task 2 checked + strike
        // Phase 4 (0.75 to 1.00): Streak saved badge + momentum secured

        final bool task1Done = t >= 0.25;
        final double strike1 =
            t < 0.25 ? 0.0 : ((t - 0.25) / 0.15).clamp(0.0, 1.0);

        final bool task2Done = t >= 0.55;
        final double strike2 =
            t < 0.55 ? 0.0 : ((t - 0.55) / 0.15).clamp(0.0, 1.0);

        final bool allDone = t >= 0.75;

        return Container(
          height: 195,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF8), // Warm paper background
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.sketchBorderColor, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x221C1C1C),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modulix Home Desk Pad Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's tasks",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Text(
                        allDone
                            ? '2 of 2 completed'
                            : (task1Done
                                ? '1 of 2 completed'
                                : '0 of 2 completed'),
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  // Real Modulix Streak badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: allDone
                          ? Colors.orange.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: allDone ? Colors.orange : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 13,
                          color: allDone ? Colors.orange : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          allDone ? 'STREAK SAVED!' : 'Streak Pending',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: allDone
                                ? Colors.orange.shade900
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Exact Modulix StudyTaskCard 1
              _buildModulixTaskCard(
                title: '50 Grand Test MCQs (Review Errors)',
                subtitle: 'Study Goal #1',
                isCompleted: task1Done,
                strikeProgress: strike1,
              ),

              const SizedBox(height: 6),

              // Exact Modulix StudyTaskCard 2
              _buildModulixTaskCard(
                title: 'Review ECG & Arrhythmia Pearls',
                subtitle: 'Study Goal #2',
                isCompleted: task2Done,
                strikeProgress: strike2,
              ),

              const Spacer(),

              // Daily Progress Status Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(
                      allDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color:
                          allDone ? Colors.green.shade700 : AppTheme.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        allDone
                            ? 'All tasks completed! Daily momentum secured.'
                            : 'Checking off spontaneous targets fuels your streak.',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: allDone
                              ? Colors.green.shade800
                              : AppTheme.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Exact Modulix StudyTaskCard replica
  Widget _buildModulixTaskCard({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required double strikeProgress,
  }) {
    return Container(
      decoration: AppTheme.sketchDecoration(
        backgroundColor: isCompleted ? const Color(0xFFF9F9F8) : Colors.white,
        borderRadius: 12,
        shadowOffset: isCompleted ? 1 : 2.5,
        borderColor:
            isCompleted ? Colors.grey.shade300 : AppTheme.sketchBorderColor,
        borderWidth: 1.4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          // Square Sketch Checkbox (Modulix signature)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.inkForeground : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCompleted
                    ? AppTheme.inkForeground
                    : AppTheme.sketchBorderColor,
                width: 1.6,
              ),
            ),
            child: isCompleted
                ? const Center(
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? Colors.grey.shade400
                            : AppTheme.inkForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (strikeProgress > 0)
                      FractionallySizedBox(
                        widthFactor: strikeProgress,
                        child: Container(
                          height: 1.6,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
