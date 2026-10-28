import { motion } from "framer-motion"
import { CheckSquare, Clock, Trophy, BarChart3, BookOpen, Palette } from "lucide-react"

export function FeaturesSection() {
  const features = [
    {
      number: "01",
      icon: CheckSquare,
      title: "Tasks with Projects & Module-Based Tasks",
      subtitle: "Custom study lists and syllabus-linked task workflows.",
      description: "Organize your daily study desk across custom personal projects or link tasks directly to syllabus modules and video units, keeping your daily workload clear and manageable.",
      highlight: "Daily Desk · Projects · Modules",
    },
    {
      number: "02",
      icon: Clock,
      title: "Focus & Pomodoro Timer",
      subtitle: "Distraction-free study timer with ambient background audio.",
      description: "Dedicated immersion timer with Pomodoro, Count-Up, and module-linked modes. Built-in ambient sounds (forest rain, brown noise, crackling fireplace) keep you focused during long study sessions.",
      highlight: "Pomodoro · Stopwatch · Ambient Audio",
    },
    {
      number: "03",
      icon: Trophy,
      title: "Leaderboard",
      subtitle: "Friendly community rankings across daily, weekly, and monthly milestones.",
      description: "Stay motivated alongside fellow medical aspirants. Track your study consistency and climb verified rankings across daily, weekly, monthly, and all-time leaderboards.",
      highlight: "Community · Daily · Weekly · Monthly",
    },
    {
      number: "04",
      icon: BarChart3,
      title: "Analytics",
      subtitle: "Visual study heatmaps, subject distribution, and streak tracking.",
      description: "Gain clear insights into your study habits with detailed daily activity heatmaps, subject time distributions, velocity charts, and consistency streaks.",
      highlight: "Heatmaps · Subject Velocity · Streaks",
    },
    {
      number: "05",
      icon: BookOpen,
      title: "Gold Standard Syllabus to Track",
      subtitle: "Complete coverage across all 19 MBBS subjects.",
      description: "Track your preparation across the standard medical curriculum. Seamlessly log your progress through video lectures, Q-Banks (MCQs), and high-yield clinical revision notes.",
      highlight: "19 Subjects · Videos · MCQs · Notes",
    },
    {
      number: "06",
      icon: Palette,
      title: "Themes",
      subtitle: "Five clinical aesthetics tailored for hospital duties and late-night reading.",
      description: "Switch seamlessly between Daylight Scholar, Midnight Scholar, Atomic Ice, Forest Mint, and Cosmic Mocha—engineered for maximum readability and zero eye fatigue.",
      highlight: "5 Curated Palettes · OLED Black",
    },
  ]

  return (
    <section className="py-12 border-t border-[var(--border-subtle)]">
      <div className="mb-8">
        <h2 className="font-editorial text-3xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Core Features
        </h2>
        <p className="text-sm text-[var(--muted-text)] mt-1 max-w-xl">
          Everything you need for disciplined medical preparation, built without clutter or distraction.
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
