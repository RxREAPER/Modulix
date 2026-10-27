import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/modulix_theme.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';

/// Full-page Theme Studio featuring minimalist, visual-first theme showcase cards.
class ThemeStudioScreen extends ConsumerWidget {
  const ThemeStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = context.modulixTheme;
    final appStateAsync = ref.watch(appStateProvider);
    final appState = appStateAsync.value ?? AppState.empty;
    final selectedPreset = PalettePreset.fromId(appState.palettePresetId);

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        try {
          context.go('/settings');
        } catch (_) {}
      },
      child: Scaffold(
        backgroundColor: activeTheme.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: activeTheme.scaffoldBackground,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: activeTheme.inkForeground),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go('/settings');
                } catch (_) {}
              }
            },
          ),
        title: Text(
          'Theme Studio',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: activeTheme.inkForeground,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        children: [
          // Themes Section Header
          Text(
            'THEMES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: activeTheme.mutedText,
            ),
          ),
          const SizedBox(height: 12),

          // Minimalist, visual-first theme cards
          for (final preset in PalettePreset.values) ...[
            _VisualThemeCard(
              preset: preset,
              isSelected: preset.id == selectedPreset.id,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(appStateProvider.notifier).setPalettePreset(preset.id);
              },
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    ),
  );
}
}

class _VisualThemeCard extends StatelessWidget {
  final PalettePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisualThemeCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeAccent = preset.isDark ? preset.accentDark : preset.accent;
    final secondaryAccent = preset.secondaryAccent;
    final onAccentColor =
        themeAccent.computeLuminance() > 0.45 ? const Color(0xFF1E1610) : Colors.white;

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.98,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: preset.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeAccent : preset.borderSubtle.withValues(alpha: 0.5),
            width: isSelected ? 1.0 : 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? themeAccent.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: preset.isDark ? 0.25 : 0.03),
              offset: const Offset(0, 3),
              blurRadius: isSelected ? 12 : 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Theme Title & Animated Selection Halo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.label,
                        style: AppTheme.headingStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: preset.inkForeground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preset.description,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: preset.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Animated Selection Radio
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? themeAccent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? themeAccent : preset.borderSubtle,
                      width: 1.2,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: onAccentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Fluid Expansion: Atmospheric Preview Strip when selected
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isSelected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  preset.scaffoldBackground,
                                  preset.surfaceSubtle,
                                  themeAccent,
                                  secondaryAccent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Bottom: Animated Swatches & Status Label
            Row(
              children: [
                _buildAnimatedSwatch(
                  color: preset.scaffoldBackground,
                  borderColor: preset.borderSubtle,
                  isSelected: isSelected,
                ),
                const SizedBox(width: 8),
                _buildAnimatedSwatch(
                  color: preset.surfaceSubtle,
                  borderColor: preset.borderSubtle,
                  isSelected: isSelected,
                ),
                const SizedBox(width: 8),
                _buildAnimatedSwatch(
                  color: themeAccent,
                  borderColor: themeAccent.withValues(alpha: 0.5),
                  isSelected: isSelected,
                ),
                const SizedBox(width: 8),
                _buildAnimatedSwatch(
                  color: secondaryAccent,
                  borderColor: secondaryAccent.withValues(alpha: 0.5),
                  isSelected: isSelected,
                ),
                const Spacer(),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? themeAccent : preset.mutedText,
                  ),
                  child: Text(isSelected ? 'Active Atmosphere' : 'Tap to apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSwatch({
    required Color color,
    required Color borderColor,
    required bool isSelected,
  }) {
    return AnimatedScale(
      scale: isSelected ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}
