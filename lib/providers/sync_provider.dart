import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncService.instance.status) {
    SyncService.instance.statusNotifier.addListener(_onStatusChanged);
  }

  void _onStatusChanged() {
    state = SyncService.instance.status;
  }

  @override
  void dispose() {
    SyncService.instance.statusNotifier.removeListener(_onStatusChanged);
    super.dispose();
  }
}

final pendingSyncCountProvider =
    StateNotifierProvider<PendingSyncCountNotifier, int>((ref) {
  return PendingSyncCountNotifier();
});

class PendingSyncCountNotifier extends StateNotifier<int> {
  PendingSyncCountNotifier() : super(SyncService.instance.pendingSyncCount) {
    SyncService.instance.pendingSyncCountNotifier.addListener(_onCountChanged);
    SyncService.instance.refreshPendingCount();
  }

  void _onCountChanged() {
    state = SyncService.instance.pendingSyncCount;
  }

  @override
  void dispose() {
    SyncService.instance.pendingSyncCountNotifier.removeListener(_onCountChanged);
    super.dispose();
  }
}

final lastSyncedAtProvider =
    StateNotifierProvider<LastSyncedAtNotifier, DateTime?>((ref) {
  return LastSyncedAtNotifier();
});

class LastSyncedAtNotifier extends StateNotifier<DateTime?> {
  LastSyncedAtNotifier() : super(SyncService.instance.lastSyncedAtNotifier.value) {
    SyncService.instance.lastSyncedAtNotifier.addListener(_onChanged);
  }

  void _onChanged() {
    state = SyncService.instance.lastSyncedAtNotifier.value;
  }

  @override
  void dispose() {
    SyncService.instance.lastSyncedAtNotifier.removeListener(_onChanged);
    super.dispose();
  }
}

final isRealtimeActiveProvider =
    StateNotifierProvider<IsRealtimeActiveNotifier, bool>((ref) {
  return IsRealtimeActiveNotifier();
});

class IsRealtimeActiveNotifier extends StateNotifier<bool> {
  IsRealtimeActiveNotifier()
      : super(SyncService.instance.realtimeStatusNotifier.value) {
    SyncService.instance.realtimeStatusNotifier.addListener(_onChanged);
  }

  void _onChanged() {
    state = SyncService.instance.realtimeStatusNotifier.value;
  }

  @override
  void dispose() {
    SyncService.instance.realtimeStatusNotifier.removeListener(_onChanged);
    super.dispose();
  }
}

