import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_desk_task.dart';
import 'app_state_provider.dart';
import '../services/notification_service.dart';
import '../services/metrics_service.dart';
import '../services/sync_service.dart';

const _kDailyTasksKey = 'modulix_daily_tasks_v1';
const _kLegacyDailyTasksV2Key = 'flowmd_daily_tasks_v2';
const _kLegacyDailyTasksKey = 'flowmd_daily_tasks_v1';
const _kCompletedTasksKey = 'modulix_completed_tasks_v1';
const _kLegacyCompletedTasksKey = 'flowmd_completed_tasks_v1';
const _kTasksHistoryKey = 'modulix_tasks_history_v1';
const _kLegacyTasksHistoryKey = 'flowmd_tasks_history_v1';
const _kLastActiveDateKey = 'modulix_tasks_last_date_v1';
const _kLegacyLastActiveDateKey = 'flowmd_tasks_last_date_v1';

class DailyTasksState {
  final List<DailyDeskTask> tasks;
  final Set<String> completedIds;
  final Map<String, int> dateHistory; // 'YYYY-MM-DD' -> count of completed tasks

  const DailyTasksState({
    this.tasks = const [],
    this.completedIds = const {},
    this.dateHistory = const {},
  });

  DailyTasksState copyWith({
    List<DailyDeskTask>? tasks,
    Set<String>? completedIds,
    Map<String, int>? dateHistory,
  }) {
    return DailyTasksState(
      tasks: tasks ?? this.tasks,
      completedIds: completedIds ?? this.completedIds,
      dateHistory: dateHistory ?? this.dateHistory,
    );
  }
}

final dailyTasksProvider =
    StateNotifierProvider<DailyTasksNotifier, DailyTasksState>((ref) {
  return DailyTasksNotifier(ref);
});

class DailyTasksNotifier extends StateNotifier<DailyTasksState> {
  final Ref? _ref;
  SharedPreferences? _cachedPrefs;
  Future<void>? _loadFuture;

  DailyTasksNotifier([this._ref]) : super(const DailyTasksState()) {
    _loadFuture = _load();
  }

  int get dayStartHour {
    if (_ref != null) {
      final appState = _ref.read(appStateProvider).valueOrNull;
      if (appState != null) return appState.dayStartHour;
    }
    return 5;
  }

  /// Reloads tasks and state from persistent storage
  Future<void> reload() async {
    _loadFuture = _load();
    await _loadFuture;
  }

  Future<void> _load() async {
    try {
      final prefs = _cachedPrefs ?? await SharedPreferences.getInstance();
      _cachedPrefs = prefs;
      final tasksJson = prefs.getString(_kDailyTasksKey) ?? prefs.getString(_kLegacyDailyTasksV2Key);
      final legacyTasksJson = prefs.getString(_kLegacyDailyTasksKey);
      String? completedJson;
      try {
        completedJson = prefs.getString(_kCompletedTasksKey) ?? prefs.getString(_kLegacyCompletedTasksKey);
      } catch (_) {
        final list = prefs.getStringList(_kCompletedTasksKey) ?? prefs.getStringList(_kLegacyCompletedTasksKey);
        if (list != null) completedJson = jsonEncode(list);
      }
      if (completedJson == null) {
        try {
          final list = prefs.getStringList(_kCompletedTasksKey) ?? prefs.getStringList(_kLegacyCompletedTasksKey);
          if (list != null) completedJson = jsonEncode(list);
        } catch (_) {}
      }
      final historyJson = prefs.getString(_kTasksHistoryKey) ?? prefs.getString(_kLegacyTasksHistoryKey);
      final lastDate = prefs.getString(_kLastActiveDateKey) ?? prefs.getString(_kLegacyLastActiveDateKey);
      final today = _todayKey();

      List<DailyDeskTask> loadedTasks = [];
      if (tasksJson != null) {
        try {
          final decoded = jsonDecode(tasksJson) as List;
          loadedTasks = decoded
              .map((e) => DailyDeskTask.fromMap(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          loadedTasks = [];
        }
      } else if (legacyTasksJson != null) {
        try {
          final decoded = jsonDecode(legacyTasksJson) as List;
          loadedTasks = decoded
              .asMap()
              .entries
              .map((entry) => DailyDeskTask.fromString(entry.value as String, entry.key))
              .toList();
        } catch (_) {
          loadedTasks = [];
        }
      }

      final validTaskIds = loadedTasks.map((t) => t.id).toSet();
      Set<String> completed = <String>{};
      if (completedJson != null) {
        try {
          completed = (jsonDecode(completedJson) as List)
              .map((e) => e.toString())
              .where((id) => validTaskIds.contains(id))
              .toSet();
        } catch (_) {
          completed = <String>{};
        }
      }
      Map<String, int> history = {};
      if (historyJson != null) {
        try {
          history = (jsonDecode(historyJson) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as int));
        } catch (_) {
          history = {};
        }
      }

      // Day Rollover (Option A):
      // If a new day has arrived (past 5:00 AM cutoff), credit yesterday's
      // completed tasks to history, clear completed tasks from desk,
      // and rollover any unfinished tasks to today.
      if (lastDate != null && lastDate != today) {
        if (completed.isNotEmpty) {
          final prevCount = history[lastDate] ?? 0;
          if (completed.length > prevCount) {
            history[lastDate] = completed.length;
          }
        }
        loadedTasks = loadedTasks.where((t) => !completed.contains(t.id)).toList();
        completed = <String>{};

        await prefs.setString(_kLastActiveDateKey, today);
        await prefs.setString(_kDailyTasksKey, jsonEncode(loadedTasks.map((t) => t.toMap()).toList()));
        await prefs.setString(_kCompletedTasksKey, jsonEncode([]));
        await prefs.setString(_kTasksHistoryKey, jsonEncode(history));
      } else if (lastDate == null) {
        await prefs.setString(_kLastActiveDateKey, today);
      }

      state = DailyTasksState(tasks: loadedTasks, completedIds: completed, dateHistory: history);
    } catch (_) {}
  }

  Future<void> setTasks(List<DailyDeskTask> newTasks) async {
    await _loadFuture;
    state = state.copyWith(tasks: newTasks);
    await _persist();
  }

  Future<void> setTaskStrings(List<String> taskTitles) async {
    await _loadFuture;
    final newTasks = taskTitles
        .asMap()
        .entries
        .map((entry) => DailyDeskTask.fromString(entry.value, entry.key))
        .toList();
    state = state.copyWith(tasks: newTasks);
    await _persist();
  }

  String _todayKey([int? customHour]) {
    final hour = customHour ?? dayStartHour;
    return MetricsService.todayKey(hour);
  }

  Future<bool> toggleTask(String taskId) async {
    await _loadFuture;
    final updated = Set<String>.from(state.completedIds);
    bool justFinishedAll = false;

    if (updated.contains(taskId)) {
      updated.remove(taskId);
    } else {
      updated.add(taskId);
      if (updated.length == state.tasks.length && state.tasks.isNotEmpty) {
        justFinishedAll = true;
        NotificationService.instance.showModuleTaskCompletedNotification(
          subjectName: "Today's Desk",
          count: updated.length,
        );
      }
    }

    final history = Map<String, int>.from(state.dateHistory);
    history[_todayKey()] = updated.length;

    state = state.copyWith(completedIds: updated, dateHistory: history);
    await _persist();
    return justFinishedAll;
  }

  Future<void> markTaskComplete(String taskId) async {
    if (!state.completedIds.contains(taskId)) {
      await toggleTask(taskId);
    }
  }

  Future<void> removeTaskAt(int index) async {
    await _loadFuture;
    final updatedTasks = List<DailyDeskTask>.from(state.tasks);
    if (index >= 0 && index < updatedTasks.length) {
      final removed = updatedTasks.removeAt(index);
      final updatedCompleted = Set<String>.from(state.completedIds)..remove(removed.id);
      final history = Map<String, int>.from(state.dateHistory);
      history[_todayKey()] = updatedCompleted.length;
      state = state.copyWith(tasks: updatedTasks, completedIds: updatedCompleted, dateHistory: history);
      await _persist();
    }
  }

  Future<void> insertTaskAt(int index, DailyDeskTask task, bool wasCompleted) async {
    await _loadFuture;
    final updatedTasks = List<DailyDeskTask>.from(state.tasks);
    final clampedIndex = index.clamp(0, updatedTasks.length);
    updatedTasks.insert(clampedIndex, task);

    final updatedCompleted = Set<String>.from(state.completedIds);
    if (wasCompleted) {
      updatedCompleted.add(task.id);
    }

    final history = Map<String, int>.from(state.dateHistory);
    history[_todayKey()] = updatedCompleted.length;

    state = state.copyWith(tasks: updatedTasks, completedIds: updatedCompleted, dateHistory: history);
    await _persist();
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    await _loadFuture;
    if (oldIndex < 0 || oldIndex >= state.tasks.length) return;
    final updatedTasks = List<DailyDeskTask>.from(state.tasks);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = updatedTasks.removeAt(oldIndex);
    updatedTasks.insert(newIndex, item);
    state = state.copyWith(tasks: updatedTasks);
    await _persist();
  }

  Future<void> clearCompleted() async {
    await _loadFuture;
    final updatedTasks = state.tasks.where((t) => !state.completedIds.contains(t.id)).toList();
    final updatedCompleted = <String>{};
    final history = Map<String, int>.from(state.dateHistory);
    history[_todayKey()] = 0;
    state = state.copyWith(tasks: updatedTasks, completedIds: updatedCompleted, dateHistory: history);
    await _persist();
  }

  Future<void> checkDayRollover() async {
    await _loadFuture;
    try {
      final prefs = _cachedPrefs ?? await SharedPreferences.getInstance();
      _cachedPrefs = prefs;
      final today = _todayKey();
      final lastDate = prefs.getString(_kLastActiveDateKey);

      if (lastDate != null && lastDate != today) {
        final history = Map<String, int>.from(state.dateHistory);
        if (state.completedIds.isNotEmpty) {
          final prevCount = history[lastDate] ?? 0;
          if (state.completedIds.length > prevCount) {
            history[lastDate] = state.completedIds.length;
          }
        }
        final remainingTasks = state.tasks.where((t) => !state.completedIds.contains(t.id)).toList();
        final updatedCompleted = <String>{};

        state = state.copyWith(
          tasks: remainingTasks,
          completedIds: updatedCompleted,
          dateHistory: history,
        );

        await prefs.setString(_kLastActiveDateKey, today);
        await _persist();
      } else if (lastDate == null) {
        await prefs.setString(_kLastActiveDateKey, today);
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = _cachedPrefs ?? await SharedPreferences.getInstance();
      _cachedPrefs = prefs;
      await prefs.setString(_kLastActiveDateKey, _todayKey());
      await prefs.setString(_kDailyTasksKey, jsonEncode(state.tasks.map((t) => t.toMap()).toList()));
      await prefs.setString(_kCompletedTasksKey, jsonEncode(state.completedIds.toList()));
      await prefs.setString(_kTasksHistoryKey, jsonEncode(state.dateHistory));
      if (_ref != null) {
        SyncService.instance.schedulePush(_ref);
      }
    } catch (_) {}
  }
}
