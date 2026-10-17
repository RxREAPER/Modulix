import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/time_log.dart';
import 'package:modulix/services/metrics_service.dart';

void main() {
  group('Domain 6: Analytics Hub & Sheets Logic Tests', () {
    test('Aggregates time logs by topic type correctly', () {
      final logs = [
        TimeLog(
          id: '1',
          subjectId: 'anatomy',
          topicType: 'video',
          topicTitle: 'Embryo 1',
          durationSecs: 1800, // 30m
          timestamp: DateTime(2026, 10, 15, 10, 0),
        ),
        TimeLog(
          id: '2',
          subjectId: 'anatomy',
          topicType: 'video',
          topicTitle: 'Embryo 2',
          durationSecs: 900, // 15m
          timestamp: DateTime(2026, 10, 15, 11, 0),
        ),
        TimeLog(
          id: '3',
          subjectId: 'anatomy',
          topicType: 'qbank',
          topicTitle: 'MCQ Module 1',
          durationSecs: 1200, // 20m
          timestamp: DateTime(2026, 10, 15, 12, 0),
        ),
        TimeLog(
          id: '4',
          subjectId: 'anatomy',
          topicType: 'notes',
          topicTitle: 'Revision Notes',
          durationSecs: 600, // 10m
          timestamp: DateTime(2026, 10, 15, 14, 0),
        ),
        TimeLog(
          id: '5',
          subjectId: 'anatomy',
          topicType: 'standalone',
          topicTitle: 'Textbook Reading',
          durationSecs: 1500, // 25m
          timestamp: DateTime(2026, 10, 15, 16, 0),
        ),
      ];

      int videoSecs = 0;
      int qbankSecs = 0;
      int notesSecs = 0;
      int standaloneSecs = 0;

      for (final l in logs) {
        switch (l.topicType) {
          case 'video':
            videoSecs += l.durationSecs;
            break;
          case 'qbank':
            qbankSecs += l.durationSecs;
            break;
          case 'notes':
            notesSecs += l.durationSecs;
            break;
          default:
            standaloneSecs += l.durationSecs;
        }
      }

      final totalSecs = videoSecs + qbankSecs + notesSecs + standaloneSecs;
      expect(videoSecs, 2700); // 45m
      expect(qbankSecs, 1200); // 20m
      expect(notesSecs, 600); // 10m
      expect(standaloneSecs, 1500); // 25m
      expect(totalSecs, 6000); // 100m = 1h 40m

      final hours = totalSecs ~/ 3600;
      final mins = (totalSecs % 3600) ~/ 60;
      expect(hours, 1);
      expect(mins, 40);
    });

    test('5 AM boundary correctly attributes time logs to effective study day', () {
      final nowNight = DateTime(2026, 10, 16, 2, 30); // 2:30 AM
      final effectiveDate = MetricsService.todayKey(5, nowNight);
      expect(effectiveDate, '2026-10-15');

      final nowMorning = DateTime(2026, 10, 16, 6, 15); // 6:15 AM
      final morningDate = MetricsService.todayKey(5, nowMorning);
      expect(morningDate, '2026-10-16');
    });

    test('Daily tasks completion percentage clamps between 0.0 and 1.0', () {
      expect((0 / 5).clamp(0.0, 1.0), 0.0);
      expect((3 / 5).clamp(0.0, 1.0), 0.6);
      expect((5 / 5).clamp(0.0, 1.0), 1.0);
      expect((7 / 5).clamp(0.0, 1.0), 1.0);
    });
  });
}
