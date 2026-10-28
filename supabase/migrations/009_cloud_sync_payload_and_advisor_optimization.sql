-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 009_cloud_sync_payload_and_advisor_optimization.sql
-- Optimizes RLS evaluation performance, secures RPC functions against IDOR,
-- and converts public read RPC to security invoker.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. CONSOLIDATE PERMISSIVE SELECT POLICIES ON PROFILES
-- Fixes Supabase Performance Advisor: multiple_permissive_policies
-- Retargets single-user view policy to service_role, leaving 'Public leaderboard profiles viewable by all'
-- as the sole optimized permissive SELECT policy for authenticated and anon users.
alter policy "Users can view own profile" on public.profiles to service_role;

-- 2. CONVERT LEADERBOARD BUNDLE TO SECURITY INVOKER
-- Fixes Supabase Security Advisor: anon_security_definer_function_executable & authenticated_security_definer_function_executable
-- Runs under the caller's privileges (anon / authenticated), reading profiles where leaderboard_visible = true.
create or replace function public.get_leaderboard_bundle(p_user_id uuid default null::uuid, p_limit integer default 20)
returns jsonb
language plpgsql
stable security invoker
set search_path to ''
as $function$
declare
  v_limit int := greatest(1, least(coalesce(p_limit, 20), 100));
  v_daily jsonb;
  v_weekly jsonb;
  v_monthly jsonb;
  v_yearly jsonb;
  v_user_stats jsonb := null;
  v_total_users int := 0;
begin
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

  select count(*) into v_total_users
  from public.profiles
  where leaderboard_visible = true;

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
$function$;

grant execute on function public.get_leaderboard_bundle(uuid, integer) to anon, authenticated, service_role;

-- 3. HARDEN RECORD_FOCUS_SESSION WITH IDOR PROTECTION
create or replace function public.record_focus_session(p_user_id uuid, p_session_secs integer, p_session_id text default null::text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_auth_uid uuid;
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
  -- IDOR Protection: Enforce caller ownership when executed via client JWT
  v_auth_uid := (select auth.uid());
  if v_auth_uid is not null and v_auth_uid <> p_user_id then
    return jsonb_build_object('status', 'error', 'message', 'Unauthorized: User ID mismatch');
  end if;

  v_clamped_secs := greatest(-86400, least(coalesce(p_session_secs, 0), 86400));

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

    insert into public.recorded_focus_sessions (session_id, user_id, session_secs)
    values (p_session_id, p_user_id, v_clamped_secs)
    on conflict (session_id) do nothing;
  end if;

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
$function$;

-- 4. REVOKE EXECUTION ON LEGACY ENDPOINT
revoke execute on function public.record_focus_session_legacy(uuid, integer) from public, anon, authenticated;
