import { useState } from "react"
import { motion } from "framer-motion"
import { useTheme } from "../../../lib/theme"

export function SyllabusMotionPreview() {
  const { isDark } = useTheme()
  const [activeEdition, setActiveEdition] = useState<"ed8" | "ed65">("ed8")

  const subjects = [
    { name: "Pathology", count: "84 Units", prof: "2nd Prof" },
    { name: "Pharmacology", count: "62 Units", prof: "2nd Prof" },
    { name: "Medicine", count: "128 Units", prof: "Final Prof" },
    { name: "Surgery", count: "96 Units", prof: "Final Prof" },
  ]

  return (
    <div className="w-full max-w-md mx-auto py-3 select-none space-y-3">
      {/* Interactive Edition Folio Spine Switcher */}
      <div className="flex items-center justify-center gap-2 p-1 rounded-xl bg-[var(--surface-subtle)] border border-[var(--border-subtle)]">
        <button
          onClick={() => setActiveEdition("ed8")}
          className={`flex-1 py-1.5 px-3 rounded-lg text-xs font-semibold transition-all ${
            activeEdition === "ed8"
              ? "bg-[var(--card-bg)] text-[var(--ink-foreground)] shadow-sm"
              : "text-[var(--muted-text)] hover:text-[var(--ink-foreground)]"
          }`}
        >
          Edition 8.0 · Latest
        </button>
        <button
          onClick={() => setActiveEdition("ed65")}
          className={`flex-1 py-1.5 px-3 rounded-lg text-xs font-semibold transition-all ${
            activeEdition === "ed65"
              ? "bg-[var(--card-bg)] text-[var(--ink-foreground)] shadow-sm"
              : "text-[var(--muted-text)] hover:text-[var(--ink-foreground)]"
          }`}
        >
          Edition 6.5 · Classic
        </button>
      </div>

      {/* 3D Physical Spine Stacking */}
      <div className="space-y-2">
        {subjects.map((sub, idx) => (
          <motion.div
            key={sub.name}
            initial={{ opacity: 0, x: -8 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.3, delay: idx * 0.05 }}
            className={`p-2.5 rounded-lg border flex items-center justify-between text-xs transition-colors ${
              isDark
                ? "bg-[#18181B] border-white/10"
                : "bg-white border-black/[0.08] shadow-sm"
            }`}
          >
            <div className="flex items-center gap-2.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[var(--accent)]" />
              <span className="font-semibold text-[var(--ink-foreground)]">{sub.name}</span>
              <span className="text-[11px] text-[var(--muted-text)] font-mono">({sub.prof})</span>
            </div>
            <span className="font-mono text-[11px] text-[var(--muted-text)]">{sub.count}</span>
          </motion.div>
        ))}
      </div>
    </div>
  )
}
