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

begin;

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
-- B. Sale access guard used by final Sale RPCs
-- ---------------------------------------------------------------------------
-- Final Sale participation, payout, conversion, direct-customer and Admin
-- review RPCs live in 12-sale-module-update.sql and config.sql. This file only
-- keeps the shared active-Sale guard so older direct-active RPC behavior cannot
-- be reintroduced from the mobile sync migration.

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

revoke all on function public.require_active_sale_user()
from public, anon, authenticated;
commit;
