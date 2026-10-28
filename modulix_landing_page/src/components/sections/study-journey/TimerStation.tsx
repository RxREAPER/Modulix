import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TimerStation({ isActive }: StationProps) {
  const { isDark } = useTheme()
  const [sec, setSec] = useState(1500)

  useEffect(() => {
    if (!isActive) return
    const timer = setInterval(() => {
      setSec((prev) => (prev > 0 ? prev - 1 : 1500))
    }, 1000)
    return () => clearInterval(timer)
  }, [isActive])

  const m = Math.floor(sec / 60).toString().padStart(2, "0")
  const s = (sec % 60).toString().padStart(2, "0")

  // Soundwave Equalizer Heights
  const waveHeights = [0.4, 0.8, 1.0, 0.6, 0.9, 0.7, 0.5, 0.85]

  return (
    <div className="w-full h-full flex flex-col items-center justify-center p-5 select-none relative">
      {/* ── Mechanical 3D Split Flap Pod ── */}
      <div className="flex items-center gap-2 drop-shadow-md">
        <div
          className={`w-14 h-16 rounded-xl border flex items-center justify-center relative overflow-hidden ${
            isDark ? "bg-[#18191D] border-white/10" : "bg-[#FCFAF5] border-[#E8DEC8]"
          }`}
        >
          <span className="font-mono text-2xl font-bold text-[var(--ink-foreground)]">
            {m}
          </span>
          <div className="absolute top-1/2 inset-x-0 h-[1.5px] bg-black/40 dark:bg-black/80" />
        </div>

        <span className="font-mono text-xl font-bold text-[var(--accent)] animate-pulse">:</span>

        <div
          className={`w-14 h-16 rounded-xl border flex items-center justify-center relative overflow-hidden ${
            isDark ? "bg-[#18191D] border-white/10" : "bg-[#FCFAF5] border-[#E8DEC8]"
          }`}
        >
          <span className="font-mono text-2xl font-bold text-[var(--ink-foreground)]">
            {s}
          </span>
          <div className="absolute top-1/2 inset-x-0 h-[1.5px] bg-black/40 dark:bg-black/80" />
        </div>
      </div>

      {/* ── Bouncing Ambient Audio Equalizer Waveform ── */}
      <div className="mt-4 flex items-end gap-1.5 h-7">
        {waveHeights.map((h, i) => (
          <motion.div
            key={i}
            animate={{
              height: isActive ? [`${h * 40}%`, `${h * 100}%`, `${h * 50}%`] : "25%",
            }}
            transition={{
              repeat: Infinity,
              duration: 0.6 + i * 0.08,
              ease: "easeInOut",
            }}
            className="w-1.5 rounded-full bg-[var(--accent)] origin-bottom"
          />
        ))}
      </div>

      <div className="mt-2.5 text-[10px] font-mono tracking-widest text-[var(--muted-text)] uppercase">
        Pomodoro & Rain Audio
      </div>
    </div>
  )
}
