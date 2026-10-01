import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────

class ProfilePaletteOption {
  final String id;
  final String label;
  final Color color;
  const ProfilePaletteOption({
    required this.id,
    required this.label,
    required this.color,
  });
}

const List<ProfilePaletteOption> kProfilePalette = [
  ProfilePaletteOption(id: 'indigo', label: 'Indigo', color: Color(0xFF4F46E5)),
  ProfilePaletteOption(id: 'coral', label: 'Coral', color: Color(0xFFFE5F55)),
  ProfilePaletteOption(id: 'emerald', label: 'Emerald', color: Color(0xFF059669)),
  ProfilePaletteOption(id: 'amber', label: 'Amber', color: Color(0xFFD97706)),
  ProfilePaletteOption(id: 'violet', label: 'Violet', color: Color(0xFF7C3AED)),
  ProfilePaletteOption(id: 'rose', label: 'Rose', color: Color(0xFFF43F5E)),
  ProfilePaletteOption(id: 'sky', label: 'Sky', color: Color(0xFF0284C7)),
  ProfilePaletteOption(id: 'ink', label: 'Ink', color: Color(0xFF1C1C1C)),
];

Color profileAvatarColor(String id) {
  for (final p in kProfilePalette) {
    if (p.id == id) return p.color;
  }
  return AppTheme.primaryBlue;
}

// ─── Icons ───────────────────────────────────────────────────────────────────

class ProfileIconOption {
  final String id;
  final IconData icon;
  const ProfileIconOption({required this.id, required this.icon});
}

const List<ProfileIconOption> kProfileIcons = [
  ProfileIconOption(id: 'letter', icon: Icons.text_fields_rounded),
  ProfileIconOption(id: 'stethoscope', icon: Icons.medical_services_rounded),
  ProfileIconOption(id: 'psychology', icon: Icons.psychology_rounded),
  ProfileIconOption(id: 'book', icon: Icons.menu_book_rounded),
  ProfileIconOption(id: 'library', icon: Icons.local_library_rounded),
  ProfileIconOption(id: 'heart', icon: Icons.monitor_heart_rounded),
  ProfileIconOption(id: 'vaccines', icon: Icons.vaccines_rounded),
  ProfileIconOption(id: 'science', icon: Icons.science_rounded),
  ProfileIconOption(id: 'biotech', icon: Icons.biotech_rounded),
  ProfileIconOption(id: 'emergency', icon: Icons.emergency_rounded),
  ProfileIconOption(id: 'favorite', icon: Icons.favorite_rounded),
  ProfileIconOption(id: 'spark', icon: Icons.auto_awesome_rounded),
];

// ─── Shared helpers ──────────────────────────────────────────────────────────

String profileInitial(String doctorName) {
  final stripped =
      doctorName.replaceAll(RegExp(r'^(Dr\.?|Dr\s+)', caseSensitive: false), '').trim();
  final letter = stripped.isNotEmpty ? stripped[0].toUpperCase() : 'D';
  return letter;
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

/// Sketch-style avatar matching the Study Desk theme: ink border, hard
/// offset shadow, palette-tinted background with a bold initial or icon.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final String colorId;
  final String iconId;
  final String doctorName;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.size,
    required this.colorId,
    required this.iconId,
    required this.doctorName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = profileAvatarColor(colorId);
    final radius = size * 0.30;

    final content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent == AppTheme.inkForeground
            ? AppTheme.inkForeground
            : accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.sketchBorderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x181C1C1C),
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: iconId == 'letter'
            ? Text(
                profileInitial(doctorName),
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w900,
                  color: accent == AppTheme.inkForeground
                      ? Colors.white
                      : accent,
                ),
              )
            : Icon(
                _iconFor(iconId),
                size: size * 0.48,
                color: accent == AppTheme.inkForeground
                    ? Colors.white
                    : accent,
              ),
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }

  IconData _iconFor(String id) {
    for (final o in kProfileIcons) {
      if (o.id == id) return o.icon;
    }
    return Icons.medical_services_rounded;
  }
}

// ─── Customize Sheet ─────────────────────────────────────────────────────────

class ProfileCustomizeSheet extends ConsumerStatefulWidget {
  const ProfileCustomizeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (_) => const ProfileCustomizeSheet(),
    );
  }

  @override
  ConsumerState<ProfileCustomizeSheet> createState() =>
      _ProfileCustomizeSheetState();
}

class _ProfileCustomizeSheetState extends ConsumerState<ProfileCustomizeSheet> {
  late final TextEditingController _nameCtrl;
  bool _nameDirty = false;

  @override
  void initState() {
    super.initState();
    final current =
        ref.read(appStateProvider).valueOrNull?.doctorName ?? 'Dr';
    _nameCtrl = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider).valueOrNull;
    if (appState == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final notifier = ref.read(appStateProvider.notifier);
    final name = appState.doctorName.isNotEmpty ? appState.doctorName : 'Doctor';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          left: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
          right: BorderSide(color: AppTheme.sketchBorderColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.sketchBorderColor, width: 1.5),
                  ),
                  child: const Icon(Icons.palette_rounded,
                      color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFILE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        'Customize',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.inkForeground),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderLight),

          // Body
          Flexible(
            child: ListView(
              physics:
                  const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              shrinkWrap: true,
              children: [
                // ── Live preview ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        size: 64,
                        colorId: appState.avatarColorId,
                        iconId: appState.avatarIconId,
                        doctorName: name,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Live preview',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Display name ──────────────────────────────
                const SizedBox(height: 20),
                const Text(
                  'DISPLAY NAME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 14,
                    shadowOffset: 2.5,
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) => _nameDirty = true,
                    onSubmitted: (v) {
                      final text = v.trim();
                      if (text.isNotEmpty) notifier.setDoctorName(text);
                      _nameDirty = false;
                    },
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Dr. Arjun',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _nameDirty
                          ? IconButton(
                              onPressed: () {
                                final text = _nameCtrl.text.trim();
                                if (text.isNotEmpty) {
                                  notifier.setDoctorName(text);
                                }
                                setState(() => _nameDirty = false);
                              },
                              icon: const Icon(Icons.check_circle_rounded,
                                  size: 20, color: AppTheme.accentEmerald),
                              splashRadius: 18,
                            )
                          : const Icon(Icons.person_rounded,
                              size: 20, color: AppTheme.mutedText),
                    ),
                  ),
                ),

                // ── Avatar color ──────────────────────────────
                const SizedBox(height: 20),
                const Text(
                  'AVATAR COLOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: kProfilePalette.map((p) {
                      final selected = p.id == appState.avatarColorId;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setAvatarColor(p.id);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppTheme.sketchBorderColor
                                  : Colors.white,
                              width: selected ? 2.6 : 2,
                            ),
                            boxShadow: [
                              if (selected)
                                const BoxShadow(
                                  color: Color(0x281C1C1C),
                                  offset: Offset(0, 3),
                                  blurRadius: 6,
                                ),
                            ],
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Avatar icon ───────────────────────────────
                const SizedBox(height: 20),
                const Text(
                  'AVATAR ICON',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick a monogram or a study glyph',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: 18,
                    shadowOffset: 3,
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kProfileIcons.map((o) {
                      final selected = o.id == appState.avatarIconId;
                      final accent = profileAvatarColor(appState.avatarColorId);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setAvatarIcon(o.id);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected
                                ? accent.withValues(alpha: 0.14)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.sketchBorderColor
                                  : AppTheme.borderLight,
                              width: selected ? 2.2 : 1.4,
                            ),
                            boxShadow: selected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x181C1C1C),
                                      offset: Offset(2, 2),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                o.icon,
                                size: 24,
                                color: selected
                                    ? accent
                                    : AppTheme.mutedText,
                              ),
                              if (selected)
                                Positioned(
                                  right: 3,
                                  top: 3,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.inkForeground,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        size: 9, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Bottom close button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.inkForeground,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
