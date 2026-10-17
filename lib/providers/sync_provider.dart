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
