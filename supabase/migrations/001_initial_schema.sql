-- ═══════════════════════════════════════════════════════════════════════════
-- FlowMD Supabase Migration: 001_initial_schema.sql
-- Complete schema for cross-device synchronization and authentication
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. PROFILES TABLE
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  doctor_name text not null default 'Dr',
  avatar_icon_id text not null default 'letter',
  avatar_color_id text not null default 'indigo',
  palette_preset_id text not null default 'paper',
  accent_color_id text not null default 'cobalt',
  theme_pref text not null default 'system',
  active_edition text not null default 'marrow_8',
  day_start_hour integer not null default 5,
  onboarding_done boolean not null default false,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now())
);

-- 2. STUDY EDITIONS TABLE (Stores completed items, plans, and history per edition)
create table if not exists public.study_editions (
  user_id uuid not null references auth.users(id) on delete cascade,
  edition_id text not null,
  plan_json jsonb not null default '{}'::jsonb,
  completed_videos jsonb not null default '{}'::jsonb,
  completed_qbanks jsonb not null default '{}'::jsonb,
  completed_notes jsonb not null default '{}'::jsonb,
  daily_history jsonb not null default '{}'::jsonb,
  bulk_completed_chapters jsonb not null default '[]'::jsonb,
  queue_batch_video_ids jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default timezone('utc'::text, now()),
  primary key (user_id, edition_id)
);

-- 3. TIME LOGS TABLE (Stores individual focus timer study sessions)
create table if not exists public.time_logs (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id text not null,
  topic_id text,
  topic_type text not null,
  topic_title text not null,
  chapter_name text not null,
  duration_secs integer not null,
  timestamp bigint not null,
  created_at timestamptz not null default timezone('utc'::text, now())
);

-- Index for querying user time logs ordered by timestamp
create index if not exists idx_time_logs_user_timestamp on public.time_logs (user_id, timestamp desc);
create index if not exists idx_time_logs_user_subject_time on public.time_logs (user_id, subject_id, timestamp desc);

-- 4. DAILY TASKS TABLE (Stores desk tasks, completed status, and history)
create table if not exists public.daily_tasks (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tasks_json jsonb not null default '[]'::jsonb,
  completed_ids jsonb not null default '[]'::jsonb,
  date_history jsonb not null default '{}'::jsonb,
  last_active_date text not null default '',
  updated_at timestamptz not null default timezone('utc'::text, now())
);

-- ═══════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.profiles enable row level security;
alter table public.study_editions enable row level security;
alter table public.time_logs enable row level security;
alter table public.daily_tasks enable row level security;

-- Profiles: Users can only read and write their own profile
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

-- Study Editions: Users can only read and write their own editions
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

-- Time Logs: Users can only view, insert, and delete their own logs
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

-- Daily Tasks: Users can only view, insert, and update their own daily tasks
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

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO-CREATE PROFILE TRIGGER
-- Automatically creates a profile record when a user signs up via Supabase Auth
-- ═══════════════════════════════════════════════════════════════════════════

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, doctor_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Dr')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Revoke execute from public/anon/authenticated since this function should only be invoked by auth triggers
revoke execute on function public.handle_new_user() from public;
revoke execute on function public.handle_new_user() from anon;
revoke execute on function public.handle_new_user() from authenticated;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
