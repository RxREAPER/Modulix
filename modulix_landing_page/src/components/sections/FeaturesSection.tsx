import { useState, useRef } from "react"
import { motion, AnimatePresence, useScroll, useMotionValueEvent } from "framer-motion"
import { ChevronLeft, ChevronRight } from "lucide-react"
import { useTheme } from "../../lib/theme"
import { TraditionalNotepadHeader } from "./clinical-clipboard/TraditionalNotepadHeader"
import { TaskMotionPreview } from "./clinical-clipboard/TaskMotionPreview"
import { FlipClockMotionPreview } from "./clinical-clipboard/FlipClockMotionPreview"
import { LeaderboardMotionPreview } from "./clinical-clipboard/LeaderboardMotionPreview"
import { AnalyticsMotionPreview } from "./clinical-clipboard/AnalyticsMotionPreview"
import { SyllabusMotionPreview } from "./clinical-clipboard/SyllabusMotionPreview"
import { ThemesMotionPreview } from "./clinical-clipboard/ThemesMotionPreview"

export function FeaturesSection() {
  const { isDark } = useTheme()
  const [currentIndex, setCurrentIndex] = useState(0)
  const containerRef = useRef<HTMLDivElement>(null)

  const sheets = [
    {
      number: "01",
      title: "Tasks with Projects & Module-Based Tasks",
      description:
        "Modulix lets you plan daily tasks across individual to-dos and custom projects with subject and unit presets, keeping your daily study time clean, structured, and manageable.",
      motionComponent: <TaskMotionPreview />,
    },
    {
      number: "02",
      title: "Focus & Pomodoro Timer",
      description:
        "A lively, highly personalized focus timer with dynamic backgrounds and ambient sounds. Features a science-backed Pomodoro mode and a distraction-free, fullscreen flip clock.",
      motionComponent: <FlipClockMotionPreview />,
    },
    {
      number: "03",
      title: "Leaderboard",
      description:
        "Stay motivated alongside fellow medical aspirants. Track your study consistency and climb verified rankings across daily, weekly, monthly, and all-time leaderboards.",
      motionComponent: <LeaderboardMotionPreview />,
    },
    {
      number: "04",
      title: "Analytics",
      description:
        "Gain clear insights into your study habits with detailed daily activity heatmaps, subject time distributions, velocity charts, and consistency streaks.",
      motionComponent: <AnalyticsMotionPreview />,
    },
    {
      number: "05",
      title: "Gold Standard Syllabus to Track",
      description:
        "Track your preparation, tasks, projects, and goals across a preloaded standard medical syllabus. No need to type every topic—we've got you covered with both latest and previous editions, including video lectures, Q-Banks, and clinical modules.",
      motionComponent: <SyllabusMotionPreview />,
    },
    {
      number: "06",
      title: "Themes",
      description:
        "Bored with standard light and dark modes? Modulix features an advanced Theme Studio with cool, curated palettes tailored for comfortable daytime study and late-night hospital shifts.",
      motionComponent: <ThemesMotionPreview />,
    },
  ]

  const total = sheets.length

  // ── Scroll-Jacking / Sticky Sheet Flipping ──
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  })

  useMotionValueEvent(scrollYProgress, "change", (latest) => {
    const clamped = Math.min(Math.max(latest, 0), 0.9999)
    const nextIndex = Math.floor(clamped * total)
    if (nextIndex !== currentIndex) {
      setCurrentIndex(nextIndex)
    }
  })

  const goToSheet = (targetIdx: number) => {
    const safeIdx = Math.max(0, Math.min(targetIdx, total - 1))
    setCurrentIndex(safeIdx)
    if (containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect()
      const scrollTop = window.scrollY + rect.top
      const trackHeight = containerRef.current.scrollHeight - window.innerHeight
      const targetScroll = scrollTop + (safeIdx / (total - 1)) * trackHeight
      window.scrollTo({ top: targetScroll, behavior: "smooth" })
    }
  }

  const activeSheet = sheets[currentIndex]

  return (
    <section
      ref={containerRef}
      className="relative h-[340vh] sm:h-[380vh] border-t border-[var(--border-subtle)] select-none"
    >
      {/* ── Sticky Pinned Viewport (Stays locked on screen while scrubbing) ── */}
      <div className="sticky top-20 h-[calc(100vh-5rem)] flex flex-col justify-center items-center py-2 sm:py-4">
        {/* Section Header */}
        <div className="mb-4 sm:mb-6 text-center max-w-xl mx-auto space-y-1">
          <span className="font-mono text-[10px] tracking-widest text-[var(--accent)] font-semibold uppercase">
            SCROLL TO FLIP PAGES ({currentIndex + 1} OF {total})
          </span>
          <h2 className="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-[var(--ink-foreground)]">
            Clinical Architecture
          </h2>
        </div>

        {/* ── Traditional Notepad Stack Stage ── */}
        <div className="relative w-full max-w-lg mx-auto min-h-[460px] sm:min-h-[490px] flex items-center justify-center px-4 sm:px-0">
          {/* Stack Layer 3 (Deepest paper sheet) */}
          <div
            className={`absolute inset-0 rounded-2xl border transition-all pointer-events-none ${
              isDark
                ? "bg-[#101114] border-white/[0.04] shadow-md"
                : "bg-[#EFE8DC] border-[#DFD5C5] shadow-sm"
            }`}
            style={{
              transform: "translate(4px, 8px)",
              zIndex: 1,
            }}
          />

          {/* Stack Layer 2 (Middle paper sheet) */}
          <div
            className={`absolute inset-0 rounded-2xl border transition-all pointer-events-none ${
              isDark
                ? "bg-[#131417] border-white/[0.07] shadow-md"
                : "bg-[#F5F0E6] border-[#E8DEC8] shadow-sm"
            }`}
            style={{
              transform: "translate(2px, 4px)",
              zIndex: 2,
            }}
          />

          {/* ── Active Notepad Paper Sheet (Fast & Snappy Transition) ── */}
          <AnimatePresence mode="popLayout">
            <motion.div
              key={currentIndex}
              initial={{ opacity: 0, y: 16, scale: 0.985 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -16, scale: 0.985 }}
              transition={{ duration: 0.16, ease: [0.16, 1, 0.3, 1] }}
              className={`relative z-10 w-full rounded-2xl p-6 sm:p-8 border shadow-xl overflow-hidden ${
                isDark
                  ? "bg-[#16171A] border-[#2A2B30] text-white"
                  : "bg-[#FCFAF5] border-[#E5DFD5] text-[#0F172A]"
              }`}
              style={{
                backgroundImage: isDark
                  ? "repeating-linear-gradient(transparent, transparent 31px, rgba(255,255,255,0.016) 31px, rgba(255,255,255,0.016) 32px)"
                  : "repeating-linear-gradient(transparent, transparent 31px, rgba(0,0,0,0.028) 31px, rgba(0,0,0,0.028) 32px)",
              }}
            >
              {/* Vertical Doctor Pad Margin Guide */}
              <div className="absolute left-8 sm:left-12 top-0 bottom-0 w-[1px] bg-red-400/20 dark:bg-rose-500/15 pointer-events-none" />

              {/* Classic Cloth Tape Header with Brass Staples & Perforation */}
              <TraditionalNotepadHeader />

              {/* Folio Header: Serial Number & Title */}
              <div className="text-center space-y-1.5 mb-3 relative z-10">
                <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
                  PAGE {activeSheet.number} / 06
                </span>
                <h3 className="font-editorial text-xl sm:text-2xl font-bold tracking-[-0.4px] leading-tight text-[var(--ink-foreground)]">
                  {activeSheet.title}
                </h3>
                <p className="text-xs sm:text-sm text-[var(--muted-text)] font-normal leading-relaxed max-w-md mx-auto pt-0.5">
                  {activeSheet.description}
                </p>
              </div>

              {/* Dedicated Realism Motion Component */}
              <div className="my-2 relative z-10">
                {activeSheet.motionComponent}
              </div>

              {/* Bottom Subtle Paper Corner Cue */}
              <div className="mt-3 flex items-center justify-between text-[10px] font-mono tracking-widest text-[var(--muted-text)] opacity-45 relative z-10">
                <span>SCROLL DOWN ↓</span>
                <span>FOLIO {activeSheet.number}</span>
              </div>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* ── Interactive Stepper & Page Indicators ── */}
        <div className="max-w-xs mx-auto mt-4 sm:mt-6 flex items-center justify-between gap-4">
          <button
            onClick={() => goToSheet(currentIndex - 1)}
            disabled={currentIndex === 0}
            className="w-8 h-8 rounded-full border border-[var(--border-subtle)] flex items-center justify-center text-[var(--ink-foreground)] hover:bg-[var(--surface-subtle)] disabled:opacity-30 disabled:pointer-events-none transition-colors active:scale-95"
            aria-label="Previous sheet"
          >
            <ChevronLeft size={15} />
          </button>

          {/* 6 Minimal Pill Dots */}
          <div className="flex items-center gap-1.5">
            {sheets.map((_, idx) => (
              <button
                key={idx}
                onClick={() => goToSheet(idx)}
                className={`h-1.5 rounded-full transition-all ${
                  currentIndex === idx
                    ? "w-6 bg-[var(--accent)]"
                    : "w-1.5 bg-[var(--border-subtle)] hover:bg-[var(--muted-text)]"
                }`}
                aria-label={`Go to page ${idx + 1}`}
              />
            ))}
          </div>

          <button
            onClick={() => goToSheet(currentIndex + 1)}
            disabled={currentIndex === total - 1}
            className="w-8 h-8 rounded-full border border-[var(--border-subtle)] flex items-center justify-center text-[var(--ink-foreground)] hover:bg-[var(--surface-subtle)] disabled:opacity-30 disabled:pointer-events-none transition-colors active:scale-95"
            aria-label="Next sheet"
          >
            <ChevronRight size={15} />
          </button>
        </div>
      </div>
    </section>
  )
}
