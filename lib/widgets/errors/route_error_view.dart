import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/error_translator_service.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import 'diagnostic_telemetry_drawer.dart';

/// 404 Destination Error Boundary for GoRouter navigation.
class RouteErrorView extends StatelessWidget {
  final Uri? uri;
  final Exception? error;

  const RouteErrorView({
    super.key,
    this.uri,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final translation = ErrorTranslatorService.translate(
      error ?? 'Destination route ${uri?.toString() ?? ""} not found',
      domain: 'route',
    );

    return Scaffold(
      backgroundColor: AppTheme.paperBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.paperBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.inkForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      translation.icon,
                      size: 36,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ApplePressable(
                      pressedScale: 0.96,
                      onPressed: () => context.go('/'),
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
                  const SizedBox(height: 18),
                  DiagnosticTelemetryDrawer(
                    technicalDetails: [
                      if (uri != null) 'Attempted Route: $uri',
                      translation.technicalDetails,
                    ].join('\n\n'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
