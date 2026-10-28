import { useRef } from "react"
import { motion, useScroll, useTransform } from "framer-motion"
import { useTheme } from "../../lib/theme"
import { SpiralSpringBinding } from "./clinical-clipboard/SpiralSpringBinding"
import { TaskMotionPreview } from "./clinical-clipboard/TaskMotionPreview"
import { FlipClockMotionPreview } from "./clinical-clipboard/FlipClockMotionPreview"
import { LeaderboardMotionPreview } from "./clinical-clipboard/LeaderboardMotionPreview"
import { AnalyticsMotionPreview } from "./clinical-clipboard/AnalyticsMotionPreview"
import { SyllabusMotionPreview } from "./clinical-clipboard/SyllabusMotionPreview"
import { ThemesMotionPreview } from "./clinical-clipboard/ThemesMotionPreview"

interface SheetItem {
  number: string
  title: string
  description: string
  motionComponent: JSX.Element
  nextCue: string
}

function NotepadCard({
  sheet,
  index,
  total,
}: {
  sheet: SheetItem
  index: number
  total: number
}) {
  const { isDark } = useTheme()
  const cardTrackRef = useRef<HTMLDivElement>(null)

  // Track scroll through this card's section
  const { scrollYProgress } = useScroll({
    target: cardTrackRef,
    offset: ["start start", "end start"],
  })

  // When the next card glides over this one, subtly scale down and dim
  const scale = useTransform(scrollYProgress, [0, 1], [1, 0.94])
  const opacity = useTransform(scrollYProgress, [0, 0.85], [1, 0.5])
  // Page curl / flip upwards around top spiral spring
  const rotateX = useTransform(scrollYProgress, [0, 1], [0, -18])
  const y = useTransform(scrollYProgress, [0, 1], [0, -28])

  return (
    <div
      ref={cardTrackRef}
      className={`relative w-full ${
        index === total - 1 ? "min-h-[70vh] sm:min-h-[75vh]" : "min-h-[85vh] sm:min-h-[92vh]"
      }`}
      style={{ perspective: 1200 }}
    >
      <motion.div
        style={{
          scale,
          opacity,
          rotateX,
          y,
          zIndex: 10 + index,
          transformOrigin: "top center",
          transformStyle: "preserve-3d",
        }}
        className={`sticky top-24 sm:top-28 w-full max-w-lg mx-auto rounded-2xl p-6 sm:p-8 border shadow-xl overflow-hidden transition-colors ${
          isDark
            ? "bg-[#16171A] border-[#2A2B30] text-white shadow-[0_16px_40px_rgba(0,0,0,0.6)]"
            : "bg-[#FCFAF5] border-[#E5DFD5] text-[#0F172A] shadow-[0_12px_36px_rgba(0,0,0,0.09)]"
        }`}
      >
        {/* Paper Ruled Background Lines */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            backgroundImage: isDark
              ? "repeating-linear-gradient(transparent, transparent 31px, rgba(255,255,255,0.016) 31px, rgba(255,255,255,0.016) 32px)"
              : "repeating-linear-gradient(transparent, transparent 31px, rgba(0,0,0,0.026) 31px, rgba(0,0,0,0.026) 32px)",
          }}
        />

        {/* Doctor Pad Vertical Red/Amber Margin Line */}
        <div className="absolute left-8 sm:left-12 top-0 bottom-0 w-[1px] bg-red-400/20 dark:bg-rose-500/15 pointer-events-none" />

        {/* Realistic Coiled Spiral Springs & Punched Tear Holes */}
        <SpiralSpringBinding />

        {/* Folio Text Content */}
        <div className="text-center space-y-1.5 mb-3 relative z-10">
          <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
            PAGE {sheet.number} OF 06
          </span>
          <h3 className="font-editorial text-2xl sm:text-3xl font-bold tracking-[-0.4px] leading-tight text-[var(--ink-foreground)]">
            {sheet.title}
          </h3>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] font-normal leading-relaxed max-w-md mx-auto pt-0.5">
            {sheet.description}
          </p>
        </div>

        {/* Hyper-Realistic Dedicated Motion Component */}
        <div className="my-3 relative z-10">
          {sheet.motionComponent}
        </div>

        {/* Bottom Folio Stamp & Peeking Hint */}
        <div className="mt-4 pt-2 border-t border-black/[0.04] dark:border-white/[0.04] flex items-center justify-between text-[10px] font-mono tracking-widest text-[var(--muted-text)] opacity-50 relative z-10">
          <span>{sheet.nextCue}</span>
          <span>FOLIO {sheet.number} // 06</span>
        </div>
      </motion.div>
    </div>
  )
}

export function FeaturesSection() {
  const sheets: SheetItem[] = [
    {
      number: "01",
      title: "Tasks with Projects & Module-Based Tasks",
      description:
        "Modulix lets you plan daily tasks across individual to-dos and custom projects with subject and unit presets, keeping your daily study time clean, structured, and manageable.",
      motionComponent: <TaskMotionPreview />,
      nextCue: "↓ SCROLL DOWN FOR TIMER",
    },
    {
      number: "02",
      title: "Focus & Pomodoro Timer",
      description:
        "A lively, highly personalized focus timer with dynamic backgrounds and ambient sounds. Features a science-backed Pomodoro mode and a distraction-free, fullscreen flip clock.",
      motionComponent: <FlipClockMotionPreview />,
      nextCue: "↓ SCROLL DOWN FOR LEADERBOARD",
    },
    {
      number: "03",
      title: "Leaderboard",
      description:
        "Stay motivated alongside fellow medical aspirants. Track your study consistency and climb verified rankings across daily, weekly, monthly, and all-time leaderboards.",
      motionComponent: <LeaderboardMotionPreview />,
      nextCue: "↓ SCROLL DOWN FOR ANALYTICS",
    },
    {
      number: "04",
      title: "Analytics",
      description:
        "Gain clear insights into your study habits with detailed daily activity heatmaps, subject time distributions, velocity charts, and consistency streaks.",
      motionComponent: <AnalyticsMotionPreview />,
      nextCue: "↓ SCROLL DOWN FOR SYLLABUS",
    },
    {
      number: "05",
      title: "Gold Standard Syllabus to Track",
      description:
        "Track your preparation, tasks, projects, and goals across a preloaded standard medical syllabus. No need to type every topic—we've got you covered with both latest and previous editions, including video lectures, Q-Banks, and clinical modules.",
      motionComponent: <SyllabusMotionPreview />,
      nextCue: "↓ SCROLL DOWN FOR THEMES",
    },
    {
      number: "06",
      title: "Themes",
      description:
        "Bored with standard light and dark modes? Modulix features an advanced Theme Studio with cool, curated palettes tailored for comfortable daytime study and late-night hospital shifts.",
      motionComponent: <ThemesMotionPreview />,
      nextCue: "↓ SCROLL DOWN FOR THEME SHOWCASE",
    },
  ]

  return (
    <section className="py-14 border-t border-[var(--border-subtle)] select-none">
      {/* ── Section Title ── */}
      <div className="mb-14 text-center max-w-xl mx-auto space-y-2">
        <span className="font-mono text-[10px] tracking-widest text-[var(--accent)] font-semibold uppercase">
          CURATED CLINICAL SUITE
        </span>
        <h2 className="font-editorial text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Clinical Architecture
        </h2>
        <p className="text-xs sm:text-sm text-[var(--muted-text)] font-medium">
          Traditional rounding memo pad sheets stacked in continuous vertical study flow.
        </p>
      </div>

      {/* ── Vertical Stacking Notepad Track ── */}
      <div className="relative w-full max-w-lg mx-auto">
        {sheets.map((sheet, index) => (
          <NotepadCard
            key={sheet.number}
            sheet={sheet}
            index={index}
            total={sheets.length}
          />
        ))}
      </div>
    </section>
  )
}
