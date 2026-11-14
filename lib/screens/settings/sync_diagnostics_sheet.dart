import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/feedback/modulix_toast.dart';
import 'package:go_router/go_router.dart';

class SyncDiagnosticsSheet extends ConsumerStatefulWidget {
  const SyncDiagnosticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 220),
        reverseDuration: Duration(milliseconds: 180),
      ),
      builder: (_) => const SyncDiagnosticsSheet(),
    );
  }

  @override
  ConsumerState<SyncDiagnosticsSheet> createState() =>
      _SyncDiagnosticsSheetState();
}

class _SyncDiagnosticsSheetState extends ConsumerState<SyncDiagnosticsSheet> {
  int? _latencyMs;
  bool _probing = false;
  int _localLogsCount = 0;
  int _outboxPendingCount = 0;
  bool _isForceSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  Future<void> _loadTelemetry() async {
    setState(() => _probing = true);
    final latency = await SyncService.instance.probeLatency();
    final outboxCount =
        await DatabaseService.instance.getPendingOutboxCount();
    final allLogs = await DatabaseService.instance.getAllTimeLogs();

    if (mounted) {
      setState(() {
        _latencyMs = latency;
        _outboxPendingCount = outboxCount;
        _localLogsCount = allLogs.length;
        _probing = false;
      });
    }
  }

  Future<void> _runForceFullSync() async {
    HapticFeedback.mediumImpact();
    setState(() => _isForceSyncing = true);
    final success =
        await SyncService.instance.syncFull(ref, forceFull: true);
    await _loadTelemetry();
    if (mounted) {
      setState(() => _isForceSyncing = false);
      if (success) {
        ModulixToast.show(
          context,
          message: 'Full cloud parity verified successfully.',
          icon: Icons.check_circle_outline_rounded,
        );
      } else {
        ModulixToast.show(
          context,
          message: 'Full sync encountered network timeouts. Retrying in background.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;
    final user = ref.watch(currentUserProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final isRealtime = ref.watch(isRealtimeActiveProvider);
    final lastSyncedAt = ref.watch(lastSyncedAtProvider);

    final email = user?.email ?? 'guest@local';
    final provider = user?.appMetadata['provider']?.toString() ?? 'guest';
    final userId = user?.id ?? 'local_guest';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: activeTheme.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: activeTheme.borderSubtle, width: 1.2),
          left: BorderSide(color: activeTheme.borderSubtle, width: 1.2),
          right: BorderSide(color: activeTheme.borderSubtle, width: 1.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: activeTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: AppTheme.accentPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIAGNOSTICS & TELEMETRY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                      Text(
                        'Cloud Sync Diagnostics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: activeTheme.inkForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: activeTheme.mutedText,
                    size: 20,
                  ),
                  onPressed: _probing ? null : _loadTelemetry,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: activeTheme.borderSubtle),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Account Identity Box
                _SectionHeader(title: 'ACCOUNT & AUTHENTICATION', theme: activeTheme),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activeTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: activeTheme.borderSubtle, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.alternate_email_rounded,
                            size: 16,
                            color: activeTheme.mutedText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: activeTheme.inkForeground,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              provider.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppTheme.accentPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'User ID: ',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: activeTheme.mutedText,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              userId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                color: activeTheme.inkForeground,
                              ),
                            ),
                          ),
                          ApplePressable(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: userId));
                              HapticFeedback.selectionClick();
                              ModulixToast.show(
                                context,
                                message: 'User ID copied to clipboard.',
                                icon: Icons.content_copy_rounded,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: activeTheme.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Network & Realtime Health
                _SectionHeader(title: 'NETWORK & WEBSOCKET ENGINE', theme: activeTheme),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activeTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: activeTheme.borderSubtle, width: 1.0),
                  ),
                  child: Column(
                    children: [
                      _DiagnosticRow(
                        label: 'Roundtrip Cloud Latency',
                        value: _probing
                            ? 'Probing...'
                            : (_latencyMs != null ? '$_latencyMs ms' : 'Unreachable'),
                        valueColor: _latencyMs != null && _latencyMs! < 150
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                        theme: activeTheme,
                      ),
                      const SizedBox(height: 10),
                      _DiagnosticRow(
                        label: 'Supabase Realtime WebSocket',
                        value: isRealtime ? 'Active · Interlinked' : 'Idle / Polling',
                        valueColor: isRealtime
                            ? const Color(0xFF059669)
                            : activeTheme.mutedText,
                        theme: activeTheme,
                      ),
                      const SizedBox(height: 10),
                      _DiagnosticRow(
                        label: 'Sync Status Engine',
                        value: syncStatus.name.toUpperCase(),
                        valueColor: syncStatus == SyncStatus.synced
                            ? const Color(0xFF059669)
                            : (syncStatus == SyncStatus.syncing
                                ? AppTheme.accentPrimary
                                : (syncStatus == SyncStatus.pausedStandby
                                    ? const Color(0xFFF59E0B)
                                    : activeTheme.mutedText)),
                        theme: activeTheme,
                      ),
                      if (lastSyncedAt != null) ...[
                        const SizedBox(height: 10),
                        _DiagnosticRow(
                          label: 'Last Parity Timestamp',
                          value: _formatTimestamp(lastSyncedAt),
                          valueColor: activeTheme.inkForeground,
                          theme: activeTheme,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 3. SQLite Outbox & Storage Health
                _SectionHeader(title: 'LOCAL SQLITE & STORAGE ENGINE', theme: activeTheme),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activeTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: activeTheme.borderSubtle, width: 1.0),
                  ),
                  child: Column(
                    children: [
                      _DiagnosticRow(
                        label: 'Durable Outbox Queue',
                        value: _outboxPendingCount == 0
                            ? 'Clean (0 pending)'
                            : '$_outboxPendingCount mutations queued',
                        valueColor: _outboxPendingCount == 0
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                        theme: activeTheme,
                      ),
                      const SizedBox(height: 10),
                      _DiagnosticRow(
                        label: 'Local SQLite Study Logs',
                        value: '$_localLogsCount records stored',
                        valueColor: activeTheme.inkForeground,
                        theme: activeTheme,
                      ),
                      const SizedBox(height: 10),
                      _DiagnosticRow(
                        label: 'Database Schema Version',
                        value: 'SQLite v5 (Linear Standard)',
                        valueColor: activeTheme.mutedText,
                        theme: activeTheme,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 4. Action Buttons
                ApplePressable(
                  onTap: _isForceSyncing ? null : _runForceFullSync,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: _isForceSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sync_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Force Full Cloud Parity Sync',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ApplePressable(
                        onTap: () {
                          Clipboard.setData(const ClipboardData(
                              text: 'https://modulix.pages.dev/#/account'));
                          HapticFeedback.selectionClick();
                          ModulixToast.show(
                            context,
                            message: 'Web portal URL copied to clipboard.',
                            icon: Icons.link_rounded,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: activeTheme.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: activeTheme.borderSubtle, width: 1.0),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_browser_rounded,
                                  size: 15, color: activeTheme.inkForeground),
                              const SizedBox(width: 6),
                              Text(
                                'Web Portal Link',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: activeTheme.inkForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ApplePressable(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/settings/privacy');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: activeTheme.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: activeTheme.borderSubtle, width: 1.0),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_outlined,
                                  size: 15, color: activeTheme.inkForeground),
                              const SizedBox(width: 6),
                              Text(
                                'Vault & Backups',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: activeTheme.inkForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ModulixThemeExtension theme;
  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: theme.mutedText,
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final ModulixThemeExtension theme;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: theme.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
