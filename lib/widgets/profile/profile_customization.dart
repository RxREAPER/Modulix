import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

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

// ─── Avatars Catalogue ────────────────────────────────────────────────────────

const Map<String, String> _kLegacyAvatarAliases = {
  'comic_spiderman': 'avatar_webslinger',
  'funny_spiderman': 'avatar_mastermind',
  'spectacular_spiderman': 'avatar_arachnid',
  'batman_animated': 'avatar_dark_knight',
  'gojo_eye_aura': 'avatar_six_eyes',
  'gojo_cat': 'avatar_blindfold_cat',
  'itachi_moon': 'avatar_moon_perch',
  'itachi_cat': 'avatar_ninja_cat',
  'groot': 'avatar_little_sprout',
};

String resolveAvatarId(String id) => _kLegacyAvatarAliases[id] ?? id;

class ProfileAvatarItem {
  final String id;
  final String label;
  final String? assetPath;
  const ProfileAvatarItem({
    required this.id,
    required this.label,
    this.assetPath,
  });
}

const List<ProfileAvatarItem> kProfileAvatars = [
  ProfileAvatarItem(id: 'letter', label: 'Initial (Letter)'),
  ProfileAvatarItem(id: 'avatar_webslinger', label: 'Web Slinger', assetPath: 'assets/avatars/avatar_webslinger.png'),
  ProfileAvatarItem(id: 'avatar_dark_knight', label: 'Dark Knight', assetPath: 'assets/avatars/avatar_dark_knight.png'),
  ProfileAvatarItem(id: 'cute_plague_doctor', label: 'Plague Doctor', assetPath: 'assets/avatars/cute_plague_doctor.png'),
  ProfileAvatarItem(id: 'avatar_six_eyes', label: 'Six Eyes', assetPath: 'assets/avatars/avatar_six_eyes.png'),
  ProfileAvatarItem(id: 'avatar_blindfold_cat', label: 'Blindfold Cat', assetPath: 'assets/avatars/avatar_blindfold_cat.png'),
  ProfileAvatarItem(id: 'avatar_moon_perch', label: 'Moon Shinobi', assetPath: 'assets/avatars/avatar_moon_perch.png'),
  ProfileAvatarItem(id: 'avatar_ninja_cat', label: 'Ninja Cat', assetPath: 'assets/avatars/avatar_ninja_cat.png'),
  ProfileAvatarItem(id: 'september_glow', label: 'Cyber Girl', assetPath: 'assets/avatars/september_glow.png'),
  ProfileAvatarItem(id: 'avatar_little_sprout', label: 'Little Sprout', assetPath: 'assets/avatars/avatar_little_sprout.png'),
  ProfileAvatarItem(id: 'bw_cats', label: 'Yin Yang Cats', assetPath: 'assets/avatars/bw_cats.png'),
  ProfileAvatarItem(id: 'avatar_mastermind', label: 'Mastermind', assetPath: 'assets/avatars/avatar_mastermind.png'),
  ProfileAvatarItem(id: 'avatar_arachnid', label: 'Arachnid', assetPath: 'assets/avatars/avatar_arachnid.png'),
  ProfileAvatarItem(id: 'peeking_cat', label: 'Peeking Cat', assetPath: 'assets/avatars/peeking_cat.png'),
  ProfileAvatarItem(id: 'anime_black_cat', label: 'Shadow Cat', assetPath: 'assets/avatars/anime_black_cat.png'),
  ProfileAvatarItem(id: 'black_cat_cartoon', label: 'Cartoon Cat', assetPath: 'assets/avatars/black_cat_cartoon.png'),
  ProfileAvatarItem(id: 'acid', label: 'Neon Flow', assetPath: 'assets/avatars/acid.png'),
];

// ─── Shared helpers ──────────────────────────────────────────────────────────

String profileInitial(String doctorName) {
  final stripped =
      doctorName.replaceAll(RegExp(r'^(Dr\.?|Dr\s+)', caseSensitive: false), '').trim();
  final letter = stripped.isNotEmpty ? stripped[0].toUpperCase() : 'D';
  return letter;
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

/// Circular avatar matching the Study Desk theme: crisp ink border, hard
/// offset shadow, rendering illustrated Discord PFP character images or initial.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final String colorId;
  final String iconId;
  final String doctorName;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.size,
    this.colorId = 'indigo',
    required this.iconId,
    required this.doctorName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveId = resolveAvatarId(iconId);
    final avatarItem = kProfileAvatars.firstWhere(
      (a) => a.id == effectiveId,
      orElse: () => const ProfileAvatarItem(id: 'letter', label: 'Initial'),
    );

    Widget inner;
    if (avatarItem.assetPath != null) {
      inner = ClipOval(
        child: Image.asset(
          avatarItem.assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackInitial(),
        ),
      );
    } else {
      inner = _buildFallbackInitial();
    }

    final content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.sketchBorderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x181C1C1C),
            offset: Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: inner,
    );

    if (onTap == null) return content;
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.92,
      borderRadius: BorderRadius.circular(size / 2),
      child: content,
    );
  }

  Widget _buildFallbackInitial() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          profileInitial(doctorName),
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
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
      decoration: BoxDecoration(
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
                  child: Icon(Icons.palette_rounded,
                      color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
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
                  icon: Icon(Icons.close_rounded,
                      color: AppTheme.inkForeground),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.borderLight),

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
                    backgroundColor: AppTheme.cardWhite,
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
                              style: TextStyle(
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
                                color: AppTheme.mutedText,
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
                Text(
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
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 14,
                    shadowOffset: 2.5,
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) {
                      final isDirty = v.trim().isNotEmpty && v.trim() != name;
                      if (isDirty != _nameDirty) {
                        setState(() => _nameDirty = isDirty);
                      }
                    },
                    onSubmitted: (v) {
                      final text = v.trim();
                      if (text.isNotEmpty) notifier.setDoctorName(text);
                      setState(() => _nameDirty = false);
                    },
                    style: TextStyle(
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
                      fillColor: AppTheme.cardWhite,
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
                              icon: Icon(Icons.check_circle_rounded,
                                  size: 20, color: AppTheme.accentEmerald),
                              splashRadius: 18,
                            )
                          : Icon(Icons.person_rounded,
                              size: 20, color: AppTheme.mutedText),
                    ),
                  ),
                ),

                // ── Choose your avatar ───────────────────────
                const SizedBox(height: 20),
                Text(
                  'CHOOSE YOUR AVATAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.inkForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your companion avatar for your profile',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: AppTheme.sketchDecoration(
                    backgroundColor: AppTheme.cardWhite,
                    borderRadius: 20,
                    shadowOffset: 3,
                  ),
                  child: SizedBox(
                    height: 154,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: kProfileAvatars.length,
                      itemBuilder: (ctx, index) {
                        final item = kProfileAvatars[index];
                        final selected = item.id == resolveAvatarId(appState.avatarIconId);

                        Widget avatarImage;
                        if (item.assetPath != null) {
                          avatarImage = ClipOval(
                            child: Image.asset(
                              item.assetPath!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          // Monogram letter
                          avatarImage = Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                profileInitial(name),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            notifier.setAvatarIcon(item.id);
                          },
                          child: AnimatedScale(
                            scale: selected ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFF59E0B) // Amber ring matching screenshot
                                      : Colors.grey.shade300,
                                  width: selected ? 3.0 : 1.5,
                                ),
                                boxShadow: [
                                  if (selected)
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  avatarImage,
                                  // Centered checkmark badge when selected (matching screenshot)
                                  if (selected)
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 17,
                                        color: Color(0xFF1C1C1C),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
                onPressed: () {
                  final text = _nameCtrl.text.trim();
                  if (text.isNotEmpty && text != appState.doctorName) {
                    notifier.setDoctorName(text);
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.inkForeground,
                  foregroundColor: AppTheme.paperBackground,
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
