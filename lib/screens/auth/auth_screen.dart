import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../services/error_translator_service.dart';
import '../../widgets/errors/diagnostic_telemetry_drawer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/feedback/modulix_toast.dart';

enum AuthMode {
  signIn,
  signUp,
  magicLink,
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  /// Navigates to the full-page Auth screen.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
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
  bool _acceptedTerms = true;

  dynamic _lastError;
  StackTrace? _lastStackTrace;
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
      _lastError = null;
      _lastStackTrace = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _loading = false;
        _lastError = 'Please enter a valid email address.';
      });
      return;
    }

    try {
      if (_mode == AuthMode.magicLink) {
        if (!_otpSent) {
          await AuthService.instance.signInWithOtp(email: email);
          setState(() {
            _otpSent = true;
            _infoMessage =
                'Magic link sent to $email. Tap the link in your email to sign in automatically, or enter the code below.';
          });
        } else {
          final token = _otpController.text.trim();
          if (token.isEmpty) {
            setState(() {
              _lastError = 'Please enter the 6-digit verification code.';
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
            _lastError = 'Please enter your password.';
          });
          return;
        }
        await AuthService.instance.signInWithEmail(email: email, password: password);
        if (mounted) _onAuthSuccess();
      } else if (_mode == AuthMode.signUp) {
        if (!_acceptedTerms) {
          setState(() {
            _loading = false;
            _lastError = 'Please agree to the Terms of Service to create an account.';
          });
          return;
        }
        if (password.length < 6) {
          setState(() {
            _loading = false;
            _lastError = 'Password must be at least 6 characters.';
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
    } catch (e, st) {
      setState(() {
        _lastError = e;
        _lastStackTrace = st;
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
      _lastError = null;
      _lastStackTrace = null;
      _infoMessage = null;
    });

    if (SupabaseConfig.googleWebClientId.isEmpty) {
      setState(() {
        _loading = false;
        _lastError = 'Google Sign-In is not configured yet. Configure the Google Web Client ID in Supabase.';
      });
      return;
    }

    try {
      await AuthService.instance.signInWithGoogle();
      if (mounted) _onAuthSuccess();
    } catch (e, st) {
      setState(() {
        _lastError = e;
        _lastStackTrace = st;
      });
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
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/settings');
    }
    ModulixToast.showSuccess(
      context,
      message: 'Signed in as ${AuthService.instance.currentUserEmail ?? "Doctor"}. Syncing study records...',
    );
    SyncService.instance.syncFull(ref);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.current.isDark;

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Artsy Curved Wave Header inspired by mockup
          SliverToBoxAdapter(
            child: _ArtsyWaveHeader(
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/settings');
                }
              },
            ),
          ),

          // Main Form Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Segmented Mode Switcher
                  _AuthModeSwitcher(
                    currentMode: _mode,
                    onModeChanged: (mode) {
                      setState(() {
                        _mode = mode;
                        _lastError = null;
                        _infoMessage = null;
                        _otpSent = false;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Error Banner with Translation & Telemetry
                  if (_lastError != null) ...[
                    _DoctorErrorBanner(
                      error: _lastError!,
                      stackTrace: _lastStackTrace,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info Message Banner
                  if (_infoMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _infoMessage!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.lightBlueAccent : Colors.blue.shade900,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Full Name Field (Sign Up Only)
                  if (_mode == AuthMode.signUp) ...[
                    _SketchInputField(
                      controller: _nameController,
                      label: 'Doctor Name',
                      hintText: 'e.g. Dr. Ayesha Khan',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Email Field
                  _SketchInputField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'doctor@hospital.org',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 14),

                  // Password Field (Sign In & Sign Up)
                  if (_mode != AuthMode.magicLink) ...[
                    _SketchInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      trailing: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppTheme.mutedText,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // OTP Field (Magic Link mode after OTP is sent)
                  if (_mode == AuthMode.magicLink && _otpSent) ...[
                    _SketchInputField(
                      controller: _otpController,
                      label: '6-Digit Verification Code',
                      hintText: '123456',
                      icon: Icons.key_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Terms & Conditions Checkbox (Sign Up Only)
                  if (_mode == AuthMode.signUp) ...[
                    InkWell(
                      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _acceptedTerms,
                                activeColor: AppTheme.inkForeground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (val) =>
                                    setState(() => _acceptedTerms = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'I accept the study companion terms & offline data privacy policy',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 8),

                  // Primary Submit Button
                  ApplePressable(
                    pressedScale: 0.98,
                    onPressed: _loading ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppTheme.inkForeground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.inkForeground.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _loading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.paperBackground),
                                ),
                              )
                            : Text(
                                _mode == AuthMode.signIn
                                    ? 'Sign In & Sync'
                                    : _mode == AuthMode.signUp
                                        ? 'Create Account'
                                        : _otpSent
                                            ? 'Verify & Sign In'
                                            : 'Send Magic Link',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.paperBackground,
                                  letterSpacing: -0.2,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: AppTheme.borderLight, height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Divider(color: AppTheme.borderLight, height: 1)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google Sign-In Button
                  ApplePressable(
                    pressedScale: 0.98,
                    onPressed: _loading ? null : _submitGoogle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleLogoBadge(),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Continue as Guest (Local Only) Button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/settings');
                        }
                      },
                      child: Text(
                        'Continue as Guest (Local Only)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom Mode Switch Prompt
                  Center(
                    child: _mode == AuthMode.signIn
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _mode = AuthMode.signUp;
                                    _lastError = null;
                                  });
                                },
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _mode = AuthMode.signIn;
                                    _lastError = null;
                                  });
                                },
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 10),

                  // Offline reassurance notice
                  Center(
                    child: Text(
                      'Modulix works 100% offline. Account sync is optional.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedText.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Artsy Curved Wave Header ──────────────────────────────────────────
class _ArtsyWaveHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _ArtsyWaveHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = AppTheme.current.isDark;

    return SizedBox(
      height: 230 + topPadding,
      child: Stack(
        children: [
          // Background organic wave painter
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePainter(
                waveColor: isDark ? const Color(0xFF1B2430) : const Color(0xFF1E293B),
                accentLineColor: AppTheme.primaryBlue.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Header Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 22),
                      onPressed: onBack,
                    ),
                  ),

                  const Spacer(),

                  // Modulix Logo & Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? const Color(0xFF1B2430)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modulix Cloud Sync',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Seamless study tracking across Android devices',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color waveColor;
  final Color accentLineColor;

  _WavePainter({
    required this.waveColor,
    required this.accentLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height - 40);

    // Organic wave curve matching design inspiration
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 10,
      size.width * 0.55,
      size.height - 35,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height - 60,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Sketch accent stroke line
    final strokePaint = Paint()
      ..color = accentLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final strokePath = Path();
    strokePath.moveTo(0, size.height - 40);
    strokePath.quadraticBezierTo(
      size.width * 0.25,
      size.height - 10,
      size.width * 0.55,
      size.height - 35,
    );
    strokePath.quadraticBezierTo(
      size.width * 0.85,
      size.height - 60,
      size.width,
      size.height - 20,
    );

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Segmented Mode Switcher ───────────────────────────────────────────
class _AuthModeSwitcher extends StatelessWidget {
  final AuthMode currentMode;
  final ValueChanged<AuthMode> onModeChanged;

  const _AuthModeSwitcher({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.parchmentSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
      ),
      child: Row(
        children: [
          _ModePill(
            label: 'Sign In',
            isSelected: currentMode == AuthMode.signIn,
            onTap: () => onModeChanged(AuthMode.signIn),
          ),
          _ModePill(
            label: 'Create Account',
            isSelected: currentMode == AuthMode.signUp,
            onTap: () => onModeChanged(AuthMode.signUp),
          ),
          _ModePill(
            label: 'Magic Link',
            isSelected: currentMode == AuthMode.magicLink,
            onTap: () => onModeChanged(AuthMode.magicLink),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ApplePressable(
        pressedScale: 0.95,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.inkForeground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? AppTheme.paperBackground
                    : AppTheme.mutedText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sketch Input Field ────────────────────────────────────────────────
class _SketchInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _SketchInputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.trailing,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.inkForeground,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkForeground,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppTheme.mutedText),
              suffixIcon: trailing,
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedText.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Google Logo Badge ────────────────────────────────────────────────
class _GoogleLogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
          fontFamily: 'sans-serif',
        ),
      ),
    );
  }
}

// ── Doctor Error Banner with Telemetry ───────────────────────────────
class _DoctorErrorBanner extends StatelessWidget {
  final dynamic error;
  final StackTrace? stackTrace;

  const _DoctorErrorBanner({
    required this.error,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    final translation = ErrorTranslatorService.translate(
      error,
      stackTrace: stackTrace,
      domain: 'auth',
    );

    final displayHeadline =
        error is String ? (error as String) : translation.headline;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.parchmentSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(translation.icon, size: 18, color: AppTheme.inkForeground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayHeadline,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkForeground,
                  ),
                ),
              ),
            ],
          ),
          if (error is! String) ...[
            const SizedBox(height: 6),
            Text(
              translation.explanation,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedText,
                height: 1.35,
              ),
            ),
          ],
          if (translation.technicalDetails.isNotEmpty) ...[
            const SizedBox(height: 10),
            DiagnosticTelemetryDrawer(
              technicalDetails: translation.technicalDetails,
            ),
          ],
        ],
      ),
    );
  }
}
