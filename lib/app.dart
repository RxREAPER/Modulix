import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/app_state_provider.dart';
import 'providers/daily_tasks_provider.dart';
import 'providers/focus_timer_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/curriculum/curriculum_screen.dart';
import 'screens/curriculum/subject_screen.dart';
import 'screens/curriculum/chapter_screen.dart';
import 'screens/curriculum/module_tasks_screen.dart';
import 'screens/curriculum/subject_analytics_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/analytics/study_plan_analytics_page.dart';
import 'screens/analytics/focus_timer_analytics_page.dart';
import 'screens/analytics/daily_tasks_analytics_page.dart';
import 'screens/analytics/subject_mastery_analytics_page.dart';
import 'screens/analytics/leaderboard_screen.dart';
import 'screens/plan/plan_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/planner/planner_screen.dart';
import 'screens/daily_tasks/daily_tasks_screen.dart';
import 'screens/settings/syllabus_edition_screen.dart';
import 'screens/settings/notifications_settings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/profile_edit_screen.dart';
import 'screens/settings/account_settings_screen.dart';
import 'screens/settings/theme_studio_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/settings/app_guide_screen.dart';
import 'screens/settings/data_privacy_screen.dart';
import 'screens/timer/focus_timer_screen.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';
import 'widgets/lovable_nav_bar.dart';
import 'widgets/timer/mini_timer_overlay.dart';
import 'widgets/errors/route_error_view.dart';

/// Provider for coordinating the iOS modal sheet background recess effect
final modalSheetRecessProvider = StateProvider<bool>((ref) => false);

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKeyHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorKeyCurriculum = GlobalKey<NavigatorState>(debugLabel: 'shellCurriculum');
final _shellNavigatorKeyAnalytics = GlobalKey<NavigatorState>(debugLabel: 'shellAnalytics');
final _shellNavigatorKeySettings = GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<bool?>(null);
  ref.listen<bool?>(
    appStateProvider.select((s) => s.valueOrNull?.onboardingDone),
    (_, next) {
      listenable.value = next;
    },
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: listenable,
    initialLocation: '/',
    errorBuilder: (context, state) => RouteErrorView(
      uri: state.uri,
      error: state.error,
    ),
    redirect: (context, state) {
      final appState = ref.read(appStateProvider).valueOrNull;
      if (appState == null) return null;
      if (!appState.onboardingDone && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      if (appState.onboardingDone &&
          state.matchedLocation == '/onboarding' &&
          state.uri.queryParameters['replay'] != 'true') {
        return '/';
      }
      return null;
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
            MainShell(
              navigationShell: navigationShell,
              currentPath: state.uri.path,
            ),
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
                routes: [
                  GoRoute(
                    path: 'planner',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const PlannerScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'daily-tasks',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const DailyTasksScreen(),
                    ),
                  ),
                ],
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
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: SubjectScreen(
                        subjectId: state.pathParameters['subjectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'analytics',
                        pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                          state: state,
                          child: SubjectAnalyticsScreen(
                            subjectId: state.pathParameters['subjectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':chapterIndex',
                        pageBuilder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>?;
                          final initialTab = state.uri.queryParameters['tab'] ?? extra?['tab'] as String?;
                          final targetItemId = state.uri.queryParameters['itemId'] ?? extra?['itemId'] as String?;
                          return _buildSlideHorizontalTransitionPage(
                            state: state,
                            child: ChapterScreen(
                              subjectId: state.pathParameters['subjectId'] ?? '',
                              chapterIndex: int.tryParse(
                                      state.pathParameters['chapterIndex'] ??
                                          '') ??
                                  -1,
                              initialTab: initialTab,
                              targetItemId: targetItemId,
                            ),
                          );
                        },
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
                routes: [
                  GoRoute(
                    path: 'plan-insights',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const StudyPlanAnalyticsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'focus-analytics',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const FocusTimerAnalyticsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'tasks-analytics',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const DailyTasksAnalyticsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'subject-mastery',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const SubjectMasteryAnalyticsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'leaderboard',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const LeaderboardScreen(),
                    ),
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const ProfileEditScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'account',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const AccountSettingsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'theme-studio',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const ThemeStudioScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'syllabus-edition',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const SyllabusEditionScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const NotificationsSettingsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'notifications-preferences',
                    redirect: (_, __) => '/settings/notifications',
                  ),
                  GoRoute(
                    path: 'guide',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const AppGuideScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'privacy',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const DataPrivacyScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'about',
                    pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
                      state: state,
                      child: const AboutScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'auth',
                    pageBuilder: (context, state) => _buildSlideUpTransitionPage(
                      state: state,
                      child: const AuthScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/theme-studio',
        redirect: (_, __) => '/settings/theme-studio',
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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/plan',
        pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
          state: state,
          child: const PlanScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/module-tasks',
        pageBuilder: (context, state) => _buildSlideHorizontalTransitionPage(
          state: state,
          child: const ModuleTasksScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        redirect: (_, __) => '/settings/auth',
      ),
      GoRoute(
        path: '/syllabus-edition',
        redirect: (_, __) => '/settings/syllabus-edition',
      ),
      GoRoute(
        path: '/notifications',
        redirect: (_, __) => '/settings/notifications',
      ),
      GoRoute(
        path: '/notifications-preferences',
        redirect: (_, __) => '/settings/notifications',
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
    child: RepaintBoundary(child: child),
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
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
    child: RepaintBoundary(child: child),
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final fadeCurved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
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

Page<void> _buildSlideHorizontalTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return MaterialPage<void>(
    key: state.pageKey,
    child: RepaintBoundary(child: child),
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

/// ModalSheetRecessWrapper passthrough (eliminated whole-app scale & ClipRRect for 120Hz performance)
class ModalSheetRecessWrapper extends StatelessWidget {
  final Widget child;

  const ModalSheetRecessWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final String currentPath;

  const MainShell({
    super.key,
    required this.navigationShell,
    this.currentPath = '/',
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial silent sync check on app mount when user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthService.instance.isAuthenticated) {
        SyncService.instance.syncFull(ref);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check 5:00 AM study day boundary rollover before triggering sync
      ref.read(dailyTasksProvider.notifier).checkDayRollover();

      // Trigger silent background sync when resuming to foreground
      if (AuthService.instance.isAuthenticated) {
        SyncService.instance.syncFull(ref);
      }
    }
  }

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
      label: 'Library',
      sketchType: SketchNavIconType.library,
      path: '/curriculum'
    ),
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Progress',
      sketchType: SketchNavIconType.progress,
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
    // Watch app theme data to trigger live re-renders across all shell tabs on preset switch
    final themeData = ref.watch(appThemeDataProvider);
    AppTheme.current = themeData.extension;

    final isSessionActive = ref.watch(
      focusTimerProvider.select((s) => s.sessionActive),
    );
    final currentIndex = widget.navigationShell.currentIndex;
    final showMiniOverlay = isSessionActive;

    final currentBranchNavKey = switch (currentIndex) {
      0 => _shellNavigatorKeyHome,
      1 => _shellNavigatorKeyCurriculum,
      2 => _shellNavigatorKeyAnalytics,
      3 => _shellNavigatorKeySettings,
      _ => null,
    };

    final canBranchPop = currentBranchNavKey?.currentState?.canPop() ?? false;
    final canRootPop = _rootNavigatorKey.currentState?.canPop() ?? false;

    // Determine whether the current view is a root main page or a subpage
    final normalizedPath = widget.currentPath.isEmpty
        ? '/'
        : widget.currentPath.split('?').first;
    const mainPaths = {'/', '/curriculum', '/analytics', '/settings'};
    final isMainPage = mainPaths.contains(normalizedPath);

    return PopScope(
      canPop: currentIndex == 0 && !canRootPop && !canBranchPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_rootNavigatorKey.currentState?.canPop() ?? false) {
          _rootNavigatorKey.currentState?.pop();
        } else if (currentBranchNavKey?.currentState?.canPop() ?? false) {
          currentBranchNavKey?.currentState?.pop();
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
            bottomNavigationBar: RepaintBoundary(
              child: LovableNavBar(
                currentIndex: currentIndex,
                isSessionActive: isSessionActive,
                isVisible: isMainPage,
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
          ),
        ],
      ),
    );
  }
}
