-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 008_account_deletion_requests_and_advisor_hardening.sql
-- Compliance table for Play Store/GDPR erasures & Security Advisor Hardening
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. CREATE COMPLIANCE TABLE: account_deletion_requests
create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  notes text,
  status text not null default 'pending',
  requested_at timestamp with time zone not null default timezone('utc'::text, now()),
  processed_at timestamp with time zone
);

-- Enable RLS
alter table public.account_deletion_requests enable row level security;

-- Index for lookup and admin sorting
create index if not exists idx_deletion_requests_email on public.account_deletion_requests (email);
create index if not exists idx_deletion_requests_status on public.account_deletion_requests (status, requested_at desc);

-- Expose to Data (REST) API roles
grant insert on table public.account_deletion_requests to anon, authenticated;
grant select on table public.account_deletion_requests to authenticated;

-- RLS: Public visitors (anon) and authenticated users can insert an account deletion request
create policy "Anyone can submit account deletion request" on public.account_deletion_requests
  for insert
  to anon, authenticated
  with check (
    length(trim(email)) >= 5 and
    email like '%@%'
  );

-- RLS: Users can view their own deletion requests if signed in with that email (optimized initplan subquery)
create policy "Users can view own deletion requests" on public.account_deletion_requests
  for select
  to authenticated
  using (((select auth.jwt()) ->> 'email') = email);

-- 2. SECURE PUBLIC PROFILES SELECT POLICY
alter policy "Public leaderboard profiles viewable by all" on public.profiles
  using ((select auth.uid()) = id or leaderboard_visible = true);

-- 3. HARDEN SENSITIVE SECURITY DEFINER FUNCTIONS FROM ANON CALLS
-- (Resolves Supabase Security Advisor warnings: anon_security_definer_function_executable)

revoke execute on function public.rollover_leaderboards(text, integer, boolean, boolean, boolean) from public, anon, authenticated;
grant execute on function public.rollover_leaderboards(text, integer, boolean, boolean, boolean) to postgres, service_role;

revoke execute on function public.get_cron_job_status(text) from public, anon, authenticated;
grant execute on function public.get_cron_job_status(text) to postgres, service_role;

revoke execute on function public.record_focus_session(uuid, integer, text) from public, anon;
grant execute on function public.record_focus_session(uuid, integer, text) to authenticated, postgres, service_role;

revoke execute on function public.record_focus_session_legacy(uuid, integer) from public, anon;
grant execute on function public.record_focus_session_legacy(uuid, integer) to postgres, service_role;
