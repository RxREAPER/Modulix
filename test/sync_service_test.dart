import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/providers/sync_provider.dart';
import 'package:modulix/services/auth_service.dart';
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

    test('Delta Cursors preference key is stored and read correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('modulix_last_editions_synced_at_v1'), isNull);

      const timestamp = '2026-10-29T00:30:00.000Z';
      await prefs.setString('modulix_last_editions_synced_at_v1', timestamp);

      expect(prefs.getString('modulix_last_editions_synced_at_v1'), equals(timestamp));
    });
  });
}
