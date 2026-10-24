import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/crash_reporting_service.dart';
import '../services/metrics_service.dart';
import '../services/sync_service.dart';
import '../theme/modulix_theme.dart';
import '../theme/app_theme.dart';

// ─── App State ───────────────────────────────────────────────────────────────

final appStateProvider =
    AsyncNotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

class AppStateNotifier extends AsyncNotifier<AppState> {
  @override
  Future<AppState> build() async {
    final loaded = StorageService.instance.load();
    final preset = PalettePreset.fromId(loaded.palettePresetId);
    AppTheme.current = ModulixThemeExtension.from(preset: preset);
    NotificationService.instance.syncAllReminders(loaded);
    // Trigger standard system permission popup ("Allow Modulix to send you notifications?")
    if (loaded.dailyReminderEnabled ||
        loaded.streakReminderEnabled ||
        loaded.moduleTasksReminderEnabled ||
        loaded.focusTimerAlertsEnabled) {
      Future.microtask(() => NotificationService.instance.requestPermissions());
    }
    return loaded;
  }

  Future<void> _update(AppState Function(AppState) updater) async {
    final current = state.value ?? AppState.empty;
    final updated = updater(current);
    state = AsyncData(updated);
    unawaited(StorageService.instance.save(updated));
    SyncService.instance.schedulePush(ref);
  }

  Future<void> updateState(AppState updated) async {
    state = AsyncData(updated);
    unawaited(StorageService.instance.save(updated));
    SyncService.instance.schedulePush(ref);
  }

  Future<void> updateLeaderboardIdentity({
    String? displayName,
    bool? isAnonymous,
    bool? visible,
  }) async {
    await _update((s) => s.copyWith(
          leaderboardDisplayName: displayName,
          isLeaderboardAnonymous: isAnonymous,
          leaderboardVisible: visible,
        ));
  }

  // Onboarding
  Future<void> completeOnboarding({
    required String doctorName,
    required String activeEdition,
    String? avatarColorId,
    String? avatarIconId,
  }) async {
    final cleanName = doctorName.trim().isEmpty ? 'Doctor' : doctorName.trim();
    await _update((s) => s.copyWith(
          onboardingDone: true,
          doctorName: cleanName,
          activeEdition: activeEdition,
          avatarColorId: avatarColorId ?? s.avatarColorId,
          avatarIconId: avatarIconId ?? s.avatarIconId,
        ));
    AnalyticsService.instance.logOnboardingCompleted(
      doctorName: cleanName,
      edition: activeEdition,
    );
    CrashReportingService.instance.setDoctorName(cleanName);
    CrashReportingService.instance.setCustomKey('active_edition', activeEdition);
  }

  // Edition
  Future<void> switchEdition(String editionId) =>
      _update((s) => s.copyWith(activeEdition: editionId));

  // Theme
  Future<void> setTheme(ThemePref pref) =>
      _update((s) => s.copyWith(themePref: pref));

  // Doctor name
  Future<void> setDoctorName(String name) =>
      _update((s) => s.copyWith(doctorName: name));

  // Accent color
  Future<void> setAccentColor(String accentId) =>
      _update((s) => s.copyWith(accentColorId: accentId));

  // Profile avatar customization
  Future<void> setAvatarColor(String colorId) =>
      _update((s) => s.copyWith(avatarColorId: colorId));

  Future<void> setAvatarIcon(String iconId) =>
      _update((s) => s.copyWith(avatarIconId: iconId));

  // Day start hour
  Future<void> setDayStartHour(int hour) =>
      _update((s) => s.copyWith(dayStartHour: hour));

  // Notifications toggles and schedules
  Future<void> setDailyReminder(bool enabled) async {
    await _update((s) => s.copyWith(dailyReminderEnabled: enabled));
    if (state.value != null) {
      await NotificationService.instance.syncAllReminders(state.value!);
    }
  }

  Future<void> setStudyReminderTime(String time) async {
    await _update((s) => s.copyWith(studyReminderTime: time));
    if (state.value != null) {
      await NotificationService.instance.syncAllReminders(state.value!);
    }
  }

  Future<void> setStreakReminder(bool enabled, [String? time]) async {
    await _update((s) => s.copyWith(
          streakReminderEnabled: enabled,
          streakReminderTime: time ?? s.streakReminderTime,
        ));
    if (state.value != null) {
      await NotificationService.instance.syncAllReminders(state.value!);
    }
  }

  Future<void> setModuleTasksReminder(bool enabled, [String? time]) async {
    await _update((s) => s.copyWith(
          moduleTasksReminderEnabled: enabled,
          moduleTasksReminderTime: time ?? s.moduleTasksReminderTime,
        ));
    if (state.value != null) {
      await NotificationService.instance.syncAllReminders(state.value!);
    }
  }

  Future<void> setFocusTimerAlerts(bool enabled) =>
      _update((s) => s.copyWith(focusTimerAlertsEnabled: enabled));

  // Reset all progress
  Future<void> resetAllProgress() async {
    final current = state.value ?? AppState.empty;
    final clearedEditions = current.editions.map((k, v) => MapEntry(
          k,
          EditionState(
              plan: v
                  .plan), // preserves configured plan structure but wipes completions & logs
        ));
    final updated = current.copyWith(editions: clearedEditions);
    state = AsyncData(updated);
    await StorageService.instance.save(updated);
  }

  // Plan
  Future<void> updatePlan(StudyPlan plan) async {
    await _update((s) => s.updateCurrentEdition((e) => e.copyWith(plan: plan)));
    AnalyticsService.instance.logPlanConfigured(
      subject: plan.targetSubject,
      targetDate: plan.targetDate,
      dailyHours: plan.dailyHours,
    );
  }

  // Video completion
  Future<void> markVideoComplete(String videoId) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedVideos);
          if (updated.containsKey(videoId)) return e;
          updated[videoId] = DateTime.now().toIso8601String();
          // Also update daily history
          final today = _todayKey(s.dayStartHour);
          final history = Map<String, int>.from(e.dailyHistory);
          final newCount = (history[today] ?? 0) + 1;
          history[today] = newCount;

          // Check if today's module task goal is crushed
          final target = e.plan.videosPerDay;
          if (target != null && target > 0 && newCount == target) {
            NotificationService.instance.showModuleTaskCompletedNotification(
              subjectName: e.plan.targetSubject.isNotEmpty
                  ? e.plan.targetSubject
                  : 'today\'s module',
              count: newCount,
            );
          }

          return e.copyWith(completedVideos: updated, dailyHistory: history);
        }));
    AnalyticsService.instance.logModuleCompleted(
      subject: state.value?.currentEdition.plan.targetSubject ?? '',
      type: 'video',
      topicId: videoId,
    );
  }

  Future<void> markVideoIncomplete(String videoId) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedVideos);
          final wasCompleted = updated.remove(videoId) != null;
          // Decrement daily history
          if (wasCompleted) {
            final today = _todayKey(s.dayStartHour);
            final history = Map<String, int>.from(e.dailyHistory);
            final cur = history[today] ?? 0;
            if (cur > 1) {
              history[today] = cur - 1;
            } else {
              history.remove(today);
            }
            return e.copyWith(completedVideos: updated, dailyHistory: history);
          }
          return e.copyWith(completedVideos: updated);
        }));
  }

  // QBank completion
  Future<void> markQBankComplete(String qbankId) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedQBanks);
          if (updated.containsKey(qbankId)) return e;
          updated[qbankId] = DateTime.now().toIso8601String();
          return e.copyWith(completedQBanks: updated);
        }));
    AnalyticsService.instance.logModuleCompleted(
      subject: state.value?.currentEdition.plan.targetSubject ?? '',
      type: 'qbank',
      topicId: qbankId,
    );
  }

  Future<void> toggleQBankComplete(String qbankId) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedQBanks);
          if (updated.containsKey(qbankId)) {
            updated.remove(qbankId);
          } else {
            updated[qbankId] = DateTime.now().toIso8601String();
          }
          return e.copyWith(completedQBanks: updated);
        }));
    AnalyticsService.instance.logModuleCompleted(
      subject: state.value?.currentEdition.plan.targetSubject ?? '',
      type: 'qbank',
      topicId: qbankId,
    );
  }

  // Notes completion
  Future<void> markNotesComplete(String noteId) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedNotes);
          if (updated.containsKey(noteId)) return e;
          updated[noteId] = DateTime.now().toIso8601String();
          return e.copyWith(completedNotes: updated);
        }));
    AnalyticsService.instance.logModuleCompleted(
      subject: state.value?.currentEdition.plan.targetSubject ?? '',
      type: 'notes',
      topicId: noteId,
    );
  }

  Future<void> toggleNotesComplete(String noteId) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedNotes);
          if (updated.containsKey(noteId)) {
            updated.remove(noteId);
          } else {
            updated[noteId] = DateTime.now().toIso8601String();
          }
          return e.copyWith(completedNotes: updated);
        }));
    AnalyticsService.instance.logModuleCompleted(
      subject: state.value?.currentEdition.plan.targetSubject ?? '',
      type: 'notes',
      topicId: noteId,
    );
  }

  // Bulk video completion (does not inflate today's study history in Analytics)
  Future<void> markVideosBulk(List<String> videoIds,
      [String? chapterName]) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedVideos);
          final nowStr = DateTime.now().toIso8601String();
          for (final id in videoIds) {
            if (!updated.containsKey(id)) {
              updated[id] = nowStr;
            }
          }
          final chapters = List<String>.from(e.bulkCompletedChapters);
          if (chapterName != null && !chapters.contains(chapterName)) {
            chapters.add(chapterName);
          }
          return e.copyWith(
            completedVideos: updated,
            bulkCompletedChapters: chapters,
          );
        }));
  }

  Future<void> unmarkVideosBulk(List<String> videoIds,
      [String? chapterName]) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedVideos);
          for (final id in videoIds) {
            updated.remove(id);
          }
          final chapters = List<String>.from(e.bulkCompletedChapters);
          if (chapterName != null) {
            chapters.remove(chapterName);
          }
          return e.copyWith(
            completedVideos: updated,
            bulkCompletedChapters: chapters,
          );
        }));
  }

  // Bulk QBank completion
  Future<void> markQBanksBulk(List<String> qbankIds) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedQBanks);
          final nowStr = DateTime.now().toIso8601String();
          for (final id in qbankIds) {
            if (!updated.containsKey(id)) {
              updated[id] = nowStr;
            }
          }
          return e.copyWith(completedQBanks: updated);
        }));
  }

  Future<void> unmarkQBanksBulk(List<String> qbankIds) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedQBanks);
          for (final id in qbankIds) {
            updated.remove(id);
          }
          return e.copyWith(completedQBanks: updated);
        }));
  }

  // Bulk Notes completion
  Future<void> markNotesBulk(List<String> noteIds) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedNotes);
          final nowStr = DateTime.now().toIso8601String();
          for (final id in noteIds) {
            if (!updated.containsKey(id)) {
              updated[id] = nowStr;
            }
          }
          return e.copyWith(completedNotes: updated);
        }));
  }

  Future<void> unmarkNotesBulk(List<String> noteIds) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedNotes);
          for (final id in noteIds) {
            updated.remove(id);
          }
          return e.copyWith(completedNotes: updated);
        }));
  }

  // Legacy Bulk chapter completion
  Future<void> bulkCompleteChapter(
      String chapterName, List<String> videoIds) async {
    await markVideosBulk(videoIds, chapterName);
  }

  // Queue batch
  Future<void> setBatch(List<String> videoIds,
          [List<String> staleIds = const []]) =>
      _update((s) => s.updateCurrentEdition((e) => e.copyWith(
            queueBatchVideoIds: videoIds,
            staleBatchVideoIds: staleIds,
            queueCompletedInBatch: 0,
          )));

  Future<void> incrementBatchCompleted() =>
      _update((s) => s.updateCurrentEdition((e) => e.copyWith(
            queueCompletedInBatch: e.queueCompletedInBatch + 1,
          )));

  // Themes & Appearance
  Future<void> setThemePref(ThemePref pref) =>
      _update((s) => s.copyWith(themePref: pref));

  Future<void> setPalettePreset(String presetId) async {
    final preset = PalettePreset.fromId(presetId);
    AppTheme.current = ModulixThemeExtension.from(preset: preset);
    await _update((s) => s.copyWith(
          palettePresetId: preset.id,
          accentColorId: preset.id,
          themePref: preset.isDark ? ThemePref.dark : ThemePref.light,
        ));
  }

  // Backup
  Future<void> importState(AppState imported) async {
    state = AsyncData(imported);
    await StorageService.instance.save(imported);
  }

  String exportState() {
    final current = state.value ?? AppState.empty;
    return StorageService.instance.export(current);
  }
}

// ─── Theme Data & Appearance ──────────────────────────────────────────────────

@immutable
class ModulixAppThemeData {
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;
  final ModulixThemeExtension extension;
  final String presetId;

  const ModulixAppThemeData({
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
    required this.extension,
    this.presetId = 'paper',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModulixAppThemeData &&
        other.presetId == presetId &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode => Object.hash(presetId, themeMode);
}

/// Backward compatibility alias for FlowMDAppThemeData
typedef FlowMDAppThemeData = ModulixAppThemeData;

final appThemeDataProvider = Provider<ModulixAppThemeData>((ref) {
  final presetId = ref.watch(appStateProvider.select(
    (s) => s.valueOrNull?.palettePresetId ?? 'paper',
  ));
  final themePref = ref.watch(appStateProvider.select(
    (s) => s.valueOrNull?.themePref ?? ThemePref.system,
  ));

  final preset = PalettePreset.fromId(presetId);
  final activeExt = ModulixThemeExtension.from(preset: preset);
  final activeTheme = ModulixThemeFactory.build(preset: preset);
  final themeMode = switch (themePref) {
    ThemePref.light => ThemeMode.light,
    ThemePref.dark => ThemeMode.dark,
    ThemePref.system => preset.isDark ? ThemeMode.dark : ThemeMode.light,
  };

  // Synchronously sync the static bridge on every emission
  AppTheme.current = activeExt;

  return ModulixAppThemeData(
    lightTheme: activeTheme,
    darkTheme: activeTheme,
    themeMode: themeMode,
    extension: activeExt,
    presetId: preset.id,
  );
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final themePref = ref.watch(appStateProvider.select(
    (s) => s.valueOrNull?.themePref ?? ThemePref.system,
  ));
  return switch (themePref) {
    ThemePref.light => ThemeMode.light,
    ThemePref.dark => ThemeMode.dark,
    ThemePref.system => ThemeMode.system,
  };
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _todayKey([int dayStartHour = 5]) => MetricsService.todayKey(dayStartHour);
