import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/daily_desk_task.dart';
import '../models/time_log.dart';
import '../providers/app_state_provider.dart';
import '../providers/daily_tasks_provider.dart';
import '../providers/time_log_provider.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'metrics_service.dart';
import 'network_resilience_service.dart';
import 'storage_service.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._();

  final ValueNotifier<SyncStatus> statusNotifier =
      ValueNotifier<SyncStatus>(SyncStatus.idle);
  SyncStatus get status => statusNotifier.value;

  DateTime? lastSyncedAt;
  Timer? _debounceTimer;
  bool _isSyncing = false;

  /// Trigger debounced sync to push local changes to cloud
  void schedulePush(dynamic ref) {
    if (!AuthService.instance.isAuthenticated) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      syncFull(ref);
    });
  }

  /// Full bi-directional sync (pull remote changes, merge, push unified state)
  Future<bool> syncFull(dynamic ref) async {
    final auth = AuthService.instance;
    if (!auth.isAuthenticated || auth.client == null) {
      statusNotifier.value = SyncStatus.idle;
      return false;
    }

    if (_isSyncing) return false;

    // Hospital-Grade Resilience Check: Active TCP/DNS socket probe
    final isOnline = await NetworkResilienceService.instance.checkConnectivity();
    if (!isOnline) {
      debugPrint('[SyncService] Host probe unreachable (hospital Wi-Fi/offline). Transitioning to offline mode.');
      statusNotifier.value = SyncStatus.offline;
      return false;
    }

    _isSyncing = true;
    statusNotifier.value = SyncStatus.syncing;

    try {
      final client = auth.client!;
      final userId = auth.currentUserId!;

      // ── 1. SYNC PROFILE & PREFERENCES ─────────────────────────────────────
      final profileRes = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      AppState localAppState;
      try {
        final appStateAsync = ref.read(appStateProvider) as AsyncValue<AppState>?;
        localAppState = appStateAsync?.asData?.value ?? StorageService.instance.load();
      } catch (_) {
        localAppState = StorageService.instance.load();
      }

      if (profileRes != null) {
        // Merge remote profile attributes if non-default
        final docName = profileRes['doctor_name'] as String? ?? '';
        final displayName = profileRes['display_name'] as String?;
        final lbVisible = profileRes['leaderboard_visible'] as bool? ?? true;
        final avatarIcon = profileRes['avatar_icon_id'] as String? ?? 'letter';
        final avatarColor = profileRes['avatar_color_id'] as String? ?? 'indigo';
        final palette = profileRes['palette_preset_id'] as String? ?? 'paper';
        final accent = profileRes['accent_color_id'] as String? ?? 'cobalt';
        final themeStr = profileRes['theme_pref'] as String? ?? 'system';
        final activeEd = profileRes['active_edition'] as String? ?? 'marrow_8';
        final startHour = profileRes['day_start_hour'] as int? ?? 5;

        ThemePref pref = ThemePref.system;
        if (themeStr == 'light') pref = ThemePref.light;
        if (themeStr == 'dark') pref = ThemePref.dark;

        final mergedAppState = localAppState.copyWith(
          doctorName: docName.isNotEmpty ? docName : localAppState.doctorName,
          leaderboardDisplayName: displayName ?? localAppState.leaderboardDisplayName,
          leaderboardVisible: lbVisible,
          avatarIconId: avatarIcon,
          avatarColorId: avatarColor,
          palettePresetId: palette,
          accentColorId: accent,
          themePref: pref,
          activeEdition: activeEd,
          dayStartHour: startHour,
        );

        await StorageService.instance.save(mergedAppState);
      } else {
        // First-time profile creation from local guest data
        await client.from('profiles').upsert({
          'id': userId,
          'doctor_name': localAppState.doctorName,
          'display_name': localAppState.publicDisplayName,
          'leaderboard_visible': localAppState.leaderboardVisible,
          'avatar_icon_id': localAppState.avatarIconId,
          'avatar_color_id': localAppState.avatarColorId,
          'palette_preset_id': localAppState.palettePresetId,
          'accent_color_id': localAppState.accentColorId,
          'theme_pref': localAppState.themePref.name,
          'active_edition': localAppState.activeEdition,
          'day_start_hour': localAppState.dayStartHour,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // ── 2. SYNC STUDY EDITIONS (COMPLETIONS & STUDY PLAN) ──────────────────
      final remoteEditions = await client
          .from('study_editions')
          .select()
          .eq('user_id', userId);

      final Map<String, EditionState> updatedEditions =
          Map<String, EditionState>.from(localAppState.editions);

      for (final row in (remoteEditions as List)) {
        final edId = row['edition_id'] as String;
        final localEd = updatedEditions[edId] ?? const EditionState();

        final remoteCompletedVideos =
            (row['completed_videos'] as Map<String, dynamic>?) ?? {};
        final remoteCompletedQBanks =
            (row['completed_qbanks'] as Map<String, dynamic>?) ?? {};
        final remoteCompletedNotes =
            (row['completed_notes'] as Map<String, dynamic>?) ?? {};
        final remoteDailyHist =
            (row['daily_history'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, v as int),
                ) ??
                {};
        final remoteBulkChapters =
            (row['bulk_completed_chapters'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toSet() ??
                <String>{};

        // Additive Union Merging for completions (Progress is NEVER lost)
        final mergedVideos = Map<String, dynamic>.from(localEd.completedVideos)
          ..addAll(remoteCompletedVideos);
        final mergedQBanks = Map<String, dynamic>.from(localEd.completedQBanks)
          ..addAll(remoteCompletedQBanks);
        final mergedNotes = Map<String, dynamic>.from(localEd.completedNotes)
          ..addAll(remoteCompletedNotes);

        final mergedHistory = Map<String, int>.from(localEd.dailyHistory);
        remoteDailyHist.forEach((k, v) {
          final cur = mergedHistory[k] ?? 0;
          if (v > cur) mergedHistory[k] = v;
        });

        final mergedBulkChapters = (localEd.bulkCompletedChapters.toSet()
              ..addAll(remoteBulkChapters))
            .toList();

        StudyPlan mergedPlan = localEd.plan;
        if (!mergedPlan.isConfigured && row['plan_json'] != null) {
          try {
            mergedPlan = StudyPlan.fromJson(row['plan_json'] as Map<String, dynamic>);
          } catch (_) {}
        }

        updatedEditions[edId] = localEd.copyWith(
          completedVideos: mergedVideos,
          completedQBanks: mergedQBanks,
          completedNotes: mergedNotes,
          dailyHistory: mergedHistory,
          bulkCompletedChapters: mergedBulkChapters,
          plan: mergedPlan,
        );
      }

      // Persist merged local edition state
      AppState currentLocal;
      try {
        final latestAsync = ref.read(appStateProvider) as AsyncValue<AppState>?;
        currentLocal = latestAsync?.asData?.value ?? localAppState;
      } catch (_) {
        currentLocal = localAppState;
      }
      final currentLocalWithMergedEditions = currentLocal.copyWith(
        editions: updatedEditions,
      );
      await StorageService.instance.save(currentLocalWithMergedEditions);
      try {
        ref.invalidate(appStateProvider);
      } catch (_) {}

      // Push merged local edition state back to Supabase
      for (final entry in updatedEditions.entries) {
        await client.from('study_editions').upsert({
          'user_id': userId,
          'edition_id': entry.key,
          'plan_json': entry.value.plan.toJson(),
          'completed_videos': entry.value.completedVideos,
          'completed_qbanks': entry.value.completedQBanks,
          'completed_notes': entry.value.completedNotes,
          'daily_history': entry.value.dailyHistory,
          'bulk_completed_chapters': entry.value.bulkCompletedChapters,
          'queue_batch_video_ids': entry.value.queueBatchVideoIds,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // ── 3. SYNC TIME LOGS (FOCUS SESSIONS) ─────────────────────────────────
      final localLogs = await DatabaseService.instance.getAllTimeLogs();
      final localLogMap = {for (final l in localLogs) l.id: l};

      final remoteLogsRes = await client
          .from('time_logs')
          .select()
          .eq('user_id', userId);

      final List<TimeLog> downloadedLogs = [];
      for (final row in (remoteLogsRes as List)) {
        final id = row['id'] as String;
        if (!localLogMap.containsKey(id)) {
          // Download remote session that occurred on another device
          downloadedLogs.add(TimeLog(
            id: id,
            subjectId: row['subject_id'] as String,
            topicId: row['topic_id'] as String?,
            topicType: row['topic_type'] as String,
            topicTitle: row['topic_title'] as String,
            chapterName: row['chapter_name'] as String,
            durationSecs: row['duration_secs'] as int,
            timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
          ));
        }
      }
      if (downloadedLogs.isNotEmpty) {
        await DatabaseService.instance.insertTimeLogsBatch(downloadedLogs);
      }

      // Upload any local sessions not yet in the cloud
      final remoteIds = (remoteLogsRes as List).map((r) => r['id'] as String).toSet();
      final missingRemote = localLogs.where((l) => !remoteIds.contains(l.id)).toList();

      if (missingRemote.isNotEmpty) {
        final payload = missingRemote.map((l) => {
          'id': l.id,
          'user_id': userId,
          'subject_id': l.subjectId,
          'topic_id': l.topicId,
          'topic_type': l.topicType,
          'topic_title': l.topicTitle,
          'chapter_name': l.chapterName,
          'duration_secs': l.durationSecs,
          'timestamp': l.timestamp.millisecondsSinceEpoch,
          'created_at': l.timestamp.toUtc().toIso8601String(),
        }).toList();

        // Chunk upserts in batches of 100 to avoid payload size and connection limits
        const chunkSize = 100;
        for (var i = 0; i < payload.length; i += chunkSize) {
          final end = (i + chunkSize < payload.length) ? i + chunkSize : payload.length;
          final chunk = payload.sublist(i, end);
          await client.from('time_logs').upsert(chunk);
        }
      }
      await ref.read(timeLogsProvider.notifier).reloadFromDatabase();

      // Aggregate and sync leaderboard stats to profile
      try {
        final allLogs = await DatabaseService.instance.getAllTimeLogs();
        final startHour = localAppState.dayStartHour;
        final todayStart = MetricsService.studyDayStart(startHour);
        final dayOfWeek = DateTime.now().weekday;
        final monday = DateTime.now().subtract(Duration(days: dayOfWeek - 1));
        final weekStart = DateTime(monday.year, monday.month, monday.day);

        int totalSecs = 0;
        int dailySecs = 0;
        int weeklySecs = 0;

        for (final l in allLogs) {
          totalSecs += l.durationSecs;
          if (l.timestamp.isAfter(todayStart)) dailySecs += l.durationSecs;
          if (l.timestamp.isAfter(weekStart)) weeklySecs += l.durationSecs;
        }

        await client.from('profiles').update({
          'display_name': localAppState.publicDisplayName,
          'total_study_secs': totalSecs,
          'daily_study_secs': dailySecs,
          'weekly_study_secs': weeklySecs,
          'leaderboard_visible': localAppState.leaderboardVisible,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', userId);
      } catch (e) {
        debugPrint('[SyncService] Leaderboard stats aggregate update: $e');
      }

      // ── 4. SYNC DAILY DESK TASKS ──────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final dailyState = ref.read(dailyTasksProvider);

      final remoteDailyRes = await client
          .from('daily_tasks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (remoteDailyRes != null) {
        final remoteTasksRaw = remoteDailyRes['tasks_json'] as List<dynamic>? ?? [];
        final remoteCompletedIds =
            (remoteDailyRes['completed_ids'] as List<dynamic>? ?? [])
                .map((e) => e as String)
                .toSet();
        final remoteDeletedIds =
            (remoteDailyRes['deleted_ids'] as List<dynamic>? ?? [])
                .map((e) => e as String)
                .toSet();
        final remoteHist =
            (remoteDailyRes['date_history'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, v as int),
                ) ??
                {};
        final remoteLastDate = remoteDailyRes['last_active_date'] as String? ?? '';

        final localTasks = dailyState.tasks;
        final localCompleted = dailyState.completedIds;

        // Union of deleted tombstones to permanently prevent zombie task resurrection
        final mergedDeleted = Set<String>.from(dailyState.deletedIds)..addAll(remoteDeletedIds);

        // Merge task lists by ID, pruning any tasks that have tombstones
        final taskMap = {for (final t in localTasks) t.id: t};
        for (final raw in remoteTasksRaw) {
          if (raw is Map<String, dynamic>) {
            final t = DailyDeskTask.fromMap(raw);
            taskMap.putIfAbsent(t.id, () => t);
          }
        }
        taskMap.removeWhere((id, _) => mergedDeleted.contains(id));

        // Union of completed task IDs, pruning tombstones
        final mergedCompleted = (Set<String>.from(localCompleted)..addAll(remoteCompletedIds))
          ..removeWhere((id) => mergedDeleted.contains(id));

        // Merge history by max count
        final mergedDailyHist = Map<String, int>.from(dailyState.dateHistory);
        remoteHist.forEach((k, v) {
          final cur = mergedDailyHist[k] ?? 0;
          if (v > cur) mergedDailyHist[k] = v;
        });

        final tasksJson = jsonEncode(taskMap.values.map((t) => t.toMap()).toList());
        final completedJson = jsonEncode(mergedCompleted.toList());
        final deletedJson = jsonEncode(mergedDeleted.toList());
        final histJson = jsonEncode(mergedDailyHist);

        await prefs.setString('modulix_daily_tasks_v1', tasksJson);
        await prefs.setString('flowmd_daily_tasks_v2', tasksJson);

        await prefs.setString('modulix_completed_tasks_v1', completedJson);
        await prefs.setString('flowmd_completed_tasks_v1', completedJson);

        await prefs.setString('modulix_deleted_tasks_v1', deletedJson);
        await prefs.setString('flowmd_deleted_tasks_v1', deletedJson);

        await prefs.setString('modulix_tasks_history_v1', histJson);
        await prefs.setString('flowmd_tasks_history_v1', histJson);

        if (remoteLastDate.isNotEmpty) {
          await prefs.setString('modulix_tasks_last_date_v1', remoteLastDate);
          await prefs.setString('flowmd_tasks_last_date_v1', remoteLastDate);
        }

        await ref.read(dailyTasksProvider.notifier).reload();
      }

      // Push final merged tasks back to Supabase
      final finalDaily = ref.read(dailyTasksProvider);
      final finalLastDate = prefs.getString('modulix_tasks_last_date_v1') ??
          prefs.getString('flowmd_tasks_last_date_v1') ??
          '';
      await client.from('daily_tasks').upsert({
        'user_id': userId,
        'tasks_json': finalDaily.tasks.map((t) => t.toMap()).toList(),
        'completed_ids': finalDaily.completedIds.toList(),
        'deleted_ids': finalDaily.deletedIds.toList(),
        'date_history': finalDaily.dateHistory,
        'last_active_date': finalLastDate,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      lastSyncedAt = DateTime.now();
      statusNotifier.value = SyncStatus.synced;
      debugPrint('[SyncService] Cloud synchronization completed successfully.');
      return true;
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
      statusNotifier.value = SyncStatus.error;
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}
