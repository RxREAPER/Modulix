import { useState } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { ChevronLeft, ChevronRight } from "lucide-react"
import { useTheme } from "../../lib/theme"
import { ClipboardClip } from "./clinical-clipboard/ClipboardClip"
import { TaskMotionPreview } from "./clinical-clipboard/TaskMotionPreview"
import { FlipClockMotionPreview } from "./clinical-clipboard/FlipClockMotionPreview"
import { LeaderboardMotionPreview } from "./clinical-clipboard/LeaderboardMotionPreview"
import { AnalyticsMotionPreview } from "./clinical-clipboard/AnalyticsMotionPreview"
import { SyllabusMotionPreview } from "./clinical-clipboard/SyllabusMotionPreview"
import { ThemesMotionPreview } from "./clinical-clipboard/ThemesMotionPreview"

export function FeaturesSection() {
  const { isDark } = useTheme()
  const [currentIndex, setCurrentIndex] = useState(0)

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

  const handleNext = () => {
    setCurrentIndex((prev) => (prev + 1) % total)
  }

  const handlePrev = () => {
    setCurrentIndex((prev) => (prev - 1 + total) % total)
  }

  const activeSheet = sheets[currentIndex]

  return (
    <section className="py-14 border-t border-[var(--border-subtle)] select-none">
      {/* ── Section Header ── */}
      <div className="mb-12 text-center max-w-xl mx-auto space-y-2">
        <h2 className="font-editorial text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Clinical Architecture
        </h2>
        <p className="text-xs sm:text-sm text-[var(--muted-text)] font-medium">
          Physical rounding folios built with pure motion and clinical precision.
        </p>
      </div>

      {/* ── 3D Physical Stacking Viewport ── */}
      <div className="relative max-w-lg mx-auto min-h-[480px] sm:min-h-[500px] flex items-center justify-center">
        {/* Layer 3 Behind (Counter rotated) */}
        <div
          className={`absolute inset-0 rounded-2xl border transition-all pointer-events-none ${
            isDark
              ? "bg-[#0A0A0A] border-white/[0.04] shadow-[0_12px_24px_rgba(0,0,0,0.6)]"
              : "bg-[#F1F5F9] border-black/[0.04] shadow-[0_12px_24px_rgba(0,0,0,0.06)]"
          }`}
          style={{
            transform: "translateY(24px) scale(0.92) rotate(-2deg)",
            zIndex: 1,
          }}
        />

        {/* Layer 2 Behind (Clockwise rotated) */}
        <div
          className={`absolute inset-0 rounded-2xl border transition-all pointer-events-none ${
            isDark
              ? "bg-[#101012] border-white/[0.08] shadow-[0_16px_32px_rgba(0,0,0,0.7)]"
              : "bg-[#FAFAFA] border-black/[0.06] shadow-[0_16px_32px_rgba(0,0,0,0.08)]"
          }`}
          style={{
            transform: "translateY(12px) scale(0.96) rotate(2deg)",
            zIndex: 2,
          }}
        />

        {/* ── Active Draggable Physical Clipboard ── */}
        <AnimatePresence mode="wait">
          <motion.div
            key={currentIndex}
            drag="x"
            dragConstraints={{ left: 0, right: 0 }}
            dragElastic={0.65}
            onDragEnd={(_, info) => {
              if (info.offset.x < -60) {
                handleNext()
              } else if (info.offset.x > 60) {
                handlePrev()
              }
            }}
            initial={{ opacity: 0, y: 16, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -16, scale: 0.96 }}
            transition={{ type: "spring", stiffness: 340, damping: 28 }}
            className={`relative z-10 w-full rounded-2xl p-6 sm:p-8 border pt-11 cursor-grab active:cursor-grabbing shadow-xl ${
              isDark
                ? "bg-[#141416] border-white/[0.12] text-white"
                : "bg-white border-black/[0.09] text-[#0F172A]"
            }`}
          >
            {/* Real Titanium / Steel Mechanical Clip */}
            <ClipboardClip />

            {/* Folio Header: Serial Number & Title */}
            <div className="text-center space-y-2 mb-4">
              <span className="font-mono text-[11px] font-bold tracking-widest text-[var(--accent)] uppercase">
                FOLIO {activeSheet.number} / 06
              </span>
              <h3 className="font-editorial text-2xl sm:text-3xl font-bold tracking-[-0.4px] leading-tight text-[var(--ink-foreground)]">
                {activeSheet.title}
              </h3>
              <p className="text-xs sm:text-sm text-[var(--muted-text)] font-normal leading-relaxed max-w-md mx-auto pt-1">
                {activeSheet.description}
              </p>
            </div>

            {/* Dedicated Hyper-Realistic Motion Component */}
            <div className="my-3">
              {activeSheet.motionComponent}
            </div>

            {/* Subtle swipe cue on mobile */}
            <div className="text-center text-[10px] font-mono tracking-widest text-[var(--muted-text)] opacity-40 pt-2">
              SWIPE OR USE ARROWS
            </div>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* ── Minimalist Stepper & Pagination ── */}
      <div className="max-w-xs mx-auto mt-7 flex items-center justify-between">
        <button
          onClick={handlePrev}
          className="w-9 h-9 rounded-full border border-[var(--border-subtle)] flex items-center justify-center text-[var(--ink-foreground)] hover:bg-[var(--surface-subtle)] transition-colors active:scale-95"
          aria-label="Previous sheet"
        >
          <ChevronLeft size={16} />
        </button>

        {/* 6 Minimal Pill Dots */}
        <div className="flex items-center gap-1.5">
          {sheets.map((_, idx) => (
            <button
              key={idx}
              onClick={() => setCurrentIndex(idx)}
              className={`h-1.5 rounded-full transition-all ${
                currentIndex === idx
                  ? "w-6 bg-[var(--accent)]"
                  : "w-1.5 bg-[var(--border-subtle)] hover:bg-[var(--muted-text)]"
              }`}
              aria-label={`Go to sheet ${idx + 1}`}
            />
          ))}
        </div>

        <button
          onClick={handleNext}
          className="w-9 h-9 rounded-full border border-[var(--border-subtle)] flex items-center justify-center text-[var(--ink-foreground)] hover:bg-[var(--surface-subtle)] transition-colors active:scale-95"
          aria-label="Next sheet"
        >
          <ChevronRight size={16} />
        </button>
      </div>
    </section>
  )
}
