import { motion } from "framer-motion"
import { CheckSquare, Clock, Trophy, BarChart3, BookOpen, Palette } from "lucide-react"

export function FeaturesSection() {
  const features = [
    {
      number: "01",
      icon: CheckSquare,
      title: "Tasks with Projects & Module-Based Tasks",
      subtitle: "Custom study lists and syllabus-linked task workflows.",
      description: "Modulix lets you plan daily tasks across individual to-dos and custom projects with subject and unit presets, keeping your daily study time clean, structured, and manageable.",
      highlight: "Daily Desk · Custom Projects · Presets",
    },
    {
      number: "02",
      icon: Clock,
      title: "Focus & Pomodoro Timer",
      subtitle: "Dynamic ambient soundscapes with a fullscreen flip clock.",
      description: "A lively, highly personalized focus timer with dynamic backgrounds and ambient sounds. Features a science-backed Pomodoro mode and a distraction-free, fullscreen flip clock.",
      highlight: "Pomodoro · Ambient Sounds · Flip Clock",
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
      subtitle: "Preloaded standard medical curriculum across current and previous editions.",
      description: "Track your preparation, tasks, projects, and goals across a preloaded standard medical syllabus. No need to type every topic—we've got you covered with both latest and previous editions, including video lectures, Q-Banks, and clinical modules.",
      highlight: "Preloaded Syllabus · Videos · Q-Banks",
    },
    {
      number: "06",
      icon: Palette,
      title: "Themes",
      subtitle: "Advanced Theme Studio with vibrant, curated clinical aesthetics.",
      description: "Bored with standard light and dark modes? Modulix features an advanced Theme Studio with cool, curated palettes tailored for comfortable daytime study and late-night hospital shifts.",
      highlight: "Theme Studio · Curated Palettes · OLED",
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
