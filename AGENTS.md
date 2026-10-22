# Development & Testing Rules

## 1. Vibe Coder Balanced Workflow (Scope-Based Testing & Verification)

Decide how much testing to do based on the size of the request:

### A. Small Tweaks (Colors, Text, Spacing, Simple UI/Logic Adjustments)
- Edit the code and run a quick syntax/compile check ONLY (`flutter analyze`) to make sure there are no typos or compilation errors.
- **DO NOT build a full APK**, **DO NOT restart the emulator/device**, and **DO NOT take verification screenshots** for small tweaks.

### B. Big Changes (New Screens, New Features, New Libraries, or "Fix this crash")
- Run the test suite (`flutter test`) and static analysis (`flutter analyze`) first.
- Complete the full debug build (`flutter build apk --debug`), install on the device/emulator, and verify it works with a screenshot so the app remains reliable.

### C. Live Debug App Updates (Hot Reload / Hot Restart)
- Changes can be pushed live directly to a running debug session via Flutter hot reload (`r`) or hot restart (`R`) without rebuilding or reinstalling an APK.
- Use this whenever the user requests "live update" / "hot reload", or suggest it during rapid visual tweaking sessions.

### D. Manual Overrides
- If the user says **"test it"** or **"show me"**: Run the full build, install, and screenshot verification check.
- If the user says **"quick edit"**: Skip all terminal commands and just edit the code directly.

## 2. Interactive Feature Tour Requirements
- **Concise Explanations:** Keep dialogue box explanations strictly to 3 to 4 lines of text overall. Avoid multi-paragraph walls of text and bullet points.
- **Strict Non-Overlapping Rule:** The highlighted target feature/cutout must NEVER be covered or obscured by the tour explanation dialogue box. The card must be placed dynamically in viewport space that guarantees clear visibility of the target.
- **No Line Overlays:** Highlight outlines must hug widgets tightly (3.0px inflate padding) and must not bleed over or overlay adjacent interactive controls. Never highlight a nested child inside an already highlighted parent.
- **Aesthetics:** No emoji characters and no confetti animations.

## 3. Checkpoint Registration & Build Manifest System
- **Incremental Checkpoints:** For every change or feature (small tweaks or big changes), register an entry in `docs/BUILD_CHECKPOINTS.md` specifying ID, category, modified files, summary, and verification status (`flutter analyze` / hot reload / test).
- **Git Commit Checkpoint:** Create a matching git commit (`checkpoint(<category>): <summary>`) so no edits can be lost or hallucinated.
- **Derive Context on APK Build:** When an APK build is triggered (`"build apk"`, `"release"`, `"test it"`), collate all `Pending APK Build` checkpoints since the previous build into a structured **Build Manifest** (release notes), verify the build, and update the checkpoints to `✅ Included in Build`.

## 4. Flutter 3.41+ Modernization & Defensive Hardening Standards

### A. Scroll Cache Extent Migration
- Never pass a raw `double` to `scrollCacheExtent`.
- Always use `const ScrollCacheExtent.pixels(...)` or `ScrollCacheExtent.viewport(...)`.
- Always import `package:flutter/rendering.dart` when using `ScrollCacheExtent`.

### B. ReorderableListView Callback Migration
- When modernizing from `onReorder` to `onReorderItem`, **DO NOT** perform index adjustment (`if (newIndex > oldIndex) newIndex -= 1`).
- The framework's `onReorderItem` already adjusts `newIndex` after item removal at `oldIndex`.

### C. SizeTransition Alignment
- Replace deprecated `axisAlignment: -1.0` with `alignment: Alignment.topCenter` (or `Alignment.topLeft`).

### D. Defensive Model & State Deserialization
- Never perform unsafe casts like `json['field'] as int` or `json['field'] as String`.
- For numbers: use `(json['field'] as num?)?.toInt()` or `(json['field'] as num?)?.toDouble()`.
- For strings: use `json['field']?.toString() ?? 'fallback'`.
- For lists and maps: safely fold or map elements with `.toString()` / null checks to prevent unhandled runtime `TypeError` crashes.

