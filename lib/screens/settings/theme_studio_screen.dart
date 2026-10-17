import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
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

    return Scaffold(
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
            }
          },
        ),
        title: Text(
          'Theme Studio',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
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
          // Banner styled consistently with the rest of the app
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: activeTheme.borderSubtle, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: activeTheme.isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : activeTheme.borderSubtle.withValues(alpha: 0.35),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activeTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeTheme.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: activeTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Atmospheres',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: activeTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select your visual theme. All canvases, card borders, and paired accents adapt instantly.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: activeTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

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
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: preset.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? themeAccent : preset.borderSubtle,
            width: isSelected ? 2.2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? themeAccent.withValues(alpha: 0.24)
                  : (preset.isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : preset.inkForeground.withValues(alpha: 0.10)),
              offset: const Offset(0, 2),
              blurRadius: isSelected ? 8 : 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Theme Title & Animated Selection Radio
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.label,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: preset.inkForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? themeAccent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? themeAccent : preset.borderSubtle,
                      width: 1.8,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
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

            // Middle: Mini App Canvas Showcase (True look & feel preview)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: preset.scaffoldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: preset.borderSubtle, width: 1.2),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: preset.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: preset.borderSubtle, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: preset.isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : preset.inkForeground.withValues(alpha: 0.08),
                      offset: const Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Simulated mini task row
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: themeAccent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: themeAccent, width: 1.0),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: onAccentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 7,
                          width: 90,
                          decoration: BoxDecoration(
                            color: preset.inkForeground.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: secondaryAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: secondaryAccent.withValues(alpha: 0.35),
                              width: 0.9,
                            ),
                          ),
                          child: Text(
                            'Desk',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: secondaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),

                    // Simulated mini focus button & progress bar
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: themeAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 12,
                                color: onAccentColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Focus',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: onAccentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Container(
                              height: 5,
                              color: preset.surfaceSubtle,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.68,
                                child: Container(color: themeAccent),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom: Palette Swatches & Status Label
            Row(
              children: [
                _buildSwatch(
                  color: preset.scaffoldBackground,
                  borderColor: preset.borderSubtle,
                ),
                const SizedBox(width: 6),
                _buildSwatch(
                  color: preset.surfaceSubtle,
                  borderColor: preset.borderSubtle,
                ),
                const SizedBox(width: 6),
                _buildSwatch(
                  color: themeAccent,
                  borderColor: themeAccent.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                _buildSwatch(
                  color: secondaryAccent,
                  borderColor: secondaryAccent.withValues(alpha: 0.4),
                ),
                const Spacer(),
                Text(
                  isSelected ? 'Active Atmosphere' : 'Tap to apply',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? themeAccent : preset.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwatch({
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}
