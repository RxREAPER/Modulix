import { motion } from "framer-motion"
import { useTheme } from "../../../lib/theme"

export function LeaderboardMotionPreview() {
  const { isDark } = useTheme()

  const podiumData = [
    {
      rank: 2,
      name: "Dr. Patel",
      time: "8h 45m",
      height: 72,
      medal: "Silver",
      gradient: isDark
        ? "linear-gradient(to top, #1E293B 0%, #334155 100%)"
        : "linear-gradient(to top, #CBD5E1 0%, #E2E8F0 100%)",
      ringColor: "#94A3B8",
      delay: 0.15,
    },
    {
      rank: 1,
      name: "Dr. Sharma",
      time: "9h 12m",
      height: 98,
      medal: "Gold",
      gradient: isDark
        ? "linear-gradient(to top, #451A03 0%, #78350F 50%, #B45309 100%)"
        : "linear-gradient(to top, #FDE68A 0%, #F59E0B 100%)",
      ringColor: "#F59E0B",
      delay: 0.05,
    },
    {
      rank: 3,
      name: "Dr. Sen",
      time: "7h 30m",
      height: 56,
      medal: "Bronze",
      gradient: isDark
        ? "linear-gradient(to top, #271406 0%, #451D0B 100%)"
        : "linear-gradient(to top, #E7D5C4 0%, #D4B996 100%)",
      ringColor: "#B45309",
      delay: 0.25,
    },
  ]

  return (
    <div className="w-full max-w-sm mx-auto py-3 select-none flex items-end justify-center gap-3">
      {podiumData.map((item) => (
        <div key={item.rank} className="flex-1 flex flex-col items-center">
          {/* Avatar Ring */}
          <div
            className="w-10 h-10 rounded-full flex items-center justify-center font-editorial font-bold text-sm mb-2 shadow-sm border-[1.5px]"
            style={{
              borderColor: item.ringColor,
              backgroundColor: isDark ? "#121212" : "#FFFFFF",
              color: isDark ? "#FFFFFF" : "#0F172A",
            }}
          >
            {item.name[3]}
          </div>

          <div className="text-center mb-1.5">
            <div className="text-xs font-semibold text-[var(--ink-foreground)] leading-tight">
              {item.name}
            </div>
            <div className="text-[11px] font-mono text-[var(--muted-text)]">
              {item.time}
            </div>
          </div>

          {/* Rising Pedestal Pillar */}
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: item.height, opacity: 1 }}
            transition={{
              duration: 0.7,
              delay: item.delay,
              ease: [0.16, 1, 0.3, 1],
            }}
            style={{
              background: item.gradient,
              borderTop: `2px solid ${item.ringColor}`,
            }}
            className="w-full rounded-t-lg flex flex-col items-center justify-start pt-2 shadow-inner"
          >
            <span className="font-mono text-sm font-bold opacity-80">
              #{item.rank}
            </span>
          </motion.div>
        </div>
      ))}
    </div>
  )
}
