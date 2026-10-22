-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 003_storage_vault_and_task_tombstones.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Add tombstone column to daily_tasks to eliminate zombie tasks
alter table public.daily_tasks
  add column if not exists deleted_ids jsonb not null default '[]'::jsonb;

-- 2. Create private storage bucket for user-vaults if not exists
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'user-vaults',
  'user-vaults',
  false,
  52428800, -- 50 MB limit
  array['application/gzip', 'application/octet-stream', 'application/json']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 52428800;

-- 3. Storage RLS Policies for user-vaults
-- Note: users can only view, upload, and delete files inside their own folder: user-vaults/{auth.uid()}/*

drop policy if exists "Users can upload own snapshots" on storage.objects;
create policy "Users can upload own snapshots" on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'user-vaults' and
    (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists "Users can view own snapshots" on storage.objects;
create policy "Users can view own snapshots" on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'user-vaults' and
    (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists "Users can update own snapshots" on storage.objects;
create policy "Users can update own snapshots" on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'user-vaults' and
    (storage.foldername(name))[1] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'user-vaults' and
    (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists "Users can delete own snapshots" on storage.objects;
create policy "Users can delete own snapshots" on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'user-vaults' and
    (storage.foldername(name))[1] = (select auth.uid()::text)
  );
