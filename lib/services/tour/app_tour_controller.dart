import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Target identifiers for spotlight cutouts across the app
enum TourTargetId {
  // Step 1: Hero clock desk
  studyDeskClockTarget,

  // Step 2: Today's tasks (primary card or setup button)
  todaysTasksTarget,

  // Step 3: Module tasks screen banner
  moduleTasksScreenHeader,

  // Step 4: Curriculum first two subjects
  curriculumSubject1,
  curriculumSubject2,

  // Step 5: Analytics 3 performance hub cards
  analyticsModuleHub,
  analyticsFocusHub,
  analyticsTasksHub,

  // Step 6: Settings Doctor Profile + Theme section
  settingsProfileCard,
  settingsThemeSection,

  // Step 7: Focus Timer Display + Bottom action dock
  timerDisplay,
  timerActionDock,
}

/// The 7 Core Tour Stops
enum TourStep {
  studyDeskClock, // 1. Study Desk Clock + live time & pace indicator
  todaysTasks,    // 2. Today's task & functionality
  moduleTasks,    // 3. Module based tasks & work functionality
  curriculum,     // 4. Curriculum page & subjects, editions, videos/qbanks
  analytics,      // 5. Analytics & explanation of functionalities
  customization,  // 6. Customization functionality (profile & themes)
  focusTimer,     // 7. Focus timer highlight & center FAB dock
}

/// Metadata for each guided tour step
class TourStepData {
  final TourStep step;
  final String title;
  final String category;
  final String description;
  final List<String> bulletPoints;
  final String route;
  final List<TourTargetId> targetIds;
  final String? interactiveActionLabel;
  final bool? preferTopCard;

  const TourStepData({
    required this.step,
    required this.title,
    required this.category,
    required this.description,
    required this.bulletPoints,
    required this.route,
    required this.targetIds,
    this.interactiveActionLabel,
    this.preferTopCard,
  });
}

/// Global step definitions matching user specifications: concise 3-4 lines overall, zero emojis
const List<TourStepData> kTourSteps = [
  // ── STEP 1: STUDY DESK CLOCK ─────────────────────────────────────────────
  TourStepData(
    step: TourStep.studyDeskClock,
    title: 'Study Desk Clock',
    category: 'HERO DESK',
    description:
        'Minimalist digital desk clock keeping you grounded in real-time study hours with zero distractions.',
    bulletPoints: [],
    route: '/',
    targetIds: [TourTargetId.studyDeskClockTarget],
    preferTopCard: false,
  ),

  // ── STEP 2: TODAY\'S TASKS ────────────────────────────────────────────────
  TourStepData(
    step: TourStep.todaysTasks,
    title: 'Today\'s Tasks & Targets',
    category: 'DAILY GOALS',
    description:
        'Set spontaneous daily goals with instant check-offs. Daily study progress rolls over at 5:00 AM.',
    bulletPoints: [],
    route: '/',
    targetIds: [TourTargetId.todaysTasksTarget],
    preferTopCard: true,
  ),

  // ── STEP 3: MODULE BASED TASKS ───────────────────────────────────────────
  TourStepData(
    step: TourStep.moduleTasks,
    title: 'Automated Module Tracker',
    category: 'CURRICULUM QUEUE',
    description:
        'Structured daily queue that organizes syllabus chapters into batches with automated pace progression.',
    bulletPoints: [],
    route: '/module-tasks',
    targetIds: [TourTargetId.moduleTasksScreenHeader],
    preferTopCard: false,
  ),

  // ── STEP 4: CURRICULUM & EDITIONS ────────────────────────────────────────
  TourStepData(
    step: TourStep.curriculum,
    title: 'Curriculum & 19 MBBS Subjects',
    category: '19 MBBS SUBJECTS',
    description:
        'Explore 19 subjects across Marrow editions with dedicated video modules, Q-Bank question banks, and notes.',
    bulletPoints: [],
    route: '/curriculum',
    targetIds: [TourTargetId.curriculumSubject1, TourTargetId.curriculumSubject2],
    preferTopCard: true,
  ),

  // ── STEP 5: ANALYTICS & PACE ENGINE ──────────────────────────────────────
  TourStepData(
    step: TourStep.analytics,
    title: 'Analytics Performance Hubs',
    category: 'PERFORMANCE METRICS',
    description:
        'Real-time study telemetry tracking module syllabus pace, deep-work focus hours, and daily completion rates.',
    bulletPoints: [],
    route: '/analytics',
    targetIds: [
      TourTargetId.analyticsModuleHub,
      TourTargetId.analyticsFocusHub,
      TourTargetId.analyticsTasksHub,
    ],
    preferTopCard: true,
  ),

  // ── STEP 6: CUSTOMIZATION & THEMES ───────────────────────────────────────
  TourStepData(
    step: TourStep.customization,
    title: 'Doctor Profile & Theme Studio',
    category: 'STUDY ENVIRONMENT',
    description:
        'Personalize your doctor avatar and switch across themes including Basic Light, Basic Dark, and custom palettes.',
    bulletPoints: [],
    route: '/settings',
    targetIds: [TourTargetId.settingsProfileCard, TourTargetId.settingsThemeSection],
    preferTopCard: false,
  ),

  // ── STEP 7: FOCUS TIMER (GRAND FINALE) ───────────────────────────────────
  TourStepData(
    step: TourStep.focusTimer,
    title: 'Focus Timer Deep Work',
    category: 'CORE STUDY ENGINE',
    description:
        'Immersive deep-work environment featuring live video wallpapers, ambient soundscapes, and session tracking.',
    bulletPoints: [],
    route: '/timer',
    targetIds: [TourTargetId.timerDisplay, TourTargetId.timerActionDock],
    preferTopCard: true,
  ),
];

/// Tour state container
class TourState {
  final bool isActive;
  final int currentStepIndex;
  final bool isActionRunning;

  const TourState({
    this.isActive = false,
    this.currentStepIndex = 0,
    this.isActionRunning = false,
  });

  TourStepData get currentStepData => kTourSteps[currentStepIndex];
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex == kTourSteps.length - 1;

  TourState copyWith({
    bool? isActive,
    int? currentStepIndex,
    bool? isActionRunning,
  }) {
    return TourState(
      isActive: isActive ?? this.isActive,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isActionRunning: isActionRunning ?? this.isActionRunning,
    );
  }
}

/// Global Target Key Registry to resolve widget bounds in screen space
class TourTargetRegistry {
  static final Map<TourTargetId, GlobalKey> _keys = {
    for (final id in TourTargetId.values) id: GlobalKey(),
  };

  static GlobalKey keyFor(TourTargetId id) => _keys[id]!;

  static void register(TourTargetId id, GlobalKey key) {
    _keys[id] = key;
  }

  static void unregister(TourTargetId id) {
    _keys[id] = GlobalKey();
  }

  static GlobalKey? getKey(TourTargetId id) => _keys[id];

  static Rect? getRect(TourTargetId id) {
    final key = _keys[id];
    if (key == null) return null;
    final context = key.currentContext;
    if (context == null) return null;
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return null;

    final translation = renderBox.getTransformTo(null).getTranslation();
    final size = renderBox.size;
    return Rect.fromLTWH(
      translation.x,
      translation.y,
      size.width,
      size.height,
    );
  }

  static List<Rect> getRects(List<TourTargetId> ids) {
    final List<Rect> rects = [];
    for (final id in ids) {
      final rect = getRect(id);
      if (rect != null) {
        rects.add(rect);
      }
    }
    return rects;
  }
}

/// Riverpod State Notifier for App Tour
class AppTourNotifier extends StateNotifier<TourState> {
  AppTourNotifier() : super(const TourState());

  void startTour(BuildContext context) {
    state = const TourState(isActive: true, currentStepIndex: 0);
    _applyStepNavigation(context, 0);
  }

  void nextStep(BuildContext context) {
    if (!state.isActive) return;
    if (state.isLastStep) {
      endTour(context);
      return;
    }
    final nextIndex = state.currentStepIndex + 1;
    state = state.copyWith(currentStepIndex: nextIndex);
    _applyStepNavigation(context, nextIndex);
  }

  void prevStep(BuildContext context) {
    if (!state.isActive || state.isFirstStep) return;
    final prevIndex = state.currentStepIndex - 1;
    state = state.copyWith(currentStepIndex: prevIndex);
    _applyStepNavigation(context, prevIndex);
  }

  void goToStep(BuildContext context, int stepIndex) {
    if (stepIndex < 0 || stepIndex >= kTourSteps.length) return;
    state = state.copyWith(isActive: true, currentStepIndex: stepIndex);
    _applyStepNavigation(context, stepIndex);
  }

  void endTour(BuildContext context) {
    state = const TourState(isActive: false, currentStepIndex: 0);
    // Return to home page comfortably
    try {
      context.go('/');
    } catch (_) {}
  }

  void runStepInteractiveAction(BuildContext context) {
    final stepData = state.currentStepData;
    if (stepData.step == TourStep.focusTimer) {
      // Step 7 is already active on /timer
    }
  }

  void _applyStepNavigation(BuildContext context, int index) {
    final step = kTourSteps[index];
    try {
      final location = GoRouterState.of(context).matchedLocation;
      if (step.route != location) {
        context.go(step.route);
      }
    } catch (_) {}

    // Smoothly scroll target into visible area ONLY if it is cut off or off-screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final id in step.targetIds) {
        final key = TourTargetRegistry.keyFor(id);
        final ctx = key.currentContext;
        final rect = TourTargetRegistry.getRect(id);
        if (ctx != null && ctx.mounted) {
          final mediaQuery = MediaQuery.maybeOf(ctx);
          final screenHeight = mediaQuery?.size.height ?? 2400.0;
          if (rect == null || rect.top < 60 || rect.bottom > screenHeight - 100) {
            final bool isLower = step.step == TourStep.todaysTasks ||
                step.step == TourStep.analytics ||
                step.step == TourStep.focusTimer;
            Scrollable.ensureVisible(
              ctx,
              alignment: isLower ? 0.85 : 0.15,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          break;
        }
      }
    });
  }
}

/// Global provider for App Tour state
final appTourProvider = StateNotifierProvider<AppTourNotifier, TourState>((ref) {
  return AppTourNotifier();
});
