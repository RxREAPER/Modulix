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

  // Soundwave Equalizer Heights from medical_wave_visualizer.dart
  const waveHeights = [0.35, 0.75, 1.0, 0.6, 0.9, 0.7, 0.45, 0.8]

  return (
    <div className="w-full flex flex-col items-center justify-center p-2 sm:p-4 select-none">
      <div
        className={`w-full max-w-xs rounded-2xl border p-4 shadow-lg transition-colors relative ${
          isDark
            ? "bg-[#18191D] border-white/10 shadow-[0_12px_32px_rgba(0,0,0,0.5)]"
            : "bg-[#FCFAF5] border-[#E8DEC8] shadow-[0_10px_28px_rgba(0,0,0,0.06)]"
        }`}
      >
        {/* Header: Mode & Pomodoro Cycle Row (from _buildPomodoroCycleRow) */}
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-black/[0.06] dark:border-white/[0.06]">
          <div className="flex items-center gap-1.5 text-[10px] font-mono tracking-wider font-bold text-[var(--accent)]">
            <span className="w-2 h-2 rounded-full bg-[var(--accent)] animate-pulse" />
            <span>POMODORO · 25 MIN</span>
          </div>

          {/* CYCLE 1 OF 4 indicator with 4 cycle pips */}
          <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-black/5 dark:bg-white/5 border border-black/5 dark:border-white/10">
            <span className="font-mono text-[9px] font-bold text-[var(--muted-text)]">
              CYCLE 1/4
            </span>
            <div className="flex items-center gap-1">
              {/* Pip 1 (Active) */}
              <div className="w-2 h-2 rounded-full bg-[var(--accent)]" />
              {/* Pip 2 */}
              <div className="w-2 h-2 rounded-full bg-black/20 dark:bg-white/20" />
              {/* Pip 3 */}
              <div className="w-2 h-2 rounded-full bg-black/20 dark:bg-white/20" />
              {/* Pip 4 (Long break interval) */}
              <div className="w-2 h-2 rounded-full border border-amber-500 bg-transparent" />
            </div>
          </div>
        </div>

        {/* ── Mechanical Split-Flap Clock Display (SketchFlipCard) ── */}
        <div className="flex items-center justify-center gap-2.5 py-1">
          {/* Minutes Split-Flap Card */}
          <div
            className={`w-16 h-20 sm:w-18 sm:h-22 rounded-xl border relative flex flex-col shadow-inner overflow-hidden ${
              isDark ? "bg-[#111215] border-white/15" : "bg-[#F3EFE6] border-[#DCD3C0]"
            }`}
          >
            {/* Top Half */}
            <div className="flex-1 flex items-end justify-center pb-0 overflow-hidden relative">
              <span className="font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] translate-y-3.5">
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
              <span className="font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] -translate-y-3.5">
                {mStr}
              </span>
            </div>
          </div>

          {/* Pulsing Colon Separator */}
          <span className="font-mono text-2xl font-bold text-[var(--accent)] animate-pulse">:</span>

          {/* Seconds Split-Flap Card with 3D Flip */}
          <div
            className={`w-16 h-20 sm:w-18 sm:h-22 rounded-xl border relative flex flex-col shadow-inner overflow-hidden ${
              isDark ? "bg-[#111215] border-white/15" : "bg-[#F3EFE6] border-[#DCD3C0]"
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
                  className="font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] translate-y-3.5 origin-bottom"
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
              <span className="font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] -translate-y-3.5">
                {sStr}
              </span>
            </div>
          </div>
        </div>

        {/* Ambient Sound Dock (from ambient_sound_sheet.dart) */}
        <div className="mt-3 pt-2.5 border-t border-black/[0.05] dark:border-white/[0.05] flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-[10px] font-mono text-[var(--muted-text)]">
            <Headphones size={11} className="text-[var(--accent)]" />
            <span>Ambient: Rain on Window</span>
          </div>

          {/* Equalizer Waveform */}
          <div className="flex items-end gap-1 h-3.5">
            {waveHeights.map((h, i) => (
              <motion.div
                key={i}
                animate={{
                  height: isActive ? [`${h * 30}%`, `${h * 100}%`, `${h * 40}%`] : "20%",
                }}
                transition={{
                  repeat: Infinity,
                  duration: 0.6 + i * 0.08,
                  ease: "easeInOut",
                }}
                className="w-1 rounded-full bg-[var(--accent)] origin-bottom"
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
