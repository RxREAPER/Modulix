import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/models/time_log.dart';
import 'package:modulix/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Subject Memoization & Zero-Allocation Accumulator Tests', () {
    test('Subject caches allVideos, allQBanks, allNotes and returns identical instances', () {
      const video1 = Video(
        id: 'v1',
        title: 'Video 1',
        subjectId: 'anatomy',
        chapterName: 'Upper Limb',
        durationMins: 30,
        durationSecs: 0,
        serialNumber: 1,
      );
      const video2 = Video(
        id: 'v2',
        title: 'Video 2',
        subjectId: 'anatomy',
        chapterName: 'Upper Limb',
        durationMins: 45,
        durationSecs: 30,
        serialNumber: 2,
      );
      const video3 = Video(
        id: 'v3',
        title: 'Video 3',
        subjectId: 'anatomy',
        chapterName: 'Lower Limb',
        durationMins: 60,
        durationSecs: 0,
        serialNumber: 3,
      );

      const qb1 = QBankTopic(
        id: 'q1',
        title: 'Brachial Plexus MCQs',
        subjectId: 'anatomy',
        chapterName: 'Upper Limb',
        totalMcqs: 25,
        serialNumber: 1,
      );

      const note1 = NotesItem(
        id: 'n1',
        title: 'Upper Limb Quick Notes',
        subjectId: 'anatomy',
        chapterName: 'Upper Limb',
        pages: 12,
      );

      const ch1 = Chapter(
        name: 'Upper Limb',
        videos: [video1, video2],
        qbanks: [qb1],
        notes: [note1],
      );

      const ch2 = Chapter(
        name: 'Lower Limb',
        videos: [video3],
      );

      const subject = Subject(
        id: 'anatomy',
        name: 'Anatomy',
        displayName: 'Anatomy Display',
        chapters: [ch1, ch2],
        accent: Color(0xFF6366F1),
      );

      // Verify counts and totals
      expect(subject.totalVideos, 3);
      expect(subject.totalQBanks, 1);
      expect(subject.totalNotes, 1);
      expect(subject.totalHours, closeTo((30 + 45.5 + 60) / 60, 0.001));

      // Verify lazy memoization identity (same in-memory instance without re-allocation)
      final firstFetch = subject.allVideos;
      final secondFetch = subject.allVideos;
      expect(identical(firstFetch, secondFetch), isTrue);
      expect(firstFetch.length, 3);

      final firstQBanks = subject.allQBanks;
      final secondQBanks = subject.allQBanks;
      expect(identical(firstQBanks, secondQBanks), isTrue);
      expect(firstQBanks.length, 1);

      final firstNotes = subject.allNotes;
      final secondNotes = subject.allNotes;
      expect(identical(firstNotes, secondNotes), isTrue);
      expect(firstNotes.length, 1);
    });

    test('Video.fromMap and QBankTopic.fromMap handle defensive deserialization', () {
      final video = Video.fromMap({
        'id': 'v_test',
        'title': 'Test Video',
        'durationMins': '25', // numeric string parsed safely to 25
        'durationSecs': 'invalid_num', // non-numeric string safely falls back to 0
        'sNo': 5,
      }, 'biochem');

      expect(video.id, 'v_test');
      expect(video.title, 'Test Video');
      expect(video.durationMins, 25);
      expect(video.durationSecs, 0); // safe fallback, no TypeError
      expect(video.serialNumber, 5);

      final qb = QBankTopic.fromMap({
        'id': 'qb_test',
        'totalMcqs': 30,
        'serialNumber': 12,
      }, 'biochem');

      expect(qb.id, 'qb_test');
      expect(qb.totalMcqs, 30);
      expect(qb.serialNumber, 12);
    });
  });

  group('DatabaseService Aggregation & Optimization Tests', () {
    test('getStudyTimeBreakdown computes native SQLite sums across time windows', () async {
      final dbService = DatabaseService.instance;
      await dbService.clearAllTimeLogs();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final weekStart = todayStart.subtract(const Duration(days: 3));
      final monthStart = todayStart.subtract(const Duration(days: 15));
      final oldStart = todayStart.subtract(const Duration(days: 60));

      final logOld = TimeLog(
        id: 'log_old',
        subjectId: 'anatomy',
        topicId: 'v_old',
        topicType: 'video',
        topicTitle: 'Old Session',
        durationSecs: 1000,
        timestamp: oldStart,
      );

      final logMonth = TimeLog(
        id: 'log_month',
        subjectId: 'physiology',
        topicId: 'v_month',
        topicType: 'video',
        topicTitle: 'Month Session',
        durationSecs: 2000,
        timestamp: monthStart.add(const Duration(hours: 1)),
      );

      final logWeek = TimeLog(
        id: 'log_week',
        subjectId: 'pathology',
        topicId: 'v_week',
        topicType: 'video',
        topicTitle: 'Week Session',
        durationSecs: 3000,
        timestamp: weekStart.add(const Duration(hours: 1)),
      );

      final logToday = TimeLog(
        id: 'log_today',
        subjectId: 'pharmacology',
        topicId: 'v_today',
        topicType: 'video',
        topicTitle: 'Today Session',
        durationSecs: 4000,
        timestamp: todayStart.add(const Duration(hours: 2)),
      );

      await dbService.insertTimeLogsBatch([logOld, logMonth, logWeek, logToday]);

      final breakdown = await dbService.getStudyTimeBreakdown(
        todayStartMs: todayStart.millisecondsSinceEpoch,
        weekStartMs: weekStart.millisecondsSinceEpoch,
        monthStartMs: monthStart.millisecondsSinceEpoch,
      );

      // Total includes all: 1000 + 2000 + 3000 + 4000 = 10000
      expect(breakdown['total'], 10000);
      // Daily includes only logToday: 4000
      expect(breakdown['daily'], 4000);
      // Weekly includes logWeek + logToday: 3000 + 4000 = 7000
      expect(breakdown['weekly'], 7000);
      // Monthly includes logMonth + logWeek + logToday: 2000 + 3000 + 4000 = 9000
      expect(breakdown['monthly'], 9000);

      // Verify getPendingTimeLogsCount
      final totalPending = await dbService.getPendingTimeLogsCount(0);
      expect(totalPending, 4);

      final partialPending = await dbService.getPendingTimeLogsCount(weekStart.millisecondsSinceEpoch);
      expect(partialPending, 2); // logWeek and logToday

      await dbService.clearAllTimeLogs();
    });
  });
}
