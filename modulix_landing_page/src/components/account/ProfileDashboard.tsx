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
    <div className="space-y-6">
      {/* Header with User Info */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[var(--border-subtle)]">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-[var(--accent-subtle)] text-[var(--accent)] flex items-center justify-center font-bold text-sm">
            Dr
          </div>
          <div>
            <div className="font-semibold text-sm text-[var(--ink-foreground)]">
              {doctorName ? `Dr. ${doctorName}` : user.email}
            </div>
            <div className="text-xs text-[var(--muted-text)]">{user.email}</div>
          </div>
        </div>

        <ApplePressable
          onClick={async () => {
            await signOut()
            onSignedOut()
          }}
          className="self-start sm:self-center px-3 py-1.5 rounded-lg border border-[var(--border-subtle)] text-xs text-[var(--muted-text)] hover:text-rose-600 flex items-center gap-1.5"
        >
          <LogOut size={13} />
          <span>Sign Out</span>
        </ApplePressable>
      </div>

      {/* Profile Form */}
      <div className="space-y-4">
        <h3 className="text-xs font-semibold uppercase tracking-wider text-[var(--muted-text)]">
          Profile & Personalization
        </h3>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-medium text-[var(--ink-foreground)] mb-1">
              Doctor Title / Surname
            </label>
            <input
              type="text"
              value={doctorName}
              onChange={(e) => setDoctorName(e.target.value)}
              placeholder="e.g. Safi"
              className="w-full px-3 py-2 rounded-lg border border-[var(--border-subtle)] bg-[var(--card-bg)] text-xs text-[var(--ink-foreground)] focus:outline-none focus:border-[var(--accent)]"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-[var(--ink-foreground)] mb-1">
              Public Alias (Leaderboard)
            </label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="e.g. NeuroIntern"
              className="w-full px-3 py-2 rounded-lg border border-[var(--border-subtle)] bg-[var(--card-bg)] text-xs text-[var(--ink-foreground)] focus:outline-none focus:border-[var(--accent)]"
            />
          </div>
        </div>

        {/* Leaderboard Visibility Switch */}
        <div className="p-3.5 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            {leaderboardVisible ? (
              <Eye size={16} className="text-[var(--accent)]" />
            ) : (
              <EyeOff size={16} className="text-[var(--muted-text)]" />
            )}
            <div>
              <div className="text-xs font-semibold text-[var(--ink-foreground)]">
                Community Leaderboard Visibility
              </div>
              <div className="text-[11px] text-[var(--muted-text)]">
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
          <div className="p-2.5 rounded-lg text-xs bg-rose-500/10 border border-rose-500/20 text-rose-600">
            {saveError}
          </div>
        )}

        <div className="flex justify-end">
          <ApplePressable
            onClick={handleSaveProfile}
            disabled={saving}
            className="px-4 py-2 rounded-lg bg-[var(--accent)] text-white text-xs font-semibold flex items-center gap-1.5"
          >
            {saveSuccess ? <Check size={13} /> : <Save size={13} />}
            <span>{saving ? "Saving..." : saveSuccess ? "Saved Successfully" : "Save Changes"}</span>
          </ApplePressable>
        </div>
      </div>

      <HairlineDivider />

      {/* Cloud Study Aggregates */}
      {profile && (
        <div className="space-y-3">
          <h3 className="text-xs font-semibold uppercase tracking-wider text-[var(--muted-text)]">
            Cloud Study Metrics
          </h3>
          <div className="grid grid-cols-3 gap-3">
            <div className="p-3 rounded-lg border border-[var(--border-subtle)] bg-[var(--card-bg)]">
              <div className="text-[11px] text-[var(--muted-text)]">Today</div>
              <div className="text-sm font-semibold text-[var(--ink-foreground)] mt-0.5">
                {formatHours(profile.daily_study_secs || 0)}
              </div>
            </div>
            <div className="p-3 rounded-lg border border-[var(--border-subtle)] bg-[var(--card-bg)]">
              <div className="text-[11px] text-[var(--muted-text)]">This Week</div>
              <div className="text-sm font-semibold text-[var(--ink-foreground)] mt-0.5">
                {formatHours(profile.weekly_study_secs || 0)}
              </div>
            </div>
            <div className="p-3 rounded-lg border border-[var(--border-subtle)] bg-[var(--card-bg)]">
              <div className="text-[11px] text-[var(--muted-text)]">All-Time</div>
              <div className="text-sm font-semibold text-[var(--ink-foreground)] mt-0.5">
                {formatHours(profile.total_study_secs || 0)}
              </div>
            </div>
          </div>
        </div>
      )}

      <HairlineDivider />

      {/* GDPR Data Portability & Account Deletion */}
      <div className="space-y-4">
        <h3 className="text-xs font-semibold uppercase tracking-wider text-[var(--muted-text)]">
          Data Management & Account Deletion
        </h3>

        {exportError && (
          <div className="p-2.5 rounded-lg text-xs bg-rose-500/10 border border-rose-500/20 text-rose-600">
            {exportError}
          </div>
        )}

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 p-4 rounded-xl border border-[var(--border-subtle)] bg-[var(--card-bg)]">
          <div>
            <div className="text-xs font-semibold text-[var(--ink-foreground)]">
              Export All Study Data (GDPR Portability)
            </div>
            <div className="text-[11px] text-[var(--muted-text)]">
              Download a complete JSON archive of all your cloud-synced study milestones.
            </div>
          </div>
          <ApplePressable
            onClick={handleExportData}
            disabled={exporting}
            className="px-3.5 py-2 rounded-lg border border-[var(--border-subtle)] text-xs font-semibold text-[var(--ink-foreground)] flex items-center justify-center gap-1.5"
          >
            <Download size={13} />
            <span>{exporting ? "Generating JSON..." : "Download JSON Archive"}</span>
          </ApplePressable>
        </div>

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 p-4 rounded-xl border border-rose-500/20 bg-rose-500/5">
          <div>
            <div className="text-xs font-semibold text-rose-600">
              Permanently Delete Modulix Account
            </div>
            <div className="text-[11px] text-[var(--muted-text)]">
              Purges profile, syllabus milestones, and focus records from Supabase.
            </div>
          </div>
          <ApplePressable
            onClick={() => setDeleteDialogOpen(true)}
            className="px-3.5 py-2 rounded-lg bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold flex items-center justify-center gap-1.5"
          >
            <Trash2 size={13} />
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
