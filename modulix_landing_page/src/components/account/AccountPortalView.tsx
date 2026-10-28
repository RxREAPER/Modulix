import { useState, useEffect } from "react"
import { Session } from "@supabase/supabase-js"
import { supabase } from "../../lib/supabase"
import { AuthGate } from "./AuthGate"
import { ProfileDashboard } from "./ProfileDashboard"
import { ManualDeleteForm } from "./ManualDeleteForm"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"
import { Shield, ArrowLeft, User, Trash2 } from "lucide-react"

export function AccountPortalView({ navigate }: { navigate: (route: string) => void }) {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<"auth" | "manual">("auth")

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setLoading(false)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [])

  return (
    <div className="py-10 sm:py-16 max-w-2xl mx-auto">
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
          <Shield size={16} className="text-[var(--accent)]" />
          <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
            PRIVACY & CLOUD SYNC PORTAL
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-5xl font-bold tracking-tight text-[var(--ink-foreground)]">
          Account & Cloud Data
        </h1>
        <p className="text-xs sm:text-sm text-[var(--muted-text)] mt-2 leading-relaxed max-w-lg">
          Manage your cloud-synchronized study milestones, clinical profile aliases, or execute account records erasure.
        </p>
      </div>

      <HairlineDivider />

      <div className="mt-8">
        {loading ? (
          <div className="py-16 text-center space-y-3">
            <div className="w-6 h-6 border-2 border-[var(--accent)] border-t-transparent rounded-full animate-spin mx-auto" />
            <p className="text-xs text-[var(--muted-text)] font-mono">
              Connecting to Supabase security service...
            </p>
          </div>
        ) : session ? (
          <ProfileDashboard
            user={session.user}
            onSignedOut={() => setSession(null)}
          />
        ) : (
          <div className="space-y-8">
            {/* ── Modern Animated Capsule Tab Switcher ── */}
            <div className="p-1 rounded-xl bg-[var(--surface-subtle)] border border-[var(--border-subtle)] flex items-center gap-1 max-w-md mx-auto">
              <button
                onClick={() => setActiveTab("auth")}
                className={`relative flex-1 py-2 px-3 rounded-lg text-xs font-semibold flex items-center justify-center gap-2 transition-colors cursor-pointer ${
                  activeTab === "auth"
                    ? "text-[var(--ink-foreground)] shadow-sm bg-[var(--card-bg)]"
                    : "text-[var(--muted-text)] hover:text-[var(--ink-foreground)]"
                }`}
              >
                <User size={13} className={activeTab === "auth" ? "text-[var(--accent)]" : "text-[var(--muted-text)]"} />
                <span>Sign In to Manage</span>
              </button>

              <button
                onClick={() => setActiveTab("manual")}
                className={`relative flex-1 py-2 px-3 rounded-lg text-xs font-semibold flex items-center justify-center gap-2 transition-colors cursor-pointer ${
                  activeTab === "manual"
                    ? "text-rose-600 shadow-sm bg-[var(--card-bg)]"
                    : "text-[var(--muted-text)] hover:text-rose-600"
                }`}
              >
                <Trash2 size={13} className={activeTab === "manual" ? "text-rose-600" : "text-[var(--muted-text)]"} />
                <span>Manual Erasure</span>
              </button>
            </div>

            {/* ── Card Container ── */}
            <div className="rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)] p-6 sm:p-8 shadow-sm">
              {activeTab === "auth" ? (
                <AuthGate onManualRequest={() => setActiveTab("manual")} />
              ) : (
                <ManualDeleteForm />
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
