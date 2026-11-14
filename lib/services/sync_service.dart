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

import 'dart:io' show Platform;

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
  pausedStandby,
}

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._() {
    _initAuthListener();
    _loadPersistedState();
  }

  void _loadPersistedState() {
    SharedPreferences.getInstance().then((prefs) {
      final list = prefs.getStringList('modulix_dirtied_editions_v1');
      if (list != null) {
        _dirtiedEditions.addAll(list);
      }
      _lastLocalProfileMutationMs = prefs.getInt('modulix_local_profile_updated_at') ?? 0;
      _lastLocalDailyTasksMutationMs = prefs.getInt('modulix_local_daily_tasks_updated_at') ?? 0;
      _lastLocalEditionMutationMs = prefs.getInt('modulix_local_edition_updated_at') ?? 0;
    }).catchError((_) {});
  }

  void _initAuthListener() {
    try {
      AuthService.instance.authStateChanges.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          final newUserId = data.session?.user.id;
          if (newUserId != null && newUserId.isNotEmpty) {
            unawaited(SharedPreferences.getInstance().then((prefs) async {
              final lastAuthUid = prefs.getString('modulix_last_authenticated_user_id');
              if (lastAuthUid != null && lastAuthUid != newUserId) {
                // Different account detected on shared device: purge local storage to prevent data leakage
                await DatabaseService.instance.resetAllDatabases();
                await StorageService.instance.clear();
              }
              await prefs.setString('modulix_last_authenticated_user_id', newUserId);
            }));
          }
        } else if (data.event == AuthChangeEvent.signedOut) {
          stopRealtimeSync();
          _lastLocalProfileMutationMs = 0;
          _lastLocalDailyTasksMutationMs = 0;
          _lastLocalEditionMutationMs = 0;
          _dirtiedEditions.clear();
          isCurrentDeviceActive = true;
          isCurrentDeviceActiveNotifier.value = true;
          activeDeviceName = null;
          activeDeviceNameNotifier.value = null;
          lastSyncedAt = null;
          lastSyncedAtNotifier.value = null;
          pendingSyncCountNotifier.value = 0;
          unawaited(SharedPreferences.getInstance().then((prefs) async {
            await prefs.remove('modulix_last_synced_at_v1');
            await prefs.remove('modulix_last_editions_synced_at_v1');
            await prefs.remove('modulix_local_profile_updated_at');
            await prefs.remove('modulix_local_daily_tasks_updated_at');
            await prefs.remove('modulix_local_edition_updated_at');
            await prefs.remove('modulix_dirtied_editions_v1');
            await prefs.remove('modulix_time_logs_cleared_at_v1');
          }));
          unawaited(DatabaseService.instance.clearOutbox());
        }
      });
    } catch (_) {}
  }

  final ValueNotifier<SyncStatus> statusNotifier =
      ValueNotifier<SyncStatus>(SyncStatus.idle);
  SyncStatus get status => statusNotifier.value;

  final ValueNotifier<int> pendingSyncCountNotifier = ValueNotifier<int>(0);
  int get pendingSyncCount => pendingSyncCountNotifier.value;

  final ValueNotifier<DateTime?> lastSyncedAtNotifier =
      ValueNotifier<DateTime?>(null);

  final ValueNotifier<bool> realtimeStatusNotifier =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isCurrentDeviceActiveNotifier =
      ValueNotifier<bool>(true);
  bool isCurrentDeviceActive = true;

  final ValueNotifier<String?> activeDeviceNameNotifier =
      ValueNotifier<String?>(null);
  String? activeDeviceName;

  DateTime? lastSyncedAt;
  Timer? _debounceTimer;
  bool _isSyncing = false;
  int _lastLocalProfileMutationMs = 0;
  int _lastLocalDailyTasksMutationMs = 0;
  int _lastLocalEditionMutationMs = 0;
  final Set<String> _dirtiedEditions = <String>{};

  /// Retrieves or assigns a stable unique installation identifier for this device
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('modulix_device_id_v1');
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(999999)}';
      await prefs.setString('modulix_device_id_v1', id);
    }
    return id;
  }

  /// Retrieves a human-readable device description for display
  Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString('modulix_device_name_v1');
    if (custom != null && custom.isNotEmpty) return custom;

    if (kIsWeb) return 'Web Client';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'iOS Device';
      if (Platform.isLinux) return 'Linux Desk';
      if (Platform.isMacOS) return 'macOS Desk';
      if (Platform.isWindows) return 'Windows Desk';
    } catch (_) {}
    return 'Mobile Device';
  }

  /// Probes roundtrip latency to Supabase in milliseconds
  Future<int?> probeLatency() async {
    try {
      final sw = Stopwatch()..start();
      final ok = await NetworkResilienceService.instance.checkConnectivity();
      sw.stop();
      return ok ? sw.elapsedMilliseconds : null;
    } catch (_) {
      return null;
    }
  }

  /// Recalculates the number of local items pending upload to cloud
  Future<void> refreshPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMillis = prefs.getInt('modulix_last_synced_at_v1') ?? 0;
      if (lastSyncMillis > 0 && lastSyncedAt == null) {
        lastSyncedAt = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
        lastSyncedAtNotifier.value = lastSyncedAt;
      }
      final pendingLogs = await DatabaseService.instance.getPendingTimeLogsCount(lastSyncMillis);
      final pendingOutbox = await DatabaseService.instance.getPendingOutboxCount();
      pendingSyncCountNotifier.value = pendingLogs + pendingOutbox;
    } catch (_) {
      pendingSyncCountNotifier.value = 0;
    }
  }

  /// Enqueues a durable study edition mutation in the SQLite outbox
  void enqueueStateMutation(AppState updated) {
    try {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      _lastLocalEditionMutationMs = nowMs;
      _dirtiedEditions.add(updated.activeEdition);
      unawaited(SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList('modulix_dirtied_editions_v1', _dirtiedEditions.toList());
        prefs.setInt('modulix_local_edition_updated_at', nowMs);
      }));
      final ed = updated.currentEdition;
      final payload = {
        'edition_id': updated.activeEdition,
        'plan_json': ed.plan.toJson(),
        'completed_videos': ed.completedVideos,
        'completed_qbanks': ed.completedQBanks,
        'completed_notes': ed.completedNotes,
        'daily_history': ed.dailyHistory,
        'bulk_completed_chapters': ed.bulkCompletedChapters,
        'queue_batch_video_ids': ed.queueBatchVideoIds,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      DatabaseService.instance.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: payload,
      );
    } catch (_) {}
  }

  /// Enqueues a durable profile & preferences mutation in the SQLite outbox
  void enqueueProfileMutation(AppState updated) {
    try {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      _lastLocalProfileMutationMs = nowMs;
      unawaited(SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('modulix_local_profile_updated_at', nowMs);
      }));

      final payload = {
        'doctor_name': updated.doctorName,
        'display_name': updated.publicDisplayName,
        'leaderboard_visible': updated.leaderboardVisible,
        'avatar_icon_id': updated.avatarIconId,
        'avatar_color_id': updated.avatarColorId,
        'palette_preset_id': updated.palettePresetId,
        'accent_color_id': updated.accentColorId,
        'theme_pref': updated.themePref.name,
        'active_edition': updated.activeEdition,
        'day_start_hour': updated.dayStartHour,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      DatabaseService.instance.enqueueOutboxMutation(
        tableName: 'profiles',
        operation: 'UPSERT',
        payload: payload,
      );
    } catch (_) {}
  }

  /// Enqueues a durable daily tasks mutation in the SQLite outbox
  void enqueueDailyTasksMutation({
    required List<Map<String, dynamic>> tasksJson,
    required List<String> completedIds,
    required List<String> deletedIds,
    required Map<String, dynamic> dateHistory,
    required String lastActiveDate,
  }) {
    try {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      _lastLocalDailyTasksMutationMs = nowMs;
      unawaited(SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('modulix_local_daily_tasks_updated_at', nowMs);
      }));

      final payload = {
        'tasks_json': tasksJson,
        'completed_ids': completedIds,
        'deleted_ids': deletedIds,
        'date_history': dateHistory,
        'last_active_date': lastActiveDate,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      DatabaseService.instance.enqueueOutboxMutation(
        tableName: 'daily_tasks',
        operation: 'UPSERT',
        payload: payload,
      );
    } catch (_) {}
  }

  /// Claims active sync device ownership for this device and triggers a full hydration sync
  Future<bool> claimActiveDevice(dynamic ref) async {
    final auth = AuthService.instance;
    if (!auth.isAuthenticated || auth.client == null) return false;
    try {
      final client = auth.client!;
      final userId = auth.currentUserId!;
      final localDeviceId = await getDeviceId();
      final localDeviceName = await getDeviceName();

      await client.from('profiles').update({
        'active_device_id': localDeviceId,
        'active_device_name': localDeviceName,
        'device_registered_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);

      isCurrentDeviceActive = true;
      isCurrentDeviceActiveNotifier.value = true;
      activeDeviceName = localDeviceName;
      activeDeviceNameNotifier.value = localDeviceName;

      return await syncFull(ref, forceFull: true);
    } catch (e) {
      debugPrint('[SyncService] Failed to claim active device: $e');
      return false;
    }
  }

  /// Trigger debounced sync to push local changes to cloud
  void schedulePush(dynamic ref) {
    if (!isCurrentDeviceActive) {
      statusNotifier.value = SyncStatus.pausedStandby;
      return;
    }
    refreshPendingCount();
    if (!AuthService.instance.isAuthenticated) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      syncFull(ref);
    });
  }

  /// Full bi-directional sync (pull remote changes, merge, push unified state)
  Future<bool> syncFull(dynamic ref, {bool forceFull = false}) async {
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
      final prefs = await SharedPreferences.getInstance();

      final localDeviceId = await getDeviceId();
      final localDeviceName = await getDeviceName();

      // ── 1. SYNC PROFILE & PREFERENCES (FETCH & ACTIVE DEVICE CHECK) ─────
      final profileRes = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileRes != null) {
        final remoteActiveDeviceId = profileRes['active_device_id']?.toString();
        final remoteActiveDeviceName = profileRes['active_device_name']?.toString();

        if (remoteActiveDeviceId != null &&
            remoteActiveDeviceId.isNotEmpty &&
            remoteActiveDeviceId != localDeviceId) {
          // Another device is actively registered as the single cloud writer
          isCurrentDeviceActive = false;
          isCurrentDeviceActiveNotifier.value = false;
          activeDeviceName = remoteActiveDeviceName ?? 'Another Device';
          activeDeviceNameNotifier.value = activeDeviceName;
          statusNotifier.value = SyncStatus.pausedStandby;
          debugPrint('[SyncService] Device standby: Account active on $activeDeviceName ($remoteActiveDeviceId). Push paused.');
          return false;
        }

        // Current device is active (or no device was registered yet)
        isCurrentDeviceActive = true;
        isCurrentDeviceActiveNotifier.value = true;
        activeDeviceName = localDeviceName;
        activeDeviceNameNotifier.value = localDeviceName;

        if (remoteActiveDeviceId != localDeviceId) {
          // Register this device as active
          await client.from('profiles').update({
            'active_device_id': localDeviceId,
            'active_device_name': localDeviceName,
            'device_registered_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', userId);
        }
      } else {
        isCurrentDeviceActive = true;
        isCurrentDeviceActiveNotifier.value = true;
        activeDeviceName = localDeviceName;
        activeDeviceNameNotifier.value = localDeviceName;
      }

      // ── 0. FLUSH DURABLE SQLITE OUTBOX MUTATIONS (LINEAR-STYLE) ─────────
      // Safe to flush because this device is verified active writer
      await _flushOutbox(client, userId);

      AppState workingState;
      try {
        final appStateAsync = ref.read(appStateProvider) as AsyncValue<AppState>?;
        workingState = appStateAsync?.asData?.value ?? StorageService.instance.load();
      } catch (_) {
        workingState = StorageService.instance.load();
      }

      final hasLocalProfileOutbox = await DatabaseService.instance.hasPendingOutboxForTable('profiles');
      final localProfileUpdatedMs = math.max(
        prefs.getInt('modulix_local_profile_updated_at') ?? 0,
        _lastLocalProfileMutationMs,
      );

      if (profileRes != null) {
        final remoteUpdatedStr = profileRes['updated_at']?.toString();
        final remoteUpdatedMs = remoteUpdatedStr != null
            ? (DateTime.tryParse(remoteUpdatedStr)?.millisecondsSinceEpoch ?? 0)
            : 0;

        // If local preferences were modified more recently or equal, OR if we have pending profile mutations in outbox, push local to Supabase
        if (hasLocalProfileOutbox || localProfileUpdatedMs >= remoteUpdatedMs) {
          await client.from('profiles').update({
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
          }).eq('id', userId);
          await prefs.setInt('modulix_local_profile_updated_at', DateTime.now().toUtc().millisecondsSinceEpoch);
        } else if (remoteUpdatedMs > localProfileUpdatedMs) {
          // Remote is legitimately newer (e.g. from web portal or another device)
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
          await StorageService.instance.save(workingState);
          try {
            ref.read(appStateProvider.notifier).applySyncedState(workingState);
          } catch (_) {}
          await prefs.setInt('modulix_local_profile_updated_at', remoteUpdatedMs);
        }
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
          'active_device_id': localDeviceId,
          'active_device_name': localDeviceName,
          'device_registered_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // ── 2. SYNC STUDY EDITIONS (COMPLETIONS & STUDY PLAN) ──────────────────
      final lastEditionsSync = prefs.getString('modulix_last_editions_synced_at_v1');
      var editionsQuery = client
          .from('study_editions')
          .select()
          .eq('user_id', userId);
      if (!forceFull && lastEditionsSync != null && lastEditionsSync.isNotEmpty) {
        editionsQuery = editionsQuery.gt('updated_at', lastEditionsSync);
      }
      final remoteEditions = await editionsQuery;

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

        final isLocallyDirtied = _dirtiedEditions.contains(edId);

        // If local edition was dirtied on this device, respect local unpushed state
        // On initial sync, union local guest progress with remote state
        // Otherwise, directly adopt remote state to permanently prevent zombie resurrected completions
        final Map<String, dynamic> mergedVideos;
        final Map<String, dynamic> mergedQBanks;
        final Map<String, dynamic> mergedNotes;
        final List<String> mergedBulkChapters;

        if (isLocallyDirtied) {
          mergedVideos = localEd.completedVideos;
          mergedQBanks = localEd.completedQBanks;
          mergedNotes = localEd.completedNotes;
          mergedBulkChapters = localEd.bulkCompletedChapters;
        } else if (lastEditionsSync == null || lastEditionsSync.isEmpty) {
          // Initial hydration: union guest state with remote cloud state
          mergedVideos = Map<String, dynamic>.from(localEd.completedVideos)..addAll(remoteCompletedVideos);
          mergedQBanks = Map<String, dynamic>.from(localEd.completedQBanks)..addAll(remoteCompletedQBanks);
          mergedNotes = Map<String, dynamic>.from(localEd.completedNotes)..addAll(remoteCompletedNotes);
          mergedBulkChapters = (localEd.bulkCompletedChapters.toSet()..addAll(remoteBulkChapters)).toList();
        } else {
          // Steady-state clean adoption: remote is authoritative single-writer source of truth
          mergedVideos = remoteCompletedVideos;
          mergedQBanks = remoteCompletedQBanks;
          mergedNotes = remoteCompletedNotes;
          mergedBulkChapters = remoteBulkChapters.toList();
        }

        final mergedHistory = Map<String, int>.from(localEd.dailyHistory);
        remoteDailyHist.forEach((k, v) {
          final cur = mergedHistory[k] ?? 0;
          if (v > cur) mergedHistory[k] = v;
        });

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

      // Check local editions that were never recorded remotely (only on initial or forced full sync)
      final isFullOrInitialSync = forceFull || lastEditionsSync == null || lastEditionsSync.isEmpty;
      if (isFullOrInitialSync) {
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
        _dirtiedEditions.removeAll(dirtyEditionIds);
        await prefs.setStringList('modulix_dirtied_editions_v1', _dirtiedEditions.toList());
      }

      // ── 3. SYNC TIME LOGS (FOCUS SESSIONS) ─────────────────────────────────
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
        final fetchSinceIso = DateTime.fromMillisecondsSinceEpoch(fetchSinceMs).toUtc().toIso8601String();
        remoteLogsQuery = remoteLogsQuery.or('timestamp.gt.$fetchSinceMs,created_at.gt.$fetchSinceIso');
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

        // Defensive retention: do not downgrade remote total study seconds unless explicitly cleared locally
        final remoteTotalSecs = (profileRes?['total_study_secs'] as num?)?.toInt() ?? 0;
        final timeLogsClearedAtMs = prefs.getInt('modulix_time_logs_cleared_at_v1') ?? 0;
        final remoteProfileUpdatedMs = profileRes?['updated_at'] != null
            ? (DateTime.tryParse(profileRes!['updated_at'].toString())?.millisecondsSinceEpoch ?? 0)
            : 0;

        int effectiveTotalSecs;
        if (totalSecs == 0 && timeLogsClearedAtMs > 0 && timeLogsClearedAtMs >= remoteProfileUpdatedMs) {
          effectiveTotalSecs = 0;
        } else {
          effectiveTotalSecs = math.max(totalSecs, remoteTotalSecs);
        }

        await client.from('profiles').update({
          'total_study_secs': effectiveTotalSecs,
          'daily_study_secs': dailySecs,
          'weekly_study_secs': weeklySecs,
          'monthly_study_secs': monthlySecs,
          'last_study_day': dayKey,
          'last_study_month': monthKey,
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
        final remoteUpdatedStr = remoteDailyRes['updated_at']?.toString();
        final remoteUpdatedMs = remoteUpdatedStr != null
            ? (DateTime.tryParse(remoteUpdatedStr)?.millisecondsSinceEpoch ?? 0)
            : 0;
        final localDailyTasksUpdatedMs = prefs.getInt('modulix_local_daily_tasks_updated_at') ?? _lastLocalDailyTasksMutationMs;

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

        // Timestamp-authoritative completed tasks:
        // If remote is strictly newer (e.g. unchecked/completed on another device), remote completed takes authority!
        // If local is newer or equal, local completed takes authority.
        Set<String> mergedCompleted;
        if (remoteUpdatedMs > localDailyTasksUpdatedMs) {
          mergedCompleted = remoteCompletedIds.where((id) => !mergedDeleted.contains(id)).toSet();
        } else {
          final localTaskIds = localTasks.map((t) => t.id).toSet();
          final newlyDiscoveredRemoteCompleted =
              remoteCompletedIds.where((id) => !localTaskIds.contains(id));
          mergedCompleted = (Set<String>.from(localCompleted)
                ..addAll(newlyDiscoveredRemoteCompleted))
              .where((id) => !mergedDeleted.contains(id))
              .toSet();
        }

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

        if (remoteUpdatedMs > localDailyTasksUpdatedMs) {
          await prefs.setInt('modulix_local_daily_tasks_updated_at', remoteUpdatedMs);
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
      lastSyncedAtNotifier.value = lastSyncedAt;
      await prefs.setInt('modulix_last_synced_at_v1', lastSyncedAt!.millisecondsSinceEpoch);
      await prefs.setString('modulix_last_editions_synced_at_v1', lastSyncedAt!.toUtc().toIso8601String());
      await refreshPendingCount();
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

  // ─── DURABLE SQLITE OUTBOX DISPATCHER ──────────────────────────────────────

  Future<void> _flushOutbox(SupabaseClient client, String userId) async {
    try {
      final pendingMutations = await DatabaseService.instance.getPendingOutboxMutations(limit: 50);
      if (pendingMutations.isEmpty) return;

      final ids = pendingMutations
          .map((m) => m['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      await DatabaseService.instance.markOutboxInFlight(ids);

      final completedIds = <String>[];

      for (final mutation in pendingMutations) {
        final id = mutation['id']?.toString() ?? '';
        final table = mutation['table_name']?.toString() ?? '';
        final op = mutation['operation']?.toString() ?? '';
        final payloadRaw = mutation['payload']?.toString() ?? '{}';

        try {
          final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
          final enrichedPayload = Map<String, dynamic>.from(payload);
          if (table != 'profiles' && !enrichedPayload.containsKey('user_id')) {
            enrichedPayload['user_id'] = userId;
          }
          if (table == 'profiles' && !enrichedPayload.containsKey('id')) {
            enrichedPayload['id'] = userId;
          }

          if (op == 'UPSERT') {
            await client.from(table).upsert(enrichedPayload);
          } else if (op == 'DELETE') {
            final filterCol = enrichedPayload['filter_column']?.toString() ?? 'id';
            final filterVal = enrichedPayload['filter_value'];
            await client.from(table).delete().eq(filterCol, filterVal);
          }
          completedIds.add(id);
        } catch (err) {
          debugPrint('[SyncService] Failed to flush outbox mutation $id: $err');
          await DatabaseService.instance.failOutboxMutation(id, err.toString());
        }
      }

      if (completedIds.isNotEmpty) {
        await DatabaseService.instance.completeOutboxMutations(completedIds);
        debugPrint('[SyncService] Flushed ${completedIds.length} durable outbox mutations.');
      }
    } catch (e) {
      debugPrint('[SyncService] Error during outbox flush: $e');
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
          final remoteUpdatedStr = payload.newRecord['updated_at']?.toString();
          final remoteUpdatedMs = remoteUpdatedStr != null
              ? (DateTime.tryParse(remoteUpdatedStr)?.millisecondsSinceEpoch ?? 0)
              : 0;
          if (_lastLocalEditionMutationMs >= remoteUpdatedMs) {
            debugPrint('[SyncService] Realtime study_editions echo ignored (local mutation is newer or matching).');
            return;
          }
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
          final remoteUpdatedStr = payload.newRecord['updated_at']?.toString();
          final remoteUpdatedMs = remoteUpdatedStr != null
              ? (DateTime.tryParse(remoteUpdatedStr)?.millisecondsSinceEpoch ?? 0)
              : 0;
          if (_lastLocalDailyTasksMutationMs >= remoteUpdatedMs) {
            debugPrint('[SyncService] Realtime daily_tasks echo ignored (local mutation is newer or matching).');
            return;
          }
          _triggerDebouncedRealtimePull(ref);
        },
      );

      channel.subscribe((status, [error]) {
        debugPrint('[SyncService] Realtime channel status: $status ${error ?? ""}');
        if (status == RealtimeSubscribeStatus.subscribed) {
          realtimeStatusNotifier.value = true;
        } else if (status == RealtimeSubscribeStatus.closed ||
            status == RealtimeSubscribeStatus.channelError) {
          realtimeStatusNotifier.value = false;
        }
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
      final activeDevId = row['active_device_id']?.toString();
      final activeDevName = row['active_device_name']?.toString();
      if (activeDevId != null && activeDevId.isNotEmpty) {
        unawaited(getDeviceId().then((localId) {
          final isActive = (activeDevId == localId);
          isCurrentDeviceActive = isActive;
          isCurrentDeviceActiveNotifier.value = isActive;
          activeDeviceName = activeDevName ?? (isActive ? 'This Device' : 'Another Device');
          activeDeviceNameNotifier.value = activeDeviceName;
          if (!isActive) {
            statusNotifier.value = SyncStatus.pausedStandby;
          }
        }));
      }

      final remoteUpdatedStr = row['updated_at']?.toString();
      final remoteUpdatedMs = remoteUpdatedStr != null
          ? (DateTime.tryParse(remoteUpdatedStr)?.millisecondsSinceEpoch ?? 0)
          : 0;

      // Guard against echo loops or stale updates:
      // If local modifications occurred at or after remote timestamp, ignore remote update
      if (_lastLocalProfileMutationMs >= remoteUpdatedMs) {
        debugPrint('[SyncService] Realtime echo ignored (local mutation is newer or matching).');
        return;
      }

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
    realtimeStatusNotifier.value = false;
  }
}
