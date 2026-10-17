import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/app.dart';
import 'package:modulix/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('ModulixApp boots into onboarding on fresh launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ModulixApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify first onboarding step is displayed
    expect(find.text('Welcome to Modulix'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
