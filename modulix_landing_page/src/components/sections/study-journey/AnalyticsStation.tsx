import { motion } from "framer-motion"
import { Flame, TrendingUp } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function AnalyticsStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  // 14 consecutive days of activity intensities (0 to 4)
  const heatmapCells = [2, 3, 4, 1, 3, 4, 4, 2, 3, 4, 3, 4, 4, 4]

  return (
    <div className="w-full flex flex-col items-center justify-center p-2 sm:p-4 select-none">
      <div
        className={`w-full max-w-xs rounded-2xl border p-4 shadow-lg transition-colors relative ${
          isDark
            ? "bg-[#18191D] border-white/10 shadow-[0_12px_32px_rgba(0,0,0,0.5)]"
            : "bg-[#FCFAF5] border-[#E8DEC8] shadow-[0_10px_28px_rgba(0,0,0,0.06)]"
        }`}
      >
        {/* Header: Editorial Momentum Header (_HeroMomentumHeader) */}
        <div className="flex items-center justify-between pb-2.5 mb-2.5 border-b border-black/[0.06] dark:border-white/[0.06]">
          <div className="flex items-center gap-1.5 text-amber-500 font-mono text-[10px] font-bold tracking-wide">
            <Flame size={12} className="fill-amber-500" />
            <span>12-DAY STREAK</span>
            <span className="opacity-50 font-normal">· BEST 24D</span>
          </div>

          <div className="text-[10px] font-mono text-[var(--muted-text)] font-semibold">
            TOP: PATHOLOGY
          </div>
        </div>

        {/* Big Logged Focus Duration Counter with Rolling Animation */}
        <div className="flex items-baseline justify-between mb-3">
          <div>
            <span className="text-[9px] font-mono tracking-widest text-[var(--muted-text)] uppercase block">
              TODAY'S DEEP WORK
            </span>
            <motion.div
              animate={{
                scale: isActive ? [1, 1.04, 1] : 1,
                color: isActive ? "var(--accent)" : "var(--ink-foreground)",
              }}
              transition={{ duration: 0.5 }}
              className="font-mono text-2xl sm:text-3xl font-bold tracking-tight"
            >
              {isActive ? "03h 45m" : "00h 00m"}
            </motion.div>
          </div>

          <div className="text-right">
            <span className="text-[10px] font-mono font-bold text-[#10B981] flex items-center gap-1 justify-end">
              <TrendingUp size={11} />
              +1h 15m
            </span>
            <span className="text-[9px] font-mono text-[var(--muted-text)] block">
              4 sessions today
            </span>
          </div>
        </div>

        {/* ── Module Planner Hero Card (_ModulePlannerHeroCard) ── */}
        <div className="p-2.5 rounded-xl border border-black/5 dark:border-white/5 bg-black/[0.02] dark:bg-white/[0.02] mb-3">
          <div className="flex items-center justify-between text-[11px] font-medium mb-1">
            <span className="font-editorial font-bold text-[var(--ink-foreground)]">
              Pathology Plan
            </span>
            <span className="font-mono text-[10px] text-[#10B981] font-semibold">
              36 of 80 vids · On Pace
            </span>
          </div>

          {/* Velocity Progress Bar */}
          <div className="w-full h-1.5 rounded-full bg-black/10 dark:bg-white/10 overflow-hidden mb-1.5">
            <motion.div
              className="h-full rounded-full bg-[#10B981]"
              animate={{ width: isActive ? "45%" : "20%" }}
              transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            />
          </div>

          <div className="flex items-center justify-between text-[9px] font-mono text-[var(--muted-text)]">
            <span>Target: 4 vids/day</span>
            <span>Deadline: 30 Nov</span>
          </div>
        </div>

        {/* ── 14-Day Consistency Matrix Heatmap Strip (NeetConsistencyMatrix) ── */}
        <div>
          <div className="flex items-center justify-between text-[9px] font-mono text-[var(--muted-text)] mb-1.5">
            <span>CONSISTENCY MATRIX</span>
            <span className="text-[var(--accent)] font-semibold">14 CONSECUTIVE DAYS</span>
          </div>

          <div className="grid grid-cols-7 gap-1">
            {heatmapCells.map((level, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0.3 }}
                animate={{
                  opacity: isActive ? 1 : 0.3,
                  scale: isActive ? 1 : 0.9,
                  backgroundColor:
                    isActive && level >= 3
                      ? "#10B981"
                      : isActive && level === 2
                      ? "#34D399"
                      : isActive && level === 1
                      ? "#A7F3D0"
                      : isDark
                      ? "#2A2B30"
                      : "#E2E8F0",
                }}
                transition={{
                  delay: i * 0.03,
                  duration: 0.25,
                }}
                className="h-3.5 rounded-[3px] shadow-xs"
              />
            ))}
          </div>
        </div>

        {/* Deep Work Focus Breakdown Pills */}
        <div className="mt-3 pt-2 border-t border-black/[0.05] dark:border-white/[0.05] flex items-center justify-between text-[9px] font-mono">
          <div className="flex items-center gap-1 text-[#3B82F6]">
            <div className="w-1.5 h-1.5 rounded-full bg-[#3B82F6]" />
            <span>Video · 2h 15m</span>
          </div>
          <div className="flex items-center gap-1 text-[#10B981]">
            <div className="w-1.5 h-1.5 rounded-full bg-[#10B981]" />
            <span>Q-Bank · 50m</span>
          </div>
          <div className="flex items-center gap-1 text-[#F59E0B]">
            <div className="w-1.5 h-1.5 rounded-full bg-[#F59E0B]" />
            <span>Notes · 40m</span>
          </div>
        </div>
      </div>
    </div>
  )
}
