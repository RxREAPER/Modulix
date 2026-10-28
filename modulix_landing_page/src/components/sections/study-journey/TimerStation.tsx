import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { Headphones } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

function SplitFlapTile({ value }: { value: string }) {
  const { isDark } = useTheme()
  const [currentVal, setCurrentVal] = useState(value)
  const [prevVal, setPrevVal] = useState(value)
  const [isFlipping, setIsFlipping] = useState(false)

  useEffect(() => {
    if (value !== currentVal) {
      setPrevVal(currentVal)
      setCurrentVal(value)
      setIsFlipping(true)
      const timer = setTimeout(() => setIsFlipping(false), 380)
      return () => clearTimeout(timer)
    }
  }, [value, currentVal])

  const bg = isDark ? "#121316" : "#F4EFE6"
  const border = isDark ? "rgba(255,255,255,0.12)" : "#DCD3C0"

  return (
    <div
      className="relative w-16 h-20 sm:w-20 sm:h-24 select-none rounded-xl overflow-hidden shadow-md border"
      style={{
        backgroundColor: bg,
        borderColor: border,
        perspective: 800,
      }}
    >
      {/* ── 1. Static Top (shows incoming value) ── */}
      <div className="absolute top-0 inset-x-0 h-1/2 overflow-hidden bg-black/[0.02] dark:bg-white/[0.02]">
        <div className="absolute top-0 inset-x-0 h-20 sm:h-24 flex items-center justify-center font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] leading-none">
          {currentVal}
        </div>
      </div>

      {/* ── 2. Static Bottom (shows prevVal while flipping, then currentVal) ── */}
      <div className="absolute bottom-0 inset-x-0 h-1/2 overflow-hidden bg-black/[0.04] dark:bg-black/30">
        <div className="absolute -top-10 sm:-top-12 inset-x-0 h-20 sm:h-24 flex items-center justify-center font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] leading-none">
          {isFlipping ? prevVal : currentVal}
        </div>
      </div>

      {/* ── 3. Dual Mechanical Flaps (0 -> -90deg, then 90deg -> 0deg: ZERO overlap) ── */}
      {isFlipping && (
        <>
          {/* Top Flap (prevVal top half) falling forward from 0deg down to -90deg */}
          <motion.div
            key={`top-${prevVal}`}
            initial={{ rotateX: 0, filter: "brightness(1)" }}
            animate={{ rotateX: -90, filter: "brightness(0.75)" }}
            transition={{ duration: 0.18, ease: "easeIn" }}
            style={{
              backgroundColor: bg,
              transformOrigin: "bottom center",
              backfaceVisibility: "hidden",
              WebkitBackfaceVisibility: "hidden",
            }}
            className="absolute top-0 inset-x-0 h-1/2 overflow-hidden z-10 border-b border-black/20 dark:border-black/60 shadow-sm"
          >
            <div className="absolute top-0 inset-x-0 h-20 sm:h-24 flex items-center justify-center font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] leading-none">
              {prevVal}
            </div>
          </motion.div>

          {/* Bottom Flap (currentVal bottom half) falling from 90deg down to 0deg */}
          <motion.div
            key={`bot-${currentVal}`}
            initial={{ rotateX: 90, filter: "brightness(0.75)" }}
            animate={{ rotateX: 0, filter: "brightness(1)" }}
            transition={{ duration: 0.18, delay: 0.18, ease: "easeOut" }}
            style={{
              backgroundColor: bg,
              transformOrigin: "top center",
              backfaceVisibility: "hidden",
              WebkitBackfaceVisibility: "hidden",
            }}
            className="absolute top-1/2 inset-x-0 h-1/2 overflow-hidden z-10 border-t border-black/10 dark:border-white/10 shadow-md"
          >
            <div className="absolute -top-10 sm:-top-12 inset-x-0 h-20 sm:h-24 flex items-center justify-center font-mono text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)] leading-none">
              {currentVal}
            </div>
          </motion.div>
        </>
      )}

      {/* Center Hinge Seam Line */}
      <div className="absolute top-1/2 -translate-y-1/2 inset-x-0 h-[1.5px] bg-black/40 dark:bg-black/80 z-20 pointer-events-none" />

      {/* Left & Right Mechanical Notches */}
      <div className="absolute top-1/2 -translate-y-1/2 -left-1 w-2 h-2 rounded-full bg-black/30 dark:bg-black/60 z-30" />
      <div className="absolute top-1/2 -translate-y-1/2 -right-1 w-2 h-2 rounded-full bg-black/30 dark:bg-black/60 z-30" />
    </div>
  )
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
    <div className="w-full flex items-center justify-center select-none">
      {/* ── Minimalist Split-Flap Clock Stage (Zero Tags, Zero Badges) ── */}
      <div
        className={`w-full max-w-md h-[200px] rounded-2xl border p-6 sm:p-7 transition-colors relative flex flex-col items-center justify-center ${
          isDark
            ? "bg-[#16171B] border-white/[0.08] shadow-[0_12px_36px_rgba(0,0,0,0.4)]"
            : "bg-[#FCFAF5] border-[#EAE3D2] shadow-[0_8px_24px_rgba(0,0,0,0.04)]"
        }`}
      >
        {/* Mechanical Split-Flap Clock Display with Zero Overlap */}
        <div className="flex items-center justify-center gap-3 py-1">
          <SplitFlapTile value={mStr} />
          <span className="font-mono text-2xl font-bold text-[var(--accent)] opacity-80 animate-pulse">:</span>
          <SplitFlapTile value={sStr} />
        </div>

        {/* Ambient Sound (Minimal Waveform + Quiet Text) */}
        <div className="mt-3 flex items-center gap-2 text-xs font-mono text-[var(--muted-text)] opacity-70">
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
      </div>
    </div>
  )
}
