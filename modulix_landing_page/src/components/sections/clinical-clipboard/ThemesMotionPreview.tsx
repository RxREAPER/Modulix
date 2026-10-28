import { useState } from "react"
import { motion } from "framer-motion"

export function ThemesMotionPreview() {
  const themes = [
    {
      id: "paper",
      name: "Daylight Scholar",
      bg: "#F8F9FA",
      accent: "#007AFF",
      ink: "#0F172A",
    },
    {
      id: "slate",
      name: "Midnight Scholar",
      bg: "#121212",
      accent: "#0A84FF",
      ink: "#FFFFFF",
    },
    {
      id: "atomic_ice",
      name: "The Catalyst",
      bg: "#C8F3FF",
      accent: "#FF5C23",
      ink: "#102833",
    },
    {
      id: "forest_mint",
      name: "The Naturalist",
      bg: "#E8FFF2",
      accent: "#075E46",
      ink: "#0A261B",
    },
    {
      id: "cosmic_mocha",
      name: "The Academic",
      bg: "#FAF5ED",
      accent: "#B7A99A",
      ink: "#281E15",
    },
  ]

  const [activeTheme, setActiveTheme] = useState(themes[0])

  return (
    <div className="w-full max-w-md mx-auto py-3 select-none space-y-4">
      {/* Morphing Ink Pool Tile */}
      <motion.div
        animate={{
          backgroundColor: activeTheme.bg,
          borderColor: activeTheme.accent,
        }}
        transition={{ duration: 0.35, ease: "easeInOut" }}
        className="p-5 rounded-2xl border-[1.5px] shadow-sm flex flex-col justify-between h-28"
      >
        <div className="flex items-center justify-between">
          <span
            className="text-xs uppercase font-mono tracking-wider"
            style={{ color: activeTheme.ink, opacity: 0.6 }}
          >
            Clinical Palette
          </span>
          <span
            className="w-3 h-3 rounded-full"
            style={{ backgroundColor: activeTheme.accent }}
          />
        </div>

        <div>
          <span
            className="font-editorial text-2xl font-bold tracking-tight"
            style={{ color: activeTheme.ink }}
          >
            {activeTheme.name}
          </span>
        </div>
      </motion.div>

      {/* Swatch Selectors */}
      <div className="flex items-center justify-center gap-2.5">
        {themes.map((th) => (
          <button
            key={th.id}
            onClick={() => setActiveTheme(th)}
            className={`w-7 h-7 rounded-full border-2 transition-transform ${
              activeTheme.id === th.id ? "scale-125 shadow-md" : "hover:scale-110 opacity-75"
            }`}
            style={{
              backgroundColor: th.bg,
              borderColor: th.accent,
            }}
            title={th.name}
          />
        ))}
      </div>
    </div>
  )
}
