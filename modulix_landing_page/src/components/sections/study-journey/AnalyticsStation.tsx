import { motion } from "framer-motion"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function AnalyticsStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  // 18 mini heatmap activity dots
  const dots = [
    1, 2, 3, 4, 3, 2, 4, 4, 3, 2, 1, 4, 3, 4, 2, 3, 4, 4
  ]

  return (
    <div className="w-full h-full flex flex-col items-center justify-center p-5 select-none relative">
      {/* ── Surging Rolling Digit Counter ── */}
      <div className="text-center mb-3">
        <span className="text-[10px] font-mono tracking-widest text-[var(--muted-text)] uppercase block">
          LOGGED STUDY TIME
        </span>
        <motion.div
          animate={{
            scale: isActive ? [1, 1.08, 1] : 1,
            color: isActive ? "var(--accent)" : "var(--ink-foreground)",
          }}
          transition={{ duration: 0.5 }}
          className="font-mono text-3xl sm:text-4xl font-bold tracking-tight"
        >
          {isActive ? "+02:30h" : "00:00h"}
        </motion.div>
      </div>

      {/* ── Glowing 24h Chronotype Heatmap Matrix ── */}
      <div className="p-3 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)]">
        <div className="grid grid-cols-6 gap-1.5">
          {dots.map((level, i) => (
            <motion.div
              key={i}
              initial={{ scale: 0.8, opacity: 0.3 }}
              animate={{
                scale: isActive ? 1 : 0.85,
                opacity: isActive ? 1 : 0.3,
                backgroundColor: isActive && level > 2 ? "var(--accent)" : isDark ? "#2A2B30" : "#CBD5E1",
              }}
              transition={{
                delay: i * 0.03,
                duration: 0.3,
              }}
              className="w-4 h-4 rounded-[4px] shadow-sm"
            />
          ))}
        </div>
      </div>

      <div className="mt-3 text-[10px] font-mono tracking-widest text-[var(--muted-text)] uppercase">
        Chronotype & Velocity Logged
      </div>
    </div>
  )
}
