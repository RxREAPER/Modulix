# Feature: Analytics, TimeLogs & Streaks

> Files:  
> - Models: `lib/models/time_log.dart`, `lib/models/app_state.dart`  
> - Providers: `lib/providers/time_log_provider.dart`, `lib/providers/app_state_provider.dart`  
> - Computation Engine: `lib/services/metrics_service.dart`  
> - UI Screens: `lib/screens/analytics/analytics_screen.dart`, `lib/screens/curriculum/subject_analytics_screen.dart`

---

## 1. Overview & Data Sources

Modulix’s Analytics subsystem provides high-yield visualization of study consistency, subject distribution, and duration.
It operates on **two distinct data streams**:

1. **Active Focus Study Time (`TimeLog` stream):**
   - Source: `modulix_time_logs_v1` (`TimeLogsNotifier`).
   - Granular, immutable log entries produced whenever a Focus Timer session is completed.
   - Measures actual time invested (seconds) per subject, topic type, and timestamp.
2. **Curriculum Velocity & Streaks (`dailyHistory` stream):**
   - Source: `AppState.currentEdition.dailyHistory` (Map of `'YYYY-MM-DD' -> videoCount`).
   - Measures daily curriculum progress count against 5:00 AM day boundaries.

---

## 2. Focus TimeLog Model (`TimeLog`)

File: `lib/models/time_log.dart`

```dart
class TimeLog {
  final String id;           // 'log_${timestamp_millis}'
  final String subjectId;    // e.g. 'obg', 'pathology'
  final String? topicId;     // Lecture or module ID
  final String topicType;    // 'video' | 'qbank' | 'notes' | 'standalone'
  final String topicTitle;   // Clean readable title
  final String chapterName;  // Unit / chapter title
  final int durationSecs;    // Total elapsed focus seconds (break time excluded)
  final DateTime timestamp;  // Exact session conclusion timestamp
}
```

### Aggregate Methods (`TimeLogsNotifier` in `lib/providers/time_log_provider.dart`):
- `forSubject(subjectId)`: Filter logs for a specific medical subject.
- `totalSecsForSubject(subjectId)`: Sum of all study time ever logged for that subject.
- `totalSecsForType(subjectId, type)`: Drill down into video vs. QBank vs. notes study duration.

---

## 3. Streak Engine Algorithm (`MetricsService.computeStreak`)

File: `lib/services/metrics_service.dart`

### Input:
`dailyHistory` — a map where keys are date strings formatted with the user's `dayStartHour` (default 5:00 AM):
```json
{
  "2026-09-30": 4,
  "2026-10-01": 5,
  "2026-10-02": 2
}
```

### Algorithm:
```dart
static StreakResult computeStreak(Map<String, int> dailyHistory) {
  if (dailyHistory.isEmpty) return const StreakResult(current: 0, best: 0);

  final dates = dailyHistory.keys.toList()..sort();
  int currentStreak = 0;
  int bestStreak = 0;
  int streak = 0;

  // 1. Current Streak: Traverse backwards from newest date
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
        break; // Streak broken
      }
    }
    prev = date;
  }
  currentStreak = streak;

  // 2. Best Streak: Traverse forward from oldest date to find peak sequence
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
        streak = 1; // Reset run
      }
    }
    if (streak > bestStreak) bestStreak = streak;
    lastDate = date;
  }

  return StreakResult(current: currentStreak, best: bestStreak);
}
```

---

## 4. UI Analytics Visualizations

### 1. Global Analytics Screen (`lib/screens/analytics/analytics_screen.dart`)
- **Streak Card:** Shows `currentStreak` (with flame badge) and all-time `bestStreak`.
- **Activity Bar Chart:** Uses `MetricsService.lastNDays(dailyHistory, 7)` to render a 7-day study consistency bar chart.
- **Modality Distribution:** Donut / split breakdown showing percentage of study time spent on Videos vs QBanks vs Notes.

### 2. Subject Analytics Screen (`lib/screens/curriculum/subject_analytics_screen.dart`)
- Accessible via the analytics chart icon in the Subject header or deep-link `/curriculum/:subjectId/analytics`.
- Displays total accumulated hours for this specific subject.
- Lists the full chronological history of focus sessions logged for this subject.
