import { motion } from "framer-motion"
import { Star } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function PodiumStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full flex items-center justify-center select-none">
      {/* ── Minimalist Podium Stage (Zero Tags, Zero Badges, Zero Buttons) ── */}
      <motion.div
        layout
        className={`w-full max-w-md rounded-2xl border p-6 sm:p-7 transition-colors relative overflow-hidden flex flex-col items-center justify-center ${
          isDark
            ? "bg-[#16171B] border-white/[0.08] shadow-[0_12px_36px_rgba(0,0,0,0.4)]"
            : "bg-[#FCFAF5] border-[#EAE3D2] shadow-[0_8px_24px_rgba(0,0,0,0.04)]"
        }`}
      >
        {/* ── Top 3 Rising Pedestals (EditorialPodium) ── */}
        <div className="flex items-end justify-center gap-3 w-full h-36 pt-2 px-2">
          {/* Rank 2 (Silver #94A3B8) */}
          <div className="flex-1 flex flex-col items-center">
            <div className="w-7 h-7 rounded-full bg-slate-200 dark:bg-slate-800 text-[10px] font-bold font-mono flex items-center justify-center text-slate-700 dark:text-slate-300 mb-1">
              RP
            </div>
            <div className="text-[11px] font-semibold text-[var(--ink-foreground)] leading-none truncate max-w-[65px]">
              Dr. Patel
            </div>
            <div className="text-[10px] font-mono text-[var(--muted-text)] opacity-70 mb-1.5">
              4h 15m
            </div>
            {/* Silver Pillar */}
            <motion.div
              animate={{ height: isActive ? 55 : 22 }}
              transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
              className="w-full rounded-t-lg bg-slate-300/50 dark:bg-slate-700/60 flex items-center justify-center text-[10px] font-mono font-bold text-slate-500"
            >
              #2
            </motion.div>
          </div>

          {/* Rank 1 (Gold #F59E0B) */}
          <div className="flex-1 flex flex-col items-center relative">
            {/* Gold Ascending Avatar */}
            <motion.div
              animate={{
                y: isActive ? [6, -3, 0] : 6,
                scale: isActive ? 1.1 : 1,
              }}
              transition={{ duration: 0.5, ease: "easeOut" }}
              className="w-8 h-8 rounded-full bg-amber-500 text-amber-950 font-bold text-xs flex items-center justify-center shadow-md mb-1 z-10"
            >
              <Star size={13} className="fill-amber-950 text-amber-950" />
            </motion.div>

            <div className="text-[11px] font-bold text-[var(--accent)] leading-none truncate max-w-[70px]">
              Dr. You
            </div>
            <div className="text-[10px] font-mono text-[var(--muted-text)] opacity-70 mb-1.5">
              5h 40m
            </div>

            {/* Gold Rising Pedestal with Metallic Sheen */}
            <motion.div
              animate={{ height: isActive ? 85 : 34 }}
              transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
              className="w-full rounded-t-lg bg-gradient-to-t from-amber-600 via-amber-500 to-amber-300 shadow-md relative overflow-hidden flex items-center justify-center text-[11px] font-mono font-extrabold text-amber-950"
            >
              {/* Metallic Sheen Sweep */}
              {isActive && (
                <motion.div
                  initial={{ left: "-100%" }}
                  animate={{ left: "200%" }}
                  transition={{ duration: 1.1, repeat: Infinity, repeatDelay: 1.6 }}
                  className="absolute inset-y-0 w-1/2 bg-white/40 skew-x-12"
                />
              )}
              <span>#1</span>
            </motion.div>
          </div>

          {/* Rank 3 (Bronze #EA580C) */}
          <div className="flex-1 flex flex-col items-center">
            <div className="w-7 h-7 rounded-full bg-amber-100 dark:bg-amber-950/40 text-[10px] font-bold font-mono flex items-center justify-center text-amber-800 dark:text-amber-400 mb-1">
              KI
            </div>
            <div className="text-[11px] font-semibold text-[var(--ink-foreground)] leading-none truncate max-w-[65px]">
              Dr. Iyer
            </div>
            <div className="text-[10px] font-mono text-[var(--muted-text)] opacity-70 mb-1.5">
              3h 50m
            </div>
            {/* Bronze Pillar */}
            <motion.div
              animate={{ height: isActive ? 42 : 18 }}
              transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
              className="w-full rounded-t-lg bg-orange-300/40 dark:bg-orange-950/50 flex items-center justify-center text-[10px] font-mono font-bold text-orange-600 dark:text-orange-400"
            >
              #3
            </motion.div>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
