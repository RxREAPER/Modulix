# Changelog

All notable changes to the Modulix Flutter medical companion project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.39.0] - 2026-11-15

### ⚡ Performance, Animations & Battery Optimization
- **Snappy 180ms Page Transitions:** Replaced sluggish 360-380ms `OpenContainer` transforms in `CurriculumScreen`, `SubjectScreen`, and `AutomatedModuleTracker` with hardware-accelerated horizontal slide transitions (180ms forward, 150ms reverse) powered by `Curves.easeOutCubic` and isolated via `RepaintBoundary`. Delivers silky navigation on 60Hz and 120Hz displays.
- **Ultra-Low Power 1Hz Focus Timer:** Reduced periodic background timer ticker from 200ms (5 ticks/s) to 1.0s (1 tick/s) with immediate first-frame trigger. Slashed background CPU wakeups by over 80%, protecting student battery life during multi-hour continuous study sessions.
- **Navigation Dock Raster Isolation:** Wrapped the navigation bar hero halo pulsing ring in an isolated `RepaintBoundary` to prevent raster cascades and avoid repainting the dock during active timer sessions.
- **BackdropFilter Elimination:** Replaced expensive Gaussian blur passes (`sigmaX: 16, sigmaY: 16`) from daily task rows and analytics focus lists with lightweight opaque and translucent surface decorations.

### 🗄️ Database & Storage Compaction
- **SQLite Cache Slashing:** Reduced SQLite pre-allocated RAM cache from 64MB (`-64000 KiB`) down to 2MB (`-2000 KiB`), freeing 62MB of system RAM.
- **Automated WAL Compaction:** Configured `PRAGMA wal_autocheckpoint = 100` and `PRAGMA auto_vacuum = INCREMENTAL`.
- **Database Vacuum & Legacy Purge:** Added automated `PRAGMA wal_checkpoint(TRUNCATE)` and `VACUUM` on startup, shrinking database files to < 1MB and purging orphaned legacy migration files.

### 🛡️ Cold-Start Zero Data Enforcement
- **Purged Test & Mock Data:** Strictly eliminated synthetic 14-week test history, mock 12-day streaks, fake 83% velocity, and sample tasks across `AnalyticsScreen`, `StudyPlanAnalyticsPage`, and `LeaderboardScreen`.
- **Honest Onboarding States:** Fresh app installs now present clean, authentic zero states ready for true user input.

### 🐛 Bug Fixes & Navigation Hardening
- **Focus Timer Finish Button Reactivity:** Hardened finish button tap callback with active feedback, prevented 0-second empty sessions, and added toast notifications when no timer is active.
- **Root Route Decoupling:** Promoted `/plan` and `/module-tasks` to top-level root routes, eliminating GoRouter context deactivation freezes when opening study plans from bottom sheets or focus timer setup.
- **Universal Multi-ABI Release Binary:** Compiled and signed `modulix-v1.39.0.apk` supporting `arm64-v8a`, `armeabi-v7a`, and `x86_64` (API 24 to 36).

---

## [1.38.0] - 2026-11-14

### 🔄 Cloud Sync & Data Sovereignty Hardening
- **Single-Active-Device Sync Lock:** Implemented single-device lease enforcement on user profiles. Devices in standby pause cloud push to prevent concurrent multi-device race conditions and state corruption.
- **Durable Dirty Tracking & Dead Letter Queue:** Enqueued profile, task, and syllabus mutations in SQLite outbox; poisoned mutations transition to Dead Letter Queue (`failed`) after 5 retries.
- **Zero Resurrection Traps:** Persisted deletion tombstones and cleared timestamps to permanently prevent deleted tasks or time logs from resurrecting on sync pulls.
- **GDPR Two-Step Account Erasure:** Built complete account wipe and local SQLite reset (`resetAllDatabases()`) compliant with Play Store and App Store privacy standards.

### 🚀 In-App Version Engine & Distribution
- **Remote Version Discovery:** Engineered background version checking against the GitHub Releases API with 24-hour throttling and manual check in Settings -> About.
- **Strict Zero In-App Downloads Policy:** Directed all update prompts externally to the official Cloudflare web portal (`https://modulix.pages.dev`) in the system browser.
- **Unified Release Pipeline:** Built `./tool/release.sh` to orchestrate tests, version synchronization, production APK compilation, signing, GitHub publishing, and Cloudflare Pages deployment in one command.

---

## [1.36.0] - 2026-11-05

### 🔔 Notifications & Settings Sub-Pages
- **Notification System Overhaul:** Smart evening streak reminder suppression (suppressed if user already studied today), soft-ask permission flow, and dedicated Notifications sub-page.
- **Native Settings Sub-Pages:** Replaced modal sheets with clean native routes for Profile, Account, Data & Privacy, and About.

---

## [1.35.0] - 2026-10-28

### 🎨 Visual Theme Studio & Curriculum
- **Visual Theme Studio:** Modernized palette swatches and theme selection.
- **Curriculum Edition Separation:** Distinct isolation and switching between Edition 8 and Edition 6.5.
- **Leaderboard Identity:** Clean display names and career cohort rankings.

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
