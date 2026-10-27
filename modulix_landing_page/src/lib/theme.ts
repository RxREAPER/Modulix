import { createContext, useContext, useEffect, useState, ReactNode, createElement } from "react"

export type Theme = "daylight" | "midnight"
export type Palette = "paper" | "slate" | "atomic_ice" | "forest_mint" | "cosmic_mocha"

interface ThemeContextType {
  theme: Theme
  palette: Palette
  toggleTheme: () => void
  setPalette: (palette: Palette) => void
  isDark: boolean
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined)

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>(() => {
    const saved = localStorage.getItem("modulix_theme") as Theme
    if (saved === "daylight" || saved === "midnight") return saved
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "midnight" : "daylight"
  })

  const [palette, setPaletteState] = useState<Palette>(() => {
    const saved = localStorage.getItem("modulix_palette") as Palette
    return saved || "paper"
  })

  useEffect(() => {
    const root = document.documentElement
    root.setAttribute("data-theme", theme)
    if (palette !== "paper" && palette !== "slate") {
      root.setAttribute("data-palette", palette)
    } else {
      root.removeAttribute("data-palette")
    }
    localStorage.setItem("modulix_theme", theme)
    localStorage.setItem("modulix_palette", palette)
  }, [theme, palette])

  const toggleTheme = () => {
    setTheme(prev => {
      const next = prev === "daylight" ? "midnight" : "daylight"
      setPaletteState(next === "midnight" ? "slate" : "paper")
      return next
    })
  }

  const setPalette = (p: Palette) => {
    setPaletteState(p)
    if (p === "slate") {
      setTheme("midnight")
    } else {
      setTheme("daylight")
    }
  }

  const isDark = theme === "midnight"

  return createElement(
    ThemeContext.Provider,
    { value: { theme, palette, toggleTheme, setPalette, isDark } },
    children
  )
}

export function useTheme() {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error("useTheme must be used within ThemeProvider")
  }
  return context
}
