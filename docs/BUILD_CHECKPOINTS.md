# Modulix — Build Checkpoints Ledger

This ledger tracks every incremental change made during development. Every feature, UI tweak, bugfix, or refactoring registers a checkpoint entry here as soon as it is verified via Hot Reload / Hot Restart and `flutter analyze`.

When an APK build is triggered, all pending checkpoints are synthesized into a **Build Manifest** (release notes), verified, and marked as `✅ Included in Build`.

---

## 📋 Active Checkpoints

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
- **Build Status:** ⏳ Pending APK Build

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
