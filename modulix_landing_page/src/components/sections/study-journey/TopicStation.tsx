import { motion } from "framer-motion"
import { BookOpen } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TopicStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full flex items-center justify-center select-none">
      {/* ── Minimalist Curriculum Card (Zero Clutter, Pure Typography) ── */}
      <motion.div
        layout
        className={`w-full max-w-md rounded-2xl border p-6 sm:p-7 transition-colors relative overflow-hidden ${
          isDark
            ? "bg-[#16171B] border-white/[0.08] shadow-[0_12px_36px_rgba(0,0,0,0.4)]"
            : "bg-[#FCFAF5] border-[#EAE3D2] shadow-[0_8px_24px_rgba(0,0,0,0.04)]"
        }`}
      >
        {/* Clean Subject Header */}
        <div className="flex items-center justify-between mb-5">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-[#DC2626]/10 flex items-center justify-center text-[#DC2626]">
              <BookOpen size={18} strokeWidth={2.2} />
            </div>
            <div>
              <h4 className="font-editorial text-lg sm:text-xl font-bold text-[var(--ink-foreground)] leading-tight">
                Pathology
              </h4>
              <span className="font-mono text-xs text-[var(--muted-text)] opacity-70">
                19 MBBS Subjects
              </span>
            </div>
          </div>

          <span className="font-mono text-base font-bold text-[var(--accent)]">
            42%
          </span>
        </div>

        {/* Minimal Progress Line */}
        <div className="w-full h-1.5 rounded-full bg-black/5 dark:bg-white/10 overflow-hidden mb-5">
          <motion.div
            className="h-full rounded-full bg-[#DC2626]"
            animate={{ width: isActive ? "42%" : "15%" }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          />
        </div>

        {/* Single Quiet Unit Line */}
        <div className="flex items-center justify-between text-xs font-mono text-[var(--muted-text)] pt-1">
          <div className="flex items-center gap-2">
            <span className="text-[var(--accent)] font-semibold">04</span>
            <span className="text-[var(--ink-foreground)] opacity-90">Cell Injury & Necrosis</span>
          </div>
          <span className="text-[var(--accent)] text-[11px] font-semibold opacity-90">In Progress</span>
        </div>
      </motion.div>
    </div>
  )
}
