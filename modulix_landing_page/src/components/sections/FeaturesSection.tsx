import { motion } from "framer-motion"
import { useTheme } from "../../lib/theme"
import { TaskMotionPreview } from "./clinical-clipboard/TaskMotionPreview"
import { FlipClockMotionPreview } from "./clinical-clipboard/FlipClockMotionPreview"
import { LeaderboardMotionPreview } from "./clinical-clipboard/LeaderboardMotionPreview"
import { AnalyticsMotionPreview } from "./clinical-clipboard/AnalyticsMotionPreview"
import { SyllabusMotionPreview } from "./clinical-clipboard/SyllabusMotionPreview"
import { ThemesMotionPreview } from "./clinical-clipboard/ThemesMotionPreview"

interface FeatureItem {
  number: string
  tag: string
  title: string
  description: string
  component: JSX.Element
}

export function FeaturesSection() {
  const { isDark } = useTheme()

  const features: FeatureItem[] = [
    {
      number: "01",
      tag: "DAILY DESK",
      title: "Daily Tasks & Module Projects",
      description:
        "Plan your study day with ink-strike checklists and subject-aligned project queues. The 5:00 AM rollover and 4-task cap prevent backlog overwhelm.",
      component: <TaskMotionPreview />,
    },
    {
      number: "02",
      tag: "DEEP WORK",
      title: "Split-Flap Focus & Pomodoro Timer",
      description:
        "Tactile split-flap numbers and procedural audio. Integrated with Android Exact Alarms to wake deep Doze at the exact scheduled second.",
      component: <FlipClockMotionPreview />,
    },
    {
      number: "03",
      tag: "COMMUNITY",
      title: "Verified Study Leaderboard",
      description:
        "Compare consistency against fellow medical aspirants across daily, weekly, monthly, and all-time podiums with verified anti-tamper hours.",
      component: <LeaderboardMotionPreview />,
    },
    {
      number: "04",
      tag: "INSIGHTS",
      title: "Cognitive Analytics & Velocity",
      description:
        "High-performance study analytics calculated directly inside on-device SQLite. Track subject distributions, pace, and revision streaks with zero cloud latency.",
      component: <AnalyticsMotionPreview />,
    },
    {
      number: "05",
      tag: "CURRICULUM",
      title: "19 MBBS Subjects Preloaded",
      description:
        "Complete medical syllabus structured across Marrow Editions 6.5 and 8. Pre-indexed video lectures, Q-Banks, and clinical notes with zero manual data entry.",
      component: <SyllabusMotionPreview />,
    },
    {
      number: "06",
      tag: "AESTHETICS",
      title: "Theme Studio & Clinical Palettes",
      description:
        "Calibrated color systems engineered for long study marathons: high-contrast Daybreak for bright libraries and deep Midnight for late-night hospital shifts.",
      component: <ThemesMotionPreview />,
    },
  ]

  return (
    <section className="py-16 sm:py-24 border-t border-[var(--border-subtle)] select-none">
      {/* ── Section Title ── */}
      <div className="mb-14 text-center max-w-xl mx-auto space-y-2 px-4">
        <span className="font-mono text-[10px] tracking-widest text-[var(--accent)] font-semibold uppercase">
          CLINICAL ARCHITECTURE
        </span>
        <h2 className="font-editorial text-3xl sm:text-5xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Core Systems & Capabilities
        </h2>
        <p className="text-xs sm:text-sm text-[var(--muted-text)] font-medium max-w-md mx-auto">
          Minimalist, offline-first tools engineered with clinical precision for medical school and residency.
        </p>
      </div>

      {/* ── Responsive Luxury Editorial Grid ── */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8">
        {features.map((feat, idx) => (
          <motion.div
            key={feat.number}
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-50px" }}
            transition={{ duration: 0.4, delay: idx * 0.06 }}
            className={`rounded-2xl border p-6 sm:p-7 flex flex-col justify-between transition-all duration-200 ${
              isDark
                ? "bg-[#141518] border-white/[0.08] hover:border-white/[0.18] shadow-[0_8px_24px_rgba(0,0,0,0.35)]"
                : "bg-white border-[#E7E3D8] hover:border-[#D5CFBF] shadow-[0_4px_20px_rgba(0,0,0,0.03)]"
            }`}
          >
            {/* Header: Tag + Title + Description */}
            <div className="space-y-2 mb-5">
              <div className="flex items-center gap-2">
                <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
                  {feat.number} · {feat.tag}
                </span>
              </div>
              <h3 className="font-editorial text-2xl sm:text-3xl font-bold tracking-[-0.3px] text-[var(--ink-foreground)]">
                {feat.title}
              </h3>
              <p className="text-xs sm:text-sm text-[var(--muted-text)] font-normal leading-relaxed pt-0.5">
                {feat.description}
              </p>
            </div>

            {/* Live Interactive Preview Container */}
            <div
              className={`w-full rounded-xl border p-4 sm:p-5 flex items-center justify-center overflow-hidden ${
                isDark
                  ? "bg-[#0E0F12] border-white/[0.06]"
                  : "bg-[#FAF7F0] border-[#ECE7DA]"
              }`}
            >
              <div className="w-full flex items-center justify-center">
                {feat.component}
              </div>
            </div>
          </motion.div>
        ))}
      </div>
    </section>
  )
}
