import { Database, ShieldCheck, Cpu, Code2 } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { GithubIcon } from "../primitives/GithubIcon"
import { APP_CONSTANTS } from "../../lib/constants"

export function EcosystemSection({ navigate }: { navigate: (route: string) => void }) {
  const credentials = [
    {
      icon: Cpu,
      title: "Offline SQLite Core",
      desc: "Zero network reliance. Study sessions, question tallies, and daily desks live entirely in your device sandbox.",
    },
    {
      icon: ShieldCheck,
      title: "Supabase Row-Level Security",
      desc: "TLS 1.3 encrypted multi-device synchronization governed by strict PostgreSQL RLS rules.",
    },
    {
      icon: Code2,
      title: "MIT Open Source Foundation",
      desc: "Full source code available for peer audit on GitHub. Zero proprietary tracker or advertising SDKs.",
    },
  ]

  return (
    <section className="py-16 sm:py-20 border-t border-[var(--border-subtle)] select-none">
      <div className="flex flex-col md:flex-row items-start md:items-end justify-between gap-6 mb-10">
        <div className="space-y-2">
          <span className="font-mono text-[10px] tracking-widest text-[var(--accent)] font-semibold uppercase">
            ENGINEERING & ARCHITECTURE
          </span>
          <h2 className="font-editorial text-3xl sm:text-4xl font-bold tracking-tight text-[var(--ink-foreground)]">
            Open Source & Cloud Infrastructure
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] font-medium max-w-xl">
            Modulix is built on an offline-first foundation with optional Supabase cloud backup, providing total privacy and ownership of your study history.
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <a
            href={APP_CONSTANTS.githubRepoUrl}
            target="_blank"
            rel="noreferrer"
          >
            <ApplePressable className="px-4 py-2.5 rounded-xl border border-[var(--border-subtle)] bg-[var(--card-bg)] text-xs font-semibold flex items-center gap-2 text-[var(--ink-foreground)] shadow-sm">
              <GithubIcon size={14} />
              <span>GitHub Repo</span>
            </ApplePressable>
          </a>

          <ApplePressable
            onClick={() => navigate("#/account")}
            className="px-4 py-2.5 rounded-xl bg-[var(--accent)] text-white text-xs font-semibold flex items-center gap-2 shadow-sm"
          >
            <Database size={14} />
            <span>Manage Cloud Data</span>
          </ApplePressable>
        </div>
      </div>

      {/* 3 Architecture Pillar Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {credentials.map((cred) => {
          const Icon = cred.icon
          return (
            <div
              key={cred.title}
              className="p-6 rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)]/60 shadow-sm"
            >
              <div className="w-8 h-8 rounded-lg bg-[var(--accent-subtle)] text-[var(--accent)] flex items-center justify-center mb-4">
                <Icon size={16} />
              </div>
              <h3 className="font-editorial text-lg font-bold text-[var(--ink-foreground)] mb-1.5">
                {cred.title}
              </h3>
              <p className="text-xs text-[var(--muted-text)] leading-relaxed">
                {cred.desc}
              </p>
            </div>
          )
        })}
      </div>
    </section>
  )
}
