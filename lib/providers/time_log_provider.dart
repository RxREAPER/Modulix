import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_log.dart';
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
