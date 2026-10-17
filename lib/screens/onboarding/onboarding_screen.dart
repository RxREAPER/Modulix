import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import 'onboarding_pages.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Profile customization state
  final TextEditingController _nameController = TextEditingController();
  String _selectedAvatarId = 'letter';
  String _selectedColorId = 'indigo';
  String _selectedEdition = 'marrow_8';
  bool _saving = false;

  static const int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    final appState = ref.read(appStateProvider).value;
    if (appState != null) {
      if (appState.doctorName.isNotEmpty && appState.doctorName != 'Doctor') {
        _nameController.text = appState.doctorName;
      }
      _selectedAvatarId = appState.avatarIconId;
      _selectedColorId = appState.avatarColorId;
      _selectedEdition = appState.activeEdition;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skipToSetup() {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    final rawName = _nameController.text.trim();
    final doctorName = rawName.isEmpty ? 'Doctor' : rawName;

    await ref.read(appStateProvider.notifier).completeOnboarding(
          doctorName: doctorName,
          activeEdition: _selectedEdition,
          avatarColorId: _selectedColorId,
          avatarIconId: _selectedAvatarId,
        );

    try {
      await NotificationService.instance.requestPermissions();
    } catch (_) {}

    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand Monogram
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.inkForeground,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Modulix',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                  // Skip to setup button (visible on pages 0 to 4)
                  if (!isLastPage)
                    TextButton(
                      onPressed: _skipToSetup,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Skip to Setup',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 32),
                ],
              ),
            ),

            const Divider(color: Color(0xFFE2D9CE), thickness: 1, height: 1),

            // ── PAGE CAROUSEL VIEW
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  const OnboardingWelcomeSlide(),
                  const OnboardingTasksSlide(),
                  const OnboardingCurriculumSlide(),
                  const OnboardingTimerSlide(),
                  OnboardingProfileSetupSlide(
                    nameController: _nameController,
                    selectedAvatarId: _selectedAvatarId,
                    selectedColorId: _selectedColorId,
                    selectedEdition: _selectedEdition,
                    onAvatarChanged: (id) =>
                        setState(() => _selectedAvatarId = id),
                    onColorChanged: (id) =>
                        setState(() => _selectedColorId = id),
                    onEditionChanged: (ed) =>
                        setState(() => _selectedEdition = ed),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFFE2D9CE), thickness: 1, height: 1),

            // ── BOTTOM CONTROLS & DOTS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Step Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        height: 6,
                        width: active ? 22 : 6,
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.inkForeground
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 14),

                  // Navigation Action Buttons
                  if (isLastPage) ...[
                    // Full-width Start Using Modulix button
                    Container(
                      width: double.infinity,
                      decoration: AppTheme.sketchDecoration(
                        backgroundColor: AppTheme.inkForeground,
                        borderRadius: 16,
                        borderWidth: 1.5,
                        shadowOffset: 2.5,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _saving ? null : _finish,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Start Using Modulix',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded,
                                            size: 18, color: Colors.white),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Back button or Skip button
                        if (_currentPage > 0)
                          ApplePressable(
                            onTap: _prevPage,
                            pressedScale: 0.92,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: AppTheme.sketchDecoration(
                                backgroundColor: AppTheme.cardWhite,
                                borderRadius: 14,
                                borderWidth: 1.3,
                                shadowOffset: 1.8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Icon(Icons.arrow_back_rounded,
                                  size: 18, color: AppTheme.inkForeground),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: _skipToSetup,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),

                        // Right: Next pill button
                        ApplePressable(
                          onTap: _nextPage,
                          pressedScale: 0.94,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: AppTheme.sketchDecoration(
                              backgroundColor: AppTheme.inkForeground,
                              borderRadius: 14,
                              borderWidth: 1.4,
                              shadowOffset: 2.2,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 11),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Next',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
