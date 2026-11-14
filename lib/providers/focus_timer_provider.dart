import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_theme.dart';
import '../models/time_log.dart';
import '../models/daily_desk_task.dart';
import '../models/task_item.dart';
import 'time_log_provider.dart';
import 'app_state_provider.dart';
import 'daily_tasks_provider.dart';
import 'tasks_hub_provider.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/sync_service.dart';
import '../services/ambient_audio_service.dart';
import '../services/study_presence_service.dart';
import '../services/alarm_clock_service.dart';

enum TimerMode { pomodoro, countUp, moduleLinked }
enum TimerPhase { idle, focusing, onBreak }

class FocusTimerState {
  final bool isRunning;
  final TimerPhase phase;
  final TimerMode mode;
  final int remainingSeconds;
  final int focusSecondsElapsed;
  final int breakSecondsElapsed;
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String topicTitle;
  final String chapterName;
  final String topicType;
  final int pomodoroPresetMins;
  final int pomodoroBreakMins;
  final int modulePresetMins;
  final int pomodoroTotalCycles;
  final int pomodoroCurrentCycle;
  final int pomodoroCompletedCycles;
  final int pomodoroLongBreakMins;
  final int pomodoroLongBreakInterval;
  final bool isLongBreak;
  final TimerThemeData theme;
  final String activeSoundId;
  final bool sessionActive;
  final bool hasTarget;
  final String? boundTaskId;
  final bool keepScreenAwake;

  const FocusTimerState({
    this.isRunning = false,
    this.phase = TimerPhase.idle,
    this.mode = TimerMode.pomodoro,
    this.remainingSeconds = 0,
    this.focusSecondsElapsed = 0,
    this.breakSecondsElapsed = 0,
    this.subjectId = '',
    this.subjectName = 'No Target Selected',
    this.topicId,
    this.topicTitle = 'Select a task or mode to start',
    this.chapterName = '',
    this.topicType = 'standalone',
    this.pomodoroPresetMins = 25,
    this.pomodoroBreakMins = 5,
    this.modulePresetMins = 15,
    this.pomodoroTotalCycles = 4,
    this.pomodoroCurrentCycle = 1,
    this.pomodoroCompletedCycles = 0,
    this.pomodoroLongBreakMins = 15,
    this.pomodoroLongBreakInterval = 4,
    this.isLongBreak = false,
    required this.theme,
    this.activeSoundId = 'none',
    this.sessionActive = false,
    this.hasTarget = false,
    this.boundTaskId,
    this.keepScreenAwake = true,
  });

  bool get isBreak => phase == TimerPhase.onBreak;
  int get pomodoroMinutes => pomodoroPresetMins;
  bool get isTaskBound => boundTaskId != null && boundTaskId!.isNotEmpty;

  FocusTimerState copyWith({
    bool? isRunning,
    TimerPhase? phase,
    TimerMode? mode,
    int? remainingSeconds,
    int? focusSecondsElapsed,
    int? breakSecondsElapsed,
    String? subjectId,
    String? subjectName,
    String? topicId,
    String? topicTitle,
    String? chapterName,
    String? topicType,
    int? pomodoroPresetMins,
    int? pomodoroBreakMins,
    int? modulePresetMins,
    int? pomodoroTotalCycles,
    int? pomodoroCurrentCycle,
    int? pomodoroCompletedCycles,
    int? pomodoroLongBreakMins,
    int? pomodoroLongBreakInterval,
    bool? isLongBreak,
    TimerThemeData? theme,
    String? activeSoundId,
    bool? sessionActive,
    bool? hasTarget,
    String? boundTaskId,
    bool clearBoundTask = false,
    bool? keepScreenAwake,
  }) {
    return FocusTimerState(
      isRunning: isRunning ?? this.isRunning,
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      focusSecondsElapsed: focusSecondsElapsed ?? this.focusSecondsElapsed,
      breakSecondsElapsed: breakSecondsElapsed ?? this.breakSecondsElapsed,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      chapterName: chapterName ?? this.chapterName,
      topicType: topicType ?? this.topicType,
      pomodoroPresetMins: pomodoroPresetMins ?? this.pomodoroPresetMins,
      pomodoroBreakMins: pomodoroBreakMins ?? this.pomodoroBreakMins,
      modulePresetMins: modulePresetMins ?? this.modulePresetMins,
      pomodoroTotalCycles: pomodoroTotalCycles ?? this.pomodoroTotalCycles,
      pomodoroCurrentCycle: pomodoroCurrentCycle ?? this.pomodoroCurrentCycle,
      pomodoroCompletedCycles: pomodoroCompletedCycles ?? this.pomodoroCompletedCycles,
      pomodoroLongBreakMins: pomodoroLongBreakMins ?? this.pomodoroLongBreakMins,
      pomodoroLongBreakInterval: pomodoroLongBreakInterval ?? this.pomodoroLongBreakInterval,
      isLongBreak: isLongBreak ?? this.isLongBreak,
      theme: theme ?? this.theme,
      activeSoundId: activeSoundId ?? this.activeSoundId,
      sessionActive: sessionActive ?? this.sessionActive,
      hasTarget: hasTarget ?? this.hasTarget,
      boundTaskId: clearBoundTask ? null : (boundTaskId ?? this.boundTaskId),
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    );
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerState>((ref) {
  return FocusTimerNotifier(ref);
});

class FocusTimerNotifier extends StateNotifier<FocusTimerState>
    with WidgetsBindingObserver {
  static const _prefKeepAwakeKey = 'focus_timer_keep_screen_awake';
  static const _prefSessionAnchorKey = 'focus_timer_active_session_anchor_v1';
  final Ref _ref;
  Timer? _ticker;
  DateTime? _sessionStartTime;
  DateTime? _sessionTargetEndTime;
  DateTime? _lastTickWallTime;
  int _lastPersistSeconds = 0;

  FocusTimerNotifier(this._ref)
      : super(FocusTimerState(theme: kTimerThemes.first)) {
    _loadKeepAwakePreference();
    WidgetsBinding.instance.addObserver(this);
    restoreSessionFromDisk();
  }

  Future<void> _loadKeepAwakePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefKeepAwakeKey);
      if (saved != null) {
        state = state.copyWith(keepScreenAwake: saved);
      }
    } catch (_) {}
  }

  /// Persist current active session to disk for crash, background kill, and reboot recovery
  Future<void> _persistSessionAnchor() async {
    if (!state.sessionActive) {
      await _clearPersistedSessionAnchor();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{
        'sessionActive': state.sessionActive,
        'isRunning': state.isRunning,
        'startTimeMs': _sessionStartTime?.millisecondsSinceEpoch,
        'targetEndTimeMs': _sessionTargetEndTime?.millisecondsSinceEpoch,
        'lastTickWallTimeMs': _lastTickWallTime?.millisecondsSinceEpoch,
        'mode': state.mode.name,
        'phase': state.phase.name,
        'subjectId': state.subjectId,
        'subjectName': state.subjectName,
        'topicId': state.topicId,
        'topicTitle': state.topicTitle,
        'chapterName': state.chapterName,
        'topicType': state.topicType,
        'pomodoroPresetMins': state.pomodoroPresetMins,
        'pomodoroBreakMins': state.pomodoroBreakMins,
        'modulePresetMins': state.modulePresetMins,
        'pomodoroTotalCycles': state.pomodoroTotalCycles,
        'pomodoroCurrentCycle': state.pomodoroCurrentCycle,
        'pomodoroCompletedCycles': state.pomodoroCompletedCycles,
        'pomodoroLongBreakMins': state.pomodoroLongBreakMins,
        'pomodoroLongBreakInterval': state.pomodoroLongBreakInterval,
        'isLongBreak': state.isLongBreak,
        'remainingSeconds': state.remainingSeconds,
        'focusSecondsElapsed': state.focusSecondsElapsed,
        'breakSecondsElapsed': state.breakSecondsElapsed,
        'hasTarget': state.hasTarget,
        'boundTaskId': state.boundTaskId,
        'activeSoundId': state.activeSoundId,
        'savedAtMs': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_prefSessionAnchorKey, jsonEncode(map));
    } catch (e) {
      debugPrint('[FocusTimerNotifier] _persistSessionAnchor error: $e');
    }
  }

  /// Clear session anchor when explicitly ended, finished, or reset
  Future<void> _clearPersistedSessionAnchor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefSessionAnchorKey);
    } catch (_) {}
  }

  /// Reconstruct active focus session from disk following cold boot or OS process death
  Future<void> restoreSessionFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefSessionAnchorKey);
      if (raw == null || raw.isEmpty) return;

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final bool sessionActive = decoded['sessionActive'] == true;
      if (!sessionActive) return;

      final bool isRunning = decoded['isRunning'] == true;
      final String modeName = decoded['mode']?.toString() ?? 'pomodoro';
      final String phaseName = decoded['phase']?.toString() ?? 'focusing';

      final TimerMode mode = TimerMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => TimerMode.pomodoro,
      );

      final TimerPhase phase = TimerPhase.values.firstWhere(
        (p) => p.name == phaseName,
        orElse: () => TimerPhase.focusing,
      );

      final int? startMs = (decoded['startTimeMs'] as num?)?.toInt();
      final int? targetMs = (decoded['targetEndTimeMs'] as num?)?.toInt();
      final int savedAtMs = (decoded['savedAtMs'] as num?)?.toInt() ?? 0;

      final int pomodoroPresetMins = (decoded['pomodoroPresetMins'] as num?)?.toInt() ?? 25;
      final int pomodoroBreakMins = (decoded['pomodoroBreakMins'] as num?)?.toInt() ?? 5;
      final int modulePresetMins = (decoded['modulePresetMins'] as num?)?.toInt() ?? 15;
      final int pomodoroTotalCycles = (decoded['pomodoroTotalCycles'] as num?)?.toInt() ?? 4;
      final int pomodoroCurrentCycle = (decoded['pomodoroCurrentCycle'] as num?)?.toInt() ?? 1;
      final int pomodoroCompletedCycles = (decoded['pomodoroCompletedCycles'] as num?)?.toInt() ?? 0;
      final int pomodoroLongBreakMins = (decoded['pomodoroLongBreakMins'] as num?)?.toInt() ?? 15;
      final int pomodoroLongBreakInterval = (decoded['pomodoroLongBreakInterval'] as num?)?.toInt() ?? 4;
      final bool isLongBreak = decoded['isLongBreak'] == true;

      int focusSecondsElapsed = (decoded['focusSecondsElapsed'] as num?)?.toInt() ?? 0;
      int breakSecondsElapsed = (decoded['breakSecondsElapsed'] as num?)?.toInt() ?? 0;
      int remainingSeconds = (decoded['remainingSeconds'] as num?)?.toInt() ?? 0;

      final String subjectId = decoded['subjectId']?.toString() ?? '';
      final String subjectName = decoded['subjectName']?.toString() ?? 'General Focus';
      final String? topicId = decoded['topicId']?.toString();
      final String topicTitle = decoded['topicTitle']?.toString() ?? 'General Focus Session';
      final String chapterName = decoded['chapterName']?.toString() ?? '';
      final String topicType = decoded['topicType']?.toString() ?? 'general';
      final String? boundTaskId = decoded['boundTaskId']?.toString();
      final String activeSoundId = decoded['activeSoundId']?.toString() ?? 'none';
      final bool hasTarget = decoded['hasTarget'] == true;

      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      if (startMs != null) {
        _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(startMs);
      }

      // ── CASE 1: Session was PAUSED when app terminated ───────────────────
      if (!isRunning) {
        state = state.copyWith(
          sessionActive: true,
          isRunning: false,
          mode: mode,
          phase: phase,
          subjectId: subjectId,
          subjectName: subjectName,
          topicId: topicId,
          topicTitle: topicTitle,
          chapterName: chapterName,
          topicType: topicType,
          pomodoroPresetMins: pomodoroPresetMins,
          pomodoroBreakMins: pomodoroBreakMins,
          modulePresetMins: modulePresetMins,
          pomodoroTotalCycles: pomodoroTotalCycles,
          pomodoroCurrentCycle: pomodoroCurrentCycle,
          pomodoroCompletedCycles: pomodoroCompletedCycles,
          pomodoroLongBreakMins: pomodoroLongBreakMins,
          pomodoroLongBreakInterval: pomodoroLongBreakInterval,
          isLongBreak: isLongBreak,
          focusSecondsElapsed: focusSecondsElapsed,
          breakSecondsElapsed: breakSecondsElapsed,
          remainingSeconds: remainingSeconds,
          hasTarget: hasTarget,
          boundTaskId: boundTaskId,
          activeSoundId: activeSoundId,
        );
        return;
      }

      // ── CASE 2: Countdown Mode (Pomodoro or ModuleLinked) ─────────────────
      if (mode != TimerMode.countUp && phase != TimerPhase.onBreak && targetMs != null) {
        if (nowMs >= targetMs) {
          // Completed while app was closed or device was asleep
          final fullSessionSecs = pomodoroPresetMins * 60;
          final safeElapsed = focusSecondsElapsed > 0 ? focusSecondsElapsed : fullSessionSecs;

          state = state.copyWith(
            sessionActive: true,
            isRunning: false,
            mode: mode,
            phase: TimerPhase.focusing,
            subjectId: subjectId,
            subjectName: subjectName,
            topicId: topicId,
            topicTitle: topicTitle,
            chapterName: chapterName,
            topicType: topicType,
            pomodoroPresetMins: pomodoroPresetMins,
            pomodoroBreakMins: pomodoroBreakMins,
            modulePresetMins: modulePresetMins,
            pomodoroTotalCycles: pomodoroTotalCycles,
            pomodoroCurrentCycle: pomodoroCurrentCycle,
            pomodoroCompletedCycles: pomodoroCompletedCycles,
            focusSecondsElapsed: safeElapsed,
            remainingSeconds: 0,
            hasTarget: hasTarget,
            boundTaskId: boundTaskId,
            activeSoundId: activeSoundId,
          );

          // Automatically finalize study session and log to database
          await finishSession();

          final alertsEnabled = _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
          if (alertsEnabled) {
            NotificationService.instance.showFocusTimerCompleted(topicTitle: topicTitle);
          }
          await _clearPersistedSessionAnchor();
          return;
        } else {
          // Active session still ongoing: calculate exact remaining seconds via wall-clock
          final diffSecs = ((targetMs - nowMs) / 1000.0).ceil();
          final elapsedSinceSave = savedAtMs > 0 ? ((nowMs - savedAtMs) / 1000.0).round() : 0;
          focusSecondsElapsed += (elapsedSinceSave > 0 ? elapsedSinceSave : 0);
          remainingSeconds = diffSecs;

          _sessionTargetEndTime = DateTime.fromMillisecondsSinceEpoch(targetMs);
          _lastTickWallTime = now;

          state = state.copyWith(
            sessionActive: true,
            isRunning: true,
            mode: mode,
            phase: phase,
            subjectId: subjectId,
            subjectName: subjectName,
            topicId: topicId,
            topicTitle: topicTitle,
            chapterName: chapterName,
            topicType: topicType,
            pomodoroPresetMins: pomodoroPresetMins,
            pomodoroBreakMins: pomodoroBreakMins,
            modulePresetMins: modulePresetMins,
            pomodoroTotalCycles: pomodoroTotalCycles,
            pomodoroCurrentCycle: pomodoroCurrentCycle,
            pomodoroCompletedCycles: pomodoroCompletedCycles,
            pomodoroLongBreakMins: pomodoroLongBreakMins,
            pomodoroLongBreakInterval: pomodoroLongBreakInterval,
            isLongBreak: isLongBreak,
            focusSecondsElapsed: focusSecondsElapsed,
            breakSecondsElapsed: breakSecondsElapsed,
            remainingSeconds: remainingSeconds,
            hasTarget: hasTarget,
            boundTaskId: boundTaskId,
            activeSoundId: activeSoundId,
          );

          _ticker?.cancel();
          _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
          AmbientAudioService.instance.onTimerStartOrResume();
          _updateRealtimeNotification();
          if (_sessionTargetEndTime != null) {
            AlarmClockService.instance.scheduleAlarm(
              targetTime: _sessionTargetEndTime!,
              title: topicTitle,
              isBreak: false,
            );
          }
          return;
        }
      }

      // ── CASE 3: Count-Up or Break Mode ──────────────────────────────────
      if (startMs != null) {
        final elapsedTotal = ((nowMs - startMs) / 1000.0).round();
        if (phase == TimerPhase.onBreak) {
          breakSecondsElapsed = elapsedTotal > 0 ? elapsedTotal : breakSecondsElapsed;
        } else {
          focusSecondsElapsed = elapsedTotal > 0 ? elapsedTotal : focusSecondsElapsed;
          remainingSeconds = focusSecondsElapsed;
        }

        _lastTickWallTime = now;
        state = state.copyWith(
          sessionActive: true,
          isRunning: true,
          mode: mode,
          phase: phase,
          subjectId: subjectId,
          subjectName: subjectName,
          topicId: topicId,
          topicTitle: topicTitle,
          chapterName: chapterName,
          topicType: topicType,
          pomodoroPresetMins: pomodoroPresetMins,
          pomodoroBreakMins: pomodoroBreakMins,
          focusSecondsElapsed: focusSecondsElapsed,
          breakSecondsElapsed: breakSecondsElapsed,
          remainingSeconds: remainingSeconds,
          hasTarget: hasTarget,
          boundTaskId: boundTaskId,
          activeSoundId: activeSoundId,
        );

        _ticker?.cancel();
        _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
        AmbientAudioService.instance.onTimerStartOrResume();
        _updateRealtimeNotification();
      }
    } catch (e) {
      debugPrint('[FocusTimerNotifier] _restoreSessionFromDisk error: $e');
    }
  }

  Future<void> _saveKeepAwakePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeepAwakeKey, value);
    } catch (_) {}
  }

  void setKeepScreenAwake(bool value) {
    state = state.copyWith(keepScreenAwake: value);
    _saveKeepAwakePreference(value);
  }

  void setTask({
    required String subjectId,
    required String subjectName,
    String? topicId,
    required String topicTitle,
    String chapterName = '',
    required String topicType,
    int? durationMins,
  }) {
    final bool isCountUpType = topicType.toLowerCase() == 'qbank' || topicType.toLowerCase() == 'notes';
    final newMode = isCountUpType ? TimerMode.countUp : TimerMode.pomodoro;
    final int presetMins = (durationMins != null && durationMins > 0)
        ? durationMins
        : state.pomodoroPresetMins;
    final int nextSeconds = (newMode == TimerMode.countUp) ? 0 : (presetMins * 60);

    state = state.copyWith(
      hasTarget: true,
      subjectId: subjectId,
      subjectName: subjectName,
      topicId: topicId,
      topicTitle: topicTitle,
      chapterName: chapterName,
      topicType: topicType,
      mode: newMode,
      pomodoroPresetMins: presetMins,
      remainingSeconds: nextSeconds,
    );
  }

  /// Binds the timer directly to a DailyDeskTask and immediately starts focus session
  void startTaskFocus(DailyDeskTask task) {
    final int presetMins = (task.estimatedMinutes != null && task.estimatedMinutes! > 0)
        ? task.estimatedMinutes!
        : 25;

    _ticker?.cancel();

    state = state.copyWith(
      boundTaskId: task.id,
      hasTarget: true,
      subjectId: task.subject.shortCode.toLowerCase(),
      subjectName: task.subject.label,
      topicId: task.id,
      topicTitle: task.title,
      chapterName: task.subject.label,
      topicType: task.category.name,
      mode: TimerMode.pomodoro,
      pomodoroPresetMins: presetMins,
      remainingSeconds: presetMins * 60,
      focusSecondsElapsed: 0,
      breakSecondsElapsed: 0,
      phase: TimerPhase.focusing,
      sessionActive: true,
      isRunning: false,
    );

    // Immediately begin ticking
    startOrPause();
  }

  /// Binds the timer directly to a TasksHub [TaskItem] and immediately starts focus session
  void startTaskItemFocus(TaskItem task) {
    final int presetMins = (task.estimatedMinutes != null && task.estimatedMinutes! > 0)
        ? task.estimatedMinutes!
        : 25;

    _ticker?.cancel();

    state = state.copyWith(
      boundTaskId: task.id,
      hasTarget: true,
      subjectId: 'tasks',
      subjectName: task.note ?? 'Tasks Hub',
      topicId: task.moduleId ?? task.id,
      topicTitle: task.title,
      chapterName: task.note ?? '',
      topicType: task.moduleId != null ? 'video' : 'task',
      mode: TimerMode.pomodoro,
      pomodoroPresetMins: presetMins,
      remainingSeconds: presetMins * 60,
      focusSecondsElapsed: 0,
      breakSecondsElapsed: 0,
      phase: TimerPhase.focusing,
      sessionActive: true,
      isRunning: false,
    );

    // Immediately begin ticking
    startOrPause();
  }

  /// Unbinds current task from the timer, reverting to general session
  void unbindTask() {
    state = state.copyWith(
      clearBoundTask: true,
      hasTarget: false,
      subjectId: 'general',
      subjectName: 'General Focus',
      topicTitle: 'General Focus Session',
    );
  }

  /// Toggles the bound desk task completed status in-situ without leaving timer
  Future<void> toggleBoundTaskCompleted() async {
    final taskId = state.boundTaskId;
    if (taskId == null || taskId.isEmpty) return;
    if (taskId.startsWith('task_')) {
      await _ref.read(tasksHubProvider.notifier).toggleComplete(taskId);
    } else {
      await _ref.read(dailyTasksProvider.notifier).toggleTask(taskId);
    }
  }

  void changeMode(TimerMode newMode) {
    if (state.isRunning) return;
    state = state.copyWith(
      hasTarget: true,
      mode: newMode,
      remainingSeconds: _computeRemaining(mode: newMode),
    );
  }

  void setPomodoroMinutes(int mins) {
    if (state.isRunning) return;
    final clamped = mins.clamp(1, 300);
    state = state.copyWith(
      hasTarget: true,
      pomodoroPresetMins: clamped,
      remainingSeconds: state.phase != TimerPhase.onBreak ? clamped * 60 : state.remainingSeconds,
    );
  }

  void setPomodoroPreset(int mins) => setPomodoroMinutes(mins);

  void adjustPomodoroMinutes(int delta) {
    if (state.isRunning) return;
    final clamped = (state.pomodoroPresetMins + delta).clamp(1, 300);
    state = state.copyWith(
      hasTarget: true,
      pomodoroPresetMins: clamped,
      remainingSeconds: state.phase != TimerPhase.onBreak ? clamped * 60 : state.remainingSeconds,
    );
  }

  void setPomodoroBreakMinutes(int mins) {
    if (state.isRunning) return;
    final clamped = mins.clamp(1, 60);
    state = state.copyWith(
      pomodoroBreakMins: clamped,
      remainingSeconds: state.phase == TimerPhase.onBreak ? clamped * 60 : state.remainingSeconds,
    );
  }

  void adjustPomodoroBreakMinutes(int delta) {
    if (state.isRunning) return;
    final clamped = (state.pomodoroBreakMins + delta).clamp(1, 60);
    state = state.copyWith(
      pomodoroBreakMins: clamped,
      remainingSeconds: state.phase == TimerPhase.onBreak ? clamped * 60 : state.remainingSeconds,
    );
  }

  void setPomodoroTotalCycles(int cycles) {
    if (state.isRunning) return;
    final clamped = cycles.clamp(1, 12);
    state = state.copyWith(
      pomodoroTotalCycles: clamped,
      pomodoroLongBreakInterval: clamped,
    );
  }

  void adjustPomodoroTotalCycles(int delta) {
    if (state.isRunning) return;
    final clamped = (state.pomodoroTotalCycles + delta).clamp(1, 12);
    state = state.copyWith(
      pomodoroTotalCycles: clamped,
      pomodoroLongBreakInterval: clamped,
    );
  }

  void setPomodoroLongBreakMinutes(int mins) {
    if (state.isRunning) return;
    final clamped = mins.clamp(1, 60);
    state = state.copyWith(pomodoroLongBreakMins: clamped);
  }

  void adjustPomodoroLongBreakMinutes(int delta) {
    if (state.isRunning) return;
    final clamped = (state.pomodoroLongBreakMins + delta).clamp(1, 60);
    state = state.copyWith(pomodoroLongBreakMins: clamped);
  }

  void setPomodoroLongBreakInterval(int interval) {
    if (state.isRunning) return;
    final clamped = interval.clamp(1, 12);
    state = state.copyWith(pomodoroLongBreakInterval: clamped);
  }

  void resetPomodoroCycles() {
    state = state.copyWith(
      pomodoroCompletedCycles: 0,
      pomodoroCurrentCycle: 1,
      isLongBreak: false,
    );
  }

  void nextPomodoroCycle() {
    final next = state.pomodoroCurrentCycle < state.pomodoroTotalCycles
        ? state.pomodoroCurrentCycle + 1
        : 1;
    state = state.copyWith(
      pomodoroCurrentCycle: next,
      phase: TimerPhase.focusing,
      remainingSeconds: state.pomodoroPresetMins * 60,
    );
  }

  void setModulePreset(int mins) {
    if (state.isRunning) return;
    final clamped = mins.clamp(1, 300);
    state = state.copyWith(
      hasTarget: true,
      modulePresetMins: clamped,
      remainingSeconds: clamped * 60,
    );
  }

  void startOrPause() {
    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    if (state.isRunning) {
      _ticker?.cancel();
      _sessionTargetEndTime = null;
      _lastTickWallTime = null;
      NotificationService.instance.cancelFocusTimerEnd();
      NotificationService.instance.cancelFocusTimerRunning();
      AlarmClockService.instance.cancelAlarm();
      AmbientAudioService.instance.onTimerPause();
      StudyPresenceService.instance.stopFocusSession();
      state = state.copyWith(isRunning: false);
      _persistSessionAnchor();
    } else {
      final newPhase = state.phase == TimerPhase.idle ? TimerPhase.focusing : state.phase;
      final now = DateTime.now();
      _sessionStartTime ??= now;
      int currentRemaining = state.remainingSeconds;
      if (state.mode == TimerMode.pomodoro && currentRemaining == 0) {
        currentRemaining = state.pomodoroPresetMins * 60;
      }

      if (newPhase != TimerPhase.onBreak && state.mode != TimerMode.countUp && currentRemaining > 0) {
        _sessionTargetEndTime = now.add(Duration(seconds: currentRemaining));
      } else {
        _sessionTargetEndTime = null;
      }

      state = state.copyWith(
        isRunning: true,
        sessionActive: true,
        phase: newPhase,
        remainingSeconds: currentRemaining,
      );
      AnalyticsService.instance.logTimerStarted(
        mode: state.mode.name,
        subject: state.subjectName.isNotEmpty ? state.subjectName : 'General Focus',
        durationMins: state.remainingSeconds ~/ 60,
      );

      if (alertsEnabled) {
        _updateRealtimeNotification();

        if (newPhase != TimerPhase.onBreak && state.mode != TimerMode.countUp && state.remainingSeconds > 0) {
          NotificationService.instance.scheduleFocusTimerEnd(
            duration: Duration(seconds: state.remainingSeconds),
            topicTitle: state.topicTitle,
            isBreak: false,
          );
          if (_sessionTargetEndTime != null) {
            AlarmClockService.instance.scheduleAlarm(
              targetTime: _sessionTargetEndTime!,
              title: state.topicTitle,
              isBreak: false,
            );
          }
        }
      }
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
      AmbientAudioService.instance.onTimerStartOrResume();
      if (newPhase == TimerPhase.focusing) {
        StudyPresenceService.instance.startFocusSession(
          subjectName: state.subjectName,
          topicTitle: state.topicTitle,
        );
      }
      _persistSessionAnchor();
    }
  }

  void toggleBreak() {
    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    final willBeBreak = state.phase != TimerPhase.onBreak;
    if (willBeBreak) {
      // Break is now a count-up timer!
      StudyPresenceService.instance.stopFocusSession();
      _sessionTargetEndTime = null;
      _lastTickWallTime = DateTime.now();
      state = state.copyWith(
        phase: TimerPhase.onBreak,
        breakSecondsElapsed: 0,
      );
    } else {
      // Return to focusing: resume countdown from preserved focus remaining seconds
      final now = DateTime.now();
      _lastTickWallTime = now;
      final resumeSeconds = state.remainingSeconds > 0
          ? state.remainingSeconds
          : _computeRemaining();
      if (state.mode != TimerMode.countUp && resumeSeconds > 0) {
        _sessionTargetEndTime = now.add(Duration(seconds: resumeSeconds));
      } else {
        _sessionTargetEndTime = null;
      }
      state = state.copyWith(
        phase: TimerPhase.focusing,
        remainingSeconds: resumeSeconds,
      );
      if (state.isRunning) {
        StudyPresenceService.instance.startFocusSession(
          subjectName: state.subjectName,
          topicTitle: state.topicTitle,
        );
      }
    }

    if (alertsEnabled) {
      NotificationService.instance.cancelFocusTimerEnd();
      AlarmClockService.instance.cancelAlarm();
      if (state.isRunning) {
        _updateRealtimeNotification();
        if (!willBeBreak && state.mode != TimerMode.countUp && state.remainingSeconds > 0 && _sessionTargetEndTime != null) {
          NotificationService.instance.scheduleFocusTimerEnd(
            duration: Duration(seconds: state.remainingSeconds),
            topicTitle: state.topicTitle,
            isBreak: false,
          );
          AlarmClockService.instance.scheduleAlarm(
            targetTime: _sessionTargetEndTime!,
            title: state.topicTitle,
            isBreak: false,
          );
        }
      }
    }
    _persistSessionAnchor();
  }

  void setTheme(TimerThemeData theme) {
    state = state.copyWith(theme: theme);
  }

  void setSound(String soundId) {
    state = state.copyWith(activeSoundId: soundId);
  }

  Future<TimeLog?> finishSession() async {
    _ticker?.cancel();
    _sessionTargetEndTime = null;
    _lastTickWallTime = null;
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();
    AlarmClockService.instance.cancelAlarm();
    AmbientAudioService.instance.onTimerPause();
    if (state.focusSecondsElapsed == 0) {
      reset();
      return null;
    }

    final hasExplicitSubject = state.subjectId.isNotEmpty && state.subjectId != 'general';
    final effectiveSubjectId = hasExplicitSubject ? state.subjectId : 'general';
    final effectiveTopicType = state.topicType.isNotEmpty ? state.topicType : 'general';
    final effectiveTopicTitle = state.hasTarget && state.topicTitle.isNotEmpty
        ? state.topicTitle
        : (hasExplicitSubject
            ? '${state.subjectName.isNotEmpty ? state.subjectName : state.subjectId} Focus'
            : 'General Focus');

    final log = TimeLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: effectiveSubjectId,
      topicId: state.topicId,
      topicType: effectiveTopicType,
      topicTitle: effectiveTopicTitle,
      chapterName: state.chapterName,
      durationSecs: state.focusSecondsElapsed,
      timestamp: DateTime.now(),
    );

    await _ref.read(timeLogsProvider.notifier).logTime(log);
    AnalyticsService.instance.logTimerCompleted(
      mode: state.mode.name,
      subject: effectiveSubjectId,
      durationMins: state.focusSecondsElapsed ~/ 60,
      breakMins: state.breakSecondsElapsed ~/ 60,
    );

    // Auto-mark linked daily task or curriculum module as completed
    try {
      if (state.boundTaskId != null && state.boundTaskId!.isNotEmpty) {
        await _ref.read(tasksHubProvider.notifier).markTaskComplete(state.boundTaskId!);
        await _ref.read(dailyTasksProvider.notifier).markTaskComplete(state.boundTaskId!);
      }
      if (state.topicId != null && state.topicId!.isNotEmpty) {
        final tId = state.topicId!;
        final type = state.topicType;
        if (type == 'video') {
          await _ref.read(appStateProvider.notifier).markVideoComplete(tId);
        } else if (type == 'qbank') {
          await _ref.read(appStateProvider.notifier).markQBankComplete(tId);
        } else if (type == 'notes') {
          await _ref.read(appStateProvider.notifier).markNotesComplete(tId);
        }

        // Also check if this matches a daily desk task by id or 'vid_$tId'
        final focusMins = state.focusSecondsElapsed ~/ 60;
        final deskNotifier = _ref.read(dailyTasksProvider.notifier);
        final deskState = _ref.read(dailyTasksProvider);
        final targetTaskId = state.boundTaskId ?? tId;
        for (final task in deskState.tasks) {
          if (!deskState.completedIds.contains(task.id)) {
            if (task.id == targetTaskId ||
                task.id == tId ||
                task.id == 'vid_$tId' ||
                task.title.trim().toLowerCase() == state.topicTitle.trim().toLowerCase()) {
              if (focusMins > 0) {
                await deskNotifier.logFocusMinutes(task.id, focusMins);
              }
              await deskNotifier.markTaskComplete(task.id);
            }
          }
        }
      } else if (state.hasTarget && state.topicTitle.isNotEmpty) {
        final focusMins = state.focusSecondsElapsed ~/ 60;
        final deskNotifier = _ref.read(dailyTasksProvider.notifier);
        final deskState = _ref.read(dailyTasksProvider);
        for (final task in deskState.tasks) {
          if (!deskState.completedIds.contains(task.id)) {
            if (task.title.trim().toLowerCase() == state.topicTitle.trim().toLowerCase()) {
              if (focusMins > 0) {
                await deskNotifier.logFocusMinutes(task.id, focusMins);
              }
              await deskNotifier.markTaskComplete(task.id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error auto-completing task in timer finish: $e');
    }

    SyncService.instance.schedulePush(_ref);
    StudyPresenceService.instance.stopFocusSession();
    await _clearPersistedSessionAnchor();
    return log;
  }

  void reset() {
    _ticker?.cancel();
    _sessionStartTime = null;
    _sessionTargetEndTime = null;
    _lastTickWallTime = null;
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();
    AlarmClockService.instance.cancelAlarm();
    AmbientAudioService.instance.onTimerPause();
    StudyPresenceService.instance.stopFocusSession();
    state = FocusTimerState(
      theme: state.theme,
      activeSoundId: state.activeSoundId,
      hasTarget: false,
      remainingSeconds: 0,
      keepScreenAwake: state.keepScreenAwake,
    );
    _clearPersistedSessionAnchor();
  }

  void resetSessionForSameTask() {
    _ticker?.cancel();
    _sessionStartTime = null;
    _sessionTargetEndTime = null;
    _lastTickWallTime = null;
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();
    AlarmClockService.instance.cancelAlarm();
    AmbientAudioService.instance.onTimerPause();
    StudyPresenceService.instance.stopFocusSession();
    final rem = state.mode == TimerMode.pomodoro
        ? state.pomodoroPresetMins * 60
        : (state.mode == TimerMode.moduleLinked ? state.modulePresetMins * 60 : 0);
    state = state.copyWith(
      isRunning: false,
      phase: TimerPhase.idle,
      sessionActive: false,
      focusSecondsElapsed: 0,
      breakSecondsElapsed: 0,
      remainingSeconds: rem,
      hasTarget: true,
    );
    _clearPersistedSessionAnchor();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWithWallClock();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _persistSessionAnchor();
    }
  }

  void _syncWithWallClock() {
    if (!state.isRunning) return;

    final now = DateTime.now();

    if (state.phase == TimerPhase.onBreak) {
      if (_lastTickWallTime != null) {
        final elapsed = now.difference(_lastTickWallTime!).inSeconds;
        if (elapsed > 0) {
          _lastTickWallTime = now;
          state = state.copyWith(
            breakSecondsElapsed: state.breakSecondsElapsed + elapsed,
          );
          _updateRealtimeNotification();
        }
      }
      return;
    }

    if (state.mode == TimerMode.countUp) {
      if (_lastTickWallTime != null) {
        final elapsed = now.difference(_lastTickWallTime!).inSeconds;
        if (elapsed > 0) {
          _lastTickWallTime = now;
          state = state.copyWith(
            focusSecondsElapsed: state.focusSecondsElapsed + elapsed,
            remainingSeconds: state.remainingSeconds + elapsed,
          );
        }
      }
      return;
    }

    if (_sessionTargetEndTime != null) {
      final diffMs = _sessionTargetEndTime!.difference(now).inMilliseconds;
      if (diffMs <= 0) {
        // Countdown completed while in background
        _onCountdownComplete();
      } else {
        final remaining = (diffMs / 1000.0).ceil();
        final elapsed = state.remainingSeconds - remaining;
        final safeElapsed = elapsed > 0 ? elapsed : 0;
        _lastTickWallTime = now;

        state = state.copyWith(
          remainingSeconds: remaining,
          focusSecondsElapsed: state.focusSecondsElapsed + safeElapsed,
        );
        _updateRealtimeNotification();
      }
    }
  }

  void _tick() {
    if (!state.isRunning) return;

    final now = DateTime.now();

    // 1. Break Phase: Count-up break timer!
    if (state.phase == TimerPhase.onBreak) {
      _lastTickWallTime ??= now;
      final elapsedDiff = now.difference(_lastTickWallTime!).inMilliseconds;
      if (elapsedDiff < 1000) return;
      final wholeSeconds = elapsedDiff ~/ 1000;
      _lastTickWallTime = _lastTickWallTime!.add(Duration(seconds: wholeSeconds));

      state = state.copyWith(
        breakSecondsElapsed: state.breakSecondsElapsed + wholeSeconds,
      );
      _updateRealtimeNotification();
      _checkPeriodicPersist();
      return;
    }

    // 2. Count-Up Focus Mode
    if (state.mode == TimerMode.countUp) {
      _lastTickWallTime ??= now;
      final elapsedDiff = now.difference(_lastTickWallTime!).inMilliseconds;
      if (elapsedDiff < 1000) return;
      final wholeSeconds = elapsedDiff ~/ 1000;
      _lastTickWallTime = _lastTickWallTime!.add(Duration(seconds: wholeSeconds));

      state = state.copyWith(
        focusSecondsElapsed: state.focusSecondsElapsed + wholeSeconds,
        remainingSeconds: state.remainingSeconds + wholeSeconds,
      );
      _checkPeriodicPersist();
      return;
    }

    // 3. Countdown Focus Mode (Pomodoro)
    if (_sessionTargetEndTime == null) return;

    final diffMs = _sessionTargetEndTime!.difference(now).inMilliseconds;
    if (diffMs <= 0) {
      _onCountdownComplete();
      return;
    }

    final remaining = (diffMs / 1000.0).ceil();
    if (remaining == state.remainingSeconds) return;

    final delta = state.remainingSeconds - remaining;
    if (delta <= 0) return;

    _lastTickWallTime = now;
    state = state.copyWith(
      focusSecondsElapsed: state.focusSecondsElapsed + delta,
      remainingSeconds: remaining,
    );
    _checkPeriodicPersist();
  }

  void _checkPeriodicPersist() {
    final totalElapsed = state.focusSecondsElapsed + state.breakSecondsElapsed;
    if (totalElapsed - _lastPersistSeconds >= 5) {
      _lastPersistSeconds = totalElapsed;
      _persistSessionAnchor();
    }
  }

  void _onCountdownComplete() {
    _ticker?.cancel();
    _sessionTargetEndTime = null;
    _lastTickWallTime = null;
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();
    AlarmClockService.instance.cancelAlarm();
    AmbientAudioService.instance.onTimerPause();

    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    final s = state;

    if (s.phase == TimerPhase.onBreak) {
      if (alertsEnabled) {
        NotificationService.instance.showBreakCompleted(topicTitle: s.topicTitle);
      }
      state = s.copyWith(
        isRunning: false,
        phase: TimerPhase.idle,
      );
    } else {
      if (alertsEnabled) {
        NotificationService.instance.showFocusTimerCompleted(topicTitle: s.topicTitle);
      }

      final nextCompleted = s.pomodoroCompletedCycles + 1;
      final isLong = (nextCompleted % s.pomodoroLongBreakInterval == 0);
      final nextCycle = s.pomodoroCurrentCycle < s.pomodoroTotalCycles
          ? s.pomodoroCurrentCycle + 1
          : s.pomodoroCurrentCycle;

      state = s.copyWith(
        isRunning: false,
        remainingSeconds: 0,
        pomodoroCompletedCycles: nextCompleted,
        pomodoroCurrentCycle: nextCycle,
        isLongBreak: isLong,
        phase: TimerPhase.onBreak,
        breakSecondsElapsed: 0,
      );

      // Auto-complete module/daily tasks
      if (s.boundTaskId != null && s.boundTaskId!.isNotEmpty) {
        _ref.read(tasksHubProvider.notifier).markTaskComplete(s.boundTaskId!);
        _ref.read(dailyTasksProvider.notifier).markTaskComplete(s.boundTaskId!);
      }

      if (s.topicId != null && s.topicId!.isNotEmpty) {
        final tId = s.topicId!;
        final type = s.topicType;
        if (type == 'video') {
          _ref.read(appStateProvider.notifier).markVideoComplete(tId);
        } else if (type == 'qbank') {
          _ref.read(appStateProvider.notifier).markQBankComplete(tId);
        } else if (type == 'notes') {
          _ref.read(appStateProvider.notifier).markNotesComplete(tId);
        }
        _ref.read(dailyTasksProvider.notifier).markTaskComplete(tId);
      }
    }
    _persistSessionAnchor();
  }

  void _updateRealtimeNotification() {
    final appState = _ref.read(appStateProvider).valueOrNull;
    final alertsEnabled = appState?.focusTimerAlertsEnabled ?? true;
    final liveEnabled = appState?.liveTimerNotificationEnabled ?? true;
    if (!alertsEnabled || !liveEnabled || !state.isRunning) {
      NotificationService.instance.cancelFocusTimerRunning();
      return;
    }

    final isBreak = state.phase == TimerPhase.onBreak;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final int whenMs;
    final bool isCountdown;

    if (isBreak) {
      isCountdown = false;
      whenMs = nowMs - (state.breakSecondsElapsed * 1000);
    } else if (state.mode == TimerMode.countUp) {
      isCountdown = false;
      whenMs = nowMs - (state.focusSecondsElapsed * 1000);
    } else {
      isCountdown = true;
      if (_sessionTargetEndTime != null) {
        whenMs = _sessionTargetEndTime!.millisecondsSinceEpoch;
      } else {
        whenMs = nowMs + (state.remainingSeconds * 1000);
      }
    }

    final title = isBreak
        ? (state.isLongBreak ? 'Long Break' : 'Recharge Break')
        : (state.topicTitle.trim().isNotEmpty &&
                state.topicTitle != 'Select a task or mode to start'
            ? state.topicTitle.trim()
            : 'General Focus');

    final subtitle = isBreak
        ? (state.isLongBreak ? 'Recharging between cycles' : 'Resting (Count-up)')
        : (state.subjectName.isNotEmpty &&
                state.subjectName != 'No Target Selected'
            ? '${state.subjectName} · ${state.mode == TimerMode.pomodoro ? "Pomodoro" : "Count-Up"}'
            : (state.mode == TimerMode.countUp
                ? 'Count-Up Mode'
                : 'Pomodoro Focus'));

    NotificationService.instance.showRealtimeTimerNotification(
      title: title,
      subtitle: subtitle,
      isBreak: isBreak,
      isCountdown: isCountdown,
      whenMillis: whenMs,
      color: isBreak ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
    );
  }

  int _computeRemaining({TimerMode? mode}) {
    final m = mode ?? state.mode;
    switch (m) {
      case TimerMode.pomodoro:
        return state.pomodoroPresetMins * 60;
      case TimerMode.moduleLinked:
        return state.pomodoroPresetMins * 60;
      case TimerMode.countUp:
        return 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    NotificationService.instance.cancelFocusTimerRunning();
    super.dispose();
  }
}
