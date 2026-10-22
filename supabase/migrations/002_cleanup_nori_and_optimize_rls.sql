-- ═══════════════════════════════════════════════════════════════════════════
-- FlowMD / Modulix Supabase Migration: 002_cleanup_nori_and_optimize_rls.sql
-- Drop legacy nori columns, harden RLS policies to authenticated role,
-- add WITH CHECK constraints, and add composite performance indexes.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. PURGE NORI COLUMNS FROM PROFILES
alter table public.profiles
  drop column if exists nori_prop_id,
  drop column if exists nori_interactions;

-- 2. HARDEN RLS POLICIES (TO authenticated with WITH CHECK on UPDATE)

-- ── Profiles ────────────────────────────────────────────────────────────────
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

create policy "Users can view own profile" on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can insert own profile" on public.profiles
  for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users can update own profile" on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- ── Study Editions ──────────────────────────────────────────────────────────
drop policy if exists "Users can view own study editions" on public.study_editions;
drop policy if exists "Users can insert own study editions" on public.study_editions;
drop policy if exists "Users can update own study editions" on public.study_editions;

create policy "Users can view own study editions" on public.study_editions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own study editions" on public.study_editions
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update own study editions" on public.study_editions
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- ── Time Logs ───────────────────────────────────────────────────────────────
drop policy if exists "Users can view own time logs" on public.time_logs;
drop policy if exists "Users can insert own time logs" on public.time_logs;
drop policy if exists "Users can update own time logs" on public.time_logs;
drop policy if exists "Users can delete own time logs" on public.time_logs;

create policy "Users can view own time logs" on public.time_logs
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own time logs" on public.time_logs
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update own time logs" on public.time_logs
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own time logs" on public.time_logs
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ── Daily Tasks ─────────────────────────────────────────────────────────────
drop policy if exists "Users can view own daily tasks" on public.daily_tasks;
drop policy if exists "Users can insert own daily tasks" on public.daily_tasks;
drop policy if exists "Users can update own daily tasks" on public.daily_tasks;

create policy "Users can view own daily tasks" on public.daily_tasks
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own daily tasks" on public.daily_tasks
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update own daily tasks" on public.daily_tasks
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- 3. COMPOSITE PERFORMANCE INDEX FOR TIME LOGS
create index if not exists idx_time_logs_user_subject_time
  on public.time_logs (user_id, subject_id, timestamp desc);
