-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 010_enable_realtime_for_user_sync.sql
-- Enables Supabase Realtime (WebSockets / postgres_changes) for cross-device
-- live synchronization between web account portal and mobile Flutter client.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.profiles replica identity full;
alter table public.study_editions replica identity full;
alter table public.daily_tasks replica identity full;

alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.study_editions;
alter publication supabase_realtime add table public.daily_tasks;
