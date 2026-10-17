import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:modulix/models/time_log.dart';
import 'package:modulix/models/timer_theme.dart';
import 'package:modulix/providers/focus_timer_provider.dart';
import 'package:modulix/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Domain 5: Focus Timer & SQLite Storage Tests', () {
    test('TimeLog serialization roundtrip preserves all fields', () {
      final now = DateTime(2026, 10, 18, 14, 30);
      final log = TimeLog(
        id: 'log_abc_123',
        subjectId: 'anatomy',
        topicId: 'topic_neuro_1',
        topicType: 'video',
        topicTitle: 'Cranial Nerves Overview',
        chapterName: 'Neuroanatomy',
        durationSecs: 1500,
        timestamp: now,
      );

      final json = log.toJson();
      final restored = TimeLog.fromJson(json);

      expect(restored.id, log.id);
      expect(restored.subjectId, log.subjectId);
      expect(restored.topicId, log.topicId);
      expect(restored.topicType, log.topicType);
      expect(restored.topicTitle, log.topicTitle);
      expect(restored.chapterName, log.chapterName);
      expect(restored.durationSecs, log.durationSecs);
      expect(restored.timestamp.millisecondsSinceEpoch, log.timestamp.millisecondsSinceEpoch);
    });

    test('SQLite date range query getTimeLogsBetween filters correctly', () async {
      final db = DatabaseService.instance;
      await db.clearAllTimeLogs();

      final day1 = DateTime(2026, 10, 1, 10, 0);
      final day2 = DateTime(2026, 10, 5, 12, 0);
      final day3 = DateTime(2026, 10, 10, 16, 0);

      await db.insertTimeLog(TimeLog(
        id: 'log_oct_1',
        subjectId: 'pathology',
        topicType: 'notes',
        topicTitle: 'Cell Injury',
        durationSecs: 1200,
        timestamp: day1,
      ));

      await db.insertTimeLog(TimeLog(
        id: 'log_oct_5',
        subjectId: 'pathology',
        topicType: 'notes',
        topicTitle: 'Inflammation',
        durationSecs: 1800,
        timestamp: day2,
      ));

      await db.insertTimeLog(TimeLog(
        id: 'log_oct_10',
        subjectId: 'pharmacology',
        topicType: 'qbank',
        topicTitle: 'Autonomic System',
        durationSecs: 2400,
        timestamp: day3,
      ));

      // Range between Oct 2 and Oct 8 should ONLY return log_oct_5
      final inRange = await db.getTimeLogsBetween(
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 8),
      );

      expect(inRange.length, 1);
      expect(inRange.first.id, 'log_oct_5');
      expect(inRange.first.durationSecs, 1800);
    });

    test('FocusTimerState correctly models phase, target, and remaining seconds', () {
      final state = FocusTimerState(
        theme: kTimerThemes.first,
        phase: TimerPhase.focusing,
        mode: TimerMode.pomodoro,
        remainingSeconds: 1500,
        focusSecondsElapsed: 300,
        hasTarget: true,
        subjectId: 'physiology',
        subjectName: 'Physiology',
        topicTitle: 'Cardiac Cycle',
      );

      expect(state.phase, TimerPhase.focusing);
      expect(state.isBreak, isFalse);
      expect(state.remainingSeconds, 1500);
      expect(state.hasTarget, isTrue);

      final breakState = state.copyWith(
        phase: TimerPhase.onBreak,
        remainingSeconds: 300,
        breakSecondsElapsed: 60,
      );

      expect(breakState.isBreak, isTrue);
      expect(breakState.remainingSeconds, 300);
      expect(breakState.breakSecondsElapsed, 60);
      expect(breakState.subjectName, 'Physiology');
    });
  });
}
