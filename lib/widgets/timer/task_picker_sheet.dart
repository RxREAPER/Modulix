import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/syllabus.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';

class SelectedTaskInfo {
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String topicTitle;
  final String chapterName;
  final String topicType; // 'video' | 'qbank' | 'notes' | 'task'
  final int? presetDurationMins;

  const SelectedTaskInfo({
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    required this.topicTitle,
    this.chapterName = '',
    required this.topicType,
    this.presetDurationMins,
  });
}

class TaskPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<SelectedTaskInfo> onSelect;

  const TaskPickerSheet({super.key, required this.onSelect});

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<SelectedTaskInfo> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (ctx) => TaskPickerSheet(onSelect: onSelect),
    );
  }

  @override
  ConsumerState<TaskPickerSheet> createState() => _TaskPickerSheetState();
}

class _TaskPickerSheetState extends ConsumerState<TaskPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customTaskController = TextEditingController();
  String? _selectedSubjectId;
  int _selectedChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyTasksProvider);
    final syllabusAsync = ref.watch(activeSyllabusProvider);
    final subjects = syllabusAsync.value ?? [];

    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    final currentSub =
        subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Study Target',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkForeground,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.inkForeground,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: "Today's Desk Tasks"),
                Tab(text: 'Curriculum Module'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Today's Desk Tasks
                _buildDeskTasksTab(dailyState, subjects),

                // 2. Curriculum Module Drill-down
                _buildCurriculumModuleTab(subjects, currentSub),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskTasksTab(DailyTasksState dailyState, List<Subject> subjects) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (dailyState.tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.sketchDecoration(
              backgroundColor: Colors.white,
              borderRadius: 16,
            ),
            child: Column(
              children: [
                const Icon(Icons.checklist_rounded, size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'No desk tasks set for today yet',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set tasks on your Home dashboard or pick a curriculum module.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else ...[
          const Text(
            'Tap a task to link timer:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...dailyState.tasks.asMap().entries.map((entry) {
            final idx = entry.key;
            final task = entry.value;
            final taskTitle = task.title;
            final isDone = dailyState.completedIds.contains('task_$idx');

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: AppTheme.sketchDecoration(
                backgroundColor: isDone ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: 14,
                shadowOffset: 2.5,
              ),
              child: ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green.shade100 : AppTheme.highlightCoral,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
                title: Text(
                  taskTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  final defaultSub = subjects.isNotEmpty ? subjects.first : null;
                  widget.onSelect(SelectedTaskInfo(
                    subjectId: defaultSub?.id ?? 'general',
                    subjectName: defaultSub?.displayName ?? 'General Focus',
                    topicTitle: taskTitle,
                    topicType: 'task',
                    presetDurationMins: 25,
                  ));
                  Navigator.pop(context);
                },
              ),
            );
          }),
        ],

        const SizedBox(height: 20),
        const Text(
          'Or enter custom session name:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTaskController,
                decoration: InputDecoration(
                  hintText: 'e.g. Rapid ECG reading...',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.sketchBorderColor, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final txt = _customTaskController.text.trim();
                if (txt.isNotEmpty) {
                  final defaultSub = subjects.isNotEmpty ? subjects.first : null;
                  widget.onSelect(SelectedTaskInfo(
                    subjectId: defaultSub?.id ?? 'general',
                    subjectName: defaultSub?.displayName ?? 'General Focus',
                    topicTitle: txt,
                    topicType: 'standalone',
                    presetDurationMins: 25,
                  ));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.inkForeground,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurriculumModuleTab(List<Subject> subjects, Subject? currentSub) {
    if (subjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 1. Horizontal Subject Selector
        SizedBox(
          height: 60,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final sub = subjects[i];
              final isSelected = sub.id == _selectedSubjectId;
              final meta = subjectMeta(sub.id);

              return ChoiceChip(
                selected: isSelected,
                avatar: Icon(meta.icon, size: 16, color: isSelected ? Colors.white : meta.accent),
                label: Text(sub.displayName),
                selectedColor: AppTheme.inkForeground,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.inkForeground,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppTheme.sketchBorderColor : Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedSubjectId = sub.id;
                    _selectedChapterIndex = 0;
                  });
                },
              );
            },
          ),
        ),

        // 2. Unit Dropdown / Selector
        if (currentSub != null && currentSub.chapters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.sketchBorderColor, width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedChapterIndex.clamp(0, currentSub.chapters.length - 1),
                  isExpanded: true,
                  items: currentSub.chapters.asMap().entries.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(
                        'Unit ${e.key + 1}: ${e.value.name}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedChapterIndex = val);
                    }
                  },
                ),
              ),
            ),
          ),

        // 3. Module List under this Unit
        Expanded(
          child: Builder(
            builder: (ctx) {
              if (currentSub == null || currentSub.chapters.isEmpty) {
                return const Center(child: Text('No units available'));
              }
              final chapter = currentSub.chapters[_selectedChapterIndex.clamp(0, currentSub.chapters.length - 1)];

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                children: [
                  // Videos
                  if (chapter.videos.isNotEmpty) ...[
                    _groupHeader('VIDEO LECTURES (${chapter.videos.length})'),
                    ...chapter.videos.map((v) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.play_circle_outline, color: AppTheme.primaryBlue, size: 22),
                        title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: Text(v.durationLabel, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          widget.onSelect(SelectedTaskInfo(
                            subjectId: currentSub.id,
                            subjectName: currentSub.displayName,
                            topicId: v.id,
                            topicTitle: v.title,
                            chapterName: chapter.name,
                            topicType: 'video',
                            presetDurationMins: v.durationMins > 0 ? v.durationMins : 25,
                          ));
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],

                  // QBank
                  if (chapter.qbanks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _groupHeader('Q-BANK MODULES (${chapter.qbanks.length})'),
                    ...chapter.qbanks.map((q) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.quiz_outlined, color: Colors.teal, size: 22),
                        title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: Text('${q.totalMcqs} MCQs', style: const TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          widget.onSelect(SelectedTaskInfo(
                            subjectId: currentSub.id,
                            subjectName: currentSub.displayName,
                            topicId: q.id,
                            topicTitle: q.title,
                            chapterName: chapter.name,
                            topicType: 'qbank',
                            presetDurationMins: 30,
                          ));
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],

                  // Notes
                  if (chapter.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _groupHeader('NOTES & TEXTBOOKS (${chapter.notes.length})'),
                    ...chapter.notes.map((n) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.menu_book_outlined, color: Colors.green, size: 22),
                        title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: Text('${n.pages} pages', style: const TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          widget.onSelect(SelectedTaskInfo(
                            subjectId: currentSub.id,
                            subjectName: currentSub.displayName,
                            topicId: n.id,
                            topicTitle: n.title,
                            chapterName: chapter.name,
                            topicType: 'notes',
                            presetDurationMins: 20,
                          ));
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _groupHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}
