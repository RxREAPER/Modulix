# Modulix — Build Checkpoints Ledger

This ledger tracks every incremental change made during development. Every feature, UI tweak, bugfix, or refactoring registers a checkpoint entry here as soon as it is verified via Hot Reload / Hot Restart and `flutter analyze`.

When an APK build is triggered, all pending checkpoints are synthesized into a **Build Manifest** (release notes), verified, and marked as `✅ Included in Build`.

---

## 📋 Active Checkpoints

### [CKPT-023] Curriculum Unit Index Navigation, Deep Search Linking, Number Visibility & 3D Split-Flap Clock Precision
- **Timestamp:** 2026-10-22 13:25 UTC
- **Category:** Bug Fixes / Search & Deep-Linking / Accessibility / 3D Mechanical Flip Clock
- **Files Modified:**
  - `lib/widgets/video_tile.dart`
  - `lib/screens/curriculum/chapter_screen.dart`
  - `lib/widgets/curriculum/unit_card.dart`
  - `lib/screens/curriculum/subject_screen.dart`
  - `lib/widgets/curriculum/curriculum_search_bar.dart`
  - `lib/app.dart`
  - `lib/providers/focus_timer_provider.dart`
  - `lib/widgets/timer/sketch_flip_digit.dart` (NEW)
  - `lib/screens/timer/fullscreen_timer_screen.dart`
- **Summary:**
  - **Unit Index Links (Bug 1):** Fixed index sheet in `SubjectScreen` to strictly align with canonical `subject.chapters`, preventing mismatched offsets across different tab states. Added direct unit route navigation (`context.push`) and interactive module pills (`Videos`, `Q-Bank`, `Notes`) per sheet item, ensuring seamless deep jumps to specific unit module tabs.
  - **Search Feature Deep-Linking & Notes Indexing (Bug 2):** Indexed all unit notes (`ch.notes`) into `CurriculumSearchBar` alongside videos and Q-Banks. Resolved exact unit indices for every module type and upgraded routing from top-level subject pages to deep links `/curriculum/${s.id}/$chIndex?tab=${type}&itemId=${id}`. Updated `ChapterScreen` to ingest initial module tab and target item ID, automatically activating the corresponding module view, scrolling to the item, and highlighting it with a distinct border. Added badge chips (`SUBJECT`, `UNIT`, `VIDEO`, `Q-BANK`, `NOTES`) to search result rows.
  - **Module Number Visibility on Complete (Bug 3):** Removed opacity 0.0 hiding of serial number badges in `video_tile.dart` and `chapter_screen.dart`. When marked complete, serial numbers remain 100% visible and sharp with a gentle green tint background, while the trailing checkbox handles the smooth check stroke animation without occluding the index.
  - **Flip Clock Accuracy & 3D Mechanical Split-Flap Engine (Bug 5):** Fixed skipped seconds and jitter in `FocusTimerNotifier` by upgrading ticker to a 200ms periodic pulse with wall-clock delta `ceil()` calculation against `_sessionTargetEndTime`, emitting state updates only on integer second boundary crossings. Integrated pro 3D mechanical split-flap flip digit widget (`SketchFlipDigit`) featuring upper flap $0^\circ \to -90^\circ$ and lower flap $90^\circ \to 0^\circ$ perspective rotations, card seam dividers, side hinge notches, and ambient drop shadows.
- **Verification:**
  - Static analysis (`flutter analyze`) on all modified files passed with **0 errors and 0 warnings**.
  - Unit and widget test suite (`test/chapter_screen_test.dart`, `test/subject_unit_index_test.dart`, `test/focus_timer_idempotency_test.dart`, `test/domain5_focus_timer_sqlite_test.dart`, `test/domain3_curriculum_virtualization_test.dart`, `test/all_screens_animation_theme_test.dart`, `test/m2_regression_test.dart`) passed 100% (**47/47 tests passed**).
- **Build Status:** ⏳ Pending APK Build

---

### [CKPT-022] Unified Individual Unit Cards with Embedded Video, Q-Bank & Notes Modules and Focus Timer Shortcut
- **Timestamp:** 2026-10-22 11:00 UTC
- **Category:** Curriculum Architecture / UI Overhaul / Focus Timer Integration
- **Files Modified:**
  - `lib/models/syllabus.dart`
  - `lib/data/subjects_metadata.dart`
  - `lib/widgets/curriculum/unit_card.dart` (NEW)
  - `lib/screens/curriculum/subject_screen.dart`
  - `lib/screens/curriculum/chapter_screen.dart`
  - `test/subject_unit_index_test.dart`
- **Summary:**
  - **Unified Unit Architecture:** Replaced disjoint 3-category tab switching (`Videos` | `Q-Bank` | `Notes`) and endless flattened item rows on `SubjectScreen` with elegant, virtualized individual `UnitCard`s.
  - **Unit Representation & Content Breakdown:** Each `UnitCard` presents unit title, unit badge, content breakdown chips (Videos with duration, Q-Bank with MCQ count, Notes with page count), overall completion progress bar, chevron indicator, and an isolated **Focus Timer shortcut button** pre-targeted to that unit's metadata.
  - **Data Unification:** Canonicalized and attached Q-Bank topics directly into corresponding video chapters (`Chapter.qbanks`). Appended remaining standalone Q-Bank chapters as dedicated units so no topics are omitted across all 20 subjects.
  - **Multi-Module Unit Detail Screen:** Upgraded `ChapterScreen` into the unified unit viewer. Includes segmented module switcher for units containing multiple resource types (`Videos`, `Q-Bank`, `Notes`), tactical Q-Bank and Notes item tiles with bouncy animated checkmarks, individual module timer triggers, bulk complete confirmation dialogs, and top AppBar focus timer action.
  - **Safety & Bounds Integrity:** Preserved all 14 boundary, negative index, and route parsing safety checks in `ChapterScreen`. Updated `test/subject_unit_index_test.dart` to verify unit cards and index sheet navigation.
- **Verification:**
  - Static analysis (`flutter analyze lib/models/syllabus.dart lib/data/subjects_metadata.dart lib/widgets/curriculum/unit_card.dart lib/screens/curriculum/subject_screen.dart lib/screens/curriculum/chapter_screen.dart`) passed with **0 errors and 0 warnings**.
  - Unit and widget test suite (`test/chapter_screen_test.dart`, `test/subject_unit_index_test.dart`) passed 100% (**23/23 tests passed**).
- **Build Status:** ⏳ Pending APK Build

---

### [CKPT-021] Uniform Card Layouts, Trailing Chevrons & Ellipsis Elimination
- **Timestamp:** 2026-10-18 05:40 UTC
- **Category:** UI Polish / Settings UX / Mobile Verification
- **Files Modified:**
  - `lib/screens/settings/settings_screen.dart`
- **Summary:**
  - Standardized all navigation cards (`Appearance & Theme`, `Syllabus & Curriculum`, `Notifications & Preferences`) to use clean `Icons.chevron_right_rounded` trailing indicators, matching the resource hub cards.
  - Eliminated all text truncation across cards on real devices: "Notifications & Preferences" title, "Study reminders, streak & routine alerts" subtitle, and "Marrow Edition 8" now render completely with zero ellipsis.
  - Subtitle on Theme Appearance simplified to "Active Atmosphere" for crisp readability.
- **Verification:**
  - Static analysis (`flutter analyze`) passed with **0 errors and 0 warnings**.
  - Compiled debug APK and installed on connected physical device **OnePlus 13R** (`ba009d81`).
  - Physically verified on device with full-screen capture (`settings_top_verified_v3.png`, `settings_scrolled_verified_v3.png`).
- **Build Status:** ✅ Included in Build v1.2.7

---

### [CKPT-020] Minimalist Settings Cards, Full Customize Persona Text, Creative Theme Swatches, Clean Theme Studio & Dedicated Notifications Page
- **Timestamp:** 2026-10-18 05:20 UTC
- **Category:** UI Polish / Settings UX / Theme Studio / Syllabus Edition / Notifications Architecture
- **Files Modified:**
  - `lib/screens/settings/notifications_preferences_screen.dart` (NEW)
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/settings/theme_studio_screen.dart`
  - `lib/screens/settings/syllabus_edition_screen.dart`
  - `lib/app.dart`
- **Summary:** Addressed 8-point refinement to the Settings screen, Theme Studio, and Syllabus Edition:
  - **Doctor Profile Card:**
    - Removed redundant text (`NEET-PG Aspirant • Physician`) and syllabus tag pill from the profile card.
    - Preserved large physician name typography and avatar with customize tap.
  - **Customize Persona Button:**
    - Fixed truncation by assigning responsive `flex: 3` to "Customize Persona" and `flex: 2` to "Edit Name", ensuring full text renders without ellipsis.
  - **Minimalist Cloud Sync Card:**
    - Converted into a clean, minimalist 1-row box matching all other standard cards on the page.
    - Eliminated verbose explanation essays and oversized buttons; displays current status ("Guest Mode • Local only" or user email) with clean "Sign In >" action.
  - **Creative & Minimalist Theme Appearance Card:**
    - Created an artistic, overlapping 3-disc palette swatch cluster showing the active atmosphere's scaffold, accent, and secondary accent colors with subtle drop-shadows.
    - Shows preset title, subtitle ("Active Atmosphere • Tap to customize"), and clean "Studio >" action navigating to `/theme-studio`.
  - **Theme Studio Simplification:**
    - Removed top banner (`"Calibrated for extended medical reading..."`).
    - Stripped simulated mini-app live preview canvas from theme cards; converted to minimalist layout showing title, description, circular selection indicator, and palette swatches.
  - **Syllabus Edition Streamlining:**
    - Removed `"Progress Isolation Guarantee"` banner and multi-line descriptions from syllabus switching.
    - Simplified cards strictly for fast switching between Marrow Edition 8 and Edition 6.5 with concise subject and lecture badges.
  - **Dedicated Notifications & Preferences Screen:**
    - Relocated 250-line inline duty rollover boundary (3:00–7:00 AM chips) and reminder toggles out of Settings into dedicated sub-page (`/notifications-preferences`).
    - Represented on Settings by a uniform standard card titled "Notifications & Preferences" with direct route navigation.
- **Verification:**
  - Static analysis (`flutter analyze`) on all 5 files passed with **0 errors and 0 warnings**.
  - Unit test suite passed 100% (`test/theme_system_test.dart`, `test/auth_screen_test.dart`, `test/theme_enhancements_verification_test.dart`).
  - Debug APK built cleanly in 134.8s (`build/app/outputs/flutter-apk/app-debug.apk`).
- **Build Status:** ✅ Included in Build v1.2.6

---

### [CKPT-019] Settings Redesign, Full-Page Artsy Auth Screen, Dedicated Syllabus Edition Screen & Danger Zone Relocation
- **Timestamp:** 2026-10-18 04:45 UTC
- **Category:** UI / Redesign / Auth Architecture / Syllabus Management / Settings
- **Files Modified:**
  - `lib/screens/settings/syllabus_edition_screen.dart` (NEW)
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/auth/auth_screen.dart`
  - `lib/screens/settings/about_support_sheet.dart`
  - `lib/screens/settings/theme_studio_screen.dart`
  - `lib/screens/timer/focus_timer_screen.dart`
  - `lib/app.dart`
  - `test/auth_screen_test.dart`
- **Summary:** Complete redesign of the Settings screen, transformation of authentication into an artsy full-page experience, dedicated syllabus edition management, and architecture cleanup:
  - **Elevated Doctor Profile Card:**
    - Expanded badge with 68px/72px avatar, bold physician title, NEET-PG Aspirant subtitle, and active syllabus edition pill.
    - Side-by-side action chips for "Customize Persona" and "Edit Name" with responsive `Flexible` protection against viewport overflows.
  - **Cloud Sync & Multi-Device Card:**
    - Redesigned status card with active guest/authenticated state, clear benefits explanation, and direct CTA navigating to the dedicated auth page.
  - **Full-Page Artsy Auth Screen (`/auth`):**
    - Converted from a modal bottom sheet into a dedicated full-page screen matching user mockup specifications.
    - Custom organic header curve (`_ArtsyWaveHeader`), hand-drawn sketch insignia/logo, segmented mode switcher (`Sign In` | `Create Account` | `Magic Link`), sketch form fields with visibility toggles, branded Google Sign-In button, Domain A error shielding via `ErrorTranslatorService`, and "Continue as Guest" fallback.
  - **Dedicated Syllabus Edition Screen (`/syllabus-edition`):**
    - Created dedicated full page for switching between Marrow Edition 8 (Current Standard) and Edition 6.5 (Classic Foundation).
    - Progress Isolation Guarantee banner explaining that video marks, notes, and task queues are preserved independently per edition.
    - Responsive stat badges and activation buttons with Wrap auto-flow.
  - **Theme Studio Text Refinement:**
    - Condensed verbose study atmospheres copy into a sleek clinical card: *"Calibrated for extended medical reading. Reduced glare, zero eye strain."*
    - "Customize Theme" preview box in Settings displaying active theme swatches and direct navigation to Theme Studio.
  - **Clinical Routine & Alerts Section:**
    - Unified day start & rollover boundary (3 AM to 7 AM time pills) with notification reminder switches and time pickers.
  - **Feature Cleanup & Danger Zone Relocation:**
    - Removed legacy "Interactive Feature Tour" card and `TourSpotlightOverlay` mounts.
    - Removed "App Guide & Reference" card.
    - Relocated Danger Zone ("Reset All Study Progress") into the About & Support sheet with strict confirmation dialog (`RESET`).
- **Verification:**
  - `flutter analyze lib/` passed with **0 errors and 0 warnings** (288 clean infos).
  - All unit & widget tests passed 100% (`test/auth_screen_test.dart`, `test/theme_system_test.dart`, `test/domain7_backup_privacy_test.dart`).
  - Full debug APK built in 141.8s, installed on OnePlus 13R (`ba009d81`), and visually verified via screenshots (`settings_perfect_verified_ckpt19.png`, `auth_screen_verified_ckpt19.png`, `syllabus_edition_clean_verified_ckpt19.png`, `theme_studio_screen_verified_ckpt19.png`, `about_support_sheet_verified_ckpt19.png`).
- **Build Status:** ✅ Included in Build v1.2.5 (app-debug.apk installed & verified on OnePlus 13R ba009d81)

---

### [CKPT-018] Centralized Error Translation Engine, Crash Shield, Route 404, Shimmer Skeletons & Desk Bubble Prompt
- **Timestamp:** 2026-10-18 03:50 UTC
- **Category:** Architecture / Error Handling / Crash Shield / Shimmer Skeletons / UX Polish
- **Files Modified:**
  - `lib/services/error_translator_service.dart` (NEW)
  - `lib/widgets/errors/diagnostic_telemetry_drawer.dart` (NEW)
  - `lib/widgets/errors/modulix_error_scaffold.dart` (NEW)
  - `lib/widgets/errors/route_error_view.dart` (NEW)
  - `lib/widgets/errors/app_error_state_view.dart` (NEW)
  - `lib/widgets/loading/app_shimmer.dart` (NEW)
  - `test/error_translator_service_test.dart` (NEW)
  - `test/error_widgets_test.dart` (NEW)
  - `test/home_bubble_prompt_test.dart` (NEW)
  - `lib/main.dart`
  - `lib/app.dart`
  - `lib/screens/home/home_screen.dart`
  - `lib/screens/curriculum/curriculum_screen.dart`
  - `lib/screens/curriculum/chapter_screen.dart`
  - `lib/screens/curriculum/subject_screen.dart`
  - `lib/screens/curriculum/subject_analytics_screen.dart`
  - `lib/screens/curriculum/module_tasks_screen.dart`
  - `lib/screens/plan/plan_screen.dart`
  - `lib/screens/analytics/analytics_screen.dart`
  - `test/study_desk_test.dart`
- **Summary:** Complete production error handling system, professional shimmer loading skeletons, and first-time desk prompt overhaul:
  - **Doctor-Facing Error Translation Catalog (Domains A through E):**
    - Built `ErrorTranslatorService` translating technical raw exceptions across 5 distinct domains into reassuring, actionable doctor-facing headlines and explanations.
    - Zero raw exceptions, error codes, or stack traces shown in UI body copy.
    - Collapsible `DiagnosticTelemetryDrawer` with copy-to-clipboard button cleanly stores technical debug details.
  - **Global Crash Shield & Route 404:**
    - Replaced Flutter's red/grey screen of death with `ModulixErrorScaffold` via `ErrorWidget.builder`, reassuring doctors that local SQLite cache is intact and offering "Reopen App" and "Copy Error Report".
    - Handled GoRouter unknown routes via `RouteErrorView` ("Destination Not in Syllabus").
  - **Component-Level Shimmer Skeletons:**
    - Created `AppShimmer` with paper/parchment matching linear gradients: `CurriculumSkeletonView`, `ModuleTimelineSkeletonView`, `DeskTasksSkeletonView`, `AnalyticsSkeletonView`.
    - Integrated throughout Curriculum, Subject, Chapter, Tasks, Plan, Analytics, and Home Desk.
  - **Desk Bubble Prompt Overhaul:**
    - Replaced oversized stationery card with sleek, compact speech-bubble prompt hugging Today's Tasks header.
    - Two-line clinical copy: *"Isolate 3–4 high-yield objectives for today."* / *"Streaks hold until 5:00 AM post-duty."*
    - Direct `[+ Plan]` action and one-tap dismissal `(X)` with persistence (`seen_first_desk_intro`).
- **Verification:**
  - `flutter analyze lib/` passed with **0 errors and 0 warnings**.
  - All unit & widget tests passed 100% (`test/error_translator_service_test.dart`, `test/error_widgets_test.dart`, `test/home_bubble_prompt_test.dart`, `test/chapter_screen_test.dart`, `test/study_desk_test.dart`).
  - Full debug APK built in 123.5s, installed, and physically verified with screenshot on OnePlus 13R (`ba009d81`).
- **Build Status:** ✅ Included in Build v1.2.4 (app-debug.apk installed & verified on OnePlus 13R ba009d81)

---

### [CKPT-017] In-Situ Hint Pills, First-Session Desk Card, Redundant Text Removal & Discovery Pulses
- **Timestamp:** 2026-10-18 02:30 UTC
- **Category:** UX / First-Time Experience / In-Situ Hint Pills / Discovery Pulses
- **Files Modified:**
  - `lib/widgets/discovery_pulse.dart` (NEW)
  - `test/discovery_pulse_test.dart` (NEW)
  - `lib/screens/home/home_screen.dart`
  - `lib/widgets/automated_module_tracker.dart`
  - `lib/screens/plan/plan_screen.dart`
  - `lib/screens/curriculum/chapter_screen.dart`
  - `lib/screens/curriculum/subject_screen.dart`
  - `lib/screens/curriculum/subject_analytics_screen.dart`
  - `lib/screens/analytics/analytics_screen.dart`
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/settings/learn_the_app_sheet.dart`
  - `lib/screens/timer/focus_timer_screen.dart`
  - `lib/widgets/in_situ_hint_pill.dart`
- **Summary:** Replaced passive onboarding reading with contextual, professional first-use guidance mechanisms:
  - **In-Situ Hint Pills:** Added minimalist, professional hint pills across major pages with `SharedPreferences` persistence and one-tap dismissal:
    - Subject Curriculum: concise 1-line prompt explaining swipe-to-complete videos.
    - Subject Analytics: in-situ pill explaining automated classification into Videos, Q-Bank, and Notes.
    - Main Analytics: in-situ pill highlighting Performance Hubs.
    - Focus Timer main dock: in-situ pill explaining mini-timer docking and flip clock mode.
    - Focus Timer setup sheet: in-situ pill explaining target focus vs open stopwatch modes.
  - **First Study Session Quick-Start Card:** Redesigned empty module plan tracker on Home Desk with clean 3-step engine pills (Exam Date, Daily Quota, Auto Batches) and direct link to Plan Setup.
  - **Stationery Intro Desk Pad:** One-time introductory stationery state for new doctors explaining the 3–4 high-yield daily objective model, with 5:00 AM reset note and primary action button; subsequent days automatically render the compact quiet state.
  - **Plan Setup Text Pruning:** Removed redundant, verbose instructional paragraphs from Steps 1, 2, and 3 in `PlanScreen`, streamlining the interface to intuitive, common-sense controls.
  - **Discovery Pulses (Breathing Glow Rings):** Created `DiscoveryPulse` widget that renders a subtle, pulsating visual cue around high-utility features until interacted with (applied to Landscape Flip Clock on Focus Timer and Chapter Bulk Complete in Chapter Screen).
  - **Reference & Guide Repurposing:** Renamed "Learn the App" to "App Guide & Reference" for replayable tour, core mechanics, and medico FAQs.
- **Verification:** `flutter analyze lib/` passed with **0 errors and 0 warnings**; unit tests passed (`test/discovery_pulse_test.dart`, `test/in_situ_hint_pill_test.dart`, and `test/chapter_screen_test.dart`).
- **Build Status:** ✅ Included in Build v1.2.3 (Commit aed66c1, app-debug.apk built in 149.9s, installed & physically verified on OnePlus 13R ba009d81)

---

### [CKPT-016] Systematic Bug Testing, 7 Domain Test Suites & Complete Warning Eradication
- **Timestamp:** 2026-10-17 19:45 UTC
- **Category:** Bug Testing / Quality Assurance / Code Health / Zero Warnings
- **Files Modified:**
  - `lib/services/storage_service.dart`
  - `lib/screens/home/home_screen.dart`
  - `lib/screens/curriculum/curriculum_screen.dart`
  - `lib/data/subjects_metadata.dart`
  - `lib/data/standard_resources.dart`
  - `lib/screens/timer/focus_timer_screen.dart`
  - `lib/screens/timer/fullscreen_timer_screen.dart`
  - `lib/screens/curriculum/subject_analytics_screen.dart`
  - `lib/screens/settings/data_privacy_sheet.dart`
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/onboarding/widgets/onboarding_illustrations.dart`
  - `test/domain1_startup_lifecycle_test.dart`
  - `test/domain2_home_tasks_test.dart`
  - `test/domain3_curriculum_virtualization_test.dart`
  - `test/domain4_pacing_engine_test.dart`
  - `test/domain5_focus_timer_sqlite_test.dart`
  - `test/domain6_analytics_sheets_test.dart`
  - `test/domain7_backup_privacy_test.dart`
- **Summary:** Systematic module-by-module test suite creation, edge-case hardening, and total elimination of all static analysis warnings across `lib/`:
  - **Domain 1 (Startup Lifecycle & State Hydration):** Safe null promotion on `SharedPreferences` in `StorageService` eliminating unchecked non-null assertions. Created `domain1_startup_lifecycle_test.dart` verifying empty state defaults, automatic legacy key migration (`flowmd_flutter_app_state` -> `modulix_app_state`), and direct routing to Home Desk.
  - **Domain 2 (Home Desk & Task System):** Removed unsupported `cacheExtent` parameter on `SingleChildScrollView`. Created `domain2_home_tasks_test.dart` verifying 5 AM day start boundary calculation, streak computation, and `DailyDeskTask` JSON roundtrip.
  - **Domain 3 (Curriculum & Syllabus Virtualization):** Wrapped horizontal sort chips row in `RepaintBoundary` in `CurriculumScreen`. Eradicated unused `standardBooks` variable in `subjects_metadata.dart` and unused `models/syllabus.dart` import in `standard_resources.dart`. Created `domain3_curriculum_virtualization_test.dart` verifying syllabus parsers and sort ordering.
  - **Domain 4 (Study Plan & Pacing Engine):** Verified and hardened `MetricsService.calculateETA` divide-by-zero protection (clamp pace to >= 1), past deadline safety, on-track status, and unit filters in `domain4_pacing_engine_test.dart`.
  - **Domain 5 (Focus Timer & Audio Engine):** Removed unused `_fmt` method, unreferenced `_topicIcon` method, and redundant `log` variable in `FocusTimerScreen`. Removed unused `timer_theme.dart` import in `FullscreenTimerScreen`. Created `domain5_focus_timer_sqlite_test.dart` verifying `TimeLog` serialization, SQLite date-range filtering, and phase modeling.
  - **Domain 6 (Analytics Hub & Sheets):** Wrapped top banner card in `RepaintBoundary` for render isolation in `SubjectAnalyticsScreen`. Created `domain6_analytics_sheets_test.dart` verifying log aggregation by topic type, 5 AM study day attribution, and progress bounds clamping.
  - **Domain 7 (Settings, Privacy & Warning Elimination):** Cleaned up 8 unused imports, removed unused `appState` variable, accelerated sheet animations to 200ms/150ms, and migrated all deprecated `withOpacity` to `withValues(alpha: ...)` in `DataPrivacySheet`. Removed unused `appearance_theme_sheet.dart` in `SettingsScreen` and unused `dart:async` in `OnboardingIllustrations`. Created `domain7_backup_privacy_test.dart` verifying backup schema integrity.
- **Verification:** `flutter analyze lib/` passed with **0 errors and 0 warnings** (100% clean); all 43 test suites passed (**227/227 tests green**).
- **Build Status:** ✅ Included in Build v1.2.2 (Commit ea080b1, app-debug.apk built in 137.9s, installed & verified on OnePlus 13R ba009d81)

---

### [CKPT-015] Async Startup, MultiSliver Timeline Virtualization, Plan Gesture Isolation & Sheet Caching
- **Timestamp:** 2026-10-17 17:45 UTC
- **Category:** Performance / Virtualization / Async Startup / 120 FPS Scrolling
- **Files Modified:**
  - `lib/main.dart`
  - `lib/app.dart`
  - `lib/screens/home/home_screen.dart`
  - `lib/widgets/automated_module_tracker.dart`
  - `lib/screens/curriculum/module_tasks_screen.dart`
  - `lib/screens/plan/plan_screen.dart`
  - `lib/widgets/curriculum/module_timeline.dart`
  - `lib/screens/curriculum/subject_screen.dart`
  - `lib/widgets/analytics/daily_tasks_analytics_sheet.dart`
  - `lib/widgets/analytics/focus_timer_analytics_sheet.dart`
  - `lib/widgets/analytics/study_plan_analytics_sheet.dart`
  - `test/analytics_streak_theme_test.dart`
  - `test/theme_enhancements_verification_test.dart`
- **Summary:** Complete eradication of app launch drag, timeline scroll lag, plan gesture contention, and sheet opening latency:
  - **Instantaneous Non-blocking Cold/Warm Startup:** Parallelized critical local database and storage initializations via `Future.wait([RiveNative.init(), StorageService.init(), DatabaseService.instance.database])` and decoupled non-essential cloud/observability services (`Firebase`, `NotificationService`, `AuthService`, `AnalyticsService`, `CrashReportingService`) into background `unawaited(_initBackgroundServices())` to eliminate the 1.5–2s first-frame launch freeze.
  - **Cold Launch Router Handshake Fix:** Fixed `routerProvider` listenable from `ValueNotifier<bool>(false)` to `ValueNotifier<bool?>(null)`, ensuring the initial transition from async loading storage state to ready state immediately notifies GoRouter redirect instead of remaining stuck on root.
  - **MultiSliver True Lazy List Virtualization:** Upgraded `ModuleTimeline` to use `MultiSliver` from `sliver_tools`, virtualizing every unit chapter via `SliverChildBuilderDelegate`. Flutter now lazily instantiates only visible viewport rows (5–6 items) rather than 40–50 heavy rows at once, locking rendering to steady 120 FPS with 0 jank frames.
  - **Plan Setup Screen Scroll & Gesture Isolation:** Wrapped horizontal subject carousel in `RepaintBoundary` with `cacheExtent: 350.0` to eliminate gesture conflict and repainting cascades during vertical scrolling. Isolated Step 2 Deadline Date Card & Daily Module Target Stepper in `RepaintBoundary` and replaced heavy `ClipRect(child: AnimatedSize)` with lightweight `AnimatedCrossFade`.
  - **Subpage Analytics Sheets & Unit Index Popups:** Wrapped sheet containers in `RepaintBoundary` and tuned `cacheExtent: 400.0` across Daily Tasks, Focus Timer, and Study Plan sheets. Added snappy `sheetAnimationStyle` (200ms open / 150ms close) and `cacheExtent: 350.0` to Unit Index selector popup.
  - **Automated Tracker Loop Elimination:** Added `static String? _lastCheckedKey` guards to `AutomatedModuleTracker` and `ModuleTasksScreen` to stop repeated disk I/O and post-frame callback rebuild loops on every render tick.
- **Verification:** `flutter analyze lib/` passed with 0 compile errors; test suite passed (100% green across all unit and widget tests).
- **Build Status:** ✅ Included in Build v1.2.1 (Commit e84ef6e, app-debug.apk built successfully)

---

### [CKPT-014] High-Speed App Animations, Apple Spring Physics & Sheet Optimizations
- **Timestamp:** 2026-10-17 16:55 UTC
- **Category:** Animation / Performance / Apple Spring Physics / Package Integration
- **Files Modified:**
  - `pubspec.yaml` & `pubspec.lock`
  - `lib/widgets/animations/apple_pressable.dart`
  - `lib/widgets/animations/page_entrance.dart`
  - `lib/app.dart`
  - `lib/screens/analytics/analytics_screen.dart`
  - `lib/widgets/analytics/study_plan_analytics_sheet.dart`
  - `lib/widgets/analytics/focus_timer_analytics_sheet.dart`
  - `lib/widgets/analytics/daily_tasks_analytics_sheet.dart`
  - `lib/screens/curriculum/subject_analytics_screen.dart`
  - `lib/screens/curriculum/curriculum_screen.dart`
  - `lib/widgets/curriculum/square_subject_card.dart`
  - `lib/widgets/curriculum/module_timeline.dart`
  - `lib/screens/curriculum/chapter_screen.dart`
  - `lib/screens/curriculum/module_tasks_screen.dart`
- **Summary:** Deep application-wide animation acceleration and physics calibration:
  - **Dependency Additions:** Integrated `sprung: ^3.0.1`, `sliver_tools: ^0.2.12`, `flutter_animate: ^4.5.2` for native spring curves, sliver toolkits, and declarative animations.
  - **Apple-Calibrated Spring Curves:** Upgraded `ApplePressable` with `Sprung.underDamped` curves on touch release and ultra-responsive 70ms touch-down compression for an authentic iOS/OxygenOS mechanical tactile rebound.
  - **Snappy Transitions (180–200ms):** Accelerated page routing transitions (`_buildFadeTransitionPage` to 180ms/140ms, `_buildSlideUpTransitionPage` to 200ms/160ms, `_buildSlideHorizontalTransitionPage` to 190ms/150ms). Replaced heavy `CupertinoPage` modal transitions with customized slide-horizontal transitions.
  - **Subpage Analytics Sheets:** Accelerated bottom sheet animation styles (`sheetAnimationStyle` duration 200ms, reverseDuration 150ms) across Study Plan, Focus Timer, and Daily Tasks analytics sheets. Wrapped all sheet content in `FadeSlideEntrance(180ms)`, wrapped fl_chart `BarChart` in `RepaintBoundary`, and wrapped session log cards and task rows in `ApplePressable(pressedScale: 0.98)`.
  - **Curriculum & Module Views:** Accelerated timeline unit expansion and tab slide durations in `ModuleTimeline` from 260ms to snappy 180ms. Added animated progress bar width (`TweenAnimationBuilder`) to `SquareSubjectCard`. Wrapped `ChapterScreen` and `ModuleTasksScreen` bodies in `FadeSlideEntrance(180ms)` with 450px cache extent for smooth 120 FPS scrolling.
- **Verification:** `flutter analyze` passed with 0 compile errors/warnings across all 13 modified files; test suite passed (14/14 tests green across `study_desk_test.dart` and `m2_regression_test.dart`).
- **Build Status:** ✅ Included in Build v1.2.0 (Verified on OnePlus 13R ba009d81)

---

### [CKPT-013] Curriculum Scroll Animations, Sub-Page Popups & Immediate Click Feedback
- **Timestamp:** 2026-10-17 15:15 UTC
- **Category:** Animation / Performance / Tactile Feedback / GitHub Repo Setup
- **Files Modified:**
  - `lib/widgets/animations/apple_pressable.dart`
  - `lib/widgets/curriculum/module_timeline.dart`
  - `lib/screens/curriculum/subject_screen.dart`
  - `lib/widgets/curriculum/square_subject_card.dart`
  - `lib/app.dart`
  - `.github/workflows/ci.yml`
  - `.github/workflows/build_apk.yml`
  - `.github/pull_request_template.md`
  - `.github/ISSUE_TEMPLATE/*`
  - `README.md`
  - `LICENSE`
  - `CONTRIBUTING.md`
  - `CHANGELOG.md`
- **Summary:** Complete optimization of scroll animations, sub-page popups, tactile touch feedback, and GitHub repository professionalization:
  - **Immediate Click & Touch Feedback:** Upgraded `ApplePressable` with minimum 60ms visual dwell and `AnimatedOpacity` support. Wrapped all timeline cards (`_TimelineCard`) and bubbles (`TimelineCheckBubble`) in `ApplePressable(pressedScale: 0.98)` for instantaneous physical depression on finger touch.
  - **Sub-Page Popup Rendering (`_openIndexSheet`):** Precomputed unit statistics in O(N) prior to rendering `ListView.separated`. Replaced `InkWell` with `ApplePressable(pressedScale: 0.97, pressedOpacity: 0.88)` on all unit rows. Replaced heavy `ClipRRect(child: LinearProgressIndicator)` with lightweight canvas-decorated progress bars. Sequenced popup dismissal and viewport scroll with a clean 120ms pause to eliminate frame competition.
  - **Module Timeline 120 FPS List Virtualization:** Replaced `ClipRect(child: AnimatedSize(...))` layout measuring during scroll with steady-state `SizeTransition` powered by an isolated `AnimationController`. Wrapped each timeline item row and custom connector line in an isolated `RepaintBoundary` to eliminate GPU repaint cascades during scrolling.
  - **Scroll Physics & Page Transitions:** Tuned `scrollCacheExtent` to `const ScrollCacheExtent.pixels(450.0)` in `SubjectScreen`. Deferred `recordVisit` Riverpod invalidation by 350ms so push animations maintain 120 FPS. Replaced heavy `CupertinoPage` transitions with high-performance 240ms cubic slide-fade transitions across curriculum sub-routes.
  - **Professional GitHub Repository:** Created production-grade `README.md`, `LICENSE`, `CONTRIBUTING.md`, `CHANGELOG.md`, GitHub Actions CI and build workflows, PR and Issue templates, clean `.gitignore`, and tracked all project files.
- **Verification:** `flutter analyze` passed with 0 issues across all modified files; test suites passed (23/23 tests green across `subject_unit_index_test.dart` and `chapter_screen_test.dart`).
- **Build Status:** ✅ Included in Build v1.2.0 (Commit 2f08f9f, app-debug.apk installed & verified on OnePlus 13R)

---

### [CKPT-012] Full-Row Interactive Touch Targets & Timeline Sliver Virtualization
- **Timestamp:** 2026-10-17 13:55 UTC
- **Category:** Touch Latency / UI Performance / Virtualization
- **Files Modified:**
  - `lib/widgets/curriculum/module_timeline.dart`
  - `lib/widgets/animations/apple_pressable.dart`
  - `lib/screens/curriculum/module_tasks_screen.dart`
- **Summary:** Completely eradicated perceived click lag, missed taps, and dropped interactions:
  - **Full-Row Interactive Touch Target:** Made `_TimelineCard` responsive across the entire row surface (topic title, subtitle, duration, and card background) via `GestureDetector(behavior: HitTestBehavior.opaque, onTap: onToggle)`. Tapping anywhere on a row instantly toggles completion with light haptic feedback.
  - **Isolated Timer Gesture Target:** Isolated the Focus Timer `IconButton` so tapping the timer icon opens the timer without triggering the card completion toggle.
  - **Generous Touch Paddings:** Added hit padding to `TimelineCheckBubble` (expanding touch area from 28x28 to 44x44px) and `_AnimatedCardCheckbox` (padded to 30x30px) so thumb taps on high-DPI displays never miss the gesture arena.
  - **Direct Sliver Virtualization:** Set `ModuleTimeline.build` to return `buildSliver(context)` directly, ensuring 100% native sliver virtualization without shrink-wrapped `CustomScrollView` wrappers.
  - **Zero-Dead-Zone Pressable:** Set `ApplePressable`'s `HitTestBehavior` from `translucent` to `opaque`, ensuring touch-down scale feedback triggers immediately even when tapping transparent padding.
  - **Module Tasks Hit Expansion:** Added tap handling to the circular number bubble in `ModuleTasksScreen` and removed redundant nested `ApplePressable` on the internal checkbox.
- **Verification:** `flutter analyze` passed with 0 issues on all modified files; test suite passed (28/28 tests green across `apple_pressable_test.dart`, `chapter_screen_test.dart`, `subject_unit_index_test.dart`).
- **Build Status:** ✅ Included in Build v1.2.0 (Commit 2f08f9f, app-debug.apk installed & verified on OnePlus 13R)

---

### [CKPT-011] Root Reactive Rebuild Storm Elimination & Asynchronous Storage Engine
- **Timestamp:** 2026-10-17 10:30 UTC
- **Category:** Architecture / State Management / Performance
- **Files Modified:**
  - `lib/app.dart`
  - `lib/providers/app_state_provider.dart`
  - `lib/widgets/animations/apple_pressable.dart`
  - `lib/screens/curriculum/curriculum_screen.dart`
- **Summary:** Completely eradicated the root cause of app-wide tap latency and navigation sluggishness:
  - **Scoped GoRouter Refresh:** Removed coarse `refreshListenable` watching the monolithic `appStateProvider`. `routerProvider` now selectively observes only `onboardingDone`, preventing full router path matching and route rebuild cascades on every user tap/check/interaction.
  - **Eliminated Root MaterialApp Rebuild Cascade:** Implemented value equality (`operator ==` and `hashCode`) on `ModulixAppThemeData` and scoped `appThemeDataProvider` via `.select` exclusively to `palettePresetId` and `themePref`. State mutations no longer re-evaluate the root `MaterialApp.router` or force rebuilds across all 4 `IndexedStack` branch trees.
  - **Scoped Shell State Subscriptions:** Removed redundant `ref.watch(appThemeDataProvider)` from `MainShell` and scoped `focusTimerProvider` watching to `sessionActive`.
  - **Non-blocking Asynchronous Storage:** Wrapped `StorageService.instance.save(updated)` in `unawaited(...)` inside `AppStateNotifier._update`, preventing JSON serialization and SharedPreferences I/O from blocking tap response on the main UI thread.
  - **Removed Redundant Card Tap I/O:** Removed synchronous `recordVisit()` from `SquareSubjectCard.onTap` which was triggering disk I/O and grid re-sorting during push transitions.
  - **Zero-Ticker Pressable:** Replaced `AnimationController` and `Listener` in `ApplePressable` with native `GestureDetector` and compositor `AnimatedScale`.
- **Verification:** `flutter analyze` passed with 0 issues on all modified files; test suite passed (37/37 tests green across `apple_pressable_test.dart`, `tab_persistence_test.dart`, `theme_system_test.dart`, `curriculum_sort_test.dart`, `chapter_screen_test.dart`, `lovable_nav_bar_test.dart`).
- **Build Status:** ✅ Included in Build (Commit 1d498c9, app-debug.apk compiled in 79.1s)

---

### [CKPT-010] Performance & Latency Restoration: Zero-Lag Interactions, Root Clip Removal & Painter Optimization
- **Timestamp:** 2026-10-17 10:05 UTC
- **Category:** Performance / Graphics / Touch Latency
- **Files Modified:**
  - `lib/widgets/animations/apple_pressable.dart`
  - `lib/widgets/animations/animated_strike_text.dart`
  - `lib/widgets/animations/page_entrance.dart`
  - `lib/widgets/curriculum/subject_sketch_icon.dart`
  - `lib/widgets/study_desk_clock.dart`
  - `lib/app.dart`
- **Summary:** Resolved pervasive device lag, click delay, and navigation stutter:
  - **Zero-Latency Touch Response:** Eliminated `HitTestBehavior.opaque` blocking and offscreen `ClipRRect` inside `ApplePressable`. Immediate callback invocation prior to haptic dispatch prevents gesture arena stalls.
  - **Zero-Layout in Paint:** Replaced `_StrikeLinePainter` inside `AnimatedStrikeText` (which was executing `TextPainter.layout()` inside `paint()`) with native C++ `TextDecoration.lineThrough` smooth color interpolation.
  - **Eliminated Whole-App Viewport Clip:** Removed `ModalSheetRecessWrapper`'s whole-app `ClipRRect` and `AnimatedScale` from the root shell, eliminating persistent offscreen `saveLayer` render passes across the application.
  - **Removed GPU Opacity Buffers:** Converted `PageEntrance` from raw `Opacity` layers to compositor-backed `FadeTransition`.
  - **RAM & VRAM Optimization:** Added `cacheWidth: 80` to `SubjectSketchIcon` (decoding 512x512 images directly to thumbnail size, saving ~95% RAM) and `cacheWidth: 1080` to `StudyDeskClock` ornate sketch frame.
- **Verification:** `flutter analyze` 0 errors on modified files; comprehensive test suite passed (44/44 tests green across `apple_pressable_test.dart`, `tab_persistence_test.dart`, `plan_screen_test.dart`, `chapter_screen_test.dart`, `curriculum_sort_test.dart`, `theme_system_test.dart`, `lovable_nav_bar_test.dart`, `animated_strike_text_test.dart`, `animated_check_stroke_test.dart`).
- **Build Status:** ✅ Included in Build (Commit 54f85fb, app-debug.apk compiled in 90.2s)

---

### [CKPT-009] Fix StatefulShellBranch Back Navigation Pop Stack & Eliminate Touch-Down GPU Rasterizer Overhead
- **Timestamp:** 2026-10-17 08:45 UTC
- **Category:** Navigation / Performance / Graphics
- **Files Modified:**
  - `lib/app.dart`
  - `lib/widgets/animations/apple_pressable.dart`
- **Summary:** Completely resolved branch escape bug and touch-down click lag:
  - Fixed `MainShell`'s `PopScope` which previously intercepted sub-screen pops inside `StatefulShellBranch` (Curriculum -> Subject -> Chapter) and prematurely redirected to `goBranch(0)`. It now queries the active branch navigator key (`_shellNavigatorKeyCurriculum`, etc.) and pops branch routes properly before tab switching.
  - Eliminated the expensive `Opacity` widget offscreen pass (`saveLayerAlpha`) inside `ApplePressable`. Interactive taps now use zero-copy GPU matrix scaling (`Transform.scale`) without creating intermediate offscreen buffers on 120Hz displays.
  - Added `onTapCancel` handling in `ApplePressable` so scrolling lists with buttons immediately cancels compression without remaining stuck down.
- **Verification:** `flutter analyze lib/app.dart lib/widgets/animations/apple_pressable.dart` passed with 0 issues; all unit tests in `apple_pressable_test.dart`, `tab_persistence_test.dart`, `plan_screen_test.dart`, `chapter_screen_test.dart`, `database_service_test.dart`, `curriculum_sort_test.dart` passed (29/29 tests green).
- **Build Status:** ✅ Included in Build (Debug APK Installed on OnePlus 13R)

---

### [CKPT-008] Fix Navigation Pop Traps, Enable Android Predictive Back & Eliminate Idle Ticker Loops
- **Timestamp:** 2026-10-17 08:15 UTC
- **Category:** Performance / Navigation / Android
- **Files Modified:**
  - `android/app/src/main/AndroidManifest.xml`
  - `lib/app.dart`
  - `lib/screens/settings/theme_studio_screen.dart`
  - `lib/screens/plan/plan_screen.dart`
  - `lib/screens/curriculum/chapter_screen.dart`
  - `lib/screens/curriculum/subject_analytics_screen.dart`
  - `lib/screens/curriculum/module_tasks_screen.dart`
  - `lib/screens/curriculum/subject_screen.dart`
  - `lib/screens/timer/focus_timer_screen.dart`
  - `lib/screens/timer/fullscreen_timer_screen.dart`
  - `lib/screens/home/home_screen.dart`
  - `lib/widgets/curriculum/study_plan_banner.dart`
  - `lib/screens/analytics/analytics_screen.dart`
- **Summary:** Resolved pervasive debug lag and screen-closing failure:
  - Fixed `PopScope` blocking traps across 8 sub-screens (`theme_studio_screen`, `plan_screen`, `chapter_screen`, `subject_analytics_screen`, `module_tasks_screen`, `subject_screen`, `focus_timer_screen`, `fullscreen_timer_screen`) by switching from `canPop: false` to dynamic `ModalRoute.of(context)?.canPop ?? false` with resilient parent route fallbacks.
  - Added `android:enableOnBackInvokedCallback="true"` to `AndroidManifest.xml` so OxygenOS 15 forwards predictive back gestures directly to Flutter.
  - Converted `_FloatingBreath` and `StudyPlanBanner` 120Hz continuous repeating tickers to lightweight stateless widgets, and moved `_HomeTasksSection.checkDayRollover()` out of `build()` into `initState`.
  - Replaced continuous `ShaderMask` and ticker shimmer loops on badges in `AnalyticsScreen` with lightweight static styling.
  - Wrapped `LovableNavBar` with a `RepaintBoundary` to prevent full sketch dock repainting on tab scrolls.
- **Verification:** `flutter analyze` 0 errors, `flutter test test/theme_system_test.dart test/lovable_nav_bar_test.dart` passed (11/11 tests green), compiled `app-debug.apk` in 106.9s, installed to OnePlus 13R (`ba009d81`), idle CPU measured at 0.0%.
- **Build Status:** ✅ Included in Build (Debug APK Installed on OnePlus 13R)

---

### [CKPT-007] Native Package ID Migration to com.modulix.app & Clean Cloud Sync Foundation
- **Timestamp:** 2026-10-17 05:41 UTC
- **Category:** Architecture / Native Android / Cloud
- **Files Modified:**
  - `android/app/build.gradle.kts`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/com/modulix/app/MainActivity.kt`
  - `lib/config/supabase_config.dart`
  - `docs/BUILD_CHECKPOINTS.md`
- **Summary:** Migrated native Android build identifier and cleaned legacy install:
  - Updated `applicationId = "com.modulix.app"` in `android/app/build.gradle.kts`.
  - Uninstalled legacy `com.flowmd.flowmd_flutter` package from connected device (`ba009d81`).
  - Preserved SHA-1/SHA-256 Android keystore fingerprints and Supabase backend URL (`https://vbvmzjhzznxgofyzxnql.supabase.co`).
  - Initiated clean debug APK compilation and fresh installation.
- **Verification:** Legacy `com.flowmd.flowmd_flutter` uninstalled via ADB, debug APK compiled with code 0 (`build/app/outputs/flutter-apk/app-debug.apk`), successfully installed on OnePlus 13R (`ba009d81`), launched `com.modulix.app/.MainActivity` and visually verified.
- **Build Status:** ✅ Included in Build (Clean Install com.modulix.app)

---

### [CKPT-006] Hand-Drawn Pomodoro Tomato Focus Timer Icon in Bottom Navigation Dock
- **Timestamp:** 2026-10-17 05:01 UTC
- **Category:** UI / Navigation / Iconography
- **Files Modified:**
  - `lib/widgets/nav/sketch_nav_icons.dart`
  - `lib/widgets/lovable_nav_bar.dart`
  - `assets/icons/navbar/pomodoro_tomato_only_white.png`
  - `assets/icons/navbar/pomodoro_tomato_only_dark.png`
  - `test/lovable_nav_bar_test.dart`
- **Summary:** Adapted the center Focus Timer button on the floating bottom nav dock to the authentic hand-drawn Pomodoro tomato timer:
  - Extracted and packaged transparent high-res assets (`pomodoro_tomato_only_white.png`, `pomodoro_tomato_only_dark.png`) from the reference drawing (`Redesigning_focus_timer_icon_var…_2K_20261017102112.jpg`).
  - Added `SketchNavIconType.pomodoro` enum and built multi-pass vector painter `_paintPomodoro` (tomato body, curved 5-leaf calyx, stem, equator dial line with graduated calibration ticks, pointer arrow, and contour hatching).
  - Configured center button with white gel-pen Pomodoro icon inside the dark circular medallion, with automatic vector fallback.
  - Removed overlapping inner halo ring from `_SketchTimerMedallionPainter` to keep the tomato body completely clear and legible.
- **Verification:** `flutter analyze` passed (0 errors), `flutter test test/lovable_nav_bar_test.dart` passed (4/4 test suites).
- **Build Status:** ✅ Included in Build (Commit a78d411)

---

### [CKPT-005] Redone Appearance & Theme Showcase Cards (Adapted Borders, Zero Badges)
- **Timestamp:** 2026-10-17 04:40 UTC
- **Category:** UI / Theme
- **Files Modified:**
  - `lib/theme/modulix_theme.dart`
  - `lib/theme/app_theme.dart`
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/settings/theme_studio_screen.dart`
  - `test/theme_system_test.dart`
- **Summary:** Redone Appearance and Theme Showcase cards with unified tactile sketch styling and zero badges:
  - Unified light theme card feel with dark theme via adapted `borderSubtle` and `inkForeground.withValues(alpha: 0.12)` sketch shadows.
  - User-specified dual palettes perfected:
    - **Ice Cream Blue:** Background `#C8F3FF` | Accent (Atomic Orange) `#FF5C23`
    - **Mint Fog:** Background `#E8FFF2` | Accent (Forest Code) `#075E46`
    - **Mocha Cream:** Background `#EBDCC6` | Accent (Cosmic Latte) `#B7A99A`
  - Dynamic button/icon contrast for Cosmic Latte (`#1E1610` dark text over light accent).
  - Redone Settings screen Appearance & Theme card with `AppTheme.sketchDecoration()` and zero badges.
  - Redone Theme Studio `_VisualThemeCard` with mini canvas showcase, floating card mockup, interactive simulated components, and swatches.
- **Verification:** `flutter test test/theme_system_test.dart` and `test/all_screens_animation_theme_test.dart` passed (7/7 and 6/6), `flutter analyze` passed (0 errors, 0 fatal warnings).
- **Build Status:** ⏳ Pending APK Build

---

### [CKPT-004] Paper-Tinted Dual Themes (Ice Cream Blue, Mint Fog, Mocha Cream)
- **Timestamp:** 2026-10-17 04:22 UTC
- **Category:** UI / Theme
- **Files Modified:**
  - `lib/models/timer_theme.dart`
  - `lib/theme/app_theme.dart`
  - `lib/screens/settings/appearance_theme_sheet.dart`
- **Summary:** Added and refined specific dual color themes with paper-tinted backgrounds and vibrant sketch accents:
  - **Ice Cream Blue:** Background `#C8F3FF` | Accent (Atomic Orange) `#FF5C23`
  - **Mint Fog:** Background `#E8FFF2` | Accent (Forest Code) `#075E46`
  - **Mocha Cream:** Background `#EBDCC6` | Accent (Cosmic Latte) `#B7A99A`
- **Verification:** `flutter analyze` passed. Live preview cards integrated.
- **Build Status:** ⏳ Pending APK Build

---

### [CKPT-003] Hand-Drawn Sketchy Bottom Navigation Dock & Overlay
- **Timestamp:** 2026-10-16 19:00 UTC
- **Category:** UI / Navigation
- **Files Modified:**
  - `lib/app.dart`
  - `lib/widgets/lovable_nav_bar.dart`
  - `lib/widgets/nav/sketch_hatch_indicator.dart`
- **Summary:** Full overhaul of navigation bar to match reference sketchbook illustration:
  - Enabled `extendBody: true` on `MainShell` so screens scroll continuously behind the floating dock.
  - Floating pill dock geometry with rounded corners matching the sketchbook design.
  - Colored-pencil hatch texture indicator dynamically adapting to current theme accent color.
- **Verification:** Live tested on device `ba009d81` (OnePlus 13R).
- **Build Status:** ⏳ Pending APK Build

---

### [CKPT-002] Nori Blob Companion Engine & Speech Card Upgrade
- **Timestamp:** 2026-10-15 12:00 UTC
- **Category:** Mascot / Motion
- **Files Modified:**
  - `lib/widgets/nori/nori_blob_character.dart`
  - `lib/widgets/nori/nori_blob_painter.dart`
  - `lib/widgets/nori/nori_speech_card.dart`
  - `lib/widgets/nori_companion.dart`
- **Summary:** Transitioned Nori from sprite sheets to vector-drawn `NoriBlobCharacter` with Duolingo-inspired squash & stretch physics:
  - 11 emotion states, interactive drag/fling physics, swappable props (stethoscope, book, coffee, crown).
  - `NoriSpeechCard` auto-flip viewport safe placement ensuring target cutouts are never obscured.
- **Verification:** Automated widget tests passed (`test/study_desk_test.dart`). Interactive browser testbench at `test_nori_web/`.
- **Build Status:** ⏳ Pending APK Build

---

### [CKPT-001] Modulix Rebranding & Zero-Loss Data Sovereignty
- **Timestamp:** 2026-10-17 03:00 UTC
- **Category:** Architecture / Branding
- **Files Modified:**
  - `android/app/build.gradle.kts`
  - `android/app/src/main/AndroidManifest.xml`
  - `lib/main.dart`
  - `lib/app.dart`
  - `lib/services/storage_service.dart`
- **Summary:** Comprehensive rebranding from FlowMD to Modulix:
  - Android namespace updated to `com.modulix.app`.
  - Automatic dual-read fallback for SQLite (`flowmd.db` → `modulix.db`) and SharedPreferences keys ensuring zero loss of existing user study time, streaks, and video progress.
  - Fixed version collision where legacy Android home screen shortcuts opened older cached APKs.
- **Verification:** Verified data migration logic in `storage_service.dart`.
- **Build Status:** ⏳ Pending APK Build

---

## 🛠️ Checkpoint Lifecycle Workflow

1. **Register Checkpoint:** Whenever an edit or feature is made, add a `[CKPT-XXX]` entry above with files, summary, and verification method.
2. **Commit Checkpoint:** Create a matching git commit (`git commit -m "checkpoint(<category>): <summary>"`).
3. **Build APK Trigger:** When the user requests an APK build (`"build apk"`, `"test it"`, or `"release"`):
   - Collate all `⏳ Pending APK Build` checkpoints.
   - Generate a **Build Manifest** in chat and build logs.
   - Run tests and build the APK.
   - Update those checkpoints to `✅ Included in Build vX.X (Commit <hash>)`.
