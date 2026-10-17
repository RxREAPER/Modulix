import 'package:flutter/material.dart';
import '../../models/timer_theme.dart';
import '../../theme/app_theme.dart';

class TimerBackgroundPicker extends StatefulWidget {
  final TimerThemeData activeTheme;
  final ValueChanged<TimerThemeData> onSelectTheme;

  const TimerBackgroundPicker({
    super.key,
    required this.activeTheme,
    required this.onSelectTheme,
  });

  static Future<void> show(
    BuildContext context, {
    required TimerThemeData activeTheme,
    required ValueChanged<TimerThemeData> onSelectTheme,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 320),
        reverseDuration: Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      ),
      builder: (ctx) => TimerBackgroundPicker(
        activeTheme: activeTheme,
        onSelectTheme: onSelectTheme,
      ),
    );
  }

  @override
  State<TimerBackgroundPicker> createState() => _TimerBackgroundPickerState();
}

class _TimerBackgroundPickerState extends State<TimerBackgroundPicker> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    final selectedIndex = kTimerThemes.indexWhere((t) => t.id == widget.activeTheme.id);
    double initialOffset = 0.0;
    if (selectedIndex > 0) {
      // ~139.0 height per item (card ~127dp + 12dp separator)
      initialOffset = (selectedIndex * 139.0) - 10.0;
      if (initialOffset < 0) initialOffset = 0.0;
    }
    _scrollCtrl = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.paperBackground;
    final cardBg = AppTheme.cardWhite;
    final border = AppTheme.borderLight;
    final ink = AppTheme.inkForeground;
    final secondary = AppTheme.mutedText;
    final accent = AppTheme.primaryBlue;

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(Icons.palette_outlined, color: accent, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Backgrounds',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Dynamic themes with generated palette colors',
                      style: TextStyle(fontSize: 11, color: secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Catalogue List (Vertical scroll)
          Flexible(
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).viewInsets.bottom + 36,
              ),
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: kTimerThemes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final thm = kTimerThemes[index];
                final isSelected = thm.id == widget.activeTheme.id;

                return GestureDetector(
                  onTap: () {
                    widget.onSelectTheme(thm);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? accent : border,
                        width: isSelected ? 2.0 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? accent.withOpacity(0.16)
                              : const Color(0x060F172A),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Section: Preview visual + Title & badge
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Visual thumbnail preview / color card
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: thm.backgroundColor,
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: thm.thumbnailAssetPath != null
                                      ? Image.asset(
                                          thm.thumbnailAssetPath!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(
                                              Icons.movie_filter_outlined,
                                              color: thm.accentColor,
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.wb_sunny_rounded,
                                            color: thm.accentColor,
                                            size: 28,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Theme description & name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          thm.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected ? accent : ink,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (thm.hasVideo)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accent.withOpacity(0.09),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.videocam_rounded,
                                                  size: 10,
                                                  color: accent,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'LIVE',
                                                  style: TextStyle(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: accent,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      thm.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.3,
                                        color: secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection indicator
                              const SizedBox(width: 8),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: Color(0xFFCBD5E1),
                                  size: 22,
                                ),
                            ],
                          ),
                        ),

                        // Bottom Section: Generated Theme Palette Strip
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.parchmentSurface,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: border.withOpacity(0.7),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'THEMED PALETTE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                  color: secondary,
                                ),
                              ),
                              const Spacer(),
                              ...thm.paletteColors.map((col) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: col,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.12),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: col.withOpacity(0.35),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
