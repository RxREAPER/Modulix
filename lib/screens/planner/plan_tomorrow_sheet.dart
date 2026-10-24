import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/daily_desk_task.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';

class PlanTomorrowSheet extends ConsumerStatefulWidget {
  const PlanTomorrowSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 320),
        reverseDuration: Duration(milliseconds: 240),
      ),
      builder: (context) => const PlanTomorrowSheet(),
    );
  }

  @override
  ConsumerState<PlanTomorrowSheet> createState() => _PlanTomorrowSheetState();
}

class _PlanTomorrowSheetState extends ConsumerState<PlanTomorrowSheet> {
  final Set<String> _selectedTaskIdsToCarry = {};
  final TextEditingController _newTitleController = TextEditingController();
  MedicalSubject _selectedSubject = MedicalSubject.general;
  final TaskCategory _selectedCategory = TaskCategory.revision;
  final TaskPriority _selectedPriority = TaskPriority.p2high;
  final int _estimatedMinutes = 45;

  @override
  void initState() {
    super.initState();
    final tasksState = ref.read(dailyTasksProvider);
    // Pre-select all unfinished tasks
    for (final t in tasksState.tasks) {
      if (!tasksState.completedIds.contains(t.id)) {
        _selectedTaskIdsToCarry.add(t.id);
      }
    }
  }

  @override
  void dispose() {
    _newTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final tasksState = ref.watch(dailyTasksProvider);
    final unfinishedTasks = tasksState.tasks.where((t) => !tasksState.completedIds.contains(t.id)).toList();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowFormatted = DateFormat('EEEE, MMM d').format(tomorrow).toUpperCase();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkForeground.withValues(alpha: 0.12),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tomorrowFormatted,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Plan Tomorrow',
                      style: AppTheme.headingStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppTheme.inkForeground),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              'Select unfinished items to carry over, or add dedicated targets for tomorrow.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 12),

            // Carry over items list
            Flexible(
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  if (unfinishedTasks.isNotEmpty) ...[
                    Text(
                      'CARRY OVER UNFINISHED (${unfinishedTasks.length})',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...unfinishedTasks.map((t) {
                      final isSelected = _selectedTaskIdsToCarry.contains(t.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ApplePressable(
                          pressedScale: 0.98,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isSelected) {
                                _selectedTaskIdsToCarry.remove(t.id);
                              } else {
                                _selectedTaskIdsToCarry.add(t.id);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.parchmentSurface : AppTheme.cardWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.accentPrimary : AppTheme.borderLight,
                                width: isSelected ? 1.5 : 1.1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  size: 20,
                                  color: isSelected ? AppTheme.accentPrimary : AppTheme.mutedText,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.inkForeground,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (t.subject != MedicalSubject.general) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t.subject.shortCode,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.inkForeground,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                  ],

                  // Add new target for tomorrow
                  Text(
                    'ADD TARGET FOR TOMORROW',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderLight, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _newTitleController,
                          cursorColor: AppTheme.inkForeground,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkForeground,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'e.g. General Pharmacology Rev + 50 MCQs',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subject & Category Quick Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              ...MedicalSubject.values.take(8).map((subj) {
                                final isSel = _selectedSubject == subj;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ApplePressable(
                                    pressedScale: 0.94,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedSubject = subj);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSel ? AppTheme.inkForeground : AppTheme.cardWhite,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: isSel ? AppTheme.inkForeground : AppTheme.borderLight,
                                        ),
                                      ),
                                      child: Text(
                                        subj.label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isSel ? AppTheme.paperBackground : AppTheme.inkForeground,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Confirm Button
            ApplePressable(
              pressedScale: 0.97,
              onTap: () async {
                HapticFeedback.mediumImpact();
                final tomorrowKey = DateFormat('yyyy-MM-dd').format(tomorrow);
                final notifier = ref.read(dailyTasksProvider.notifier);

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                // Add newly typed task for tomorrow if present
                final newText = _newTitleController.text.trim();
                if (newText.isNotEmpty) {
                  await notifier.addTask(
                    DailyDeskTask(
                      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                      title: newText,
                      category: _selectedCategory,
                      subject: _selectedSubject,
                      priority: _selectedPriority,
                      scheduledDate: tomorrowKey,
                      estimatedMinutes: _estimatedMinutes,
                    ),
                  );
                }

                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 3),
                      content: const Text("Tomorrow's study desk targets prepared"),
                      backgroundColor: AppTheme.inkForeground,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.inkForeground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Confirm Plan for Tomorrow',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.paperBackground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.paperBackground),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
