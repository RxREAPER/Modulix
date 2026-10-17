import 'package:flutter/material.dart';
import '../../services/error_translator_service.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import 'diagnostic_telemetry_drawer.dart';

/// Reusable doctor-facing error state view for screen-level and card-level
/// error states. Translates technical exceptions into reassuring clinical messages
/// and tucks stack traces inside a collapsed telemetry drawer.
class AppErrorStateView extends StatelessWidget {
  final dynamic error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final VoidCallback? onPrimaryAction;
  final String? retryLabel;
  final String? domain;
  final String? headline;
  final String? explanation;
  final bool compact;

  const AppErrorStateView({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.onPrimaryAction,
    this.retryLabel,
    this.domain,
    this.headline,
    this.explanation,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final translation = ErrorTranslatorService.translate(
      error,
      stackTrace: stackTrace,
      domain: domain,
    );

    final displayHeadline = headline ?? translation.headline;
    final displayExplanation = explanation ?? translation.explanation;

    final actionCallback = onPrimaryAction ?? onRetry;
    final actionText = retryLabel ?? translation.primaryActionLabel;

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.parchmentSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(translation.icon, size: 22, color: AppTheme.inkForeground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayHeadline,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayExplanation,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedText,
                height: 1.35,
              ),
            ),
            if (actionCallback != null) ...[
              const SizedBox(height: 12),
              ApplePressable(
                pressedScale: 0.95,
                onPressed: actionCallback,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.inkForeground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.paperBackground,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            DiagnosticTelemetryDrawer(
              technicalDetails: translation.technicalDetails,
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.parchmentSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.borderLight,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  translation.icon,
                  size: 34,
                  color: AppTheme.inkForeground,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                displayHeadline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkForeground,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                displayExplanation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mutedText,
                  height: 1.45,
                  letterSpacing: -0.1,
                ),
              ),
              if (actionCallback != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ApplePressable(
                    pressedScale: 0.96,
                    onPressed: actionCallback,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
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
                        actionText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.paperBackground,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              DiagnosticTelemetryDrawer(
                technicalDetails: translation.technicalDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
