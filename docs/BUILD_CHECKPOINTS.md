# Modulix — Build Checkpoints Ledger

This ledger tracks every incremental change made during development. Every feature, UI tweak, bugfix, or refactoring registers a checkpoint entry here as soon as it is verified via Hot Reload / Hot Restart and `flutter analyze`.

When an APK build is triggered, all pending checkpoints are synthesized into a **Build Manifest** (release notes), verified, and marked as `✅ Included in Build`.

---

## 📋 Active Checkpoints

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
