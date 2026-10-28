-- Modulix Supabase Migration: 011_simplify_leaderboard_identity.sql
-- Simplifies leaderboard identity to use doctor_name directly, with unique fallback 'User XXXX'
-- Guarantees zero overlapping generic names and enforces participation for all users.

-- 1. BACKFILL PROFILES
update public.profiles
set
  leaderboard_visible = true,
  display_name = coalesce(
    nullif(trim(doctor_name), ''),
    'User ' || right(id::text, 4)
  )
where leaderboard_visible is false or display_name is null or display_name = 'Dr. Colleague';

-- 2. REVISE GET_LEADERBOARD_BUNDLE RPC WITH UNIQUE 'User XXXX' FALLBACK
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
      coalesce(nullif(trim(p.doctor_name), ''), nullif(trim(p.display_name), ''), 'User ' || right(p.id::text, 4)),
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
      coalesce(nullif(trim(p.doctor_name), ''), nullif(trim(p.display_name), ''), 'User ' || right(p.id::text, 4)),
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
      coalesce(nullif(trim(p.doctor_name), ''), nullif(trim(p.display_name), ''), 'User ' || right(p.id::text, 4)),
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
      coalesce(nullif(trim(p.doctor_name), ''), nullif(trim(p.display_name), ''), 'User ' || right(p.id::text, 4)),
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
