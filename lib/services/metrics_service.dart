import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/syllabus.dart';

/// Ported from js/core/metrics.js
class MetricsService {
  /// Day boundary with configurable start hour (defaults to 5 AM)
  static String todayKey([int dayStartHour = 5]) {
    final adjusted = DateTime.now().subtract(Duration(hours: dayStartHour));
    return DateFormat('yyyy-MM-dd').format(adjusted);
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
    String targetDate,
  ) {
    final pace = videosPerDay < 1 ? 1 : videosPerDay;
    final daysNeeded = (remainingVideos / pace).ceil();
    final finishDate = DateTime.now().add(Duration(days: daysNeeded));

    DateTime? deadline;
    int? daysToDeadline;
    bool isOverdue = false;

    if (targetDate.isNotEmpty) {
      try {
        deadline = DateTime.parse(targetDate);
        daysToDeadline = deadline.difference(DateTime.now()).inDays;
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
  static StreakResult computeStreak(Map<String, int> dailyHistory) {
    if (dailyHistory.isEmpty) return const StreakResult(current: 0, best: 0);

    final dates = dailyHistory.keys.toList()..sort();
    int currentStreak = 0;
    int bestStreak = 0;
    int streak = 0;

    DateTime? prev;
    for (final dateStr in dates.reversed) {
      final date = DateTime.parse(dateStr);
      if (prev == null) {
        streak = 1;
      } else {
        final diff = prev.difference(date).inDays;
        if (diff == 1) {
          streak++;
        } else {
          break;
        }
      }
      prev = date;
    }
    currentStreak = streak;

    // Best streak
    streak = 0;
    DateTime? lastDate;
    for (final dateStr in dates) {
      final date = DateTime.parse(dateStr);
      if (lastDate == null) {
        streak = 1;
      } else {
        final diff = date.difference(lastDate).inDays;
        if (diff == 1) {
          streak++;
        } else {
          streak = 1;
        }
      }
      if (streak > bestStreak) bestStreak = streak;
      lastDate = date;
    }

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
