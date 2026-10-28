import { motion } from "framer-motion"
import { useTheme } from "../../../lib/theme"

export function AnalyticsMotionPreview() {
  const { isDark } = useTheme()

  // 24 hours of chronotype activity density
  const hourlyIntensity = [
    0.1, 0.05, 0.0, 0.0, 0.0, 0.15, 0.45, 0.7, 0.85, 0.9, 0.75, 0.6,
    0.4, 0.35, 0.5, 0.65, 0.8, 0.95, 0.85, 0.9, 0.65, 0.4, 0.25, 0.15,
  ]

  return (
    <div className="w-full max-w-md mx-auto py-3 select-none space-y-3">
      {/* 24-Hour Chronotype Heat Strip */}
      <div className="p-3.5 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)]">
        <div className="flex items-center justify-between text-[11px] font-mono text-[var(--muted-text)] mb-2">
          <span>00:00</span>
          <span>06:00</span>
          <span>12:00</span>
          <span>18:00</span>
          <span>24:00</span>
        </div>

        {/* Dynamic Vertical Wave Bars */}
        <div className="h-14 flex items-end gap-[3px] sm:gap-[5px]">
          {hourlyIntensity.map((val, idx) => (
            <motion.div
              key={idx}
              className="flex-1 rounded-sm origin-bottom"
              style={{
                backgroundColor:
                  val > 0.7
                    ? "var(--accent)"
                    : isDark
                    ? `rgba(255,255,255,${val * 0.5 + 0.1})`
                    : `rgba(15,23,42,${val * 0.5 + 0.08})`,
              }}
              initial={{ height: "8%" }}
              animate={{
                height: `${Math.max(val * 100, 8)}%`,
              }}
              transition={{
                duration: 0.8,
                delay: idx * 0.02,
                ease: [0.16, 1, 0.3, 1],
              }}
            />
          ))}
        </div>
      </div>

      <div className="flex items-center justify-between text-xs font-mono px-1">
        <span className="text-[var(--muted-text)]">24h Study Distribution</span>
        <span className="text-[var(--ink-foreground)] font-semibold">Peak: 18:00 - 21:00</span>
      </div>
    </div>
  )
}
