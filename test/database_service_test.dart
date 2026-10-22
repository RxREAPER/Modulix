import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:modulix/models/time_log.dart';
import 'package:modulix/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService Tests', () {
    test('Can insert, retrieve, and filter TimeLogs in SQLite', () async {
      final dbService = DatabaseService.instance;
      await dbService.clearAllTimeLogs();

      final log1 = TimeLog(
        id: 'test_log_1',
        subjectId: 'anatomy',
        topicId: 'vid_1',
        topicType: 'video',
        topicTitle: 'Embryology Intro',
        durationSecs: 1800,
        timestamp: DateTime(2026, 10, 11, 10, 0),
      );

      final log2 = TimeLog(
        id: 'test_log_2',
        subjectId: 'biochemistry',
        topicId: 'vid_2',
        topicType: 'video',
        topicTitle: 'Glycolysis',
        durationSecs: 1200,
        timestamp: DateTime(2026, 10, 11, 12, 0),
      );

      await dbService.insertTimeLog(log1);
      await dbService.insertTimeLog(log2);

      final allLogs = await dbService.getAllTimeLogs();
      expect(allLogs.length, 2);

      final anatomyLogs = await dbService.getTimeLogsForSubject('anatomy');
      expect(anatomyLogs.length, 1);
      expect(anatomyLogs.first.topicTitle, 'Embryology Intro');
      expect(anatomyLogs.first.durationSecs, 1800);

      final biochemLogs = await dbService.getTimeLogsForSubject('biochemistry');
      expect(biochemLogs.length, 1);
      expect(biochemLogs.first.topicTitle, 'Glycolysis');

      await dbService.deleteTimeLog('test_log_1');
      final remaining = await dbService.getAllTimeLogs();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'test_log_2');

      await dbService.clearAllTimeLogs();
      final emptyList = await dbService.getAllTimeLogs();
      expect(emptyList.isEmpty, true);
    });

    test('Can batch insert multiple TimeLogs efficiently', () async {
      final dbService = DatabaseService.instance;
      await dbService.clearAllTimeLogs();

      final batchLogs = List.generate(
        25,
        (i) => TimeLog(
          id: 'batch_log_$i',
          subjectId: i.isEven ? 'pathology' : 'pharmacology',
          topicType: 'qbank',
          topicTitle: 'Question Set #$i',
          durationSecs: 600 + i * 10,
          timestamp: DateTime(2026, 10, 15, 8, i),
        ),
      );

      await dbService.insertTimeLogsBatch(batchLogs);

      final retrieved = await dbService.getAllTimeLogs();
      expect(retrieved.length, 25);

      final pathologyLogs = await dbService.getTimeLogsForSubject('pathology');
      expect(pathologyLogs.length, 13);
      expect(pathologyLogs.first.subjectId, 'pathology');

      final pharmaLogs = await dbService.getTimeLogsForSubject('pharmacology');
      expect(pharmaLogs.length, 12);
    });
  });
}
