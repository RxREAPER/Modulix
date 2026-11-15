import { MxMonogram } from "../primitives/MxMonogram"
import { HairlineDivider } from "../primitives/HairlineDivider"
import { APP_CONSTANTS } from "../../lib/constants"

interface FooterProps {
  navigate: (route: string) => void
}

export function Footer({ navigate }: FooterProps) {
  return (
    <footer className="w-full max-w-5xl mx-auto px-5 sm:px-8 pt-16 pb-28 md:pb-20 mt-12 text-[var(--ink-foreground)]">
      <HairlineDivider />

      <div className="pt-8 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
        <div className="flex items-center gap-3">
          <MxMonogram size={26} />
          <div>
            <span className="font-editorial text-lg font-bold">Modulix</span>
            <p className="text-xs text-[var(--muted-text)] leading-relaxed mt-0.5">
              Crafted with clinical precision for medical doctors.
            </p>
          </div>
        </div>

        {/* Links Navigation */}
        <div className="flex flex-wrap items-center gap-x-6 gap-y-2 text-xs font-medium text-[var(--muted-text)]">
          <button
            onClick={() => navigate("#/")}
            className="hover:text-[var(--accent)] cursor-pointer"
          >
            Features
          </button>
          <button
            onClick={() => navigate("#/privacy")}
            className="hover:text-[var(--accent)] cursor-pointer"
          >
            Privacy Policy
          </button>
          <button
            onClick={() => navigate("#/terms")}
            className="hover:text-[var(--accent)] cursor-pointer"
          >
            Terms of Service
          </button>
          <button
            onClick={() => navigate("#/copyright")}
            className="hover:text-[var(--accent)] cursor-pointer"
          >
            Copyright & IP
          </button>
          <button
            onClick={() => navigate("#/account")}
            className="hover:text-[var(--accent)] cursor-pointer"
          >
            Account & Data
          </button>
          <button
            onClick={() => navigate("#/updates")}
            className="hover:text-[var(--accent)] cursor-pointer"
          >
            Changelog
          </button>
          <a
            href={APP_CONSTANTS.githubRepoUrl}
            target="_blank"
            rel="noreferrer"
            className="hover:text-[var(--accent)] inline-flex items-center gap-1"
          >
            GitHub
          </a>
        </div>
      </div>

      <div className="mt-8 pt-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-[11px] text-[var(--muted-text)] opacity-80">
        <div>
          © {new Date().getFullYear()} Modulix (RxREAPER). All rights reserved. Independent personal study companion.
        </div>
        <div className="flex items-center gap-3">
          <span className="inline-flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            Supabase Cloud Connected
          </span>
          <span>·</span>
          <span>Android v{APP_CONSTANTS.version}</span>
        </div>
      </div>
    </footer>
  )
}
