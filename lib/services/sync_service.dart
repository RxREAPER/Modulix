import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  SyncService._() {
    _initAuthListener();
  }

  void _initAuthListener() {
    try {
      AuthService.instance.authStateChanges.listen((data) {
        if (data.event == AuthChangeEvent.signedOut) {
          stopRealtimeSync();
        }
      });
    } catch (_) {}
  }

  final ValueNotifier<SyncStatus> statusNotifier =
      ValueNotifier<SyncStatus>(SyncStatus.idle);
  SyncStatus get status => statusNotifier.value;

  final ValueNotifier<int> pendingSyncCountNotifier = ValueNotifier<int>(0);
  int get pendingSyncCount => pendingSyncCountNotifier.value;

  DateTime? lastSyncedAt;
  Timer? _debounceTimer;
  bool _isSyncing = false;

  /// Recalculates the number of local items pending upload to cloud
  Future<void> refreshPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMillis = prefs.getInt('modulix_last_synced_at_v1') ?? 0;
      final pending = await DatabaseService.instance.getPendingTimeLogsCount(lastSyncMillis);
      pendingSyncCountNotifier.value = pending;
    } catch (_) {
      pendingSyncCountNotifier.value = 0;
    }
  }

  /// Trigger debounced sync to push local changes to cloud
  void schedulePush(dynamic ref) {
    refreshPendingCount();
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

      AppState workingState;
      try {
        final appStateAsync = ref.read(appStateProvider) as AsyncValue<AppState>?;
        workingState = appStateAsync?.asData?.value ?? StorageService.instance.load();
      } catch (_) {
        workingState = StorageService.instance.load();
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

        workingState = workingState.copyWith(
          doctorName: docName.isNotEmpty ? docName : workingState.doctorName,
          leaderboardDisplayName: displayName ?? workingState.leaderboardDisplayName,
          leaderboardVisible: lbVisible,
          avatarIconId: avatarIcon,
          avatarColorId: avatarColor,
          palettePresetId: palette,
          accentColorId: accent,
          themePref: pref,
          activeEdition: activeEd,
          dayStartHour: startHour,
        );
      } else {
        // First-time profile creation from local guest data
        await client.from('profiles').upsert({
          'id': userId,
          'doctor_name': workingState.doctorName,
          'display_name': workingState.publicDisplayName,
          'leaderboard_visible': workingState.leaderboardVisible,
          'avatar_icon_id': workingState.avatarIconId,
          'avatar_color_id': workingState.avatarColorId,
          'palette_preset_id': workingState.palettePresetId,
          'accent_color_id': workingState.accentColorId,
          'theme_pref': workingState.themePref.name,
          'active_edition': workingState.activeEdition,
          'day_start_hour': workingState.dayStartHour,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // ── 2. SYNC STUDY EDITIONS (COMPLETIONS & STUDY PLAN) ──────────────────
      final remoteEditions = await client
          .from('study_editions')
          .select()
          .eq('user_id', userId);

      final Map<String, EditionState> updatedEditions =
          Map<String, EditionState>.from(workingState.editions);
      final Set<String> dirtyEditionIds = <String>{};

      for (final row in (remoteEditions as List)) {
        final edId = row['edition_id']?.toString() ?? '';
        if (edId.isEmpty) continue;
        final localEd = updatedEditions[edId] ?? const EditionState();

        final remoteCompletedVideos =
            (row['completed_videos'] as Map<String, dynamic>?) ?? {};
        final remoteCompletedQBanks =
            (row['completed_qbanks'] as Map<String, dynamic>?) ?? {};
        final remoteCompletedNotes =
            (row['completed_notes'] as Map<String, dynamic>?) ?? {};
        final remoteDailyHist =
            (row['daily_history'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
                ) ??
                {};
        final remoteBulkChapters =
            (row['bulk_completed_chapters'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toSet() ??
                <String>{};
        final remoteQueueBatch =
            (row['queue_batch_video_ids'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                <String>[];

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

        // Bidirectional merge of queued batch video IDs
        final mergedQueue = List<String>.from(localEd.queueBatchVideoIds);
        for (final qId in remoteQueueBatch) {
          if (!mergedQueue.contains(qId)) {
            mergedQueue.add(qId);
          }
        }

        StudyPlan mergedPlan = localEd.plan;
        if (!mergedPlan.isConfigured && row['plan_json'] != null) {
          try {
            mergedPlan = StudyPlan.fromJson(row['plan_json'] as Map<String, dynamic>);
          } catch (_) {}
        }

        final mergedEd = localEd.copyWith(
          completedVideos: mergedVideos,
          completedQBanks: mergedQBanks,
          completedNotes: mergedNotes,
          dailyHistory: mergedHistory,
          bulkCompletedChapters: mergedBulkChapters,
          queueBatchVideoIds: mergedQueue,
          plan: mergedPlan,
        );

        final hasLocalChanges = localEd.completedVideos.length != remoteCompletedVideos.length ||
            localEd.completedQBanks.length != remoteCompletedQBanks.length ||
            localEd.completedNotes.length != remoteCompletedNotes.length ||
            localEd.bulkCompletedChapters.length != remoteBulkChapters.length ||
            localEd.queueBatchVideoIds.length != remoteQueueBatch.length ||
            (localEd.plan.isConfigured && row['plan_json'] == null);

        if (hasLocalChanges || mergedEd != localEd) {
          dirtyEditionIds.add(edId);
        }

        updatedEditions[edId] = mergedEd;
      }

      // Check local editions that were never recorded remotely
      final remoteEditionIds = (remoteEditions as List)
          .map((r) => r['edition_id']?.toString() ?? '')
          .toSet();
      for (final entry in updatedEditions.entries) {
        if (!remoteEditionIds.contains(entry.key)) {
          if (entry.value.completedVideos.isNotEmpty ||
              entry.value.completedQBanks.isNotEmpty ||
              entry.value.completedNotes.isNotEmpty ||
              entry.value.bulkCompletedChapters.isNotEmpty ||
              entry.value.queueBatchVideoIds.isNotEmpty ||
              entry.value.plan.isConfigured) {
            dirtyEditionIds.add(entry.key);
          }
        }
      }

      // Persist merged local edition state and immediately notify Riverpod
      workingState = workingState.copyWith(
        editions: updatedEditions,
      );
      await StorageService.instance.save(workingState);
      try {
        ref.read(appStateProvider.notifier).applySyncedState(workingState);
      } catch (_) {
        try {
          ref.invalidate(appStateProvider);
        } catch (_) {}
      }

      // High-performance batch upsert: ONLY push dirty / modified editions in a single call
      if (dirtyEditionIds.isNotEmpty) {
        final payloads = dirtyEditionIds.map((edId) {
          final ed = updatedEditions[edId]!;
          return {
            'user_id': userId,
            'edition_id': edId,
            'plan_json': ed.plan.toJson(),
            'completed_videos': ed.completedVideos,
            'completed_qbanks': ed.completedQBanks,
            'completed_notes': ed.completedNotes,
            'daily_history': ed.dailyHistory,
            'bulk_completed_chapters': ed.bulkCompletedChapters,
            'queue_batch_video_ids': ed.queueBatchVideoIds,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          };
        }).toList();

        await client.from('study_editions').upsert(payloads);
      }

      // ── 3. SYNC TIME LOGS (FOCUS SESSIONS) ─────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMillis = prefs.getInt('modulix_last_synced_at_v1') ?? 0;

      // Incremental SQLite query: only load candidate local logs created since last sync window
      final fetchSinceMs = lastSyncMillis > 0
          ? (lastSyncMillis - 60000).clamp(0, double.maxFinite).toInt()
          : 0;

      final candidateLogs = lastSyncMillis > 0
          ? await DatabaseService.instance.getTimeLogsSince(fetchSinceMs)
          : await DatabaseService.instance.getAllTimeLogs();

      var remoteLogsQuery = client.from('time_logs').select().eq('user_id', userId);
      if (lastSyncMillis > 0) {
        // Incremental sync: pull only records within or newer than last sync window
        remoteLogsQuery = remoteLogsQuery.gt('timestamp', fetchSinceMs);
      }
      final remoteLogsRes = await remoteLogsQuery;

      final List<dynamic> remoteRows = (remoteLogsRes as List<dynamic>?) ?? [];
      final remoteRowIds = remoteRows
          .map((r) => r['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // Check which remote IDs already exist in local SQLite without loading all logs
      final existingLocalIds = await DatabaseService.instance.getExistingLogIds(remoteRowIds);

      final List<TimeLog> downloadedLogs = [];
      for (final row in remoteRows) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty || existingLocalIds.contains(id)) continue;
        downloadedLogs.add(TimeLog(
          id: id,
          subjectId: row['subject_id']?.toString() ?? '',
          topicId: row['topic_id']?.toString(),
          topicType: row['topic_type']?.toString() ?? 'standalone',
          topicTitle: row['topic_title']?.toString() ?? '',
          chapterName: row['chapter_name']?.toString() ?? '',
          durationSecs: (row['duration_secs'] as num?)?.toInt() ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (row['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
          ),
        ));
      }
      if (downloadedLogs.isNotEmpty) {
        await DatabaseService.instance.insertTimeLogsBatch(downloadedLogs);
        await ref.read(timeLogsProvider.notifier).reloadFromDatabase();
      }

      // Upload local sessions not yet in the cloud
      final remoteIdsSet = remoteRowIds.toSet();
      final missingRemote = candidateLogs.where((l) => !remoteIdsSet.contains(l.id)).toList();

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

      // Aggregate and sync leaderboard stats to profile via native SQLite engine
      try {
        final startHour = workingState.dayStartHour;
        final todayStart = MetricsService.studyDayStart(startHour);
        final weekStart = MetricsService.studyWeekStart(startHour);
        final monthStart = MetricsService.studyMonthStart(startHour);
        final now = DateTime.now();
        final adjusted = now.subtract(Duration(hours: startHour));
        final dayKey = DateFormat('yyyy-MM-dd').format(adjusted);
        final monthKey = DateFormat('yyyy-MM').format(adjusted);

        final breakdown = await DatabaseService.instance.getStudyTimeBreakdown(
          todayStartMs: todayStart.millisecondsSinceEpoch,
          weekStartMs: weekStart.millisecondsSinceEpoch,
          monthStartMs: monthStart.millisecondsSinceEpoch,
        );

        final totalSecs = breakdown['total'] ?? 0;
        final dailySecs = breakdown['daily'] ?? 0;
        final weeklySecs = breakdown['weekly'] ?? 0;
        final monthlySecs = breakdown['monthly'] ?? 0;

        // Defensive retention: do not downgrade remote total study seconds if higher
        final remoteTotalSecs = (profileRes?['total_study_secs'] as num?)?.toInt() ?? 0;
        final effectiveTotalSecs = math.max(totalSecs, remoteTotalSecs);

        await client.from('profiles').update({
          'doctor_name': workingState.doctorName,
          'display_name': workingState.publicDisplayName,
          'total_study_secs': effectiveTotalSecs,
          'daily_study_secs': dailySecs,
          'weekly_study_secs': weeklySecs,
          'monthly_study_secs': monthlySecs,
          'last_study_day': dayKey,
          'last_study_month': monthKey,
          'leaderboard_visible': workingState.leaderboardVisible,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', userId);
      } catch (e) {
        debugPrint('[SyncService] Leaderboard stats aggregate update: $e');
      }

      // ── 4. SYNC DAILY DESK TASKS ──────────────────────────────────────────
      final dailyState = ref.read(dailyTasksProvider);

      final remoteDailyRes = await client
          .from('daily_tasks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      bool dailyTasksDirty = false;

      if (remoteDailyRes != null) {
        final remoteTasksRaw = remoteDailyRes['tasks_json'] as List<dynamic>? ?? [];
        final remoteCompletedIds =
            (remoteDailyRes['completed_ids'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toSet();
        final remoteDeletedIds =
            (remoteDailyRes['deleted_ids'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toSet();
        final remoteHist =
            (remoteDailyRes['date_history'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
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
        final boundedDeleted = mergedDeleted.length > 100
            ? mergedDeleted.toList().sublist(mergedDeleted.length - 100).toSet()
            : mergedDeleted;
        final deletedJson = jsonEncode(boundedDeleted.toList());
        final histJson = jsonEncode(mergedDailyHist);

        final localTasksJson = jsonEncode(localTasks.map((t) => t.toMap()).toList());
        final localCompletedJson = jsonEncode(localCompleted.toList());

        if (tasksJson != jsonEncode(remoteTasksRaw) ||
            completedJson != jsonEncode(remoteDailyRes['completed_ids']) ||
            boundedDeleted.length != remoteDeletedIds.length ||
            localTasksJson != tasksJson ||
            localCompletedJson != completedJson) {
          dailyTasksDirty = true;
        }

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
      } else {
        dailyTasksDirty = dailyState.tasks.isNotEmpty ||
            dailyState.completedIds.isNotEmpty ||
            dailyState.dateHistory.isNotEmpty;
      }

      // Push final merged tasks back to Supabase only if changes occurred
      if (dailyTasksDirty) {
        final finalDaily = ref.read(dailyTasksProvider);
        final finalLastDate = prefs.getString('modulix_tasks_last_date_v1') ??
            prefs.getString('flowmd_tasks_last_date_v1') ??
            '';
        final boundedFinalDeleted = finalDaily.deletedIds.length > 100
            ? finalDaily.deletedIds.toList().sublist(finalDaily.deletedIds.length - 100).toList()
            : finalDaily.deletedIds.toList();

        await client.from('daily_tasks').upsert({
          'user_id': userId,
          'tasks_json': finalDaily.tasks.map((t) => t.toMap()).toList(),
          'completed_ids': finalDaily.completedIds.toList(),
          'deleted_ids': boundedFinalDeleted,
          'date_history': finalDaily.dateHistory,
          'last_active_date': finalLastDate,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      lastSyncedAt = DateTime.now();
      await prefs.setInt('modulix_last_synced_at_v1', lastSyncedAt!.millisecondsSinceEpoch);
      pendingSyncCountNotifier.value = 0;
      statusNotifier.value = SyncStatus.synced;
      debugPrint('[SyncService] Cloud synchronization completed successfully.');

      // Maintain active Realtime cross-device channel
      startRealtimeSync(ref);

      return true;
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
      statusNotifier.value = SyncStatus.error;
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // ─── REALTIME CROSS-DEVICE SYNCHRONIZATION ─────────────────────────────────

  RealtimeChannel? _realtimeChannel;
  String? _subscribedUserId;
  Timer? _realtimePullDebounce;

  /// Returns true if WebSocket channel for cross-device events is currently active
  bool get isRealtimeActive => _realtimeChannel != null && _subscribedUserId != null;

  /// Starts listening to Supabase Realtime changes for cross-device synchronization
  void startRealtimeSync(dynamic ref) {
    if (!AuthService.instance.isAuthenticated) return;
    final client = AuthService.instance.client;
    final userId = AuthService.instance.currentUserId;
    if (client == null || userId == null || userId.isEmpty) return;

    if (_subscribedUserId == userId && _realtimeChannel != null) {
      return; // Already actively subscribed to current user
    }

    stopRealtimeSync();
    _subscribedUserId = userId;

    try {
      final channel = client.channel('public:user_sync_$userId');
      _realtimeChannel = channel;

      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[SyncService] Realtime profile change: ${payload.eventType}');
          _handleRealtimeProfileUpdate(ref, payload.newRecord);
        },
      );

      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'study_editions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[SyncService] Realtime study_editions change: ${payload.eventType}');
          _triggerDebouncedRealtimePull(ref);
        },
      );

      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'daily_tasks',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[SyncService] Realtime daily_tasks change: ${payload.eventType}');
          _triggerDebouncedRealtimePull(ref);
        },
      );

      channel.subscribe((status, [error]) {
        debugPrint('[SyncService] Realtime channel status: $status ${error ?? ""}');
      });
    } catch (e) {
      debugPrint('[SyncService] Error starting Realtime subscription: $e');
    }
  }

  void _triggerDebouncedRealtimePull(dynamic ref) {
    _realtimePullDebounce?.cancel();
    _realtimePullDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (!_isSyncing) {
        syncFull(ref);
      }
    });
  }

  void _handleRealtimeProfileUpdate(dynamic ref, Map<String, dynamic> row) {
    if (row.isEmpty) return;
    try {
      final docName = row['doctor_name']?.toString();
      final displayName = row['display_name']?.toString();
      final lbVisible = row['leaderboard_visible'] as bool?;
      final avatarIcon = row['avatar_icon_id']?.toString();
      final avatarColor = row['avatar_color_id']?.toString();
      final palette = row['palette_preset_id']?.toString();
      final accent = row['accent_color_id']?.toString();
      final themeStr = row['theme_pref']?.toString();
      final activeEd = row['active_edition']?.toString();
      final startHour = (row['day_start_hour'] as num?)?.toInt();

      ThemePref? pref;
      if (themeStr != null) {
        if (themeStr == 'light') pref = ThemePref.light;
        if (themeStr == 'dark') pref = ThemePref.dark;
        if (themeStr == 'system') pref = ThemePref.system;
      }

      AppState? current;
      try {
        current = ref.read(appStateProvider).value;
      } catch (_) {}
      current ??= StorageService.instance.load();

      final updated = current.copyWith(
        doctorName: (docName != null && docName.isNotEmpty) ? docName : null,
        leaderboardDisplayName: displayName,
        leaderboardVisible: lbVisible,
        avatarIconId: avatarIcon,
        avatarColorId: avatarColor,
        palettePresetId: palette,
        accentColorId: accent,
        themePref: pref,
        activeEdition: activeEd,
        dayStartHour: startHour,
      );

      if (updated != current) {
        unawaited(StorageService.instance.save(updated));
        try {
          ref.read(appStateProvider.notifier).applySyncedState(updated);
        } catch (_) {
          try {
            ref.invalidate(appStateProvider);
          } catch (_) {}
        }
        debugPrint('[SyncService] Realtime profile updated from cross-device event.');
      }
    } catch (e) {
      debugPrint('[SyncService] Error applying realtime profile update: $e');
    }
  }

  /// Stops Realtime subscription and frees active channels
  void stopRealtimeSync() {
    _realtimePullDebounce?.cancel();
    if (_realtimeChannel != null) {
      try {
        AuthService.instance.client?.removeChannel(_realtimeChannel!);
      } catch (_) {}
      _realtimeChannel = null;
    }
    _subscribedUserId = null;
  }
}
