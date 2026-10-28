import { ArrowLeft, AlertCircle } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"

export function TermsView({ navigate }: { navigate: (route: string) => void }) {
  return (
    <div className="py-10 sm:py-16 max-w-3xl mx-auto select-none">
      {/* ── Header ── */}
      <div className="mb-8">
        <ApplePressable
          onClick={() => navigate("#/")}
          className="text-xs font-semibold text-[var(--muted-text)] hover:text-[var(--accent)] flex items-center gap-1.5 py-1 mb-4 w-fit"
        >
          <ArrowLeft size={14} />
          <span>Back to Overview</span>
        </ApplePressable>

        <div className="flex items-center gap-2 mb-2">
          <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
            TERMS OF USE & MEDICAL DISCLAIMER
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-5xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Terms of Service
        </h1>
        <p className="text-xs font-mono text-[var(--muted-text)] mt-2 flex items-center gap-2">
          <span>Updated October 2026</span>
          <span className="opacity-40">·</span>
          <span>MIT Open Source License</span>
        </p>
      </div>

      <HairlineDivider />

      <div className="space-y-10 my-10 text-sm text-[var(--ink-foreground)] leading-relaxed">
        {/* Medical Education Disclaimer Callout */}
        <section className="p-6 sm:p-7 rounded-2xl border border-amber-500/20 bg-amber-500/5 text-amber-900 dark:text-amber-200">
          <div className="flex items-start gap-3">
            <AlertCircle size={18} className="text-amber-500 shrink-0 mt-0.5" />
            <div>
              <h3 className="font-editorial text-lg font-bold">Medical Education Disclaimer</h3>
              <p className="text-xs sm:text-sm mt-1.5 opacity-90 leading-relaxed text-[var(--ink-foreground)]">
                Modulix is an educational syllabus tracking and timer companion designed solely to aid medical students and doctors studying for examination curricula (such as NEET-PG, INI-CET, and USMLE). It does not provide medical diagnostic advice, treatment recommendations, or clinical decision support.
              </p>
            </div>
          </div>
        </section>

        {/* Section 1 */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            1. Open Source License (MIT)
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            Modulix is released under the permissive MIT Open Source license. You are free to inspect the Flutter source code, submit patches, or build the software locally from source without restriction.
          </p>
        </section>

        {/* Section 2 */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            2. Intellectual Property of Curriculum Titles
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            Curriculum subject names, chapter topics, and video indices referenced in the software are structured for indexing and tracking personal study progress. Modulix does not host, stream, or distribute proprietary lecture videos or copyrighted question bank text.
          </p>
        </section>

        {/* Section 3 */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            3. Account & Service Availability
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            Cloud sync functionality is provided as a convenience. Because local data is always persisted inside your phone’s SQLite database, you maintain complete ownership and offline access to your study logs regardless of server connectivity.
          </p>
        </section>
      </div>
    </div>
  )
}
