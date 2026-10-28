import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Headphones } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TimerStation({ isActive }: StationProps) {
  const { isDark } = useTheme()
  const [seconds, setSeconds] = useState(59)
  const [minutes, setMinutes] = useState(24)

  useEffect(() => {
    if (!isActive) {
      setMinutes(24)
      setSeconds(59)
      return
    }

    const interval = setInterval(() => {
      setSeconds((prev) => {
        if (prev <= 1) {
          setMinutes((m) => (m > 0 ? m - 1 : 24))
          return 59
        }
        return prev - 1
      })
    }, 1000)

    return () => clearInterval(interval)
  }, [isActive])

  const sStr = seconds.toString().padStart(2, "0")
  const mStr = minutes.toString().padStart(2, "0")

  // Soundwave Equalizer Heights
  const waveHeights = [0.35, 0.75, 1.0, 0.6, 0.9, 0.7, 0.45, 0.8]

  return (
    <div className="w-full flex items-center justify-center p-4 sm:p-6 select-none">
      {/* ── Minimalist Split-Flap Clock Stage (Zero Tags, Zero Badges) ── */}
      <motion.div
        layout
        className={`w-full max-w-sm rounded-2xl border p-6 transition-colors relative flex flex-col items-center justify-center ${
          isDark
            ? "bg-[#16171B] border-white/8 shadow-[0_12px_36px_rgba(0,0,0,0.4)]"
            : "bg-[#FCFAF5] border-[#EAE3D2] shadow-[0_8px_24px_rgba(0,0,0,0.04)]"
        }`}
      >
        {/* ── Mechanical Split-Flap Clock Display (SketchFlipCard) ── */}
        <div className="flex items-center justify-center gap-3 py-2">
          {/* Minutes Split-Flap Card */}
          <div
            className={`w-16 h-20 sm:w-20 sm:h-24 rounded-xl border relative flex flex-col shadow-inner overflow-hidden ${
              isDark ? "bg-[#111215] border-white/12" : "bg-[#F3EFE6] border-[#DCD3C0]"
            }`}
          >
            {/* Top Half */}
            <div className="flex-1 flex items-end justify-center pb-0 overflow-hidden relative">
              <span className="font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] translate-y-3.5 sm:translate-y-4">
                {mStr}
              </span>
            </div>
            {/* Split Hinge Seam with Side Notches */}
            <div className="relative h-[1.5px] bg-black/40 dark:bg-black/90 w-full z-10">
              <div className="absolute -left-1 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-black/60" />
              <div className="absolute -right-1 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-black/60" />
            </div>
            {/* Bottom Half */}
            <div className="flex-1 flex items-start justify-center pt-0 overflow-hidden relative bg-black/[0.02] dark:bg-black/20">
              <span className="font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] -translate-y-3.5 sm:-translate-y-4">
                {mStr}
              </span>
            </div>
          </div>

          {/* Pulsing Colon Separator */}
          <span className="font-mono text-2xl font-bold text-[var(--accent)] opacity-80 animate-pulse">:</span>

          {/* Seconds Split-Flap Card with 3D Flip */}
          <div
            className={`w-16 h-20 sm:w-20 sm:h-24 rounded-xl border relative flex flex-col shadow-inner overflow-hidden ${
              isDark ? "bg-[#111215] border-white/12" : "bg-[#F3EFE6] border-[#DCD3C0]"
            }`}
          >
            {/* Top Half */}
            <div className="flex-1 flex items-end justify-center pb-0 overflow-hidden relative">
              <AnimatePresence mode="popLayout">
                <motion.span
                  key={sStr}
                  initial={{ rotateX: -90, opacity: 0 }}
                  animate={{ rotateX: 0, opacity: 1 }}
                  exit={{ rotateX: 90, opacity: 0 }}
                  transition={{ duration: 0.35, ease: "easeOut" }}
                  className="font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] translate-y-3.5 sm:translate-y-4 origin-bottom"
                >
                  {sStr}
                </motion.span>
              </AnimatePresence>
            </div>
            {/* Split Hinge Seam with Side Notches */}
            <div className="relative h-[1.5px] bg-black/40 dark:bg-black/90 w-full z-10">
              <div className="absolute -left-1 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-black/60" />
              <div className="absolute -right-1 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-black/60" />
            </div>
            {/* Bottom Half */}
            <div className="flex-1 flex items-start justify-center pt-0 overflow-hidden relative bg-black/[0.02] dark:bg-black/20">
              <span className="font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] -translate-y-3.5 sm:-translate-y-4">
                {sStr}
              </span>
            </div>
          </div>
        </div>

        {/* Ambient Sound (Minimal Waveform + Quiet Text) */}
        <div className="mt-4 flex items-center gap-2 text-xs font-mono text-[var(--muted-text)] opacity-70">
          <Headphones size={13} className="text-[var(--accent)]" />
          <span>Rain on Window</span>
          <div className="flex items-end gap-0.5 h-3 ml-1">
            {waveHeights.map((h, i) => (
              <motion.div
                key={i}
                animate={{
                  height: isActive ? [`${h * 30}%`, `${h * 100}%`, `${h * 40}%`] : "25%",
                }}
                transition={{
                  repeat: Infinity,
                  duration: 0.6 + i * 0.08,
                  ease: "easeInOut",
                }}
                className="w-0.5 rounded-full bg-[var(--accent)] origin-bottom"
              />
            ))}
          </div>
        </div>
      </motion.div>
    </div>
  )
}
