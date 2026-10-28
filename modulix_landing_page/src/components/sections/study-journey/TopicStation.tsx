import { motion } from "framer-motion"
import { Sparkles, CheckCircle2 } from "lucide-react"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TopicStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full flex flex-col items-center justify-center p-2 sm:p-4 select-none">
      {/* ── Realistic SquareSubjectCard from widgets/curriculum/square_subject_card.dart ── */}
      <motion.div
        animate={{
          scale: isActive ? 1.02 : 1,
          y: isActive ? -2 : 0,
        }}
        transition={{ duration: 0.35, ease: "easeOut" }}
        className={`w-full max-w-xs rounded-2xl border p-4 shadow-lg transition-colors relative ${
          isDark
            ? "bg-[#18191D] border-white/10 shadow-[0_12px_32px_rgba(0,0,0,0.5)]"
            : "bg-[#FCFAF5] border-[#E8DEC8] shadow-[0_10px_28px_rgba(0,0,0,0.06)]"
        }`}
      >
        {/* Top Row: Year Pill & Completion Chip */}
        <div className="flex items-center justify-between mb-3">
          {/* Year Badge */}
          <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-[#DC2626]/10 border border-[#DC2626]/30 text-[#DC2626] text-[10px] font-mono font-bold tracking-wide">
            <span>2ND YEAR</span>
          </div>

          {/* Completion Badge (42%) */}
          <div
            className={`px-2 py-0.5 rounded-md border text-[11px] font-mono font-bold ${
              isDark
                ? "bg-white/5 border-white/10 text-[var(--ink-foreground)]"
                : "bg-black/5 border-black/10 text-[var(--ink-foreground)]"
            }`}
          >
            42%
          </div>
        </div>

        {/* Subject Header: Icon Bubble + Title */}
        <div className="flex items-center gap-3 mb-2">
          {/* Subject Sketch Icon Bubble */}
          <div className="w-10 h-10 rounded-xl bg-[#DC2626]/12 border border-[#DC2626]/30 flex items-center justify-center flex-shrink-0">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#DC2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="3" />
              <path d="M12 2v3m0 14v3M2 12h3m14 0h3" />
              <path d="M4.93 4.93l2.12 2.12m9.9 9.9l2.12 2.12M4.93 19.07l2.12-2.12m9.9-9.9l2.12-2.12" />
            </svg>
          </div>

          <div>
            <h4 className="font-editorial text-base sm:text-lg font-bold text-[var(--ink-foreground)] tracking-tight leading-none">
              Pathology
            </h4>
            <span className="text-[11px] font-mono text-[var(--muted-text)]">
              124 vids · 48.5 hrs
            </span>
          </div>
        </div>

        {/* Sketch Progress Bar */}
        <div className="w-full h-2 rounded-full bg-black/5 dark:bg-white/10 overflow-hidden mb-3 border border-black/5 dark:border-white/5">
          <motion.div
            className="h-full rounded-full bg-[#DC2626]"
            animate={{
              width: isActive ? "42%" : "15%",
            }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          />
        </div>

        {/* Active Module Unit Selector (ModuleTasksScreen unit) */}
        <motion.div
          animate={{
            borderColor: isActive ? "var(--accent)" : "rgba(0,0,0,0.08)",
            backgroundColor: isActive
              ? isDark ? "rgba(16, 185, 129, 0.08)" : "rgba(16, 185, 129, 0.06)"
              : "transparent",
          }}
          transition={{ duration: 0.3 }}
          className="rounded-xl border p-2.5 flex items-center justify-between"
        >
          <div className="flex items-center gap-2 overflow-hidden">
            <div className="w-5 h-5 rounded-md bg-[var(--accent)]/15 text-[var(--accent)] flex items-center justify-center text-[10px] font-mono font-bold">
              04
            </div>
            <div className="truncate">
              <div className="text-[11px] font-medium text-[var(--ink-foreground)] truncate">
                Cell Injury & Necrosis
              </div>
              <div className="text-[9px] font-mono text-[var(--muted-text)]">
                Video · 35m · Edition 8.0
              </div>
            </div>
          </div>

          <motion.div
            animate={{ scale: isActive ? [0.8, 1.2, 1] : 0.8 }}
            transition={{ duration: 0.3, delay: 0.3 }}
          >
            <CheckCircle2 size={15} className="text-[var(--accent)] flex-shrink-0" />
          </motion.div>
        </motion.div>

        {/* Lock Tag Footer */}
        <div className="mt-2.5 flex items-center justify-between text-[10px] font-mono text-[var(--muted-text)]">
          <div className="flex items-center gap-1 text-[var(--accent)] font-semibold">
            <Sparkles size={11} />
            <span>SYLLABUS LOCKED</span>
          </div>
          <span>ROBBINS 10TH ED</span>
        </div>
      </motion.div>
    </div>
  )
}
