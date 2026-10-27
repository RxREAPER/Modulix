import { useState, useEffect } from "react"
import { supabase } from "../../lib/supabase"
import { AuthGate } from "./AuthGate"
import { ProfileDashboard } from "./ProfileDashboard"
import { ManualDeleteForm } from "./ManualDeleteForm"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"
import { Shield, ArrowLeft, User, Trash2 } from "lucide-react"

export function AccountPortalView({ navigate }: { navigate: (route: string) => void }) {
  const [session, setSession] = useState<any>(null)
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
    <div className="py-8 max-w-2xl">
      <div className="mb-6">
        <ApplePressable
          onClick={() => navigate("#/")}
          className="text-xs font-semibold text-[var(--muted-text)] hover:text-[var(--accent)] flex items-center gap-1.5 py-1 mb-3"
        >
          <ArrowLeft size={14} />
          <span>Back to Overview</span>
        </ApplePressable>

        <div className="flex items-center gap-2 mb-2">
          <Shield size={18} className="text-[var(--accent)]" />
          <span className="text-xs font-semibold uppercase tracking-wider text-[var(--muted-text)]">
            User Privacy & Data Management Portal
          </span>
        </div>
        <h1 className="font-editorial text-3xl sm:text-4xl font-bold text-[var(--ink-foreground)]">
          Account & Cloud Data
        </h1>
        <p className="text-xs text-[var(--muted-text)] mt-1">
          Manage your cloud-synchronized study milestones, profile aliases, or execute account deletion.
        </p>
      </div>

      <HairlineDivider />

      {loading ? (
        <div className="py-12 text-center text-xs text-[var(--muted-text)]">
          Connecting to Supabase security service...
        </div>
      ) : session ? (
        <ProfileDashboard
          user={session.user}
          onSignedOut={() => setSession(null)}
        />
      ) : (
        <div className="space-y-6">
          {/* Sub-tabs: Instant Sign-In vs Manual Deletion */}
          <div className="flex border-b border-[var(--border-subtle)] text-xs font-semibold">
            <button
              onClick={() => setActiveTab("auth")}
              className={`pb-3 px-4 flex items-center gap-2 cursor-pointer border-b-2 transition-all ${
                activeTab === "auth"
                  ? "border-[var(--accent)] text-[var(--accent)]"
                  : "border-transparent text-[var(--muted-text)] hover:text-[var(--ink-foreground)]"
              }`}
            >
              <User size={14} />
              <span>Sign In to Manage Account</span>
            </button>
            <button
              onClick={() => setActiveTab("manual")}
              className={`pb-3 px-4 flex items-center gap-2 cursor-pointer border-b-2 transition-all ${
                activeTab === "manual"
                  ? "border-rose-500 text-rose-600"
                  : "border-transparent text-[var(--muted-text)] hover:text-rose-600"
              }`}
            >
              <Trash2 size={14} />
              <span>Manual Deletion Request (Play Store)</span>
            </button>
          </div>

          {activeTab === "auth" ? (
            <AuthGate onManualRequest={() => setActiveTab("manual")} />
          ) : (
            <ManualDeleteForm />
          )}
        </div>
      )}
    </div>
  )
}
