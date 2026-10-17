import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/syllabus.dart';

/// Ported from js/core/metrics.js
class MetricsService {
  /// Day boundary with configurable start hour (defaults to 5 AM)
  static String todayKey([int dayStartHour = 5, DateTime? now]) {
    final adjusted = (now ?? DateTime.now()).subtract(Duration(hours: dayStartHour));
    return DateFormat('yyyy-MM-dd').format(adjusted);
  }

  /// Timestamp representing the start of the study day (defaults to 5 AM)
  static DateTime studyDayStart([int dayStartHour = 5, DateTime? now]) {
    final current = now ?? DateTime.now();
    final adjusted = current.subtract(Duration(hours: dayStartHour));
    return current.isUtc
        ? DateTime.utc(adjusted.year, adjusted.month, adjusted.day, dayStartHour)
        : DateTime(adjusted.year, adjusted.month, adjusted.day, dayStartHour);
  }

  /// Syllabus-wide stats for a given edition state + subjects
  static SyllabusMetrics computeSyllabusMetrics(
    EditionState edState,
    List<Subject> subjects,
  ) {
    int total = 0;
    int completed = 0;
    double totalMins = 0;
    double completedMins = 0;

    for (final subject in subjects) {
      for (final video in subject.allVideos) {
        total++;
        totalMins += video.totalMinutes;
        if (edState.completedVideos.containsKey(video.id)) {
          completed++;
          completedMins += video.totalMinutes;
        }
      }
    }

    return SyllabusMetrics(
      totalVideos: total,
      completedVideos: completed,
      remainingVideos: total - completed,
      totalHours: totalMins / 60,
      completedHours: completedMins / 60,
      remainingHours: (totalMins - completedMins) / 60,
      masteryPercent: total == 0 ? 0 : (completed / total) * 100,
    );
  }

  /// Stats for a specific subject
  static SubjectMetrics computeSubjectMetrics(
    EditionState edState,
    Subject subject,
  ) {
    int total = 0;
    int completed = 0;
    double totalMins = 0;
    double completedMins = 0;

    for (final video in subject.allVideos) {
      total++;
      totalMins += video.totalMinutes;
      if (edState.completedVideos.containsKey(video.id)) {
        completed++;
        completedMins += video.totalMinutes;
      }
    }

    return SubjectMetrics(
      subjectId: subject.id,
      totalVideos: total,
      completedVideos: completed,
      remainingVideos: total - completed,
      totalHours: totalMins / 60,
      completedHours: completedMins / 60,
      remainingHours: (totalMins - completedMins) / 60,
      masteryPercent: total == 0 ? 0 : (completed / total) * 100,
    );
  }

  /// Compute today's daily quest batch for a plan
  static List<Video> computeDailyBatch(
    EditionState edState,
    StudyPlan plan,
    List<Subject> subjects,
  ) {
    if (!plan.isConfigured) return [];

    final subject = subjects.firstWhere(
      (s) => s.id == plan.targetSubject,
      orElse: () => throw StateError('Subject not found: ${plan.targetSubject}'),
    );

    if (edState.queueBatchVideoIds.isNotEmpty) {
      // Validate batch videos are from this subject
      final allIds = subject.allVideos.map((v) => v.id).toSet();
      if (edState.queueBatchVideoIds.every((id) => allIds.contains(id))) {
        return edState.queueBatchVideoIds
            .map((id) => subject.allVideos.firstWhere((v) => v.id == id))
            .toList();
      }
    }

    // Generate new batch: get uncompleted videos in order
    List<Video> scope;
    if (plan.targetUnits.isNotEmpty) {
      scope = subject.chapters
          .where((c) => plan.targetUnits.contains(c.name))
          .expand((c) => c.videos)
          .toList();
    } else {
      scope = subject.allVideos;
    }

    final uncompleted = scope
        .where((v) => !edState.completedVideos.containsKey(v.id))
        .toList();

    final pace = plan.videosPerDay ?? 5;
    return uncompleted.take(pace).toList();
  }

  /// ETA calculation
  static ETAResult calculateETA(
    int remainingVideos,
    int videosPerDay,
    String targetDate, {
    DateTime? now,
  }) {
    final pace = videosPerDay < 1 ? 1 : videosPerDay;
    final daysNeeded = (remainingVideos / pace).ceil();
    final effectiveNow = now ?? DateTime.now();
    final finishDate = effectiveNow.add(Duration(days: daysNeeded));

    DateTime? deadline;
    int? daysToDeadline;
    bool isOverdue = false;

    if (targetDate.isNotEmpty) {
      try {
        deadline = DateTime.parse(targetDate);
        final deadlineUtc = DateTime.utc(deadline.year, deadline.month, deadline.day);
        final nowUtc = DateTime.utc(effectiveNow.year, effectiveNow.month, effectiveNow.day);
        daysToDeadline = deadlineUtc.difference(nowUtc).inDays;
        isOverdue = daysToDeadline < 0;
      } catch (_) {}
    }

    return ETAResult(
      finishDate: finishDate,
      daysNeeded: daysNeeded,
      remainingVideos: remainingVideos,
      videosPerDay: pace,
      deadline: deadline,
      daysToDeadline: daysToDeadline,
      isOverdue: isOverdue,
      isOnTrack: daysToDeadline == null || daysNeeded <= daysToDeadline,
    );
  }

  /// Streak calculation from daily history
  static StreakResult computeStreak(
    Map<String, int> dailyHistory, {
    int dayStartHour = 5,
    DateTime? now,
  }) {
    final active = dailyHistory.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
    if (active.isEmpty) return const StreakResult(current: 0, best: 0);

    final activeSet = <DateTime>{};
    for (final d in active) {
      final parsed = DateTime.tryParse('${d}T00:00:00Z');
      if (parsed != null) {
        activeSet.add(parsed);
      }
    }
    if (activeSet.isEmpty) return const StreakResult(current: 0, best: 0);
    final activeDatesUtc = activeSet.toList()..sort();

    final refNow = now ?? DateTime.now();
    final todayStr = todayKey(dayStartHour, refNow);
    final adjustedRef = refNow.subtract(Duration(hours: dayStartHour));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(
      adjustedRef.subtract(const Duration(days: 1)),
    );
    final todayUtc = DateTime.parse('${todayStr}T00:00:00Z');
    final yesterdayUtc = DateTime.parse('${yesterdayStr}T00:00:00Z');

    int currentStreak = 0;
    DateTime? anchorDate;
    if (activeSet.contains(todayUtc)) {
      anchorDate = todayUtc;
    } else if (activeSet.contains(yesterdayUtc)) {
      anchorDate = yesterdayUtc;
    }

    if (anchorDate != null) {
      currentStreak = 1;
      DateTime currentCheck = anchorDate;
      while (true) {
        final expectedPrev = currentCheck.subtract(const Duration(days: 1));
        if (activeSet.contains(expectedPrev)) {
          currentStreak++;
          currentCheck = expectedPrev;
        } else {
          break;
        }
      }
    }

    // Best streak
    int bestStreak = 1;
    int streak = 1;
    for (int i = 1; i < activeDatesUtc.length; i++) {
      final prev = activeDatesUtc[i - 1];
      final cur = activeDatesUtc[i];
      if (cur == prev.add(const Duration(days: 1))) {
        streak++;
      } else {
        streak = 1;
      }
      if (streak > bestStreak) bestStreak = streak;
    }
    if (currentStreak > bestStreak) bestStreak = currentStreak;

    return StreakResult(current: currentStreak, best: bestStreak);
  }

  /// Last N days of history for bar chart
  static List<DayCount> lastNDays(Map<String, int> dailyHistory, int n) {
    return List.generate(n, (i) {
      final date = DateTime.now().subtract(Duration(days: n - 1 - i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      return DayCount(date: date, count: dailyHistory[key] ?? 0);
    });
  }
}

// --- Result types ---

class SyllabusMetrics {
  final int totalVideos;
  final int completedVideos;
  final int remainingVideos;
  final double totalHours;
  final double completedHours;
  final double remainingHours;
  final double masteryPercent;

  const SyllabusMetrics({
    required this.totalVideos,
    required this.completedVideos,
    required this.remainingVideos,
    required this.totalHours,
    required this.completedHours,
    required this.remainingHours,
    required this.masteryPercent,
  });
}

class SubjectMetrics {
  final String subjectId;
  final int totalVideos;
  final int completedVideos;
  final int remainingVideos;
  final double totalHours;
  final double completedHours;
  final double remainingHours;
  final double masteryPercent;

  const SubjectMetrics({
    required this.subjectId,
    required this.totalVideos,
    required this.completedVideos,
    required this.remainingVideos,
    required this.totalHours,
    required this.completedHours,
    required this.remainingHours,
    required this.masteryPercent,
  });
}

class ETAResult {
  final DateTime finishDate;
  final int daysNeeded;
  final int remainingVideos;
  final int videosPerDay;
  final DateTime? deadline;
  final int? daysToDeadline;
  final bool isOverdue;
  final bool isOnTrack;

  const ETAResult({
    required this.finishDate,
    required this.daysNeeded,
    required this.remainingVideos,
    required this.videosPerDay,
    this.deadline,
    this.daysToDeadline,
    required this.isOverdue,
    required this.isOnTrack,
  });
}

class StreakResult {
  final int current;
  final int best;
  const StreakResult({required this.current, required this.best});
}

class DayCount {
  final DateTime date;
  final int count;
  const DayCount({required this.date, required this.count});
}
