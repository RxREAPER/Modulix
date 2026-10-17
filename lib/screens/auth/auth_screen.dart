import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';

enum AuthMode {
  signIn,
  signUp,
  magicLink,
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AuthScreen(),
    );
  }

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _mode = AuthMode.signIn;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  StreamSubscription<AuthState>? _authSub;
  bool _succeeded = false;
  bool _obscurePassword = true;
  bool _loading = false;
  bool _otpSent = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _authSub = AuthService.instance.authStateChanges.listen((state) {
      if (state.session != null && mounted) {
        _onAuthSuccess();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _loading = false;
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    try {
      if (_mode == AuthMode.magicLink) {
        if (!_otpSent) {
          await AuthService.instance.signInWithOtp(email: email);
          setState(() {
            _otpSent = true;
            _infoMessage = 'Magic link sent to $email. Tap the sign-in link in your email on this device to sign in automatically, or enter the code if provided.';
          });
        } else {
          final token = _otpController.text.trim();
          if (token.isEmpty) {
            setState(() {
              _errorMessage = 'Please enter the verification code.';
            });
            return;
          }
          await AuthService.instance.verifyOtp(email: email, token: token);
          if (mounted) _onAuthSuccess();
        }
      } else if (_mode == AuthMode.signIn) {
        if (password.isEmpty) {
          setState(() {
            _loading = false;
            _errorMessage = 'Please enter your password.';
          });
          return;
        }
        await AuthService.instance.signInWithEmail(email: email, password: password);
        if (mounted) _onAuthSuccess();
      } else if (_mode == AuthMode.signUp) {
        if (password.length < 6) {
          setState(() {
            _loading = false;
            _errorMessage = 'Password must be at least 6 characters.';
          });
          return;
        }
        final res = await AuthService.instance.signUpWithEmail(
          email: email,
          password: password,
          doctorName: name.isNotEmpty ? name : null,
        );

        if (res.session != null) {
          if (mounted) _onAuthSuccess();
        } else {
          setState(() {
            _infoMessage = 'Account created! Please check your email to confirm registration.';
          });
        }
      }
    } on AuthException catch (e) {
      String msg = e.message;
      final lower = e.message.toLowerCase();
      if (lower.contains('email not confirmed')) {
        msg = 'Email confirmation required. Please click the link sent to your email, or disable "Confirm email" in Supabase Auth.';
      } else if (lower.contains('invalid login credentials')) {
        msg = 'Invalid email or password. Please verify your credentials or select "Create Account".';
      }
      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitGoogle() async {
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    if (SupabaseConfig.googleWebClientId.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'Google Sign-In is not configured yet. Configure the Google Web Client ID in Supabase and Google Cloud Console.';
      });
      return;
    }

    try {
      await AuthService.instance.signInWithGoogle();
      if (mounted) _onAuthSuccess();
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      final errText = e.toString();
      if (errText.contains('10') || errText.toLowerCase().contains('developer_error')) {
        setState(() {
          _errorMessage =
              'Google Sign-In configuration mismatch (Error 10): Please add an Android OAuth client in Google Cloud Console with package name "com.modulix.app" and your SHA-1 fingerprint, and verify the test user is added.';
        });
      } else {
        setState(() {
          _errorMessage = 'Google Sign-In failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _onAuthSuccess() {
    if (_succeeded || !mounted) return;
    _succeeded = true;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signed in as ${AuthService.instance.currentUserEmail ?? "Doctor"}. Syncing progress...'),
        backgroundColor: AppTheme.accentPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    SyncService.instance.syncFull(ref);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.mutedText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.cloud_sync_rounded,
                    color: AppTheme.accentPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modulix Cloud Sync',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Seamless study tracking across Android devices',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.mutedText,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mode Selector Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  _buildTab(AuthMode.signIn, 'Sign In'),
                  _buildTab(AuthMode.signUp, 'Create Account'),
                  _buildTab(AuthMode.magicLink, 'Magic Link'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Error & Info Banners
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            if (_infoMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18, color: AppTheme.accentPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _infoMessage!,
                        style: TextStyle(fontSize: 12, color: AppTheme.accentPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Input Fields
            if (_mode == AuthMode.signUp) ...[
              _buildTextField(
                controller: _nameController,
                label: 'Doctor Name',
                hint: 'e.g. Dr. House',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
            ],

            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'doctor@hospital.org',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            if (_mode != AuthMode.magicLink) ...[
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppTheme.mutedText,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_otpSent) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 20, color: AppTheme.accentPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap the button in your email on this device to sign in instantly, or enter the code below if your email included one.',
                        style: TextStyle(fontSize: 12, color: AppTheme.inkForeground, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTextField(
                controller: _otpController,
                label: 'Verification Code (or tap email link)',
                hint: 'Enter 6-digit code',
                icon: Icons.pin_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),

            // Primary Action Button
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.inkForeground,
                foregroundColor: AppTheme.cardBackground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _mode == AuthMode.signIn
                          ? 'Sign In & Sync'
                          : _mode == AuthMode.signUp
                              ? 'Create Account'
                              : _otpSent
                                  ? 'Verify & Sign In'
                                  : 'Send Magic Link',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
            ),
            const SizedBox(height: 14),

            // Divider OR
            Row(
              children: [
                Expanded(child: Divider(color: AppTheme.cardBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.mutedText),
                  ),
                ),
                Expanded(child: Divider(color: AppTheme.cardBorder)),
              ],
            ),
            const SizedBox(height: 14),

            // Google Sign-In Button
            OutlinedButton.icon(
              onPressed: _loading ? null : _submitGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: AppTheme.cardBorder, width: 1.2),
              ),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
              label: Text(
                'Continue with Google',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.inkForeground,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Continue as Guest Option
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Continue as Guest (Local Only)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(AuthMode mode, String label) {
    final active = _mode == mode;
    return Expanded(
      child: ApplePressable(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _mode = mode;
            _errorMessage = null;
            _infoMessage = null;
          });
        },
        pressedScale: 0.95,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppTheme.inkForeground : AppTheme.mutedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkForeground,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.inkForeground,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: AppTheme.mutedText.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.mutedText),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppTheme.scaffoldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.inkForeground, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
