import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/config/supabase_config.dart';
import 'package:modulix/screens/auth/auth_screen.dart';
import 'package:modulix/services/auth_service.dart';
import 'package:modulix/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    AuthService.instance.setTestClient(null);
    SupabaseConfig.resetOverrides();
  });

  Widget buildTestableAuthScreen() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AuthScreen(),
        ),
      ),
    );
  }

  group('AuthScreen Widget Tests', () {
    testWidgets('renders all essential elements in default Sign In mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableAuthScreen());
      await tester.pumpAndSettle();

      expect(find.text('Modulix Cloud Sync'), findsOneWidget);
      expect(find.text('Seamless study tracking across Android devices'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Magic Link'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In & Sync'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue as Guest (Local Only)'), findsOneWidget);
    });

    testWidgets('switches to Create Account mode and shows Doctor Name field',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableAuthScreen());
      await tester.pumpAndSettle();

      expect(find.text('Doctor Name'), findsNothing);

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Doctor Name'), findsOneWidget);
      expect(find.text('Create Account'), findsNWidgets(2)); // Tab + Button
    });

    testWidgets('switches to Magic Link mode and hides Password field',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableAuthScreen());
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);

      await tester.tap(find.text('Magic Link'));
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsNothing);
      expect(find.text('Send Magic Link'), findsOneWidget);
    });

    testWidgets('shows validation error banner when submitting with invalid/empty email',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In & Sync'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('shows validation error banner when submitting empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableAuthScreen());
      await tester.pumpAndSettle();

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextField, 'doctor@hospital.org'),
        'test@example.com',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In & Sync'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('tapping Continue as Guest dismisses sheet in navigator flow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => AuthScreen.show(context),
                  child: const Text('Open Auth'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Auth'));
      await tester.pumpAndSettle();

      expect(find.text('Modulix Cloud Sync'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue as Guest (Local Only)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue as Guest (Local Only)'));
      await tester.pumpAndSettle();

      expect(find.text('Modulix Cloud Sync'), findsNothing);
    });

    testWidgets('tapping Continue with Google displays clear setup message when unconfigured',
        (WidgetTester tester) async {
      SupabaseConfig.overrideGoogleWebClientId = '';
      await tester.pumpWidget(buildTestableAuthScreen());
      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Google Sign-In is not configured yet'),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
