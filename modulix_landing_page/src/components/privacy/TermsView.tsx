import { ArrowLeft, AlertCircle } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"

export function TermsView({ navigate }: { navigate: (route: string) => void }) {
  return (
    <div className="py-8 max-w-3xl">
      <div className="mb-6">
        <ApplePressable
          onClick={() => navigate("#/")}
          className="text-xs font-semibold text-[var(--muted-text)] hover:text-[var(--accent)] flex items-center gap-1.5 py-1 mb-3"
        >
          <ArrowLeft size={14} />
          <span>Back to Overview</span>
        </ApplePressable>

        <h1 className="font-editorial text-3xl sm:text-4xl font-bold text-[var(--ink-foreground)]">
          Terms of Service & Medical Disclaimer
        </h1>
        <p className="text-xs text-[var(--muted-text)] mt-1">
          Last revised: October 2026
        </p>
      </div>

      <HairlineDivider />

      <div className="space-y-8 text-sm text-[var(--ink-foreground)] leading-relaxed">
        <section className="p-4 rounded-xl border border-amber-500/20 bg-amber-500/5 text-amber-900 dark:text-amber-200">
          <div className="flex items-start gap-2.5">
            <AlertCircle size={18} className="text-amber-500 shrink-0 mt-0.5" />
            <div>
              <h3 className="font-semibold text-sm">Medical Education Disclaimer</h3>
              <p className="text-xs mt-1 opacity-90 leading-relaxed">
                Modulix is an educational syllabus tracking and timer companion designed solely to aid medical students and doctors studying for examination curricula (such as NEET-PG, INI-CET, and USMLE). It does not provide medical diagnostic advice, treatment recommendations, or clinical decision support.
              </p>
            </div>
          </div>
        </section>

        <section>
          <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] mb-2">
            1. Open Source License (MIT)
          </h2>
          <p className="text-[var(--muted-text)]">
            Modulix is licensed under the permissive MIT Open Source license. You are free to inspect the Flutter source code, submit patches, or build the software locally from source.
          </p>
        </section>

        <section>
          <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] mb-2">
            2. Intellectual Property of Curriculum Titles
          </h2>
          <p className="text-[var(--muted-text)]">
            Curriculum subject names, chapter topics, and video indices referenced in the software are structured for indexing and tracking personal study progress. Modulix does not host, stream, or distribute proprietary lecture videos or copyrighted study question text.
          </p>
        </section>

        <section>
          <h2 className="font-editorial text-2xl font-bold text-[var(--ink-foreground)] mb-2">
            3. Account & Service Availability
          </h2>
          <p className="text-[var(--muted-text)]">
            Cloud sync functionality is provided as a convenience. Because local data is always stored in your phone’s SQLite database, you maintain complete ownership and offline access to your study logs regardless of server connectivity.
          </p>
        </section>
      </div>
    </div>
  )
}
