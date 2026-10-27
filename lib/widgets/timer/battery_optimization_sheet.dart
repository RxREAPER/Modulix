import 'package:flutter/material.dart';
import '../../services/battery_optimization_service.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';

/// Modal bottom sheet guiding students to exempt Modulix from aggressive OEM
/// battery optimization daemons and Doze mode memory killers.
class BatteryOptimizationSheet extends StatefulWidget {
  const BatteryOptimizationSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 320),
        reverseDuration: Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      ),
      builder: (_) => const BatteryOptimizationSheet(),
    );
  }

  @override
  State<BatteryOptimizationSheet> createState() => _BatteryOptimizationSheetState();
}

class _BatteryOptimizationSheetState extends State<BatteryOptimizationSheet> {
  final BatteryOptimizationService _service = BatteryOptimizationService.instance;
  bool _isLoading = true;
  bool _isIgnoring = false;
  DeviceHardwareProfile? _profile;
  BrandReliabilityAdvice? _advice;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final isIgnoring = await _service.isIgnoringBatteryOptimizations();
    final profile = await _service.getHardwareProfile();
    final advice = await _service.getBrandAdvice();
    if (mounted) {
      setState(() {
        _isIgnoring = isIgnoring;
        _profile = profile;
        _advice = advice;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestExemption() async {
    final granted = await _service.requestIgnoreBatteryOptimizations();
    if (mounted) {
      setState(() => _isIgnoring = granted);
      if (granted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _openSettings() async {
    await _service.openBatteryOptimizationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.paperBackground;
    final cardBg = AppTheme.cardWhite;
    final border = AppTheme.borderLight;
    final ink = AppTheme.inkForeground;
    final secondary = AppTheme.mutedText;
    final accent = AppTheme.primaryBlue;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isLoading
            ? const SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isIgnoring ? Icons.verified_user_rounded : Icons.bolt_rounded,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Uninterrupted Focus Mode',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isIgnoring
                                    ? 'Modulix has unrestricted background permissions.'
                                    : 'Exempt Modulix from OS battery optimization to keep timers and audio running smoothly when the screen locks.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Pill Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isIgnoring
                            ? const Color(0xFF10B981).withValues(alpha: 0.08)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isIgnoring
                              ? const Color(0xFF10B981).withValues(alpha: 0.25)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isIgnoring ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 18,
                            color: _isIgnoring
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isIgnoring
                                  ? 'Status: Unrestricted (Doze Piercing Active)'
                                  : 'Status: Restricted by Battery Saver',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isIgnoring
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hardware & Brand Guide Card
                    if (_advice != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.settings_suggest_rounded, size: 18, color: ink),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _advice!.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: ink,
                                        ),
                                      ),
                                      if (_profile != null && _profile!.model != 'generic') ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_profile!.model} · Android ${_profile!.sdkVersion > 0 ? _profile!.sdkVersion : ""}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: secondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            for (int i = 0; i < _advice!.steps.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.only(top: 1, right: 10),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _advice!.steps[i],
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: ink.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_advice!.lockInRecentsTip != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 16,
                                      color: accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _advice!.lockInRecentsTip!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.35,
                                          color: ink.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action Buttons
                    if (!_isIgnoring) ...[
                      ApplePressable(
                        onTap: _requestExemption,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Allow Uninterrupted Study',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ApplePressable(
                        onTap: _openSettings,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Text(
                            'Open Device Battery Settings',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      ApplePressable(
                        onTap: () => Navigator.of(context).pop(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }
}
