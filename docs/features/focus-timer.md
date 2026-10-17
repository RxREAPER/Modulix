# Feature: Focus Timer

> Files: `lib/screens/timer/focus_timer_screen.dart` (~1665 lines), `lib/providers/focus_timer_provider.dart` (389 lines)  
> Related: `lib/widgets/timer/`, `lib/models/timer_theme.dart`, `lib/services/notification_service.dart`

---

## 1. Overview

A full-screen immersive study timer that occupies the entire display (no navigation bar — it's outside the `ShellRoute`). Supports three timing modes, live animated background themes, ambient audio, and session task tagging. Completing a session writes a `TimeLog` entry which feeds into the Analytics screen.

The screen is navigated to via `context.push('/timer', extra: {...})` — the `extra` map optionally pre-fills topic/subject from wherever the user tapped (e.g. a module card in Module Tasks, a video row in the Subject screen).

---

## 2. State Model — `FocusTimerState`

Provider: `focusTimerProvider` (`StateNotifierProvider<FocusTimerNotifier, FocusTimerState>`)

```dart
class FocusTimerState {
  bool isRunning
  TimerPhase phase           // idle | focusing | onBreak
  TimerMode mode             // pomodoro | countUp | moduleLinked
  int remainingSeconds       // countdown value (countUp: counts up from 0)
  int focusSecondsElapsed    // focus-phase time accumulated this session
  int breakSecondsElapsed    // break-phase time accumulated this session
  String subjectId / subjectName / topicId / topicTitle / chapterName / topicType
  int pomodoroPresetMins     // user-configured focus duration (default 25)
  int pomodoroBreakMins      // user-configured break duration (default 5)
  int modulePresetMins       // preset from module's video.durationMins (default 15)
  TimerThemeData theme       // active background theme
  String activeSoundId       // 'none' | 'rain' | 'lofi' | 'waves' | 'fire' | 'forest'
  bool sessionActive         // true once started, used to show Finish button
}
```

**Aliases:** `timer.isBreak` = `phase == onBreak`. `timer.pomodoroMinutes` = `pomodoroPresetMins` (getter alias, added for backwards compatibility with sheet widgets).

---

## 3. Timer Modes

### `TimerMode.pomodoro`
- `remainingSeconds` counts down from `pomodoroPresetMins * 60`.
- When it hits 0 (auto): notification fires, timer stops, user must manually start break or restart.
- Break phase: `remainingSeconds` resets to `pomodoroBreakMins * 60` and counts down.
- Variables are fully custom: 1-minute step buttons (`_SheetStepBtn`) in `_SessionConfigSheet`. Tap the value label to open a `showDialog` for direct integer input (`_showCustomMinutesDialog`).
- No presets. Focus: clamped 1–300 min. Break: clamped 1–60 min.

### `TimerMode.countUp`
- `remainingSeconds` increments from 0 (never auto-stops).
- No break phase in this mode — `toggleBreak` in countUp keeps `remainingSeconds` unchanged.
- `_computeRemaining()` returns 0 for this mode.
- Timer end notification is never scheduled for countUp.

### `TimerMode.moduleLinked`
- Preset duration comes from `modulePresetMins`, which is set when `setTask(durationMins: X)` is called with `durationMins > 0`.
- When navigated from a Module Task card (timer icon), the extra map passes `durationMins: video.durationMins > 0 ? video.durationMins : 15`.
- Behaves like Pomodoro countdown but without a break phase stepper.

**Mode switching** is blocked while the timer is running (`if (state.isRunning) return;` guard in `changeMode`, all setters).

---

## 4. The Tick Engine

`FocusTimerNotifier._tick()` is called by a `dart:async Timer.periodic(1 second)` stored in `_ticker`.

**Focusing phase tick:**
```
focusSecondsElapsed++
if mode == countUp:
  remainingSeconds++  (counting up)
else if remainingSeconds > 1:
  remainingSeconds--
else:
  _ticker.cancel(), fire showFocusTimerCompleted(), isRunning = false
```

**Break phase tick:**
```
breakSecondsElapsed++
if mode != countUp && remainingSeconds > 1:
  remainingSeconds--
else if mode != countUp && remainingSeconds <= 1:
  _ticker.cancel(), fire showBreakCompleted(), isRunning = false
else (countUp break):
  breakSecondsElapsed++  (no countdown)
```

---

## 5. Session Finish & TimeLog Recording

`FocusTimerNotifier.finishSession()` is the only path that writes a `TimeLog`:

1. Cancels ticker + all notifications.
2. If `focusSecondsElapsed == 0`: calls `reset()`, returns `null` (no log). Nothing written.
3. Otherwise: constructs `TimeLog` with `id = 'log_${millisecondsSinceEpoch}'`, all current topic/subject fields, `durationSecs = focusSecondsElapsed`.
4. Writes via `ref.read(timeLogsProvider.notifier).logTime(log)`.
5. Returns the `TimeLog` — UI shows `_SessionDoneDialog` with session summary.

**Critical:** Only `focusSecondsElapsed` is logged. Break time is tracked in state (`breakSecondsElapsed`) for display purposes but is NOT persisted to the time log.

`reset()` is called after the done dialog closes. It preserves: theme, activeSoundId, mode, all task/subject fields, Pomodoro presets. Clears: elapsed counters, running state, phase → idle, sessionActive.

---

## 6. Screen Layout

The screen is a `Stack` with no `Scaffold` navigation elements:

```
Stack (full screen)
├── [0] Background layer
│   ├── If theme.assetImagePath != null: Image.asset (fit: BoxFit.cover)
│   ├── If theme.gifUrl != null: CachedNetworkImage / Image.network
│   └── Fallback: Container(color: theme.backgroundColor)
│
├── [1] Positioned(top: 0) — Icon Row + Session Pill
│   ├── Row: [🎨 bg picker] [🔇 sound] [⊡ fullscreen?] ... [✕ close]
│   └── _SessionConfigPill: horizontal pill showing "SUBJECT.NAME · Mode" + tune icon
│       └── onTap → _SessionConfigSheet.show(...)
│
├── [2] Center — Timer Centerpiece (absolutely centered on screen)
│   ├── UNIT.NAME (purple, uppercase, letter-spaced)
│   ├── chapterName · topicTitle (secondary subtitle)
│   ├── "Study Time:" label
│   ├── HH:MM:SS (bold, large, primary color)
│   ├── Monospace telemetry lines (Total Break: ..., Total Time: ...)
│   └── Phase badge pill (● READY | ▶ FOCUSING | ⏸ PAUSED | ☕ BREAK)
│
└── [3] Positioned(bottom: 0) — Control Row
    ├── [Break] _ControlBtn
    ├── [▶ START / ⏸ PAUSE] _ControlBtn (center, large purple pill)
    └── [✓ Finish] _ControlBtn
```

**No text drop shadows anywhere** — explicitly removed after user request.

---

## 7. Session Config Sheet (`_SessionConfigSheet`)

Opened by tapping the pill at the top of the screen. Implemented as a `StatelessWidget` with a `static void show(context, {...})` that calls `showModalBottomSheet`.

Sections inside the sheet:
1. **TOPIC** — single card row showing `SUBJECT.NAME` + topic title. Taps open `TaskPickerSheet.show()` which lets the user select any subject/topic from the syllabus.
2. **FOCUS MODE** — three animated `AnimatedContainer` rows (Pomodoro / Count-Up / Module-Linked). Selected row gets purple border + check circle. Tapping calls `notifier.changeMode(newMode)`.
3. **TIMER VARIABLES** — only visible when mode is Pomodoro or Module-Linked.
   - Pomodoro: two side-by-side steppers (FOCUS: `[−] Nm [+]`, BREAK: `[−] Nm [+]`).
   - Module-Linked: single stepper (DURATION).
   - Each stepper's `[−]`/`[+]` is `_SheetStepBtn` calling `notifier.adjustPomodoroMinutes(±1)` etc.
   - Tapping the value label (`GestureDetector` wrapping the `Nm` text) calls the parent's `onShowCustomDialog` callback, which opens `_showCustomMinutesDialog` — an `AlertDialog` with a `TextField(keyboardType: number)` for direct input.

**`_SessionConfigSheet` signature:**
```dart
static void show(BuildContext context, {
  required FocusTimerState timer,
  required TimerThemeData theme,
  required bool isLight,
  required FocusTimerNotifier notifier,
  required Function({required BuildContext, required String title,
    required int currentMins, required int minMins, required int maxMins,
    required ValueChanged<int> onSave}) onShowCustomDialog,
})
```

---

## 8. Background Themes & Ambient Sounds

### Themes — `kTimerThemes` in `lib/models/timer_theme.dart`

6 themes available:

| id | name | bg color | style |
|---|---|---|---|
| `modulix_light` | Modulix Light | `#FCFBF8` | Paper / brand purple — default |
| `sakura` | Sakura Shrine | `#1D0E1C` | Dark + remote image |
| `paper` | Warm Study Desk | `#141416` | Dark + remote image |
| `lofi` | Midnight Lo-Fi | `#0F172A` | Dark + remote GIF |
| `rainy_cafe` | Rainy Cafe | `#062828` | Dark + remote GIF |
| `sunset_library` | Golden Sunset | `#2E1015` | Dark + remote GIF |

`TimerThemeData.isLight` = `backgroundColor.computeLuminance() > 0.4`. This drives whether the overlay UI uses dark or light ink/icon colors throughout the screen.

Selected via `TimerBackgroundPicker` bottom sheet (same `#FCFBF8` Modulix-web style as the config sheet).

### Sounds — `kAmbientSounds` in `lib/widgets/timer/ambient_sound_sheet.dart`

6 options: `none` (silent), `rain`, `lofi`, `waves`, `fire`, `forest`. Audio assets expected at `assets/audio/<id>.mp3`. Currently wired in state only — actual audio playback via `AmbientAudioService` (`lib/services/ambient_audio_service.dart`).

---

## 9. Notifications (Timer-Specific)

All conditional on `appState.focusTimerAlertsEnabled`.

| Event | Method | Type |
|---|---|---|
| Timer started | `showFocusTimerStarted(topicTitle, minutes)` | Ongoing persistent |
| Timer auto-completed | `showFocusTimerCompleted(topicTitle)` | One-shot |
| Break started | `showBreakStarted(minutes)` | One-shot |
| Break auto-completed | `showBreakCompleted(topicTitle)` | One-shot |
| End countdown | `scheduleFocusTimerEnd(duration, topicTitle, isBreak)` | Scheduled future |
| Module quota hit | `showModuleTaskCompletedNotification(subjectName, count)` | One-shot |

`cancelFocusTimerEnd()` and `cancelFocusTimerRunning()` are called on pause, finish, and dispose to clean up.

---

## 10. Known Gotchas

- **Mode switch during countUp break**: break toggles in countUp don't reset `remainingSeconds` — it stays 0 (expected since countUp has no countdown).
- **setTask with durationMins**: auto-switches mode to `moduleLinked` only if `durationMins > 0`. Passing `durationMins: 0` or null preserves current mode.
- **Timer outside ShellRoute**: `FocusTimerScreen` is registered at the root GoRouter level, not inside the `ShellRoute`. This means the bottom nav bar and `MiniTimerOverlay` are NOT rendered behind the timer screen. The overlay only appears when the user backs out to a shell route while the timer is still running.
- **`_Unused_OldCard` class**: a dead-code stub class left at the bottom of the file to prevent orphaned reference errors after a large refactor. Safe to delete in a future cleanup pass.
- **`withOpacity` deprecation**: ~70 info-level warnings exist in these files. Not errors. Can be batch-replaced with `.withValues(alpha: x)` in a future cleanup.
