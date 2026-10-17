import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modulix/services/tour/app_tour_controller.dart';
import 'package:modulix/widgets/tour/tour_spotlight_overlay.dart';

void main() {
  group('App Tour Controller & Definitions', () {
    test('kTourSteps defines exactly 7 stops in exact sequence', () {
      expect(kTourSteps.length, 7);
      expect(kTourSteps[0].step, TourStep.studyDeskClock);
      expect(kTourSteps[1].step, TourStep.todaysTasks);
      expect(kTourSteps[2].step, TourStep.moduleTasks);
      expect(kTourSteps[3].step, TourStep.curriculum);
      expect(kTourSteps[4].step, TourStep.analytics);
      expect(kTourSteps[5].step, TourStep.customization);
      expect(kTourSteps[6].step, TourStep.focusTimer);
    });

    test('Strict zero emojis across all tour titles, descriptions and bullets', () {
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      );

      for (final step in kTourSteps) {
        expect(emojiRegex.hasMatch(step.title), isFalse,
            reason: 'Title contains emoji: ${step.title}');
        expect(emojiRegex.hasMatch(step.category), isFalse,
            reason: 'Category contains emoji: ${step.category}');
        expect(emojiRegex.hasMatch(step.description), isFalse,
            reason: 'Description contains emoji: ${step.description}');
        for (final bullet in step.bulletPoints) {
          expect(emojiRegex.hasMatch(bullet), isFalse,
              reason: 'Bullet contains emoji: $bullet');
        }
      }
    });

    test('Strict concise explanations: 3-4 lines overall, zero bullet points', () {
      for (final step in kTourSteps) {
        // Bullet points must be empty to avoid multi-line bloating
        expect(step.bulletPoints, isEmpty,
            reason: 'Step ${step.title} must not contain bullet points');

        // Description should not contain newlines or exceed concise length
        expect(step.description.contains('\n'), isFalse,
            reason: 'Step ${step.title} description must not contain newline breaks');
        expect(step.description.length, lessThanOrEqualTo(140),
            reason: 'Step ${step.title} description is too long for 2 lines');

        // Title must be concise (1 line)
        expect(step.title.length, lessThanOrEqualTo(35),
            reason: 'Step ${step.title} title exceeds single line length');
      }
    });

    test('Target configurations match user specifications (single & multi-targets without nested parent-child overlap)', () {
      // Step 1: Desk Clock
      expect(kTourSteps[0].targetIds, [TourTargetId.noriHeroCard]);

      // Step 2: Today's Tasks
      expect(kTourSteps[1].targetIds, [TourTargetId.todaysTasksTarget]);

      // Step 3: Module Tasks Screen Header
      expect(kTourSteps[2].targetIds, [TourTargetId.moduleTasksScreenHeader]);
      expect(kTourSteps[2].route, '/module-tasks');

      // Step 4: Curriculum first two subjects
      expect(kTourSteps[3].targetIds, [
        TourTargetId.curriculumSubject1,
        TourTargetId.curriculumSubject2,
      ]);
      expect(kTourSteps[3].route, '/curriculum');

      // Step 5: Analytics 3 performance hub cards
      expect(kTourSteps[4].targetIds, [
        TourTargetId.analyticsModuleHub,
        TourTargetId.analyticsFocusHub,
        TourTargetId.analyticsTasksHub,
      ]);
      expect(kTourSteps[4].route, '/analytics');

      // Step 6: Settings Profile Card + Theme Section
      expect(kTourSteps[5].targetIds, [
        TourTargetId.settingsProfileCard,
        TourTargetId.settingsThemeSection,
      ]);
      expect(kTourSteps[5].route, '/settings');

      // Step 7: Focus Timer Display + Bottom action dock
      expect(kTourSteps[6].targetIds, [
        TourTargetId.timerDisplay,
        TourTargetId.timerActionDock,
      ]);
      expect(kTourSteps[6].route, '/timer');
    });

    test('TourTargetRegistry pre-populates GlobalKeys for all 12 targets', () {
      expect(TourTargetId.values.length, 12);
      for (final id in TourTargetId.values) {
        final key = TourTargetRegistry.keyFor(id);
        expect(key, isNotNull);
        expect(TourTargetRegistry.getKey(id), equals(key));
      }
    });

    test('Steps 2, 4, 5, and 7 have preferTopCard set to avoid covering lower/mid targets', () {
      expect(kTourSteps[1].preferTopCard, isTrue);
      expect(kTourSteps[3].preferTopCard, isTrue);
      expect(kTourSteps[4].preferTopCard, isTrue);
      expect(kTourSteps[6].preferTopCard, isTrue);
    });
  });

  group('Strict Non-Overlapping Geometry Algorithm Tests', () {
    const cardHeight = 190.0;
    const cardWidth = 360.0;

    void assertNoOverlap({
      required Size screenSize,
      required List<Rect> targetRects,
      bool? preferTopCard,
    }) {
      final cardTop = TourSpotlightOverlay.calculateCardTop(
        screenSize: screenSize,
        targetRects: targetRects,
        preferTopCard: preferTopCard,
      );

      final cardRect = Rect.fromLTWH(18.0, cardTop, cardWidth, cardHeight);

      for (final target in targetRects) {
        final overlaps = cardRect.overlaps(target);
        expect(
          overlaps,
          isFalse,
          reason: 'Card rect $cardRect overlaps target rect $target on screen $screenSize',
        );
      }
    }

    test('Top target (e.g. Nori Desk Clock at y: 70..230) places card strictly below', () {
      final target = Rect.fromLTWH(20, 70, 360, 160);
      const screenSize = Size(400, 850);

      final cardTop = TourSpotlightOverlay.calculateCardTop(
        screenSize: screenSize,
        targetRects: [target],
        preferTopCard: false,
      );

      expect(cardTop, greaterThanOrEqualTo(target.bottom));
      assertNoOverlap(screenSize: screenSize, targetRects: [target], preferTopCard: false);
    });

    test('Mid-screen target (e.g. Today\'s Tasks at y: 380..520) places card strictly at top', () {
      final target = Rect.fromLTWH(20, 380, 360, 140);
      const screenSize = Size(400, 850);

      final cardTop = TourSpotlightOverlay.calculateCardTop(
        screenSize: screenSize,
        targetRects: [target],
        preferTopCard: true,
      );

      expect(cardTop, equals(56.0));
      expect(cardTop + cardHeight, lessThan(target.top));
      assertNoOverlap(screenSize: screenSize, targetRects: [target], preferTopCard: true);
    });

    test('Module Tasks Screen Header at y: 80..230 places card strictly below', () {
      final target = Rect.fromLTWH(20, 80, 360, 150);
      const screenSize = Size(400, 850);

      final cardTop = TourSpotlightOverlay.calculateCardTop(
        screenSize: screenSize,
        targetRects: [target],
        preferTopCard: false,
      );

      expect(cardTop, greaterThanOrEqualTo(target.bottom));
      assertNoOverlap(screenSize: screenSize, targetRects: [target], preferTopCard: false);
    });

    test('Curriculum first two subjects at y: 360..530 places card strictly at top', () {
      final targets = [
        Rect.fromLTWH(18, 360, 170, 170),
        Rect.fromLTWH(202, 360, 170, 170),
      ];
      const screenSize = Size(400, 850);

      final cardTop = TourSpotlightOverlay.calculateCardTop(
        screenSize: screenSize,
        targetRects: targets,
        preferTopCard: true,
      );

      expect(cardTop, equals(56.0));
      assertNoOverlap(screenSize: screenSize, targetRects: targets, preferTopCard: true);
    });

    test('Analytics 3 performance hub cards at y: 350..680 places card strictly at top', () {
      final targets = [
        Rect.fromLTWH(18, 350, 360, 100),
        Rect.fromLTWH(18, 464, 360, 100),
        Rect.fromLTWH(18, 578, 360, 100),
      ];
      const screenSize = Size(400, 850);

      final cardTop = TourSpotlightOverlay.calculateCardTop(
        screenSize: screenSize,
        targetRects: targets,
        preferTopCard: true,
      );

      expect(cardTop, equals(56.0));
      assertNoOverlap(screenSize: screenSize, targetRects: targets, preferTopCard: true);
    });

    test('Doctor Profile + Theme Section at y: 75..295 places card strictly below', () {
      final targets = [
        Rect.fromLTWH(18, 75, 360, 80),
        Rect.fromLTWH(18, 175, 360, 120),
      ];
      const screenSize = Size(400, 850);

      final cardTop = TourSpotlightOverlay.calculateCardTop(
        screenSize: screenSize,
        targetRects: targets,
        preferTopCard: false,
      );

      expect(cardTop, greaterThanOrEqualTo(295.0));
      assertNoOverlap(screenSize: screenSize, targetRects: targets, preferTopCard: false);
    });

    test('Focus Timer Display and Action Dock places card strictly at top', () {
      final targets = [
        Rect.fromLTWH(40, 380, 320, 80),
        Rect.fromLTWH(24, 720, 350, 50),
      ];
      const screenSize = Size(400, 850);

      final cardTop = TourSpotlightOverlay.calculateCardTop(
        screenSize: screenSize,
        targetRects: targets,
        preferTopCard: true,
      );

      expect(cardTop, equals(56.0));
      assertNoOverlap(screenSize: screenSize, targetRects: targets, preferTopCard: true);
    });

    test('Non-overlapping across multiple device screen resolutions', () {
      final screenSizes = [
        const Size(360, 640),   // Small Android
        const Size(390, 844),   // Standard iPhone / Pixel
        const Size(412, 915),   // Large Android
        const Size(1264, 2780), // Target physical device ba009d81
      ];

      final stepTargetGroups = [
        [Rect.fromLTWH(20, 75, 360, 150)], // Step 1: Nori Mascot
        [Rect.fromLTWH(16, 360, 360, 140)], // Step 2: Today's Tasks
        [Rect.fromLTWH(16, 80, 360, 150)], // Step 3: Module Tasks Banner
        [
          Rect.fromLTWH(18, 360, 170, 170),
          Rect.fromLTWH(202, 360, 170, 170),
        ], // Step 4: Curriculum first two subjects
        [
          Rect.fromLTWH(18, 350, 360, 100),
          Rect.fromLTWH(18, 464, 360, 100),
          Rect.fromLTWH(18, 578, 360, 100),
        ], // Step 5: Analytics 3 Hub cards
        [
          Rect.fromLTWH(18, 75, 360, 80),
          Rect.fromLTWH(18, 175, 360, 120),
        ], // Step 6: Settings Profile + Themes
        [
          Rect.fromLTWH(40, 380, 320, 80),
          Rect.fromLTWH(24, 720, 350, 50),
        ], // Step 7: Focus Timer Display & Dock
      ];

      for (final size in screenSizes) {
        for (int i = 0; i < stepTargetGroups.length; i++) {
          final targets = stepTargetGroups[i];
          final step = kTourSteps[i];

          final scaledTargets = targets.map((target) {
            return Rect.fromLTRB(
              target.left,
              target.top * (size.height / 850.0),
              target.right,
              target.bottom * (size.height / 850.0),
            );
          }).toList();

          assertNoOverlap(
            screenSize: size,
            targetRects: scaledTargets,
            preferTopCard: step.preferTopCard,
          );
        }
      }
    });
  });

  group('TourSpotlightOverlay Widget & Navigation Test', () {
    testWidgets('TourSpotlightOverlay remains hidden when tour is inactive',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Text('Underlying Content'),
                  TourSpotlightOverlay(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('STEP 1 OF 7'), findsNothing);
      expect(find.text('Underlying Content'), findsOneWidget);
    });

    testWidgets('Tour traverses all 7 steps with Next, Back and Skip controls',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TourSpotlightOverlay(),
                ],
              ),
            ),
          ),
        ),
      );

      // Initially inactive
      expect(find.text('STEP 1 OF 7'), findsNothing);

      // ── Step 1 ─────────────────────────────────────────────────────────────
      container.read(appTourProvider.notifier).state =
          const TourState(isActive: true, currentStepIndex: 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STEP 1 OF 7'), findsOneWidget);
      expect(find.text('Study Desk Clock'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip Tour'), findsOneWidget);

      // ── Step 2 ─────────────────────────────────────────────────────────────
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STEP 2 OF 7'), findsOneWidget);
      expect(find.text('Today\'s Tasks & Targets'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // ── Back Button Test ───────────────────────────────────────────────────
      await tester.tap(find.text('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('STEP 1 OF 7'), findsOneWidget);

      // ── Move to Step 2 ─────────────────────────────────────────────────────
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('STEP 2 OF 7'), findsOneWidget);

      // ── Step 3 ─────────────────────────────────────────────────────────────
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('STEP 3 OF 7'), findsOneWidget);
      expect(find.text('Automated Module Tracker'), findsOneWidget);

      // ── Step 4 ─────────────────────────────────────────────────────────────
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('STEP 4 OF 7'), findsOneWidget);
      expect(find.text('Curriculum & 19 MBBS Subjects'), findsOneWidget);

      // ── Step 5 ─────────────────────────────────────────────────────────────
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('STEP 5 OF 7'), findsOneWidget);
      expect(find.text('Analytics Performance Hubs'), findsOneWidget);

      // ── Step 6 ─────────────────────────────────────────────────────────────
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('STEP 6 OF 7'), findsOneWidget);
      expect(find.text('Doctor Profile & Theme Studio'), findsOneWidget);

      // ── Step 7 (Grand Finale) ──────────────────────────────────────────────
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('STEP 7 OF 7'), findsOneWidget);
      expect(find.text('Focus Timer Deep Work'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);

      // Finish Tour
      await tester.tap(find.text('Finish'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = container.read(appTourProvider);
      expect(state.isActive, isFalse);
    });

    testWidgets('Skip Tour immediately dismisses the overlay', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TourSpotlightOverlay(),
                ],
              ),
            ),
          ),
        ),
      );

      container.read(appTourProvider.notifier).state =
          const TourState(isActive: true, currentStepIndex: 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STEP 3 OF 7'), findsOneWidget);
      await tester.tap(find.text('Skip Tour'));
      await tester.pump();

      expect(container.read(appTourProvider).isActive, isFalse);
    });
  });
}
