import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/models/time_log.dart';
import 'package:modulix/services/backup_service.dart';

void main() {
  group('Domain 7: Backup & Data Sovereignty Tests', () {
    test('Backup JSON payload schema contains required keys and valid types', () {
      const sampleState = AppState(
        doctorName: 'Dr. Modulix',
        onboardingDone: true,
        activeEdition: 'marrow_8',
      );

      final sampleLog = TimeLog(
        id: 'log_test_1',
        subjectId: 'anatomy',
        topicType: 'video',
        topicTitle: 'Embryology Introduction',
        durationSecs: 1800,
        timestamp: DateTime(2026, 10, 18, 12, 0),
      );

      const sampleTask = DailyDeskTask(
        id: 'task_1',
        title: 'Review Thorax notes',
        category: TaskCategory.notes,
      );

      final payload = {
        'schema_version': BackupService.currentSchemaVersion,
        'app_identifier': 'Modulix',
        'exported_at': DateTime.now().toIso8601String(),
        'app_state': sampleState.toJson(),
        'time_logs': [sampleLog.toJson()],
        'daily_tasks': {
          'tasks': [sampleTask.toMap()],
          'completed_ids': ['task_1'],
          'date_history': {'2026-10-18': 1},
          'last_active_date': '2026-10-18',
        },
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['schema_version'], 1);
      expect(decoded['app_identifier'], 'Modulix');
      expect(decoded['exported_at'], isNotEmpty);

      // Verify restored app_state
      final restoredState = AppState.fromJson(decoded['app_state'] as Map<String, dynamic>);
      expect(restoredState.doctorName, 'Dr. Modulix');
      expect(restoredState.onboardingDone, isTrue);
      expect(restoredState.activeEdition, 'marrow_8');

      // Verify restored time_logs
      final logsList = decoded['time_logs'] as List<dynamic>;
      expect(logsList.length, 1);
      final restoredLog = TimeLog.fromJson(logsList.first as Map<String, dynamic>);
      expect(restoredLog.id, 'log_test_1');
      expect(restoredLog.subjectId, 'anatomy');
      expect(restoredLog.durationSecs, 1800);

      // Verify restored daily_tasks
      final tasksMap = decoded['daily_tasks'] as Map<String, dynamic>;
      final rawTasks = tasksMap['tasks'] as List<dynamic>;
      expect(rawTasks.length, 1);
      final restoredTask = DailyDeskTask.fromMap(rawTasks.first as Map<String, dynamic>);
      expect(restoredTask.title, 'Review Thorax notes');
      expect(restoredTask.category, TaskCategory.notes);
      expect(tasksMap['completed_ids'], contains('task_1'));
    });
  });
}
