import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/lovable_nav_bar.dart';

void main() {
  final testItems = [
    const LovableNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    const LovableNavItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Library',
    ),
    const LovableNavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Progress',
    ),
    const LovableNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  setUp(() {
    LovableNavBar.enableDebounce = false;
  });

  tearDown(() {
    LovableNavBar.enableDebounce = true;
  });

  testWidgets('LovableNavBar renders Modern Floating Dock and handles taps',
      (tester) async {
    int? tappedIndex;
    int? reTappedIndex;
    bool timerTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: LovableNavBar(
            currentIndex: 0,
            onTap: (i) => tappedIndex = i,
            onReTap: (i) => reTappedIndex = i,
            onTimerTap: () => timerTapped = true,
            items: testItems,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LovableNavBar), findsOneWidget);
    // Selected tab (Home) displays its text
    expect(find.text('Home'), findsOneWidget);

    // Verify presence of SketchNavIcon vector icons across all 5 slots
    expect(find.byType(SketchNavIcon), findsAtLeastNWidgets(5));

    // Verify sliding indicator
    expect(find.byType(SketchHatchIndicator), findsOneWidget);

    // Tap Tab 1 (Library) via key
    await tester.tap(find.byKey(const Key('nav_tab_1')));
    await tester.pump();
    expect(tappedIndex, equals(1));

    // Tap Center Focus Timer button via key
    await tester.tap(find.byKey(const Key('nav_center_timer_button')));
    await tester.pump();
    expect(timerTapped, isTrue);
    await tester.pump(const Duration(milliseconds: 100));

    // Re-tap current active tab (Tab 0: Home)
    await tester.tap(find.byKey(const Key('nav_tab_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(reTappedIndex, equals(0));
  });

  testWidgets('LovableNavBar handles isSessionActive breathing halo ring',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: LovableNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onTimerTap: () {},
            items: testItems,
            isSessionActive: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LovableNavBar), findsOneWidget);
  });

  testWidgets(
      'LovableNavBar supports rapid mid-flight tab switching and outer tabs',
      (tester) async {
    int activeIndex = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              extendBody: true,
              bottomNavigationBar: LovableNavBar(
                currentIndex: activeIndex,
                onTap: (i) => setState(() => activeIndex = i),
                onTimerTap: () {},
                items: testItems,
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Tap Tab 3 (Profile - right outermost tab) via key
    await tester.tap(find.byKey(const Key('nav_tab_3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70)); // Mid-flight

    // Interrupt mid-flight by tapping Tab 1 (Library) via key
    await tester.tap(find.byKey(const Key('nav_tab_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));

    // Tap Tab 0 (Home - left outermost tab) via key
    await tester.tap(find.byKey(const Key('nav_tab_0')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(activeIndex, equals(0));
    expect(find.byType(LovableNavBar), findsOneWidget);
  });

  testWidgets('SketchNavIcon renders all icon types with custom paths',
      (tester) async {
    for (final iconType in SketchNavIconType.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SketchNavIcon(
              type: iconType,
              color: Colors.black,
              isSelected: true,
            ),
          ),
        ),
      );
      expect(find.byType(SketchNavIcon), findsOneWidget);
    }
  });
}
