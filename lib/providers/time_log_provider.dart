import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_log.dart';

const _kTimeLogsKey = 'flowmd_time_logs_v1';

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
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kTimeLogsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => TimeLog.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<void> logTime(TimeLog entry) async {
    final updated = [...state, entry];
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(List<TimeLog> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_kTimeLogsKey, raw);
    } catch (_) {}
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
