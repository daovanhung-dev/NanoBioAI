-- Commit de xuat: docs(supabase): tao health schedule schema
-- NanoBio / BioAI - health, onboarding, schedule, AI and catalog draft.
-- Run after 01-core-auth-profile.sql.

begin;

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
create index if not exists idx_health_score_ledgers_subject_period
  on public.health_score_ledgers (subject_id, period_end desc, formula_version);
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
    'health_score_ledgers',
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
     public.health_score_ledgers,
     public.nutrition_logs,
     public.ai_insights,
     public.ai_recommendations
  to authenticated;

grant select on public.meal_catalog, public.exercise_catalog, public.schedule_task_catalog to authenticated;
revoke insert, update, delete on public.meal_catalog, public.exercise_catalog, public.schedule_task_catalog from anon, authenticated;

commit;
