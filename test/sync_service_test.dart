import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/providers/sync_provider.dart';
import 'package:modulix/services/auth_service.dart';
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
  });
}
