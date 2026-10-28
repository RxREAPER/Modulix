import { motion } from "framer-motion"
import { Check } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TopicStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full flex items-center justify-center select-none">
      {/* ── Minimalist Subject Card (Zero Tags, Zero Badges) ── */}
      <motion.div
        layout
        className={`w-full max-w-sm rounded-2xl border p-6 transition-colors relative overflow-hidden ${
          isDark
            ? "bg-[#16171B] border-white/8 shadow-[0_12px_36px_rgba(0,0,0,0.4)]"
            : "bg-[#FCFAF5] border-[#EAE3D2] shadow-[0_8px_24px_rgba(0,0,0,0.04)]"
        }`}
      >
        {/* Subject Header */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            {/* Subject Sketch Icon Bubble */}
            <div className="w-9 h-9 rounded-xl bg-[#DC2626]/10 flex items-center justify-center flex-shrink-0">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#DC2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="3" />
                <path d="M12 2v3m0 14v3M2 12h3m14 0h3" />
                <path d="M4.93 4.93l2.12 2.12m9.9 9.9l2.12 2.12M4.93 19.07l2.12-2.12m9.9-9.9l2.12-2.12" />
              </svg>
            </div>

            <div>
              <h4 className="font-editorial text-base sm:text-lg font-bold text-[var(--ink-foreground)] leading-none">
                Pathology
              </h4>
              <span className="font-mono text-xs text-[var(--muted-text)] opacity-70">
                124 videos · 48.5 hours
              </span>
            </div>
          </div>

          {/* Minimal Percentage Text (No Badge) */}
          <span className="font-mono text-sm font-bold text-[var(--ink-foreground)] opacity-90">
            42%
          </span>
        </div>

        {/* Minimal Progress Line */}
        <div className="w-full h-1.5 rounded-full bg-black/5 dark:bg-white/10 overflow-hidden mb-4">
          <motion.div
            className="h-full rounded-full bg-[#DC2626]"
            animate={{ width: isActive ? "42%" : "15%" }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          />
        </div>

        {/* Active Unit Row */}
        <div className="flex items-center justify-between pt-3 border-t border-black/5 dark:border-white/5 text-xs">
          <div className="flex items-center gap-2">
            <span className="font-mono text-[11px] text-[var(--accent)] font-semibold">04</span>
            <span className="text-[var(--ink-foreground)] font-medium">Cell Injury & Necrosis</span>
          </div>
          <motion.div
            animate={{ scale: isActive ? [0.8, 1.15, 1] : 0.8 }}
            transition={{ duration: 0.3 }}
          >
            <Check size={14} className="text-[var(--accent)] stroke-[2.5]" />
          </motion.div>
        </div>
      </motion.div>
    </div>
  )
}
