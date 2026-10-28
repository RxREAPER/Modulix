import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/models/time_log.dart';
import 'package:modulix/services/backup_service.dart';
import 'package:modulix/services/database_service.dart';
import 'package:modulix/services/network_resilience_service.dart';
import 'package:modulix/providers/daily_tasks_provider.dart';

class TestWidgetRef implements WidgetRef {
  final ProviderContainer container;
  TestWidgetRef(this.container);

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  void invalidate(ProviderOrFamily provider) => container.invalidate(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NetworkResilienceService Tests', () {
    test('checkConnectivity returns true when probe succeeds', () async {
      final service = NetworkResilienceService.instance;
      service.customProbe = () async => true;
      final result = await service.checkConnectivity();
      expect(result, isTrue);
    });

    test('checkConnectivity returns false when probe throws or fails', () async {
      final service = NetworkResilienceService.instance;
      service.customProbe = () async => throw Exception('Socket timeout');
      final result = await service.checkConnectivity();
      expect(result, isFalse);
    });

    test('calculateBackoff produces exponential backoff within bounds', () {
      final service = NetworkResilienceService.instance;
      expect(service.calculateBackoff(0), Duration.zero);

      final b1 = service.calculateBackoff(1, baseSeconds: 2, maxSeconds: 30);
      expect(b1.inSeconds, 2);
      expect(b1.inMilliseconds, inInclusiveRange(2000, 2500));

      final b2 = service.calculateBackoff(2, baseSeconds: 2, maxSeconds: 30);
      expect(b2.inSeconds, 4);
      expect(b2.inMilliseconds, inInclusiveRange(4000, 4500));

      final b3 = service.calculateBackoff(3, baseSeconds: 2, maxSeconds: 30);
      expect(b3.inSeconds, 8);
      expect(b3.inMilliseconds, inInclusiveRange(8000, 8500));

      final bMax = service.calculateBackoff(10, baseSeconds: 2, maxSeconds: 30);
      expect(bMax.inSeconds, 30);
    });
  });

  group('BackupService Cloud Vault & Compression Tests', () {
    test('GZip compression and decompression round-trip preserves JSON integrity', () async {
      final container = ProviderContainer();
      final ref = TestWidgetRef(container);

      // Create payload & test compression directly
      final originalPayload = await BackupService.createBackupPayload(ref);
      final directCompressed = gzip.encode(utf8.encode(originalPayload));
      final decompressedString = BackupService.decompressBackupBytes(directCompressed);
      expect(decompressedString, equals(originalPayload));

      // Test createCompressedBackupBytes method
      final compressedBytes = await BackupService.createCompressedBackupBytes(ref);
      expect(compressedBytes, isNotEmpty);
      expect(compressedBytes.length, lessThan(utf8.encode(originalPayload).length));

      final decodedFromService = jsonDecode(BackupService.decompressBackupBytes(compressedBytes)) as Map<String, dynamic>;
      expect(decodedFromService['app_identifier'], equals('Modulix'));
      expect(decodedFromService['schema_version'], equals(1));
      expect(decodedFromService['app_state'], isNotNull);
    });

    test('Compact JSON payload creates smaller byte size than formatted JSON', () async {
      final container = ProviderContainer();
      final ref = TestWidgetRef(container);

      final compact = await BackupService.createBackupPayload(ref, formatted: false);
      final formatted = await BackupService.createBackupPayload(ref, formatted: true);

      expect(compact.length, lessThan(formatted.length));
      expect(compact.contains('\n'), isFalse);
    });

    test('CloudSnapshot formattedSize formats byte ranges correctly', () {
      const s1 = CloudSnapshot(name: 's1', path: 'p1', sizeBytes: 512);
      expect(s1.formattedSize, '512 B');

      const s2 = CloudSnapshot(name: 's2', path: 'p2', sizeBytes: 15360); // 15 KB
      expect(s2.formattedSize, '15.0 KB');

      const s3 = CloudSnapshot(name: 's3', path: 'p3', sizeBytes: 2621440); // 2.5 MB
      expect(s3.formattedSize, '2.5 MB');
    });
  });

  group('Daily Tasks Tombstone Elimination Tests', () {
    test('Removing a task records its ID in deletedIds and persists tombstone', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      const task1 = DailyDeskTask(id: 'task_alpha', title: 'Task Alpha', category: TaskCategory.video);
      const task2 = DailyDeskTask(id: 'task_beta', title: 'Task Beta', category: TaskCategory.qbank);
      await notifier.setTasks([task1, task2]);

      expect(notifier.state.tasks.length, 2);
      expect(notifier.state.deletedIds, isEmpty);

      // Remove task1
      await notifier.removeTaskAt(0);
      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.first.id, 'task_beta');
      expect(notifier.state.deletedIds, contains('task_alpha'));

      // Check SharedPreferences tombstone persistence
      final prefs = await SharedPreferences.getInstance();
      final storedTombstones = prefs.getString('modulix_deleted_tasks_v1');
      expect(storedTombstones, isNotNull);
      final decodedList = (jsonDecode(storedTombstones!) as List).map((e) => e.toString()).toList();
      expect(decodedList, contains('task_alpha'));
    });

    test('mergeTombstones purges matching tasks and prevents resurrection', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      const taskA = DailyDeskTask(id: 'task_a', title: 'Task A', category: TaskCategory.video);
      const taskB = DailyDeskTask(id: 'task_b', title: 'Task B', category: TaskCategory.notes);
      await notifier.setTasks([taskA, taskB]);

      // Simulate incoming remote tombstones from another device
      await notifier.mergeTombstones({'task_a'});

      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.first.id, 'task_b');
      expect(notifier.state.deletedIds, contains('task_a'));
    });

    test('clearTasks records tombstones for all cleared tasks', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      const task1 = DailyDeskTask(id: 'task_1', title: 'Task 1', category: TaskCategory.video);
      const task2 = DailyDeskTask(id: 'task_2', title: 'Task 2', category: TaskCategory.general);
      await notifier.setTasks([task1, task2]);

      await notifier.clearTasks();
      expect(notifier.state.tasks, isEmpty);
      expect(notifier.state.deletedIds, containsAll(['task_1', 'task_2']));
    });

    test('mergeTombstones bounds deletedIds set to maximum 100 entries', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final largeTombstones = List.generate(150, (i) => 'old_task_$i').toSet();
      await notifier.mergeTombstones(largeTombstones);

      expect(notifier.state.deletedIds.length, 100);
      expect(notifier.state.deletedIds, contains('old_task_149'));
    });
  });

  group('DatabaseService Incremental Sync Query Tests', () {
    late Database testDb;

    setUp(() async {
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 4,
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
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_time_logs_timestamp ON time_logs(timestamp)');
        },
      );
      DatabaseService.instance.setTestDatabase(testDb);
    });

    tearDown(() async {
      await testDb.close();
      DatabaseService.instance.setTestDatabase(null);
    });

    test('getTimeLogsSince filters logs by timestamp and preserves order', () async {
      final log1 = TimeLog(
        id: 'l1',
        subjectId: 'anat',
        topicType: 'video',
        topicTitle: 'Heart',
        chapterName: 'Thorax',
        durationSecs: 1000,
        timestamp: DateTime.fromMillisecondsSinceEpoch(100000),
      );
      final log2 = TimeLog(
        id: 'l2',
        subjectId: 'phys',
        topicType: 'video',
        topicTitle: 'ECG',
        chapterName: 'CVS',
        durationSecs: 1200,
        timestamp: DateTime.fromMillisecondsSinceEpoch(200000),
      );
      final log3 = TimeLog(
        id: 'l3',
        subjectId: 'bio',
        topicType: 'qbank',
        topicTitle: 'Enzymes',
        chapterName: 'Biochem',
        durationSecs: 1500,
        timestamp: DateTime.fromMillisecondsSinceEpoch(300000),
      );

      await DatabaseService.instance.insertTimeLogsBatch([log1, log2, log3]);

      final logsSince150k = await DatabaseService.instance.getTimeLogsSince(150000);
      expect(logsSince150k.length, 2);
      expect(logsSince150k.map((l) => l.id), equals(['l2', 'l3']));

      final existingIds = await DatabaseService.instance.getExistingLogIds(['l1', 'l3', 'l999']);
      expect(existingIds, equals({'l1', 'l3'}));
    });
  });
}
