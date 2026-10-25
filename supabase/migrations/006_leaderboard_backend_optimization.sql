-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 006_leaderboard_backend_optimization.sql
-- High-Performance Micro-Payload Leaderboard Bundle & Idempotent Session Sync
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. COVERING INDEXES FOR ZERO-HEAP INDEX-ONLY SCANS
create index if not exists idx_profiles_lb_daily_cov
  on public.profiles (daily_study_secs desc)
  include (id, display_name, doctor_name, avatar_color_id, avatar_icon_id, total_study_secs)
  where leaderboard_visible = true;

create index if not exists idx_profiles_lb_weekly_cov
  on public.profiles (weekly_study_secs desc)
  include (id, display_name, doctor_name, avatar_color_id, avatar_icon_id, total_study_secs)
  where leaderboard_visible = true;

create index if not exists idx_profiles_lb_monthly_cov
  on public.profiles (monthly_study_secs desc)
  include (id, display_name, doctor_name, avatar_color_id, avatar_icon_id, total_study_secs)
  where leaderboard_visible = true;

create index if not exists idx_profiles_lb_yearly_cov
  on public.profiles (total_study_secs desc)
  include (id, display_name, doctor_name, avatar_color_id, avatar_icon_id)
  where leaderboard_visible = true;

-- 2. LIGHTWEIGHT FOCUS SESSION IDEMPOTENCY LEDGER
create table if not exists public.recorded_focus_sessions (
  session_id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  session_secs integer not null,
  recorded_at timestamp with time zone not null default timezone('utc'::text, now())
);

create index if not exists idx_recorded_sessions_user_id
  on public.recorded_focus_sessions (user_id);

alter table public.recorded_focus_sessions enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'recorded_focus_sessions'
      and policyname = 'Users can view own recorded sessions'
  ) then
    create policy "Users can view own recorded sessions" on public.recorded_focus_sessions
      for select
      to authenticated
      using ((select auth.uid()) = user_id);
  end if;
end
$$;

-- 3. IDEMPOTENT & SAFE FOCUS SESSION LOGGING RPC
create or replace function public.record_focus_session(
  p_user_id uuid,
  p_session_secs integer,
  p_session_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_updated record;
  v_clamped_secs integer;
begin
  -- Sanity clamp: 0 <= session_secs <= 86400 (24 hours max per single log)
  v_clamped_secs := greatest(-86400, least(coalesce(p_session_secs, 0), 86400));

  -- Idempotency check: if session_id provided and already recorded, skip duplicate increment
  if p_session_id is not null and p_session_id <> '' then
    if exists (
      select 1 from public.recorded_focus_sessions
      where session_id = p_session_id
    ) then
      select id, display_name, daily_study_secs, weekly_study_secs, monthly_study_secs, total_study_secs
      into v_updated
      from public.profiles
      where id = p_user_id;

      return jsonb_build_object(
        'status', 'duplicate_ignored',
        'profile', row_to_json(v_updated)
      );
    end if;

    -- Record session in idempotency ledger
    insert into public.recorded_focus_sessions (session_id, user_id, session_secs)
    values (p_session_id, p_user_id, v_clamped_secs)
    on conflict (session_id) do nothing;
  end if;

  -- Atomic increment of user study stats
  update public.profiles
  set
    daily_study_secs = greatest(0, daily_study_secs + v_clamped_secs),
    weekly_study_secs = greatest(0, weekly_study_secs + v_clamped_secs),
    monthly_study_secs = greatest(0, monthly_study_secs + v_clamped_secs),
    total_study_secs = greatest(0, total_study_secs + v_clamped_secs),
    updated_at = timezone('utc'::text, now())
  where id = p_user_id
  returning id, display_name, daily_study_secs, weekly_study_secs, monthly_study_secs, total_study_secs
  into v_updated;

  return jsonb_build_object(
    'status', 'recorded',
    'profile', row_to_json(v_updated)
  );
end;
$$;

-- 4. SINGLE-ROUNDTRIP BUNDLED LEADERBOARD RPC
create or replace function public.get_leaderboard_bundle(
  p_user_id uuid default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_limit int := greatest(1, least(coalesce(p_limit, 20), 100));
  v_daily jsonb;
  v_weekly jsonb;
  v_monthly jsonb;
  v_yearly jsonb;
  v_user_stats jsonb := null;
  v_total_users int := 0;
begin
  -- 1. Daily Top Cohort (compact tuple: [id, name, secs, color, icon, total_secs])
  select coalesce(jsonb_agg(
    jsonb_build_array(
      p.id,
      coalesce(p.display_name, p.doctor_name, 'Dr. Colleague'),
      p.daily_study_secs,
      coalesce(p.avatar_color_id, 'indigo'),
      coalesce(p.avatar_icon_id, 'letter'),
      p.total_study_secs
    )
  ), '[]'::jsonb)
  into v_daily
  from (
    select id, display_name, doctor_name, daily_study_secs, avatar_color_id, avatar_icon_id, total_study_secs
    from public.profiles
    where leaderboard_visible = true
    order by daily_study_secs desc, total_study_secs desc
    limit v_limit
  ) p;

  -- 2. Weekly Top Cohort
  select coalesce(jsonb_agg(
    jsonb_build_array(
      p.id,
      coalesce(p.display_name, p.doctor_name, 'Dr. Colleague'),
      p.weekly_study_secs,
      coalesce(p.avatar_color_id, 'indigo'),
      coalesce(p.avatar_icon_id, 'letter'),
      p.total_study_secs
    )
  ), '[]'::jsonb)
  into v_weekly
  from (
    select id, display_name, doctor_name, weekly_study_secs, avatar_color_id, avatar_icon_id, total_study_secs
    from public.profiles
    where leaderboard_visible = true
    order by weekly_study_secs desc, total_study_secs desc
    limit v_limit
  ) p;

  -- 3. Monthly Top Cohort
  select coalesce(jsonb_agg(
    jsonb_build_array(
      p.id,
      coalesce(p.display_name, p.doctor_name, 'Dr. Colleague'),
      p.monthly_study_secs,
      coalesce(p.avatar_color_id, 'indigo'),
      coalesce(p.avatar_icon_id, 'letter'),
      p.total_study_secs
    )
  ), '[]'::jsonb)
  into v_monthly
  from (
    select id, display_name, doctor_name, monthly_study_secs, avatar_color_id, avatar_icon_id, total_study_secs
    from public.profiles
    where leaderboard_visible = true
    order by monthly_study_secs desc, total_study_secs desc
    limit v_limit
  ) p;

  -- 4. Yearly (All-Time) Top Cohort
  select coalesce(jsonb_agg(
    jsonb_build_array(
      p.id,
      coalesce(p.display_name, p.doctor_name, 'Dr. Colleague'),
      p.total_study_secs,
      coalesce(p.avatar_color_id, 'indigo'),
      coalesce(p.avatar_icon_id, 'letter'),
      p.total_study_secs
    )
  ), '[]'::jsonb)
  into v_yearly
  from (
    select id, display_name, doctor_name, total_study_secs, avatar_color_id, avatar_icon_id
    from public.profiles
    where leaderboard_visible = true
    order by total_study_secs desc
    limit v_limit
  ) p;

  -- 5. Total Visible Active Doctors Count
  select count(*) into v_total_users
  from public.profiles
  where leaderboard_visible = true;

  -- 6. User Exact Rank Across All 4 Scales
  if p_user_id is not null then
    with user_row as (
      select daily_study_secs, weekly_study_secs, monthly_study_secs, total_study_secs
      from public.profiles
      where id = p_user_id
    )
    select jsonb_build_object(
      'daily_rank', (select count(*) + 1 from public.profiles where leaderboard_visible = true and daily_study_secs > u.daily_study_secs),
      'weekly_rank', (select count(*) + 1 from public.profiles where leaderboard_visible = true and weekly_study_secs > u.weekly_study_secs),
      'monthly_rank', (select count(*) + 1 from public.profiles where leaderboard_visible = true and monthly_study_secs > u.monthly_study_secs),
      'yearly_rank', (select count(*) + 1 from public.profiles where leaderboard_visible = true and total_study_secs > u.total_study_secs),
      'daily_secs', u.daily_study_secs,
      'weekly_secs', u.weekly_study_secs,
      'monthly_secs', u.monthly_study_secs,
      'total_secs', u.total_study_secs
    )
    into v_user_stats
    from user_row u;
  end if;

  return jsonb_build_object(
    'daily', v_daily,
    'weekly', v_weekly,
    'monthly', v_monthly,
    'yearly', v_yearly,
    'total_users', v_total_users,
    'user_standing', v_user_stats
  );
end;
$$;
