import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { CheckSquare, BookOpen, Clock, BarChart3, Trophy } from "lucide-react"
import { useTheme } from "../../../lib/theme"
import { TaskStation } from "./TaskStation"
import { TopicStation } from "./TopicStation"
import { TimerStation } from "./TimerStation"
import { AnalyticsStation } from "./AnalyticsStation"
import { PodiumStation } from "./PodiumStation"

export function StudyJourneySection() {
  const { isDark } = useTheme()
  const [activeStep, setActiveStep] = useState(0)

  // Auto-play kinetic flow cycle by default
  useEffect(() => {
    const interval = setInterval(() => {
      setActiveStep((prev) => (prev + 1) % 5)
    }, 4000)
    return () => clearInterval(interval)
  }, [activeStep])

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

  return (
    <section className="py-16 sm:py-20 border-t border-[var(--border-subtle)] select-none">
      {/* ── Section Title ── */}
      <div className="mb-10 text-center max-w-xl mx-auto space-y-2 px-4">
        <span className="font-mono text-[10px] tracking-widest text-[var(--accent)] font-semibold uppercase">
          THE COMPLETE DAILY LOOP
        </span>
        <h2 className="font-editorial text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Modulix-Based Study Timeline
        </h2>
        <p className="text-xs sm:text-sm text-[var(--muted-text)] font-medium">
          Watch how a single study thought moves through the Modulix kinetic engine.
        </p>
      </div>

      {/* ── Interactive 5-Step Pipeline Roadmap Bar ── */}
      <div className="max-w-3xl mx-auto mb-8 px-4">
        <div className="relative flex items-center justify-between">
          {/* Animated Connecting Line */}
          <div className="absolute top-1/2 left-4 right-4 -translate-y-1/2 h-[2px] bg-[var(--border-subtle)] z-0">
            <motion.div
              className="h-full bg-[var(--accent)] origin-left"
              animate={{
                width: `${(activeStep / (steps.length - 1)) * 100}%`,
              }}
              transition={{ duration: 0.35, ease: "easeInOut" }}
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
                onClick={() => setActiveStep(idx)}
                className="relative z-10 flex flex-col items-center group cursor-pointer focus:outline-none"
              >
                {/* Node Button Circle */}
                <motion.div
                  animate={{
                    scale: isCurrent ? 1.18 : 1,
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

      {/* ── Preserved Step Heading & Phase Indicator (Secured, Zero Geometry Shift) ── */}
      <div className="max-w-xl mx-auto px-4 mb-4 text-center">
        {/* Shoved out of the card: Phase indicator */}
        <div className="flex items-center justify-center gap-2 mb-1.5">
          <span className="font-mono text-xs font-bold tracking-widest text-[var(--accent)] uppercase">
            PHASE {steps[activeStep].number} / 05
          </span>
          <span className="text-[var(--muted-text)] opacity-40">·</span>
          <span className="font-mono text-xs font-semibold text-[var(--ink-foreground)] uppercase tracking-wider">
            {steps[activeStep].headline}
          </span>
        </div>

        {/* Preserved description with locked min-height so switching never jumps vertical layout */}
        <div className="h-10 sm:h-8 flex items-center justify-center">
          <p className="text-xs sm:text-sm text-[var(--muted-text)] font-normal leading-relaxed max-w-md">
            {steps[activeStep].description}
          </p>
        </div>
      </div>

      {/* ── Unboxed Kinetic Showcase Stage (Motion Cards Sit Directly on Canvas) ── */}
      <div className="max-w-xl mx-auto px-4 flex items-center justify-center">
        <div className="w-full min-h-[220px] sm:min-h-[230px] flex items-center justify-center">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeStep}
              initial={{ opacity: 0, y: 8, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -8, scale: 0.98 }}
              transition={{ duration: 0.22, ease: [0.16, 1, 0.3, 1] }}
              className="w-full flex items-center justify-center"
            >
              {steps[activeStep].component}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
    </section>
  )
}
