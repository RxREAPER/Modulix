import { motion } from "framer-motion"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function PodiumStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full h-full flex flex-col items-center justify-center p-5 select-none relative">
      <div className="text-center mb-2">
        <span className="text-[10px] font-mono tracking-widest text-[var(--accent)] uppercase font-semibold">
          RANKING SURGE
        </span>
        <div className="font-editorial text-lg font-bold text-[var(--ink-foreground)]">
          {isActive ? "Dr. You · Rank #1 Gold" : "Calculating Rank..."}
        </div>
      </div>

      {/* ── Top 3 Rising Pedestal Stage ── */}
      <div className="flex items-end justify-center gap-2.5 w-full max-w-[240px] h-32 pt-2">
        {/* Rank 2 (Silver) */}
        <div className="flex-1 flex flex-col items-center">
          <div className="text-[10px] font-mono text-[var(--muted-text)] mb-1">#2</div>
          <div
            className={`w-full h-14 rounded-t-lg border border-b-0 ${
              isDark ? "bg-[#1E293B] border-slate-700" : "bg-[#CBD5E1] border-slate-300"
            }`}
          />
        </div>

        {/* Rank 1 (Gold - Surges up!) */}
        <div className="flex-1 flex flex-col items-center relative">
          {/* Animated Ascending Avatar */}
          <motion.div
            animate={{
              y: isActive ? [12, -4, 0] : 12,
              scale: isActive ? 1.15 : 1,
            }}
            transition={{ duration: 0.5, ease: "easeOut" }}
            className="w-8 h-8 rounded-full border-2 border-amber-400 bg-amber-500 text-white font-bold text-xs flex items-center justify-center shadow-md mb-1 z-10"
          >
            ★
          </motion.div>

          {/* Gold Rising Pillar */}
          <motion.div
            animate={{
              height: isActive ? 80 : 35,
            }}
            transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
            className="w-full rounded-t-lg border border-b-0 bg-gradient-to-t from-amber-600 via-amber-500 to-amber-300 border-amber-400 shadow-lg relative overflow-hidden"
          >
            {/* Metallic Sheen Sweep */}
            {isActive && (
              <motion.div
                initial={{ left: "-100%" }}
                animate={{ left: "200%" }}
                transition={{ duration: 0.9, repeat: Infinity, repeatDelay: 1.5 }}
                className="absolute inset-y-0 w-1/2 bg-white/40 skew-x-12"
              />
            )}
            <div className="text-center pt-2 text-[11px] font-bold text-amber-950 font-mono">
              #1
            </div>
          </motion.div>
        </div>

        {/* Rank 3 (Bronze) */}
        <div className="flex-1 flex flex-col items-center">
          <div className="text-[10px] font-mono text-[var(--muted-text)] mb-1">#3</div>
          <div
            className={`w-full h-10 rounded-t-lg border border-b-0 ${
              isDark ? "bg-[#29170E] border-amber-950" : "bg-[#D4B996] border-[#BFA27E]"
            }`}
          />
        </div>
      </div>

      <div className="mt-3 text-[10px] font-mono tracking-widest text-[var(--muted-text)] uppercase">
        Verified Daily Leaderboard
      </div>
    </div>
  )
}
