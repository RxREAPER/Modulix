import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_theme.dart';
import '../models/time_log.dart';
import 'time_log_provider.dart';
import 'app_state_provider.dart';
import '../services/notification_service.dart';

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
  final int modulePresetMins;
  final TimerThemeData theme;
  final String activeSoundId;
  final bool sessionActive;

  const FocusTimerState({
    this.isRunning = false,
    this.phase = TimerPhase.idle,
    this.mode = TimerMode.pomodoro,
    this.remainingSeconds = 25 * 60,
    this.focusSecondsElapsed = 0,
    this.breakSecondsElapsed = 0,
    this.subjectId = 'general',
    this.subjectName = 'General Focus',
    this.topicId,
    this.topicTitle = 'High-Yield Clinical Study',
    this.chapterName = '',
    this.topicType = 'standalone',
    this.pomodoroPresetMins = 25,
    this.modulePresetMins = 15,
    required this.theme,
    this.activeSoundId = 'none',
    this.sessionActive = false,
  });

  bool get isBreak => phase == TimerPhase.onBreak;

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
    int? modulePresetMins,
    TimerThemeData? theme,
    String? activeSoundId,
    bool? sessionActive,
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
      modulePresetMins: modulePresetMins ?? this.modulePresetMins,
      theme: theme ?? this.theme,
      activeSoundId: activeSoundId ?? this.activeSoundId,
      sessionActive: sessionActive ?? this.sessionActive,
    );
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerState>((ref) {
  return FocusTimerNotifier(ref);
});

class FocusTimerNotifier extends StateNotifier<FocusTimerState> {
  final Ref _ref;
  Timer? _ticker;

  FocusTimerNotifier(this._ref)
      : super(FocusTimerState(theme: kTimerThemes.first));

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
    state = state.copyWith(
      subjectId: subjectId,
      subjectName: subjectName,
      topicId: topicId,
      topicTitle: topicTitle,
      chapterName: chapterName,
      topicType: topicType,
      mode: isModule ? TimerMode.moduleLinked : state.mode,
      modulePresetMins: isModule ? durationMins! : state.modulePresetMins,
      remainingSeconds: isModule ? durationMins! * 60 : _computeRemaining(),
    );
  }

  void changeMode(TimerMode newMode) {
    if (state.isRunning) return;
    state = state.copyWith(mode: newMode, remainingSeconds: _computeRemaining(mode: newMode));
  }

  void setPomodoroPreset(int mins) {
    if (state.isRunning) return;
    state = state.copyWith(
        pomodoroPresetMins: mins, remainingSeconds: mins * 60);
  }

  void setModulePreset(int mins) {
    if (state.isRunning) return;
    final clamped = mins.clamp(5, 300);
    state = state.copyWith(
        modulePresetMins: clamped, remainingSeconds: clamped * 60);
  }

  void startOrPause() {
    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    if (state.isRunning) {
      _ticker?.cancel();
      NotificationService.instance.cancelFocusTimerEnd();
      NotificationService.instance.cancelFocusTimerRunning();
      state = state.copyWith(isRunning: false);
    } else {
      final newPhase = state.phase == TimerPhase.idle ? TimerPhase.focusing : state.phase;
      state = state.copyWith(isRunning: true, sessionActive: true, phase: newPhase);

      if (alertsEnabled) {
        final int remainingMins = (state.remainingSeconds / 60).ceil();
        if (newPhase == TimerPhase.focusing) {
          NotificationService.instance.showFocusTimerStarted(
            topicTitle: state.topicTitle,
            minutes: remainingMins,
          );
        } else if (newPhase == TimerPhase.onBreak) {
          NotificationService.instance.showBreakStarted(
            minutes: remainingMins,
          );
        }

        if (state.mode != TimerMode.countUp && state.remainingSeconds > 0) {
          NotificationService.instance.scheduleFocusTimerEnd(
            duration: Duration(seconds: state.remainingSeconds),
            topicTitle: state.topicTitle,
            isBreak: newPhase == TimerPhase.onBreak,
          );
        }
      }
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void toggleBreak() {
    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    final willBeBreak = state.phase != TimerPhase.onBreak;
    final int nextSeconds;
    if (willBeBreak) {
      nextSeconds = state.mode == TimerMode.pomodoro ? 5 * 60 : state.remainingSeconds;
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

    if (alertsEnabled) {
      final int nextMins = (nextSeconds / 60).ceil();
      if (willBeBreak) {
        NotificationService.instance.showBreakStarted(minutes: nextMins);
      } else {
        NotificationService.instance.showFocusTimerStarted(
          topicTitle: state.topicTitle,
          minutes: nextMins,
        );
      }

      if (state.isRunning && state.mode != TimerMode.countUp && nextSeconds > 0) {
        NotificationService.instance.scheduleFocusTimerEnd(
          duration: Duration(seconds: nextSeconds),
          topicTitle: state.topicTitle,
          isBreak: willBeBreak,
        );
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
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();
    if (state.focusSecondsElapsed == 0) {
      reset();
      return null;
    }

    final log = TimeLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: state.subjectId,
      topicId: state.topicId,
      topicType: state.topicType,
      topicTitle: state.topicTitle,
      chapterName: state.chapterName,
      durationSecs: state.focusSecondsElapsed,
      timestamp: DateTime.now(),
    );

    await _ref.read(timeLogsProvider.notifier).logTime(log);
    return log;
  }

  void reset() {
    _ticker?.cancel();
    NotificationService.instance.cancelFocusTimerEnd();
    NotificationService.instance.cancelFocusTimerRunning();
    state = FocusTimerState(
      theme: state.theme,
      activeSoundId: state.activeSoundId,
      remainingSeconds: state.pomodoroPresetMins * 60,
    );
  }

  void _tick() {
    final alertsEnabled =
        _ref.read(appStateProvider).valueOrNull?.focusTimerAlertsEnabled ?? true;
    final s = state;
    if (s.phase == TimerPhase.onBreak) {
      final newBreak = s.breakSecondsElapsed + 1;
      if (s.mode != TimerMode.countUp && s.remainingSeconds > 1) {
        state = s.copyWith(
            breakSecondsElapsed: newBreak, remainingSeconds: s.remainingSeconds - 1);
      } else if (s.mode != TimerMode.countUp && s.remainingSeconds <= 1) {
        // Break countdown complete
        _ticker?.cancel();
        NotificationService.instance.cancelFocusTimerEnd();
        NotificationService.instance.cancelFocusTimerRunning();
        if (alertsEnabled) {
          NotificationService.instance.showBreakCompleted(topicTitle: s.topicTitle);
        }
        state = s.copyWith(
          isRunning: false,
          breakSecondsElapsed: newBreak,
          remainingSeconds: 0,
        );
      } else {
        state = s.copyWith(breakSecondsElapsed: newBreak);
      }
    } else {
      final newFocus = s.focusSecondsElapsed + 1;
      if (s.mode == TimerMode.countUp) {
        state = s.copyWith(
            focusSecondsElapsed: newFocus, remainingSeconds: s.remainingSeconds + 1);
      } else {
        if (s.remainingSeconds > 1) {
          state = s.copyWith(
              focusSecondsElapsed: newFocus, remainingSeconds: s.remainingSeconds - 1);
        } else {
          // Focus session countdown complete
          _ticker?.cancel();
          NotificationService.instance.cancelFocusTimerEnd();
          NotificationService.instance.cancelFocusTimerRunning();
          if (alertsEnabled) {
            NotificationService.instance.showFocusTimerCompleted(topicTitle: s.topicTitle);
          }
          state = s.copyWith(
            isRunning: false,
            focusSecondsElapsed: newFocus,
            remainingSeconds: 0,
          );
        }
      }
    }
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
    _ticker?.cancel();
    NotificationService.instance.cancelFocusTimerRunning();
    super.dispose();
  }
}
