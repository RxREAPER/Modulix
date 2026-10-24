import 'package:flutter/material.dart';
import '../../theme/tasks_theme.dart';

/// Wraps its [child] in the Tasks Hub standalone white-mode [ThemeData].
/// This ensures no Modulix sketch theme, paper textures, or palette
/// presets bleed into the Tasks section.
class TasksThemeWrapper extends StatelessWidget {
  final Widget child;

  const TasksThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: TasksTheme.themeData,
      child: child,
    );
  }
}
