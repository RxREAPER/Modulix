import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_state.dart';
import '../../models/syllabus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../theme/app_theme.dart';
import '../../data/subjects_metadata.dart';

class ConfigurePlanSheet extends ConsumerStatefulWidget {
  const ConfigurePlanSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (ctx) => const ConfigurePlanSheet(),
    );
  }

  @override
  ConsumerState<ConfigurePlanSheet> createState() => _ConfigurePlanSheetState();
}

class _ConfigurePlanSheetState extends ConsumerState<ConfigurePlanSheet> {
  String? _targetSubject;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  int _videosPerDay = 5;
  double _dailyHours = 4.0;
  List<String> _selectedUnits = [];
  int _revisionCycles = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final appState = ref.read(appStateProvider).value;
    if (appState != null) {
      final p = appState.currentEdition.plan;
      if (p.targetSubject.isNotEmpty) {
        _targetSubject = p.targetSubject;
      }
      _videosPerDay = p.videosPerDay ?? 5;
      _selectedUnits = List.from(p.targetUnits);
      _dailyHours = p.dailyHours;
      _revisionCycles = p.revisionCycles;
      if (p.targetDate.isNotEmpty) {
        try {
          _targetDate = DateTime.parse(p.targetDate);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final syllabusAsync = ref.watch(activeSyllabusProvider);
    final subjects = syllabusAsync.value ?? [];

    if (_targetSubject == null && subjects.isNotEmpty) {
      _targetSubject = subjects.first.id;
    }

    final selectedSub = subjects.where((s) => s.id == _targetSubject).firstOrNull;
    final totalVids = selectedSub != null
        ? (_selectedUnits.isEmpty
            ? selectedSub.totalVideos
            : selectedSub.chapters
                .where((c) => _selectedUnits.contains(c.name))
                .expand((c) => c.videos)
                .length)
        : 0;

    final daysRemaining = _targetDate.difference(DateTime.now()).inDays.clamp(1, 1000);
    final neededPerDay = (totalVids / daysRemaining).ceil();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Module Based Study Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    Text(
                      'Automate your NEET-PG daily module targets',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1.5, color: Color(0xFFE4E4E7)),

          // Scrollable config contents
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // STEP 1: Subject Picker
                _sectionTitle('1. Choose Target Subject', Icons.menu_book_rounded),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    scrollDirection: Axis.horizontal,
                    itemCount: subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final sub = subjects[i];
                      final isSelected = sub.id == _targetSubject;
                      final meta = subjectMeta(sub.id);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _targetSubject = sub.id;
                            _selectedUnits.clear();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 86,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? meta.accent.withOpacity(0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.sketchBorderColor : Colors.grey.shade300,
                              width: isSelected ? 2.0 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    const BoxShadow(
                                      color: Color(0x181C1C1C),
                                      offset: Offset(3, 3),
                                      blurRadius: 0,
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: meta.accent.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(meta.icon, color: meta.accent, size: 18),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sub.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? AppTheme.inkForeground : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // STEP 2: Exam Date & Daily Pace
                _sectionTitle('2. Target Exam Date & Pace', Icons.event_available_rounded),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 16,
                  ),
                  child: Column(
                    children: [
                      // Date Picker Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXAM TARGET DATE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEE, d MMM yyyy').format(_targetDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkForeground,
                                ),
                              ),
                              Text(
                                '$daysRemaining days remaining',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _targetDate,
                                firstDate: DateTime.now().add(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 1200)),
                              );
                              if (picked != null) {
                                setState(() => _targetDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: const Text('Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.paperBackground,
                              foregroundColor: AppTheme.inkForeground,
                              elevation: 0,
                              side: const BorderSide(color: AppTheme.sketchBorderColor, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),

                      // Videos per day slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Videos to watch per day',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_videosPerDay vids/day',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _videosPerDay.toDouble(),
                        min: 1,
                        max: 25,
                        divisions: 24,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (v) => setState(() => _videosPerDay = v.round()),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pace needed to finish before exam: ~$neededPerDay vids/day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: neededPerDay > _videosPerDay
                                ? Colors.red.shade600
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // STEP 3: Daily Study Hours & Revision
                _sectionTitle('3. Daily Study Hours & Revision', Icons.alarm_rounded),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 16,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily study commitment',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            '${_dailyHours.toStringAsFixed(1)} hrs/day',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _dailyHours,
                        min: 1.0,
                        max: 12.0,
                        divisions: 22,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (v) => setState(() => _dailyHours = v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Revision cycles planned',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _revisionCycles > 1
                                    ? () => setState(() => _revisionCycles--)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _revisionCycles > 1 ? Colors.grey.shade100 : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                    color: _revisionCycles > 1 ? AppTheme.inkForeground : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '$_revisionCycles cycle${_revisionCycles > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _revisionCycles < 5
                                    ? () => setState(() => _revisionCycles++)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _revisionCycles < 5 ? Colors.grey.shade100 : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: _revisionCycles < 5 ? AppTheme.inkForeground : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // STEP 4: Chapter/Unit Scope
                if (selectedSub != null) ...[
                  _sectionTitle(
                    '4. Unit Scope (Optional)',
                    Icons.filter_list_rounded,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All units selected by default. Tap to focus on specific units.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedSub.chapters.map((ch) {
                      final isSelected = _selectedUnits.contains(ch.name);
                      return FilterChip(
                        label: Text(
                          ch.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.inkForeground : Colors.grey.shade800,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.highlightCoral,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? AppTheme.sketchBorderColor : Colors.grey.shade300,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedUnits.add(ch.name);
                            } else {
                              _selectedUnits.remove(ch.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 32),

                // Save Action Button
                ElevatedButton.icon(
                  onPressed: _saving ? null : _savePlan,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    _saving ? 'Saving...' : 'Lock In Study Plan',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.inkForeground,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.inkForeground,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Future<void> _savePlan() async {
    if (_targetSubject == null) return;
    setState(() => _saving = true);

    final plan = StudyPlan(
      targetSubject: _targetSubject!,
      targetDate: DateFormat('yyyy-MM-dd').format(_targetDate),
      videosPerDay: _videosPerDay,
      dailyHours: _dailyHours,
      revisionCycles: _revisionCycles,
      targetUnits: _selectedUnits,
    );

    await ref.read(appStateProvider.notifier).updatePlan(plan);
    // Invalidate module batch so it immediately regenerates for the new subject/unit
    await ref.read(appStateProvider.notifier).setBatch([]);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('flowmd_module_batch_date');
    } catch (_) {}
    setState(() => _saving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Study Plan updated for ${_targetSubject!.toUpperCase()}!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
