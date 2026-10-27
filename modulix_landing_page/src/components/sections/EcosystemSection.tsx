import { Database } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { GithubIcon } from "../primitives/GithubIcon"
import { APP_CONSTANTS } from "../../lib/constants"

export function EcosystemSection({ navigate }: { navigate: (route: string) => void }) {
  return (
    <section className="py-12 border-t border-[var(--border-subtle)]">
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <h2 className="font-editorial text-2xl sm:text-3xl font-bold text-[var(--ink-foreground)]">
            Open Source & Ecosystem Credentials
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] mt-1 max-w-xl">
            Modulix is fully open source under the MIT License. Local study progress remains on your phone via SQLite; optional multi-device sync is backed by Supabase with Row-Level Security.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <a
            href={APP_CONSTANTS.githubRepoUrl}
            target="_blank"
            rel="noreferrer"
          >
            <ApplePressable className="px-4 py-2.5 rounded-lg border border-[var(--border-subtle)] text-xs font-semibold flex items-center gap-1.5 text-[var(--ink-foreground)]">
              <GithubIcon size={14} />
              <span>GitHub Repo</span>
            </ApplePressable>
          </a>

          <ApplePressable
            onClick={() => navigate("#/account")}
            className="px-4 py-2.5 rounded-lg bg-[var(--accent)] text-white text-xs font-semibold flex items-center gap-1.5"
          >
            <Database size={14} />
            <span>Manage Cloud Data</span>
          </ApplePressable>
        </div>
      </div>
    </section>
  )
}
