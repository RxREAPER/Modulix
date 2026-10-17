# Contributing to Modulix

First off, thank you for considering contributing to Modulix! Medical education software demands the highest level of craftsmanship, zero latency, reliable offline state persistence, and clinical precision.

---

## 🏛 Code Architecture Principles

1. **State Isolation & Performance:**
   - Always use scoped Riverpod providers. Avoid full-tree widget rebuilds.
   - For lists and timelines, isolate paint and size passes using `RepaintBoundary`.
   - Avoid `AnimatedSize` or heavy layout trackers inside actively scrolled viewports.
2. **Tactile & Haptic Touch Standards:**
   - Every interactive control must provide immediate visual feedback upon finger contact (`ApplePressable` or active press state).
   - Use light, subtle haptics (`HapticFeedback.lightImpact()` or `selectionClick()`). Avoid jarring vibrations.
3. **Clinical Domain Invariants:**
   - Follow the 5:00 AM daily task rollover algorithm.
   - Respect the "2 Stale + 2 Fresh = 4" quota capping rule for daily module tasks.
   - Maintain immutable `TimeLog` records for analytical veracity.

---

## 🛠 Local Development Setup

### Prerequisites
- Flutter SDK (3.24+ / Dart 3.5+)
- Android Studio / Android SDK (API 34+)
- VS Code or Android Studio with Flutter extensions

### Getting Started
```bash
# 1. Clone repository
git clone https://github.com/RxREAPER/flowmd_flutter.git
cd flowmd_flutter

# 2. Install dependencies
flutter pub get

# 3. Run static analysis
flutter analyze

# 4. Run test suite
flutter test

# 5. Launch debug app
flutter run
```

---

## 🧪 Testing & Quality Assurance

Before submitting any Pull Request:
1. Run `flutter analyze` — all files must pass with **0 issues found**.
2. Run `flutter test` — ensure all unit and widget tests pass.
3. Register your checkpoint in `docs/BUILD_CHECKPOINTS.md` with:
   - Checkpoint ID (`[CKPT-XXX]`)
   - Category (`perf`, `ui`, `feature`, `fix`)
   - Modified files
   - Verification status
4. Create a matching conventional commit:
   ```bash
   git commit -m "checkpoint(<category>): <concise summary>"
   ```

---

## 📄 License
By contributing to Modulix, you agree that your contributions will be licensed under its [MIT License](LICENSE).
