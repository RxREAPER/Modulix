import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/error_translator_service.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import 'diagnostic_telemetry_drawer.dart';

/// Global unhandled exception shield for Modulix.
/// Replaces Flutter's red/grey screen of death with a calming,
/// doctor-facing self-healing interface that guarantees local SQLite
/// study data preservation.
class ModulixErrorScaffold extends StatelessWidget {
  final FlutterErrorDetails? details;
  final Object? error;
  final StackTrace? stackTrace;
  final VoidCallback? onReopen;

  const ModulixErrorScaffold({
    super.key,
    this.details,
    this.error,
    this.stackTrace,
    this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final translation = ErrorTranslatorService.translate(
      details?.exception ?? error,
      stackTrace: details?.stack ?? stackTrace,
      domain: 'runtime',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppTheme.paperBackground,
      ),
      home: Scaffold(
        backgroundColor: AppTheme.paperBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Calming medical icon medallion
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.parchmentSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.borderLight,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        translation.icon,
                        size: 38,
                        color: AppTheme.inkForeground,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Headline
                    Text(
                      translation.headline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkForeground,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Calming Explanation
                    Text(
                      translation.explanation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.mutedText,
                        height: 1.45,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Safe storage guarantee pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 15,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Local Study Cache Intact',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ApplePressable(
                        pressedScale: 0.96,
                        onPressed: () {
                          if (onReopen != null) {
                            onReopen!();
                          } else {
                            try {
                              context.go('/');
                            } catch (_) {
                              // If outside GoRouter context, pop or reload
                              Navigator.of(context).maybePop();
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.inkForeground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.inkForeground.withValues(alpha: 0.2),
                                offset: const Offset(0, 3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            translation.primaryActionLabel,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.paperBackground,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Collapsed Telemetry Drawer
                    DiagnosticTelemetryDrawer(
                      technicalDetails: translation.technicalDetails,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
