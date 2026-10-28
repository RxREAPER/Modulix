import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { CheckSquare, BookOpen, Clock, BarChart3, Trophy, Play, Pause } from "lucide-react"
import { useTheme } from "../../../lib/theme"
import { TaskStation } from "./TaskStation"
import { TopicStation } from "./TopicStation"
import { TimerStation } from "./TimerStation"
import { AnalyticsStation } from "./AnalyticsStation"
import { PodiumStation } from "./PodiumStation"

export function StudyJourneySection() {
  const { isDark } = useTheme()
  const [activeStep, setActiveStep] = useState(0)
  const [isPlaying, setIsPlaying] = useState(true)

  const steps = [
    {
      id: "task",
      number: "01",
      icon: CheckSquare,
      title: "Daily Desk",
      headline: "Daily Desk",
      description: "Capture study to-dos with ink and clean paper aesthetics.",
      component: <TaskStation isActive={activeStep === 0} />,
    },
    {
      id: "topic",
      number: "02",
      icon: BookOpen,
      title: "Curriculum",
      headline: "Curriculum",
      description: "Align daily focus blocks with 19 MBBS subjects.",
      component: <TopicStation isActive={activeStep === 1} />,
    },
    {
      id: "timer",
      number: "03",
      icon: Clock,
      title: "Focus Timer",
      headline: "Focus Timer",
      description: "Deep work with split-flap mechanics and procedural rain audio.",
      component: <TimerStation isActive={activeStep === 2} />,
    },
    {
      id: "analytics",
      number: "04",
      icon: BarChart3,
      title: "Analytics",
      headline: "Analytics",
      description: "Automatic local aggregation of focus hours and study streaks.",
      component: <AnalyticsStation isActive={activeStep === 3} />,
    },
    {
      id: "leaderboard",
      number: "05",
      icon: Trophy,
      title: "Leaderboard",
      headline: "Leaderboard",
      description: "Verified study hours reflected on the daily clinical podium.",
      component: <PodiumStation isActive={activeStep === 4} />,
    },
  ]

  // Auto-play kinetic flow cycle
  useEffect(() => {
    if (!isPlaying) return
    const interval = setInterval(() => {
      setActiveStep((prev) => (prev + 1) % steps.length)
    }, 3400)
    return () => clearInterval(interval)
  }, [isPlaying, steps.length])

  return (
    <section className="py-16 sm:py-20 border-t border-[var(--border-subtle)] select-none">
      {/* ── Section Title ── */}
      <div className="mb-12 text-center max-w-xl mx-auto space-y-2">
        <span className="font-mono text-[10px] tracking-widest text-[var(--accent)] font-semibold uppercase">
          THE COMPLETE DAILY LOOP
        </span>
        <h2 className="font-editorial text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Clinical Study Pipeline
        </h2>
        <p className="text-xs sm:text-sm text-[var(--muted-text)] font-medium">
          Watch how a single study thought moves through the Modulix kinetic engine.
        </p>
      </div>

      {/* ── Interactive 5-Step Pipeline Roadmap Bar ── */}
      <div className="max-w-3xl mx-auto mb-10 px-4">
        <div className="relative flex items-center justify-between">
          {/* Animated Glowing Connection Line */}
          <div className="absolute top-1/2 left-4 right-4 -translate-y-1/2 h-[2px] bg-[var(--border-subtle)] z-0">
            <motion.div
              className="h-full bg-[var(--accent)] origin-left"
              animate={{
                width: `${(activeStep / (steps.length - 1)) * 100}%`,
              }}
              transition={{ duration: 0.4, ease: "easeInOut" }}
            />
          </div>

          {/* 5 Pipeline Milestone Nodes */}
          {steps.map((st, idx) => {
            const Icon = st.icon
            const isCurrent = activeStep === idx
            const isCompleted = activeStep > idx

            return (
              <button
                key={st.id}
                onClick={() => {
                  setActiveStep(idx)
                  setIsPlaying(false)
                }}
                className="relative z-10 flex flex-col items-center group cursor-pointer focus:outline-none"
              >
                {/* Node Button Circle */}
                <motion.div
                  animate={{
                    scale: isCurrent ? 1.2 : 1,
                    borderColor: isCurrent || isCompleted ? "var(--accent)" : "var(--border-subtle)",
                    backgroundColor: isCurrent ? "var(--accent)" : isDark ? "#18191D" : "#FFFFFF",
                  }}
                  transition={{ duration: 0.25 }}
                  className="w-9 h-9 sm:w-11 sm:h-11 rounded-full border-2 flex items-center justify-center shadow-md transition-colors"
                >
                  <Icon
                    size={16}
                    className={
                      isCurrent
                        ? "text-white"
                        : isCompleted
                        ? "text-[var(--accent)]"
                        : "text-[var(--muted-text)]"
                    }
                  />
                </motion.div>

                {/* Node Step Label */}
                <span
                  className={`mt-2 font-mono text-[10px] tracking-wider uppercase font-semibold hidden sm:block ${
                    isCurrent ? "text-[var(--accent)]" : "text-[var(--muted-text)]"
                  }`}
                >
                  {st.title}
                </span>
              </button>
            )
          })}
        </div>
      </div>

      {/* ── The Kinetic Showcase Stage ── */}
      <div className="max-w-2xl mx-auto px-4">
        <div
          className={`rounded-2xl border p-6 sm:p-8 relative shadow-xl overflow-hidden transition-colors ${
            isDark
              ? "bg-[#141518] border-white/10 shadow-[0_16px_40px_rgba(0,0,0,0.5)]"
              : "bg-white border-black/8 shadow-[0_12px_36px_rgba(0,0,0,0.06)]"
          }`}
        >
          {/* Active Step Indicator Pill & Play/Pause */}
          <div className="flex items-center justify-between pb-4 mb-4 border-b border-black/[0.05] dark:border-white/[0.05]">
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs font-bold text-[var(--accent)]">
                PHASE {steps[activeStep].number} // 05
              </span>
              <span className="text-[var(--muted-text)] opacity-40">·</span>
              <span className="text-xs font-semibold text-[var(--ink-foreground)]">
                {steps[activeStep].headline}
              </span>
            </div>

            <button
              onClick={() => setIsPlaying(!isPlaying)}
              className="flex items-center gap-1.5 px-2.5 py-1 rounded-full border border-[var(--border-subtle)] text-[10px] font-mono text-[var(--muted-text)] hover:text-[var(--ink-foreground)] transition-colors"
            >
              {isPlaying ? <Pause size={10} /> : <Play size={10} />}
              <span>{isPlaying ? "AUTO-LOOP" : "PAUSED"}</span>
            </button>
          </div>

          {/* Dedicated High-Motion Station Component */}
          <div className="min-h-[220px] sm:min-h-[240px] flex items-center justify-center">
            <AnimatePresence mode="wait">
              <motion.div
                key={activeStep}
                initial={{ opacity: 0, y: 12, scale: 0.98 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: -12, scale: 0.98 }}
                transition={{ duration: 0.22, ease: [0.16, 1, 0.3, 1] }}
                className="w-full flex items-center justify-center"
              >
                {steps[activeStep].component}
              </motion.div>
            </AnimatePresence>
          </div>

          {/* Description Footer */}
          <p className="text-center text-xs sm:text-sm text-[var(--muted-text)] font-normal leading-relaxed max-w-md mx-auto pt-3">
            {steps[activeStep].description}
          </p>
        </div>
      </div>
    </section>
  )
}
