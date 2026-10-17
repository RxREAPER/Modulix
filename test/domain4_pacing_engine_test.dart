import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/services/metrics_service.dart';

void main() {
  group('Domain 4: Study Plan & Pacing Engine Tests', () {
    test('calculateETA handles divide-by-zero protection when pace <= 0', () {
      final now = DateTime(2026, 1, 1);
      final etaZero = MetricsService.calculateETA(50, 0, '2026-02-01', now: now);
      expect(etaZero.videosPerDay, 1);
      expect(etaZero.daysNeeded, 50);

      final etaNegative = MetricsService.calculateETA(50, -5, '2026-02-01', now: now);
      expect(etaNegative.videosPerDay, 1);
      expect(etaNegative.daysNeeded, 50);
    });

    test('calculateETA correctly determines on-track vs behind pace', () {
      final now = DateTime(2026, 1, 1);

      // 40 videos remaining, 5/day = 8 days needed. Deadline in 10 days (2026-01-11).
      final onTrack = MetricsService.calculateETA(40, 5, '2026-01-11', now: now);
      expect(onTrack.daysNeeded, 8);
      expect(onTrack.daysToDeadline, 10);
      expect(onTrack.isOnTrack, isTrue);
      expect(onTrack.isOverdue, isFalse);

      // 40 videos remaining, 2/day = 20 days needed. Deadline in 10 days.
      final behindPace = MetricsService.calculateETA(40, 2, '2026-01-11', now: now);
      expect(behindPace.daysNeeded, 20);
      expect(behindPace.daysToDeadline, 10);
      expect(behindPace.isOnTrack, isFalse);
      expect(behindPace.isOverdue, isFalse);
    });

    test('calculateETA handles past deadline dates cleanly without crashing', () {
      final now = DateTime(2026, 6, 1);
      final pastDate = MetricsService.calculateETA(20, 5, '2026-01-01', now: now);

      expect(pastDate.isOverdue, isTrue);
      expect(pastDate.isOnTrack, isFalse);
      expect(pastDate.daysToDeadline, lessThan(0));
    });

    test('computeDailyBatch with unit filters picks only targeted unit videos', () {
      final v1 = const Video(id: 'v1', title: 'Video 1', durationMins: 30, serialNumber: 1, subjectId: 'anatomy', chapterName: 'Embryology');
      final v2 = const Video(id: 'v2', title: 'Video 2', durationMins: 45, serialNumber: 2, subjectId: 'anatomy', chapterName: 'Embryology');
      final v3 = const Video(id: 'v3', title: 'Video 3', durationMins: 20, serialNumber: 3, subjectId: 'anatomy', chapterName: 'Neuroanatomy');

      final anatomy = Subject(
        id: 'anatomy',
        name: 'Anatomy',
        displayName: 'Human Anatomy',
        accent: const Color(0xFF3B82F6),
        chapters: [
          Chapter(name: 'Embryology', videos: [v1, v2]),
          Chapter(name: 'Neuroanatomy', videos: [v3]),
        ],
      );

      final plan = const StudyPlan(
        targetSubject: 'anatomy',
        targetDate: '2026-12-31',
        videosPerDay: 5,
        targetUnits: ['Embryology'],
      );

      final edState = const EditionState();
      final batch = MetricsService.computeDailyBatch(edState, plan, [anatomy]);

      expect(batch.length, 2);
      expect(batch.map((v) => v.id), containsAll(['v1', 'v2']));
      expect(batch.map((v) => v.id), isNot(contains('v3')));
    });

    test('computeDailyBatch excludes already completed videos', () {
      final v1 = const Video(id: 'v1', title: 'Video 1', durationMins: 30, serialNumber: 1, subjectId: 'anatomy', chapterName: 'General');
      final v2 = const Video(id: 'v2', title: 'Video 2', durationMins: 30, serialNumber: 2, subjectId: 'anatomy', chapterName: 'General');

      final anatomy = Subject(
        id: 'anatomy',
        name: 'Anatomy',
        displayName: 'Human Anatomy',
        accent: const Color(0xFF3B82F6),
        chapters: [
          Chapter(name: 'General', videos: [v1, v2]),
        ],
      );

      final plan = const StudyPlan(
        targetSubject: 'anatomy',
        targetDate: '2026-12-31',
        videosPerDay: 5,
      );

      final edState = const EditionState(
        completedVideos: {'v1': '2026-01-01T10:00:00Z'},
      );

      final batch = MetricsService.computeDailyBatch(edState, plan, [anatomy]);
      expect(batch.length, 1);
      expect(batch.first.id, 'v2');
    });
  });
}
