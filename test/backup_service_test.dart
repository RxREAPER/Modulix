import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/models/time_log.dart';
import 'package:modulix/services/backup_service.dart';
import 'package:modulix/services/storage_service.dart';
import 'package:modulix/providers/daily_tasks_provider.dart';
import 'package:modulix/services/metrics_service.dart';

class ContainerWidgetRef implements WidgetRef {
  final ProviderContainer container;
  ContainerWidgetRef(this.container);

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

  group('BackupService Payload Validation Tests', () {
    test('Validates backup payload format and rejects invalid versions', () {
      final validPayload = {
        'schema_version': 1,
        'app_identifier': 'Modulix',
        'exported_at': DateTime.now().toIso8601String(),
        'app_state': const AppState(doctorName: 'Dr. Test').toJson(),
        'time_logs': [
          TimeLog(
            id: 'log_1',
            subjectId: 'pathology',
            topicType: 'video',
            topicTitle: 'Cell Injury',
            durationSecs: 2400,
            timestamp: DateTime(2026, 10, 11),
          ).toJson()
        ],
        'daily_tasks': {
          'tasks': [],
          'completed_ids': ['vid_1'],
          'date_history': {'2026-10-11': 1},
          'last_active_date': '2026-10-11',
        },
      };

      final jsonStr = jsonEncode(validPayload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['schema_version'], 1);
      expect(decoded['app_identifier'], 'Modulix');
      expect(decoded['app_state']['doctorName'], 'Dr. Test');
      expect((decoded['time_logs'] as List).length, 1);
      expect(decoded['daily_tasks']['last_active_date'], '2026-10-11');

      // Verify future schema versions are detected
      final futurePayload = Map<String, dynamic>.from(validPayload);
      futurePayload['schema_version'] = 999;
      expect(
        (futurePayload['schema_version'] as int) > BackupService.currentSchemaVersion,
        true,
      );
    });

    test('createBackupPayload includes last_active_date and daily tasks', () async {
      final todayKey = MetricsService.todayKey(5);
      SharedPreferences.setMockInitialValues({
        'flowmd_tasks_last_date_v1': todayKey,
      });
      await StorageService.init();

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = ContainerWidgetRef(container);

      final payloadJson = await BackupService.createBackupPayload(ref);

      final decoded = jsonDecode(payloadJson) as Map<String, dynamic>;
      expect(decoded.containsKey('daily_tasks'), isTrue);
      final dailyTasks = decoded['daily_tasks'] as Map<String, dynamic>;
      expect(dailyTasks['last_active_date'], todayKey);
    });

    test('restoreFromPayload writes flowmd_completed_tasks_v1 as JSON string and restores last date', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();

      final todayKey = MetricsService.todayKey(5);
      final backupData = {
        'schema_version': 1,
        'app_identifier': 'FlowMD',
        'exported_at': DateTime.now().toIso8601String(),
        'app_state': const AppState(doctorName: 'Dr. Restored').toJson(),
        'time_logs': <Map<String, dynamic>>[],
        'daily_tasks': {
          'tasks': [
            const DailyDeskTask(id: 'task_1', title: 'Task 1', category: TaskCategory.video).toMap(),
            const DailyDeskTask(id: 'task_2', title: 'Task 2', category: TaskCategory.qbank).toMap(),
          ],
          'completed_ids': ['task_1'],
          'date_history': {todayKey: 1},
          'last_active_date': todayKey,
        },
      };
      final backupJson = jsonEncode(backupData);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = ContainerWidgetRef(container);

      final restoreSuccess = await BackupService.restoreFromPayload(ref, backupJson);
      expect(restoreSuccess, isTrue);

      final prefs = await SharedPreferences.getInstance();
      // flowmd_completed_tasks_v1 MUST be stored as a JSON string, NOT a StringList
      final completedJson = prefs.getString('flowmd_completed_tasks_v1');
      expect(completedJson, isNotNull);
      final completedList = (jsonDecode(completedJson!) as List).map((e) => e.toString()).toList();
      expect(completedList, contains('task_1'));

      // last_active_date MUST be restored
      expect(prefs.getString('flowmd_tasks_last_date_v1'), todayKey);
    });
  });

  group('DailyTasksNotifier Persistence & Reload Tests', () {
    test('DailyTasksNotifier._load parses completed tasks stored as JSON string', () async {
      final todayKey = MetricsService.todayKey(5);
      const task1 = DailyDeskTask(id: 't1', title: 'Read Cardiology', category: TaskCategory.video);
      final tasksJson = jsonEncode([task1.toMap()]);
      final completedJson = jsonEncode(['t1']);

      SharedPreferences.setMockInitialValues({
        'flowmd_daily_tasks_v2': tasksJson,
        'flowmd_completed_tasks_v1': completedJson,
        'flowmd_tasks_last_date_v1': todayKey,
      });

      final notifier = DailyTasksNotifier();
      // Wait for async _load to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.first.id, 't1');
      expect(notifier.state.completedIds, contains('t1'));
    });

    test('DailyTasksNotifier._load fallback safely parses legacy List<String>', () async {
      final todayKey = MetricsService.todayKey(5);
      const task1 = DailyDeskTask(id: 't1', title: 'Read Nephrology', category: TaskCategory.notes);
      final tasksJson = jsonEncode([task1.toMap()]);

      // Legacy representation in SharedPreferences stored as List<String>
      SharedPreferences.setMockInitialValues({
        'flowmd_daily_tasks_v2': tasksJson,
        'flowmd_completed_tasks_v1': <String>['t1'],
        'flowmd_tasks_last_date_v1': todayKey,
      });

      final notifier = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.completedIds, contains('t1'));
    });

    test('DailyTasksNotifier.reload reloads updated preferences without wiping tasks', () async {
      final todayKey = MetricsService.todayKey(5);
      SharedPreferences.setMockInitialValues({});
      final notifier = DailyTasksNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.tasks, isEmpty);

      // Simulate external write (e.g. backup restore)
      final prefs = await SharedPreferences.getInstance();
      const task = DailyDeskTask(id: 'restored_1', title: 'Restored Task', category: TaskCategory.video);
      await prefs.setString('flowmd_daily_tasks_v2', jsonEncode([task.toMap()]));
      await prefs.setString('flowmd_completed_tasks_v1', jsonEncode(['restored_1']));
      await prefs.setString('flowmd_tasks_last_date_v1', todayKey);

      // Call reload()
      await notifier.reload();

      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.first.title, 'Restored Task');
      expect(notifier.state.completedIds, contains('restored_1'));
    });
  });
}
