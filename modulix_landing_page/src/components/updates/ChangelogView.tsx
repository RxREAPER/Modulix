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
    <div className="py-8 max-w-3xl">
      <div className="mb-6">
        <ApplePressable
          onClick={() => navigate("#/")}
          className="text-xs font-semibold text-[var(--muted-text)] hover:text-[var(--accent)] flex items-center gap-1.5 py-1 mb-3"
        >
          <ArrowLeft size={14} />
          <span>Back to Overview</span>
        </ApplePressable>

        <div className="flex items-center gap-2 mb-2">
          <Clock size={18} className="text-[var(--accent)]" />
          <span className="text-xs font-semibold uppercase tracking-wider text-[var(--muted-text)]">
            Release Notes & Development History
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-4xl font-bold text-[var(--ink-foreground)]">
          Changelog & Updates
        </h1>
        <p className="text-xs text-[var(--muted-text)] mt-1">
          Tracking the incremental evolution of the Modulix Flutter companion and clinical tools.
        </p>
      </div>

      <HairlineDivider />

      <div className="space-y-10 my-8">
        {releases.map((rel, i) => (
          <div key={rel.version} className="relative pl-6 border-l border-[var(--border-subtle)]">
            {/* Version timeline dot */}
            <div
              className={`absolute -left-[5px] top-1.5 w-2.5 h-2.5 rounded-full ${
                i === 0 ? "bg-[var(--accent)] ring-4 ring-[var(--accent-subtle)]" : "bg-[var(--border-subtle)]"
              }`}
            />

            <div className="flex items-center gap-2 mb-1">
              <span className="font-editorial text-xl font-bold text-[var(--ink-foreground)]">
                {rel.version}
              </span>
              <span className="text-xs text-[var(--muted-text)]">· {rel.date}</span>
              <span className="ml-2 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-[var(--surface-subtle)] text-[var(--ink-foreground)] border border-[var(--border-subtle)]">
                {rel.tag}
              </span>
            </div>

            <h3 className="text-xs font-semibold text-[var(--accent)] mb-2">
              {rel.title}
            </h3>

            <ul className="space-y-1.5 text-xs sm:text-sm text-[var(--muted-text)]">
              {rel.changes.map((change, idx) => (
                <li key={idx} className="flex items-start gap-2">
                  <span className="text-[var(--accent)] shrink-0 select-none">·</span>
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
