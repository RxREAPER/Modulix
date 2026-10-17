# Feature: Module-Based Tasks & Study Plan

> Files:  
> - Models: `lib/models/app_state.dart` (`StudyPlan`, `EditionState`), `lib/models/syllabus.dart` (`Subject`, `Chapter`, `Video`)  
> - Logic & Metrics: `lib/services/metrics_service.dart`, `lib/providers/app_state_provider.dart`  
> - UI Screens: `lib/screens/curriculum/module_tasks_screen.dart` (1177 lines), `lib/screens/plan/plan_screen.dart`  
> - Home Component: `lib/widgets/automated_module_tracker.dart`

---

## 1. Overview & Core Philosophy
The Module-Based Tasks system is Modulix’s automated daily curriculum pipeline. 
Rather than forcing a medical student to manually browse 19 subjects and 800+ videos every morning to figure out what to study, this engine:
1. Calculates a dynamic daily study queue matching the user's target subject, unit scope, and daily video quota.
2. Tracks overall completion percentage for the active scope.
3. Automatically rolls over uncompleted items into **"Stale"** status after 5:00 AM while strictly capping the total daily workload.
4. Directly hooks into the **Focus Timer** with pre-configured lecture durations.

---

## 2. Configuration Model: `StudyPlan`

Stored inside each edition’s `EditionState` partition:

```dart
class StudyPlan {
  final String targetSubject;      // e.g. 'obg', 'surgery', 'pathology'
  final String targetDate;         // ISO date string deadline ('2026-12-31')
  final int? videosPerDay;         // Daily pace quota (e.g. 4 videos/day)
  final List<String> targetUnits;  // Chapter unit names (empty = entire subject)
  final String? focusChapterName;
  final double dailyHours;         // Target study hours per day (default 4.0)
  final int revisionCycles;        // Number of revision passes planned (default 1)
}
```

A plan is considered valid and configured (`isConfigured`) when:
```dart
targetSubject.isNotEmpty && targetDate.isNotEmpty && videosPerDay != null
```

---

## 3. Daily Batch Allocation & The "2 Stale + 2 Fresh = 4" Algorithm

One of the most complex parts of Modulix is how daily batches are generated and preserved without cognitive overload.

### The Problem
If a student has a quota of 4 videos/day and misses 2 videos yesterday:
- Naive rollover adds 2 missed videos to 4 new videos = **6 videos today**.
- Tomorrow they miss 3 = **7 videos**. The backlog snowballs and causes user abandonment.

### Modulix's Capped Rollover Solution (`_checkAndRefreshDailyBatch`)
Modulix enforces **Strict Quota Capping**:
$$\text{Total Daily Batch} = \text{Stale (Unfinished from Yesterday)} + \text{Fresh Candidates} \le \text{User Quota}$$

```dart
// 1. Identify uncompleted items from yesterday's queue
final uncompletedFromYesterday = currentBatchIds
    .where((id) => !editionState.completedVideos.containsKey(id) && planVideoIds.contains(id))
    .toList();

final staleCount = uncompletedFromYesterday.length;

// 2. Compute needed fresh videos to satisfy quota exactly
final neededFresh = (targetQuota - staleCount).clamp(0, targetQuota);

// 3. Select next uncompleted sequential videos from the syllabus
final freshCandidates = planVideos
    .where((v) => !editionState.completedVideos.containsKey(v.id) &&
                  !uncompletedFromYesterday.contains(v.id))
    .toList();

final freshBatchIds = freshCandidates.take(neededFresh).map((v) => v.id).toList();

// 4. Assemble composite batch
final newBatch = [...uncompletedFromYesterday, ...freshBatchIds];

// 5. Commit to AppState
ref.read(appStateProvider.notifier).setBatch(newBatch, uncompletedFromYesterday);
```

### Stale Badge Indicators
- Videos that were carried over from yesterday are tagged in `editionState.staleBatchVideoIds`.
- In the UI, these items receive an amber **"Stale"** chip and amber timeline bubble to remind the user that these are overdue items requiring immediate clearance.

---

## 4. Progress Scopes & Global Numbering

### Unit Scope vs. Subject Scope
The user can target an entire subject or restrict their queue to specific chapters/units:
- If `plan.targetUnits.isNotEmpty`:
  - `planVideos` filter: Only videos where `chapter.name` $\in$ `plan.targetUnits`.
  - Banner shows: `"Unit: <Unit Name>"` with Unit-specific completion bar.
- If `plan.targetUnits.isEmpty`:
  - `planVideos`: All videos across all chapters of the subject.
  - Banner shows: `"Scope: All Units"` with Subject-wide completion bar.

### Absolute Syllabus Global Numbering
In `_buildTimelineItem`:
- Videos are not numbered relative to today’s mini-batch (e.g. 1, 2, 3, 4).
- Instead, each video displays its **whole-subject sequential index** (e.g. `24`, `25`, `26`, `27`).
- This gives the student absolute spatial awareness of where they are in the entire textbook/syllabus.

---

## 5. Metrics & Predictive Analytics (`MetricsService`)

File: `lib/services/metrics_service.dart`

### 1. Syllabus & Subject Mastery
- Counts total videos and sums duration:
  $$\text{Mastery \%} = \frac{\text{Completed Videos}}{\text{Total Videos}} \times 100$$
  $$\text{Remaining Hours} = \frac{\sum \text{Duration of Unfinished Videos (mins)}}{60}$$

### 2. ETA & Velocity Calculation (`MetricsService.calculateETA`)
Given remaining videos, `videosPerDay`, and `targetDate`:
$$\text{Days Needed} = \left\lceil \frac{\text{Remaining Videos}}{\text{Videos Per Day}} \right\rceil$$
$$\text{Projected Finish Date} = \text{Today} + \text{Days Needed}$$
$$\text{Days to Deadline} = \text{Target Date} - \text{Today}$$
- **On Track:** `daysNeeded <= daysToDeadline`
- **Overdue:** `daysToDeadline < 0`

### 3. Streak Engine (`MetricsService.computeStreak`)
- Evaluates `EditionState.dailyHistory` (Map of `'YYYY-MM-DD' -> count`).
- Reverses chronological dates and calculates consecutive active days (difference == 1 day).
- Tracks `currentStreak` and all-time `bestStreak`.

---

## 6. Integrations with Other Subsystems

1. **Curriculum Deep-Linking:**
   - The Top Banner features a direct deep link button:
     - If targeting a single unit $\rightarrow$ opens `ChapterScreen` (`/curriculum/:subjectId/:chapterIndex`).
     - If targeting whole subject $\rightarrow$ opens `SubjectScreen` (`/curriculum/:subjectId`).
2. **Focus Timer Direct-Launch:**
   - Every module timeline card has a timer shortcut button.
   - Launches `/timer` with `extra` payload:
     ```dart
     'subjectId': targetSubject.id,
     'subjectName': targetSubject.displayName,
     'topicId': video.id,
     'topicTitle': video.title,
     'chapterName': video.chapterName,
     'topicType': 'video',
     'durationMins': video.durationMins > 0 ? video.durationMins : 15,
     ```
   - Automatically initializes the Focus Timer into `TimerMode.moduleLinked` with exact lecture runtime!
3. **Daily Desk Task Cross-Sync:**
   - Toggling completion in `ModuleTasksScreen` automatically checks if a desk task exists with `id == 'vid_${video.id}'` and keeps both in sync.
