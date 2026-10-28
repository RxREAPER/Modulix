import { motion } from "framer-motion"
import { Microscope, Check } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TopicStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full flex items-center justify-center select-none">
      {/* ── Spacious MBBS Curriculum Card (Zero Cramped UI) ── */}
      <motion.div
        layout
        className={`w-full max-w-md rounded-2xl border p-6 sm:p-7 transition-colors relative overflow-hidden ${
          isDark
            ? "bg-[#16171B] border-white/8 shadow-[0_12px_36px_rgba(0,0,0,0.4)]"
            : "bg-[#FCFAF5] border-[#EAE3D2] shadow-[0_8px_24px_rgba(0,0,0,0.04)]"
        }`}
      >
        {/* Top Header: Subject Icon & Title */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-[#DC2626]/10 flex items-center justify-center flex-shrink-0 text-[#DC2626]">
              <Microscope size={20} strokeWidth={2.2} />
            </div>
            <div>
              <h4 className="font-editorial text-lg font-bold text-[var(--ink-foreground)] leading-tight">
                Pathology
              </h4>
              <span className="font-mono text-xs text-[var(--muted-text)] opacity-70">
                2nd Prof MBBS · Robbins 10th Ed.
              </span>
            </div>
          </div>

          <div className="text-right">
            <span className="font-mono text-base font-bold text-[var(--accent)] block leading-none">
              42%
            </span>
            <span className="font-mono text-[10px] text-[var(--muted-text)] opacity-60">
              18/42 units
            </span>
          </div>
        </div>

        {/* Smooth Crimson Progress Bar */}
        <div className="w-full h-2 rounded-full bg-black/5 dark:bg-white/10 overflow-hidden mb-5">
          <motion.div
            className="h-full rounded-full bg-gradient-to-r from-[#DC2626] to-[#EF4444]"
            animate={{ width: isActive ? "42%" : "12%" }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          />
        </div>

        {/* Breathable Syllabus Track (2 Distinct Units with Generous Spacing) */}
        <div className="space-y-2.5">
          {/* Completed Unit */}
          <div className="flex items-center justify-between text-xs py-2 px-3 rounded-lg bg-black/[0.02] dark:bg-white/[0.02]">
            <div className="flex items-center gap-2.5 min-w-0">
              <span className="font-mono text-[11px] text-[var(--muted-text)] opacity-60">03</span>
              <span className="text-[var(--muted-text)] line-through truncate opacity-70">
                Hemodynamics & Shock
              </span>
            </div>
            <div className="flex items-center gap-1 text-[11px] font-mono text-emerald-600 dark:text-emerald-400 flex-shrink-0">
              <Check size={13} className="stroke-[2.5]" />
              <span>Done</span>
            </div>
          </div>

          {/* Active Unit Focus */}
          <div className="flex items-center justify-between text-xs py-2 px-3 rounded-lg bg-[#DC2626]/[0.05] border border-[#DC2626]/20">
            <div className="flex items-center gap-2.5 min-w-0">
              <span className="font-mono text-[11px] text-[#DC2626] font-bold">04</span>
              <span className="text-[var(--ink-foreground)] font-semibold truncate">
                Cell Injury & Necrosis
              </span>
            </div>
            <div className="flex items-center gap-1.5 font-mono text-[10px] text-[#DC2626] font-medium flex-shrink-0">
              <motion.span
                animate={{ scale: [1, 1.3, 1], opacity: [0.7, 1, 0.7] }}
                transition={{ duration: 1.5, repeat: Infinity }}
                className="w-1.5 h-1.5 rounded-full bg-[#DC2626]"
              />
              <span>In Focus</span>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
