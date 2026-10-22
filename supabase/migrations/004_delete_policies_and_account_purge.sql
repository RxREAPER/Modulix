-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 004_delete_policies_and_account_purge.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- Allow authenticated users to delete their own records across all public tables
-- (Required for GDPR and Apple App Store Guideline 5.1.1(v) account & data deletion)

drop policy if exists "Users can delete own profile" on public.profiles;
create policy "Users can delete own profile" on public.profiles
  for delete
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "Users can delete own study editions" on public.study_editions;
create policy "Users can delete own study editions" on public.study_editions
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own daily tasks" on public.daily_tasks;
create policy "Users can delete own daily tasks" on public.daily_tasks
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);
