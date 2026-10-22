import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_theme.dart';
import '../models/time_log.dart';
import 'time_log_provider.dart';
import 'app_state_provider.dart';
import 'daily_tasks_provider.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/sync_service.dart';

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
  final TimerThemeData theme;
  final String activeSoundId;
  final bool sessionActive;
  final bool hasTarget;
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
    required this.theme,
    this.activeSoundId = 'none',
    this.sessionActive = false,
    this.hasTarget = false,
    this.keepScreenAwake = true,
  });

  bool get isBreak => phase == TimerPhase.onBreak;
  int get pomodoroMinutes => pomodoroPresetMins;

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
    TimerThemeData? theme,
    String? activeSoundId,
    bool? sessionActive,
    bool? hasTarget,
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
      theme: theme ?? this.theme,
      activeSoundId: activeSoundId ?? this.activeSoundId,
      sessionActive: sessionActive ?? this.sessionActive,
      hasTarget: hasTarget ?? this.hasTarget,
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
  final Ref _ref;
  Timer? _ticker;
  DateTime? _sessionTargetEndTime;
  DateTime? _lastTickWallTime;

  FocusTimerNotifier(this._ref)
      : super(FocusTimerState(theme: kTimerThemes.first)) {
    _loadKeepAwakePreference();
    WidgetsBinding.instance.addObserver(this);
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
    final bool isModule = durationMins != null && durationMins > 0;
    final newMode = isModule ? TimerMode.moduleLinked : state.mode;
    final int nextSeconds;
    if (isModule) {
      nextSeconds = durationMins * 60;
    } else if (newMode == TimerMode.pomodoro) {
      nextSeconds = state.pomodoroPresetMins * 60;
    } else {
      nextSeconds = 0;
    }

    state = state.copyWith(
      hasTarget: true,
      subjectId: subjectId,
      subjectName: subjectName,
      topicId: topicId,
      topicTitle: topicTitle,
      chapterName: chapterName,
      topicType: topicType,
      mode: newMode,
      modulePresetMins: isModule ? durationMins : state.modulePresetMins,
      remainingSeconds: nextSeconds,
    );
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
      state = state.copyWith(isRunning: false);
    } else {
      final newPhase = state.phase == TimerPhase.idle ? TimerPhase.focusing : state.phase;
      final now = DateTime.now();
      int currentRemaining = state.remainingSeconds;
      if (state.mode == TimerMode.pomodoro && currentRemaining == 0) {
        currentRemaining = state.pomodoroPresetMins * 60;
      }

      if (state.mode != TimerMode.countUp && currentRemaining > 0) {
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

        if (state.mode != TimerMode.countUp && state.remainingSeconds > 0) {
          NotificationService.instance.scheduleFocusTimerEnd(
            duration: Duration(seconds: state.remainingSeconds),
            topicTitle: state.topicTitle,
            isBreak: newPhase == TimerPhase.onBreak,
          );
        }
      }
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    }
  }

  void toggleBreak() {
    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    final willBeBreak = state.phase != TimerPhase.onBreak;
    final int nextSeconds;
    if (willBeBreak) {
      nextSeconds = state.mode == TimerMode.pomodoro ? state.pomodoroBreakMins * 60 : state.remainingSeconds;
      state = state.copyWith(
        phase: TimerPhase.onBreak,
        remainingSeconds: nextSeconds,
      );
    } else {
      nextSeconds = _computeRemaining();
      state = state.copyWith(
        phase: TimerPhase.focusing,
        remainingSeconds: nextSeconds,
      );
    }

    final now = DateTime.now();
    _lastTickWallTime = now;
    if (state.mode != TimerMode.countUp && nextSeconds > 0) {
      _sessionTargetEndTime = now.add(Duration(seconds: nextSeconds));
    } else {
      _sessionTargetEndTime = null;
    }

    if (alertsEnabled) {
      NotificationService.instance.cancelFocusTimerEnd();
      if (state.isRunning) {
        _updateRealtimeNotification();

        if (state.mode != TimerMode.countUp && nextSeconds > 0) {
          NotificationService.instance.scheduleFocusTimerEnd(
            duration: Duration(seconds: nextSeconds),
            topicTitle: state.topicTitle,
            isBreak: willBeBreak,
          );
        }
      }
    }
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
    if (state.focusSecondsElapsed == 0) {
      reset();
      return null;
    }

    final isGeneral = !state.hasTarget ||
        state.subjectId.isEmpty ||
        state.topicType == 'standalone' ||
        state.topicType == 'general';

    final effectiveSubjectId = isGeneral ? 'general' : state.subjectId;
    final effectiveTopicType = isGeneral ? 'general' : state.topicType;
    final effectiveTopicTitle =
        state.hasTarget && state.topicTitle.isNotEmpty ? state.topicTitle : 'General Focus';

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
        final deskNotifier = _ref.read(dailyTasksProvider.notifier);
        final deskState = _ref.read(dailyTasksProvider);
        for (final task in deskState.tasks) {
          if (!deskState.completedIds.contains(task.id)) {
            if (task.id == tId ||
                task.id == 'vid_$tId' ||
                task.title.trim().toLowerCase() == state.topicTitle.trim().toLowerCase()) {
              await deskNotifier.markTaskComplete(task.id);
            }
          }
        }
      } else if (state.hasTarget && state.topicTitle.isNotEmpty) {
        final deskNotifier = _ref.read(dailyTasksProvider.notifier);
        final deskState = _ref.read(dailyTasksProvider);
        for (final task in deskState.tasks) {
          if (!deskState.completedIds.contains(task.id)) {
            if (task.title.trim().toLowerCase() == state.topicTitle.trim().toLowerCase()) {
              await deskNotifier.markTaskComplete(task.id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error auto-completing task in timer finish: $e');
    }

    SyncService.instance.schedulePush(_ref);
    return log;
  }

  void reset() {
    _ticker?.cancel();
    _sessionTargetEndTime = null;
    _lastTickWallTime = null;
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();
    state = FocusTimerState(
      theme: state.theme,
      activeSoundId: state.activeSoundId,
      hasTarget: false,
      remainingSeconds: 0,
      keepScreenAwake: state.keepScreenAwake,
    );
  }

  void resetSessionForSameTask() {
    _ticker?.cancel();
    _sessionTargetEndTime = null;
    _lastTickWallTime = null;
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWithWallClock();
    }
  }

  void _syncWithWallClock() {
    if (!state.isRunning) return;

    final now = DateTime.now();
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

        if (state.phase == TimerPhase.onBreak) {
          state = state.copyWith(
            remainingSeconds: remaining,
            breakSecondsElapsed: state.breakSecondsElapsed + safeElapsed,
          );
        } else {
          state = state.copyWith(
            remainingSeconds: remaining,
            focusSecondsElapsed: state.focusSecondsElapsed + safeElapsed,
          );
        }
        _updateRealtimeNotification();
      }
    }
  }

  void _tick() {
    if (!state.isRunning) return;

    final now = DateTime.now();

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
      return;
    }

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
    if (state.phase == TimerPhase.onBreak) {
      state = state.copyWith(
        breakSecondsElapsed: state.breakSecondsElapsed + delta,
        remainingSeconds: remaining,
      );
    } else {
      state = state.copyWith(
        focusSecondsElapsed: state.focusSecondsElapsed + delta,
        remainingSeconds: remaining,
      );
    }
  }

  void _onCountdownComplete() {
    _ticker?.cancel();
    _sessionTargetEndTime = null;
    _lastTickWallTime = null;
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();

    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    final s = state;

    if (s.phase == TimerPhase.onBreak) {
      if (alertsEnabled) {
        NotificationService.instance.showBreakCompleted(topicTitle: s.topicTitle);
      }
      state = s.copyWith(
        isRunning: false,
        remainingSeconds: 0,
      );
    } else {
      if (alertsEnabled) {
        NotificationService.instance.showFocusTimerCompleted(topicTitle: s.topicTitle);
      }
      state = s.copyWith(
        isRunning: false,
        remainingSeconds: 0,
      );

      // Auto-complete module/daily tasks
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
  }

  void _updateRealtimeNotification() {
    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    if (!alertsEnabled || !state.isRunning) return;

    final isBreak = state.phase == TimerPhase.onBreak;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final int whenMs;
    final bool isCountdown;

    if (state.mode == TimerMode.countUp) {
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
        ? 'Recharge Break'
        : (state.topicTitle.trim().isNotEmpty &&
                state.topicTitle != 'Select a task or mode to start'
            ? state.topicTitle.trim()
            : 'General Focus');

    final subtitle = isBreak
        ? 'Taking a short rest'
        : (state.subjectName.isNotEmpty &&
                state.subjectName != 'No Target Selected'
            ? '${state.subjectName} · ${state.mode == TimerMode.pomodoro ? "Pomodoro" : (state.mode == TimerMode.moduleLinked ? "Module Target" : "Count-Up")}'
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
        return state.modulePresetMins * 60;
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
