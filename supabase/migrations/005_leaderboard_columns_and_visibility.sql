-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 005_leaderboard_columns_and_visibility.sql
-- Add leaderboard study metrics and public leaderboard visibility policy
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. ADD LEADERBOARD STATS COLUMNS TO PROFILES
alter table public.profiles
  add column if not exists display_name text,
  add column if not exists daily_study_secs integer not null default 0,
  add column if not exists weekly_study_secs integer not null default 0,
  add column if not exists total_study_secs integer not null default 0,
  add column if not exists leaderboard_visible boolean not null default true;

-- 2. PARTIAL INDEXES FOR FAST LEADERBOARD SORTING & PAGINATION
create index if not exists idx_profiles_leaderboard_daily
  on public.profiles (daily_study_secs desc)
  where leaderboard_visible = true;

create index if not exists idx_profiles_leaderboard_weekly
  on public.profiles (weekly_study_secs desc)
  where leaderboard_visible = true;

create index if not exists idx_profiles_leaderboard_total
  on public.profiles (total_study_secs desc)
  where leaderboard_visible = true;

-- 3. RLS: ALLOW VIEWING PROFILES IF LEADERBOARD_VISIBLE
create policy "Public leaderboard profiles viewable by all" on public.profiles
  for select
  to authenticated, anon
  using (leaderboard_visible = true);
