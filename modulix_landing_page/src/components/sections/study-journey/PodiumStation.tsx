import { motion } from "framer-motion"
import { Star, ShieldCheck } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function PodiumStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full flex flex-col items-center justify-center p-2 sm:p-4 select-none">
      <div
        className={`w-full max-w-xs rounded-2xl border p-4 shadow-lg transition-colors relative ${
          isDark
            ? "bg-[#18191D] border-white/10 shadow-[0_12px_32px_rgba(0,0,0,0.5)]"
            : "bg-[#FCFAF5] border-[#E8DEC8] shadow-[0_10px_28px_rgba(0,0,0,0.06)]"
        }`}
      >
        {/* Header: Tactile 4-Way Scale Switcher (_TactileScaleSwitcher) + Live Presence */}
        <div className="flex items-center justify-between pb-2.5 mb-2.5 border-b border-black/[0.06] dark:border-white/[0.06]">
          {/* 4 Scales */}
          <div className="flex items-center gap-1 p-0.5 rounded-lg bg-black/5 dark:bg-white/5 border border-black/5 dark:border-white/5 text-[9px] font-mono font-semibold">
            <span className="px-1.5 py-0.5 rounded bg-[var(--accent)] text-white font-bold">
              DAILY
            </span>
            <span className="px-1.5 py-0.5 text-[var(--muted-text)]">WEEKLY</span>
            <span className="px-1.5 py-0.5 text-[var(--muted-text)]">MONTHLY</span>
          </div>

          {/* Presence Beacon (from study_presence_service) */}
          <div className="flex items-center gap-1 text-[10px] font-mono font-bold text-emerald-600 dark:text-emerald-400">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping" />
            <span>142 FOCUSING</span>
          </div>
        </div>

        {/* ── Editorial Top 3 Rising Pedestal Stage (EditorialPodium) ── */}
        <div className="flex items-end justify-center gap-2.5 w-full h-32 pt-2 px-2">
          {/* Rank 2 (Left - Silver #94A3B8) */}
          <div className="flex-1 flex flex-col items-center">
            <div className="w-7 h-7 rounded-full border border-slate-300 dark:border-slate-700 bg-slate-200 dark:bg-slate-800 text-[10px] font-bold font-mono flex items-center justify-center text-slate-700 dark:text-slate-300 mb-1 shadow-xs">
              RP
            </div>
            <div className="text-[10px] font-semibold text-[var(--ink-foreground)] leading-none truncate max-w-[65px]">
              Dr. Patel
            </div>
            <div className="text-[9px] font-mono text-[var(--muted-text)] mb-1">
              4h 15m
            </div>
            {/* Silver Pedestal */}
            <motion.div
              animate={{ height: isActive ? 52 : 24 }}
              transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
              className="w-full rounded-t-lg border border-b-0 border-slate-400/30 bg-gradient-to-t from-slate-400/30 to-slate-300/40 dark:from-slate-800 dark:to-slate-700 flex items-center justify-center text-[10px] font-mono font-bold text-slate-500"
            >
              #2
            </motion.div>
          </div>

          {/* Rank 1 (Center - Gold #F59E0B) */}
          <div className="flex-1 flex flex-col items-center relative">
            {/* Holographic Aura Ring */}
            {isActive && (
              <motion.div
                animate={{ scale: [1, 1.25, 1], opacity: [0.7, 0.2, 0.7] }}
                transition={{ duration: 1.8, repeat: Infinity, ease: "easeInOut" }}
                className="absolute -top-1 w-9 h-9 rounded-full border border-amber-400 pointer-events-none"
              />
            )}

            {/* Gold Ascending Avatar */}
            <motion.div
              animate={{
                y: isActive ? [8, -3, 0] : 8,
                scale: isActive ? 1.1 : 1,
              }}
              transition={{ duration: 0.5, ease: "easeOut" }}
              className="w-8 h-8 rounded-full border-2 border-amber-400 bg-amber-500 text-amber-950 font-bold text-xs flex items-center justify-center shadow-md mb-1 z-10"
            >
              <Star size={13} className="fill-amber-950 text-amber-950" />
            </motion.div>

            <div className="text-[11px] font-bold text-[var(--accent)] leading-none truncate max-w-[70px]">
              Dr. You
            </div>
            <div className="text-[9px] font-mono text-[var(--muted-text)] mb-1">
              5h 40m
            </div>

            {/* Gold Rising Pedestal with Metallic Sheen */}
            <motion.div
              animate={{ height: isActive ? 80 : 36 }}
              transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
              className="w-full rounded-t-lg border border-b-0 border-amber-400 bg-gradient-to-t from-amber-600 via-amber-500 to-amber-300 shadow-md relative overflow-hidden flex items-center justify-center text-[11px] font-mono font-extrabold text-amber-950"
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

          {/* Rank 3 (Right - Bronze #EA580C) */}
          <div className="flex-1 flex flex-col items-center">
            <div className="w-7 h-7 rounded-full border border-amber-900/30 bg-amber-100 dark:bg-amber-950/40 text-[10px] font-bold font-mono flex items-center justify-center text-amber-800 dark:text-amber-400 mb-1 shadow-xs">
              KI
            </div>
            <div className="text-[10px] font-semibold text-[var(--ink-foreground)] leading-none truncate max-w-[65px]">
              Dr. Iyer
            </div>
            <div className="text-[9px] font-mono text-[var(--muted-text)] mb-1">
              3h 50m
            </div>
            {/* Bronze Pedestal */}
            <motion.div
              animate={{ height: isActive ? 40 : 18 }}
              transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
              className="w-full rounded-t-lg border border-b-0 border-orange-500/30 bg-gradient-to-t from-orange-400/30 to-orange-300/40 dark:from-orange-950 dark:to-orange-900 flex items-center justify-center text-[10px] font-mono font-bold text-orange-600 dark:text-orange-400"
            >
              #3
            </motion.div>
          </div>
        </div>

        {/* ── Career Level Progress Ladder (models/user_rank.dart) ── */}
        <div className="mt-3 pt-2.5 border-t border-black/[0.05] dark:border-white/[0.05]">
          <div className="flex items-center justify-between text-[10px] font-mono mb-1">
            <span className="font-semibold text-[var(--ink-foreground)] flex items-center gap-1">
              <ShieldCheck size={12} className="text-[var(--accent)]" />
              Junior Resident (Lvl 3)
            </span>
            <span className="text-[var(--accent)] font-bold">
              142 / 150 hrs
            </span>
          </div>

          {/* Level Progress Bar */}
          <div className="w-full h-1.5 rounded-full bg-black/10 dark:bg-white/10 overflow-hidden mb-1">
            <motion.div
              className="h-full rounded-full bg-[var(--accent)]"
              animate={{ width: isActive ? "94%" : "60%" }}
              transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            />
          </div>

          <div className="text-[9px] font-mono text-[var(--muted-text)] flex justify-between">
            <span>Next: Senior Resident (ER Command)</span>
            <span>+8h to promotion</span>
          </div>
        </div>
      </div>
    </div>
  )
}
