import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { useTheme } from "../../../lib/theme"

interface FlipDigitProps {
  digit: string
  prevDigit: string
}

function MechanicalFlipCard({ digit, prevDigit }: FlipDigitProps) {
  const { isDark } = useTheme()
  const isFlipping = digit !== prevDigit

  const cardBg = isDark ? "#1C1C1E" : "#FFFFFF"
  const cardBorder = isDark ? "rgba(255,255,255,0.12)" : "rgba(0,0,0,0.12)"
  const textCol = isDark ? "#FFFFFF" : "#0F172A"

  return (
    <div
      className="relative w-16 sm:w-20 h-20 sm:h-24 select-none"
      style={{ perspective: 600 }}
    >
      {/* ── TOP STATIC HALF (Shows next digit) ── */}
      <div
        className="absolute top-0 inset-x-0 h-1/2 rounded-t-xl overflow-hidden flex items-end justify-center border-t border-x"
        style={{
          backgroundColor: cardBg,
          borderColor: cardBorder,
        }}
      >
        <span
          className="font-mono text-3xl sm:text-4xl font-bold leading-none translate-y-1/2"
          style={{ color: textCol }}
        >
          {digit}
        </span>
      </div>

      {/* ── BOTTOM STATIC HALF (Shows current digit) ── */}
      <div
        className="absolute bottom-0 inset-x-0 h-1/2 rounded-b-xl overflow-hidden flex items-start justify-center border-b border-x"
        style={{
          backgroundColor: cardBg,
          borderColor: cardBorder,
        }}
      >
        <span
          className="font-mono text-3xl sm:text-4xl font-bold leading-none -translate-y-1/2"
          style={{ color: textCol }}
        >
          {digit}
        </span>
      </div>

      {/* ── ANIMATED FALLING TOP FLAP ── */}
      <AnimatePresence mode="popLayout">
        {isFlipping && (
          <motion.div
            key={prevDigit}
            initial={{ rotateX: 0 }}
            animate={{ rotateX: -180 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.42, ease: [0.37, 0, 0.63, 1] }}
            style={{
              transformOrigin: "bottom center",
              transformStyle: "preserve-3d",
              backfaceVisibility: "hidden",
            }}
            className="absolute top-0 inset-x-0 h-1/2 rounded-t-xl overflow-hidden flex items-end justify-center border-t border-x z-10"
          >
            <div
              className="w-full h-full flex items-end justify-center"
              style={{
                backgroundColor: cardBg,
                borderColor: cardBorder,
              }}
            >
              <span
                className="font-mono text-3xl sm:text-4xl font-bold leading-none translate-y-1/2"
                style={{ color: textCol }}
              >
                {prevDigit}
              </span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Horizontal Split Mechanical Seam */}
      <div className="absolute top-1/2 -translate-y-1/2 inset-x-0 h-[1.5px] bg-black/40 dark:bg-black/80 z-20 pointer-events-none" />

      {/* Left and Right Mechanical Hinge Notches */}
      <div className="absolute top-1/2 -translate-y-1/2 -left-1 w-2 h-2 rounded-full bg-slate-400 dark:bg-slate-600 z-30" />
      <div className="absolute top-1/2 -translate-y-1/2 -right-1 w-2 h-2 rounded-full bg-slate-400 dark:bg-slate-600 z-30" />
    </div>
  )
}

export function FlipClockMotionPreview() {
  const [seconds, setSeconds] = useState(1500) // 25:00
  const [prevSeconds, setPrevSeconds] = useState(1500)

  useEffect(() => {
    const timer = setInterval(() => {
      setSeconds((prev) => {
        setPrevSeconds(prev)
        return prev > 0 ? prev - 1 : 1500
      })
    }, 1000)
    return () => clearInterval(timer)
  }, [])

  const formatMinSec = (sec: number) => {
    const m = Math.floor(sec / 60)
    const s = sec % 60
    return {
      minStr: m.toString().padStart(2, "0"),
      secStr: s.toString().padStart(2, "0"),
    }
  }

  const current = formatMinSec(seconds)
  const prev = formatMinSec(prevSeconds)

  return (
    <div className="w-full py-4 flex flex-col items-center justify-center select-none">
      <div className="flex items-center gap-2.5 sm:gap-4 drop-shadow-[0_8px_16px_rgba(0,0,0,0.12)]">
        {/* Minutes */}
        <MechanicalFlipCard digit={current.minStr} prevDigit={prev.minStr} />

        {/* Colon separator */}
        <div className="flex flex-col gap-2 opacity-60">
          <div className="w-1.5 h-1.5 rounded-full bg-[var(--ink-foreground)]" />
          <div className="w-1.5 h-1.5 rounded-full bg-[var(--ink-foreground)]" />
        </div>

        {/* Seconds */}
        <MechanicalFlipCard digit={current.secStr} prevDigit={prev.secStr} />
      </div>

      <div className="mt-3 text-[11px] font-mono tracking-widest text-[var(--muted-text)] uppercase">
        25:00 · Focused Study State
      </div>
    </div>
  )
}
