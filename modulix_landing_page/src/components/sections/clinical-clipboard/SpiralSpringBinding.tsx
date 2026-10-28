import { useTheme } from "../../../lib/theme"

export function SpiralSpringBinding() {
  const { isDark } = useTheme()

  // 14 realistic coiled spring rings across the top of the notepad
  const coils = Array.from({ length: 14 })

  return (
    <div className="relative w-full -mt-7 sm:-mt-9 mb-4 select-none pointer-events-none">
      {/* ── Realistic Coiled Spiral Spring Loops ── */}
      <div className="relative w-full flex items-center justify-between px-3 sm:px-6 z-20">
        {coils.map((_, i) => (
          <div key={i} className="relative flex flex-col items-center">
            {/* The 3D Metallic Wire Loop arching over the top */}
            <svg
              width="16"
              height="36"
              viewBox="0 0 16 36"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              className="drop-shadow-[0_4px_5px_rgba(0,0,0,0.32)] -mb-3 z-20"
            >
              <defs>
                <linearGradient id={`wireGradient-${i}`} x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor={isDark ? "#475569" : "#94A3B8"} />
                  <stop offset="30%" stopColor={isDark ? "#94A3B8" : "#F1F5F9"} />
                  <stop offset="50%" stopColor={isDark ? "#FFFFFF" : "#FFFFFF"} />
                  <stop offset="70%" stopColor={isDark ? "#94A3B8" : "#E2E8F0"} />
                  <stop offset="100%" stopColor={isDark ? "#1E293B" : "#64748B"} />
                </linearGradient>
              </defs>

              {/* Curved 3D Wire Spring */}
              <path
                d="M4 2 C4 0, 12 0, 12 2 C12 8, 12 28, 12 32 C12 34, 4 34, 4 32 C4 28, 4 8, 4 2 Z"
                fill={`url(#wireGradient-${i})`}
              />
              {/* Specular Highlight along wire edge */}
              <path
                d="M6 3 L6 31"
                stroke="#FFFFFF"
                strokeWidth="0.9"
                strokeLinecap="round"
                opacity={isDark ? "0.6" : "0.85"}
              />
            </svg>

            {/* Punched Paper Hole in the sheet underneath the coil */}
            <div
              className={`w-3.5 h-4 rounded-full border shadow-inner z-10 transition-colors ${
                isDark
                  ? "bg-[#090A0C] border-black/60 shadow-[inset_0_2px_4px_rgba(0,0,0,0.9)]"
                  : "bg-[#D8D0C3] border-[#C8BEAE] shadow-[inset_0_2px_4px_rgba(0,0,0,0.3)]"
              }`}
            />
          </div>
        ))}
      </div>

      {/* ── Perforated Tear Line (Dotted Punch Holes where page can be torn off) ── */}
      <div className="relative w-full mt-2.5 px-2 flex items-center justify-between overflow-hidden z-10">
        {/* Left tear notch */}
        <div className="w-2.5 h-2.5 rounded-full -ml-1.5 bg-[var(--scaffold-bg)]" />
        {/* Fine perforated dotted tear border */}
        <div className="flex-1 border-b-[1.5px] border-dashed border-black/25 dark:border-white/20 mx-1.5" />
        {/* Right tear notch */}
        <div className="w-2.5 h-2.5 rounded-full -mr-1.5 bg-[var(--scaffold-bg)]" />
      </div>
    </div>
  )
}
