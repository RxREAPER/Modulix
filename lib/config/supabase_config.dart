import 'package:flutter/foundation.dart';

/// Configuration management for Supabase connection & authentication.
/// Reads values from compile-time `--dart-define` flags or defaults.
class SupabaseConfig {
  static const String _defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vbvmzjhzznxgofyzxnql.supabase.co',
  );

  static const String _defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_JJvE8O5n_ilc9V35GIFgdg_xDHA1LX6',
  );

  static const String _defaultGoogleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '386076412890-q5nvesa7lpvssd5scmoob4m9du7ptpot.apps.googleusercontent.com',
  );

  /// Custom overrides for dynamic runtime or testing configuration
  static String? overrideUrl;
  static String? overrideAnonKey;
  static String? overrideGoogleWebClientId;

  static String get url => overrideUrl ?? _defaultUrl;
  static String get anonKey => overrideAnonKey ?? _defaultAnonKey;
  static String get googleWebClientId =>
      overrideGoogleWebClientId ?? _defaultGoogleWebClientId;

  /// Returns true if valid, non-placeholder credentials have been configured.
  static bool get isConfigured {
    final u = url.trim();
    final k = anonKey.trim();
    return u.isNotEmpty &&
        !u.contains('placeholder') &&
        k.isNotEmpty &&
        !k.contains('placeholder');
  }

  /// Reset overrides (useful in testing)
  @visibleForTesting
  static void resetOverrides() {
    overrideUrl = null;
    overrideAnonKey = null;
    overrideGoogleWebClientId = null;
  }
}
