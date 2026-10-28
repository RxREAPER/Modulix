import { motion } from "framer-motion"
import { Flame } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function AnalyticsStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  // 7-day consistency strip
  const days = [3, 4, 2, 4, 4, 3, 4]

  return (
    <div className="w-full flex items-center justify-center select-none">
      {/* ── Minimalist Analytics Card (Zero Tags, Zero Badges) ── */}
      <motion.div
        layout
        className={`w-full max-w-md rounded-2xl border p-6 sm:p-7 transition-colors relative overflow-hidden text-center ${
          isDark
            ? "bg-[#16171B] border-white/8 shadow-[0_12px_36px_rgba(0,0,0,0.4)]"
            : "bg-[#FCFAF5] border-[#EAE3D2] shadow-[0_8px_24px_rgba(0,0,0,0.04)]"
        }`}
      >
        {/* Big Rolling Focus Duration */}
        <div className="mb-4">
          <motion.div
            animate={{
              scale: isActive ? [1, 1.03, 1] : 1,
              color: isActive ? "var(--accent)" : "var(--ink-foreground)",
            }}
            transition={{ duration: 0.5 }}
            className="font-mono text-4xl sm:text-5xl font-bold tracking-tight text-[var(--ink-foreground)]"
          >
            {isActive ? "03:45" : "00:00"}
          </motion.div>
          <span className="font-mono text-xs text-[var(--muted-text)] opacity-70 block mt-1">
            hours focused today
          </span>
        </div>

        {/* 7-Day Consistency Heat Strip */}
        <div className="flex items-center justify-center gap-1.5 py-2">
          {days.map((level, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0.2 }}
              animate={{
                opacity: isActive ? 1 : 0.2,
                backgroundColor:
                  isActive && level >= 3
                    ? "#10B981"
                    : isActive && level === 2
                    ? "#34D399"
                    : isDark
                    ? "rgba(255,255,255,0.1)"
                    : "rgba(0,0,0,0.08)",
              }}
              transition={{ delay: i * 0.05, duration: 0.3 }}
              className="w-5 h-5 rounded-md"
            />
          ))}
        </div>

        {/* Clean Streak Line (Zero Badges) */}
        <div className="mt-4 pt-3 border-t border-black/5 dark:border-white/5 flex items-center justify-center gap-1.5 font-mono text-xs text-amber-500 font-medium">
          <Flame size={13} className="fill-amber-500" />
          <span>12 days streak</span>
        </div>
      </motion.div>
    </div>
  )
}
