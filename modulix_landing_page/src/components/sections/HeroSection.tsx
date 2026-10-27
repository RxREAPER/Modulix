import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { Download, ArrowRight } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { GithubIcon } from "../primitives/GithubIcon"
import { APP_CONSTANTS } from "../../lib/constants"

export function HeroSection({ navigate }: { navigate: (route: string) => void }) {
  const doctorNames = ["Doctor", "Safi", "Sharma", "Patel", "Verma", "Rao"]
  const [nameIndex, setNameIndex] = useState(0)

  useEffect(() => {
    const timer = setInterval(() => {
      setNameIndex((prev) => (prev + 1) % doctorNames.length)
    }, 3200)
    return () => clearInterval(timer)
  }, [])

  return (
    <section className="relative pt-12 pb-14 sm:pt-16 sm:pb-20">
      <div className="max-w-3xl">
        <div className="inline-flex items-center gap-2 mb-3">
          <span className="w-2 h-2 rounded-full bg-blue-500"></span>
          <span className="text-xs font-semibold tracking-wider uppercase text-[var(--muted-text)]">
            Medical Study Companion
          </span>
        </div>

        <h1 className="font-editorial text-4xl sm:text-6xl font-bold tracking-[-0.6px] leading-[1.12] text-[var(--ink-foreground)]">
          Focus, Dr.{" "}
          <motion.span
            key={doctorNames[nameIndex]}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.35, ease: "easeOut" }}
            className="text-[var(--accent)] underline decoration-[var(--border-subtle)] decoration-1 underline-offset-8"
          >
            {doctorNames[nameIndex]}
          </motion.span>
        </h1>

        <p className="mt-6 text-lg sm:text-xl text-[var(--muted-text)] font-normal leading-relaxed max-w-2xl">
          The high-performance medical syllabus tracker, habit anchor, and cognitive focus companion engineered for doctors preparing for <strong>NEET-PG</strong>, <strong>INI-CET</strong>, and <strong>USMLE</strong>.
        </p>

        <div className="mt-8 flex flex-wrap items-center gap-3">
          <a
            href={APP_CONSTANTS.apkDownloadUrl}
            target="_blank"
            rel="noreferrer"
          >
            <ApplePressable className="px-6 py-3.5 rounded-xl bg-[var(--accent)] text-white font-semibold text-sm shadow-sm flex items-center gap-2">
              <Download size={17} />
              <span>Download Android APK</span>
              <span className="text-xs opacity-75 font-normal ml-0.5">v{APP_CONSTANTS.version}</span>
            </ApplePressable>
          </a>

          <a
            href={APP_CONSTANTS.githubRepoUrl}
            target="_blank"
            rel="noreferrer"
          >
            <ApplePressable className="px-5 py-3.5 rounded-xl border border-[var(--border-subtle)] bg-[var(--card-bg)] text-[var(--ink-foreground)] font-semibold text-sm flex items-center gap-2">
              <GithubIcon size={16} />
              <span>View Source Code</span>
            </ApplePressable>
          </a>

          <ApplePressable
            onClick={() => navigate("#/privacy")}
            className="px-4 py-3.5 text-xs font-semibold text-[var(--muted-text)] hover:text-[var(--accent)] flex items-center gap-1"
          >
            <span>Play Store Data Safety</span>
            <ArrowRight size={13} />
          </ApplePressable>
        </div>

        <div className="mt-12 pt-6 border-t border-[var(--border-subtle)] grid grid-cols-2 sm:grid-cols-4 gap-6 text-[var(--ink-foreground)]">
          <div>
            <div className="font-editorial text-2xl font-bold">19 Subjects</div>
            <div className="text-xs text-[var(--muted-text)] mt-0.5">Editions 8 & 6.5</div>
          </div>
          <div>
            <div className="font-editorial text-2xl font-bold">5:00 AM</div>
            <div className="text-xs text-[var(--muted-text)] mt-0.5">Clinical Rollover</div>
          </div>
          <div>
            <div className="font-editorial text-2xl font-bold">120 FPS</div>
            <div className="text-xs text-[var(--muted-text)] mt-0.5">ApplePressable Feel</div>
          </div>
          <div>
            <div className="font-editorial text-2xl font-bold">Offline-First</div>
            <div className="text-xs text-[var(--muted-text)] mt-0.5">SQLite & Cloud Sync</div>
          </div>
        </div>
      </div>
    </section>
  )
}
