import { useTheme, Palette } from "../../lib/theme"
import { Check } from "lucide-react"

export function ThemeShowcase() {
  const { palette, setPalette } = useTheme()

  const palettes: { id: Palette; label: string; desc: string; previewBg: string; previewAccent: string; isDark: boolean }[] = [
    {
      id: "paper",
      label: "The Daylight Scholar",
      desc: "Pristine daylight clarity with focused cobalt precision",
      previewBg: "#F8F9FA",
      previewAccent: "#007AFF",
      isDark: false,
    },
    {
      id: "slate",
      label: "The Midnight Scholar",
      desc: "Zero-glare obsidian sanctuary for late-night deep work",
      previewBg: "#000000",
      previewAccent: "#0A84FF",
      isDark: true,
    },
    {
      id: "atomic_ice",
      label: "The Catalyst",
      desc: "Kinetic ice-blue canvas with high-yield atomic energy",
      previewBg: "#C8F3FF",
      previewAccent: "#FF5C23",
      isDark: false,
    },
    {
      id: "forest_mint",
      label: "The Naturalist",
      desc: "Refreshing mint fog with calming evergreen composure",
      previewBg: "#E8FFF2",
      previewAccent: "#075E46",
      isDark: false,
    },
    {
      id: "cosmic_mocha",
      label: "The Academic",
      desc: "Warm vintage parchment with rich espresso depth",
      previewBg: "#EBDCC6",
      previewAccent: "#B7A99A",
      isDark: false,
    },
  ]

  return (
    <section className="py-12 border-t border-[var(--border-subtle)]">
      <div className="mb-6">
        <h2 className="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Curated Clinical Themes
        </h2>
        <p className="text-xs sm:text-sm text-[var(--muted-text)] mt-1">
          Click any theme swatch to preview that palette live across this entire portal.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5">
        {palettes.map((p) => {
          const isSelected = palette === p.id
          return (
            <button
              key={p.id}
              onClick={() => setPalette(p.id)}
              className={`p-4 rounded-xl border text-left transition-all cursor-pointer flex items-start justify-between ${
                isSelected
                  ? "border-[var(--accent)] ring-1 ring-[var(--accent)] bg-[var(--surface-subtle)]"
                  : "border-[var(--border-subtle)] hover:border-[var(--muted-text)]/40 bg-[var(--card-bg)]"
              }`}
            >
              <div className="flex items-start gap-3">
                <div
                  className="w-8 h-8 rounded-full border border-black/10 flex items-center justify-center shrink-0 shadow-sm"
                  style={{ backgroundColor: p.previewBg }}
                >
                  <div
                    className="w-3.5 h-3.5 rounded-full"
                    style={{ backgroundColor: p.previewAccent }}
                  />
                </div>
                <div>
                  <div className="text-sm font-semibold text-[var(--ink-foreground)] flex items-center gap-1.5">
                    <span>{p.label}</span>
                    {p.isDark && (
                      <span className="text-[10px] px-1.5 py-0.2 rounded bg-neutral-800 text-neutral-300">
                        OLED
                      </span>
                    )}
                  </div>
                  <div className="text-xs text-[var(--muted-text)] mt-0.5 leading-snug">
                    {p.desc}
                  </div>
                </div>
              </div>

              {isSelected && (
                <div className="text-[var(--accent)] shrink-0 pt-0.5">
                  <Check size={16} />
                </div>
              )}
            </button>
          )
        })}
      </div>
    </section>
  )
}
