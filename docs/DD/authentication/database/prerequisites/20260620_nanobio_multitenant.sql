-- NanoBio / BioAI: PostgreSQL schema for Supabase (multi-user)
-- Run this file once in Supabase Dashboard -> SQL Editor.
--
-- Design:
--   auth.users         = authentication identity managed by Supabase Auth.
--   public.users       = public profile, one row per auth user.
--   user_id columns    = ownership boundary on every personal-health table.
--   catalog tables     = shared, read-only from Flutter clients.
--   RLS                = each authenticated user can only access their own rows.

begin;

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- 1. Public profile. Keep the existing local table name: users.
-- -----------------------------------------------------------------------------
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  phone text unique,
  full_name text,
  avatar_url text,
  gender text,
  birth_year integer,
  subscription_tier text not null default 'free',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 2. Shared catalogs. These records are not owned by an individual user.
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 3. Personal tables. user_id is mandatory and is always a Supabase Auth UUID.
-- -----------------------------------------------------------------------------
create table if not exists public.lifestyle_schedule_items (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
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

create table if not exists public.meal_plans (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
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
  unique (user_id, plan_date, meal_order)
);

create table if not exists public.medical_treatments (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  treatment_name text,
  medication_name text,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  title text,
  body text,
  type text,
  is_read boolean not null default false,
  source_type text,
  source_id text,
  scheduled_at timestamptz,
  notification_id integer,
  action_status text not null default 'pending',
  responded_at timestamptz,
  payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.nutrition_logs (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  food_name text,
  calories integer,
  protein double precision,
  carbs double precision,
  fat double precision,
  meal_type text,
  eaten_at timestamptz not null default now()
);

create table if not exists public.survey_answers (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  question_code text not null,
  answer_value text,
  created_at timestamptz not null default now(),
  unique (user_id, question_code)
);

create table if not exists public.ai_insights (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  insight_type text,
  title text,
  content text,
  risk_level text,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_recommendations (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  recommendation_type text,
  title text,
  description text,
  action_text text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_health_tasks (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
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
  unique (user_id, task_date, task_code)
);

create table if not exists public.food_allergies (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  allergy_name text not null,
  note text,
  created_at timestamptz not null default now(),
  unique (user_id, allergy_name)
);

create table if not exists public.health_conditions (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  condition_code text not null,
  condition_name text,
  severity_level integer,
  created_at timestamptz not null default now(),
  unique (user_id, condition_code)
);

create table if not exists public.health_goals (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  goal_code text not null,
  goal_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (user_id, goal_code)
);

create table if not exists public.health_profiles (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
  occupation text,
  height_cm double precision,
  weight_kg double precision,
  bmi double precision,
  blood_pressure text,
  blood_sugar text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create table if not exists public.health_tracking_logs (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
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
  unique (user_id, log_date)
);

create table if not exists public.lifestyle_habits (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references public.users(id) on delete cascade,
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
  unique (user_id)
);

-- -----------------------------------------------------------------------------
-- 4. Query indexes for the actual app screens.
-- -----------------------------------------------------------------------------
create index if not exists idx_meal_catalog_type_active
  on public.meal_catalog (meal_type, is_active);
create index if not exists idx_exercise_catalog_category_active
  on public.exercise_catalog (category, is_active);
create index if not exists idx_schedule_task_catalog_category_active
  on public.schedule_task_catalog (category, is_active);

create index if not exists idx_lifestyle_schedule_user_date_order
  on public.lifestyle_schedule_items (user_id, schedule_date, sort_order);
create index if not exists idx_lifestyle_schedule_source
  on public.lifestyle_schedule_items (source_type, source_id);
create index if not exists idx_meal_plans_user_date_order
  on public.meal_plans (user_id, plan_date, meal_order);
create index if not exists idx_medical_treatments_user_created
  on public.medical_treatments (user_id, created_at desc);
create index if not exists idx_notifications_user_scheduled
  on public.notifications (user_id, scheduled_at desc);
create index if not exists idx_notifications_user_unread
  on public.notifications (user_id, is_read, created_at desc);
create index if not exists idx_nutrition_logs_user_eaten
  on public.nutrition_logs (user_id, eaten_at desc);
create index if not exists idx_survey_answers_user_question
  on public.survey_answers (user_id, question_code);
create index if not exists idx_ai_insights_user_created
  on public.ai_insights (user_id, created_at desc);
create index if not exists idx_ai_recommendations_user_unread
  on public.ai_recommendations (user_id, is_read, created_at desc);
create index if not exists idx_daily_tasks_user_date_order
  on public.daily_health_tasks (user_id, task_date, sort_order);
create index if not exists idx_food_allergies_user
  on public.food_allergies (user_id);
create index if not exists idx_health_conditions_user
  on public.health_conditions (user_id);
create index if not exists idx_health_goals_user_active
  on public.health_goals (user_id, is_active);
create index if not exists idx_health_tracking_user_date
  on public.health_tracking_logs (user_id, log_date desc);

-- -----------------------------------------------------------------------------
-- 5. Keep updated_at correct without trusting the Flutter client clock.
-- -----------------------------------------------------------------------------
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

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users',
    'meal_catalog',
    'exercise_catalog',
    'schedule_task_catalog',
    'lifestyle_schedule_items',
    'meal_plans',
    'notifications',
    'daily_health_tasks',
    'health_profiles',
    'health_tracking_logs',
    'lifestyle_habits'
  ]
  loop
    execute format(
      'drop trigger if exists %I on public.%I',
      'trg_' || table_name || '_updated_at',
      table_name
    );
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
      'trg_' || table_name || '_updated_at',
      table_name
    );
  end loop;
end;
$$;

-- -----------------------------------------------------------------------------
-- 6. Create and keep public.users synchronized with Supabase Auth.
-- -----------------------------------------------------------------------------
create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (
    id,
    email,
    phone,
    full_name,
    avatar_url
  )
  values (
    new.id,
    new.email,
    new.phone,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update
  set
    email = excluded.email,
    phone = excluded.phone,
    full_name = coalesce(public.users.full_name, excluded.full_name),
    avatar_url = coalesce(public.users.avatar_url, excluded.avatar_url);

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
    phone = new.phone,
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

-- Create a public profile for Auth users who already existed before this migration.
insert into public.users (id, email, phone, full_name, avatar_url)
select
  id,
  email,
  phone,
  coalesce(raw_user_meta_data ->> 'full_name', raw_user_meta_data ->> 'name'),
  raw_user_meta_data ->> 'avatar_url'
from auth.users
on conflict (id) do update
set
  email = excluded.email,
  phone = excluded.phone,
  full_name = coalesce(public.users.full_name, excluded.full_name),
  avatar_url = coalesce(public.users.avatar_url, excluded.avatar_url);

-- -----------------------------------------------------------------------------
-- 7. Row Level Security. A signed-in user can only access their own health data.
-- -----------------------------------------------------------------------------
alter table public.users enable row level security;

drop policy if exists users_select_own on public.users;
drop policy if exists users_insert_own on public.users;
drop policy if exists users_update_own on public.users;

create policy users_select_own
  on public.users for select to authenticated
  using ((select auth.uid()) = id);

create policy users_insert_own
  on public.users for insert to authenticated
  with check ((select auth.uid()) = id);

create policy users_update_own
  on public.users for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Do not create a DELETE policy for public.users.
-- Account deletion should be handled server-side through Supabase Auth,
-- then ON DELETE CASCADE removes the profile and all owned data.

-- All personal health tables receive the same four owner-only policies.
do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'lifestyle_schedule_items',
    'meal_plans',
    'medical_treatments',
    'notifications',
    'nutrition_logs',
    'survey_answers',
    'ai_insights',
    'ai_recommendations',
    'daily_health_tasks',
    'food_allergies',
    'health_conditions',
    'health_goals',
    'health_profiles',
    'health_tracking_logs',
    'lifestyle_habits'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);

    execute format('drop policy if exists %I on public.%I', table_name || '_select_own', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_insert_own', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_update_own', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_delete_own', table_name);

    execute format(
      'create policy %I on public.%I for select to authenticated using ((select auth.uid()) = user_id)',
      table_name || '_select_own',
      table_name
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated with check ((select auth.uid()) = user_id)',
      table_name || '_insert_own',
      table_name
    );
    execute format(
      'create policy %I on public.%I for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)',
      table_name || '_update_own',
      table_name
    );
    execute format(
      'create policy %I on public.%I for delete to authenticated using ((select auth.uid()) = user_id)',
      table_name || '_delete_own',
      table_name
    );
  end loop;
end;
$$;

-- Catalogs can be read by authenticated users but are writable only by SQL migrations,
-- Dashboard, Edge Functions, or other trusted server-side processes.
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

-- Explicit client permissions. RLS remains the security boundary.
grant select, insert, update on public.users to authenticated;
revoke delete on public.users from anon, authenticated;

grant select on public.meal_catalog, public.exercise_catalog, public.schedule_task_catalog to authenticated;
revoke insert, update, delete on public.meal_catalog, public.exercise_catalog, public.schedule_task_catalog from anon, authenticated;

grant select, insert, update, delete
  on public.lifestyle_schedule_items,
     public.meal_plans,
     public.medical_treatments,
     public.notifications,
     public.nutrition_logs,
     public.survey_answers,
     public.ai_insights,
     public.ai_recommendations,
     public.daily_health_tasks,
     public.food_allergies,
     public.health_conditions,
     public.health_goals,
     public.health_profiles,
     public.health_tracking_logs,
     public.lifestyle_habits
  to authenticated;

commit;
