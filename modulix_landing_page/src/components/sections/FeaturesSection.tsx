import { motion } from "framer-motion"
import { BookOpen, Clock, CalendarDays, BellRing, Database } from "lucide-react"

export function FeaturesSection() {
  const features = [
    {
      number: "01",
      icon: BookOpen,
      title: "Comprehensive 19 MBBS Subjects Curriculum",
      subtitle: "Multi-modal tracking across Videos, Q-Banks (MCQs), and High-Yield Clinical Notes.",
      description: "Full syllabus mapping across Editions 6.5 and 8 with instant search across all modules, unit numbers, titles, and clinical topics. Features elastic swipe-to-complete and bulk unit marking that does not skew your daily study history.",
      highlight: "800+ Videos · 19 Subjects",
    },
    {
      number: "02",
      icon: Clock,
      title: "Deep Focus Timer & Ambient Studio",
      subtitle: "Immersion study modes with procedural ambient audio and lock screen alarms.",
      description: "Supports Pomodoro, Count-Up stopwatch, and Module-Linked study modes. Includes synthesized background sounds (forest rain, brown noise, crackling fireplace, deep stream). Integrated with Android AlarmManager.setAlarmClock to pierce Deep Doze.",
      highlight: "Lock Screen · Deep Doze Piercer",
    },
    {
      number: "03",
      icon: CalendarDays,
      title: "Daily Desk & Intelligent 5:00 AM Rollover",
      subtitle: "Automated '2 Stale + 2 Fresh = 4' quota engine preventing backlog overload.",
      description: "Medical doctors frequently study past midnight. Modulix offsets the study day to 5:00 AM instead of calendar midnight. Incomplete tasks carry over marked with amber [Stale] tags, while your daily quota remains strictly capped.",
      highlight: "5 AM Boundary · Anti-Snowball",
    },
    {
      number: "04",
      icon: BellRing,
      title: "Hardware Audio & Battery Resilience",
      subtitle: "Headphone disconnect protection and OEM battery optimization guard.",
      description: "Features a native ACTION_AUDIO_BECOMING_NOISY receiver that automatically pauses ambient sounds when Bluetooth headphones disconnect in quiet study libraries. Built-in battery optimization whitelist checker prevents Android task-killing.",
      highlight: "Library Safe · Earbud Sensor",
    },
    {
      number: "05",
      icon: Database,
      title: "Native SQLite C-Engine Study Analytics",
      subtitle: "Instant SQL aggregations, activity heatmaps, and tamper-proof session logs.",
      description: "Study session analytics are calculated inside the SQLite engine via C-level SUM(CASE WHEN ...) aggregations, eliminating memory heap allocation. Features active streak calculations, subject velocities, and optional public leaderboards.",
      highlight: "Zero Heap Churn · Instant Analytics",
    },
  ]

  return (
    <section className="py-12 border-t border-[var(--border-subtle)]">
      <div className="mb-8">
        <h2 className="font-editorial text-3xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Engineering & Clinical Architecture
        </h2>
        <p className="text-sm text-[var(--muted-text)] mt-1 max-w-xl">
          Designed without boxed card clutter or repetitive wrappers. Built specifically around the cognitive demands of medical post-graduate preparation.
        </p>
      </div>

      <div className="divide-y divide-[var(--border-subtle)]">
        {features.map((feat, idx) => (
          <motion.div
            key={feat.number}
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-20px" }}
            transition={{ duration: 0.3, delay: idx * 0.04 }}
            className="py-7 flex flex-col md:flex-row md:items-start justify-between gap-5"
          >
            <div className="flex items-start gap-4 max-w-xl">
              <span className="font-editorial text-xl font-bold text-[var(--accent)] opacity-80 pt-0.5">
                {feat.number}
              </span>
              <div>
                <h3 className="text-base sm:text-lg font-semibold text-[var(--ink-foreground)]">
                  {feat.title}
                </h3>
                <p className="text-xs font-medium text-[var(--accent)] mt-0.5">
                  {feat.subtitle}
                </p>
                <p className="text-xs sm:text-sm text-[var(--muted-text)] mt-2 leading-relaxed">
                  {feat.description}
                </p>
              </div>
            </div>

            <div className="self-start md:self-center pl-8 md:pl-0">
              <span className="inline-block px-3 py-1.5 rounded-full text-[11px] font-semibold bg-[var(--surface-subtle)] border border-[var(--border-subtle)] text-[var(--ink-foreground)]">
                {feat.highlight}
              </span>
            </div>
          </motion.div>
        ))}
      </div>
    </section>
  )
}
