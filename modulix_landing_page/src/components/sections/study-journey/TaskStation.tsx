import { motion } from "framer-motion"
import { useTheme } from "../../../lib/theme"

interface StationProps {
  isActive: boolean
}

export function TaskStation({ isActive }: StationProps) {
  const { isDark } = useTheme()

  return (
    <div className="w-full h-full flex flex-col items-center justify-center p-5 select-none relative overflow-hidden">
      {/* Physician Prescription / Memo Slip */}
      <motion.div
        animate={{
          scale: isActive ? 1.02 : 1,
          borderColor: isActive ? "var(--accent)" : "var(--border-subtle)",
        }}
        transition={{ duration: 0.3 }}
        className={`w-full max-w-xs rounded-xl p-4 border relative ${
          isDark
            ? "bg-[#18191D] border-white/10 shadow-[0_8px_24px_rgba(0,0,0,0.5)]"
            : "bg-[#FCFAF5] border-[#E8DEC8] shadow-[0_6px_20px_rgba(0,0,0,0.06)]"
        }`}
      >
        {/* Prescription Pad Header */}
        <div className="flex items-center justify-between pb-2 mb-3 border-b border-black/[0.06] dark:border-white/[0.06] text-[10px] font-mono tracking-wider opacity-60">
          <span>DAILY DESK // PROTOCOL</span>
          <span>RX-01</span>
        </div>

        {/* Animated Task Row with Inking Pen */}
        <div className="relative py-2 flex items-center gap-3">
          {/* Animated Check Circle */}
          <motion.div
            animate={{
              borderColor: isActive ? "var(--accent)" : "var(--muted-text)",
              backgroundColor: isActive ? "var(--accent)" : "transparent",
            }}
            transition={{ delay: 0.3, duration: 0.2 }}
            className="w-5 h-5 rounded-full border-[1.5px] flex items-center justify-center flex-shrink-0"
          >
            <svg width="10" height="8" viewBox="0 0 10 8" fill="none">
              <motion.path
                d="M1 4L3.8 6.8L9 1.2"
                stroke="#FFFFFF"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
                animate={{ pathLength: isActive ? 1 : 0 }}
                transition={{ delay: 0.35, duration: 0.25 }}
              />
            </svg>
          </motion.div>

          {/* Task Title with Drawing Ink Effect */}
          <div className="relative flex-1 text-xs sm:text-sm font-semibold tracking-tight text-[var(--ink-foreground)]">
            <span>Pathology · Robbins Neoplasia</span>

            {/* Drawing Fountain Pen Icon */}
            {isActive && (
              <motion.div
                initial={{ left: 0, opacity: 1 }}
                animate={{ left: "100%", opacity: [1, 1, 0] }}
                transition={{ duration: 0.8, ease: "easeInOut" }}
                className="absolute -top-3 w-4 h-4 pointer-events-none"
              >
                <svg viewBox="0 0 24 24" fill="none" className="rotate-45">
                  <path
                    d="M12 19l7-7 3 3-7 7-3-3zM18 13l-1.5-1.5M2 22l5-1 12-12-4-4L3 17l-1 5z"
                    fill="var(--accent)"
                  />
                </svg>
              </motion.div>
            )}
          </div>
        </div>

        {/* Animated Ink Strike */}
        <motion.div
          className="h-[1.5px] bg-[var(--accent)] origin-left mt-1"
          animate={{ scaleX: isActive ? 1 : 0 }}
          transition={{ delay: 0.45, duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
          style={{ width: "85%", marginLeft: "28px" }}
        />
      </motion.div>

      {/* Discharging Energy Pulse Ring */}
      {isActive && (
        <motion.div
          initial={{ scale: 0.8, opacity: 0.8 }}
          animate={{ scale: 1.6, opacity: 0 }}
          transition={{ duration: 1.2, repeat: Infinity, ease: "easeOut" }}
          className="absolute w-24 h-24 rounded-full border border-[var(--accent)] pointer-events-none"
        />
      )}
    </div>
  )
}
