import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../models/app_state.dart';
import '../../models/syllabus.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  String? _selectedSubject;
  DateTime? _targetDate;
  int _videosPerDay = 5;
  List<String> _selectedUnits = [];
  bool _saving = false;

  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider).value;
    final syllabusAsync = ref.watch(activeSyllabusProvider);

    // Load existing plan once
    if (appState != null && !_loaded) {
      final plan = appState.currentEdition.plan;
      _selectedSubject = plan.targetSubject.isEmpty ? null : plan.targetSubject;
      _videosPerDay = plan.videosPerDay ?? 5;
      _selectedUnits = List.from(plan.targetUnits);
      if (plan.targetDate.isNotEmpty) {
        try {
          _targetDate = DateTime.parse(plan.targetDate);
        } catch (_) {}
      }
      _loaded = true;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: const Text('Study Plan'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(appState),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: syllabusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subjects) => ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── Subject picker ─────────────────────────────────────────────
            _SectionLabel('Target Subject'),
            const SizedBox(height: 8),
            _SubjectPicker(
              subjects: subjects,
              selected: _selectedSubject,
              onChanged: (id) => setState(() {
                _selectedSubject = id;
                _selectedUnits = [];
              }),
            ),
            const SizedBox(height: 24),

            // ── Videos per day ─────────────────────────────────────────────
            _SectionLabel('Daily Video Target'),
            const SizedBox(height: 4),
            Text(
              '$_videosPerDay videos / day',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Slider(
              value: _videosPerDay.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '$_videosPerDay',
              onChanged: (v) => setState(() => _videosPerDay = v.round()),
            ),
            const SizedBox(height: 24),

            // ── Target date ────────────────────────────────────────────────
            _SectionLabel('Target Exam Date'),
            const SizedBox(height: 8),
            _DatePickerField(
              date: _targetDate,
              onPicked: (d) => setState(() => _targetDate = d),
            ),
            const SizedBox(height: 24),

            // ── Chapter scope ──────────────────────────────────────────────
            if (_selectedSubject != null) ...[
              _SectionLabel('Chapter Scope (optional)'),
              Text(
                'Leave empty to study the whole subject, or pick specific chapters.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5)),
              ),
              const SizedBox(height: 12),
              _ChapterSelector(
                subjects: subjects,
                subjectId: _selectedSubject!,
                selected: _selectedUnits,
                onChanged: (units) => setState(() => _selectedUnits = units),
              ),
            ],

            const SizedBox(height: 32),

            // ── Save button ────────────────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : () => _save(appState),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Plan',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _save(dynamic appState) async {
    if (_selectedSubject == null || _targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a subject and target date')),
      );
      return;
    }
    setState(() => _saving = true);
    final plan = StudyPlan(
      targetSubject: _selectedSubject!,
      targetDate: _targetDate!.toIso8601String().substring(0, 10),
      videosPerDay: _videosPerDay,
      targetUnits: _selectedUnits,
    );
    await ref.read(appStateProvider.notifier).updatePlan(plan);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved ✓'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _SubjectPicker extends StatelessWidget {
  final List<Subject> subjects;
  final String? selected;
  final ValueChanged<String> onChanged;

  const _SubjectPicker({
    required this.subjects,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      hint: const Text('Choose a subject'),
      decoration: const InputDecoration(),
      borderRadius: BorderRadius.circular(16),
      items: subjects
          .map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(s.displayName),
              ))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({required this.date, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now().add(const Duration(days: 90)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 1095)),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: cs.primary.withOpacity(0.7)),
            const SizedBox(width: 12),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : 'Select date',
              style: TextStyle(
                color: date != null ? cs.onSurface : cs.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterSelector extends StatelessWidget {
  final List<Subject> subjects;
  final String subjectId;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _ChapterSelector({
    required this.subjects,
    required this.subjectId,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subject = subjects.where((s) => s.id == subjectId).firstOrNull;
    if (subject == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subject.chapters.map((chapter) {
        final isSelected = selected.contains(chapter.name);
        return FilterChip(
          label: Text(chapter.name, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (v) {
            final updated = List<String>.from(selected);
            if (v) {
              updated.add(chapter.name);
            } else {
              updated.remove(chapter.name);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
