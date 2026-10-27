import { Shield, ArrowLeft, Smartphone, Database, Trash2 } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"

export function PrivacyView({ navigate }: { navigate: (route: string) => void }) {
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
          <Shield size={18} className="text-[var(--accent)]" />
          <span className="text-xs font-semibold uppercase tracking-wider text-[var(--muted-text)]">
            Google Play Data Safety & Compliance
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-4xl font-bold text-[var(--ink-foreground)]">
          Privacy Policy
        </h1>
        <p className="text-xs text-[var(--muted-text)] mt-1">
          Last revised: October 2026 · Complies with Google Play Developer Policy & GDPR
        </p>
      </div>

      <HairlineDivider />

      <div className="space-y-8 text-sm text-[var(--ink-foreground)] leading-relaxed">
        {/* Section 1 */}
        <section>
          <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] mb-2">
            1. Core Architectural Philosophy: Offline-First
          </h2>
          <p className="text-[var(--muted-text)]">
            Modulix is engineered as an <strong>offline-first clinical workstation</strong>. You can prepare for NEET-PG, INI-CET, and USMLE with zero account creation and zero internet connectivity. Your study progress, timers, and notes remain encrypted and isolated inside your device’s local application sandbox by default.
          </p>
        </section>

        {/* Section 2 */}
        <section>
          <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] mb-2">
            2. On-Device Storage (SQLite & SharedPreferences)
          </h2>
          <p className="text-[var(--muted-text)] mb-3">
            The following data is maintained exclusively on your physical phone:
          </p>
          <ul className="list-disc pl-5 space-y-1.5 text-xs sm:text-sm text-[var(--muted-text)]">
            <li><strong>Syllabus Progress:</strong> Completed lecture videos, question bank status, and high-yield notes markers.</li>
            <li><strong>Focus Timer Records:</strong> Local SQLite records stored in <code className="text-xs bg-[var(--surface-subtle)] px-1.5 py-0.5 rounded">time_logs</code> tracking session durations and timestamps.</li>
            <li><strong>Daily Desk Tasks:</strong> Local checklists and historical 5:00 AM rollover counts.</li>
            <li><strong>Theme & Aesthetics:</strong> Active color palettes, avatar selections, and UI font preferences.</li>
          </ul>
        </section>

        {/* Section 3 */}
        <section className="p-5 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)]">
          <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] mb-2 flex items-center gap-2">
            <Database size={18} className="text-[var(--accent)]" />
            <span>3. Cloud-Synchronized Data (Optional via Supabase)</span>
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] mb-3">
            If you voluntarily sign in with Google or Email to synchronize your study progress across multiple devices, data is transmitted over TLS 1.3 encryption to Supabase:
          </p>
          <div className="space-y-2 text-xs">
            <div className="flex justify-between border-b border-[var(--border-subtle)] pb-1.5">
              <span className="font-mono font-medium">public.profiles</span>
              <span className="text-[var(--muted-text)]">Doctor Name, Leaderboard Visibility, Aggregated Study Seconds</span>
            </div>
            <div className="flex justify-between border-b border-[var(--border-subtle)] pb-1.5">
              <span className="font-mono font-medium">public.study_editions</span>
              <span className="text-[var(--muted-text)]">Edition 8 & 6.5 syllabus completion milestones</span>
            </div>
            <div className="flex justify-between border-b border-[var(--border-subtle)] pb-1.5">
              <span className="font-mono font-medium">public.time_logs</span>
              <span className="text-[var(--muted-text)]">Timestamped focus session durations</span>
            </div>
            <div className="flex justify-between">
              <span className="font-mono font-medium">public.daily_tasks</span>
              <span className="text-[var(--muted-text)]">Active daily desk task checklists</span>
            </div>
          </div>
          <p className="text-xs text-[var(--muted-text)] mt-3">
            All tables are governed by strict <strong>PostgreSQL Row-Level Security (RLS)</strong>. Only your authenticated user ID can read, modify, or delete your records.
          </p>
        </section>

        {/* Section 4 */}
        <section>
          <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] mb-2 flex items-center gap-2">
            <Smartphone size={18} className="text-[var(--accent)]" />
            <span>4. Android Operating System Permissions Declared</span>
          </h2>
          <div className="space-y-3 text-xs sm:text-sm text-[var(--muted-text)]">
            <div>
              <strong className="text-[var(--ink-foreground)]">SCHEDULE_EXACT_ALARM:</strong> Required to pierce Android 11–16 Deep Doze at the exact millisecond a focus session or countdown expires, displaying on the lock screen and Always-On Display.
            </div>
            <div>
              <strong className="text-[var(--ink-foreground)]">POST_NOTIFICATIONS:</strong> Displays the persistent ongoing study timer notification and scheduled 5:00 AM clinical rollover reminders.
            </div>
            <div>
              <strong className="text-[var(--ink-foreground)]">REQUEST_IGNORE_BATTERY_OPTIMIZATIONS:</strong> Guides users to disable aggressive OEM battery killers (e.g. OnePlus OxygenOS / Xiaomi MIUI) so study countdowns are not prematurely halted.
            </div>
          </div>
        </section>

        {/* Section 5 */}
        <section className="pt-4 border-t border-[var(--border-subtle)]">
          <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] mb-2 flex items-center gap-2">
            <Trash2 size={18} className="text-rose-500" />
            <span>5. Account Deletion & Right to Erasure (Google Play Mandate)</span>
          </h2>
          <p className="text-[var(--muted-text)] mb-3">
            In compliance with Google Play’s user data policy, users have an unconditional right to delete their cloud account and all associated study data at any time without reinstalling the app.
          </p>
          <div className="flex items-center gap-3">
            <ApplePressable
              onClick={() => navigate("#/account")}
              className="px-4 py-2.5 rounded-lg bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold inline-flex items-center gap-2"
            >
              <Trash2 size={13} />
              <span>Launch Account & Data Deletion Portal</span>
            </ApplePressable>
          </div>
        </section>
      </div>
    </div>
  )
}
