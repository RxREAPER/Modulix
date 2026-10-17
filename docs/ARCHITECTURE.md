# Modulix Flutter — Architecture Overview

> Last updated: 2026-10-02  
> App ID: `com.modulix.modulix_flutter`  
> Target: Android (primary), iOS (planned). Tested device: Oppo CPH2691 (ADB serial `ba009d81`).

---

## 1. Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter (Dart) |
| State Management | Riverpod 2 (`StateNotifierProvider`, `AsyncNotifierProvider`, `Provider`, `FutureProvider`) |
| Navigation/Routing | GoRouter (`ShellRoute` + nested `GoRoute`) |
| Local Persistence | `SharedPreferences` (all state serialized as JSON) |
| Data (Syllabus) | Static JSON assets bundled in `assets/`, parsed at runtime per edition |
| Notifications | `flutter_local_notifications` via `NotificationService` singleton |
| Animations | Rive (via `rive_native`), custom `AnimationController` widgets |

---

## 2. State Architecture

All app state lives in two independent persistence buckets:

### Bucket A — `AppState` (via `StorageService`)
**Key:** `modulix_flutter_app_state` in SharedPreferences  
**File:** `lib/models/app_state.dart`, `lib/providers/app_state_provider.dart`

This is the core application state blob. It is a nested struct serialized as a single JSON string:

```
AppState
├── onboardingDone: bool
├── doctorName: String
├── activeEdition: String            — 'marrow_8' | 'marrow_6_5'
├── themePref: ThemePref             — light | dark | system
├── accentColorId: String
├── avatarColorId / avatarIconId     — profile avatar customization
├── dayStartHour: int                — configurable day boundary (default 5 AM)
├── notification toggles + times    — 4 independent reminder channels
├── noriPropId / noriInteractions   — mascot state
└── editions: Map<String, EditionState>
    └── EditionState (per edition)
        ├── plan: StudyPlan          — single-subject plan config
        ├── completedVideos: Map<videoId, ISO timestamp>
        ├── completedQBanks: Map<qbankId, ISO timestamp>
        ├── completedNotes: Map<noteId, ISO timestamp>
        ├── dailyHistory: Map<'YYYY-MM-DD', int>   — videos marked done per day
        ├── bulkCompletedChapters: List<chapterName> — chapters bulk-marked
        ├── queueBatchVideoIds: List<String>        — today's module batch
        ├── staleBatchVideoIds: List<String>        — rolled-over yesterday videos
        └── queueCompletedInBatch: int
```

`AppState.updateCurrentEdition(updater)` is the primary mutation pattern — it reads `editions[activeEdition]`, applies the updater, and writes back. All mutations trigger an immediate `StorageService.instance.save()` call.

### Bucket B — `DailyTasksState` (via separate SharedPreferences keys)
**Keys:** `modulix_daily_tasks_v2`, `modulix_completed_tasks_v1`, `modulix_tasks_history_v1`, `modulix_tasks_last_date_v1`  
**File:** `lib/providers/daily_tasks_provider.dart`

Daily desk tasks are stored separately from AppState because they have their own rollover logic and category system. See `features/daily-desk-tasks.md`.

### Bucket C — `TimeLog` list (via SharedPreferences)
**Key:** `modulix_time_logs_v1`  
**File:** `lib/providers/time_log_provider.dart`

A flat append-only list of `TimeLog` entries recording every Focus Timer session completion. This is the source for study-time analytics. Never written to by bulk-marking or desk tasks.

---

## 3. Syllabus Data Loading

**File:** `lib/providers/syllabus_provider.dart`, `lib/data/` directory

Syllabus content (subjects, chapters, videos, QBanks, notes) is loaded lazily from static JSON assets. Two editions exist:

- **`marrow_8`** — loaded by `_marrow8Provider` (FutureProvider)
- **`marrow_6_5`** — loaded by `_marrow65Provider` (FutureProvider)

`activeSyllabusProvider` is a derived `Provider` that switches between the two based on `appState.activeEdition`. Downstream providers (`subjectProvider`, `syllabusMetricsProvider`, `suggestedVideosProvider`) all watch `activeSyllabusProvider`.

**Data Model Hierarchy:**
```
Subject
├── id, name, displayName, accent: Color
├── chapters: List<Chapter>              — for videos + notes
│   └── Chapter { name, videos, qbanks, notes }
│       ├── videos: List<Video>          { id, title, subjectId, chapterName, durationMins, serialNumber }
│       ├── qbanks: List<QBankTopic>     { id, title, totalMcqs, serialNumber }
│       └── notes: List<NotesItem>       { id, title, pages, isCustom }
└── qbankChapters: List<Chapter>         — separate chapter grouping for QBanks when provided
```

`Subject.allQBanks` prefers `qbankChapters` if non-empty, falls back to `chapters`.

---

## 4. Navigation & Routing

**File:** `lib/app.dart`

GoRouter is provided via `routerProvider`. Authentication (onboarding) redirect is handled at the router level — if `!onboardingDone`, any route redirects to `/onboarding`.

```
/onboarding              — OnboardingScreen (outside ShellRoute)
ShellRoute (MainShell)   — wraps bottom nav + MiniTimerOverlay
├── /                    — HomeScreen            (fade transition)
├── /curriculum          — CurriculumScreen      (fade)
├── /curriculum/:subjectId               — SubjectScreen      (slide horizontal)
├── /curriculum/:subjectId/analytics     — SubjectAnalyticsScreen (slide horizontal)
├── /curriculum/:subjectId/:chapterIndex — ChapterScreen      (slide horizontal)
├── /analytics           — AnalyticsScreen       (fade)
├── /plan                — PlanScreen            (fade)
├── /settings            — SettingsScreen        (slide up, query param: ?from=)
└── /module-tasks        — ModuleTasksScreen     (slide horizontal)
/timer                   — FocusTimerScreen (outside ShellRoute, slide up)
```

The `/timer` route accepts an `extra` `Map<String, dynamic>` with optional pre-population fields: `subjectId`, `subjectName`, `topicId`, `topicTitle`, `chapterName`, `topicType`, `durationMins`.

**Transition functions defined in `app.dart`:**
- `_buildFadeTransitionPage` — 200ms fade, easeOutCubic
- `_buildSlideHorizontalTransitionPage` — slides in from right
- `_buildSlideUpTransitionPage` — 240ms slide up + fade (used for timer, settings)

---

## 5. Theme & Design Tokens

**File:** `lib/theme/app_theme.dart`

Modulix uses a "parchment sketch" aesthetic derived from the Modulix web product:

| Token | Value | Usage |
|---|---|---|
| `paperBackground` | `#F5F2EA` | All scaffold backgrounds |
| `inkForeground` | `#0F172A` | Primary text |
| `primaryBlue` | `#4263EB` (approx) | CTA buttons, accents |
| `parchmentBorder` | sketch border color | Card borders |
| `sketchBorderColor` | subtle border | Timeline items, dividers |

`AppTheme.sketchDecoration({...})` is the universal card decoration factory — produces the characteristic hand-drawn offset shadow effect.

**Focus Timer Screen** uses a separate design language (`#FCFBF8` bg, `#6C3BAA` brand purple, `#0F172A` text) matching the Modulix website. No text drop shadows anywhere on timer screen. See `features/focus-timer.md`.

---

## 6. Notification Architecture

**File:** `lib/services/notification_service.dart`

`NotificationService` is a singleton initialized in `main.dart`. Four distinct reminder channels:

| Channel | ID | Trigger |
|---|---|---|
| Daily study reminder | 1 | Scheduled daily at `studyReminderTime` |
| Streak reminder | 2 | Scheduled daily at `streakReminderTime` |
| Module tasks reminder | 3 | Scheduled daily at `moduleTasksReminderTime` |
| Focus timer alerts | 4 | In-session: start, end countdown, break start/end |

`syncAllReminders(AppState)` cancels + reschedules all channel notifications whenever any toggle or time setting changes (called from `AppStateNotifier`).

**In-session notifications (Focus Timer):**
- `showFocusTimerStarted()` — persistent ongoing notification while timer runs
- `scheduleFocusTimerEnd()` — future notification scheduled at T+remaining
- `showBreakStarted()` / `showBreakCompleted()` — break phase notifications
- `showFocusTimerCompleted()` — fires when countdown hits 0
- `showModuleTaskCompletedNotification()` — fires when daily video quota is hit OR all desk tasks completed

---

## 7. Key Design Decisions & Constraints

- **No database** — all persistence is SharedPreferences JSON. Acceptable for the current data volume (thousands of video IDs as map keys).
- **Edition isolation** — completion data is fully isolated per edition. Switching edition is instant (no migration needed).
- **Bulk vs. individual completion** — bulk completion (`markVideosBulk`) sets `bulkCompletedChapters` but does NOT increment `dailyHistory`. Only `markVideoComplete` (individual tap) increments the daily counter. This is intentional — bulk marking chapters already watched shouldn't inflate analytics.
- **Day boundary** — Modulix's "today" is offset by `dayStartHour` (default 5 AM). A day runs from 5:00 AM to 4:59 AM next calendar day. Every subsystem that needs "today's date" uses this offset: `MetricsService.todayKey()`, `DailyTasksNotifier._todayKey()`, `ModuleTasksScreen` day window calculation.
- **MiniTimerOverlay** — a persistent widget in `MainShell` that renders a floating mini-timer badge when the timer is running and the user navigates away from `/timer`. State is from `focusTimerProvider`.

---

## 8. File Map (Key Files Quick Reference)

```
lib/
├── main.dart                          app bootstrap, StorageService.init()
├── app.dart                           GoRouter config, ShellRoute, MainShell, transitions
├── models/
│   ├── app_state.dart                 AppState, EditionState, StudyPlan, ThemePref
│   ├── syllabus.dart                  Video, QBankTopic, NotesItem, Chapter, Subject
│   ├── daily_desk_task.dart           DailyDeskTask, TaskCategory
│   ├── time_log.dart                  TimeLog (focus session records)
│   └── timer_theme.dart               TimerThemeData, kTimerThemes list
├── providers/
│   ├── app_state_provider.dart        AppStateNotifier (core CRUD), themeModeProvider
│   ├── syllabus_provider.dart         activeSyllabusProvider, subjectProvider, syllabusMetricsProvider
│   ├── daily_tasks_provider.dart      DailyTasksNotifier, DailyTasksState
│   ├── focus_timer_provider.dart      FocusTimerNotifier, FocusTimerState, TimerMode, TimerPhase
│   └── time_log_provider.dart         TimeLogsNotifier (append-only session log)
├── services/
│   ├── storage_service.dart           SharedPrefs JSON save/load/export/import for AppState
│   ├── metrics_service.dart           Pure computation: syllabus metrics, streaks, ETA, daily batch
│   ├── notification_service.dart      flutter_local_notifications singleton
│   └── ambient_audio_service.dart     Audio playback for ambient sounds
├── screens/
│   ├── home/home_screen.dart          Home, StudyDesk, AutomatedModuleTracker widget
│   ├── curriculum/
│   │   ├── curriculum_screen.dart     Subject grid/list
│   │   ├── subject_screen.dart        Per-subject tabs (Videos/QBank/Notes), bulk mark
│   │   ├── chapter_screen.dart        Chapter detail, individual item completion
│   │   ├── module_tasks_screen.dart   Daily batch view, batch rollover, stale detection
│   │   └── subject_analytics_screen.dart  Per-subject time logs, session history
│   ├── analytics/analytics_screen.dart    Global analytics, streaks, daily history bar chart
│   ├── timer/focus_timer_screen.dart      Focus timer, pill button, _SessionConfigSheet
│   ├── plan/plan_screen.dart              Study plan wizard
│   └── settings/settings_screen.dart     All user preferences
└── widgets/
    ├── timer/
    │   ├── ambient_sound_sheet.dart   Sound picker bottom sheet (Modulix white style)
    │   ├── timer_background_picker.dart  Background picker bottom sheet
    │   ├── task_picker_sheet.dart     Topic/subject selector for timer session
    │   └── mini_timer_overlay.dart    Floating timer badge (shown in ShellRoute)
    ├── automated_module_tracker.dart  Home-screen widget showing today's batch progress
    ├── study_desk_clock.dart          Animated clock widget on home screen
    ├── study_task_card.dart           Daily desk task card UI
    └── task_setup_sheet.dart          Bottom sheet for adding/editing desk tasks
```
