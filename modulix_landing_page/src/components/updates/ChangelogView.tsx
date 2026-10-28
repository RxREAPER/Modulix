import { Clock, ArrowLeft } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"
import { SupportSection } from "./SupportSection"

export function ChangelogView({ navigate }: { navigate: (route: string) => void }) {
  const releases = [
    {
      version: "v1.32.0",
      date: "October 2026",
      tag: "Latest Release",
      title: "Editorial Luxury & Zero Box-Fatigue",
      changes: [
        "Eliminated box fatigue: Replaced repetitive boxed task cards with an airy, minimal list layout featuring 0.6px hairline dividers and generous whitespace.",
        "Render isolation: Wrapped high-frequency animated layers inside dedicated RepaintBoundary compositing layers.",
        "Zero-CLS skeletons: Replaced jumping circular spinners with editorial shimmer skeleton loaders across analytics and desk tasks.",
        "Fast-path animation lifecycle: Bypasses transformation wrappers once entrance motions finish, eliminating CPU listener overhead.",
      ],
    },
    {
      version: "v1.31.0",
      date: "October 2026",
      tag: "Core Performance",
      title: "Memory Memoization & Native SQLite Aggregations",
      changes: [
        "Native SQLite C-Engine aggregations: Study time breakdowns now execute directly inside the SQLite engine via single queries, eliminating in-memory heap churn.",
        "Expando memoization: Added thread-safe lazy caching on Subject syllabus models, eliminating >38 list allocations per frame.",
        "Incremental cloud sync: Implemented timestamp filtering against Supabase to reduce network egress bandwidth by >95%.",
      ],
    },
    {
      version: "v1.30.0",
      date: "October 2026",
      tag: "Hardware Resilience",
      title: "Deep Doze Alarm & Audio Protection",
      changes: [
        "Android Exact Alarm: Integrated AlarmManager.setAlarmClock to pierce Android 11–16 Deep Doze at the exact millisecond and display on Always-On Display (AOD).",
        "Becoming Noisy broadcast receiver: Automatically pauses background ambient audio when Bluetooth earbuds disconnect, protecting quiet library study.",
        "OEM battery optimization whitelist detection for Xiaomi, OnePlus, and Samsung devices.",
      ],
    },
    {
      version: "v1.2.0",
      date: "October 2026",
      tag: "120 FPS Haptics",
      title: "Timeline Virtualization & ApplePressable Haptics",
      changes: [
        "Module timeline 120 FPS virtualization with isolated SizeTransition controllers.",
        "ApplePressable tactile scaling (100ms compression, 220ms spring snap-back) across all interactive cards and number bubbles.",
        "Migrated native Android package identifier to com.modulix.app.",
      ],
    },
    {
      version: "v1.0.0",
      date: "October 2026",
      tag: "Foundation",
      title: "Initial Medical Companion Release",
      changes: [
        "19 MBBS subject curriculum mapped across Marrow Editions 6.5 and 8.",
        "5:00 AM clinical rollover engine with '2 Stale + 2 Fresh = 4' study plan quota capping.",
        "Multi-mode focus timer (Pomodoro, Count-Up, Module-Linked) with procedural rain and stream audio.",
        "Offline-first SQLite persistence with optional Supabase cloud backup.",
      ],
    },
  ]

  return (
    <div className="py-10 sm:py-16 max-w-3xl mx-auto select-none">
      {/* ── Header ── */}
      <div className="mb-8">
        <ApplePressable
          onClick={() => navigate("#/")}
          className="text-xs font-semibold text-[var(--muted-text)] hover:text-[var(--accent)] flex items-center gap-1.5 py-1 mb-4 w-fit"
        >
          <ArrowLeft size={14} />
          <span>Back to Overview</span>
        </ApplePressable>

        <div className="flex items-center gap-2 mb-2">
          <Clock size={16} className="text-[var(--accent)]" />
          <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
            RELEASE LEDGER & UPDATES
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-5xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Changelog & Milestones
        </h1>
        <p className="text-xs sm:text-sm text-[var(--muted-text)] mt-2 leading-relaxed max-w-lg">
          A continuous engineering record tracking every performance breakthrough, architectural hardening, and clinical curriculum release.
        </p>
      </div>

      <HairlineDivider />

      {/* ── Release Timeline Cards ── */}
      <div className="space-y-6 my-10">
        {releases.map((rel, i) => (
          <div
            key={rel.version}
            className="rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)] p-6 sm:p-7 shadow-sm transition-all hover:border-[var(--accent)]/40"
          >
            <div className="flex flex-wrap items-center justify-between gap-2 pb-4 mb-4 border-b border-[var(--border-subtle)]">
              <div className="flex items-center gap-3">
                <span className="font-editorial text-2xl font-bold text-[var(--ink-foreground)]">
                  {rel.version}
                </span>
                <span className="font-mono text-xs text-[var(--muted-text)]">
                  · {rel.date}
                </span>
              </div>
              <span
                className={`text-[10px] font-mono font-bold tracking-wider uppercase px-2.5 py-1 rounded-full border ${
                  i === 0
                    ? "bg-[var(--accent-subtle)] text-[var(--accent)] border-[var(--accent)]/30"
                    : "bg-[var(--surface-subtle)] text-[var(--muted-text)] border-[var(--border-subtle)]"
                }`}
              >
                {rel.tag}
              </span>
            </div>

            <h3 className="font-editorial text-xl font-bold text-[var(--ink-foreground)] mb-3">
              {rel.title}
            </h3>

            <ul className="space-y-2 text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
              {rel.changes.map((change, idx) => (
                <li key={idx} className="flex items-start gap-2.5">
                  <span className="text-[var(--accent)] font-bold mt-0.5 select-none">•</span>
                  <span>{change}</span>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <SupportSection />
    </div>
  )
}
