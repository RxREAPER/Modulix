import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';

class SyllabusEditionScreen extends ConsumerWidget {
  const SyllabusEditionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEdition =
        ref.watch(appStateProvider.select((s) => s.valueOrNull?.activeEdition)) ??
            'marrow_8';
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Syllabus Edition',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.inkForeground,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          // Clinical Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.parchmentSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight, width: 1.3),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.layers_outlined,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Isolation Guarantee',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your video completion marks, notes, and study desk tasks are preserved independently for each edition. You can switch between editions at any time without losing progress.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'AVAILABLE EDITIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppTheme.mutedText,
            ),
          ),

          const SizedBox(height: 12),

          // Edition 8 Card
          _EditionCard(
            editionId: 'marrow_8',
            title: 'Marrow Edition 8',
            editionTag: 'CURRENT STANDARD (2024–2026)',
            summary:
                '19 MBBS subjects, 848 comprehensive lectures, updated clinical case discussions, and integrated Next-Gen NEET-PG syllabus mapping.',
            subjectsCount: 19,
            videosCount: 848,
            isActive: activeEdition == 'marrow_8',
            badgeColor: AppTheme.primaryBlue,
            onSelect: () {
              if (activeEdition != 'marrow_8') {
                notifier.switchEdition('marrow_8');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switched active syllabus to Marrow Edition 8'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 16),

          // Edition 6.5 Card
          _EditionCard(
            editionId: 'marrow_6_5',
            title: 'Marrow Edition 6.5',
            editionTag: 'CLASSIC FOUNDATION',
            summary:
                '19 MBBS subjects, high-yield classic core video lectures, streamlined foundation topics, and rapid revision curriculum.',
            subjectsCount: 19,
            videosCount: 792,
            isActive: activeEdition == 'marrow_6_5',
            badgeColor: Colors.teal,
            onSelect: () {
              if (activeEdition != 'marrow_6_5') {
                notifier.switchEdition('marrow_6_5');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Switched active syllabus to Marrow Edition 6.5'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EditionCard extends StatelessWidget {
  final String editionId;
  final String title;
  final String editionTag;
  final String summary;
  final int subjectsCount;
  final int videosCount;
  final bool isActive;
  final Color badgeColor;
  final VoidCallback onSelect;

  const _EditionCard({
    required this.editionId,
    required this.title,
    required this.editionTag,
    required this.summary,
    required this.subjectsCount,
    required this.videosCount,
    required this.isActive,
    required this.badgeColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      pressedScale: 0.98,
      onPressed: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? badgeColor : AppTheme.borderLight,
            width: isActive ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? badgeColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isActive ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    editionTag,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: badgeColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Tap to activate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.inkForeground,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              summary,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatBadge(
                      icon: Icons.menu_book_rounded,
                      label: '$subjectsCount Subjects',
                    ),
                    const SizedBox(width: 8),
                    _StatBadge(
                      icon: Icons.play_circle_outline_rounded,
                      label: '$videosCount Videos',
                    ),
                  ],
                ),
                if (!isActive)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onSelect,
                    child: Text(
                      'Activate',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.parchmentSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.mutedText),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkForeground,
            ),
          ),
        ],
      ),
    );
  }
}
