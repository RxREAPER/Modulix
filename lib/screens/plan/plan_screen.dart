import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/subjects_metadata.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/elastic_ink_pill.dart';
import '../../widgets/animations/rolling_digit_text.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/curriculum/subject_sketch_icon.dart';
import '../../widgets/errors/app_error_state_view.dart';
import '../../widgets/loading/app_shimmer.dart';
import '../../widgets/feedback/modulix_toast.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  String? _selectedSubject;
  DateTime? _targetDate;
  int? _videosPerDay;
  List<String> _selectedUnits = [];
  bool _isMultipleMode = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider).value;
    final syllabusAsync = ref.watch(activeSyllabusProvider);
    final subjects = syllabusAsync.value ?? [];
    final isDark = AppTheme.current.isDark;

    // Load existing configured plan once
    if (appState != null && !_loaded) {
      final plan = appState.currentEdition.plan;
      if (plan.isConfigured) {
        _selectedSubject = plan.targetSubject;
        _videosPerDay = plan.videosPerDay;
        _selectedUnits = List.from(plan.targetUnits);
        _isMultipleMode = plan.targetUnits.isNotEmpty;
        if (plan.targetDate.isNotEmpty) {
          try {
            _targetDate = DateTime.parse(plan.targetDate);
          } catch (_) {}
        }
      } else {
        // Brand new user or unconfigured plan: start blank awaiting selection (Task G)
        _selectedSubject = null;
        _targetDate = null;
        _videosPerDay = null;
        _selectedUnits = [];
        _isMultipleMode = false;
      }
      _loaded = true;
    }

    final selectedSub =
        subjects.where((s) => s.id == _selectedSubject).firstOrNull;

    // If in "All" mode and units haven't been populated or was empty, reflect all chapters
    if (selectedSub != null && !_isMultipleMode) {
      if (_selectedUnits.length != selectedSub.chapters.length) {
        _selectedUnits = selectedSub.chapters.map((c) => c.name).toList();
      }
    }

    final totalVids = selectedSub != null
        ? (_isMultipleMode
            ? selectedSub.chapters
                .where((c) => _selectedUnits.contains(c.name))
                .expand((c) => c.videos)
                .length
            : selectedSub.totalVideos)
        : 0;

    final now = DateTime.now();
    final daysRemaining = _targetDate != null
        ? DateTime.utc(_targetDate!.year, _targetDate!.month, _targetDate!.day)
            .difference(DateTime.utc(now.year, now.month, now.day))
            .inDays
            .clamp(1, 1000)
        : 0;

    final neededPerDay = (_targetDate != null && daysRemaining > 0 && totalVids > 0)
        ? (totalVids / daysRemaining).ceil()
        : 0;

    final canSave = _selectedSubject != null &&
        _targetDate != null &&
        _videosPerDay != null &&
        _videosPerDay! > 0 &&
        (!_isMultipleMode || _selectedUnits.isNotEmpty);

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        try {
          context.go('/');
        } catch (_) {}
      },
      child: Scaffold(
        backgroundColor: AppTheme.paperBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.paperBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: AppTheme.inkForeground),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go('/');
                } catch (_) {}
              }
            },
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Module-Based Study Plan',
              style: AppTheme.headingStyle(
                color: AppTheme.inkForeground,
                fontSize: 18.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: (_saving || !canSave) ? null : _savePlan,
                icon: _saving
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryBlue,
                        ),
                      )
                    : Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: canSave
                            ? AppTheme.primaryBlue
                            : Colors.grey.shade400,
                      ),
                label: Text(
                  _saving ? 'Saving...' : 'Save',
                  style: AppTypography.compactAction(
                    fontWeight: FontWeight.w600,
                    color: canSave
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.2),
            child: Container(
              height: 1.2,
              color: AppTheme.parchmentBorder.withValues(alpha: 0.7),
            ),
          ),
        ),
        body: syllabusAsync.when(
          loading: () => const ModuleTimelineSkeletonView(),
          error: (e, st) => AppErrorStateView(
            error: e,
            stackTrace: st,
            onRetry: () => ref.refresh(activeSyllabusProvider),
          ),
          data: (subjectsList) => ListView(
            scrollCacheExtent: const ScrollCacheExtent.pixels(450.0),
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
            children: [
              // Task A: Info box removed! Directly starts with Step 1

              // ── STEP 1: Choose Target Subject ─────────────────────────────
              _sectionHeader(
                '1. Target Subject',
                Icons.menu_book_rounded,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 106,
                child: RepaintBoundary(
                  child: ListView.separated(
                    scrollCacheExtent: const ScrollCacheExtent.pixels(350.0),
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    scrollDirection: Axis.horizontal,
                    itemCount: subjectsList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                    final sub = subjectsList[i];
                    final isSelected = sub.id == _selectedSubject;

                    return ApplePressable(
                      pressedScale: 0.94,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (_selectedSubject == sub.id) return;
                          _selectedSubject = sub.id;

                          // Task G: Check if selected subject matches saved plan
                          final savedPlan = appState?.currentEdition.plan;
                          if (savedPlan != null &&
                              savedPlan.isConfigured &&
                              savedPlan.targetSubject == sub.id) {
                            // Restore this subject's saved plan
                            _videosPerDay = savedPlan.videosPerDay;
                            _selectedUnits = List.from(savedPlan.targetUnits);
                            _isMultipleMode = savedPlan.targetUnits.isNotEmpty;
                            if (savedPlan.targetDate.isNotEmpty) {
                              try {
                                _targetDate = DateTime.parse(savedPlan.targetDate);
                              } catch (_) {
                                _targetDate = null;
                              }
                            } else {
                              _targetDate = null;
                            }
                          } else {
                            // Brand new / different subject: Blank parameters awaiting user input!
                            _targetDate = null;
                            _videosPerDay = null;
                            _selectedUnits = [];
                            _isMultipleMode = false;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 92,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentSubtle
                              : AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentPrimary
                                : AppTheme.borderLight,
                            width: isSelected ? 2.0 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accentPrimary.withValues(alpha: 0.18),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SubjectSketchIcon(
                              subjectId: sub.id,
                              color: subjectMeta(sub.id).accent,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sub.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTypography.cardTitle(
                                fontSize: 11.0,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.inkForeground
                                    : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${sub.totalVideos} vids',
                              style: AppTypography.cardMeta(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

              const SizedBox(height: 24),

              // ── STEP 2: Unit Scope (All & Multiple toggle) ────────
              _sectionHeader(
                '2. Unit Scope',
                Icons.filter_list_rounded,
              ),
              const SizedBox(height: 10),
              if (selectedSub != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'CHAPTER COVERAGE',
                      style: AppTypography.sectionMicroHeader(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // All / Multiple toggle component with ElasticInkPill
                    Container(
                      width: 132,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.parchmentSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.borderLight, width: 1.0),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tabWidth = constraints.maxWidth / 2;
                          final tabHeight = constraints.maxHeight;
                          return Stack(
                            children: [
                              ElasticInkPill(
                                targetRect: Rect.fromLTWH(
                                  _isMultipleMode ? tabWidth : 0.0,
                                  0.0,
                                  tabWidth,
                                  tabHeight,
                                ),
                                fillColor: AppTheme.primaryBlue,
                                strokeColor: AppTheme.primaryBlue,
                                strokeWidth: 1.0,
                                borderRadius: 16.0,
                                isSketchy: false,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _isMultipleMode = false;
                                          _selectedUnits = selectedSub.chapters
                                              .map((c) => c.name)
                                              .toList();
                                        });
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        height: tabHeight,
                                        alignment: Alignment.center,
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 150),
                                          style: AppTypography.compactAction(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: !_isMultipleMode
                                                ? Colors.white
                                                : AppTheme.inkForeground,
                                          ),
                                          child: const Text('All'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _isMultipleMode = true;
                                          _selectedUnits.clear(); // Task E: deselects all units on click
                                        });
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        height: tabHeight,
                                        alignment: Alignment.center,
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 150),
                                          style: AppTypography.compactAction(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: _isMultipleMode
                                                ? Colors.white
                                                : AppTheme.inkForeground,
                                          ),
                                          child: const Text('Multiple'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_isMultipleMode && _selectedUnits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Tap units below to set their sequence (1, 2, 3...)',
                      style: AppTypography.cardSubtitle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                // Unit Chips: Task E order numbering
                RepaintBoundary(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(selectedSub.chapters.length, (index) {
                    final ch = selectedSub.chapters[index];
                    final isSelected = _isMultipleMode
                        ? _selectedUnits.contains(ch.name)
                        : true;

                    // Numbering: In All mode -> 01, 02... In Multiple mode -> order 1, 2, 3...
                    final String badgeText;
                    if (_isMultipleMode) {
                      final orderIdx = _selectedUnits.indexOf(ch.name);
                      badgeText = orderIdx >= 0 ? '${orderIdx + 1}' : '+';
                    } else {
                      badgeText = (index + 1).toString().padLeft(2, '0');
                    }

                    return ApplePressable(
                      pressedScale: 0.94,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (!_isMultipleMode) {
                            // Tapping a chip in All mode automatically switches to Multiple mode with this unit as #1
                            _isMultipleMode = true;
                            _selectedUnits = [ch.name];
                          } else {
                            // Multiple mode: toggle unit in custom order
                            if (_selectedUnits.contains(ch.name)) {
                              _selectedUnits.remove(ch.name);
                            } else {
                              _selectedUnits.add(ch.name);
                            }
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                            width: 0.6,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    offset: const Offset(0, 1.5),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.0 : 0.92,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black.withValues(alpha: 0.12)
                                      : AppTheme.parchmentSurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeText,
                                  style: AppTypography.metricValue(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppTheme.inkForeground
                                        : AppTheme.mutedText,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                ch.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardTitle(
                                  fontSize: 11.0,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.inkForeground
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${ch.videos.length})',
                              style: AppTypography.cardMeta(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.inkForeground
                                        .withValues(alpha: 0.7)
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              ] else ...[
                // Awaiting subject selection prompt (Task G)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 20, color: AppTheme.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select a subject above to configure unit scope and start your study plan.',
                          style: AppTypography.cardSubtitle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── STEP 3: Deadline Date ───────────────────────────
              _sectionHeader(
                '3. Deadline Date',
                Icons.event_available_rounded,
              ),
              const SizedBox(height: 10),
              RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      width: 0.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEADLINE DATE',
                                style: AppTypography.sectionMicroHeader(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _targetDate != null
                                    ? DateFormat('EEE, d MMM yyyy')
                                        .format(_targetDate!)
                                    : 'Awaiting Date',
                                style: AppTypography.metricValue(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: _targetDate != null
                                      ? AppTheme.inkForeground
                                      : Colors.grey.shade400,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (_targetDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$daysRemaining days remaining',
                                    style: AppTypography.microBadge(
                                      fontSize: 10.5,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'Select deadline to calculate pace',
                                  style: AppTypography.cardSubtitle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final initial = _targetDate ??
                                DateTime.now().add(const Duration(days: 90));
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime.now()
                                   .add(const Duration(days: 1)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 1200)),
                            );
                            if (picked != null) {
                              HapticFeedback.lightImpact();
                              setState(() => _targetDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month_rounded,
                              size: 16),
                          label: Text(_targetDate != null ? 'Change' : 'Pick Date'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.paperBackground,
                            foregroundColor: AppTheme.inkForeground,
                            elevation: 0,
                            side: BorderSide(
                                color: AppTheme.sketchBorderColor,
                                width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            textStyle: AppTypography.compactAction(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(
                        height: 28, thickness: 1, color: Color(0xFFF0F0F0)),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Daily Module Target',
                            style: AppTypography.cardTitle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: Text(
                            'Video lectures to complete per day',
                            style: AppTypography.cardSubtitle(
                              fontSize: 11,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                                  width: 0.6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _stepperButton(
                                  icon: Icons.remove_rounded,
                                  enabled: _videosPerDay != null && _videosPerDay! > 1,
                                  onTap: () {
                                    if (_videosPerDay != null && _videosPerDay! > 1) {
                                      HapticFeedback.lightImpact();
                                      setState(() => _videosPerDay = _videosPerDay! - 1);
                                    }
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: _videosPerDay != null
                                      ? RollingDigitText.count(
                                          count: _videosPerDay!,
                                          style: AppTypography.metricValue(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.inkForeground,
                                          ),
                                        )
                                      : Text(
                                          '--',
                                          style: AppTypography.metricValue(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.inkForeground,
                                          ),
                                        ),
                                ),
                                _stepperButton(
                                  icon: Icons.add_rounded,
                                  enabled: _videosPerDay == null || _videosPerDay! < 35,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      if (_videosPerDay == null) {
                                        _videosPerDay = 5;
                                      } else if (_videosPerDay! < 35) {
                                        _videosPerDay = _videosPerDay! + 1;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

              // Dedicated On-Track / Pace Insight Card
              RepaintBoundary(
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: (_targetDate != null && _videosPerDay != null && _selectedSubject != null)
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (_videosPerDay ?? 0) >= neededPerDay
                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                              : const Color(0xFFD97706).withValues(alpha: 0.35),
                          width: 0.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ((_videosPerDay ?? 0) >= neededPerDay
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFD97706))
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              (_videosPerDay ?? 0) >= neededPerDay
                                  ? Icons.check_circle_rounded
                                  : Icons.speed_rounded,
                              size: 18,
                              color: (_videosPerDay ?? 0) >= neededPerDay
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target: $_videosPerDay/day  ·  Needed: ~$neededPerDay/day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.inkForeground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (_videosPerDay ?? 0) >= neededPerDay
                                      ? '$daysRemaining days remaining · On track for deadline'
                                      : '$daysRemaining days remaining · Increase daily target to meet target date',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: 32),

              // ── Action Buttons: Save & Direct Link to Tasks ───────────────
              // Tactile "Lock In Study Plan" button
              ApplePressable(
                onTap: (_saving || !canSave) ? null : _savePlan,
                pressedScale: 0.98,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: canSave
                        ? (isDark ? const Color(0xFF2C2C2E) : AppTheme.inkForeground)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                    border: canSave && isDark
                        ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8)
                        : null,
                    boxShadow: canSave
                        ? [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : AppTheme.inkForeground.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_saving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                          color: canSave
                              ? (isDark ? Colors.white : AppTheme.paperBackground)
                              : AppTheme.mutedText,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _saving
                            ? 'Saving Plan...'
                            : (canSave
                                ? 'Lock In Study Plan'
                                : 'Configure All Parameters Above'),
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: canSave
                              ? (isDark ? Colors.white : AppTheme.paperBackground)
                              : AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tactile "Open Module Tasks Queue" button
              ApplePressable(
                onTap: () => context.push('/module-tasks'),
                pressedScale: 0.98,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.view_timeline_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Open Module Tasks Queue',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.accentPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.headingStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkForeground,
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.cardSubtitle(
              fontSize: 11,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return ApplePressable(
      pressedScale: 0.90,
      onPressed: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.cardWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppTheme.borderLight : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.inkForeground : AppTheme.mutedText,
        ),
      ),
    );
  }

  Future<void> _savePlan() async {
    if (_selectedSubject == null || _targetDate == null || _videosPerDay == null) return;
    setState(() => _saving = true);

    final List<String> unitsToSave = _isMultipleMode
        ? List<String>.from(_selectedUnits)
        : [];

    final plan = StudyPlan(
      targetSubject: _selectedSubject!,
      targetDate: DateFormat('yyyy-MM-dd').format(_targetDate!),
      videosPerDay: _videosPerDay,
      targetUnits: unitsToSave,
    );

    await ref.read(appStateProvider.notifier).updatePlan(plan);

    // Invalidate module batch so it immediately regenerates for the new subject/unit
    await ref.read(appStateProvider.notifier).setBatch([]);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('modulix_module_batch_date'); await prefs.remove('flowmd_module_batch_date');
    } catch (_) {}

    setState(() => _saving = false);

    if (mounted) {
      ModulixToast.showSuccess(
        context,
        message: 'Module-Based Study Plan locked in for ${_selectedSubject!.toUpperCase()}!',
      );
    }
  }
}
