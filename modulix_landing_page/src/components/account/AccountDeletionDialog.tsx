import * as Dialog from "@radix-ui/react-dialog"
import { useState } from "react"
import { ApplePressable } from "../primitives/ApplePressable"
import { deleteUserAccount } from "../../lib/supabase"
import { Trash2, X } from "lucide-react"

interface AccountDeletionDialogProps {
  userId: string
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
}

export function AccountDeletionDialog({
  userId,
  open,
  onOpenChange,
  onSuccess,
}: AccountDeletionDialogProps) {
  const [confirmText, setConfirmText] = useState("")
  const [deleting, setDeleting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleDelete = async () => {
    if (confirmText.toLowerCase() !== "delete") return
    try {
      setDeleting(true)
      setError(null)
      await deleteUserAccount(userId)
      onSuccess()
    } catch (err: unknown) {
      console.error(err)
      const message = err instanceof Error ? err.message : "Failed to purge account records."
      setError(message)
    } finally {
      setDeleting(false)
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 animate-fade-in" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[92vw] max-w-md bg-[var(--card-bg)] border border-[var(--border-subtle)] p-6 sm:p-7 rounded-2xl shadow-2xl z-50 text-[var(--ink-foreground)] focus:outline-none">
          <div className="flex items-center justify-between pb-3 border-b border-[var(--border-subtle)]">
            <Dialog.Title className="font-editorial text-xl font-bold text-rose-600 flex items-center gap-2">
              <Trash2 size={18} />
              <span>Permanent Account Erasure</span>
            </Dialog.Title>
            <Dialog.Close asChild>
              <button className="text-[var(--muted-text)] hover:text-[var(--ink-foreground)] transition-colors p-1">
                <X size={16} />
              </button>
            </Dialog.Close>
          </div>

          <Dialog.Description className="text-xs text-[var(--muted-text)] mt-3 leading-relaxed">
            This action permanently erases your Modulix cloud account, including your public profile, study milestones, synchronized time logs, and daily desk tasks.
          </Dialog.Description>

          <div className="my-4 p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/20 text-xs text-rose-700 dark:text-rose-300 leading-relaxed">
            <strong>Warning:</strong> This deletion cannot be reversed. Any study logs not exported to JSON will be lost forever. Local SQLite data on your physical device remains intact.
          </div>

          <div className="space-y-2">
            <label className="block text-xs font-semibold">
              Type <span className="font-mono text-rose-600 font-bold">DELETE</span> to confirm:
            </label>
            <input
              type="text"
              value={confirmText}
              onChange={(e) => setConfirmText(e.target.value)}
              placeholder="DELETE"
              className="w-full px-3.5 py-2.5 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] text-xs text-[var(--ink-foreground)] focus:outline-none focus:border-rose-500 transition-colors font-mono"
            />
          </div>

          {error && (
            <p className="mt-2 text-xs text-rose-600 font-medium">{error}</p>
          )}

          <div className="mt-6 flex items-center justify-end gap-2.5">
            <ApplePressable
              onClick={() => onOpenChange(false)}
              className="px-4 py-2.5 rounded-xl border border-[var(--border-subtle)] text-xs font-semibold text-[var(--muted-text)] hover:text-[var(--ink-foreground)]"
            >
              Cancel
            </ApplePressable>
            <ApplePressable
              onClick={handleDelete}
              disabled={confirmText.toLowerCase() !== "delete" || deleting}
              className="px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold flex items-center gap-1.5 disabled:opacity-40 shadow-sm"
            >
              <Trash2 size={13} />
              <span>{deleting ? "Purging Data..." : "Confirm & Delete Account"}</span>
            </ApplePressable>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
