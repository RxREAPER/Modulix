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
    <div className="pt-10 border-t border-[var(--border-subtle)] space-y-6">
      <div>
        <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] flex items-center gap-2">
          <HelpCircle size={20} className="text-[var(--accent)]" />
          <span>Frequently Asked Questions</span>
        </h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {faqs.map((faq, i) => (
          <div
            key={i}
            className="p-4 rounded-xl border border-[var(--border-subtle)] bg-[var(--card-bg)] space-y-1.5"
          >
            <h4 className="text-xs font-semibold text-[var(--ink-foreground)] leading-snug">
              {faq.q}
            </h4>
            <p className="text-xs text-[var(--muted-text)] leading-relaxed">
              {faq.a}
            </p>
          </div>
        ))}
      </div>

      <div className="p-4 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2.5">
          <Bug size={16} className="text-[var(--accent)]" />
          <span className="text-xs text-[var(--ink-foreground)]">
            Encountered an issue or have a medical syllabus correction?
          </span>
        </div>
        <a
          href={APP_CONSTANTS.githubIssuesUrl}
          target="_blank"
          rel="noreferrer"
        >
          <ApplePressable className="px-3.5 py-1.5 rounded-lg border border-[var(--border-subtle)] bg-[var(--card-bg)] text-xs font-semibold text-[var(--ink-foreground)] flex items-center gap-1.5">
            <span>Open Issue on GitHub</span>
            <ExternalLink size={12} />
          </ApplePressable>
        </a>
      </div>
    </div>
  )
}
