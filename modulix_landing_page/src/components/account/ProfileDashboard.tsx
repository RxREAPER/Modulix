import { useState, useEffect } from "react"
import { User } from "@supabase/supabase-js"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"
import { AccountDeletionDialog } from "./AccountDeletionDialog"
import {
  ProfileRecord,
  fetchUserProfile,
  updateUserProfile,
  exportAllUserData,
  signOut,
} from "../../lib/supabase"
import { Download, Trash2, LogOut, Save, Eye, EyeOff, Check } from "lucide-react"

interface ProfileDashboardProps {
  user: User
  onSignedOut: () => void
}

export function ProfileDashboard({ user, onSignedOut }: ProfileDashboardProps) {
  const [profile, setProfile] = useState<ProfileRecord | null>(null)
  const [doctorName, setDoctorName] = useState("")
  const [displayName, setDisplayName] = useState("")
  const [leaderboardVisible, setLeaderboardVisible] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saveSuccess, setSaveSuccess] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [exporting, setExporting] = useState(false)
  const [exportError, setExportError] = useState<string | null>(null)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)

  useEffect(() => {
    async function load() {
      const data = await fetchUserProfile(user.id)
      if (data) {
        setProfile(data)
        setDoctorName(data.doctor_name || "")
        setDisplayName(data.display_name || "")
        setLeaderboardVisible(data.leaderboard_visible ?? true)
      } else {
        setDoctorName(user.user_metadata?.full_name || "Doctor")
      }
    }
    load()
  }, [user.id, user.user_metadata?.full_name])

  const handleSaveProfile = async () => {
    setSaving(true)
    setSaveError(null)
    try {
      const { error } = await updateUserProfile(user.id, {
        doctor_name: doctorName.trim(),
        display_name: displayName.trim() || null,
        leaderboard_visible: leaderboardVisible,
      })
      if (error) throw error
      setSaveSuccess(true)
      setTimeout(() => setSaveSuccess(false), 2500)
    } catch (err: unknown) {
      console.error(err)
      const msg = err instanceof Error ? err.message : "Failed to update profile changes."
      setSaveError(msg)
    } finally {
      setSaving(false)
    }
  }

  const handleExportData = async () => {
    setExporting(true)
    setExportError(null)
    try {
      const data = await exportAllUserData(user.id)
      const blob = new Blob([JSON.stringify(data, null, 2)], {
        type: "application/json",
      })
      const url = URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `modulix_data_export_${new Date().toISOString().split("T")[0]}.json`
      a.click()
      URL.revokeObjectURL(url)
    } catch (err: unknown) {
      console.error(err)
      const msg = err instanceof Error ? err.message : "Failed to generate JSON archive."
      setExportError(msg)
    } finally {
      setExporting(false)
    }
  }

  const formatHours = (secs: number) => {
    const hours = (secs / 3600).toFixed(1)
    return `${hours} hrs`
  }

  return (
    <div className="space-y-8 select-none">
      {/* ── Header with Doctor Profile Alias & Sign Out ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-[var(--border-subtle)]">
        <div className="flex items-center gap-3.5">
          <div className="w-12 h-12 rounded-2xl bg-[var(--surface-subtle)] border border-[var(--border-subtle)] text-[var(--accent)] flex items-center justify-center font-editorial font-bold text-xl shadow-sm">
            Dr
          </div>
          <div>
            <div className="font-editorial text-xl font-bold text-[var(--ink-foreground)]">
              {doctorName ? `Dr. ${doctorName}` : user.email}
            </div>
            <div className="text-xs text-[var(--muted-text)] font-mono">{user.email}</div>
          </div>
        </div>

        <ApplePressable
          onClick={async () => {
            await signOut()
            onSignedOut()
          }}
          className="self-start sm:self-center px-3.5 py-2 rounded-xl border border-[var(--border-subtle)] text-xs font-semibold text-[var(--muted-text)] hover:text-rose-600 flex items-center gap-1.5 transition-colors shadow-sm"
        >
          <LogOut size={13} />
          <span>Sign Out</span>
        </ApplePressable>
      </div>

      {/* ── Profile Configuration Form ── */}
      <div className="space-y-5">
        <div className="flex items-center gap-2">
          <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
            PROFILE ALIASES & IDENTITY
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-[var(--ink-foreground)] mb-1.5">
              Doctor Title / Surname
            </label>
            <input
              type="text"
              value={doctorName}
              onChange={(e) => setDoctorName(e.target.value)}
              placeholder="e.g. Safi"
              className="w-full px-4 py-3 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] focus:bg-[var(--card-bg)] text-xs sm:text-sm text-[var(--ink-foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 focus:border-[var(--accent)] transition-all"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-[var(--ink-foreground)] mb-1.5">
              Public Alias (Leaderboard)
            </label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="e.g. NeuroIntern"
              className="w-full px-4 py-3 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] focus:bg-[var(--card-bg)] text-xs sm:text-sm text-[var(--ink-foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 focus:border-[var(--accent)] transition-all"
            />
          </div>
        </div>

        {/* Leaderboard Visibility Switch */}
        <div className="p-4 rounded-2xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] flex items-center justify-between">
          <div className="flex items-center gap-3">
            {leaderboardVisible ? (
              <Eye size={18} className="text-[var(--accent)]" />
            ) : (
              <EyeOff size={18} className="text-[var(--muted-text)]" />
            )}
            <div>
              <div className="text-xs font-semibold text-[var(--ink-foreground)]">
                Community Leaderboard Visibility
              </div>
              <div className="text-[11px] text-[var(--muted-text)] mt-0.5">
                {leaderboardVisible
                  ? "Your study hours are displayed on competitive leaderboards."
                  : "Your study hours are strictly private and hidden."}
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setLeaderboardVisible(!leaderboardVisible)}
            className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${
              leaderboardVisible ? "bg-[var(--accent)]" : "bg-neutral-300 dark:bg-neutral-700"
            }`}
          >
            <span
              className={`block w-4 h-4 rounded-full bg-white transition-transform ${
                leaderboardVisible ? "translate-x-6" : "translate-x-1"
              }`}
            />
          </button>
        </div>

        {saveError && (
          <div className="p-3 rounded-xl text-xs bg-rose-500/10 border border-rose-500/20 text-rose-600 leading-relaxed">
            {saveError}
          </div>
        )}

        <div className="flex justify-end pt-1">
          <ApplePressable
            onClick={handleSaveProfile}
            disabled={saving}
            className="px-5 py-2.5 rounded-xl bg-[var(--accent)] text-white text-xs font-semibold flex items-center gap-2 shadow-sm"
          >
            {saveSuccess ? <Check size={14} /> : <Save size={14} />}
            <span>{saving ? "Saving..." : saveSuccess ? "Saved Successfully" : "Save Changes"}</span>
          </ApplePressable>
        </div>
      </div>

      <HairlineDivider />

      {/* ── Cloud Study Aggregates (Editorial Stat Chips) ── */}
      {profile && (
        <div className="space-y-4">
          <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--accent)] uppercase">
            CLOUD STUDY METRICS
          </span>
          <div className="grid grid-cols-3 gap-3 sm:gap-4">
            <div className="p-4 rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)] text-center shadow-sm">
              <div className="font-mono text-[10px] uppercase tracking-wider text-[var(--muted-text)]">Today</div>
              <div className="font-editorial text-2xl sm:text-3xl font-bold text-[var(--ink-foreground)] mt-1">
                {formatHours(profile.daily_study_secs || 0)}
              </div>
            </div>
            <div className="p-4 rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)] text-center shadow-sm">
              <div className="font-mono text-[10px] uppercase tracking-wider text-[var(--muted-text)]">This Week</div>
              <div className="font-editorial text-2xl sm:text-3xl font-bold text-[var(--ink-foreground)] mt-1">
                {formatHours(profile.weekly_study_secs || 0)}
              </div>
            </div>
            <div className="p-4 rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)] text-center shadow-sm">
              <div className="font-mono text-[10px] uppercase tracking-wider text-[var(--muted-text)]">All-Time</div>
              <div className="font-editorial text-2xl sm:text-3xl font-bold text-[var(--ink-foreground)] mt-1">
                {formatHours(profile.total_study_secs || 0)}
              </div>
            </div>
          </div>
        </div>
      )}

      <HairlineDivider />

      {/* ── GDPR Data Portability & Account Erasure ── */}
      <div className="space-y-4">
        <span className="font-mono text-[10px] font-bold tracking-widest text-[var(--muted-text)] uppercase">
          DATA MANAGEMENT & PRIVACY
        </span>

        {exportError && (
          <div className="p-3 rounded-xl text-xs bg-rose-500/10 border border-rose-500/20 text-rose-600">
            {exportError}
          </div>
        )}

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 p-5 rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)] shadow-sm">
          <div>
            <div className="text-xs sm:text-sm font-semibold text-[var(--ink-foreground)]">
              Export Study Archive (GDPR Portability)
            </div>
            <div className="text-xs text-[var(--muted-text)] mt-0.5">
              Download complete JSON archive of all cloud study milestones and logs.
            </div>
          </div>
          <ApplePressable
            onClick={handleExportData}
            disabled={exporting}
            className="px-4 py-2.5 rounded-xl border border-[var(--border-subtle)] text-xs font-semibold text-[var(--ink-foreground)] flex items-center justify-center gap-1.5 shadow-sm"
          >
            <Download size={14} />
            <span>{exporting ? "Generating JSON..." : "Download Archive"}</span>
          </ApplePressable>
        </div>

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 p-5 rounded-2xl border border-rose-500/20 bg-rose-500/5">
          <div>
            <div className="text-xs sm:text-sm font-semibold text-rose-600">
              Permanently Delete Modulix Account
            </div>
            <div className="text-xs text-[var(--muted-text)] mt-0.5">
              Permanently purges profile, syllabus milestones, and focus records from cloud.
            </div>
          </div>
          <ApplePressable
            onClick={() => setDeleteDialogOpen(true)}
            className="px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold flex items-center justify-center gap-1.5 shadow-sm"
          >
            <Trash2 size={14} />
            <span>Delete Account</span>
          </ApplePressable>
        </div>
      </div>

      <AccountDeletionDialog
        userId={user.id}
        open={deleteDialogOpen}
        onOpenChange={setDeleteDialogOpen}
        onSuccess={() => {
          setDeleteDialogOpen(false)
          onSignedOut()
        }}
      />
    </div>
  )
}
