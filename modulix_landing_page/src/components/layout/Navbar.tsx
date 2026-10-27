import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Sun, Moon, Menu, X, Shield, User, Clock, ExternalLink } from "lucide-react"
import { MxMonogram } from "../primitives/MxMonogram"
import { ApplePressable } from "../primitives/ApplePressable"
import { GithubIcon } from "../primitives/GithubIcon"
import { useTheme } from "../../lib/theme"
import { APP_CONSTANTS } from "../../lib/constants"

interface NavbarProps {
  currentRoute: string
  navigate: (route: string) => void
}

export function Navbar({ currentRoute, navigate }: NavbarProps) {
  const { isDark, toggleTheme } = useTheme()
  const [isScrolled, setIsScrolled] = useState(false)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  useEffect(() => {
    const onScroll = () => {
      setIsScrolled(window.scrollY > 20)
    }
    window.addEventListener("scroll", onScroll)
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  const navItems = [
    { label: "Showcase", hash: "#/", icon: null },
    { label: "Privacy Policy", hash: "#/privacy", icon: Shield },
    { label: "Account Portal", hash: "#/account", icon: User },
    { label: "Changelog", hash: "#/updates", icon: Clock },
  ]

  const handleNavClick = (hash: string) => {
    navigate(hash)
    setMobileMenuOpen(false)
  }

  return (
    <header
      className={`sticky top-0 z-50 transition-all duration-300 ${
        isScrolled
          ? "bg-[var(--scaffold-bg)]/85 backdrop-blur-md border-b border-[var(--border-subtle)]"
          : "bg-transparent border-b border-transparent"
      }`}
    >
      <div className="max-w-5xl mx-auto px-5 sm:px-8 h-18 flex items-center justify-between">
        {/* Brand Bar with 46x44mm sleek container */}
        <div
          onClick={() => handleNavClick("#/")}
          className="flex items-center gap-3 cursor-pointer select-none group"
        >
          <div
            className={`w-[46px] h-[44px] rounded-[11px] flex items-center justify-center transition-all ${
              isDark
                ? "bg-white/[0.06] border border-white/[0.12] group-hover:border-white/[0.25]"
                : "bg-black/[0.035] border border-black/[0.07] group-hover:border-black/[0.15]"
            }`}
          >
            <MxMonogram size={30} />
          </div>
          <div className="flex flex-col">
            <span className="font-editorial text-[22px] font-bold tracking-[-0.3px] leading-none text-[var(--ink-foreground)]">
              Modulix
            </span>
            <span className="text-[10px] uppercase font-semibold tracking-wider text-[var(--muted-text)] mt-1">
              v{APP_CONSTANTS.version}
            </span>
          </div>
        </div>

        {/* Desktop Navigation Links */}
        <nav className="hidden md:flex items-center gap-1 sm:gap-2">
          {navItems.map((item) => {
            const isActive =
              currentRoute === item.hash || (item.hash === "#/" && currentRoute === "")
            return (
              <ApplePressable
                key={item.label}
                onClick={() => handleNavClick(item.hash)}
                className={`px-3 py-1.5 rounded-lg text-[13px] font-medium transition-colors ${
                  isActive
                    ? "text-[var(--accent)] font-semibold bg-[var(--accent-subtle)]"
                    : "text-[var(--muted-text)] hover:text-[var(--ink-foreground)]"
                }`}
              >
                {item.label}
              </ApplePressable>
            )
          })}
        </nav>

        {/* Action Controls: Theme Toggle & GitHub */}
        <div className="flex items-center gap-2">
          <ApplePressable
            onClick={toggleTheme}
            className={`w-9 h-9 rounded-full flex items-center justify-center transition-colors border ${
              isDark
                ? "bg-white/[0.06] border-white/[0.12] text-amber-300"
                : "bg-black/[0.04] border-black/[0.08] text-slate-700"
            }`}
            title="Toggle theme (Daylight / Midnight)"
          >
            {isDark ? <Sun size={17} /> : <Moon size={17} />}
          </ApplePressable>

          <a
            href={APP_CONSTANTS.githubRepoUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:inline-flex"
            title="GitHub Repository"
          >
            <ApplePressable
              className={`w-9 h-9 rounded-full flex items-center justify-center transition-colors border ${
                isDark
                  ? "bg-white/[0.06] border-white/[0.12] text-white"
                  : "bg-black/[0.04] border-black/[0.08] text-slate-800"
              }`}
            >
              <GithubIcon size={16} />
            </ApplePressable>
          </a>

          {/* Mobile Menu Button */}
          <ApplePressable
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden w-9 h-9 rounded-full flex items-center justify-center border border-[var(--border-subtle)] text-[var(--ink-foreground)]"
          >
            {mobileMenuOpen ? <X size={18} /> : <Menu size={18} />}
          </ApplePressable>
        </div>
      </div>

      {/* Mobile Animated Dropdown */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ type: "spring", stiffness: 350, damping: 30 }}
            className="md:hidden border-b border-[var(--border-subtle)] bg-[var(--scaffold-bg)] px-6 py-4 flex flex-col gap-2"
          >
            {navItems.map((item) => (
              <button
                key={item.label}
                onClick={() => handleNavClick(item.hash)}
                className="flex items-center gap-3 py-2.5 text-left text-sm font-medium text-[var(--ink-foreground)] hover:text-[var(--accent)]"
              >
                {item.icon && <item.icon size={16} className="text-[var(--muted-text)]" />}
                {item.label}
              </button>
            ))}
            <div className="pt-2 border-t border-[var(--border-subtle)] flex items-center justify-between text-xs text-[var(--muted-text)]">
              <span>Modulix for Android</span>
              <a
                href={APP_CONSTANTS.githubRepoUrl}
                target="_blank"
                rel="noreferrer"
                className="flex items-center gap-1 text-[var(--accent)]"
              >
                GitHub <ExternalLink size={12} />
              </a>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  )
}
