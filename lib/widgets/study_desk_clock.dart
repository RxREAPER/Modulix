import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'nori_companion.dart';
import 'nori/nori_particles.dart';
import 'nori/nori_speech_bubble.dart';
import 'nori/nori_wardrobe_sheet.dart';

class StudyDeskClock extends StatefulWidget {
  const StudyDeskClock({super.key});

  @override
  State<StudyDeskClock> createState() => _StudyDeskClockState();
}

class _StudyDeskClockState extends State<StudyDeskClock> {
  final NoriParticleController _particleController = NoriParticleController();

  String _currentDialogue = "A quiet minute to begin.";
  String _dialogueBadge = "Focus";
  int _pearlIndex = 0;

  static const List<Map<String, String>> _studyPearls = [
    {
      'badge': 'High-Yield',
      'text': 'Penta of TTP: FAT RN (Fever, Anemia, Thrombo, Renal, Neuro).',
    },
    {
      'badge': 'Quick Tip',
      'text': 'Horner Syndrome: Ptosis, Miosis, Anhidrosis. Stay steady!',
    },
    {
      'badge': 'Anatomy',
      'text': 'Erb-Duchenne palsy affects C5-C6: Waiter\'s tip position.',
    },
    {
      'badge': 'Pharm',
      'text': 'Class 1A antiarrhythmics: Double Quarter Pounder (Disopyramide, Quinidine, Procainamide).',
    },
    {
      'badge': 'Focus',
      'text': 'Proud of your hard work, Doctor. Let\'s conquer today!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateDialogueForTime();
  }

  void _updateDialogueForTime() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 5) {
      _currentDialogue = "Night rotation? Stay hydrated & breathe deep.";
      _dialogueBadge = "Night Shift";
    } else if (hour >= 5 && hour < 12) {
      _currentDialogue = "Fresh morning focus. One module at a time!";
      _dialogueBadge = "Morning";
    } else if (hour >= 12 && hour < 17) {
      _currentDialogue = "Keep the momentum going strong, Doctor.";
      _dialogueBadge = "Afternoon";
    } else {
      _currentDialogue = "Evening study session. Review and solidify.";
      _dialogueBadge = "Evening";
    }
  }

  void _handlePearl() {
    HapticFeedback.lightImpact();
    setState(() {
      _pearlIndex = (_pearlIndex + 1) % _studyPearls.length;
      final pearl = _studyPearls[_pearlIndex];
      _currentDialogue = pearl['text']!;
      _dialogueBadge = pearl['badge']!;
    });
  }

  void _handlePet(VoidCallback onPet) {
    HapticFeedback.mediumImpact();
    _particleController.spawnBurst(60, 50, count: 5);
    onPet();
  }

  @override
  Widget build(BuildContext context) {
    final hasProvider = context.findAncestorWidgetOfExactType<ProviderScope>() != null;

    if (hasProvider) {
      return Consumer(
        builder: (context, ref, _) {
          final appState = ref.watch(appStateProvider).value;
          final propId = appState?.noriPropId ?? 'stethoscope';
          return _buildHeroCard(
            context,
            propId: propId,
            onPet: () {
              ref.read(appStateProvider.notifier).incrementNoriInteractions();
            },
          );
        },
      );
    }

    return _buildHeroCard(
      context,
      propId: 'stethoscope',
      onPet: () {},
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String propId,
    required VoidCallback onPet,
  }) {
    final hour = DateTime.now().hour;
    final NoriMood mood = (hour >= 0 && hour < 5) ? NoriMood.sleepy : NoriMood.awake;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8), // Clean warm parchment
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── TOP HEADER BAR: Pace Badge & Wardrobe Button ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pace Indicator Chip
              const _LivePaceBadge(),

              // Wardrobe Button
              InkWell(
                onTap: () => NoriWardrobeSheet.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2D9CE), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checkroom_rounded, size: 13, color: AppTheme.inkForeground),
                      SizedBox(width: 4),
                      Text(
                        'Wardrobe',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── MAIN DUAL-WING CONTENT ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // LEFT WING: Clock, Mantra, and Prominent CTA Button
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'STUDY DESK',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Big Bold Monospace Time with isolated second-ticker
                    const _LiveClockTimeText(),

                    const SizedBox(height: 6),
                    const Text(
                      'A quiet minute to begin · Stay steady',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // START FOCUS CTA Button
                    InkWell(
                      onTap: () {
                        try {
                          context.push('/timer');
                        } catch (_) {}
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.inkForeground,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              offset: Offset(0, 3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'START FOCUS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // RIGHT WING: Floating Pearl + Dedicated Nori Mochi Mascot Stage
              Expanded(
                flex: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Floating High-Yield Speech Bubble
                    NoriSpeechBubble(
                      text: _currentDialogue,
                      badge: _dialogueBadge,
                      onTap: _handlePearl,
                    ),

                    const SizedBox(height: 6),

                    // Mascot Stage with Sparkle Particle Overlay (Isolated in RepaintBoundary)
                    SizedBox(
                      width: 110,
                      height: 92,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          RepaintBoundary(
                            child: NoriCompanion(
                              size: 88,
                              propId: propId,
                              mood: mood,
                              onTap: () => _handlePet(onPet),
                              onDoubleTap: _handlePearl,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: NoriParticleOverlay(
                                controller: _particleController,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Isolated Clock Time widget that refreshes every second without dirtying the parent StudyDeskClock or HomeScreen
class _LiveClockTimeText extends StatefulWidget {
  const _LiveClockTimeText();

  @override
  State<_LiveClockTimeText> createState() => _LiveClockTimeTextState();
}

class _LiveClockTimeTextState extends State<_LiveClockTimeText> {
  late DateTime _time;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _time = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final now = DateTime.now();
        if (now.second != _time.second) {
          setState(() {
            _time = now;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm').format(_time);
    final amPmStr = DateFormat('a').format(_time);

    return RepaintBoundary(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: -1.2,
              height: 1.05,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            amPmStr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Isolated Pace Badge widget
class _LivePaceBadge extends StatefulWidget {
  const _LivePaceBadge();

  @override
  State<_LivePaceBadge> createState() => _LivePaceBadgeState();
}

class _LivePaceBadgeState extends State<_LivePaceBadge> {
  late int _hour;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _hour = DateTime.now().hour;
    // Check every minute if the hour changed
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        final h = DateTime.now().hour;
        if (h != _hour) {
          setState(() {
            _hour = h;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getPaceStatus(int hour) {
    if (hour >= 0 && hour < 5) return 'NIGHT ROTATION';
    if (hour >= 5 && hour < 12) return 'ON TRACK · MORNING';
    if (hour >= 12 && hour < 18) return 'STEADY FLOW · AFTERNOON';
    return 'POWER HOUR · EVENING';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getPaceStatus(_hour),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

