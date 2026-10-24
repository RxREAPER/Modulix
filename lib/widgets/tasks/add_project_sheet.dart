import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_project.dart';
import '../../providers/tasks_hub_provider.dart';
import '../../theme/tasks_theme.dart';

/// Sheet to create or edit a [TaskProject].
/// Minimal: name input + 8 color swatches.
class AddProjectSheet extends ConsumerStatefulWidget {
  final TaskProject? existing; // null = create new

  const AddProjectSheet({super.key, this.existing});

  @override
  ConsumerState<AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends ConsumerState<AddProjectSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _selectedColor = kProjectColorSwatches[6]; // grey default

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _controller.text = widget.existing!.name;
      _selectedColor = widget.existing!.colorHex;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(tasksHubProvider.notifier);
    if (widget.existing != null) {
      await notifier.updateProject(
          widget.existing!.copyWith(name: name, colorHex: _selectedColor));
    } else {
      final project =
          notifier.buildNewProject(name: name, colorHex: _selectedColor);
      await notifier.addProject(project);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: TasksTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TasksTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                widget.existing == null ? 'New Project' : 'Edit Project',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: TasksTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Name field
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(
                  fontSize: 15,
                  color: TasksTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Project name',
                  hintStyle: const TextStyle(color: TasksTheme.textTertiary),
                  filled: true,
                  fillColor: TasksTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: TasksTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: TasksTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: TasksTheme.accent, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Colour swatches
              const Text(
                'COLOUR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: TasksTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: kProjectColorSwatches
                    .map((hex) => _ColorSwatch(
                          hex: hex,
                          isSelected: hex == _selectedColor,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = hex);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: TasksTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.existing == null ? 'Create' : 'Save',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color c;
    try {
      c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      c = const Color(0xFF6B7280);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          border: isSelected
              ? Border.all(color: c, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
