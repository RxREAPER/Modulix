import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { ThemeProvider } from "./lib/theme"
import { Navbar } from "./components/layout/Navbar"
import { Footer } from "./components/layout/Footer"
import { HeroSection } from "./components/sections/HeroSection"
import { FeaturesSection } from "./components/sections/FeaturesSection"
import { StudyJourneySection } from "./components/sections/study-journey/StudyJourneySection"
import { EcosystemSection } from "./components/sections/EcosystemSection"
import { PrivacyView } from "./components/privacy/PrivacyView"
import { TermsView } from "./components/privacy/TermsView"
import { AccountPortalView } from "./components/account/AccountPortalView"
import { ChangelogView } from "./components/updates/ChangelogView"

function sanitizeRoute(rawHash: string): string {
  if (!rawHash || rawHash === "#" || rawHash === "#/") return "#/"
  
  if (rawHash.includes("access_token") || rawHash.includes("error_description")) {
    return "#/account"
  }

  const base = rawHash.split("?")[0].split("&")[0]
  return base || "#/"
}

export default function App() {
  const [currentRoute, setCurrentRoute] = useState<string>(() => {
    return sanitizeRoute(window.location.hash)
  })

  useEffect(() => {
    if (window.location.hash.includes("access_token")) {
      window.location.hash = "#/account"
    }

    const handleHashChange = () => {
      const sanitized = sanitizeRoute(window.location.hash)
      setCurrentRoute(sanitized)
      window.scrollTo({ top: 0, behavior: "smooth" })
    }

    window.addEventListener("hashchange", handleHashChange)
    return () => window.removeEventListener("hashchange", handleHashChange)
  }, [])

  const navigate = (route: string) => {
    window.location.hash = route
  }

  const renderContent = () => {
    switch (currentRoute) {
      case "#/privacy":
        return <PrivacyView navigate={navigate} />
      case "#/terms":
        return <TermsView navigate={navigate} />
      case "#/account":
        return <AccountPortalView navigate={navigate} />
      case "#/updates":
        return <ChangelogView navigate={navigate} />
      case "#/":
      default:
        return (
          <>
            <HeroSection navigate={navigate} />
            <FeaturesSection />
            <StudyJourneySection />
            <EcosystemSection navigate={navigate} />
          </>
        )
    }
  }

  return (
    <ThemeProvider>
      <div className="min-h-screen flex flex-col bg-[var(--scaffold-bg)] text-[var(--ink-foreground)] selection:bg-blue-500/20 selection:text-blue-500">
        <Navbar currentRoute={currentRoute} navigate={navigate} />

        <main className="flex-1 w-full max-w-5xl mx-auto px-5 sm:px-8">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentRoute}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.2, ease: [0.25, 0.1, 0.25, 1.0] }}
            >
              {renderContent()}
            </motion.div>
          </AnimatePresence>
        </main>

        <Footer navigate={navigate} />
      </div>
    </ThemeProvider>
  )
}
