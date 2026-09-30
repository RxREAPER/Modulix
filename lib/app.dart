import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/app_state.dart';
import 'providers/app_state_provider.dart';
import 'providers/focus_timer_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/curriculum/curriculum_screen.dart';
import 'screens/curriculum/subject_screen.dart';
import 'screens/curriculum/chapter_screen.dart';
import 'screens/curriculum/module_tasks_screen.dart';
import 'screens/curriculum/subject_analytics_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/plan/plan_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/timer/focus_timer_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/lovable_nav_bar.dart';
import 'widgets/timer/mini_timer_overlay.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<AsyncValue<AppState>>(const AsyncLoading());
  ref.listen<AsyncValue<AppState>>(appStateProvider, (_, next) {
    listenable.value = next;
  });

  return GoRouter(
    refreshListenable: listenable,
    initialLocation: '/',
    redirect: (context, state) {
      final appState = ref.read(appStateProvider);
      return appState.when(
        loading: () => null,
        error: (_, __) => null,
        data: (data) {
          if (!data.onboardingDone && state.matchedLocation != '/onboarding') {
            return '/onboarding';
          }
          if (data.onboardingDone && state.matchedLocation == '/onboarding') {
            return '/';
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildFadeTransitionPage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _buildFadeTransitionPage(
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/curriculum',
            pageBuilder: (context, state) => _buildFadeTransitionPage(
              state: state,
              child: const CurriculumScreen(),
            ),
          ),
          GoRoute(
            path: '/curriculum/:subjectId',
            pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
              state: state,
              child: SubjectScreen(
                subjectId: state.pathParameters['subjectId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/curriculum/:subjectId/analytics',
            pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
              state: state,
              child: SubjectAnalyticsScreen(
                subjectId: state.pathParameters['subjectId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/curriculum/:subjectId/:chapterIndex',
            pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
              state: state,
              child: ChapterScreen(
                subjectId: state.pathParameters['subjectId']!,
                chapterIndex: int.parse(state.pathParameters['chapterIndex']!),
              ),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => _buildFadeTransitionPage(
              state: state,
              child: const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/plan',
            pageBuilder: (context, state) => _buildFadeTransitionPage(
              state: state,
              child: const PlanScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildSlideUpTransitionPage(
              state: state,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/module-tasks',
            pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
              state: state,
              child: const ModuleTasksScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/timer',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _buildSlideUpTransitionPage(
            state: state,
            child: FocusTimerScreen(
              initialSubjectId: extra?['subjectId'] as String?,
              initialSubjectName: extra?['subjectName'] as String?,
              initialTopicId: extra?['topicId'] as String?,
              initialTopicTitle: extra?['topicTitle'] as String?,
              initialChapterName: extra?['chapterName'] as String?,
              initialTopicType: extra?['topicType'] as String? ?? 'standalone',
              initialDurationMins: extra?['durationMins'] as int?,
            ),
          );
        },
      ),
    ],
  );
});

CustomTransitionPage<void> _buildFadeTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _buildSlideUpTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _buildSlideHorizontalTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  );
}

class FlowMDApp extends ConsumerWidget {
  const FlowMDApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FlowMD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabs = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      path: '/'
    ),
    (
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Curriculum',
      path: '/curriculum'
    ),
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Analytics',
      path: '/analytics'
    ),
    (
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      path: '/settings'
    ),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/timer') return 4;
    if (location.startsWith('/curriculum')) return 1;
    if (location.startsWith('/analytics')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Watching the global timer keeps it alive while navigating other tabs
    final timerState = ref.watch(focusTimerProvider);
    final currentIndex = _calculateSelectedIndex(context);
    final isOnTimerScreen = currentIndex == 4;
    final showMiniOverlay = timerState.sessionActive && !isOnTimerScreen;

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (currentIndex != 0) {
          context.go('/');
        }
      },
      child: Scaffold(
        extendBody: false,
        body: widget.child,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Aesthetic floating mini timer placed cleanly above the bottom nav bar
            if (showMiniOverlay) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: MiniTimerOverlay(),
              ),
            ],
            LovableNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                if (index != currentIndex) {
                  context.go(_tabs[index].path);
                }
              },
              onTimerTap: () {
                context.push('/timer');
              },
              items: _tabs
                  .map((tab) => LovableNavItem(
                        icon: tab.icon,
                        activeIcon: tab.activeIcon,
                        label: tab.label,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
