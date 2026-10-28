import { useTheme } from "../../../lib/theme"

export function ClipboardClip() {
  const { isDark } = useTheme()

  return (
    <div className="absolute -top-7 left-1/2 -translate-x-1/2 z-20 pointer-events-none select-none flex flex-col items-center">
      {/* Upper Bed-Rail Hanging Loop */}
      <div
        className={`w-12 h-6 rounded-t-full border-t-[3.5px] border-x-[3.5px] transition-colors ${
          isDark
            ? "border-slate-500 bg-transparent shadow-[0_2px_4px_rgba(0,0,0,0.5)]"
            : "border-slate-400 bg-transparent shadow-[0_2px_4px_rgba(0,0,0,0.15)]"
        }`}
      />

      {/* Main Titanium / Steel Clamp Bar */}
      <div className="relative -mt-1">
        <svg
          width="170"
          height="42"
          viewBox="0 0 170 42"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="drop-shadow-[0_4px_8px_rgba(0,0,0,0.28)]"
        >
          <defs>
            <linearGradient id="clipMetal" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor={isDark ? "#334155" : "#94A3B8"} />
              <stop offset="18%" stopColor={isDark ? "#64748B" : "#E2E8F0"} />
              <stop offset="45%" stopColor={isDark ? "#475569" : "#CBD5E1"} />
              <stop offset="50%" stopColor={isDark ? "#94A3B8" : "#FFFFFF"} />
              <stop offset="55%" stopColor={isDark ? "#475569" : "#CBD5E1"} />
              <stop offset="82%" stopColor={isDark ? "#64748B" : "#E2E8F0"} />
              <stop offset="100%" stopColor={isDark ? "#1E293B" : "#64748B"} />
            </linearGradient>

            <linearGradient id="clipBevel" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor={isDark ? "#94A3B8" : "#FFFFFF"} stopOpacity="0.8" />
              <stop offset="100%" stopColor={isDark ? "#0F172A" : "#475569"} stopOpacity="0.9" />
            </linearGradient>

            <radialGradient id="boltHead" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor={isDark ? "#CBD5E1" : "#FFFFFF"} />
              <stop offset="70%" stopColor={isDark ? "#475569" : "#64748B"} />
              <stop offset="100%" stopColor={isDark ? "#0F172A" : "#334155"} />
            </radialGradient>
          </defs>

          {/* Main clamp plate with rounded corners */}
          <rect
            x="4"
            y="2"
            width="162"
            height="32"
            rx="5"
            fill="url(#clipMetal)"
            stroke="url(#clipBevel)"
            strokeWidth="0.8"
          />

          {/* Center tension spring arch */}
          <rect
            x="36"
            y="7"
            width="98"
            height="18"
            rx="3"
            fill={isDark ? "#1E293B" : "#F1F5F9"}
            fillOpacity={isDark ? "0.6" : "0.75"}
            stroke={isDark ? "#475569" : "#94A3B8"}
            strokeWidth="0.6"
          />

          {/* Embossed grip ribs */}
          <line x1="56" y1="12" x2="56" y2="20" stroke={isDark ? "#94A3B8" : "#64748B"} strokeWidth="1.2" strokeLinecap="round" opacity="0.65" />
          <line x1="72" y1="12" x2="72" y2="20" stroke={isDark ? "#94A3B8" : "#64748B"} strokeWidth="1.2" strokeLinecap="round" opacity="0.65" />
          <line x1="85" y1="11" x2="85" y2="21" stroke={isDark ? "#CBD5E1" : "#475569"} strokeWidth="1.6" strokeLinecap="round" opacity="0.85" />
          <line x1="98" y1="12" x2="98" y2="20" stroke={isDark ? "#94A3B8" : "#64748B"} strokeWidth="1.2" strokeLinecap="round" opacity="0.65" />
          <line x1="114" y1="12" x2="114" y2="20" stroke={isDark ? "#94A3B8" : "#64748B"} strokeWidth="1.2" strokeLinecap="round" opacity="0.65" />

          {/* Left rivet bolt */}
          <circle cx="18" cy="18" r="4.5" fill="url(#boltHead)" />
          <line x1="15.5" y1="18" x2="20.5" y2="18" stroke={isDark ? "#0F172A" : "#334155"} strokeWidth="0.8" />

          {/* Right rivet bolt */}
          <circle cx="152" cy="18" r="4.5" fill="url(#boltHead)" />
          <line x1="149.5" y1="18" x2="154.5" y2="18" stroke={isDark ? "#0F172A" : "#334155"} strokeWidth="0.8" />
        </svg>

        {/* Soft realistic drop shadow onto the paper */}
        <div className="w-36 h-2 mx-auto -mt-1 bg-black/25 dark:bg-black/50 blur-[3px] rounded-full pointer-events-none" />
      </div>
    </div>
  )
}
