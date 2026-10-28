import { useTheme } from "../../../lib/theme"

export function TraditionalNotepadHeader() {
  const { isDark } = useTheme()

  return (
    <div className="relative w-full -mt-6 sm:-mt-8 -mx-6 sm:-mx-8 mb-5 select-none">
      {/* ── TOP BINDING STRIP (Classic cloth/leatherette tape) ── */}
      <div
        className={`w-[calc(100%+3rem)] sm:w-[calc(100%+4rem)] h-10 rounded-t-2xl px-6 flex items-center justify-between border-b ${
          isDark
            ? "bg-[#1C1D21] border-[#2A2B30] text-slate-400"
            : "bg-[#2A2D34] border-[#1F2228] text-amber-100/80"
        } shadow-inner`}
      >
        {/* Left Brass / Steel Staple */}
        <div className="w-5 h-2 rounded-sm bg-gradient-to-r from-amber-600 via-amber-300 to-amber-700 dark:from-slate-500 dark:via-slate-300 dark:to-slate-600 shadow-sm" />

        {/* Embossed Classical Foil Stamp */}
        <span className="font-mono text-[10px] tracking-[0.25em] uppercase opacity-75 font-semibold">
          MODULIX · CLINICAL MEMO PAD
        </span>

        {/* Right Brass / Steel Staple */}
        <div className="w-5 h-2 rounded-sm bg-gradient-to-r from-amber-600 via-amber-300 to-amber-700 dark:from-slate-500 dark:via-slate-300 dark:to-slate-600 shadow-sm" />
      </div>

      {/* ── PERFORATED TEAR LINE ── */}
      <div className="relative w-[calc(100%+3rem)] sm:w-[calc(100%+4rem)] h-3 flex items-center justify-between px-2 overflow-hidden">
        {/* Left notch cut */}
        <div className="w-2.5 h-2.5 rounded-full -ml-1.5 bg-[var(--scaffold-bg)]" />
        {/* Dotted perforation */}
        <div className="flex-1 border-b-[1.5px] border-dashed border-black/[0.15] dark:border-white/[0.15] mx-2" />
        {/* Right notch cut */}
        <div className="w-2.5 h-2.5 rounded-full -mr-1.5 bg-[var(--scaffold-bg)]" />
      </div>
    </div>
  )
}
