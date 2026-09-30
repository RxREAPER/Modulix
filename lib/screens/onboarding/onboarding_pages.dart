import 'package:flutter/material.dart';

// ─── Shared onboarding page layout ───────────────────────────────────────────

class _OnboardingBase extends StatefulWidget {
  final Widget illustration;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _OnboardingBase({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  State<_OnboardingBase> createState() => _OnboardingBaseState();
}

class _OnboardingBaseState extends State<_OnboardingBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0)));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: widget.illustration,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Text
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Daily goals ──────────────────────────────────────────────────────

class OnboardingPage1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _OnboardingBase(
      accentColor: const Color(0xFF6C3BAA),
      illustration: _AnimatedCalendarIcon(),
      title: 'Track Your Daily Goals',
      subtitle:
          'Set a daily video target and check off lectures as you study. Build momentum with streak tracking.',
    );
  }
}

class _AnimatedCalendarIcon extends StatefulWidget {
  @override
  State<_AnimatedCalendarIcon> createState() => _AnimatedCalendarIconState();
}

class _AnimatedCalendarIconState extends State<_AnimatedCalendarIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: const Icon(Icons.calendar_month_rounded,
          size: 100, color: Color(0xFF6C3BAA)),
    );
  }
}

// ─── Step 2: Curriculum ───────────────────────────────────────────────────────

class OnboardingPage2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _OnboardingBase(
      accentColor: const Color(0xFF10B981),
      illustration: _SubjectGridIllustration(),
      title: 'Marrow 8 & 6.5 Syllabus',
      subtitle:
          'Browse every subject, chapter, and lecture. Switch between editions anytime — your progress stays separate.',
    );
  }
}

class _SubjectGridIllustration extends StatelessWidget {
  final _colors = const [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFF8B5CF6),
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: _colors
          .map((c) => Container(
                decoration: BoxDecoration(
                  color: c.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.withOpacity(0.4)),
                ),
                child: Icon(Icons.book_rounded, color: c, size: 28),
              ))
          .toList(),
    );
  }
}

// ─── Step 3: Analytics ────────────────────────────────────────────────────────

class OnboardingPage3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _OnboardingBase(
      accentColor: const Color(0xFF06B6D4),
      illustration: _AnimatedChartIllustration(),
      title: 'Smart Analytics',
      subtitle:
          'Heatmap calendar, syllabus mastery arc, streak counter, and ETA countdown — see exactly where you stand.',
    );
  }
}

class _AnimatedChartIllustration extends StatefulWidget {
  @override
  State<_AnimatedChartIllustration> createState() =>
      _AnimatedChartIllustrationState();
}

class _AnimatedChartIllustrationState extends State<_AnimatedChartIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bars = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 1.0];
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(bars.length, (i) {
          final delay = i * 0.1;
          final t = (((_ctrl.value - delay) / (1 - delay)).clamp(0.0, 1.0));
          return Container(
            width: 18,
            height: 100 * bars[i] * t,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.7 + 0.3 * bars[i]),
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 4: Daily quests ─────────────────────────────────────────────────────

class OnboardingPage4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _OnboardingBase(
      accentColor: const Color(0xFFF59E0B),
      illustration: _QuestIllustration(),
      title: 'Daily Quests',
      subtitle:
          'Every day the app queues your next batch of videos. Tick them off and unlock bonus videos when you overshoot.',
    );
  }
}

class _QuestIllustration extends StatefulWidget {
  @override
  State<_QuestIllustration> createState() => _QuestIllustrationState();
}

class _QuestIllustrationState extends State<_QuestIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _check;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _check = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              ScaleTransition(
                scale: i == 0 ? _check : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFF59E0B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: i == 0
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 10,
                width: 100 - i * 20.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Step 5: Setup form ───────────────────────────────────────────────────────

class OnboardingPage5 extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedEdition;
  final ValueChanged<String> onEditionChanged;

  const OnboardingPage5({
    super.key,
    required this.nameController,
    required this.selectedEdition,
    required this.onEditionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Emoji + title
          Text('👋', style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            "Let's set you up",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Just a couple of things to personalise your experience.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 36),

          // Name field
          Text('Your name',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Dr. Arjun',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 28),

          // Edition picker
          Text('Study source',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _EditionCard(
            id: 'marrow_8',
            label: 'Marrow Edition 8',
            subtitle: 'Latest edition (2024)',
            icon: Icons.auto_stories_rounded,
            selected: selectedEdition == 'marrow_8',
            onTap: () => onEditionChanged('marrow_8'),
          ),
          const SizedBox(height: 10),
          _EditionCard(
            id: 'marrow_6_5',
            label: 'Marrow Edition 6.5',
            subtitle: 'Previous edition',
            icon: Icons.menu_book_rounded,
            selected: selectedEdition == 'marrow_6_5',
            onTap: () => onEditionChanged('marrow_6_5'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: cs.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can switch editions anytime from Settings.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditionCard extends StatelessWidget {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EditionCard({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(0.1) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withOpacity(0.15)
                    : cs.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected ? cs.primary : cs.onSurface.withOpacity(0.5),
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.primary : cs.onSurface,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.5),
                      )),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
