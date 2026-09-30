import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import 'nori_character.dart';
import 'nori_particles.dart';

class NoriPropOption {
  final String id;
  final String title;
  final String subtitle;
  final String icon;

  const NoriPropOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class NoriWardrobeSheet extends ConsumerStatefulWidget {
  const NoriWardrobeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (ctx) => const NoriWardrobeSheet(),
    );
  }

  @override
  ConsumerState<NoriWardrobeSheet> createState() => _NoriWardrobeSheetState();
}

class _NoriWardrobeSheetState extends ConsumerState<NoriWardrobeSheet> {
  final NoriParticleController _particleController = NoriParticleController();

  static const List<NoriPropOption> _props = [
    NoriPropOption(
      id: 'stethoscope',
      title: 'Doctor Stethoscope',
      subtitle: 'Resident doctor ready for rounds',
      icon: '🩺',
    ),
    NoriPropOption(
      id: 'glasses',
      title: 'Study Reading Specs',
      subtitle: 'Sharp focus for marathon reading',
      icon: '👓',
    ),
    NoriPropOption(
      id: 'coffee',
      title: 'Steaming Coffee Mug',
      subtitle: 'Fresh brew with rising steam vapor',
      icon: '☕',
    ),
    NoriPropOption(
      id: 'headphones',
      title: 'Studio Headphones',
      subtitle: 'Noise-canceling beats for deep focus',
      icon: '🎧',
    ),
    NoriPropOption(
      id: 'nightcap',
      title: 'Late-Night Cap',
      subtitle: 'Cozy sleep cap for late night prep',
      icon: '🌙',
    ),
    NoriPropOption(
      id: 'crown',
      title: 'Golden Laurel Crown',
      subtitle: 'Master medico daily target trophy',
      icon: '🥇',
    ),
    NoriPropOption(
      id: 'none',
      title: 'Classic Calico',
      subtitle: 'Pure cozy companion',
      icon: '🐱',
    ),
  ];

  String _getPetMilestone(int pets) {
    if (pets >= 100) return '🏆 Chief Medical Director';
    if (pets >= 50) return '🩺 Senior Registrar';
    if (pets >= 25) return '✨ Junior Resident';
    if (pets >= 10) return '🐾 Dedicated Intern';
    if (pets >= 1) return '💖 Curious Medic';
    return '👋 First Meeting';
  }

  @override
  Widget build(BuildContext context) {
    final appStateAsync = ref.watch(appStateProvider);
    final appState = appStateAsync.value;
    final currentProp = appState?.noriPropId ?? 'stethoscope';
    final totalPets = appState?.noriInteractions ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.sketchBorderColor, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    color: AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Nori's Wardrobe",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Text(
                        'Customize your study companion',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.inkForeground),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Main Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Live Preview Stage
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: AppTheme.sketchDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: 20,
                      shadowOffset: 4,
                    ),
                    child: Column(
                      children: [
                        // Nori Mascot Interactive Preview
                        Center(
                          child: NoriCharacter(
                            size: 130,
                            propId: currentProp,
                            particleController: _particleController,
                            onTap: () {
                              ref.read(appStateProvider.notifier).incrementNoriInteractions();
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Lifetime Pet Counter Milestone Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getPetMilestone(totalPets),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$totalPets pets',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap Nori to pet her anytime!',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'AVAILABLE COSTUMES & PROPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Prop Options List
                  ..._props.map((prop) {
                    final isEquipped = prop.id == currentProp;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(appStateProvider.notifier).setNoriProp(prop.id);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isEquipped
                                ? AppTheme.primaryBlue.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEquipped
                                  ? AppTheme.primaryBlue
                                  : AppTheme.sketchBorderColor,
                              width: isEquipped ? 2.0 : 1.2,
                            ),
                            boxShadow: isEquipped
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isEquipped
                                      ? AppTheme.primaryBlue.withOpacity(0.15)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  prop.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prop.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isEquipped
                                            ? AppTheme.primaryBlue
                                            : AppTheme.inkForeground,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      prop.subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isEquipped) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'EQUIPPED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Close Button
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
