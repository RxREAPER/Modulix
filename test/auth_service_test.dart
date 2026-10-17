import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:modulix/services/auth_service.dart';
import 'package:modulix/config/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Unit Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService.instance;
      authService.setTestClient(null);
      SupabaseConfig.overrideUrl = 'https://placeholder-project.supabase.co';
      SupabaseConfig.overrideAnonKey = 'placeholder-anon-key';
    });

    test('initial state when unconfigured', () {
      expect(authService.isReady, isFalse);
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUserId, isNull);
      expect(authService.currentUserEmail, isNull);
    });

    test('initialize returns false when SupabaseConfig is not configured', () async {
      final initialized = await authService.initialize();
      if (!SupabaseConfig.isConfigured) {
        expect(initialized, isFalse);
        expect(authService.isReady, isFalse);
      }
    });

    test('signInWithEmail throws AuthException when unconfigured', () async {
      expect(
        () => authService.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('signUpWithEmail throws AuthException when unconfigured', () async {
      expect(
        () => authService.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          doctorName: 'Dr. Test',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('signInWithOtp throws AuthException when unconfigured', () async {
      expect(
        () => authService.signInWithOtp(email: 'test@example.com'),
        throwsA(isA<AuthException>()),
      );
    });

    test('verifyOtp throws AuthException when unconfigured', () async {
      expect(
        () => authService.verifyOtp(email: 'test@example.com', token: '123456'),
        throwsA(isA<AuthException>()),
      );
    });

    test('resetPassword throws AuthException when unconfigured', () async {
      expect(
        () => authService.resetPassword('test@example.com'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut gracefully completes without throwing when unconfigured', () async {
      await expectLater(authService.signOut(), completes);
    });

    test('authStateChanges emits empty stream when unconfigured', () async {
      final events = await authService.authStateChanges.toList();
      expect(events, isEmpty);
    });
  });
}
