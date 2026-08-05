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
