-- ═══════════════════════════════════════════════════════════════════════════
-- Modulix Supabase Migration: 012_single_active_device.sql
-- Strictly One Active Device per Account Architecture
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.profiles
  add column if not exists active_device_id text,
  add column if not exists active_device_name text,
  add column if not exists device_registered_at timestamptz;

create index if not exists idx_profiles_active_device
  on public.profiles (id, active_device_id);
