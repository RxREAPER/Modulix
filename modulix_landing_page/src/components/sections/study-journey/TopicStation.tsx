import { motion } from "framer-motion"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TopicStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full h-full flex flex-col items-center justify-center p-5 select-none relative">
      {/* ── Magnetic Rotating Syllabus Wheel ── */}
      <div className="relative w-44 h-44 sm:w-48 sm:h-48 flex items-center justify-center">
        {/* Outer Circular Calibrated Ring */}
        <div
          className={`absolute inset-0 rounded-full border-[1.5px] border-dashed transition-all ${
            isActive ? "border-[var(--accent)] opacity-80" : "border-[var(--border-subtle)] opacity-40"
          }`}
        />

        {/* Animated Spinning Turntable Dial */}
        <motion.div
          animate={{
            rotate: isActive ? [0, 180, 360] : 0,
          }}
          transition={{
            duration: 1.4,
            ease: [0.16, 1, 0.3, 1],
          }}
          className="relative w-36 h-36 sm:w-40 sm:h-40 rounded-full border shadow-md flex items-center justify-center bg-[var(--card-bg)]"
        >
          {/* 4 Quadrant Marks */}
          <div className="absolute top-2 w-1.5 h-1.5 rounded-full bg-red-500" />
          <div className="absolute right-2 w-1.5 h-1.5 rounded-full bg-orange-500" />
          <div className="absolute bottom-2 w-1.5 h-1.5 rounded-full bg-emerald-500" />
          <div className="absolute left-2 w-1.5 h-1.5 rounded-full bg-rose-500" />

          {/* Magnetic Center Hub */}
          <div
            className={`w-24 h-24 rounded-full border flex flex-col items-center justify-center text-center p-2 transition-colors ${
              isDark ? "bg-[#18191D] border-white/10" : "bg-[#FCFAF5] border-[#E8DEC8]"
            }`}
          >
            <span className="text-[10px] font-mono tracking-widest text-[var(--accent)] font-semibold uppercase">
              LOCKED
            </span>
            <span className="font-editorial text-sm font-bold text-[var(--ink-foreground)] leading-tight mt-0.5">
              Pathology
            </span>
            <span className="text-[9px] font-mono text-[var(--muted-text)]">
              Ed 8.0 · 2nd Prof
            </span>
          </div>
        </motion.div>

        {/* Magnetic Crosshair Lock Reticle */}
        {isActive && (
          <motion.div
            initial={{ scale: 1.4, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.3, delay: 0.8 }}
            className="absolute inset-0 rounded-full border-2 border-[var(--accent)] pointer-events-none"
          />
        )}
      </div>

      <div className="mt-3 text-[11px] font-mono tracking-wider text-[var(--muted-text)]">
        Syllabus Module Connected
      </div>
    </div>
  )
}
