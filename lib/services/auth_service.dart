import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'database_service.dart';
import 'storage_service.dart';

/// Service managing user authentication with Supabase and Google Sign-In.
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  SupabaseClient? _client;
  bool _initialized = false;

  /// Returns true if Supabase client is initialized and ready
  bool get isReady {
    if (_client != null) return true;
    return client != null;
  }

  SupabaseClient? get client {
    if (_client != null) return _client;
    try {
      _client = Supabase.instance.client;
      _initialized = true;
    } catch (_) {}
    return _client;
  }

  /// Explicitly set client for unit tests
  @visibleForTesting
  void setTestClient(SupabaseClient? testClient) {
    _client = testClient;
    _initialized = testClient != null;
  }

  /// Initializes Supabase if valid credentials are provided
  Future<bool> initialize() async {
    if (_initialized) return true;
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[AuthService] Supabase credentials not configured. Running in local/offline mode.');
      return false;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      debugPrint('[AuthService] Supabase initialized successfully.');
      return true;
    } catch (e) {
      debugPrint('[AuthService] Supabase initialization failed: $e');
      return false;
    }
  }

  User? get currentUser => client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get currentUserId => currentUser?.id;
  String? get currentUserEmail => currentUser?.email;

  Stream<AuthState> get authStateChanges {
    final c = client;
    if (c == null) return const Stream.empty();
    return c.auth.onAuthStateChange;
  }

  /// Sign up with Email and Password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? doctorName,
  }) async {
    final c = client;
    if (c == null) {
      throw const AuthException('Cloud sync is not configured. Please check connection settings.');
    }

    final data = <String, dynamic>{};
    if (doctorName != null && doctorName.trim().isNotEmpty) {
      data['full_name'] = doctorName.trim();
    }

    return await c.auth.signUp(
      email: email.trim(),
      password: password,
      data: data.isNotEmpty ? data : null,
    );
  }

  /// Sign in with Email and Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) {
      throw const AuthException('Cloud sync is not configured. Please check connection settings.');
    }

    return await c.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Send passwordless Magic Link (OTP) to email
  Future<void> signInWithOtp({required String email}) async {
    final c = client;
    if (c == null) {
      throw const AuthException('Cloud sync is not configured. Please check connection settings.');
    }

    await c.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: 'modulix://login-callback',
    );
  }

  /// Verify Email OTP token
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    final c = client;
    if (c == null) {
      throw const AuthException('Cloud sync is not configured. Please check connection settings.');
    }

    return await c.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.magiclink,
    );
  }

  /// Sign in using Google Sign-In on Android/iOS
  Future<AuthResponse> signInWithGoogle() async {
    final c = client;
    if (c == null) {
      throw const AuthException('Cloud sync is not configured. Please check connection settings.');
    }

    final webClientId = SupabaseConfig.googleWebClientId;
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google Sign-In canceled by user.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('Failed to retrieve ID Token from Google.');
    }

    return await c.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    final c = client;
    if (c == null) {
      throw const AuthException('Cloud sync is not configured.');
    }

    await c.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'modulix://reset-callback',
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    final c = client;
    if (c == null) return;

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    await c.auth.signOut();
  }

  /// Permanently purges all remote cloud data for the current user and signs out.
  /// Complies with Apple App Store Guideline 5.1.1(v) and GDPR Article 17 (Right to Erasure).
  Future<bool> purgeRemoteDataAndAccount() async {
    final c = client;
    final uid = currentUserId;
    if (c == null || uid == null) return false;

    try {
      // 1. Delete all user snapshots from private storage vault
      try {
        final files = await c.storage.from('user-vaults').list(path: uid);
        if (files.isNotEmpty) {
          final paths = files.map((f) => '$uid/${f.name}').toList();
          await c.storage.from('user-vaults').remove(paths);
        }
      } catch (e) {
        debugPrint('[AuthService] Error clearing user-vaults storage: $e');
      }

      // 2. Delete cloud rows across all public tables
      await c.from('time_logs').delete().eq('user_id', uid);
      await c.from('study_editions').delete().eq('user_id', uid);
      await c.from('daily_tasks').delete().eq('user_id', uid);
      await c.from('profiles').delete().eq('id', uid);

      // 3. Atomically purge local SQLite user tables and local AppState
      await DatabaseService.instance.resetAllDatabases();
      await StorageService.instance.clear();

      // 4. Complete sign out
      await signOut();
      return true;
    } catch (e) {
      debugPrint('[AuthService] Error purging remote data: $e');
      return false;
    }
  }
}
