import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Provider exposing the current Supabase Auth state stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.authStateChanges;
});

/// Provider returning the current logged-in User or null
final currentUserProvider = Provider<User?>((ref) {
  // Watch auth state changes so this provider updates reactively
  ref.watch(authStateProvider);
  return AuthService.instance.currentUser;
});

/// Provider returning true if the user is authenticated with Supabase
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
