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
      label: 'Curriculum',
    ),
    const LovableNavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Analytics',
    ),
    const LovableNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  testWidgets('LovableNavBar renders Floating Sketchy Island and handles taps',
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

    expect(find.byType(LovableNavBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Curriculum'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify presence of SketchNavIcon vector icons
    expect(find.byType(SketchNavIcon), findsAtLeastNWidgets(5));

    // Verify sliding Crayon/Colored-Pencil hatch indicator
    expect(find.byType(SketchHatchIndicator), findsOneWidget);

    // Tap Tab 1 (Curriculum)
    await tester.tap(find.text('Curriculum'));
    await tester.pump();
    expect(tappedIndex, equals(1));

    // Tap Center Focus Timer button via key or icon
    await tester.tap(find.byKey(const Key('nav_center_timer_button')));
    await tester.pump();
    expect(timerTapped, isTrue);

    // Re-tap current active tab (Tab 0: Home)
    await tester.tap(find.text('Home'));
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

    expect(find.byType(LovableNavBar), findsOneWidget);
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

    // Tap Tab 3 (Profile - right outermost tab)
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70)); // Mid-flight

    // Interrupt mid-flight by tapping Tab 1 (Curriculum)
    await tester.tap(find.text('Curriculum'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));

    // Tap Tab 0 (Home - left outermost tab)
    await tester.tap(find.text('Home'));
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
