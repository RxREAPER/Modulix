# Feature: Daily Desk Tasks

> Files:  
> - Model: `lib/models/daily_desk_task.dart`  
> - Provider & Controller: `lib/providers/daily_tasks_provider.dart`  
> - UI Components: `lib/widgets/study_task_card.dart`, `lib/widgets/task_setup_sheet.dart`, `lib/screens/home/home_screen.dart`

---

## 1. Overview & Purpose
Daily Desk Tasks represent the user's immediate, actionable task checklist displayed on their main Home Screen "Study Desk".
Unlike long-range curriculum planning (which spans weeks/months), desk tasks are short-term items meant to be cleared during today's study block.

It supports:
1. **Dynamic Task Categories** (`video`, `qbank`, `revision`, `notes`, `general`).
2. **Shortcode Syntax Parsing** (e.g., `[VID]`, `[MCQ]`, `[REV]`, `[NOTE]`).
3. **Automated 5:00 AM Day-Rollover & History Archival**.
4. **Interactive Desk Management** (Reordering, Inserting, Deleting, Batch Clear).
5. **Bidirectional Synchronization with Module Tasks**.

---

## 2. Data Models & Category Taxonomy

### `DailyDeskTask` (`lib/models/daily_desk_task.dart`)
```dart
class DailyDeskTask {
  final String id;              // Unique string id (e.g. 'task_1696200000_1234')
  final String title;           // Plain user-visible description
  final TaskCategory category;  // Enum categorization
}
```

### `TaskCategory` Enum
| Category Enum | Display Label | Prefix Tag | Meaning / Usage Context |
|---|---|---|---|
| `video` | Video | `[VID] ` | Watching a lecture/video module |
| `qbank` | Q-Bank | `[MCQ] ` | Solving practice questions / MCQs |
| `revision` | Revision | `[REV] ` | 24-hr or 7-day spaced retrieval review |
| `notes` | Notes | `[NOTE] ` | Reading textbook / First Aid / unit notes |
| `general` | Goal | *(none)* | General medical study goal or desk errand |

### Shortcode Parsing Logic (`DailyDeskTask.fromString(raw, index)`)
Users or automated generators can inject raw strings. The factory inspects prefix headers:
```dart
if (raw.startsWith('[REV] ')) -> category = revision, title stripped by 6 chars
if (raw.startsWith('[MCQ] ')) -> category = qbank,    title stripped by 6 chars
if (raw.startsWith('[VID] ')) -> category = video,    title stripped by 6 chars
if (raw.startsWith('[NOTE] ')) -> category = notes,   title stripped by 7 chars
```

---

## 3. State Management & Lifecycle (`DailyTasksNotifier`)

Provider: `dailyTasksProvider` (`StateNotifierProvider<DailyTasksNotifier, DailyTasksState>`)

```dart
class DailyTasksState {
  final List<DailyDeskTask> tasks;          // Active tasks on the desk
  final Set<String> completedIds;           // Completed task IDs for today
  final Map<String, int> dateHistory;       // 'YYYY-MM-DD' -> count of completed tasks
}
```

### Persistence Layer Keys
All state is stored independently in `SharedPreferences` to ensure durability:
- `_kDailyTasksKey` (`modulix_daily_tasks_v2`): JSON list of all active task objects.
- `_kCompletedTasksKey` (`modulix_completed_tasks_v1`): JSON list of completed task ID strings.
- `_kTasksHistoryKey` (`modulix_tasks_history_v1`): JSON map of historical completion counts.
- `_kLastActiveDateKey` (`modulix_tasks_last_date_v1`): String ISO date key for rollover detection.

---

## 4. Business Logic: The 5:00 AM Day-Rollover Algorithm

Medical students frequently study past midnight (1:00 AM – 4:00 AM). Therefore, calendar midnight (`00:00:00`) is **not** a valid study boundary.

Modulix defines a configurable `dayStartHour` (defaulting to **5:00 AM**):
```dart
String _todayKey([int? customHour]) {
  final hour = customHour ?? dayStartHour;
  final now = DateTime.now().subtract(Duration(hours: hour));
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
```

### Rollover Execution (`checkDayRollover()` & `_load()`):
When the app launches or returns to the foreground:
1. Compares `lastActiveDateKey` against `todayKey()`.
2. **If date changed (`lastDate != today`):**
   - **Credit History:** If `completedIds.length > 0`, writes count into `dateHistory[lastDate]`.
   - **Purge Completed:** Strips all completed tasks from the active desk:
     ```dart
     loadedTasks = loadedTasks.where((t) => !completed.contains(t.id)).toList();
     ```
   - **Carry Over Unfinished:** Any task *not* completed remains on the desk automatically for today.
   - **Reset Daily Set:** `completedIds` is wiped clean (`<String>{}`).
   - Updates `_kLastActiveDateKey` to `today`.

---

## 5. Operations & Task Mutators

- `toggleTask(taskId)`:
  - Toggles membership in `completedIds`.
  - Recalculates today's history entry: `dateHistory[_todayKey()] = updated.length`.
  - If all tasks are now completed (`updated.length == tasks.length`), fires system completion notification:
    `NotificationService.instance.showModuleTaskCompletedNotification(subjectName: "Today's Desk", count: length)`.
- `insertTaskAt(index, task, wasCompleted)`:
  - Inserts task at clamped index. Supports undo/restore workflows.
- `removeTaskAt(index)`:
  - Deletes task and cleanly decrements today's completed tally if it was checked off.
- `reorderTasks(oldIndex, newIndex)`:
  - Handles Flutter `ReorderableListView` index adjustment (`if (newIndex > oldIndex) newIndex -= 1`).
- `clearCompleted()`:
  - Clears all checked items from the desk and zeros today's count in history.

---

## 6. Edge Cases & Synchronization Notes

1. **Curriculum Video Synchronization:**
   - In `ModuleTasksScreen` (`lib/screens/curriculum/module_tasks_screen.dart`), when a user marks a video as done/incomplete, the screen checks if any task on the desk has `id == 'vid_${video.id}'`.
   - If found, it automatically calls `dailyTasksNotifier.toggleTask('vid_${video.id}')` so the student doesn't have to check it off twice.
2. **Undo Support via SnackBar:**
   - Deleting a task emits a `ScaffoldMessenger` SnackBar with an "Undo" action. The deleted task and its completion state are cached and restored via `insertTaskAt(index, task, wasCompleted)`.
