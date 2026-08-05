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
  transfer_reference text,
  transfer_memo text,
  amount_cents integer not null check (amount_cents >= 0),
  list_price_cents integer check (list_price_cents is null or list_price_cents >= 0),
  commission_base_cents integer check (commission_base_cents is null or commission_base_cents >= 0),
  currency text not null default 'VND',
  status text not null
    check (
      status in (
        'awaiting_transfer',
        'pending_review',
        'pending',
        'succeeded',
        'refunded',
        'chargeback',
        'failed'
      )
    ),
  paid_at timestamptz,
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  review_reason text,
  idempotency_key text,
  raw_event_hash text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint payment_events_transfer_reference_format_check
    check (
      transfer_reference is null
      or transfer_reference ~ '^NB[0-9A-F]{12}$'
    ),
  constraint payment_events_transfer_memo_format_check
    check (
      transfer_memo is null
      or transfer_memo ~ '^[A-Z0-9 ]{1,25}$'
    ),
  unique (provider, provider_event_id)
);

create index if not exists idx_payment_events_payer_paid
  on public.payment_events (payer_user_id, paid_at desc);
create index if not exists idx_payment_events_status_created
  on public.payment_events (status, created_at desc);
create index if not exists idx_payment_events_status_paid
  on public.payment_events (status, paid_at desc);
create unique index if not exists uq_payment_events_transfer_reference
  on public.payment_events (transfer_reference)
  where transfer_reference is not null;
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

drop function if exists public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
);

create or replace function public.create_membership_payment_request(
  p_plan_code public.nb_membership_plan,
  p_billing_cycle text,
  p_idempotency_key text,
  p_payer_full_name text
)
returns table (
  payment_event_id uuid,
  plan_code text,
  billing_cycle text,
  status text,
  amount_cents integer,
  currency text,
  transfer_reference text,
  transfer_memo text,
  bank_code text,
  bank_name text,
  bank_bin text,
  bank_account_number text,
  bank_account_name text,
  bank_account_display_name text,
  transfer_confirmed_at timestamptz,
  review_reason text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_price_config jsonb;
  v_bank_config jsonb;
  v_billing_cycle text;
  v_amount_cents integer;
  v_currency text;
  v_provider text := 'manual_membership_request';
  v_provider_event_id text;
  v_payer_full_name text;
  v_payer_name_ascii text;
  v_bank_code text;
  v_bank_name text;
  v_bank_bin text;
  v_bank_account_number text;
  v_bank_account_name text;
  v_bank_account_display_name text;
  v_transfer_reference text;
  v_transfer_memo text;
  v_attempt integer := 0;
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if p_plan_code not in ('plus', 'family_plus') then
    raise exception 'INVALID_MEMBERSHIP_PLAN' using errcode = '22023';
  end if;

  v_billing_cycle := lower(btrim(coalesce(p_billing_cycle, '')));
  if v_billing_cycle not in ('monthly', 'yearly') then
    raise exception 'INVALID_BILLING_CYCLE' using errcode = '22023';
  end if;

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED' using errcode = '22023';
  end if;

  v_payer_full_name := btrim(coalesce(p_payer_full_name, ''));
  if v_payer_full_name = '' then
    raise exception 'PAYER_FULL_NAME_REQUIRED' using errcode = '22023';
  end if;

  v_payer_name_ascii := upper(v_payer_full_name);
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴàáạảãâầấậẩẫăằắặẳẵ]',
    'A',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÈÉẸẺẼÊỀẾỆỂỄèéẹẻẽêềếệểễ]',
    'E',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÌÍỊỈĨìíịỉĩ]',
    'I',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠòóọỏõôồốộổỗơờớợởỡ]',
    'O',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÙÚỤỦŨƯỪỨỰỬỮùúụủũưừứựửữ]',
    'U',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ỲÝỴỶỸỳýỵỷỹ]',
    'Y',
    'g'
  );
  v_payer_name_ascii := replace(
    replace(v_payer_name_ascii, 'Đ', 'D'),
    'đ',
    'D'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[^A-Z0-9 ]+',
    ' ',
    'g'
  );
  v_payer_name_ascii := btrim(
    regexp_replace(v_payer_name_ascii, '[[:space:]]+', ' ', 'g')
  );

  if v_payer_name_ascii = '' then
    raise exception 'PAYER_FULL_NAME_INVALID' using errcode = '22023';
  end if;

  select scv.config_value
  into v_price_config
  from public.system_config_versions scv
  where scv.config_key = 'membership_payment_prices'
    and scv.status = 'active'
  order by scv.created_at desc
  limit 1;

  v_amount_cents := nullif(
    v_price_config #>> array['prices', p_plan_code::text, v_billing_cycle],
    ''
  )::integer;
  v_currency := upper(coalesce(nullif(v_price_config ->> 'currency', ''), ''));

  if v_amount_cents is null or v_amount_cents <= 0 or v_currency <> 'VND' then
    raise exception 'MEMBERSHIP_PAYMENT_PRICE_NOT_CONFIGURED'
      using errcode = '22023';
  end if;

  select scv.config_value
  into v_bank_config
  from public.system_config_versions scv
  where scv.config_key = 'membership_payment_bank'
    and scv.status = 'active'
  order by scv.created_at desc
  limit 1;

  v_bank_code := upper(btrim(coalesce(v_bank_config ->> 'bank_code', '')));
  v_bank_name := btrim(coalesce(v_bank_config ->> 'bank_name', ''));
  v_bank_bin := btrim(coalesce(v_bank_config ->> 'bank_bin', ''));
  v_bank_account_number := btrim(
    coalesce(v_bank_config ->> 'bank_account_number', '')
  );
  v_bank_account_name := btrim(
    coalesce(v_bank_config ->> 'bank_account_name', '')
  );
  v_bank_account_display_name := btrim(
    coalesce(v_bank_config ->> 'bank_account_display_name', '')
  );

  if v_bank_code = ''
    or v_bank_name = ''
    or v_bank_bin !~ '^[0-9]{6}$'
    or v_bank_account_number !~ '^[0-9]{4,32}$'
    or v_bank_account_name = ''
    or v_bank_account_display_name = '' then
    raise exception 'MEMBERSHIP_PAYMENT_BANK_NOT_CONFIGURED'
      using errcode = '22023';
  end if;

  v_provider_event_id := concat(v_user_id::text, ':', btrim(p_idempotency_key));

  select *
  into v_payment
  from public.payment_events
  where provider = v_provider
    and provider_event_id = v_provider_event_id
  for update;

  if found then
    update public.payment_events
    set metadata = metadata || jsonb_build_object(
      'idempotent_replay',
      true
    )
    where id = v_payment.id
    returning * into v_payment;
  else
    loop
      v_attempt := v_attempt + 1;
      v_transfer_reference := concat(
        'NB',
        upper(encode(gen_random_bytes(6), 'hex'))
      );
      v_transfer_memo := concat(
        v_transfer_reference,
        ' ',
        left(v_payer_name_ascii, 25 - length(v_transfer_reference) - 1)
      );

      begin
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
          transfer_reference,
          transfer_memo,
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
          'awaiting_transfer',
          v_transfer_reference,
          v_transfer_memo,
          btrim(p_idempotency_key),
          jsonb_build_object(
            'billing_cycle',
            v_billing_cycle,
            'payer_full_name',
            v_payer_full_name,
            'manual_approval_required',
            true,
            'grants_access_before_approval',
            false,
            'transfer_reference',
            v_transfer_reference,
            'transfer_memo',
            v_transfer_memo,
            'bank',
            jsonb_build_object(
              'bank_code', v_bank_code,
              'bank_name', v_bank_name,
              'bank_bin', v_bank_bin,
              'bank_account_number', v_bank_account_number,
              'bank_account_name', v_bank_account_name,
              'bank_account_display_name', v_bank_account_display_name
            )
          )
        )
        returning * into v_payment;
        exit;
      exception
        when unique_violation then
          select *
          into v_payment
          from public.payment_events
          where provider = v_provider
            and provider_event_id = v_provider_event_id
          for update;

          if found then
            update public.payment_events
            set metadata = metadata || jsonb_build_object(
              'idempotent_replay',
              true
            )
            where id = v_payment.id
            returning * into v_payment;
            exit;
          end if;

          if v_attempt >= 5 then
            raise;
          end if;
      end;
    end loop;
  end if;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    coalesce(v_payment.metadata ->> 'billing_cycle', v_billing_cycle),
    v_payment.status,
    v_payment.amount_cents,
    v_payment.currency,
    v_payment.transfer_reference,
    v_payment.transfer_memo,
    nullif(v_payment.metadata #>> '{bank,bank_code}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_name}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_bin}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_number}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_name}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_display_name}', ''),
    nullif(v_payment.metadata ->> 'transfer_confirmed_at', '')::timestamptz,
    nullif(v_payment.review_reason, ''),
    v_payment.created_at;
end;
$$;

create or replace function public.confirm_my_membership_payment_transfer(
  p_payment_event_id uuid
)
returns table (
  payment_event_id uuid,
  plan_code text,
  billing_cycle text,
  status text,
  amount_cents integer,
  currency text,
  transfer_reference text,
  transfer_memo text,
  bank_code text,
  bank_name text,
  bank_bin text,
  bank_account_number text,
  bank_account_name text,
  bank_account_display_name text,
  transfer_confirmed_at timestamptz,
  review_reason text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_provider text := 'manual_membership_request';
  v_confirmed_at timestamptz;
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  select *
  into v_payment
  from public.payment_events
  where id = p_payment_event_id
    and payer_user_id = v_user_id
    and provider = v_provider
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if v_payment.status = 'awaiting_transfer' then
    if v_payment.transfer_reference is null or v_payment.transfer_memo is null then
      raise exception 'PAYMENT_TRANSFER_DETAILS_MISSING' using errcode = '22023';
    end if;

    v_confirmed_at := now();
    update public.payment_events
    set
      status = 'pending_review',
      metadata = metadata || jsonb_build_object(
        'transfer_confirmed_at',
        v_confirmed_at,
        'transfer_confirmation',
        jsonb_build_object(
          'confirmed_at', v_confirmed_at,
          'confirmed_by_user_id', v_user_id,
          'transfer_reference', transfer_reference,
          'transfer_memo', transfer_memo,
          'bank', metadata -> 'bank'
        )
      )
    where id = v_payment.id
    returning * into v_payment;
  elsif v_payment.status <> 'pending_review' then
    raise exception 'PAYMENT_TRANSFER_NOT_AWAITING_CONFIRMATION'
      using errcode = '22023';
  end if;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    v_payment.metadata ->> 'billing_cycle',
    v_payment.status,
    v_payment.amount_cents,
    v_payment.currency,
    v_payment.transfer_reference,
    v_payment.transfer_memo,
    nullif(v_payment.metadata #>> '{bank,bank_code}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_name}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_bin}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_number}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_name}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_display_name}', ''),
    nullif(v_payment.metadata ->> 'transfer_confirmed_at', '')::timestamptz,
    nullif(v_payment.review_reason, ''),
    v_payment.created_at;
end;
$$;

create or replace function public.get_my_membership_payment_request()
returns table (
  payment_event_id uuid,
  plan_code text,
  billing_cycle text,
  status text,
  amount_cents integer,
  currency text,
  transfer_reference text,
  transfer_memo text,
  bank_code text,
  bank_name text,
  bank_bin text,
  bank_account_number text,
  bank_account_name text,
  bank_account_display_name text,
  transfer_confirmed_at timestamptz,
  review_reason text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_provider text := 'manual_membership_request';
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  select *
  into v_payment
  from public.payment_events pe
  where pe.payer_user_id = v_user_id
    and pe.provider = v_provider
  order by
    case
      when pe.status in ('awaiting_transfer', 'pending_review', 'pending') then 0
      else 1
    end,
    pe.created_at desc
  limit 1;

  if not found then
    return;
  end if;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    v_payment.metadata ->> 'billing_cycle',
    v_payment.status,
    v_payment.amount_cents,
    v_payment.currency,
    v_payment.transfer_reference,
    v_payment.transfer_memo,
    nullif(v_payment.metadata #>> '{bank,bank_code}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_name}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_bin}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_number}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_name}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_display_name}', ''),
    nullif(v_payment.metadata ->> 'transfer_confirmed_at', '')::timestamptz,
    nullif(v_payment.review_reason, ''),
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

create or replace function public.admin_get_payment_review_alert()
returns table (pending_review_count integer)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('payments.write');

  return query
  select count(*)::integer
  from public.payment_events pe
  where pe.status = 'pending_review';
end;
$$;

drop function if exists public.admin_list_payments(text, integer);

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
  created_at timestamptz,
  transfer_reference text,
  transfer_memo text,
  payer_full_name text,
  amount_cents integer,
  currency text,
  transfer_confirmed_at timestamptz,
  review_reason text
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
    concat_ws(
      ' - ',
      coalesce(
        nullif(pe.metadata ->> 'payer_full_name', ''),
        nullif(u.full_name, ''),
        u.email,
        pe.payer_user_id::text
      ),
      pe.provider,
      pe.transfer_reference
    ),
    pe.status,
    'payments',
    pe.created_at,
    pe.transfer_reference,
    pe.transfer_memo,
    coalesce(
      nullif(pe.metadata ->> 'payer_full_name', ''),
      nullif(u.full_name, ''),
      u.email,
      pe.payer_user_id::text
    ),
    pe.amount_cents,
    pe.currency,
    nullif(pe.metadata ->> 'transfer_confirmed_at', '')::timestamptz,
    nullif(pe.review_reason, '')
  from public.payment_events pe
  join public.users u on u.id = pe.payer_user_id
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or pe.provider_event_id ilike '%' || p_query || '%'
     or pe.transfer_reference ilike '%' || p_query || '%'
     or pe.transfer_memo ilike '%' || p_query || '%'
     or coalesce(pe.metadata ->> 'payer_full_name', '') ilike '%' || p_query || '%'
  order by
    case
      when pe.status = 'pending_review' then 0
      when pe.status = 'pending' then 1
      else 2
    end,
    pe.created_at desc
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

  if p_decision = 'reject'
    and nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception 'PAYMENT_REJECTION_REASON_REQUIRED' using errcode = '22023';
  end if;

  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if v_payment.status not in ('pending_review', 'pending') then
    raise exception 'PAYMENT_NOT_READY_FOR_REVIEW' using errcode = '22023';
  end if;

  v_status := case when p_decision = 'approve' then 'succeeded' else 'failed' end;

  update public.payment_events
  set
    status = v_status,
    paid_at = case when p_decision = 'approve' then coalesce(paid_at, now()) else paid_at end,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = nullif(btrim(p_reason), ''),
    idempotency_key = nullif(btrim(p_idempotency_key), ''),
    metadata = metadata || jsonb_build_object(
      'admin_decision',
      p_decision,
      'manual_approval_required',
      true,
      'transfer_reference',
      transfer_reference,
      'transfer_memo',
      transfer_memo,
      'transfer_confirmed_at',
      metadata ->> 'transfer_confirmed_at'
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
    jsonb_build_object(
      'decision', p_decision,
      'transfer_reference', v_payment.transfer_reference,
      'transfer_memo', v_payment.transfer_memo,
      'transfer_confirmed_at', v_payment.metadata ->> 'transfer_confirmed_at'
    )
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

revoke all on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
) from public, anon;
revoke all on function public.confirm_my_membership_payment_transfer(uuid)
  from public, anon;
revoke all on function public.get_my_membership_payment_request()
  from public, anon;
revoke all on function public.admin_get_payment_review_alert()
  from public, anon;
revoke all on function public.admin_list_payments(text, integer)
  from public, anon;
revoke all on function public.admin_review_payment(uuid, text, text, text)
  from public, anon;

grant execute on function public.get_my_admin_session() to authenticated;
grant execute on function public.get_admin_dashboard_summary(timestamptz, timestamptz, text, text) to authenticated;
grant execute on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
) to authenticated;
grant execute on function public.confirm_my_membership_payment_transfer(uuid)
  to authenticated;
grant execute on function public.get_my_membership_payment_request()
  to authenticated;
grant execute on function public.admin_get_payment_review_alert()
  to authenticated;
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

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'membership_payment_bank',
  '{
    "bank_code": "VCB",
    "bank_name": "Vietcombank",
    "bank_bin": "970436",
    "bank_account_number": "1026806174",
    "bank_account_name": "LE PHU THACH",
    "bank_account_display_name": "Lê Phú Thạch"
  }'::jsonb,
  'active',
  'Server-owned VietQR receiving account for manually reviewed membership payments.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'membership_payment_bank'
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
      coalesce(max(public.commission_records.currency), 'VND') as result_currency
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
      coalesce(max(public.commission_records.currency), 'VND') as result_currency
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
revoke all on function public.get_my_sale_dashboard() from public, anon;
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
grant execute on function public.get_my_sale_dashboard() to authenticated;
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
    plan_item_count between plan_days * 10 and plan_days * 11
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
    plan_item_count between plan_days * 10 and plan_days * 11
    and registered_item_count between 0 and plan_item_count
  ),
  unique (user_id, registration_idempotency_key)
);

alter table public.guest_schedule_reward_registrations
  drop constraint if exists guest_reward_plan_shape_valid;
alter table public.guest_schedule_reward_registrations
  add constraint guest_reward_plan_shape_valid check (
    plan_item_count between plan_days * 10 and plan_days * 11
    and cardinality(plan_item_ids) = plan_item_count
    and eligible_item_ids <@ plan_item_ids
  );

alter table public.member_schedule_reward_registrations
  drop constraint if exists member_reward_plan_shape_valid;
alter table public.member_schedule_reward_registrations
  add constraint member_reward_plan_shape_valid check (
    plan_item_count between plan_days * 10 and plan_days * 11
    and registered_item_count between 0 and plan_item_count
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
     or v_request.schedule_item_count < v_request.days * 10
     or v_request.schedule_item_count > v_request.days * 11 then
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
       having count(*) not between 10 and 11
           or count(distinct lsi.start_time) <> count(*)
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
  if now() > v_eligibility.window_end then
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
     or v_object.created_at > v_eligibility.window_end then
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
    when now() > v_eligibility.window_end then 'available'
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
  if now() > v_eligibility.window_end then
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
-- BEGIN 18-nabi-companion-notifications.sql
-- Commit de xuat: feat(m30): them Nabi companion notification contract
-- Draft non-destructive migration. Review in sandbox before production.

begin;

insert into public.admin_permissions (code, description)
values
  ('notifications.read', 'Read Nabi notification catalog and metrics.'),
  ('notifications.write', 'Version and activate Nabi notification catalog.')
on conflict (code) do update
set description = excluded.description, is_active = true;

create table if not exists public.nabi_notification_definitions (
  id uuid primary key default gen_random_uuid(),
  notification_id text not null,
  content_version integer not null check (content_version > 0),
  category text not null check (category in (
    'contextual', 'milestone', 'subscription', 'retention',
    'reward', 'report', 'care', 'profile'
  )),
  priority integer not null check (priority between 0 and 1000),
  policy_key text not null,
  primary_action_key text not null,
  secondary_action_key text,
  allowed_channels text[] not null default array['in_app']::text[],
  title_template text not null default 'Nabi nhắn bạn',
  body_template text not null,
  config jsonb not null default '{}'::jsonb,
  effective_from timestamptz,
  effective_until timestamptz,
  status text not null default 'draft'
    check (status in ('draft', 'active', 'archived')),
  reason text not null,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (notification_id, content_version)
);

create unique index if not exists idx_nabi_notification_one_active
  on public.nabi_notification_definitions(notification_id)
  where status = 'active';

create table if not exists public.nabi_notification_user_states (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  notification_id text not null,
  content_version integer not null,
  source_event_id text not null,
  status text not null check (status in (
    'eligible', 'queued', 'presented', 'collapsed', 'opened', 'deferred',
    'actioned', 'converted', 'expired', 'cancelled', 'failed'
  )),
  eligible_at timestamptz not null,
  presented_at timestamptz,
  opened_at timestamptz,
  deferred_until timestamptz,
  actioned_at timestamptz,
  converted_at timestamptz,
  expires_at timestamptz,
  display_count integer not null default 0 check (display_count >= 0),
  dismiss_count integer not null default 0 check (dismiss_count >= 0),
  primary_click_count integer not null default 0 check (primary_click_count >= 0),
  secondary_click_count integer not null default 0 check (secondary_click_count >= 0),
  last_session_id text,
  last_screen_key text,
  membership_plan text,
  billing_cycle text,
  safe_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, notification_id, source_event_id, content_version)
);

create index if not exists idx_nabi_notification_state_user_status
  on public.nabi_notification_user_states(user_id, status, eligible_at desc);

create table if not exists public.nabi_notification_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  proactive_in_app_enabled boolean not null default true,
  push_enabled boolean not null default false,
  analytics_upload_enabled boolean not null default false,
  quiet_start_minutes integer check (quiet_start_minutes between 0 and 1439),
  quiet_end_minutes integer check (quiet_end_minutes between 0 and 1439),
  updated_at timestamptz not null default now()
);

create table if not exists public.nabi_notification_events (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  occurrence_id uuid references public.nabi_notification_user_states(id) on delete set null,
  notification_id text not null,
  event_name text not null check (event_name in (
    'nabi_notification_eligible', 'nabi_notification_shown',
    'nabi_notification_opened', 'nabi_notification_dismissed',
    'nabi_notification_primary_clicked', 'nabi_notification_secondary_clicked',
    'nabi_upgrade_page_viewed', 'nabi_checkout_started',
    'nabi_conversion_completed', 'nabi_notification_failed'
  )),
  session_id text,
  screen_key text,
  app_version text,
  result_code text,
  safe_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_nabi_notification_events_user_created
  on public.nabi_notification_events(user_id, created_at desc);
create index if not exists idx_nabi_notification_events_retention
  on public.nabi_notification_events(created_at);

alter table public.nabi_notification_definitions enable row level security;
alter table public.nabi_notification_user_states enable row level security;
alter table public.nabi_notification_preferences enable row level security;
alter table public.nabi_notification_events enable row level security;

drop policy if exists nabi_notification_definitions_read_active
  on public.nabi_notification_definitions;
create policy nabi_notification_definitions_read_active
  on public.nabi_notification_definitions for select to authenticated
  using (
    status = 'active'
    and (effective_from is null or effective_from <= now())
    and (effective_until is null or effective_until > now())
  );

drop policy if exists nabi_notification_state_read_own
  on public.nabi_notification_user_states;
create policy nabi_notification_state_read_own
  on public.nabi_notification_user_states for select to authenticated
  using (user_id = auth.uid());

drop policy if exists nabi_notification_preferences_read_own
  on public.nabi_notification_preferences;
create policy nabi_notification_preferences_read_own
  on public.nabi_notification_preferences for select to authenticated
  using (user_id = auth.uid());

drop policy if exists nabi_notification_events_read_own
  on public.nabi_notification_events;
create policy nabi_notification_events_read_own
  on public.nabi_notification_events for select to authenticated
  using (user_id = auth.uid());

create or replace function public.get_active_nabi_notification_definitions()
returns setof public.nabi_notification_definitions
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select d.*
  from public.nabi_notification_definitions d
  where auth.uid() is not null
    and d.status = 'active'
    and (d.effective_from is null or d.effective_from <= now())
    and (d.effective_until is null or d.effective_until > now())
  order by d.priority desc, d.notification_id, d.content_version desc
$$;

create or replace function public.claim_nabi_notification_occurrence(
  p_notification_id text,
  p_content_version integer,
  p_source_event_id text,
  p_status text,
  p_eligible_at timestamptz,
  p_expires_at timestamptz default null,
  p_safe_metadata jsonb default '{}'::jsonb
)
returns public.nabi_notification_user_states
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_state public.nabi_notification_user_states%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;
  if p_status not in ('eligible', 'queued') then
    raise exception 'INVALID_NOTIFICATION_STATE' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_notification_id, '')), '') is null
     or nullif(btrim(coalesce(p_source_event_id, '')), '') is null
     or p_content_version <= 0 then
    raise exception 'INVALID_NOTIFICATION_CLAIM' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.nabi_notification_definitions d
    where d.notification_id = btrim(p_notification_id)
      and d.content_version = p_content_version
      and d.status = 'active'
      and (d.effective_from is null or d.effective_from <= now())
      and (d.effective_until is null or d.effective_until > now())
  ) then
    raise exception 'NOTIFICATION_DEFINITION_INACTIVE' using errcode = '22023';
  end if;

  insert into public.nabi_notification_user_states (
    user_id, notification_id, content_version, source_event_id, status,
    eligible_at, expires_at, safe_metadata
  ) values (
    v_user_id, btrim(p_notification_id), p_content_version,
    btrim(p_source_event_id), p_status, p_eligible_at, p_expires_at,
    coalesce(p_safe_metadata, '{}'::jsonb)
  )
  on conflict (user_id, notification_id, source_event_id, content_version)
  do update set updated_at = public.nabi_notification_user_states.updated_at
  returning * into v_state;

  return v_state;
end;
$$;

create or replace function public.upsert_my_nabi_notification_preferences(
  p_proactive_in_app_enabled boolean,
  p_push_enabled boolean,
  p_analytics_upload_enabled boolean,
  p_quiet_start_minutes integer default null,
  p_quiet_end_minutes integer default null
)
returns public.nabi_notification_preferences
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_preferences public.nabi_notification_preferences%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;
  if p_quiet_start_minutes is not null and p_quiet_start_minutes not between 0 and 1439 then
    raise exception 'INVALID_QUIET_START' using errcode = '22023';
  end if;
  if p_quiet_end_minutes is not null and p_quiet_end_minutes not between 0 and 1439 then
    raise exception 'INVALID_QUIET_END' using errcode = '22023';
  end if;

  insert into public.nabi_notification_preferences (
    user_id, proactive_in_app_enabled, push_enabled,
    analytics_upload_enabled, quiet_start_minutes, quiet_end_minutes, updated_at
  ) values (
    v_user_id, p_proactive_in_app_enabled, p_push_enabled,
    p_analytics_upload_enabled, p_quiet_start_minutes, p_quiet_end_minutes, now()
  )
  on conflict (user_id) do update set
    proactive_in_app_enabled = excluded.proactive_in_app_enabled,
    push_enabled = excluded.push_enabled,
    analytics_upload_enabled = excluded.analytics_upload_enabled,
    quiet_start_minutes = excluded.quiet_start_minutes,
    quiet_end_minutes = excluded.quiet_end_minutes,
    updated_at = now()
  returning * into v_preferences;

  return v_preferences;
end;
$$;

create or replace function public.record_nabi_notification_events(p_events jsonb)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_event jsonb;
  v_count integer := 0;
  v_event_name text;
  v_occurrence_id uuid;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;
  if jsonb_typeof(coalesce(p_events, '[]'::jsonb)) <> 'array'
     or jsonb_array_length(coalesce(p_events, '[]'::jsonb)) > 100 then
    raise exception 'INVALID_EVENT_BATCH' using errcode = '22023';
  end if;
  if not coalesce((
    select p.analytics_upload_enabled
    from public.nabi_notification_preferences p
    where p.user_id = v_user_id
  ), false) then
    return 0;
  end if;

  for v_event in select value from jsonb_array_elements(p_events)
  loop
    v_event_name := v_event ->> 'event_name';
    if v_event_name not in (
      'nabi_notification_eligible', 'nabi_notification_shown',
      'nabi_notification_opened', 'nabi_notification_dismissed',
      'nabi_notification_primary_clicked', 'nabi_notification_secondary_clicked',
      'nabi_upgrade_page_viewed', 'nabi_checkout_started',
      'nabi_conversion_completed', 'nabi_notification_failed'
    ) then
      continue;
    end if;
    v_occurrence_id := nullif(v_event ->> 'occurrence_id', '')::uuid;
    if v_occurrence_id is not null and not exists (
      select 1 from public.nabi_notification_user_states s
      where s.id = v_occurrence_id and s.user_id = v_user_id
    ) then
      continue;
    end if;

    insert into public.nabi_notification_events (
      id, user_id, occurrence_id, notification_id, event_name,
      session_id, screen_key, app_version, result_code, safe_metadata, created_at
    ) values (
      (v_event ->> 'id')::uuid,
      v_user_id,
      v_occurrence_id,
      coalesce(v_event ->> 'notification_id', 'unknown'),
      v_event_name,
      nullif(v_event ->> 'session_id', ''),
      nullif(v_event ->> 'screen_key', ''),
      nullif(v_event ->> 'app_version', ''),
      nullif(v_event ->> 'result_code', ''),
      coalesce(v_event -> 'safe_metadata', '{}'::jsonb),
      coalesce(nullif(v_event ->> 'created_at', '')::timestamptz, now())
    ) on conflict (id) do nothing;
    if found then v_count := v_count + 1; end if;
  end loop;
  return v_count;
end;
$$;

create or replace function public.admin_upsert_nabi_notification_definition(
  p_notification_id text,
  p_content_version integer,
  p_category text,
  p_priority integer,
  p_policy_key text,
  p_primary_action_key text,
  p_secondary_action_key text,
  p_allowed_channels text[],
  p_title_template text,
  p_body_template text,
  p_config jsonb,
  p_status text,
  p_reason text,
  p_idempotency_key text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  perform public.admin_assert_permission('notifications.write');
  if nullif(btrim(coalesce(p_reason, '')), '') is null
     or nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception 'ADMIN_REASON_AND_IDEMPOTENCY_REQUIRED' using errcode = '22023';
  end if;
  if p_status not in ('draft', 'active', 'archived')
     or p_category not in ('contextual', 'milestone', 'subscription', 'retention', 'reward', 'report', 'care', 'profile')
     or not p_policy_key = any(array[
       'free_plan_limit', 'free_chat_limit', 'first_streak_7', 'expert_locked',
       'map365_locked', 'weekly_report_locked', 'expert_recommended',
       'plus_day_7', 'plus_day_15', 'plus_expiry_5', 'plus_expiry_1',
       'streak_6', 'rescue_card', 'reward_ready', 'report_ready',
       'invite_available', 'care_near_sleep', 'return_72h', 'partial_day', 'profile_stale'
     ])
     or not p_primary_action_key = any(array[
       'membership_compare', 'membership_payment', 'achievement', 'expert_benefit',
       'map365', 'weekly_report', 'easiest_task', 'rescue_card_confirm',
       'reward_box', 'user_invite', 'dashboard_today', 'today_tasks', 'partial_profile'
     ])
     or exists (
       select 1 from unnest(coalesce(p_allowed_channels, array[]::text[])) channel
       where channel not in ('in_app', 'os_local')
     ) then
    raise exception 'INVALID_NOTIFICATION_DEFINITION' using errcode = '22023';
  end if;

  if p_status = 'active' then
    update public.nabi_notification_definitions
    set status = 'archived'
    where notification_id = btrim(p_notification_id) and status = 'active';
  end if;

  insert into public.nabi_notification_definitions (
    notification_id, content_version, category, priority, policy_key,
    primary_action_key, secondary_action_key, allowed_channels,
    title_template, body_template, config, status, reason, created_by
  ) values (
    btrim(p_notification_id), p_content_version, p_category, p_priority,
    p_policy_key, p_primary_action_key, nullif(btrim(coalesce(p_secondary_action_key, '')), ''),
    p_allowed_channels, p_title_template, p_body_template,
    coalesce(p_config, '{}'::jsonb), p_status, btrim(p_reason), auth.uid()
  )
  on conflict (notification_id, content_version) do update set
    category = excluded.category,
    priority = excluded.priority,
    policy_key = excluded.policy_key,
    primary_action_key = excluded.primary_action_key,
    secondary_action_key = excluded.secondary_action_key,
    allowed_channels = excluded.allowed_channels,
    title_template = excluded.title_template,
    body_template = excluded.body_template,
    config = excluded.config,
    status = excluded.status,
    reason = excluded.reason
  returning id into v_id;

  perform public.admin_write_audit(
    'nabi_notification_definition_upsert', 'nabi_notification_definition',
    btrim(p_notification_id), btrim(p_reason), btrim(p_idempotency_key),
    jsonb_build_object('content_version', p_content_version, 'status', p_status)
  );
  return v_id;
end;
$$;

revoke all on table public.nabi_notification_definitions from anon, authenticated;
revoke all on table public.nabi_notification_user_states from anon, authenticated;
revoke all on table public.nabi_notification_preferences from anon, authenticated;
revoke all on table public.nabi_notification_events from anon, authenticated;
grant select on public.nabi_notification_definitions to authenticated;
grant select on public.nabi_notification_user_states to authenticated;
grant select on public.nabi_notification_preferences to authenticated;
grant select on public.nabi_notification_events to authenticated;

revoke all on function public.get_active_nabi_notification_definitions() from public, anon;
revoke all on function public.claim_nabi_notification_occurrence(text, integer, text, text, timestamptz, timestamptz, jsonb) from public, anon;
revoke all on function public.upsert_my_nabi_notification_preferences(boolean, boolean, boolean, integer, integer) from public, anon;
revoke all on function public.record_nabi_notification_events(jsonb) from public, anon;
revoke all on function public.admin_upsert_nabi_notification_definition(text, integer, text, integer, text, text, text, text[], text, text, jsonb, text, text, text) from public, anon;
grant execute on function public.get_active_nabi_notification_definitions() to authenticated;
grant execute on function public.claim_nabi_notification_occurrence(text, integer, text, text, timestamptz, timestamptz, jsonb) to authenticated;
grant execute on function public.upsert_my_nabi_notification_preferences(boolean, boolean, boolean, integer, integer) to authenticated;
grant execute on function public.record_nabi_notification_events(jsonb) to authenticated;
grant execute on function public.admin_upsert_nabi_notification_definition(text, integer, text, integer, text, text, text, text[], text, text, jsonb, text, text, text) to authenticated;

insert into public.system_config_versions (
  config_key, config_value, status, reason, created_by
)
select
  'nabi_companion_notifications_rollout',
  '{"enabled": false, "in_app_enabled": false, "os_local_enabled": false}'::jsonb,
  'active',
  'M30 rollout remains disabled until sandbox and device acceptance pass.',
  null
where not exists (
  select 1 from public.system_config_versions
  where config_key = 'nabi_companion_notifications_rollout' and status = 'active'
);

-- BEGIN 19-dev-sandbox-comprehensive-seed.sql
-- NanoBio comprehensive local/sandbox fixture.
-- This source is mirrored verbatim into config.sql immediately before its
-- final COMMIT. It deliberately has no transaction wrapper or module markers.
-- Never run it on production or shared staging.
--
-- Every identifier, person, address, bank detail, citizen identifier and
-- voucher below is fictional. Relative dates use the database clock and the
-- Asia/Ho_Chi_Minh quota boundary so the fixture stays meaningful over time.

-- fixture-table: users
-- fixture-table: health_subjects
-- fixture-table: health_profiles
-- fixture-table: lifestyle_habits
-- fixture-table: health_goals
-- fixture-table: health_conditions
-- fixture-table: food_allergies
-- fixture-table: medical_treatments
-- fixture-table: survey_answers
-- fixture-table: meal_plans
-- fixture-table: daily_health_tasks
-- fixture-table: lifestyle_schedule_items
-- fixture-table: notifications
-- fixture-table: health_tracking_logs
-- fixture-table: health_score_ledgers
-- fixture-table: wellness_point_ledgers
-- fixture-table: nutrition_logs
-- fixture-table: ai_insights
-- fixture-table: ai_recommendations
-- fixture-table: personal_schedule_ai_requests
-- fixture-table: meal_catalog
-- fixture-table: exercise_catalog
-- fixture-table: schedule_task_catalog
-- fixture-table: membership_plans
-- fixture-table: plan_entitlements
-- fixture-table: membership_subscriptions
-- fixture-table: usage_quota_rules
-- fixture-table: usage_quota_counters
-- fixture-table: usage_events
-- fixture-table: family_groups
-- fixture-table: family_members
-- fixture-table: sale_profiles
-- fixture-table: referral_codes
-- fixture-table: referral_relationships
-- fixture-table: payment_events
-- fixture-table: commission_rates
-- fixture-table: commission_records
-- fixture-table: admin_roles
-- fixture-table: admin_permissions
-- fixture-table: admin_role_permissions
-- fixture-table: admin_user_roles
-- fixture-table: admin_audit_events
-- fixture-table: system_config_versions
-- fixture-table: report_exports
-- fixture-table: sale_point_adjustments
-- fixture-table: admin_reconciliation_runs
-- fixture-table: admin_reconciliation_discrepancies
-- fixture-table: sale_point_conversions
-- fixture-table: sale_payout_profiles
-- fixture-table: guest_schedule_reward_registrations
-- fixture-table: member_schedule_reward_registrations
-- fixture-table: schedule_reward_eligibilities
-- fixture-table: schedule_completion_attempts
-- fixture-table: schedule_completion_proofs
-- fixture-table: wellness_reward_wallets
-- fixture-table: wellness_point_allocations
-- fixture-table: wellness_reward_offers
-- fixture-table: wellness_reward_codes
-- fixture-table: wellness_reward_redemptions
-- fixture-table: wellness_redemption_allocation_usages
-- fixture-table: nabi_notification_definitions
-- fixture-table: nabi_notification_user_states
-- fixture-table: nabi_notification_preferences
-- fixture-table: nabi_notification_events

-- ---------------------------------------------------------------------------
-- Auth -> users/self subjects. Existing dev.free/dev.plus/dev.family/dev.admin
-- bindings are owned by the historical config seed and are intentionally not
-- changed here.
-- ---------------------------------------------------------------------------

with fixture_users as (
  select *
  from (
    values
      ('11000000-0000-4000-8000-000000000001'::uuid, '21000000-0000-4000-8000-000000000001'::uuid, 'dev.fixture.guest@nanobio.local', 'Fixture Guest', 'anonymous', true),
      ('11000000-0000-4000-8000-000000000002'::uuid, '21000000-0000-4000-8000-000000000002'::uuid, 'dev.fixture.free.ready@nanobio.local', 'Fixture Free Ready', 'email', false),
      ('11000000-0000-4000-8000-000000000003'::uuid, '21000000-0000-4000-8000-000000000003'::uuid, 'dev.fixture.free.exhausted@nanobio.local', 'Fixture Free Exhausted', 'email', false),
      ('11000000-0000-4000-8000-000000000004'::uuid, '21000000-0000-4000-8000-000000000004'::uuid, 'dev.fixture.plus.active@nanobio.local', 'Fixture Plus Active', 'email', false),
      ('11000000-0000-4000-8000-000000000005'::uuid, '21000000-0000-4000-8000-000000000005'::uuid, 'dev.fixture.plus.trial@nanobio.local', 'Fixture Plus Trial', 'email', false),
      ('11000000-0000-4000-8000-000000000006'::uuid, '21000000-0000-4000-8000-000000000006'::uuid, 'dev.fixture.plus.pastdue@nanobio.local', 'Fixture Plus Past Due', 'email', false),
      ('11000000-0000-4000-8000-000000000007'::uuid, '21000000-0000-4000-8000-000000000007'::uuid, 'dev.fixture.plus.canceled@nanobio.local', 'Fixture Plus Canceled', 'email', false),
      ('11000000-0000-4000-8000-000000000008'::uuid, '21000000-0000-4000-8000-000000000008'::uuid, 'dev.fixture.plus.expired@nanobio.local', 'Fixture Plus Expired', 'email', false),
      ('11000000-0000-4000-8000-000000000009'::uuid, '21000000-0000-4000-8000-000000000009'::uuid, 'dev.fixture.family.owner@nanobio.local', 'Fixture Family Owner', 'email', false),
      ('11000000-0000-4000-8000-000000000010'::uuid, '21000000-0000-4000-8000-000000000010'::uuid, 'dev.fixture.family.adult@nanobio.local', 'Fixture Family Adult', 'email', false),
      ('11000000-0000-4000-8000-000000000011'::uuid, '21000000-0000-4000-8000-000000000011'::uuid, 'dev.fixture.family.member@nanobio.local', 'Fixture Family Member', 'email', false),
      ('11000000-0000-4000-8000-000000000012'::uuid, '21000000-0000-4000-8000-000000000012'::uuid, 'dev.fixture.family.child@nanobio.local', 'Fixture Family Child', 'email', false),
      ('11000000-0000-4000-8000-000000000013'::uuid, '21000000-0000-4000-8000-000000000013'::uuid, 'dev.fixture.family.viewer@nanobio.local', 'Fixture Family Viewer', 'email', false),
      ('11000000-0000-4000-8000-000000000014'::uuid, '21000000-0000-4000-8000-000000000014'::uuid, 'dev.fixture.family.invited@nanobio.local', 'Fixture Family Invited', 'email', false),
      ('11000000-0000-4000-8000-000000000015'::uuid, '21000000-0000-4000-8000-000000000015'::uuid, 'dev.fixture.family.removed@nanobio.local', 'Fixture Family Removed', 'email', false),
      ('11000000-0000-4000-8000-000000000016'::uuid, '21000000-0000-4000-8000-000000000016'::uuid, 'dev.fixture.family.paused@nanobio.local', 'Fixture Family Paused', 'email', false),
      ('11000000-0000-4000-8000-000000000017'::uuid, '21000000-0000-4000-8000-000000000017'::uuid, 'dev.fixture.family.closed@nanobio.local', 'Fixture Family Closed', 'email', false),
      ('11000000-0000-4000-8000-000000000018'::uuid, '21000000-0000-4000-8000-000000000018'::uuid, 'dev.fixture.sale.active@nanobio.local', 'Fixture Sale A', 'email', false),
      ('11000000-0000-4000-8000-000000000019'::uuid, '21000000-0000-4000-8000-000000000019'::uuid, 'dev.fixture.sale.direct@nanobio.local', 'Fixture Sale B', 'email', false),
      ('11000000-0000-4000-8000-000000000020'::uuid, '21000000-0000-4000-8000-000000000020'::uuid, 'dev.fixture.sale.customer@nanobio.local', 'Fixture Sale Customer C', 'email', false),
      ('11000000-0000-4000-8000-000000000021'::uuid, '21000000-0000-4000-8000-000000000021'::uuid, 'dev.fixture.sale.pending@nanobio.local', 'Fixture Sale Pending', 'email', false),
      ('11000000-0000-4000-8000-000000000022'::uuid, '21000000-0000-4000-8000-000000000022'::uuid, 'dev.fixture.sale.suspended@nanobio.local', 'Fixture Sale Suspended', 'email', false),
      ('11000000-0000-4000-8000-000000000023'::uuid, '21000000-0000-4000-8000-000000000023'::uuid, 'dev.fixture.sale.closed@nanobio.local', 'Fixture Sale Closed', 'email', false),
      ('11000000-0000-4000-8000-000000000024'::uuid, '21000000-0000-4000-8000-000000000024'::uuid, 'dev.fixture.wellness@nanobio.local', 'Fixture Wellness', 'email', false),
      ('11000000-0000-4000-8000-000000000025'::uuid, '21000000-0000-4000-8000-000000000025'::uuid, 'dev.fixture.admin.finance@nanobio.local', 'Fixture Finance Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000026'::uuid, '21000000-0000-4000-8000-000000000026'::uuid, 'dev.fixture.admin.support@nanobio.local', 'Fixture Support Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000027'::uuid, '21000000-0000-4000-8000-000000000027'::uuid, 'dev.fixture.admin.content@nanobio.local', 'Fixture Content Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000028'::uuid, '21000000-0000-4000-8000-000000000028'::uuid, 'dev.fixture.admin.operations@nanobio.local', 'Fixture Operations Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000029'::uuid, '21000000-0000-4000-8000-000000000029'::uuid, 'dev.fixture.admin.only@nanobio.local', 'Fixture Admin Only', 'email', false),
      ('11000000-0000-4000-8000-000000000030'::uuid, '21000000-0000-4000-8000-000000000030'::uuid, 'dev.fixture.admin.revoked@nanobio.local', 'Fixture Revoked Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000031'::uuid, '21000000-0000-4000-8000-000000000031'::uuid, 'dev.fixture.sale.a.ready@nanobio.local', 'Fixture Sale A Customer Ready', 'email', false),
      ('11000000-0000-4000-8000-000000000032'::uuid, '21000000-0000-4000-8000-000000000032'::uuid, 'dev.fixture.sale.a.pending@nanobio.local', 'Fixture Sale A Customer Pending', 'email', false),
      ('11000000-0000-4000-8000-000000000033'::uuid, '21000000-0000-4000-8000-000000000033'::uuid, 'dev.fixture.sale.a.prospect@nanobio.local', 'Fixture Sale A Customer Prospect', 'email', false)
  ) as t(user_id, identity_id, email, full_name, provider, is_anonymous)
)
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone_change, phone_change_token,
  reauthentication_token, raw_app_meta_data, raw_user_meta_data, created_at,
  updated_at, is_sso_user, is_anonymous
)
select
  user_id,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'authenticated',
  'authenticated',
  email,
  crypt('NanoBio@123456', gen_salt('bf')),
  now(),
  '', '', '', '', '', '', '', '',
  jsonb_build_object('provider', provider, 'providers', array[provider]),
  jsonb_build_object(
    'full_name', full_name,
    'seed_fixture', 'dev-sandbox-comprehensive-v1',
    'fixture_key', replace(replace(email, 'dev.fixture.', ''), '@nanobio.local', '')
  ),
  now(), now(), false, is_anonymous
from fixture_users
on conflict (id) do update
set
  email = excluded.email,
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = coalesce(auth.users.email_confirmed_at, excluded.email_confirmed_at),
  confirmation_token = '',
  recovery_token = '',
  email_change = '',
  email_change_token_new = '',
  email_change_token_current = '',
  phone_change = '',
  phone_change_token = '',
  reauthentication_token = '',
  raw_app_meta_data = excluded.raw_app_meta_data,
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at = now(),
  is_anonymous = excluded.is_anonymous;

with fixture_users as (
  select *
  from (
    values
      ('11000000-0000-4000-8000-000000000001'::uuid, '21000000-0000-4000-8000-000000000001'::uuid, 'dev.fixture.guest@nanobio.local', 'Fixture Guest', 'anonymous'),
      ('11000000-0000-4000-8000-000000000002'::uuid, '21000000-0000-4000-8000-000000000002'::uuid, 'dev.fixture.free.ready@nanobio.local', 'Fixture Free Ready', 'email'),
      ('11000000-0000-4000-8000-000000000003'::uuid, '21000000-0000-4000-8000-000000000003'::uuid, 'dev.fixture.free.exhausted@nanobio.local', 'Fixture Free Exhausted', 'email'),
      ('11000000-0000-4000-8000-000000000004'::uuid, '21000000-0000-4000-8000-000000000004'::uuid, 'dev.fixture.plus.active@nanobio.local', 'Fixture Plus Active', 'email'),
      ('11000000-0000-4000-8000-000000000005'::uuid, '21000000-0000-4000-8000-000000000005'::uuid, 'dev.fixture.plus.trial@nanobio.local', 'Fixture Plus Trial', 'email'),
      ('11000000-0000-4000-8000-000000000006'::uuid, '21000000-0000-4000-8000-000000000006'::uuid, 'dev.fixture.plus.pastdue@nanobio.local', 'Fixture Plus Past Due', 'email'),
      ('11000000-0000-4000-8000-000000000007'::uuid, '21000000-0000-4000-8000-000000000007'::uuid, 'dev.fixture.plus.canceled@nanobio.local', 'Fixture Plus Canceled', 'email'),
      ('11000000-0000-4000-8000-000000000008'::uuid, '21000000-0000-4000-8000-000000000008'::uuid, 'dev.fixture.plus.expired@nanobio.local', 'Fixture Plus Expired', 'email'),
      ('11000000-0000-4000-8000-000000000009'::uuid, '21000000-0000-4000-8000-000000000009'::uuid, 'dev.fixture.family.owner@nanobio.local', 'Fixture Family Owner', 'email'),
      ('11000000-0000-4000-8000-000000000010'::uuid, '21000000-0000-4000-8000-000000000010'::uuid, 'dev.fixture.family.adult@nanobio.local', 'Fixture Family Adult', 'email'),
      ('11000000-0000-4000-8000-000000000011'::uuid, '21000000-0000-4000-8000-000000000011'::uuid, 'dev.fixture.family.member@nanobio.local', 'Fixture Family Member', 'email'),
      ('11000000-0000-4000-8000-000000000012'::uuid, '21000000-0000-4000-8000-000000000012'::uuid, 'dev.fixture.family.child@nanobio.local', 'Fixture Family Child', 'email'),
      ('11000000-0000-4000-8000-000000000013'::uuid, '21000000-0000-4000-8000-000000000013'::uuid, 'dev.fixture.family.viewer@nanobio.local', 'Fixture Family Viewer', 'email'),
      ('11000000-0000-4000-8000-000000000014'::uuid, '21000000-0000-4000-8000-000000000014'::uuid, 'dev.fixture.family.invited@nanobio.local', 'Fixture Family Invited', 'email'),
      ('11000000-0000-4000-8000-000000000015'::uuid, '21000000-0000-4000-8000-000000000015'::uuid, 'dev.fixture.family.removed@nanobio.local', 'Fixture Family Removed', 'email'),
      ('11000000-0000-4000-8000-000000000016'::uuid, '21000000-0000-4000-8000-000000000016'::uuid, 'dev.fixture.family.paused@nanobio.local', 'Fixture Family Paused', 'email'),
      ('11000000-0000-4000-8000-000000000017'::uuid, '21000000-0000-4000-8000-000000000017'::uuid, 'dev.fixture.family.closed@nanobio.local', 'Fixture Family Closed', 'email'),
      ('11000000-0000-4000-8000-000000000018'::uuid, '21000000-0000-4000-8000-000000000018'::uuid, 'dev.fixture.sale.active@nanobio.local', 'Fixture Sale A', 'email'),
      ('11000000-0000-4000-8000-000000000019'::uuid, '21000000-0000-4000-8000-000000000019'::uuid, 'dev.fixture.sale.direct@nanobio.local', 'Fixture Sale B', 'email'),
      ('11000000-0000-4000-8000-000000000020'::uuid, '21000000-0000-4000-8000-000000000020'::uuid, 'dev.fixture.sale.customer@nanobio.local', 'Fixture Sale Customer C', 'email'),
      ('11000000-0000-4000-8000-000000000021'::uuid, '21000000-0000-4000-8000-000000000021'::uuid, 'dev.fixture.sale.pending@nanobio.local', 'Fixture Sale Pending', 'email'),
      ('11000000-0000-4000-8000-000000000022'::uuid, '21000000-0000-4000-8000-000000000022'::uuid, 'dev.fixture.sale.suspended@nanobio.local', 'Fixture Sale Suspended', 'email'),
      ('11000000-0000-4000-8000-000000000023'::uuid, '21000000-0000-4000-8000-000000000023'::uuid, 'dev.fixture.sale.closed@nanobio.local', 'Fixture Sale Closed', 'email'),
      ('11000000-0000-4000-8000-000000000024'::uuid, '21000000-0000-4000-8000-000000000024'::uuid, 'dev.fixture.wellness@nanobio.local', 'Fixture Wellness', 'email'),
      ('11000000-0000-4000-8000-000000000025'::uuid, '21000000-0000-4000-8000-000000000025'::uuid, 'dev.fixture.admin.finance@nanobio.local', 'Fixture Finance Admin', 'email'),
      ('11000000-0000-4000-8000-000000000026'::uuid, '21000000-0000-4000-8000-000000000026'::uuid, 'dev.fixture.admin.support@nanobio.local', 'Fixture Support Admin', 'email'),
      ('11000000-0000-4000-8000-000000000027'::uuid, '21000000-0000-4000-8000-000000000027'::uuid, 'dev.fixture.admin.content@nanobio.local', 'Fixture Content Admin', 'email'),
      ('11000000-0000-4000-8000-000000000028'::uuid, '21000000-0000-4000-8000-000000000028'::uuid, 'dev.fixture.admin.operations@nanobio.local', 'Fixture Operations Admin', 'email'),
      ('11000000-0000-4000-8000-000000000029'::uuid, '21000000-0000-4000-8000-000000000029'::uuid, 'dev.fixture.admin.only@nanobio.local', 'Fixture Admin Only', 'email'),
      ('11000000-0000-4000-8000-000000000030'::uuid, '21000000-0000-4000-8000-000000000030'::uuid, 'dev.fixture.admin.revoked@nanobio.local', 'Fixture Revoked Admin', 'email'),
      ('11000000-0000-4000-8000-000000000031'::uuid, '21000000-0000-4000-8000-000000000031'::uuid, 'dev.fixture.sale.a.ready@nanobio.local', 'Fixture Sale A Customer Ready', 'email'),
      ('11000000-0000-4000-8000-000000000032'::uuid, '21000000-0000-4000-8000-000000000032'::uuid, 'dev.fixture.sale.a.pending@nanobio.local', 'Fixture Sale A Customer Pending', 'email'),
      ('11000000-0000-4000-8000-000000000033'::uuid, '21000000-0000-4000-8000-000000000033'::uuid, 'dev.fixture.sale.a.prospect@nanobio.local', 'Fixture Sale A Customer Prospect', 'email')
  ) as t(user_id, identity_id, email, full_name, provider)
)
insert into auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at,
  created_at, updated_at
)
select
  identity_id,
  user_id,
  user_id::text,
  jsonb_build_object(
    'sub', user_id::text,
    'email', email,
    'email_verified', true,
    'phone_verified', false,
    'full_name', full_name,
    'seed_fixture', 'dev-sandbox-comprehensive-v1'
  ),
  provider,
  now(), now(), now()
from fixture_users
on conflict (provider, provider_id) do update
set
  user_id = excluded.user_id,
  identity_data = excluded.identity_data,
  updated_at = now();

update public.users
set
  phone = case id
    when '11000000-0000-4000-8000-000000000002'::uuid then '+84900000002'
    when '11000000-0000-4000-8000-000000000003'::uuid then '+84900000003'
    when '11000000-0000-4000-8000-000000000018'::uuid then '+84900000018'
    when '11000000-0000-4000-8000-000000000019'::uuid then '+84900000019'
    when '11000000-0000-4000-8000-000000000020'::uuid then '+84900000020'
    when '11000000-0000-4000-8000-000000000031'::uuid then '+84900000031'
    when '11000000-0000-4000-8000-000000000032'::uuid then '+84900000032'
    when '11000000-0000-4000-8000-000000000033'::uuid then '+84900000033'
    else phone
  end,
  birth_year = case id
    when '11000000-0000-4000-8000-000000000031'::uuid then 1990
    when '11000000-0000-4000-8000-000000000032'::uuid then 1987
    when '11000000-0000-4000-8000-000000000033'::uuid then 1995
    else birth_year
  end,
  onboarding_status = case id
    when '11000000-0000-4000-8000-000000000002'::uuid then 'not_started'::public.nb_onboarding_status
    when '11000000-0000-4000-8000-000000000003'::uuid then 'in_progress'::public.nb_onboarding_status
    else 'completed'::public.nb_onboarding_status
  end,
  onboarding_completed_at = case
    when id in (
      '11000000-0000-4000-8000-000000000002'::uuid,
      '11000000-0000-4000-8000-000000000003'::uuid
    ) then null
    else now() - interval '1 day'
  end,
  app_access_mode = case
    when id = '11000000-0000-4000-8000-000000000029'::uuid then 'admin'
    when id in (
      '11000000-0000-4000-8000-000000000025'::uuid,
      '11000000-0000-4000-8000-000000000026'::uuid,
      '11000000-0000-4000-8000-000000000027'::uuid,
      '11000000-0000-4000-8000-000000000028'::uuid
    ) then 'both'
    else 'user'
  end,
  admin_status = case
    when id = '11000000-0000-4000-8000-000000000030'::uuid then 'closed'
    when id = '11000000-0000-4000-8000-000000000022'::uuid then 'suspended'
    else 'active'
  end,
  updated_at = now()
where id between
  '11000000-0000-4000-8000-000000000001'::uuid and
  '11000000-0000-4000-8000-000000000033'::uuid;

-- Make the historical Admin a dual-surface account; its super_admin role is
-- created by the legacy bootstrap and remains the stable Storage uploader.
update public.users
set app_access_mode = 'both', updated_at = now()
where id = '10000000-0000-4000-8000-000000000104'::uuid;

-- ---------------------------------------------------------------------------
-- Membership, entitlement and quota cohorts.
-- ---------------------------------------------------------------------------

insert into public.membership_subscriptions (
  id, user_id, plan_code, status, source, starts_at, ends_at,
  current_period_start, current_period_end, provider, provider_subscription_id,
  metadata
)
values
  ('31000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'free', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'free-ready-v1', '{"fixture":true,"scenario":"free-ready"}'::jsonb),
  ('31000000-0000-4000-8000-000000000003'::uuid, '11000000-0000-4000-8000-000000000003'::uuid, 'free', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'free-exhausted-v1', '{"fixture":true,"scenario":"free-exhausted"}'::jsonb),
  ('31000000-0000-4000-8000-000000000004'::uuid, '11000000-0000-4000-8000-000000000004'::uuid, 'plus', 'active', 'payment_provider', now() - interval '7 days', now() + interval '23 days', now() - interval '7 days', now() + interval '23 days', 'fixture', 'plus-active-v1', '{"fixture":true,"scenario":"plus-active"}'::jsonb),
  ('31000000-0000-4000-8000-000000000005'::uuid, '11000000-0000-4000-8000-000000000005'::uuid, 'plus', 'trialing', 'promotion', now() - interval '2 days', now() + interval '12 days', now() - interval '2 days', now() + interval '12 days', 'fixture', 'plus-trial-v1', '{"fixture":true,"scenario":"plus-trial"}'::jsonb),
  ('31000000-0000-4000-8000-000000000006'::uuid, '11000000-0000-4000-8000-000000000006'::uuid, 'plus', 'past_due', 'payment_provider', now() - interval '29 days', now() + interval '1 day', now() - interval '29 days', now() + interval '1 day', 'fixture', 'plus-past-due-v1', '{"fixture":true,"scenario":"plus-past-due"}'::jsonb),
  ('31000000-0000-4000-8000-000000000007'::uuid, '11000000-0000-4000-8000-000000000007'::uuid, 'plus', 'canceled', 'payment_provider', now() - interval '31 days', now() - interval '1 day', now() - interval '31 days', now() - interval '1 day', 'fixture', 'plus-canceled-v1', '{"fixture":true,"scenario":"plus-canceled"}'::jsonb),
  ('31000000-0000-4000-8000-000000000008'::uuid, '11000000-0000-4000-8000-000000000008'::uuid, 'plus', 'expired', 'payment_provider', now() - interval '61 days', now() - interval '31 days', now() - interval '61 days', now() - interval '31 days', 'fixture', 'plus-expired-v1', '{"fixture":true,"scenario":"plus-expired"}'::jsonb),
  ('31000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, 'family_plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'family-owner-v1', '{"fixture":true,"scenario":"family-active"}'::jsonb),
  ('31000000-0000-4000-8000-000000000016'::uuid, '11000000-0000-4000-8000-000000000016'::uuid, 'family_plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'family-paused-v1', '{"fixture":true,"scenario":"family-paused"}'::jsonb),
  ('31000000-0000-4000-8000-000000000017'::uuid, '11000000-0000-4000-8000-000000000017'::uuid, 'family_plus', 'active', 'manual', now() - interval '37 days', now() + interval '3 days', now() - interval '37 days', now() + interval '3 days', 'fixture', 'family-closed-v1', '{"fixture":true,"scenario":"family-closed"}'::jsonb),
  ('31000000-0000-4000-8000-000000000018'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 'plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'sale-a-v1', '{"fixture":true,"scenario":"sale-a"}'::jsonb),
  ('31000000-0000-4000-8000-000000000019'::uuid, '11000000-0000-4000-8000-000000000019'::uuid, 'plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'sale-b-v1', '{"fixture":true,"scenario":"sale-b"}'::jsonb),
  ('31000000-0000-4000-8000-000000000020'::uuid, '11000000-0000-4000-8000-000000000020'::uuid, 'plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'sale-c-v1', '{"fixture":true,"scenario":"sale-c"}'::jsonb),
  ('31000000-0000-4000-8000-000000000031'::uuid, '11000000-0000-4000-8000-000000000031'::uuid, 'plus', 'active', 'payment_provider', now() - interval '90 days', now() + interval '30 days', now() - interval '30 days', now() + interval '30 days', 'fixture', 'sale-a-customer-ready-v1', '{"fixture":true,"scenario":"sale-a-customer-ready"}'::jsonb),
  ('31000000-0000-4000-8000-000000000032'::uuid, '11000000-0000-4000-8000-000000000032'::uuid, 'plus', 'active', 'payment_provider', now() - interval '3 days', now() + interval '27 days', now() - interval '3 days', now() + interval '27 days', 'fixture', 'sale-a-customer-pending-v1', '{"fixture":true,"scenario":"sale-a-customer-pending"}'::jsonb),
  ('31000000-0000-4000-8000-000000000033'::uuid, '11000000-0000-4000-8000-000000000033'::uuid, 'free', 'active', 'manual', now() - interval '1 day', now() + interval '30 days', now() - interval '1 day', now() + interval '30 days', 'fixture', 'sale-a-customer-prospect-v1', '{"fixture":true,"scenario":"sale-a-customer-prospect"}'::jsonb),
  ('31000000-0000-4000-8000-000000000024'::uuid, '11000000-0000-4000-8000-000000000024'::uuid, 'free', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'wellness-v1', '{"fixture":true,"scenario":"wellness"}'::jsonb)
on conflict (id) do update
set
  plan_code = excluded.plan_code,
  status = excluded.status,
  source = excluded.source,
  starts_at = excluded.starts_at,
  ends_at = excluded.ends_at,
  current_period_start = excluded.current_period_start,
  current_period_end = excluded.current_period_end,
  metadata = excluded.metadata,
  updated_at = now();

insert into public.usage_quota_counters (
  id, user_id, feature_key, period_key, plan_code, used_count, limit_count,
  reset_at
)
values
  (
    '32000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('day', now(), 'Asia/Ho_Chi_Minh'),
    'free', 1, 3,
    public.usage_quota_reset_at('day', now(), 'Asia/Ho_Chi_Minh')
  ),
  (
    '32000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000003'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('day', now(), 'Asia/Ho_Chi_Minh'),
    'free', 3, 3,
    public.usage_quota_reset_at('day', now(), 'Asia/Ho_Chi_Minh')
  ),
  (
    '32000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'personal_schedule_generation',
    public.usage_quota_period_key('month', now(), 'Asia/Ho_Chi_Minh'),
    'free', 1, 3,
    public.usage_quota_reset_at('month', now(), 'Asia/Ho_Chi_Minh')
  ),
  (
    '32000000-0000-4000-8000-000000000024'::uuid,
    '11000000-0000-4000-8000-000000000024'::uuid,
    'personal_schedule_generation',
    public.usage_quota_period_key('month', now(), 'Asia/Ho_Chi_Minh'),
    'free', 1, 3,
    public.usage_quota_reset_at('month', now(), 'Asia/Ho_Chi_Minh')
  )
on conflict (user_id, feature_key, period_key) do update
set
  used_count = excluded.used_count,
  plan_code = excluded.plan_code,
  limit_count = excluded.limit_count,
  reset_at = excluded.reset_at,
  updated_at = now();

insert into public.usage_events (
  id, user_id, feature_key, period_key, count_delta, idempotency_key,
  event_source, metadata
)
values
  (
    '33000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('day', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-free-ready-ai-chat', 'admin',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000003'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('day', now(), 'Asia/Ho_Chi_Minh'),
    3, 'fixture-free-exhausted-ai-chat', 'admin',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'personal_schedule_generation',
    public.usage_quota_period_key('month', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-free-ready-schedule-request', 'trusted_backend',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh","source":"quota_commit"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000005'::uuid,
    '11000000-0000-4000-8000-000000000004'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('none', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-plus-edge-ai-chat', 'edge_function',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000006'::uuid,
    '11000000-0000-4000-8000-000000000005'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('none', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-plus-sql-job-ai-chat', 'sql_job',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000024'::uuid,
    '11000000-0000-4000-8000-000000000024'::uuid,
    'personal_schedule_generation',
    public.usage_quota_period_key('month', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-wellness-reward-request', 'trusted_backend',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh","source":"quota_commit"}'::jsonb
  )
on conflict (user_id, feature_key, idempotency_key) do update
set count_delta = excluded.count_delta,
    event_source = excluded.event_source,
    metadata = excluded.metadata;

-- ---------------------------------------------------------------------------
-- Health/cloud-sync representative rows. They use the Free-ready self subject
-- and remain ordinary user-owned data, unlike the server-owned reward rows.
-- ---------------------------------------------------------------------------

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_profiles (
  id, user_id, subject_id, occupation, height_cm, weight_kg, bmi,
  blood_pressure, blood_sugar
)
select
  '40000000-0000-4000-8000-000000000001'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture analyst', 165, 60, 22.04, '118/76', '5.2'
from s
on conflict (subject_id) do update
set occupation = excluded.occupation, height_cm = excluded.height_cm,
    weight_kg = excluded.weight_kg, bmi = excluded.bmi,
    blood_pressure = excluded.blood_pressure, blood_sugar = excluded.blood_sugar,
    updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.lifestyle_habits (
  id, user_id, subject_id, skip_breakfast, eat_late, eat_sweet, eat_oily,
  low_vegetable, low_water, fast_food, alcohol, coffee_high, sleep_quality,
  activity_level, water_per_day
)
select
  '40000000-0000-4000-8000-000000000002'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  false, true, false, false, false, false, false, false, false,
  'good', 'moderate', '2000ml'
from s
on conflict (subject_id) do update
set skip_breakfast = excluded.skip_breakfast, eat_late = excluded.eat_late,
    sleep_quality = excluded.sleep_quality, activity_level = excluded.activity_level,
    water_per_day = excluded.water_per_day, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_goals (
  id, user_id, subject_id, goal_code, goal_name, is_active
)
select
  '40000000-0000-4000-8000-000000000003'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture-balance', 'Fixture balanced routine', true
from s
on conflict (subject_id, goal_code) do update
set goal_name = excluded.goal_name, is_active = excluded.is_active;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_conditions (
  id, user_id, subject_id, condition_code, condition_name, severity_level
)
select
  '40000000-0000-4000-8000-000000000004'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture-monitor', 'Fixture monitoring only', 1
from s
on conflict (subject_id, condition_code) do update
set condition_name = excluded.condition_name, severity_level = excluded.severity_level;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.food_allergies (
  id, user_id, subject_id, allergy_name, note
)
select
  '40000000-0000-4000-8000-000000000005'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture ingredient', 'Synthetic fixture only'
from s
on conflict (subject_id, allergy_name) do update set note = excluded.note;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.medical_treatments (
  id, user_id, subject_id, treatment_name, medication_name, note
)
select
  '40000000-0000-4000-8000-000000000006'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture review', 'Fixture placebo', 'No real medical information'
from s
on conflict (id) do update
set treatment_name = excluded.treatment_name, medication_name = excluded.medication_name,
    note = excluded.note;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.survey_answers (
  id, user_id, subject_id, question_code, answer_value
)
select
  '40000000-0000-4000-8000-000000000007'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture-consent', 'accepted'
from s
on conflict (subject_id, question_code) do update set answer_value = excluded.answer_value;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.meal_plans (
  id, user_id, subject_id, plan_date, meal_type, meal_name, description,
  calories, protein, carbs, fat, fiber, water_ml, meal_order, start_time,
  end_time, cooking_instructions, is_completed, ai_generated
)
select
  '40000000-0000-4000-8000-000000000008'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date, 'breakfast',
  'Fixture breakfast', 'Synthetic meal plan', 420, 22, 54, 12, 8, 300, 1,
  time '07:00', time '07:30', 'Fixture instructions', false, true
from s
on conflict (subject_id, plan_date, meal_order) do update
set meal_name = excluded.meal_name, description = excluded.description,
    is_completed = excluded.is_completed, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.daily_health_tasks (
  id, user_id, subject_id, task_date, task_code, category, title, description,
  target_value, current_value, unit, is_completed, sort_order, source,
  encouragement
)
select
  '40000000-0000-4000-8000-000000000009'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date, 'fixture-water',
  'hydration', 'Fixture hydration task', 'Synthetic task', 2000, 1200, 'ml',
  false, 1, 'fixture', 'Keep going'
from s
on conflict (subject_id, task_date, task_code) do update
set current_value = excluded.current_value, is_completed = excluded.is_completed,
    updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.notifications (
  id, user_id, subject_id, title, body, type, is_read, source_type, source_id,
  scheduled_at, notification_id, action_status, payload
)
select
  '40000000-0000-4000-8000-000000000010'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture reminder', 'Synthetic notification', 'fixture', false,
  'fixture', 'fixture-notification', now(), 19001, 'pending',
  '{"fixture":true}'::jsonb
from s
on conflict (id) do update
set title = excluded.title, body = excluded.body, is_read = excluded.is_read,
    updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
), rows as (
  select *
  from (
    values
      ('40000000-0000-4000-8000-000000000016'::uuid, 'Fixture completed reminder', 'Synthetic completed notification', true, 'fixture-notification-completed', 19002, 'completed', now() - interval '20 minutes'),
      ('40000000-0000-4000-8000-000000000017'::uuid, 'Fixture skipped reminder', 'Synthetic skipped notification', true, 'fixture-notification-skipped', 19003, 'skipped', now() - interval '10 minutes')
  ) as t(id, title, body, is_read, source_id, notification_id, action_status, responded_at)
)
insert into public.notifications (
  id, user_id, subject_id, title, body, type, is_read, source_type, source_id,
  scheduled_at, notification_id, action_status, responded_at, payload
)
select
  r.id, '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  r.title, r.body, 'fixture', r.is_read, 'fixture', r.source_id,
  now(), r.notification_id, r.action_status, r.responded_at,
  jsonb_build_object('fixture', true, 'action_status', r.action_status)
from s cross join rows r
on conflict (id) do update
set title = excluded.title, body = excluded.body, is_read = excluded.is_read,
    action_status = excluded.action_status, responded_at = excluded.responded_at,
    payload = excluded.payload, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_tracking_logs (
  id, user_id, subject_id, weight_kg, calories, water_ml, sleep_hours,
  stress_level, steps_count, heart_rate_bpm, oxygen_saturation, daily_score,
  mood, log_date
)
select
  '40000000-0000-4000-8000-000000000011'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  60, 1800, 1600, 7.5, 2, 7200, 72, 98, 82, 'steady',
  (now() at time zone 'Asia/Ho_Chi_Minh')::date
from s
on conflict (subject_id, log_date) do update
set water_ml = excluded.water_ml, steps_count = excluded.steps_count,
    daily_score = excluded.daily_score, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_score_ledgers (
  id, user_id, subject_id, period_start, period_end, score, formula_version,
  breakdown, idempotency_key, calculated_at
)
select
  '40000000-0000-4000-8000-000000000012'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date - 6,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  82, 'fixture-v1', '{"fixture":true}'::jsonb, 'fixture-health-score-v1', now()
from s
on conflict (subject_id, period_start, period_end, formula_version) do update
set score = excluded.score, breakdown = excluded.breakdown, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.nutrition_logs (
  id, user_id, subject_id, food_name, calories, protein, carbs, fat, meal_type,
  eaten_at
)
select
  '40000000-0000-4000-8000-000000000013'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture salad', 210, 8, 28, 7, 'lunch', now()
from s
on conflict (id) do update set food_name = excluded.food_name, eaten_at = excluded.eaten_at;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.ai_insights (
  id, user_id, subject_id, insight_type, title, content, risk_level
)
select
  '40000000-0000-4000-8000-000000000014'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture', 'Fixture insight', 'Synthetic insight only', 'low'
from s
on conflict (id) do update
set title = excluded.title, content = excluded.content, risk_level = excluded.risk_level;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.ai_recommendations (
  id, user_id, subject_id, recommendation_type, title, description, action_text,
  is_read
)
select
  '40000000-0000-4000-8000-000000000015'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture', 'Fixture recommendation', 'Synthetic recommendation', 'Review', false
from s
on conflict (id) do update
set title = excluded.title, description = excluded.description,
    action_text = excluded.action_text, is_read = excluded.is_read;

insert into public.personal_schedule_ai_requests (
  request_id, user_id, actor_mode, status, start_date, days, meal_count,
  exercise_count, schedule_item_count, error_code, completed_at
)
values
  (
    'fixture-free-ready-schedule-request',
    '11000000-0000-4000-8000-000000000002'::uuid,
    'member_new', 'succeeded', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 3, 3, 10, null, now()
  ),
  (
    'fixture-free-ready-schedule-generating',
    '11000000-0000-4000-8000-000000000002'::uuid,
    'member_new', 'generating', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 0, 0, 0, null, null
  ),
  (
    'fixture-free-ready-schedule-failed',
    '11000000-0000-4000-8000-000000000002'::uuid,
    'member_new', 'failed', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 0, 0, 0, 'fixture_generation_failed', now() - interval '1 hour'
  ),
  (
    'fixture-guest-initial-schedule-request',
    '11000000-0000-4000-8000-000000000003'::uuid,
    'initial_guest', 'succeeded', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 3, 3, 10, null, now() - interval '2 hours'
  ),
  (
    'fixture-wellness-reward-request',
    '11000000-0000-4000-8000-000000000024'::uuid,
    'member_new', 'succeeded', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 3, 3, 11, null, now() - interval '3 hours'
  )
on conflict (request_id) do update
set status = excluded.status, completed_at = excluded.completed_at,
    schedule_item_count = excluded.schedule_item_count,
    error_code = excluded.error_code, updated_at = now();

-- Reference catalogs are intentionally small but complete enough for a bare
-- local/sandbox rebuild to exercise every public catalog table.
insert into public.meal_catalog (
  code, meal_type, meal_name, description, cooking_instructions, calories,
  protein, carbs, fat, fiber, water_ml, is_active
)
values (
  'fixture-meal-breakfast-v1', 'breakfast', 'Fixture balanced breakfast',
  'Synthetic reference meal; not nutrition guidance.',
  'Fixture-only preparation instructions.', 420, 22, 54, 12, 8, 300, true
)
on conflict (code) do update
set meal_type = excluded.meal_type, meal_name = excluded.meal_name,
    description = excluded.description,
    cooking_instructions = excluded.cooking_instructions,
    calories = excluded.calories, protein = excluded.protein,
    carbs = excluded.carbs, fat = excluded.fat, fiber = excluded.fiber,
    water_ml = excluded.water_ml, is_active = excluded.is_active,
    updated_at = now();

insert into public.exercise_catalog (
  code, category, title, description, unit, encouragement, min_target,
  max_target, default_target, intensity_level, is_active
)
values (
  'fixture-exercise-walk-v1', 'cardio', 'Fixture walk',
  'Synthetic reference exercise; not medical advice.', 'minutes',
  'Fixture encouragement.', 5, 60, 20, 'low', true
)
on conflict (code) do update
set category = excluded.category, title = excluded.title,
    description = excluded.description, unit = excluded.unit,
    encouragement = excluded.encouragement, min_target = excluded.min_target,
    max_target = excluded.max_target, default_target = excluded.default_target,
    intensity_level = excluded.intensity_level, is_active = excluded.is_active,
    updated_at = now();

insert into public.schedule_task_catalog (
  code, category, title, description, start_time, end_time, target_value,
  unit, encouragement, sort_order, is_active
)
values (
  'fixture-task-hydration-v1', 'hydration', 'Fixture hydration task',
  'Synthetic reference task.', time '07:00', time '21:00', 2000, 'ml',
  'Fixture encouragement.', 1, true
)
on conflict (code) do update
set category = excluded.category, title = excluded.title,
    description = excluded.description, start_time = excluded.start_time,
    end_time = excluded.end_time, target_value = excluded.target_value,
    unit = excluded.unit, encouragement = excluded.encouragement,
    sort_order = excluded.sort_order, is_active = excluded.is_active,
    updated_at = now();

-- The wellness account gets a complete 11-item manifest. The first two items
-- deliberately have a current 30-minute proof window for the Storage runner.
-- The runner, not static SQL, creates the completed/undone proof lifecycle;
-- the remaining rows are void historical cases or a future eligible case.
with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000024'::uuid
    and subject_type = 'self'
  limit 1
), items as (
  select *
  from (
    values
      ('44000000-0000-4000-8000-000000000001'::uuid, 0, 'Fixture proof active', 'wellness'),
      ('44000000-0000-4000-8000-000000000002'::uuid, 1, 'Fixture proof reversed', 'wellness'),
      ('44000000-0000-4000-8000-000000000003'::uuid, 2, 'Fixture completed', 'wellness'),
      ('44000000-0000-4000-8000-000000000004'::uuid, 3, 'Fixture undone', 'wellness'),
      ('44000000-0000-4000-8000-000000000005'::uuid, 4, 'Fixture void', 'wellness'),
      ('44000000-0000-4000-8000-000000000006'::uuid, 5, 'Fixture item 6', 'wellness'),
      ('44000000-0000-4000-8000-000000000007'::uuid, 6, 'Fixture item 7', 'wellness'),
      ('44000000-0000-4000-8000-000000000008'::uuid, 7, 'Fixture item 8', 'wellness'),
      ('44000000-0000-4000-8000-000000000009'::uuid, 8, 'Fixture item 9', 'wellness'),
      ('44000000-0000-4000-8000-000000000010'::uuid, 9, 'Fixture item 10', 'wellness'),
      ('44000000-0000-4000-8000-000000000011'::uuid, 10, 'Fixture proof future', 'wellness')
  ) as t(id, item_order, title, category)
)
insert into public.lifestyle_schedule_items (
  id, user_id, subject_id, schedule_date, start_time, end_time, title,
  description, category, source_type, source_id, target_value, current_value,
  unit, is_completed, sort_order, ai_generated, encouragement
)
select
  i.id,
  '11000000-0000-4000-8000-000000000024'::uuid,
  s.id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  ((now() at time zone 'Asia/Ho_Chi_Minh') + make_interval(mins => i.item_order))::time,
  ((now() at time zone 'Asia/Ho_Chi_Minh') + make_interval(mins => i.item_order + 20))::time,
  i.title, 'Synthetic schedule fixture', i.category, 'fixture',
  'fixture-wellness-manifest', 1, 0, 'task', false, i.item_order, true,
  'Fixture encouragement'
from s cross join items i
on conflict (id) do update
set title = excluded.title, description = excluded.description,
    schedule_date = excluded.schedule_date, start_time = excluded.start_time,
    end_time = excluded.end_time, updated_at = now();

-- ---------------------------------------------------------------------------
-- FamilyPlus: an active linked group, plus paused and closed groups. Owner is
-- represented by family_groups.owner_user_id; family_members uses reachable
-- app roles only (adult/member/child/viewer).
-- ---------------------------------------------------------------------------

insert into public.family_groups (
  id, owner_user_id, plan_subscription_id, display_name, status,
  last_idempotency_key
)
values
  (
    '50000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000009'::uuid,
    '31000000-0000-4000-8000-000000000009'::uuid,
    'Fixture Active Family', 'active', 'fixture-family-active-v1'
  ),
  (
    '50000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000016'::uuid,
    '31000000-0000-4000-8000-000000000016'::uuid,
    'Fixture Paused Family', 'paused', 'fixture-family-paused-v1'
  ),
  (
    '50000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000017'::uuid,
    '31000000-0000-4000-8000-000000000017'::uuid,
    'Fixture Closed Family', 'closed', 'fixture-family-closed-v1'
  )
on conflict (id) do update
set display_name = excluded.display_name, status = excluded.status,
    plan_subscription_id = excluded.plan_subscription_id,
    last_idempotency_key = excluded.last_idempotency_key, updated_at = now();

-- The app-owned family subjects belong to the FamilyPlus owner while retaining
-- an optional linked account. This is the same ownership boundary enforced by
-- the FamilyPlus RPC, rather than reusing each member's self subject.
insert into public.health_subjects (
  id, owner_user_id, linked_user_id, family_group_id, subject_type,
  display_name, relationship, is_active
)
values
  ('52000000-0000-4000-8000-000000000010'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000010'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Adult', 'adult', true),
  ('52000000-0000-4000-8000-000000000011'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000011'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Member', 'member', true),
  ('52000000-0000-4000-8000-000000000012'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000012'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Child', 'child', true),
  ('52000000-0000-4000-8000-000000000013'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000013'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Viewer', 'viewer', true),
  ('52000000-0000-4000-8000-000000000014'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000014'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Invited', 'member', true),
  ('52000000-0000-4000-8000-000000000015'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000015'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Removed', 'member', false),
  ('52000000-0000-4000-8000-000000000016'::uuid, '11000000-0000-4000-8000-000000000016'::uuid, null, '50000000-0000-4000-8000-000000000002'::uuid, 'family_member', 'Fixture Paused Subject', 'adult', true)
on conflict (id) do update
set
  owner_user_id = excluded.owner_user_id,
  linked_user_id = excluded.linked_user_id,
  family_group_id = excluded.family_group_id,
  subject_type = excluded.subject_type,
  display_name = excluded.display_name,
  relationship = excluded.relationship,
  is_active = excluded.is_active,
  updated_at = now();

with family_subjects as (
  select *
  from (
    values
      ('11000000-0000-4000-8000-000000000010'::uuid, '52000000-0000-4000-8000-000000000010'::uuid),
      ('11000000-0000-4000-8000-000000000011'::uuid, '52000000-0000-4000-8000-000000000011'::uuid),
      ('11000000-0000-4000-8000-000000000012'::uuid, '52000000-0000-4000-8000-000000000012'::uuid),
      ('11000000-0000-4000-8000-000000000013'::uuid, '52000000-0000-4000-8000-000000000013'::uuid),
      ('11000000-0000-4000-8000-000000000014'::uuid, '52000000-0000-4000-8000-000000000014'::uuid),
      ('11000000-0000-4000-8000-000000000015'::uuid, '52000000-0000-4000-8000-000000000015'::uuid),
      ('11000000-0000-4000-8000-000000000016'::uuid, '52000000-0000-4000-8000-000000000016'::uuid)
  ) as t(user_id, id)
)
insert into public.family_members (
  id, family_group_id, subject_id, user_id, invited_email, display_name, role,
  status, can_view, can_edit, last_idempotency_key, joined_at
)
select
  v.id, v.family_group_id, fs.id, v.user_id, v.invited_email, v.display_name,
  v.role, v.status, v.can_view, v.can_edit, v.idempotency_key, v.joined_at
from (
  values
    ('51000000-0000-4000-8000-000000000010'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000010'::uuid, null::text, 'Fixture Adult', 'adult', 'active', true, true, 'fixture-family-adult-v1', now() - interval '5 days'),
    ('51000000-0000-4000-8000-000000000011'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000011'::uuid, null::text, 'Fixture Member', 'member', 'active', true, false, 'fixture-family-member-v1', now() - interval '5 days'),
    ('51000000-0000-4000-8000-000000000012'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000012'::uuid, null::text, 'Fixture Child', 'child', 'active', true, false, 'fixture-family-child-v1', now() - interval '5 days'),
    ('51000000-0000-4000-8000-000000000013'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000013'::uuid, null::text, 'Fixture Viewer', 'viewer', 'active', true, false, 'fixture-family-viewer-v1', now() - interval '5 days'),
    ('51000000-0000-4000-8000-000000000014'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000014'::uuid, 'dev.fixture.family.invited@nanobio.local', 'Fixture Invited', 'member', 'invited', false, false, 'fixture-family-invited-v1', null::timestamptz),
    ('51000000-0000-4000-8000-000000000015'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000015'::uuid, null::text, 'Fixture Removed', 'member', 'removed', false, false, 'fixture-family-removed-v1', now() - interval '10 days'),
    ('51000000-0000-4000-8000-000000000016'::uuid, '50000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000016'::uuid, null::text, 'Fixture Paused Member', 'adult', 'active', true, true, 'fixture-family-paused-member-v1', now() - interval '5 days')
) as v(id, family_group_id, user_id, invited_email, display_name, role, status, can_view, can_edit, idempotency_key, joined_at)
join family_subjects fs on fs.user_id = v.user_id
on conflict (id) do update
set
  user_id = excluded.user_id, invited_email = excluded.invited_email,
  display_name = excluded.display_name, role = excluded.role, status = excluded.status,
  can_view = excluded.can_view, can_edit = excluded.can_edit,
  last_idempotency_key = excluded.last_idempotency_key,
  joined_at = excluded.joined_at, updated_at = now();


-- ---------------------------------------------------------------------------
-- Sale A has direct customer fixtures for its dashboard, customer list and
-- point ledger. The independent A -> B -> Customer C chain remains direct-only:
-- C's succeeded payment produces the only 10% commission for B, never A.
-- ---------------------------------------------------------------------------

insert into public.sale_profiles (
  user_id, status, approved_at, suspended_at, closed_at, terms_version,
  terms_accepted_at, participation_device_hash, note, metadata
)
values
  ('11000000-0000-4000-8000-000000000018'::uuid, 'active', now() - interval '20 days', null, null, 'fixture-v1', now() - interval '21 days', 'fixture-sale-a-device', 'Fixture Sale A active', '{"fixture":true,"graph":"A"}'::jsonb),
  ('11000000-0000-4000-8000-000000000019'::uuid, 'active', now() - interval '19 days', null, null, 'fixture-v1', now() - interval '20 days', 'fixture-sale-b-device', 'Fixture Sale B active', '{"fixture":true,"graph":"B"}'::jsonb),
  ('11000000-0000-4000-8000-000000000021'::uuid, 'pending', null, null, null, 'fixture-v1', now() - interval '2 days', 'fixture-sale-pending-device', 'Fixture Sale pending review', '{"fixture":true}'::jsonb),
  ('11000000-0000-4000-8000-000000000022'::uuid, 'suspended', now() - interval '30 days', now() - interval '2 days', null, 'fixture-v1', now() - interval '31 days', 'fixture-sale-suspended-device', 'Fixture Sale suspended', '{"fixture":true}'::jsonb),
  ('11000000-0000-4000-8000-000000000023'::uuid, 'closed', now() - interval '60 days', null, now() - interval '3 days', 'fixture-v1', now() - interval '61 days', 'fixture-sale-closed-device', 'Fixture Sale closed', '{"fixture":true}'::jsonb)
on conflict (user_id) do update
set
  status = excluded.status, approved_at = excluded.approved_at,
  suspended_at = excluded.suspended_at, closed_at = excluded.closed_at,
  terms_version = excluded.terms_version, terms_accepted_at = excluded.terms_accepted_at,
  participation_device_hash = excluded.participation_device_hash,
  note = excluded.note, metadata = excluded.metadata, updated_at = now();

insert into public.referral_codes (
  code, sale_user_id, status, created_at, revoked_at
)
values
  ('FIXTURE-A', '11000000-0000-4000-8000-000000000018'::uuid, 'active', now() - interval '20 days', null),
  ('FIXTURE-B', '11000000-0000-4000-8000-000000000019'::uuid, 'active', now() - interval '19 days', null),
  ('FIXTURE-CLOSED', '11000000-0000-4000-8000-000000000023'::uuid, 'revoked', now() - interval '59 days', now() - interval '3 days')
on conflict (code) do update
set sale_user_id = excluded.sale_user_id, status = excluded.status,
    revoked_at = excluded.revoked_at;

insert into public.referral_relationships (
  id, referrer_user_id, referred_user_id, referral_code, accepted_at, source,
  status, device_hash, metadata
)
values
  (
    '62000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000019'::uuid,
    'FIXTURE-A', now() - interval '18 days', 'signup', 'active',
    'fixture-referral-a-b', '{"fixture":true,"edge":"A->B"}'::jsonb
  ),
  (
    '62000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000019'::uuid,
    '11000000-0000-4000-8000-000000000020'::uuid,
    'FIXTURE-B', now() - interval '17 days', 'signup', 'active',
    'fixture-referral-b-c', '{"fixture":true,"edge":"B->C","direct_only":true}'::jsonb
  ),
  (
    '62000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    'FIXTURE-A', now() - interval '1 day', 'manual_admin', 'voided',
    'fixture-referral-voided', '{"fixture":true,"scenario":"voided"}'::jsonb
  ),
  (
    '62000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000031'::uuid,
    'FIXTURE-A', now() - interval '90 days', 'signup', 'active',
    'fixture-referral-a-ready', '{"fixture":true,"scenario":"sale-a-ready-customer","direct_only":true}'::jsonb
  ),
  (
    '62000000-0000-4000-8000-000000000005'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000032'::uuid,
    'FIXTURE-A', now() - interval '3 days', 'signup', 'active',
    'fixture-referral-a-pending', '{"fixture":true,"scenario":"sale-a-pending-customer","direct_only":true}'::jsonb
  ),
  (
    '62000000-0000-4000-8000-000000000006'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000033'::uuid,
    'FIXTURE-A', now() - interval '1 day', 'signup', 'active',
    'fixture-referral-a-prospect', '{"fixture":true,"scenario":"sale-a-prospect-customer","direct_only":true}'::jsonb
  )
on conflict (id) do update
set
  referrer_user_id = excluded.referrer_user_id,
  referred_user_id = excluded.referred_user_id,
  referral_code = excluded.referral_code,
  accepted_at = excluded.accepted_at, source = excluded.source,
  status = excluded.status, device_hash = excluded.device_hash,
  metadata = excluded.metadata;

insert into public.commission_rates (code, rate, is_active)
values ('direct_referral', 0.1000, true)
on conflict (code) do update set rate = excluded.rate, is_active = excluded.is_active,
  updated_at = now();

insert into public.payment_events (
  id, payer_user_id, subscription_id, plan_code, provider, provider_event_id,
  amount_cents, list_price_cents, commission_base_cents, currency, status,
  paid_at, reviewed_by, reviewed_at, review_reason, idempotency_key,
  raw_event_hash, metadata
)
values
  (
    '63000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000020'::uuid,
    '31000000-0000-4000-8000-000000000020'::uuid,
    'plus', 'fixture', 'payment-c-succeeded-v1', 199000, 199000, 199000,
    'VND', 'succeeded', now() - interval '2 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '2 days',
    'Fixture payment succeeded', 'fixture-payment-c-succeeded-v1',
    'fixture-payment-hash-c-1',
    '{"fixture":true,"commission_base_cents":199000,"graph":"A->B->C"}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    null, 'plus', 'fixture', 'payment-pending-v1', 199000, 199000, 199000,
    'VND', 'pending', null, null, null, null, 'fixture-payment-pending-v1',
    'fixture-payment-hash-pending', '{"fixture":true}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    null, 'plus', 'fixture', 'payment-refunded-v1', 199000, 199000, 199000,
    'VND', 'refunded', now() - interval '10 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '9 days',
    'Fixture refund', 'fixture-payment-refunded-v1',
    'fixture-payment-hash-refunded', '{"fixture":true}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000022'::uuid,
    null, 'plus', 'fixture', 'payment-chargeback-v1', 199000, 199000, 199000,
    'VND', 'chargeback', now() - interval '12 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '11 days',
    'Fixture chargeback', 'fixture-payment-chargeback-v1',
    'fixture-payment-hash-chargeback', '{"fixture":true}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000005'::uuid,
    '11000000-0000-4000-8000-000000000023'::uuid,
    null, 'plus', 'fixture', 'payment-failed-v1', 199000, 199000, 199000,
    'VND', 'failed', null, null, null, 'Fixture payment failed',
    'fixture-payment-failed-v1', 'fixture-payment-hash-failed',
    '{"fixture":true}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000006'::uuid,
    '11000000-0000-4000-8000-000000000031'::uuid,
    '31000000-0000-4000-8000-000000000031'::uuid,
    'plus', 'fixture', 'payment-a-ready-1-v1', 3990000, 3990000, 3990000,
    'VND', 'succeeded', now() - interval '70 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '70 days',
    'Fixture Sale A customer renewal 1', 'fixture-payment-a-ready-1-v1',
    'fixture-payment-hash-a-ready-1', '{"fixture":true,"sale":"A","scenario":"ready"}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000007'::uuid,
    '11000000-0000-4000-8000-000000000031'::uuid,
    '31000000-0000-4000-8000-000000000031'::uuid,
    'plus', 'fixture', 'payment-a-ready-2-v1', 3990000, 3990000, 3990000,
    'VND', 'succeeded', now() - interval '40 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '40 days',
    'Fixture Sale A customer renewal 2', 'fixture-payment-a-ready-2-v1',
    'fixture-payment-hash-a-ready-2', '{"fixture":true,"sale":"A","scenario":"ready"}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000008'::uuid,
    '11000000-0000-4000-8000-000000000031'::uuid,
    '31000000-0000-4000-8000-000000000031'::uuid,
    'plus', 'fixture', 'payment-a-ready-3-v1', 3990000, 3990000, 3990000,
    'VND', 'succeeded', now() - interval '10 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '10 days',
    'Fixture Sale A customer renewal 3', 'fixture-payment-a-ready-3-v1',
    'fixture-payment-hash-a-ready-3', '{"fixture":true,"sale":"A","scenario":"ready"}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000009'::uuid,
    '11000000-0000-4000-8000-000000000032'::uuid,
    '31000000-0000-4000-8000-000000000032'::uuid,
    'plus', 'fixture', 'payment-a-pending-v1', 1990000, 1990000, 1990000,
    'VND', 'succeeded', now() - interval '1 hour',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 hour',
    'Fixture Sale A customer recent payment', 'fixture-payment-a-pending-v1',
    'fixture-payment-hash-a-pending', '{"fixture":true,"sale":"A","scenario":"pending"}'::jsonb
  )
on conflict (provider, provider_event_id) do update
set
  status = excluded.status, paid_at = excluded.paid_at,
  reviewed_by = excluded.reviewed_by, reviewed_at = excluded.reviewed_at,
  review_reason = excluded.review_reason, metadata = excluded.metadata;

-- This direct insert supplies historical lifecycle rows for non-succeeded
-- payments. The succeeded C event receives its pending B commission through
-- the database trigger above and is never assigned to Sale A. Sale A's ready
-- customer commission rows are also created by that trigger, then promoted to
-- available fixture history below.
insert into public.commission_records (
  id, payment_event_id, receiver_user_id, payer_user_id, source_referral_id,
  rate, amount_cents, currency, status, available_at
)
values
  (
    '64000000-0000-4000-8000-000000000002'::uuid,
    '63000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000019'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    '62000000-0000-4000-8000-000000000003'::uuid,
    0.1000, 19900, 'VND', 'approved', now() - interval '1 day'
  ),
  (
    '64000000-0000-4000-8000-000000000003'::uuid,
    '63000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    '62000000-0000-4000-8000-000000000003'::uuid,
    0.1000, 19900, 'VND', 'reversed', now() - interval '8 days'
  ),
  (
    '64000000-0000-4000-8000-000000000004'::uuid,
    '63000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000022'::uuid,
    null, 0.1000, 19900, 'VND', 'paid', now() - interval '10 days'
  )
on conflict (payment_event_id, receiver_user_id) do update
set status = excluded.status, available_at = excluded.available_at,
    amount_cents = excluded.amount_cents, updated_at = now();

update public.commission_records
set status = 'approved', available_at = now() - interval '1 day', updated_at = now()
where receiver_user_id = '11000000-0000-4000-8000-000000000018'::uuid
  and payment_event_id in (
    '63000000-0000-4000-8000-000000000006'::uuid,
    '63000000-0000-4000-8000-000000000007'::uuid,
    '63000000-0000-4000-8000-000000000008'::uuid
  );

insert into public.sale_payout_profiles (
  sale_user_id, citizen_id, bank_bin, bank_name, bank_account_number,
  bank_account_name, updated_by, metadata
)
values (
  '11000000-0000-4000-8000-000000000018'::uuid,
  '000000000000', '9704', 'Fixture Bank', '000018000018',
  'FIXTURE SALE A', '10000000-0000-4000-8000-000000000104'::uuid,
  '{"fixture":true,"all_personal_data_is_fake":true}'::jsonb
)
on conflict (sale_user_id) do update
set citizen_id = excluded.citizen_id, bank_bin = excluded.bank_bin,
    bank_name = excluded.bank_name, bank_account_number = excluded.bank_account_number,
    bank_account_name = excluded.bank_account_name, updated_by = excluded.updated_by,
    metadata = excluded.metadata, updated_at = now();

insert into public.sale_point_adjustments (
  id, sale_user_id, point_delta_cents, currency, status, reason, reviewed_by,
  idempotency_key, metadata
)
values
  (
    '65000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    1900000, 'VND', 'approved', 'Fixture point credit',
    '10000000-0000-4000-8000-000000000104'::uuid,
    'fixture-sale-point-credit-v1', '{"fixture":true}'::jsonb
  ),
  (
    '65000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    -100000, 'VND', 'reversed', 'Fixture reversal',
    '10000000-0000-4000-8000-000000000104'::uuid,
    'fixture-sale-point-reversal-v1', '{"fixture":true}'::jsonb
  )
on conflict (idempotency_key) do update
set point_delta_cents = excluded.point_delta_cents, status = excluded.status,
    reason = excluded.reason, reviewed_by = excluded.reviewed_by,
    metadata = excluded.metadata;

insert into public.sale_point_conversions (
  id, sale_user_id, requested_point_cents, point_to_money_rate,
  money_amount_cents, currency, status, idempotency_key, requested_at,
  reviewed_by, reviewed_at, review_reason, paid_at, metadata
)
values
  ('66000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'requested', 'fixture-conversion-requested-v1', now() - interval '6 days', null, null, null, null, '{"fixture":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'pending_review', 'fixture-conversion-pending-v1', now() - interval '5 days', null, null, null, null, '{"fixture":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000003'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'approved', 'fixture-conversion-approved-v1', now() - interval '4 days', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '3 days', 'Fixture approval for Storage upload', null, '{"fixture":true,"storage_runner":"upload_here"}'::jsonb),
  ('66000000-0000-4000-8000-000000000007'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'approved', 'fixture-conversion-approved-retained-v1', now() - interval '2 days', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 day', 'Fixture approved lifecycle retained after optional payout finalization', null, '{"fixture":true,"retain_approved_state":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000004'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'paid', 'fixture-conversion-paid-v1', now() - interval '10 days', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '9 days', 'Fixture paid without Storage object', now() - interval '8 days', '{"fixture":true,"no_static_storage_object":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000005'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'rejected', 'fixture-conversion-rejected-v1', now() - interval '12 days', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '11 days', 'Fixture reject', null, '{"fixture":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000006'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'cancelled', 'fixture-conversion-cancelled-v1', now() - interval '14 days', null, null, 'Fixture cancel', null, '{"fixture":true}'::jsonb)
on conflict (sale_user_id, idempotency_key) where idempotency_key is not null do update
set
  status = excluded.status, reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at, review_reason = excluded.review_reason,
  paid_at = excluded.paid_at, metadata = excluded.metadata, updated_at = now();

-- ---------------------------------------------------------------------------
-- Admin roles, audit, export and reconciliation surfaces.
-- ---------------------------------------------------------------------------

insert into public.admin_user_roles (
  user_id, role_code, scope, is_active, granted_by, granted_at, revoked_at
)
values
  ('11000000-0000-4000-8000-000000000025'::uuid, 'finance_admin', 'global', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000026'::uuid, 'support_admin', 'global', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000027'::uuid, 'content_admin', 'global', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000028'::uuid, 'operations_admin', 'global', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000029'::uuid, 'super_admin', 'admin-only', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000030'::uuid, 'support_admin', 'global', false, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '30 days', now() - interval '1 day')
on conflict (user_id, role_code, scope) do update
set
  is_active = excluded.is_active, granted_by = excluded.granted_by,
  granted_at = excluded.granted_at, revoked_at = excluded.revoked_at;

insert into public.admin_audit_events (
  id, actor_id, action, target_type, target_id, reason, idempotency_key,
  metadata
)
values
  (
    '67000000-0000-4000-8000-000000000001'::uuid,
    '10000000-0000-4000-8000-000000000104'::uuid,
    'fixture_seed', 'sale_point_conversion',
    '66000000-0000-4000-8000-000000000003',
    'Fixture Admin audit', 'fixture-admin-audit-v1',
    '{"fixture":true,"no_production_data":true}'::jsonb
  )
on conflict (action, idempotency_key) do update
set reason = excluded.reason, metadata = excluded.metadata;

insert into public.system_config_versions (
  id, config_key, config_value, status, reason, created_by, created_at
)
values
  (
    '68000000-0000-4000-8000-000000000001'::uuid,
    'fixture_comprehensive_seed',
    '{"enabled":true,"contract":"dev-sandbox-comprehensive-v1","timezone":"Asia/Ho_Chi_Minh"}'::jsonb,
    'active', 'Comprehensive local/sandbox fixture marker.',
    '10000000-0000-4000-8000-000000000104'::uuid, now()
  ),
  (
    '68000000-0000-4000-8000-000000000002'::uuid,
    'fixture_comprehensive_seed_draft',
    '{"enabled":false,"contract":"dev-sandbox-comprehensive-v1","timezone":"Asia/Ho_Chi_Minh"}'::jsonb,
    'draft', 'Comprehensive local/sandbox fixture draft configuration.',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '2 minutes'
  ),
  (
    '68000000-0000-4000-8000-000000000003'::uuid,
    'fixture_comprehensive_seed_archived',
    '{"enabled":false,"contract":"dev-sandbox-comprehensive-v1","timezone":"Asia/Ho_Chi_Minh"}'::jsonb,
    'archived', 'Comprehensive local/sandbox fixture archived configuration.',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 minute'
  )
on conflict (id) do update
set config_value = excluded.config_value, status = excluded.status,
    reason = excluded.reason, created_by = excluded.created_by;

insert into public.report_exports (
  id, report_type, filters, status, reason, requested_by, completed_at
)
values
  ('69000000-0000-4000-8000-000000000001'::uuid, 'fixture', '{"range":"today"}'::jsonb, 'requested', 'Fixture requested export', '10000000-0000-4000-8000-000000000104'::uuid, null),
  ('69000000-0000-4000-8000-000000000002'::uuid, 'fixture', '{"range":"week"}'::jsonb, 'generating', 'Fixture generating export', '10000000-0000-4000-8000-000000000104'::uuid, null),
  ('69000000-0000-4000-8000-000000000003'::uuid, 'fixture', '{"range":"month"}'::jsonb, 'ready', 'Fixture ready export', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 day'),
  ('69000000-0000-4000-8000-000000000004'::uuid, 'fixture', '{"range":"year"}'::jsonb, 'failed', 'Fixture failed export', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 day')
on conflict (id) do update
set status = excluded.status, reason = excluded.reason, completed_at = excluded.completed_at;

insert into public.admin_reconciliation_runs (
  id, scope, status, reason, created_by, idempotency_key, metadata, completed_at
)
values
  ('6a000000-0000-4000-8000-000000000001'::uuid, 'payments', 'open', 'Fixture open reconciliation', '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-reconciliation-open-v1', '{"fixture":true}'::jsonb, null),
  ('6a000000-0000-4000-8000-000000000002'::uuid, 'payments', 'resolved', 'Fixture resolved reconciliation', '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-reconciliation-resolved-v1', '{"fixture":true}'::jsonb, now() - interval '1 day'),
  ('6a000000-0000-4000-8000-000000000003'::uuid, 'payments', 'failed', 'Fixture failed reconciliation', '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-reconciliation-failed-v1', '{"fixture":true}'::jsonb, now() - interval '1 day')
on conflict (idempotency_key) do update
set status = excluded.status, reason = excluded.reason,
    metadata = excluded.metadata, completed_at = excluded.completed_at;

insert into public.admin_reconciliation_discrepancies (
  id, run_id, target_type, target_id, severity, status, summary, metadata,
  reviewed_by, reviewed_at, review_reason
)
values
  ('6b000000-0000-4000-8000-000000000001'::uuid, '6a000000-0000-4000-8000-000000000001'::uuid, 'payment', '63000000-0000-4000-8000-000000000002', 'low', 'open', 'Fixture open discrepancy', '{"fixture":true}'::jsonb, null, null, null),
  ('6b000000-0000-4000-8000-000000000002'::uuid, '6a000000-0000-4000-8000-000000000001'::uuid, 'payment', '63000000-0000-4000-8000-000000000003', 'medium', 'needs_follow_up', 'Fixture follow-up discrepancy', '{"fixture":true}'::jsonb, '10000000-0000-4000-8000-000000000104'::uuid, now(), 'Fixture follow-up'),
  ('6b000000-0000-4000-8000-000000000003'::uuid, '6a000000-0000-4000-8000-000000000002'::uuid, 'payment', '63000000-0000-4000-8000-000000000004', 'high', 'resolved', 'Fixture resolved discrepancy', '{"fixture":true}'::jsonb, '10000000-0000-4000-8000-000000000104'::uuid, now(), 'Fixture resolved'),
  ('6b000000-0000-4000-8000-000000000004'::uuid, '6a000000-0000-4000-8000-000000000002'::uuid, 'conversion', '66000000-0000-4000-8000-000000000003', 'medium', 'adjusted', 'Fixture adjusted discrepancy', '{"fixture":true}'::jsonb, '10000000-0000-4000-8000-000000000104'::uuid, now(), 'Fixture adjusted'),
  ('6b000000-0000-4000-8000-000000000005'::uuid, '6a000000-0000-4000-8000-000000000003'::uuid, 'payment', '63000000-0000-4000-8000-000000000005', 'low', 'dismissed', 'Fixture dismissed discrepancy', '{"fixture":true}'::jsonb, '10000000-0000-4000-8000-000000000104'::uuid, now(), 'Fixture dismissed')
on conflict (id) do update
set status = excluded.status, summary = excluded.summary, metadata = excluded.metadata,
    reviewed_by = excluded.reviewed_by, reviewed_at = excluded.reviewed_at,
    review_reason = excluded.review_reason;

-- ---------------------------------------------------------------------------
-- Wellness / wallet / voucher data. Proof rows and Storage objects are
-- intentionally absent here: Seed-StorageFixtures.ps1 creates them through
-- the actual Auth + RPC + Storage path after the opt-in demo profile is set.
-- ---------------------------------------------------------------------------

insert into public.guest_schedule_reward_registrations (
  user_id, schedule_request_id, plan_start_date, plan_days, plan_item_count,
  manifest_hash, plan_item_ids, eligible_item_ids,
  first_registration_idempotency_key, registered_item_count
)
values (
  '11000000-0000-4000-8000-000000000003'::uuid,
  'fixture-guest-initial-schedule-request',
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  1, 10,
  repeat('a', 64),
  array[
    '45000000-0000-4000-8000-000000000001'::uuid,
    '45000000-0000-4000-8000-000000000002'::uuid,
    '45000000-0000-4000-8000-000000000003'::uuid,
    '45000000-0000-4000-8000-000000000004'::uuid,
    '45000000-0000-4000-8000-000000000005'::uuid,
    '45000000-0000-4000-8000-000000000006'::uuid,
    '45000000-0000-4000-8000-000000000007'::uuid,
    '45000000-0000-4000-8000-000000000008'::uuid,
    '45000000-0000-4000-8000-000000000009'::uuid,
    '45000000-0000-4000-8000-000000000010'::uuid
  ],
  array[
    '45000000-0000-4000-8000-000000000001'::uuid,
    '45000000-0000-4000-8000-000000000002'::uuid
  ],
  'fixture-guest-registration-v1', 2
)
on conflict (user_id) do update
set
  schedule_request_id = excluded.schedule_request_id,
  plan_start_date = excluded.plan_start_date,
  plan_days = excluded.plan_days,
  plan_item_count = excluded.plan_item_count,
  manifest_hash = excluded.manifest_hash,
  plan_item_ids = excluded.plan_item_ids,
  eligible_item_ids = excluded.eligible_item_ids,
  first_registration_idempotency_key = excluded.first_registration_idempotency_key,
  registered_item_count = excluded.registered_item_count,
  updated_at = now();

insert into public.member_schedule_reward_registrations (
  schedule_request_id, user_id, plan_start_date, plan_days, plan_item_count,
  manifest_hash, registration_idempotency_key, registered_item_count
)
values (
  'fixture-wellness-reward-request',
  '11000000-0000-4000-8000-000000000024'::uuid,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  1, 11, repeat('b', 64), 'fixture-wellness-registration-v1', 11
)
on conflict (schedule_request_id) do update
set
  user_id = excluded.user_id,
  plan_start_date = excluded.plan_start_date,
  plan_days = excluded.plan_days,
  plan_item_count = excluded.plan_item_count,
  manifest_hash = excluded.manifest_hash,
  registration_idempotency_key = excluded.registration_idempotency_key,
  registered_item_count = excluded.registered_item_count,
  updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000024'::uuid
    and subject_type = 'self'
  limit 1
), rows as (
  select *
  from (
    values
      ('70000000-0000-4000-8000-000000000001'::uuid, '44000000-0000-4000-8000-000000000001'::uuid, 0, 'eligible'),
      ('70000000-0000-4000-8000-000000000002'::uuid, '44000000-0000-4000-8000-000000000002'::uuid, 1, 'eligible'),
      ('70000000-0000-4000-8000-000000000003'::uuid, '44000000-0000-4000-8000-000000000003'::uuid, 2, 'void'),
      ('70000000-0000-4000-8000-000000000004'::uuid, '44000000-0000-4000-8000-000000000004'::uuid, 3, 'void'),
      ('70000000-0000-4000-8000-000000000005'::uuid, '44000000-0000-4000-8000-000000000005'::uuid, 4, 'void'),
      ('70000000-0000-4000-8000-000000000006'::uuid, '44000000-0000-4000-8000-000000000006'::uuid, 5, 'void'),
      ('70000000-0000-4000-8000-000000000007'::uuid, '44000000-0000-4000-8000-000000000007'::uuid, 6, 'void'),
      ('70000000-0000-4000-8000-000000000008'::uuid, '44000000-0000-4000-8000-000000000008'::uuid, 7, 'void'),
      ('70000000-0000-4000-8000-000000000009'::uuid, '44000000-0000-4000-8000-000000000009'::uuid, 8, 'void'),
      ('70000000-0000-4000-8000-000000000010'::uuid, '44000000-0000-4000-8000-000000000010'::uuid, 9, 'void'),
      ('70000000-0000-4000-8000-000000000011'::uuid, '44000000-0000-4000-8000-000000000011'::uuid, 10, 'eligible')
  ) as t(id, schedule_item_id, item_order, status)
)
insert into public.schedule_reward_eligibilities (
  id, user_id, subject_id, schedule_item_id, schedule_request_id, schedule_date,
  start_time, window_start, window_end, title_snapshot, category_snapshot,
  source_type_snapshot, source_id_snapshot, status, registration_idempotency_key
)
select
  r.id,
  '11000000-0000-4000-8000-000000000024'::uuid,
  s.id,
  r.schedule_item_id,
  'fixture-wellness-reward-request',
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  ((now() at time zone 'Asia/Ho_Chi_Minh') + make_interval(mins => r.item_order - 5))::time,
  case
    when r.item_order in (0, 1) then now() - interval '1 minute' + r.item_order * interval '30 seconds'
    when r.item_order = 10 then now() + interval '1 hour'
    else now() - interval '3 hours' + make_interval(mins => r.item_order)
  end,
  case
    when r.item_order in (0, 1) then now() + interval '29 minutes' + r.item_order * interval '30 seconds'
    when r.item_order = 10 then now() + interval '1 hour 30 minutes'
    else now() - interval '2 hours 30 minutes' + make_interval(mins => r.item_order)
  end,
  concat('Fixture wellness item ', r.item_order + 1),
  'wellness', 'fixture', 'fixture-wellness-manifest', r.status,
  'fixture-wellness-registration-v1'
from s cross join rows r
on conflict (id) do update
set
  schedule_item_id = excluded.schedule_item_id,
  schedule_request_id = excluded.schedule_request_id,
  schedule_date = excluded.schedule_date,
  start_time = excluded.start_time,
  window_start = excluded.window_start,
  window_end = excluded.window_end,
  title_snapshot = excluded.title_snapshot,
  status = excluded.status,
  registration_idempotency_key = excluded.registration_idempotency_key,
  updated_at = now();

-- These historical attempts belong to the separate Free-ready cohort, so the
-- Storage runner for dev.fixture.wellness never attempts to delete a fake
-- nonexistent static object path.
with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.schedule_reward_eligibilities (
  id, user_id, subject_id, schedule_item_id, schedule_request_id, schedule_date,
  start_time, window_start, window_end, title_snapshot, category_snapshot,
  source_type_snapshot, source_id_snapshot, status, registration_idempotency_key
)
select
  '70000000-0000-4000-8000-000000000012'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid,
  s.id,
  '45000000-0000-4000-8000-000000000001'::uuid,
  'fixture-free-ready-reward-request',
  (now() at time zone 'Asia/Ho_Chi_Minh')::date - 1,
  time '09:00', now() - interval '1 day', now() - interval '1 day' + interval '30 minutes',
  'Fixture historical attempt', 'wellness', 'fixture', 'fixture-free-ready',
  'void', 'fixture-free-ready-registration-v1'
from s
on conflict (id) do update
set status = excluded.status, updated_at = now();

insert into public.schedule_completion_attempts (
  id, eligibility_id, user_id, begin_idempotency_key, finalize_idempotency_key,
  undo_idempotency_key, object_path, status, began_at, finalized_at,
  rejection_code
)
values
  (
    '73000000-0000-4000-8000-000000000001'::uuid,
    '70000000-0000-4000-8000-000000000012'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'fixture-static-begun-v1', null, null,
    '11000000-0000-4000-8000-000000000002/fixture-static-begun.jpg',
    'begun', now() - interval '1 day', null, null
  ),
  (
    '73000000-0000-4000-8000-000000000002'::uuid,
    '70000000-0000-4000-8000-000000000012'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'fixture-static-rejected-v1', null, null,
    '11000000-0000-4000-8000-000000000002/fixture-static-rejected.jpg',
    'rejected', now() - interval '2 days', null, 'fixture_rejected'
  )
on conflict (id) do update
set
  status = excluded.status, object_path = excluded.object_path,
  began_at = excluded.began_at, rejection_code = excluded.rejection_code,
  updated_at = now();

-- This module deliberately omits proof rows and Storage object rows; the
-- runner creates immutable schedule evidence only through the real application
-- path. Historical wallet lifecycle rows below use the admin-refund source,
-- so they do not claim a proof-backed schedule completion before the runner.

insert into public.wellness_reward_wallets (
  user_id, pending_points, available_points, lifetime_earned_points,
  lifetime_spent_points, lifetime_refunded_points, lock_version
)
values (
  '11000000-0000-4000-8000-000000000024'::uuid,
  10, 20, 50, 10, 10, 1
)
on conflict (user_id) do update
set
  pending_points = excluded.pending_points,
  available_points = excluded.available_points,
  lifetime_earned_points = excluded.lifetime_earned_points,
  lifetime_spent_points = excluded.lifetime_spent_points,
  lifetime_refunded_points = excluded.lifetime_refunded_points,
  lock_version = excluded.lock_version,
  updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000024'::uuid
    and subject_type = 'self'
  limit 1
), program as (
  select id
  from public.system_config_versions
  where config_key = 'wellness_reward_program' and status = 'active'
  order by created_at desc
  limit 1
), rows as (
  select *
  from (
    values
      ('74000000-0000-4000-8000-000000000001'::uuid, '75000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'pending', 10, 10, now() + interval '1 day', now() + interval '180 days'),
      ('74000000-0000-4000-8000-000000000002'::uuid, '75000000-0000-4000-8000-000000000002'::uuid, null::uuid, 'available', 10, 10, now() - interval '2 days', now() + interval '180 days'),
      ('74000000-0000-4000-8000-000000000003'::uuid, '75000000-0000-4000-8000-000000000003'::uuid, null::uuid, 'spent', 10, 0, now() - interval '10 days', now() + interval '170 days'),
      ('74000000-0000-4000-8000-000000000004'::uuid, '75000000-0000-4000-8000-000000000004'::uuid, null::uuid, 'expired', 10, 10, now() - interval '200 days', now() - interval '1 day'),
      ('74000000-0000-4000-8000-000000000005'::uuid, '75000000-0000-4000-8000-000000000005'::uuid, null::uuid, 'reversed', 10, 0, now() - interval '5 days', now() + interval '175 days')
  ) as t(ledger_id, allocation_id, eligibility_id, allocation_status, original_points, remaining_points, available_at, expires_at)
)
insert into public.wellness_point_ledgers (
  id, user_id, subject_id, source_type, source_id, schedule_date, points_delta,
  program_code, idempotency_key, event_type, status, title, is_redeemable,
  available_at, expires_at, program_config_id, eligibility_id, metadata
)
select
  r.ledger_id,
  '11000000-0000-4000-8000-000000000024'::uuid,
  s.id,
  'admin_refund',
  r.allocation_id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  case when r.allocation_status = 'reversed' then -10 else 10 end,
  'wellness_schedule_fixture_v1',
  concat('fixture-wellness-ledger-', r.allocation_status),
  'fixture_reward', r.allocation_status, concat('Fixture ', r.allocation_status),
  true, r.available_at, r.expires_at, program.id, r.eligibility_id,
  '{"fixture":true}'::jsonb
from s cross join program cross join rows r
on conflict (user_id, idempotency_key) do nothing;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000024'::uuid
    and subject_type = 'self'
  limit 1
), program as (
  select id
  from public.system_config_versions
  where config_key = 'wellness_reward_program' and status = 'active'
  order by created_at desc
  limit 1
), rows as (
  select *
  from (
    values
      ('75000000-0000-4000-8000-000000000001'::uuid, '74000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'pending', 10, 10, now() + interval '1 day', now() + interval '180 days'),
      ('75000000-0000-4000-8000-000000000002'::uuid, '74000000-0000-4000-8000-000000000002'::uuid, null::uuid, 'available', 10, 10, now() - interval '2 days', now() + interval '180 days'),
      ('75000000-0000-4000-8000-000000000003'::uuid, '74000000-0000-4000-8000-000000000003'::uuid, null::uuid, 'spent', 10, 0, now() - interval '10 days', now() + interval '170 days'),
      ('75000000-0000-4000-8000-000000000004'::uuid, '74000000-0000-4000-8000-000000000004'::uuid, null::uuid, 'expired', 10, 10, now() - interval '200 days', now() - interval '1 day'),
      ('75000000-0000-4000-8000-000000000005'::uuid, '74000000-0000-4000-8000-000000000005'::uuid, null::uuid, 'reversed', 10, 0, now() - interval '5 days', now() + interval '175 days')
  ) as t(id, ledger_id, eligibility_id, allocation_status, original_points, remaining_points, available_at, expires_at)
)
insert into public.wellness_point_allocations (
  id, user_id, subject_id, ledger_id, eligibility_id, source_type, source_id,
  original_points, remaining_points, status, available_at, expires_at,
  program_config_id
)
select
  r.id,
  '11000000-0000-4000-8000-000000000024'::uuid,
  s.id,
  r.ledger_id, r.eligibility_id,
  'admin_refund',
  r.id,
  r.original_points, r.remaining_points, r.allocation_status,
  r.available_at, r.expires_at, program.id
from s cross join program cross join rows r
on conflict (id) do update
set
  remaining_points = excluded.remaining_points,
  status = excluded.status,
  available_at = excluded.available_at,
  expires_at = excluded.expires_at,
  updated_at = now();

insert into public.wellness_reward_offers (
  id, offer_code, title, description, provider_name, cost_points,
  eligible_plan_codes, available_from, available_until, voucher_expires_at,
  is_active, metadata, created_by, updated_by
)
values (
  '76000000-0000-4000-8000-000000000001'::uuid,
  'FIXTURE-REWARD', 'Fixture reward', 'Synthetic reward only',
  'Fixture Provider', 10, array['free','plus','family_plus']::text[],
  now() - interval '30 days', now() + interval '30 days',
  now() + interval '90 days', true,
  '{"fixture":true,"not_for_production":true}'::jsonb,
  '10000000-0000-4000-8000-000000000104'::uuid,
  '10000000-0000-4000-8000-000000000104'::uuid
)
on conflict (offer_code) do update
set
  title = excluded.title, description = excluded.description,
  cost_points = excluded.cost_points, available_from = excluded.available_from,
  available_until = excluded.available_until,
  voucher_expires_at = excluded.voucher_expires_at, is_active = excluded.is_active,
  metadata = excluded.metadata, updated_by = excluded.updated_by, updated_at = now();

insert into public.wellness_reward_codes (
  id, offer_id, code_value, code_hash, status, voucher_expires_at,
  assigned_user_id, assigned_redemption_id, issued_at, retired_at, imported_by,
  import_batch_key
)
values
  ('77000000-0000-4000-8000-000000000001'::uuid, '76000000-0000-4000-8000-000000000001'::uuid, 'FIXTURE-AVAILABLE-001', repeat('1', 64), 'available', now() + interval '90 days', null, null, null, null, '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-voucher-v1'),
  ('77000000-0000-4000-8000-000000000002'::uuid, '76000000-0000-4000-8000-000000000001'::uuid, 'FIXTURE-ISSUED-002', repeat('2', 64), 'issued', now() + interval '90 days', '11000000-0000-4000-8000-000000000024'::uuid, '78000000-0000-4000-8000-000000000001'::uuid, now() - interval '2 days', null, '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-voucher-v1'),
  ('77000000-0000-4000-8000-000000000003'::uuid, '76000000-0000-4000-8000-000000000001'::uuid, 'FIXTURE-RETIRED-003', repeat('3', 64), 'retired', now() - interval '1 day', null, null, null, now() - interval '1 day', '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-voucher-v1'),
  ('77000000-0000-4000-8000-000000000004'::uuid, '76000000-0000-4000-8000-000000000001'::uuid, 'FIXTURE-CANCELLED-004', repeat('4', 64), 'issued', now() + interval '90 days', '11000000-0000-4000-8000-000000000024'::uuid, '78000000-0000-4000-8000-000000000002'::uuid, now() - interval '4 days', null, '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-voucher-v1')
on conflict (code_hash) do update
set
  status = excluded.status, voucher_expires_at = excluded.voucher_expires_at,
  assigned_user_id = excluded.assigned_user_id,
  assigned_redemption_id = excluded.assigned_redemption_id,
  issued_at = excluded.issued_at, retired_at = excluded.retired_at,
  imported_by = excluded.imported_by, import_batch_key = excluded.import_batch_key;

insert into public.wellness_reward_redemptions (
  id, user_id, offer_id, reward_code_id, offer_title_snapshot,
  provider_name_snapshot, points_spent, status, voucher_expires_at,
  idempotency_key, issued_at, cancelled_at, cancelled_by, cancellation_reason,
  refund_allocation_id
)
values
  (
    '78000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000024'::uuid,
    '76000000-0000-4000-8000-000000000001'::uuid,
    '77000000-0000-4000-8000-000000000002'::uuid,
    'Fixture reward', 'Fixture Provider', 10, 'issued', now() + interval '90 days',
    'fixture-redemption-issued-v1', now() - interval '2 days', null, null, null, null
  ),
  (
    '78000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000024'::uuid,
    '76000000-0000-4000-8000-000000000001'::uuid,
    '77000000-0000-4000-8000-000000000004'::uuid,
    'Fixture reward', 'Fixture Provider', 10, 'cancelled', now() + interval '90 days',
    'fixture-redemption-cancelled-v1', now() - interval '4 days',
    now() - interval '3 days', '10000000-0000-4000-8000-000000000104'::uuid,
    'Fixture cancellation', '75000000-0000-4000-8000-000000000005'::uuid
  )
on conflict (id) do update
set
  status = excluded.status, cancelled_at = excluded.cancelled_at,
  cancelled_by = excluded.cancelled_by, cancellation_reason = excluded.cancellation_reason,
  refund_allocation_id = excluded.refund_allocation_id, updated_at = now();

insert into public.wellness_redemption_allocation_usages (
  redemption_id, allocation_id, points_used
)
values
  ('78000000-0000-4000-8000-000000000001'::uuid, '75000000-0000-4000-8000-000000000003'::uuid, 10),
  ('78000000-0000-4000-8000-000000000002'::uuid, '75000000-0000-4000-8000-000000000005'::uuid, 10)
on conflict (redemption_id, allocation_id) do update
set points_used = excluded.points_used;

-- ---------------------------------------------------------------------------
-- Nabi notification catalog, occurrence and event lifecycles.
-- ---------------------------------------------------------------------------

insert into public.nabi_notification_definitions (
  id, notification_id, content_version, category, priority, policy_key,
  primary_action_key, secondary_action_key, allowed_channels, title_template,
  body_template, config, effective_from, effective_until, status, reason,
  created_by
)
values
  (
    '80000000-0000-4000-8000-000000000001'::uuid,
    'fixture-nabi-draft', 1, 'contextual', 100, 'partial_day',
    'today_tasks', null, array['in_app']::text[], 'Fixture draft',
    'Synthetic Nabi draft', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'draft',
    'Fixture draft definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000002'::uuid,
    'fixture-nabi-active', 1, 'reward', 200, 'reward_ready',
    'reward_box', 'today_tasks', array['in_app']::text[], 'Fixture active',
    'Synthetic Nabi active', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture active definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000003'::uuid,
    'fixture-nabi-archived', 1, 'retention', 50, 'return_72h',
    'dashboard_today', null, array['in_app']::text[], 'Fixture archived',
    'Synthetic Nabi archived', '{"fixture":true}'::jsonb,
    now() - interval '31 days', now() - interval '1 day', 'archived',
    'Fixture archived definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000004'::uuid,
    'fixture-nabi-milestone', 1, 'milestone', 300, 'milestone_reached',
    'dashboard_today', null, array['in_app']::text[], 'Fixture milestone',
    'Synthetic Nabi milestone', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture milestone definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000005'::uuid,
    'fixture-nabi-subscription', 1, 'subscription', 300, 'subscription_due',
    'membership', null, array['in_app']::text[], 'Fixture subscription',
    'Synthetic Nabi subscription', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture subscription definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000006'::uuid,
    'fixture-nabi-report', 1, 'report', 300, 'report_ready',
    'health_report', null, array['in_app']::text[], 'Fixture report',
    'Synthetic Nabi report', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture report definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000007'::uuid,
    'fixture-nabi-care', 1, 'care', 300, 'care_reminder',
    'today_tasks', null, array['in_app']::text[], 'Fixture care',
    'Synthetic Nabi care', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture care definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000008'::uuid,
    'fixture-nabi-profile', 1, 'profile', 300, 'profile_incomplete',
    'profile', null, array['in_app']::text[], 'Fixture profile',
    'Synthetic Nabi profile', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture profile definition', '10000000-0000-4000-8000-000000000104'::uuid
  )
on conflict (notification_id, content_version) do update
set
  category = excluded.category, priority = excluded.priority,
  policy_key = excluded.policy_key, primary_action_key = excluded.primary_action_key,
  secondary_action_key = excluded.secondary_action_key,
  allowed_channels = excluded.allowed_channels, title_template = excluded.title_template,
  body_template = excluded.body_template, config = excluded.config,
  effective_from = excluded.effective_from, effective_until = excluded.effective_until,
  status = excluded.status, reason = excluded.reason, created_by = excluded.created_by;

insert into public.nabi_notification_user_states (
  id, user_id, notification_id, content_version, source_event_id, status,
  eligible_at, presented_at, opened_at, deferred_until, actioned_at,
  converted_at, expires_at, display_count, dismiss_count, primary_click_count,
  secondary_click_count, last_session_id, last_screen_key, membership_plan,
  billing_cycle, safe_metadata
)
values
  ('81000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-eligible', 'eligible', now() - interval '10 minutes', null, null, null, null, null, now() + interval '1 day', 0, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-queued', 'queued', now() - interval '20 minutes', null, null, null, null, null, now() + interval '1 day', 0, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000003'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-presented', 'presented', now() - interval '30 minutes', now() - interval '20 minutes', null, null, null, null, now() + interval '1 day', 1, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000004'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-collapsed', 'collapsed', now() - interval '40 minutes', now() - interval '35 minutes', null, null, null, null, now() + interval '1 day', 1, 1, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000005'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-opened', 'opened', now() - interval '50 minutes', now() - interval '45 minutes', now() - interval '44 minutes', null, null, null, now() + interval '1 day', 1, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000006'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-deferred', 'deferred', now() - interval '60 minutes', now() - interval '55 minutes', null, now() + interval '1 hour', null, null, now() + interval '1 day', 1, 1, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000007'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-actioned', 'actioned', now() - interval '70 minutes', now() - interval '65 minutes', now() - interval '64 minutes', null, now() - interval '63 minutes', null, now() + interval '1 day', 1, 0, 1, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000008'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-converted', 'converted', now() - interval '80 minutes', now() - interval '75 minutes', now() - interval '74 minutes', null, now() - interval '73 minutes', now() - interval '72 minutes', now() + interval '1 day', 1, 0, 1, 0, 'fixture-session', 'membership', 'plus', 'monthly', '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-expired', 'expired', now() - interval '2 days', null, null, null, null, null, now() - interval '1 day', 0, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000010'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-cancelled', 'cancelled', now() - interval '3 hours', null, null, null, null, null, now() + interval '1 day', 0, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000011'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-failed', 'failed', now() - interval '4 hours', now() - interval '3 hours', null, null, null, null, now() + interval '1 day', 1, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true,"result":"fixture_failure"}'::jsonb)
on conflict (user_id, notification_id, source_event_id, content_version) do update
set
  status = excluded.status, eligible_at = excluded.eligible_at,
  presented_at = excluded.presented_at, opened_at = excluded.opened_at,
  deferred_until = excluded.deferred_until, actioned_at = excluded.actioned_at,
  converted_at = excluded.converted_at, expires_at = excluded.expires_at,
  display_count = excluded.display_count, dismiss_count = excluded.dismiss_count,
  primary_click_count = excluded.primary_click_count,
  secondary_click_count = excluded.secondary_click_count,
  last_session_id = excluded.last_session_id, last_screen_key = excluded.last_screen_key,
  membership_plan = excluded.membership_plan, billing_cycle = excluded.billing_cycle,
  safe_metadata = excluded.safe_metadata, updated_at = now();

insert into public.nabi_notification_preferences (
  user_id, proactive_in_app_enabled, push_enabled, analytics_upload_enabled,
  quiet_start_minutes, quiet_end_minutes
)
values (
  '11000000-0000-4000-8000-000000000002'::uuid,
  true, false, true, 1320, 420
)
on conflict (user_id) do update
set
  proactive_in_app_enabled = excluded.proactive_in_app_enabled,
  push_enabled = excluded.push_enabled,
  analytics_upload_enabled = excluded.analytics_upload_enabled,
  quiet_start_minutes = excluded.quiet_start_minutes,
  quiet_end_minutes = excluded.quiet_end_minutes,
  updated_at = now();

insert into public.nabi_notification_events (
  id, user_id, occurrence_id, notification_id, event_name, session_id,
  screen_key, app_version, result_code, safe_metadata, created_at
)
values
  ('82000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000001'::uuid, 'fixture-nabi-active', 'nabi_notification_eligible', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '10 minutes'),
  ('82000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000003'::uuid, 'fixture-nabi-active', 'nabi_notification_shown', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '20 minutes'),
  ('82000000-0000-4000-8000-000000000003'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000005'::uuid, 'fixture-nabi-active', 'nabi_notification_opened', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '44 minutes'),
  ('82000000-0000-4000-8000-000000000004'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000004'::uuid, 'fixture-nabi-active', 'nabi_notification_dismissed', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '35 minutes'),
  ('82000000-0000-4000-8000-000000000005'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000007'::uuid, 'fixture-nabi-active', 'nabi_notification_primary_clicked', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '63 minutes'),
  ('82000000-0000-4000-8000-000000000006'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000007'::uuid, 'fixture-nabi-active', 'nabi_notification_secondary_clicked', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '63 minutes'),
  ('82000000-0000-4000-8000-000000000007'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000008'::uuid, 'fixture-nabi-active', 'nabi_upgrade_page_viewed', 'fixture-session', 'membership', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '73 minutes'),
  ('82000000-0000-4000-8000-000000000008'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000008'::uuid, 'fixture-nabi-active', 'nabi_checkout_started', 'fixture-session', 'membership', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '73 minutes'),
  ('82000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000008'::uuid, 'fixture-nabi-active', 'nabi_conversion_completed', 'fixture-session', 'membership', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '72 minutes'),
  ('82000000-0000-4000-8000-000000000010'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000011'::uuid, 'fixture-nabi-active', 'nabi_notification_failed', 'fixture-session', 'home', 'fixture', 'fixture_failure', '{"fixture":true}'::jsonb, now() - interval '3 hours')
on conflict (id) do update
set
  occurrence_id = excluded.occurrence_id, notification_id = excluded.notification_id,
  event_name = excluded.event_name, session_id = excluded.session_id,
  screen_key = excluded.screen_key, app_version = excluded.app_version,
  result_code = excluded.result_code, safe_metadata = excluded.safe_metadata,
  created_at = excluded.created_at;

-- ---------------------------------------------------------------------------
-- Private Sale proof bucket contract. Object rows remain Storage API-owned.
-- ---------------------------------------------------------------------------

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'sale-payout-proofs',
  'sale-payout-proofs',
  false,
  5242880,
  array['image/jpeg']::text[]
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists sale_payout_proofs_storage_select_admin on storage.objects;
create policy sale_payout_proofs_storage_select_admin
  on storage.objects for select to authenticated
  using (
    bucket_id = 'sale-payout-proofs'
    and public.admin_has_permission('sales.write')
  );

drop policy if exists sale_payout_proofs_storage_insert_admin on storage.objects;
create policy sale_payout_proofs_storage_insert_admin
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'sale-payout-proofs'
    and public.admin_has_permission('sales.write')
    and split_part(name, '/', 1) = 'sale-point-conversions'
    and nullif(split_part(name, '/', 2), '') is not null
  );

-- Paths are unique and evidence is immutable. Do not grant authenticated
-- UPDATE/DELETE access; the service-role cleanup in the local runner is
-- intentionally scoped to fixture prefixes only.
drop policy if exists sale_payout_proofs_storage_update_admin on storage.objects;
drop policy if exists sale_payout_proofs_storage_delete_admin on storage.objects;

-- Rollback-only smoke performs the executable negative assertions under RLS.
-- These static guards stop an accidental fixture edit that would create an
-- invalid referral cycle, exceed the FamilyPlus limit, or pay a second level.
do $$
begin
  if exists (
    select 1
    from public.referral_relationships r
    where r.referrer_user_id = r.referred_user_id
       or exists (
         select 1
         from public.referral_relationships reverse_r
         where reverse_r.referrer_user_id = r.referred_user_id
           and reverse_r.referred_user_id = r.referrer_user_id
           and reverse_r.status = 'active'
       )
  ) then
    raise exception 'FIXTURE_REFERRAL_FRAUD_ASSERTION_FAILED';
  end if;

  if exists (
    select 1
    from public.family_members fm
    join public.family_groups fg on fg.id = fm.family_group_id
    where fm.status = 'active'
    group by fg.id
    having count(*) > 5
  ) then
    raise exception 'FIXTURE_FAMILY_LIMIT_ASSERTION_FAILED';
  end if;

  if exists (
    select 1
    from public.commission_records cr
    join public.payment_events pe on pe.id = cr.payment_event_id
    where pe.id = '63000000-0000-4000-8000-000000000001'::uuid
      and cr.receiver_user_id <> '11000000-0000-4000-8000-000000000019'::uuid
  ) then
    raise exception 'FIXTURE_DIRECT_ONLY_ASSERTION_FAILED';
  end if;
end
$$;
-- END 19-dev-sandbox-comprehensive-seed.sql

-- Fixture 19 copy complete; commit the destructive local/sandbox rebuild.
commit;

-- END 18-nabi-companion-notifications.sql

-- BEGIN 21-nutrition-profile-meal-catalog-v17.sql
-- NanoBio V17: nutrition profile, recipe provenance and safe catalog cache.
-- Run after 16-wellness-rewards.sql and before development fixtures.

begin;

alter table public.meal_catalog
  add column if not exists health_topic_code text,
  add column if not exists health_topic_name text,
  add column if not exists health_topic_description text,
  add column if not exists chapter_number integer,
  add column if not exists chapter_name text,
  add column if not exists ingredients_json jsonb not null default '[]'::jsonb,
  add column if not exists cooking_steps_json jsonb not null default '[]'::jsonb,
  add column if not exists benefits text,
  add column if not exists serving_size text,
  add column if not exists allergen_tags_json jsonb not null default '[]'::jsonb,
  add column if not exists avoid_condition_tags_json jsonb not null default '[]'::jsonb,
  add column if not exists nutrition_status text not null default 'approved',
  add column if not exists constraint_metadata_status text not null default 'approved',
  add column if not exists metadata_status text not null default 'approved',
  add column if not exists is_plan_eligible boolean not null default true,
  add column if not exists source_name text,
  add column if not exists source_page integer,
  add column if not exists source_chapter text,
  add column if not exists source_topic text,
  add column if not exists source_recipe_order integer,
  add column if not exists source_hash text,
  add column if not exists version integer not null default 1;

create index if not exists idx_meal_catalog_topic_active
  on public.meal_catalog(health_topic_code, is_active);
create index if not exists idx_meal_catalog_plan_pool
  on public.meal_catalog(meal_type, is_active, is_plan_eligible, metadata_status);
create index if not exists idx_meal_catalog_source_version
  on public.meal_catalog(source_hash, version);

alter table public.meal_plans
  add column if not exists catalog_code text,
  add column if not exists serving_size text,
  add column if not exists health_topic_code text,
  add column if not exists health_topic_name text,
  add column if not exists ingredients_json jsonb not null default '[]'::jsonb,
  add column if not exists cooking_steps_json jsonb not null default '[]'::jsonb,
  add column if not exists benefits text,
  add column if not exists allergen_tags_json jsonb not null default '[]'::jsonb,
  add column if not exists avoid_condition_tags_json jsonb not null default '[]'::jsonb,
  add column if not exists source_name text,
  add column if not exists source_hash text,
  add column if not exists source_page integer,
  add column if not exists snapshot_schema_version integer not null default 1,
  add column if not exists replacement_count integer not null default 0;

create table if not exists public.nutrition_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  birth_date date,
  waist_cm double precision,
  current_status text,
  average_sleep_hours double precision,
  smoking_status text not null default 'not_provided',
  smoking_amount_note text,
  alcohol_frequency text not null default 'not_provided',
  coffee_frequency text not null default 'not_provided',
  target_weight_kg double precision,
  target_weight_source text,
  water_restriction boolean not null default false,
  water_restriction_note text,
  nocturia_level text not null default 'not_provided',
  schema_version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(subject_id)
);

create table if not exists public.health_symptoms (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  symptom_type text not null, body_location text, severity_level integer, started_at date,
  trigger_note text, impact_note text, note text, is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.medication_records (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  name text not null, product_type text not null default 'medication', usage_schedule text,
  prescriber_confirmed boolean not null default false, note text, is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.food_restrictions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  restriction_type text not null, item_name text not null, severity_level integer, note text,
  is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.lab_results (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  test_code text, test_name text not null, value_text text not null, unit text, measured_at date,
  reference_note text, note text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.nutrition_goals (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  goal_code text not null, goal_name text not null, priority integer not null check(priority between 1 and 3),
  target_period text, target_date date, is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(subject_id, priority)
);
create table if not exists public.meal_schedule_preferences (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  meal_type text not null, start_time time, end_time time, portion_note text, target_calories integer, note text,
  is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(subject_id, meal_type)
);
create table if not exists public.nutrition_preference_rules (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  subject_id uuid not null default public.default_self_subject_id() references public.health_subjects(id) on delete cascade,
  rule_type text not null, item_code text, item_name text not null, preference_level text not null, note text,
  schema_version integer not null default 1, is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create index if not exists idx_health_symptoms_owner on public.health_symptoms(user_id, is_active);
create index if not exists idx_medication_records_owner on public.medication_records(user_id, is_active);
create index if not exists idx_food_restrictions_owner on public.food_restrictions(user_id, is_active);
create index if not exists idx_lab_results_owner on public.lab_results(user_id, measured_at desc);
create index if not exists idx_nutrition_goals_owner on public.nutrition_goals(user_id, priority);
create index if not exists idx_nutrition_rules_owner on public.nutrition_preference_rules(user_id, is_active);

alter table public.nutrition_profiles enable row level security;
alter table public.health_symptoms enable row level security;
alter table public.medication_records enable row level security;
alter table public.food_restrictions enable row level security;
alter table public.lab_results enable row level security;
alter table public.nutrition_goals enable row level security;
alter table public.meal_schedule_preferences enable row level security;
alter table public.nutrition_preference_rules enable row level security;

-- Direct writes remain blocked; snapshot RPC overwrites user_id/subject_id.
do $$
declare v_table text;
begin
  foreach v_table in array array[
    'nutrition_profiles','health_symptoms','medication_records','food_restrictions',
    'lab_results','nutrition_goals','meal_schedule_preferences','nutrition_preference_rules'
  ] loop
    execute format('drop policy if exists %I on public.%I', v_table || '_read_own', v_table);
    execute format(
      'create policy %I on public.%I for select to authenticated using (user_id = auth.uid())',
      v_table || '_read_own', v_table
    );
    execute format('revoke insert, update, delete on public.%I from anon, authenticated', v_table);
    execute format('grant select on public.%I to authenticated', v_table);
  end loop;
end $$;

-- Catalog is public-safe metadata only. No user health data and no client writes.
alter table public.meal_catalog enable row level security;
drop policy if exists meal_catalog_read_active_safe on public.meal_catalog;
create policy meal_catalog_read_active_safe on public.meal_catalog
  for select to anon, authenticated using (is_active = true);
grant select on public.meal_catalog to anon, authenticated;
revoke insert, update, delete on public.meal_catalog from anon, authenticated;

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
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations',
    'health_symptoms',
    'medication_records',
    'food_restrictions',
    'lab_results',
    'nutrition_goals',
    'meal_schedule_preferences',
    'nutrition_preference_rules'
  ];
  v_singleton_tables text[] := array['health_profiles', 'lifestyle_habits', 'nutrition_profiles'];
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
    elsif v_table = 'nutrition_profiles' then
      v_allowed_columns := array[
        'id', 'birth_date', 'waist_cm', 'current_status',
        'average_sleep_hours', 'smoking_status', 'smoking_amount_note',
        'alcohol_frequency', 'coffee_frequency', 'target_weight_kg',
        'target_weight_source', 'water_restriction',
        'water_restriction_note', 'nocturia_level', 'schema_version'
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
        'start_time', 'end_time', 'cooking_instructions', 'catalog_code',
        'serving_size', 'health_topic_code', 'health_topic_name',
        'ingredients_json', 'cooking_steps_json', 'benefits',
        'allergen_tags_json', 'avoid_condition_tags_json', 'source_name',
        'source_hash', 'source_page', 'snapshot_schema_version', 'replacement_count',
        'is_completed', 'ai_generated'
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
    elsif v_table = 'health_symptoms' then
      v_allowed_columns := array[
        'id', 'symptom_type', 'body_location', 'severity_level', 'started_at',
        'trigger_note', 'impact_note', 'note', 'is_active'
      ];
    elsif v_table = 'medication_records' then
      v_allowed_columns := array[
        'id', 'name', 'product_type', 'usage_schedule',
        'prescriber_confirmed', 'note', 'is_active'
      ];
    elsif v_table = 'food_restrictions' then
      v_allowed_columns := array[
        'id', 'restriction_type', 'item_name', 'severity_level', 'note',
        'is_active'
      ];
    elsif v_table = 'lab_results' then
      v_allowed_columns := array[
        'id', 'test_code', 'test_name', 'value_text', 'unit', 'measured_at',
        'reference_note', 'note'
      ];
    elsif v_table = 'nutrition_goals' then
      v_allowed_columns := array[
        'id', 'goal_code', 'goal_name', 'priority', 'target_period',
        'target_date', 'is_active'
      ];
    elsif v_table = 'meal_schedule_preferences' then
      v_allowed_columns := array[
        'id', 'meal_type', 'start_time', 'end_time', 'portion_note',
        'target_calories', 'note', 'is_active'
      ];
    elsif v_table = 'nutrition_preference_rules' then
      v_allowed_columns := array[
        'id', 'rule_type', 'item_code', 'item_name', 'preference_level',
        'note', 'schema_version', 'is_active'
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

revoke all on function public.sync_my_mobile_snapshot(jsonb) from public, anon;
grant execute on function public.sync_my_mobile_snapshot(jsonb) to authenticated;

commit;
-- END 21-nutrition-profile-meal-catalog-v17.sql

-- BEGIN 22-meal-catalog-source-seed.sql
-- Generated from assets/data/meal_catalog_v1.json. Do not hand-edit.
begin;
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_thieu_mau_01_canh_thit_bo_rau_cai_bo_xoi','unclassified','CANH THỊT BÒ RAU CẢI BÓ XÔI','Thiếu máu là tình trạng cơ thể không sản xuất đủ hồng cầu hoặc hemoglobin, dẫn đến các triệu chứng như mệt mỏi, da xanh xao, hoa mắt, chóng mặt. Chế độ ăn giàu sắt và vitamin C có thể giúp cải thiện tình trạng này.','Thịt bò thái mỏng, ướp với chút muối và tiêu.
Xào hành tím với dầu, cho thịt bò vào xào nhanh.
Thêm nước, đun sôi rồi cho cải bó xôi vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c01_thieu_mau','Thiếu máu','Thiếu máu là tình trạng cơ thể không sản xuất đủ hồng cầu hoặc hemoglobin, dẫn đến các triệu chứng như mệt mỏi, da xanh xao, hoa mắt, chóng mặt. Chế độ ăn giàu sắt và vitamin C có thể giúp cải thiện tình trạng này.',1,'Tim Mạch Và Mạch Máu Não','["200g thịt bò", "200g rau cải bó xôi", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Thịt bò thái mỏng, ướp với chút muối và tiêu.", "Xào hành tím với dầu, cho thịt bò vào xào nhanh.", "Thêm nước, đun sôi rồi cho cải bó xôi vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Thịt bò giàu sắt heme dễ hấp thụ, cải bó xôi giàu vitamin C giúp cơ thể hấp thụ sắt tốt hơn.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',6,'Chương 1: Tim Mạch Và Mạch Máu Não','Thiếu máu',1,'f973f9d388e032d768797ea217e8d83fa678aa1d21d43e84eb0ff5eae50ff44c',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_thieu_mau_02_sinh_to_chuoi_va_hat_dieu','unclassified','Sinh tố chuối và hạt điều','Thiếu máu là tình trạng cơ thể không sản xuất đủ hồng cầu hoặc hemoglobin, dẫn đến các triệu chứng như mệt mỏi, da xanh xao, hoa mắt, chóng mặt. Chế độ ăn giàu sắt và vitamin C có thể giúp cải thiện tình trạng này.','Chuối bóc vỏ, cắt nhỏ.
Hạt điều ngâm nước 10 phút, sau đó cho vào máy xay cùng chuối, sữa hạnh nhân và mật ong.
Xay nhuyễn và thưởng thức.',0,0,0,0,0,0,'c01_thieu_mau','Thiếu máu','Thiếu máu là tình trạng cơ thể không sản xuất đủ hồng cầu hoặc hemoglobin, dẫn đến các triệu chứng như mệt mỏi, da xanh xao, hoa mắt, chóng mặt. Chế độ ăn giàu sắt và vitamin C có thể giúp cải thiện tình trạng này.',1,'Tim Mạch Và Mạch Máu Não','["1 quả chuối chín", "30g hạt điều", "200ml sữa hạnh nhân", "1 thìa mật ong"]'::jsonb,'["Chuối bóc vỏ, cắt nhỏ.", "Hạt điều ngâm nước 10 phút, sau đó cho vào máy xay cùng chuối, sữa hạnh nhân và mật ong.", "Xay nhuyễn và thưởng thức."]'::jsonb,'Tăng cường hấp thu sắt tự nhiên, Giảm mệt mỏi, chóng mặt, uể oải do thiếu máu gây ra, Hỗ trợ quá trình tạo máu.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',6,'Chương 1: Tim Mạch Và Mạch Máu Não','Thiếu máu',2,'9859286f5f880f3c86f9e08516c45141c6d92f66598a9ad575cbfad967218c25',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_thieu_mau_03_chao_hat_sen_dau_xanh','unclassified','CHÁO HẠT SEN ĐẬU XANH','Thiếu máu là tình trạng cơ thể không sản xuất đủ hồng cầu hoặc hemoglobin, dẫn đến các triệu chứng như mệt mỏi, da xanh xao, hoa mắt, chóng mặt. Chế độ ăn giàu sắt và vitamin C có thể giúp cải thiện tình trạng này.','Hạt sen và đậu xanh ngâm nước 2 tiếng.
Cho hạt sen, đậu xanh và gạo vào nồi, nấu đến khi chín nhừ.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c01_thieu_mau','Thiếu máu','Thiếu máu là tình trạng cơ thể không sản xuất đủ hồng cầu hoặc hemoglobin, dẫn đến các triệu chứng như mệt mỏi, da xanh xao, hoa mắt, chóng mặt. Chế độ ăn giàu sắt và vitamin C có thể giúp cải thiện tình trạng này.',1,'Tim Mạch Và Mạch Máu Não','["100g hạt sen", "100g đậu xanh", "50g gạo tẻ", "Gia vị: muối, đường"]'::jsonb,'["Hạt sen và đậu xanh ngâm nước 2 tiếng.", "Cho hạt sen, đậu xanh và gạo vào nồi, nấu đến khi chín nhừ.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Hạt sen và đậu xanh giúp bổ máu, tăng cường sức khỏe, giảm mệt mỏi do thiếu máu.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',6,'Chương 1: Tim Mạch Và Mạch Máu Não','Thiếu máu',3,'7f8b8f53955e5f28794b7a849ff194027f966f0f81b1887b64ad30d80a2da10b',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_benh_mach_vanh_01_canh_nam_dong_co_va_rau_ngot','unclassified','CANH NẤM ĐÔNG CÔ VÀ RAU NGÓT','Bệnh mạch vành là tình trạng động mạch vành bị tắc nghẽn do mảng bám, dẫn đến giảm lưu thông máu đến tim. Chế độ ăn giàu chất xơ và chất chống oxy hóa có thể giúp cải thiện tình trạng này.','Nấm đông cô ngâm nở, rửa sạch.
Rau ngót nhặt sạch, rửa kỹ.
Phi hành tím với dầu, cho nấm vào xào sơ.
Thêm nước, đun sôi rồi cho rau ngót vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c01_benh_mach_vanh','Bệnh mạch vành','Bệnh mạch vành là tình trạng động mạch vành bị tắc nghẽn do mảng bám, dẫn đến giảm lưu thông máu đến tim. Chế độ ăn giàu chất xơ và chất chống oxy hóa có thể giúp cải thiện tình trạng này.',1,'Tim Mạch Và Mạch Máu Não','["200g nấm đông cô", "100g rau ngót", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Nấm đông cô ngâm nở, rửa sạch.", "Rau ngót nhặt sạch, rửa kỹ.", "Phi hành tím với dầu, cho nấm vào xào sơ.", "Thêm nước, đun sôi rồi cho rau ngót vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Nấm đông cô giàu chất chống oxy hóa giúp bảo vệ tim mạch, rau ngót hỗ trợ lưu thông máu và thanh lọc cơ thể',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',7,'Chương 1: Tim Mạch Và Mạch Máu Não','Bệnh mạch vành',1,'6e0b5ab892edb7a86d0a9bc9cfb716c5a448e12312572441740af50fee1fc4c1',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_benh_mach_vanh_02_sinh_to_can_tay_va_tao','unclassified','SINH TỐ CẦN TÂY VÀ TÁO','Bệnh mạch vành là tình trạng động mạch vành bị tắc nghẽn do mảng bám, dẫn đến giảm lưu thông máu đến tim. Chế độ ăn giàu chất xơ và chất chống oxy hóa có thể giúp cải thiện tình trạng này.','Cần tây rửa sạch, cắt khúc.
Táo rửa sạch, cắt nhỏ.
Cho cần tây, táo, nước và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c01_benh_mach_vanh','Bệnh mạch vành','Bệnh mạch vành là tình trạng động mạch vành bị tắc nghẽn do mảng bám, dẫn đến giảm lưu thông máu đến tim. Chế độ ăn giàu chất xơ và chất chống oxy hóa có thể giúp cải thiện tình trạng này.',1,'Tim Mạch Và Mạch Máu Não','["2 nhánh cần tây", "1 quả táo", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Cần tây rửa sạch, cắt khúc.", "Táo rửa sạch, cắt nhỏ.", "Cho cần tây, táo, nước và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Cần tây và táo giàu chất xơ và kali, giúp giảm huyết áp và cải thiện sức khỏe tim mạch.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',7,'Chương 1: Tim Mạch Và Mạch Máu Não','Bệnh mạch vành',2,'20dd9f4c5acdcab27c56edaceded9e6ddb9bef03ffcf3b48812d9bc3d57ec9d2',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_benh_mach_vanh_03_tra_hoa_cuc_mat_ong','unclassified','TRÀ HOA CÚC MẬT ONG','Bệnh mạch vành là tình trạng động mạch vành bị tắc nghẽn do mảng bám, dẫn đến giảm lưu thông máu đến tim. Chế độ ăn giàu chất xơ và chất chống oxy hóa có thể giúp cải thiện tình trạng này.','Cho hoa cúc vào nước sôi, hãm khoảng 5 phút
Lọc bỏ bã, thêm mật ong khuấy đều.',0,0,0,0,0,0,'c01_benh_mach_vanh','Bệnh mạch vành','Bệnh mạch vành là tình trạng động mạch vành bị tắc nghẽn do mảng bám, dẫn đến giảm lưu thông máu đến tim. Chế độ ăn giàu chất xơ và chất chống oxy hóa có thể giúp cải thiện tình trạng này.',1,'Tim Mạch Và Mạch Máu Não','["5 bông hoa cúc khô", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Cho hoa cúc vào nước sôi, hãm khoảng 5 phút", "Lọc bỏ bã, thêm mật ong khuấy đều."]'::jsonb,'Hoa cúc giúp thanh nhiệt, mật ong kháng viêm, hỗ trợ hệ tim mạch.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',7,'Chương 1: Tim Mạch Và Mạch Máu Não','Bệnh mạch vành',3,'324305c71ec39bfedd53c7e9fdab831a0a66b94095e311cfe2f51f9cee150298',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_roi_loan_nhip_tim_01_sinh_to_chuoi_va_hat_dieu','unclassified','SINH TỐ CHUỐI VÀ HẠT ĐIỀU','Rối loạn nhịp tim là tình trạng nhịp tim không đều, có thể quá nhanh, quá chậm hoặc không đều. Chế độ ăn giàu kali và magie có thể giúp ổn định nhịp tim.','Chuối bóc vỏ, cắt nhỏ.
Cho chuối, hạt điều, sữa hạnh nhân và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c01_roi_loan_nhip_tim','Rối loạn nhịp tim','Rối loạn nhịp tim là tình trạng nhịp tim không đều, có thể quá nhanh, quá chậm hoặc không đều. Chế độ ăn giàu kali và magie có thể giúp ổn định nhịp tim.',1,'Tim Mạch Và Mạch Máu Não','["1 quả chuối", "50g hạt điều", "200ml sữa hạnh nhân", "1 thìa mật ong"]'::jsonb,'["Chuối bóc vỏ, cắt nhỏ.", "Cho chuối, hạt điều, sữa hạnh nhân và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Chuối và hạt điều giàu kali và magie, giúp ổn định nhịp tim.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',8,'Chương 1: Tim Mạch Và Mạch Máu Não','Rối loạn nhịp tim',1,'3054559f38b555baa83b4b718999a9a111319f615b2fcdec65451c540e4f42d5',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_roi_loan_nhip_tim_02_canh_du_du_ham_suon_non','unclassified','CANH ĐU ĐỦ HẦM SƯỜN NON','Rối loạn nhịp tim là tình trạng nhịp tim không đều, có thể quá nhanh, quá chậm hoặc không đều. Chế độ ăn giàu kali và magie có thể giúp ổn định nhịp tim.','Sườn non rửa sạch, chần qua nước sôi.
Đu đủ gọt vỏ, bỏ hạt, cắt khúc.
Phi hành tím với dầu, cho sườn vào xào sơ.
Thêm nước, đun sôi rồi cho đu đủ vào hầm cho mềm
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c01_roi_loan_nhip_tim','Rối loạn nhịp tim','Rối loạn nhịp tim là tình trạng nhịp tim không đều, có thể quá nhanh, quá chậm hoặc không đều. Chế độ ăn giàu kali và magie có thể giúp ổn định nhịp tim.',1,'Tim Mạch Và Mạch Máu Não','["200g đu đủ xanh", "300g sườn non", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Sườn non rửa sạch, chần qua nước sôi.", "Đu đủ gọt vỏ, bỏ hạt, cắt khúc.", "Phi hành tím với dầu, cho sườn vào xào sơ.", "Thêm nước, đun sôi rồi cho đu đủ vào hầm cho mềm", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Đu đủ chứa kali hỗ trợ ổn định nhịp tim, sườn non cung cấp collagen giúp bảo vệ mạch máu..',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',8,'Chương 1: Tim Mạch Và Mạch Máu Não','Rối loạn nhịp tim',2,'9737b1a0e34c9a64bf73a4104cce82379be7fc6608638c74d3c5d85d7b145b14',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_roi_loan_nhip_tim_03_tra_gung_va_mat_ong','unclassified','TRÀ GỪNG VÀ MẬT ONG','Rối loạn nhịp tim là tình trạng nhịp tim không đều, có thể quá nhanh, quá chậm hoặc không đều. Chế độ ăn giàu kali và magie có thể giúp ổn định nhịp tim.','Gừng rửa sạch, thái lát.
Cho gừng vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c01_roi_loan_nhip_tim','Rối loạn nhịp tim','Rối loạn nhịp tim là tình trạng nhịp tim không đều, có thể quá nhanh, quá chậm hoặc không đều. Chế độ ăn giàu kali và magie có thể giúp ổn định nhịp tim.',1,'Tim Mạch Và Mạch Máu Não','["1 củ gừng nhỏ", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Gừng rửa sạch, thái lát.", "Cho gừng vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Gừng có tính ấm, giúp lưu thông khí huyết, mật ong giúp tăng cường sức đề kháng, hỗ trợ ổn định nhịp tim.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',8,'Chương 1: Tim Mạch Và Mạch Máu Não','Rối loạn nhịp tim',3,'8b7c2a603e3e10ee59f6ddfff421fb5e4eb692fe050f4cfac71f8d1e8ef3311f',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_cao_huyet_ap_01_sinh_to_can_tay_va_tao','unclassified','SINH TỐ CẦN TÂY VÀ TÁO','Cao huyết áp là tình trạng áp lực máu lên thành động mạch tăng cao, có thể dẫn đến các biến chứng nguy hiểm. Chế độ ăn uống ít muối và giàu chất xơ có thể giúp kiểm soát huyết áp.','Cần tây rửa sạch, cắt khúc.
Táo rửa sạch, cắt nhỏ.
Cho cần tây, táo, nước và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c01_cao_huyet_ap','Cao huyết áp','Cao huyết áp là tình trạng áp lực máu lên thành động mạch tăng cao, có thể dẫn đến các biến chứng nguy hiểm. Chế độ ăn uống ít muối và giàu chất xơ có thể giúp kiểm soát huyết áp.',1,'Tim Mạch Và Mạch Máu Não','["2 nhánh cần tây", "1 quả táo", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Cần tây rửa sạch, cắt khúc.", "Táo rửa sạch, cắt nhỏ.", "Cho cần tây, táo, nước và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Cần tây và táo giàu chất xơ và kali, giúp giảm huyết áp.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',9,'Chương 1: Tim Mạch Và Mạch Máu Não','Cao huyết áp',1,'d757812a7856804373de99b834bd5011eba4ef23a14e59045e0c05fa03033cc4',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_cao_huyet_ap_02_canh_rong_bien_va_dau_hu','unclassified','CANH RONG BIỂN VÀ ĐẬU HŨ','Cao huyết áp là tình trạng áp lực máu lên thành động mạch tăng cao, có thể dẫn đến các biến chứng nguy hiểm. Chế độ ăn uống ít muối và giàu chất xơ có thể giúp kiểm soát huyết áp.','Rong biển ngâm nở, rửa sạch.
Đậu hũ cắt miếng vừa ăn.
Phi hành tím với dầu, cho rong biển vào xào sơ.
Thêm nước, đun sôi rồi cho đậu hũ vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c01_cao_huyet_ap','Cao huyết áp','Cao huyết áp là tình trạng áp lực máu lên thành động mạch tăng cao, có thể dẫn đến các biến chứng nguy hiểm. Chế độ ăn uống ít muối và giàu chất xơ có thể giúp kiểm soát huyết áp.',1,'Tim Mạch Và Mạch Máu Não','["100g rong biển khô", "200g đậu hũ", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Rong biển ngâm nở, rửa sạch.", "Đậu hũ cắt miếng vừa ăn.", "Phi hành tím với dầu, cho rong biển vào xào sơ.", "Thêm nước, đun sôi rồi cho đậu hũ vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Rong biển giàu chất xơ và khoáng chất, giúp kiểm soát huyết áp.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',9,'Chương 1: Tim Mạch Và Mạch Máu Não','Cao huyết áp',2,'2248f88e4dfd1cc7f3d13a5ec157ffd14637d2bddc6d09af24dbf5de4a82c4aa',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_cao_huyet_ap_03_tra_xanh_va_bac_ha','unclassified','TRÀ XANH VÀ BẠC HÀ','Cao huyết áp là tình trạng áp lực máu lên thành động mạch tăng cao, có thể dẫn đến các biến chứng nguy hiểm. Chế độ ăn uống ít muối và giàu chất xơ có thể giúp kiểm soát huyết áp.','Cho túi trà xanh và bạc hà vào cốc.
Đổ nước sôi vào, hãm trong 5-7 phút.
Uống ngay.',0,0,0,0,0,0,'c01_cao_huyet_ap','Cao huyết áp','Cao huyết áp là tình trạng áp lực máu lên thành động mạch tăng cao, có thể dẫn đến các biến chứng nguy hiểm. Chế độ ăn uống ít muối và giàu chất xơ có thể giúp kiểm soát huyết áp.',1,'Tim Mạch Và Mạch Máu Não','["1 túi trà xanh", "1 nhánh bạc hà tươi", "200ml nước sôi"]'::jsonb,'["Cho túi trà xanh và bạc hà vào cốc.", "Đổ nước sôi vào, hãm trong 5-7 phút.", "Uống ngay."]'::jsonb,'Trà xanh và bạc hà có tính làm dịu, giúp giảm huyết áp và căng thẳng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',9,'Chương 1: Tim Mạch Và Mạch Máu Não','Cao huyết áp',3,'46522b8741e587b1c8986f8edd56fb5cc6f6275dc9bab82ce5a6c22f08d7e56c',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_huyet_ap_thap_01_canh_ca_chua_nau_trung_ga','unclassified','Canh cà chua nấu trứng gà','Huyết áp thấp (hay còn gọi là hạ huyết áp) là tình trạng khi huyết áp trong động mạch giảm xuống dưới mức bình thường, gây ra các triệu chứng như chóng mặt, mệt mỏi, ngất xỉu, nhức đầu và thậm chí khó thở. Huyết áp thấp có thể do nhiều nguyên nhân, bao gồm mất nước, thiếu hụt dinh dưỡng, các bệnh lý về tim mạch hoặc rối loạn nội tiết.','Cà chua rửa sạch, cắt múi cau.
Trứng gà đập vào bát, đánh tan.
Phi hành tím với dầu ăn cho thơm, cho cà chua vào xào sơ.
Thêm nước vào, đun sôi, sau đó đổ trứng vào và khuấy nhẹ.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c01_huyet_ap_thap','Huyết áp thấp','Huyết áp thấp (hay còn gọi là hạ huyết áp) là tình trạng khi huyết áp trong động mạch giảm xuống dưới mức bình thường, gây ra các triệu chứng như chóng mặt, mệt mỏi, ngất xỉu, nhức đầu và thậm chí khó thở. Huyết áp thấp có thể do nhiều nguyên nhân, bao gồm mất nước, thiếu hụt dinh dưỡng, các bệnh lý về tim mạch hoặc rối loạn nội tiết.',1,'Tim Mạch Và Mạch Máu Não','["2 quả cà chua", "2 quả trứng gà", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Cà chua rửa sạch, cắt múi cau.", "Trứng gà đập vào bát, đánh tan.", "Phi hành tím với dầu ăn cho thơm, cho cà chua vào xào sơ.", "Thêm nước vào, đun sôi, sau đó đổ trứng vào và khuấy nhẹ.", "Nêm gia vị vừa ăn."]'::jsonb,'Cà chua giúp cải thiện tuần hoàn máu, trong khi trứng cung cấp protein và vitamin B12 giúp duy trì huyết áp ổn định.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',10,'Chương 1: Tim Mạch Và Mạch Máu Não','Huyết áp thấp',1,'02b6f78fa5e9ccb42e6b72da6013f7e6e415c30b55edca585ec02be802c86fec',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_huyet_ap_thap_02_nuoc_ep_dua_hau_va_la_bac_ha','unclassified','Nước ép dưa hấu và lá bạc hà','Huyết áp thấp (hay còn gọi là hạ huyết áp) là tình trạng khi huyết áp trong động mạch giảm xuống dưới mức bình thường, gây ra các triệu chứng như chóng mặt, mệt mỏi, ngất xỉu, nhức đầu và thậm chí khó thở. Huyết áp thấp có thể do nhiều nguyên nhân, bao gồm mất nước, thiếu hụt dinh dưỡng, các bệnh lý về tim mạch hoặc rối loạn nội tiết.','Dưa hấu gọt vỏ, cắt miếng nhỏ.
Lá bạc hà rửa sạch.
Cho tất cả vào máy xay sinh tố, xay nhuyễn.
Lọc qua rây và thưởng thức.',0,0,0,0,0,0,'c01_huyet_ap_thap','Huyết áp thấp','Huyết áp thấp (hay còn gọi là hạ huyết áp) là tình trạng khi huyết áp trong động mạch giảm xuống dưới mức bình thường, gây ra các triệu chứng như chóng mặt, mệt mỏi, ngất xỉu, nhức đầu và thậm chí khó thở. Huyết áp thấp có thể do nhiều nguyên nhân, bao gồm mất nước, thiếu hụt dinh dưỡng, các bệnh lý về tim mạch hoặc rối loạn nội tiết.',1,'Tim Mạch Và Mạch Máu Não','["200g dưa hấu", "10 lá bạc hà"]'::jsonb,'["Dưa hấu gọt vỏ, cắt miếng nhỏ.", "Lá bạc hà rửa sạch.", "Cho tất cả vào máy xay sinh tố, xay nhuyễn.", "Lọc qua rây và thưởng thức."]'::jsonb,'Dưa hấu giúp cung cấp nước và khoáng chất, giúp tăng cường lưu thông máu, trong khi bạc hà giúp làm dịu cơ thể và giảm căng thẳng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',10,'Chương 1: Tim Mạch Và Mạch Máu Não','Huyết áp thấp',2,'ef9b6d2692e30c1a3de52ebd396495dc511228a04bb5ba37c14e471fa6a6cf68',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c01_huyet_ap_thap_03_chao_dau_do_va_hat_sen','unclassified','Cháo đậu đỏ và hạt sen','Huyết áp thấp (hay còn gọi là hạ huyết áp) là tình trạng khi huyết áp trong động mạch giảm xuống dưới mức bình thường, gây ra các triệu chứng như chóng mặt, mệt mỏi, ngất xỉu, nhức đầu và thậm chí khó thở. Huyết áp thấp có thể do nhiều nguyên nhân, bao gồm mất nước, thiếu hụt dinh dưỡng, các bệnh lý về tim mạch hoặc rối loạn nội tiết.','Đậu đỏ và hạt sen ngâm qua đêm cho mềm.
Gạo nếp vo sạch, cho vào nồi nấu cùng đậu đỏ và hạt sen.
Đun sôi, hạ nhỏ lửa và nấu cho đến khi cháo nhừ.
Thêm đường phèn vào và khuấy đều.',0,0,0,0,0,0,'c01_huyet_ap_thap','Huyết áp thấp','Huyết áp thấp (hay còn gọi là hạ huyết áp) là tình trạng khi huyết áp trong động mạch giảm xuống dưới mức bình thường, gây ra các triệu chứng như chóng mặt, mệt mỏi, ngất xỉu, nhức đầu và thậm chí khó thở. Huyết áp thấp có thể do nhiều nguyên nhân, bao gồm mất nước, thiếu hụt dinh dưỡng, các bệnh lý về tim mạch hoặc rối loạn nội tiết.',1,'Tim Mạch Và Mạch Máu Não','["100g đậu đỏ", "50g hạt sen", "50g gạo nếp", "1 ít đường phèn"]'::jsonb,'["Đậu đỏ và hạt sen ngâm qua đêm cho mềm.", "Gạo nếp vo sạch, cho vào nồi nấu cùng đậu đỏ và hạt sen.", "Đun sôi, hạ nhỏ lửa và nấu cho đến khi cháo nhừ.", "Thêm đường phèn vào và khuấy đều."]'::jsonb,'Đậu đỏ giúp bổ sung sắt, cải thiện sức khỏe tuần hoàn, hạt sen giúp an thần và hỗ trợ sức khỏe tim mạch, làm ổn định huyết áp.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',11,'Chương 1: Tim Mạch Và Mạch Máu Não','Huyết áp thấp',3,'782fde8972c7649d4354b82126248e7a3f2319eb8eeadb669647a6167618f460',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_dau_dau_01_sinh_to_bo_va_hat_oc_cho','unclassified','SINH TỐ BƠ VÀ HẠT ÓC CHÓ','Đau đầu là cảm giác đau hoặc khó chịu ở đầu, có thể kéo dài từ vài phút đến vài giờ hoặc thậm chí vài ngày. Đau đầu có thể là triệu chứng của nhiều bệnh lý khác nhau, từ căng thẳng đơn giản cho đến các vấn đề nghiêm trọng hơn như rối loạn thần kinh.','Bơ bóc vỏ, bỏ hạt, cắt nhỏ.
Cho bơ, hạt óc chó, sữa hạnh nhân và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c02_dau_dau','Đau đầu','Đau đầu là cảm giác đau hoặc khó chịu ở đầu, có thể kéo dài từ vài phút đến vài giờ hoặc thậm chí vài ngày. Đau đầu có thể là triệu chứng của nhiều bệnh lý khác nhau, từ căng thẳng đơn giản cho đến các vấn đề nghiêm trọng hơn như rối loạn thần kinh.',2,'Bệnh Thần Kinh','["1 quả bơ", "50g hạt óc chó", "200ml sữa hạnh nhân", "1 thìa mật ong"]'::jsonb,'["Bơ bóc vỏ, bỏ hạt, cắt nhỏ.", "Cho bơ, hạt óc chó, sữa hạnh nhân và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Bơ và hạt óc chó giàu chất béo lành mạnh, giúp cải thiện lưu thông máu và giảm đau đầu.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',11,'Chương 2: Bệnh Thần Kinh','Đau đầu',1,'e708b35cdff7ea225b272e1cfa5dffa3c583e5d117b957e8358f18b75becd044',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_dau_dau_02_tra_hoa_cuc_va_bac_ha','unclassified','TRÀ HOA CÚC VÀ BẠC HÀ','Đau đầu là cảm giác đau hoặc khó chịu ở đầu, có thể kéo dài từ vài phút đến vài giờ hoặc thậm chí vài ngày. Đau đầu có thể là triệu chứng của nhiều bệnh lý khác nhau, từ căng thẳng đơn giản cho đến các vấn đề nghiêm trọng hơn như rối loạn thần kinh.','Cho túi trà hoa cúc và bạc hà vào cốc.
Đổ nước sôi vào, hãm trong 5-7 phút.
Uống ngay.',0,0,0,0,0,0,'c02_dau_dau','Đau đầu','Đau đầu là cảm giác đau hoặc khó chịu ở đầu, có thể kéo dài từ vài phút đến vài giờ hoặc thậm chí vài ngày. Đau đầu có thể là triệu chứng của nhiều bệnh lý khác nhau, từ căng thẳng đơn giản cho đến các vấn đề nghiêm trọng hơn như rối loạn thần kinh.',2,'Bệnh Thần Kinh','["1 túi trà hoa cúc", "1 nhánh bạc hà tươi", "200ml nước sôi"]'::jsonb,'["Cho túi trà hoa cúc và bạc hà vào cốc.", "Đổ nước sôi vào, hãm trong 5-7 phút.", "Uống ngay."]'::jsonb,'Hoa cúc và bạc hà có tính làm dịu, giúp giảm căng thẳng và đau đầu.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',12,'Chương 2: Bệnh Thần Kinh','Đau đầu',2,'c9f11a180cfe02eb66c5dacf024e7cf6ef73bd6a2532a292b1e98a4a35f0fedb',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_dau_dau_03_salad_rau_diep_ca_va_qua_oc_cho','unclassified','SALAD RAU DIẾP CÁ VÀ QUẢ ÓC CHÓ','Đau đầu là cảm giác đau hoặc khó chịu ở đầu, có thể kéo dài từ vài phút đến vài giờ hoặc thậm chí vài ngày. Đau đầu có thể là triệu chứng của nhiều bệnh lý khác nhau, từ căng thẳng đơn giản cho đến các vấn đề nghiêm trọng hơn như rối loạn thần kinh.','Rau diếp cá rửa sạch, để ráo.
Quả óc chó bóc vỏ, tách nhân.
Pha nước sốt với nước cốt chanh, muối, đường và dầu ô liu.
Trộn đều rau diếp cá và quả óc chó với nước sốt.',0,0,0,0,0,0,'c02_dau_dau','Đau đầu','Đau đầu là cảm giác đau hoặc khó chịu ở đầu, có thể kéo dài từ vài phút đến vài giờ hoặc thậm chí vài ngày. Đau đầu có thể là triệu chứng của nhiều bệnh lý khác nhau, từ căng thẳng đơn giản cho đến các vấn đề nghiêm trọng hơn như rối loạn thần kinh.',2,'Bệnh Thần Kinh','["200g rau diếp cá", "50g quả óc chó", "1 quả chanh", "Gia vị: muối, đường, dầu ô liu"]'::jsonb,'["Rau diếp cá rửa sạch, để ráo.", "Quả óc chó bóc vỏ, tách nhân.", "Pha nước sốt với nước cốt chanh, muối, đường và dầu ô liu.", "Trộn đều rau diếp cá và quả óc chó với nước sốt."]'::jsonb,'Rau diếp cá và quả óc chó giàu chất chống oxy hóa, giúp giảm căng thẳng và đau đầu.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',12,'Chương 2: Bệnh Thần Kinh','Đau đầu',3,'59602acf868642bdb01cac39c6c8eb343645ac54cbe0fb343811736747b32d0d',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_chung_mat_ngu_va_mo_nhieu_01_canh_rau_mong_toi_voi_dau_phu','unclassified','CANH RAU MỒNG TƠI VỚI ĐẬU PHỤ','Mất ngủ là tình trạng khó ngủ hoặc thức giấc giữa đêm và không thể ngủ lại. Mơ nhiều có thể đi kèm với lo âu hoặc căng thẳng, rối loạn tâm lý, chế độ ăn thiếu vitamin B, magiê, melatonin.','Đậu phụ cắt miếng vừa ăn, rau mồng tơi rửa sạch.
Phi hành tím với dầu ăn cho thơm, cho đậu phụ vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau mồng tơi vào nấu chín.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c02_chung_mat_ngu_va_mo_nhieu','Chứng mất ngủ và mơ nhiều','Mất ngủ là tình trạng khó ngủ hoặc thức giấc giữa đêm và không thể ngủ lại. Mơ nhiều có thể đi kèm với lo âu hoặc căng thẳng, rối loạn tâm lý, chế độ ăn thiếu vitamin B, magiê, melatonin.',2,'Bệnh Thần Kinh','["100g đậu phụ", "100g rau mồng tơi", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Đậu phụ cắt miếng vừa ăn, rau mồng tơi rửa sạch.", "Phi hành tím với dầu ăn cho thơm, cho đậu phụ vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau mồng tơi vào nấu chín.", "Nêm gia vị vừa ăn."]'::jsonb,'Đậu phụ giúp thư giãn cơ thể, rau mồng tơi có tác dụng an thần, giúp cải thiện giấc ngủ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',12,'Chương 2: Bệnh Thần Kinh','Chứng mất ngủ và mơ nhiều',1,'3fe7adae3309a72bb6767a3ee67887d3c6f176dbb95a1361c036bddc4a1040b7',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_chung_mat_ngu_va_mo_nhieu_02_nuoc_ep_cam_va_chanh','unclassified','NƯỚC ÉP CAM VÀ CHANH','Mất ngủ là tình trạng khó ngủ hoặc thức giấc giữa đêm và không thể ngủ lại. Mơ nhiều có thể đi kèm với lo âu hoặc căng thẳng, rối loạn tâm lý, chế độ ăn thiếu vitamin B, magiê, melatonin.','Cam và chanh vắt lấy nước.
Thêm mật ong vào và khuấy đều.',0,0,0,0,0,0,'c02_chung_mat_ngu_va_mo_nhieu','Chứng mất ngủ và mơ nhiều','Mất ngủ là tình trạng khó ngủ hoặc thức giấc giữa đêm và không thể ngủ lại. Mơ nhiều có thể đi kèm với lo âu hoặc căng thẳng, rối loạn tâm lý, chế độ ăn thiếu vitamin B, magiê, melatonin.',2,'Bệnh Thần Kinh','["1 quả cam", "1 quả chanh", "1 ít mật ong"]'::jsonb,'["Cam và chanh vắt lấy nước.", "Thêm mật ong vào và khuấy đều."]'::jsonb,'Cam và chanh giúp cung cấp vitamin C, làm dịu thần kinh, hỗ trợ giấc ngủ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',13,'Chương 2: Bệnh Thần Kinh','Chứng mất ngủ và mơ nhiều',2,'ba2247972698eed36ca2c2bead7c8a5e0496eab8d48ee2a751407bd82b1ecb5b',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_tram_cam_01_canh_ca_hoi_voi_cai_bo_xoi','unclassified','CANH CÁ HỒI VỚI CẢI BÓ XÔI','Trầm cảm là một tình trạng rối loạn tâm lý gây cảm giác buồn bã kéo dài, mất hứng thú với cuộc sống và các hoạt động. Nguyên nhân do căng thẳng kéo dài, di truyền, thiếu hụt chất dẫn truyền thần kinh (serotonin, dopamine), thiếu vitamin B12, folate.','Cá hồi rửa sạch, cắt khúc vừa ăn.
Cải bó xôi rửa sạch, cắt khúc.
Phi hành tím với dầu ăn cho thơm, sau đó cho cá vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho cải bó xôi vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c02_tram_cam','Trầm cảm','Trầm cảm là một tình trạng rối loạn tâm lý gây cảm giác buồn bã kéo dài, mất hứng thú với cuộc sống và các hoạt động. Nguyên nhân do căng thẳng kéo dài, di truyền, thiếu hụt chất dẫn truyền thần kinh (serotonin, dopamine), thiếu vitamin B12, folate.',2,'Bệnh Thần Kinh','["200g cá hồi", "100g cải bó xôi", "1 củ hành tím", "Gia vị: muối, tiêu"]'::jsonb,'["Cá hồi rửa sạch, cắt khúc vừa ăn.", "Cải bó xôi rửa sạch, cắt khúc.", "Phi hành tím với dầu ăn cho thơm, sau đó cho cá vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho cải bó xôi vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Cá hồi chứa omega-3 giúp cải thiện tâm trạng và chức năng não bộ, cải bó xôi giúp bổ sung vitamin và khoáng chất hỗ trợ sức khỏe thần kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',13,'Chương 2: Bệnh Thần Kinh','Trầm cảm',1,'fac9e8129f20112ed545d02fef0eae7c50c047f8f8db3c5f6707e95316d80981',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_tram_cam_02_sinh_to_ca_rot_va_dua','unclassified','SINH TỐ CÀ RỐT VÀ DỨA','Trầm cảm là một tình trạng rối loạn tâm lý gây cảm giác buồn bã kéo dài, mất hứng thú với cuộc sống và các hoạt động. Nguyên nhân do căng thẳng kéo dài, di truyền, thiếu hụt chất dẫn truyền thần kinh (serotonin, dopamine), thiếu vitamin B12, folate.','Cà rốt và dứa gọt vỏ, cắt miếng nhỏ.
Cho vào máy xay sinh tố, xay nhuyễn.
Thêm mật ong vào, khuấy đều.',0,0,0,0,0,0,'c02_tram_cam','Trầm cảm','Trầm cảm là một tình trạng rối loạn tâm lý gây cảm giác buồn bã kéo dài, mất hứng thú với cuộc sống và các hoạt động. Nguyên nhân do căng thẳng kéo dài, di truyền, thiếu hụt chất dẫn truyền thần kinh (serotonin, dopamine), thiếu vitamin B12, folate.',2,'Bệnh Thần Kinh','["1 củ cà rốt", "1/2 quả dứa", "1 ít mật ong"]'::jsonb,'["Cà rốt và dứa gọt vỏ, cắt miếng nhỏ.", "Cho vào máy xay sinh tố, xay nhuyễn.", "Thêm mật ong vào, khuấy đều."]'::jsonb,'Cà rốt và dứa cung cấp vitamin A, C giúp cải thiện tâm trạng và hỗ trợ sức khỏe tổng thể.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',14,'Chương 2: Bệnh Thần Kinh','Trầm cảm',2,'ffdbe24840bb717a588644ea813a2504325d41590353f5c1d90cd7032ed39dcf',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_chung_dau_dau_va_u_tai_01_canh_cai_xanh_voi_tom','unclassified','CANH CẢI XANH VỚI TÔM','Đau đầu và ù tai có thể là dấu hiệu của căng thẳng, vấn đề về tuần hoàn máu, hoặc các vấn đề về thính giác. Nguyên nhân: Stress, rối loạn tuần hoàn máu, tắc nghẽn mạch máu, viêm tai, bệnh lý về thần kinh.','Tôm làm sạch, cải xanh rửa sạch, cắt khúc.
Phi hành với dầu ăn cho thơm, cho tôm vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho cải xanh vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c02_chung_dau_dau_va_u_tai','Chứng đau đầu và ù tai','Đau đầu và ù tai có thể là dấu hiệu của căng thẳng, vấn đề về tuần hoàn máu, hoặc các vấn đề về thính giác. Nguyên nhân: Stress, rối loạn tuần hoàn máu, tắc nghẽn mạch máu, viêm tai, bệnh lý về thần kinh.',2,'Bệnh Thần Kinh','["200g tôm", "100g rau cải xanh", "1 củ hành tím", "Gia vị: muối, tiêu"]'::jsonb,'["Tôm làm sạch, cải xanh rửa sạch, cắt khúc.", "Phi hành với dầu ăn cho thơm, cho tôm vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho cải xanh vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Tôm cung cấp omega-3 giúp tuần hoàn máu tốt hơn, cải xanh bổ sung vitamin K giúp giảm viêm và bảo vệ sức khỏe tai.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',14,'Chương 2: Bệnh Thần Kinh','Chứng đau đầu và ù tai',1,'58793d756ef90c597429378b881c3b837e6039c5542fdb7af3d2df592d94f3de',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_chung_dau_dau_va_u_tai_02_nuoc_ep_dua_hau_va_bac_ha','unclassified','NƯỚC ÉP DƯA HẤU VÀ BẠC HÀ','Đau đầu và ù tai có thể là dấu hiệu của căng thẳng, vấn đề về tuần hoàn máu, hoặc các vấn đề về thính giác. Nguyên nhân: Stress, rối loạn tuần hoàn máu, tắc nghẽn mạch máu, viêm tai, bệnh lý về thần kinh.','Dưa hấu gọt vỏ, cắt miếng nhỏ.
Lá bạc hà rửa sạch, cho vào máy xay với dưa hấu.
Xay nhuyễn và lọc qua rây.',0,0,0,0,0,0,'c02_chung_dau_dau_va_u_tai','Chứng đau đầu và ù tai','Đau đầu và ù tai có thể là dấu hiệu của căng thẳng, vấn đề về tuần hoàn máu, hoặc các vấn đề về thính giác. Nguyên nhân: Stress, rối loạn tuần hoàn máu, tắc nghẽn mạch máu, viêm tai, bệnh lý về thần kinh.',2,'Bệnh Thần Kinh','["200g dưa hấu", "10 lá bạc hà"]'::jsonb,'["Dưa hấu gọt vỏ, cắt miếng nhỏ.", "Lá bạc hà rửa sạch, cho vào máy xay với dưa hấu.", "Xay nhuyễn và lọc qua rây."]'::jsonb,'Dưa hấu giúp giải độc cơ thể và giảm viêm, bạc hà làm dịu thần kinh, giảm đau đầu và ù tai.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',14,'Chương 2: Bệnh Thần Kinh','Chứng đau đầu và ù tai',2,'4bf4ba9e18506476db1b107a5cf40cfdec18a79059f0d93c69cf96fc4409f848',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_chung_suy_nhuoc_than_kinh_01_canh_ga_nau_rau_cai_thao','unclassified','CANH GÀ NẤU RAU CẢI THẢO','Suy nhược thần kinh là tình trạng mệt mỏi, căng thẳng kéo dài khiến người bệnh cảm thấy không có năng lượng, mất khả năng tập trung. Nguyên nhân: Căng thẳng lâu dài, thiếu ngủ, chế độ ăn uống không đủ dưỡng chất, mất cân bằng nội tiết.','Thịt gà rửa sạch, thái miếng vừa ăn.
Rau cải thảo rửa sạch, cắt khúc.
Phi hành tím với dầu ăn cho thơm, cho thịt gà vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau cải vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c02_chung_suy_nhuoc_than_kinh','Chứng suy nhược thần kinh','Suy nhược thần kinh là tình trạng mệt mỏi, căng thẳng kéo dài khiến người bệnh cảm thấy không có năng lượng, mất khả năng tập trung. Nguyên nhân: Căng thẳng lâu dài, thiếu ngủ, chế độ ăn uống không đủ dưỡng chất, mất cân bằng nội tiết.',2,'Bệnh Thần Kinh','["200g thịt gà", "100g rau cải thảo", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Thịt gà rửa sạch, thái miếng vừa ăn.", "Rau cải thảo rửa sạch, cắt khúc.", "Phi hành tím với dầu ăn cho thơm, cho thịt gà vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau cải vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Thịt gà bổ sung protein và vitamin B giúp cải thiện năng lượng và phục hồi hệ thần kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',15,'Chương 2: Bệnh Thần Kinh','Chứng suy nhược thần kinh',1,'0feebbae3691a8cb6f1e018789b5fc886c7798dfc77dfd9881cb4a8e514395b4',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_chung_suy_nhuoc_than_kinh_02_nuoc_ep_cam_va_bac_ha','unclassified','NƯỚC ÉP CAM VÀ BẠC HÀ','Suy nhược thần kinh là tình trạng mệt mỏi, căng thẳng kéo dài khiến người bệnh cảm thấy không có năng lượng, mất khả năng tập trung. Nguyên nhân: Căng thẳng lâu dài, thiếu ngủ, chế độ ăn uống không đủ dưỡng chất, mất cân bằng nội tiết.','Cam vắt lấy nước.
Lá bạc hà rửa sạch, cho vào máy xay cùng cam.
Xay nhuyễn và thưởng thức.',0,0,0,0,0,0,'c02_chung_suy_nhuoc_than_kinh','Chứng suy nhược thần kinh','Suy nhược thần kinh là tình trạng mệt mỏi, căng thẳng kéo dài khiến người bệnh cảm thấy không có năng lượng, mất khả năng tập trung. Nguyên nhân: Căng thẳng lâu dài, thiếu ngủ, chế độ ăn uống không đủ dưỡng chất, mất cân bằng nội tiết.',2,'Bệnh Thần Kinh','["2 quả cam", "10 lá bạc hà"]'::jsonb,'["Cam vắt lấy nước.", "Lá bạc hà rửa sạch, cho vào máy xay cùng cam.", "Xay nhuyễn và thưởng thức."]'::jsonb,'Cam cung cấp vitamin C, giúp giảm căng thẳng và mệt mỏi, bạc hà giúp làm dịu thần kinh, giảm căng thẳng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',15,'Chương 2: Bệnh Thần Kinh','Chứng suy nhược thần kinh',2,'40f2f5a8adc1e59e9dd7e5185783364ac370a00d86325fdfa283476b5a41af74',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_dau_day_than_kinh_sinh_ba_01_canh_rau_den_do_voi_tom','unclassified','CANH RAU DỀN ĐỎ VỚI TÔM','Đau dây thần kinh sinh ba là một cơn đau dữ dội kéo dài dọc theo dây thần kinh sinh ba, có thể gây cảm giác như bị điện giật hoặc tê bì ở vùng mặt. Nguyên nhân: Chèn ép thần kinh, viêm hoặc tổn thương thần kinh do chấn thương, rối loạn mạch máu.','Tôm làm sạch, rau dền đỏ rửa sạch.
Phi hành với dầu ăn cho thơm, cho tôm vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau dền vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c02_dau_day_than_kinh_sinh_ba','Đau dây thần kinh sinh ba','Đau dây thần kinh sinh ba là một cơn đau dữ dội kéo dài dọc theo dây thần kinh sinh ba, có thể gây cảm giác như bị điện giật hoặc tê bì ở vùng mặt. Nguyên nhân: Chèn ép thần kinh, viêm hoặc tổn thương thần kinh do chấn thương, rối loạn mạch máu.',2,'Bệnh Thần Kinh','["200g tôm", "100g rau dền đỏ", "Gia vị: muối, tiêu"]'::jsonb,'["Tôm làm sạch, rau dền đỏ rửa sạch.", "Phi hành với dầu ăn cho thơm, cho tôm vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau dền vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Rau dền đỏ giúp giảm viêm và làm dịu thần kinh, tôm cung cấp omega-3 hỗ trợ tái tạo các tế bào thần kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',16,'Chương 2: Bệnh Thần Kinh','Đau dây thần kinh sinh ba',1,'e240e847ee190c752e814eaabbcd087a59e8beb83b25e7fa73231256e982a0a2',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_benh_alzheimer_01_canh_ca_chep_nau_rau_can','unclassified','CANH CÁ CHÉP NẤU RAU CẦN','Alzheimer là bệnh lý thoái hóa não, dẫn đến suy giảm trí nhớ và khả năng nhận thức, ảnh hưởng đến hành vi và chức năng thần kinh. Nguyên nhân: Di truyền, rối loạn chất dẫn truyền thần kinh, tổn thương não do tuổi tác hoặc các yếu tố môi trường.','Cá chép làm sạch, cắt khúc vừa ăn.
Rau cần rửa sạch, cắt khúc.
Phi hành tím với dầu ăn cho thơm, sau đó cho cá vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau cần vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c02_benh_alzheimer','Bệnh Alzheimer','Alzheimer là bệnh lý thoái hóa não, dẫn đến suy giảm trí nhớ và khả năng nhận thức, ảnh hưởng đến hành vi và chức năng thần kinh. Nguyên nhân: Di truyền, rối loạn chất dẫn truyền thần kinh, tổn thương não do tuổi tác hoặc các yếu tố môi trường.',2,'Bệnh Thần Kinh','["300g cá chép", "100g rau cần", "Gia vị: muối, tiêu"]'::jsonb,'["Cá chép làm sạch, cắt khúc vừa ăn.", "Rau cần rửa sạch, cắt khúc.", "Phi hành tím với dầu ăn cho thơm, sau đó cho cá vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau cần vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Cá chép chứa omega-3 giúp bảo vệ não bộ, rau cần giúp thanh nhiệt, giải độc.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',16,'Chương 2: Bệnh Thần Kinh','Bệnh Alzheimer',1,'e39ce465decfff4e836c592412839ba4598f666bfb920239b32ced42e63bdc30',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c02_dau_day_than_kinh_toa_01_canh_rau_cu_cai_voi_thit_ga','unclassified','CANH RAU CỦ CẢI VỚI THỊT GÀ','Đau dây thần kinh tọa là tình trạng đau từ lưng dưới lan xuống mông và chân, do dây thần kinh tọa bị chèn ép hoặc tổn thương. Nguyên nhân: Thoát vị đĩa đệm, chèn ép thần kinh, chấn thương cột sống.','Thịt gà rửa sạch, thái miếng vừa ăn.
Củ cải gọt vỏ, cắt khúc vừa ăn.
Phi hành với dầu ăn cho thơm, cho thịt gà vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho củ cải vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c02_dau_day_than_kinh_toa','Đau dây thần kinh tọa','Đau dây thần kinh tọa là tình trạng đau từ lưng dưới lan xuống mông và chân, do dây thần kinh tọa bị chèn ép hoặc tổn thương. Nguyên nhân: Thoát vị đĩa đệm, chèn ép thần kinh, chấn thương cột sống.',2,'Bệnh Thần Kinh','["200g thịt gà", "100g củ cải", "Gia vị: muối, tiêu"]'::jsonb,'["Thịt gà rửa sạch, thái miếng vừa ăn.", "Củ cải gọt vỏ, cắt khúc vừa ăn.", "Phi hành với dầu ăn cho thơm, cho thịt gà vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho củ cải vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Củ cải giúp giảm viêm, giải độc, thịt gà bổ sung protein, giúp phục hồi sức khỏe và giảm đau.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',17,'Chương 2: Bệnh Thần Kinh','Đau dây thần kinh tọa',1,'657b22e0d6b2eae98f4eb8fdf76acbf63e0f8b18ebcc1b2c486d9069fd13bc60',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_cam_cum_01_sinh_to_cam_va_gung','unclassified','SINH TỐ CAM VÀ GỪNG','Cảm cúm là một bệnh nhiễm trùng đường hô hấp do virus cúm gây ra, thường biểu hiện qua các triệu chứng như sốt, ho, đau họng, mệt mỏi, nhức đầu và nghẹt mũi. Cảm cúm có thể tự khỏi trong vài ngày, nhưng nếu không được chăm sóc đúng cách có thể dẫn đến các biến chứng nghiêm trọng.','Cam vắt lấy nước.
Gừng rửa sạch, thái lát.
Cho nước cam, gừng và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c03_cam_cum','Cảm cúm','Cảm cúm là một bệnh nhiễm trùng đường hô hấp do virus cúm gây ra, thường biểu hiện qua các triệu chứng như sốt, ho, đau họng, mệt mỏi, nhức đầu và nghẹt mũi. Cảm cúm có thể tự khỏi trong vài ngày, nhưng nếu không được chăm sóc đúng cách có thể dẫn đến các biến chứng nghiêm trọng.',3,'Hô Hấp','["2 quả cam", "1 củ gừng nhỏ", "1 thìa mật ong"]'::jsonb,'["Cam vắt lấy nước.", "Gừng rửa sạch, thái lát.", "Cho nước cam, gừng và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Cam giàu vitamin C, gừng có tính ấm, giúp tăng cường hệ miễn dịch và giảm triệu chứng cảm cúm.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',17,'Chương 3: Hô Hấp','Cảm cúm',1,'ac92e459c5fb6dd57d2fbdc354fc6f51ac776042d8ab7567a01143689c2dc3a6',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_cam_cum_02_canh_ga_nau_nam','unclassified','CANH GÀ NẤU NẤM','Cảm cúm là một bệnh nhiễm trùng đường hô hấp do virus cúm gây ra, thường biểu hiện qua các triệu chứng như sốt, ho, đau họng, mệt mỏi, nhức đầu và nghẹt mũi. Cảm cúm có thể tự khỏi trong vài ngày, nhưng nếu không được chăm sóc đúng cách có thể dẫn đến các biến chứng nghiêm trọng.','Thịt gà rửa sạch, thái miếng.
Nấm hương ngâm nở, rửa sạch.
Phi hành tím với dầu, cho thịt gà vào xào sơ.
Thêm nước, đun sôi rồi cho nấm vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c03_cam_cum','Cảm cúm','Cảm cúm là một bệnh nhiễm trùng đường hô hấp do virus cúm gây ra, thường biểu hiện qua các triệu chứng như sốt, ho, đau họng, mệt mỏi, nhức đầu và nghẹt mũi. Cảm cúm có thể tự khỏi trong vài ngày, nhưng nếu không được chăm sóc đúng cách có thể dẫn đến các biến chứng nghiêm trọng.',3,'Hô Hấp','["200g thịt gà", "100g nấm hương", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Thịt gà rửa sạch, thái miếng.", "Nấm hương ngâm nở, rửa sạch.", "Phi hành tím với dầu, cho thịt gà vào xào sơ.", "Thêm nước, đun sôi rồi cho nấm vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Thịt gà giàu protein, nấm hương có tính kháng virus, giúp tăng cường hệ miễn dịch.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',17,'Chương 3: Hô Hấp','Cảm cúm',2,'dfc715089a63c6b3833dce0e3c5806ce9884ac739a9cb46db52ef066f4276e9b',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_cam_cum_03_tra_chanh_mat_ong','unclassified','TRÀ CHANH MẬT ONG','Cảm cúm là một bệnh nhiễm trùng đường hô hấp do virus cúm gây ra, thường biểu hiện qua các triệu chứng như sốt, ho, đau họng, mệt mỏi, nhức đầu và nghẹt mũi. Cảm cúm có thể tự khỏi trong vài ngày, nhưng nếu không được chăm sóc đúng cách có thể dẫn đến các biến chứng nghiêm trọng.','Chanh vắt lấy nước cốt.
Cho nước cốt chanh và mật ong vào nước sôi, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c03_cam_cum','Cảm cúm','Cảm cúm là một bệnh nhiễm trùng đường hô hấp do virus cúm gây ra, thường biểu hiện qua các triệu chứng như sốt, ho, đau họng, mệt mỏi, nhức đầu và nghẹt mũi. Cảm cúm có thể tự khỏi trong vài ngày, nhưng nếu không được chăm sóc đúng cách có thể dẫn đến các biến chứng nghiêm trọng.',3,'Hô Hấp','["1 quả chanh", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Chanh vắt lấy nước cốt.", "Cho nước cốt chanh và mật ong vào nước sôi, khuấy đều.", "Uống ngay."]'::jsonb,'Chanh giàu vitamin C, mật ong giúp tăng cường hệ miễn dịch, giảm triệu chứng cảm cúm.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',18,'Chương 3: Hô Hấp','Cảm cúm',3,'be35bfafdf3a5c551d379cdbae476f6b67dde631bd954907076d261b6f8f6678',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_viem_phoi_01_canh_ga_ham_thuoc_bac','unclassified','CANH GÀ HẦM THUỐC BẮC','Viêm phổi là tình trạng viêm nhiễm ở phổi, thường do vi khuẩn, virus hoặc nấm gây ra. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Gà làm sạch, chặt miếng vừa ăn.
Cho gà, kỷ tử, táo đỏ và gừng vào nồi hầm.
Hầm đến khi gà chín mềm.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c03_viem_phoi','Viêm phổi','Viêm phổi là tình trạng viêm nhiễm ở phổi, thường do vi khuẩn, virus hoặc nấm gây ra. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',3,'Hô Hấp','["1 con gà ác", "50g kỷ tử", "50g táo đỏ", "1 củ gừng", "Gia vị: muối, tiêu"]'::jsonb,'["Gà làm sạch, chặt miếng vừa ăn.", "Cho gà, kỷ tử, táo đỏ và gừng vào nồi hầm.", "Hầm đến khi gà chín mềm.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Gà hầm thuốc Bắc giúp bồi bổ cơ thể, tăng cường hệ miễn dịch, hỗ trợ điều trị viêm phổi.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',18,'Chương 3: Hô Hấp','Viêm phổi',1,'cfb44725d370d2493ef41a64eacfc9c718437dcd8179a1c84ecee2a5914104e4',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_viem_phoi_02_sinh_to_cam_va_gung','unclassified','SINH TỐ CAM VÀ GỪNG','Viêm phổi là tình trạng viêm nhiễm ở phổi, thường do vi khuẩn, virus hoặc nấm gây ra. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Cam vắt lấy nước.
Gừng rửa sạch, thái lát.
Cho nước cam, gừng và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c03_viem_phoi','Viêm phổi','Viêm phổi là tình trạng viêm nhiễm ở phổi, thường do vi khuẩn, virus hoặc nấm gây ra. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',3,'Hô Hấp','["2 quả cam", "1 củ gừng nhỏ", "1 thìa mật ong"]'::jsonb,'["Cam vắt lấy nước.", "Gừng rửa sạch, thái lát.", "Cho nước cam, gừng và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Cam giàu vitamin C, gừng có tính ấm, giúp tăng cường hệ miễn dịch và giảm triệu chứng viêm phổi.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',19,'Chương 3: Hô Hấp','Viêm phổi',2,'414c599fe0c8285348025c26e8999be14a2ae55f41d036902f394766b6708b95',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_viem_phoi_03_tra_xanh_va_bac_ha','unclassified','TRÀ XANH VÀ BẠC HÀ','Viêm phổi là tình trạng viêm nhiễm ở phổi, thường do vi khuẩn, virus hoặc nấm gây ra. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Cho túi trà xanh và bạc hà vào cốc.
Đổ nước sôi vào, hãm trong 5-7 phút.
Uống ngay.',0,0,0,0,0,0,'c03_viem_phoi','Viêm phổi','Viêm phổi là tình trạng viêm nhiễm ở phổi, thường do vi khuẩn, virus hoặc nấm gây ra. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',3,'Hô Hấp','["1 túi trà xanh", "1 nhánh bạc hà tươi", "200ml nước sôi"]'::jsonb,'["Cho túi trà xanh và bạc hà vào cốc.", "Đổ nước sôi vào, hãm trong 5-7 phút.", "Uống ngay."]'::jsonb,'Trà xanh và bạc hà có tính kháng viêm, giúp làm dịu cổ họng và hỗ trợ điều trị viêm phổi.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',19,'Chương 3: Hô Hấp','Viêm phổi',3,'e8c8634bd598566f37030f9728304f3b4c86004dc1c36a981d1d1328a32c2792',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_viem_phe_quan_man_tinh_01_canh_nam_dong_co_va_rong_bien','unclassified','Canh nấm đông cô và rong biển','Viêm phế quản mãn tính là tình trạng viêm nhiễm kéo dài ở đường hô hấp, gây ho và khó thở. Chế độ ăn uống giàu chất chống oxy hóa và kháng viêm có thể giúp cải thiện tình trạng này.','Nấm đông cô ngâm nước cho nở, cắt lát. Rong biển rửa sạch, ngâm mềm.
Phi thơm hành tím, cho nấm vào xào sơ.
Thêm nước, đun sôi rồi cho rong biển và đậu hũ vào.
Nêm gia vị cho vừa ăn',0,0,0,0,0,0,'c03_viem_phe_quan_man_tinh','Viêm phế quản mãn tính','Viêm phế quản mãn tính là tình trạng viêm nhiễm kéo dài ở đường hô hấp, gây ho và khó thở. Chế độ ăn uống giàu chất chống oxy hóa và kháng viêm có thể giúp cải thiện tình trạng này.',3,'Hô Hấp','["100g nấm đông cô", "50g rong biển khô", "1 miếng đậu hũ non", "Gia vị: muối, tiêu, dầu mè"]'::jsonb,'["Nấm đông cô ngâm nước cho nở, cắt lát. Rong biển rửa sạch, ngâm mềm.", "Phi thơm hành tím, cho nấm vào xào sơ.", "Thêm nước, đun sôi rồi cho rong biển và đậu hũ vào.", "Nêm gia vị cho vừa ăn"]'::jsonb,'Nấm hương có tính kháng viêm, đậu hũ giàu protein giúp tăng cường hệ miễn dịch.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',19,'Chương 3: Hô Hấp','Viêm phế quản mãn tính',1,'479f0d2f67d0c9c2fd12c8b4d822342e04ce89ed106480447fa78f1d0ac5335a',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_viem_phe_quan_man_tinh_02_sinh_to_rau_bina_va_dua_chuot','unclassified','SINH TỐ RAU BINA VÀ DƯA CHUỘT','Viêm phế quản mãn tính là tình trạng viêm nhiễm kéo dài ở đường hô hấp, gây ho và khó thở. Chế độ ăn uống giàu chất chống oxy hóa và kháng viêm có thể giúp cải thiện tình trạng này.','Rau bina và dưa chuột rửa sạch, cắt nhỏ.
Cho rau bina, dưa chuột, nước và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c03_viem_phe_quan_man_tinh','Viêm phế quản mãn tính','Viêm phế quản mãn tính là tình trạng viêm nhiễm kéo dài ở đường hô hấp, gây ho và khó thở. Chế độ ăn uống giàu chất chống oxy hóa và kháng viêm có thể giúp cải thiện tình trạng này.',3,'Hô Hấp','["1 nắm rau bina", "1 quả dưa chuột", "200ml nước lọc"]'::jsonb,'["Rau bina và dưa chuột rửa sạch, cắt nhỏ.", "Cho rau bina, dưa chuột, nước và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Rau bina và dưa chuột giàu chất chống oxy hóa, giúp giảm viêm và hỗ trợ điều trị viêm phế quản mãn tính.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',20,'Chương 3: Hô Hấp','Viêm phế quản mãn tính',2,'04726cee583c069ce0d19dab42aa8925215d85fa1c30dba92de0aadaec8224c8',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c03_viem_phe_quan_man_tinh_03_tra_gung_va_mat_ong','unclassified','TRÀ GỪNG VÀ MẬT ONG','Viêm phế quản mãn tính là tình trạng viêm nhiễm kéo dài ở đường hô hấp, gây ho và khó thở. Chế độ ăn uống giàu chất chống oxy hóa và kháng viêm có thể giúp cải thiện tình trạng này.','Gừng rửa sạch, thái lát.
Cho gừng vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c03_viem_phe_quan_man_tinh','Viêm phế quản mãn tính','Viêm phế quản mãn tính là tình trạng viêm nhiễm kéo dài ở đường hô hấp, gây ho và khó thở. Chế độ ăn uống giàu chất chống oxy hóa và kháng viêm có thể giúp cải thiện tình trạng này.',3,'Hô Hấp','["1 củ gừng nhỏ", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Gừng rửa sạch, thái lát.", "Cho gừng vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Gừng có tính kháng viêm, mật ong giúp làm dịu cổ họng, hỗ trợ điều trị viêm phế quản mãn tính.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',20,'Chương 3: Hô Hấp','Viêm phế quản mãn tính',3,'6215a5fa35df50a428b4ecdbb2a27b3eeb56fc12740c5f7ab3998e7416405985',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_da_day_01_chao_khoai_lang_tim_va_gao_lut','unclassified','Cháo khoai lang tím và gạo lứt','Viêm dạ dày là tình trạng viêm niêm mạc dạ dày, gây đau và khó chịu. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Khoai lang tím gọt vỏ, cắt miếng nhỏ.
Gạo lứt vo sạch, ngâm nước 1 giờ trước khi nấu.
Cho gạo lứt và khoai lang vào nồi, nấu đến khi chín nhừ.
Nêm thêm ít muối để tăng hương vị.',0,0,0,0,0,0,'c04_viem_da_day','Viêm dạ dày','Viêm dạ dày là tình trạng viêm niêm mạc dạ dày, gây đau và khó chịu. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["100g khoai lang tím", "50g gạo lứt", "200ml nước"]'::jsonb,'["Khoai lang tím gọt vỏ, cắt miếng nhỏ.", "Gạo lứt vo sạch, ngâm nước 1 giờ trước khi nấu.", "Cho gạo lứt và khoai lang vào nồi, nấu đến khi chín nhừ.", "Nêm thêm ít muối để tăng hương vị."]'::jsonb,'Khoai lang tím giàu chất chống oxy hóa giúp bảo vệ niêm mạc dạ dày, gạo lứt cung cấp chất xơ hỗ trợ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',20,'Chương 4: Tiêu Hóa','Viêm dạ dày',1,'c86d03a7b7889c99e02eb74e51f18c31322b657dc3300fda741f1202e9eb7443',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_da_day_02_sinh_to_bo_va_sua_chua','unclassified','SINH TỐ BƠ VÀ SỮA CHUA','Viêm dạ dày là tình trạng viêm niêm mạc dạ dày, gây đau và khó chịu. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Bơ bóc vỏ, bỏ hạt, cắt nhỏ.
Cho bơ, sữa chua và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c04_viem_da_day','Viêm dạ dày','Viêm dạ dày là tình trạng viêm niêm mạc dạ dày, gây đau và khó chịu. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["1 quả bơ", "200ml sữa chua không đường", "1 thìa mật ong"]'::jsonb,'["Bơ bóc vỏ, bỏ hạt, cắt nhỏ.", "Cho bơ, sữa chua và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Bơ và sữa chua giàu chất béo lành mạnh, giúp làm dịu niêm mạc dạ dày.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',21,'Chương 4: Tiêu Hóa','Viêm dạ dày',2,'863a2d78de4a791ad45a858485bf14896f6d9028b647151485721d091fdb47a3',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_da_day_03_canh_bi_do_nau_thit_ga','unclassified','CANH BÍ ĐỎ NẤU THỊT GÀ','Viêm dạ dày là tình trạng viêm niêm mạc dạ dày, gây đau và khó chịu. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Bí đỏ gọt vỏ, cắt miếng vừa ăn.
Thịt gà rửa sạch, thái miếng.
Phi hành tím với dầu, cho thịt gà vào xào sơ.
Thêm nước, đun sôi rồi cho bí đỏ vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c04_viem_da_day','Viêm dạ dày','Viêm dạ dày là tình trạng viêm niêm mạc dạ dày, gây đau và khó chịu. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["300g bí đỏ", "200g thịt gà", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Bí đỏ gọt vỏ, cắt miếng vừa ăn.", "Thịt gà rửa sạch, thái miếng.", "Phi hành tím với dầu, cho thịt gà vào xào sơ.", "Thêm nước, đun sôi rồi cho bí đỏ vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Bí đỏ giàu chất xơ, thịt gà giàu protein, giúp làm dịu niêm mạc dạ dày.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',21,'Chương 4: Tiêu Hóa','Viêm dạ dày',3,'acf0b2d34d95ec86dc125454f079b6c7beea7736e42079fe089e1a78dc9c8d1d',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_dai_trang_01_chao_yen_mach_va_thit_ga','unclassified','CHÁO YẾN MẠCH VÀ THỊT GÀ','Viêm đại tràng là tình trạng viêm niêm mạc đại tràng, gây đau bụng, rối loạn tiêu hóa và khó hấp thu dinh dưỡng. Chế độ ăn uống nhẹ nhàng, giàu chất xơ hòa tan và dễ tiêu hóa sẽ giúp giảm triệu chứng và phục hồi niêm mạc ruột.','Thịt gà luộc chín, xé nhỏ.
Phi thơm hành tím với dầu oliu, cho yến mạch vào đảo đều.
Thêm nước, đun sôi, khuấy đều đến khi cháo chín nhừ.
Cho thịt gà vào, nêm nhạt, thêm gừng thái sợi để giảm đầy hơi.',0,0,0,0,0,0,'c04_viem_dai_trang','Viêm đại tràng','Viêm đại tràng là tình trạng viêm niêm mạc đại tràng, gây đau bụng, rối loạn tiêu hóa và khó hấp thu dinh dưỡng. Chế độ ăn uống nhẹ nhàng, giàu chất xơ hòa tan và dễ tiêu hóa sẽ giúp giảm triệu chứng và phục hồi niêm mạc ruột.',4,'Tiêu Hóa','["50g yến mạch", "100g thịt gà (ức hoặc đùi không da)", "1 củ hành tím", "1 nhánh gừng nhỏ", "Gia vị: muối, dầu oliu"]'::jsonb,'["Thịt gà luộc chín, xé nhỏ.", "Phi thơm hành tím với dầu oliu, cho yến mạch vào đảo đều.", "Thêm nước, đun sôi, khuấy đều đến khi cháo chín nhừ.", "Cho thịt gà vào, nêm nhạt, thêm gừng thái sợi để giảm đầy hơi."]'::jsonb,'Yến mạch giàu chất xơ, Thịt gà dễ tiêu, cung cấp protein lành mạnh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',21,'Chương 4: Tiêu Hóa','Viêm đại tràng',1,'657115049664ab29211ada7b463f41bdf9b866b77154a983d0644b18752313b6',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_dai_trang_02_sup_khoai_tay_va_carot','unclassified','SÚP KHOAI TÂY VÀ CAROT','Viêm đại tràng là tình trạng viêm niêm mạc đại tràng, gây đau bụng, rối loạn tiêu hóa và khó hấp thu dinh dưỡng. Chế độ ăn uống nhẹ nhàng, giàu chất xơ hòa tan và dễ tiêu hóa sẽ giúp giảm triệu chứng và phục hồi niêm mạc ruột.','Khoai tây, cà rốt gọt vỏ, luộc chín mềm, xay nhuyễn.
Hòa bột gạo với nước, đun sôi cùng hỗn hợp khoai-cà rốt.
Nêm nhạt, thêm chút dầu oliu và rau thơm nếu thích.',0,0,0,0,0,0,'c04_viem_dai_trang','Viêm đại tràng','Viêm đại tràng là tình trạng viêm niêm mạc đại tràng, gây đau bụng, rối loạn tiêu hóa và khó hấp thu dinh dưỡng. Chế độ ăn uống nhẹ nhàng, giàu chất xơ hòa tan và dễ tiêu hóa sẽ giúp giảm triệu chứng và phục hồi niêm mạc ruột.',4,'Tiêu Hóa','["1 củ khoai tây, 1 củ cà rốt", "1 thìa bột gạo (hoặc bột năng)", "Gia vị: muối, dầu oliu, hành lá, thì là"]'::jsonb,'["Khoai tây, cà rốt gọt vỏ, luộc chín mềm, xay nhuyễn.", "Hòa bột gạo với nước, đun sôi cùng hỗn hợp khoai-cà rốt.", "Nêm nhạt, thêm chút dầu oliu và rau thơm nếu thích."]'::jsonb,'Khoai tây và cà rốt cung cấp tinh bột dễ hấp thu, giảm kích thích đại tràng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',22,'Chương 4: Tiêu Hóa','Viêm đại tràng',2,'8d768fca0056d4b3eee2a4ec206547227a53d77388068dd3748b02db7c307c39',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_dai_trang_03_sinh_to_khoai_lang_va_nghe','unclassified','SINH TỐ KHOAI LANG VÀ NGHỆ','Viêm đại tràng là tình trạng viêm niêm mạc đại tràng, gây đau bụng, rối loạn tiêu hóa và khó hấp thu dinh dưỡng. Chế độ ăn uống nhẹ nhàng, giàu chất xơ hòa tan và dễ tiêu hóa sẽ giúp giảm triệu chứng và phục hồi niêm mạc ruột.','Khoai lang hấp chín, bỏ vỏ, cắt nhỏ
Nghệ tươi rửa sạch, cắt lát mỏng ( hoặc cho vào Nano Curcumin )
Cho tất cả nguyên liệu vào máy xay sinh tố
Xay nhuyễn đến khi hỗn hợp mịn đều',0,0,0,0,0,0,'c04_viem_dai_trang','Viêm đại tràng','Viêm đại tràng là tình trạng viêm niêm mạc đại tràng, gây đau bụng, rối loạn tiêu hóa và khó hấp thu dinh dưỡng. Chế độ ăn uống nhẹ nhàng, giàu chất xơ hòa tan và dễ tiêu hóa sẽ giúp giảm triệu chứng và phục hồi niêm mạc ruột.',4,'Tiêu Hóa','["1/2 củ khoai lang vàng (khoảng 100g)", "1 đốt ngón tay nghệ tươi (Curcumin)", "1 thìa mật ong nguyên chất (tùy chọn)"]'::jsonb,'["Khoai lang hấp chín, bỏ vỏ, cắt nhỏ", "Nghệ tươi rửa sạch, cắt lát mỏng ( hoặc cho vào Nano Curcumin )", "Cho tất cả nguyên liệu vào máy xay sinh tố", "Xay nhuyễn đến khi hỗn hợp mịn đều"]'::jsonb,'Hỗ trợ phục hồi niêm mạc đại tràng bị tổn thương, giảm viêm nhiễm và cân bằng hệ tiêu hóa. Khoai lang cung cấp tinh bột lành mạnh, trong khi nghệ có đặc tính kháng viêm mạnh mẽ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',22,'Chương 4: Tiêu Hóa','Viêm đại tràng',3,'e54c998821d02df9226b7ba52cd531fe904df6e1a8807cddd2251d95476c1fcf',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_benh_sa_da_day_01_chao_ga_va_hat_sen','unclassified','CHÁO GÀ VÀ HẠT SEN','Bệnh sa dạ dày là tình trạng dạ dày bị sa xuống thấp hơn vị trí bình thường, gây khó tiêu và đau bụng. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Thịt gà rửa sạch, thái miếng.
Hạt sen ngâm nước 2 tiếng.
Cho gạo, hạt sen và thịt gà vào nồi, nấu đến khi chín nhừ.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c04_benh_sa_da_day','Bệnh sa dạ dày','Bệnh sa dạ dày là tình trạng dạ dày bị sa xuống thấp hơn vị trí bình thường, gây khó tiêu và đau bụng. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["200g thịt gà", "100g hạt sen", "50g gạo tẻ", "Gia vị: muối, tiêu"]'::jsonb,'["Thịt gà rửa sạch, thái miếng.", "Hạt sen ngâm nước 2 tiếng.", "Cho gạo, hạt sen và thịt gà vào nồi, nấu đến khi chín nhừ.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Thịt gà và hạt sen giàu dinh dưỡng, giúp cải thiện tình trạng sa dạ dày.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',22,'Chương 4: Tiêu Hóa','Bệnh sa dạ dày',1,'f8142718640b73d1d910a6199b7cba286a1833a5ec9bb0ff901de76e15d6e0b5',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_benh_sa_da_day_02_sinh_to_xoai_sua_chua','unclassified','SINH TỐ XOÀI SỮA CHUA','Bệnh sa dạ dày là tình trạng dạ dày bị sa xuống thấp hơn vị trí bình thường, gây khó tiêu và đau bụng. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Xoài gọt vỏ, cắt nhỏ..
Cho vào máy xay cùng sữa chua, mật ong, xay nhuyễn.',0,0,0,0,0,0,'c04_benh_sa_da_day','Bệnh sa dạ dày','Bệnh sa dạ dày là tình trạng dạ dày bị sa xuống thấp hơn vị trí bình thường, gây khó tiêu và đau bụng. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["1 quả xoài chín", "200ml sữa chua không đường", "1 thìa mật ong"]'::jsonb,'["Xoài gọt vỏ, cắt nhỏ..", "Cho vào máy xay cùng sữa chua, mật ong, xay nhuyễn."]'::jsonb,'Xoài giàu vitamin C, sữa chua tốt cho hệ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',23,'Chương 4: Tiêu Hóa','Bệnh sa dạ dày',2,'9ab4cd60b51461d41fb233768ee7fc765f9a2cd0a4bed96803fe3dea574f8c31',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_benh_sa_da_day_03_canh_rau_can_tay_va_ca_rot','unclassified','CANH RAU CẦN TÂY VÀ CÀ RỐT','Bệnh sa dạ dày là tình trạng dạ dày bị sa xuống thấp hơn vị trí bình thường, gây khó tiêu và đau bụng. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Rau cần tây rửa sạch, cắt khúc.
Cà rốt gọt vỏ, thái lát.
Phi hành tím với dầu, cho cà rốt vào xào sơ.
Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c04_benh_sa_da_day','Bệnh sa dạ dày','Bệnh sa dạ dày là tình trạng dạ dày bị sa xuống thấp hơn vị trí bình thường, gây khó tiêu và đau bụng. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["200g rau cần tây", "1 củ cà rốt", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Rau cần tây rửa sạch, cắt khúc.", "Cà rốt gọt vỏ, thái lát.", "Phi hành tím với dầu, cho cà rốt vào xào sơ.", "Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Rau cần tây và cà rốt giàu chất xơ, giúp cải thiện tiêu hóa và hỗ trợ điều trị sa dạ dày.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',23,'Chương 4: Tiêu Hóa','Bệnh sa dạ dày',3,'48fdc36f422603e20128cb2a1a17a299c4dfa0d706d59713570e2452e6242fbc',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_ung_thu_da_day_01_sinh_to_rau_bina_va_dua_chuot','unclassified','SINH TỐ RAU BINA VÀ DƯA CHUỘT','Ung thư dạ dày là tình trạng các tế bào ác tính phát triển trong dạ dày. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Rau bina và dưa chuột rửa sạch, cắt nhỏ.
Cho rau bina, dưa chuột, nước và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c04_ung_thu_da_day','Ung thư dạ dày','Ung thư dạ dày là tình trạng các tế bào ác tính phát triển trong dạ dày. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',4,'Tiêu Hóa','["1 nắm rau bina", "1 quả dưa chuột", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Rau bina và dưa chuột rửa sạch, cắt nhỏ.", "Cho rau bina, dưa chuột, nước và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Rau bina và dưa chuột giàu chất chống oxy hóa, giúp hỗ trợ điều trị ung thư dạ dày.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',23,'Chương 4: Tiêu Hóa','Ung thư dạ dày',1,'21e21b137f7018f16be5e110cffcb60420123ee7daf72a7dbea7b5d9eb7bd03d',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_ung_thu_da_day_02_canh_nam_huong_va_dau_hu','unclassified','CANH NẤM HƯƠNG VÀ ĐẬU HŨ','Ung thư dạ dày là tình trạng các tế bào ác tính phát triển trong dạ dày. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Nấm hương ngâm nở, rửa sạch.
Đậu hũ cắt miếng vừa ăn.
Phi hành tím với dầu, cho nấm vào xào sơ.
Thêm nước, đun sôi rồi cho đậu hũ vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c04_ung_thu_da_day','Ung thư dạ dày','Ung thư dạ dày là tình trạng các tế bào ác tính phát triển trong dạ dày. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',4,'Tiêu Hóa','["200g nấm hương", "200g đậu hũ", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Nấm hương ngâm nở, rửa sạch.", "Đậu hũ cắt miếng vừa ăn.", "Phi hành tím với dầu, cho nấm vào xào sơ.", "Thêm nước, đun sôi rồi cho đậu hũ vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Nấm hương có tính kháng viêm, đậu hũ giàu protein giúp tăng cường hệ miễn dịch.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',24,'Chương 4: Tiêu Hóa','Ung thư dạ dày',2,'c1e579e0c783d981ac433fc2e248c53b5f04964584dfe7ca076f501683cc400b',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_ung_thu_da_day_03_tra_xanh_va_bac_ha','unclassified','TRÀ XANH VÀ BẠC HÀ','Ung thư dạ dày là tình trạng các tế bào ác tính phát triển trong dạ dày. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Cho túi trà xanh và bạc hà vào cốc.
Đổ nước sôi vào, hãm trong 5-7 phút.
Uống ngay.',0,0,0,0,0,0,'c04_ung_thu_da_day','Ung thư dạ dày','Ung thư dạ dày là tình trạng các tế bào ác tính phát triển trong dạ dày. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',4,'Tiêu Hóa','["1 túi trà xanh", "1 nhánh bạc hà tươi", "200ml nước sôi"]'::jsonb,'["Cho túi trà xanh và bạc hà vào cốc.", "Đổ nước sôi vào, hãm trong 5-7 phút.", "Uống ngay."]'::jsonb,'Trà xanh và bạc hà có tính kháng viêm, giúp hỗ trợ điều trị ung thư dạ dày.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',24,'Chương 4: Tiêu Hóa','Ung thư dạ dày',3,'a0b869eb550d0b00c35db669a437344bb930065f5e472d9f57114584fba98806',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_tieu_chay_01_sup_chuoi_xanh','unclassified','SÚP CHUỐI XANH','Tiêu chảy là tình trạng đi ngoài phân lỏng nhiều lần trong ngày, thường do nhiễm khuẩn hoặc rối loạn tiêu hóa. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Chuối xanh gọt vỏ, cắt khoanh
Luộc chín với nước dừa
Xay nhuyễn, thêm muối
Dùng ấm',0,0,0,0,0,0,'c04_tieu_chay','Tiêu chảy','Tiêu chảy là tình trạng đi ngoài phân lỏng nhiều lần trong ngày, thường do nhiễm khuẩn hoặc rối loạn tiêu hóa. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["1 quả chuối xanh", "200ml nước dừa tươi", "1/4 thìa muối biển"]'::jsonb,'["Chuối xanh gọt vỏ, cắt khoanh", "Luộc chín với nước dừa", "Xay nhuyễn, thêm muối", "Dùng ấm"]'::jsonb,'Tinh bột kháng trong chuối xanh giúp cầm tiêu chảy, Nước dừa bù điện giải',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',25,'Chương 4: Tiêu Hóa','Tiêu chảy',1,'e97cee95ad40a7b1d56c1b5d0a4449a76c202b431b44a894ce9a4447fdd44b3d',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_tieu_chay_02_canh_rau_sam','unclassified','CANH RAU SAM','Tiêu chảy là tình trạng đi ngoài phân lỏng nhiều lần trong ngày, thường do nhiễm khuẩn hoặc rối loạn tiêu hóa. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Rau sam nhặt sạch
Thịt heo băm nhỏ
Phi hành, xào thịt, thêm nước
Cho rau sam vào khi sôi',0,0,0,0,0,0,'c04_tieu_chay','Tiêu chảy','Tiêu chảy là tình trạng đi ngoài phân lỏng nhiều lần trong ngày, thường do nhiễm khuẩn hoặc rối loạn tiêu hóa. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["100g rau sam tươi", "50g thịt nạc heo", "1 củ hành tím"]'::jsonb,'["Rau sam nhặt sạch", "Thịt heo băm nhỏ", "Phi hành, xào thịt, thêm nước", "Cho rau sam vào khi sôi"]'::jsonb,'Rau sam có tính kháng khuẩn, Cung cấp đạm dễ tiêU',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',25,'Chương 4: Tiêu Hóa','Tiêu chảy',2,'3507800e61f99b71ca8d26aaf1f79b8cab9523d6ef2f1220d731a969af433483',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_tieu_chay_03_canh_rau_ma_va_ca_rot','unclassified','CANH RAU MÁ VÀ CÀ RỐT','Tiêu chảy là tình trạng đi ngoài phân lỏng nhiều lần trong ngày, thường do nhiễm khuẩn hoặc rối loạn tiêu hóa. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.','Rau má rửa sạch, cắt khúc.
Cà rốt gọt vỏ, thái lát.
Phi hành tím với dầu, cho cà rốt vào xào sơ.
Thêm nước, đun sôi rồi cho rau má vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c04_tieu_chay','Tiêu chảy','Tiêu chảy là tình trạng đi ngoài phân lỏng nhiều lần trong ngày, thường do nhiễm khuẩn hoặc rối loạn tiêu hóa. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp cải thiện tình trạng này.',4,'Tiêu Hóa','["200g rau má", "1 củ cà rốt", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Rau má rửa sạch, cắt khúc.", "Cà rốt gọt vỏ, thái lát.", "Phi hành tím với dầu, cho cà rốt vào xào sơ.", "Thêm nước, đun sôi rồi cho rau má vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Rau má và cà rốt giàu chất xơ, giúp cải thiện tiêu hóa và giảm tiêu chảy.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',25,'Chương 4: Tiêu Hóa','Tiêu chảy',3,'7fb4d2869e368c9b8021162772dd91f56350fcc6a978c8a7284d5184678cefc3',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_da_day_ruot_cap_tinh_01_chao_gao_lut_voi_dau_xanh','unclassified','CHÁO GẠO LỨT VỚI ĐẬU XANH','Viêm dạ dày ruột cấp tính là tình trạng viêm niêm mạc dạ dày và ruột, thường do vi khuẩn, virus hoặc ngộ độc thực phẩm gây ra. Triệu chứng phổ biến bao gồm đau bụng, tiêu chảy, buồn nôn, và nôn mửa. Chế độ ăn uống nhẹ nhàng, dễ tiêu sẽ giúp hỗ trợ phục hồi nhanh chóng.','Gạo lứt và đậu xanh rửa sạch, ngâm qua đêm.
Nấu gạo lứt và đậu xanh trong nước cho đến khi cháo nhừ.
Thêm muối vào vừa ăn.',0,0,0,0,0,0,'c04_viem_da_day_ruot_cap_tinh','Viêm dạ dày ruột cấp tính','Viêm dạ dày ruột cấp tính là tình trạng viêm niêm mạc dạ dày và ruột, thường do vi khuẩn, virus hoặc ngộ độc thực phẩm gây ra. Triệu chứng phổ biến bao gồm đau bụng, tiêu chảy, buồn nôn, và nôn mửa. Chế độ ăn uống nhẹ nhàng, dễ tiêu sẽ giúp hỗ trợ phục hồi nhanh chóng.',4,'Tiêu Hóa','["100g gạo lứt", "50g đậu xanh", "1 ít muối"]'::jsonb,'["Gạo lứt và đậu xanh rửa sạch, ngâm qua đêm.", "Nấu gạo lứt và đậu xanh trong nước cho đến khi cháo nhừ.", "Thêm muối vào vừa ăn."]'::jsonb,'Gạo lứt dễ tiêu hóa, giúp làm dịu dạ dày, trong khi đậu xanh thanh nhiệt và hỗ trợ hệ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',26,'Chương 4: Tiêu Hóa','Viêm dạ dày ruột cấp tính',1,'a6a6859314e3202d4bd64c5666e2a073a60c8af52689512e094530d0e311f1a0',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_da_day_ruot_cap_tinh_02_nuoc_ep_dua_hau_va_gung','unclassified','NƯỚC ÉP DƯA HẤU VÀ GỪNG','Viêm dạ dày ruột cấp tính là tình trạng viêm niêm mạc dạ dày và ruột, thường do vi khuẩn, virus hoặc ngộ độc thực phẩm gây ra. Triệu chứng phổ biến bao gồm đau bụng, tiêu chảy, buồn nôn, và nôn mửa. Chế độ ăn uống nhẹ nhàng, dễ tiêu sẽ giúp hỗ trợ phục hồi nhanh chóng.','Dưa hấu gọt vỏ, cắt miếng nhỏ.
Gừng thái lát mỏng.
Cho vào máy xay, xay nhuyễn và lọc qua rây.',0,0,0,0,0,0,'c04_viem_da_day_ruot_cap_tinh','Viêm dạ dày ruột cấp tính','Viêm dạ dày ruột cấp tính là tình trạng viêm niêm mạc dạ dày và ruột, thường do vi khuẩn, virus hoặc ngộ độc thực phẩm gây ra. Triệu chứng phổ biến bao gồm đau bụng, tiêu chảy, buồn nôn, và nôn mửa. Chế độ ăn uống nhẹ nhàng, dễ tiêu sẽ giúp hỗ trợ phục hồi nhanh chóng.',4,'Tiêu Hóa','["200g dưa hấu", "1 lát gừng tươi"]'::jsonb,'["Dưa hấu gọt vỏ, cắt miếng nhỏ.", "Gừng thái lát mỏng.", "Cho vào máy xay, xay nhuyễn và lọc qua rây."]'::jsonb,'Dưa hấu giúp giải độc cơ thể, trong khi gừng giúp giảm viêm và hỗ trợ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',26,'Chương 4: Tiêu Hóa','Viêm dạ dày ruột cấp tính',2,'932e4924fcda94cda365f158f45a230f9c300fbc441830e09693e41a40f6a8ab',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_da_day_ruot_cap_tinh_03_canh_rau_ma_cu_den','unclassified','CANH RAU MÁ CỦ DỀN','Viêm dạ dày ruột cấp tính là tình trạng viêm niêm mạc dạ dày và ruột, thường do vi khuẩn, virus hoặc ngộ độc thực phẩm gây ra. Triệu chứng phổ biến bao gồm đau bụng, tiêu chảy, buồn nôn, và nôn mửa. Chế độ ăn uống nhẹ nhàng, dễ tiêu sẽ giúp hỗ trợ phục hồi nhanh chóng.','Củ dền gọt vỏ, cắt lát. Rau má rửa sạch.
Phi hành tím với dầu ăn, cho củ dền vào đảo qua.
Thêm nước, đun sôi rồi cho rau má vào, nấu chín.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c04_viem_da_day_ruot_cap_tinh','Viêm dạ dày ruột cấp tính','Viêm dạ dày ruột cấp tính là tình trạng viêm niêm mạc dạ dày và ruột, thường do vi khuẩn, virus hoặc ngộ độc thực phẩm gây ra. Triệu chứng phổ biến bao gồm đau bụng, tiêu chảy, buồn nôn, và nôn mửa. Chế độ ăn uống nhẹ nhàng, dễ tiêu sẽ giúp hỗ trợ phục hồi nhanh chóng.',4,'Tiêu Hóa','["100g rau má", "1 củ dền đỏ", "1 củ hành tím", "Gia vị: muối, tiêu"]'::jsonb,'["Củ dền gọt vỏ, cắt lát. Rau má rửa sạch.", "Phi hành tím với dầu ăn, cho củ dền vào đảo qua.", "Thêm nước, đun sôi rồi cho rau má vào, nấu chín.", "Nêm gia vị vừa ăn."]'::jsonb,'Rau má giúp thanh nhiệt, củ dền giàu chất chống oxy hóa, hỗ trợ hệ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',26,'Chương 4: Tiêu Hóa','Viêm dạ dày ruột cấp tính',3,'2ad7fa258b58a707a003cb39dcd99ecf231027d455cd82d08d5ad84807ab36e9',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_ruot_man_tinh_01_canh_ca_loc_nau_rau_can','unclassified','CANH CÁ LÓC NẤU RAU CẦN','Viêm ruột mãn tính là tình trạng viêm kéo dài ở ruột, gây tiêu chảy mãn tính, đau bụng và mệt mỏi. Nguyên nhân có thể là bệnh Crohn, viêm đại tràng hoặc rối loạn miễn dịch.','Cá lóc làm sạch, cắt khúc vừa ăn.
Rau cần rửa sạch, cắt khúc.
Phi hành với dầu ăn cho thơm, sau đó cho cá vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau cần vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c04_viem_ruot_man_tinh','Viêm ruột mãn tính','Viêm ruột mãn tính là tình trạng viêm kéo dài ở ruột, gây tiêu chảy mãn tính, đau bụng và mệt mỏi. Nguyên nhân có thể là bệnh Crohn, viêm đại tràng hoặc rối loạn miễn dịch.',4,'Tiêu Hóa','["200g cá lóc", "100g rau cần", "Gia vị: muối, tiêu"]'::jsonb,'["Cá lóc làm sạch, cắt khúc vừa ăn.", "Rau cần rửa sạch, cắt khúc.", "Phi hành với dầu ăn cho thơm, sau đó cho cá vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau cần vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Cá lóc dễ tiêu hóa, giúp phục hồi sức khỏe ruột, rau cần giúp giải độc và làm mát cơ thể.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',27,'Chương 4: Tiêu Hóa','Viêm ruột mãn tính',1,'70ce2046449c04a310acdb54294032e0fe4a85c676d9a7a75a7ee9a72ed81626',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_ruot_man_tinh_02_nuoc_ep_ca_rot_va_cu_cai_do','unclassified','NƯỚC ÉP CÀ RỐT VÀ CỦ CẢI ĐỎ','Viêm ruột mãn tính là tình trạng viêm kéo dài ở ruột, gây tiêu chảy mãn tính, đau bụng và mệt mỏi. Nguyên nhân có thể là bệnh Crohn, viêm đại tràng hoặc rối loạn miễn dịch.','Cà rốt và củ cải đỏ gọt vỏ, cắt miếng vừa ăn.
Cho vào máy xay sinh tố, xay nhuyễn.
Lọc qua rây và thưởng thức.',0,0,0,0,0,0,'c04_viem_ruot_man_tinh','Viêm ruột mãn tính','Viêm ruột mãn tính là tình trạng viêm kéo dài ở ruột, gây tiêu chảy mãn tính, đau bụng và mệt mỏi. Nguyên nhân có thể là bệnh Crohn, viêm đại tràng hoặc rối loạn miễn dịch.',4,'Tiêu Hóa','["2 củ cà rốt", "1 củ cải đỏ"]'::jsonb,'["Cà rốt và củ cải đỏ gọt vỏ, cắt miếng vừa ăn.", "Cho vào máy xay sinh tố, xay nhuyễn.", "Lọc qua rây và thưởng thức."]'::jsonb,'Cà rốt và củ cải đỏ cung cấp nhiều vitamin giúp tăng cường sức khỏe ruột, hỗ trợ phục hồi viêm ruột mãn tính.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',27,'Chương 4: Tiêu Hóa','Viêm ruột mãn tính',2,'0cd6425b93d1e9f6aff2597471f8de02def1396b42113f7bae17ca875b065336',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_viem_ruot_man_tinh_03_canh_dau_bap_nau_nam_rom','unclassified','Canh đậu bắp nấu nấm rơm','Viêm ruột mãn tính là tình trạng viêm kéo dài ở ruột, gây tiêu chảy mãn tính, đau bụng và mệt mỏi. Nguyên nhân có thể là bệnh Crohn, viêm đại tràng hoặc rối loạn miễn dịch.','Đậu bắp rửa sạch, cắt khúc. Nấm rơm rửa sạch, cắt đôi.
Phi hành với dầu ăn cho thơm, cho nấm rơm vào xào sơ.
Thêm nước, đun sôi rồi cho đậu bắp vào nấu chín.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c04_viem_ruot_man_tinh','Viêm ruột mãn tính','Viêm ruột mãn tính là tình trạng viêm kéo dài ở ruột, gây tiêu chảy mãn tính, đau bụng và mệt mỏi. Nguyên nhân có thể là bệnh Crohn, viêm đại tràng hoặc rối loạn miễn dịch.',4,'Tiêu Hóa','["200g đậu bắp", "100g nấm rơm", "1 củ hành tím", "Gia vị: muối, tiêu"]'::jsonb,'["Đậu bắp rửa sạch, cắt khúc. Nấm rơm rửa sạch, cắt đôi.", "Phi hành với dầu ăn cho thơm, cho nấm rơm vào xào sơ.", "Thêm nước, đun sôi rồi cho đậu bắp vào nấu chín.", "Nêm gia vị vừa ăn."]'::jsonb,'Đậu bắp giàu chất nhầy giúp bôi trơn ruột, giảm táo bón, nấm rơm hỗ trợ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',28,'Chương 4: Tiêu Hóa','Viêm ruột mãn tính',3,'65e5ddc5cc378c419c2ebdaf2c5ec71e80414972fdd79bdb3ca378938711db62',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_tao_bon_01_chao_bot_gao_voi_hat_chia','unclassified','CHÁO BỘT GẠO VỚI HẠT CHIA','Táo bón là tình trạng khó đi tiêu, phân cứng và khô, gây đau đớn khi đại tiện. Nguyên nhân chủ yếu là thiếu chất xơ, ít vận động hoặc chế độ ăn uống không đủ nước.','Nấu bột gạo với nước cho đến khi cháo nhừ.
Thêm hạt chia vào khuấy đều, nấu thêm 5 phút.
Thêm đường phèn vào và khuấy đều.',0,0,0,0,0,0,'c04_tao_bon','Táo bón','Táo bón là tình trạng khó đi tiêu, phân cứng và khô, gây đau đớn khi đại tiện. Nguyên nhân chủ yếu là thiếu chất xơ, ít vận động hoặc chế độ ăn uống không đủ nước.',4,'Tiêu Hóa','["50g bột gạo", "1 thìa hạt chia", "1 ít đường phèn"]'::jsonb,'["Nấu bột gạo với nước cho đến khi cháo nhừ.", "Thêm hạt chia vào khuấy đều, nấu thêm 5 phút.", "Thêm đường phèn vào và khuấy đều."]'::jsonb,'Bột gạo dễ tiêu hóa, hạt chia chứa nhiều chất xơ giúp làm mềm phân và hỗ trợ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',28,'Chương 4: Tiêu Hóa','Táo bón',1,'2017bebedf69db6a18708236da028538fadaef26ccbfd462bd0afd559ae19dec',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_tao_bon_02_nuoc_ep_mat_ong_va_chanh','unclassified','NƯỚC ÉP MẬT ONG VÀ CHANH','Táo bón là tình trạng khó đi tiêu, phân cứng và khô, gây đau đớn khi đại tiện. Nguyên nhân chủ yếu là thiếu chất xơ, ít vận động hoặc chế độ ăn uống không đủ nước.','Vắt lấy nước chanh.
Thêm mật ong vào khuấy đều và uống ngay.',0,0,0,0,0,0,'c04_tao_bon','Táo bón','Táo bón là tình trạng khó đi tiêu, phân cứng và khô, gây đau đớn khi đại tiện. Nguyên nhân chủ yếu là thiếu chất xơ, ít vận động hoặc chế độ ăn uống không đủ nước.',4,'Tiêu Hóa','["1 quả chanh", "1 thìa mật ong"]'::jsonb,'["Vắt lấy nước chanh.", "Thêm mật ong vào khuấy đều và uống ngay."]'::jsonb,'Chanh giúp làm sạch ruột, mật ong giúp kích thích nhu động ruột và hỗ trợ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',29,'Chương 4: Tiêu Hóa','Táo bón',2,'e8dd26d5a283b2632487d298b7b8377b8ccd6db030cbbab4d42fa45a3f2bdb28',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_tao_bon_03_canh_mong_toi_nau_cua','unclassified','CANH MỒNG TƠI NẤU CUA','Táo bón là tình trạng khó đi tiêu, phân cứng và khô, gây đau đớn khi đại tiện. Nguyên nhân chủ yếu là thiếu chất xơ, ít vận động hoặc chế độ ăn uống không đủ nước.','Cua đồng xay lọc lấy nước, bỏ bã.
Rau mồng tơi nhặt sạch, rửa kỹ.
Đun sôi nước cua, vớt bọt.
Cho rau mồng tơi vào, nấu chín và nêm gia vị vừa ăn.',0,0,0,0,0,0,'c04_tao_bon','Táo bón','Táo bón là tình trạng khó đi tiêu, phân cứng và khô, gây đau đớn khi đại tiện. Nguyên nhân chủ yếu là thiếu chất xơ, ít vận động hoặc chế độ ăn uống không đủ nước.',4,'Tiêu Hóa','["200g cua đồng xay", "100g rau mồng tơi"]'::jsonb,'["Cua đồng xay lọc lấy nước, bỏ bã.", "Rau mồng tơi nhặt sạch, rửa kỹ.", "Đun sôi nước cua, vớt bọt.", "Cho rau mồng tơi vào, nấu chín và nêm gia vị vừa ăn."]'::jsonb,'Cua đồng giàu canxi tốt cho hệ xương, rau mồng tơi giúp nhuận tràng, hỗ trợ tiêu hóa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',29,'Chương 4: Tiêu Hóa','Táo bón',3,'11a2d49cbf29a3b60b7bf5ad2810cee322c477424a8ac3492cc8c2500c5b846f',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_benh_tri_01_canh_cu_cai_va_rau_cai_bo_xoi','unclassified','CANH CỦ CẢI VÀ RAU CẢI BÓ XÔI','Bệnh trĩ là tình trạng tĩnh mạch ở hậu môn bị sưng, đau và có thể gây chảy máu. Nguyên nhân chủ yếu là táo bón mãn tính, mang vác nặng hoặc ngồi lâu.','Củ cải gọt vỏ, cắt miếng nhỏ.
Cải bó xôi rửa sạch, cắt khúc.
Nấu củ cải trong nước cho đến khi mềm, sau đó cho cải bó xôi vào nấu chín.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c04_benh_tri','Bệnh trĩ','Bệnh trĩ là tình trạng tĩnh mạch ở hậu môn bị sưng, đau và có thể gây chảy máu. Nguyên nhân chủ yếu là táo bón mãn tính, mang vác nặng hoặc ngồi lâu.',4,'Tiêu Hóa','["200g củ cải", "100g cải bó xôi", "Gia vị: muối, tiêu"]'::jsonb,'["Củ cải gọt vỏ, cắt miếng nhỏ.", "Cải bó xôi rửa sạch, cắt khúc.", "Nấu củ cải trong nước cho đến khi mềm, sau đó cho cải bó xôi vào nấu chín.", "Nêm gia vị vừa ăn."]'::jsonb,'Củ cải giúp làm sạch hệ tiêu hóa, cải bó xôi bổ sung chất xơ giúp dễ dàng đi tiêu, ngăn ngừa táo bón và bệnh trĩ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',30,'Chương 4: Tiêu Hóa','Bệnh trĩ',1,'e48eefa4e8c405c4b985d1a332888e02376b6ba7dce9ab5a3715a62510d2ff5e',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_benh_tri_02_sinh_to_ca_rot_va_cu_den','unclassified','SINH TỐ CÀ RỐT VÀ CỦ DỀN','Bệnh trĩ là tình trạng tĩnh mạch ở hậu môn bị sưng, đau và có thể gây chảy máu. Nguyên nhân chủ yếu là táo bón mãn tính, mang vác nặng hoặc ngồi lâu.','Cà rốt và củ dền gọt vỏ, cắt miếng nhỏ.
Cho vào máy xay sinh tố, xay nhuyễn.
Lọc qua rây và uống ngay.',0,0,0,0,0,0,'c04_benh_tri','Bệnh trĩ','Bệnh trĩ là tình trạng tĩnh mạch ở hậu môn bị sưng, đau và có thể gây chảy máu. Nguyên nhân chủ yếu là táo bón mãn tính, mang vác nặng hoặc ngồi lâu.',4,'Tiêu Hóa','["1 củ cà rốt", "1 củ dền"]'::jsonb,'["Cà rốt và củ dền gọt vỏ, cắt miếng nhỏ.", "Cho vào máy xay sinh tố, xay nhuyễn.", "Lọc qua rây và uống ngay."]'::jsonb,'Cà rốt và củ dền cung cấp nhiều vitamin A và chất xơ giúp nhuận tràng và phòng',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',30,'Chương 4: Tiêu Hóa','Bệnh trĩ',2,'16919949ba9c1a697f1c91d0465e97490bd65cc22f4a5637a57684aa7c3a26ea',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_ung_thu_truc_trang_01_sinh_to_rau_bina_va_dua_chuot','unclassified','SINH TỐ RAU BINA VÀ DƯA CHUỘT','Ung thư trực tràng là tình trạng các tế bào ác tính phát triển trong trực tràng. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Rau bina và dưa chuột rửa sạch, cắt nhỏ.
Cho rau bina, dưa chuột, nước và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c04_ung_thu_truc_trang','Ung thư trực tràng','Ung thư trực tràng là tình trạng các tế bào ác tính phát triển trong trực tràng. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',4,'Tiêu Hóa','["1 nắm rau bina", "1 quả dưa chuột", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Rau bina và dưa chuột rửa sạch, cắt nhỏ.", "Cho rau bina, dưa chuột, nước và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Rau bina và dưa chuột giàu chất chống oxy hóa, giúp hỗ trợ điều trị ung thư trực tràng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',30,'Chương 4: Tiêu Hóa','Ung thư trực tràng',1,'ba2a2f4f5f301294fae843466dc0594cd30ea5fbf8d74f2d9e31ecaf83af3a42',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_ung_thu_truc_trang_02_canh_nam_huong_va_dau_hu','unclassified','CANH NẤM HƯƠNG VÀ ĐẬU HŨ','Ung thư trực tràng là tình trạng các tế bào ác tính phát triển trong trực tràng. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Nấm hương ngâm nở, rửa sạch.
Đậu hũ cắt miếng vừa ăn.
Phi hành tím với dầu, cho nấm vào xào sơ.
Thêm nước, đun sôi rồi cho đậu hũ vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c04_ung_thu_truc_trang','Ung thư trực tràng','Ung thư trực tràng là tình trạng các tế bào ác tính phát triển trong trực tràng. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',4,'Tiêu Hóa','["200g nấm hương", "200g đậu hũ", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Nấm hương ngâm nở, rửa sạch.", "Đậu hũ cắt miếng vừa ăn.", "Phi hành tím với dầu, cho nấm vào xào sơ.", "Thêm nước, đun sôi rồi cho đậu hũ vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Nấm hương có tính kháng viêm, đậu hũ giàu protein giúp tăng cường hệ miễn dịch.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',31,'Chương 4: Tiêu Hóa','Ung thư trực tràng',2,'f240376b9b6f3efa0c3bdbb13141367724f4d1ac3c475263e27f7c4be52ba914',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c04_ung_thu_truc_trang_03_tra_xanh_va_bac_ha','unclassified','TRÀ XANH VÀ BẠC HÀ','Ung thư trực tràng là tình trạng các tế bào ác tính phát triển trong trực tràng. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Cho túi trà xanh và bạc hà vào cốc.
Đổ nước sôi vào, hãm trong 5-7 phút.
Uống ngay.',0,0,0,0,0,0,'c04_ung_thu_truc_trang','Ung thư trực tràng','Ung thư trực tràng là tình trạng các tế bào ác tính phát triển trong trực tràng. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',4,'Tiêu Hóa','["1 túi trà xanh", "1 nhánh bạc hà tươi", "200ml nước sôi"]'::jsonb,'["Cho túi trà xanh và bạc hà vào cốc.", "Đổ nước sôi vào, hãm trong 5-7 phút.", "Uống ngay."]'::jsonb,'Trà xanh và bạc hà có tính kháng viêm, giúp hỗ trợ điều trị ung thư trực tràng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',31,'Chương 4: Tiêu Hóa','Ung thư trực tràng',3,'e46f28a41715760da338756986b8d82dd235fd25381aec1be15afe3cb5def7d8',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_tieu_duong_01_nuoc_ep_kho_qua_va_tao_xanh','unclassified','NƯỚC ÉP KHỔ QUA VÀ TÁO XANH','Bệnh tiểu đường là tình trạng cơ thể không sản xuất đủ insulin hoặc không sử dụng insulin hiệu quả, dẫn đến lượng đường trong máu cao. Chế độ ăn uống ít đường và giàu chất xơ có thể giúp kiểm soát bệnh.','Khổ qua rửa sạch, bỏ hạt, thái lát mỏng.
Táo xanh rửa sạch, cắt miếng.
Cho tất cả vào máy xay sinh tố cùng nước, xay nhuyễn và lọc qua rây',0,0,0,0,0,0,'c05_benh_tieu_duong','Bệnh tiểu đường','Bệnh tiểu đường là tình trạng cơ thể không sản xuất đủ insulin hoặc không sử dụng insulin hiệu quả, dẫn đến lượng đường trong máu cao. Chế độ ăn uống ít đường và giàu chất xơ có thể giúp kiểm soát bệnh.',5,'Nội Tiết Và Chuyển Hóa','["1 quả khổ qua", "1 quả táo xanh", "200ml nước lọc"]'::jsonb,'["Khổ qua rửa sạch, bỏ hạt, thái lát mỏng.", "Táo xanh rửa sạch, cắt miếng.", "Cho tất cả vào máy xay sinh tố cùng nước, xay nhuyễn và lọc qua rây"]'::jsonb,'Khổ qua giúp hạ đường huyết, táo xanh cung cấp vitamin C và chất xơ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',32,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh tiểu đường',1,'95bd278a506d69cadf85fc921b281dc7ed000be8c022bcb7fd02f1e17dd8909d',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_tieu_duong_02_canh_bi_dao_va_nam','unclassified','CANH BÍ ĐAO VÀ NẤM','Bệnh tiểu đường là tình trạng cơ thể không sản xuất đủ insulin hoặc không sử dụng insulin hiệu quả, dẫn đến lượng đường trong máu cao. Chế độ ăn uống ít đường và giàu chất xơ có thể giúp kiểm soát bệnh.','Bí đao gọt vỏ, cắt miếng vừa ăn.
Nấm hương ngâm nở, rửa sạch.
Phi hành tím với dầu, cho nấm vào xào sơ.
Thêm nước, đun sôi rồi cho bí đao vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c05_benh_tieu_duong','Bệnh tiểu đường','Bệnh tiểu đường là tình trạng cơ thể không sản xuất đủ insulin hoặc không sử dụng insulin hiệu quả, dẫn đến lượng đường trong máu cao. Chế độ ăn uống ít đường và giàu chất xơ có thể giúp kiểm soát bệnh.',5,'Nội Tiết Và Chuyển Hóa','["300g bí đao", "100g nấm hương", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Bí đao gọt vỏ, cắt miếng vừa ăn.", "Nấm hương ngâm nở, rửa sạch.", "Phi hành tím với dầu, cho nấm vào xào sơ.", "Thêm nước, đun sôi rồi cho bí đao vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Bí đao và nấm hương giàu chất xơ, giúp kiểm soát lượng đường trong máu.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',32,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh tiểu đường',2,'b07e384487d441bf54e506706171c2f5dfa22f7f7356be57b552583fb63d8374',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_tieu_duong_03_tra_la_xoai','unclassified','TRÀ LÁ XOÀI','Bệnh tiểu đường là tình trạng cơ thể không sản xuất đủ insulin hoặc không sử dụng insulin hiệu quả, dẫn đến lượng đường trong máu cao. Chế độ ăn uống ít đường và giàu chất xơ có thể giúp kiểm soát bệnh.','Lá xoài rửa sạch, để ráo.
Cho lá xoài vào nước sôi, hãm trong 10 phút.
Uống ngay.',0,0,0,0,0,0,'c05_benh_tieu_duong','Bệnh tiểu đường','Bệnh tiểu đường là tình trạng cơ thể không sản xuất đủ insulin hoặc không sử dụng insulin hiệu quả, dẫn đến lượng đường trong máu cao. Chế độ ăn uống ít đường và giàu chất xơ có thể giúp kiểm soát bệnh.',5,'Nội Tiết Và Chuyển Hóa','["5-7 lá xoài tươi", "200ml nước sôi"]'::jsonb,'["Lá xoài rửa sạch, để ráo.", "Cho lá xoài vào nước sôi, hãm trong 10 phút.", "Uống ngay."]'::jsonb,'Lá xoài có tác dụng giúp ổn định lượng đường trong máu, hỗ trợ điều trị bệnh tiểu đường.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',32,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh tiểu đường',3,'dae83658c27d31def3785377979e986c1ebb69206679b1afccd9b88361dc3dd9',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_mo_mau_01_canh_dau_den_va_rong_bien','unclassified','CANH ĐẬU ĐEN VÀ RONG BIỂN','Bệnh mỡ máu là tình trạng rối loạn chuyển hóa lipid, khiến nồng độ cholesterol xấu (LDL) và triglyceride trong máu tăng cao, đồng thời giảm cholesterol tốt (HDL). Chế độ ăn ít chất béo bão hòa, giàu chất xơ và omega-3 có thể giúp kiểm soát bệnh hiệu quả.','Đậu đen ngâm nước 4 tiếng, rửa sạch.
Rong biển ngâm nở, rửa sạch.
Phi thơm hành tím, cho đậu đen vào xào sơ.
Thêm nước dùng, ninh nhừ đậu.
Cho rong biển vào đun thêm 5 phút.',0,0,0,0,0,0,'c05_benh_mo_mau','Bệnh Mỡ Máu','Bệnh mỡ máu là tình trạng rối loạn chuyển hóa lipid, khiến nồng độ cholesterol xấu (LDL) và triglyceride trong máu tăng cao, đồng thời giảm cholesterol tốt (HDL). Chế độ ăn ít chất béo bão hòa, giàu chất xơ và omega-3 có thể giúp kiểm soát bệnh hiệu quả.',5,'Nội Tiết Và Chuyển Hóa','["50g đậu đen", "10g rong biển khô", "1 củ hành tím", "500ml nước dùng rau củ"]'::jsonb,'["Đậu đen ngâm nước 4 tiếng, rửa sạch.", "Rong biển ngâm nở, rửa sạch.", "Phi thơm hành tím, cho đậu đen vào xào sơ.", "Thêm nước dùng, ninh nhừ đậu.", "Cho rong biển vào đun thêm 5 phút."]'::jsonb,'Đậu đen giàu chất xơ hòa tan giúp giảm cholesterol, rong biển chứa alginate hỗ trợ đào thải mỡ thừa.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',33,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh Mỡ Máu',1,'fe7b922cfdfabcec4464d195cde0ed083abfc8f9117754fa97aa133885d97f80',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_mo_mau_02_salad_cai_bo_xoi_va_qua_bo','unclassified','SALAD CẢI BÓ XÔI VÀ QUẢ BƠ','Bệnh mỡ máu là tình trạng rối loạn chuyển hóa lipid, khiến nồng độ cholesterol xấu (LDL) và triglyceride trong máu tăng cao, đồng thời giảm cholesterol tốt (HDL). Chế độ ăn ít chất béo bão hòa, giàu chất xơ và omega-3 có thể giúp kiểm soát bệnh hiệu quả.','Cải rửa sạch ngâm nước muối
Bơ thái lát mỏng
Trộn đều với dầu oliu và hạt óc chó',0,0,0,0,0,0,'c05_benh_mo_mau','Bệnh Mỡ Máu','Bệnh mỡ máu là tình trạng rối loạn chuyển hóa lipid, khiến nồng độ cholesterol xấu (LDL) và triglyceride trong máu tăng cao, đồng thời giảm cholesterol tốt (HDL). Chế độ ăn ít chất béo bão hòa, giàu chất xơ và omega-3 có thể giúp kiểm soát bệnh hiệu quả.',5,'Nội Tiết Và Chuyển Hóa','["100g cải bó xôi non", "1/2 quả bơ chín", "5 hạt óc chó", "1 thìa dầu oliu"]'::jsonb,'["Cải rửa sạch ngâm nước muối", "Bơ thái lát mỏng", "Trộn đều với dầu oliu và hạt óc chó"]'::jsonb,'Omega-3 từ bơ và óc chó giảm triglyceride, Chất xơ trong cải đào thải cholesterol',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',33,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh Mỡ Máu',2,'4db06a14ead86d7b9e70d158e0869b54b4e5b7fcaae0c92ad0351014fd09b7c0',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_mo_mau_03_tra_gung_nghe_mat_ong','unclassified','TRÀ GỪNG NGHỆ MẬT ONG','Bệnh mỡ máu là tình trạng rối loạn chuyển hóa lipid, khiến nồng độ cholesterol xấu (LDL) và triglyceride trong máu tăng cao, đồng thời giảm cholesterol tốt (HDL). Chế độ ăn ít chất béo bão hòa, giàu chất xơ và omega-3 có thể giúp kiểm soát bệnh hiệu quả.','Gừng rửa sạch, đập dập
Cho gừng và nghệ vào cốc, chế nước sôi ủ 10 phút
Thêm mật ong khuấy đều',0,0,0,0,0,0,'c05_benh_mo_mau','Bệnh Mỡ Máu','Bệnh mỡ máu là tình trạng rối loạn chuyển hóa lipid, khiến nồng độ cholesterol xấu (LDL) và triglyceride trong máu tăng cao, đồng thời giảm cholesterol tốt (HDL). Chế độ ăn ít chất béo bão hòa, giàu chất xơ và omega-3 có thể giúp kiểm soát bệnh hiệu quả.',5,'Nội Tiết Và Chuyển Hóa','["1 củ gừng tươi bằng ngón tay", "1/2 thìa bột nghệ", "1 thìa mật ong nguyên chất", "300ml nước sôi"]'::jsonb,'["Gừng rửa sạch, đập dập", "Cho gừng và nghệ vào cốc, chế nước sôi ủ 10 phút", "Thêm mật ong khuấy đều"]'::jsonb,'Gừng tăng tuần hoàn máu, Nghệ giảm viêm thành mạch,Mật ong chống oxy hóa',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',33,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh Mỡ Máu',3,'d6b4d2a18dd4d054a45bbea58dc92847d57aebe0d3cbcdc1b59914f244118e93',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_gut_01_sinh_to_dua_hau_va_dua_chuot','unclassified','SINH TỐ DƯA HẤU VÀ DƯA CHUỘT','Bệnh gút là tình trạng viêm khớp do sự tích tụ axit uric trong cơ thể. Chế độ ăn uống ít purin và giàu chất chống viêm có thể giúp cải thiện tình trạng này.','Dưa hấu và dưa chuột rửa sạch, cắt nhỏ.
Cho dưa hấu, dưa chuột, nước và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c05_benh_gut','Bệnh gút','Bệnh gút là tình trạng viêm khớp do sự tích tụ axit uric trong cơ thể. Chế độ ăn uống ít purin và giàu chất chống viêm có thể giúp cải thiện tình trạng này.',5,'Nội Tiết Và Chuyển Hóa','["200g dưa hấu", "1 quả dưa chuột", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Dưa hấu và dưa chuột rửa sạch, cắt nhỏ.", "Cho dưa hấu, dưa chuột, nước và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Dưa hấu và dưa chuột giàu nước và chất chống oxy hóa, giúp đào thải axit uric và giảm viêm.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',34,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh gút',1,'c0bf9b1911a829d86f3c500795f252f9bd5d46d057ab09cab8830dd89375bb0d',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_gut_02_canh_rau_can_tay_va_ca_rot','unclassified','CANH RAU CẦN TÂY VÀ CÀ RỐT','Bệnh gút là tình trạng viêm khớp do sự tích tụ axit uric trong cơ thể. Chế độ ăn uống ít purin và giàu chất chống viêm có thể giúp cải thiện tình trạng này.','Rau cần tây rửa sạch, cắt khúc.
Cà rốt gọt vỏ, thái lát.
Phi hành tím với dầu, cho cà rốt vào xào sơ.
Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c05_benh_gut','Bệnh gút','Bệnh gút là tình trạng viêm khớp do sự tích tụ axit uric trong cơ thể. Chế độ ăn uống ít purin và giàu chất chống viêm có thể giúp cải thiện tình trạng này.',5,'Nội Tiết Và Chuyển Hóa','["200g rau cần tây", "1 củ cà rốt", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Rau cần tây rửa sạch, cắt khúc.", "Cà rốt gọt vỏ, thái lát.", "Phi hành tím với dầu, cho cà rốt vào xào sơ.", "Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Rau cần tây và cà rốt giàu chất xơ, giúp đào thải axit uric và giảm viêm.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',34,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh gút',2,'b13c6b0a21495f796aa2c3ae008d9067dc2360bb28e1bf9ea918061e694481a7',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_benh_gut_03_tra_gung_va_mat_ong','unclassified','TRÀ GỪNG VÀ MẬT ONG','Bệnh gút là tình trạng viêm khớp do sự tích tụ axit uric trong cơ thể. Chế độ ăn uống ít purin và giàu chất chống viêm có thể giúp cải thiện tình trạng này.','Gừng rửa sạch, thái lát.
Cho gừng vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c05_benh_gut','Bệnh gút','Bệnh gút là tình trạng viêm khớp do sự tích tụ axit uric trong cơ thể. Chế độ ăn uống ít purin và giàu chất chống viêm có thể giúp cải thiện tình trạng này.',5,'Nội Tiết Và Chuyển Hóa','["1 củ gừng nhỏ", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Gừng rửa sạch, thái lát.", "Cho gừng vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Gừng có tính kháng viêm, mật ong giúp tăng cường hệ miễn dịch, hỗ trợ điều trị bệnh gút.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',34,'Chương 5: Nội Tiết Và Chuyển Hóa','Bệnh gút',3,'edecb55360323c47daf871fc6fe33ce7afe8e4acb07cb606122e1e1fa50ac31a',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_viem_than_cap_01_sup_bi_do_hat_sen','unclassified','SÚP BÍ ĐỎ HẠT SEN','Viêm thận cấp là tình trạng viêm nhiễm cấp tính ở thận, thường do nhiễm khuẩn hoặc độc tố. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp hỗ trợ điều trị.','Bí đỏ gọt vỏ, cắt miếng
Hạt sen bỏ tâm, rửa sạch
Cho bí đỏ, hạt sen vào nồi ninh nhừ
Thêm gừng đập dập khi gần chín',0,0,0,0,0,0,'c05_viem_than_cap','Viêm thận cấp','Viêm thận cấp là tình trạng viêm nhiễm cấp tính ở thận, thường do nhiễm khuẩn hoặc độc tố. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp hỗ trợ điều trị.',5,'Nội Tiết Và Chuyển Hóa','["200g bí đỏ", "30g hạt sen tươi", "1 nhánh gừng nhỏ", "500ml nước lọc"]'::jsonb,'["Bí đỏ gọt vỏ, cắt miếng", "Hạt sen bỏ tâm, rửa sạch", "Cho bí đỏ, hạt sen vào nồi ninh nhừ", "Thêm gừng đập dập khi gần chín"]'::jsonb,'Bí đỏ giàu beta-carotene giúp phục hồi tế bào thận, Hạt sen có tác dụng an thần, giảm phù nề, Gừng tăng tuần hoàn máu đến thận',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',35,'Chương 5: Nội Tiết Và Chuyển Hóa','Viêm thận cấp',1,'752f1407e096d0b5da0a1d8b0ce2b5e58d8c28c3a8f918268939d32fd549e17e',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_viem_than_cap_02_chao_gao_lut_dau_den','unclassified','CHÁO GẠO LỨT ĐẬU ĐEN','Viêm thận cấp là tình trạng viêm nhiễm cấp tính ở thận, thường do nhiễm khuẩn hoặc độc tố. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp hỗ trợ điều trị.','Gạo lứt và đậu đen ngâm 4 tiếng
Phi thơm hành tím, cho gạo và đậu vào xào sơ
Thêm nước ninh nhừ thành cháo
Nêm nhạt bằng chút muối biển',0,0,0,0,0,0,'c05_viem_than_cap','Viêm thận cấp','Viêm thận cấp là tình trạng viêm nhiễm cấp tính ở thận, thường do nhiễm khuẩn hoặc độc tố. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp hỗ trợ điều trị.',5,'Nội Tiết Và Chuyển Hóa','["50g gạo lứt", "30g đậu đen (đã ngâm)", "1 củ hành tím", "700ml nước"]'::jsonb,'["Gạo lứt và đậu đen ngâm 4 tiếng", "Phi thơm hành tím, cho gạo và đậu vào xào sơ", "Thêm nước ninh nhừ thành cháo", "Nêm nhạt bằng chút muối biển"]'::jsonb,'Đậu đen giàu anthocyanin chống viêm thận, Gạo lứt cung cấp vitamin nhóm B,',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',35,'Chương 5: Nội Tiết Và Chuyển Hóa','Viêm thận cấp',2,'c975e8eef69713062de3a955079fe4f83f24ae8bd1ebdd7b957a404d4f906f9f',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_viem_than_cap_03_sinh_to_dua_hau_va_bac_ha','unclassified','SINH TỐ DƯA HẤU VÀ BẠC HÀ','Viêm thận cấp là tình trạng viêm nhiễm cấp tính ở thận, thường do nhiễm khuẩn hoặc độc tố. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp hỗ trợ điều trị.','Dưa hấu cắt miếng nhỏ
Cho vào máy xay cùng bạc hà, nước cốt chanh
Xay nhuyễn, lọc qua rây nếu cần',0,0,0,0,0,0,'c05_viem_than_cap','Viêm thận cấp','Viêm thận cấp là tình trạng viêm nhiễm cấp tính ở thận, thường do nhiễm khuẩn hoặc độc tố. Chế độ ăn uống nhẹ nhàng và giàu chất dinh dưỡng có thể giúp hỗ trợ điều trị.',5,'Nội Tiết Và Chuyển Hóa','["200g dưa hấu (bỏ hạt)", "5 lá bạc hà", "1 thìa nước cốt chanh", "100ml nước ấm"]'::jsonb,'["Dưa hấu cắt miếng nhỏ", "Cho vào máy xay cùng bạc hà, nước cốt chanh", "Xay nhuyễn, lọc qua rây nếu cần"]'::jsonb,'Dưa hấu lợi tiểu nhẹ, giảm phù, Bạc hà giúp giải độc thận, Chanh cân bằng điện giải',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',35,'Chương 5: Nội Tiết Và Chuyển Hóa','Viêm thận cấp',3,'2062e2c8114fa39709adf28dd7be0622b4d51696d610bf30e80a89eab3e41e3c',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_soi_than_01_nuoc_ep_buoi_va_tao_do','unclassified','Nước ép bưởi và táo đỏ','Sỏi thận là tình trạng các tinh thể khoáng chất tích tụ trong thận, gây đau và khó chịu. Chế độ ăn uống giàu chất xơ và uống nhiều nước có thể giúp ngăn ngừa và hỗ trợ điều trị sỏi thận.','Bưởi bóc vỏ, bỏ hạt, lấy tép.
Táo đỏ rửa sạch, cắt miếng nhỏ.
Cho vào máy ép lấy nước, có thể thêm ít mật ong.',0,0,0,0,0,0,'c05_soi_than','Sỏi thận','Sỏi thận là tình trạng các tinh thể khoáng chất tích tụ trong thận, gây đau và khó chịu. Chế độ ăn uống giàu chất xơ và uống nhiều nước có thể giúp ngăn ngừa và hỗ trợ điều trị sỏi thận.',5,'Nội Tiết Và Chuyển Hóa','["1/2 quả bưởi", "1 quả táo đỏ", "200ml nước"]'::jsonb,'["Bưởi bóc vỏ, bỏ hạt, lấy tép.", "Táo đỏ rửa sạch, cắt miếng nhỏ.", "Cho vào máy ép lấy nước, có thể thêm ít mật ong."]'::jsonb,'Bưởi giúp lợi tiểu, táo đỏ hỗ trợ thanh lọc thận.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',36,'Chương 5: Nội Tiết Và Chuyển Hóa','Sỏi thận',1,'03c31d2c18b152456d3bf46e5830b7bf28eca919e626e57b48027e37d60f6ce6',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_soi_than_02_canh_rau_can_tay_va_ca_rot','unclassified','CANH RAU CẦN TÂY VÀ CÀ RỐT','Sỏi thận là tình trạng các tinh thể khoáng chất tích tụ trong thận, gây đau và khó chịu. Chế độ ăn uống giàu chất xơ và uống nhiều nước có thể giúp ngăn ngừa và hỗ trợ điều trị sỏi thận.','Rau cần tây rửa sạch, cắt khúc.
Cà rốt gọt vỏ, thái lát.
Phi hành tím với dầu, cho cà rốt vào xào sơ.
Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c05_soi_than','Sỏi thận','Sỏi thận là tình trạng các tinh thể khoáng chất tích tụ trong thận, gây đau và khó chịu. Chế độ ăn uống giàu chất xơ và uống nhiều nước có thể giúp ngăn ngừa và hỗ trợ điều trị sỏi thận.',5,'Nội Tiết Và Chuyển Hóa','["200g rau cần tây", "1 củ cà rốt", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Rau cần tây rửa sạch, cắt khúc.", "Cà rốt gọt vỏ, thái lát.", "Phi hành tím với dầu, cho cà rốt vào xào sơ.", "Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Rau cần tây và cà rốt giàu chất xơ, giúp đào thải độc tố và ngăn ngừa sỏi thận.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',36,'Chương 5: Nội Tiết Và Chuyển Hóa','Sỏi thận',2,'ad1d891c49b0bda3a9392c7814b653e571f30e3436f627faff4a2027907b69ec',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c05_soi_than_03_tra_cam_thao_va_que','unclassified','TRÀ CAM THẢO VÀ QUẾ','Sỏi thận là tình trạng các tinh thể khoáng chất tích tụ trong thận, gây đau và khó chịu. Chế độ ăn uống giàu chất xơ và uống nhiều nước có thể giúp ngăn ngừa và hỗ trợ điều trị sỏi thận.','Đun sôi nước, cho cam thảo và quế vào hãm 5 phút.
Lọc bỏ bã, có thể thêm mật ong.',0,0,0,0,0,0,'c05_soi_than','Sỏi thận','Sỏi thận là tình trạng các tinh thể khoáng chất tích tụ trong thận, gây đau và khó chịu. Chế độ ăn uống giàu chất xơ và uống nhiều nước có thể giúp ngăn ngừa và hỗ trợ điều trị sỏi thận.',5,'Nội Tiết Và Chuyển Hóa','["3 lát cam thảo", "1 thanh quế nhỏ 200ml nước sôi"]'::jsonb,'["Đun sôi nước, cho cam thảo và quế vào hãm 5 phút.", "Lọc bỏ bã, có thể thêm mật ong."]'::jsonb,'Gừng có tính kháng viêm, mật ong giúp tăng cường hệ miễn dịch, hỗ trợ điều trị sỏi thận.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',36,'Chương 5: Nội Tiết Và Chuyển Hóa','Sỏi thận',3,'b8da61c2cd0cc9b76578f290cbdf018ae6fcdc40477425048e5d0da3dc9b76fd',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_kinh_nguyet_it_01_sinh_to_du_du_va_sua_chua','unclassified','SINH TỐ ĐU ĐỦ VÀ SỮA CHUA','Kinh nguyệt ít là tình trạng lượng máu kinh ít hơn bình thường, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Đu đủ gọt vỏ, bỏ hạt, cắt nhỏ.
Cho vào máy xay cùng sữa chua, mật ong và nước.
Xay nhuyễn, rót ra ly và thưởng thức ngay.',0,0,0,0,0,0,'c06_kinh_nguyet_it','Kinh nguyệt ít','Kinh nguyệt ít là tình trạng lượng máu kinh ít hơn bình thường, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["1 miếng đu đủ chín (~150g)", "1 hộp sữa chua không đường (~100ml)", "100ml nước lọc (hoặc sữa hạnh nhân)", "1 thìa mật ong"]'::jsonb,'["Đu đủ gọt vỏ, bỏ hạt, cắt nhỏ.", "Cho vào máy xay cùng sữa chua, mật ong và nước.", "Xay nhuyễn, rót ra ly và thưởng thức ngay."]'::jsonb,'Đu đủ chứa enzym papain giúp cải thiện kích thích nội tiết tố nữ. Thức uống này giúp điều hòa kinh nguyệt và hỗ trợ sức khỏe sinh sản',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',37,'Chương 6: Phụ Khoa','Kinh nguyệt ít',1,'0493c2e08d351109fbd952bd6c866465290722ccae1a91f9459205cb9ee11752',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_kinh_nguyet_it_02_canh_ga_ham_thuoc_bac','unclassified','CANH GÀ HẦM THUỐC BẮC','Kinh nguyệt ít là tình trạng lượng máu kinh ít hơn bình thường, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Gà làm sạch, chặt miếng vừa ăn.
Cho gà, kỷ tử, táo đỏ và gừng vào nồi hầm.
Hầm đến khi gà chín mềm.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c06_kinh_nguyet_it','Kinh nguyệt ít','Kinh nguyệt ít là tình trạng lượng máu kinh ít hơn bình thường, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["1 con gà ác", "50g kỷ tử", "50g táo đỏ", "1 củ gừng", "Gia vị: muối, tiêu"]'::jsonb,'["Gà làm sạch, chặt miếng vừa ăn.", "Cho gà, kỷ tử, táo đỏ và gừng vào nồi hầm.", "Hầm đến khi gà chín mềm.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Gà hầm thuốc Bắc giúp bồi bổ cơ thể, tăng cường lưu thông máu và cải thiện kinh nguyệt ít.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',37,'Chương 6: Phụ Khoa','Kinh nguyệt ít',2,'f6051224de8f413d33d48952f0bf2566e7094ac33adf6f6a46c0edf9f9bf8794',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_kinh_nguyet_it_03_tra_nhan_sam_va_mat_ong','unclassified','TRÀ NHÂN SÂM VÀ MẬT ONG','Kinh nguyệt ít là tình trạng lượng máu kinh ít hơn bình thường, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Cho nhân sâm vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c06_kinh_nguyet_it','Kinh nguyệt ít','Kinh nguyệt ít là tình trạng lượng máu kinh ít hơn bình thường, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["1 lát nhân sâm tươi", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Cho nhân sâm vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Nhân sâm có tác dụng tăng cường sinh lực, mật ong giúp tăng cường sức đề kháng, hỗ trợ cải thiện kinh nguyệt ít.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',38,'Chương 6: Phụ Khoa','Kinh nguyệt ít',3,'fc329920bf3c738b5d3bb4866e320dfb2b2de2e9aca0d309313c77820c4d406f',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_dau_bung_kinh_01_sinh_to_chuoi_va_dau_tay','unclassified','SINH TỐ CHUỐI VÀ DÂU TÂY','Đau bụng kinh là tình trạng phổ biến ở phụ nữ trong chu kỳ kinh nguyệt. Chế độ ăn uống giàu chất dinh dưỡng và thư giãn có thể giúp giảm triệu chứng.','Rửa sạch dâu tây, gọt chuối và cắt nhỏ.
Cho chuối, dâu tây, sữa và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c06_dau_bung_kinh','Đau bụng kinh','Đau bụng kinh là tình trạng phổ biến ở phụ nữ trong chu kỳ kinh nguyệt. Chế độ ăn uống giàu chất dinh dưỡng và thư giãn có thể giúp giảm triệu chứng.',6,'Phụ Khoa','["1 quả chuối", "100g dâu tây", "200ml sữa tươi hoặc sữa hạnh nhân", "1 thìa mật ong"]'::jsonb,'["Rửa sạch dâu tây, gọt chuối và cắt nhỏ.", "Cho chuối, dâu tây, sữa và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Chuối và dâu tây giàu vitamin và khoáng chất, giúp giảm đau bụng kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',38,'Chương 6: Phụ Khoa','Đau bụng kinh',1,'cbdd137e5febce6288de910e6eab336957da0883188652d3af3125ef0c6784dd',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_dau_bung_kinh_02_canh_ga_ham_thuoc_bac','unclassified','CANH GÀ HẦM THUỐC BẮC','Đau bụng kinh là tình trạng phổ biến ở phụ nữ trong chu kỳ kinh nguyệt. Chế độ ăn uống giàu chất dinh dưỡng và thư giãn có thể giúp giảm triệu chứng.','Gà làm sạch, chặt miếng vừa ăn.
Cho gà, kỷ tử, táo đỏ và gừng vào nồi hầm.
Hầm đến khi gà chín mềm.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c06_dau_bung_kinh','Đau bụng kinh','Đau bụng kinh là tình trạng phổ biến ở phụ nữ trong chu kỳ kinh nguyệt. Chế độ ăn uống giàu chất dinh dưỡng và thư giãn có thể giúp giảm triệu chứng.',6,'Phụ Khoa','["1 con gà ác", "50g kỷ tử", "50g táo đỏ", "1 củ gừng", "Gia vị: muối, tiêu"]'::jsonb,'["Gà làm sạch, chặt miếng vừa ăn.", "Cho gà, kỷ tử, táo đỏ và gừng vào nồi hầm.", "Hầm đến khi gà chín mềm.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Gà hầm thuốc Bắc giúp bồi bổ cơ thể, tăng cường lưu thông máu và giảm đau bụng kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',38,'Chương 6: Phụ Khoa','Đau bụng kinh',2,'22218aa3b6ab5269659307585f9fe676e173b3000f3e12bb8ac298ee0a379108',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_dau_bung_kinh_03_tra_nhan_sam_va_mat_ong','unclassified','TRÀ NHÂN SÂM VÀ MẬT ONG','Đau bụng kinh là tình trạng phổ biến ở phụ nữ trong chu kỳ kinh nguyệt. Chế độ ăn uống giàu chất dinh dưỡng và thư giãn có thể giúp giảm triệu chứng.','Cho nhân sâm vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c06_dau_bung_kinh','Đau bụng kinh','Đau bụng kinh là tình trạng phổ biến ở phụ nữ trong chu kỳ kinh nguyệt. Chế độ ăn uống giàu chất dinh dưỡng và thư giãn có thể giúp giảm triệu chứng.',6,'Phụ Khoa','["1 lát nhân sâm tươi", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Cho nhân sâm vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Nhân sâm có tác dụng tăng cường sinh lực, mật ong giúp tăng cường sức đề kháng, hỗ trợ giảm đau bụng kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',39,'Chương 6: Phụ Khoa','Đau bụng kinh',3,'d1d9e8d6e36c87ebd773dfefb53465b6705430dd04e595eb5b51db75c1df4c35',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_be_kinh_01_sinh_to_chuoi_va_hat_dieu','unclassified','SINH TỐ CHUỐI VÀ HẠT ĐIỀU','Bế kinh là tình trạng kinh nguyệt không xuất hiện trong một thời gian dài, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Chuối bóc vỏ, cắt nhỏ.
Cho chuối, hạt điều, sữa hạnh nhân và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c06_be_kinh','Bế kinh','Bế kinh là tình trạng kinh nguyệt không xuất hiện trong một thời gian dài, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["1 quả chuối", "50g hạt điều", "200ml sữa hạnh nhân", "1 thìa mật ong"]'::jsonb,'["Chuối bóc vỏ, cắt nhỏ.", "Cho chuối, hạt điều, sữa hạnh nhân và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Chuối và hạt điều giàu chất dinh dưỡng, giúp tăng cường lưu thông máu và cải thiện bế kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',39,'Chương 6: Phụ Khoa','Bế kinh',1,'1dfc1d9400453cde9e323ce631c1028a9b3a82882fa80160d8589d02a4d42d46',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_be_kinh_02_canh_hau_va_rau_can_tay','unclassified','CANH HÀU VÀ RAU CẦN TÂY','Bế kinh là tình trạng kinh nguyệt không xuất hiện trong một thời gian dài, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Hàu rửa sạch, bỏ vỏ.
Rau cần tây rửa sạch, cắt khúc.
Phi hành tím với dầu, cho hàu vào xào sơ.
Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c06_be_kinh','Bế kinh','Bế kinh là tình trạng kinh nguyệt không xuất hiện trong một thời gian dài, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["200g hàu tươi", "200g rau cần tây", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Hàu rửa sạch, bỏ vỏ.", "Rau cần tây rửa sạch, cắt khúc.", "Phi hành tím với dầu, cho hàu vào xào sơ.", "Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Hàu giàu kẽm, rau cần tây giàu chất xơ, giúp tăng cường lưu thông máu và cải thiện bế kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',39,'Chương 6: Phụ Khoa','Bế kinh',2,'34594d26c16674c9dd284f8cd76e14e12c32ff39292bb358ff86006664928e4c',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_be_kinh_03_tra_nhan_sam_va_mat_ong','unclassified','TRÀ NHÂN SÂM VÀ MẬT ONG','Bế kinh là tình trạng kinh nguyệt không xuất hiện trong một thời gian dài, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Cho nhân sâm vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c06_be_kinh','Bế kinh','Bế kinh là tình trạng kinh nguyệt không xuất hiện trong một thời gian dài, thường do rối loạn nội tiết. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["1 lát nhân sâm tươi", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Cho nhân sâm vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Nhân sâm có tác dụng tăng cường sinh lực, mật ong giúp tăng cường sức đề kháng, hỗ trợ cải thiện bế kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',40,'Chương 6: Phụ Khoa','Bế kinh',3,'147de166672aabdfd62c07c6331bc41a91a807862a86153f49f0d356295c6695',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_viem_am_dao_01_sinh_to_diep_ca_va_nha_dam','unclassified','SINH TỐ DIẾP CÁ VÀ NHA ĐAM','Viêm âm đạo là tình trạng viêm nhiễm ở âm đạo, thường do vi khuẩn hoặc nấm gây ra. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Rau diếp cá rửa sạch, nha đam gọt bỏ vỏ lấy phần gel trong.
Cho tất cả nguyên liệu vào máy xay sinh tố, xay nhuyễn.
Lọc qua rây, uống ngay trong ngày.',0,0,0,0,0,0,'c06_viem_am_dao','Viêm âm đạo','Viêm âm đạo là tình trạng viêm nhiễm ở âm đạo, thường do vi khuẩn hoặc nấm gây ra. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',6,'Phụ Khoa','["1 nắm rau diếp cá", "1 lá nha đam (loại nhỏ)", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Rau diếp cá rửa sạch, nha đam gọt bỏ vỏ lấy phần gel trong.", "Cho tất cả nguyên liệu vào máy xay sinh tố, xay nhuyễn.", "Lọc qua rây, uống ngay trong ngày."]'::jsonb,'Diếp cá có tính kháng khuẩn mạnh, giúp giảm viêm, còn nha đam giúp làm dịu niêm mạc và hỗ trợ cân bằng độ pH tự nhiên.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',40,'Chương 6: Phụ Khoa','Viêm âm đạo',1,'6645673e30e54c8b9fac47782410b7e00865c73cc9d8b98e8923d410752b4f8b',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_viem_am_dao_02_canh_nam_huong_va_dau_hu','unclassified','CANH NẤM HƯƠNG VÀ ĐẬU HŨ','Viêm âm đạo là tình trạng viêm nhiễm ở âm đạo, thường do vi khuẩn hoặc nấm gây ra. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Nấm hương ngâm nở, rửa sạch.
Đậu hũ cắt miếng vừa ăn.
Phi hành tím với dầu, cho nấm vào xào sơ.
Thêm nước, đun sôi rồi cho đậu hũ vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c06_viem_am_dao','Viêm âm đạo','Viêm âm đạo là tình trạng viêm nhiễm ở âm đạo, thường do vi khuẩn hoặc nấm gây ra. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',6,'Phụ Khoa','["200g nấm hương", "200g đậu hũ", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Nấm hương ngâm nở, rửa sạch.", "Đậu hũ cắt miếng vừa ăn.", "Phi hành tím với dầu, cho nấm vào xào sơ.", "Thêm nước, đun sôi rồi cho đậu hũ vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Nấm hương có tính kháng viêm, đậu hũ giàu protein giúp tăng cường hệ miễn dịch.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',40,'Chương 6: Phụ Khoa','Viêm âm đạo',2,'8495ebd4021b174b7d0bcd4d3fbe9f5ef9cb3b196abcb36a2d14d5740927dcc3',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_viem_am_dao_03_sua_nghe_hat_sen','unclassified','SỮA NGHỆ HẠT SEN','Viêm âm đạo là tình trạng viêm nhiễm ở âm đạo, thường do vi khuẩn hoặc nấm gây ra. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.','Nấu hạt sen với 100ml nước đến khi chín mềm, xay nhuyễn.
Hòa bột nghệ vào sữa hạt, đun ấm.
Thêm hạt sen xay và mật ong, khuấy đều.',0,0,0,0,0,0,'c06_viem_am_dao','Viêm âm đạo','Viêm âm đạo là tình trạng viêm nhiễm ở âm đạo, thường do vi khuẩn hoặc nấm gây ra. Chế độ ăn uống giàu chất chống oxy hóa và tăng cường hệ miễn dịch có thể giúp hỗ trợ điều trị.',6,'Phụ Khoa','["200ml sữa hạt", "1 thìa cà phê bột nghệ", "10 hạt sen tươi hoặc khô (nếu khô ngâm trước 2 giờ)", "1 thìa mật ong"]'::jsonb,'["Nấu hạt sen với 100ml nước đến khi chín mềm, xay nhuyễn.", "Hòa bột nghệ vào sữa hạt, đun ấm.", "Thêm hạt sen xay và mật ong, khuấy đều."]'::jsonb,'Trà xanh và bạc hà có tính kháng viêm, giúp hỗ trợ điều trị viêm âm đạo.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',41,'Chương 6: Phụ Khoa','Viêm âm đạo',3,'08c6b5efc339b1bca1ea4d5bc941f0bc3f2b87664bad8f5ab6fc1f763109a7bc',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_khi_hu_bat_thuong_01_sinh_to_la_trau_khong_va_dua','unclassified','SINH TỐ LÁ TRẦU KHÔNG VÀ DỨA','Khí hư bất thường là tình trạng dịch tiết âm đạo có màu sắc, mùi hoặc lượng bất thường. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp cải thiện tình trạng này.','Lá trầu không rửa sạch, cắt nhỏ. Dứa gọt vỏ, cắt miếng.
Cho lá trầu, dứa, nước lọc vào máy xay sinh tố, xay nhuyễn.
Lọc lấy nước, thêm mật ong, uống vào buổi sáng.',0,0,0,0,0,0,'c06_khi_hu_bat_thuong','Khí hư bất thường','Khí hư bất thường là tình trạng dịch tiết âm đạo có màu sắc, mùi hoặc lượng bất thường. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["5 lá trầu không", "1/4 quả dứa chín", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Lá trầu không rửa sạch, cắt nhỏ. Dứa gọt vỏ, cắt miếng.", "Cho lá trầu, dứa, nước lọc vào máy xay sinh tố, xay nhuyễn.", "Lọc lấy nước, thêm mật ong, uống vào buổi sáng."]'::jsonb,'Chuối và dâu tây giàu vitamin và khoáng chất, giúp tăng cường hệ miễn dịch và cải thiện khí hư bất thường.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',41,'Chương 6: Phụ Khoa','Khí hư bất thường',1,'80d3c852c298b35107d9074808da781f23b03dd057d85f4a64e510b73b17d954',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_khi_hu_bat_thuong_02_canh_ga_ham_thuoc_bac','unclassified','CANH GÀ HẦM THUỐC BẮC','Khí hư bất thường là tình trạng dịch tiết âm đạo có màu sắc, mùi hoặc lượng bất thường. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp cải thiện tình trạng này.','Gà làm sạch, chặt miếng vừa ăn.
Cho gà, kỷ tử, táo đỏ và gừng vào nồi hầm.
Hầm đến khi gà chín mềm.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c06_khi_hu_bat_thuong','Khí hư bất thường','Khí hư bất thường là tình trạng dịch tiết âm đạo có màu sắc, mùi hoặc lượng bất thường. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["1 con gà ác", "50g kỷ tử", "50g táo đỏ", "1 củ gừng", "Gia vị: muối, tiêu"]'::jsonb,'["Gà làm sạch, chặt miếng vừa ăn.", "Cho gà, kỷ tử, táo đỏ và gừng vào nồi hầm.", "Hầm đến khi gà chín mềm.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Gà hầm thuốc Bắc giúp bồi bổ cơ thể, tăng cường hệ miễn dịch và cải thiện khí hư bất thường.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',42,'Chương 6: Phụ Khoa','Khí hư bất thường',2,'8b38c1ec076d125ad5ecc7b36c88a971ec7f216bb204185f18e7386af0bbc18a',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_khi_hu_bat_thuong_03_tra_nhan_sam_va_mat_ong','unclassified','TRÀ NHÂN SÂM VÀ MẬT ONG','Khí hư bất thường là tình trạng dịch tiết âm đạo có màu sắc, mùi hoặc lượng bất thường. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp cải thiện tình trạng này.','Cho nhân sâm vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c06_khi_hu_bat_thuong','Khí hư bất thường','Khí hư bất thường là tình trạng dịch tiết âm đạo có màu sắc, mùi hoặc lượng bất thường. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường hệ miễn dịch có thể giúp cải thiện tình trạng này.',6,'Phụ Khoa','["1 lát nhân sâm tươi", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Cho nhân sâm vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Nhân sâm có tác dụng tăng cường sinh lực, mật ong giúp tăng cường sức đề kháng, hỗ trợ cải thiện khí hư bất thường.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',42,'Chương 6: Phụ Khoa','Khí hư bất thường',3,'3854003bbce51b73b9b1b88e435ca1820087ddab68cd3f7cc82a74d0d7db2b6f',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_viem_vung_chau_01_canh_rau_mong_toi_va_dau_hu','unclassified','CANH RAU MỒNG TƠI VÀ ĐẬU HŨ','Viêm vùng chậu là tình trạng nhiễm trùng ở các cơ quan sinh dục nữ, bao gồm tử cung, ống dẫn trứng và buồng trứng. Bệnh có thể gây đau bụng dưới, sốt, và có thể ảnh hưởng đến khả năng sinh sản. Nguyên nhân: Nhiễm trùng do vi khuẩn (thường là do lây truyền qua quan hệ tình dục không an toàn), viêm nhiễm lâu dài.','Rau mồng tơi rửa sạch, đậu hũ cắt miếng vừa ăn.
Phi hành tím với dầu ăn, cho rau mồng tơi vào xào sơ.
Thêm nước vào, đun sôi rồi cho đậu hũ vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c06_viem_vung_chau','Viêm vùng chậu','Viêm vùng chậu là tình trạng nhiễm trùng ở các cơ quan sinh dục nữ, bao gồm tử cung, ống dẫn trứng và buồng trứng. Bệnh có thể gây đau bụng dưới, sốt, và có thể ảnh hưởng đến khả năng sinh sản. Nguyên nhân: Nhiễm trùng do vi khuẩn (thường là do lây truyền qua quan hệ tình dục không an toàn), viêm nhiễm lâu dài.',6,'Phụ Khoa','["100g rau mồng tơi", "200g đậu hũ", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Rau mồng tơi rửa sạch, đậu hũ cắt miếng vừa ăn.", "Phi hành tím với dầu ăn, cho rau mồng tơi vào xào sơ.", "Thêm nước vào, đun sôi rồi cho đậu hũ vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Rau mồng tơi có tác dụng thanh nhiệt, giải độc, giúp hỗ trợ điều trị viêm nhiễm. Đậu hũ cung cấp protein dễ tiêu hóa, tốt cho cơ thể.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',43,'Chương 6: Phụ Khoa','Viêm vùng chậu',1,'b261422bef1ff46fa1c3c06f6f728f23c7d156199602540dd67883f94197a994',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_viem_vung_chau_02_sinh_to_cam_va_chanh','unclassified','SINH TỐ CAM VÀ CHANH','Viêm vùng chậu là tình trạng nhiễm trùng ở các cơ quan sinh dục nữ, bao gồm tử cung, ống dẫn trứng và buồng trứng. Bệnh có thể gây đau bụng dưới, sốt, và có thể ảnh hưởng đến khả năng sinh sản. Nguyên nhân: Nhiễm trùng do vi khuẩn (thường là do lây truyền qua quan hệ tình dục không an toàn), viêm nhiễm lâu dài.','Cam và chanh vắt lấy nước.
Thêm mật ong vào và khuấy đều.',0,0,0,0,0,0,'c06_viem_vung_chau','Viêm vùng chậu','Viêm vùng chậu là tình trạng nhiễm trùng ở các cơ quan sinh dục nữ, bao gồm tử cung, ống dẫn trứng và buồng trứng. Bệnh có thể gây đau bụng dưới, sốt, và có thể ảnh hưởng đến khả năng sinh sản. Nguyên nhân: Nhiễm trùng do vi khuẩn (thường là do lây truyền qua quan hệ tình dục không an toàn), viêm nhiễm lâu dài.',6,'Phụ Khoa','["2 quả cam", "1 quả chanh", "1 thìa mật ong"]'::jsonb,'["Cam và chanh vắt lấy nước.", "Thêm mật ong vào và khuấy đều."]'::jsonb,'Cam và chanh cung cấp vitamin C giúp tăng cường hệ miễn dịch, hỗ trợ giảm viêm và cải thiện sức khỏe sinh sản.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',43,'Chương 6: Phụ Khoa','Viêm vùng chậu',2,'458dda6a5928b6c1da5f7e4f47ade48c0431353b8cc5607e61a7d1bd92c4eb96',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_viem_co_tu_cung_01_canh_ca_chep_va_rau_can','unclassified','CANH CÁ CHÉP VÀ RAU CẦN','Viêm cổ tử cung là tình trạng viêm nhiễm ở cổ tử cung, gây đau, chảy máu bất thường và có thể gây ảnh hưởng đến khả năng sinh sản. Nguyên nhân: Nhiễm trùng do vi khuẩn hoặc virus (thường là lây qua quan hệ tình dục), sử dụng các sản phẩm không phù hợp, hoặc vệ sinh không đúng cách.','Cá chép làm sạch, cắt khúc vừa ăn.
Rau cần rửa sạch, cắt khúc.
Phi hành tím với dầu ăn cho thơm, cho cá vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau cần vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c06_viem_co_tu_cung','Viêm cổ tử cung','Viêm cổ tử cung là tình trạng viêm nhiễm ở cổ tử cung, gây đau, chảy máu bất thường và có thể gây ảnh hưởng đến khả năng sinh sản. Nguyên nhân: Nhiễm trùng do vi khuẩn hoặc virus (thường là lây qua quan hệ tình dục), sử dụng các sản phẩm không phù hợp, hoặc vệ sinh không đúng cách.',6,'Phụ Khoa','["200g cá chép", "100g rau cần", "Gia vị: muối, tiêu"]'::jsonb,'["Cá chép làm sạch, cắt khúc vừa ăn.", "Rau cần rửa sạch, cắt khúc.", "Phi hành tím với dầu ăn cho thơm, cho cá vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau cần vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Cá chép cung cấp omega-3 giúp cải thiện sức khỏe sinh sản, rau cần giúp làm mát và thanh nhiệt cơ thể.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',44,'Chương 6: Phụ Khoa','Viêm cổ tử cung',1,'ffd850349b360eea27d4a3c7b7b63ca373aaf9ecc553f333fd26ff2e7f72b6c4',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_viem_co_tu_cung_02_tra_gung_va_mat_ong','unclassified','TRÀ GỪNG VÀ MẬT ONG','Viêm cổ tử cung là tình trạng viêm nhiễm ở cổ tử cung, gây đau, chảy máu bất thường và có thể gây ảnh hưởng đến khả năng sinh sản. Nguyên nhân: Nhiễm trùng do vi khuẩn hoặc virus (thường là lây qua quan hệ tình dục), sử dụng các sản phẩm không phù hợp, hoặc vệ sinh không đúng cách.','Gừng thái lát mỏng.
Đun nước sôi, cho gừng vào, để ngấm trong 5 phút.
Thêm mật ong vào và khuấy đều.',0,0,0,0,0,0,'c06_viem_co_tu_cung','Viêm cổ tử cung','Viêm cổ tử cung là tình trạng viêm nhiễm ở cổ tử cung, gây đau, chảy máu bất thường và có thể gây ảnh hưởng đến khả năng sinh sản. Nguyên nhân: Nhiễm trùng do vi khuẩn hoặc virus (thường là lây qua quan hệ tình dục), sử dụng các sản phẩm không phù hợp, hoặc vệ sinh không đúng cách.',6,'Phụ Khoa','["1 nhánh gừng tươi", "1 thìa mật ong", "Nước sôi"]'::jsonb,'["Gừng thái lát mỏng.", "Đun nước sôi, cho gừng vào, để ngấm trong 5 phút.", "Thêm mật ong vào và khuấy đều."]'::jsonb,'Gừng giúp làm dịu viêm, hỗ trợ điều trị viêm nhiễm, mật ong giúp giảm sưng viêm và tăng cường sức đề kháng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',44,'Chương 6: Phụ Khoa','Viêm cổ tử cung',2,'d3e185f50bf1b5f98cfe12e5441f2a71f7d61ff0c809d0d8f36eb1e73b1d64c1',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_vo_sinh_01_canh_ga_nau_rau_ngot','unclassified','CANH GÀ NẤU RAU NGÓT','Vô sinh là tình trạng không thể thụ thai sau một năm quan hệ tình dục đều đặn mà không sử dụng biện pháp tránh thai. Nguyên nhân có thể do các vấn đề ở cả nam và nữ. Nguyên nhân: Rối loạn nội tiết tố, viêm nhiễm sinh dục, vấn đề về ống dẫn trứng, tinh trùng yếu hoặc không đủ.','Thịt gà làm sạch, thái miếng vừa ăn.
Rau ngót rửa sạch.
Phi hành tím với dầu ăn cho thơm, cho thịt gà vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau ngót vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c06_vo_sinh','Vô sinh','Vô sinh là tình trạng không thể thụ thai sau một năm quan hệ tình dục đều đặn mà không sử dụng biện pháp tránh thai. Nguyên nhân có thể do các vấn đề ở cả nam và nữ. Nguyên nhân: Rối loạn nội tiết tố, viêm nhiễm sinh dục, vấn đề về ống dẫn trứng, tinh trùng yếu hoặc không đủ.',6,'Phụ Khoa','["200g thịt gà", "100g rau ngót", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Thịt gà làm sạch, thái miếng vừa ăn.", "Rau ngót rửa sạch.", "Phi hành tím với dầu ăn cho thơm, cho thịt gà vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau ngót vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Thịt gà cung cấp protein giúp duy trì sức khỏe, rau ngót giúp thanh nhiệt và cải thiện chức năng sinh sản.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',45,'Chương 6: Phụ Khoa','Vô sinh',1,'01bb8124786451d4287e0e14dadfcbc198c9b40b1fc5e3c07f9b3b1c3280abc7',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_vo_sinh_02_sinh_to_ca_rot_va_dua','unclassified','SINH TỐ CÀ RỐT VÀ DỨA','Vô sinh là tình trạng không thể thụ thai sau một năm quan hệ tình dục đều đặn mà không sử dụng biện pháp tránh thai. Nguyên nhân có thể do các vấn đề ở cả nam và nữ. Nguyên nhân: Rối loạn nội tiết tố, viêm nhiễm sinh dục, vấn đề về ống dẫn trứng, tinh trùng yếu hoặc không đủ.','Cà rốt và dứa gọt vỏ, cắt miếng nhỏ.
Cho vào máy xay sinh tố, xay nhuyễn.
Thêm mật ong vào và khuấy đều.',0,0,0,0,0,0,'c06_vo_sinh','Vô sinh','Vô sinh là tình trạng không thể thụ thai sau một năm quan hệ tình dục đều đặn mà không sử dụng biện pháp tránh thai. Nguyên nhân có thể do các vấn đề ở cả nam và nữ. Nguyên nhân: Rối loạn nội tiết tố, viêm nhiễm sinh dục, vấn đề về ống dẫn trứng, tinh trùng yếu hoặc không đủ.',6,'Phụ Khoa','["1 củ cà rốt", "1/2 quả dứa", "1 ít mật ong"]'::jsonb,'["Cà rốt và dứa gọt vỏ, cắt miếng nhỏ.", "Cho vào máy xay sinh tố, xay nhuyễn.", "Thêm mật ong vào và khuấy đều."]'::jsonb,'Cà rốt và dứa cung cấp vitamin A và C, hỗ trợ tăng cường sức khỏe sinh sản và cải thiện khả năng thụ thai.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',45,'Chương 6: Phụ Khoa','Vô sinh',2,'3be2afd420ea43683aa17b63ed4ae6d98473845a9fdd91001866c67470eba2e1',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_say_thai_quen_da_01_canh_ca_rot_voi_hat_sen','unclassified','CANH CÀ RỐT VỚI HẠT SEN','Sảy thai quen dạ là tình trạng người phụ nữ bị sảy thai nhiều lần liên tiếp, thường do vấn đề về sức khỏe hoặc các yếu tố di truyền. Nguyên nhân: Rối loạn nội tiết tố, cấu trúc tử cung bất thường, nhiễm trùng, các vấn đề di truyền.','Cà rốt gọt vỏ, thái lát mỏng.
Hạt sen rửa sạch, ngâm mềm.
Nấu cà rốt và hạt sen với nước đến khi mềm.
Thêm muối vào vừa ăn.',0,0,0,0,0,0,'c06_say_thai_quen_da','Sảy thai quen dạ','Sảy thai quen dạ là tình trạng người phụ nữ bị sảy thai nhiều lần liên tiếp, thường do vấn đề về sức khỏe hoặc các yếu tố di truyền. Nguyên nhân: Rối loạn nội tiết tố, cấu trúc tử cung bất thường, nhiễm trùng, các vấn đề di truyền.',6,'Phụ Khoa','["200g cà rốt", "50g hạt sen", "1 ít muối"]'::jsonb,'["Cà rốt gọt vỏ, thái lát mỏng.", "Hạt sen rửa sạch, ngâm mềm.", "Nấu cà rốt và hạt sen với nước đến khi mềm.", "Thêm muối vào vừa ăn."]'::jsonb,'Cà rốt và hạt sen giúp bổ sung dưỡng chất, hỗ trợ cải thiện sức khỏe sinh sản và ngăn ngừa nguy cơ sảy thai.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',46,'Chương 6: Phụ Khoa','Sảy thai quen dạ',1,'be7a57201439bae8fdd17d4b53f4c3198a8ddba1977200db867195352c973747',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_say_thai_quen_da_02_nuoc_ep_dua_hau_va_la_bac_ha','unclassified','NƯỚC ÉP DƯA HẤU VÀ LÁ BẠC HÀ','Sảy thai quen dạ là tình trạng người phụ nữ bị sảy thai nhiều lần liên tiếp, thường do vấn đề về sức khỏe hoặc các yếu tố di truyền. Nguyên nhân: Rối loạn nội tiết tố, cấu trúc tử cung bất thường, nhiễm trùng, các vấn đề di truyền.','Dưa hấu gọt vỏ, cắt miếng nhỏ.
Lá bạc hà rửa sạch.
Cho vào máy xay sinh tố, xay nhuyễn.',0,0,0,0,0,0,'c06_say_thai_quen_da','Sảy thai quen dạ','Sảy thai quen dạ là tình trạng người phụ nữ bị sảy thai nhiều lần liên tiếp, thường do vấn đề về sức khỏe hoặc các yếu tố di truyền. Nguyên nhân: Rối loạn nội tiết tố, cấu trúc tử cung bất thường, nhiễm trùng, các vấn đề di truyền.',6,'Phụ Khoa','["200g dưa hấu", "10 lá bạc hà"]'::jsonb,'["Dưa hấu gọt vỏ, cắt miếng nhỏ.", "Lá bạc hà rửa sạch.", "Cho vào máy xay sinh tố, xay nhuyễn."]'::jsonb,'Dưa hấu giúp làm mát cơ thể, hỗ trợ cải thiện chức năng sinh sản, bạc hà giúp giảm căng thẳng, hỗ trợ sự phát triển của thai nhi.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',46,'Chương 6: Phụ Khoa','Sảy thai quen dạ',2,'becacdcf0bb8cab07546e219c475c0d52ec3f358d72cc1914111abc7280de7ed',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_hoi_chung_man_kinh_01_canh_ca_loc_nau_rau_cai','unclassified','CANH CÁ LÓC NẤU RAU CẢI','Hội chứng mãn kinh là tập hợp các triệu chứng mà phụ nữ gặp phải khi bước vào giai đoạn mãn kinh, như bốc hỏa, mất ngủ, thay đổi tâm trạng. Nguyên nhân: Sự giảm sút hormone estrogen và progesterone trong cơ thể, tuổi tác.','Cá lóc làm sạch, cắt khúc vừa ăn.
Rau cải rửa sạch, cắt khúc.
Phi hành với dầu ăn cho thơm, cho cá vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau cải vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c06_hoi_chung_man_kinh','Hội chứng mãn kinh','Hội chứng mãn kinh là tập hợp các triệu chứng mà phụ nữ gặp phải khi bước vào giai đoạn mãn kinh, như bốc hỏa, mất ngủ, thay đổi tâm trạng. Nguyên nhân: Sự giảm sút hormone estrogen và progesterone trong cơ thể, tuổi tác.',6,'Phụ Khoa','["200g cá lóc", "100g rau cải", "Gia vị: muối, tiêu"]'::jsonb,'["Cá lóc làm sạch, cắt khúc vừa ăn.", "Rau cải rửa sạch, cắt khúc.", "Phi hành với dầu ăn cho thơm, cho cá vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau cải vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Cá lóc cung cấp omega-3 và vitamin D giúp cải thiện các triệu chứng của mãn kinh, rau cải bổ sung vitamin và khoáng chất giúp hỗ trợ sức khỏe tổng thể.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',47,'Chương 6: Phụ Khoa','Hội chứng mãn kinh',1,'7f91f9ffe52710e47dc38e9f85a4fb220f0b595bf854813b7bffb145f0a486fe',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c06_hoi_chung_man_kinh_02_sinh_to_bo_va_dua','unclassified','SINH TỐ BƠ VÀ DỨA','Hội chứng mãn kinh là tập hợp các triệu chứng mà phụ nữ gặp phải khi bước vào giai đoạn mãn kinh, như bốc hỏa, mất ngủ, thay đổi tâm trạng. Nguyên nhân: Sự giảm sút hormone estrogen và progesterone trong cơ thể, tuổi tác.','Bơ gọt vỏ, dứa gọt vỏ và cắt miếng nhỏ.
Cho vào máy xay sinh tố, xay nhuyễn.',0,0,0,0,0,0,'c06_hoi_chung_man_kinh','Hội chứng mãn kinh','Hội chứng mãn kinh là tập hợp các triệu chứng mà phụ nữ gặp phải khi bước vào giai đoạn mãn kinh, như bốc hỏa, mất ngủ, thay đổi tâm trạng. Nguyên nhân: Sự giảm sút hormone estrogen và progesterone trong cơ thể, tuổi tác.',6,'Phụ Khoa','["1 quả bơ", "1/2 quả dứa"]'::jsonb,'["Bơ gọt vỏ, dứa gọt vỏ và cắt miếng nhỏ.", "Cho vào máy xay sinh tố, xay nhuyễn."]'::jsonb,'Bơ cung cấp chất béo lành mạnh giúp giảm triệu chứng bốc hỏa, dứa có tác dụng làm mát cơ thể và tăng cường miễn dịch.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',47,'Chương 6: Phụ Khoa','Hội chứng mãn kinh',2,'521a58983df289c04a064cd99e3b90fa88c5b71a023f354c1e27d0fd4d19eb64',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_roi_loan_cuong_duong_01_sinh_to_chuoi_va_hat_dieu','unclassified','SINH TỐ CHUỐI VÀ HẠT ĐIỀU','Rối loạn cương dương là tình trạng không thể duy trì sự cương cứng đủ để quan hệ tình dục. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Chuối bóc vỏ, cắt nhỏ.
Cho chuối, hạt điều, sữa hạnh nhân và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c07_roi_loan_cuong_duong','Rối loạn cương dương','Rối loạn cương dương là tình trạng không thể duy trì sự cương cứng đủ để quan hệ tình dục. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',7,'Nam Khoa','["1 quả chuối", "50g hạt điều", "200ml sữa hạnh nhân", "1 thìa mật ong"]'::jsonb,'["Chuối bóc vỏ, cắt nhỏ.", "Cho chuối, hạt điều, sữa hạnh nhân và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Chuối và hạt điều giàu chất dinh dưỡng, giúp tăng cường lưu thông máu và cải thiện chức năng sinh lý.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',47,'Chương 7: Nam Khoa','Rối loạn cương dương',1,'18f1ccb934b5f7995e738c44a57e05cbb03e204acb5247b58232b941e9accd81',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_roi_loan_cuong_duong_02_canh_hau_va_rau_can_tay','unclassified','CANH HÀU VÀ RAU CẦN TÂY','Rối loạn cương dương là tình trạng không thể duy trì sự cương cứng đủ để quan hệ tình dục. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Hàu rửa sạch, bỏ vỏ.
Rau cần tây rửa sạch, cắt khúc.
Phi hành tím với dầu, cho hàu vào xào sơ.
Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c07_roi_loan_cuong_duong','Rối loạn cương dương','Rối loạn cương dương là tình trạng không thể duy trì sự cương cứng đủ để quan hệ tình dục. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',7,'Nam Khoa','["200g hàu tươi", "200g rau cần tây", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Hàu rửa sạch, bỏ vỏ.", "Rau cần tây rửa sạch, cắt khúc.", "Phi hành tím với dầu, cho hàu vào xào sơ.", "Thêm nước, đun sôi rồi cho rau cần tây vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Hàu giàu kẽm, rau cần tây giàu chất xơ, giúp tăng cường sinh lý và lưu thông máu.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',48,'Chương 7: Nam Khoa','Rối loạn cương dương',2,'758198cd7737f9b26a4d245fcc87f9bbe2bca6343e11fe5ef2754e2cbb5075d6',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_roi_loan_cuong_duong_03_tra_nhan_sam_va_mat_ong','unclassified','TRÀ NHÂN SÂM VÀ MẬT ONG','Rối loạn cương dương là tình trạng không thể duy trì sự cương cứng đủ để quan hệ tình dục. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.','Cho nhân sâm vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c07_roi_loan_cuong_duong','Rối loạn cương dương','Rối loạn cương dương là tình trạng không thể duy trì sự cương cứng đủ để quan hệ tình dục. Chế độ ăn uống giàu chất dinh dưỡng và tăng cường lưu thông máu có thể giúp cải thiện tình trạng này.',7,'Nam Khoa','["1 lát nhân sâm tươi", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Cho nhân sâm vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Nhân sâm có tác dụng tăng cường sinh lực, mật ong giúp tăng cường sức đề kháng, hỗ trợ điều trị rối loạn cương dương.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',48,'Chương 7: Nam Khoa','Rối loạn cương dương',3,'1457fbe2bf29f6502492fa537eeff5cc9cf953cee7a04de7c0626045d8969ed5',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_xuat_tinh_som_01_chao_hau_bien_va_hat_sen','unclassified','CHÁO HÀU BIỂN VÀ HẠT SEN','Xuất tinh sớm là tình trạng nam giới xuất tinh trong thời gian quá ngắn sau khi bắt đầu quan hệ tình dục, dẫn đến sự không thoải mái và lo âu cho cả hai bên. Nguyên nhân: Căng thẳng, lo âu, rối loạn hormone, hoặc các vấn đề tâm lý và thể chất.','Hàu tách vỏ, rửa sạch, cắt nhỏ.
Hạt sen nấu với gạo tẻ cho đến khi cháo nhừ.
Phi thơm hành tím, cho hàu vào xào nhanh rồi đổ vào cháo.
Nêm gia vị, thêm hành lá, rau mùi, dùng khi còn ấm.',0,0,0,0,0,0,'c07_xuat_tinh_som','Xuất tinh sớm','Xuất tinh sớm là tình trạng nam giới xuất tinh trong thời gian quá ngắn sau khi bắt đầu quan hệ tình dục, dẫn đến sự không thoải mái và lo âu cho cả hai bên. Nguyên nhân: Căng thẳng, lo âu, rối loạn hormone, hoặc các vấn đề tâm lý và thể chất.',7,'Nam Khoa','["5-6 con hàu tươi", "½ chén gạo tẻ", "10 hạt sen tươi (hoặc hạt sen khô ngâm mềm)", "1 củ hành tím băm nhỏ", "1 ít hành lá, rau mùi", "Gia vị: muối, tiêu, nước mắm"]'::jsonb,'["Hàu tách vỏ, rửa sạch, cắt nhỏ.", "Hạt sen nấu với gạo tẻ cho đến khi cháo nhừ.", "Phi thơm hành tím, cho hàu vào xào nhanh rồi đổ vào cháo.", "Nêm gia vị, thêm hành lá, rau mùi, dùng khi còn ấm."]'::jsonb,'Đậu hũ chứa nhiều protein giúp cải thiện sức khỏe sinh lý, rau mồng tơi giúp giải độc, thanh nhiệt cơ thể, hỗ trợ làm dịu thần kinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',49,'Chương 7: Nam Khoa','Xuất tinh sớm',1,'7654848e9d2a9db879b88191cbe0cde5eb0c057e97b3a20795afedee03e6654e',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_xuat_tinh_som_02_canh_thit_bo_nau_ngoc_truc_va_ky_tu','unclassified','CANH THỊT BÒ NẤU NGỌC TRÚC VÀ KỶ TỬ','Xuất tinh sớm là tình trạng nam giới xuất tinh trong thời gian quá ngắn sau khi bắt đầu quan hệ tình dục, dẫn đến sự không thoải mái và lo âu cho cả hai bên. Nguyên nhân: Căng thẳng, lo âu, rối loạn hormone, hoặc các vấn đề tâm lý và thể chất.','Ngọc trúc và kỷ tử rửa sạch, ngâm nước 10 phút.
Thịt bò thái lát mỏng, ướp muối tiêu.
Đun sôi nước, cho ngọc trúc và kỷ tử vào nấu 15 phút.
Thêm thịt bò, đun chín mềm, nêm gia vị vừa ăn.',0,0,0,0,0,0,'c07_xuat_tinh_som','Xuất tinh sớm','Xuất tinh sớm là tình trạng nam giới xuất tinh trong thời gian quá ngắn sau khi bắt đầu quan hệ tình dục, dẫn đến sự không thoải mái và lo âu cho cả hai bên. Nguyên nhân: Căng thẳng, lo âu, rối loạn hormone, hoặc các vấn đề tâm lý và thể chất.',7,'Nam Khoa','["200g thịt bò thăn", "10g ngọc trúc (hoặc hoài sơn khô)", "5g kỷ tử", "1 củ hành tím băm nhỏ", "500ml nước lọc", "Gia vị: muối, tiêu, nước mắm"]'::jsonb,'["Ngọc trúc và kỷ tử rửa sạch, ngâm nước 10 phút.", "Thịt bò thái lát mỏng, ướp muối tiêu.", "Đun sôi nước, cho ngọc trúc và kỷ tử vào nấu 15 phút.", "Thêm thịt bò, đun chín mềm, nêm gia vị vừa ăn."]'::jsonb,'Ngọc trúc giúp bổ thận, tăng cường sinh lực, hỗ trợ cải thiện xuất tinh sớm. Kỷ tử giúp dưỡng huyết, tăng sức bền, cải thiện chất lượng quan hệ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',49,'Chương 7: Nam Khoa','Xuất tinh sớm',2,'13f15293e54e595e065cf840612938378d0cd5716c9584069f31580642dc8f46',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_di_tinh_01_trung_ga_hap_mat_ong','unclassified','TRỨNG GÀ HẤP MẬT ONG','Di tinh là tình trạng xuất tinh không tự chủ trong khi ngủ hoặc khi không có kích thích tình dục. Đây có thể là dấu hiệu của sự mất cân bằng nội tiết hoặc vấn đề về tâm lý. Nguyên nhân: Căng thẳng, lo âu, mệt mỏi, rối loạn nội tiết tố.','Đập trứng gà vào chén, thêm mật ong và nước ấm.
Đánh đều hỗn hợp, sau đó hấp cách thủy 10 phút.
Dùng khi còn ấm, có thể ăn vào buổi sáng hoặc tối trước khi ngủ.',0,0,0,0,0,0,'c07_di_tinh','Di tinh','Di tinh là tình trạng xuất tinh không tự chủ trong khi ngủ hoặc khi không có kích thích tình dục. Đây có thể là dấu hiệu của sự mất cân bằng nội tiết hoặc vấn đề về tâm lý. Nguyên nhân: Căng thẳng, lo âu, mệt mỏi, rối loạn nội tiết tố.',7,'Nam Khoa','["1 quả trứng gà ta", "1 thìa cà phê mật ong", "100ml nước ấm"]'::jsonb,'["Đập trứng gà vào chén, thêm mật ong và nước ấm.", "Đánh đều hỗn hợp, sau đó hấp cách thủy 10 phút.", "Dùng khi còn ấm, có thể ăn vào buổi sáng hoặc tối trước khi ngủ."]'::jsonb,'Trứng gà giúp bổ thận, tăng cường sinh lực, mật ong giúp cơ thể hấp thu dinh dưỡng tốt hơn và cải thiện tình trạng di tinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',50,'Chương 7: Nam Khoa','Di tinh',1,'581dd7c3b49ba61db29455bc33500e772d9c902f053febf0aeedae6e3cc92cb7',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_di_tinh_02_chao_hanh_tia_to','unclassified','CHÁO HÀNH TÍA TÔ','Di tinh là tình trạng xuất tinh không tự chủ trong khi ngủ hoặc khi không có kích thích tình dục. Đây có thể là dấu hiệu của sự mất cân bằng nội tiết hoặc vấn đề về tâm lý. Nguyên nhân: Căng thẳng, lo âu, mệt mỏi, rối loạn nội tiết tố.','Nấu cháo từ gạo tẻ cho đến khi nhừ.
Đập trứng gà vào, khuấy đều, nấu thêm 2 phút.
Cho tía tô và hành lá thái nhỏ vào, tắt bếp.
Nêm gia vị vừa ăn, dùng nóng.',0,0,0,0,0,0,'c07_di_tinh','Di tinh','Di tinh là tình trạng xuất tinh không tự chủ trong khi ngủ hoặc khi không có kích thích tình dục. Đây có thể là dấu hiệu của sự mất cân bằng nội tiết hoặc vấn đề về tâm lý. Nguyên nhân: Căng thẳng, lo âu, mệt mỏi, rối loạn nội tiết tố.',7,'Nam Khoa','["½ chén gạo tẻ", "1 quả trứng gà ta", "1 ít lá tía tô", "1 nhánh hành lá", "Gia vị: muối, nước mắm, tiêu"]'::jsonb,'["Nấu cháo từ gạo tẻ cho đến khi nhừ.", "Đập trứng gà vào, khuấy đều, nấu thêm 2 phút.", "Cho tía tô và hành lá thái nhỏ vào, tắt bếp.", "Nêm gia vị vừa ăn, dùng nóng."]'::jsonb,'Cháo giúp cơ thể ấm, tía tô hỗ trợ lưu thông khí huyết, giúp giảm căng thẳng – một nguyên nhân gây di tinh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',50,'Chương 7: Nam Khoa','Di tinh',2,'a58b653e79ae8de6abf988323336ef3cf224b6d7be00ea34ae02fb59896dc6b3',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_viem_tuyen_tien_liet_01_canh_ca_loc_nau_rau_mong_toi','unclassified','CANH CÁ LÓC NẤU RAU MỒNG TƠI','Viêm tuyến tiền liệt là tình trạng viêm nhiễm ở tuyến tiền liệt, gây đau vùng chậu, tiểu khó, và có thể ảnh hưởng đến khả năng sinh lý của nam giới. Nguyên nhân: Nhiễm trùng vi khuẩn, lối sống không lành mạnh, ít vận động.','Cá lóc làm sạch, cắt khúc vừa ăn.
Rau mồng tơi rửa sạch, cắt khúc.
Phi hành với dầu ăn cho thơm, cho cá vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau mồng tơi vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c07_viem_tuyen_tien_liet','Viêm tuyến tiền liệt','Viêm tuyến tiền liệt là tình trạng viêm nhiễm ở tuyến tiền liệt, gây đau vùng chậu, tiểu khó, và có thể ảnh hưởng đến khả năng sinh lý của nam giới. Nguyên nhân: Nhiễm trùng vi khuẩn, lối sống không lành mạnh, ít vận động.',7,'Nam Khoa','["200g cá lóc", "100g rau mồng tơi", "Gia vị: muối, tiêu"]'::jsonb,'["Cá lóc làm sạch, cắt khúc vừa ăn.", "Rau mồng tơi rửa sạch, cắt khúc.", "Phi hành với dầu ăn cho thơm, cho cá vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau mồng tơi vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Cá lóc cung cấp omega-3 hỗ trợ sức khỏe tuyến tiền liệt, rau mồng tơi có tác dụng giải độc và làm mát cơ thể, hỗ trợ điều trị viêm.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',51,'Chương 7: Nam Khoa','Viêm tuyến tiền liệt',1,'a43c25b9e20684c7da756bb2405286de395ad6c7d2cc8916d9c66fc11b0dd559',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_viem_tuyen_tien_liet_02_dau_nanh_ham_lac_dau_phong','unclassified','ĐẬU NÀNH HẦM LẠC (ĐẬU PHỘNG)','Viêm tuyến tiền liệt là tình trạng viêm nhiễm ở tuyến tiền liệt, gây đau vùng chậu, tiểu khó, và có thể ảnh hưởng đến khả năng sinh lý của nam giới. Nguyên nhân: Nhiễm trùng vi khuẩn, lối sống không lành mạnh, ít vận động.','Đậu nành và lạc ngâm nước 4 tiếng hoặc qua đêm để mềm.
Cho tất cả vào nồi, đổ nước và đun nhỏ lửa khoảng 30 phút.
Nêm chút muối, ăn nóng hoặc nguội đều được.',0,0,0,0,0,0,'c07_viem_tuyen_tien_liet','Viêm tuyến tiền liệt','Viêm tuyến tiền liệt là tình trạng viêm nhiễm ở tuyến tiền liệt, gây đau vùng chậu, tiểu khó, và có thể ảnh hưởng đến khả năng sinh lý của nam giới. Nguyên nhân: Nhiễm trùng vi khuẩn, lối sống không lành mạnh, ít vận động.',7,'Nam Khoa','["100g đậu nành", "50g lạc (đậu phộng)", "500ml nước", "1 ít muối"]'::jsonb,'["Đậu nành và lạc ngâm nước 4 tiếng hoặc qua đêm để mềm.", "Cho tất cả vào nồi, đổ nước và đun nhỏ lửa khoảng 30 phút.", "Nêm chút muối, ăn nóng hoặc nguội đều được."]'::jsonb,'Đậu nành giàu isoflavone giúp cân bằng nội tiết tố nam, giảm viêm tiền liệt tuyến. Lạc chứa nhiều chất béo tốt giúp bảo vệ tuyến tiền liệt.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',51,'Chương 7: Nam Khoa','Viêm tuyến tiền liệt',2,'0eccd36794d13018e18e2ae5adc375a16a1f999ba9142f1c1474914009c8abdb',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_phi_dai_tuyen_tien_liet_01_canh_dau_do_nau_ga','unclassified','CANH ĐẬU ĐỎ NẤU GÀ','Phì đại tuyến tiền liệt là tình trạng tuyến tiền liệt mở rộng, gây khó khăn khi tiểu tiện, tiểu đêm và có thể dẫn đến các vấn đề nghiêm trọng về sức khỏe sinh sản. Nguyên nhân: Lão hóa, thiếu hormone, viêm nhiễm mãn tính.','Đậu đỏ ngâm nước 3 tiếng để mềm.
Gà rửa sạch, chặt miếng nhỏ.
Phi thơm hành tím, cho thịt gà vào xào săn, đổ nước vào đun sôi.
Thêm đậu đỏ vào nấu mềm, nêm gia vị vừa ăn, rắc hành lá.',0,0,0,0,0,0,'c07_phi_dai_tuyen_tien_liet','Phì đại tuyến tiền liệt','Phì đại tuyến tiền liệt là tình trạng tuyến tiền liệt mở rộng, gây khó khăn khi tiểu tiện, tiểu đêm và có thể dẫn đến các vấn đề nghiêm trọng về sức khỏe sinh sản. Nguyên nhân: Lão hóa, thiếu hormone, viêm nhiễm mãn tính.',7,'Nam Khoa','["100g đậu đỏ", "200g thịt gà ta", "1 củ hành tím", "1 ít hành lá", "Gia vị: muối, tiêu, nước mắm"]'::jsonb,'["Đậu đỏ ngâm nước 3 tiếng để mềm.", "Gà rửa sạch, chặt miếng nhỏ.", "Phi thơm hành tím, cho thịt gà vào xào săn, đổ nước vào đun sôi.", "Thêm đậu đỏ vào nấu mềm, nêm gia vị vừa ăn, rắc hành lá."]'::jsonb,'Đậu đỏ giúp lợi tiểu, giảm áp lực lên tuyến tiền liệt, trong khi thịt gà giàu protein giúp tăng cường sức đề kháng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',52,'Chương 7: Nam Khoa','Phì đại tuyến tiền liệt',1,'49950d7469591f63a8067d930b27e96084868e067c9a53bc615487094b77e854',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c07_phi_dai_tuyen_tien_liet_02_sinh_to_cam_va_cu_den','unclassified','SINH TỐ CAM VÀ CỦ DỀN','Phì đại tuyến tiền liệt là tình trạng tuyến tiền liệt mở rộng, gây khó khăn khi tiểu tiện, tiểu đêm và có thể dẫn đến các vấn đề nghiêm trọng về sức khỏe sinh sản. Nguyên nhân: Lão hóa, thiếu hormone, viêm nhiễm mãn tính.','Cam vắt lấy nước, củ dền gọt vỏ, cắt nhỏ.
Cho vào máy xay, xay nhuyễn.',0,0,0,0,0,0,'c07_phi_dai_tuyen_tien_liet','Phì đại tuyến tiền liệt','Phì đại tuyến tiền liệt là tình trạng tuyến tiền liệt mở rộng, gây khó khăn khi tiểu tiện, tiểu đêm và có thể dẫn đến các vấn đề nghiêm trọng về sức khỏe sinh sản. Nguyên nhân: Lão hóa, thiếu hormone, viêm nhiễm mãn tính.',7,'Nam Khoa','["1 quả cam", "1 củ dền"]'::jsonb,'["Cam vắt lấy nước, củ dền gọt vỏ, cắt nhỏ.", "Cho vào máy xay, xay nhuyễn."]'::jsonb,'Cam cung cấp vitamin C giúp bảo vệ tế bào tuyến tiền liệt, củ dền giúp tăng cường tuần hoàn máu và giảm viêm.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',52,'Chương 7: Nam Khoa','Phì đại tuyến tiền liệt',2,'46114f8becfe7a2495049cec74f752eb36cd6e0a23d40b4d8821528c0b622375',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_viem_loet_mieng_01_sinh_to_cam_va_ca_rot','unclassified','SINH TỐ CAM VÀ CÀ RỐT','Viêm loét miệng là tình trạng xuất hiện các vết loét trong miệng, gây đau và khó chịu. Chế độ ăn uống giàu vitamin và khoáng chất có thể giúp làm lành vết loét.','Cam vắt lấy nước.
Cà rốt gọt vỏ, cắt nhỏ.
Cho nước cam, cà rốt, nước và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c08_viem_loet_mieng','Viêm loét miệng','Viêm loét miệng là tình trạng xuất hiện các vết loét trong miệng, gây đau và khó chịu. Chế độ ăn uống giàu vitamin và khoáng chất có thể giúp làm lành vết loét.',8,'Tai Mũi Họng','["2 quả cam", "1 củ cà rốt", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Cam vắt lấy nước.", "Cà rốt gọt vỏ, cắt nhỏ.", "Cho nước cam, cà rốt, nước và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Cam và cà rốt giàu vitamin C và beta-carotene, giúp làm lành vết loét miệng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',52,'Chương 8: Tai Mũi Họng','Viêm loét miệng',1,'57bd8ffb0d58a4b42b80ef68a72b971adcfe9729ed091b571f9b20b516365314',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_viem_loet_mieng_02_canh_nam_huong_va_ga','unclassified','CANH NẤM HƯƠNG VÀ GÀ','Viêm loét miệng là tình trạng xuất hiện các vết loét trong miệng, gây đau và khó chịu. Chế độ ăn uống giàu vitamin và khoáng chất có thể giúp làm lành vết loét.','Thịt gà rửa sạch, thái miếng.
Nấm hương ngâm nở, rửa sạch.
Phi hành tím với dầu, cho thịt gà vào xào sơ.
Thêm nước, đun sôi rồi cho nấm vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c08_viem_loet_mieng','Viêm loét miệng','Viêm loét miệng là tình trạng xuất hiện các vết loét trong miệng, gây đau và khó chịu. Chế độ ăn uống giàu vitamin và khoáng chất có thể giúp làm lành vết loét.',8,'Tai Mũi Họng','["200g thịt gà", "100g nấm hương", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Thịt gà rửa sạch, thái miếng.", "Nấm hương ngâm nở, rửa sạch.", "Phi hành tím với dầu, cho thịt gà vào xào sơ.", "Thêm nước, đun sôi rồi cho nấm vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Thịt gà và nấm hương giàu protein và chất chống oxy hóa, giúp làm lành vết loét miệng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',53,'Chương 8: Tai Mũi Họng','Viêm loét miệng',2,'e97a935a71c6158bd97a37468d72a0d6226ed402b03596d7da555c9bc92e6b0f',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_viem_loet_mieng_03_tra_gung_va_chanh','unclassified','TRÀ GỪNG VÀ CHANH','Viêm loét miệng là tình trạng xuất hiện các vết loét trong miệng, gây đau và khó chịu. Chế độ ăn uống giàu vitamin và khoáng chất có thể giúp làm lành vết loét.','Gừng rửa sạch, thái lát.
Chanh vắt lấy nước cốt.
Cho gừng vào nước sôi, hãm trong 10 phút.
Thêm nước cốt chanh, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c08_viem_loet_mieng','Viêm loét miệng','Viêm loét miệng là tình trạng xuất hiện các vết loét trong miệng, gây đau và khó chịu. Chế độ ăn uống giàu vitamin và khoáng chất có thể giúp làm lành vết loét.',8,'Tai Mũi Họng','["1 củ gừng nhỏ", "1 quả chanh", "200ml nước sôi"]'::jsonb,'["Gừng rửa sạch, thái lát.", "Chanh vắt lấy nước cốt.", "Cho gừng vào nước sôi, hãm trong 10 phút.", "Thêm nước cốt chanh, khuấy đều.", "Uống ngay."]'::jsonb,'Gừng có tính kháng viêm, chanh giàu vitamin C, giúp làm lành vết loét miệng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',53,'Chương 8: Tai Mũi Họng','Viêm loét miệng',3,'211abf8352a33e1ea4090619e09fd85d0f3bf398ba8dc096c40bf7d3a0f393ea',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_viem_mui_01_tra_gung_va_mat_ong','unclassified','TRÀ GỪNG VÀ MẬT ONG','Viêm mũi là tình trạng viêm nhiễm ở niêm mạc mũi, gây tắc nghẽn mũi, chảy nước mũi và khó thở. Bệnh có thể do vi khuẩn, virus hoặc các dị ứng gây ra.','Gừng cạo vỏ, thái lát mỏng.
Đun nước sôi, cho gừng vào hãm trong 5 phút.
Thêm mật ong vào khuấy đều.',0,0,0,0,0,0,'c08_viem_mui','Viêm mũi','Viêm mũi là tình trạng viêm nhiễm ở niêm mạc mũi, gây tắc nghẽn mũi, chảy nước mũi và khó thở. Bệnh có thể do vi khuẩn, virus hoặc các dị ứng gây ra.',8,'Tai Mũi Họng','["1 nhánh gừng tươi", "1 thìa mật ong", "Nước sôi"]'::jsonb,'["Gừng cạo vỏ, thái lát mỏng.", "Đun nước sôi, cho gừng vào hãm trong 5 phút.", "Thêm mật ong vào khuấy đều."]'::jsonb,'Gừng giúp làm dịu viêm, mật ong hỗ trợ làm sạch mũi, giúp giảm tắc nghẽn và triệu chứng viêm mũi.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',54,'Chương 8: Tai Mũi Họng','Viêm mũi',1,'e3957aa9776e0cbb5ff5251480e7bf448aff81162304b2d0a4838c7a2324e055',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_viem_mui_02_sinh_to_ca_rot_va_dua','unclassified','SINH TỐ CÀ RỐT VÀ DỨA','Viêm mũi là tình trạng viêm nhiễm ở niêm mạc mũi, gây tắc nghẽn mũi, chảy nước mũi và khó thở. Bệnh có thể do vi khuẩn, virus hoặc các dị ứng gây ra.','Cà rốt và dứa gọt vỏ, cắt miếng nhỏ.
Cho vào máy xay sinh tố, xay nhuyễn.
Lọc qua rây và uống ngay.',0,0,0,0,0,0,'c08_viem_mui','Viêm mũi','Viêm mũi là tình trạng viêm nhiễm ở niêm mạc mũi, gây tắc nghẽn mũi, chảy nước mũi và khó thở. Bệnh có thể do vi khuẩn, virus hoặc các dị ứng gây ra.',8,'Tai Mũi Họng','["1 củ cà rốt", "1/2 quả dứa"]'::jsonb,'["Cà rốt và dứa gọt vỏ, cắt miếng nhỏ.", "Cho vào máy xay sinh tố, xay nhuyễn.", "Lọc qua rây và uống ngay."]'::jsonb,'Cà rốt và dứa giúp tăng cường hệ miễn dịch, hỗ trợ giảm viêm, giải độc cơ thể.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',54,'Chương 8: Tai Mũi Họng','Viêm mũi',2,'f5306dee1684270d626c5aab3e1eb42cb75c1410b1a16a47e38426202cdb8fe7',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_u_tai_diec_tai_01_nuoc_ep_dua_hau_va_bac_ha','unclassified','NƯỚC ÉP DƯA HẤU VÀ BẠC HÀ','Ù tai và điếc tai là tình trạng khi người bệnh nghe thấy âm thanh trong tai mà không có nguồn âm thanh bên ngoài. Các triệu chứng đi kèm có thể bao gồm cảm giác tắc nghẽn tai, khó nghe và chóng mặt. Nguyên nhân: Căng thẳng, tiếp xúc với tiếng ồn lớn, tắc nghẽn tai, viêm nhiễm hoặc tổn thương thần kinh thính giác.','Dưa hấu gọt vỏ, cắt miếng nhỏ.
Lá bạc hà rửa sạch.
Cho tất cả vào máy xay sinh tố, xay nhuyễn.
Lọc qua rây và thưởng thức ngay.',0,0,0,0,0,0,'c08_u_tai_diec_tai','Ù tai, điếc tai','Ù tai và điếc tai là tình trạng khi người bệnh nghe thấy âm thanh trong tai mà không có nguồn âm thanh bên ngoài. Các triệu chứng đi kèm có thể bao gồm cảm giác tắc nghẽn tai, khó nghe và chóng mặt. Nguyên nhân: Căng thẳng, tiếp xúc với tiếng ồn lớn, tắc nghẽn tai, viêm nhiễm hoặc tổn thương thần kinh thính giác.',8,'Tai Mũi Họng','["200g dưa hấu", "10 lá bạc hà"]'::jsonb,'["Dưa hấu gọt vỏ, cắt miếng nhỏ.", "Lá bạc hà rửa sạch.", "Cho tất cả vào máy xay sinh tố, xay nhuyễn.", "Lọc qua rây và thưởng thức ngay."]'::jsonb,'Dưa hấu giúp giải độc cơ thể, làm mát, trong khi bạc hà giúp thư giãn thần kinh và làm dịu các triệu chứng ù tai.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',54,'Chương 8: Tai Mũi Họng','Ù tai, điếc tai',1,'86c6a3242660d4128ac877539b25ed106e8951f2a7798ae720986c2598d87018',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_u_tai_diec_tai_02_canh_ca_rot_ham_xuong','unclassified','CANH CÀ RỐT HẦM XƯƠNG','Ù tai và điếc tai là tình trạng khi người bệnh nghe thấy âm thanh trong tai mà không có nguồn âm thanh bên ngoài. Các triệu chứng đi kèm có thể bao gồm cảm giác tắc nghẽn tai, khó nghe và chóng mặt. Nguyên nhân: Căng thẳng, tiếp xúc với tiếng ồn lớn, tắc nghẽn tai, viêm nhiễm hoặc tổn thương thần kinh thính giác.','Xương heo rửa sạch, ninh lấy nước trong 30 phút.
Cà rốt gọt vỏ, cắt miếng, cho vào nấu mềm.
Nêm gia vị vừa ăn, thêm hành lá, dùng nóng.',0,0,0,0,0,0,'c08_u_tai_diec_tai','Ù tai, điếc tai','Ù tai và điếc tai là tình trạng khi người bệnh nghe thấy âm thanh trong tai mà không có nguồn âm thanh bên ngoài. Các triệu chứng đi kèm có thể bao gồm cảm giác tắc nghẽn tai, khó nghe và chóng mặt. Nguyên nhân: Căng thẳng, tiếp xúc với tiếng ồn lớn, tắc nghẽn tai, viêm nhiễm hoặc tổn thương thần kinh thính giác.',8,'Tai Mũi Họng','["1 củ cà rốt", "200g xương heo", "1 ít hành lá", "Gia vị: muối, tiêu, nước mắm"]'::jsonb,'["Xương heo rửa sạch, ninh lấy nước trong 30 phút.", "Cà rốt gọt vỏ, cắt miếng, cho vào nấu mềm.", "Nêm gia vị vừa ăn, thêm hành lá, dùng nóng."]'::jsonb,'Cà rốt chứa vitamin A, giúp bảo vệ thần kinh thính giác, trong khi xương hầm cung cấp collagen và khoáng chất hỗ trợ tuần hoàn máu đến tai.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',55,'Chương 8: Tai Mũi Họng','Ù tai, điếc tai',2,'519890b47e7c14b16700ed51d8d06e27e4b4d6c3628485ae21eaf6883f468ee1',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_viem_ket_mac_truyen_nhiem_01_sinh_to_ca_rot_ca_chua','unclassified','SINH TỐ CÀ RỐT – CÀ CHUA','Viêm kết mạc truyền nhiễm là tình trạng viêm nhiễm ở kết mạc mắt, gây đỏ mắt, ngứa, chảy nước mắt và có thể có mủ. Tình trạng này có thể lây qua tiếp xúc với vi khuẩn, virus hoặc chất kích thích.','Cà rốt và cà chua rửa sạch, cắt nhỏ.
Cho tất cả vào máy xay sinh tố cùng nước lọc, xay nhuyễn.
Lọc lấy nước, thêm mật ong, uống ngay.',0,0,0,0,0,0,'c08_viem_ket_mac_truyen_nhiem','Viêm kết mạc truyền nhiễm','Viêm kết mạc truyền nhiễm là tình trạng viêm nhiễm ở kết mạc mắt, gây đỏ mắt, ngứa, chảy nước mắt và có thể có mủ. Tình trạng này có thể lây qua tiếp xúc với vi khuẩn, virus hoặc chất kích thích.',8,'Tai Mũi Họng','["1 củ cà rốt", "1 quả cà chua", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Cà rốt và cà chua rửa sạch, cắt nhỏ.", "Cho tất cả vào máy xay sinh tố cùng nước lọc, xay nhuyễn.", "Lọc lấy nước, thêm mật ong, uống ngay."]'::jsonb,'Trà xanh có tính kháng viêm, giúp làm dịu mắt, trong khi bạc hà có tác dụng làm mát, hỗ trợ điều trị viêm kết mạc.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',55,'Chương 8: Tai Mũi Họng','Viêm kết mạc truyền nhiễm',1,'a3f5757323908f665df718777e34fb2c0da5623e556e82bc9ce41e35bda8ba35',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_viem_ket_mac_truyen_nhiem_02_canh_rau_ngot_nau_thit_bam','unclassified','CANH RAU NGÓT NẤU THỊT BĂM','Viêm kết mạc truyền nhiễm là tình trạng viêm nhiễm ở kết mạc mắt, gây đỏ mắt, ngứa, chảy nước mắt và có thể có mủ. Tình trạng này có thể lây qua tiếp xúc với vi khuẩn, virus hoặc chất kích thích.','Rau ngót rửa sạch, vò nhẹ để ra chất dinh dưỡng.
Phi hành tím, xào thịt băm, thêm nước nấu sôi.
Cho rau ngót vào, nấu chín mềm, nêm gia vị vừa ăn.',0,0,0,0,0,0,'c08_viem_ket_mac_truyen_nhiem','Viêm kết mạc truyền nhiễm','Viêm kết mạc truyền nhiễm là tình trạng viêm nhiễm ở kết mạc mắt, gây đỏ mắt, ngứa, chảy nước mắt và có thể có mủ. Tình trạng này có thể lây qua tiếp xúc với vi khuẩn, virus hoặc chất kích thích.',8,'Tai Mũi Họng','["1 bó rau ngót", "100g thịt nạc băm", "1 củ hành tím", "Gia vị: muối, tiêu, nước mắm"]'::jsonb,'["Rau ngót rửa sạch, vò nhẹ để ra chất dinh dưỡng.", "Phi hành tím, xào thịt băm, thêm nước nấu sôi.", "Cho rau ngót vào, nấu chín mềm, nêm gia vị vừa ăn."]'::jsonb,'Rau ngót giàu vitamin C giúp tăng cường hệ miễn dịch, giảm viêm nhiễm, hỗ trợ mắt khỏe mạnh.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',56,'Chương 8: Tai Mũi Họng','Viêm kết mạc truyền nhiễm',2,'fc1eddb54a0bdae6250f04d6c92a3da58aedcd693c8ed5635dbf9163b73d88ba',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_benh_quang_ga_01_sinh_to_ca_rot_va_dua','unclassified','SINH TỐ CÀ RỐT VÀ DỨA','Bệnh quáng gà là tình trạng mắt không thể nhìn rõ trong điều kiện ánh sáng yếu hoặc ban đêm. Nguyên nhân chủ yếu là do thiếu vitamin A, rối loạn chức năng mắt hoặc các bệnh lý về võng mạc.','Cà rốt và dứa gọt vỏ, cắt miếng nhỏ.
Cho vào máy xay sinh tố, xay nhuyễn.
Lọc qua rây và uống ngay.',0,0,0,0,0,0,'c08_benh_quang_ga','Bệnh quáng gà','Bệnh quáng gà là tình trạng mắt không thể nhìn rõ trong điều kiện ánh sáng yếu hoặc ban đêm. Nguyên nhân chủ yếu là do thiếu vitamin A, rối loạn chức năng mắt hoặc các bệnh lý về võng mạc.',8,'Tai Mũi Họng','["1 củ cà rốt", "1/2 quả dứa"]'::jsonb,'["Cà rốt và dứa gọt vỏ, cắt miếng nhỏ.", "Cho vào máy xay sinh tố, xay nhuyễn.", "Lọc qua rây và uống ngay."]'::jsonb,'Cà rốt giàu vitamin A, giúp bảo vệ mắt và cải thiện tầm nhìn. Dứa có tác dụng thanh nhiệt và bổ sung vitamin C cho cơ thể.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',56,'Chương 8: Tai Mũi Họng','Bệnh quáng gà',1,'778cf604411f0c6b4d6b0d6bca15efcdd65e68e812f15e5e397df8c4a2ddb558',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c08_benh_quang_ga_02_canh_rau_den_do_voi_hat_sen','unclassified','CANH RAU DỀN ĐỎ VỚI HẠT SEN','Bệnh quáng gà là tình trạng mắt không thể nhìn rõ trong điều kiện ánh sáng yếu hoặc ban đêm. Nguyên nhân chủ yếu là do thiếu vitamin A, rối loạn chức năng mắt hoặc các bệnh lý về võng mạc.','Rau dền đỏ rửa sạch, hạt sen ngâm mềm.
Nấu rau dền và hạt sen với nước cho đến khi mềm.
Thêm gia vị vừa ăn.',0,0,0,0,0,0,'c08_benh_quang_ga','Bệnh quáng gà','Bệnh quáng gà là tình trạng mắt không thể nhìn rõ trong điều kiện ánh sáng yếu hoặc ban đêm. Nguyên nhân chủ yếu là do thiếu vitamin A, rối loạn chức năng mắt hoặc các bệnh lý về võng mạc.',8,'Tai Mũi Họng','["100g rau dền đỏ", "50g hạt sen", "Gia vị: muối, tiêu"]'::jsonb,'["Rau dền đỏ rửa sạch, hạt sen ngâm mềm.", "Nấu rau dền và hạt sen với nước cho đến khi mềm.", "Thêm gia vị vừa ăn."]'::jsonb,'Rau dền đỏ giàu vitamin và khoáng chất giúp bảo vệ mắt, hạt sen giúp cải thiện sức khỏe tổng thể và giảm căng thẳng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',57,'Chương 8: Tai Mũi Họng','Bệnh quáng gà',2,'68a9cd44b1d7b17f9e112525b0c04d9c009aed2cbf1a70ea1e3568cde8b00eb2',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_mun_trung_ca_01_sinh_to_rau_ma_va_dua_chuot','unclassified','SINH TỐ RAU MÁ VÀ DƯA CHUỘT','Mụn trứng cá là tình trạng viêm da phổ biến, đặc biệt ở tuổi dậy thì. Chế độ ăn uống giàu chất chống oxy hóa và vitamin có thể giúp cải thiện tình trạng này.','Rửa sạch rau má và dưa chuột, cắt nhỏ.
Cho rau má, dưa chuột, nước dừa và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c09_mun_trung_ca','Mụn trứng cá','Mụn trứng cá là tình trạng viêm da phổ biến, đặc biệt ở tuổi dậy thì. Chế độ ăn uống giàu chất chống oxy hóa và vitamin có thể giúp cải thiện tình trạng này.',9,'Bệnh Da Liễu','["1 nắm rau má", "1 quả dưa chuột", "200ml nước dừa tươi", "1 thìa mật ong"]'::jsonb,'["Rửa sạch rau má và dưa chuột, cắt nhỏ.", "Cho rau má, dưa chuột, nước dừa và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Rau má và dưa chuột có tính mát, giúp thanh nhiệt, giải độc, hỗ trợ làm giảm mụn trứng cá.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',57,'Chương 9: Bệnh Da Liễu','Mụn trứng cá',1,'19b5556cd36e1d19d8e220f685cad12a040b75b0ac68445fca2790823cf69aef',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_mun_trung_ca_02_canh_bi_dao_nau_tom','unclassified','CANH BÍ ĐAO NẤU TÔM','Mụn trứng cá là tình trạng viêm da phổ biến, đặc biệt ở tuổi dậy thì. Chế độ ăn uống giàu chất chống oxy hóa và vitamin có thể giúp cải thiện tình trạng này.','Bí đao gọt vỏ, cắt miếng vừa ăn.
Tôm bóc vỏ, bỏ đầu, rửa sạch.
Phi hành tím với dầu, cho tôm vào xào sơ.
Thêm nước, đun sôi rồi cho bí đao vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c09_mun_trung_ca','Mụn trứng cá','Mụn trứng cá là tình trạng viêm da phổ biến, đặc biệt ở tuổi dậy thì. Chế độ ăn uống giàu chất chống oxy hóa và vitamin có thể giúp cải thiện tình trạng này.',9,'Bệnh Da Liễu','["300g bí đao", "100g tôm tươi", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Bí đao gọt vỏ, cắt miếng vừa ăn.", "Tôm bóc vỏ, bỏ đầu, rửa sạch.", "Phi hành tím với dầu, cho tôm vào xào sơ.", "Thêm nước, đun sôi rồi cho bí đao vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Bí đao có tính mát, giúp thanh nhiệt, giải độc, hỗ trợ làm giảm mụn trứng cá.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',57,'Chương 9: Bệnh Da Liễu','Mụn trứng cá',2,'2db30c664a9b7ec681c621868d36d3e9190ec6a69304dd09a20ed08fabe2c26b',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_mun_trung_ca_03_salad_rau_diep_ca_va_ca_chua','unclassified','SALAD RAU DIẾP CÁ VÀ CÀ CHUA','Mụn trứng cá là tình trạng viêm da phổ biến, đặc biệt ở tuổi dậy thì. Chế độ ăn uống giàu chất chống oxy hóa và vitamin có thể giúp cải thiện tình trạng này.','Rau diếp cá rửa sạch, để ráo.
Cà chua rửa sạch, cắt lát.
Pha nước sốt với nước cốt chanh, muối, đường và dầu ô liu.
Trộn đều rau diếp cá và cà chua với nước sốt.',0,0,0,0,0,0,'c09_mun_trung_ca','Mụn trứng cá','Mụn trứng cá là tình trạng viêm da phổ biến, đặc biệt ở tuổi dậy thì. Chế độ ăn uống giàu chất chống oxy hóa và vitamin có thể giúp cải thiện tình trạng này.',9,'Bệnh Da Liễu','["200g rau diếp cá", "2 quả cà chua", "1 quả chanh", "Gia vị: muối, đường, dầu ô liu"]'::jsonb,'["Rau diếp cá rửa sạch, để ráo.", "Cà chua rửa sạch, cắt lát.", "Pha nước sốt với nước cốt chanh, muối, đường và dầu ô liu.", "Trộn đều rau diếp cá và cà chua với nước sốt."]'::jsonb,'Rau diếp cá và cà chua giàu vitamin C và chất chống oxy hóa, giúp làm sạch da và giảm mụn.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',58,'Chương 9: Bệnh Da Liễu','Mụn trứng cá',3,'aad78f1e343d34c644d14a0f5a17c2f0933a1e34a306c6c843ba58349afd9f7b',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_nam_da_01_canh_ca_loc_nau_rau_mong_toi','unclassified','CANH CÁ LÓC NẤU RAU MỒNG TƠI','Nám da là tình trạng xuất hiện các đốm nâu hoặc đen trên da, thường gặp ở vùng má, trán, mũi và cằm. Bệnh không gây nguy hiểm nhưng ảnh hưởng đến thẩm mỹ. Nám da thường do sự thay đổi nội tiết tố, đặc biệt là trong thai kỳ, sử dụng thuốc tránh thai, hoặc do tác động của ánh nắng mặt trời. Nguyên nhân: Tăng sắc tố do ánh nắng mặt trời, thay đổi nội tiết tố, di truyền, sử dụng mỹ phẩm không phù hợp, căng thẳng.','Cá lóc làm sạch, cắt khúc vừa ăn.
Rau mồng tơi rửa sạch, cắt khúc.
Phi hành với dầu ăn cho thơm, cho cá vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau mồng tơi vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c09_nam_da','Nám da','Nám da là tình trạng xuất hiện các đốm nâu hoặc đen trên da, thường gặp ở vùng má, trán, mũi và cằm. Bệnh không gây nguy hiểm nhưng ảnh hưởng đến thẩm mỹ. Nám da thường do sự thay đổi nội tiết tố, đặc biệt là trong thai kỳ, sử dụng thuốc tránh thai, hoặc do tác động của ánh nắng mặt trời. Nguyên nhân: Tăng sắc tố do ánh nắng mặt trời, thay đổi nội tiết tố, di truyền, sử dụng mỹ phẩm không phù hợp, căng thẳng.',9,'Bệnh Da Liễu','["200g cá lóc", "100g rau mồng tơi", "Gia vị: muối, tiêu"]'::jsonb,'["Cá lóc làm sạch, cắt khúc vừa ăn.", "Rau mồng tơi rửa sạch, cắt khúc.", "Phi hành với dầu ăn cho thơm, cho cá vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau mồng tơi vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Cá lóc cung cấp omega-3 giúp làm đẹp da, rau mồng tơi giúp làm mát và thanh nhiệt, hỗ trợ làm sáng da.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',58,'Chương 9: Bệnh Da Liễu','Nám da',1,'47b2fa08925a5f70aa9e95910a16f025c2a0414c17afb35ac696332951834e4c',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_nam_da_02_sinh_to_du_du_sua_chua','unclassified','SINH TỐ ĐU ĐỦ – SỮA CHUA','Nám da là tình trạng xuất hiện các đốm nâu hoặc đen trên da, thường gặp ở vùng má, trán, mũi và cằm. Bệnh không gây nguy hiểm nhưng ảnh hưởng đến thẩm mỹ. Nám da thường do sự thay đổi nội tiết tố, đặc biệt là trong thai kỳ, sử dụng thuốc tránh thai, hoặc do tác động của ánh nắng mặt trời. Nguyên nhân: Tăng sắc tố do ánh nắng mặt trời, thay đổi nội tiết tố, di truyền, sử dụng mỹ phẩm không phù hợp, căng thẳng.','Đu đủ gọt vỏ, bỏ hạt, cắt nhỏ.
Cho đu đủ, sữa chua, nước lọc vào máy xay, xay nhuyễn.
Thêm mật ong, khuấy đều, uống ngay.',0,0,0,0,0,0,'c09_nam_da','Nám da','Nám da là tình trạng xuất hiện các đốm nâu hoặc đen trên da, thường gặp ở vùng má, trán, mũi và cằm. Bệnh không gây nguy hiểm nhưng ảnh hưởng đến thẩm mỹ. Nám da thường do sự thay đổi nội tiết tố, đặc biệt là trong thai kỳ, sử dụng thuốc tránh thai, hoặc do tác động của ánh nắng mặt trời. Nguyên nhân: Tăng sắc tố do ánh nắng mặt trời, thay đổi nội tiết tố, di truyền, sử dụng mỹ phẩm không phù hợp, căng thẳng.',9,'Bệnh Da Liễu','["½ quả đu đủ chín", "½ hũ sữa chua không đường", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Đu đủ gọt vỏ, bỏ hạt, cắt nhỏ.", "Cho đu đủ, sữa chua, nước lọc vào máy xay, xay nhuyễn.", "Thêm mật ong, khuấy đều, uống ngay."]'::jsonb,'Đu đủ chứa enzyme papain giúp làm sáng da, giảm thâm nám. Sữa chua giàu axit lactic giúp nuôi dưỡng da từ bên trong.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',59,'Chương 9: Bệnh Da Liễu','Nám da',2,'f3b1fa5645c7e0dff11134613befceb2c0325a8e696ce9fcc3e8e04791c6614d',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_nam_da_03_canh_ca_chua_nau_dau_phu','unclassified','CANH CÀ CHUA NẤU ĐẬU PHỤ','Nám da là tình trạng xuất hiện các đốm nâu hoặc đen trên da, thường gặp ở vùng má, trán, mũi và cằm. Bệnh không gây nguy hiểm nhưng ảnh hưởng đến thẩm mỹ. Nám da thường do sự thay đổi nội tiết tố, đặc biệt là trong thai kỳ, sử dụng thuốc tránh thai, hoặc do tác động của ánh nắng mặt trời. Nguyên nhân: Tăng sắc tố do ánh nắng mặt trời, thay đổi nội tiết tố, di truyền, sử dụng mỹ phẩm không phù hợp, căng thẳng.','Cà chua rửa sạch, cắt múi cau.
Đậu phụ cắt miếng vừa ăn.
Phi hành, xào cà chua, đổ nước vào nấu sôi.
Thêm đậu phụ, nấu 5 phút, nêm gia vị vừa ăn.',0,0,0,0,0,0,'c09_nam_da','Nám da','Nám da là tình trạng xuất hiện các đốm nâu hoặc đen trên da, thường gặp ở vùng má, trán, mũi và cằm. Bệnh không gây nguy hiểm nhưng ảnh hưởng đến thẩm mỹ. Nám da thường do sự thay đổi nội tiết tố, đặc biệt là trong thai kỳ, sử dụng thuốc tránh thai, hoặc do tác động của ánh nắng mặt trời. Nguyên nhân: Tăng sắc tố do ánh nắng mặt trời, thay đổi nội tiết tố, di truyền, sử dụng mỹ phẩm không phù hợp, căng thẳng.',9,'Bệnh Da Liễu','["2 quả cà chua", "1 miếng đậu phụ", "1 ít hành lá", "Gia vị: muối, tiêu, nước mắm"]'::jsonb,'["Cà chua rửa sạch, cắt múi cau.", "Đậu phụ cắt miếng vừa ăn.", "Phi hành, xào cà chua, đổ nước vào nấu sôi.", "Thêm đậu phụ, nấu 5 phút, nêm gia vị vừa ăn."]'::jsonb,'Cà chua giàu lycopene giúp chống oxy hóa, bảo vệ da khỏi tác động của tia UV. Đậu phụ chứa isoflavone giúp cân bằng nội tiết tố, hỗ trợ làm mờ nám.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',59,'Chương 9: Bệnh Da Liễu','Nám da',3,'ba365b2f3401225902cd0c7243b2225efc9cecb0466a96255a7de7bc46bb4a36',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_te_cong_01_canh_rau_cu_cai_voi_tom','unclassified','CANH RAU CỦ CẢI VỚI TÔM','Tê cóng là cảm giác tê bì, lạnh ở tay, chân, đặc biệt là khi cơ thể tiếp xúc với nhiệt độ lạnh. Tình trạng này có thể xuất hiện do thiếu máu, rối loạn tuần hoàn máu, hoặc mắc các bệnh về thần kinh. Nguyên nhân: thiếu hụt vitamin B12, căng thẳng hoặc tiếp xúc lâu dài với lạnh.','Tôm làm sạch, củ cải gọt vỏ, cắt miếng vừa ăn.
Phi hành với dầu ăn cho thơm, cho tôm vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho củ cải vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c09_te_cong','Tê cóng','Tê cóng là cảm giác tê bì, lạnh ở tay, chân, đặc biệt là khi cơ thể tiếp xúc với nhiệt độ lạnh. Tình trạng này có thể xuất hiện do thiếu máu, rối loạn tuần hoàn máu, hoặc mắc các bệnh về thần kinh. Nguyên nhân: thiếu hụt vitamin B12, căng thẳng hoặc tiếp xúc lâu dài với lạnh.',9,'Bệnh Da Liễu','["200g tôm", "100g củ cải", "Gia vị: muối, tiêu"]'::jsonb,'["Tôm làm sạch, củ cải gọt vỏ, cắt miếng vừa ăn.", "Phi hành với dầu ăn cho thơm, cho tôm vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho củ cải vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Củ cải giúp lưu thông khí huyết, tôm bổ sung protein giúp cải thiện tuần hoàn máu, giảm tê cóng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',60,'Chương 9: Bệnh Da Liễu','Tê cóng',1,'66dee2e5336bc7333c7028cea40790a1ee1588d729e52b31e2dfb5b6d1904447',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_te_cong_02_nuoc_ep_ca_rot_va_cu_den','unclassified','NƯỚC ÉP CÀ RỐT VÀ CỦ DỀN','Tê cóng là cảm giác tê bì, lạnh ở tay, chân, đặc biệt là khi cơ thể tiếp xúc với nhiệt độ lạnh. Tình trạng này có thể xuất hiện do thiếu máu, rối loạn tuần hoàn máu, hoặc mắc các bệnh về thần kinh. Nguyên nhân: thiếu hụt vitamin B12, căng thẳng hoặc tiếp xúc lâu dài với lạnh.','Cà rốt và củ dền gọt vỏ, cắt miếng vừa ăn.
Cho vào máy xay, xay nhuyễn và lọc qua rây.
Uống ngay.',0,0,0,0,0,0,'c09_te_cong','Tê cóng','Tê cóng là cảm giác tê bì, lạnh ở tay, chân, đặc biệt là khi cơ thể tiếp xúc với nhiệt độ lạnh. Tình trạng này có thể xuất hiện do thiếu máu, rối loạn tuần hoàn máu, hoặc mắc các bệnh về thần kinh. Nguyên nhân: thiếu hụt vitamin B12, căng thẳng hoặc tiếp xúc lâu dài với lạnh.',9,'Bệnh Da Liễu','["1 củ cà rốt", "1 củ dền"]'::jsonb,'["Cà rốt và củ dền gọt vỏ, cắt miếng vừa ăn.", "Cho vào máy xay, xay nhuyễn và lọc qua rây.", "Uống ngay."]'::jsonb,'Cà rốt và củ dền giúp tăng cường tuần hoàn máu, bổ sung dưỡng chất giúp cải thiện tình trạng tê cóng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',60,'Chương 9: Bệnh Da Liễu','Tê cóng',2,'af212c9d8706bf23c6d357198fbd9cf47b48354c22bbcda4a1a446851bad6497',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c09_te_cong_03_tra_gung_que_mat_ong','unclassified','TRÀ GỪNG – QUẾ – MẬT ONG','Tê cóng là cảm giác tê bì, lạnh ở tay, chân, đặc biệt là khi cơ thể tiếp xúc với nhiệt độ lạnh. Tình trạng này có thể xuất hiện do thiếu máu, rối loạn tuần hoàn máu, hoặc mắc các bệnh về thần kinh. Nguyên nhân: thiếu hụt vitamin B12, căng thẳng hoặc tiếp xúc lâu dài với lạnh.','Gừng thái lát mỏng, quế cho vào cốc.
Đổ nước sôi vào, để ngấm trong 5 phút.
Thêm mật ong vào và khuấy đều.',0,0,0,0,0,0,'c09_te_cong','Tê cóng','Tê cóng là cảm giác tê bì, lạnh ở tay, chân, đặc biệt là khi cơ thể tiếp xúc với nhiệt độ lạnh. Tình trạng này có thể xuất hiện do thiếu máu, rối loạn tuần hoàn máu, hoặc mắc các bệnh về thần kinh. Nguyên nhân: thiếu hụt vitamin B12, căng thẳng hoặc tiếp xúc lâu dài với lạnh.',9,'Bệnh Da Liễu','["1 nhánh gừng tươi, 1 nhánh quế", "1 thìa mật ong", "Nước sôi"]'::jsonb,'["Gừng thái lát mỏng, quế cho vào cốc.", "Đổ nước sôi vào, để ngấm trong 5 phút.", "Thêm mật ong vào và khuấy đều."]'::jsonb,'Gừng giúp kích thích tuần hoàn máu, làm ấm cơ thể, mật ong hỗ trợ tăng cường hệ miễn dịch và làm dịu cơ thể.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',60,'Chương 9: Bệnh Da Liễu','Tê cóng',3,'0c46b72daa0e636b3c5ac8703b12e149c9c5fca5a2291ff3c71492d51d03831a',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_bieng_an_01_sinh_to_xoai_hanh_nhan','unclassified','SINH TỐ XOÀI HẠNH NHÂN','Biếng ăn là tình trạng trẻ không muốn ăn hoặc ăn ít, dẫn đến thiếu hụt dinh dưỡng. Chế độ ăn uống giàu dinh dưỡng và hấp dẫn có thể giúp cải thiện tình trạng này.','Xoài gọt vỏ, cắt nhỏ
Cho xoài, hạnh nhân, sữa và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c10_bieng_an','Biếng ăn','Biếng ăn là tình trạng trẻ không muốn ăn hoặc ăn ít, dẫn đến thiếu hụt dinh dưỡng. Chế độ ăn uống giàu dinh dưỡng và hấp dẫn có thể giúp cải thiện tình trạng này.',10,'Nhi Khoa','["1 quả xoài chín", "10g hạnh nhân lát", "200ml sữa tươi hoặc sữa hạnh nhân", "1 thìa mật ong"]'::jsonb,'["Xoài gọt vỏ, cắt nhỏ", "Cho xoài, hạnh nhân, sữa và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Xoài và hạnh nhân giàu vitamin và khoáng chất, giúp kích thích vị giác và cải thiện tình trạng biếng ăn.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',61,'Chương 10: Nhi Khoa','Biếng ăn',1,'431b3d104e70c8cbf2f1b2c1643840b8513f8ab5f312cbc4557238e67ae0890a',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_bieng_an_02_chao_khoai_lang_hat_dieu','unclassified','CHÁO KHOAI LANG HẠT ĐIỀU','Biếng ăn là tình trạng trẻ không muốn ăn hoặc ăn ít, dẫn đến thiếu hụt dinh dưỡng. Chế độ ăn uống giàu dinh dưỡng và hấp dẫn có thể giúp cải thiện tình trạng này.','Khoai lang gọt vỏ, cắt nhỏ, nấu chín.
Hạt điều xay nhuyễn, cho vào nấu cùng khoai lang.
Khi cháo nhuyễn, thêm đường phèn, khuấy đều.',0,0,0,0,0,0,'c10_bieng_an','Biếng ăn','Biếng ăn là tình trạng trẻ không muốn ăn hoặc ăn ít, dẫn đến thiếu hụt dinh dưỡng. Chế độ ăn uống giàu dinh dưỡng và hấp dẫn có thể giúp cải thiện tình trạng này.',10,'Nhi Khoa','["100g khoai lang", "30g hạt điều", "200ml nước", "1 ít đường phèn"]'::jsonb,'["Khoai lang gọt vỏ, cắt nhỏ, nấu chín.", "Hạt điều xay nhuyễn, cho vào nấu cùng khoai lang.", "Khi cháo nhuyễn, thêm đường phèn, khuấy đều."]'::jsonb,'Khoai lang giàu beta-carotene giúp kích thích vị giác, hạt điều cung cấp protein và chất béo tốt.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',61,'Chương 10: Nhi Khoa','Biếng ăn',2,'434d0af72a558d053e2e44feb22923b5abaf6e18603c013ae2539237b7e07db4',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_bieng_an_03_canh_bi_do_nau_thit_ga','unclassified','CANH BÍ ĐỎ NẤU THỊT GÀ','Biếng ăn là tình trạng trẻ không muốn ăn hoặc ăn ít, dẫn đến thiếu hụt dinh dưỡng. Chế độ ăn uống giàu dinh dưỡng và hấp dẫn có thể giúp cải thiện tình trạng này.','Bí đỏ gọt vỏ, cắt miếng vừa ăn.
Thịt gà rửa sạch, thái miếng.
Phi hành tím với dầu, cho thịt gà vào xào sơ.
Thêm nước, đun sôi rồi cho bí đỏ vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c10_bieng_an','Biếng ăn','Biếng ăn là tình trạng trẻ không muốn ăn hoặc ăn ít, dẫn đến thiếu hụt dinh dưỡng. Chế độ ăn uống giàu dinh dưỡng và hấp dẫn có thể giúp cải thiện tình trạng này.',10,'Nhi Khoa','["300g bí đỏ", "200g thịt gà", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Bí đỏ gọt vỏ, cắt miếng vừa ăn.", "Thịt gà rửa sạch, thái miếng.", "Phi hành tím với dầu, cho thịt gà vào xào sơ.", "Thêm nước, đun sôi rồi cho bí đỏ vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Bí đỏ giàu vitamin A, thịt gà giàu protein, giúp cải thiện tình trạng biếng ăn.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',61,'Chương 10: Nhi Khoa','Biếng ăn',3,'f3a8c726f6ee45b6a2cda0665e71cf35a242a0afed079dfc884ae01a41b24d59',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_chung_khoc_dem_01_chao_bot_gao_voi_hat_sen','unclassified','CHÁO BỘT GẠO VỚI HẠT SEN','Chứng khóc đêm là tình trạng trẻ em hoặc người lớn thức giấc vào ban đêm và khóc hoặc kêu la, thường gặp ở trẻ sơ sinh hoặc trẻ nhỏ. Nguyên nhân có thể do đói, khát, cơn đau bụng, hoặc cảm giác không an toàn.','Hạt sen ngâm mềm, bột gạo nấu với nước cho đến khi cháo nhừ.
Thêm đường phèn vào khuấy đều.',0,0,0,0,0,0,'c10_chung_khoc_dem','Chứng khóc đêm','Chứng khóc đêm là tình trạng trẻ em hoặc người lớn thức giấc vào ban đêm và khóc hoặc kêu la, thường gặp ở trẻ sơ sinh hoặc trẻ nhỏ. Nguyên nhân có thể do đói, khát, cơn đau bụng, hoặc cảm giác không an toàn.',10,'Nhi Khoa','["50g bột gạo", "50g hạt sen", "1 ít đường phèn"]'::jsonb,'["Hạt sen ngâm mềm, bột gạo nấu với nước cho đến khi cháo nhừ.", "Thêm đường phèn vào khuấy đều."]'::jsonb,'Hạt sen giúp an thần, làm dịu thần kinh, hỗ trợ giấc ngủ ngon và giảm chứng khóc đêm.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',62,'Chương 10: Nhi Khoa','Chứng khóc đêm',1,'573e3a84f6bafc31f3ca473ead4e48d4cdb83fedab5a1e1ee4eda1d0ee92d793',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_chung_khoc_dem_02_nuoc_ep_cam_va_chanh','unclassified','NƯỚC ÉP CAM VÀ CHANH','Chứng khóc đêm là tình trạng trẻ em hoặc người lớn thức giấc vào ban đêm và khóc hoặc kêu la, thường gặp ở trẻ sơ sinh hoặc trẻ nhỏ. Nguyên nhân có thể do đói, khát, cơn đau bụng, hoặc cảm giác không an toàn.','Cam và chanh vắt lấy nước.
Thêm mật ong vào và khuấy đều.',0,0,0,0,0,0,'c10_chung_khoc_dem','Chứng khóc đêm','Chứng khóc đêm là tình trạng trẻ em hoặc người lớn thức giấc vào ban đêm và khóc hoặc kêu la, thường gặp ở trẻ sơ sinh hoặc trẻ nhỏ. Nguyên nhân có thể do đói, khát, cơn đau bụng, hoặc cảm giác không an toàn.',10,'Nhi Khoa','["2 quả cam", "1 quả chanh", "1 thìa mật ong"]'::jsonb,'["Cam và chanh vắt lấy nước.", "Thêm mật ong vào và khuấy đều."]'::jsonb,'Vitamin C từ cam và chanh giúp thư giãn, giảm căng thẳng và giúp trẻ ngủ ngon.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',62,'Chương 10: Nhi Khoa','Chứng khóc đêm',2,'e9f8b9121197fcaffdfa7500389bcf037e2f3ca021e263652d05834e8da47331',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_suy_dinh_duong_01_chao_thit_bo_bi_do','unclassified','CHÁO THỊT BÒ – BÍ ĐỎ','Suy dinh dưỡng là tình trạng thiếu hụt dưỡng chất cần thiết, dẫn đến chậm phát triển thể chất và trí tuệ, dễ mắc bệnh. Tình trạng này thường do chế độ ăn thiếu hụt vitamin, khoáng chất và protein. Nguyên nhân: Thiếu chất dinh dưỡng, chế độ ăn uống kém, rối loạn tiêu hóa, hoặc bệnh lý mạn tính.','Bí đỏ gọt vỏ, cắt nhỏ.
Nấu cháo với gạo và nước đến khi nhừ.
Xào thịt bò với hành tím, sau đó cho vào cháo.
Thêm bí đỏ, nấu thêm 5 phút, nêm gia vị vừa ăn.',0,0,0,0,0,0,'c10_suy_dinh_duong','Suy dinh dưỡng','Suy dinh dưỡng là tình trạng thiếu hụt dưỡng chất cần thiết, dẫn đến chậm phát triển thể chất và trí tuệ, dễ mắc bệnh. Tình trạng này thường do chế độ ăn thiếu hụt vitamin, khoáng chất và protein. Nguyên nhân: Thiếu chất dinh dưỡng, chế độ ăn uống kém, rối loạn tiêu hóa, hoặc bệnh lý mạn tính.',10,'Nhi Khoa','["½ chén gạo tẻ :", "100g thịt bò", "100g bí đỏ", "1 củ hành tím", "Gia vị: muối, tiêu, nước mắm"]'::jsonb,'["Bí đỏ gọt vỏ, cắt nhỏ.", "Nấu cháo với gạo và nước đến khi nhừ.", "Xào thịt bò với hành tím, sau đó cho vào cháo.", "Thêm bí đỏ, nấu thêm 5 phút, nêm gia vị vừa ăn."]'::jsonb,'Thịt bò giàu sắt và protein giúp tăng cường thể lực, bí đỏ bổ sung vitamin A và chất xơ hỗ trợ tiêu hóa tốt.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',63,'Chương 10: Nhi Khoa','Suy dinh dưỡng',1,'3f6824445c9b92ef14e0e7c8dcdffc1604d9649e462a7457243420a80b9b57f5',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_suy_dinh_duong_02_chao_gao_lut_voi_dau_xanh','unclassified','CHÁO GẠO LỨT VỚI ĐẬU XANH','Suy dinh dưỡng là tình trạng thiếu hụt dưỡng chất cần thiết, dẫn đến chậm phát triển thể chất và trí tuệ, dễ mắc bệnh. Tình trạng này thường do chế độ ăn thiếu hụt vitamin, khoáng chất và protein. Nguyên nhân: Thiếu chất dinh dưỡng, chế độ ăn uống kém, rối loạn tiêu hóa, hoặc bệnh lý mạn tính.','Gạo lứt và đậu xanh rửa sạch, ngâm qua đêm.
Nấu gạo lứt và đậu xanh trong nước cho đến khi cháo nhừ.
Thêm muối vào vừa ăn.',0,0,0,0,0,0,'c10_suy_dinh_duong','Suy dinh dưỡng','Suy dinh dưỡng là tình trạng thiếu hụt dưỡng chất cần thiết, dẫn đến chậm phát triển thể chất và trí tuệ, dễ mắc bệnh. Tình trạng này thường do chế độ ăn thiếu hụt vitamin, khoáng chất và protein. Nguyên nhân: Thiếu chất dinh dưỡng, chế độ ăn uống kém, rối loạn tiêu hóa, hoặc bệnh lý mạn tính.',10,'Nhi Khoa','["100g gạo lứt", "50g đậu xanh", "1 ít muối"]'::jsonb,'["Gạo lứt và đậu xanh rửa sạch, ngâm qua đêm.", "Nấu gạo lứt và đậu xanh trong nước cho đến khi cháo nhừ.", "Thêm muối vào vừa ăn."]'::jsonb,'Gạo lứt và đậu xanh giúp bổ sung chất xơ và các vi chất dinh dưỡng cần thiết cho cơ thể, hỗ trợ phục hồi sức khỏe cho người bị suy dinh dưỡng.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',63,'Chương 10: Nhi Khoa','Suy dinh dưỡng',2,'95862ca6d9809e66a982981b8da2c8a63c3dd1e5d197e4c5d3665b14e284c834',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_chung_co_giat_01_nuoc_ep_dua_tuoi','unclassified','NƯỚC ÉP DỪA TƯƠI','Co giật là sự co thắt bất thường của cơ bắp, có thể xảy ra ở các bộ phận cơ thể khác nhau. Co giật có thể là dấu hiệu của các vấn đề về thần kinh hoặc thiếu hụt dưỡng chất. Nguyên nhân: Thiếu hụt canxi, magie, vitamin D, rối loạn điện giải, hoặc các vấn đề về thần kinh.','Cắt dừa lấy nước.
Uống ngay hoặc làm mát trong tủ lạnh.',0,0,0,0,0,0,'c10_chung_co_giat','Chứng co giật','Co giật là sự co thắt bất thường của cơ bắp, có thể xảy ra ở các bộ phận cơ thể khác nhau. Co giật có thể là dấu hiệu của các vấn đề về thần kinh hoặc thiếu hụt dưỡng chất. Nguyên nhân: Thiếu hụt canxi, magie, vitamin D, rối loạn điện giải, hoặc các vấn đề về thần kinh.',10,'Nhi Khoa','["1 quả dừa tươi"]'::jsonb,'["Cắt dừa lấy nước.", "Uống ngay hoặc làm mát trong tủ lạnh."]'::jsonb,'Nước dừa cung cấp kali và magie, giúp cân bằng điện giải trong cơ thể, giảm tình trạng co giật.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',64,'Chương 10: Nhi Khoa','Chứng co giật',1,'10683dbec801cc05a0957f2c354552742c599d42531427d9c9dd680cb7fd9247',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_chung_co_giat_02_canh_rau_ngot_voi_tom','unclassified','CANH RAU NGÓT VỚI TÔM','Co giật là sự co thắt bất thường của cơ bắp, có thể xảy ra ở các bộ phận cơ thể khác nhau. Co giật có thể là dấu hiệu của các vấn đề về thần kinh hoặc thiếu hụt dưỡng chất. Nguyên nhân: Thiếu hụt canxi, magie, vitamin D, rối loạn điện giải, hoặc các vấn đề về thần kinh.','Tôm làm sạch, rau ngót rửa sạch.
Phi hành với dầu ăn cho thơm, cho tôm vào xào sơ.
Thêm nước vào nồi, đun sôi rồi cho rau ngót vào.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c10_chung_co_giat','Chứng co giật','Co giật là sự co thắt bất thường của cơ bắp, có thể xảy ra ở các bộ phận cơ thể khác nhau. Co giật có thể là dấu hiệu của các vấn đề về thần kinh hoặc thiếu hụt dưỡng chất. Nguyên nhân: Thiếu hụt canxi, magie, vitamin D, rối loạn điện giải, hoặc các vấn đề về thần kinh.',10,'Nhi Khoa','["200g tôm", "100g rau ngót", "Gia vị: muối, tiêu"]'::jsonb,'["Tôm làm sạch, rau ngót rửa sạch.", "Phi hành với dầu ăn cho thơm, cho tôm vào xào sơ.", "Thêm nước vào nồi, đun sôi rồi cho rau ngót vào.", "Nêm gia vị vừa ăn."]'::jsonb,'Tôm cung cấp protein và khoáng chất cần thiết cho cơ thể, trong khi rau ngót giúp bổ sung vitamin C và khoáng chất, hỗ trợ quá trình phục hồi.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',64,'Chương 10: Nhi Khoa','Chứng co giật',2,'ed771272e4e2dbb336d56f5ae202731d1bd8cd3784706895604b9e7d7a0df053',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_chung_dai_dam_01_canh_cu_cai_voi_rau_cai_bo_xoi','unclassified','CANH CỦ CẢI VỚI RAU CẢI BÓ XÔI','Chứng đái dầm là tình trạng không kiểm soát được việc tiểu tiện vào ban đêm, phổ biến ở trẻ em nhưng cũng có thể xảy ra ở người lớn. Nguyên nhân: Mắc các vấn đề về thần kinh, tiêu thụ nhiều nước trước khi ngủ, căng thẳng tâm lý, hoặc do di truyền.','Củ cải gọt vỏ, cắt miếng nhỏ.
Rau cải bó xôi rửa sạch, cắt khúc.
Nấu củ cải trong nước cho đến khi mềm, sau đó cho cải bó xôi vào nấu chín.
Nêm gia vị vừa ăn.',0,0,0,0,0,0,'c10_chung_dai_dam','Chứng đái dầm','Chứng đái dầm là tình trạng không kiểm soát được việc tiểu tiện vào ban đêm, phổ biến ở trẻ em nhưng cũng có thể xảy ra ở người lớn. Nguyên nhân: Mắc các vấn đề về thần kinh, tiêu thụ nhiều nước trước khi ngủ, căng thẳng tâm lý, hoặc do di truyền.',10,'Nhi Khoa','["200g củ cải", "100g cải bó xôi", "Gia vị: muối, tiêu"]'::jsonb,'["Củ cải gọt vỏ, cắt miếng nhỏ.", "Rau cải bó xôi rửa sạch, cắt khúc.", "Nấu củ cải trong nước cho đến khi mềm, sau đó cho cải bó xôi vào nấu chín.", "Nêm gia vị vừa ăn."]'::jsonb,'Củ cải và cải bó xôi giúp thanh nhiệt, giải độc, làm dịu cơ thể, hỗ trợ điều trị chứng đái dầm.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',65,'Chương 10: Nhi Khoa','Chứng đái dầm',1,'6d5463065ceea2126c2962a5aba119c1f7514f6b062cc41ad8da566ce378b43f',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_chung_dai_dam_02_sinh_to_cam_va_bac_ha','unclassified','SINH TỐ CAM VÀ BẠC HÀ','Chứng đái dầm là tình trạng không kiểm soát được việc tiểu tiện vào ban đêm, phổ biến ở trẻ em nhưng cũng có thể xảy ra ở người lớn. Nguyên nhân: Mắc các vấn đề về thần kinh, tiêu thụ nhiều nước trước khi ngủ, căng thẳng tâm lý, hoặc do di truyền.','Cam vắt lấy nước, lá bạc hà rửa sạch.
Cho cam và bạc hà vào máy xay, xay nhuyễn.
Uống ngay.',0,0,0,0,0,0,'c10_chung_dai_dam','Chứng đái dầm','Chứng đái dầm là tình trạng không kiểm soát được việc tiểu tiện vào ban đêm, phổ biến ở trẻ em nhưng cũng có thể xảy ra ở người lớn. Nguyên nhân: Mắc các vấn đề về thần kinh, tiêu thụ nhiều nước trước khi ngủ, căng thẳng tâm lý, hoặc do di truyền.',10,'Nhi Khoa','["2 quả cam", "10 lá bạc hà"]'::jsonb,'["Cam vắt lấy nước, lá bạc hà rửa sạch.", "Cho cam và bạc hà vào máy xay, xay nhuyễn.", "Uống ngay."]'::jsonb,'Cam cung cấp vitamin C giúp làm dịu thần kinh, bạc hà hỗ trợ giảm căng thẳng và kích thích chức năng thận.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',65,'Chương 10: Nhi Khoa','Chứng đái dầm',2,'3413c37c2e740f4a5a63fc77577f563f61a83d119b9cd277ff49f07e1cbdbfcd',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_beo_phi_01_salad_dau_o_liu_va_hat_chia','unclassified','SALAD DẦU Ô LIU VÀ HẠT CHIA','Béo phì là tình trạng cơ thể tích trữ quá nhiều mỡ, dẫn đến tăng cân không kiểm soát và ảnh hưởng đến sức khỏe tổng thể. Nguyên nhân: Chế độ ăn nhiều calo, ít vận động, di truyền, hoặc các vấn đề về hormone.','Xà lách và cà chua bi rửa sạch, thái nhỏ.
Cho tất cả vào một bát lớn, trộn đều với dầu ô liu và hạt chia.',0,0,0,0,0,0,'c10_beo_phi','Béo phì','Béo phì là tình trạng cơ thể tích trữ quá nhiều mỡ, dẫn đến tăng cân không kiểm soát và ảnh hưởng đến sức khỏe tổng thể. Nguyên nhân: Chế độ ăn nhiều calo, ít vận động, di truyền, hoặc các vấn đề về hormone.',10,'Nhi Khoa','["50g rau xà lách", "50g cà chua bi", "1 thìa dầu ô liu", "1 thìa hạt chia"]'::jsonb,'["Xà lách và cà chua bi rửa sạch, thái nhỏ.", "Cho tất cả vào một bát lớn, trộn đều với dầu ô liu và hạt chia."]'::jsonb,'Dầu ô liu giúp giảm viêm và mỡ thừa, hạt chia giúp tăng cường quá trình trao đổi chất, hỗ trợ giảm cân.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',66,'Chương 10: Nhi Khoa','Béo phì',1,'a644872e3490d596872fab5fb00922dff8c56200210e7039868ca396dd13bb6e',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c10_beo_phi_02_nuoc_ep_dua_hau_va_la_huong_duong','unclassified','NƯỚC ÉP DƯA HẤU VÀ LÁ HƯỚNG DƯƠNG','Béo phì là tình trạng cơ thể tích trữ quá nhiều mỡ, dẫn đến tăng cân không kiểm soát và ảnh hưởng đến sức khỏe tổng thể. Nguyên nhân: Chế độ ăn nhiều calo, ít vận động, di truyền, hoặc các vấn đề về hormone.','Dưa hấu gọt vỏ, cắt miếng nhỏ.
Lá hướng dương rửa sạch.
Cho tất cả vào máy xay sinh tố, xay nhuyễn.
Lọc qua rây và uống ngay.',0,0,0,0,0,0,'c10_beo_phi','Béo phì','Béo phì là tình trạng cơ thể tích trữ quá nhiều mỡ, dẫn đến tăng cân không kiểm soát và ảnh hưởng đến sức khỏe tổng thể. Nguyên nhân: Chế độ ăn nhiều calo, ít vận động, di truyền, hoặc các vấn đề về hormone.',10,'Nhi Khoa','["200g dưa hấu", "10 lá hướng dương"]'::jsonb,'["Dưa hấu gọt vỏ, cắt miếng nhỏ.", "Lá hướng dương rửa sạch.", "Cho tất cả vào máy xay sinh tố, xay nhuyễn.", "Lọc qua rây và uống ngay."]'::jsonb,'Dưa hấu giúp giảm mỡ thừa, giải độc cơ thể, lá hướng dương có tác dụng làm dịu cơ thể, hỗ trợ tiêu hóa và giảm béo.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',66,'Chương 10: Nhi Khoa','Béo phì',2,'8ce8beace74224574225a9fd7342beacbf4563f69274dd63ba412988ef908485',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_loang_xuong_01_canh_xuong_ham_du_du','unclassified','CANH XƯƠNG HẦM ĐU ĐỦ','Loãng xương là tình trạng xương bị mất mật độ, trở nên giòn và dễ gãy. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.','Xương heo rửa sạch, chặt khúc.
Đu đủ gọt vỏ, cắt miếng vừa ăn.
Phi hành tím với dầu, cho xương vào xào sơ.
Thêm nước, đun sôi rồi cho đu đủ vào hầm đến khi chín mềm.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c13_loang_xuong','Loãng xương','Loãng xương là tình trạng xương bị mất mật độ, trở nên giòn và dễ gãy. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["500g xương heo", "1 quả đu đủ xanh", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Xương heo rửa sạch, chặt khúc.", "Đu đủ gọt vỏ, cắt miếng vừa ăn.", "Phi hành tím với dầu, cho xương vào xào sơ.", "Thêm nước, đun sôi rồi cho đu đủ vào hầm đến khi chín mềm.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Xương heo giàu canxi, đu đủ chứa enzyme hỗ trợ tiêu hóa và hấp thụ canxi.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',67,'Chương 13: Bệnh Về Xương Khớp','Loãng xương',1,'c4156bfc04e04fba2dde0b5cea9e5f0c2b2207994f055a7d106a4ad2b5569fac',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_loang_xuong_02_sinh_to_sua_hat_dieu_va_chuoi','unclassified','SINH TỐ SỮA HẠT ĐIỀU VÀ CHUỐI','Loãng xương là tình trạng xương bị mất mật độ, trở nên giòn và dễ gãy. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.','Chuối bóc vỏ, cắt nhỏ.
Cho chuối, sữa hạt điều và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c13_loang_xuong','Loãng xương','Loãng xương là tình trạng xương bị mất mật độ, trở nên giòn và dễ gãy. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["1 quả chuối", "200ml sữa hạt điều", "1 thìa mật ong"]'::jsonb,'["Chuối bóc vỏ, cắt nhỏ.", "Cho chuối, sữa hạt điều và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Sữa hạt điều giàu canxi, chuối chứa kali giúp tăng cường sức khỏe xương.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',67,'Chương 13: Bệnh Về Xương Khớp','Loãng xương',2,'77d67b46f77a192177f527e8589702ef42b6133c2ba1a1130f58e0afc0f8ded0',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_loang_xuong_03_salad_cai_xoan_va_hat_chia','unclassified','SALAD CẢI XOĂN VÀ HẠT CHIA','Loãng xương là tình trạng xương bị mất mật độ, trở nên giòn và dễ gãy. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.','Cải xoăn rửa sạch, để ráo.
Pha nước sốt với nước cốt chanh, muối, đường và dầu ô liu.
Trộn đều cải xoăn và hạt chia với nước sốt.',0,0,0,0,0,0,'c13_loang_xuong','Loãng xương','Loãng xương là tình trạng xương bị mất mật độ, trở nên giòn và dễ gãy. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["200g cải xoăn", "1 thìa hạt chia", "1 quả chanh", "Gia vị: muối, đường, dầu ô liu"]'::jsonb,'["Cải xoăn rửa sạch, để ráo.", "Pha nước sốt với nước cốt chanh, muối, đường và dầu ô liu.", "Trộn đều cải xoăn và hạt chia với nước sốt."]'::jsonb,'Cải xoăn giàu canxi, hạt chia chứa omega-3 giúp tăng cường sức khỏe xương.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',67,'Chương 13: Bệnh Về Xương Khớp','Loãng xương',3,'7f008dfee5c2d5fdaa8a8fbaa001d2cd4e1c00e9dac3f01338ba7b93c69d0aa2',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_viem_khop_dang_thap_01_sinh_to_dua_va_gung','unclassified','SINH TỐ DỨA VÀ GỪNG','Viêm khớp dạng thấp là tình trạng viêm mãn tính ở các khớp, gây đau và cứng khớp. Chế độ ăn uống giàu chất chống viêm và chất chống oxy hóa có thể giúp cải thiện tình trạng này.','Dứa gọt vỏ, cắt nhỏ.
Gừng rửa sạch, thái lát.
Cho dứa, gừng, nước và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c13_viem_khop_dang_thap','Viêm khớp dạng thấp','Viêm khớp dạng thấp là tình trạng viêm mãn tính ở các khớp, gây đau và cứng khớp. Chế độ ăn uống giàu chất chống viêm và chất chống oxy hóa có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["200g dứa", "1 củ gừng nhỏ", "200ml nước lọc", "1 thìa mật ong"]'::jsonb,'["Dứa gọt vỏ, cắt nhỏ.", "Gừng rửa sạch, thái lát.", "Cho dứa, gừng, nước và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Dứa giàu enzyme bromelain có tính kháng viêm, gừng giúp giảm đau và viêm khớp.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',68,'Chương 13: Bệnh Về Xương Khớp','Viêm khớp dạng thấp',1,'39efb2c7abe2a5d84e131affa479715bdabbc77071d05dfdce3af691584bc1c6',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_viem_khop_dang_thap_02_canh_ca_hoi_va_bong_cai_xanh','unclassified','CANH CÁ HỒI VÀ BÔNG CẢI XANH','Viêm khớp dạng thấp là tình trạng viêm mãn tính ở các khớp, gây đau và cứng khớp. Chế độ ăn uống giàu chất chống viêm và chất chống oxy hóa có thể giúp cải thiện tình trạng này.','Cá hồi rửa sạch, cắt miếng vừa ăn.
Bông cải xanh rửa sạch, cắt nhỏ.
Phi hành tím với dầu ô liu, cho cá hồi vào xào sơ.
Thêm nước, đun sôi rồi cho bông cải xanh vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c13_viem_khop_dang_thap','Viêm khớp dạng thấp','Viêm khớp dạng thấp là tình trạng viêm mãn tính ở các khớp, gây đau và cứng khớp. Chế độ ăn uống giàu chất chống viêm và chất chống oxy hóa có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["200g cá hồi", "200g bông cải xanh", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ô liu"]'::jsonb,'["Cá hồi rửa sạch, cắt miếng vừa ăn.", "Bông cải xanh rửa sạch, cắt nhỏ.", "Phi hành tím với dầu ô liu, cho cá hồi vào xào sơ.", "Thêm nước, đun sôi rồi cho bông cải xanh vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Cá hồi giàu omega-3, bông cải xanh giàu chất chống oxy hóa, giúp giảm viêm và đau khớp.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',68,'Chương 13: Bệnh Về Xương Khớp','Viêm khớp dạng thấp',2,'d63733dab2a9d8919fed91ab3c4c1a856001e7c74dd233b8e90979355fd053ec',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_viem_khop_dang_thap_03_tra_xanh_va_bac_ha','unclassified','TRÀ XANH VÀ BẠC HÀ','Viêm khớp dạng thấp là tình trạng viêm mãn tính ở các khớp, gây đau và cứng khớp. Chế độ ăn uống giàu chất chống viêm và chất chống oxy hóa có thể giúp cải thiện tình trạng này.','Cho túi trà xanh và bạc hà vào cốc.
Đổ nước sôi vào, hãm trong 5-7 phút.
Uống ngay.',0,0,0,0,0,0,'c13_viem_khop_dang_thap','Viêm khớp dạng thấp','Viêm khớp dạng thấp là tình trạng viêm mãn tính ở các khớp, gây đau và cứng khớp. Chế độ ăn uống giàu chất chống viêm và chất chống oxy hóa có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["1 túi trà xanh", "1 nhánh bạc hà tươi", "200ml nước sôi"]'::jsonb,'["Cho túi trà xanh và bạc hà vào cốc.", "Đổ nước sôi vào, hãm trong 5-7 phút.", "Uống ngay."]'::jsonb,'Trà xanh và bạc hà có tính kháng viêm, giúp giảm đau và viêm khớp.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',68,'Chương 13: Bệnh Về Xương Khớp','Viêm khớp dạng thấp',3,'fbf41eaef2033082a9c4afba15debc078c39381d02c81f9b54077ddcaca2fa70',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_thoai_hoa_dot_song_co_01_sinh_to_chuoi_hat_dieu','unclassified','SINH TỐ CHUỐI HẠT ĐIỀU','Thoái hóa đốt sống cổ là tình trạng các đốt sống cổ bị thoái hóa, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và chất chống oxy hóa có thể giúp cải thiện tình trạng này. `','Chuối bóc vỏ, cắt nhỏ.
Cho chuối, hạt điều, sữa hạnh nhân và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c13_thoai_hoa_dot_song_co','Thoái hóa đốt sống cổ','Thoái hóa đốt sống cổ là tình trạng các đốt sống cổ bị thoái hóa, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và chất chống oxy hóa có thể giúp cải thiện tình trạng này. `',13,'Bệnh Về Xương Khớp','["1 quả chuối", "50g hạt điều", "200ml sữa hạnh nhân", "1 thìa mật ong"]'::jsonb,'["Chuối bóc vỏ, cắt nhỏ.", "Cho chuối, hạt điều, sữa hạnh nhân và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Chuối và hạt điều giàu kali và magie, giúp tăng cường sức khỏe xương và giảm đau đốt sống cổ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',69,'Chương 13: Bệnh Về Xương Khớp','Thoái hóa đốt sống cổ',1,'ab7c444c7c38347883a190918cc747c6d7f2313798cf4103536eb898d2464b28',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_thoai_hoa_dot_song_co_02_canh_xuong_ham_du_du','unclassified','CANH XƯƠNG HẦM ĐU ĐỦ','Thoái hóa đốt sống cổ là tình trạng các đốt sống cổ bị thoái hóa, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và chất chống oxy hóa có thể giúp cải thiện tình trạng này. `','Xương heo rửa sạch, chặt khúc.
Đu đủ gọt vỏ, cắt miếng vừa ăn.
Phi hành tím với dầu, cho xương vào xào sơ.
Thêm nước, đun sôi rồi cho đu đủ vào hầm đến khi chín mềm.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c13_thoai_hoa_dot_song_co','Thoái hóa đốt sống cổ','Thoái hóa đốt sống cổ là tình trạng các đốt sống cổ bị thoái hóa, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và chất chống oxy hóa có thể giúp cải thiện tình trạng này. `',13,'Bệnh Về Xương Khớp','["500g xương heo", "1 quả đu đủ xanh", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Xương heo rửa sạch, chặt khúc.", "Đu đủ gọt vỏ, cắt miếng vừa ăn.", "Phi hành tím với dầu, cho xương vào xào sơ.", "Thêm nước, đun sôi rồi cho đu đủ vào hầm đến khi chín mềm.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Xương heo giàu canxi, đu đủ chứa enzyme hỗ trợ tiêu hóa và hấp thụ canxi, giúp cải thiện thoái hóa đốt sống cổ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',69,'Chương 13: Bệnh Về Xương Khớp','Thoái hóa đốt sống cổ',2,'e78c3ea4297332f153b5a2c4c4b8ca359d4ea27015890a39ec376f93627f7fe2',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_thoai_hoa_dot_song_co_03_tra_gung_va_mat_ong','unclassified','TRÀ GỪNG VÀ MẬT ONG','Thoái hóa đốt sống cổ là tình trạng các đốt sống cổ bị thoái hóa, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và chất chống oxy hóa có thể giúp cải thiện tình trạng này. `','Gừng rửa sạch, thái lát.
Cho gừng vào nước sôi, hãm trong 10 phút.
Thêm mật ong, khuấy đều.
Uống ngay.',0,0,0,0,0,0,'c13_thoai_hoa_dot_song_co','Thoái hóa đốt sống cổ','Thoái hóa đốt sống cổ là tình trạng các đốt sống cổ bị thoái hóa, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và chất chống oxy hóa có thể giúp cải thiện tình trạng này. `',13,'Bệnh Về Xương Khớp','["1 củ gừng nhỏ", "1 thìa mật ong", "200ml nước sôi"]'::jsonb,'["Gừng rửa sạch, thái lát.", "Cho gừng vào nước sôi, hãm trong 10 phút.", "Thêm mật ong, khuấy đều.", "Uống ngay."]'::jsonb,'Gừng có tính kháng viêm, mật ong giúp tăng cường sức đề kháng, hỗ trợ giảm đau đốt sống cổ.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',69,'Chương 13: Bệnh Về Xương Khớp','Thoái hóa đốt sống cổ',3,'d7eb331bcedb9348fe6636249a25336b431ded1ab3b9b648ea98894c40b2b856',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_benh_tang_sinh_xuong_01_sinh_to_sua_hat_dieu_va_chuoi','unclassified','SINH TỐ SỮA HẠT ĐIỀU VÀ CHUỐI','Bệnh tăng sinh xương là tình trạng xương phát triển quá mức, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.','Chuối bóc vỏ, cắt nhỏ.
Cho chuối, sữa hạt điều và mật ong vào máy xay sinh tố.
Xay nhuyễn và dùng ngay.',0,0,0,0,0,0,'c13_benh_tang_sinh_xuong','Bệnh tăng sinh xương','Bệnh tăng sinh xương là tình trạng xương phát triển quá mức, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["1 quả chuối", "200ml sữa hạt điều", "1 thìa mật ong"]'::jsonb,'["Chuối bóc vỏ, cắt nhỏ.", "Cho chuối, sữa hạt điều và mật ong vào máy xay sinh tố.", "Xay nhuyễn và dùng ngay."]'::jsonb,'Sữa hạt điều giàu canxi, chuối chứa kali giúp tăng cường sức khỏe xương.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',70,'Chương 13: Bệnh Về Xương Khớp','Bệnh tăng sinh xương',1,'7e73ce78adbfdb369135bbdfa776f44169a5a993fe486ecca9bc431828e15d0d',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_benh_tang_sinh_xuong_02_canh_rau_cai_xoan_va_hat_chia','unclassified','CANH RAU CẢI XOĂN VÀ HẠT CHIA','Bệnh tăng sinh xương là tình trạng xương phát triển quá mức, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.','Cải xoăn rửa sạch, cắt nhỏ.
Hạt chia ngâm nước 10 phút.
Phi hành tím với dầu, cho cải xoăn vào xào sơ.
Thêm nước, đun sôi rồi cho hạt chia vào nấu chín.
Nêm nếm lại cho vừa miệng.',0,0,0,0,0,0,'c13_benh_tang_sinh_xuong','Bệnh tăng sinh xương','Bệnh tăng sinh xương là tình trạng xương phát triển quá mức, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["200g cải xoăn", "1 thìa hạt chia", "1 củ hành tím", "Gia vị: muối, tiêu, dầu ăn"]'::jsonb,'["Cải xoăn rửa sạch, cắt nhỏ.", "Hạt chia ngâm nước 10 phút.", "Phi hành tím với dầu, cho cải xoăn vào xào sơ.", "Thêm nước, đun sôi rồi cho hạt chia vào nấu chín.", "Nêm nếm lại cho vừa miệng."]'::jsonb,'Cải xoăn giàu canxi, hạt chia chứa omega-3 giúp tăng cường sức khỏe xương.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',70,'Chương 13: Bệnh Về Xương Khớp','Bệnh tăng sinh xương',2,'7f23ee0d7b29fad47d973741c620a6c1a885c423bae0a58d6156d7740eeb47a8',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
insert into public.meal_catalog (code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,source_recipe_order,source_hash,version,is_active) values ('src_c13_benh_tang_sinh_xuong_03_nuoc_hat_dau_nanh_vung_den','unclassified','NƯỚC HẠT ĐẬU NÀNH – VỪNG ĐEN','Bệnh tăng sinh xương là tình trạng xương phát triển quá mức, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.','Đậu nành ngâm nước 6 tiếng, đãi sạch vỏ.
Vừng đen rang thơm.
Xay đậu nành với nước, lọc lấy nước, đun sôi nhẹ.
Thêm vừng đen xay nhuyễn và mật ong, khuấy đều, uống ấm.',0,0,0,0,0,0,'c13_benh_tang_sinh_xuong','Bệnh tăng sinh xương','Bệnh tăng sinh xương là tình trạng xương phát triển quá mức, gây đau và hạn chế vận động. Chế độ ăn uống giàu canxi và vitamin D có thể giúp cải thiện tình trạng này.',13,'Bệnh Về Xương Khớp','["100g đậu nành", "50g vừng đen (mè đen)", "500ml nước", "1 thìa mật ong"]'::jsonb,'["Đậu nành ngâm nước 6 tiếng, đãi sạch vỏ.", "Vừng đen rang thơm.", "Xay đậu nành với nước, lọc lấy nước, đun sôi nhẹ.", "Thêm vừng đen xay nhuyễn và mật ong, khuấy đều, uống ấm."]'::jsonb,'Đậu nành và vừng đen giàu canxi, kẽm, giúp nuôi dưỡng xương khớp, làm chậm quá trình tăng sinh xương bất thường.',null,'[]'::jsonb,'[]'::jsonb,'missing_source_data','awaiting_professional_review','source_imported',false,'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',71,'Chương 13: Bệnh Về Xương Khớp','Bệnh tăng sinh xương',3,'1551ae246434224892111b0a30dbf4ea5052e5245d857a806742217375e15315',1,true) on conflict (code) do update set meal_name=excluded.meal_name, description=excluded.description, cooking_instructions=excluded.cooking_instructions, health_topic_code=excluded.health_topic_code, health_topic_name=excluded.health_topic_name, health_topic_description=excluded.health_topic_description, chapter_number=excluded.chapter_number, chapter_name=excluded.chapter_name, ingredients_json=excluded.ingredients_json, cooking_steps_json=excluded.cooking_steps_json, benefits=excluded.benefits, source_name=excluded.source_name, source_page=excluded.source_page, source_chapter=excluded.source_chapter, source_topic=excluded.source_topic, source_recipe_order=excluded.source_recipe_order, source_hash=excluded.source_hash, version=excluded.version, updated_at=now();
commit;
-- END 22-meal-catalog-source-seed.sql
