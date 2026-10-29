import { ArrowLeft, Database, Smartphone, Trash2 } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"

export function PrivacyView({ navigate }: { navigate: (route: string) => void }) {
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
          <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
            DATA SAFETY & REGULATORY COMPLIANCE
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-5xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Privacy Policy
        </h1>
        <p className="text-xs font-mono text-[var(--muted-text)] mt-2 flex flex-wrap items-center gap-2">
          <span>Updated October 2026</span>
          <span className="opacity-40">·</span>
          <span>Google Play Developer Policy Mandate</span>
          <span className="opacity-40">·</span>
          <span>GDPR / Offline-First</span>
        </p>
      </div>

      <HairlineDivider />

      <div className="space-y-10 my-10 text-sm text-[var(--ink-foreground)] leading-relaxed">
        {/* Section 1 */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            1. Core Architecture: Offline-First
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            Modulix is engineered as a strictly <strong>offline-first clinical study companion</strong>. Medical students and doctors can track syllabus progress, run focus sessions, and manage daily tasks with zero account creation and zero active internet connection. All study records remain isolated and encrypted inside your device’s sandbox by default.
          </p>
        </section>

        {/* Section 2 */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            2. On-Device Storage (SQLite & Preferences)
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] mb-3 leading-relaxed">
            The following telemetry and tracking parameters are persisted exclusively on your physical hardware:
          </p>
          <ul className="space-y-2 text-xs sm:text-sm text-[var(--muted-text)]">
            <li className="flex items-start gap-2.5">
              <span className="text-[var(--accent)] font-bold mt-0.5">•</span>
              <span><strong>Syllabus Progress:</strong> Completed topics, question bank status, and high-yield milestone markers.</span>
            </li>
            <li className="flex items-start gap-2.5">
              <span className="text-[var(--accent)] font-bold mt-0.5">•</span>
              <span><strong>Focus Timer Records:</strong> Local SQLite records stored in <code className="text-[11px] font-mono bg-[var(--surface-subtle)] border border-[var(--border-subtle)] px-1.5 py-0.5 rounded">time_logs</code> tracking session durations and timestamps.</span>
            </li>
            <li className="flex items-start gap-2.5">
              <span className="text-[var(--accent)] font-bold mt-0.5">•</span>
              <span><strong>Daily Desk Tasks:</strong> Local checklists and historical 5:00 AM clinical rollover counts.</span>
            </li>
            <li className="flex items-start gap-2.5">
              <span className="text-[var(--accent)] font-bold mt-0.5">•</span>
              <span><strong>Theme & Aesthetics:</strong> Active color palettes, avatar selections, and UI font preferences.</span>
            </li>
          </ul>
        </section>

        {/* Section 3 */}
        <section className="p-6 sm:p-7 rounded-2xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)]/40 shadow-sm">
          <div className="flex items-center gap-2.5 mb-2">
            <Database size={16} className="text-[var(--accent)]" />
            <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)]">
              3. Cloud Synchronization (Optional via Supabase)
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] mb-4 leading-relaxed">
            If you voluntarily link your Google or Email account to synchronize progress across phones or tablets, encrypted telemetry is transmitted over TLS 1.3 to Supabase:
          </p>
          <div className="space-y-2 text-xs">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-[var(--border-subtle)] pb-2 gap-1">
              <span className="font-mono font-medium text-[var(--ink-foreground)]">public.profiles</span>
              <span className="text-[var(--muted-text)] text-[11px] sm:text-xs">Doctor Name, Leaderboard Visibility, Aggregated Study Hours</span>
            </div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-[var(--border-subtle)] pb-2 gap-1">
              <span className="font-mono font-medium text-[var(--ink-foreground)]">public.study_editions</span>
              <span className="text-[var(--muted-text)] text-[11px] sm:text-xs">Curriculum subject and module completion milestones</span>
            </div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-[var(--border-subtle)] pb-2 gap-1">
              <span className="font-mono font-medium text-[var(--ink-foreground)]">public.time_logs</span>
              <span className="text-[var(--muted-text)] text-[11px] sm:text-xs">Timestamped focus session durations and subject tags</span>
            </div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-1 gap-1">
              <span className="font-mono font-medium text-[var(--ink-foreground)]">public.daily_tasks</span>
              <span className="text-[var(--muted-text)] text-[11px] sm:text-xs">Active desk checklist items and 5:00 AM status</span>
            </div>
          </div>
          <p className="text-[11px] sm:text-xs text-[var(--muted-text)] mt-4 pt-3 border-t border-[var(--border-subtle)]">
            All tables are governed by strict <strong>PostgreSQL Row-Level Security (RLS)</strong>. Only your authenticated user ID can read, modify, or delete your study records.
          </p>
        </section>

        {/* Section 4 */}
        <section>
          <div className="flex items-center gap-2.5 mb-2.5">
            <Smartphone size={16} className="text-[var(--accent)]" />
            <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)]">
              4. Local Notifications & Operating System Permissions
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] mb-3 leading-relaxed">
            All notifications and timer alerts in Modulix are generated <strong>100% locally on your hardware</strong> using the Android OS AlarmManager. Modulix does not transmit push notification tokens (APNs/FCM) or study schedules to any external servers:
          </p>
          <div className="space-y-3 text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            <div>
              <strong className="text-[var(--ink-foreground)] font-mono text-xs">POST_NOTIFICATIONS:</strong> The single runtime prompt requested on Android 13+ to display the ongoing study chronometer in the notification drawer and scheduled study reminders.
            </div>
            <div>
              <strong className="text-[var(--ink-foreground)] font-mono text-xs">USE_EXACT_ALARM & SCHEDULE_EXACT_ALARM:</strong> Pierces Android 11–16 Deep Doze at the exact millisecond a focus session or break interval expires so timer alarms ring on time without delay.
            </div>
            <div>
              <strong className="text-[var(--ink-foreground)] font-mono text-xs">RECEIVE_BOOT_COMPLETED:</strong> Automatically restores scheduled morning kickoff and streak protection reminders when your device is restarted.
            </div>
            <div>
              <strong className="text-[var(--ink-foreground)] font-mono text-xs">REQUEST_IGNORE_BATTERY_OPTIMIZATIONS:</strong> Optional diagnostic setting allowing OnePlus, Xiaomi, and Samsung users to exempt Modulix from aggressive OEM background task killers.
            </div>
          </div>
        </section>

        {/* Section 5 */}
        <section className="pt-6 border-t border-[var(--border-subtle)]">
          <div className="flex items-center gap-2.5 mb-2.5">
            <Trash2 size={16} className="text-rose-500" />
            <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)]">
              5. Account Deletion & Right to Erasure
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] mb-4 leading-relaxed">
            In compliance with Google Play’s user data policy, users have an unconditional right to permanently delete their cloud account and all associated study data at any time without reinstalling the application.
          </p>
          <ApplePressable
            onClick={() => navigate("#/account")}
            className="px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold inline-flex items-center gap-2 shadow-sm"
          >
            <Trash2 size={13} />
            <span>Launch Account & Data Erasure Portal</span>
          </ApplePressable>
        </section>
      </div>
    </div>
  )
}
