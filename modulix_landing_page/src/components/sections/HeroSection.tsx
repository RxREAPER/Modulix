import { Download } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { GithubIcon } from "../primitives/GithubIcon"
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
        <p className="text-xs sm:text-sm text-[var(--muted-text)] font-semibold tracking-widest uppercase">
          A PLANNER CURATED FOR MED SCHOOL
        </p>
      </div>

      {/* ── MIDDLE: Interactive Live Medical Hero Card (Switch-Lit Style) ── */}
      <div className="my-6 sm:my-9">
        <MedicalHeroIllustration />
      </div>

      {/* ── BOTTOM: Call-to-Action Buttons ── */}
      <div className="max-w-md mx-auto flex flex-col sm:flex-row items-center justify-center gap-3.5 pt-2">
        {/* Primary CTA: Download APK for Android */}
        <a
          href={APP_CONSTANTS.apkDownloadUrl}
          className="w-full sm:w-auto"
        >
          <ApplePressable className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-[var(--accent)] text-white font-semibold text-xs sm:text-sm shadow-md flex items-center justify-center gap-2.5 hover:opacity-95 transition-opacity">
            <Download size={17} />
            <span>Download for Android (.apk)</span>
            <span className="text-[11px] opacity-80 font-normal ml-0.5">v{APP_CONSTANTS.version}</span>
          </ApplePressable>
        </a>

        {/* Secondary CTA: GitHub Release */}
        <a
          href={APP_CONSTANTS.githubReleaseUrl}
          target="_blank"
          rel="noreferrer"
          className="w-full sm:w-auto"
        >
          <ApplePressable className="w-full sm:w-auto px-5 py-3.5 rounded-xl border border-[var(--border-subtle)] bg-[var(--card-bg)] text-[var(--ink-foreground)] font-semibold text-xs sm:text-sm flex items-center justify-center gap-2 hover:bg-[var(--surface-subtle)] transition-colors">
            <GithubIcon size={16} />
            <span>GitHub Release</span>
          </ApplePressable>
        </a>
      </div>

      <div className="mt-3.5 text-center">
        <p className="text-[11px] text-[var(--muted-text)] tracking-wide">
          Signed production build (ARM64) · Direct install · Google Play launch pending review
        </p>
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
