import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_log.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

final timeLogsProvider =
    StateNotifierProvider<TimeLogsNotifier, List<TimeLog>>((ref) {
  return TimeLogsNotifier(ref);
});

class TimeLogsNotifier extends StateNotifier<List<TimeLog>> {
  final Ref? _ref;

  TimeLogsNotifier([this._ref]) : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final logs = await DatabaseService.instance.getAllTimeLogs();
      state = logs;
    } catch (_) {}
  }

  Future<void> logTime(TimeLog entry) async {
    final updated = [...state, entry];
    state = updated;
    try {
      await DatabaseService.instance.insertTimeLog(entry);
      if (_ref != null) {
        SyncService.instance.schedulePush(_ref);
      }
    } catch (_) {}
  }

  Future<void> reloadFromDatabase() async {
    await _load();
  }

  Future<void> clearAll() async {
    state = [];
    await DatabaseService.instance.clearAllTimeLogs();

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('modulix_time_logs_cleared_at_v1', nowMs);
    await prefs.setInt('modulix_last_synced_at_v1', nowMs);

    final auth = AuthService.instance;
    if (auth.isAuthenticated && auth.client != null) {
      final client = auth.client!;
      final userId = auth.currentUserId;
      if (userId != null && userId.isNotEmpty) {
        // Enqueue durable outbox delete mutation to guarantee cloud deletion even if offline
        DatabaseService.instance.enqueueOutboxMutation(
          tableName: 'time_logs',
          operation: 'DELETE',
          payload: {
            'filter_column': 'user_id',
            'filter_value': userId,
          },
        );

        // Immediate direct remote wipe if online
        try {
          await client.from('time_logs').delete().eq('user_id', userId);
          await client.from('profiles').update({
            'total_study_secs': 0,
            'daily_study_secs': 0,
            'weekly_study_secs': 0,
            'monthly_study_secs': 0,
            'updated_at': now.toUtc().toIso8601String(),
          }).eq('id', userId);
        } catch (_) {}
      }
    }

    if (_ref != null) {
      SyncService.instance.schedulePush(_ref);
    }
  }

  List<TimeLog> forSubject(String subjectId) {
    return state.where((l) => l.subjectId == subjectId).toList();
  }

  int totalSecsForSubject(String subjectId) {
    int total = 0;
    for (final l in state) {
      if (l.subjectId == subjectId) total += l.durationSecs;
    }
    return total;
  }

  int totalSecsForType(String subjectId, String type) {
    int total = 0;
    for (final l in state) {
      if (l.subjectId == subjectId && l.topicType == type) total += l.durationSecs;
    }
    return total;
  }
}
