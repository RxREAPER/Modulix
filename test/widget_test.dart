import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowmd_flutter/app.dart';
import 'package:flowmd_flutter/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('FlowMDApp boots into onboarding on fresh launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FlowMDApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify first onboarding step is displayed
    expect(find.text('Track Your Daily Goals'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
