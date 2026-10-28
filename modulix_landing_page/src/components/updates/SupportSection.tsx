import { HelpCircle, ExternalLink, Bug } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { APP_CONSTANTS } from "../../lib/constants"

export function SupportSection() {
  const faqs = [
    {
      q: "Why does the study day roll over at 5:00 AM instead of midnight?",
      a: "Medical students frequently complete study sessions between 1:00 AM and 4:00 AM. Setting the day boundary to 5:00 AM prevents midnight from arbitrarily severing study streaks and breaking daily quotas.",
    },
    {
      q: "How does the '2 Stale + 2 Fresh = 4' Quota Engine work?",
      a: "To prevent backlog snowballing after busy clinical duty, missed tasks from yesterday are carried over into today's batch as 'Stale' items while the total daily quota remains strictly capped (e.g. 2 stale + 2 fresh = 4 total).",
    },
    {
      q: "Why does Modulix request the Exact Alarm permission on Android?",
      a: "Standard Android timers are throttled by the OS when the screen is off (Doze mode). Modulix uses AlarmManager.setAlarmClock so countdowns and breaks ring at the exact scheduled second, displaying on your Always-On Display.",
    },
    {
      q: "How can I restore my progress on a new phone?",
      a: "You can sign in with your Google or Email account to restore from Supabase cloud sync, or export a local JSON backup file from Settings -> Backup and import it onto your new phone.",
    },
  ]

  return (
    <div className="pt-12 border-t border-[var(--border-subtle)] space-y-8 select-none">
      <div>
        <div className="flex items-center gap-2 mb-1.5">
          <HelpCircle size={16} className="text-[var(--accent)]" />
          <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
            COMMUNITY & CLINICAL KNOWLEDGE BASE
          </span>
        </div>
        <h2 className="font-editorial text-2xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Frequently Asked Questions
        </h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
        {faqs.map((faq, i) => (
          <div
            key={i}
            className="p-5 sm:p-6 rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)] space-y-2 shadow-sm transition-all hover:border-[var(--accent)]/30"
          >
            <h4 className="text-xs sm:text-sm font-semibold text-[var(--ink-foreground)] leading-snug">
              {faq.q}
            </h4>
            <p className="text-xs text-[var(--muted-text)] leading-relaxed pt-0.5">
              {faq.a}
            </p>
          </div>
        ))}
      </div>

      <div className="p-5 sm:p-6 rounded-2xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-[var(--accent-subtle)] text-[var(--accent)] flex items-center justify-center shrink-0">
            <Bug size={17} />
          </div>
          <div>
            <div className="text-xs sm:text-sm font-semibold text-[var(--ink-foreground)]">
              Encountered a bug or have a medical syllabus correction?
            </div>
            <div className="text-[11px] text-[var(--muted-text)] mt-0.5">
              Tracked publicly on GitHub Issues with rapid engineering triage.
            </div>
          </div>
        </div>
        <a
          href={APP_CONSTANTS.githubIssuesUrl}
          target="_blank"
          rel="noreferrer"
          className="shrink-0"
        >
          <ApplePressable className="px-4 py-2.5 rounded-xl border border-[var(--border-subtle)] bg-[var(--card-bg)] text-xs font-semibold text-[var(--ink-foreground)] flex items-center justify-center gap-2 shadow-sm">
            <span>Open Issue on GitHub</span>
            <ExternalLink size={13} />
          </ApplePressable>
        </a>
      </div>
    </div>
  )
}
