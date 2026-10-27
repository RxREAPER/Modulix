import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { ThemeProvider } from "./lib/theme"
import { FilmicBackground } from "./components/layout/FilmicBackground"
import { Navbar } from "./components/layout/Navbar"
import { Footer } from "./components/layout/Footer"
import { HeroSection } from "./components/sections/HeroSection"
import { FeaturesSection } from "./components/sections/FeaturesSection"
import { ThemeShowcase } from "./components/sections/ThemeShowcase"
import { EcosystemSection } from "./components/sections/EcosystemSection"
import { PrivacyView } from "./components/privacy/PrivacyView"
import { TermsView } from "./components/privacy/TermsView"
import { AccountPortalView } from "./components/account/AccountPortalView"
import { ChangelogView } from "./components/updates/ChangelogView"

export default function App() {
  const [currentRoute, setCurrentRoute] = useState<string>(() => {
    return window.location.hash || "#/"
  })

  useEffect(() => {
    const handleHashChange = () => {
      const hash = window.location.hash || "#/"
      setCurrentRoute(hash)
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
            <ThemeShowcase />
            <EcosystemSection navigate={navigate} />
          </>
        )
    }
  }

  return (
    <ThemeProvider>
      <div className="min-h-screen flex flex-col relative selection:bg-blue-500/20 selection:text-blue-500">
        <FilmicBackground />
        <Navbar currentRoute={currentRoute} navigate={navigate} />

        <main className="flex-1 w-full max-w-5xl mx-auto px-5 sm:px-8">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentRoute}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.22, ease: [0.25, 0.1, 0.25, 1.0] }}
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
