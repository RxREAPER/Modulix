import { Download } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { MedicalHeroIllustration } from "./MedicalHeroIllustration"
import { APP_CONSTANTS } from "../../lib/constants"

export function HeroSection({ navigate }: { navigate: (route: string) => void }) {
  return (
    <section className="relative pt-10 pb-16 sm:pt-14 sm:pb-20 text-center">
      {/* ── TOP: Centered Headline & Tagline (Switch-Lit Stacked Style) ── */}
      <div className="max-w-2xl mx-auto space-y-3">
        <h1 className="font-editorial text-4xl sm:text-6xl font-bold tracking-[-0.6px] leading-[1.1] text-[var(--ink-foreground)]">
          Introducing Modulix
        </h1>
        <p className="text-base sm:text-lg text-[var(--muted-text)] font-medium tracking-tight">
          A Planner Curated For Med school
        </p>
      </div>

      {/* ── MIDDLE: Interactive 3D Medical Folio Illustration ── */}
      <div className="my-3 sm:my-5">
        <MedicalHeroIllustration />
      </div>

      {/* ── BOTTOM: Call-to-Action Buttons ── */}
      <div className="max-w-md mx-auto flex flex-col sm:flex-row items-center justify-center gap-3.5 pt-2">
        {/* Get it on Playstore */}
        <a
          href={APP_CONSTANTS.playStoreUrl}
          target="_blank"
          rel="noreferrer"
          className="w-full sm:w-auto"
        >
          <ApplePressable className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-[var(--accent)] text-white font-semibold text-xs sm:text-sm shadow-sm flex items-center justify-center gap-2.5">
            <svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3.609 1.814L13.792 12 3.61 22.186a1.503 1.503 0 01-.61-.954V2.768c0-.38.225-.72.609-.954zm11.603 11.604l2.585 2.586-12.274 7.087 9.689-9.673zm0-2.836L5.524.909l12.273 7.087-2.585 2.586zm1.414 1.414l3.18 1.836c1.077.622 1.077 1.636 0 2.258l-3.18 1.836-2.185-2.185 2.185-2.185z" />
            </svg>
            <span>Get it on Playstore</span>
          </ApplePressable>
        </a>

        {/* Download APK */}
        <a
          href={APP_CONSTANTS.apkDownloadUrl}
          target="_blank"
          rel="noreferrer"
          className="w-full sm:w-auto"
        >
          <ApplePressable className="w-full sm:w-auto px-6 py-3.5 rounded-xl border border-[var(--border-subtle)] bg-[var(--card-bg)] text-[var(--ink-foreground)] font-semibold text-xs sm:text-sm flex items-center justify-center gap-2">
            <Download size={16} />
            <span>Download</span>
            <span className="text-[11px] text-[var(--muted-text)] font-normal ml-0.5">v{APP_CONSTANTS.version}</span>
          </ApplePressable>
        </a>
      </div>

      <div className="mt-5 text-center">
        <button
          onClick={() => navigate("#/privacy")}
          className="text-xs text-[var(--muted-text)] hover:text-[var(--accent)] font-medium cursor-pointer transition-colors"
        >
          Google Play Data Safety & Privacy Policy →
        </button>
      </div>
    </section>
  )
}
