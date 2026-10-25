-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 007_leaderboard_automated_rollover.sql
-- Automated 05:00 AM Study Day, Weekly & Monthly Leaderboard Rollover Engine
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. ADD STUDY PERIOD TRACKING COLUMNS TO PROFILES
alter table public.profiles
  add column if not exists last_study_day text,
  add column if not exists last_study_week text,
  add column if not exists last_study_month text;

-- 2. AUTOMATED ROLLOVER FUNCTION (EXECUTED BY PG_CRON OR MANUAL TRIGGER)
create or replace function public.rollover_leaderboards(
  p_timezone text default 'Asia/Kolkata',
  p_day_start_hour integer default 5,
  p_force_daily boolean default false,
  p_force_weekly boolean default false,
  p_force_monthly boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce(p_timezone, 'Asia/Kolkata');
  v_offset interval := (coalesce(p_day_start_hour, 5) || ' hours')::interval;
  v_now timestamp := (now() at time zone v_tz) - v_offset;
  v_isodow integer := extract(isodow from v_now)::integer;
  v_day_of_month integer := extract(day from v_now)::integer;
  v_daily_reset_count integer := 0;
  v_weekly_reset_count integer := 0;
  v_monthly_reset_count integer := 0;
  v_is_weekly boolean := false;
  v_is_monthly boolean := false;
begin
  -- 1. Daily Reset: Clears daily study seconds for all active users
  update public.profiles
  set daily_study_secs = 0
  where daily_study_secs > 0;
  get diagnostics v_daily_reset_count = row_count;

  -- 2. Weekly Reset: Monday (isodow = 1) at day start hour, or if forced
  if v_isodow = 1 or p_force_weekly then
    v_is_weekly := true;
    update public.profiles
    set weekly_study_secs = 0
    where weekly_study_secs > 0;
    get diagnostics v_weekly_reset_count = row_count;
  end if;

  -- 3. Monthly Reset: 1st of month at day start hour, or if forced
  if v_day_of_month = 1 or p_force_monthly then
    v_is_monthly := true;
    update public.profiles
    set monthly_study_secs = 0
    where monthly_study_secs > 0;
    get diagnostics v_monthly_reset_count = row_count;
  end if;

  -- 4. Prune historical cron job run details older than 7 days to eliminate table bloat
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'cron' and table_name = 'job_run_details'
  ) then
    delete from cron.job_run_details where start_time < (now() - interval '7 days');
  end if;

  return jsonb_build_object(
    'status', 'success',
    'timestamp', now(),
    'timezone', v_tz,
    'day_start_hour', coalesce(p_day_start_hour, 5),
    'daily_reset_count', v_daily_reset_count,
    'weekly_reset_triggered', v_is_weekly,
    'weekly_reset_count', v_weekly_reset_count,
    'monthly_reset_triggered', v_is_monthly,
    'monthly_reset_count', v_monthly_reset_count
  );
end;
$$;

-- 3. ENHANCE RECORD_FOCUS_SESSION WITH DEFENSIVE 5 AM PERIOD ROLLOVER
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
  v_user_profile record;
  v_tz text := 'Asia/Kolkata';
  v_day_start_hour integer := 5;
  v_study_now timestamp;
  v_curr_day text;
  v_curr_week text;
  v_curr_month text;
  v_new_daily integer;
  v_new_weekly integer;
  v_new_monthly integer;
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

  -- Fetch current profile state
  select id, day_start_hour, daily_study_secs, weekly_study_secs, monthly_study_secs, total_study_secs,
         last_study_day, last_study_week, last_study_month
  into v_user_profile
  from public.profiles
  where id = p_user_id;

  if v_user_profile.id is null then
    return jsonb_build_object('status', 'error', 'message', 'User profile not found');
  end if;

  v_day_start_hour := coalesce(v_user_profile.day_start_hour, 5);
  v_study_now := (now() at time zone v_tz) - (v_day_start_hour || ' hours')::interval;
  v_curr_day := to_char(v_study_now, 'YYYY-MM-DD');
  v_curr_week := to_char(v_study_now, 'IYYY-IW');
  v_curr_month := to_char(v_study_now, 'YYYY-MM');

  -- Defensive rollover: if last recorded study period preceded current 5 AM period, reset accumulator
  if v_user_profile.last_study_day is null or v_user_profile.last_study_day <> v_curr_day then
    v_new_daily := greatest(0, v_clamped_secs);
  else
    v_new_daily := greatest(0, v_user_profile.daily_study_secs + v_clamped_secs);
  end if;

  if v_user_profile.last_study_week is null or v_user_profile.last_study_week <> v_curr_week then
    v_new_weekly := greatest(0, v_clamped_secs);
  else
    v_new_weekly := greatest(0, v_user_profile.weekly_study_secs + v_clamped_secs);
  end if;

  if v_user_profile.last_study_month is null or v_user_profile.last_study_month <> v_curr_month then
    v_new_monthly := greatest(0, v_clamped_secs);
  else
    v_new_monthly := greatest(0, v_user_profile.monthly_study_secs + v_clamped_secs);
  end if;

  -- Atomic update of study counters and study period keys
  update public.profiles
  set
    daily_study_secs = v_new_daily,
    weekly_study_secs = v_new_weekly,
    monthly_study_secs = v_new_monthly,
    total_study_secs = greatest(0, total_study_secs + v_clamped_secs),
    last_study_day = v_curr_day,
    last_study_week = v_curr_week,
    last_study_month = v_curr_month,
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

-- 4. CONFIGURE PG_CRON SCHEDULE FOR DAILY 05:00 AM IST (23:30 UTC)
create extension if not exists pg_cron;

do $$
begin
  if exists (select 1 from cron.job where jobname = 'modulix-daily-leaderboard-reset') then
    perform cron.unschedule('modulix-daily-leaderboard-reset');
  end if;
  perform cron.schedule(
    'modulix-daily-leaderboard-reset',
    '30 23 * * *',
    'select public.rollover_leaderboards(''Asia/Kolkata'', 5);'
  );
end $$;

-- 5. SAFE HELPER TO INSPECT CRON JOB STATUS WITHOUT EXPOSING CRON SCHEMA
create or replace function public.get_cron_job_status(p_jobname text default 'modulix-daily-leaderboard-reset')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_job record;
begin
  if not exists (select 1 from information_schema.tables where table_schema = 'cron' and table_name = 'job') then
    return jsonb_build_object('exists', false);
  end if;

  select jobid, schedule, command, active, jobname
  into v_job
  from cron.job
  where jobname = p_jobname;

  if v_job.jobid is null then
    return jsonb_build_object('exists', false);
  end if;

  return jsonb_build_object(
    'exists', true,
    'jobid', v_job.jobid,
    'schedule', v_job.schedule,
    'command', v_job.command,
    'active', v_job.active,
    'jobname', v_job.jobname
  );
end;
$$;
