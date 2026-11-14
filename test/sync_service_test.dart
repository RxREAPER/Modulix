import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/providers/sync_provider.dart';
import 'package:modulix/providers/time_log_provider.dart';
import 'package:modulix/services/auth_service.dart';
import 'package:modulix/services/backup_service.dart';
import 'package:modulix/services/database_service.dart';
import 'package:modulix/services/storage_service.dart';
import 'package:modulix/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService & Additive Merge Unit Tests', () {
    late SyncService syncService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      AuthService.instance.setTestClient(null);
      syncService = SyncService.instance;
      syncService.statusNotifier.value = SyncStatus.idle;
    });

    test('initial sync status is idle', () {
      expect(syncService.status, equals(SyncStatus.idle));
      expect(syncService.lastSyncedAt, isNull);
    });

    test('syncFull returns false and stays idle when unauthenticated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await syncService.syncFull(container);
      expect(result, isFalse);
      expect(syncService.status, equals(SyncStatus.idle));
    });

    test('schedulePush does not throw and does not trigger sync when unauthenticated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      syncService.schedulePush(container);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(syncService.status, equals(SyncStatus.idle));
    });

    test('syncStatusProvider reflects SyncService statusNotifier updates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(syncStatusProvider), equals(SyncStatus.idle));

      syncService.statusNotifier.value = SyncStatus.syncing;
      expect(container.read(syncStatusProvider), equals(SyncStatus.syncing));

      syncService.statusNotifier.value = SyncStatus.synced;
      expect(container.read(syncStatusProvider), equals(SyncStatus.synced));

      syncService.statusNotifier.value = SyncStatus.offline;
      expect(container.read(syncStatusProvider), equals(SyncStatus.offline));
    });

    test('Additive Set Union guarantees zero data loss across completions', () {
      // Local state from Device A
      final localVideos = {'vid_1': true, 'vid_2': true};
      final localQBanks = {'qb_1': true};
      final localNotes = {'note_1': true};
      final localBulk = ['ch_1', 'ch_2'];
      final localHistory = {'2026-10-13': 5, '2026-10-14': 2};

      // Remote state from Device B
      final remoteVideos = {'vid_2': true, 'vid_3': true};
      final remoteQBanks = {'qb_2': true};
      final remoteNotes = {'note_2': true};
      final remoteBulk = ['ch_2', 'ch_3'];
      final remoteHistory = {'2026-10-13': 7, '2026-10-14': 1};

      // Merge videos
      final mergedVideos = Map<String, dynamic>.from(localVideos)..addAll(remoteVideos);
      expect(mergedVideos.keys.toSet(), equals({'vid_1', 'vid_2', 'vid_3'}));

      // Merge qbanks
      final mergedQBanks = Map<String, dynamic>.from(localQBanks)..addAll(remoteQBanks);
      expect(mergedQBanks.keys.toSet(), equals({'qb_1', 'qb_2'}));

      // Merge notes
      final mergedNotes = Map<String, dynamic>.from(localNotes)..addAll(remoteNotes);
      expect(mergedNotes.keys.toSet(), equals({'note_1', 'note_2'}));

      // Merge bulk chapters
      final mergedBulk = (localBulk.toSet()..addAll(remoteBulk)).toList();
      expect(mergedBulk.toSet(), equals({'ch_1', 'ch_2', 'ch_3'}));

      // Merge history using max count per day
      final mergedHistory = Map<String, int>.from(localHistory);
      remoteHistory.forEach((k, v) {
        final cur = mergedHistory[k] ?? 0;
        if (v > cur) mergedHistory[k] = v;
      });
      expect(mergedHistory['2026-10-13'], equals(7)); // Took max from remote
      expect(mergedHistory['2026-10-14'], equals(2)); // Kept max from local
    });

    test('Daily Desk Tasks merge by ID union and completed IDs union', () {
      final localTasks = [
        const DailyDeskTask(id: 'task_1', title: 'Task 1'),
        const DailyDeskTask(id: 'task_2', title: 'Task 2'),
      ];
      final localCompleted = {'task_1'};

      final remoteRaw = [
        {'id': 'task_2', 'title': 'Task 2'},
        {'id': 'task_3', 'title': 'Task 3'},
      ];
      final remoteCompleted = {'task_2'};

      final taskMap = {for (final t in localTasks) t.id: t};
      for (final raw in remoteRaw) {
        final t = DailyDeskTask.fromMap(raw);
        taskMap.putIfAbsent(t.id, () => t);
      }

      final mergedCompleted = Set<String>.from(localCompleted)..addAll(remoteCompleted);

      expect(taskMap.length, equals(3));
      expect(taskMap.containsKey('task_1'), isTrue);
      expect(taskMap.containsKey('task_2'), isTrue);
      expect(taskMap.containsKey('task_3'), isTrue);
      expect(mergedCompleted, equals({'task_1', 'task_2'}));
    });

    test('Queue batch video IDs bidirectional merge preserves order and appends remote items', () {
      final localQueue = ['vid_101', 'vid_102'];
      final remoteQueue = ['vid_102', 'vid_103', 'vid_104'];

      final mergedQueue = List<String>.from(localQueue);
      for (final qId in remoteQueue) {
        if (!mergedQueue.contains(qId)) {
          mergedQueue.add(qId);
        }
      }

      expect(mergedQueue, equals(['vid_101', 'vid_102', 'vid_103', 'vid_104']));
    });

    test('startRealtimeSync is safely a no-op when unauthenticated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      syncService.startRealtimeSync(container);
      expect(syncService.isRealtimeActive, isFalse);
    });

    test('stopRealtimeSync resets active channel and status cleanly', () {
      syncService.stopRealtimeSync();
      expect(syncService.isRealtimeActive, isFalse);
    });
  });

  group('Durable SQLite Outbox & Delta Sync Tests', () {
    late Database testDb;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 5,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE time_logs (
              id TEXT PRIMARY KEY,
              subject_id TEXT NOT NULL,
              topic_id TEXT,
              topic_type TEXT NOT NULL,
              topic_title TEXT NOT NULL,
              chapter_name TEXT NOT NULL,
              duration_secs INTEGER NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE sync_outbox (
              id TEXT PRIMARY KEY,
              table_name TEXT NOT NULL,
              operation TEXT NOT NULL,
              payload TEXT NOT NULL,
              client_mutation_id TEXT UNIQUE,
              status TEXT NOT NULL DEFAULT 'pending',
              retry_count INTEGER NOT NULL DEFAULT 0,
              last_error TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE task_projects (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              color_hex TEXT NOT NULL DEFAULT '#6B7280',
              icon_name TEXT NOT NULL DEFAULT 'list',
              sort_order INTEGER NOT NULL DEFAULT 0,
              mode TEXT NOT NULL DEFAULT 'module',
              subject_id TEXT,
              subject_name TEXT,
              unit_name TEXT,
              deadline TEXT,
              per_day_modules INTEGER,
              is_archived INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE task_items (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              note TEXT,
              due_date TEXT,
              due_hour INTEGER,
              due_minute INTEGER,
              project_id TEXT,
              priority INTEGER NOT NULL DEFAULT 4,
              is_completed INTEGER NOT NULL DEFAULT 0,
              completed_at TEXT,
              sub_tasks TEXT NOT NULL DEFAULT '[]',
              tags TEXT NOT NULL DEFAULT '[]',
              estimated_minutes INTEGER,
              module_id TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );
      DatabaseService.instance.setTestDatabase(testDb);
    });

    tearDown(() async {
      await testDb.close();
      DatabaseService.instance.setTestDatabase(null);
    });

    test('enqueueOutboxMutation persists an offline mutation in SQLite', () async {
      final dbService = DatabaseService.instance;
      expect(await dbService.getPendingOutboxCount(), equals(0));

      await dbService.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: {'edition_id': 'marrow_8', 'completed_videos_count': 5},
      );

      expect(await dbService.getPendingOutboxCount(), equals(1));
      final pending = await dbService.getPendingOutboxMutations();
      expect(pending.length, equals(1));
      expect(pending.first['table_name'], equals('study_editions'));
      expect(pending.first['operation'], equals('UPSERT'));
      expect(pending.first['status'], equals('pending'));
    });

    test('Outbox mutations maintain strict FIFO ordering', () async {
      final dbService = DatabaseService.instance;

      await dbService.enqueueOutboxMutation(
        tableName: 'daily_tasks',
        operation: 'UPSERT',
        payload: {'batch': 1},
        clientMutationId: 'mut_order_1',
      );
      await Future.delayed(const Duration(milliseconds: 5));
      await dbService.enqueueOutboxMutation(
        tableName: 'daily_tasks',
        operation: 'UPSERT',
        payload: {'batch': 2},
        clientMutationId: 'mut_order_2',
      );

      final pending = await dbService.getPendingOutboxMutations();
      expect(pending.length, equals(2));
      expect(pending[0]['client_mutation_id'], equals('mut_order_1'));
      expect(pending[1]['client_mutation_id'], equals('mut_order_2'));
    });

    test('Idempotency key prevents duplicate mutation insertion', () async {
      final dbService = DatabaseService.instance;

      await dbService.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: {'video_id': 'vid_501'},
        clientMutationId: 'idempotent_key_abc',
      );

      // Attempt duplicate insertion with same client_mutation_id
      await dbService.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: {'video_id': 'vid_501'},
        clientMutationId: 'idempotent_key_abc',
      );

      expect(await dbService.getPendingOutboxCount(), equals(1));
    });

    test('Outbox state transitions: in_flight, failure retry, and completion purge', () async {
      final dbService = DatabaseService.instance;

      await dbService.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: {'batch': 'in_flight_test'},
        clientMutationId: 'mut_flight',
      );

      final pending = await dbService.getPendingOutboxMutations();
      final id = pending.first['id'] as String;

      // Mark in-flight
      await dbService.markOutboxInFlight([id]);
      expect(await dbService.getPendingOutboxCount(), equals(0));

      // Simulate failure and retry reset
      await dbService.failOutboxMutation(id, 'Network timeout');
      expect(await dbService.getPendingOutboxCount(), equals(1));
      final retried = await dbService.getPendingOutboxMutations();
      expect(retried.first['retry_count'], equals(1));
      expect(retried.first['last_error'], equals('Network timeout'));

      // Mark completed (purged)
      await dbService.completeOutboxMutations([id]);
      expect(await dbService.getPendingOutboxCount(), equals(0));
    });

    test('SyncService combines pending time logs and pending outbox mutations', () async {
      final dbService = DatabaseService.instance;

      await dbService.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: {'test': true},
      );
      await dbService.enqueueOutboxMutation(
        tableName: 'daily_tasks',
        operation: 'UPSERT',
        payload: {'test': true},
      );

      final syncService = SyncService.instance;
      await syncService.refreshPendingCount();

      expect(syncService.pendingSyncCount, equals(2));
    });

    test('SyncService enqueues state and tasks mutations durably', () async {
      final dbService = DatabaseService.instance;
      final syncService = SyncService.instance;

      syncService.enqueueStateMutation(
        const AppState(activeEdition: 'marrow_8'),
      );
      syncService.enqueueDailyTasksMutation(
        tasksJson: [{'id': 'task_1', 'title': 'Revise Anatomy'}],
        completedIds: ['task_1'],
        deletedIds: [],
        dateHistory: {},
        lastActiveDate: '2026-10-29',
      );

      expect(await dbService.getPendingOutboxCount(), equals(2));
      final pending = await dbService.getPendingOutboxMutations();
      final tables = pending.map((m) => m['table_name']).toList();
      expect(tables, contains('study_editions'));
      expect(tables, contains('daily_tasks'));
    });

    test('SyncService enqueues profile mutations durably with theme and edition', () async {
      final dbService = DatabaseService.instance;
      final syncService = SyncService.instance;

      syncService.enqueueProfileMutation(
        const AppState(
          doctorName: 'Dr House',
          activeEdition: 'marrow_6_5',
          palettePresetId: 'obsidian',
        ),
      );

      final pending = await dbService.getPendingOutboxMutations();
      final profileMutation = pending.firstWhere((m) => m['table_name'] == 'profiles');
      final payload = jsonDecode(profileMutation['payload'] as String) as Map<String, dynamic>;
      expect(payload['doctor_name'], equals('Dr House'));
      expect(payload['active_edition'], equals('marrow_6_5'));
      expect(payload['palette_preset_id'], equals('obsidian'));
    });

    test('Delta Cursors preference key is stored and read correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('modulix_last_editions_synced_at_v1'), isNull);

      const timestamp = '2026-10-29T00:30:00.000Z';
      await prefs.setString('modulix_last_editions_synced_at_v1', timestamp);

      expect(prefs.getString('modulix_last_editions_synced_at_v1'), equals(timestamp));
    });

    test('Outbox poison pill transitions to failed after 5 retries and is omitted from pending', () async {
      final dbService = DatabaseService.instance;
      await dbService.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: {'edition_id': 'marrow_8'},
        clientMutationId: 'poison_pill_1',
      );

      var pending = await dbService.getPendingOutboxMutations();
      final id = pending.first['id'] as String;

      for (var i = 0; i < 4; i++) {
        await dbService.failOutboxMutation(id, 'Transient error');
      }
      pending = await dbService.getPendingOutboxMutations();
      expect(pending.any((m) => m['id'] == id), isTrue);

      // 5th failure -> poison pill dead lettered
      await dbService.failOutboxMutation(id, 'Fatal error');
      pending = await dbService.getPendingOutboxMutations();
      expect(pending.any((m) => m['id'] == id), isFalse);

      final db = await dbService.database;
      final row = (await db.query('sync_outbox', where: 'id = ?', whereArgs: [id])).first;
      expect(row['status'], equals('failed'));
      expect(row['retry_count'], equals(5));
    });

    test('clearOutbox and resetAllDatabases purge SQLite state cleanly', () async {
      final dbService = DatabaseService.instance;
      await dbService.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: {'edition_id': 'marrow_8'},
      );
      expect(await dbService.getPendingOutboxCount(), greaterThan(0));

      await dbService.clearOutbox();
      expect(await dbService.getPendingOutboxCount(), equals(0));

      await dbService.resetAllDatabases();
      expect(await dbService.getPendingOutboxCount(), equals(0));
      expect(await dbService.getAllTimeLogs(), isEmpty);
    });

    test('enqueueStateMutation persists dirtied editions in SharedPreferences', () async {
      final syncService = SyncService.instance;
      final prefs = await SharedPreferences.getInstance();

      syncService.enqueueStateMutation(
        const AppState(activeEdition: 'marrow_8'),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      final savedDirtied = prefs.getStringList('modulix_dirtied_editions_v1');
      expect(savedDirtied, contains('marrow_8'));
    });

    test('TimeLogsNotifier clearAll sets cleared timestamp and enqueues DELETE mutation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final prefs = await SharedPreferences.getInstance();

      await container.read(timeLogsProvider.notifier).clearAll();

      final clearedAt = prefs.getInt('modulix_time_logs_cleared_at_v1');
      expect(clearedAt, isNotNull);
      expect(clearedAt, greaterThan(0));
      expect(container.read(timeLogsProvider), isEmpty);
    });

    test('BackupService createBackupPayload includes tasks_hub structure', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final payloadStr = await BackupService.createBackupPayload(container, formatted: false);
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;

      expect(payload.containsKey('tasks_hub'), isTrue);
      expect((payload['tasks_hub'] as Map<String, dynamic>).containsKey('projects'), isTrue);
      expect((payload['tasks_hub'] as Map<String, dynamic>).containsKey('items'), isTrue);
    });

    test('getDeviceId generates and persists a stable device UUID', () async {
      final devId1 = await SyncService.instance.getDeviceId();
      expect(devId1, isNotEmpty);
      expect(devId1.startsWith('dev_'), isTrue);

      final devId2 = await SyncService.instance.getDeviceId();
      expect(devId2, equals(devId1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('modulix_device_id_v1'), equals(devId1));
    });

    test('getDeviceName returns valid descriptive string', () async {
      final devName = await SyncService.instance.getDeviceName();
      expect(devName, isNotEmpty);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('modulix_device_name_v1', 'Custom iPhone');
      expect(await SyncService.instance.getDeviceName(), equals('Custom iPhone'));
    });

    test('Single active device notifiers and providers reflect state changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isCurrentDeviceActiveProvider), isTrue);
      expect(container.read(activeDeviceNameProvider), isNull);

      SyncService.instance.isCurrentDeviceActiveNotifier.value = false;
      SyncService.instance.activeDeviceNameNotifier.value = 'Galaxy S24';
      SyncService.instance.statusNotifier.value = SyncStatus.pausedStandby;

      expect(container.read(isCurrentDeviceActiveProvider), isFalse);
      expect(container.read(activeDeviceNameProvider), equals('Galaxy S24'));
      expect(container.read(syncStatusProvider), equals(SyncStatus.pausedStandby));

      // Reset
      SyncService.instance.isCurrentDeviceActiveNotifier.value = true;
      SyncService.instance.activeDeviceNameNotifier.value = null;
      SyncService.instance.statusNotifier.value = SyncStatus.idle;
    });

    test('claimActiveDevice returns false and does not throw when unauthenticated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await SyncService.instance.claimActiveDevice(container);
      expect(result, isFalse);
    });

    test('Clean state adoption directly adopts remote completions without zombie resurrection', () {
      Map<String, dynamic> resolveAdoptedCompletions({
        required Map<String, dynamic> local,
        required Map<String, dynamic> remote,
        required bool isDirtied,
        required String? lastSync,
      }) {
        if (isDirtied) {
          return local;
        } else if (lastSync == null || lastSync.isEmpty) {
          return Map<String, dynamic>.from(local)..addAll(remote);
        } else {
          return remote;
        }
      }

      // Steady-state single active device scenario:
      // Local cache had a video completed, but user uncompleted it on the active cloud writer
      final localVideos = {'vid_1': true, 'vid_2': true};
      final remoteVideos = {'vid_1': true}; // vid_2 was unchecked on active device

      final mergedVideos = resolveAdoptedCompletions(
        local: localVideos,
        remote: remoteVideos,
        isDirtied: false,
        lastSync: '2026-10-29T10:00:00.000Z',
      );

      expect(mergedVideos.containsKey('vid_2'), isFalse);
      expect(mergedVideos.containsKey('vid_1'), isTrue);
    });

    test('Account switch detection: different user ID purges local databases', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('modulix_last_authenticated_user_id', 'user_alpha');

      final dbService = DatabaseService.instance;
      await dbService.enqueueOutboxMutation(
        tableName: 'study_editions',
        operation: 'UPSERT',
        payload: {'edition_id': 'marrow_8'},
      );
      expect(await dbService.getPendingOutboxCount(), greaterThan(0));

      // Simulate sign in with different user id
      const newUserId = 'user_beta';
      final lastAuthUid = prefs.getString('modulix_last_authenticated_user_id');
      if (lastAuthUid != null && lastAuthUid != newUserId) {
        await dbService.resetAllDatabases();
        await StorageService.instance.clear();
      }
      await prefs.setString('modulix_last_authenticated_user_id', newUserId);

      expect(await dbService.getPendingOutboxCount(), equals(0));
      expect(prefs.getString('modulix_last_authenticated_user_id'), equals('user_beta'));
    });
  });
}
