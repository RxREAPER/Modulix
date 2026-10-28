import { useState } from "react"
import { ApplePressable } from "../primitives/ApplePressable"
import { submitManualDeletionRequest } from "../../lib/supabase"
import { Trash2, CheckCircle2, AlertTriangle } from "lucide-react"

export function ManualDeleteForm() {
  const [email, setEmail] = useState("")
  const [notes, setNotes] = useState("")
  const [submitting, setSubmitting] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [receiptDate, setReceiptDate] = useState("")
  const [ticketId, setTicketId] = useState<string | undefined>()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email || !email.includes("@")) return
    setSubmitting(true)
    try {
      const res = await submitManualDeletionRequest(email, notes)
      setSubmitted(true)
      setReceiptDate(res.timestamp)
      setTicketId(res.ticketId)
    } catch (err) {
      console.error(err)
    } finally {
      setSubmitting(false)
    }
  }

  if (submitted) {
    return (
      <div className="p-6 rounded-xl border border-emerald-500/20 bg-emerald-500/5 text-emerald-900 dark:text-emerald-200">
        <div className="flex items-start gap-3">
          <CheckCircle2 size={20} className="text-emerald-500 shrink-0 mt-0.5" />
          <div className="space-y-1.5 flex-1">
            <h3 className="font-semibold text-sm">Deletion Request Received</h3>
            <p className="text-xs opacity-90 leading-relaxed">
              Your request to purge account <strong>{email}</strong> and all cloud study records was logged on <strong>{new Date(receiptDate).toLocaleString()}</strong>.
            </p>
            {ticketId && (
              <p className="text-[11px] font-mono text-emerald-700 dark:text-emerald-300 bg-emerald-500/10 px-2 py-1 rounded w-fit border border-emerald-500/20">
                Ticket ID: {ticketId}
              </p>
            )}
            <p className="text-xs opacity-80 pt-1">
              Any active Supabase cloud records linked to this email address will be deleted. Local device records on your phone will remain until uninstalled.
            </p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="p-4 rounded-xl border border-amber-500/20 bg-amber-500/5 text-amber-900 dark:text-amber-200 text-xs leading-relaxed">
        <div className="flex items-start gap-2.5">
          <AlertTriangle size={16} className="text-amber-500 shrink-0 mt-0.5" />
          <span>
            Google Play Account Erasure: If you uninstalled the app or lost access to your device, you can request full erasure of your cloud account using this form.
          </span>
        </div>
      </div>

      <div>
        <label className="block text-xs font-semibold text-[var(--ink-foreground)] mb-1.5">
          Registered Account Email *
        </label>
        <input
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="doctor@hospital.edu"
          className="w-full px-4 py-3 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] focus:bg-[var(--card-bg)] text-xs sm:text-sm text-[var(--ink-foreground)] focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 transition-all font-mono"
        />
      </div>

      <div>
        <label className="block text-xs font-semibold text-[var(--ink-foreground)] mb-1.5">
          Additional Notes (Optional)
        </label>
        <textarea
          rows={3}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="e.g. Please purge all synced time logs and daily tasks from Supabase."
          className="w-full px-4 py-3 rounded-xl border border-[var(--border-subtle)] bg-[var(--surface-subtle)] focus:bg-[var(--card-bg)] text-xs sm:text-sm text-[var(--ink-foreground)] focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 transition-all resize-none"
        />
      </div>

      <ApplePressable
        type="submit"
        disabled={submitting || !email}
        className="w-full py-3 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-semibold text-xs sm:text-sm flex items-center justify-center gap-2 shadow-sm"
      >
        <Trash2 size={14} />
        <span>{submitting ? "Submitting Request..." : "Submit Account Erasure Request"}</span>
      </ApplePressable>
    </form>
  )
}
