import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_log.dart';
import '../services/database_service.dart';

final timeLogsProvider =
    StateNotifierProvider<TimeLogsNotifier, List<TimeLog>>((ref) {
  return TimeLogsNotifier();
});

class TimeLogsNotifier extends StateNotifier<List<TimeLog>> {
  TimeLogsNotifier() : super([]) {
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
    } catch (_) {}
  }

  Future<void> reloadFromDatabase() async {
    await _load();
  }

  Future<void> clearAll() async {
    state = [];
    await DatabaseService.instance.clearAllTimeLogs();
  }

  List<TimeLog> forSubject(String subjectId) {
    return state.where((l) => l.subjectId == subjectId).toList();
  }

  int totalSecsForSubject(String subjectId) {
    return state
        .where((l) => l.subjectId == subjectId)
        .fold<int>(0, (sum, l) => sum + l.durationSecs);
  }

  int totalSecsForType(String subjectId, String type) {
    return state
        .where((l) => l.subjectId == subjectId && l.topicType == type)
        .fold<int>(0, (sum, l) => sum + l.durationSecs);
  }
}
