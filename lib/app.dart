import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'screens/settings/theme_studio_screen.dart';
import 'screens/timer/focus_timer_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/lovable_nav_bar.dart';
import 'widgets/timer/mini_timer_overlay.dart';
import 'widgets/tour/tour_spotlight_overlay.dart';

/// Provider for coordinating the iOS modal sheet background recess effect
final modalSheetRecessProvider = StateProvider<bool>((ref) => false);

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKeyHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorKeyCurriculum = GlobalKey<NavigatorState>(debugLabel: 'shellCurriculum');
final _shellNavigatorKeyAnalytics = GlobalKey<NavigatorState>(debugLabel: 'shellAnalytics');
final _shellNavigatorKeySettings = GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<AsyncValue<AppState>>(const AsyncLoading());
  ref.listen<AsyncValue<AppState>>(appStateProvider, (_, next) {
    listenable.value = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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
          if (data.onboardingDone &&
              state.matchedLocation == '/onboarding' &&
              state.uri.queryParameters['replay'] != 'true') {
            return '/';
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding',
        pageBuilder: (context, state) => _buildFadeTransitionPage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home Desk
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyHome,
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => _buildFadeTransitionPage(
                  state: state,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Curriculum & 19 MBBS Subjects
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyCurriculum,
            routes: [
              GoRoute(
                path: '/curriculum',
                pageBuilder: (context, state) => _buildFadeTransitionPage(
                  state: state,
                  child: const CurriculumScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':subjectId',
                    pageBuilder: (context, state) => CupertinoPage(
                      key: state.pageKey,
                      child: SubjectScreen(
                        subjectId: state.pathParameters['subjectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'analytics',
                        pageBuilder: (context, state) => CupertinoPage(
                          key: state.pageKey,
                          child: SubjectAnalyticsScreen(
                            subjectId: state.pathParameters['subjectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':chapterIndex',
                        pageBuilder: (context, state) => CupertinoPage(
                          key: state.pageKey,
                          child: ChapterScreen(
                            subjectId: state.pathParameters['subjectId'] ?? '',
                            chapterIndex: int.tryParse(
                                    state.pathParameters['chapterIndex'] ??
                                        '') ??
                                -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Analytics & Performance Hub
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyAnalytics,
            routes: [
              GoRoute(
                path: '/analytics',
                pageBuilder: (context, state) => _buildFadeTransitionPage(
                  state: state,
                  child: const AnalyticsScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Profile & Settings
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeySettings,
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _buildSlideUpTransitionPage(
                  state: state,
                  child: SettingsScreen(
                    from: state.uri.queryParameters['from'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/plan',
        pageBuilder: (context, state) => _buildFadeTransitionPage(
          state: state,
          child: const PlanScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/theme-studio',
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const ThemeStudioScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/module-tasks',
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const ModuleTasksScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
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
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
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
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      final fadeCurved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: fadeCurved,
          child: child,
        ),
      );
    },
  );
}

class ModulixApp extends ConsumerWidget {
  const ModulixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(appThemeDataProvider);
    final router = ref.watch(routerProvider);

    // Keep dynamic AppTheme bridge in lockstep with reactive riverpod theme extension
    AppTheme.current = themeData.extension;

    return MaterialApp.router(
      title: 'Modulix',
      debugShowCheckedModeBanner: false,
      theme: themeData.lightTheme,
      darkTheme: themeData.darkTheme,
      themeMode: themeData.themeMode,
      routerConfig: router,
    );
  }
}

/// Backward compatibility alias for FlowMDApp
typedef FlowMDApp = ModulixApp;

/// ModalSheetRecessWrapper scales down the main viewport ($0.94x$, $22px$ corners)
/// when modal bottom sheets are open, providing authentic iOS recess depth.
class ModalSheetRecessWrapper extends ConsumerWidget {
  final Widget child;

  const ModalSheetRecessWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecessed = ref.watch(modalSheetRecessProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      color: isRecessed ? Colors.black : Colors.transparent,
      child: AnimatedScale(
        scale: isRecessed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isRecessed ? 22.0 : 0.0),
          child: child,
        ),
      ),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabs = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      sketchType: SketchNavIconType.home,
      path: '/'
    ),
    (
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Curriculum',
      sketchType: SketchNavIconType.curriculum,
      path: '/curriculum'
    ),
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Analytics',
      sketchType: SketchNavIconType.analytics,
      path: '/analytics'
    ),
    (
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      sketchType: SketchNavIconType.profile,
      path: '/settings'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeDataProvider);
    final timerState = ref.watch(focusTimerProvider);
    final currentIndex = widget.navigationShell.currentIndex;
    final showMiniOverlay = timerState.sessionActive;

    return PopScope(
      canPop: currentIndex == 0 && !context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else if (currentIndex != 0) {
          widget.navigationShell.goBranch(0);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            extendBody: true,
            body: ModalSheetRecessWrapper(
              child: Stack(
                children: [
                  widget.navigationShell,
                  if (showMiniOverlay) const MiniTimerOverlay(),
                ],
              ),
            ),
            bottomNavigationBar: LovableNavBar(
              currentIndex: currentIndex,
              isSessionActive: timerState.sessionActive,
              onTap: (index) {
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == currentIndex,
                );
              },
              onReTap: (index) {
                // Re-tapping active tab returns to root of branch
                widget.navigationShell.goBranch(index, initialLocation: true);
              },
              onTimerTap: () {
                context.push('/timer');
              },
              items: _tabs
                  .map((tab) => LovableNavItem(
                        icon: tab.icon,
                        activeIcon: tab.activeIcon,
                        label: tab.label,
                        sketchType: tab.sketchType,
                      ))
                  .toList(),
            ),
          ),
          const TourSpotlightOverlay(),
        ],
      ),
    );
  }
}
