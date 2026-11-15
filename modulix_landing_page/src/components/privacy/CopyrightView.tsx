import { ArrowLeft, Copyright, ShieldCheck, FileText, Lock } from "lucide-react"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"

export function CopyrightView({ navigate }: { navigate: (route: string) => void }) {
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
            INTELLECTUAL PROPERTY & FAIR USE
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-5xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Copyright & IP Notice
        </h1>
        <p className="text-xs font-mono text-[var(--muted-text)] mt-2 flex flex-wrap items-center gap-2">
          <span>Copyright © 2024–2026 Modulix</span>
          <span className="opacity-40">·</span>
          <span>All Rights Reserved</span>
          <span className="opacity-40">·</span>
          <span>Author: RxREAPER</span>
        </p>
      </div>

      <HairlineDivider />

      <div className="space-y-10 my-10 text-sm text-[var(--ink-foreground)] leading-relaxed">
        {/* Ownership Hero Callout */}
        <section className="p-6 sm:p-7 rounded-2xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)]/50 shadow-sm">
          <div className="flex items-start gap-3">
            <Copyright size={20} className="text-[var(--accent)] shrink-0 mt-0.5" />
            <div>
              <h3 className="font-editorial text-lg font-bold">Copyright Statement</h3>
              <p className="text-xs sm:text-sm mt-1.5 opacity-90 leading-relaxed text-[var(--ink-foreground)]">
                The Modulix application, website, source code, UI designs, and algorithms are original works of authorship owned exclusively by <strong>Modulix (RxREAPER)</strong>. Protected under the Indian Copyright Act 1957, Information Technology Act 2000, Trade Marks Act 1999, and international treaties including the Berne Convention and TRIPS.
              </p>
            </div>
          </div>
        </section>

        {/* Section 1: Scope of Protected Works */}
        <section>
          <div className="flex items-center gap-2.5 mb-2.5">
            <Lock size={18} className="text-[var(--accent)]" />
            <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)]">
              1. Scope of Protected Original Works
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed mb-3">
            The following original elements are proprietary and protected against unauthorized reproduction or redistribution:
          </p>
          <ul className="space-y-2.5 text-xs sm:text-sm text-[var(--muted-text)]">
            <li className="flex items-start gap-2.5">
              <span className="text-[var(--accent)] font-bold mt-0.5">•</span>
              <span><strong>Source Code:</strong> All Flutter/Dart and web codebase implementations, state architecture, and offline SQLite synchronization protocols.</span>
            </li>
            <li className="flex items-start gap-2.5">
              <span className="text-[var(--accent)] font-bold mt-0.5">•</span>
              <span><strong>Visual & Interface Design:</strong> Proprietary UI components including the Apple Glass Floating Dock, Study Desk Clock, Editorial Podium, and tactile interactive sheet layouts.</span>
            </li>
            <li className="flex items-start gap-2.5">
              <span className="text-[var(--accent)] font-bold mt-0.5">•</span>
              <span><strong>Algorithms:</strong> Habit streak calculations, Pomodoro session state machine, and the 10-tier medical progression career ladder.</span>
            </li>
            <li className="flex items-start gap-2.5">
              <span className="text-[var(--accent)] font-bold mt-0.5">•</span>
              <span><strong>Branding & Mark:</strong> The "Modulix" brand name, monogram, and identity assets.</span>
            </li>
          </ul>
        </section>

        {/* Section 2: Fair Use Statement */}
        <section className="p-6 sm:p-7 rounded-2xl border border-emerald-500/20 bg-emerald-500/5 text-emerald-950 dark:text-emerald-200">
          <div className="flex items-start gap-3">
            <ShieldCheck size={20} className="text-emerald-600 shrink-0 mt-0.5" />
            <div>
              <h2 className="font-editorial text-lg sm:text-xl font-bold text-emerald-800 dark:text-emerald-300">
                2. Nominative Fair Use & Zero-Piracy Guarantee
              </h2>
              <p className="text-xs sm:text-sm mt-2 opacity-90 leading-relaxed text-[var(--ink-foreground)]">
                Modulix references standard medical curriculum topic indices solely under the doctrine of fair use for personal study tracking. 
              </p>
              <div className="mt-3 p-3.5 rounded-xl bg-[var(--scaffold-bg)] border border-emerald-500/20 text-xs text-[var(--muted-text)] space-y-1.5">
                <p>• Modulix does <strong>NOT</strong> host, stream, scrape, or distribute any proprietary video lectures or question bank content from Marrow, PrepLadder, Cerebellum, DAMS, Bhatia, NBE, or USMLE.</p>
                <p>• All third-party trademarks and exam brand names belong entirely to their respective trademark holders.</p>
              </div>
            </div>
          </div>
        </section>

        {/* Section 3: Prohibited Acts */}
        <section>
          <div className="flex items-center gap-2.5 mb-2.5">
            <FileText size={18} className="text-[var(--accent)]" />
            <h2 className="font-editorial text-xl sm:text-2xl font-bold text-[var(--ink-foreground)]">
              3. Strictly Prohibited Conduct
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed mb-3">
            Without prior explicit written permission from the Developer, you are strictly prohibited from:
          </p>
          <ul className="space-y-2 text-xs sm:text-sm text-[var(--muted-text)]">
            <li>(a) Decompiling, reverse engineering, or extracting proprietary source code or schemas.</li>
            <li>(b) Re-packaging, reselling, or commercially sub-licensing the APK or web application.</li>
            <li>(c) Copying the proprietary Apple Glass dock or Study Desk clock design for competing commercial products.</li>
            <li>(d) Misrepresenting an unauthorized fork as an official Modulix distribution.</li>
          </ul>
        </section>

        {/* Section 4: Infringement / Takedown Notice */}
        <section className="p-6 sm:p-7 rounded-2xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)]/30">
          <h2 className="font-editorial text-lg font-bold text-[var(--ink-foreground)] mb-2">
            4. Intellectual Property & DMCA Inquiries
          </h2>
          <p className="text-xs sm:text-sm text-[var(--muted-text)] leading-relaxed">
            If you are a copyright owner or authorized representative who believes in good faith that any content or index inside Modulix infringes your rights, please submit a notice to our dedicated inbox:
          </p>
          <div className="mt-3 inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[var(--scaffold-bg)] border border-[var(--border-subtle)] text-xs font-mono font-medium text-[var(--accent)]">
            modulix.support@gmail.com
          </div>
          <p className="text-xs text-[var(--muted-text)] mt-2">
            All legitimate notices are addressed promptly and amicably in accordance with applicable copyright laws.
          </p>
        </section>
      </div>
    </div>
  )
}
