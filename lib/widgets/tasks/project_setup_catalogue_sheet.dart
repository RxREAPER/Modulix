import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/subjects_metadata.dart';
import '../../models/syllabus.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/tasks_theme.dart';

/// Modal catalogue allowing users to create either a "Module based"
/// or "Self Study" project with progressive disclosure steps.
class ProjectSetupCatalogueSheet extends ConsumerStatefulWidget {
  const ProjectSetupCatalogueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProjectSetupCatalogueSheet(),
    );
  }

  @override
  ConsumerState<ProjectSetupCatalogueSheet> createState() =>
      _ProjectSetupCatalogueSheetState();
}

class _ProjectSetupCatalogueSheetState
    extends ConsumerState<ProjectSetupCatalogueSheet> {
  // Mode: null | 'module' | 'self_study'
  String? _selectedMode;

  // Selections
  Subject? _selectedSubject;
  Chapter? _selectedUnit;
  DateTime? _selectedDeadline;
  int _perDayModules = 2;

  // Progressive collapsing states
  bool _isSubjectCollapsed = false;
  bool _isUnitCollapsed = false;

  // Self study specific
  bool _isGeneralStudy = false;
  final TextEditingController _customTitleController = TextEditingController();

  bool _isCreating = false;

  @override
  void dispose() {
    _customTitleController.dispose();
    super.dispose();
  }

  String _formatDynamicGuide() {
    if (_selectedMode != 'module' || _selectedUnit == null) return '';
    final totalModules = _selectedUnit!.videos.length;
    if (totalModules == 0) return 'No video modules in this unit';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedDeadline != null) {
      final days = _selectedDeadline!.difference(today).inDays + 1;
      if (days <= 0) {
        return '$totalModules modules · Deadline must be in the future';
      }
      final neededPace = (totalModules / days).ceil();
      final deadlineStr = DateFormat('dd MMM').format(_selectedDeadline!);
      return '$totalModules modules across $days days · ~$neededPace per day by $deadlineStr';
    } else {
      final pace = _perDayModules > 0 ? _perDayModules : 1;
      final daysNeeded = (totalModules / pace).ceil();
      final finishDate = today.add(Duration(days: daysNeeded - 1));
      final dateStr = DateFormat('dd MMM').format(finishDate);
      return '$totalModules modules at $pace/day · Finishes in $daysNeeded days ($dateStr)';
    }
  }

  Future<void> _handleConfirm() async {
    if (_isCreating) return;

    if (_selectedMode == 'module') {
      if (_selectedSubject == null || _selectedUnit == null) return;
      setState(() => _isCreating = true);

      final notifier = ref.read(tasksHubProvider.notifier);
      final project = await notifier.createModuleProject(
        name: '${_selectedSubject!.displayName} · ${_selectedUnit!.name}',
        subjectId: _selectedSubject!.id,
        subjectName: _selectedSubject!.displayName,
        unitName: _selectedUnit!.name,
        videos: _selectedUnit!.videos,
        deadline: _selectedDeadline,
        perDayModules: _perDayModules,
      );

      if (mounted) {
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        router.push('/tasks/project/${project.id}');
      }
    } else if (_selectedMode == 'self_study') {
      setState(() => _isCreating = true);

      final subjectId = _isGeneralStudy ? 'general' : (_selectedSubject?.id ?? 'general');
      final subjectName = _isGeneralStudy
          ? 'General Study'
          : (_selectedSubject?.displayName ?? 'General Study');
      final unitName = _selectedUnit?.name;

      final customName = _customTitleController.text.trim();
      final projectName = customName.isNotEmpty
          ? customName
          : (_isGeneralStudy
              ? 'General Study'
              : (unitName != null
                  ? '$subjectName · $unitName'
                  : '$subjectName Study'));

      final notifier = ref.read(tasksHubProvider.notifier);
      final project = await notifier.createSelfStudyProject(
        name: projectName,
        subjectId: subjectId,
        subjectName: subjectName,
        unitName: unitName,
        deadline: _selectedDeadline,
      );

      if (mounted) {
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        router.push('/tasks/project/${project.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final syllabusAsync = ref.watch(activeSyllabusProvider);
    final subjects = syllabusAsync.value ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: TasksTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: TasksTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New Project',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: TasksTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: TasksTheme.textTertiary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: TasksTheme.divider),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Selection
                    _buildSectionHeader('1', 'PROJECT MODE'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeCard(
                            mode: 'module',
                            title: 'Module based',
                            subtitle: 'Syllabus video modules',
                            icon: Icons.view_timeline_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModeCard(
                            mode: 'self_study',
                            title: 'Self Study',
                            subtitle: 'Custom tasks & reading',
                            icon: Icons.auto_stories_outlined,
                          ),
                        ),
                      ],
                    ),

                    if (_selectedMode != null) ...[
                      const SizedBox(height: 24),

                      // Step 2: Subject Selection
                      _buildSectionHeader('2', 'SUBJECT'),
                      if (_isSubjectCollapsed && (_selectedSubject != null || _isGeneralStudy))
                        _buildCollapsedSummary(
                          icon: _isGeneralStudy
                              ? Icons.menu_book_rounded
                              : subjectMeta(_selectedSubject!.id).icon,
                          iconColor: _isGeneralStudy
                              ? const Color(0xFF10B981)
                              : subjectMeta(_selectedSubject!.id).accent,
                          title: _isGeneralStudy
                              ? 'General Study'
                              : _selectedSubject!.displayName,
                          onChange: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isSubjectCollapsed = false);
                          },
                        )
                      else
                        _buildSubjectSelector(subjects),

                      // Step 3: Unit Selection
                      if (_selectedSubject != null || _isGeneralStudy) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          '3',
                          'UNIT',
                          optionalBadge: _selectedMode == 'self_study' ? 'Optional' : null,
                        ),
                        if (_isUnitCollapsed &&
                            (_selectedUnit != null ||
                                (_selectedMode == 'self_study' && _selectedUnit == null)))
                          _buildCollapsedSummary(
                            icon: Icons.bookmark_outline_rounded,
                            iconColor: TasksTheme.accent,
                            title: _selectedUnit != null
                                ? '${_selectedUnit!.name} · ${_selectedUnit!.videos.length} videos'
                                : (_isGeneralStudy
                                    ? 'General Study Curriculum'
                                    : 'Entire Subject'),
                            onChange: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isUnitCollapsed = false);
                            },
                          )
                        else
                          _buildUnitSelector(),
                      ],

                      // Step 4: Deadline & Pace for Module Based
                      if (_selectedMode == 'module' && _selectedUnit != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('4', 'SCHEDULE & PACING'),
                        _buildModulePaceControls(),

                        // Dynamic Guide Text
                        Container(
                          margin: const EdgeInsets.only(top: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TasksTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: TasksTheme.border),
                          ),
                          child: Text(
                            _formatDynamicGuide(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: TasksTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],

                      // Self study options
                      if (_selectedMode == 'self_study' &&
                          (_selectedSubject != null || _isGeneralStudy)) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('4', 'DETAILS & SCHEDULE'),
                        TextField(
                          controller: _customTitleController,
                          style: const TextStyle(
                            fontSize: 15,
                            color: TasksTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: _isGeneralStudy
                                ? 'General Study'
                                : '${_selectedSubject?.displayName ?? "Subject"} Study',
                            hintStyle: const TextStyle(color: TasksTheme.textTertiary),
                            filled: true,
                            fillColor: TasksTheme.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: TasksTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: TasksTheme.accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.event_outlined, size: 18, color: TasksTheme.textSecondary),
                                SizedBox(width: 8),
                                Text(
                                  'Target completion',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: TasksTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDeadline = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: TasksTheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: TasksTheme.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedDeadline != null
                                          ? DateFormat('dd MMM yyyy').format(_selectedDeadline!)
                                          : 'Add deadline',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _selectedDeadline != null ? FontWeight.w600 : FontWeight.w400,
                                        color: _selectedDeadline != null
                                            ? TasksTheme.textPrimary
                                            : TasksTheme.accent,
                                      ),
                                    ),
                                    if (_selectedDeadline != null) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedDeadline = null),
                                        child: const Icon(Icons.close_rounded, size: 14, color: TasksTheme.textTertiary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TasksTheme.accent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _canConfirm() ? _handleConfirm : null,
                          child: _isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Project',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canConfirm() {
    if (_isCreating) return false;
    if (_selectedMode == 'module') {
      return _selectedSubject != null && _selectedUnit != null;
    }
    if (_selectedMode == 'self_study') {
      return _selectedSubject != null || _isGeneralStudy;
    }
    return false;
  }

  Widget _buildSectionHeader(String stepNumber, String title, {String? optionalBadge}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TasksTheme.textPrimary,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: TasksTheme.textPrimary,
            ),
          ),
          if (optionalBadge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: TasksTheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: TasksTheme.border),
              ),
              child: Text(
                optionalBadge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: TasksTheme.textTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedSummary({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onChange,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TasksTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TasksTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TasksTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TasksTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TasksTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMode = mode;
          _selectedSubject = null;
          _selectedUnit = null;
          _isGeneralStudy = false;
          _isSubjectCollapsed = false;
          _isUnitCollapsed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? TasksTheme.surface : TasksTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? TasksTheme.accent : TasksTheme.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? TasksTheme.accent : TasksTheme.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: TasksTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: TasksTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelector(List<Subject> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedMode == 'self_study')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildChoiceChip(
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF10B981),
              label: 'General Study',
              isSelected: _isGeneralStudy,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isGeneralStudy = true;
                  _selectedSubject = null;
                  _selectedUnit = null;
                  _isSubjectCollapsed = true;
                  _isUnitCollapsed = false;
                });
              },
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subjects.map((sub) {
            final isSelected = !_isGeneralStudy && _selectedSubject?.id == sub.id;
            final meta = subjectMeta(sub.id);
            return _buildChoiceChip(
              icon: meta.icon,
              iconColor: meta.accent,
              label: sub.displayName,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isGeneralStudy = false;
                  _selectedSubject = sub;
                  _selectedUnit = null;
                  _isSubjectCollapsed = true;
                  _isUnitCollapsed = false;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUnitSelector() {
    if (_isGeneralStudy) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TasksTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TasksTheme.border),
        ),
        child: const Text(
          'General Study covers non-curriculum topics and self-paced work.',
          style: TextStyle(fontSize: 13, color: TasksTheme.textSecondary),
        ),
      );
    }

    final chapters = _selectedSubject?.chapters ?? [];
    if (chapters.isEmpty) {
      return const Text(
        'No units available for this subject',
        style: TextStyle(fontSize: 13, color: TasksTheme.textTertiary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedMode == 'self_study')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildChoiceChip(
              label: 'Skip Unit / Entire Subject',
              isSelected: _selectedUnit == null,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedUnit = null;
                  _isUnitCollapsed = true;
                });
              },
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chapters.map((ch) {
            final isSelected = _selectedUnit?.name == ch.name;
            return _buildChoiceChip(
              label: '${ch.name} · ${ch.videos.length}',
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedUnit = ch;
                  _isUnitCollapsed = true;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    IconData? icon,
    Color? iconColor,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TasksTheme.textPrimary : TasksTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? TasksTheme.textPrimary : TasksTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : (iconColor ?? TasksTheme.textSecondary),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : TasksTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulePaceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily modules stepper
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Per day video modules',
              style: TextStyle(
                fontSize: 14,
                color: TasksTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                  color: _perDayModules > 1 ? TasksTheme.textPrimary : TasksTheme.border,
                  onPressed: _perDayModules > 1
                      ? () => setState(() => _perDayModules--)
                      : null,
                ),
                Text(
                  '$_perDayModules',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TasksTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                  color: _perDayModules < 10 ? TasksTheme.textPrimary : TasksTheme.border,
                  onPressed: _perDayModules < 10
                      ? () => setState(() => _perDayModules++)
                      : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Inline completion target (no "Target deadline" heading)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: TasksTheme.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Target completion',
                  style: TextStyle(
                    fontSize: 14,
                    color: TasksTheme.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDeadline = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: TasksTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: TasksTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedDeadline != null
                          ? DateFormat('dd MMM yyyy').format(_selectedDeadline!)
                          : 'Add deadline',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedDeadline != null ? FontWeight.w600 : FontWeight.w400,
                        color: _selectedDeadline != null
                            ? TasksTheme.textPrimary
                            : TasksTheme.accent,
                      ),
                    ),
                    if (_selectedDeadline != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDeadline = null),
                        child: const Icon(Icons.close_rounded, size: 14, color: TasksTheme.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
