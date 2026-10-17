# Feature: Curriculum, Subjects & Bulk Operations

> Files:  
> - Models: `lib/models/syllabus.dart` (`Subject`, `Chapter`, `Video`, `QBankTopic`, `NotesItem`)  
> - Data Loaders: `lib/providers/syllabus_provider.dart`, `lib/data/subjects_metadata.dart`  
> - State Mutators: `lib/providers/app_state_provider.dart` (`markVideosBulk`, `markQBanksBulk`, `markNotesBulk`)  
> - UI Screens: `lib/screens/curriculum/curriculum_screen.dart`, `lib/screens/curriculum/subject_screen.dart`, `lib/screens/curriculum/chapter_screen.dart`

---

## 1. Overview & Data Hierarchy

The Curriculum module represents the comprehensive medical syllabus (supporting both **Marrow Edition 8** and **Edition 6.5**).
It organizes educational assets across 19 clinical and pre-clinical subjects into three distinct study modalities:

1. **Videos (Lectures):** Full-length chapter video modules with duration metadata.
2. **QBanks (MCQs):** Question bank modules with total question count metadata.
3. **Notes (High-Yield):** Consolidated unit-level study notes and reference review material.

### Entity Relationship Model
```
Subject (e.g. 'OBG', 'Anatomy', 'Pathology')
 ├── id, name, displayName, accent Color
 ├── chapters: List<Chapter> (Units)
 │    ├── name: 'Embryology', 'Placenta & Fetal Membranes', etc.
 │    ├── videos: List<Video>
 │    │    └── { id, title, durationMins, durationSecs, serialNumber }
 │    ├── qbanks: List<QBankTopic>
 │    │    └── { id, title, totalMcqs, serialNumber }
 │    └── notes: List<NotesItem>
 │         └── { id, title, pages, isCustom }
 └── qbankChapters: List<Chapter> (Optional dedicated QBank unit partition)
```

---

## 2. Subject View Modalities (`SubjectScreen`)

`SubjectScreen` (`lib/screens/curriculum/subject_screen.dart`) provides a segmented tab view to navigate the three modalities:

### 1. Videos Tab
- Groups lectures by Chapter / Unit.
- Displays lecture duration, global sequence numbering, and completion checkboxes.
- Offers deep link to launch lecture into Focus Timer.
- Contains the **"Mark Unit Done"** bulk completion action.

### 2. QBanks Tab
- Displays practice question modules with question counts (e.g. `45 MCQs`).
- Supports unit-level bulk marking.

### 3. Notes Tab — Consolidated Single-Topic Architecture
- **Design Rule:** Unlike videos or QBanks which may have dozens of individual sub-topics, each Chapter/Unit in Modulix has **one consolidated notes topic** named directly after the unit (e.g., Under Unit *Embryology*, the notes topic is named *"Embryology Notes"*).
- Eliminates random note fragments and mirrors standard high-yield medical textbook structure.

---

## 3. Bulk Marking Business Logic (`markVideosBulk`)

One of the most critical design rules in Modulix revolves around how bulk-marking impacts statistics and analytics.

### The Problem
If a medical student has already completed 15 chapters of Anatomy during medical school and wants to mark them as done in Modulix:
- If marking an entire unit as done added +50 videos to "Today's Study History", today's daily study velocity would show an artificial spike of 50 videos and 18 hours.
- This corrupts streak calculations, today's metrics, and daily goal completion.

### The Solution: Analytics Isolation
Modulix explicitly separates **individual module completion** from **bulk unit completion**:

```dart
// Individual Completion (lib/providers/app_state_provider.dart)
Future<void> markVideoComplete(String videoId) async {
  // 1. Adds videoId to completedVideos
  // 2. INCREMENTS dailyHistory[todayKey] (+1)
  // 3. Triggers daily goal completion check
}

// Bulk Unit Completion (lib/providers/app_state_provider.dart)
Future<void> markVideosBulk(List<String> videoIds, [String? chapterName]) async {
  await _update((s) => s.updateCurrentEdition((e) {
    final updated = Map<String, dynamic>.from(e.completedVideos);
    final nowStr = DateTime.now().toIso8601String();
    for (final id in videoIds) {
      if (!updated.containsKey(id)) {
        updated[id] = nowStr;
      }
    }
    final chapters = List<String>.from(e.bulkCompletedChapters);
    if (chapterName != null && !chapters.contains(chapterName)) {
      chapters.add(chapterName);
    }
    return e.copyWith(
      completedVideos: updated,
      bulkCompletedChapters: chapters,
      // CRITICAL: dailyHistory is NOT touched!
    );
  }));
}
```

### Result:
- **Subject & Unit Progress Cards:** Accurately show 100% completion and progress bars reflect the completed units.
- **Analytics & Daily Streaks:** Remain completely unpolluted by historical bulk imports.
- **Unmarking Bulk:** `unmarkVideosBulk` cleanly removes the IDs and strips the chapter from `bulkCompletedChapters`.

---

## 4. Multi-Edition Syllabus Swapping

Modulix allows seamless toggling between different syllabus editions (e.g. Marrow 8 vs Marrow 6.5) via `activeSyllabusProvider`:

```dart
final activeSyllabusProvider = Provider<AsyncValue<List<Subject>>>((ref) {
  final appState = ref.watch(appStateProvider);
  return appState.when(
    data: (state) {
      if (state.activeEdition == 'marrow_6_5') {
        return ref.watch(_marrow65Provider);
      }
      return ref.watch(_marrow8Provider);
    },
    ...
  );
});
```

Because completion data in `AppState` is partitioned per edition (`editions[activeEdition]`), users can switch between editions in Settings without losing their study progress on either edition.
