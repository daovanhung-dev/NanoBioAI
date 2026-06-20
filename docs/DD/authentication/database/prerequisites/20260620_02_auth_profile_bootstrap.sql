-- NanoBio / BioAI
-- Auth -> public profile bootstrap.
-- Run AFTER 20260620_nanobio_multitenant.sql.
--
-- Result for every new auth.users row:
--   1. public.users          : created with the SAME UUID
--   2. public.health_profiles: one blank row, ready for onboarding update
--   3. public.lifestyle_habits: one default row, ready for onboarding update
--
-- Do NOT create empty rows for logs, plans, notifications, goals, allergies,
-- treatments, etc. Those are event/collection data and should be created only
-- when the user actually has that data.

begin;

-- This trigger executes in the same database transaction as the Auth insert.
-- Keep it small and reliable: an error here will make account creation fail.
create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- 1) Application profile. id is exactly auth.users.id.
  insert into public.users (
    id,
    email,
    phone,
    full_name,
    avatar_url,
    subscription_tier
  )
  values (
    new.id,
    new.email,
    coalesce(new.phone, nullif(new.raw_user_meta_data ->> 'phone', '')),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', '')
    ),
    nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
    'free'
  )
  on conflict (id) do update
  set
    email = excluded.email,
    phone = coalesce(excluded.phone, public.users.phone),
    full_name = coalesce(public.users.full_name, excluded.full_name),
    avatar_url = coalesce(public.users.avatar_url, excluded.avatar_url),
    updated_at = now();

  -- 2) One-to-one health record. All optional health fields remain NULL until
  --    the onboarding flow writes height, weight, occupation, etc.
  insert into public.health_profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  -- 3) One-to-one habits record. Boolean fields are safe defaults (false);
  --    text fields remain NULL until onboarding writes them.
  insert into public.lifestyle_habits (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

-- Recreate the Auth INSERT trigger so it uses the function above.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_auth_user_created();

-- Existing Auth users: ensure every account already has the same base rows.
insert into public.users (id, email, phone, full_name, avatar_url, subscription_tier)
select
  au.id,
  au.email,
  coalesce(au.phone, nullif(au.raw_user_meta_data ->> 'phone', '')),
  coalesce(
    nullif(au.raw_user_meta_data ->> 'full_name', ''),
    nullif(au.raw_user_meta_data ->> 'name', '')
  ),
  nullif(au.raw_user_meta_data ->> 'avatar_url', ''),
  'free'
from auth.users au
on conflict (id) do nothing;

insert into public.health_profiles (user_id)
select id from public.users
on conflict (user_id) do nothing;

insert into public.lifestyle_habits (user_id)
select id from public.users
on conflict (user_id) do nothing;

-- Client code must never manually create public.users, health_profiles or
-- lifestyle_habits. These rows are created by the trusted trigger above.
drop policy if exists users_insert_own on public.users;
revoke insert on public.users from authenticated;

drop policy if exists health_profiles_insert_own on public.health_profiles;
drop policy if exists lifestyle_habits_insert_own on public.lifestyle_habits;
revoke insert on public.health_profiles, public.lifestyle_habits from authenticated;

-- The client keeps SELECT + UPDATE for its own profile rows through existing
-- RLS policies. The trigger owner has the rights needed for its INSERTs.
commit;

-- SQL Editor verification query (run as project administrator):
-- select
--   au.id as auth_user_id,
--   au.email,
--   u.id as public_user_id,
--   hp.id as health_profile_id,
--   lh.id as lifestyle_habits_id
-- from auth.users au
-- left join public.users u on u.id = au.id
-- left join public.health_profiles hp on hp.user_id = au.id
-- left join public.lifestyle_habits lh on lh.user_id = au.id
-- order by au.created_at desc;
