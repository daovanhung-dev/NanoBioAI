-- NanoBio / BioAI - Supabase single-file rebuild config.
-- DESTRUCTIVE LOCAL/SANDBOX SCRIPT ONLY. Do not run against production.
-- This file wipes auth users, drops/recreates public schema, then recreates
-- all app database objects, RLS policies, trusted RPCs and baseline seed data.
-- Keep this file updated whenever docs/supabase schema, RLS, RPC or seed logic changes.

begin;

-- ---------------------------------------------------------------------------
-- 00. Destructive reset: auth data and public schema
-- ---------------------------------------------------------------------------
-- Wipes Supabase Auth users/identities/sessions and every app object in public.
-- Requires SQL Editor/postgres privileges. Flutter anon/authenticated clients
-- must never execute this script.

do $$
begin
  if to_regclass('auth.users') is not null then
    execute 'truncate table auth.users cascade';
  end if;
end $$;

drop schema if exists public cascade;
create schema public;
comment on schema public is 'NanoBio application schema rebuilt from docs/supabase/config.sql';

grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on schema public to postgres, service_role;
alter default privileges in schema public grant all on tables to postgres, service_role;
alter default privileges in schema public grant all on sequences to postgres, service_role;
alter default privileges in schema public grant all on functions to postgres, service_role;

-- ---------------------------------------------------------------------------

-- 01. Core auth/profile

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): tao core auth profile schema
-- NanoBio / BioAI - Supabase core Auth/Profile draft.
-- Run before other docs/supabase SQL files.

create extension if not exists pgcrypto;

do $$
begin
  create domain public.nb_membership_plan as text
    check (value in ('free', 'plus', 'family_plus'));
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create domain public.nb_onboarding_status as text
    check (value in ('not_started', 'in_progress', 'completed'));
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create domain public.nb_product_access_status as text
    check (value in ('guest', 'free', 'plus', 'family_plus'));
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create domain public.nb_sale_status as text
    check (value in ('none', 'pending', 'active', 'suspended', 'closed'));
exception
  when duplicate_object then null;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  phone text,
  full_name text,
  avatar_url text,
  gender text,
  birth_year integer,
  subscription_tier public.nb_membership_plan not null default 'free',
  product_access_status public.nb_product_access_status not null default 'guest',
  sale_status public.nb_sale_status not null default 'none',
  is_anonymous boolean not null default false,
  onboarding_status public.nb_onboarding_status not null default 'not_started',
  onboarding_completed_at timestamptz,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_completed_onboarding_has_time
    check (onboarding_status <> 'completed' or onboarding_completed_at is not null)
);

create unique index if not exists idx_users_phone_unique_not_null
  on public.users (phone)
  where phone is not null;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

create table if not exists public.health_subjects (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  linked_user_id uuid references public.users(id) on delete set null,
  family_group_id uuid,
  subject_type text not null default 'self'
    check (subject_type in ('self', 'family_member')),
  display_name text,
  relationship text,
  gender text,
  birth_year integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint health_subject_self_owner
    check (subject_type <> 'self' or owner_user_id = coalesce(linked_user_id, owner_user_id))
);

create unique index if not exists idx_health_subjects_one_self_per_owner
  on public.health_subjects (owner_user_id)
  where subject_type = 'self';

create index if not exists idx_health_subjects_owner_active
  on public.health_subjects (owner_user_id, is_active);

create index if not exists idx_health_subjects_linked_user
  on public.health_subjects (linked_user_id)
  where linked_user_id is not null;

drop trigger if exists trg_health_subjects_updated_at on public.health_subjects;
create trigger trg_health_subjects_updated_at
  before update on public.health_subjects
  for each row execute function public.set_updated_at();

create or replace function public.default_self_subject_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select hs.id
  from public.health_subjects hs
  where hs.owner_user_id = (select auth.uid())
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1
$$;

create or replace function public.can_read_health_subject(p_subject_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.health_subjects hs
    where hs.id = p_subject_id
      and hs.is_active = true
      and (
        hs.owner_user_id = (select auth.uid())
        or hs.linked_user_id = (select auth.uid())
      )
  )
$$;

create or replace function public.can_write_health_subject(p_subject_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.health_subjects hs
    where hs.id = p_subject_id
      and hs.is_active = true
      and hs.owner_user_id = (select auth.uid())
  )
$$;

create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_anonymous boolean;
  v_product_status public.nb_product_access_status;
begin
  v_is_anonymous := coalesce(
    (new.raw_app_meta_data ->> 'provider') = 'anonymous',
    new.email is null and new.phone is null
  );

  v_product_status := case when v_is_anonymous then 'guest' else 'free' end;

  insert into public.users (
    id,
    email,
    phone,
    full_name,
    avatar_url,
    subscription_tier,
    product_access_status,
    is_anonymous
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
    'free',
    v_product_status,
    v_is_anonymous
  )
  on conflict (id) do update
  set
    email = excluded.email,
    phone = coalesce(excluded.phone, public.users.phone),
    full_name = coalesce(public.users.full_name, excluded.full_name),
    avatar_url = coalesce(public.users.avatar_url, excluded.avatar_url),
    product_access_status = excluded.product_access_status,
    is_anonymous = excluded.is_anonymous,
    updated_at = now();

  insert into public.health_subjects (
    owner_user_id,
    linked_user_id,
    subject_type,
    display_name,
    relationship
  )
  values (
    new.id,
    new.id,
    'self',
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      new.email,
      'Bạn'
    ),
    'self'
  )
  on conflict (owner_user_id) where subject_type = 'self'
  do update
  set
    linked_user_id = excluded.linked_user_id,
    display_name = coalesce(public.health_subjects.display_name, excluded.display_name),
    is_active = true,
    updated_at = now();

  return new;
end;
$$;

create or replace function public.handle_auth_user_contact_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
  set
    email = new.email,
    phone = coalesce(new.phone, public.users.phone),
    updated_at = now()
  where id = new.id;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_auth_user_created();

drop trigger if exists on_auth_user_contact_changed on auth.users;
create trigger on_auth_user_contact_changed
  after update of email, phone on auth.users
  for each row execute function public.handle_auth_user_contact_changed();

insert into public.users (id, email, phone, full_name, avatar_url, subscription_tier, product_access_status, is_anonymous)
select
  au.id,
  au.email,
  coalesce(au.phone, nullif(au.raw_user_meta_data ->> 'phone', '')),
  coalesce(nullif(au.raw_user_meta_data ->> 'full_name', ''), nullif(au.raw_user_meta_data ->> 'name', '')),
  nullif(au.raw_user_meta_data ->> 'avatar_url', ''),
  'free',
  case when au.email is null and au.phone is null then 'guest' else 'free' end,
  au.email is null and au.phone is null
from auth.users au
on conflict (id) do nothing;

insert into public.health_subjects (owner_user_id, linked_user_id, subject_type, display_name, relationship)
select
  u.id,
  u.id,
  'self',
  coalesce(u.full_name, u.email, 'Bạn'),
  'self'
from public.users u
on conflict (owner_user_id) where subject_type = 'self' do nothing;

alter table public.users enable row level security;
alter table public.health_subjects enable row level security;

drop policy if exists users_select_own on public.users;
drop policy if exists users_update_own_profile on public.users;

create policy users_select_own
  on public.users for select to authenticated
  using ((select auth.uid()) = id);

create policy users_update_own_profile
  on public.users for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists health_subjects_select_allowed on public.health_subjects;
drop policy if exists health_subjects_insert_own on public.health_subjects;
drop policy if exists health_subjects_update_allowed on public.health_subjects;
drop policy if exists health_subjects_delete_own on public.health_subjects;

create policy health_subjects_select_allowed
  on public.health_subjects for select to authenticated
  using (public.can_read_health_subject(id));

create policy health_subjects_insert_own
  on public.health_subjects for insert to authenticated
  with check (owner_user_id = (select auth.uid()));

create policy health_subjects_update_allowed
  on public.health_subjects for update to authenticated
  using (public.can_write_health_subject(id))
  with check (public.can_write_health_subject(id));

create policy health_subjects_delete_own
  on public.health_subjects for delete to authenticated
  using (owner_user_id = (select auth.uid()));

grant usage on schema public to anon, authenticated;
grant select on public.users, public.health_subjects to authenticated;
grant update (
  phone,
  full_name,
  avatar_url,
  gender,
  birth_year,
  onboarding_status,
  onboarding_completed_at,
  last_login_at
) on public.users to authenticated;
grant select, insert, update, delete on public.health_subjects to authenticated;

revoke insert, delete on public.users from anon, authenticated;
revoke update (
  subscription_tier,
  product_access_status,
  sale_status,
  is_anonymous,
  created_at,
  updated_at
) on public.users from anon, authenticated;

-- ---------------------------------------------------------------------------

-- 02. Health, schedule, AI and catalog

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): tao health schedule schema
-- NanoBio / BioAI - health, onboarding, schedule, AI and catalog draft.
-- Run after 01-core-auth-profile.sql.

create table if not exists public.health_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  occupation text,
  height_cm double precision,
  weight_kg double precision,
  bmi double precision,
  blood_pressure text,
  blood_sugar text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (subject_id)
);

create table if not exists public.lifestyle_habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  skip_breakfast boolean not null default false,
  eat_late boolean not null default false,
  eat_sweet boolean not null default false,
  eat_oily boolean not null default false,
  low_vegetable boolean not null default false,
  low_water boolean not null default false,
  fast_food boolean not null default false,
  alcohol boolean not null default false,
  coffee_high boolean not null default false,
  sleep_quality text,
  activity_level text,
  water_per_day text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (subject_id)
);

create table if not exists public.health_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  goal_code text not null,
  goal_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (subject_id, goal_code)
);

create table if not exists public.health_conditions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  condition_code text not null,
  condition_name text,
  severity_level integer,
  created_at timestamptz not null default now(),
  unique (subject_id, condition_code)
);

create table if not exists public.food_allergies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  allergy_name text not null,
  note text,
  created_at timestamptz not null default now(),
  unique (subject_id, allergy_name)
);

create table if not exists public.medical_treatments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  treatment_name text,
  medication_name text,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.survey_answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  question_code text not null,
  answer_value text,
  created_at timestamptz not null default now(),
  unique (subject_id, question_code)
);

create table if not exists public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  plan_date date not null,
  meal_type text not null,
  meal_name text not null,
  description text,
  calories integer,
  protein double precision,
  carbs double precision,
  fat double precision,
  fiber double precision,
  water_ml integer,
  meal_order integer not null default 0,
  start_time time,
  end_time time,
  cooking_instructions text,
  is_completed boolean not null default false,
  ai_generated boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (subject_id, plan_date, meal_order)
);

create table if not exists public.daily_health_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  task_date date not null,
  task_code text not null,
  category text not null,
  title text not null,
  description text,
  target_value double precision,
  current_value double precision not null default 0,
  unit text,
  is_completed boolean not null default false,
  sort_order integer not null default 0,
  source text,
  encouragement text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (subject_id, task_date, task_code)
);

create table if not exists public.lifestyle_schedule_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  schedule_date date not null,
  start_time time not null,
  end_time time,
  title text not null,
  description text,
  category text not null,
  source_type text not null,
  source_id text,
  target_value double precision not null default 1,
  current_value double precision not null default 0,
  unit text,
  is_completed boolean not null default false,
  sort_order integer not null default 0,
  ai_generated boolean not null default true,
  encouragement text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid default public.default_self_subject_id() references public.health_subjects(id) on delete set null,
  title text,
  body text,
  type text,
  is_read boolean not null default false,
  source_type text,
  source_id text,
  scheduled_at timestamptz,
  notification_id integer,
  action_status text not null default 'pending'
    check (action_status in ('pending', 'completed', 'skipped')),
  responded_at timestamptz,
  payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.health_tracking_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  weight_kg double precision,
  calories integer,
  water_ml integer,
  sleep_hours double precision,
  stress_level integer,
  steps_count integer,
  heart_rate_bpm integer,
  oxygen_saturation double precision,
  daily_score integer,
  mood text,
  log_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (subject_id, log_date)
);

create table if not exists public.health_score_ledgers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  score integer not null check (score >= 0 and score <= 100),
  formula_version text not null,
  breakdown jsonb not null default '{}'::jsonb,
  idempotency_key text,
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint health_score_ledgers_period_valid check (period_end >= period_start),
  unique (subject_id, period_start, period_end, formula_version)
);

create table if not exists public.wellness_point_ledgers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  source_type text not null,
  source_id uuid,
  schedule_date date not null,
  points_delta integer not null,
  program_code text not null,
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create table if not exists public.nutrition_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  food_name text,
  calories integer,
  protein double precision,
  carbs double precision,
  fat double precision,
  meal_type text,
  eaten_at timestamptz not null default now()
);

create table if not exists public.ai_insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  insight_type text,
  title text,
  content text,
  risk_level text,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  recommendation_type text,
  title text,
  description text,
  action_text text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_schedule_ai_requests (
  request_id text primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  actor_mode text not null check (actor_mode in ('initial_guest', 'member_new')),
  status text not null check (status in ('generating', 'succeeded', 'failed')),
  start_date date,
  days integer not null default 7,
  meal_count integer not null default 0,
  exercise_count integer not null default 0,
  schedule_item_count integer not null default 0,
  error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.meal_catalog (
  code text primary key,
  meal_type text not null,
  meal_name text not null,
  description text not null,
  cooking_instructions text not null,
  calories integer not null,
  protein double precision not null,
  carbs double precision not null,
  fat double precision not null,
  fiber double precision not null,
  water_ml integer not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.exercise_catalog (
  code text primary key,
  category text not null,
  title text not null,
  description text not null,
  unit text not null,
  encouragement text not null,
  min_target double precision not null,
  max_target double precision not null,
  default_target double precision not null,
  intensity_level text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.schedule_task_catalog (
  code text primary key,
  category text not null,
  title text not null,
  description text not null,
  start_time time not null,
  end_time time not null,
  target_value double precision not null,
  unit text not null,
  encouragement text not null,
  sort_order integer not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_health_profiles_subject on public.health_profiles (subject_id);
create index if not exists idx_lifestyle_habits_subject on public.lifestyle_habits (subject_id);
create index if not exists idx_health_goals_subject_active on public.health_goals (subject_id, is_active);
create index if not exists idx_health_conditions_subject on public.health_conditions (subject_id);
create index if not exists idx_food_allergies_subject on public.food_allergies (subject_id);
create index if not exists idx_medical_treatments_subject_created on public.medical_treatments (subject_id, created_at desc);
create index if not exists idx_survey_answers_subject_question on public.survey_answers (subject_id, question_code);
create index if not exists idx_meal_plans_subject_date_order on public.meal_plans (subject_id, plan_date, meal_order);
create index if not exists idx_daily_tasks_subject_date_order on public.daily_health_tasks (subject_id, task_date, sort_order);
create index if not exists idx_lifestyle_schedule_subject_date_order on public.lifestyle_schedule_items (subject_id, schedule_date, sort_order);
create index if not exists idx_notifications_user_scheduled on public.notifications (user_id, scheduled_at desc);
create index if not exists idx_health_tracking_subject_date on public.health_tracking_logs (subject_id, log_date desc);
create index if not exists idx_health_score_ledgers_subject_period
  on public.health_score_ledgers (subject_id, period_end desc, formula_version);
create index if not exists idx_wellness_point_ledgers_subject_date
  on public.wellness_point_ledgers (subject_id, schedule_date desc, program_code);
create index if not exists idx_wellness_point_ledgers_source
  on public.wellness_point_ledgers (source_type, source_id);
create index if not exists idx_nutrition_logs_subject_eaten on public.nutrition_logs (subject_id, eaten_at desc);
create index if not exists idx_ai_insights_subject_created on public.ai_insights (subject_id, created_at desc);
create index if not exists idx_ai_recommendations_subject_unread on public.ai_recommendations (subject_id, is_read, created_at desc);
create index if not exists idx_personal_schedule_ai_requests_user_mode
  on public.personal_schedule_ai_requests (user_id, actor_mode, status, updated_at desc);
create index if not exists idx_meal_catalog_type_active on public.meal_catalog (meal_type, is_active);
create index if not exists idx_exercise_catalog_category_active on public.exercise_catalog (category, is_active);
create index if not exists idx_schedule_task_catalog_category_active on public.schedule_task_catalog (category, is_active);
create index if not exists idx_health_profiles_user on public.health_profiles (user_id);
create index if not exists idx_lifestyle_habits_user on public.lifestyle_habits (user_id);
create index if not exists idx_health_goals_user on public.health_goals (user_id);
create index if not exists idx_health_conditions_user on public.health_conditions (user_id);
create index if not exists idx_food_allergies_user on public.food_allergies (user_id);
create index if not exists idx_medical_treatments_user on public.medical_treatments (user_id);
create index if not exists idx_survey_answers_user on public.survey_answers (user_id);
create index if not exists idx_meal_plans_user on public.meal_plans (user_id);
create index if not exists idx_daily_health_tasks_user on public.daily_health_tasks (user_id);
create index if not exists idx_lifestyle_schedule_items_user on public.lifestyle_schedule_items (user_id);
create index if not exists idx_health_tracking_logs_user on public.health_tracking_logs (user_id);
create index if not exists idx_health_score_ledgers_user on public.health_score_ledgers (user_id);
create index if not exists idx_wellness_point_ledgers_user on public.wellness_point_ledgers (user_id);
create index if not exists idx_nutrition_logs_user on public.nutrition_logs (user_id);
create index if not exists idx_ai_insights_user on public.ai_insights (user_id);
create index if not exists idx_ai_recommendations_user on public.ai_recommendations (user_id);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'health_profiles',
    'lifestyle_habits',
    'meal_plans',
    'daily_health_tasks',
    'lifestyle_schedule_items',
    'notifications',
    'health_tracking_logs',
    'health_score_ledgers',
    'wellness_point_ledgers',
    'personal_schedule_ai_requests',
    'meal_catalog',
    'exercise_catalog',
    'schedule_task_catalog'
  ]
  loop
    execute format('drop trigger if exists %I on public.%I', 'trg_' || table_name || '_updated_at', table_name);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
      'trg_' || table_name || '_updated_at',
      table_name
    );
  end loop;
end;
$$;

insert into public.health_profiles (user_id, subject_id)
select hs.owner_user_id, hs.id
from public.health_subjects hs
where hs.subject_type = 'self'
on conflict (subject_id) do nothing;

insert into public.lifestyle_habits (user_id, subject_id)
select hs.owner_user_id, hs.id
from public.health_subjects hs
where hs.subject_type = 'self'
on conflict (subject_id) do nothing;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'health_profiles',
    'lifestyle_habits',
    'health_goals',
    'health_conditions',
    'food_allergies',
    'medical_treatments',
    'survey_answers',
    'meal_plans',
    'daily_health_tasks',
    'lifestyle_schedule_items',
    'notifications',
    'health_tracking_logs',
    'health_score_ledgers',
    'wellness_point_ledgers',
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);

    execute format('drop policy if exists %I on public.%I', table_name || '_select_subject', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_insert_subject', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_update_subject', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_delete_subject', table_name);

    execute format(
      'create policy %I on public.%I for select to authenticated using (public.can_read_health_subject(subject_id))',
      table_name || '_select_subject',
      table_name
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (user_id = (select auth.uid()) and public.can_write_health_subject(subject_id))',
      table_name || '_insert_subject',
      table_name
    );
    execute format(
      'create policy %I on public.%I for update to authenticated using (public.can_write_health_subject(subject_id)) with check (user_id = (select auth.uid()) and public.can_write_health_subject(subject_id))',
      table_name || '_update_subject',
      table_name
    );
    execute format(
      'create policy %I on public.%I for delete to authenticated using (public.can_write_health_subject(subject_id))',
      table_name || '_delete_subject',
      table_name
    );
  end loop;
end;
$$;

alter table public.personal_schedule_ai_requests enable row level security;
drop policy if exists personal_schedule_ai_requests_select_own
  on public.personal_schedule_ai_requests;
create policy personal_schedule_ai_requests_select_own
  on public.personal_schedule_ai_requests for select to authenticated
  using (user_id = (select auth.uid()));

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'meal_catalog',
    'exercise_catalog',
    'schedule_task_catalog'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_read_authenticated', table_name);
    execute format(
      'create policy %I on public.%I for select to authenticated using (true)',
      table_name || '_read_authenticated',
      table_name
    );
  end loop;
end;
$$;

grant select, insert, update, delete
  on public.health_profiles,
     public.lifestyle_habits,
     public.health_goals,
     public.health_conditions,
     public.food_allergies,
     public.medical_treatments,
     public.survey_answers,
     public.meal_plans,
     public.daily_health_tasks,
     public.lifestyle_schedule_items,
     public.notifications,
     public.health_tracking_logs,
     public.health_score_ledgers,
     public.wellness_point_ledgers,
     public.nutrition_logs,
     public.ai_insights,
     public.ai_recommendations
  to authenticated;

grant select on public.meal_catalog, public.exercise_catalog, public.schedule_task_catalog to authenticated;
grant select on public.personal_schedule_ai_requests to authenticated;
revoke insert, update, delete on public.personal_schedule_ai_requests
  from anon, authenticated;
revoke insert, update, delete on public.meal_catalog, public.exercise_catalog, public.schedule_task_catalog from anon, authenticated;

-- ---------------------------------------------------------------------------

-- 03. Membership and quota

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): tao membership quota schema
-- NanoBio / BioAI - membership entitlement and usage quota draft.
-- Run after 01-core-auth-profile.sql.

create table if not exists public.membership_plans (
  code public.nb_membership_plan primary key,
  display_name text not null,
  access_version text not null check (access_version in ('v2', 'v3')),
  sort_order integer not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.plan_entitlements (
  id uuid primary key default gen_random_uuid(),
  plan_code public.nb_membership_plan not null references public.membership_plans(code) on delete cascade,
  entitlement_key text not null,
  entitlement_value jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (plan_code, entitlement_key)
);

create table if not exists public.membership_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  plan_code public.nb_membership_plan not null references public.membership_plans(code),
  status text not null default 'active'
    check (status in ('trialing', 'active', 'past_due', 'canceled', 'expired')),
  source text not null default 'manual'
    check (source in ('manual', 'payment_provider', 'promotion', 'migration')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  current_period_start timestamptz,
  current_period_end timestamptz,
  provider text,
  provider_subscription_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint membership_subscription_period_valid
    check (ends_at is null or ends_at > starts_at)
);

create index if not exists idx_membership_subscriptions_user_status
  on public.membership_subscriptions (user_id, status, starts_at desc);

create unique index if not exists idx_membership_subscriptions_provider_id
  on public.membership_subscriptions (provider, provider_subscription_id)
  where provider is not null and provider_subscription_id is not null;

create table if not exists public.usage_quota_rules (
  id uuid primary key default gen_random_uuid(),
  plan_code public.nb_membership_plan not null references public.membership_plans(code) on delete cascade,
  feature_key text not null,
  period_unit text not null check (period_unit in ('day', 'month', 'lifetime', 'none')),
  max_count integer,
  reset_timezone text not null default 'Asia/Ho_Chi_Minh',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint usage_quota_rule_limit_valid
    check (
      (period_unit = 'none' and max_count is null)
      or (period_unit <> 'none' and max_count is not null and max_count >= 0)
    ),
  unique (plan_code, feature_key, period_unit)
);

create table if not exists public.usage_quota_counters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  feature_key text not null,
  period_key text not null,
  plan_code public.nb_membership_plan not null,
  used_count integer not null default 0 check (used_count >= 0),
  limit_count integer,
  reset_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, feature_key, period_key)
);

create table if not exists public.usage_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  feature_key text not null,
  period_key text not null,
  count_delta integer not null default 1,
  idempotency_key text,
  event_source text not null default 'trusted_backend'
    check (event_source in ('trusted_backend', 'edge_function', 'sql_job', 'admin')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, feature_key, idempotency_key)
);

create index if not exists idx_usage_events_user_feature_created
  on public.usage_events (user_id, feature_key, created_at desc);

create or replace function public.current_plan_for_user(p_user_id uuid)
returns public.nb_membership_plan
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select ms.plan_code
      from public.membership_subscriptions ms
      where ms.user_id = p_user_id
        and ms.status in ('trialing', 'active')
        and ms.starts_at <= now()
        and (ms.ends_at is null or ms.ends_at > now())
      order by
        case ms.plan_code
          when 'family_plus' then 3
          when 'plus' then 2
          else 1
        end desc,
        ms.starts_at desc
      limit 1
    ),
    'free'::public.nb_membership_plan
  )
$$;

create or replace function public.sync_user_subscription_tier()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_plan public.nb_membership_plan;
begin
  if TG_OP = 'DELETE' then
    v_user_id := old.user_id;
  else
    v_user_id := new.user_id;
  end if;

  v_plan := public.current_plan_for_user(v_user_id);

  update public.users
  set
    subscription_tier = v_plan,
    product_access_status = case
      when product_access_status = 'guest' and is_anonymous then product_access_status
      else v_plan::text::public.nb_product_access_status
    end,
    updated_at = now()
  where id = v_user_id;

  if TG_OP = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_membership_subscriptions_sync_user on public.membership_subscriptions;
create trigger trg_membership_subscriptions_sync_user
  after insert or update or delete on public.membership_subscriptions
  for each row execute function public.sync_user_subscription_tier();

create or replace view public.effective_user_access
with (security_invoker = true)
as
select
  u.id as user_id,
  u.is_anonymous,
  case
    when u.is_anonymous and u.product_access_status = 'guest' then 'guest'
    else public.current_plan_for_user(u.id)::text
  end as product_access,
  public.current_plan_for_user(u.id) as membership_plan,
  u.sale_status,
  u.onboarding_status,
  u.updated_at
from public.users u;

create or replace function public.can_consume_quota(
  p_user_id uuid,
  p_feature_key text,
  p_period_key text,
  p_count integer default 1
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with plan as (
    select public.current_plan_for_user(p_user_id) as plan_code
  ),
  rule as (
    select r.max_count
    from public.usage_quota_rules r
    join plan p on p.plan_code = r.plan_code
    where r.feature_key = p_feature_key
      and r.is_active = true
    order by
      case r.period_unit
        when 'none' then 0
        when 'day' then 1
        when 'month' then 2
        else 3
      end
    limit 1
  ),
  counter as (
    select used_count
    from public.usage_quota_counters
    where user_id = p_user_id
      and feature_key = p_feature_key
      and period_key = p_period_key
  )
  select case
    when not exists (select 1 from rule) then true
    when (select max_count from rule) is null then true
    else coalesce((select used_count from counter), 0) + p_count <= (select max_count from rule)
  end
$$;

create or replace function public.usage_quota_period_key(
  p_period_unit text,
  p_at timestamptz,
  p_reset_timezone text
)
returns text
language sql
stable
as $$
  select case p_period_unit
    when 'day' then to_char(p_at at time zone p_reset_timezone, 'YYYY-MM-DD')
    when 'month' then to_char(p_at at time zone p_reset_timezone, 'YYYY-MM')
    when 'lifetime' then 'lifetime'
    else 'none'
  end
$$;

create or replace function public.usage_quota_reset_at(
  p_period_unit text,
  p_at timestamptz,
  p_reset_timezone text
)
returns timestamptz
language sql
stable
as $$
  select case p_period_unit
    when 'day' then (
      date_trunc('day', p_at at time zone p_reset_timezone) + interval '1 day'
    ) at time zone p_reset_timezone
    when 'month' then (
      date_trunc('month', p_at at time zone p_reset_timezone) + interval '1 month'
    ) at time zone p_reset_timezone
    else null::timestamptz
  end
$$;

create or replace function public.check_usage_quota(
  p_user_id uuid,
  p_request_id text,
  p_feature_key text,
  p_reset_timezone text default 'Asia/Ho_Chi_Minh',
  p_requested_at timestamptz default now()
)
returns table (
  allowed boolean,
  used_count integer,
  limit_count integer,
  reset_at timestamptz,
  reason_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_plan public.nb_membership_plan;
  v_period_unit text;
  v_rule_timezone text;
  v_period_key text;
  v_used_count integer := 0;
begin
  if p_user_id is null or nullif(btrim(p_feature_key), '') is null then
    raise exception 'QUOTA_REQUEST_INVALID';
  end if;

  if v_actor is not null and v_actor <> p_user_id then
    raise exception 'QUOTA_USER_MISMATCH';
  end if;

  v_plan := public.current_plan_for_user(p_user_id);

  select r.period_unit, r.max_count, coalesce(nullif(r.reset_timezone, ''), p_reset_timezone)
    into v_period_unit, limit_count, v_rule_timezone
  from public.usage_quota_rules r
  where r.plan_code = v_plan
    and r.feature_key = p_feature_key
    and r.is_active = true
  order by
    case r.period_unit
      when 'none' then 0
      when 'day' then 1
      when 'month' then 2
      when 'lifetime' then 3
      else 4
    end
  limit 1;

  if not found or v_period_unit = 'none' or limit_count is null then
    return query select true, 0, null::integer, null::timestamptz, null::text;
    return;
  end if;

  v_period_key := public.usage_quota_period_key(
    v_period_unit,
    p_requested_at,
    v_rule_timezone
  );
  reset_at := public.usage_quota_reset_at(
    v_period_unit,
    p_requested_at,
    v_rule_timezone
  );

  select coalesce(uqc.used_count, 0)
    into v_used_count
  from public.usage_quota_counters uqc
  where uqc.user_id = p_user_id
    and uqc.feature_key = p_feature_key
    and uqc.period_key = v_period_key;

  v_used_count := coalesce(v_used_count, 0);
  used_count := v_used_count;
  allowed := v_used_count + 1 <= limit_count;
  reason_code := case when allowed then null else 'quota_exceeded' end;

  return next;
end;
$$;

create or replace function public.commit_usage_quota(
  p_user_id uuid,
  p_request_id text,
  p_feature_key text,
  p_reset_timezone text default 'Asia/Ho_Chi_Minh',
  p_requested_at timestamptz default now(),
  p_count integer default 1
)
returns table (
  committed boolean,
  used_count integer,
  limit_count integer,
  reset_at timestamptz,
  reason_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_decision record;
  v_plan public.nb_membership_plan;
  v_period_unit text := 'none';
  v_rule_timezone text := p_reset_timezone;
  v_period_key text := 'none';
  v_rows integer := 0;
begin
  if nullif(btrim(p_request_id), '') is null or p_count <= 0 then
    raise exception 'QUOTA_COMMIT_INVALID';
  end if;

  select *
    into v_decision
  from public.check_usage_quota(
    p_user_id,
    p_request_id,
    p_feature_key,
    p_reset_timezone,
    p_requested_at
  );

  if not coalesce(v_decision.allowed, false) then
    return query select
      false,
      v_decision.used_count,
      v_decision.limit_count,
      v_decision.reset_at,
      coalesce(v_decision.reason_code, 'quota_exceeded');
    return;
  end if;

  v_plan := public.current_plan_for_user(p_user_id);

  select r.period_unit, r.max_count, coalesce(nullif(r.reset_timezone, ''), p_reset_timezone)
    into v_period_unit, limit_count, v_rule_timezone
  from public.usage_quota_rules r
  where r.plan_code = v_plan
    and r.feature_key = p_feature_key
    and r.is_active = true
  order by
    case r.period_unit
      when 'none' then 0
      when 'day' then 1
      when 'month' then 2
      when 'lifetime' then 3
      else 4
    end
  limit 1;

  v_period_unit := coalesce(v_period_unit, 'none');
  v_period_key := public.usage_quota_period_key(
    v_period_unit,
    p_requested_at,
    v_rule_timezone
  );
  reset_at := public.usage_quota_reset_at(
    v_period_unit,
    p_requested_at,
    v_rule_timezone
  );

  insert into public.usage_events (
    user_id,
    feature_key,
    period_key,
    count_delta,
    idempotency_key,
    event_source,
    metadata
  )
  values (
    p_user_id,
    p_feature_key,
    v_period_key,
    p_count,
    p_request_id,
    'trusted_backend',
    jsonb_build_object('plan_code', v_plan)
  )
  on conflict (user_id, feature_key, idempotency_key) do nothing;

  get diagnostics v_rows = row_count;

  if v_rows > 0 and v_period_unit <> 'none' and limit_count is not null then
    insert into public.usage_quota_counters (
      user_id,
      feature_key,
      period_key,
      plan_code,
      used_count,
      limit_count,
      reset_at
    )
    values (
      p_user_id,
      p_feature_key,
      v_period_key,
      v_plan,
      p_count,
      limit_count,
      reset_at
    )
    on conflict (user_id, feature_key, period_key) do update
    set
      used_count = public.usage_quota_counters.used_count + excluded.used_count,
      plan_code = excluded.plan_code,
      limit_count = excluded.limit_count,
      reset_at = excluded.reset_at,
      updated_at = now();
  end if;

  if v_period_unit <> 'none' and limit_count is not null then
    select coalesce(uqc.used_count, 0)
      into used_count
    from public.usage_quota_counters uqc
    where uqc.user_id = p_user_id
      and uqc.feature_key = p_feature_key
      and uqc.period_key = v_period_key;
  else
    used_count := 0;
    limit_count := null;
    reset_at := null;
  end if;

  committed := true;
  reason_code := null;
  return next;
end;
$$;

create or replace function public.check_personal_schedule_generation_quota(
  p_user_id uuid,
  p_request_id text,
  p_feature_key text default 'personal_schedule_generation',
  p_reset_timezone text default 'Asia/Ho_Chi_Minh',
  p_requested_at timestamptz default now()
)
returns table (
  allowed boolean,
  used_count integer,
  limit_count integer,
  reset_at timestamptz,
  reason_code text
)
language sql
security definer
set search_path = public
as $$
  select *
  from public.check_usage_quota(
    p_user_id,
    p_request_id,
    coalesce(nullif(p_feature_key, ''), 'personal_schedule_generation'),
    p_reset_timezone,
    p_requested_at
  )
$$;

create or replace function public.commit_personal_schedule_generation_quota(
  p_user_id uuid,
  p_request_id text,
  p_feature_key text default 'personal_schedule_generation',
  p_reset_timezone text default 'Asia/Ho_Chi_Minh',
  p_committed_at timestamptz default now()
)
returns table (
  committed boolean,
  used_count integer,
  limit_count integer,
  reset_at timestamptz,
  reason_code text
)
language sql
security definer
set search_path = public
as $$
  select *
  from public.commit_usage_quota(
    p_user_id,
    p_request_id,
    coalesce(nullif(p_feature_key, ''), 'personal_schedule_generation'),
    p_reset_timezone,
    p_committed_at
  )
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'membership_plans',
    'plan_entitlements',
    'membership_subscriptions',
    'usage_quota_rules',
    'usage_quota_counters'
  ]
  loop
    execute format('drop trigger if exists %I on public.%I', 'trg_' || table_name || '_updated_at', table_name);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
      'trg_' || table_name || '_updated_at',
      table_name
    );
  end loop;
end;
$$;

alter table public.membership_plans enable row level security;
alter table public.plan_entitlements enable row level security;
alter table public.membership_subscriptions enable row level security;
alter table public.usage_quota_rules enable row level security;
alter table public.usage_quota_counters enable row level security;
alter table public.usage_events enable row level security;

drop policy if exists membership_plans_read_authenticated on public.membership_plans;
drop policy if exists plan_entitlements_read_authenticated on public.plan_entitlements;
drop policy if exists usage_quota_rules_read_authenticated on public.usage_quota_rules;

create policy membership_plans_read_authenticated
  on public.membership_plans for select to authenticated
  using (is_active = true);

create policy plan_entitlements_read_authenticated
  on public.plan_entitlements for select to authenticated
  using (is_active = true);

create policy usage_quota_rules_read_authenticated
  on public.usage_quota_rules for select to authenticated
  using (is_active = true);

drop policy if exists membership_subscriptions_select_own on public.membership_subscriptions;
create policy membership_subscriptions_select_own
  on public.membership_subscriptions for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists usage_quota_counters_select_own on public.usage_quota_counters;
create policy usage_quota_counters_select_own
  on public.usage_quota_counters for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists usage_events_select_own on public.usage_events;
create policy usage_events_select_own
  on public.usage_events for select to authenticated
  using (user_id = (select auth.uid()));

grant select on
  public.membership_plans,
  public.plan_entitlements,
  public.membership_subscriptions,
  public.usage_quota_rules,
  public.usage_quota_counters,
  public.usage_events,
  public.effective_user_access
to authenticated;

revoke insert, update, delete on
  public.membership_plans,
  public.plan_entitlements,
  public.membership_subscriptions,
  public.usage_quota_rules,
  public.usage_quota_counters,
  public.usage_events
from anon, authenticated;

grant execute on function public.check_usage_quota(uuid, text, text, text, timestamptz)
  to authenticated;
grant execute on function public.commit_usage_quota(uuid, text, text, text, timestamptz, integer)
  to authenticated;
grant execute on function public.check_personal_schedule_generation_quota(uuid, text, text, text, timestamptz)
  to authenticated;
grant execute on function public.commit_personal_schedule_generation_quota(uuid, text, text, text, timestamptz)
  to authenticated;

-- ---------------------------------------------------------------------------

-- 04. FamilyPlus

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): tao family plus schema
-- NanoBio / BioAI - FamilyPlus data boundary draft.
-- Run after 01-core-auth-profile.sql and 03-membership-quota.sql.

create table if not exists public.family_groups (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  plan_subscription_id uuid references public.membership_subscriptions(id) on delete set null,
  display_name text not null,
  status text not null default 'active'
    check (status in ('active', 'paused', 'closed')),
  last_idempotency_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_group_id uuid not null references public.family_groups(id) on delete cascade,
  subject_id uuid not null references public.health_subjects(id) on delete cascade,
  user_id uuid references public.users(id) on delete set null,
  invited_email text,
  display_name text not null,
  role text not null default 'member'
    check (role in ('owner', 'adult', 'member', 'child', 'viewer')),
  status text not null default 'active'
    check (status in ('invited', 'active', 'removed')),
  can_view boolean not null default true,
  can_edit boolean not null default false,
  last_idempotency_key text,
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_group_id, subject_id)
);

alter table public.family_groups
  add column if not exists last_idempotency_key text;

alter table public.family_members
  add column if not exists last_idempotency_key text;

create unique index if not exists idx_family_members_group_user_unique
  on public.family_members (family_group_id, user_id)
  where user_id is not null and status <> 'removed';

create unique index if not exists idx_family_groups_owner_active_unique
  on public.family_groups (owner_user_id)
  where status = 'active';

create index if not exists idx_family_groups_owner_status
  on public.family_groups (owner_user_id, status);

create index if not exists idx_family_members_subject
  on public.family_members (subject_id);

create index if not exists idx_family_members_user_status
  on public.family_members (user_id, status)
  where user_id is not null;

drop trigger if exists trg_family_groups_updated_at on public.family_groups;
create trigger trg_family_groups_updated_at
  before update on public.family_groups
  for each row execute function public.set_updated_at();

drop trigger if exists trg_family_members_updated_at on public.family_members;
create trigger trg_family_members_updated_at
  before update on public.family_members
  for each row execute function public.set_updated_at();

create or replace function public.can_read_health_subject(p_subject_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.health_subjects hs
    where hs.id = p_subject_id
      and hs.is_active = true
      and (
        hs.owner_user_id = (select auth.uid())
        or hs.linked_user_id = (select auth.uid())
        or exists (
          select 1
          from public.family_members target_member
          join public.family_groups fg
            on fg.id = target_member.family_group_id
          left join public.family_members actor_member
            on actor_member.family_group_id = target_member.family_group_id
           and actor_member.user_id = (select auth.uid())
           and actor_member.status = 'active'
          where target_member.subject_id = hs.id
            and target_member.status = 'active'
            and fg.status = 'active'
            and (
              fg.owner_user_id = (select auth.uid())
              or actor_member.can_view = true
            )
        )
      )
  )
$$;

create or replace function public.can_write_health_subject(p_subject_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.health_subjects hs
    where hs.id = p_subject_id
      and hs.is_active = true
      and (
        hs.owner_user_id = (select auth.uid())
        or exists (
          select 1
          from public.family_members target_member
          join public.family_groups fg
            on fg.id = target_member.family_group_id
          join public.family_members actor_member
            on actor_member.family_group_id = target_member.family_group_id
           and actor_member.user_id = (select auth.uid())
           and actor_member.status = 'active'
          where target_member.subject_id = hs.id
            and target_member.status = 'active'
            and fg.status = 'active'
            and (
              fg.owner_user_id = (select auth.uid())
              or actor_member.can_edit = true
            )
        )
      )
  )
$$;

create or replace function public.assert_current_user_familyplus()
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.membership_subscriptions ms
    where ms.user_id = v_user_id
      and ms.plan_code = 'family_plus'
      and ms.status = 'active'
      and (ms.ends_at is null or ms.ends_at > now())
  ) then
    raise exception 'FAMILYPLUS_REQUIRED' using errcode = '42501';
  end if;

  return v_user_id;
end;
$$;

create or replace function public.familyplus_context_for_user(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_group public.family_groups%rowtype;
  v_self_subject_id uuid;
  v_has_familyplus boolean;
  v_members jsonb := '[]'::jsonb;
begin
  select exists (
    select 1
    from public.membership_subscriptions ms
    where ms.user_id = p_user_id
      and ms.plan_code = 'family_plus'
      and ms.status = 'active'
      and (ms.ends_at is null or ms.ends_at > now())
  ) into v_has_familyplus;

  select hs.id into v_self_subject_id
  from public.health_subjects hs
  where hs.owner_user_id = p_user_id
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1;

  select * into v_group
  from public.family_groups fg
  where fg.owner_user_id = p_user_id
    and fg.status = 'active'
  order by fg.created_at desc
  limit 1;

  if v_group.id is not null then
    select coalesce(jsonb_agg(
      jsonb_build_object(
        'id', fm.id,
        'family_group_id', fm.family_group_id,
        'subject_id', fm.subject_id,
        'user_id', fm.user_id,
        'display_name', fm.display_name,
        'role', fm.role,
        'status', fm.status,
        'can_view', fm.can_view,
        'can_edit', fm.can_edit
      )
      order by fm.created_at asc
    ), '[]'::jsonb)
    into v_members
    from public.family_members fm
    where fm.family_group_id = v_group.id;
  end if;

  return jsonb_build_object(
    'actor_id', p_user_id,
    'self_subject_id', v_self_subject_id,
    'has_family_plus', coalesce(v_has_familyplus, false),
    'group', case when v_group.id is null then null else jsonb_build_object(
      'id', v_group.id,
      'owner_user_id', v_group.owner_user_id,
      'display_name', v_group.display_name,
      'status', v_group.status
    ) end,
    'members', v_members,
    'selected_subject_id', v_self_subject_id
  );
end;
$$;

create or replace function public.get_my_familyplus_context()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.familyplus_context_for_user(public.assert_current_user_familyplus())
$$;

create or replace function public.upsert_my_familyplus_group(
  p_display_name text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.assert_current_user_familyplus();
  v_display_name text := nullif(btrim(coalesce(p_display_name, '')), '');
  v_idempotency_key text := nullif(btrim(coalesce(p_idempotency_key, '')), '');
  v_subscription_id uuid;
  v_group_id uuid;
begin
  if v_display_name is null or v_idempotency_key is null then
    raise exception 'INVALID_FAMILYPLUS_GROUP' using errcode = '22023';
  end if;

  select ms.id into v_subscription_id
  from public.membership_subscriptions ms
  where ms.user_id = v_user_id
    and ms.plan_code = 'family_plus'
    and ms.status = 'active'
    and (ms.ends_at is null or ms.ends_at > now())
  order by ms.starts_at desc
  limit 1;

  insert into public.family_groups (
    owner_user_id,
    plan_subscription_id,
    display_name,
    status,
    last_idempotency_key
  )
  values (
    v_user_id,
    v_subscription_id,
    v_display_name,
    'active',
    v_idempotency_key
  )
  on conflict do nothing;

  select fg.id into v_group_id
  from public.family_groups fg
  where fg.owner_user_id = v_user_id
    and fg.status = 'active'
  order by fg.created_at desc
  limit 1;

  update public.family_groups
  set
    display_name = v_display_name,
    plan_subscription_id = coalesce(v_subscription_id, plan_subscription_id),
    last_idempotency_key = v_idempotency_key,
    updated_at = now()
  where id = v_group_id;

  return public.familyplus_context_for_user(v_user_id);
end;
$$;

create or replace function public.upsert_my_familyplus_member(
  p_subject_id uuid,
  p_display_name text,
  p_role text default 'member',
  p_can_view boolean default true,
  p_can_edit boolean default false,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.assert_current_user_familyplus();
  v_display_name text := nullif(btrim(coalesce(p_display_name, '')), '');
  v_role text := lower(nullif(btrim(coalesce(p_role, 'member')), ''));
  v_idempotency_key text := nullif(btrim(coalesce(p_idempotency_key, '')), '');
  v_group_id uuid;
  v_subject public.health_subjects%rowtype;
  v_existing_id uuid;
  v_active_count integer;
begin
  if p_subject_id is null or v_display_name is null or v_idempotency_key is null then
    raise exception 'INVALID_FAMILYPLUS_MEMBER' using errcode = '22023';
  end if;
  if v_role not in ('adult', 'member', 'child', 'viewer') then
    raise exception 'INVALID_FAMILYPLUS_ROLE' using errcode = '22023';
  end if;

  select * into v_subject
  from public.health_subjects hs
  where hs.id = p_subject_id
    and hs.owner_user_id = v_user_id
    and hs.is_active = true;

  if not found then
    raise exception 'FAMILYPLUS_SUBJECT_NOT_ALLOWED' using errcode = '42501';
  end if;

  select fg.id into v_group_id
  from public.family_groups fg
  where fg.owner_user_id = v_user_id
    and fg.status = 'active'
  order by fg.created_at desc
  limit 1;

  if v_group_id is null then
    raise exception 'FAMILYPLUS_GROUP_REQUIRED' using errcode = '22023';
  end if;

  select fm.id into v_existing_id
  from public.family_members fm
  where fm.family_group_id = v_group_id
    and fm.subject_id = p_subject_id
  limit 1;

  select count(*)::integer into v_active_count
  from public.family_members fm
  where fm.family_group_id = v_group_id
    and fm.status = 'active';

  if v_existing_id is null and v_active_count >= 5 then
    raise exception 'FAMILYPLUS_MEMBER_LIMIT' using errcode = '22023';
  end if;

  insert into public.family_members (
    family_group_id,
    subject_id,
    user_id,
    display_name,
    role,
    status,
    can_view,
    can_edit,
    joined_at,
    last_idempotency_key
  )
  values (
    v_group_id,
    p_subject_id,
    v_subject.linked_user_id,
    v_display_name,
    v_role,
    'active',
    coalesce(p_can_view, true),
    coalesce(p_can_edit, false),
    now(),
    v_idempotency_key
  )
  on conflict (family_group_id, subject_id)
  do update set
    user_id = excluded.user_id,
    display_name = excluded.display_name,
    role = excluded.role,
    status = 'active',
    can_view = excluded.can_view,
    can_edit = excluded.can_edit,
    joined_at = coalesce(public.family_members.joined_at, now()),
    last_idempotency_key = excluded.last_idempotency_key,
    updated_at = now();

  return public.familyplus_context_for_user(v_user_id);
end;
$$;

create or replace function public.remove_my_familyplus_member(
  p_member_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.assert_current_user_familyplus();
  v_idempotency_key text := nullif(btrim(coalesce(p_idempotency_key, '')), '');
begin
  if p_member_id is null or v_idempotency_key is null then
    raise exception 'INVALID_FAMILYPLUS_REMOVE' using errcode = '22023';
  end if;

  update public.family_members fm
  set
    status = 'removed',
    last_idempotency_key = v_idempotency_key,
    updated_at = now()
  from public.family_groups fg
  where fm.id = p_member_id
    and fm.family_group_id = fg.id
    and fg.owner_user_id = v_user_id
    and fg.status = 'active';

  if not found then
    raise exception 'FAMILYPLUS_MEMBER_NOT_FOUND' using errcode = '22023';
  end if;

  return public.familyplus_context_for_user(v_user_id);
end;
$$;

alter table public.family_groups enable row level security;
alter table public.family_members enable row level security;

drop policy if exists family_groups_select_allowed on public.family_groups;
create policy family_groups_select_allowed
  on public.family_groups for select to authenticated
  using (
    owner_user_id = (select auth.uid())
    or exists (
      select 1
      from public.family_members fm
      where fm.family_group_id = id
        and fm.user_id = (select auth.uid())
        and fm.status = 'active'
    )
  );

drop policy if exists family_members_select_allowed on public.family_members;
create policy family_members_select_allowed
  on public.family_members for select to authenticated
  using (
    exists (
      select 1
      from public.family_groups fg
      where fg.id = family_group_id
        and fg.owner_user_id = (select auth.uid())
    )
    or exists (
      select 1
      from public.family_members actor
      where actor.family_group_id = family_members.family_group_id
        and actor.user_id = (select auth.uid())
        and actor.status = 'active'
        and actor.can_view = true
    )
  );

grant select on public.family_groups, public.family_members to authenticated;

revoke insert, update, delete on public.family_groups, public.family_members from anon, authenticated;
revoke all on function public.assert_current_user_familyplus() from public, anon, authenticated;
revoke all on function public.familyplus_context_for_user(uuid) from public, anon, authenticated;
revoke all on function public.get_my_familyplus_context() from public, anon;
revoke all on function public.upsert_my_familyplus_group(text, text) from public, anon;
revoke all on function public.upsert_my_familyplus_member(uuid, text, text, boolean, boolean, text)
  from public, anon;
revoke all on function public.remove_my_familyplus_member(uuid, text) from public, anon;

grant execute on function public.get_my_familyplus_context() to authenticated;
grant execute on function public.upsert_my_familyplus_group(text, text) to authenticated;
grant execute on function public.upsert_my_familyplus_member(uuid, text, text, boolean, boolean, text)
  to authenticated;
grant execute on function public.remove_my_familyplus_member(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------

-- 05. Sale/referral/payment/commission direct-only

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): cap nhat sale referral direct-only
-- NanoBio / BioAI - Sale/referral, payment event and direct 10% commission draft.
-- Run after 01-core-auth-profile.sql and 03-membership-quota.sql.
-- Draft only: review in sandbox/staging before production migration.

create table if not exists public.sale_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  status public.nb_sale_status not null default 'pending',
  approved_at timestamptz,
  suspended_at timestamptz,
  closed_at timestamptz,
  terms_version text,
  terms_accepted_at timestamptz,
  participation_device_hash text,
  note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.referral_codes (
  code text primary key,
  sale_user_id uuid not null references public.sale_profiles(user_id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'revoked')),
  created_at timestamptz not null default now(),
  revoked_at timestamptz
);

create unique index if not exists idx_referral_codes_active_sale_user
  on public.referral_codes (sale_user_id)
  where status = 'active';

create table if not exists public.referral_relationships (
  id uuid primary key default gen_random_uuid(),
  referrer_user_id uuid not null references public.users(id) on delete restrict,
  referred_user_id uuid not null references public.users(id) on delete cascade,
  referral_code text references public.referral_codes(code) on delete set null,
  accepted_at timestamptz not null default now(),
  source text not null default 'signup'
    check (source in ('signup', 'manual_admin', 'migration')),
  status text not null default 'active'
    check (status in ('active', 'voided')),
  device_hash text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint referral_relationship_no_self
    check (referrer_user_id <> referred_user_id),
  unique (referred_user_id)
);

create index if not exists idx_referral_relationships_referrer
  on public.referral_relationships (referrer_user_id, created_at desc);
create index if not exists idx_referral_relationships_referred_status
  on public.referral_relationships (referred_user_id, status);

create index if not exists idx_referral_relationships_device_hash
  on public.referral_relationships (device_hash)
  where device_hash is not null;

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  payer_user_id uuid not null references public.users(id) on delete restrict,
  subscription_id uuid references public.membership_subscriptions(id) on delete set null,
  plan_code public.nb_membership_plan not null,
  provider text not null,
  provider_event_id text not null,
  amount_cents integer not null check (amount_cents >= 0),
  list_price_cents integer check (list_price_cents is null or list_price_cents >= 0),
  commission_base_cents integer check (commission_base_cents is null or commission_base_cents >= 0),
  currency text not null default 'VND',
  status text not null
    check (status in ('pending', 'succeeded', 'refunded', 'chargeback', 'failed')),
  paid_at timestamptz,
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  review_reason text,
  idempotency_key text,
  raw_event_hash text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (provider, provider_event_id)
);

create index if not exists idx_payment_events_payer_paid
  on public.payment_events (payer_user_id, paid_at desc);
create index if not exists idx_payment_events_status_created
  on public.payment_events (status, created_at desc);
create index if not exists idx_payment_events_status_paid
  on public.payment_events (status, paid_at desc);
create index if not exists idx_sale_profiles_status_created
  on public.sale_profiles (status, created_at desc);

create table if not exists public.commission_rates (
  code text primary key default 'direct_referral',
  rate numeric(5, 4) not null check (rate >= 0 and rate <= 1),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commission_records (
  id uuid primary key default gen_random_uuid(),
  payment_event_id uuid not null references public.payment_events(id) on delete cascade,
  receiver_user_id uuid not null references public.users(id) on delete restrict,
  payer_user_id uuid not null references public.users(id) on delete restrict,
  source_referral_id uuid references public.referral_relationships(id) on delete set null,
  rate numeric(5, 4) not null check (rate >= 0 and rate <= 1),
  amount_cents integer not null check (amount_cents >= 0),
  currency text not null default 'VND',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'reversed', 'paid')),
  available_at timestamptz not null default (now() + interval '24 hours'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (payment_event_id, receiver_user_id)
);

create index if not exists idx_commission_records_receiver_created
  on public.commission_records (receiver_user_id, created_at desc);
create index if not exists idx_commission_records_receiver_status_available
  on public.commission_records (receiver_user_id, status, available_at, created_at desc);
create index if not exists idx_commission_records_payment
  on public.commission_records (payment_event_id);

drop trigger if exists trg_sale_profiles_updated_at on public.sale_profiles;
create trigger trg_sale_profiles_updated_at
  before update on public.sale_profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_commission_rates_updated_at on public.commission_rates;
create trigger trg_commission_rates_updated_at
  before update on public.commission_rates
  for each row execute function public.set_updated_at();

drop trigger if exists trg_commission_records_updated_at on public.commission_records;
create trigger trg_commission_records_updated_at
  before update on public.commission_records
  for each row execute function public.set_updated_at();

create or replace function public.sync_user_sale_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'DELETE' then
    update public.users
    set sale_status = 'none', updated_at = now()
    where id = old.user_id;
    return old;
  end if;

  update public.users
  set sale_status = new.status, updated_at = now()
  where id = new.user_id;

  return new;
end;
$$;

drop trigger if exists trg_sale_profiles_sync_user on public.sale_profiles;
create trigger trg_sale_profiles_sync_user
  after insert or update or delete on public.sale_profiles
  for each row execute function public.sync_user_sale_status();

create or replace function public.create_commission_records_for_payment(
  p_payment_event_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.payment_events%rowtype;
  v_direct public.referral_relationships%rowtype;
  v_rate numeric(5, 4);
  v_base_cents integer;
begin
  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
    and status = 'succeeded'
    and paid_at is not null;

  if not found then
    return;
  end if;

  select * into v_direct
  from public.referral_relationships
  where referred_user_id = v_payment.payer_user_id
    and status = 'active'
  limit 1;

  if not found then
    return;
  end if;

  select rate into v_rate
  from public.commission_rates
  where code = 'direct_referral' and is_active = true;

  if v_rate is null then
    return;
  end if;

  v_base_cents := coalesce(
    v_payment.commission_base_cents,
    v_payment.list_price_cents,
    nullif(v_payment.metadata ->> 'commission_base_cents', '')::integer,
    nullif(v_payment.metadata ->> 'list_price_cents', '')::integer,
    v_payment.amount_cents
  );

  if exists (
    select 1 from public.sale_profiles
    where user_id = v_direct.referrer_user_id
      and status = 'active'
  ) then
    insert into public.commission_records (
      payment_event_id,
      receiver_user_id,
      payer_user_id,
      source_referral_id,
      rate,
      amount_cents,
      currency,
      status,
      available_at
    )
    values (
      v_payment.id,
      v_direct.referrer_user_id,
      v_payment.payer_user_id,
      v_direct.id,
      v_rate,
      round(v_base_cents * v_rate)::integer,
      v_payment.currency,
      'pending',
      coalesce(v_payment.paid_at, now()) + interval '24 hours'
    )
    on conflict (payment_event_id, receiver_user_id) do nothing;
  end if;
end;
$$;

create or replace function public.handle_successful_payment_commission()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'succeeded' and new.paid_at is not null then
    perform public.create_commission_records_for_payment(new.id);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_payment_events_create_commission on public.payment_events;
create trigger trg_payment_events_create_commission
  after insert or update of status, paid_at on public.payment_events
  for each row execute function public.handle_successful_payment_commission();

alter table public.sale_profiles enable row level security;
alter table public.referral_codes enable row level security;
alter table public.referral_relationships enable row level security;
alter table public.payment_events enable row level security;
alter table public.commission_rates enable row level security;
alter table public.commission_records enable row level security;

drop policy if exists sale_profiles_select_own on public.sale_profiles;
create policy sale_profiles_select_own
  on public.sale_profiles for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists referral_codes_select_own on public.referral_codes;
create policy referral_codes_select_own
  on public.referral_codes for select to authenticated
  using (sale_user_id = (select auth.uid()));

drop policy if exists referral_relationships_select_related on public.referral_relationships;
create policy referral_relationships_select_related
  on public.referral_relationships for select to authenticated
  using (
    referrer_user_id = (select auth.uid())
    or referred_user_id = (select auth.uid())
  );

drop policy if exists payment_events_select_payer on public.payment_events;
create policy payment_events_select_payer
  on public.payment_events for select to authenticated
  using (payer_user_id = (select auth.uid()));

drop policy if exists commission_rates_read_authenticated on public.commission_rates;
create policy commission_rates_read_authenticated
  on public.commission_rates for select to authenticated
  using (is_active = true);

drop policy if exists commission_records_select_receiver on public.commission_records;
create policy commission_records_select_receiver
  on public.commission_records for select to authenticated
  using (receiver_user_id = (select auth.uid()));

grant select on
  public.sale_profiles,
  public.referral_codes,
  public.referral_relationships,
  public.payment_events,
  public.commission_rates,
  public.commission_records
to authenticated;

revoke insert, update, delete on
  public.sale_profiles,
  public.referral_codes,
  public.referral_relationships,
  public.payment_events,
  public.commission_rates,
  public.commission_records
from anon, authenticated;

-- 10A. Mobile snapshot sync

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): them mobile snapshot sync va Sale RPC bao mat
-- NanoBio / BioAI - DRAFT migration.
-- Run AFTER 01-core-auth-profile.sql, 02-health-and-schedule.sql,
-- 03-membership-quota.sql and 05-sale-referral-commission.sql.
--
-- IMPORTANT:
-- 1. Review and run first in Supabase sandbox/staging.
-- 2. `sync_my_mobile_snapshot` is cloud-wins at login and local-wins only for
--    a pending guest snapshot whose cloud onboarding is not completed.
-- 3. This RPC deliberately never accepts membership, entitlement, sale status,
--    commission, payment or another user's subject identity from the mobile app.

-- ---------------------------------------------------------------------------
-- A. Mobile full-snapshot synchronisation
-- ---------------------------------------------------------------------------
-- A user may write only his/her own self-subject data. The payload comes from
-- the Flutter mapping; user_id and subject_id are overwritten server-side.
-- Collection rows are replaced atomically so removed local data is also removed
-- from cloud. This is intentional for a complete user-scoped snapshot, not a
-- generic multi-device conflict resolver.

create or replace function public.insert_mobile_snapshot_row(
  p_table_name text,
  p_user_id uuid,
  p_subject_id uuid,
  p_row jsonb,
  p_allowed_columns text[],
  p_include_subject boolean default true
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_payload jsonb;
  v_payload_columns text[];
  v_insert_columns text[];
  v_column_names text;
  v_select_names text;
  v_column_definitions text;
  v_matched_column_count integer;
begin
  if jsonb_typeof(p_row) <> 'object' then
    raise exception 'INVALID_SNAPSHOT_ROW for table %', p_table_name
      using errcode = '22023';
  end if;

  if p_include_subject and p_subject_id is null then
    raise exception 'SNAPSHOT_SUBJECT_REQUIRED for table %', p_table_name
      using errcode = '22023';
  end if;

  select coalesce(array_agg(c.column_name order by c.ordinality), array[]::text[])
  into v_payload_columns
  from unnest(p_allowed_columns) with ordinality as c(column_name, ordinality)
  where c.column_name not in ('user_id', 'subject_id')
    and p_row ? c.column_name
    and (p_row -> c.column_name) <> 'null'::jsonb;

  select coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
  into v_payload
  from jsonb_each(p_row) as e(key, value)
  where e.key = any(p_allowed_columns)
    and e.key not in ('user_id', 'subject_id')
    and e.value <> 'null'::jsonb;

  v_payload := v_payload || jsonb_build_object('user_id', p_user_id);
  v_insert_columns := array['user_id']::text[] || v_payload_columns;

  if p_include_subject then
    v_payload := v_payload || jsonb_build_object('subject_id', p_subject_id);
    v_insert_columns := array['user_id', 'subject_id']::text[] || v_payload_columns;
  end if;

  select
    string_agg(format('%I', c.column_name), ', ' order by c.ordinality),
    string_agg(format('x.%I', c.column_name), ', ' order by c.ordinality)
  into v_column_names, v_select_names
  from unnest(v_insert_columns) with ordinality as c(column_name, ordinality);

  select
    string_agg(
      format('%I %s', c.column_name, pg_catalog.format_type(a.atttypid, a.atttypmod)),
      ', ' order by c.ordinality
    ),
    count(*)
  into v_column_definitions, v_matched_column_count
  from unnest(v_insert_columns) with ordinality as c(column_name, ordinality)
  join pg_catalog.pg_class cls
    on cls.relname = p_table_name
  join pg_catalog.pg_namespace ns
    on ns.oid = cls.relnamespace and ns.nspname = 'public'
  join pg_catalog.pg_attribute a
    on a.attrelid = cls.oid
   and a.attname = c.column_name
   and a.attnum > 0
   and not a.attisdropped;

  if v_matched_column_count <> cardinality(v_insert_columns) then
    raise exception 'SNAPSHOT_SCHEMA_MISMATCH for table %', p_table_name
      using errcode = '22023';
  end if;

  execute format(
    'insert into public.%I (%s) select %s from jsonb_to_record($1) as x(%s)',
    p_table_name,
    v_column_names,
    v_select_names,
    v_column_definitions
  ) using v_payload;
end;
$$;

revoke all on function public.insert_mobile_snapshot_row(text, uuid, uuid, jsonb, text[], boolean)
from public, anon, authenticated;

create or replace function public.sync_my_mobile_snapshot(p_snapshot jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_subject_id uuid;
  v_user jsonb := coalesce(p_snapshot -> 'user', '{}'::jsonb);
  v_tables jsonb := coalesce(p_snapshot -> 'tables', '{}'::jsonb);
  v_table text;
  v_row jsonb;
  v_authoritative_row jsonb;
  v_authoritative_schedule_rows jsonb := '[]'::jsonb;
  v_allowed_columns text[];
  v_rows integer := 0;
  v_collection_tables text[] := array[
    'health_goals',
    'health_conditions',
    'food_allergies',
    'medical_treatments',
    'survey_answers',
    'meal_plans',
    'daily_health_tasks',
    'lifestyle_schedule_items',
    'notifications',
    'health_tracking_logs',
    'health_score_ledgers',
    'wellness_point_ledgers',
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations'
  ];
  v_singleton_tables text[] := array['health_profiles', 'lifestyle_habits'];
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if coalesce(jsonb_typeof(p_snapshot), '') <> 'object'
     or coalesce(jsonb_typeof(v_tables), '') <> 'object' then
    raise exception 'INVALID_SNAPSHOT' using errcode = '22023';
  end if;

  select id into v_subject_id
  from public.health_subjects
  where owner_user_id = v_user_id
    and subject_type = 'self'
    and is_active = true
  limit 1;

  if v_subject_id is null then
    insert into public.health_subjects (
      owner_user_id, linked_user_id, subject_type, display_name, relationship
    )
    values (v_user_id, v_user_id, 'self', 'Bạn', 'self')
    on conflict (owner_user_id) where subject_type = 'self'
    do update set linked_user_id = excluded.linked_user_id, is_active = true
    returning id into v_subject_id;
  end if;

  -- User-controlled profile fields only. Access and Sale states remain trusted
  -- server-owned fields.
  update public.users
  set
    phone = coalesce(nullif(v_user ->> 'phone', ''), phone),
    full_name = coalesce(nullif(v_user ->> 'full_name', ''), full_name),
    avatar_url = coalesce(nullif(v_user ->> 'avatar_url', ''), avatar_url),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    onboarding_status = case
      when v_user ->> 'onboarding_status' = 'completed' then 'completed'::public.nb_onboarding_status
      when v_user ->> 'onboarding_status' = 'in_progress' then 'in_progress'::public.nb_onboarding_status
      else onboarding_status
    end,
    onboarding_completed_at = case
      when v_user ->> 'onboarding_status' = 'completed'
        then coalesce(nullif(v_user ->> 'onboarding_completed_at', '')::timestamptz, now())
      else onboarding_completed_at
    end,
    updated_at = now()
  where id = v_user_id;

  update public.health_subjects
  set
    display_name = coalesce(nullif(v_user ->> 'full_name', ''), display_name),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    updated_at = now()
  where id = v_subject_id;

  -- Singleton records: exactly one row for this user's self subject.
  foreach v_table in array v_singleton_tables loop
    execute format(
      'delete from public.%I where user_id = $1 and subject_id = $2',
      v_table
    ) using v_user_id, v_subject_id;

    if v_table = 'health_profiles' then
      v_allowed_columns := array[
        'id', 'occupation', 'height_cm', 'weight_kg', 'bmi',
        'blood_pressure', 'blood_sugar'
      ];
    elsif v_table = 'lifestyle_habits' then
      v_allowed_columns := array[
        'id', 'skip_breakfast', 'eat_late', 'eat_sweet', 'eat_oily',
        'low_vegetable', 'low_water', 'fast_food', 'alcohol', 'coffee_high',
        'sleep_quality', 'activity_level', 'water_per_day'
      ];
    else
      raise exception 'UNSUPPORTED_SNAPSHOT_TABLE: %', v_table
        using errcode = '22023';
    end if;

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      perform public.insert_mobile_snapshot_row(
        v_table,
        v_user_id,
        v_subject_id,
        v_row,
        v_allowed_columns,
        true
      );
      v_rows := v_rows + 1;
    end loop;
  end loop;

  -- Collections: delete then recreate the self-scoped cloud projection. The
  -- client uses UUIDs, so source_id references are already mapped before RPC.
  foreach v_table in array v_collection_tables loop
    -- Legacy notifications may be user-scoped without a subject_id. Delete by
    -- owner so a complete snapshot cannot leave stale notification rows.
    if v_table = 'notifications' then
      execute 'delete from public.notifications where user_id = $1'
        using v_user_id;
    else
      execute format(
        'delete from public.%I where user_id = $1 and subject_id = $2',
        v_table
      ) using v_user_id, v_subject_id;
    end if;

    if v_table = 'health_goals' then
      v_allowed_columns := array['id', 'goal_code', 'goal_name', 'is_active'];
    elsif v_table = 'health_conditions' then
      v_allowed_columns := array[
        'id', 'condition_code', 'condition_name', 'severity_level'
      ];
    elsif v_table = 'food_allergies' then
      v_allowed_columns := array['id', 'allergy_name', 'note'];
    elsif v_table = 'medical_treatments' then
      v_allowed_columns := array[
        'id', 'treatment_name', 'medication_name', 'note'
      ];
    elsif v_table = 'survey_answers' then
      v_allowed_columns := array['id', 'question_code', 'answer_value'];
    elsif v_table = 'meal_plans' then
      v_allowed_columns := array[
        'id', 'plan_date', 'meal_type', 'meal_name', 'description', 'calories',
        'protein', 'carbs', 'fat', 'fiber', 'water_ml', 'meal_order',
        'start_time', 'end_time', 'cooking_instructions', 'is_completed',
        'ai_generated'
      ];
    elsif v_table = 'daily_health_tasks' then
      v_allowed_columns := array[
        'id', 'task_date', 'task_code', 'category', 'title', 'description',
        'target_value', 'current_value', 'unit', 'is_completed', 'sort_order',
        'source', 'encouragement'
      ];
    elsif v_table = 'lifestyle_schedule_items' then
      v_allowed_columns := array[
        'id', 'schedule_date', 'start_time', 'end_time', 'title', 'description',
        'category', 'source_type', 'source_id', 'target_value', 'current_value',
        'unit', 'is_completed', 'sort_order', 'ai_generated', 'encouragement'
      ];
    elsif v_table = 'notifications' then
      v_allowed_columns := array[
        'id', 'title', 'body', 'type', 'is_read', 'source_type', 'source_id',
        'scheduled_at', 'notification_id', 'action_status', 'responded_at', 'payload'
      ];
    elsif v_table = 'health_tracking_logs' then
      v_allowed_columns := array[
        'id', 'weight_kg', 'calories', 'water_ml', 'sleep_hours', 'stress_level',
        'steps_count', 'heart_rate_bpm', 'oxygen_saturation', 'daily_score',
        'mood', 'log_date'
      ];
    elsif v_table = 'health_score_ledgers' then
      v_allowed_columns := array[
        'id', 'period_start', 'period_end', 'score', 'formula_version',
        'breakdown', 'idempotency_key', 'calculated_at'
      ];
    elsif v_table = 'wellness_point_ledgers' then
      v_allowed_columns := array[
        'id', 'source_type', 'source_id', 'schedule_date', 'points_delta',
        'program_code', 'idempotency_key'
      ];
    elsif v_table = 'nutrition_logs' then
      v_allowed_columns := array[
        'id', 'food_name', 'calories', 'protein', 'carbs', 'fat', 'meal_type',
        'eaten_at'
      ];
    elsif v_table = 'ai_insights' then
      v_allowed_columns := array['id', 'insight_type', 'title', 'content', 'risk_level'];
    elsif v_table = 'ai_recommendations' then
      v_allowed_columns := array[
        'id', 'recommendation_type', 'title', 'description', 'action_text', 'is_read'
      ];
    else
      raise exception 'UNSUPPORTED_SNAPSHOT_TABLE: %', v_table
        using errcode = '22023';
    end if;

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      perform public.insert_mobile_snapshot_row(
        v_table,
        v_user_id,
        v_subject_id,
        v_row,
        v_allowed_columns,
        true
      );
      v_rows := v_rows + 1;
    end loop;
  end loop;

  delete from public.personal_schedule_ai_requests where user_id = v_user_id;
  v_allowed_columns := array[
    'request_id', 'actor_mode', 'status', 'start_date', 'days', 'meal_count',
    'exercise_count', 'schedule_item_count', 'error_code', 'completed_at'
  ];

  for v_row in
    select value from jsonb_array_elements(
      coalesce(v_tables -> 'personal_schedule_ai_requests', '[]'::jsonb)
    )
  loop
    perform public.insert_mobile_snapshot_row(
      'personal_schedule_ai_requests',
      v_user_id,
      null,
      v_row,
      v_allowed_columns,
      false
    );
    v_rows := v_rows + 1;
  end loop;

  return jsonb_build_object(
    'user_id', v_user_id,
    'subject_id', v_subject_id,
    'synced_rows', v_rows,
    'synced_at', now()
  );
end;
$$;

revoke all on function public.sync_my_mobile_snapshot(jsonb) from public, anon;
grant execute on function public.sync_my_mobile_snapshot(jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- 10B. Sale access guard used by final Sale RPCs
-- ---------------------------------------------------------------------------

create or replace function public.require_active_sale_user()
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or not exists (
    select 1
    from public.sale_profiles sp
    where sp.user_id = v_user_id
      and sp.status = 'active'
  ) then
    raise exception 'SALE_ACCESS_REQUIRED' using errcode = '42501';
  end if;

  return v_user_id;
end;
$$;

-- ---------------------------------------------------------------------------

-- 11. Admin access/dashboard/audit

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): tao admin access dashboard schema
-- NanoBio / BioAI - Admin roles, dashboard, CRUD RPC and audit draft.
-- Run after 01-core-auth-profile.sql, 03-membership-quota.sql and
-- 05-sale-referral-commission.sql.
-- Draft only: review in sandbox/staging before production migration.

alter table public.users
  add column if not exists admin_status text not null default 'active'
    check (admin_status in ('active', 'suspended', 'closed')),
  add column if not exists app_access_mode text not null default 'user'
    check (app_access_mode in ('user', 'admin', 'both'));

create table if not exists public.admin_roles (
  code text primary key
    check (code in (
      'super_admin',
      'finance_admin',
      'support_admin',
      'content_admin',
      'operations_admin'
    )),
  display_name text not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_permissions (
  code text primary key,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_role_permissions (
  role_code text not null references public.admin_roles(code) on delete cascade,
  permission_code text not null references public.admin_permissions(code) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role_code, permission_code)
);

create table if not exists public.admin_user_roles (
  user_id uuid not null references public.users(id) on delete cascade,
  role_code text not null references public.admin_roles(code) on delete restrict,
  scope text not null default 'global',
  is_active boolean not null default true,
  granted_by uuid references public.users(id) on delete set null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  primary key (user_id, role_code, scope)
);

-- Preserve the normal-user surface for existing active admins when upgrading
-- from the previous schema. Set app_access_mode = 'admin' explicitly for an
-- admin-only account.
update public.users u
set
  app_access_mode = 'both',
  updated_at = now()
where u.app_access_mode = 'user'
  and exists (
    select 1
    from public.admin_user_roles aur
    where aur.user_id = u.id
      and aur.is_active = true
      and aur.revoked_at is null
  );

revoke update (app_access_mode) on public.users from anon, authenticated;

create table if not exists public.admin_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text not null,
  reason text not null,
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (action, idempotency_key)
);

create table if not exists public.system_config_versions (
  id uuid primary key default gen_random_uuid(),
  config_key text not null,
  config_value jsonb not null default '{}'::jsonb,
  status text not null default 'active'
    check (status in ('draft', 'active', 'archived')),
  reason text not null,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (config_key, created_at)
);

create or replace function public.create_membership_payment_request(
  p_plan_code public.nb_membership_plan,
  p_billing_cycle text,
  p_idempotency_key text
)
returns table (
  payment_event_id uuid,
  plan_code text,
  billing_cycle text,
  status text,
  amount_cents integer,
  currency text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_config jsonb;
  v_amount_cents integer;
  v_currency text;
  v_provider text := 'manual_membership_request';
  v_provider_event_id text;
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if p_plan_code not in ('plus', 'family_plus') then
    raise exception 'INVALID_MEMBERSHIP_PLAN' using errcode = '22023';
  end if;

  if btrim(coalesce(p_billing_cycle, '')) not in ('monthly', 'yearly') then
    raise exception 'INVALID_BILLING_CYCLE' using errcode = '22023';
  end if;

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED' using errcode = '22023';
  end if;

  select scv.config_value
  into v_config
  from public.system_config_versions scv
  where scv.config_key = 'membership_payment_prices'
    and scv.status = 'active'
  order by scv.created_at desc
  limit 1;

  v_amount_cents := nullif(
    v_config #>> array['prices', p_plan_code::text, btrim(p_billing_cycle)],
    ''
  )::integer;
  v_currency := coalesce(nullif(v_config ->> 'currency', ''), 'VND');

  if v_amount_cents is null or v_amount_cents <= 0 then
    raise exception 'MEMBERSHIP_PAYMENT_PRICE_NOT_CONFIGURED'
      using errcode = '22023';
  end if;

  v_provider_event_id := concat(v_user_id::text, ':', btrim(p_idempotency_key));

  insert into public.payment_events (
    payer_user_id,
    plan_code,
    provider,
    provider_event_id,
    amount_cents,
    list_price_cents,
    commission_base_cents,
    currency,
    status,
    idempotency_key,
    metadata
  )
  values (
    v_user_id,
    p_plan_code,
    v_provider,
    v_provider_event_id,
    v_amount_cents,
    v_amount_cents,
    v_amount_cents,
    v_currency,
    'pending',
    btrim(p_idempotency_key),
    jsonb_build_object(
      'billing_cycle',
      btrim(p_billing_cycle),
      'manual_approval_required',
      true,
      'grants_access_before_approval',
      false
    )
  )
  on conflict (provider, provider_event_id) do update
  set metadata = public.payment_events.metadata || jsonb_build_object(
    'idempotent_replay',
    true
  )
  returning * into v_payment;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    coalesce(v_payment.metadata ->> 'billing_cycle', btrim(p_billing_cycle)),
    v_payment.status,
    v_payment.amount_cents,
    v_payment.currency,
    v_payment.created_at;
end;
$$;

create table if not exists public.report_exports (
  id uuid primary key default gen_random_uuid(),
  report_type text not null,
  filters jsonb not null default '{}'::jsonb,
  status text not null default 'requested'
    check (status in ('requested', 'generating', 'ready', 'failed')),
  reason text not null,
  requested_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.sale_point_adjustments (
  id uuid primary key default gen_random_uuid(),
  sale_user_id uuid not null references public.users(id) on delete restrict,
  point_delta_cents integer not null check (point_delta_cents <> 0),
  currency text not null default 'VND',
  status text not null default 'approved'
    check (status in ('approved', 'reversed')),
  reason text not null,
  reviewed_by uuid references public.users(id) on delete set null,
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (idempotency_key)
);

create table if not exists public.admin_reconciliation_runs (
  id uuid primary key default gen_random_uuid(),
  scope text not null default 'payments',
  status text not null default 'open'
    check (status in ('open', 'resolved', 'failed')),
  reason text not null,
  created_by uuid references public.users(id) on delete set null,
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (idempotency_key)
);

create table if not exists public.admin_reconciliation_discrepancies (
  id uuid primary key default gen_random_uuid(),
  run_id uuid references public.admin_reconciliation_runs(id) on delete set null,
  target_type text not null,
  target_id text not null,
  severity text not null default 'medium'
    check (severity in ('low', 'medium', 'high')),
  status text not null default 'open'
    check (status in ('open', 'needs_follow_up', 'resolved', 'adjusted', 'dismissed')),
  summary text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  review_reason text
);

create index if not exists idx_admin_user_roles_user_active
  on public.admin_user_roles (user_id, is_active, revoked_at);
create index if not exists idx_system_config_versions_key_status_created
  on public.system_config_versions (config_key, status, created_at desc);
create index if not exists idx_report_exports_requested_status_created
  on public.report_exports (requested_by, status, created_at desc);
create index if not exists idx_sale_point_adjustments_user_status_created
  on public.sale_point_adjustments (sale_user_id, status, created_at desc);
create index if not exists idx_admin_reconciliation_discrepancies_status_created
  on public.admin_reconciliation_discrepancies (status, created_at desc);
create index if not exists idx_admin_reconciliation_discrepancies_target
  on public.admin_reconciliation_discrepancies (target_id);
create index if not exists idx_admin_audit_events_created
  on public.admin_audit_events (created_at desc);
create index if not exists idx_admin_audit_events_target
  on public.admin_audit_events (target_id, created_at desc);

drop trigger if exists trg_admin_roles_updated_at on public.admin_roles;
create trigger trg_admin_roles_updated_at
  before update on public.admin_roles
  for each row execute function public.set_updated_at();

insert into public.admin_roles (code, display_name, description)
values
  ('super_admin', 'Super Admin', 'Full Admin control including roles and config.'),
  ('finance_admin', 'Finance Admin', 'Payment, Sale point and finance reports.'),
  ('support_admin', 'Support Admin', 'Customer support and user operations.'),
  ('content_admin', 'Content Admin', 'Content and plan configuration operations.'),
  ('operations_admin', 'Operations Admin', 'User, Sale and support operations.')
on conflict (code) do update
set
  display_name = excluded.display_name,
  description = excluded.description,
  is_active = true,
  updated_at = now();

insert into public.admin_permissions (code, description)
values
  ('*', 'All Admin permissions.'),
  ('dashboard.read', 'Read Admin dashboard.'),
  ('users.write', 'Manage user operational state.'),
  ('payments.write', 'Approve or reject payment events.'),
  ('sales.write', 'Approve or suspend Sale profiles.'),
  ('reconciliation.write', 'Run reconciliation and classify discrepancies.'),
  ('points.write', 'Adjust Sale points with Admin audit.'),
  ('plans.write', 'Version plan and package config.'),
  ('reports.write', 'Request report exports.'),
  ('audit.read', 'Read Admin audit events.'),
  ('config.write', 'Version system configuration.')
on conflict (code) do update
set description = excluded.description, is_active = true;

insert into public.admin_role_permissions (role_code, permission_code)
values
  ('super_admin', '*'),
  ('finance_admin', '*'),
  ('support_admin', '*'),
  ('content_admin', '*'),
  ('operations_admin', '*')
on conflict (role_code, permission_code) do nothing;

create or replace function public.admin_has_permission(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.admin_user_roles aur
    join public.admin_roles ar
      on ar.code = aur.role_code
     and ar.is_active = true
    join public.admin_role_permissions arp
      on arp.role_code = aur.role_code
    join public.admin_permissions ap
      on ap.code = arp.permission_code
     and ap.is_active = true
    where aur.user_id = auth.uid()
      and aur.is_active = true
      and aur.revoked_at is null
      and (ap.code = '*' or ap.code = p_permission)
  )
$$;

create or replace function public.admin_assert_permission(p_permission text)
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not public.admin_has_permission(p_permission) then
    raise exception 'ADMIN_PERMISSION_REQUIRED' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.admin_write_audit(
  p_action text,
  p_target_type text,
  p_target_id text,
  p_reason text,
  p_idempotency_key text,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if nullif(btrim(p_reason), '') is null then
    raise exception 'ADMIN_REASON_REQUIRED' using errcode = '22023';
  end if;

  insert into public.admin_audit_events (
    actor_id,
    action,
    target_type,
    target_id,
    reason,
    idempotency_key,
    metadata
  )
  values (
    auth.uid(),
    p_action,
    p_target_type,
    p_target_id,
    btrim(p_reason),
    nullif(btrim(p_idempotency_key), ''),
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (action, idempotency_key) do update
  set metadata = public.admin_audit_events.metadata
  returning id into v_id;

  return v_id;
end;
$$;

drop function if exists public.get_my_admin_session();

create or replace function public.get_my_admin_session()
returns table (
  user_id uuid,
  roles text[],
  permissions text[],
  is_active boolean,
  app_access_mode text,
  can_use_user_app boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    u.id as user_id,
    coalesce(
      array_agg(distinct aur.role_code)
        filter (where aur.role_code is not null),
      array[]::text[]
    ) as roles,
    coalesce(
      array_agg(distinct arp.permission_code)
        filter (where arp.permission_code is not null),
      array[]::text[]
    ) as permissions,
    exists (
      select 1
      from public.admin_user_roles active_aur
      where active_aur.user_id = u.id
        and active_aur.is_active = true
        and active_aur.revoked_at is null
    ) as is_active,
    u.app_access_mode,
    u.app_access_mode in ('user', 'both') as can_use_user_app
  from public.users u
  left join public.admin_user_roles aur
    on aur.user_id = u.id
   and aur.is_active = true
   and aur.revoked_at is null
  left join public.admin_role_permissions arp
    on arp.role_code = aur.role_code
  where u.id = auth.uid()
  group by u.id, u.app_access_mode
$$;

drop function if exists public.get_admin_dashboard_summary(timestamptz, timestamptz, text);

create or replace function public.get_admin_dashboard_summary(
  p_from timestamptz,
  p_to timestamptz,
  p_scope text default 'global',
  p_time_zone text default 'Asia/Ho_Chi_Minh'
)
returns table (
  metric_key text,
  label text,
  metric_value integer,
  status text,
  target_section text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_time_zone text := coalesce(nullif(p_time_zone, ''), 'Asia/Ho_Chi_Minh');
begin
  perform public.admin_assert_permission('dashboard.read');
  v_time_zone := case
    when v_time_zone = 'Asia/Ho_Chi_Minh' then v_time_zone
    else 'Asia/Ho_Chi_Minh'
  end;

  return query
  select 'users_total', 'Nguoi dung', count(*)::integer, 'ready', 'users'
  from public.users
  union all
  select 'onboarding_completed', 'Da hoan thanh onboarding', count(*)::integer, 'ready', 'users'
  from public.users u
  where u.onboarding_status = 'completed'
  union all
  select 'packages_active', 'Goi thanh vien active', count(*)::integer, 'active', 'plans'
  from public.membership_subscriptions ms
  where ms.status in ('trialing', 'active')
  union all
  select 'payments_pending', 'Payment cho duyet', count(*)::integer, 'pending', 'payments'
  from public.payment_events pe
  where pe.status = 'pending'
    and pe.created_at between p_from and p_to
  union all
  select 'payments_succeeded', 'Payment hop le', count(*)::integer, 'ready', 'payments'
  from public.payment_events pe
  where pe.status = 'succeeded'
    and coalesce(pe.paid_at, pe.created_at) between p_from and p_to
  union all
  select
    'revenue_succeeded',
    'Doanh thu da duyet',
    coalesce(sum(pe.amount_cents), 0)::integer,
    'ready',
    'reports'
  from public.payment_events pe
  where pe.status = 'succeeded'
    and coalesce(pe.paid_at, pe.created_at) between p_from and p_to
  union all
  select 'sales_active', 'Sale active', count(*)::integer, 'active', 'sales'
  from public.sale_profiles sp
  where sp.status = 'active'
  union all
  select 'familyplus_active', 'FamilyPlus active', count(*)::integer, 'active', 'users'
  from public.family_groups fg
  where fg.status = 'active'
  union all
  select
    'commission_available',
    'Diem Sale kha dung',
    coalesce(sum(cr.amount_cents), 0)::integer,
    'approved',
    'sale_conversions'
  from public.commission_records cr
  where cr.status in ('pending', 'approved')
    and cr.available_at <= now()
    and cr.created_at between p_from and p_to
  union all
  select
    'admin_alerts',
    'Can Admin xu ly',
    (
      (select count(*) from public.admin_reconciliation_discrepancies ard
       where ard.status in ('open', 'needs_follow_up'))
      + (select count(*) from public.payment_events pe
         where pe.status = 'pending' and pe.created_at between p_from and p_to)
    )::integer,
    'pending',
    'reconciliation';
end;
$$;

create or replace function public.admin_search_users(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('users.write');

  return query
  select
    u.id::text,
    coalesce(nullif(u.full_name, ''), nullif(u.email, ''), u.id::text),
    concat_ws(' - ', u.email, u.product_access_status::text, u.sale_status::text),
    u.admin_status,
    'users',
    u.created_at
  from public.users u
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or u.phone ilike '%' || p_query || '%'
  order by u.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_update_user_status(
  p_user_id uuid,
  p_status text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('users.write');

  if p_status not in ('active', 'suspended', 'closed') then
    raise exception 'INVALID_USER_STATUS' using errcode = '22023';
  end if;

  update public.users
  set admin_status = p_status, updated_at = now()
  where id = p_user_id;

  perform public.admin_write_audit(
    'admin_update_user_status',
    'user',
    p_user_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('status', p_status)
  );

  return query select true, 'Da cap nhat trang thai nguoi dung.';
end;
$$;

create or replace function public.admin_list_payments(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('payments.write');

  return query
  select
    pe.id::text,
    concat(pe.plan_code::text, ' - ', pe.amount_cents::text, ' ', pe.currency),
    concat_ws(' - ', coalesce(nullif(u.full_name, ''), u.email), pe.provider, pe.plan_code::text),
    pe.status,
    'payments',
    pe.created_at
  from public.payment_events pe
  join public.users u on u.id = pe.payer_user_id
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or pe.provider_event_id ilike '%' || p_query || '%'
  order by pe.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_review_payment(
  p_payment_event_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_payment public.payment_events%rowtype;
  v_status text;
  v_subscription_id uuid;
begin
  perform public.admin_assert_permission('payments.write');

  if p_decision not in ('approve', 'reject') then
    raise exception 'INVALID_PAYMENT_DECISION' using errcode = '22023';
  end if;

  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if v_payment.status <> 'pending' then
    raise exception 'PAYMENT_ALREADY_REVIEWED' using errcode = '22023';
  end if;

  v_status := case when p_decision = 'approve' then 'succeeded' else 'failed' end;

  update public.payment_events
  set
    status = v_status,
    paid_at = case when p_decision = 'approve' then coalesce(paid_at, now()) else paid_at end,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason),
    idempotency_key = nullif(btrim(p_idempotency_key), ''),
    metadata = metadata || jsonb_build_object(
      'admin_decision',
      p_decision,
      'manual_approval_required',
      true
    )
  where id = p_payment_event_id
  returning * into v_payment;

  if p_decision = 'approve' then
    insert into public.membership_subscriptions (
      user_id,
      plan_code,
      status,
      source,
      starts_at,
      provider,
      provider_subscription_id,
      metadata
    )
    values (
      v_payment.payer_user_id,
      v_payment.plan_code,
      'active',
      'payment_provider',
      now(),
      v_payment.provider,
      v_payment.provider_event_id,
      jsonb_build_object('payment_event_id', v_payment.id)
    )
    returning id into v_subscription_id;

    update public.payment_events
    set subscription_id = v_subscription_id
    where id = v_payment.id;
  end if;

  perform public.admin_write_audit(
    'admin_review_payment',
    'payment_event',
    p_payment_event_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('decision', p_decision)
  );

  return query select true, 'Da xu ly payment.';
end;
$$;

create or replace function public.record_trusted_payment_event(
  p_payer_user_id uuid,
  p_plan_code public.nb_membership_plan,
  p_provider text,
  p_provider_event_id text,
  p_amount_cents integer,
  p_list_price_cents integer default null,
  p_commission_base_cents integer default null,
  p_currency text default 'VND',
  p_auto_approve boolean default false,
  p_raw_event_hash text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_payment_id uuid;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
  v_list_price_cents integer;
  v_commission_base_cents integer;
begin
  v_list_price_cents := coalesce(
    p_list_price_cents,
    nullif(v_metadata ->> 'list_price_cents', '')::integer
  );
  v_commission_base_cents := coalesce(
    p_commission_base_cents,
    v_list_price_cents,
    nullif(v_metadata ->> 'commission_base_cents', '')::integer,
    p_amount_cents
  );

  insert into public.payment_events (
    payer_user_id,
    plan_code,
    provider,
    provider_event_id,
    amount_cents,
    list_price_cents,
    commission_base_cents,
    currency,
    status,
    paid_at,
    raw_event_hash,
    metadata
  )
  values (
    p_payer_user_id,
    p_plan_code,
    p_provider,
    p_provider_event_id,
    p_amount_cents,
    v_list_price_cents,
    v_commission_base_cents,
    coalesce(nullif(p_currency, ''), 'VND'),
    'pending',
    null,
    p_raw_event_hash,
    v_metadata || jsonb_build_object(
      'manual_approval_required',
      true,
      'auto_approve_requested',
      coalesce(p_auto_approve, false),
      'commission_base_policy',
      'list_price_owner_package_only'
    )
  )
  on conflict (provider, provider_event_id) do update
  set
    list_price_cents = coalesce(public.payment_events.list_price_cents, excluded.list_price_cents),
    commission_base_cents = coalesce(public.payment_events.commission_base_cents, excluded.commission_base_cents),
    metadata = public.payment_events.metadata || excluded.metadata
  returning id into v_payment_id;

  return v_payment_id;
end;
$$;

create or replace function public.create_sale_point_reversal_for_payment(
  p_payment_event_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_record record;
begin
  for v_record in
    select
      cr.id,
      cr.receiver_user_id,
      cr.amount_cents,
      cr.currency
    from public.commission_records cr
    where cr.payment_event_id = p_payment_event_id
      and cr.amount_cents > 0
  loop
    insert into public.sale_point_adjustments (
      sale_user_id,
      point_delta_cents,
      currency,
      reason,
      reviewed_by,
      idempotency_key,
      metadata
    )
    values (
      v_record.receiver_user_id,
      -v_record.amount_cents,
      v_record.currency,
      btrim(p_reason),
      auth.uid(),
      concat('sale-reversal-', v_record.id::text),
      jsonb_build_object(
        'payment_event_id',
        p_payment_event_id,
        'commission_record_id',
        v_record.id,
        'reversal_decision',
        p_decision,
        'ledger_policy',
        'negative_adjustment_without_overwriting_commission'
      )
    )
    on conflict (idempotency_key) do nothing;
  end loop;
end;
$$;

create or replace function public.admin_refund_or_cancel_payment(
  p_payment_event_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_payment public.payment_events%rowtype;
  v_status text;
begin
  perform public.admin_assert_permission('payments.write');

  if p_decision not in ('refund', 'cancel', 'chargeback') then
    raise exception 'INVALID_PAYMENT_REVERSAL_DECISION' using errcode = '22023';
  end if;

  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if coalesce(v_payment.paid_at, v_payment.reviewed_at, v_payment.created_at)
      < now() - interval '24 hours' then
    raise exception 'PAYMENT_REVERSAL_WINDOW_EXPIRED' using errcode = '22023';
  end if;

  v_status := case
    when p_decision = 'refund' then 'refunded'
    when p_decision = 'chargeback' then 'chargeback'
    else 'failed'
  end;

  update public.payment_events
  set
    status = v_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason),
    metadata = metadata || jsonb_build_object('admin_decision', p_decision)
  where id = p_payment_event_id;

  perform public.create_sale_point_reversal_for_payment(
    p_payment_event_id,
    p_decision,
    p_reason,
    p_idempotency_key
  );

  if v_payment.subscription_id is not null then
    update public.membership_subscriptions
    set status = 'canceled', ends_at = least(coalesce(ends_at, now()), now())
    where id = v_payment.subscription_id
      and status in ('trialing', 'active', 'past_due');
  end if;

  perform public.admin_write_audit(
    'admin_refund_or_cancel_payment',
    'payment_event',
    p_payment_event_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'decision',
      p_decision,
      'reversal_policy',
      'negative_sale_point_adjustment'
    )
  );

  return query select true, 'Da xu ly hoan huy va tru diem Sale neu co.';
end;
$$;

create or replace function public.admin_list_sales(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('sales.write');

  return query
  select
    sp.user_id::text,
    coalesce(nullif(u.full_name, ''), nullif(u.email, ''), sp.user_id::text),
    concat_ws(' - ', u.email, rc.code),
    sp.status::text,
    'sales',
    sp.created_at
  from public.sale_profiles sp
  join public.users u on u.id = sp.user_id
  left join public.referral_codes rc
    on rc.sale_user_id = sp.user_id
   and rc.status = 'active'
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or rc.code ilike '%' || p_query || '%'
  order by sp.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_review_sale_profile(
  p_sale_user_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status public.nb_sale_status;
  v_candidate text;
  v_created_code text;
begin
  perform public.admin_assert_permission('sales.write');

  v_status := case p_decision
    when 'approve' then 'active'::public.nb_sale_status
    when 'reject' then 'closed'::public.nb_sale_status
    when 'suspend' then 'suspended'::public.nb_sale_status
    when 'close' then 'closed'::public.nb_sale_status
    else null
  end;

  if v_status is null then
    raise exception 'INVALID_SALE_DECISION' using errcode = '22023';
  end if;

  if v_status = 'active' and not exists (
    select 1
    from public.membership_subscriptions ms
    where ms.user_id = p_sale_user_id
      and ms.plan_code in ('plus', 'family_plus')
      and ms.status = 'active'
      and ms.starts_at <= now()
      and (ms.ends_at is null or ms.ends_at > now())
  ) then
    raise exception 'SALE_REQUIRES_ACTIVE_PAID_PLAN' using errcode = '42501';
  end if;

  insert into public.sale_profiles (user_id, status, approved_at, note)
  values (
    p_sale_user_id,
    v_status,
    case when v_status = 'active' then now() else null end,
    btrim(p_reason)
  )
  on conflict (user_id) do update
  set
    status = excluded.status,
    approved_at = case
      when excluded.status = 'active' then coalesce(public.sale_profiles.approved_at, now())
      else public.sale_profiles.approved_at
    end,
    suspended_at = case
      when excluded.status = 'suspended' then now()
      else public.sale_profiles.suspended_at
    end,
    closed_at = case
      when excluded.status = 'closed' then now()
      else public.sale_profiles.closed_at
    end,
    note = excluded.note,
    updated_at = now();

  if v_status = 'active' and not exists (
    select 1
    from public.referral_codes
    where sale_user_id = p_sale_user_id
      and status = 'active'
  ) then
    for i in 1..12 loop
      v_candidate := 'NANO-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
      insert into public.referral_codes (code, sale_user_id, status)
      values (v_candidate, p_sale_user_id, 'active')
      on conflict (code) do nothing
      returning code into v_created_code;
      exit when v_created_code is not null;
    end loop;

    if v_created_code is null then
      raise exception 'REFERRAL_CODE_ALLOCATION_FAILED';
    end if;
  end if;

  perform public.admin_write_audit(
    'admin_review_sale_profile',
    'sale_profile',
    p_sale_user_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('decision', p_decision, 'status', v_status::text)
  );

  return query select true, 'Da cap nhat Sale.';
end;
$$;

create or replace function public.admin_upsert_config_version(
  p_config_key text,
  p_config_value jsonb,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_permission text;
begin
  v_permission := case
    when p_config_key ilike 'plan%' then 'plans.write'
    else 'config.write'
  end;

  perform public.admin_assert_permission(v_permission);

  update public.system_config_versions
  set status = 'archived'
  where config_key = p_config_key
    and status = 'active';

  insert into public.system_config_versions (
    config_key,
    config_value,
    status,
    reason,
    created_by
  )
  values (
    btrim(p_config_key),
    coalesce(p_config_value, '{}'::jsonb),
    'active',
    btrim(p_reason),
    auth.uid()
  );

  perform public.admin_write_audit(
    'admin_upsert_config_version',
    'system_config',
    p_config_key,
    p_reason,
    p_idempotency_key,
    coalesce(p_config_value, '{}'::jsonb)
  );

  return query select true, 'Da luu phien ban cau hinh.';
end;
$$;

create or replace function public.admin_list_config_versions(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('config.write');

  return query
  select
    scv.config_key,
    scv.config_key,
    scv.reason,
    scv.status,
    'config',
    scv.created_at
  from public.system_config_versions scv
  where coalesce(p_query, '') = ''
     or scv.config_key ilike '%' || p_query || '%'
  order by scv.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_list_plan_config_versions(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('plans.write');

  return query
  select
    scv.config_key,
    scv.config_key,
    scv.reason,
    scv.status,
    'plans',
    scv.created_at
  from public.system_config_versions scv
  where scv.config_key ilike 'plan%'
    and (
      coalesce(p_query, '') = ''
      or scv.config_key ilike '%' || p_query || '%'
    )
  order by scv.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_list_report_catalog(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('reports.write');

  return query
  select *
  from (
    values
      (
        'membership_summary',
        'Tong hop goi thanh vien',
        'So lieu goi, thanh toan va trang thai theo Asia/Ho_Chi_Minh',
        'available',
        'reports',
        now()
      ),
      (
        'sale_points_summary',
        'Tong hop diem Sale',
        'Doi soat diem, quy doi va dieu chinh noi bo',
        'available',
        'reports',
        now()
      ),
      (
        'admin_audit_summary',
        'Tong hop audit Admin',
        'Chi xuat tom tat hanh dong, khong xuat raw metadata',
        'available',
        'reports',
        now()
      )
  ) as catalog(id, title, subtitle, status, section, created_at)
  where coalesce(p_query, '') = ''
    or catalog.id ilike '%' || p_query || '%'
    or catalog.title ilike '%' || p_query || '%'
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_request_report_export(
  p_report_type text,
  p_filters jsonb,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_export_id uuid;
begin
  perform public.admin_assert_permission('reports.write');

  if btrim(coalesce(p_report_type, '')) not in (
    'membership_summary',
    'sale_points_summary',
    'admin_audit_summary'
  ) then
    raise exception 'INVALID_REPORT_TYPE' using errcode = '22023';
  end if;

  insert into public.report_exports (
    report_type,
    filters,
    reason,
    requested_by
  )
  values (
    btrim(p_report_type),
    jsonb_build_object(
      'report_type', btrim(p_report_type),
      'time_zone', coalesce(p_filters ->> 'time_zone', 'Asia/Ho_Chi_Minh'),
      'privacy', 'no_raw_payloads'
    ),
    btrim(p_reason),
    auth.uid()
  )
  returning id into v_export_id;

  perform public.admin_write_audit(
    'admin_request_report_export',
    'report_export',
    v_export_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'report_type', btrim(p_report_type),
      'time_zone', coalesce(p_filters ->> 'time_zone', 'Asia/Ho_Chi_Minh'),
      'privacy', 'no_raw_payloads'
    )
  );

  return query select true, 'Da tao yeu cau xuat bao cao.';
end;
$$;

create or replace function public.admin_list_report_exports(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('reports.write');

  return query
  select
    re.id::text,
    re.report_type,
    re.reason,
    re.status,
    'reports',
    re.created_at
  from public.report_exports re
  where coalesce(p_query, '') = ''
     or re.report_type ilike '%' || p_query || '%'
     or re.reason ilike '%' || p_query || '%'
  order by re.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_adjust_sale_points(
  p_sale_user_id uuid,
  p_point_delta_cents integer,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_adjustment_id uuid;
begin
  perform public.admin_assert_permission('points.write');

  if p_point_delta_cents is null or p_point_delta_cents = 0 then
    raise exception 'INVALID_POINT_ADJUSTMENT' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.sale_profiles
    where user_id = p_sale_user_id
  ) then
    raise exception 'SALE_PROFILE_NOT_FOUND' using errcode = '22023';
  end if;

  insert into public.sale_point_adjustments (
    sale_user_id,
    point_delta_cents,
    reason,
    reviewed_by,
    idempotency_key,
    metadata
  )
  values (
    p_sale_user_id,
    p_point_delta_cents,
    btrim(p_reason),
    auth.uid(),
    nullif(btrim(p_idempotency_key), ''),
    jsonb_build_object('approval_count_required', 1)
  )
  on conflict (idempotency_key) do update
  set metadata = public.sale_point_adjustments.metadata
  returning id into v_adjustment_id;

  perform public.admin_write_audit(
    'admin_adjust_sale_points',
    'sale_point_adjustment',
    v_adjustment_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'sale_user_id',
      p_sale_user_id,
      'point_delta_cents',
      p_point_delta_cents,
      'approval_count_required',
      1
    )
  );

  return query select true, 'Da ghi dieu chinh diem Sale.';
end;
$$;

create or replace function public.admin_create_reconciliation_run(
  p_scope text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_run_id uuid;
begin
  perform public.admin_assert_permission('reconciliation.write');

  insert into public.admin_reconciliation_runs (
    scope,
    status,
    reason,
    created_by,
    idempotency_key
  )
  values (
    coalesce(nullif(btrim(p_scope), ''), 'payments'),
    'open',
    btrim(p_reason),
    auth.uid(),
    nullif(btrim(p_idempotency_key), '')
  )
  on conflict (idempotency_key) do update
  set metadata = public.admin_reconciliation_runs.metadata
  returning id into v_run_id;

  insert into public.admin_reconciliation_discrepancies (
    run_id,
    target_type,
    target_id,
    severity,
    status,
    summary,
    metadata
  )
  select
    v_run_id,
    'payment_event',
    pe.id::text,
    'high',
    'open',
    'Payment da duyet nhung chua co subscription lien ket.',
    jsonb_build_object('payment_event_id', pe.id, 'plan_code', pe.plan_code)
  from public.payment_events pe
  where pe.status = 'succeeded'
    and pe.subscription_id is null
  on conflict do nothing;

  perform public.admin_write_audit(
    'admin_create_reconciliation_run',
    'admin_reconciliation_run',
    v_run_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('scope', p_scope)
  );

  return query select true, 'Da tao phien doi soat.';
end;
$$;

create or replace function public.admin_list_reconciliation_discrepancies(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('reconciliation.write');

  return query
  select
    ard.id::text,
    ard.summary,
    concat_ws(' - ', ard.target_type, ard.target_id, ard.severity),
    ard.status,
    'reconciliation',
    ard.created_at
  from public.admin_reconciliation_discrepancies ard
  where coalesce(p_query, '') = ''
     or ard.summary ilike '%' || p_query || '%'
     or ard.target_id = p_query
  order by ard.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_update_reconciliation_discrepancy_status(
  p_discrepancy_id uuid,
  p_status text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_discrepancy public.admin_reconciliation_discrepancies%rowtype;
begin
  perform public.admin_assert_permission('reconciliation.write');

  if p_status not in ('needs_follow_up', 'resolved', 'adjusted', 'dismissed') then
    raise exception 'INVALID_RECONCILIATION_STATUS' using errcode = '22023';
  end if;

  select * into v_discrepancy
  from public.admin_reconciliation_discrepancies
  where id = p_discrepancy_id
  for update;

  if not found then
    raise exception 'RECONCILIATION_DISCREPANCY_NOT_FOUND' using errcode = '22023';
  end if;

  update public.admin_reconciliation_discrepancies
  set
    status = p_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason)
  where id = p_discrepancy_id;

  if p_status = 'adjusted'
    and (v_discrepancy.metadata ? 'sale_user_id')
    and (v_discrepancy.metadata ? 'point_delta_cents') then
    insert into public.sale_point_adjustments (
      sale_user_id,
      point_delta_cents,
      reason,
      reviewed_by,
      idempotency_key,
      metadata
    )
    values (
      (v_discrepancy.metadata ->> 'sale_user_id')::uuid,
      (v_discrepancy.metadata ->> 'point_delta_cents')::integer,
      btrim(p_reason),
      auth.uid(),
      nullif(btrim(p_idempotency_key), ''),
      jsonb_build_object('reconciliation_discrepancy_id', p_discrepancy_id)
    )
    on conflict (idempotency_key) do update
    set metadata = public.sale_point_adjustments.metadata;
  end if;

  perform public.admin_write_audit(
    'admin_update_reconciliation_discrepancy_status',
    'admin_reconciliation_discrepancy',
    p_discrepancy_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('status', p_status)
  );

  return query select true, 'Da cap nhat doi soat.';
end;
$$;

create or replace function public.admin_list_audit_events(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  action text,
  actor_id text,
  target text,
  reason text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('audit.read');

  return query
  select
    aae.id::text,
    aae.action,
    coalesce(aae.actor_id::text, ''),
    aae.target_type || ':' || aae.target_id,
    aae.reason,
    aae.created_at
  from public.admin_audit_events aae
  where coalesce(p_query, '') = ''
     or aae.action ilike '%' || p_query || '%'
     or aae.target_id ilike '%' || p_query || '%'
     or aae.reason ilike '%' || p_query || '%'
  order by aae.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

alter table public.admin_roles enable row level security;
alter table public.admin_permissions enable row level security;
alter table public.admin_role_permissions enable row level security;
alter table public.admin_user_roles enable row level security;
alter table public.admin_audit_events enable row level security;
alter table public.system_config_versions enable row level security;
alter table public.report_exports enable row level security;
alter table public.sale_point_adjustments enable row level security;
alter table public.admin_reconciliation_runs enable row level security;
alter table public.admin_reconciliation_discrepancies enable row level security;

drop policy if exists admin_roles_read_admin on public.admin_roles;
create policy admin_roles_read_admin
  on public.admin_roles for select to authenticated
  using (public.admin_has_permission('audit.read'));

drop policy if exists admin_permissions_read_admin on public.admin_permissions;
create policy admin_permissions_read_admin
  on public.admin_permissions for select to authenticated
  using (public.admin_has_permission('audit.read'));

drop policy if exists admin_role_permissions_read_admin on public.admin_role_permissions;
create policy admin_role_permissions_read_admin
  on public.admin_role_permissions for select to authenticated
  using (public.admin_has_permission('audit.read'));

drop policy if exists admin_user_roles_read_self_or_admin on public.admin_user_roles;
create policy admin_user_roles_read_self_or_admin
  on public.admin_user_roles for select to authenticated
  using (
    user_id = (select auth.uid())
    or public.admin_has_permission('audit.read')
  );

drop policy if exists admin_audit_events_read_admin on public.admin_audit_events;
create policy admin_audit_events_read_admin
  on public.admin_audit_events for select to authenticated
  using (public.admin_has_permission('audit.read'));

drop policy if exists system_config_versions_read_admin on public.system_config_versions;
create policy system_config_versions_read_admin
  on public.system_config_versions for select to authenticated
  using (public.admin_has_permission('config.write'));

drop policy if exists report_exports_read_admin on public.report_exports;
create policy report_exports_read_admin
  on public.report_exports for select to authenticated
  using (public.admin_has_permission('reports.write'));

drop policy if exists sale_point_adjustments_read_admin on public.sale_point_adjustments;
create policy sale_point_adjustments_read_admin
  on public.sale_point_adjustments for select to authenticated
  using (public.admin_has_permission('points.write'));

drop policy if exists admin_reconciliation_runs_read_admin
  on public.admin_reconciliation_runs;
create policy admin_reconciliation_runs_read_admin
  on public.admin_reconciliation_runs for select to authenticated
  using (public.admin_has_permission('reconciliation.write'));

drop policy if exists admin_reconciliation_discrepancies_read_admin
  on public.admin_reconciliation_discrepancies;
create policy admin_reconciliation_discrepancies_read_admin
  on public.admin_reconciliation_discrepancies for select to authenticated
  using (public.admin_has_permission('reconciliation.write'));

grant select on
  public.admin_roles,
  public.admin_permissions,
  public.admin_role_permissions,
  public.admin_user_roles,
  public.admin_audit_events,
  public.system_config_versions,
  public.report_exports,
  public.sale_point_adjustments,
  public.admin_reconciliation_runs,
  public.admin_reconciliation_discrepancies
to authenticated;

revoke insert, update, delete on
  public.admin_roles,
  public.admin_permissions,
  public.admin_role_permissions,
  public.admin_user_roles,
  public.admin_audit_events,
  public.system_config_versions,
  public.report_exports,
  public.sale_point_adjustments,
  public.admin_reconciliation_runs,
  public.admin_reconciliation_discrepancies
from anon, authenticated;

grant execute on function public.get_my_admin_session() to authenticated;
grant execute on function public.get_admin_dashboard_summary(timestamptz, timestamptz, text, text) to authenticated;
grant execute on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
) to authenticated;
grant execute on function public.admin_search_users(text, integer) to authenticated;
grant execute on function public.admin_update_user_status(uuid, text, text, text) to authenticated;
grant execute on function public.admin_list_payments(text, integer) to authenticated;
grant execute on function public.admin_review_payment(uuid, text, text, text) to authenticated;
grant execute on function public.admin_refund_or_cancel_payment(uuid, text, text, text) to authenticated;
grant execute on function public.admin_list_sales(text, integer) to authenticated;
grant execute on function public.admin_review_sale_profile(uuid, text, text, text) to authenticated;
grant execute on function public.admin_upsert_config_version(text, jsonb, text, text) to authenticated;
grant execute on function public.admin_list_config_versions(text, integer) to authenticated;
grant execute on function public.admin_list_plan_config_versions(text, integer) to authenticated;
grant execute on function public.admin_list_report_catalog(text, integer) to authenticated;
grant execute on function public.admin_request_report_export(text, jsonb, text, text) to authenticated;
grant execute on function public.admin_list_report_exports(text, integer) to authenticated;
grant execute on function public.admin_adjust_sale_points(uuid, integer, text, text) to authenticated;
grant execute on function public.admin_create_reconciliation_run(text, text, text) to authenticated;
grant execute on function public.admin_list_reconciliation_discrepancies(text, integer) to authenticated;
grant execute on function public.admin_update_reconciliation_discrepancy_status(uuid, text, text, text) to authenticated;
grant execute on function public.admin_list_audit_events(text, integer) to authenticated;

revoke all on function public.record_trusted_payment_event(
  uuid,
  public.nb_membership_plan,
  text,
  text,
  integer,
  integer,
  integer,
  text,
  boolean,
  text,
  jsonb
) from public, anon, authenticated;

revoke all on function public.create_sale_point_reversal_for_payment(
  uuid,
  text,
  text,
  text
) from public, anon, authenticated;

-- 12. Sale module final internal update

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): cap nhat module Sale full noi bo
-- NanoBio / BioAI - Sale direct-only internal module update.
-- Run after 01-core-auth-profile.sql, 05-sale-referral-commission.sql,
-- 10-mobile-sync-and-sale-rpc.sql and 11-admin-access-dashboard.sql.
-- Draft only: review in sandbox/staging before production migration.

-- In the existing domain, `pending` represents BD v2.0 pending_review.
-- Admin approval is required before a user receives an active referral code.

create table if not exists public.sale_point_conversions (
  id uuid primary key default gen_random_uuid(),
  sale_user_id uuid not null references public.users(id) on delete restrict,
  requested_point_cents integer not null check (requested_point_cents > 0),
  point_to_money_rate numeric(12, 4) not null check (point_to_money_rate > 0),
  money_amount_cents integer not null check (money_amount_cents >= 0),
  currency text not null default 'VND',
  status text not null default 'requested'
    check (status in ('requested', 'pending_review', 'approved', 'paid', 'rejected', 'cancelled')),
  idempotency_key text,
  requested_at timestamptz not null default now(),
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  review_reason text,
  paid_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_sale_point_conversions_idempotency
  on public.sale_point_conversions (sale_user_id, idempotency_key)
  where idempotency_key is not null;

create index if not exists idx_sale_point_conversions_sale_created
  on public.sale_point_conversions (sale_user_id, created_at desc);
create index if not exists idx_sale_point_conversions_status_created
  on public.sale_point_conversions (status, created_at desc);
create index if not exists idx_sale_point_conversions_sale_status_created
  on public.sale_point_conversions (sale_user_id, status, created_at desc);

create table if not exists public.sale_payout_profiles (
  sale_user_id uuid primary key references public.sale_profiles(user_id) on delete cascade,
  citizen_id text not null,
  bank_bin text not null,
  bank_name text not null,
  bank_account_number text not null,
  bank_account_name text not null,
  updated_by uuid references public.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sale_payout_profile_complete
    check (
      length(btrim(citizen_id)) >= 9
      and length(btrim(bank_bin)) >= 3
      and length(btrim(bank_name)) > 0
      and length(btrim(bank_account_number)) >= 4
      and length(btrim(bank_account_name)) > 0
    )
);

drop trigger if exists trg_sale_payout_profiles_updated_at
  on public.sale_payout_profiles;
create trigger trg_sale_payout_profiles_updated_at
  before update on public.sale_payout_profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_sale_point_conversions_updated_at
  on public.sale_point_conversions;
create trigger trg_sale_point_conversions_updated_at
  before update on public.sale_point_conversions
  for each row execute function public.set_updated_at();

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'sale_point_conversion',
  '{"enabled": false, "point_to_money_rate": 1, "minimum_point_cents": 500000, "currency": "VND"}'::jsonb,
  'active',
  'Default disabled Sale point conversion policy.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'sale_point_conversion'
    and status = 'active'
);

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'membership_payment_prices',
  '{
    "currency": "VND",
    "prices": {
      "plus": {"monthly": 199000, "yearly": 1990000},
      "family_plus": {"monthly": 399000, "yearly": 3990000}
    }
  }'::jsonb,
  'active',
  'Default membership payment price table used by create_membership_payment_request.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'membership_payment_prices'
    and status = 'active'
);

drop function if exists public.get_my_sale_state();
create or replace function public.get_my_sale_state()
returns table (
  sale_status text,
  referral_code text,
  terms_version text,
  approved_at timestamptz,
  note text,
  payout_profile_complete boolean
)
language sql
security definer
set search_path = public, pg_temp
as $$
  select
    coalesce(sp.status::text, u.sale_status::text, 'none') as sale_status,
    rc.code as referral_code,
    sp.terms_version,
    sp.approved_at,
    sp.note,
    (spp.sale_user_id is not null) as payout_profile_complete
  from public.users u
  left join public.sale_profiles sp on sp.user_id = u.id
  left join public.sale_payout_profiles spp on spp.sale_user_id = u.id
  left join lateral (
    select code
    from public.referral_codes
    where sale_user_id = u.id and status = 'active'
    order by created_at asc
    limit 1
  ) rc on true
  where u.id = auth.uid()
$$;

drop function if exists public.request_sale_participation(text);
create or replace function public.request_sale_participation(
  p_terms_version text,
  p_device_hash text
)
returns table (
  sale_status text,
  referral_code text,
  terms_version text,
  approved_at timestamptz,
  note text,
  payout_profile_complete boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing_status public.nb_sale_status;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if nullif(btrim(p_terms_version), '') is null then
    raise exception 'TERMS_VERSION_REQUIRED' using errcode = '22023';
  end if;

  if nullif(btrim(p_device_hash), '') is null then
    raise exception 'DEVICE_HASH_REQUIRED' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.membership_subscriptions ms
    where ms.user_id = v_user_id
      and ms.plan_code in ('plus', 'family_plus')
      and ms.status = 'active'
      and ms.starts_at <= now()
      and (ms.ends_at is null or ms.ends_at > now())
  ) then
    raise exception 'SALE_REQUIRES_ACTIVE_PAID_PLAN' using errcode = '42501';
  end if;

  select status into v_existing_status
  from public.sale_profiles
  where user_id = v_user_id
  for update;

  if v_existing_status in ('suspended', 'closed') then
    raise exception 'SALE_STATUS_REQUIRES_SUPPORT' using errcode = '42501';
  end if;

  if v_existing_status = 'active' then
    update public.sale_profiles
    set
      terms_version = btrim(p_terms_version),
      terms_accepted_at = now(),
      participation_device_hash = btrim(p_device_hash),
      note = 'Da cap nhat dieu le Sale trong ung dung.',
      updated_at = now()
    where user_id = v_user_id;
  else
    insert into public.sale_profiles (
      user_id,
      status,
      terms_version,
      terms_accepted_at,
      participation_device_hash,
      note
    )
    values (
      v_user_id,
      'pending',
      btrim(p_terms_version),
      now(),
      btrim(p_device_hash),
      'Da gui yeu cau Sale; dang cho Admin duyet.'
    )
    on conflict (user_id) do update
    set
      status = 'pending',
      terms_version = excluded.terms_version,
      terms_accepted_at = excluded.terms_accepted_at,
      participation_device_hash = excluded.participation_device_hash,
      note = excluded.note,
      updated_at = now();
  end if;

  return query select * from public.get_my_sale_state();
end;
$$;

drop function if exists public.attach_my_referral_code(text);
create or replace function public.attach_my_referral_code(
  p_referral_code text,
  p_device_hash text
)
returns table (
  success boolean,
  message text,
  referrer_display_name text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_code text := upper(replace(btrim(coalesce(p_referral_code, '')), ' ', ''));
  v_device_hash text := btrim(coalesce(p_device_hash, ''));
  v_referrer_id uuid;
  v_referrer_name text;
  v_user_email text;
  v_user_phone text;
  v_referrer_email text;
  v_referrer_phone text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if v_code = '' then
    return query select false, 'Ma gioi thieu khong hop le.', null::text;
    return;
  end if;

  if v_device_hash = '' then
    return query select false, 'Can xac thuc thiet bi truoc khi gan ma gioi thieu.', null::text;
    return;
  end if;

  select email, phone
  into v_user_email, v_user_phone
  from public.users
  where id = v_user_id;

  select
    rc.sale_user_id,
    coalesce(nullif(u.full_name, ''), 'Sale NanoBio'),
    u.email,
    u.phone
  into v_referrer_id, v_referrer_name, v_referrer_email, v_referrer_phone
  from public.referral_codes rc
  join public.sale_profiles sp
    on sp.user_id = rc.sale_user_id
   and sp.status = 'active'
  join public.users u on u.id = rc.sale_user_id
  where rc.code = v_code
    and rc.status = 'active'
  limit 1;

  if v_referrer_id is null then
    return query select false, 'Ma gioi thieu khong ton tai hoac chua hoat dong.', null::text;
    return;
  end if;

  if v_referrer_id = v_user_id then
    return query select false, 'Khong the dung ma gioi thieu cua chinh minh.', null::text;
    return;
  end if;

  if nullif(lower(coalesce(v_user_email, '')), '') is not null
    and lower(v_user_email) = lower(coalesce(v_referrer_email, '')) then
    return query select false, 'Email co dau hieu trung voi Sale gioi thieu.', null::text;
    return;
  end if;

  if nullif(coalesce(v_user_phone, ''), '') is not null
    and v_user_phone = coalesce(v_referrer_phone, '') then
    return query select false, 'So dien thoai co dau hieu trung voi Sale gioi thieu.', null::text;
    return;
  end if;

  if exists (
    select 1
    from public.sale_profiles sp
    where sp.user_id = v_referrer_id
      and sp.participation_device_hash = v_device_hash
  ) then
    return query select false, 'Thiet bi co dau hieu trung voi Sale gioi thieu.', null::text;
    return;
  end if;

  if exists (
    select 1
    from public.referral_relationships
    where referred_user_id = v_user_id
      and status = 'active'
  ) then
    return query select false, 'Tai khoan da co ma gioi thieu.', null::text;
    return;
  end if;

  if exists (
    select 1
    from public.referral_relationships rr
    where rr.device_hash = v_device_hash
      and rr.status = 'active'
  ) then
    return query select false, 'Thiet bi nay da duoc dung de gan ma gioi thieu.', null::text;
    return;
  end if;

  if exists (
    select 1
    from public.payment_events
    where payer_user_id = v_user_id
      and status in ('pending', 'succeeded', 'refunded', 'chargeback')
  ) then
    return query select false, 'Tai khoan da co lich su payment nen khong the gan ma trong ung dung.', null::text;
    return;
  end if;

  insert into public.referral_relationships (
    referrer_user_id,
    referred_user_id,
    referral_code,
    source,
    status,
    device_hash,
    metadata
  )
  values (
    v_referrer_id,
    v_user_id,
    v_code,
    'signup',
    'active',
    v_device_hash,
    jsonb_build_object(
      'anti_fraud_checks',
      jsonb_build_array('self', 'existing_referral', 'payment_history', 'email', 'phone', 'device'),
      'attached_during',
      'account_registration'
    )
  );

  return query select true, 'Da gan ma gioi thieu.', v_referrer_name;
end;
$$;

create or replace function public.get_my_sale_payout_profile()
returns table (
  citizen_id text,
  bank_bin text,
  bank_name text,
  bank_account_number text,
  bank_account_name text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  return query
  select
    spp.citizen_id,
    spp.bank_bin,
    spp.bank_name,
    spp.bank_account_number,
    spp.bank_account_name,
    spp.updated_at
  from public.sale_payout_profiles spp
  where spp.sale_user_id = v_user_id;
end;
$$;

create or replace function public.upsert_my_sale_payout_profile(
  p_citizen_id text,
  p_bank_bin text,
  p_bank_name text,
  p_bank_account_number text,
  p_bank_account_name text
)
returns table (
  citizen_id text,
  bank_bin text,
  bank_name text,
  bank_account_number text,
  bank_account_name text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  if length(btrim(coalesce(p_citizen_id, ''))) < 9
    or length(btrim(coalesce(p_bank_bin, ''))) < 3
    or nullif(btrim(coalesce(p_bank_name, '')), '') is null
    or length(btrim(coalesce(p_bank_account_number, ''))) < 4
    or nullif(btrim(coalesce(p_bank_account_name, '')), '') is null then
    raise exception 'SALE_PAYOUT_PROFILE_INCOMPLETE' using errcode = '22023';
  end if;

  insert into public.sale_payout_profiles (
    sale_user_id,
    citizen_id,
    bank_bin,
    bank_name,
    bank_account_number,
    bank_account_name,
    updated_by,
    metadata
  )
  values (
    v_user_id,
    btrim(p_citizen_id),
    btrim(p_bank_bin),
    btrim(p_bank_name),
    btrim(p_bank_account_number),
    upper(btrim(p_bank_account_name)),
    v_user_id,
    jsonb_build_object('updated_from', 'sale_app_rpc')
  )
  on conflict (sale_user_id) do update
  set
    citizen_id = excluded.citizen_id,
    bank_bin = excluded.bank_bin,
    bank_name = excluded.bank_name,
    bank_account_number = excluded.bank_account_number,
    bank_account_name = excluded.bank_account_name,
    updated_by = excluded.updated_by,
    metadata = public.sale_payout_profiles.metadata || excluded.metadata,
    updated_at = now();

  return query select * from public.get_my_sale_payout_profile();
end;
$$;



create or replace function public.get_my_sale_dashboard()
returns table (
  direct_customers integer,
  successful_payments integer,
  pending_point_cents integer,
  approved_point_cents integer,
  paid_point_cents integer,
  converted_point_cents integer,
  available_point_cents integer,
  currency text,
  conversion_enabled boolean,
  conversion_rate numeric,
  conversion_minimum_point_cents integer,
  conversion_currency text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
  v_config jsonb := '{}'::jsonb;
  v_enabled boolean := false;
  v_rate numeric := 0;
  v_minimum integer := 0;
  v_conversion_currency text := 'VND';
begin
  select config_value into v_config
  from public.system_config_versions
  where config_key = 'sale_point_conversion'
    and status = 'active'
  order by created_at desc
  limit 1;

  v_config := coalesce(v_config, '{}'::jsonb);
  v_enabled := coalesce((v_config ->> 'enabled')::boolean, false);
  v_rate := coalesce((v_config ->> 'point_to_money_rate')::numeric, 0);
  v_minimum := coalesce((v_config ->> 'minimum_point_cents')::integer, 0);
  v_conversion_currency := coalesce(nullif(v_config ->> 'currency', ''), 'VND');

  return query
  with direct_nodes as (
    select rr.referred_user_id
    from public.referral_relationships rr
    where rr.referrer_user_id = v_user_id
      and rr.status = 'active'
  ), payment_summary as (
    select count(distinct pe.id)::integer as success_count
    from public.payment_events pe
    join direct_nodes dn on dn.referred_user_id = pe.payer_user_id
    where pe.status = 'succeeded'
  ), point_summary as (
    select
      coalesce(sum(amount_cents) filter (
        where status in ('pending', 'approved')
          and available_at > now()
      ), 0)::integer as pending_cents,
      coalesce(sum(amount_cents) filter (
        where status in ('pending', 'approved')
          and available_at <= now()
      ), 0)::integer as approved_cents,
      coalesce(sum(amount_cents) filter (where status = 'paid'), 0)::integer as paid_cents,
      coalesce(max(currency), 'VND') as result_currency
    from public.commission_records
    where receiver_user_id = v_user_id
  ), adjustment_summary as (
    select coalesce(sum(point_delta_cents), 0)::integer as adjustment_cents
    from public.sale_point_adjustments
    where sale_user_id = v_user_id
      and status = 'approved'
  ), conversion_summary as (
    select coalesce(sum(requested_point_cents), 0)::integer as converted_cents
    from public.sale_point_conversions
    where sale_user_id = v_user_id
      and status in ('requested', 'pending_review', 'approved', 'paid')
  )
  select
    (select count(*)::integer from direct_nodes),
    coalesce(ps.success_count, 0),
    pts.pending_cents,
    (pts.approved_cents + ads.adjustment_cents)::integer,
    pts.paid_cents,
    cs.converted_cents,
    (pts.approved_cents + ads.adjustment_cents - cs.converted_cents)::integer,
    pts.result_currency,
    v_enabled,
    v_rate,
    v_minimum,
    v_conversion_currency
  from payment_summary ps
  cross join point_summary pts
  cross join adjustment_summary ads
  cross join conversion_summary cs;
end;
$$;

drop function if exists public.get_my_sale_direct_customers();
create or replace function public.get_my_sale_direct_customers()
returns table (
  display_name text,
  full_name text,
  age integer,
  phone text,
  accepted_at timestamptz,
  successful_payments integer,
  approved_point_cents integer,
  currency text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  return query
  with direct_nodes as (
    select rr.referred_user_id, rr.accepted_at
    from public.referral_relationships rr
    where rr.referrer_user_id = v_user_id
      and rr.status = 'active'
  ), payments as (
    select payer_user_id, count(*)::integer as success_count
    from public.payment_events
    where status = 'succeeded'
    group by payer_user_id
  ), points as (
    select
      payer_user_id,
      coalesce(sum(amount_cents) filter (
        where status in ('pending', 'approved')
          and available_at <= now()
      ), 0)::integer as approved_cents,
      coalesce(max(currency), 'VND') as result_currency
    from public.commission_records
    where receiver_user_id = v_user_id
    group by payer_user_id
  )
  select
    coalesce(nullif(u.full_name, ''), 'Nguoi dung NanoBio'),
    coalesce(nullif(u.full_name, ''), 'Nguoi dung NanoBio'),
    case
      when coalesce(u.birth_year, hs_self.birth_year) is null then null
      else extract(year from age(make_date(coalesce(u.birth_year, hs_self.birth_year), 1, 1)))::integer
    end,
    u.phone,
    dn.accepted_at,
    coalesce(p.success_count, 0),
    coalesce(pt.approved_cents, 0),
    coalesce(pt.result_currency, 'VND')
  from direct_nodes dn
  join public.users u on u.id = dn.referred_user_id
  left join public.health_subjects hs_self
    on hs_self.owner_user_id = dn.referred_user_id
   and hs_self.subject_type = 'self'
   and hs_self.is_active = true
  left join payments p on p.payer_user_id = dn.referred_user_id
  left join points pt on pt.payer_user_id = dn.referred_user_id
  order by dn.accepted_at desc;
end;
$$;

create or replace function public.get_my_sale_point_ledger()
returns table (
  id text,
  customer_name text,
  plan_code text,
  payment_amount_cents integer,
  point_amount_cents integer,
  currency text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  return query
  select
    cr.id::text,
    coalesce(nullif(u.full_name, ''), 'Nguoi dung NanoBio') as customer_name,
    pe.plan_code::text,
    pe.amount_cents,
    cr.amount_cents,
    cr.currency,
    cr.status,
    cr.created_at
  from public.commission_records cr
  join public.payment_events pe on pe.id = cr.payment_event_id
  join public.users u on u.id = cr.payer_user_id
  where cr.receiver_user_id = v_user_id
  union all
  select
    spa.id::text,
    'Dieu chinh Admin' as customer_name,
    'manual_adjustment' as plan_code,
    0 as payment_amount_cents,
    spa.point_delta_cents,
    spa.currency,
    spa.status,
    spa.created_at
  from public.sale_point_adjustments spa
  where spa.sale_user_id = v_user_id
  order by created_at desc;
end;
$$;

create or replace function public.get_my_sale_conversions()
returns table (
  id text,
  requested_point_cents integer,
  money_amount_cents integer,
  currency text,
  status text,
  requested_at timestamptz,
  reviewed_at timestamptz,
  note text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  return query
  select
    spc.id::text,
    spc.requested_point_cents,
    spc.money_amount_cents,
    spc.currency,
    spc.status,
    spc.requested_at,
    spc.reviewed_at,
    spc.review_reason
  from public.sale_point_conversions spc
  where spc.sale_user_id = v_user_id
  order by spc.created_at desc;
end;
$$;

create or replace function public.request_sale_point_conversion(
  p_requested_point_cents integer,
  p_idempotency_key text
)
returns table (
  id text,
  requested_point_cents integer,
  money_amount_cents integer,
  currency text,
  status text,
  requested_at timestamptz,
  reviewed_at timestamptz,
  note text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
  v_config jsonb := '{}'::jsonb;
  v_enabled boolean := false;
  v_rate numeric := 0;
  v_minimum integer := 0;
  v_currency text := 'VND';
  v_approved integer := 0;
  v_held integer := 0;
  v_available integer := 0;
  v_conversion_id uuid;
  v_payout public.sale_payout_profiles%rowtype;
begin
  if p_requested_point_cents is null or p_requested_point_cents <= 0 then
    raise exception 'INVALID_CONVERSION_POINTS' using errcode = '22023';
  end if;

  select config_value into v_config
  from public.system_config_versions
  where config_key = 'sale_point_conversion'
    and status = 'active'
  order by created_at desc
  limit 1;

  v_config := coalesce(v_config, '{}'::jsonb);
  v_enabled := coalesce((v_config ->> 'enabled')::boolean, false);
  v_rate := coalesce((v_config ->> 'point_to_money_rate')::numeric, 0);
  v_minimum := coalesce((v_config ->> 'minimum_point_cents')::integer, 0);
  v_currency := coalesce(nullif(v_config ->> 'currency', ''), 'VND');

  if not v_enabled or v_rate <= 0 then
    raise exception 'SALE_CONVERSION_DISABLED' using errcode = '42501';
  end if;

  select * into v_payout
  from public.sale_payout_profiles spp
  where spp.sale_user_id = v_user_id;

  if not found then
    raise exception 'SALE_PAYOUT_PROFILE_REQUIRED' using errcode = '42501';
  end if;

  if p_requested_point_cents < v_minimum then
    raise exception 'SALE_CONVERSION_MINIMUM_NOT_MET' using errcode = '22023';
  end if;

  select (
    select coalesce(sum(amount_cents), 0)::integer
    from public.commission_records
    where receiver_user_id = v_user_id
      and status in ('pending', 'approved')
      and available_at <= now()
  ) + (
    select coalesce(sum(point_delta_cents), 0)::integer
    from public.sale_point_adjustments
    where sale_user_id = v_user_id
      and status = 'approved'
  ) into v_approved;

  select coalesce(sum(requested_point_cents), 0)::integer into v_held
  from public.sale_point_conversions
  where sale_user_id = v_user_id
    and status in ('requested', 'pending_review', 'approved', 'paid');

  v_available := greatest(v_approved - v_held, 0);

  if p_requested_point_cents > v_available then
    raise exception 'SALE_CONVERSION_POINTS_EXCEED_AVAILABLE' using errcode = '22023';
  end if;

  insert into public.sale_point_conversions (
    sale_user_id,
    requested_point_cents,
    point_to_money_rate,
    money_amount_cents,
    currency,
    status,
    idempotency_key,
    metadata
  )
  values (
    v_user_id,
    p_requested_point_cents,
    v_rate,
    round(p_requested_point_cents * v_rate)::integer,
    v_currency,
    'requested',
    nullif(btrim(p_idempotency_key), ''),
    jsonb_build_object(
      'citizen_id',
      v_payout.citizen_id,
      'bank_bin',
      v_payout.bank_bin,
      'bank_name',
      v_payout.bank_name,
      'bank_account_number',
      v_payout.bank_account_number,
      'bank_account_name',
      v_payout.bank_account_name,
      'payment_content',
      concat('SALE ', substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))
    )
  )
  on conflict (sale_user_id, idempotency_key)
  where idempotency_key is not null
  do update set metadata = public.sale_point_conversions.metadata
  returning public.sale_point_conversions.id into v_conversion_id;

  return query
  select
    spc.id::text,
    spc.requested_point_cents,
    spc.money_amount_cents,
    spc.currency,
    spc.status,
    spc.requested_at,
    spc.reviewed_at,
    spc.review_reason
  from public.sale_point_conversions spc
  where spc.id = v_conversion_id;
end;
$$;

drop function if exists public.admin_list_sale_point_conversions(text, integer);
create or replace function public.admin_list_sale_point_conversions(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz,
  metadata jsonb
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('sales.write');

  return query
  select
    spc.id::text,
    concat(coalesce(nullif(u.full_name, ''), u.email, spc.sale_user_id::text), ' - ', spc.requested_point_cents::text, ' diem'),
    concat_ws(' - ', spc.money_amount_cents::text || ' ' || spc.currency, spc.review_reason),
    spc.status,
    'sale_point_conversions',
    spc.created_at,
    jsonb_build_object(
      'sale_user_id',
      spc.sale_user_id,
      'requested_point_cents',
      spc.requested_point_cents,
      'money_amount_cents',
      spc.money_amount_cents,
      'currency',
      spc.currency,
      'citizen_id',
      coalesce(spc.metadata ->> 'citizen_id', spp.citizen_id),
      'bank_bin',
      coalesce(spc.metadata ->> 'bank_bin', spp.bank_bin),
      'bank_name',
      coalesce(spc.metadata ->> 'bank_name', spp.bank_name),
      'bank_account_number',
      coalesce(spc.metadata ->> 'bank_account_number', spp.bank_account_number),
      'bank_account_name',
      coalesce(spc.metadata ->> 'bank_account_name', spp.bank_account_name),
      'payment_content',
      coalesce(spc.metadata ->> 'payment_content', concat('SALE ', substr(spc.id::text, 1, 8))),
      'payment_proof_path',
      spc.metadata ->> 'payment_proof_path',
      'vietqr_payload',
      concat_ws(
        '|',
        'VIETQR',
        coalesce(spc.metadata ->> 'bank_bin', spp.bank_bin),
        coalesce(spc.metadata ->> 'bank_account_number', spp.bank_account_number),
        coalesce(spc.metadata ->> 'bank_account_name', spp.bank_account_name),
        spc.money_amount_cents::text,
        spc.currency,
        coalesce(spc.metadata ->> 'payment_content', concat('SALE ', substr(spc.id::text, 1, 8)))
      )
    )
  from public.sale_point_conversions spc
  join public.users u on u.id = spc.sale_user_id
  left join public.sale_payout_profiles spp on spp.sale_user_id = spc.sale_user_id
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or spc.id::text = p_query
  order by spc.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

drop function if exists public.admin_review_sale_point_conversion(uuid, text, text, text);
create or replace function public.admin_review_sale_point_conversion(
  p_conversion_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text,
  p_payment_proof_path text default null
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
begin
  perform public.admin_assert_permission('sales.write');

  v_status := case p_decision
    when 'approve' then 'approved'
    when 'reject' then 'rejected'
    when 'mark_paid' then 'paid'
    else null
  end;

  if v_status is null then
    raise exception 'INVALID_CONVERSION_DECISION' using errcode = '22023';
  end if;

  update public.sale_point_conversions
  set
    status = v_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason),
    paid_at = case when v_status = 'paid' then now() else paid_at end,
    metadata = metadata
      || jsonb_build_object('admin_decision', p_decision)
      || case
        when nullif(btrim(coalesce(p_payment_proof_path, '')), '') is null then '{}'::jsonb
        else jsonb_build_object('payment_proof_path', btrim(p_payment_proof_path))
      end
  where id = p_conversion_id;

  if not found then
    raise exception 'SALE_CONVERSION_NOT_FOUND' using errcode = '22023';
  end if;

  perform public.admin_write_audit(
    'admin_review_sale_point_conversion',
    'sale_point_conversion',
    p_conversion_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'decision',
      p_decision,
      'status',
      v_status,
      'payment_proof_path',
      nullif(btrim(coalesce(p_payment_proof_path, '')), '')
    )
  );

  return query select true, 'Da cap nhat yeu cau quy doi diem Sale.';
end;
$$;

alter table public.sale_point_conversions enable row level security;
alter table public.sale_payout_profiles enable row level security;

drop policy if exists sale_point_conversions_select_own
  on public.sale_point_conversions;
create policy sale_point_conversions_select_own
  on public.sale_point_conversions for select to authenticated
  using (
    sale_user_id = (select auth.uid())
    or public.admin_has_permission('sales.write')
  );

drop policy if exists sale_payout_profiles_select_own
  on public.sale_payout_profiles;
create policy sale_payout_profiles_select_own
  on public.sale_payout_profiles for select to authenticated
  using (
    sale_user_id = (select auth.uid())
    or public.admin_has_permission('sales.write')
  );

grant select on public.sale_point_conversions to authenticated;
revoke insert, update, delete on public.sale_point_conversions
from anon, authenticated;
revoke all on table public.sale_payout_profiles from anon, authenticated;

revoke all on function public.get_my_sale_state() from public, anon;
revoke all on function public.request_sale_participation(text, text)
from public, anon;
revoke all on function public.attach_my_referral_code(text, text)
from public, anon;
revoke all on function public.get_my_sale_payout_profile()
from public, anon;
revoke all on function public.upsert_my_sale_payout_profile(text, text, text, text, text)
from public, anon;
revoke all on function public.get_my_sale_direct_customers() from public, anon;
revoke all on function public.get_my_sale_point_ledger() from public, anon;
revoke all on function public.get_my_sale_conversions() from public, anon;
revoke all on function public.request_sale_point_conversion(integer, text)
from public, anon;
revoke all on function public.admin_list_sale_point_conversions(text, integer)
from public, anon;
revoke all on function public.admin_review_sale_point_conversion(uuid, text, text, text, text)
from public, anon;

grant execute on function public.get_my_sale_state() to authenticated;
grant execute on function public.request_sale_participation(text, text)
to authenticated;
grant execute on function public.attach_my_referral_code(text, text)
to authenticated;
grant execute on function public.get_my_sale_payout_profile()
to authenticated;
grant execute on function public.upsert_my_sale_payout_profile(text, text, text, text, text)
to authenticated;
grant execute on function public.get_my_sale_direct_customers() to authenticated;
grant execute on function public.get_my_sale_point_ledger() to authenticated;
grant execute on function public.get_my_sale_conversions() to authenticated;
grant execute on function public.request_sale_point_conversion(integer, text)
to authenticated;
grant execute on function public.admin_list_sale_point_conversions(text, integer)
to authenticated;
grant execute on function public.admin_review_sale_point_conversion(uuid, text, text, text, text)
to authenticated;

-- 13. Reference seed data

-- ---------------------------------------------------------------------------

-- Commit de xuat: docs(supabase): seed du lieu tham chieu
-- NanoBio / BioAI - reference seed for plans, entitlements, quota and commission.
-- Run after 03-membership-quota.sql and 05-sale-referral-commission.sql.

insert into public.membership_plans (code, display_name, access_version, sort_order, is_active)
values
  ('free', 'Free', 'v2', 10, true),
  ('plus', 'Plus', 'v3', 20, true),
  ('family_plus', 'FamilyPlus', 'v3', 30, true)
on conflict (code) do update
set
  display_name = excluded.display_name,
  access_version = excluded.access_version,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.plan_entitlements (plan_code, entitlement_key, entitlement_value, is_active)
values
  ('free', 'ai_chat', '{"enabled": true, "quota_key": "ai_chat_message"}'::jsonb, true),
  ('free', 'personal_schedule_generation', '{"enabled": true, "quota_key": "personal_schedule_generation"}'::jsonb, true),
  ('free', 'health_score', '{"enabled": true, "basis": "ai_schedule_completion_history"}'::jsonb, true),
  ('plus', 'ai_chat', '{"enabled": true, "unlimited": true}'::jsonb, true),
  ('plus', 'personal_schedule_generation', '{"enabled": true, "unlimited": true}'::jsonb, true),
  ('plus', 'goal_roadmap', '{"enabled": true}'::jsonb, true),
  ('plus', 'advanced_health_tracking', '{"enabled": true}'::jsonb, true),
  ('family_plus', 'ai_chat', '{"enabled": true, "unlimited": true, "inherits": "plus"}'::jsonb, true),
  ('family_plus', 'personal_schedule_generation', '{"enabled": true, "unlimited": true, "inherits": "plus"}'::jsonb, true),
  ('family_plus', 'family_members', '{"enabled": true}'::jsonb, true),
  ('family_plus', 'family_schedule', '{"enabled": true}'::jsonb, true),
  ('family_plus', 'family_health_tracking', '{"enabled": true}'::jsonb, true)
on conflict (plan_code, entitlement_key) do update
set
  entitlement_value = excluded.entitlement_value,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.usage_quota_rules (
  plan_code,
  feature_key,
  period_unit,
  max_count,
  reset_timezone,
  is_active
)
values
  ('free', 'ai_chat_message', 'day', 3, 'Asia/Ho_Chi_Minh', true),
  ('free', 'personal_schedule_generation', 'month', 3, 'Asia/Ho_Chi_Minh', true),
  ('plus', 'ai_chat_message', 'none', null, 'Asia/Ho_Chi_Minh', true),
  ('plus', 'personal_schedule_generation', 'none', null, 'Asia/Ho_Chi_Minh', true),
  ('family_plus', 'ai_chat_message', 'none', null, 'Asia/Ho_Chi_Minh', true),
  ('family_plus', 'personal_schedule_generation', 'none', null, 'Asia/Ho_Chi_Minh', true)
on conflict (plan_code, feature_key, period_unit) do update
set
  max_count = excluded.max_count,
  reset_timezone = excluded.reset_timezone,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.commission_rates (code, rate, is_active)
values
  ('direct_referral', 0.1000, true)
on conflict (code) do update
set
  rate = excluded.rate,
  is_active = excluded.is_active,
  updated_at = now();

-- ---------------------------------------------------------------------------
-- 14. Dev/sandbox auth users and Admin bootstrap
-- ---------------------------------------------------------------------------
-- DEV/SANDBOX ONLY. Test password for all accounts: NanoBio@123456
--   dev.free@nanobio.local   -> free
--   dev.plus@nanobio.local   -> plus
--   dev.family@nanobio.local -> family_plus
--   dev.admin@nanobio.local  -> free + super_admin

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
      ),
      (
        '10000000-0000-4000-8000-000000000104'::uuid,
        '20000000-0000-4000-8000-000000000104'::uuid,
        '30000000-0000-4000-8000-000000000104'::uuid,
        'dev.admin@nanobio.local',
        'Dev Admin',
        'free'::public.nb_membership_plan
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
      'dev.family@nanobio.local',
      'dev.admin@nanobio.local'
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
      ),
      (
        '10000000-0000-4000-8000-000000000104'::uuid,
        '20000000-0000-4000-8000-000000000104'::uuid,
        'dev.admin@nanobio.local',
        'Dev Admin'
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
      ),
      (
        '30000000-0000-4000-8000-000000000104'::uuid,
        '10000000-0000-4000-8000-000000000104'::uuid,
        'free'::public.nb_membership_plan
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
  jsonb_build_object('seed', 'config-sql-dev-users')
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
  '10000000-0000-4000-8000-000000000103'::uuid,
  '10000000-0000-4000-8000-000000000104'::uuid
)
  and hs.subject_type = 'self'
on conflict (subject_id) do nothing;

insert into public.lifestyle_habits (user_id, subject_id)
select hs.owner_user_id, hs.id
from public.health_subjects hs
where hs.owner_user_id in (
  '10000000-0000-4000-8000-000000000101'::uuid,
  '10000000-0000-4000-8000-000000000102'::uuid,
  '10000000-0000-4000-8000-000000000103'::uuid,
  '10000000-0000-4000-8000-000000000104'::uuid
)
  and hs.subject_type = 'self'
on conflict (subject_id) do nothing;

create or replace function public.bootstrap_admin_by_email(
  p_email text,
  p_role_code text default 'super_admin'
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid;
begin
  if nullif(btrim(p_email), '') is null then
    raise exception 'ADMIN_EMAIL_REQUIRED' using errcode = '22023';
  end if;

  select id into v_user_id
  from public.users
  where lower(email) = lower(btrim(p_email))
  limit 1;

  if v_user_id is null then
    raise exception 'ADMIN_USER_NOT_FOUND' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.admin_roles where code = p_role_code and is_active = true
  ) then
    raise exception 'ADMIN_ROLE_NOT_FOUND' using errcode = '22023';
  end if;

  update public.users
  set
    app_access_mode = case
      when app_access_mode = 'admin' then 'admin'
      else 'both'
    end,
    updated_at = now()
  where id = v_user_id;

  insert into public.admin_user_roles (
    user_id,
    role_code,
    scope,
    is_active,
    granted_by,
    granted_at,
    revoked_at
  )
  values (
    v_user_id,
    p_role_code,
    'global',
    true,
    null,
    now(),
    null
  )
  on conflict (user_id, role_code, scope) do update
  set
    is_active = true,
    granted_by = null,
    granted_at = now(),
    revoked_at = null;

  return v_user_id;
end;
$$;

revoke all on function public.bootstrap_admin_by_email(text, text)
from public, anon, authenticated;

select public.bootstrap_admin_by_email('dev.admin@nanobio.local', 'super_admin');

commit;

-- BEGIN 15-auth-sync-completion.sql
-- NanoBio migration 15: Auth V2 signup/referral atomic contract.
-- Non-destructive: replaces only the auth signup trigger function and keeps
-- existing tables/data. Apply to sandbox first. Do not execute config.sql on
-- remote/production.


create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_anonymous boolean;
  v_product_status public.nb_product_access_status;
  v_referral_code text;
  v_device_hash text;
  v_phone text;
  v_referrer_id uuid;
  v_referrer_email text;
  v_referrer_phone text;
begin
  v_is_anonymous := coalesce(
    (new.raw_app_meta_data ->> 'provider') = 'anonymous',
    new.email is null and new.phone is null
  );
  v_product_status := case when v_is_anonymous then 'guest' else 'free' end;
  v_referral_code := upper(
    nullif(btrim(new.raw_user_meta_data ->> 'referral_code'), '')
  );
  v_device_hash := nullif(
    btrim(new.raw_user_meta_data ->> 'device_fingerprint'),
    ''
  );
  v_phone := coalesce(
    nullif(btrim(new.phone), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'phone'), '')
  );

  -- All referral checks happen inside the auth.users insert transaction. Any
  -- exception below rolls back auth.users, public.users and the self subject.
  if v_referral_code is not null then
    if v_is_anonymous then
      raise exception using errcode = 'P0001', message = 'invalid_referral_code';
    end if;

    if v_device_hash is null then
      raise exception using errcode = 'P0001', message = 'referral_device_missing';
    end if;

    select
      rc.sale_user_id,
      u.email,
      u.phone
    into
      v_referrer_id,
      v_referrer_email,
      v_referrer_phone
    from public.referral_codes rc
    join public.sale_profiles sp
      on sp.user_id = rc.sale_user_id
     and sp.status = 'active'
    join public.users u
      on u.id = rc.sale_user_id
    where upper(rc.code) = v_referral_code
      and rc.status = 'active'
    limit 1;

    if v_referrer_id is null then
      raise exception using errcode = 'P0001', message = 'invalid_referral_code';
    end if;

    if v_referrer_id = new.id then
      raise exception using errcode = 'P0001', message = 'referral_collision';
    end if;

    if new.email is not null
       and v_referrer_email is not null
       and lower(new.email) = lower(v_referrer_email) then
      raise exception using errcode = 'P0001', message = 'referral_collision';
    end if;

    if v_phone is not null
       and v_referrer_phone is not null
       and v_phone = v_referrer_phone then
      raise exception using errcode = 'P0001', message = 'referral_collision';
    end if;

    if exists (
      select 1
      from public.sale_profiles sp
      where sp.user_id = v_referrer_id
        and sp.participation_device_hash = v_device_hash
    ) then
      raise exception using errcode = 'P0001', message = 'referral_collision';
    end if;

    if exists (
      select 1
      from public.referral_relationships rr
      where rr.status = 'active'
        and rr.device_hash = v_device_hash
    ) then
      raise exception using errcode = 'P0001', message = 'referral_already_used';
    end if;

    if new.email is not null and exists (
      select 1
      from public.referral_relationships rr
      join public.users referred on referred.id = rr.referred_user_id
      where rr.status = 'active'
        and referred.email is not null
        and lower(referred.email) = lower(new.email)
    ) then
      raise exception using errcode = 'P0001', message = 'referral_already_used';
    end if;

    if v_phone is not null and exists (
      select 1
      from public.referral_relationships rr
      join public.users referred on referred.id = rr.referred_user_id
      where rr.status = 'active'
        and referred.phone = v_phone
    ) then
      raise exception using errcode = 'P0001', message = 'referral_already_used';
    end if;
  end if;

  insert into public.users (
    id,
    email,
    phone,
    full_name,
    avatar_url,
    subscription_tier,
    product_access_status,
    is_anonymous
  )
  values (
    new.id,
    new.email,
    v_phone,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', '')
    ),
    nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
    'free',
    v_product_status,
    v_is_anonymous
  )
  on conflict (id) do update
  set
    email = excluded.email,
    phone = coalesce(excluded.phone, public.users.phone),
    full_name = coalesce(public.users.full_name, excluded.full_name),
    avatar_url = coalesce(public.users.avatar_url, excluded.avatar_url),
    product_access_status = excluded.product_access_status,
    is_anonymous = excluded.is_anonymous,
    updated_at = now();

  insert into public.health_subjects (
    owner_user_id,
    linked_user_id,
    subject_type,
    display_name,
    relationship
  )
  values (
    new.id,
    new.id,
    'self',
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      new.email,
      'Bạn'
    ),
    'self'
  )
  on conflict (owner_user_id) where subject_type = 'self'
  do update
  set
    linked_user_id = excluded.linked_user_id,
    display_name = coalesce(public.health_subjects.display_name, excluded.display_name),
    is_active = true,
    updated_at = now();

  if v_referral_code is not null then
    insert into public.referral_relationships (
      referrer_user_id,
      referred_user_id,
      referral_code,
      source,
      status,
      device_hash,
      metadata
    )
    values (
      v_referrer_id,
      new.id,
      v_referral_code,
      'signup',
      'active',
      v_device_hash,
      jsonb_build_object(
        'contract_version', 'auth_v2_atomic_signup_v1',
        'policy', 'direct_only',
        'validated_at', now()
      )
    );
  end if;

  return new;
end;
$$;

-- Recreate explicitly so environments with a stale trigger binding use the
-- latest function contract without changing any table.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_auth_user_created();
-- END 15-auth-sync-completion.sql
-- BEGIN 16-wellness-rewards.sql
-- NanoBio / BioAI
-- Migration 16: server-authoritative schedule proof, wellness points and rewards.
--
-- Non-destructive migration. Apply to local/sandbox first. This migration
-- depends on the schema through migration 15, including Admin permission and
-- audit helpers. Never replace a remote database with config.sql.

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 16A. Versioned program configuration and server-owned reward tables
-- ---------------------------------------------------------------------------

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'wellness_reward_program',
  jsonb_build_object(
    'contract_version', 'wellness_schedule_v2_2026_07',
    'reward_points', 10,
    'expiry_days', 180,
    'time_zone', 'Asia/Ho_Chi_Minh'
  ),
  'active',
  'Khởi tạo chương trình Điểm chăm sóc v2.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'wellness_reward_program'
    and status = 'active'
);

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'wellness_rewards_rollout',
  '{"enabled": false, "contract_version": "wellness_rewards_v1"}'::jsonb,
  'active',
  'Cờ tính năng mặc định tắt cho đến khi kiểm thử trên môi trường thử nghiệm hoàn tất.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'wellness_rewards_rollout'
    and status = 'active'
);

-- Server-owned marker that permanently pins the only initial Guest request
-- allowed to issue reward eligibility for an account after sign-in. The
-- request table itself is mobile-snapshot data and can be replaced on pull;
-- this marker therefore snapshots the validated request identity and shape.
create table if not exists public.guest_schedule_reward_registrations (
  user_id uuid primary key references public.users(id) on delete cascade,
  schedule_request_id text not null unique,
  plan_start_date date not null,
  plan_days integer not null check (plan_days between 1 and 7),
  plan_item_count integer not null,
  manifest_hash text not null check (manifest_hash ~ '^[0-9a-f]{64}$'),
  plan_item_ids uuid[] not null,
  eligible_item_ids uuid[] not null,
  first_registration_idempotency_key text not null,
  registered_item_count integer not null default 0
    check (registered_item_count >= 0 and registered_item_count <= plan_item_count),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint guest_reward_plan_shape_valid check (
    plan_item_count = plan_days * 10
    and cardinality(plan_item_ids) = plan_item_count
    and eligible_item_ids <@ plan_item_ids
  )
);

-- Member requests are quota-backed and must be registered exactly once with
-- one immutable full-plan manifest. A different idempotency key can never add
-- eligibility to an already pinned Member request.
create table if not exists public.member_schedule_reward_registrations (
  schedule_request_id text primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  plan_start_date date not null,
  plan_days integer not null check (plan_days between 1 and 7),
  plan_item_count integer not null,
  manifest_hash text not null check (manifest_hash ~ '^[0-9a-f]{64}$'),
  registration_idempotency_key text not null,
  registered_item_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_reward_plan_shape_valid check (
    plan_item_count = plan_days * 10
    and registered_item_count between 0 and plan_item_count
  ),
  unique (user_id, registration_idempotency_key)
);

create table if not exists public.schedule_reward_eligibilities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  subject_id uuid not null references public.health_subjects(id) on delete cascade,
  schedule_item_id uuid not null,
  schedule_request_id text not null,
  schedule_date date not null,
  start_time time not null,
  window_start timestamptz not null,
  window_end timestamptz not null,
  title_snapshot text not null,
  category_snapshot text,
  source_type_snapshot text not null,
  source_id_snapshot text,
  status text not null default 'eligible'
    check (status in ('eligible', 'completed', 'undone', 'void')),
  registration_idempotency_key text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint schedule_reward_window_valid check (
    window_end = window_start + interval '30 minutes'
    and window_end > window_start
  ),
  unique (user_id, schedule_item_id),
  unique (user_id, schedule_request_id, schedule_date, start_time)
);

create table if not exists public.schedule_completion_attempts (
  id uuid primary key default gen_random_uuid(),
  eligibility_id uuid not null references public.schedule_reward_eligibilities(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  begin_idempotency_key text not null,
  finalize_idempotency_key text,
  undo_idempotency_key text,
  object_path text not null unique,
  status text not null default 'begun'
    check (status in ('begun', 'finalized', 'undone', 'rejected')),
  began_at timestamptz not null default now(),
  finalized_at timestamptz,
  rejection_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, begin_idempotency_key),
  unique (user_id, finalize_idempotency_key),
  unique (user_id, undo_idempotency_key)
);

create table if not exists public.schedule_completion_proofs (
  id uuid primary key default gen_random_uuid(),
  eligibility_id uuid not null references public.schedule_reward_eligibilities(id) on delete cascade,
  attempt_id uuid not null unique references public.schedule_completion_attempts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  bucket_id text not null default 'schedule-completion-proofs',
  object_path text not null unique,
  content_type text not null check (content_type = 'image/jpeg'),
  byte_size integer not null check (byte_size > 0 and byte_size <= 5242880),
  captured_at timestamptz not null,
  uploaded_at timestamptz not null,
  status text not null default 'active'
    check (status in ('active', 'reversed')),
  reversed_at timestamptz,
  undo_idempotency_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, undo_idempotency_key)
);

create unique index if not exists idx_schedule_completion_proofs_one_active
  on public.schedule_completion_proofs (eligibility_id)
  where status = 'active';

create table if not exists public.wellness_reward_wallets (
  user_id uuid primary key references public.users(id) on delete cascade,
  pending_points integer not null default 0 check (pending_points >= 0),
  available_points integer not null default 0 check (available_points >= 0),
  lifetime_earned_points integer not null default 0 check (lifetime_earned_points >= 0),
  lifetime_spent_points integer not null default 0 check (lifetime_spent_points >= 0),
  lifetime_refunded_points integer not null default 0 check (lifetime_refunded_points >= 0),
  lock_version bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Existing +1/-1 mobile rows become display-only +10/-10 history. They never
-- seed the redeemable wallet because the old client-controlled snapshot could
-- not prove eligibility or evidence ownership.
alter table public.wellness_point_ledgers
  add column if not exists event_type text not null default 'legacy_history',
  add column if not exists status text not null default 'history',
  add column if not exists title text not null default 'Lịch sử điểm nhiệm vụ cũ',
  add column if not exists is_redeemable boolean not null default false,
  add column if not exists available_at timestamptz,
  add column if not exists expires_at timestamptz,
  add column if not exists program_config_id uuid references public.system_config_versions(id) on delete restrict,
  add column if not exists eligibility_id uuid references public.schedule_reward_eligibilities(id) on delete set null,
  add column if not exists redemption_id uuid,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

update public.wellness_point_ledgers
set
  points_delta = points_delta * 10,
  program_code = 'wellness_schedule_legacy_v1',
  event_type = 'legacy_history',
  status = 'history',
  title = 'Lịch sử điểm nhiệm vụ cũ',
  is_redeemable = false,
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'migration', '16-wellness-rewards',
    'original_points_delta', points_delta,
    'redeemable', false
  ),
  updated_at = now()
where program_code = 'wellness_schedule_v1'
  and abs(points_delta) = 1
  and event_type = 'legacy_history';

create table if not exists public.wellness_point_allocations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  subject_id uuid not null references public.health_subjects(id) on delete cascade,
  ledger_id uuid not null unique references public.wellness_point_ledgers(id) on delete restrict,
  eligibility_id uuid references public.schedule_reward_eligibilities(id) on delete set null,
  source_type text not null check (source_type in ('schedule_reward', 'admin_refund')),
  source_id uuid not null,
  original_points integer not null check (original_points > 0),
  remaining_points integer not null check (remaining_points >= 0 and remaining_points <= original_points),
  status text not null check (status in ('pending', 'available', 'spent', 'expired', 'reversed')),
  available_at timestamptz not null,
  expires_at timestamptz not null,
  program_config_id uuid not null references public.system_config_versions(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_type, source_id)
);

create table if not exists public.wellness_reward_offers (
  id uuid primary key default gen_random_uuid(),
  offer_code text not null unique,
  title text not null,
  description text not null,
  provider_name text not null,
  cost_points integer not null check (cost_points > 0),
  eligible_plan_codes text[] not null default array['free', 'plus', 'family_plus']::text[],
  available_from timestamptz,
  available_until timestamptz,
  voucher_expires_at timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references public.users(id) on delete set null,
  updated_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wellness_reward_offer_window_valid check (
    available_until is null or available_from is null or available_until > available_from
  ),
  constraint wellness_reward_offer_plans_valid check (
    cardinality(eligible_plan_codes) > 0
    and eligible_plan_codes <@ array['free', 'plus', 'family_plus']::text[]
  )
);

create table if not exists public.wellness_reward_codes (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid not null references public.wellness_reward_offers(id) on delete restrict,
  code_value text not null,
  code_hash text not null,
  status text not null default 'available'
    check (status in ('available', 'issued', 'retired')),
  voucher_expires_at timestamptz,
  assigned_user_id uuid references public.users(id) on delete set null,
  assigned_redemption_id uuid,
  issued_at timestamptz,
  retired_at timestamptz,
  imported_by uuid references public.users(id) on delete set null,
  import_batch_key text,
  created_at timestamptz not null default now(),
  unique (code_hash)
);

create table if not exists public.wellness_reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  offer_id uuid not null references public.wellness_reward_offers(id) on delete restrict,
  reward_code_id uuid not null unique references public.wellness_reward_codes(id) on delete restrict,
  offer_title_snapshot text not null,
  provider_name_snapshot text not null,
  points_spent integer not null check (points_spent > 0),
  status text not null default 'issued' check (status in ('issued', 'cancelled')),
  voucher_expires_at timestamptz not null,
  idempotency_key text not null,
  issued_at timestamptz not null default now(),
  cancelled_at timestamptz,
  cancelled_by uuid references public.users(id) on delete set null,
  cancellation_reason text,
  refund_allocation_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create table if not exists public.wellness_redemption_allocation_usages (
  redemption_id uuid not null references public.wellness_reward_redemptions(id) on delete restrict,
  allocation_id uuid not null references public.wellness_point_allocations(id) on delete restrict,
  points_used integer not null check (points_used > 0),
  created_at timestamptz not null default now(),
  primary key (redemption_id, allocation_id)
);

create index if not exists idx_schedule_reward_eligibilities_user_window
  on public.schedule_reward_eligibilities (user_id, window_start, window_end);
create index if not exists idx_schedule_completion_attempts_user_status
  on public.schedule_completion_attempts (user_id, status, began_at desc);
create index if not exists idx_schedule_completion_proofs_user_created
  on public.schedule_completion_proofs (user_id, created_at desc);
create index if not exists idx_wellness_point_allocations_wallet_expiry
  on public.wellness_point_allocations (user_id, status, available_at, expires_at);
create unique index if not exists idx_wellness_point_allocations_one_schedule_reward
  on public.wellness_point_allocations (eligibility_id)
  where eligibility_id is not null;
create index if not exists idx_wellness_point_ledgers_reward_history
  on public.wellness_point_ledgers (user_id, is_redeemable, created_at desc);
create index if not exists idx_wellness_reward_offers_catalog
  on public.wellness_reward_offers (is_active, available_from, available_until);
create index if not exists idx_wellness_reward_codes_stock
  on public.wellness_reward_codes (offer_id, status, created_at);
create unique index if not exists idx_wellness_reward_codes_global_hash
  on public.wellness_reward_codes (code_hash);
create index if not exists idx_wellness_reward_redemptions_user_created
  on public.wellness_reward_redemptions (user_id, created_at desc);

drop trigger if exists trg_schedule_reward_eligibilities_updated_at
  on public.schedule_reward_eligibilities;
create trigger trg_schedule_reward_eligibilities_updated_at
  before update on public.schedule_reward_eligibilities
  for each row execute function public.set_updated_at();

drop trigger if exists trg_guest_schedule_reward_registrations_updated_at
  on public.guest_schedule_reward_registrations;
create trigger trg_guest_schedule_reward_registrations_updated_at
  before update on public.guest_schedule_reward_registrations
  for each row execute function public.set_updated_at();

drop trigger if exists trg_member_schedule_reward_registrations_updated_at
  on public.member_schedule_reward_registrations;
create trigger trg_member_schedule_reward_registrations_updated_at
  before update on public.member_schedule_reward_registrations
  for each row execute function public.set_updated_at();

drop trigger if exists trg_schedule_completion_attempts_updated_at
  on public.schedule_completion_attempts;
create trigger trg_schedule_completion_attempts_updated_at
  before update on public.schedule_completion_attempts
  for each row execute function public.set_updated_at();

drop trigger if exists trg_schedule_completion_proofs_updated_at
  on public.schedule_completion_proofs;
create trigger trg_schedule_completion_proofs_updated_at
  before update on public.schedule_completion_proofs
  for each row execute function public.set_updated_at();

drop trigger if exists trg_wellness_reward_wallets_updated_at
  on public.wellness_reward_wallets;
create trigger trg_wellness_reward_wallets_updated_at
  before update on public.wellness_reward_wallets
  for each row execute function public.set_updated_at();

drop trigger if exists trg_wellness_point_allocations_updated_at
  on public.wellness_point_allocations;
create trigger trg_wellness_point_allocations_updated_at
  before update on public.wellness_point_allocations
  for each row execute function public.set_updated_at();

drop trigger if exists trg_wellness_reward_offers_updated_at
  on public.wellness_reward_offers;
create trigger trg_wellness_reward_offers_updated_at
  before update on public.wellness_reward_offers
  for each row execute function public.set_updated_at();

drop trigger if exists trg_wellness_reward_redemptions_updated_at
  on public.wellness_reward_redemptions;
create trigger trg_wellness_reward_redemptions_updated_at
  before update on public.wellness_reward_redemptions
  for each row execute function public.set_updated_at();

-- The legacy updated_at trigger would imply mutation is supported. From this
-- migration onward the ledger is append-only; account-cascade deletion remains
-- allowed so the account-deletion contract can remove personal data.
drop trigger if exists trg_wellness_point_ledgers_updated_at
  on public.wellness_point_ledgers;

create or replace function public.guard_wellness_point_ledger_append_only()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if current_setting('nanobio.wellness_ledger_maintenance', true) = 'on' then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  if tg_op = 'DELETE'
     and not exists (select 1 from public.users where id = old.user_id) then
    return old;
  end if;

  raise exception using
    errcode = 'P0001',
    message = 'wellness_ledger_append_only';
end;
$$;

drop trigger if exists trg_wellness_point_ledgers_append_only
  on public.wellness_point_ledgers;
create trigger trg_wellness_point_ledgers_append_only
  before update or delete on public.wellness_point_ledgers
  for each row execute function public.guard_wellness_point_ledger_append_only();

create or replace function public.wellness_rewards_feature_enabled()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce((
    select case
      when lower(scv.config_value ->> 'enabled') in ('true', '1') then true
      else false
    end
    from public.system_config_versions scv
    where scv.config_key = 'wellness_rewards_rollout'
      and scv.status = 'active'
    order by scv.created_at desc
    limit 1
  ), false)
$$;

create or replace function public.current_wellness_reward_program()
returns table (
  program_config_id uuid,
  contract_version text,
  reward_points integer,
  expiry_days integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_config public.system_config_versions%rowtype;
  v_expiry_text text;
begin
  select * into v_config
  from public.system_config_versions scv
  where scv.config_key = 'wellness_reward_program'
    and scv.status = 'active'
  order by scv.created_at desc
  limit 1;

  if v_config.id is null then
    raise exception using errcode = 'P0001', message = 'reward_program_not_configured';
  end if;

  v_expiry_text := v_config.config_value ->> 'expiry_days';
  if coalesce(v_expiry_text, '') !~ '^[0-9]{1,4}$'
     or v_expiry_text::integer not between 1 and 3650 then
    raise exception using errcode = 'P0001', message = 'reward_program_invalid';
  end if;

  return query select
    v_config.id,
    coalesce(nullif(v_config.config_value ->> 'contract_version', ''), 'wellness_schedule_v2'),
    10,
    v_expiry_text::integer;
end;
$$;

create or replace function public.reward_text_is_vietnamese(p_text text)
returns boolean
language sql
immutable
set search_path = public, pg_temp
as $$
  select
    nullif(btrim(coalesce(p_text, '')), '') is not null
    and p_text ~ '[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]'
    and p_text !~ '(Ã.|Â.|Ä.|Æ.|�)'
$$;

create or replace function public.refresh_wellness_reward_wallet(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_newly_available integer := 0;
  v_expired integer := 0;
begin
  if p_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  insert into public.wellness_reward_wallets (user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  perform 1
  from public.wellness_reward_wallets
  where user_id = p_user_id
  for update;

  perform 1
  from public.wellness_point_allocations
  where user_id = p_user_id
    and status = 'pending'
    and available_at <= now()
    and remaining_points > 0
  for update;

  select coalesce(sum(remaining_points), 0)::integer
  into v_newly_available
  from public.wellness_point_allocations
  where user_id = p_user_id
    and status = 'pending'
    and available_at <= now()
    and remaining_points > 0;

  update public.wellness_point_allocations
  set status = 'available', updated_at = now()
  where user_id = p_user_id
    and status = 'pending'
    and available_at <= now()
    and remaining_points > 0;

  if v_newly_available > 0 then
    update public.wellness_reward_wallets
    set
      pending_points = pending_points - v_newly_available,
      available_points = available_points + v_newly_available,
      lock_version = lock_version + 1,
      updated_at = now()
    where user_id = p_user_id;
  end if;

  perform 1
  from public.wellness_point_allocations
  where user_id = p_user_id
    and status = 'available'
    and expires_at <= now()
    and remaining_points > 0
  for update;

  select coalesce(sum(remaining_points), 0)::integer
  into v_expired
  from public.wellness_point_allocations
  where user_id = p_user_id
    and status = 'available'
    and expires_at <= now()
    and remaining_points > 0;

  insert into public.wellness_point_ledgers (
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    available_at,
    expires_at,
    program_config_id,
    metadata
  )
  select
    wpa.user_id,
    wpa.subject_id,
    'wellness_point_allocation',
    wpa.id,
    (wpa.expires_at at time zone 'Asia/Ho_Chi_Minh')::date,
    -wpa.remaining_points,
    'wellness_rewards_v2',
    'wellness_expiry:' || wpa.id::text,
    'expiry',
    'expired',
    'Điểm chăm sóc đã hết hạn',
    true,
    wpa.available_at,
    wpa.expires_at,
    wpa.program_config_id,
    jsonb_build_object('allocation_id', wpa.id)
  from public.wellness_point_allocations wpa
  where wpa.user_id = p_user_id
    and wpa.status = 'available'
    and wpa.expires_at <= now()
    and wpa.remaining_points > 0
  on conflict (user_id, idempotency_key) do nothing;

  update public.wellness_point_allocations
  set remaining_points = 0, status = 'expired', updated_at = now()
  where user_id = p_user_id
    and status = 'available'
    and expires_at <= now()
    and remaining_points > 0;

  if v_expired > 0 then
    update public.wellness_reward_wallets
    set
      available_points = available_points - v_expired,
      lock_version = lock_version + 1,
      updated_at = now()
    where user_id = p_user_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 16B. RLS, grants and private Storage contract
-- ---------------------------------------------------------------------------

alter table public.guest_schedule_reward_registrations enable row level security;
alter table public.member_schedule_reward_registrations enable row level security;
alter table public.schedule_reward_eligibilities enable row level security;
alter table public.schedule_completion_attempts enable row level security;
alter table public.schedule_completion_proofs enable row level security;
alter table public.wellness_reward_wallets enable row level security;
alter table public.wellness_point_allocations enable row level security;
alter table public.wellness_reward_offers enable row level security;
alter table public.wellness_reward_codes enable row level security;
alter table public.wellness_reward_redemptions enable row level security;
alter table public.wellness_redemption_allocation_usages enable row level security;

drop policy if exists wellness_point_ledgers_select_subject
  on public.wellness_point_ledgers;
drop policy if exists wellness_point_ledgers_insert_subject
  on public.wellness_point_ledgers;
drop policy if exists wellness_point_ledgers_update_subject
  on public.wellness_point_ledgers;
drop policy if exists wellness_point_ledgers_delete_subject
  on public.wellness_point_ledgers;
drop policy if exists wellness_point_ledgers_select_own
  on public.wellness_point_ledgers;
create policy wellness_point_ledgers_select_own
  on public.wellness_point_ledgers for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists schedule_reward_eligibilities_select_own
  on public.schedule_reward_eligibilities;
create policy schedule_reward_eligibilities_select_own
  on public.schedule_reward_eligibilities for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists schedule_completion_attempts_select_own
  on public.schedule_completion_attempts;
create policy schedule_completion_attempts_select_own
  on public.schedule_completion_attempts for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists schedule_completion_proofs_select_own
  on public.schedule_completion_proofs;
create policy schedule_completion_proofs_select_own
  on public.schedule_completion_proofs for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists wellness_reward_wallets_select_own
  on public.wellness_reward_wallets;
create policy wellness_reward_wallets_select_own
  on public.wellness_reward_wallets for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists wellness_point_allocations_select_own
  on public.wellness_point_allocations;
create policy wellness_point_allocations_select_own
  on public.wellness_point_allocations for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists wellness_reward_offers_select_active
  on public.wellness_reward_offers;
create policy wellness_reward_offers_select_active
  on public.wellness_reward_offers for select to authenticated
  using (is_active = true);

drop policy if exists wellness_reward_redemptions_select_own
  on public.wellness_reward_redemptions;
create policy wellness_reward_redemptions_select_own
  on public.wellness_reward_redemptions for select to authenticated
  using (user_id = (select auth.uid()));

revoke all on
  public.guest_schedule_reward_registrations,
  public.member_schedule_reward_registrations,
  public.schedule_reward_eligibilities,
  public.schedule_completion_attempts,
  public.schedule_completion_proofs,
  public.wellness_reward_wallets,
  public.wellness_point_allocations,
  public.wellness_reward_offers,
  public.wellness_reward_codes,
  public.wellness_reward_redemptions,
  public.wellness_redemption_allocation_usages
from anon, authenticated;

revoke insert, update, delete on public.wellness_point_ledgers
from anon, authenticated;
grant select on
  public.schedule_reward_eligibilities,
  public.schedule_completion_attempts,
  public.schedule_completion_proofs,
  public.wellness_reward_wallets,
  public.wellness_point_ledgers,
  public.wellness_point_allocations,
  public.wellness_reward_offers,
  public.wellness_reward_redemptions
to authenticated;

insert into public.admin_permissions (code, description)
values
  ('wellness_rewards.read', 'Xem danh mục, tồn kho và giao dịch Điểm chăm sóc.'),
  ('wellness_rewards.write', 'Quản lý ưu đãi, kho mã và hủy giao dịch Điểm chăm sóc.')
on conflict (code) do update
set description = excluded.description, is_active = true;

create or replace function public.can_access_schedule_proof_object(p_name text)
returns boolean
language sql
stable
security definer
set search_path = public, storage, pg_temp
as $$
  select
    split_part(coalesce(p_name, ''), '/', 1) = auth.uid()::text
    and exists (
      select 1
      from public.schedule_completion_attempts sca
      where sca.user_id = auth.uid()
        and sca.object_path = p_name
        and sca.status in ('begun', 'finalized', 'undone')
    )
$$;

revoke all on function public.guard_wellness_point_ledger_append_only()
from public, anon, authenticated;
revoke all on function public.refresh_wellness_reward_wallet(uuid)
from public, anon, authenticated;
revoke all on function public.current_wellness_reward_program()
from public, anon, authenticated;
revoke all on function public.reward_text_is_vietnamese(text)
from public, anon, authenticated;
revoke all on function public.can_access_schedule_proof_object(text)
from public, anon;
grant execute on function public.can_access_schedule_proof_object(text)
to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'schedule-completion-proofs',
  'schedule-completion-proofs',
  false,
  5242880,
  array['image/jpeg']::text[]
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists schedule_completion_proofs_storage_select_own
  on storage.objects;
create policy schedule_completion_proofs_storage_select_own
  on storage.objects for select to authenticated
  using (
    bucket_id = 'schedule-completion-proofs'
    and public.can_access_schedule_proof_object(name)
  );

drop policy if exists schedule_completion_proofs_storage_insert_own
  on storage.objects;
create policy schedule_completion_proofs_storage_insert_own
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'schedule-completion-proofs'
    and split_part(name, '/', 1) = auth.uid()::text
    and public.can_access_schedule_proof_object(name)
  );

-- Deliberately no authenticated UPDATE or DELETE policy. Combined with the
-- server-issued unique path this makes Storage upsert impossible and keeps
-- active/reversed evidence until account deletion or trusted retention work.
drop policy if exists schedule_completion_proofs_storage_update_own
  on storage.objects;
drop policy if exists schedule_completion_proofs_storage_delete_own
  on storage.objects;

-- ---------------------------------------------------------------------------
-- 16C. Schedule eligibility, proof and +10 point RPCs
-- ---------------------------------------------------------------------------

create or replace function public.register_my_schedule_reward_eligibilities(
  p_request_id text,
  p_items jsonb,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_subject_id uuid;
  v_request public.personal_schedule_ai_requests%rowtype;
  v_guest_marker public.guest_schedule_reward_registrations%rowtype;
  v_member_marker public.member_schedule_reward_registrations%rowtype;
  v_item_count integer;
  v_matched_count integer;
  v_full_item_count integer;
  v_full_day_count integer;
  v_request_eligible_count integer;
  v_manifest_hash text;
  v_full_item_id_hash text;
  v_full_manifest_hash text;
  v_full_item_ids uuid[];
  v_guest_eligible_item_ids uuid[];
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if nullif(btrim(coalesce(p_request_id, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'schedule_request_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if jsonb_typeof(p_items) <> 'array' then
    raise exception using errcode = 'P0001', message = 'schedule_items_invalid';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:register:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  v_item_count := jsonb_array_length(p_items);
  if v_item_count < 1 or v_item_count > 70 then
    raise exception using errcode = 'P0001', message = 'schedule_items_invalid';
  end if;

  if exists (
    select 1 from public.users
    where id = v_user_id and is_anonymous = true
  ) then
    raise exception using errcode = 'P0001', message = 'member_account_required';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'eligibility_id', sre.id,
        'schedule_item_id', sre.schedule_item_id,
        'schedule_date', sre.schedule_date,
        'window_start', sre.window_start,
        'window_end', sre.window_end,
        'status', sre.status
      ) order by sre.window_start
    ),
    '[]'::jsonb
  )
  into v_result
  from public.schedule_reward_eligibilities sre
  where sre.user_id = v_user_id
    and sre.registration_idempotency_key = btrim(p_idempotency_key);

  if jsonb_array_length(v_result) > 0 then
    if exists (
      select 1
      from public.schedule_reward_eligibilities sre
      where sre.user_id = v_user_id
        and sre.registration_idempotency_key = btrim(p_idempotency_key)
        and sre.schedule_request_id <> btrim(p_request_id)
    ) then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    return jsonb_build_object(
      'request_id', btrim(p_request_id),
      'registered_count', jsonb_array_length(v_result),
      'eligibilities', v_result,
      'idempotent_replay', true
    );
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) item
    where coalesce(item ->> 'schedule_item_id', item ->> 'id', '')
      !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_item_id_invalid';
  end if;

  select encode(
    digest(string_agg(parsed.schedule_item_id::text, ',' order by parsed.schedule_item_id), 'sha256'),
    'hex'
  )
  into v_manifest_hash
  from (
    select distinct
      coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid as schedule_item_id
    from jsonb_array_elements(p_items) item
  ) parsed;

  select * into v_request
  from public.personal_schedule_ai_requests psar
  where psar.request_id = btrim(p_request_id)
    and psar.user_id = v_user_id
    and psar.actor_mode in ('member_new', 'initial_guest')
    and psar.status = 'succeeded';

  if v_request.request_id is null
     or v_request.start_date is null
     or v_request.days not between 1 and 7
     or v_request.schedule_item_count <> v_request.days * 10 then
    raise exception using errcode = 'P0001', message = 'schedule_request_not_eligible';
  end if;

  -- This request-scoped lock is independent of the client key. It prevents a
  -- second key racing the first registration before its immutable marker is
  -- visible.
  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:register-request:' || btrim(p_request_id),
    0
  ));

  if v_request.actor_mode = 'member_new' then
    if v_request.schedule_item_count <> v_item_count then
      raise exception using errcode = 'P0001', message = 'schedule_request_not_eligible';
    end if;

    if not exists (
      select 1
      from public.usage_events ue
      where ue.user_id = v_user_id
        and ue.feature_key = 'personal_schedule_generation'
        and ue.idempotency_key = btrim(p_request_id)
        and ue.event_source in ('trusted_backend', 'edge_function', 'sql_job', 'admin')
    ) then
      raise exception using errcode = 'P0001', message = 'schedule_quota_commit_required';
    end if;

    select * into v_member_marker
    from public.member_schedule_reward_registrations msrr
    where msrr.schedule_request_id = btrim(p_request_id)
    for update;

    if v_member_marker.schedule_request_id is not null then
      if v_member_marker.user_id <> v_user_id then
        raise exception using errcode = 'P0001', message = 'member_schedule_request_claimed';
      end if;
      raise exception using errcode = 'P0001', message = 'member_schedule_request_already_registered';
    end if;
  else
    -- Different idempotency keys for the same account/request must still
    -- serialize against the lifetime Guest marker and its unique request ID.
    perform pg_advisory_xact_lock(hashtextextended(
      'wellness:guest-register:' || v_user_id::text,
      0
    ));
    if (
      select count(*)
      from public.personal_schedule_ai_requests psar
      where psar.user_id = v_user_id
        and psar.actor_mode = 'initial_guest'
        and psar.status = 'succeeded'
    ) <> 1 then
      raise exception using errcode = 'P0001', message = 'guest_schedule_request_ambiguous';
    end if;

    select * into v_guest_marker
    from public.guest_schedule_reward_registrations gsrr
    where gsrr.user_id = v_user_id
    for update;

    if v_guest_marker.user_id is not null
       and v_guest_marker.schedule_request_id <> btrim(p_request_id) then
      raise exception using errcode = 'P0001', message = 'guest_schedule_request_already_registered';
    end if;
    if v_guest_marker.user_id is not null
       and (
         v_guest_marker.plan_start_date <> v_request.start_date
         or v_guest_marker.plan_days <> v_request.days
         or v_guest_marker.plan_item_count <> v_request.schedule_item_count
       ) then
      raise exception using errcode = 'P0001', message = 'guest_schedule_request_changed';
    end if;
    if exists (
      select 1
      from public.guest_schedule_reward_registrations gsrr
      where gsrr.schedule_request_id = btrim(p_request_id)
        and gsrr.user_id <> v_user_id
    ) then
      raise exception using errcode = 'P0001', message = 'guest_schedule_request_claimed';
    end if;

  end if;

  -- Validate the complete server-side schedule range for both modes. Member
  -- manifests must enumerate this exact set; Guest manifests may be a future,
  -- incomplete subset of it.
  select
    count(*)::integer,
    count(distinct lsi.schedule_date)::integer,
    array_agg(lsi.id order by lsi.id),
    encode(digest(string_agg(lsi.id::text, ',' order by lsi.id), 'sha256'), 'hex'),
    encode(digest(string_agg(
      jsonb_build_array(
        lsi.id,
        lsi.schedule_date,
        lsi.start_time::text,
        lsi.title,
        lsi.category,
        lsi.source_type,
        lsi.source_id
      )::text,
      E'\n' order by lsi.id
    ), 'sha256'), 'hex')
  into
    v_full_item_count,
    v_full_day_count,
    v_full_item_ids,
    v_full_item_id_hash,
    v_full_manifest_hash
  from public.lifestyle_schedule_items lsi
  where lsi.user_id = v_user_id
    and lsi.ai_generated = true
    and lsi.schedule_date >= v_request.start_date
    and lsi.schedule_date < v_request.start_date + v_request.days;

  if v_full_item_count <> v_request.schedule_item_count
     or v_full_day_count <> v_request.days
     or exists (
       select 1
       from public.lifestyle_schedule_items lsi
       where lsi.user_id = v_user_id
         and lsi.ai_generated = true
         and lsi.schedule_date >= v_request.start_date
         and lsi.schedule_date < v_request.start_date + v_request.days
       group by lsi.schedule_date
       having count(*) <> 10
           or count(distinct lsi.start_time) <> 10
     ) then
    if v_request.actor_mode = 'initial_guest' then
      raise exception using errcode = 'P0001', message = 'guest_schedule_plan_invalid';
    end if;
    raise exception using errcode = 'P0001', message = 'member_schedule_plan_invalid';
  end if;

  if v_request.actor_mode = 'member_new'
     and v_manifest_hash <> v_full_item_id_hash then
    raise exception using errcode = 'P0001', message = 'member_schedule_manifest_mismatch';
  end if;
  if v_request.actor_mode = 'initial_guest'
     and v_guest_marker.user_id is not null
     and v_guest_marker.manifest_hash <> v_full_manifest_hash then
    raise exception using errcode = 'P0001', message = 'guest_schedule_request_changed';
  end if;

  if v_request.actor_mode = 'initial_guest' then
    if v_guest_marker.user_id is null then
      select coalesce(array_agg(lsi.id order by lsi.id), '{}'::uuid[])
      into v_guest_eligible_item_ids
      from public.lifestyle_schedule_items lsi
      where lsi.user_id = v_user_id
        and lsi.id = any(v_full_item_ids)
        and lsi.is_completed = false
        and ((lsi.schedule_date + lsi.start_time) at time zone 'Asia/Ho_Chi_Minh') > now();
    else
      v_guest_eligible_item_ids := v_guest_marker.eligible_item_ids;
    end if;
  end if;

  select count(distinct lsi.id)::integer
  into v_matched_count
  from jsonb_array_elements(p_items) item
  join public.lifestyle_schedule_items lsi
    on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
   and lsi.user_id = v_user_id
  where lsi.is_completed = false
    and lsi.ai_generated = true;

  if v_matched_count <> v_item_count then
    raise exception using errcode = 'P0001', message = 'schedule_items_not_found';
  end if;

  if v_request.actor_mode = 'initial_guest' and exists (
    select 1
    from jsonb_array_elements(p_items) item
    where not (
      coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
      = any(v_guest_eligible_item_ids)
    )
  ) then
    raise exception using errcode = 'P0001', message = 'guest_schedule_item_not_in_pinned_plan';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) item
    join public.lifestyle_schedule_items lsi
      on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
     and lsi.user_id = v_user_id
    where lsi.schedule_date < v_request.start_date
       or lsi.schedule_date >= v_request.start_date + v_request.days
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_items_outside_request_range';
  end if;

  if v_request.actor_mode = 'member_new' and exists (
    select 1
    from jsonb_array_elements(p_items) item
    join public.lifestyle_schedule_items lsi
      on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
     and lsi.user_id = v_user_id
    group by lsi.schedule_date
    having count(*) <> 10
        or count(distinct lsi.id) <> 10
        or count(distinct lsi.start_time) <> 10
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_day_must_have_10_items';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) item
    join public.lifestyle_schedule_items lsi
      on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
     and lsi.user_id = v_user_id
    where ((lsi.schedule_date + lsi.start_time) at time zone 'Asia/Ho_Chi_Minh') <= now()
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_window_must_be_future';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) item
    join public.schedule_reward_eligibilities sre
      on sre.user_id = v_user_id
     and sre.schedule_item_id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
    where sre.schedule_request_id <> btrim(p_request_id)
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_item_already_registered';
  end if;

  select hs.id into v_subject_id
  from public.health_subjects hs
  where hs.owner_user_id = v_user_id
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1;

  if v_subject_id is null then
    raise exception using errcode = 'P0001', message = 'health_subject_required';
  end if;

  if v_request.actor_mode = 'initial_guest' then
    insert into public.guest_schedule_reward_registrations (
      user_id,
      schedule_request_id,
      plan_start_date,
      plan_days,
      plan_item_count,
      manifest_hash,
      plan_item_ids,
      eligible_item_ids,
      first_registration_idempotency_key
    )
    values (
      v_user_id,
      btrim(p_request_id),
      v_request.start_date,
      v_request.days,
      v_request.schedule_item_count,
      v_full_manifest_hash,
      v_full_item_ids,
      v_guest_eligible_item_ids,
      btrim(p_idempotency_key)
    )
    on conflict (user_id) do nothing;
  else
    insert into public.member_schedule_reward_registrations (
      schedule_request_id,
      user_id,
      plan_start_date,
      plan_days,
      plan_item_count,
      manifest_hash,
      registration_idempotency_key
    )
    values (
      btrim(p_request_id),
      v_user_id,
      v_request.start_date,
      v_request.days,
      v_request.schedule_item_count,
      v_full_manifest_hash,
      btrim(p_idempotency_key)
    );
  end if;

  insert into public.schedule_reward_eligibilities (
    user_id,
    subject_id,
    schedule_item_id,
    schedule_request_id,
    schedule_date,
    start_time,
    window_start,
    window_end,
    title_snapshot,
    category_snapshot,
    source_type_snapshot,
    source_id_snapshot,
    registration_idempotency_key
  )
  select
    v_user_id,
    v_subject_id,
    lsi.id,
    btrim(p_request_id),
    lsi.schedule_date,
    lsi.start_time,
    ((lsi.schedule_date + lsi.start_time) at time zone 'Asia/Ho_Chi_Minh'),
    ((lsi.schedule_date + lsi.start_time) at time zone 'Asia/Ho_Chi_Minh') + interval '30 minutes',
    lsi.title,
    lsi.category,
    lsi.source_type,
    lsi.source_id,
    btrim(p_idempotency_key)
  from jsonb_array_elements(p_items) item
  join public.lifestyle_schedule_items lsi
    on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
   and lsi.user_id = v_user_id
  on conflict (user_id, schedule_item_id) do nothing;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'eligibility_id', sre.id,
        'schedule_item_id', sre.schedule_item_id,
        'schedule_date', sre.schedule_date,
        'window_start', sre.window_start,
        'window_end', sre.window_end,
        'status', sre.status
      ) order by sre.window_start
    ),
    '[]'::jsonb
  )
  into v_result
  from public.schedule_reward_eligibilities sre
  where sre.user_id = v_user_id
    and sre.schedule_request_id = btrim(p_request_id)
    and sre.schedule_item_id in (
      select coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
      from jsonb_array_elements(p_items) item
    );

  if jsonb_array_length(v_result) <> v_item_count then
    raise exception using errcode = 'P0001', message = 'eligibility_registration_conflict';
  end if;

  select count(*)::integer
  into v_request_eligible_count
  from public.schedule_reward_eligibilities sre
  where sre.user_id = v_user_id
    and sre.schedule_request_id = btrim(p_request_id);

  if v_request_eligible_count > v_request.schedule_item_count then
    raise exception using errcode = 'P0001', message = 'schedule_request_eligibility_limit_exceeded';
  end if;

  if v_request.actor_mode = 'initial_guest' then
    update public.guest_schedule_reward_registrations gsrr
    set registered_item_count = v_request_eligible_count
    where gsrr.user_id = v_user_id
      and gsrr.schedule_request_id = btrim(p_request_id);
  else
    if v_request_eligible_count <> v_request.schedule_item_count then
      raise exception using errcode = 'P0001', message = 'member_schedule_manifest_incomplete';
    end if;
    update public.member_schedule_reward_registrations msrr
    set registered_item_count = v_request_eligible_count
    where msrr.schedule_request_id = btrim(p_request_id)
      and msrr.user_id = v_user_id;
  end if;

  return jsonb_build_object(
    'request_id', btrim(p_request_id),
    'registered_count', v_item_count,
    'eligibilities', v_result,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.begin_my_schedule_completion(
  p_schedule_item_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_eligibility public.schedule_reward_eligibilities%rowtype;
  v_attempt public.schedule_completion_attempts%rowtype;
  v_attempt_id uuid := gen_random_uuid();
  v_path text;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if p_schedule_item_id is null then
    raise exception using errcode = 'P0001', message = 'schedule_item_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:begin:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  select * into v_attempt
  from public.schedule_completion_attempts sca
  where sca.user_id = v_user_id
    and sca.begin_idempotency_key = btrim(p_idempotency_key);

  if v_attempt.id is not null then
    if not exists (
      select 1
      from public.schedule_reward_eligibilities sre
      where sre.id = v_attempt.eligibility_id
        and sre.schedule_item_id = p_schedule_item_id
    ) then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    if v_attempt.status = 'undone' then
      raise exception using errcode = 'P0001', message = 'eligibility_not_available';
    end if;
    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'eligibility_id', v_attempt.eligibility_id,
      'bucket_id', 'schedule-completion-proofs',
      'storage_path', v_attempt.object_path,
      'object_path', v_attempt.object_path,
      'content_type', 'image/jpeg',
      'max_bytes', 5242880,
      'window_end', (
        select window_end from public.schedule_reward_eligibilities
        where id = v_attempt.eligibility_id
      ),
      'upload_deadline', (
        select window_end from public.schedule_reward_eligibilities
        where id = v_attempt.eligibility_id
      ),
      'status', v_attempt.status,
      'idempotent_replay', true
    );
  end if;

  select * into v_eligibility
  from public.schedule_reward_eligibilities sre
  where sre.schedule_item_id = p_schedule_item_id
    and sre.user_id = v_user_id
  for update;

  if v_eligibility.id is null then
    raise exception using errcode = 'P0001', message = 'eligibility_not_found';
  end if;
  if v_eligibility.status = 'completed' then
    raise exception using errcode = 'P0001', message = 'schedule_already_completed';
  end if;
  if v_eligibility.status <> 'eligible' then
    raise exception using errcode = 'P0001', message = 'eligibility_not_available';
  end if;
  if now() < v_eligibility.window_start then
    raise exception using errcode = 'P0001', message = 'schedule_window_not_open';
  end if;
  if now() >= v_eligibility.window_end then
    raise exception using errcode = 'P0001', message = 'schedule_window_locked';
  end if;

  v_path := v_user_id::text || '/' || v_eligibility.id::text || '/' || v_attempt_id::text || '.jpg';

  insert into public.schedule_completion_attempts (
    id,
    eligibility_id,
    user_id,
    begin_idempotency_key,
    object_path
  )
  values (
    v_attempt_id,
    v_eligibility.id,
    v_user_id,
    btrim(p_idempotency_key),
    v_path
  )
  returning * into v_attempt;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'eligibility_id', v_attempt.eligibility_id,
    'bucket_id', 'schedule-completion-proofs',
    'storage_path', v_attempt.object_path,
    'object_path', v_attempt.object_path,
    'content_type', 'image/jpeg',
    'max_bytes', 5242880,
    'window_end', v_eligibility.window_end,
    'upload_deadline', v_eligibility.window_end,
    'status', v_attempt.status,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.finalize_my_schedule_completion(
  p_attempt_id uuid,
  p_storage_path text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, storage, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt public.schedule_completion_attempts%rowtype;
  v_eligibility public.schedule_reward_eligibilities%rowtype;
  v_object storage.objects%rowtype;
  v_proof public.schedule_completion_proofs%rowtype;
  v_allocation public.wellness_point_allocations%rowtype;
  v_wallet public.wellness_reward_wallets%rowtype;
  v_program record;
  v_ledger_id uuid := gen_random_uuid();
  v_allocation_id uuid := gen_random_uuid();
  v_size_text text;
  v_content_type text;
  v_byte_size integer;
  v_reward_status text;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if p_attempt_id is null then
    raise exception using errcode = 'P0001', message = 'completion_attempt_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if nullif(btrim(coalesce(p_storage_path, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'storage_path_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:finalize:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  if exists (
    select 1
    from public.schedule_completion_attempts sca
    where sca.user_id = v_user_id
      and sca.finalize_idempotency_key = btrim(p_idempotency_key)
      and sca.id <> p_attempt_id
  ) then
    raise exception using errcode = 'P0001', message = 'idempotency_conflict';
  end if;

  select * into v_attempt
  from public.schedule_completion_attempts sca
  where sca.id = p_attempt_id
    and sca.user_id = v_user_id
  for update;

  if v_attempt.id is null then
    raise exception using errcode = 'P0001', message = 'completion_attempt_not_found';
  end if;
  if v_attempt.object_path <> btrim(p_storage_path) then
    raise exception using errcode = 'P0001', message = 'storage_path_mismatch';
  end if;

  select * into v_eligibility
  from public.schedule_reward_eligibilities sre
  where sre.id = v_attempt.eligibility_id
    and sre.user_id = v_user_id
  for update;

  if v_attempt.status = 'finalized' then
    if v_attempt.finalize_idempotency_key <> btrim(p_idempotency_key) then
      raise exception using errcode = 'P0001', message = 'schedule_already_completed';
    end if;

    select * into v_proof
    from public.schedule_completion_proofs scp
    where scp.attempt_id = v_attempt.id;

    select * into v_allocation
    from public.wellness_point_allocations wpa
    where wpa.source_type = 'schedule_reward'
      and wpa.source_id = v_attempt.id;

    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;

    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'eligibility_id', v_attempt.eligibility_id,
      'proof_id', v_proof.id,
      'proof_status', v_proof.status,
      'reward_points', v_allocation.original_points,
      'points_delta', v_allocation.original_points,
      'reward_status', v_allocation.status,
      'available_at', v_allocation.available_at,
      'expires_at', v_allocation.expires_at,
      'pending_points', v_wallet.pending_points,
      'available_points', v_wallet.available_points,
      'idempotent_replay', true
    );
  end if;

  if v_eligibility.id is null then
    raise exception using errcode = 'P0001', message = 'eligibility_not_available';
  end if;
  if exists (
    select 1
    from public.wellness_point_allocations wpa
    where wpa.eligibility_id = v_eligibility.id
  ) then
    raise exception using errcode = 'P0001', message = 'eligibility_reward_already_awarded';
  end if;
  if v_eligibility.status <> 'eligible' then
    raise exception using errcode = 'P0001', message = 'eligibility_not_available';
  end if;
  if v_attempt.status <> 'begun' then
    raise exception using errcode = 'P0001', message = 'completion_attempt_not_active';
  end if;

  select * into v_object
  from storage.objects so
  where so.bucket_id = 'schedule-completion-proofs'
    and so.name = v_attempt.object_path
  limit 1;

  if v_object.id is null then
    raise exception using errcode = 'P0001', message = 'proof_not_uploaded';
  end if;
  if v_object.created_at < greatest(v_attempt.began_at, v_eligibility.window_start)
     or v_object.created_at >= v_eligibility.window_end then
    raise exception using errcode = 'P0001', message = 'proof_upload_outside_window';
  end if;

  v_content_type := lower(coalesce(
    v_object.metadata ->> 'mimetype',
    v_object.metadata ->> 'contentType',
    ''
  ));
  v_size_text := coalesce(v_object.metadata ->> 'size', '');

  if v_content_type <> 'image/jpeg' then
    raise exception using errcode = 'P0001', message = 'proof_content_type_invalid';
  end if;
  if v_size_text !~ '^[0-9]{1,7}$' then
    raise exception using errcode = 'P0001', message = 'proof_size_invalid';
  end if;
  v_byte_size := v_size_text::integer;
  if v_byte_size < 1 or v_byte_size > 5242880 then
    raise exception using errcode = 'P0001', message = 'proof_size_invalid';
  end if;

  select * into v_program
  from public.current_wellness_reward_program();

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  v_reward_status := case
    when now() >= v_eligibility.window_end then 'available'
    else 'pending'
  end;

  insert into public.schedule_completion_proofs (
    eligibility_id,
    attempt_id,
    user_id,
    object_path,
    content_type,
    byte_size,
    captured_at,
    uploaded_at
  )
  values (
    v_eligibility.id,
    v_attempt.id,
    v_user_id,
    v_attempt.object_path,
    v_content_type,
    v_byte_size,
    greatest(
      v_attempt.began_at,
      v_eligibility.window_start,
      v_object.created_at
    ),
    v_object.created_at
  )
  returning * into v_proof;

  insert into public.wellness_point_ledgers (
    id,
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    available_at,
    expires_at,
    program_config_id,
    eligibility_id,
    metadata
  )
  values (
    v_ledger_id,
    v_user_id,
    v_eligibility.subject_id,
    'schedule_completion_attempt',
    v_attempt.id,
    v_eligibility.schedule_date,
    v_program.reward_points,
    v_program.contract_version,
    'schedule_reward:' || v_attempt.id::text,
    'schedule_award',
    v_reward_status,
    'Hoàn thành nhiệm vụ: ' || v_eligibility.title_snapshot,
    true,
    v_eligibility.window_end,
    v_eligibility.window_end + make_interval(days => v_program.expiry_days),
    v_program.program_config_id,
    v_eligibility.id,
    jsonb_build_object(
      'attempt_id', v_attempt.id,
      'proof_id', v_proof.id,
      'client_idempotency_key', btrim(p_idempotency_key)
    )
  );

  insert into public.wellness_point_allocations (
    id,
    user_id,
    subject_id,
    ledger_id,
    eligibility_id,
    source_type,
    source_id,
    original_points,
    remaining_points,
    status,
    available_at,
    expires_at,
    program_config_id
  )
  values (
    v_allocation_id,
    v_user_id,
    v_eligibility.subject_id,
    v_ledger_id,
    v_eligibility.id,
    'schedule_reward',
    v_attempt.id,
    v_program.reward_points,
    v_program.reward_points,
    v_reward_status,
    v_eligibility.window_end,
    v_eligibility.window_end + make_interval(days => v_program.expiry_days),
    v_program.program_config_id
  )
  returning * into v_allocation;

  update public.wellness_reward_wallets
  set
    pending_points = pending_points + case when v_reward_status = 'pending' then v_program.reward_points else 0 end,
    available_points = available_points + case when v_reward_status = 'available' then v_program.reward_points else 0 end,
    lifetime_earned_points = lifetime_earned_points + v_program.reward_points,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  update public.schedule_completion_attempts
  set
    finalize_idempotency_key = btrim(p_idempotency_key),
    status = 'finalized',
    finalized_at = now(),
    updated_at = now()
  where id = v_attempt.id;

  update public.schedule_reward_eligibilities
  set status = 'completed', updated_at = now()
  where id = v_eligibility.id;

  update public.lifestyle_schedule_items
  set
    is_completed = true,
    current_value = greatest(current_value, target_value),
    updated_at = now()
  where id = v_eligibility.schedule_item_id
    and user_id = v_user_id;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'eligibility_id', v_eligibility.id,
    'proof_id', v_proof.id,
    'proof_status', v_proof.status,
    'reward_points', v_allocation.original_points,
    'points_delta', v_allocation.original_points,
    'reward_status', v_allocation.status,
    'available_at', v_allocation.available_at,
    'expires_at', v_allocation.expires_at,
    'pending_points', v_wallet.pending_points,
    'available_points', v_wallet.available_points,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.undo_my_schedule_completion(
  p_schedule_item_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_eligibility public.schedule_reward_eligibilities%rowtype;
  v_proof public.schedule_completion_proofs%rowtype;
  v_attempt public.schedule_completion_attempts%rowtype;
  v_allocation public.wellness_point_allocations%rowtype;
  v_wallet public.wellness_reward_wallets%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if p_schedule_item_id is null then
    raise exception using errcode = 'P0001', message = 'schedule_item_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:undo:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  select * into v_proof
  from public.schedule_completion_proofs scp
  where scp.user_id = v_user_id
    and scp.undo_idempotency_key = btrim(p_idempotency_key);

  if v_proof.id is not null then
    if not exists (
      select 1
      from public.schedule_reward_eligibilities sre
      where sre.id = v_proof.eligibility_id
        and sre.schedule_item_id = p_schedule_item_id
    ) then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;
    return jsonb_build_object(
      'eligibility_id', v_proof.eligibility_id,
      'schedule_item_id', p_schedule_item_id,
      'proof_id', v_proof.id,
      'proof_status', v_proof.status,
      'reward_delta', -10,
      'points_delta', -10,
      'reward_status', 'reversed',
      'pending_points', v_wallet.pending_points,
      'available_points', v_wallet.available_points,
      'idempotent_replay', true
    );
  end if;

  -- An undo may arrive while upload/finalize is still pending. Persist the
  -- client key on the attempt so a lost response can be replayed without ever
  -- creating or reversing points.
  select * into v_attempt
  from public.schedule_completion_attempts sca
  where sca.user_id = v_user_id
    and sca.undo_idempotency_key = btrim(p_idempotency_key);

  if v_attempt.id is not null then
    if not exists (
      select 1
      from public.schedule_reward_eligibilities sre
      where sre.id = v_attempt.eligibility_id
        and sre.schedule_item_id = p_schedule_item_id
    ) then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;
    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'eligibility_id', v_attempt.eligibility_id,
      'schedule_item_id', p_schedule_item_id,
      'proof_id', null,
      'proof_status', 'not_created',
      'reward_delta', 0,
      'points_delta', 0,
      'reward_status', 'not_awarded',
      'pending_points', v_wallet.pending_points,
      'available_points', v_wallet.available_points,
      'idempotent_replay', true
    );
  end if;

  select * into v_eligibility
  from public.schedule_reward_eligibilities sre
  where sre.schedule_item_id = p_schedule_item_id
    and sre.user_id = v_user_id
  for update;

  if v_eligibility.id is null then
    raise exception using errcode = 'P0001', message = 'eligibility_not_found';
  end if;
  if now() >= v_eligibility.window_end then
    raise exception using errcode = 'P0001', message = 'undo_window_locked';
  end if;

  if v_eligibility.status = 'eligible' then
    select * into v_attempt
    from public.schedule_completion_attempts sca
    where sca.eligibility_id = v_eligibility.id
      and sca.user_id = v_user_id
      and sca.status = 'begun'
    order by sca.began_at desc, sca.id desc
    limit 1
    for update;

    if v_attempt.id is null then
      raise exception using errcode = 'P0001', message = 'schedule_not_completed';
    end if;

    update public.schedule_completion_attempts
    set
      status = 'undone',
      undo_idempotency_key = btrim(p_idempotency_key),
      rejection_code = 'cancelled_by_user_before_finalize',
      updated_at = now()
    where id = v_attempt.id;

    -- A caller may have begun more than one attempt with different keys. Once
    -- the task is undone, every still-open attempt must become non-finalizable.
    update public.schedule_completion_attempts
    set
      status = 'undone',
      rejection_code = 'cancelled_by_user_before_finalize',
      updated_at = now()
    where eligibility_id = v_eligibility.id
      and user_id = v_user_id
      and status = 'begun'
      and id <> v_attempt.id;

    update public.schedule_reward_eligibilities
    set status = 'undone', updated_at = now()
    where id = v_eligibility.id;

    update public.lifestyle_schedule_items
    set is_completed = false, current_value = 0, updated_at = now()
    where id = v_eligibility.schedule_item_id
      and user_id = v_user_id;

    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;

    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'eligibility_id', v_eligibility.id,
      'schedule_item_id', p_schedule_item_id,
      'proof_id', null,
      'proof_status', 'not_created',
      'reward_delta', 0,
      'points_delta', 0,
      'reward_status', 'not_awarded',
      'pending_points', v_wallet.pending_points,
      'available_points', v_wallet.available_points,
      'idempotent_replay', false
    );
  end if;

  if v_eligibility.status <> 'completed' then
    raise exception using errcode = 'P0001', message = 'eligibility_not_available';
  end if;

  select * into v_proof
  from public.schedule_completion_proofs scp
  where scp.eligibility_id = v_eligibility.id
    and scp.user_id = v_user_id
    and scp.status = 'active'
  for update;

  if v_proof.id is null then
    raise exception using errcode = 'P0001', message = 'active_proof_not_found';
  end if;

  select * into v_attempt
  from public.schedule_completion_attempts sca
  where sca.id = v_proof.attempt_id
  for update;

  select * into v_allocation
  from public.wellness_point_allocations wpa
  where wpa.user_id = v_user_id
    and wpa.source_type = 'schedule_reward'
    and wpa.source_id = v_attempt.id
  for update;

  if v_allocation.id is null or v_allocation.status <> 'pending'
     or v_allocation.remaining_points <> v_allocation.original_points then
    raise exception using errcode = 'P0001', message = 'reward_cannot_be_undone';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  insert into public.wellness_point_ledgers (
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    available_at,
    expires_at,
    program_config_id,
    eligibility_id,
    metadata
  )
  values (
    v_user_id,
    v_eligibility.subject_id,
    'schedule_completion_proof',
    v_proof.id,
    v_eligibility.schedule_date,
    -v_allocation.original_points,
    'wellness_rewards_v2',
    'schedule_undo:' || v_proof.id::text,
    'schedule_reversal',
    'reversed',
    'Hoàn tác nhiệm vụ: ' || v_eligibility.title_snapshot,
    true,
    v_allocation.available_at,
    v_allocation.expires_at,
    v_allocation.program_config_id,
    v_eligibility.id,
    jsonb_build_object('client_idempotency_key', btrim(p_idempotency_key))
  );

  update public.wellness_point_allocations
  set remaining_points = 0, status = 'reversed', updated_at = now()
  where id = v_allocation.id;

  update public.wellness_reward_wallets
  set
    pending_points = pending_points - v_allocation.original_points,
    lifetime_earned_points = lifetime_earned_points - v_allocation.original_points,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  update public.schedule_completion_proofs
  set
    status = 'reversed',
    reversed_at = now(),
    undo_idempotency_key = btrim(p_idempotency_key),
    updated_at = now()
  where id = v_proof.id;

  update public.schedule_completion_attempts
  set status = 'undone', updated_at = now()
  where id = v_attempt.id;

  update public.schedule_reward_eligibilities
  set status = 'undone', updated_at = now()
  where id = v_eligibility.id;

  update public.lifestyle_schedule_items
  set is_completed = false, current_value = 0, updated_at = now()
  where id = v_eligibility.schedule_item_id
    and user_id = v_user_id;

  return jsonb_build_object(
    'eligibility_id', v_eligibility.id,
    'schedule_item_id', p_schedule_item_id,
    'proof_id', v_proof.id,
    'proof_status', 'reversed',
    'reward_delta', -v_allocation.original_points,
    'points_delta', -v_allocation.original_points,
    'reward_status', 'reversed',
    'pending_points', v_wallet.pending_points,
    'available_points', v_wallet.available_points,
    'idempotent_replay', false
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 16D. User wallet, catalog and atomic redemption RPCs
-- ---------------------------------------------------------------------------

create or replace function public.get_my_wellness_reward_summary()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_wallet public.wellness_reward_wallets%rowtype;
  v_expiring integer := 0;
  v_next_expiry timestamptz;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id;

  select
    coalesce(sum(remaining_points), 0)::integer,
    min(expires_at)
  into v_expiring, v_next_expiry
  from public.wellness_point_allocations
  where user_id = v_user_id
    and status = 'available'
    and remaining_points > 0
    and expires_at > now()
    and expires_at <= now() + interval '30 days';

  return jsonb_build_object(
    'pending_points', v_wallet.pending_points,
    'available_points', v_wallet.available_points,
    'expiring_soon_points', v_expiring,
    'next_expiry_at', v_next_expiry,
    'synced_at', now(),
    'program_enabled', public.wellness_rewards_feature_enabled()
  );
end;
$$;

create or replace function public.list_my_wellness_point_history(
  p_limit integer default 100
)
returns table (
  id uuid,
  points_delta integer,
  event_type text,
  status text,
  title text,
  is_redeemable boolean,
  available_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);

  return query
  select
    wpl.id,
    wpl.points_delta,
    wpl.event_type,
    case
      when wpl.event_type = 'schedule_award' then coalesce(wpa.status, wpl.status)
      else wpl.status
    end,
    wpl.title,
    wpl.is_redeemable,
    wpl.available_at,
    wpl.expires_at,
    wpl.created_at
  from public.wellness_point_ledgers wpl
  left join public.wellness_point_allocations wpa
    on wpa.ledger_id = wpl.id
  where wpl.user_id = v_user_id
  order by wpl.created_at desc, wpl.id desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.list_my_reward_offers(
  p_limit integer default 100
)
returns table (
  id uuid,
  offer_id uuid,
  offer_code text,
  title text,
  description text,
  provider_name text,
  cost_points integer,
  available_codes integer,
  eligible_plan_codes text[],
  available_from timestamptz,
  available_until timestamptz,
  voucher_expires_at timestamptz,
  is_active boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan text;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  v_plan := public.current_plan_for_user(v_user_id)::text;

  return query
  select
    wro.id,
    wro.id,
    wro.offer_code,
    wro.title,
    wro.description,
    wro.provider_name,
    wro.cost_points,
    count(wrc.id) filter (
      where wrc.status = 'available'
        and coalesce(wrc.voucher_expires_at, wro.voucher_expires_at) > now()
    )::integer,
    wro.eligible_plan_codes,
    wro.available_from,
    wro.available_until,
    wro.voucher_expires_at,
    wro.is_active
  from public.wellness_reward_offers wro
  left join public.wellness_reward_codes wrc
    on wrc.offer_id = wro.id
  where public.wellness_rewards_feature_enabled()
    and wro.is_active = true
    and (wro.available_from is null or wro.available_from <= now())
    and (wro.available_until is null or wro.available_until > now())
    and v_plan = any(wro.eligible_plan_codes)
  group by wro.id
  order by wro.cost_points, wro.created_at desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.redeem_my_reward_offer(
  p_offer_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan text;
  v_offer public.wellness_reward_offers%rowtype;
  v_code public.wellness_reward_codes%rowtype;
  v_existing public.wellness_reward_redemptions%rowtype;
  v_redemption_id uuid := gen_random_uuid();
  v_subject_id uuid;
  v_wallet public.wellness_reward_wallets%rowtype;
  v_allocation record;
  v_needed integer;
  v_take integer;
  v_voucher_expires_at timestamptz;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if p_offer_id is null then
    raise exception using errcode = 'P0001', message = 'offer_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:redeem:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing
  from public.wellness_reward_redemptions wrr
  where wrr.user_id = v_user_id
    and wrr.idempotency_key = btrim(p_idempotency_key)
  for update;

  if v_existing.id is not null then
    if v_existing.offer_id <> p_offer_id then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    select * into v_code
    from public.wellness_reward_codes
    where id = v_existing.reward_code_id;
    return jsonb_build_object(
      'id', v_existing.id,
      'redemption_id', v_existing.id,
      'offer_id', v_existing.offer_id,
      'title', v_existing.offer_title_snapshot,
      'provider_name', v_existing.provider_name_snapshot,
      'points_spent', v_existing.points_spent,
      'status', v_existing.status,
      'voucher_code', case when v_existing.status = 'issued' then v_code.code_value else null end,
      'voucher_expires_at', v_existing.voucher_expires_at,
      'created_at', v_existing.created_at,
      'cancelled_at', v_existing.cancelled_at,
      'idempotent_replay', true
    );
  end if;

  select * into v_offer
  from public.wellness_reward_offers wro
  where wro.id = p_offer_id
  for update;

  if v_offer.id is null
     or not v_offer.is_active
     or (v_offer.available_from is not null and v_offer.available_from > now())
     or (v_offer.available_until is not null and v_offer.available_until <= now()) then
    raise exception using errcode = 'P0001', message = 'offer_unavailable';
  end if;

  v_plan := public.current_plan_for_user(v_user_id)::text;
  if not (v_plan = any(v_offer.eligible_plan_codes)) then
    raise exception using errcode = 'P0001', message = 'offer_ineligible';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  if v_wallet.available_points < v_offer.cost_points then
    raise exception using errcode = 'P0001', message = 'insufficient_points';
  end if;

  select * into v_code
  from public.wellness_reward_codes wrc
  where wrc.offer_id = v_offer.id
    and wrc.status = 'available'
    and coalesce(wrc.voucher_expires_at, v_offer.voucher_expires_at) > now()
  order by coalesce(wrc.voucher_expires_at, v_offer.voucher_expires_at), wrc.created_at
  for update skip locked
  limit 1;

  if v_code.id is null then
    raise exception using errcode = 'P0001', message = 'offer_out_of_stock';
  end if;

  v_voucher_expires_at := coalesce(v_code.voucher_expires_at, v_offer.voucher_expires_at);
  select hs.id into v_subject_id
  from public.health_subjects hs
  where hs.owner_user_id = v_user_id
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1;

  if v_subject_id is null then
    raise exception using errcode = 'P0001', message = 'health_subject_required';
  end if;

  insert into public.wellness_reward_redemptions (
    id,
    user_id,
    offer_id,
    reward_code_id,
    offer_title_snapshot,
    provider_name_snapshot,
    points_spent,
    voucher_expires_at,
    idempotency_key
  )
  values (
    v_redemption_id,
    v_user_id,
    v_offer.id,
    v_code.id,
    v_offer.title,
    v_offer.provider_name,
    v_offer.cost_points,
    v_voucher_expires_at,
    btrim(p_idempotency_key)
  );

  v_needed := v_offer.cost_points;
  for v_allocation in
    select wpa.id, wpa.remaining_points
    from public.wellness_point_allocations wpa
    where wpa.user_id = v_user_id
      and wpa.status = 'available'
      and wpa.remaining_points > 0
      and wpa.expires_at > now()
    order by wpa.expires_at, wpa.created_at, wpa.id
    for update
  loop
    exit when v_needed = 0;
    v_take := least(v_needed, v_allocation.remaining_points);

    insert into public.wellness_redemption_allocation_usages (
      redemption_id,
      allocation_id,
      points_used
    )
    values (v_redemption_id, v_allocation.id, v_take);

    update public.wellness_point_allocations
    set
      remaining_points = remaining_points - v_take,
      status = case when remaining_points - v_take = 0 then 'spent' else status end,
      updated_at = now()
    where id = v_allocation.id;

    v_needed := v_needed - v_take;
  end loop;

  if v_needed <> 0 then
    raise exception using errcode = 'P0001', message = 'wallet_allocation_mismatch';
  end if;

  update public.wellness_reward_codes
  set
    status = 'issued',
    assigned_user_id = v_user_id,
    assigned_redemption_id = v_redemption_id,
    issued_at = now()
  where id = v_code.id;

  insert into public.wellness_point_ledgers (
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    redemption_id,
    metadata
  )
  values (
    v_user_id,
    v_subject_id,
    'reward_redemption',
    v_redemption_id,
    (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    -v_offer.cost_points,
    'wellness_rewards_v2',
    'reward_redemption:' || v_redemption_id::text,
    'redemption',
    'redeemed',
    'Đổi ưu đãi: ' || v_offer.title,
    true,
    v_redemption_id,
    jsonb_build_object('offer_id', v_offer.id)
  );

  update public.wellness_reward_wallets
  set
    available_points = available_points - v_offer.cost_points,
    lifetime_spent_points = lifetime_spent_points + v_offer.cost_points,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  return jsonb_build_object(
    'id', v_redemption_id,
    'redemption_id', v_redemption_id,
    'offer_id', v_offer.id,
    'title', v_offer.title,
    'provider_name', v_offer.provider_name,
    'points_spent', v_offer.cost_points,
    'status', 'issued',
    'voucher_code', v_code.code_value,
    'voucher_expires_at', v_voucher_expires_at,
    'available_points', v_wallet.available_points,
    'created_at', now(),
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.list_my_reward_redemptions(
  p_limit integer default 100
)
returns table (
  id uuid,
  redemption_id uuid,
  offer_id uuid,
  title text,
  provider_name text,
  points_spent integer,
  status text,
  voucher_expires_at timestamptz,
  created_at timestamptz,
  cancelled_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  return query
  select
    wrr.id,
    wrr.id,
    wrr.offer_id,
    wrr.offer_title_snapshot,
    wrr.provider_name_snapshot,
    wrr.points_spent,
    wrr.status,
    wrr.voucher_expires_at,
    wrr.created_at,
    wrr.cancelled_at
  from public.wellness_reward_redemptions wrr
  where wrr.user_id = v_user_id
  order by wrr.created_at desc, wrr.id desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.get_my_reward_code(
  p_redemption_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_redemption public.wellness_reward_redemptions%rowtype;
  v_code public.wellness_reward_codes%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  select * into v_redemption
  from public.wellness_reward_redemptions wrr
  where wrr.id = p_redemption_id
    and wrr.user_id = v_user_id;

  if v_redemption.id is null then
    raise exception using errcode = 'P0001', message = 'redemption_not_found';
  end if;

  select * into v_code
  from public.wellness_reward_codes wrc
  where wrc.id = v_redemption.reward_code_id;

  return jsonb_build_object(
    'redemption_id', v_redemption.id,
    'status', v_redemption.status,
    'voucher_code', case when v_redemption.status = 'issued' then v_code.code_value else null end,
    'voucher_expires_at', v_redemption.voucher_expires_at
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 16E. Admin catalog, inventory, cancellation/refund and audit RPCs
-- ---------------------------------------------------------------------------

create or replace function public.admin_list_wellness_rewards(
  p_query text default '',
  p_limit integer default 100
)
returns table (
  item_type text,
  id uuid,
  offer_id uuid,
  redemption_id uuid,
  title text,
  description text,
  provider_name text,
  cost_points integer,
  points_spent integer,
  status text,
  is_active boolean,
  eligible_plan_codes text[],
  available_from timestamptz,
  available_until timestamptz,
  voucher_expires_at timestamptz,
  available_codes integer,
  issued_codes integer,
  retired_codes integer,
  user_id uuid,
  user_label text,
  masked_code text,
  created_at timestamptz,
  cancelled_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('wellness_rewards.read');

  return query
  with offer_rows as (
    select
      'offer'::text as item_type,
      wro.id,
      wro.id as offer_id,
      null::uuid as redemption_id,
      wro.title,
      wro.description,
      wro.provider_name,
      wro.cost_points,
      null::integer as points_spent,
      case when wro.is_active then 'active' else 'inactive' end::text as status,
      wro.is_active,
      wro.eligible_plan_codes,
      wro.available_from,
      wro.available_until,
      wro.voucher_expires_at,
      count(wrc.id) filter (
        where wrc.status = 'available'
          and coalesce(wrc.voucher_expires_at, wro.voucher_expires_at) > now()
      )::integer as available_codes,
      count(wrc.id) filter (where wrc.status = 'issued')::integer as issued_codes,
      count(wrc.id) filter (where wrc.status = 'retired')::integer as retired_codes,
      null::uuid as user_id,
      null::text as user_label,
      null::text as masked_code,
      wro.created_at,
      null::timestamptz as cancelled_at,
      wro.updated_at as sort_at
    from public.wellness_reward_offers wro
    left join public.wellness_reward_codes wrc on wrc.offer_id = wro.id
    where coalesce(btrim(p_query), '') = ''
       or wro.title ilike '%' || btrim(p_query) || '%'
       or wro.provider_name ilike '%' || btrim(p_query) || '%'
       or wro.offer_code ilike '%' || btrim(p_query) || '%'
    group by wro.id
  ),
  redemption_rows as (
    select
      'redemption'::text as item_type,
      wrr.id,
      wrr.offer_id,
      wrr.id as redemption_id,
      wrr.offer_title_snapshot as title,
      ''::text as description,
      wrr.provider_name_snapshot as provider_name,
      null::integer as cost_points,
      wrr.points_spent,
      wrr.status,
      true as is_active,
      array[]::text[] as eligible_plan_codes,
      null::timestamptz as available_from,
      null::timestamptz as available_until,
      wrr.voucher_expires_at,
      null::integer as available_codes,
      null::integer as issued_codes,
      null::integer as retired_codes,
      wrr.user_id,
      coalesce(
        nullif(u.full_name, ''),
        case
          when position('@' in coalesce(u.email, '')) > 1
            then left(u.email, 1) || '***' || substring(u.email from position('@' in u.email))
          else 'Tài khoản NanoBio'
        end
      ) as user_label,
      '••••••'::text as masked_code,
      wrr.created_at,
      wrr.cancelled_at,
      wrr.updated_at as sort_at
    from public.wellness_reward_redemptions wrr
    join public.users u on u.id = wrr.user_id
    where coalesce(btrim(p_query), '') = ''
       or wrr.offer_title_snapshot ilike '%' || btrim(p_query) || '%'
       or wrr.provider_name_snapshot ilike '%' || btrim(p_query) || '%'
       or coalesce(u.full_name, '') ilike '%' || btrim(p_query) || '%'
       or coalesce(u.email, '') ilike '%' || btrim(p_query) || '%'
  ),
  combined as (
    select * from offer_rows
    union all
    select * from redemption_rows
  )
  select
    c.item_type,
    c.id,
    c.offer_id,
    c.redemption_id,
    c.title,
    c.description,
    c.provider_name,
    c.cost_points,
    c.points_spent,
    c.status,
    c.is_active,
    c.eligible_plan_codes,
    c.available_from,
    c.available_until,
    c.voucher_expires_at,
    c.available_codes,
    c.issued_codes,
    c.retired_codes,
    c.user_id,
    c.user_label,
    c.masked_code,
    c.created_at,
    c.cancelled_at
  from combined c
  order by c.sort_at desc, c.id desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.admin_upsert_reward_offer(
  p_offer_id uuid,
  p_title text,
  p_description text,
  p_provider_name text,
  p_cost_points integer,
  p_eligible_plan_codes text[],
  p_available_from timestamptz,
  p_available_until timestamptz,
  p_voucher_expires_at timestamptz,
  p_is_active boolean,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_offer public.wellness_reward_offers%rowtype;
  v_new_id uuid := coalesce(p_offer_id, gen_random_uuid());
  v_existing_audit public.admin_audit_events%rowtype;
begin
  perform public.admin_assert_permission('wellness_rewards.write');

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'admin_reason_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:admin:upsert:' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing_audit
  from public.admin_audit_events aae
  where aae.action = 'admin_upsert_reward_offer'
    and aae.idempotency_key = btrim(p_idempotency_key);

  if v_existing_audit.id is not null then
    if p_offer_id is not null
       and v_existing_audit.target_id <> p_offer_id::text then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    select * into v_offer
    from public.wellness_reward_offers
    where id::text = v_existing_audit.target_id;
    return jsonb_build_object(
      'success', true,
      'message', 'Yêu cầu đã được xử lý trước đó.',
      'offer_id', v_offer.id,
      'accepted_count', 0,
      'duplicate_count', 0,
      'rejected_count', 0,
      'idempotent_replay', true
    );
  end if;

  if not public.reward_text_is_vietnamese(p_title)
     or not public.reward_text_is_vietnamese(p_description) then
    raise exception using errcode = 'P0001', message = 'invalid_vietnamese_copy';
  end if;
  if nullif(btrim(coalesce(p_provider_name, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'provider_name_required';
  end if;
  if p_cost_points is null or p_cost_points <= 0 then
    raise exception using errcode = 'P0001', message = 'reward_cost_invalid';
  end if;
  if p_eligible_plan_codes is null
     or cardinality(p_eligible_plan_codes) = 0
     or not (p_eligible_plan_codes <@ array['free', 'plus', 'family_plus']::text[]) then
    raise exception using errcode = 'P0001', message = 'eligible_plans_invalid';
  end if;
  if p_available_from is not null and p_available_until is not null
     and p_available_until <= p_available_from then
    raise exception using errcode = 'P0001', message = 'offer_window_invalid';
  end if;
  if p_voucher_expires_at is not null and p_voucher_expires_at <= now() then
    raise exception using errcode = 'P0001', message = 'voucher_expiry_invalid';
  end if;

  if p_offer_id is not null and not exists (
    select 1 from public.wellness_reward_offers where id = p_offer_id
  ) then
    raise exception using errcode = 'P0001', message = 'offer_not_found';
  end if;

  insert into public.wellness_reward_offers (
    id,
    offer_code,
    title,
    description,
    provider_name,
    cost_points,
    eligible_plan_codes,
    available_from,
    available_until,
    voucher_expires_at,
    is_active,
    created_by,
    updated_by
  )
  values (
    v_new_id,
    'reward_' || replace(v_new_id::text, '-', ''),
    btrim(p_title),
    btrim(p_description),
    btrim(p_provider_name),
    p_cost_points,
    array(select distinct lower(btrim(x)) from unnest(p_eligible_plan_codes) x order by 1),
    p_available_from,
    p_available_until,
    p_voucher_expires_at,
    coalesce(p_is_active, false),
    auth.uid(),
    auth.uid()
  )
  on conflict (id) do update
  set
    title = excluded.title,
    description = excluded.description,
    provider_name = excluded.provider_name,
    cost_points = excluded.cost_points,
    eligible_plan_codes = excluded.eligible_plan_codes,
    available_from = excluded.available_from,
    available_until = excluded.available_until,
    voucher_expires_at = excluded.voucher_expires_at,
    is_active = excluded.is_active,
    updated_by = auth.uid(),
    updated_at = now()
  returning * into v_offer;

  perform public.admin_write_audit(
    'admin_upsert_reward_offer',
    'wellness_reward_offer',
    v_offer.id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'is_active', v_offer.is_active,
      'cost_points', v_offer.cost_points,
      'eligible_plan_codes', v_offer.eligible_plan_codes,
      'voucher_expires_at', v_offer.voucher_expires_at
    )
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Đã lưu ưu đãi.',
    'offer_id', v_offer.id,
    'accepted_count', 1,
    'duplicate_count', 0,
    'rejected_count', 0,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.admin_import_reward_codes(
  p_offer_id uuid,
  p_codes text[],
  p_voucher_expires_at timestamptz,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_offer public.wellness_reward_offers%rowtype;
  v_existing_audit public.admin_audit_events%rowtype;
  v_expiry timestamptz;
  v_total integer;
  v_valid integer;
  v_accepted integer := 0;
  v_duplicate integer;
  v_rejected integer;
begin
  perform public.admin_assert_permission('wellness_rewards.write');

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'admin_reason_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:admin:import:' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing_audit
  from public.admin_audit_events aae
  where aae.action = 'admin_import_reward_codes'
    and aae.idempotency_key = btrim(p_idempotency_key);

  if v_existing_audit.id is not null then
    if v_existing_audit.target_id <> p_offer_id::text then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    return jsonb_build_object(
      'success', true,
      'message', 'Yêu cầu nhập mã đã được xử lý trước đó.',
      'offer_id', v_existing_audit.target_id,
      'accepted_count', coalesce((v_existing_audit.metadata ->> 'accepted_count')::integer, 0),
      'duplicate_count', coalesce((v_existing_audit.metadata ->> 'duplicate_count')::integer, 0),
      'rejected_count', coalesce((v_existing_audit.metadata ->> 'rejected_count')::integer, 0),
      'idempotent_replay', true
    );
  end if;

  select * into v_offer
  from public.wellness_reward_offers
  where id = p_offer_id
  for update;

  if v_offer.id is null then
    raise exception using errcode = 'P0001', message = 'offer_not_found';
  end if;

  v_total := coalesce(cardinality(p_codes), 0);
  if v_total < 1 or v_total > 1000 then
    raise exception using errcode = 'P0001', message = 'voucher_codes_count_invalid';
  end if;

  v_expiry := coalesce(p_voucher_expires_at, v_offer.voucher_expires_at);
  if v_expiry is null or v_expiry <= now() then
    raise exception using errcode = 'P0001', message = 'voucher_expiry_required';
  end if;

  select count(*)::integer
  into v_valid
  from unnest(p_codes) raw_code
  where btrim(coalesce(raw_code, '')) ~ '^[A-Za-z0-9][A-Za-z0-9_-]{3,127}$';

  v_rejected := v_total - v_valid;

  insert into public.wellness_reward_codes (
    offer_id,
    code_value,
    code_hash,
    voucher_expires_at,
    imported_by,
    import_batch_key
  )
  select
    v_offer.id,
    normalized.code_value,
    encode(digest(upper(normalized.code_value), 'sha256'), 'hex'),
    v_expiry,
    auth.uid(),
    btrim(p_idempotency_key)
  from (
    select distinct on (upper(btrim(raw_code))) btrim(raw_code) as code_value
    from unnest(p_codes) raw_code
    where btrim(coalesce(raw_code, '')) ~ '^[A-Za-z0-9][A-Za-z0-9_-]{3,127}$'
    order by upper(btrim(raw_code)), btrim(raw_code)
  ) normalized
  on conflict (code_hash) do nothing;

  get diagnostics v_accepted = row_count;
  v_duplicate := v_valid - v_accepted;

  perform public.admin_write_audit(
    'admin_import_reward_codes',
    'wellness_reward_offer',
    v_offer.id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'accepted_count', v_accepted,
      'duplicate_count', v_duplicate,
      'rejected_count', v_rejected,
      'voucher_expires_at', v_expiry,
      'raw_codes_logged', false
    )
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Đã xử lý kho mã ưu đãi.',
    'offer_id', v_offer.id,
    'accepted_count', v_accepted,
    'duplicate_count', v_duplicate,
    'rejected_count', v_rejected,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.admin_cancel_reward_redemption(
  p_redemption_id uuid,
  p_reason text,
  p_external_revocation_confirmed boolean,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_redemption public.wellness_reward_redemptions%rowtype;
  v_code public.wellness_reward_codes%rowtype;
  v_existing_audit public.admin_audit_events%rowtype;
  v_program record;
  v_subject_id uuid;
  v_ledger_id uuid := gen_random_uuid();
  v_allocation public.wellness_point_allocations%rowtype;
  v_allocation_id uuid := gen_random_uuid();
  v_wallet public.wellness_reward_wallets%rowtype;
begin
  perform public.admin_assert_permission('wellness_rewards.write');

  if p_redemption_id is null then
    raise exception using errcode = 'P0001', message = 'redemption_required';
  end if;
  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'admin_reason_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if not coalesce(p_external_revocation_confirmed, false) then
    raise exception using errcode = 'P0001', message = 'external_revocation_confirmation_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:admin:cancel:' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing_audit
  from public.admin_audit_events aae
  where aae.action = 'admin_cancel_reward_redemption'
    and aae.idempotency_key = btrim(p_idempotency_key);

  if v_existing_audit.id is not null then
    if v_existing_audit.target_id <> p_redemption_id::text then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    return jsonb_build_object(
      'success', true,
      'message', 'Giao dịch đã được hủy trước đó.',
      'redemption_id', p_redemption_id,
      'accepted_count', 0,
      'duplicate_count', 0,
      'rejected_count', 0,
      'idempotent_replay', true
    );
  end if;

  select * into v_redemption
  from public.wellness_reward_redemptions wrr
  where wrr.id = p_redemption_id
  for update;

  if v_redemption.id is null then
    raise exception using errcode = 'P0001', message = 'redemption_not_found';
  end if;

  if v_redemption.status = 'cancelled' then
    perform public.admin_write_audit(
      'admin_cancel_reward_redemption',
      'wellness_reward_redemption',
      v_redemption.id::text,
      p_reason,
      p_idempotency_key,
      jsonb_build_object(
        'already_cancelled', true,
        'refund_created', false,
        'external_revocation_confirmed', true
      )
    );
    return jsonb_build_object(
      'success', true,
      'message', 'Giao dịch đã ở trạng thái hủy.',
      'redemption_id', v_redemption.id,
      'accepted_count', 0,
      'duplicate_count', 0,
      'rejected_count', 0,
      'idempotent_replay', true
    );
  end if;

  select * into v_code
  from public.wellness_reward_codes wrc
  where wrc.id = v_redemption.reward_code_id
  for update;

  select hs.id into v_subject_id
  from public.health_subjects hs
  where hs.owner_user_id = v_redemption.user_id
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1;

  if v_subject_id is null then
    raise exception using errcode = 'P0001', message = 'health_subject_required';
  end if;

  select * into v_program
  from public.current_wellness_reward_program();

  perform public.refresh_wellness_reward_wallet(v_redemption.user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_redemption.user_id
  for update;

  insert into public.wellness_point_ledgers (
    id,
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    available_at,
    expires_at,
    program_config_id,
    redemption_id,
    metadata
  )
  values (
    v_ledger_id,
    v_redemption.user_id,
    v_subject_id,
    'reward_redemption_refund',
    v_redemption.id,
    (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    v_redemption.points_spent,
    v_program.contract_version,
    'reward_refund:' || v_redemption.id::text,
    'refund',
    'refunded',
    'Hoàn điểm ưu đãi: ' || v_redemption.offer_title_snapshot,
    true,
    now(),
    now() + make_interval(days => v_program.expiry_days),
    v_program.program_config_id,
    v_redemption.id,
    jsonb_build_object(
      'cancelled_by', auth.uid(),
      'external_revocation_confirmed', true
    )
  );

  insert into public.wellness_point_allocations (
    id,
    user_id,
    subject_id,
    ledger_id,
    source_type,
    source_id,
    original_points,
    remaining_points,
    status,
    available_at,
    expires_at,
    program_config_id
  )
  values (
    v_allocation_id,
    v_redemption.user_id,
    v_subject_id,
    v_ledger_id,
    'admin_refund',
    v_redemption.id,
    v_redemption.points_spent,
    v_redemption.points_spent,
    'available',
    now(),
    now() + make_interval(days => v_program.expiry_days),
    v_program.program_config_id
  )
  returning * into v_allocation;

  update public.wellness_reward_wallets
  set
    available_points = available_points + v_redemption.points_spent,
    lifetime_refunded_points = lifetime_refunded_points + v_redemption.points_spent,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_redemption.user_id
  returning * into v_wallet;

  update public.wellness_reward_codes
  set
    status = 'retired',
    retired_at = now()
  where id = v_code.id;

  update public.wellness_reward_redemptions
  set
    status = 'cancelled',
    cancelled_at = now(),
    cancelled_by = auth.uid(),
    cancellation_reason = btrim(p_reason),
    refund_allocation_id = v_allocation.id,
    updated_at = now()
  where id = v_redemption.id;

  perform public.admin_write_audit(
    'admin_cancel_reward_redemption',
    'wellness_reward_redemption',
    v_redemption.id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'external_revocation_confirmed', true,
      'code_restocked', false,
      'refund_points', v_redemption.points_spent,
      'refund_allocation_id', v_allocation.id,
      'refund_expires_at', v_allocation.expires_at
    )
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Đã hủy giao dịch và hoàn Điểm chăm sóc.',
    'redemption_id', v_redemption.id,
    'refund_points', v_redemption.points_spent,
    'available_points', v_wallet.available_points,
    'accepted_count', 1,
    'duplicate_count', 0,
    'rejected_count', 0,
    'idempotent_replay', false
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 16F. Mobile snapshot hardening
-- ---------------------------------------------------------------------------
-- The wellness ledger is intentionally absent from both the replacement list
-- and the client column whitelist. The app may pull the owner-scoped ledger as
-- a read-only projection, but snapshot push can neither insert nor delete it.

create or replace function public.sync_my_mobile_snapshot(p_snapshot jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_subject_id uuid;
  v_user jsonb := coalesce(p_snapshot -> 'user', '{}'::jsonb);
  v_tables jsonb := coalesce(p_snapshot -> 'tables', '{}'::jsonb);
  v_table text;
  v_row jsonb;
  v_allowed_columns text[];
  v_rows integer := 0;
  v_collection_tables text[] := array[
    'health_goals',
    'health_conditions',
    'food_allergies',
    'medical_treatments',
    'survey_answers',
    'meal_plans',
    'daily_health_tasks',
    'lifestyle_schedule_items',
    'notifications',
    'health_tracking_logs',
    'health_score_ledgers',
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations'
  ];
  v_singleton_tables text[] := array['health_profiles', 'lifestyle_habits'];
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if coalesce(jsonb_typeof(p_snapshot), '') <> 'object'
     or coalesce(jsonb_typeof(v_tables), '') <> 'object' then
    raise exception 'INVALID_SNAPSHOT' using errcode = '22023';
  end if;

  select id into v_subject_id
  from public.health_subjects
  where owner_user_id = v_user_id
    and subject_type = 'self'
    and is_active = true
  limit 1;

  if v_subject_id is null then
    insert into public.health_subjects (
      owner_user_id, linked_user_id, subject_type, display_name, relationship
    )
    values (v_user_id, v_user_id, 'self', 'Bạn', 'self')
    on conflict (owner_user_id) where subject_type = 'self'
    do update set linked_user_id = excluded.linked_user_id, is_active = true
    returning id into v_subject_id;
  end if;

  update public.users
  set
    phone = coalesce(nullif(v_user ->> 'phone', ''), phone),
    full_name = coalesce(nullif(v_user ->> 'full_name', ''), full_name),
    avatar_url = coalesce(nullif(v_user ->> 'avatar_url', ''), avatar_url),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    onboarding_status = case
      when v_user ->> 'onboarding_status' = 'completed' then 'completed'::public.nb_onboarding_status
      when v_user ->> 'onboarding_status' = 'in_progress' then 'in_progress'::public.nb_onboarding_status
      else onboarding_status
    end,
    onboarding_completed_at = case
      when v_user ->> 'onboarding_status' = 'completed'
        then coalesce(nullif(v_user ->> 'onboarding_completed_at', '')::timestamptz, now())
      else onboarding_completed_at
    end,
    updated_at = now()
  where id = v_user_id;

  update public.health_subjects
  set
    display_name = coalesce(nullif(v_user ->> 'full_name', ''), display_name),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    updated_at = now()
  where id = v_subject_id;

  foreach v_table in array v_singleton_tables loop
    execute format(
      'delete from public.%I where user_id = $1 and subject_id = $2',
      v_table
    ) using v_user_id, v_subject_id;

    if v_table = 'health_profiles' then
      v_allowed_columns := array[
        'id', 'occupation', 'height_cm', 'weight_kg', 'bmi',
        'blood_pressure', 'blood_sugar'
      ];
    elsif v_table = 'lifestyle_habits' then
      v_allowed_columns := array[
        'id', 'skip_breakfast', 'eat_late', 'eat_sweet', 'eat_oily',
        'low_vegetable', 'low_water', 'fast_food', 'alcohol', 'coffee_high',
        'sleep_quality', 'activity_level', 'water_per_day'
      ];
    else
      raise exception 'UNSUPPORTED_SNAPSHOT_TABLE: %', v_table
        using errcode = '22023';
    end if;

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      perform public.insert_mobile_snapshot_row(
        v_table,
        v_user_id,
        v_subject_id,
        v_row,
        v_allowed_columns,
        true
      );
      v_rows := v_rows + 1;
    end loop;
  end loop;

  foreach v_table in array v_collection_tables loop
    if v_table = 'lifestyle_schedule_items' then
      -- Preserve every row already governed by server-issued eligibility.
      -- A stale device may omit the row entirely, so overlaying booleans after
      -- a destructive replace would otherwise be insufficient.
      select coalesce(jsonb_agg(to_jsonb(lsi) order by lsi.id), '[]'::jsonb)
      into v_authoritative_schedule_rows
      from public.lifestyle_schedule_items lsi
      where lsi.user_id = v_user_id
        and lsi.subject_id = v_subject_id
        and exists (
          select 1
          from public.schedule_reward_eligibilities sre
          where sre.user_id = v_user_id
            and sre.schedule_item_id = lsi.id
        );

      delete from public.lifestyle_schedule_items
      where user_id = v_user_id and subject_id = v_subject_id;
    elsif v_table = 'notifications' then
      execute 'delete from public.notifications where user_id = $1'
        using v_user_id;
    else
      execute format(
        'delete from public.%I where user_id = $1 and subject_id = $2',
        v_table
      ) using v_user_id, v_subject_id;
    end if;

    if v_table = 'health_goals' then
      v_allowed_columns := array['id', 'goal_code', 'goal_name', 'is_active'];
    elsif v_table = 'health_conditions' then
      v_allowed_columns := array[
        'id', 'condition_code', 'condition_name', 'severity_level'
      ];
    elsif v_table = 'food_allergies' then
      v_allowed_columns := array['id', 'allergy_name', 'note'];
    elsif v_table = 'medical_treatments' then
      v_allowed_columns := array[
        'id', 'treatment_name', 'medication_name', 'note'
      ];
    elsif v_table = 'survey_answers' then
      v_allowed_columns := array['id', 'question_code', 'answer_value'];
    elsif v_table = 'meal_plans' then
      v_allowed_columns := array[
        'id', 'plan_date', 'meal_type', 'meal_name', 'description', 'calories',
        'protein', 'carbs', 'fat', 'fiber', 'water_ml', 'meal_order',
        'start_time', 'end_time', 'cooking_instructions', 'is_completed',
        'ai_generated'
      ];
    elsif v_table = 'daily_health_tasks' then
      v_allowed_columns := array[
        'id', 'task_date', 'task_code', 'category', 'title', 'description',
        'target_value', 'current_value', 'unit', 'is_completed', 'sort_order',
        'source', 'encouragement'
      ];
    elsif v_table = 'lifestyle_schedule_items' then
      v_allowed_columns := array[
        'id', 'schedule_date', 'start_time', 'end_time', 'title', 'description',
        'category', 'source_type', 'source_id', 'target_value', 'current_value',
        'unit', 'is_completed', 'sort_order', 'ai_generated', 'encouragement'
      ];
    elsif v_table = 'notifications' then
      v_allowed_columns := array[
        'id', 'title', 'body', 'type', 'is_read', 'source_type', 'source_id',
        'scheduled_at', 'notification_id', 'action_status', 'responded_at', 'payload'
      ];
    elsif v_table = 'health_tracking_logs' then
      v_allowed_columns := array[
        'id', 'weight_kg', 'calories', 'water_ml', 'sleep_hours', 'stress_level',
        'steps_count', 'heart_rate_bpm', 'oxygen_saturation', 'daily_score',
        'mood', 'log_date'
      ];
    elsif v_table = 'health_score_ledgers' then
      v_allowed_columns := array[
        'id', 'period_start', 'period_end', 'score', 'formula_version',
        'breakdown', 'idempotency_key', 'calculated_at'
      ];
    elsif v_table = 'nutrition_logs' then
      v_allowed_columns := array[
        'id', 'food_name', 'calories', 'protein', 'carbs', 'fat', 'meal_type',
        'eaten_at'
      ];
    elsif v_table = 'ai_insights' then
      v_allowed_columns := array['id', 'insight_type', 'title', 'content', 'risk_level'];
    elsif v_table = 'ai_recommendations' then
      v_allowed_columns := array[
        'id', 'recommendation_type', 'title', 'description', 'action_text', 'is_read'
      ];
    else
      raise exception 'UNSUPPORTED_SNAPSHOT_TABLE: %', v_table
        using errcode = '22023';
    end if;

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      perform public.insert_mobile_snapshot_row(
        v_table,
        v_user_id,
        v_subject_id,
        v_row,
        v_allowed_columns,
        true
      );
      v_rows := v_rows + 1;
    end loop;

    if v_table = 'lifestyle_schedule_items' then
      -- Restore eligible rows omitted by this snapshot, then force immutable
      -- schedule snapshots and completion state from eligibility/proof. This
      -- makes a stale device push unable to undo a finalized completion or
      -- mutate a pinned Guest/Member manifest.
      for v_authoritative_row in
        select value
        from jsonb_array_elements(v_authoritative_schedule_rows)
      loop
        if not exists (
          select 1
          from public.lifestyle_schedule_items lsi
          where lsi.id = (v_authoritative_row ->> 'id')::uuid
            and lsi.user_id = v_user_id
        ) then
          perform public.insert_mobile_snapshot_row(
            'lifestyle_schedule_items',
            v_user_id,
            v_subject_id,
            v_authoritative_row,
            v_allowed_columns,
            true
          );
        end if;
      end loop;

      update public.lifestyle_schedule_items lsi
      set
        schedule_date = sre.schedule_date,
        start_time = sre.start_time,
        title = sre.title_snapshot,
        category = coalesce(sre.category_snapshot, lsi.category),
        source_type = sre.source_type_snapshot,
        source_id = sre.source_id_snapshot,
        ai_generated = true,
        is_completed = (
          sre.status = 'completed'
          and exists (
            select 1
            from public.schedule_completion_proofs scp
            where scp.eligibility_id = sre.id
              and scp.user_id = v_user_id
              and scp.status = 'active'
          )
        ),
        current_value = case
          when sre.status = 'completed'
           and exists (
             select 1
             from public.schedule_completion_proofs scp
             where scp.eligibility_id = sre.id
               and scp.user_id = v_user_id
               and scp.status = 'active'
           )
            then lsi.target_value
          else 0
        end,
        updated_at = now()
      from public.schedule_reward_eligibilities sre
      where lsi.user_id = v_user_id
        and lsi.subject_id = v_subject_id
        and sre.user_id = v_user_id
        and sre.schedule_item_id = lsi.id;
    end if;
  end loop;

  delete from public.personal_schedule_ai_requests where user_id = v_user_id;
  v_allowed_columns := array[
    'request_id', 'actor_mode', 'status', 'start_date', 'days', 'meal_count',
    'exercise_count', 'schedule_item_count', 'error_code', 'completed_at'
  ];

  for v_row in
    select value from jsonb_array_elements(
      coalesce(v_tables -> 'personal_schedule_ai_requests', '[]'::jsonb)
    )
  loop
    perform public.insert_mobile_snapshot_row(
      'personal_schedule_ai_requests',
      v_user_id,
      null,
      v_row,
      v_allowed_columns,
      false
    );
    v_rows := v_rows + 1;
  end loop;

  return jsonb_build_object(
    'user_id', v_user_id,
    'subject_id', v_subject_id,
    'synced_rows', v_rows,
    'synced_at', now(),
    'server_owned_tables', jsonb_build_array('wellness_point_ledgers')
  );
end;
$$;

revoke all on function public.wellness_rewards_feature_enabled()
from public, anon, authenticated;

revoke all on function public.register_my_schedule_reward_eligibilities(text, jsonb, text)
from public, anon;
revoke all on function public.begin_my_schedule_completion(uuid, text)
from public, anon;
revoke all on function public.finalize_my_schedule_completion(uuid, text, text)
from public, anon;
revoke all on function public.undo_my_schedule_completion(uuid, text)
from public, anon;
revoke all on function public.get_my_wellness_reward_summary()
from public, anon;
revoke all on function public.list_my_wellness_point_history(integer)
from public, anon;
revoke all on function public.list_my_reward_offers(integer)
from public, anon;
revoke all on function public.redeem_my_reward_offer(uuid, text)
from public, anon;
revoke all on function public.list_my_reward_redemptions(integer)
from public, anon;
revoke all on function public.get_my_reward_code(uuid)
from public, anon;
revoke all on function public.admin_list_wellness_rewards(text, integer)
from public, anon;
revoke all on function public.admin_upsert_reward_offer(
  uuid, text, text, text, integer, text[], timestamptz, timestamptz,
  timestamptz, boolean, text, text
)
from public, anon;
revoke all on function public.admin_import_reward_codes(
  uuid, text[], timestamptz, text, text
)
from public, anon;
revoke all on function public.admin_cancel_reward_redemption(
  uuid, text, boolean, text
)
from public, anon;

grant execute on function public.register_my_schedule_reward_eligibilities(text, jsonb, text)
to authenticated;
grant execute on function public.begin_my_schedule_completion(uuid, text)
to authenticated;
grant execute on function public.finalize_my_schedule_completion(uuid, text, text)
to authenticated;
grant execute on function public.undo_my_schedule_completion(uuid, text)
to authenticated;
grant execute on function public.get_my_wellness_reward_summary()
to authenticated;
grant execute on function public.list_my_wellness_point_history(integer)
to authenticated;
grant execute on function public.list_my_reward_offers(integer)
to authenticated;
grant execute on function public.redeem_my_reward_offer(uuid, text)
to authenticated;
grant execute on function public.list_my_reward_redemptions(integer)
to authenticated;
grant execute on function public.get_my_reward_code(uuid)
to authenticated;
grant execute on function public.admin_list_wellness_rewards(text, integer)
to authenticated;
grant execute on function public.admin_upsert_reward_offer(
  uuid, text, text, text, integer, text[], timestamptz, timestamptz,
  timestamptz, boolean, text, text
)
to authenticated;
grant execute on function public.admin_import_reward_codes(
  uuid, text[], timestamptz, text, text
)
to authenticated;
grant execute on function public.admin_cancel_reward_redemption(
  uuid, text, boolean, text
)
to authenticated;

commit;
-- END 16-wellness-rewards.sql
