import { useTheme } from "../../lib/theme"

export function FilmicBackground() {
  const { isDark } = useTheme()

  return (
    <div
      className="fixed inset-0 pointer-events-none z-0 overflow-hidden"
      aria-hidden="true"
    >
      {/* Top 35% Atmospheric Filmic Wash with Smooth Horizon Dissolve */}
      <div
        className="absolute top-0 left-0 right-0 h-[38vh] opacity-80 transition-opacity duration-700"
        style={{
          background: isDark
            ? `radial-gradient(120% 100% at 50% 0%, rgba(10, 132, 255, 0.12) 0%, rgba(18, 18, 18, 0.4) 60%, transparent 100%)`
            : `radial-gradient(120% 100% at 50% 0%, rgba(0, 122, 255, 0.08) 0%, rgba(241, 245, 249, 0.5) 60%, transparent 100%)`,
        }}
      />

      {/* Horizon Dissolve Gradient: Fades perfectly into scaffold background strictly by 35-40% */}
      <div
        className="absolute top-0 left-0 right-0 h-[45vh]"
        style={{
          background: `linear-gradient(to bottom, transparent 60%, var(--scaffold-bg) 100%)`,
        }}
      />

      {/* 35mm Analog Film Grain Texture Simulation */}
      <div
        className="absolute inset-0 opacity-[0.035] mix-blend-overlay pointer-events-none"
        style={{
          backgroundImage: `radial-gradient(#000 1px, transparent 1px)`,
          backgroundSize: `4px 4px`,
        }}
      />
    </div>
  )
}
