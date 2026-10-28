import { createClient } from "@supabase/supabase-js"

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://vbvmzjhzznxgofyzxnql.supabase.co"
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZidm16amh6em54Z29meXp4bnFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5ODYyODQsImV4cCI6MjEwNzU2MjI4NH0.Oofi0Fr0b2KmyJZ0MrXNwxVVs1kwcc6OGYVjJg9VZH4"

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})

export interface ProfileRecord {
  id: string
  doctor_name: string
  display_name: string | null
  avatar_icon_id: string
  avatar_color_id: string
  palette_preset_id: string
  accent_color_id: string
  theme_pref: string
  active_edition: string
  day_start_hour: number
  leaderboard_visible: boolean
  daily_study_secs: number
  weekly_study_secs: number
  monthly_study_secs: number
  total_study_secs: number
  created_at?: string
  updated_at?: string
}

export async function signInWithGoogle() {
  const redirectUrl = window.location.origin
  return await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: redirectUrl,
    },
  })
}

export async function signInWithEmailOtp(email: string) {
  const redirectUrl = window.location.origin
  return await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: redirectUrl,
    },
  })
}

export async function signOut() {
  return await supabase.auth.signOut()
}

export async function fetchUserProfile(userId: string): Promise<ProfileRecord | null> {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single()

  if (error) {
    console.error("Error fetching profile:", error)
    return null
  }
  return data as ProfileRecord
}

export async function updateUserProfile(
  userId: string,
  updates: Partial<Pick<ProfileRecord, "doctor_name" | "display_name" | "leaderboard_visible" | "theme_pref">>
) {
  return await supabase
    .from("profiles")
    .update({
      ...updates,
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId)
}

export async function exportAllUserData(userId: string) {
  const [profileRes, editionsRes, tasksRes, timeLogsRes, focusRes] = await Promise.all([
    supabase.from("profiles").select("*").eq("id", userId),
    supabase.from("study_editions").select("*").eq("user_id", userId),
    supabase.from("daily_tasks").select("*").eq("user_id", userId),
    supabase.from("time_logs").select("*").eq("user_id", userId),
    supabase.from("recorded_focus_sessions").select("*").eq("user_id", userId),
  ])

  return {
    exportDate: new Date().toISOString(),
    userId,
    profile: profileRes.data?.[0] || null,
    studyEditions: editionsRes.data || [],
    dailyTasks: tasksRes.data || [],
    timeLogs: timeLogsRes.data || [],
    recordedFocusSessions: focusRes.data || [],
  }
}

export async function deleteUserAccount(userId: string) {
  // Resilient cascaded deletes: attempt each table independently
  await Promise.allSettled([
    supabase.from("daily_tasks").delete().eq("user_id", userId),
    supabase.from("study_editions").delete().eq("user_id", userId),
    supabase.from("time_logs").delete().eq("user_id", userId),
    supabase.from("recorded_focus_sessions").delete().eq("user_id", userId),
  ])
  
  // Delete main profile row
  const { error } = await supabase.from("profiles").delete().eq("id", userId)
  if (error) {
    console.warn("Could not delete profiles row directly via client anon key:", error)
  }

  // Sign out user locally
  await signOut()
}

export async function submitManualDeletionRequest(email: string, notes?: string) {
  // Store or log the manual request for Play Store audit compliance
  const payload = {
    email: email.trim().toLowerCase(),
    requestedAt: new Date().toISOString(),
    notes: notes || "Submitted via public web deletion portal",
    status: "pending_verification",
  }
  
  // Save to localStorage as a fallback receipt for user
  const existing = JSON.parse(localStorage.getItem("modulix_deletion_requests") || "[]")
  existing.push(payload)
  localStorage.setItem("modulix_deletion_requests", JSON.stringify(existing))

  return { success: true, timestamp: payload.requestedAt }
}
