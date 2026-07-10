-- DEV/SANDBOX ONLY.
-- Creates fixed membership test accounts for local Supabase review.
-- Do not run this file against production or a shared staging environment.
-- Real environments should create auth users from a trusted server workflow
-- using Supabase Admin API, then attach subscriptions through controlled jobs.
--
-- Test password for all accounts: NanoBio@123456
--
-- Accounts:
-- - dev.free@nanobio.local   -> free
-- - dev.plus@nanobio.local   -> plus
-- - dev.family@nanobio.local -> family_plus
--
-- Run after:
-- 01-core-auth-profile.sql
-- 02-health-and-schedule.sql
-- 03-membership-quota.sql
-- 07-seed-reference-data.sql

begin;

create extension if not exists pgcrypto;

with seed_users as (
  select *
  from (
    values
      (
        '10000000-0000-4000-8000-000000000101'::uuid,
        '20000000-0000-4000-8000-000000000101'::uuid,
        '30000000-0000-4000-8000-000000000101'::uuid,
        'dev.free@nanobio.local',
        'Dev Free',
        'free'::public.nb_membership_plan
      ),
      (
        '10000000-0000-4000-8000-000000000102'::uuid,
        '20000000-0000-4000-8000-000000000102'::uuid,
        '30000000-0000-4000-8000-000000000102'::uuid,
        'dev.plus@nanobio.local',
        'Dev Plus',
        'plus'::public.nb_membership_plan
      ),
      (
        '10000000-0000-4000-8000-000000000103'::uuid,
        '20000000-0000-4000-8000-000000000103'::uuid,
        '30000000-0000-4000-8000-000000000103'::uuid,
        'dev.family@nanobio.local',
        'Dev FamilyPlus',
        'family_plus'::public.nb_membership_plan
      )
  ) as t(user_id, identity_id, subscription_id, email, full_name, plan_code)
)
insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  confirmation_token,
  recovery_token,
  email_change,
  email_change_token_new,
  email_change_token_current,
  phone_change,
  phone_change_token,
  reauthentication_token,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  is_sso_user,
  is_anonymous
)
select
  user_id,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'authenticated',
  'authenticated',
  email,
  crypt('NanoBio@123456', gen_salt('bf')),
  now(),
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  jsonb_build_object('provider', 'email', 'providers', array['email']),
  jsonb_build_object('full_name', full_name),
  now(),
  now(),
  false,
  false
from seed_users
on conflict (id) do update
set
  email = excluded.email,
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = coalesce(auth.users.email_confirmed_at, excluded.email_confirmed_at),
  confirmation_token = coalesce(excluded.confirmation_token, ''),
  recovery_token = coalesce(excluded.recovery_token, ''),
  email_change = coalesce(excluded.email_change, ''),
  email_change_token_new = coalesce(excluded.email_change_token_new, ''),
  email_change_token_current = coalesce(excluded.email_change_token_current, ''),
  phone_change = coalesce(excluded.phone_change, ''),
  phone_change_token = coalesce(excluded.phone_change_token, ''),
  reauthentication_token = coalesce(excluded.reauthentication_token, ''),
  raw_app_meta_data = excluded.raw_app_meta_data,
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at = now(),
  is_anonymous = false;

update auth.users
set
  confirmation_token = coalesce(confirmation_token, ''),
  recovery_token = coalesce(recovery_token, ''),
  email_change = coalesce(email_change, ''),
  email_change_token_new = coalesce(email_change_token_new, ''),
  email_change_token_current = coalesce(email_change_token_current, ''),
  phone_change = coalesce(phone_change, ''),
  phone_change_token = coalesce(phone_change_token, ''),
  reauthentication_token = coalesce(reauthentication_token, '')
where confirmation_token is null
   or recovery_token is null
   or email_change is null
   or email_change_token_new is null
   or email_change_token_current is null
   or phone_change is null
   or phone_change_token is null
   or reauthentication_token is null;

do $$
begin
  if exists (
    select 1
    from auth.users
    where email in (
      'dev.free@nanobio.local',
      'dev.plus@nanobio.local',
      'dev.family@nanobio.local'
    )
      and (
        confirmation_token is null
        or recovery_token is null
        or email_change is null
        or email_change_token_new is null
        or email_change_token_current is null
        or phone_change is null
        or phone_change_token is null
        or reauthentication_token is null
      )
  ) then
    raise exception 'DEV_AUTH_SEED_TOKEN_COLUMNS_NULL';
  end if;
end $$;

with seed_users as (
  select *
  from (
    values
      (
        '10000000-0000-4000-8000-000000000101'::uuid,
        '20000000-0000-4000-8000-000000000101'::uuid,
        'dev.free@nanobio.local',
        'Dev Free'
      ),
      (
        '10000000-0000-4000-8000-000000000102'::uuid,
        '20000000-0000-4000-8000-000000000102'::uuid,
        'dev.plus@nanobio.local',
        'Dev Plus'
      ),
      (
        '10000000-0000-4000-8000-000000000103'::uuid,
        '20000000-0000-4000-8000-000000000103'::uuid,
        'dev.family@nanobio.local',
        'Dev FamilyPlus'
      )
  ) as t(user_id, identity_id, email, full_name)
)
insert into auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
select
  identity_id,
  user_id,
  user_id::text,
  jsonb_build_object(
    'sub',
    user_id::text,
    'email',
    email,
    'email_verified',
    true,
    'phone_verified',
    false,
    'full_name',
    full_name
  ),
  'email',
  now(),
  now(),
  now()
from seed_users
on conflict (provider, provider_id) do update
set
  user_id = excluded.user_id,
  identity_data = excluded.identity_data,
  updated_at = now();

insert into public.membership_plans (
  code,
  display_name,
  access_version,
  sort_order,
  is_active
)
values
  ('free', 'Free', 'v2', 10, true),
  ('plus', 'Plus', 'v2', 20, true),
  ('family_plus', 'FamilyPlus', 'v3', 30, true)
on conflict (code) do update
set
  display_name = excluded.display_name,
  access_version = excluded.access_version,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = now();

with seed_subscriptions as (
  select *
  from (
    values
      (
        '30000000-0000-4000-8000-000000000101'::uuid,
        '10000000-0000-4000-8000-000000000101'::uuid,
        'free'::public.nb_membership_plan
      ),
      (
        '30000000-0000-4000-8000-000000000102'::uuid,
        '10000000-0000-4000-8000-000000000102'::uuid,
        'plus'::public.nb_membership_plan
      ),
      (
        '30000000-0000-4000-8000-000000000103'::uuid,
        '10000000-0000-4000-8000-000000000103'::uuid,
        'family_plus'::public.nb_membership_plan
      )
  ) as t(subscription_id, user_id, plan_code)
)
insert into public.membership_subscriptions (
  id,
  user_id,
  plan_code,
  status,
  source,
  starts_at,
  current_period_start,
  current_period_end,
  metadata
)
select
  subscription_id,
  user_id,
  plan_code,
  'active',
  'manual',
  now(),
  now(),
  now() + interval '30 days',
  jsonb_build_object('seed', 'dev-membership-test-accounts')
from seed_subscriptions
on conflict (id) do update
set
  plan_code = excluded.plan_code,
  status = 'active',
  source = 'manual',
  starts_at = least(public.membership_subscriptions.starts_at, excluded.starts_at),
  ends_at = null,
  current_period_start = excluded.current_period_start,
  current_period_end = excluded.current_period_end,
  metadata = excluded.metadata,
  updated_at = now();

insert into public.health_profiles (user_id, subject_id)
select hs.owner_user_id, hs.id
from public.health_subjects hs
where hs.owner_user_id in (
  '10000000-0000-4000-8000-000000000101'::uuid,
  '10000000-0000-4000-8000-000000000102'::uuid,
  '10000000-0000-4000-8000-000000000103'::uuid
)
  and hs.subject_type = 'self'
on conflict (subject_id) do nothing;

insert into public.lifestyle_habits (user_id, subject_id)
select hs.owner_user_id, hs.id
from public.health_subjects hs
where hs.owner_user_id in (
  '10000000-0000-4000-8000-000000000101'::uuid,
  '10000000-0000-4000-8000-000000000102'::uuid,
  '10000000-0000-4000-8000-000000000103'::uuid
)
  and hs.subject_type = 'self'
on conflict (subject_id) do nothing;

select
  email,
  subscription_tier,
  onboarding_status
from public.users
where email in (
  'dev.free@nanobio.local',
  'dev.plus@nanobio.local',
  'dev.family@nanobio.local'
)
order by email;

commit;
