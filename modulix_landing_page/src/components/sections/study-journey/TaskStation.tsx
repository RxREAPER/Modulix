import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Check } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TaskStation({ isActive }: StationProps) {
  const { isDark } = useTheme()
  const [typedText, setTypedText] = useState("")
  const [isCompleted, setIsCompleted] = useState(false)

  const fullText = "Robbins Pathology · Neoplasia"

  useEffect(() => {
    if (!isActive) {
      setTypedText("")
      setIsCompleted(false)
      return
    }

    let index = 0
    setTypedText("")
    setIsCompleted(false)

    // Type out the task text
    const interval = setInterval(() => {
      index++
      if (index <= fullText.length) {
        setTypedText(fullText.slice(0, index))
      } else {
        clearInterval(interval)
        // Complete the task with strikethrough & checkmark
        setTimeout(() => {
          setIsCompleted(true)
        }, 400)
      }
    }, 40)

    return () => clearInterval(interval)
  }, [isActive])

  return (
    <div className="w-full flex items-center justify-center p-4 sm:p-6 select-none">
      {/* ── Minimalist Daily Desk Card (Zero Tags, Zero Badges) ── */}
      <motion.div
        layout
        className={`w-full max-w-sm rounded-2xl border p-6 transition-colors relative overflow-hidden ${
          isDark
            ? "bg-[#16171B] border-white/8 shadow-[0_12px_36px_rgba(0,0,0,0.4)]"
            : "bg-[#FCFAF5] border-[#EAE3D2] shadow-[0_8px_24px_rgba(0,0,0,0.04)]"
        }`}
      >
        <div className="flex items-start gap-3.5">
          {/* Minimalist Check Circle */}
          <div className="mt-0.5">
            <motion.div
              animate={{
                borderColor: isCompleted ? "var(--accent)" : isDark ? "rgba(255,255,255,0.2)" : "rgba(0,0,0,0.2)",
                backgroundColor: isCompleted ? "var(--accent)" : "transparent",
              }}
              transition={{ duration: 0.25 }}
              className="w-5 h-5 rounded-full border-[1.5px] flex items-center justify-center flex-shrink-0"
            >
              <AnimatePresence>
                {isCompleted && (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    exit={{ scale: 0 }}
                    transition={{ type: "spring", stiffness: 400, damping: 25 }}
                  >
                    <Check size={12} className="text-white stroke-[2.5]" />
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          </div>

          {/* Task Content */}
          <div className="flex-1 min-w-0">
            {/* Task Title with Inking Cursor */}
            <div className="relative inline-block font-editorial text-base sm:text-lg font-bold text-[var(--ink-foreground)] leading-snug">
              <span>{typedText || <span className="opacity-30 font-sans text-sm font-normal">What needs to get done?</span>}</span>

              {/* Inking Cursor */}
              {isActive && !isCompleted && (
                <motion.span
                  animate={{ opacity: [1, 0, 1] }}
                  transition={{ duration: 0.7, repeat: Infinity }}
                  className="inline-block w-[2px] h-4 bg-[var(--accent)] ml-0.5 translate-y-0.5"
                />
              )}

              {/* Ink Strikethrough Line */}
              <AnimatePresence>
                {isCompleted && (
                  <motion.div
                    initial={{ scaleX: 0 }}
                    animate={{ scaleX: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
                    className="absolute inset-x-0 top-1/2 h-[1.5px] bg-[var(--accent)] origin-left pointer-events-none"
                  />
                )}
              </AnimatePresence>
            </div>

            {/* Quiet Subtitle Meta */}
            <div className="mt-1 font-mono text-xs text-[var(--muted-text)] opacity-70">
              Video · 35 min
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
