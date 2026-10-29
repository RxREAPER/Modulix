import { useState } from "react"
import { User } from "@supabase/supabase-js"
import { ApplePressable } from "../primitives/ApplePressable"
import { HairlineDivider } from "../primitives/HairlineDivider"
import { AccountDeletionDialog } from "./AccountDeletionDialog"
import { exportAllUserData, signOut } from "../../lib/supabase"
import { Download, Trash2, LogOut, ShieldAlert } from "lucide-react"

interface ProfileDashboardProps {
  user: User
  onSignedOut: () => void
}

export function ProfileDashboard({ user, onSignedOut }: ProfileDashboardProps) {
  const [exporting, setExporting] = useState(false)
  const [exportError, setExportError] = useState<string | null>(null)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)

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

  return (
    <div className="space-y-6 select-none">
      {/* ── User Header & Sign Out ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-5 border-b border-[var(--border-subtle)]">
        <div>
          <div className="font-editorial text-lg sm:text-xl font-bold text-[var(--ink-foreground)]">
            Authenticated Account
          </div>
          <div className="text-xs text-[var(--muted-text)] font-mono mt-0.5">{user.email}</div>
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

      {/* ── Deletion Notice & Action ── */}
      <div className="space-y-4">
        <div className="p-4 rounded-xl border border-amber-500/20 bg-amber-500/5 text-amber-800 dark:text-amber-300 text-xs leading-relaxed flex items-start gap-3">
          <ShieldAlert size={18} className="shrink-0 mt-0.5 text-amber-600" />
          <div>
            Account deletion is irreversible. Purging your account will immediately remove all cloud-synchronized syllabus completions, desk tasks, focus session logs, and leaderboard profile records from our servers.
          </div>
        </div>

        {exportError && (
          <div className="p-3 rounded-xl text-xs bg-rose-500/10 border border-rose-500/20 text-rose-600">
            {exportError}
          </div>
        )}

        {/* Export Data Archive */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 p-5 rounded-2xl border border-[var(--border-subtle)] bg-[var(--card-bg)] shadow-sm">
          <div>
            <div className="text-xs sm:text-sm font-semibold text-[var(--ink-foreground)]">
              Download Personal Data Archive
            </div>
            <div className="text-xs text-[var(--muted-text)] mt-0.5">
              Export a complete JSON archive of all your cloud milestones before deletion.
            </div>
          </div>
          <ApplePressable
            onClick={handleExportData}
            disabled={exporting}
            className="px-4 py-2.5 rounded-xl border border-[var(--border-subtle)] text-xs font-semibold text-[var(--ink-foreground)] flex items-center justify-center gap-1.5 shadow-sm"
          >
            <Download size={14} />
            <span>{exporting ? "Generating..." : "Download JSON"}</span>
          </ApplePressable>
        </div>

        <HairlineDivider />

        {/* Permanent Account Deletion Action */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 p-5 rounded-2xl border border-rose-500/20 bg-rose-500/5">
          <div>
            <div className="text-xs sm:text-sm font-semibold text-rose-600">
              Permanently Erase Cloud Account & Records
            </div>
            <div className="text-xs text-[var(--muted-text)] mt-0.5">
              Fulfills Google Play Store & Apple App Store account and cloud data deletion mandates.
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
