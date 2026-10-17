import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile/profile_customization.dart';
import 'widgets/onboarding_illustrations.dart';

// ─── Shared Base Onboarding Slide (Attenly-Inspired Modulix Layout) ────────────

class OnboardingSlide extends StatelessWidget {
  final String tag;
  final Widget? illustration;
  final String title;
  final String subtitle;
  final List<Widget>? customFooterElements;

  const OnboardingSlide({
    super.key,
    required this.tag,
    this.illustration,
    required this.title,
    required this.subtitle,
    this.customFooterElements,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 4),

                  // 1. FLOATING HERO VISUAL (Spacious, Unboxed)
                  if (illustration != null)
                    Center(child: illustration!)
                  else
                    // Reserved slot for future custom logo design
                    const SizedBox(height: 180),

                  const SizedBox(height: 16),

                  // 2. TEXT CONTENT & CONTEXT CAPSULES
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.inkForeground.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                AppTheme.inkForeground.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.inkForeground,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Large Bold Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.15,
                          color: AppTheme.inkForeground,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Single-Sentence Subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      // Contextual Elements (e.g. Slide 1 pills)
                      if (customFooterElements != null) ...[
                        const SizedBox(height: 18),
                        ...customFooterElements!,
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Slide 1: Welcome to Modulix ─────────────────────────────────────────────

class OnboardingWelcomeSlide extends StatelessWidget {
  const OnboardingWelcomeSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingSlide(
      tag: 'STUDY COMPANION',
      // Welcome card removed as requested; reserved for custom logo
      illustration: null,
      title: 'Welcome to Modulix',
      subtitle:
          'Your quiet space to plan daily tasks, track subjects, and focus.',
      customFooterElements: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFeaturePill(Icons.playlist_add_check_rounded, 'Daily Tasks',
                AppTheme.primaryBlue),
            _buildFeaturePill(Icons.library_books_rounded, '19 Subjects',
                const Color(0xFF059669)),
            _buildFeaturePill(
                Icons.timer_outlined, 'Focus Timer', const Color(0xFFD97706)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturePill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppTheme.sketchDecoration(
        backgroundColor: Colors.white,
        borderRadius: 12,
        borderWidth: 1.2,
        shadowOffset: 1.5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: AppTheme.inkForeground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.inkForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 2: Plan Daily Goals ──────────────────────────────────────────────

class OnboardingTasksSlide extends StatelessWidget {
  const OnboardingTasksSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingSlide(
      tag: 'STUDY DESK',
      illustration: DailyTasksIllustration(),
      title: 'Plan Daily Goals',
      subtitle:
          'Set your daily study targets and keep your syllabus pace on track.',
    );
  }
}

// ─── Slide 3: 19 Medical Subjects (Tracking Only) ───────────────────────────

class OnboardingCurriculumSlide extends StatelessWidget {
  const OnboardingCurriculumSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingSlide(
      tag: 'FULL SYLLABUS',
      illustration: CurriculumModulesIllustration(),
      title: '19 Medical Subjects',
      subtitle:
          'Track your video lectures, question banks, and revision notes across every subject.',
    );
  }
}

// ─── Slide 4: Focus Timer ───────────────────────────────────────────────────

class OnboardingTimerSlide extends StatelessWidget {
  const OnboardingTimerSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingSlide(
      tag: 'DEEP FOCUS',
      illustration: FocusTimerIllustration(),
      title: 'Focus Timer',
      subtitle:
          'Study in distraction-free blocks with clean timers and calming ambient sounds.',
    );
  }
}

// ─── Slide 5: Set Up Your Desk (Profile Customization) ──────────────────────

class OnboardingProfileSetupSlide extends StatefulWidget {
  final TextEditingController nameController;
  final String selectedAvatarId;
  final String selectedColorId;
  final String selectedEdition;
  final ValueChanged<String> onAvatarChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onEditionChanged;

  const OnboardingProfileSetupSlide({
    super.key,
    required this.nameController,
    required this.selectedAvatarId,
    required this.selectedColorId,
    required this.selectedEdition,
    required this.onAvatarChanged,
    required this.onColorChanged,
    required this.onEditionChanged,
  });

  @override
  State<OnboardingProfileSetupSlide> createState() =>
      _OnboardingProfileSetupSlideState();
}

class _OnboardingProfileSetupSlideState
    extends State<OnboardingProfileSetupSlide> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = widget.nameController.text.trim().isNotEmpty
        ? widget.nameController.text.trim()
        : 'Doctor';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Hero Avatar & Tag
          Center(
            child: Column(
              children: [
                ProfileAvatar(
                  size: 64,
                  colorId: widget.selectedColorId,
                  iconId: widget.selectedAvatarId,
                  doctorName: doctorName,
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.inkForeground.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'PROFILE SETUP',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Set Up Your Desk',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: AppTheme.inkForeground,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Choose your doctor name and your preferred study edition.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 18),

          // ── DOCTOR NAME INPUT CARD
          Text(
            'Doctor Name',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: AppTheme.sketchDecoration(
              backgroundColor: Colors.white,
              borderRadius: 14,
              borderWidth: 1.3,
              shadowOffset: 2.0,
            ),
            child: TextField(
              controller: widget.nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkForeground,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Dr. Arjun',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(Icons.person_outline_rounded,
                    size: 20, color: AppTheme.inkForeground),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── STUDY EDITION SELECTOR CARDS
          Text(
            'Preferred Study Edition',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildEditionCard(
                  id: 'marrow_8',
                  title: 'Marrow Edition 8',
                  sub: 'Latest 2024 Edition',
                  isSelected: widget.selectedEdition == 'marrow_8',
                  onTap: () => widget.onEditionChanged('marrow_8'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildEditionCard(
                  id: 'marrow_6_5',
                  title: 'Marrow Edition 6.5',
                  sub: 'Previous Revision',
                  isSelected: widget.selectedEdition == 'marrow_6_5',
                  onTap: () => widget.onEditionChanged('marrow_6_5'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── AVATAR SELECTOR ROW
          Text(
            'Avatar Style',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kProfileAvatars.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = kProfileAvatars[index];
                final isSelected = item.id == resolveAvatarId(widget.selectedAvatarId);

                return GestureDetector(
                  onTap: () => widget.onAvatarChanged(item.id),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.inkForeground
                            : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ProfileAvatar(
                      size: 44,
                      colorId: widget.selectedColorId,
                      iconId: item.id,
                      doctorName: doctorName,
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

  Widget _buildEditionCard({
    required String id,
    required String title,
    required String sub,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: AppTheme.sketchDecoration(
          backgroundColor: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: 14,
          borderWidth: isSelected ? 1.8 : 1.2,
          shadowOffset: isSelected ? 1.5 : 2.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: isSelected
                      ? AppTheme.inkForeground
                      : Colors.grey.shade400,
                ),
                Text(
                  isSelected ? 'Active' : 'Switch',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppTheme.inkForeground
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkForeground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
