import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import '../feedback/modulix_toast.dart';

/// Collapsible diagnostic drawer strictly concealing technical stack traces
/// and error codes from the user-facing body copy.
class DiagnosticTelemetryDrawer extends StatefulWidget {
  final String technicalDetails;

  const DiagnosticTelemetryDrawer({
    super.key,
    required this.technicalDetails,
  });

  @override
  State<DiagnosticTelemetryDrawer> createState() => _DiagnosticTelemetryDrawerState();
}

class _DiagnosticTelemetryDrawerState extends State<DiagnosticTelemetryDrawer> {
  bool _isExpanded = false;

  void _copyDiagnostics(BuildContext context) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.technicalDetails));
    ModulixToast.showSuccess(
      context,
      message: 'Diagnostic telemetry copied to clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.technicalDetails.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ApplePressable(
          pressedScale: 0.96,
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: AppTheme.mutedText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Diagnostic Telemetry (for Support)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedText,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppTheme.mutedText,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.parchmentSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TECHNICAL STACK REPORT',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ApplePressable(
                      pressedScale: 0.94,
                      onPressed: () => _copyDiagnostics(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: AppTheme.inkForeground,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy Diagnostics',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SelectableText(
                      widget.technicalDetails,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
