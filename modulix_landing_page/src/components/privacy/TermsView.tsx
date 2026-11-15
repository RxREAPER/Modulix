import { ArrowLeft, AlertCircle, ShieldAlert, BookOpen, Scale } from "lucide-react"
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
            LEGAL AGREEMENT & CRITICAL DISCLAIMERS
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-5xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Terms of Service
        </h1>
        <p className="text-xs font-mono text-[var(--muted-text)] mt-2 flex flex-wrap items-center gap-2">
          <span>Updated November 2026</span>
          <span className="opacity-40">·</span>
          <span>Independent Personal Project</span>
          <span className="opacity-40">·</span>
          <span>Solo Developer Shield</span>
        </p>
      </div>

      <HairlineDivider />

      <div className="space-y-10 my-10 text-sm text-[var(--ink-foreground)] leading-relaxed">
        {/* Solo Developer & Personal Project Callout */}
        <section className="p-6 sm:p-7 rounded-2xl border border-blue-500/20 bg-blue-500/5 text-blue-950 dark:text-blue-200">
          <div className="flex items-start gap-3">
            <Scale size={18} className="text-blue-500 shrink-0 mt-0.5" />
            <div>
              <h3 className="font-editorial text-lg font-bold">Independent Personal Project Notice</h3>
              <p className="text-xs sm:text-sm mt-1.5 opacity-90 leading-relaxed text-[var(--ink-foreground)]">
                Modulix is created, developed, and maintained independently by a solo developer (<strong>RxREAPER</strong>) as a personal educational study companion. It is not operated by a corporation, commercial entity, or venture company. By using the app or website, you acknowledge this solo developer nature and agree that no individual or personal asset liability shall attach to the developer.
              </p>
            </div>
          </div>
        </section>

        {/* Medical Education Disclaimer Callout */}
        <section className="p-6 sm:p-7 rounded-2xl border border-amber-500/20 bg-amber-500/5 text-amber-950 dark:text-amber-200">
          <div className="flex items-start gap-3">
            <AlertCircle size={18} className="text-amber-500 shrink-0 mt-0.5" />
            <div>
              <h3 className="font-editorial text-lg font-bold">Medical Advice & Clinical Safety Disclaimer</h3>
              <p className="text-xs sm:text-sm mt-1.5 opacity-90 leading-relaxed text-[var(--ink-foreground)]">
                Modulix is strictly a time-management, pacing velocity, and syllabus habit tracking tool. It is <strong>NOT a medical device, clinical diagnostic aid, or healthcare decision support system</strong>. It does not provide medical advice, patient diagnosis, clinical treatment plans, or dosage calculations. Never use Modulix for clinical decision-making or patient emergencies. Always consult licensed healthcare authorities for clinical practice.
              </p>
            </div>
          </div>
        </section>

        {/* Section 1: Non-Affiliation & Nominative Fair Use */}
        <section className="p-6 sm:p-7 rounded-2xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)]/40 shadow-sm">
          <div className="flex items-center gap-2.5 mb-2.5">
            <BookOpen size={18} className="text-[var(--accent)]" />
            <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)]">
              1. Nominative Fair Use & Third-Party Trademark Disclaimer
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed mb-3">
            Modulix references publicly known medical subject outlines, standard academic curriculum taxonomy, and topic structures (including those colloquially recognized in competitive medical test preparation frameworks). These references are made strictly under the doctrine of <strong>nominative fair use / fair reference</strong> solely to enable individual doctors and students to index their personal study pacing.
          </p>
          <div className="p-4 rounded-xl bg-[var(--scaffold-bg)] border border-[var(--border-subtle)] text-xs text-[var(--muted-text)] space-y-2">
            <p className="font-semibold text-[var(--ink-foreground)]">Strict Zero-Content Guarantee:</p>
            <p>
              Modulix does <strong>NOT</strong> host, reproduce, stream, scrape, store, transmit, or make available any copyrighted video lectures, audio recordings, proprietary question-bank test items, answer explanations, clinical slides, or study notes belonging to Marrow, PrepLadder, Cerebellum, DAMS, Bhatia, NBE, USMLE, First Aid, or any other commercial publisher.
            </p>
            <p>
              Modulix is completely independent. It is not affiliated with, endorsed by, sponsored by, or associated with any examination board (NBE, NMC, USMLE, NBME) or commercial test-preparation company. All third-party trademarks and brand names remain the property of their respective owners.
            </p>
          </div>
        </section>

        {/* Section 2: Examination Outcomes */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            2. Academic & Examination Outcome Disclaimer
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            All pacing velocities, daily completion targets, streak counters, and projected completion dates are computational estimates provided solely for personal discipline and self-motivation. The Developer makes no representation, warranty, or guarantee that using Modulix will lead to passing, qualifying, or achieving any specific mark, percentile, or rank in NEET-PG, INI-CET, FMGE, USMLE, PLAB, or any examination.
          </p>
        </section>

        {/* Section 3: Intellectual Property Protection */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            3. Intellectual Property Ownership & Prohibited Conduct
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed mb-3">
            All original source code, UI designs (including the Apple Glass Dock and Study Desk Clock), algorithms (habit streaks, Pomodoro pacing, medical career progression tier ladder), and Modulix branding are <strong>Copyright © 2024–2026 Modulix (RxREAPER). All rights reserved.</strong>
          </p>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            You expressly agree not to copy, reverse-engineer, decompile, resell, sublicense, scrape, redistribute, or create unauthorized derivative works based on the App or its proprietary design assets.
          </p>
        </section>

        {/* Section 4: Limitation of Liability */}
        <section className="p-6 sm:p-7 rounded-2xl border border-red-500/20 bg-red-500/5 text-red-950 dark:text-red-200">
          <div className="flex items-start gap-3">
            <ShieldAlert size={18} className="text-red-500 shrink-0 mt-0.5" />
            <div>
              <h2 className="font-editorial text-lg sm:text-xl font-bold text-red-700 dark:text-red-400">
                4. Total Limitation of Liability & Asset Shield
              </h2>
              <p className="text-xs sm:text-sm mt-1.5 opacity-90 leading-relaxed text-[var(--ink-foreground)]">
                To the fullest extent permitted by law, the solo developer and Modulix shall not be liable for any direct, indirect, incidental, special, or consequential damages (including loss of study records, hardware failure, battery depletion, or exam results). Under no circumstances shall legal recourse be sought against the personal assets, accounts, or estate of the individual solo developer. Maximum aggregate liability is strictly capped at zero dollars / rupees.
              </p>
            </div>
          </div>
        </section>

        {/* Section 5: Governing Law */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            5. Governing Law & Dispute Resolution
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            These Terms shall be governed by the laws of the Republic of India. Any controversy or dispute that cannot be resolved amicably within 30 days shall be resolved through arbitration under the Arbitration and Conciliation Act 1996 in New Delhi, India.
          </p>
        </section>

        {/* Section 6: Contact */}
        <section>
          <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)] mb-2.5">
            6. Contact & Inquiries
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            For questions regarding these Terms or the Modulix companion, contact:{" "}
            <a href="mailto:modulix.support@gmail.com" className="text-[var(--accent)] font-mono hover:underline">
              modulix.support@gmail.com
            </a>
          </p>
        </section>
      </div>
    </div>
  )
}

