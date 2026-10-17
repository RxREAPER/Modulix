# Modulix Flutter

A focused, clinical-grade daily companion and curriculum tracker for medical students preparing for post-graduate medical entrance examinations (NEET-PG / INI-CET / USMLE).

---

## 📚 Developer & Architecture Knowledge Base

Modulix contains dedicated, professional-grade technical documentation detailing all core models, state machines, math algorithms, and routing rules:

- **[System Architecture & Tech Stack](docs/ARCHITECTURE.md)**: State management (Riverpod), navigation (GoRouter), storage partitions, theme tokens, and notifications.
- **[Focus Timer](docs/features/focus-timer.md)**: Timer modes (Pomodoro, Count-Up, Module-Linked), the 1-second tick engine, background themes, and TimeLog logging.
- **[Daily Desk Tasks](docs/features/daily-desk-tasks.md)**: Task models, shortcode prefixes (`[VID]`, `[MCQ]`, `[REV]`), mutators, and the **5:00 AM day-rollover algorithm**.
- **[Module-Based Tasks & Study Plan](docs/features/module-based-tasks.md)**: `StudyPlan` schema, the **"2 Stale + 2 Fresh = 4"** quota capping algorithm, global numbering, and velocity calculations.
- **[Curriculum, Subjects & Bulk Marking](docs/features/curriculum-and-bulk-mark.md)**: Medical syllabus modalities (Videos/QBanks/Notes), single-unit notes design rule, multi-edition support, and **analytics-safe bulk completion**.
- **[Analytics, TimeLogs & Streaks](docs/features/analytics-and-streaks.md)**: Immutable `TimeLog` session stream, streak tracking algorithm, and distribution metrics.

---

## 🛠 Tech Stack

- **Framework:** Flutter (Dart 3)
- **State Management:** Riverpod 2 (`AsyncNotifierProvider`, `StateNotifierProvider`, `Provider`)
- **Navigation:** GoRouter with animated page transitions
- **Storage:** Local SharedPreferences (JSON serialized)
- **Notifications:** `flutter_local_notifications`
- **Design Language:** Modulix parchment-sketch aesthetic & Modulix Studio Light theme
