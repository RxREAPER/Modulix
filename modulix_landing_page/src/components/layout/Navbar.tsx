import { useState, useEffect, useRef } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Sun, Moon, Compass, Shield, User, Clock } from "lucide-react"
import { MxMonogram } from "../primitives/MxMonogram"
import { GithubIcon } from "../primitives/GithubIcon"
import { useTheme } from "../../lib/theme"
import { APP_CONSTANTS } from "../../lib/constants"

interface NavbarProps {
  currentRoute: string
  navigate: (route: string) => void
}

export function Navbar({ currentRoute, navigate }: NavbarProps) {
  const { isDark, toggleTheme } = useTheme()
  const [dockVisible, setDockVisible] = useState(true)
  const lastScrollY = useRef(0)

  // Smart auto-tuck bottom dock on scroll down, spring reveal on scroll up
  useEffect(() => {
    const handleScroll = () => {
      const currentScrollY = window.scrollY
      if (currentScrollY < 60) {
        setDockVisible(true)
      } else if (currentScrollY > lastScrollY.current + 8) {
        // Fast scroll down -> hide dock to maximize reading canvas
        setDockVisible(false)
      } else if (currentScrollY < lastScrollY.current - 8) {
        // Scroll up -> reveal dock for instant thumb navigation
        setDockVisible(true)
      }
      lastScrollY.current = currentScrollY
    }

    window.addEventListener("scroll", handleScroll, { passive: true })
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  const navItems = [
    { label: "Showcase", shortLabel: "Home", hash: "#/", icon: Compass },
    { label: "Privacy Policy", shortLabel: "Privacy", hash: "#/privacy", icon: Shield },
    { label: "Account Portal", shortLabel: "Account", hash: "#/account", icon: User },
    { label: "Changelog", shortLabel: "Updates", hash: "#/updates", icon: Clock },
  ]

  const handleNavClick = (hash: string) => {
    navigate(hash)
  }

  const isItemActive = (hash: string) => {
    return currentRoute === hash || (hash === "#/" && (currentRoute === "" || currentRoute === "#/"))
  }

  return (
    <>
      {/* ─────────────────────────────────────────────────────────────
          1. TABLET & DESKTOP: Refined Floating Header Pill (>= 768px)
         ───────────────────────────────────────────────────────────── */}
      <header className="hidden md:block sticky top-4 z-50 max-w-4xl mx-auto px-4 w-full select-none">
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ type: "spring", stiffness: 350, damping: 28 }}
          className="rounded-full border border-[var(--border-subtle)] bg-[var(--card-bg)]/85 backdrop-blur-2xl shadow-[0_8px_32px_rgba(0,0,0,0.06)] px-4 py-2 flex items-center justify-between transition-colors"
        >
          {/* Brand Monogram & Title */}
          <motion.div
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => handleNavClick("#/")}
            className="flex items-center gap-2.5 cursor-pointer"
          >
            <div
              className={`w-8 h-8 rounded-lg flex items-center justify-center border transition-colors ${
                isDark
                  ? "bg-white/[0.06] border-white/[0.12] text-white"
                  : "bg-black/[0.04] border-black/[0.08] text-black"
              }`}
            >
              <MxMonogram size={22} />
            </div>
            <div className="flex items-center gap-2">
              <span className="font-editorial text-lg font-bold tracking-tight text-[var(--ink-foreground)]">
                Modulix
              </span>
              <span className="font-mono text-[9px] uppercase font-semibold text-[var(--accent)] tracking-wider px-1.5 py-0.5 rounded-full bg-[var(--accent-subtle)] border border-[var(--accent)]/20">
                v{APP_CONSTANTS.version}
              </span>
            </div>
          </motion.div>

          {/* Center: Segmented Navigation Pill Switcher */}
          <nav className="flex items-center gap-1 bg-[var(--surface-subtle)]/80 p-1 rounded-full border border-[var(--border-subtle)]/70">
            {navItems.map((item) => {
              const active = isItemActive(item.hash)
              return (
                <button
                  key={item.label}
                  onClick={() => handleNavClick(item.hash)}
                  className="relative px-3.5 py-1.5 rounded-full text-xs font-medium cursor-pointer transition-colors focus:outline-none"
                >
                  {active && (
                    <motion.div
                      layoutId="activeNavPillDesktop"
                      className="absolute inset-0 rounded-full bg-[var(--card-bg)] shadow-[0_2px_8px_rgba(0,0,0,0.08)] border border-[var(--border-subtle)]"
                      transition={{ type: "spring", stiffness: 450, damping: 30 }}
                    />
                  )}
                  <span
                    className={`relative z-10 transition-colors ${
                      active
                        ? "text-[var(--ink-foreground)] font-semibold"
                        : "text-[var(--muted-text)] hover:text-[var(--ink-foreground)]"
                    }`}
                  >
                    {item.label}
                  </span>
                </button>
              )
            })}
          </nav>

          {/* Right Controls: Theme Toggle & GitHub Pill */}
          <div className="flex items-center gap-2">
            <motion.button
              whileHover={{ scale: 1.08 }}
              whileTap={{ scale: 0.92 }}
              onClick={toggleTheme}
              className={`w-8 h-8 rounded-full flex items-center justify-center border transition-colors cursor-pointer ${
                isDark
                  ? "bg-white/[0.06] border-white/[0.12] text-amber-300"
                  : "bg-black/[0.04] border-black/[0.08] text-slate-700"
              }`}
              title="Toggle Daylight / Midnight Theme"
            >
              <AnimatePresence mode="wait" initial={false}>
                <motion.div
                  key={isDark ? "dark" : "light"}
                  initial={{ rotate: -90, scale: 0, opacity: 0 }}
                  animate={{ rotate: 0, scale: 1, opacity: 1 }}
                  exit={{ rotate: 90, scale: 0, opacity: 0 }}
                  transition={{ duration: 0.18 }}
                >
                  {isDark ? <Sun size={15} /> : <Moon size={15} />}
                </motion.div>
              </AnimatePresence>
            </motion.button>

            <a
              href={APP_CONSTANTS.githubRepoUrl}
              target="_blank"
              rel="noreferrer"
            >
              <motion.div
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className={`px-3 py-1.5 rounded-full border text-xs font-semibold flex items-center gap-1.5 transition-colors ${
                  isDark
                    ? "bg-white/[0.06] border-white/[0.12] text-white"
                    : "bg-black/[0.04] border-black/[0.08] text-slate-800"
                }`}
              >
                <GithubIcon size={13} />
                <span className="hidden lg:inline text-[11px]">GitHub</span>
              </motion.div>
            </a>
          </div>
        </motion.div>
      </header>

      {/* ─────────────────────────────────────────────────────────────
          2. MOBILE: Quiet Top Brand Bar (< 768px)
         ───────────────────────────────────────────────────────────── */}
      <header className="md:hidden sticky top-0 z-40 bg-[var(--scaffold-bg)]/85 backdrop-blur-xl border-b border-[var(--border-subtle)] px-5 py-3 flex items-center justify-between select-none">
        <div
          onClick={() => handleNavClick("#/")}
          className="flex items-center gap-2.5 cursor-pointer"
        >
          <div
            className={`w-7 h-7 rounded-lg flex items-center justify-center border ${
              isDark
                ? "bg-white/[0.06] border-white/[0.12]"
                : "bg-black/[0.04] border-black/[0.08]"
            }`}
          >
            <MxMonogram size={18} />
          </div>
          <span className="font-editorial text-base font-bold tracking-tight text-[var(--ink-foreground)]">
            Modulix
          </span>
        </div>

        <div className="flex items-center gap-2">
          <span className="font-mono text-[9px] uppercase font-semibold text-[var(--accent)] tracking-wider px-2 py-0.5 rounded-full bg-[var(--accent-subtle)] border border-[var(--accent)]/20">
            v{APP_CONSTANTS.version}
          </span>
          <a
            href={APP_CONSTANTS.githubRepoUrl}
            target="_blank"
            rel="noreferrer"
            title="GitHub Repository"
          >
            <div
              className={`w-7 h-7 rounded-full flex items-center justify-center border ${
                isDark
                  ? "bg-white/[0.06] border-white/[0.12] text-white"
                  : "bg-black/[0.04] border-black/[0.08] text-slate-800"
              }`}
            >
              <GithubIcon size={13} />
            </div>
          </a>
        </div>
      </header>

      {/* ─────────────────────────────────────────────────────────────
          3. MOBILE: Floating Bottom Capsule Dock (< 768px)
         ───────────────────────────────────────────────────────────── */}
      <motion.nav
        initial={{ y: 80, opacity: 0 }}
        animate={{
          y: dockVisible ? 0 : 80,
          opacity: dockVisible ? 1 : 0,
          scale: dockVisible ? 1 : 0.94,
        }}
        transition={{ type: "spring", stiffness: 400, damping: 28 }}
        className="fixed bottom-5 inset-x-0 mx-auto w-fit z-50 md:hidden select-none px-3"
      >
        <div className="rounded-full border border-[var(--border-subtle)] bg-[var(--card-bg)]/90 backdrop-blur-2xl shadow-[0_12px_40px_rgba(0,0,0,0.18)] p-1.5 flex items-center gap-1 transition-colors">
          {navItems.map((item) => {
            const active = isItemActive(item.hash)
            const Icon = item.icon
            return (
              <motion.button
                key={item.label}
                whileTap={{ scale: 0.88 }}
                onClick={() => handleNavClick(item.hash)}
                className="relative flex flex-col items-center justify-center px-3.5 py-1.5 rounded-full cursor-pointer focus:outline-none transition-colors"
              >
                {active && (
                  <motion.div
                    layoutId="mobileActiveDockPill"
                    className="absolute inset-0 rounded-full bg-[var(--accent)]/15 border border-[var(--accent)]/30"
                    transition={{ type: "spring", stiffness: 450, damping: 30 }}
                  />
                )}
                <Icon
                  size={17}
                  className={`relative z-10 transition-colors ${
                    active ? "text-[var(--accent)]" : "text-[var(--muted-text)]"
                  }`}
                />
                <span
                  className={`relative z-10 text-[9px] font-mono font-medium tracking-tight mt-0.5 transition-colors ${
                    active
                      ? "text-[var(--accent)] font-bold"
                      : "text-[var(--muted-text)]"
                  }`}
                >
                  {item.shortLabel}
                </span>
              </motion.button>
            )
          })}

          {/* 0.6px Vertical Hairline Divider */}
          <div className="w-[1px] h-5 bg-[var(--border-subtle)] mx-0.5" />

          {/* Dock Theme Toggle */}
          <motion.button
            whileTap={{ scale: 0.88 }}
            onClick={toggleTheme}
            className="relative p-2 rounded-full text-[var(--muted-text)] hover:text-[var(--ink-foreground)] cursor-pointer focus:outline-none"
            title="Toggle Theme"
          >
            <AnimatePresence mode="wait" initial={false}>
              <motion.div
                key={isDark ? "dark" : "light"}
                initial={{ rotate: -90, scale: 0, opacity: 0 }}
                animate={{ rotate: 0, scale: 1, opacity: 1 }}
                exit={{ rotate: 90, scale: 0, opacity: 0 }}
                transition={{ duration: 0.18 }}
              >
                {isDark ? (
                  <Sun size={17} className="text-amber-300" />
                ) : (
                  <Moon size={17} />
                )}
              </motion.div>
            </AnimatePresence>
          </motion.button>
        </div>
      </motion.nav>
    </>
  )
}
