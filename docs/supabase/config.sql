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
      'Báº¡n'
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
  coalesce(u.full_name, u.email, 'Báº¡n'),
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
create index if not exists idx_nutrition_logs_subject_eaten on public.nutrition_logs (subject_id, eaten_at desc);
create index if not exists idx_ai_insights_subject_created on public.ai_insights (subject_id, created_at desc);
create index if not exists idx_ai_recommendations_subject_unread on public.ai_recommendations (subject_id, is_read, created_at desc);
create index if not exists idx_meal_catalog_type_active on public.meal_catalog (meal_type, is_active);
create index if not exists idx_exercise_catalog_category_active on public.exercise_catalog (category, is_active);
create index if not exists idx_schedule_task_catalog_category_active on public.schedule_task_catalog (category, is_active);

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
     public.nutrition_logs,
     public.ai_insights,
     public.ai_recommendations
  to authenticated;

grant select on public.meal_catalog, public.exercise_catalog, public.schedule_task_catalog to authenticated;
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
  reset_timezone text not null default 'Asia/Saigon',
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
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_group_id, subject_id)
);

create unique index if not exists idx_family_members_group_user_unique
  on public.family_members (family_group_id, user_id)
  where user_id is not null and status <> 'removed';

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

-- Family mutations must validate FamilyPlus entitlement, consent and member limits.
-- Keep writes server-only until a DD defines the exact UX and backend contract.
revoke insert, update, delete on public.family_groups, public.family_members from anon, authenticated;

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
  note text,
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
  created_at timestamptz not null default now(),
  constraint referral_relationship_no_self
    check (referrer_user_id <> referred_user_id),
  unique (referred_user_id)
);

create index if not exists idx_referral_relationships_referrer
  on public.referral_relationships (referrer_user_id, created_at desc);

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  payer_user_id uuid not null references public.users(id) on delete restrict,
  subscription_id uuid references public.membership_subscriptions(id) on delete set null,
  plan_code public.nb_membership_plan not null,
  provider text not null,
  provider_event_id text not null,
  amount_cents integer not null check (amount_cents >= 0),
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
      round(v_payment.amount_cents * v_rate)::integer,
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

-- ---------------------------------------------------------------------------

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
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations'
  ];
  v_singleton_tables text[] := array['health_profiles', 'lifestyle_habits'];
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if jsonb_typeof(p_snapshot) <> 'object' then
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
    values (v_user_id, v_user_id, 'self', 'Báº¡n', 'self')
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

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      execute format(
        'insert into public.%I '
        'select (jsonb_populate_record(null::public.%I, $1)).*',
        v_table,
        v_table
      ) using (
        (v_row - 'user_id' - 'subject_id') ||
        jsonb_build_object('user_id', v_user_id, 'subject_id', v_subject_id)
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

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      execute format(
        'insert into public.%I '
        'select (jsonb_populate_record(null::public.%I, $1)).*',
        v_table,
        v_table
      ) using (
        (v_row - 'user_id' - 'subject_id') ||
        jsonb_build_object('user_id', v_user_id, 'subject_id', v_subject_id)
      );
      v_rows := v_rows + 1;
    end loop;
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
    check (admin_status in ('active', 'suspended', 'closed'));

create table if not exists public.admin_roles (
  code text primary key
    check (code in ('super_admin', 'finance_admin', 'operations_admin')),
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

drop trigger if exists trg_admin_roles_updated_at on public.admin_roles;
create trigger trg_admin_roles_updated_at
  before update on public.admin_roles
  for each row execute function public.set_updated_at();

insert into public.admin_roles (code, display_name, description)
values
  ('super_admin', 'Super Admin', 'Full Admin control including roles and config.'),
  ('finance_admin', 'Finance Admin', 'Payment, Sale point and finance reports.'),
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

create or replace function public.get_my_admin_session()
returns table (
  user_id uuid,
  roles text[],
  permissions text[],
  is_active boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    auth.uid() as user_id,
    coalesce(array_agg(distinct aur.role_code) filter (where aur.role_code is not null), array[]::text[]) as roles,
    coalesce(array_agg(distinct arp.permission_code) filter (where arp.permission_code is not null), array[]::text[]) as permissions,
    exists (
      select 1
      from public.admin_user_roles active_aur
      where active_aur.user_id = auth.uid()
        and active_aur.is_active = true
        and active_aur.revoked_at is null
    ) as is_active
  from public.admin_user_roles aur
  left join public.admin_role_permissions arp on arp.role_code = aur.role_code
  where aur.user_id = auth.uid()
    and aur.is_active = true
    and aur.revoked_at is null
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
  select 'payments_pending', 'Payment cho duyet', count(*)::integer, 'pending', 'payments'
  from public.payment_events
  where status = 'pending'
    and created_at between p_from and p_to
  union all
  select 'sales_active', 'Sale active', count(*)::integer, 'active', 'sales'
  from public.sale_profiles
  where status = 'active'
  union all
  select
    'commission_available',
    'Diem Sale kha dung',
    coalesce(sum(amount_cents), 0)::integer,
    'approved',
    'sale_conversions'
  from public.commission_records
  where status in ('pending', 'approved')
    and available_at <= now()
    and created_at between p_from and p_to;
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
begin
  insert into public.payment_events (
    payer_user_id,
    plan_code,
    provider,
    provider_event_id,
    amount_cents,
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
    coalesce(nullif(p_currency, ''), 'VND'),
    'pending',
    null,
    p_raw_event_hash,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'manual_approval_required',
      true,
      'auto_approve_requested',
      coalesce(p_auto_approve, false)
    )
  )
  on conflict (provider, provider_event_id) do update
  set metadata = public.payment_events.metadata || excluded.metadata
  returning id into v_payment_id;

  return v_payment_id;
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
  v_effective_at timestamptz;
  v_status text;
begin
  perform public.admin_assert_permission('payments.write');

  if p_decision not in ('refund', 'cancel') then
    raise exception 'INVALID_PAYMENT_REVERSAL_DECISION' using errcode = '22023';
  end if;

  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  v_effective_at := coalesce(v_payment.paid_at, v_payment.created_at);
  if now() > v_effective_at + interval '24 hours' then
    raise exception 'PACKAGE_REFUND_CANCEL_WINDOW_CLOSED' using errcode = '22023';
  end if;

  v_status := case when p_decision = 'refund' then 'refunded' else 'failed' end;

  update public.payment_events
  set
    status = v_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason),
    metadata = metadata || jsonb_build_object('admin_decision', p_decision)
  where id = p_payment_event_id;

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
    jsonb_build_object('decision', p_decision, 'window_hours', 24)
  );

  return query select true, 'Da xu ly hoan huy trong cua so 24 gio.';
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
    approved_at = case when excluded.status = 'active' then coalesce(public.sale_profiles.approved_at, now()) else public.sale_profiles.approved_at end,
    suspended_at = case when excluded.status = 'suspended' then now() else public.sale_profiles.suspended_at end,
    closed_at = case when excluded.status = 'closed' then now() else public.sale_profiles.closed_at end,
    note = excluded.note,
    updated_at = now();

  perform public.admin_write_audit(
    'admin_review_sale_profile',
    'sale_profile',
    p_sale_user_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('decision', p_decision)
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

  insert into public.report_exports (
    report_type,
    filters,
    reason,
    requested_by
  )
  values (
    btrim(p_report_type),
    coalesce(p_filters, '{}'::jsonb),
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
    coalesce(p_filters, '{}'::jsonb)
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
  text,
  boolean,
  text,
  jsonb
) from public, anon, authenticated;

-- ---------------------------------------------------------------------------

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
  '{"enabled": false, "point_to_money_rate": 1, "minimum_point_cents": 100000, "currency": "VND"}'::jsonb,
  'active',
  'Default disabled Sale point conversion policy.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'sale_point_conversion'
    and status = 'active'
);

create or replace function public.get_my_sale_state()
returns table (
  sale_status text,
  referral_code text,
  terms_version text,
  approved_at timestamptz,
  note text
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
    sp.note
  from public.users u
  left join public.sale_profiles sp on sp.user_id = u.id
  left join lateral (
    select code
    from public.referral_codes
    where sale_user_id = u.id and status = 'active'
    order by created_at asc
    limit 1
  ) rc on true
  where u.id = auth.uid()
$$;

create or replace function public.request_sale_participation(
  p_terms_version text
)
returns table (
  sale_status text,
  referral_code text,
  terms_version text,
  approved_at timestamptz,
  note text
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
      note = 'Da cap nhat dieu le Sale trong ung dung.',
      updated_at = now()
    where user_id = v_user_id;
  else
    insert into public.sale_profiles (
      user_id,
      status,
      terms_version,
      terms_accepted_at,
      note
    )
    values (
      v_user_id,
      'pending',
      btrim(p_terms_version),
      now(),
      'Da gui yeu cau Sale; dang cho Admin duyet.'
    )
    on conflict (user_id) do update
    set
      status = 'pending',
      terms_version = excluded.terms_version,
      terms_accepted_at = excluded.terms_accepted_at,
      note = excluded.note,
      updated_at = now();
  end if;

  return query select * from public.get_my_sale_state();
end;
$$;

create or replace function public.attach_my_referral_code(
  p_referral_code text
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
  v_referrer_id uuid;
  v_referrer_name text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if v_code = '' then
    return query select false, 'Ma gioi thieu khong hop le.', null::text;
    return;
  end if;

  select rc.sale_user_id, coalesce(nullif(u.full_name, ''), 'Sale NanoBio')
  into v_referrer_id, v_referrer_name
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
    status
  )
  values (
    v_referrer_id,
    v_user_id,
    v_code,
    'signup',
    'active'
  );

  return query select true, 'Da gan ma gioi thieu.', v_referrer_name;
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
    greatest(pts.approved_cents + ads.adjustment_cents, 0)::integer,
    pts.paid_cents,
    cs.converted_cents,
    greatest(pts.approved_cents + ads.adjustment_cents - cs.converted_cents, 0)::integer,
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

create or replace function public.get_my_sale_direct_customers()
returns table (
  display_name text,
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
    dn.accepted_at,
    coalesce(p.success_count, 0),
    coalesce(pt.approved_cents, 0),
    coalesce(pt.result_currency, 'VND')
  from direct_nodes dn
  join public.users u on u.id = dn.referred_user_id
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
    idempotency_key
  )
  values (
    v_user_id,
    p_requested_point_cents,
    v_rate,
    round(p_requested_point_cents * v_rate)::integer,
    v_currency,
    'requested',
    nullif(btrim(p_idempotency_key), '')
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
    spc.id::text,
    concat(coalesce(nullif(u.full_name, ''), u.email, spc.sale_user_id::text), ' - ', spc.requested_point_cents::text, ' diem'),
    concat_ws(' - ', spc.money_amount_cents::text || ' ' || spc.currency, spc.review_reason),
    spc.status,
    'sale_point_conversions',
    spc.created_at
  from public.sale_point_conversions spc
  join public.users u on u.id = spc.sale_user_id
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or spc.id::text = p_query
  order by spc.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_review_sale_point_conversion(
  p_conversion_id uuid,
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
    metadata = metadata || jsonb_build_object('admin_decision', p_decision)
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
    jsonb_build_object('decision', p_decision, 'status', v_status)
  );

  return query select true, 'Da cap nhat yeu cau quy doi diem Sale.';
end;
$$;

alter table public.sale_point_conversions enable row level security;

drop policy if exists sale_point_conversions_select_own
  on public.sale_point_conversions;
create policy sale_point_conversions_select_own
  on public.sale_point_conversions for select to authenticated
  using (
    sale_user_id = (select auth.uid())
    or public.admin_has_permission('sales.write')
  );

grant select on public.sale_point_conversions to authenticated;
revoke insert, update, delete on public.sale_point_conversions
from anon, authenticated;

revoke all on function public.attach_my_referral_code(text) from public, anon;
revoke all on function public.get_my_sale_direct_customers() from public, anon;
revoke all on function public.get_my_sale_point_ledger() from public, anon;
revoke all on function public.get_my_sale_conversions() from public, anon;
revoke all on function public.request_sale_point_conversion(integer, text)
from public, anon;
revoke all on function public.admin_list_sale_point_conversions(text, integer)
from public, anon;
revoke all on function public.admin_review_sale_point_conversion(uuid, text, text, text)
from public, anon;

grant execute on function public.attach_my_referral_code(text) to authenticated;
grant execute on function public.get_my_sale_direct_customers() to authenticated;
grant execute on function public.get_my_sale_point_ledger() to authenticated;
grant execute on function public.get_my_sale_conversions() to authenticated;
grant execute on function public.request_sale_point_conversion(integer, text)
to authenticated;
grant execute on function public.admin_list_sale_point_conversions(text, integer)
to authenticated;
grant execute on function public.admin_review_sale_point_conversion(uuid, text, text, text)
to authenticated;

-- ---------------------------------------------------------------------------
-- 12B. Final Sale RPC grants after Sale module overrides
-- ---------------------------------------------------------------------------

revoke all on function public.require_active_sale_user() from public, anon, authenticated;
revoke all on function public.get_my_sale_state() from public, anon;
revoke all on function public.request_sale_participation(text) from public, anon;
revoke all on function public.attach_my_referral_code(text) from public, anon;
revoke all on function public.get_my_sale_dashboard() from public, anon;
revoke all on function public.get_my_sale_direct_customers() from public, anon;
revoke all on function public.get_my_sale_point_ledger() from public, anon;
revoke all on function public.get_my_sale_conversions() from public, anon;
revoke all on function public.request_sale_point_conversion(integer, text) from public, anon;
revoke all on function public.admin_list_sale_point_conversions(text, integer) from public, anon;
revoke all on function public.admin_review_sale_point_conversion(uuid, text, text, text) from public, anon;

grant execute on function public.get_my_sale_state() to authenticated;
grant execute on function public.request_sale_participation(text) to authenticated;
grant execute on function public.attach_my_referral_code(text) to authenticated;
grant execute on function public.get_my_sale_dashboard() to authenticated;
grant execute on function public.get_my_sale_direct_customers() to authenticated;
grant execute on function public.get_my_sale_point_ledger() to authenticated;
grant execute on function public.get_my_sale_conversions() to authenticated;
grant execute on function public.request_sale_point_conversion(integer, text) to authenticated;
grant execute on function public.admin_list_sale_point_conversions(text, integer) to authenticated;
grant execute on function public.admin_review_sale_point_conversion(uuid, text, text, text) to authenticated;

-- ---------------------------------------------------------------------------

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
  ('free', 'ai_chat_message', 'day', 3, 'Asia/Saigon', true),
  ('free', 'personal_schedule_generation', 'month', 3, 'Asia/Saigon', true),
  ('plus', 'ai_chat_message', 'none', null, 'Asia/Saigon', true),
  ('plus', 'personal_schedule_generation', 'none', null, 'Asia/Saigon', true),
  ('family_plus', 'ai_chat_message', 'none', null, 'Asia/Saigon', true),
  ('family_plus', 'personal_schedule_generation', 'none', null, 'Asia/Saigon', true)
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
  raw_app_meta_data = excluded.raw_app_meta_data,
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at = now(),
  is_anonymous = false;

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

