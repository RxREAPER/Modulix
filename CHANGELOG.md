# Changelog

All notable changes to the Modulix / FlowMD Flutter medical companion project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-10-17

### ⚡ Performance & Animation Optimizations
- **Module Timeline 120 FPS Virtualization:** Replaced `ClipRect(child: AnimatedSize(...))` layout measuring during scroll with steady-state `SizeTransition` powered by an isolated `AnimationController`.
- **GPU Raster Isolation:** Wrapped every timeline item row and custom connector line in an isolated `RepaintBoundary` to eliminate GPU repaint cascades during high-velocity scrolling.
- **Immediate Tactile Click Response:** Upgraded all timeline cards (`_TimelineCard`), number bubbles (`TimelineCheckBubble`), and modal index rows with `ApplePressable` physical scale compression and subtle opacity dimming on touch-down.
- **Sub-Page Unit Index Popup:** Precomputed unit counts in O(N) prior to rendering and replaced offscreen `ClipRRect(child: LinearProgressIndicator)` with lightweight canvas-decorated progress bars.
- **Scroll Physics & Sequence:** Replaced double-hop scrolling stutter with a single smooth `Curves.fastOutSlowIn` curve and sequenced popup dismissal cleanly before scrolling.
- **Route Navigation:** Replaced heavy `CupertinoPage` transitions with high-performance 240ms cubic slide-fade transitions across curriculum sub-routes.
- **Deferred I/O:** Deferred `recordVisit` Riverpod invalidation by 350ms so page entrance animations maintain a flawless 120 FPS.

### 🐛 Fixes & Refinements
- Expanded interactive hit target to the entire body of module timeline cards while preserving isolated Focus Timer buttons.
- Migrated native Android package identifier to `com.modulix.app`.
- Eliminated router refresh storms and root rebuild cascades.

---

## [1.1.0] - 2026-10-15

### 🚀 Features & Architecture
- **Interactive App Tour:** Added a zero-confetti, concise 4-step guided in-situ feature tour for new doctors (`TourSpotlightOverlay`).
- **Nori Companion State Machine:** Implemented the fluid organic blob companion (`NoriBlobPainter`) with emotion engine and physics idle wobbling.
- **Pomodoro & Focus Timer:** Integrated module-linked stopwatch and count-up timers with ambient background noise synthesis.
- **Cloud & Local Offline Sync:** Built Supabase offline-first sync engine with local JSON SQLite storage.

---

## [1.0.0] - 2026-10-01

### 🌟 Initial Release
- **Curriculum Tracker:** Full 19 MBBS subjects syllabus (Editions 6.5 and 8) with multi-modal categorization (Videos, Q-Bank, Notes).
- **Daily Desk:** 5:00 AM day-rollover task manager with "2 Stale + 2 Fresh" study plan quota algorithm.
- **Analytics Hub:** Study streak tracking, time distribution graphs, and subject mastery velocity analytics.
