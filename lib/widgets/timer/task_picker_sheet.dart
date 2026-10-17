import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/syllabus.dart';
import '../../models/timer_theme.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/daily_tasks_provider.dart';
import '../../providers/focus_timer_provider.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';
import '../curriculum/subject_sketch_icon.dart';
import '../animations/apple_pressable.dart';

class SelectedTaskInfo {
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String topicTitle;
  final String chapterName;
  final String topicType; // 'video' | 'qbank' | 'notes' | 'task' | 'standalone'
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
  final TimerThemeData? theme;

  const TaskPickerSheet({super.key, required this.onSelect, this.theme});

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<SelectedTaskInfo> onSelect,
    TimerThemeData? theme,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (ctx) => TaskPickerSheet(onSelect: onSelect, theme: theme),
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
  String _selectedCategory = 'videos';

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

    final timerTheme = widget.theme ?? ref.watch(focusTimerProvider).theme;
    final accent = timerTheme.accentColor;
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: AppTheme.paperBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: AppTheme.borderLight,
                width: 1.5,
              ),
            ),
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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(Icons.track_changes_rounded, color: accent, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Study Target',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Link timer to desk tasks or curriculum',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Pill Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                    _buildDeskTasksTab(dailyState, subjects, timerTheme),

                    // 2. Curriculum Module Drill-down
                    _buildCurriculumModuleTab(subjects, currentSub, timerTheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeskTasksTab(
    DailyTasksState dailyState,
    List<Subject> subjects,
    TimerThemeData theme,
  ) {
    final isLight = !AppTheme.current.isDark;
    final accent = theme.accentColor;
    final cardBg = AppTheme.cardWhite;
    final border = AppTheme.borderLight;
    final textPrimary = AppTheme.inkForeground;
    final textSecondary = AppTheme.mutedText;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        if (dailyState.tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.2),
            ),
            child: Column(
              children: [
                Icon(Icons.checklist_rounded, size: 36, color: accent.withOpacity(0.8)),
                const SizedBox(height: 10),
                Text(
                  'No desk tasks set for today yet',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a curriculum module in the next tab or enter a custom session below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          )
        else ...[
          Text(
            'TAP A TASK TO LINK TIMER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...dailyState.tasks.asMap().entries.map((entry) {
            final idx = entry.key;
            final task = entry.value;
            final taskTitle = task.title;
            final isDone = dailyState.completedIds.contains('task_$idx');

            return ApplePressable(
              pressedScale: 0.98,
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
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDone
                      ? (isLight ? const Color(0xFFF0FDF4) : const Color(0xFF14532D).withOpacity(0.25))
                      : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF10B981).withOpacity(0.40)
                        : border,
                    width: 1.2,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF10B981)
                          : accent.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: accent,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    taskTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDone ? const Color(0xFF10B981) : accent,
                  ),
                ),
              ),
            );
          }),
        ],

        const SizedBox(height: 22),
        Text(
          'OR ENTER QUICK CUSTOM TARGET',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTaskController,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Rapid ECG reading...',
                  hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 1.8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ApplePressable(
              pressedScale: 0.95,
              onTap: () {
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
              child: ElevatedButton(
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
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurriculumModuleTab(
    List<Subject> subjects,
    Subject? currentSub,
    TimerThemeData theme,
  ) {
    if (subjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final accent = theme.accentColor;
    final cardBg = AppTheme.cardWhite;
    final border = AppTheme.borderLight;
    final textPrimary = AppTheme.inkForeground;
    final textSecondary = AppTheme.mutedText;

    return Column(
      children: [
        // 1. Horizontal Subject Selector
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final sub = subjects[i];
              final isSelected = sub.id == _selectedSubjectId;
              final meta = subjectMeta(sub.id);

              return ApplePressable(
                pressedScale: 0.94,
                onTap: () {
                  setState(() {
                    _selectedSubjectId = sub.id;
                    _selectedChapterIndex = 0;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? accent : cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? accent : border,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accent.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SubjectSketchIcon(
                        subjectId: sub.id,
                        size: 16,
                        color: isSelected ? Colors.white : meta.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sub.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        // 1b. Category Selector (Videos | Q-Bank | Notes)
        if (currentSub != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                _categoryFilterChip(
                  'videos',
                  'Videos (${currentSub.totalVideos})',
                  Icons.play_arrow_rounded,
                  AppTheme.primaryBlue,
                  theme,
                ),
                const SizedBox(width: 8),
                _categoryFilterChip(
                  'qbank',
                  'Q-Bank (${currentSub.totalQBanks})',
                  Icons.quiz_rounded,
                  Colors.teal,
                  theme,
                ),
                const SizedBox(width: 8),
                _categoryFilterChip(
                  'notes',
                  'Notes (${currentSub.totalNotes})',
                  Icons.menu_book_rounded,
                  Colors.amber.shade700,
                  theme,
                ),
              ],
            ),
          ),

        // 2. Unit Dropdown / Selector
        Builder(
          builder: (context) {
            if (currentSub == null) return const SizedBox.shrink();
            final targetChapters = _selectedCategory == 'qbank'
                ? currentSub.qbankChapters
                : currentSub.chapters;

            if (targetChapters.isEmpty) return const SizedBox.shrink();

            final safeIndex = _selectedChapterIndex.clamp(0, targetChapters.length - 1);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: safeIndex,
                    dropdownColor: cardBg,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
                    items: targetChapters.asMap().entries.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(
                          'Unit ${e.key + 1}: ${e.value.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
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
            );
          },
        ),

        // 3. Module List under this Unit
        Expanded(
          child: Builder(
            builder: (ctx) {
              if (currentSub == null) {
                return Center(
                  child: Text('No subject selected', style: TextStyle(color: textSecondary)),
                );
              }
              final targetChapters = _selectedCategory == 'qbank'
                  ? currentSub.qbankChapters
                  : currentSub.chapters;

              if (targetChapters.isEmpty) {
                return Center(
                  child: Text('No units available', style: TextStyle(color: textSecondary)),
                );
              }
              final chapter = targetChapters[_selectedChapterIndex.clamp(0, targetChapters.length - 1)];

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                children: [
                  // Videos
                  if (_selectedCategory == 'videos' && chapter.videos.isNotEmpty) ...[
                    _groupHeader('VIDEO LECTURES (${chapter.videos.length})', theme),
                    ...chapter.videos.map((v) {
                      return _moduleTile(
                        icon: Icons.play_circle_fill_rounded,
                        iconColor: AppTheme.primaryBlue,
                        title: v.title,
                        badgeText: v.durationLabel,
                        theme: theme,
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
                  if (_selectedCategory == 'qbank' && chapter.qbanks.isNotEmpty) ...[
                    _groupHeader('Q-BANK MODULES (${chapter.qbanks.length})', theme),
                    ...chapter.qbanks.map((q) {
                      return _moduleTile(
                        icon: Icons.quiz_rounded,
                        iconColor: Colors.teal,
                        title: q.title,
                        badgeText: '${q.totalMcqs} MCQs',
                        theme: theme,
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
                  if (_selectedCategory == 'notes' && chapter.notes.isNotEmpty) ...[
                    _groupHeader('NOTES & TEXTBOOKS (${chapter.notes.length})', theme),
                    ...chapter.notes.map((n) {
                      return _moduleTile(
                        icon: Icons.menu_book_rounded,
                        iconColor: Colors.amber.shade700,
                        title: n.title,
                        badgeText: 'Notes',
                        theme: theme,
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

  Widget _moduleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required TimerThemeData theme,
    required VoidCallback onTap,
  }) {
    final cardBg = AppTheme.cardWhite;
    final border = AppTheme.borderLight;
    final textPrimary = AppTheme.inkForeground;
    final textSecondary = AppTheme.mutedText;

    return ApplePressable(
      pressedScale: 0.98,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Icon(icon, color: iconColor, size: 24),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: textPrimary,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
        ),
      ),
    );
  }

  Widget _categoryFilterChip(
    String cat,
    String label,
    IconData icon,
    Color color,
    TimerThemeData theme,
  ) {
    final isSelected = _selectedCategory == cat;
    final border = AppTheme.borderLight;
    final cardBg = AppTheme.cardWhite;
    final unselectedText = AppTheme.mutedText;

    return Expanded(
      child: ApplePressable(
        pressedScale: 0.94,
        onTap: () {
          setState(() {
            _selectedCategory = cat;
            _selectedChapterIndex = 0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.14)
                : cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : border,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x050F172A),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : unselectedText),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? color : unselectedText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupHeader(String text, TimerThemeData theme) {
    const bg = Color(0xFFF1F5F9);
    const fg = Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: fg,
        ),
      ),
    );
  }
}
