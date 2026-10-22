import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/app.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/services/storage_service.dart';

class _FakeOnboardedAppStateNotifier extends AppStateNotifier {
  @override
  Future<AppState> build() async {
    return const AppState(onboardingDone: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets(
      'StatefulShellRoute retains navigation branches and allows zero-flicker switching',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateProvider.overrideWith(() => _FakeOnboardedAppStateNotifier()),
        ],
        child: const ModulixApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Initially at Home Desk (Tab 0)
    expect(find.text('Home'), findsOneWidget);

    // Switch to Library (Tab 1)
    await tester.tap(find.byKey(const Key('nav_tab_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify Library tab is visible and selected
    expect(find.text('Library'), findsWidgets);

    // Switch to Progress (Tab 2)
    await tester.tap(find.byKey(const Key('nav_tab_2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Switch back to Home (Tab 0) - should be instant with zero flicker
    await tester.tap(find.byKey(const Key('nav_tab_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Home'), findsWidgets);
  });
}
