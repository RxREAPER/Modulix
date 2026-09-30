import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/storage_service.dart';

// ─── App State ───────────────────────────────────────────────────────────────

final appStateProvider =
    AsyncNotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

class AppStateNotifier extends AsyncNotifier<AppState> {
  @override
  Future<AppState> build() async {
    return StorageService.instance.load();
  }

  Future<void> _update(AppState Function(AppState) updater) async {
    final current = state.value ?? AppState.empty;
    final updated = updater(current);
    state = AsyncData(updated);
    await StorageService.instance.save(updated);
  }

  // Onboarding
  Future<void> completeOnboarding({
    required String doctorName,
    required String activeEdition,
  }) =>
      _update((s) => s.copyWith(
            onboardingDone: true,
            doctorName: doctorName.trim().isEmpty ? 'Dr' : doctorName.trim(),
            activeEdition: activeEdition,
          ));

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

  // Day start hour
  Future<void> setDayStartHour(int hour) =>
      _update((s) => s.copyWith(dayStartHour: hour));

  // Notifications toggle
  Future<void> setDailyReminder(bool enabled) =>
      _update((s) => s.copyWith(dailyReminderEnabled: enabled));

  // Nori Props & Interactions
  Future<void> setNoriProp(String propId) =>
      _update((s) => s.copyWith(noriPropId: propId));

  Future<void> incrementNoriInteractions() =>
      _update((s) => s.copyWith(noriInteractions: s.noriInteractions + 1));

  // Reset all progress
  Future<void> resetAllProgress() async {
    final current = state.value ?? AppState.empty;
    final clearedEditions = current.editions.map((k, v) => MapEntry(
          k,
          EditionState(plan: v.plan), // preserves configured plan structure but wipes completions & logs
        ));
    final updated = current.copyWith(editions: clearedEditions);
    state = AsyncData(updated);
    await StorageService.instance.save(updated);
  }

  // Plan
  Future<void> updatePlan(StudyPlan plan) =>
      _update((s) => s.updateCurrentEdition((e) => e.copyWith(plan: plan)));

  // Video completion
  Future<void> markVideoComplete(String videoId) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedVideos);
          updated[videoId] = DateTime.now().toIso8601String();
          // Also update daily history
          final today = _todayKey();
          final history = Map<String, int>.from(e.dailyHistory);
          history[today] = (history[today] ?? 0) + 1;
          return e.copyWith(completedVideos: updated, dailyHistory: history);
        }));
  }

  Future<void> markVideoIncomplete(String videoId) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedVideos);
          final wasCompleted = updated.remove(videoId) != null;
          // Decrement daily history
          if (wasCompleted) {
            final today = _todayKey();
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
  }

  // Notes completion
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
  }

  // Bulk chapter completion
  Future<void> bulkCompleteChapter(
      String chapterName, List<String> videoIds) async {
    await _update((s) => s.updateCurrentEdition((e) {
          final updated = Map<String, dynamic>.from(e.completedVideos);
          for (final id in videoIds) {
            updated[id] = true; // legacy bulk marker
          }
          final chapters = List<String>.from(e.bulkCompletedChapters);
          if (!chapters.contains(chapterName)) chapters.add(chapterName);
          return e.copyWith(
            completedVideos: updated,
            bulkCompletedChapters: chapters,
          );
        }));
  }

  // Queue batch
  Future<void> setBatch(List<String> videoIds, [List<String> staleIds = const []]) =>
      _update((s) => s.updateCurrentEdition((e) => e.copyWith(
            queueBatchVideoIds: videoIds,
            staleBatchVideoIds: staleIds,
            queueCompletedInBatch: 0,
          )));

  Future<void> incrementBatchCompleted() =>
      _update((s) => s.updateCurrentEdition((e) => e.copyWith(
            queueCompletedInBatch: e.queueCompletedInBatch + 1,
          )));

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

// ─── Theme Mode ──────────────────────────────────────────────────────────────

final themeModeProvider = Provider<ThemeMode>((ref) {
  final appState = ref.watch(appStateProvider);
  return appState.when(
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
    data: (state) => switch (state.themePref) {
      ThemePref.light => ThemeMode.light,
      ThemePref.dark => ThemeMode.dark,
      ThemePref.system => ThemeMode.system,
    },
  );
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
