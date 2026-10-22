import 'package:flutter/cupertino.dart';
import 'theme_studio_screen.dart';

export 'theme_studio_screen.dart';

/// Legacy bridge for AppearanceThemeSheet redirecting to full-page ThemeStudioScreen.
class AppearanceThemeSheet extends StatelessWidget {
  const AppearanceThemeSheet({super.key});

  /// Navigates to full-page ThemeStudioScreen with a smooth native slide transition.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => const ThemeStudioScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ThemeStudioScreen();
  }
}
