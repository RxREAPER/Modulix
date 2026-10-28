import { useTheme } from "../../lib/theme"

export function FilmicBackground() {
  const { isDark } = useTheme()

  return (
    <div
      className="fixed inset-0 pointer-events-none z-0 overflow-hidden"
      aria-hidden="true"
    >
      {/* 1. Base Ambient Vertical Wash */}
      <div
        className="absolute inset-0 transition-opacity duration-500"
        style={{
          background: isDark
            ? `linear-gradient(to bottom, #07090E 0%, #0B0F19 25%, var(--scaffold-bg) 60%)`
            : `linear-gradient(to bottom, #FFFFFF 0%, #F1F5F9 25%, var(--scaffold-bg) 60%)`,
        }}
      />

      {/* 2. Top Half Atmospheric Radial Orbs (Matching Homescreen FilmicMetalMeshPainter) */}
      <div
        className="absolute top-0 left-0 right-0 h-[65vh] transition-opacity duration-700"
        style={{
          backgroundImage: isDark
            ? `
              radial-gradient(circle 800px at 40% 12%, rgba(30, 64, 175, 0.35) 0%, transparent 70%),
              radial-gradient(circle 750px at 72% 18%, rgba(12, 74, 110, 0.30) 0%, transparent 70%),
              radial-gradient(circle 600px at 20% 25%, rgba(56, 189, 248, 0.15) 0%, transparent 65%)
            `
            : `
              radial-gradient(circle 850px at 38% 12%, rgba(96, 165, 250, 0.28) 0%, transparent 70%),
              radial-gradient(circle 750px at 74% 18%, rgba(186, 230, 253, 0.35) 0%, transparent 70%),
              radial-gradient(circle 600px at 15% 25%, rgba(224, 242, 254, 0.40) 0%, transparent 65%)
            `,
        }}
      />

      {/* 3. Smooth 55%-65% Horizon Dissolve into clean canvas */}
      <div
        className="absolute top-0 left-0 right-0 h-[70vh]"
        style={{
          background: `linear-gradient(to bottom, transparent 35%, var(--scaffold-bg) 65%)`,
        }}
      />

      {/* 4. Analog Film Grain Simulation (Dimmed 24fps cinema cadence feel) */}
      <div
        className="absolute inset-0 opacity-[0.04] mix-blend-overlay pointer-events-none"
        style={{
          backgroundImage: `radial-gradient(#000 1px, transparent 1px)`,
          backgroundSize: `4px 4px`,
        }}
      />
    </div>
  )
}
