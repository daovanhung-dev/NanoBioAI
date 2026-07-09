-- NanoBio / BioAI
-- Hotfix 14.1: Mobile snapshot RPC preserves cloud defaults and uses valid PL/pgSQL control flow.
--
-- Apply this revision in Supabase SQL Editor BEFORE retesting the Flutter app.
-- It is safe to run repeatedly. Do not run docs/supabase/config.sql on production.
--
-- Root cause fixed:
--   jsonb_populate_record(null::public.some_table, payload) produces a complete
--   record. Any omitted JSON key becomes SQL NULL, so INSERT ... SELECT record.*
--   explicitly inserts NULL into columns such as created_at and bypasses
--   DEFAULT now(), causing PostgreSQL 23502.

begin;

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
  v_payload jsonb;
  v_allowed_columns text[];
  v_payload_columns text[];
  v_insert_columns text[];
  v_column_names text;
  v_select_names text;
  v_column_definitions text;
  v_matched_column_count integer;
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

  if jsonb_typeof(p_snapshot) <> 'object'
     or jsonb_typeof(v_tables) <> 'object' then
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

  -- Only fields that are user-controlled may be updated here. Membership,
  -- entitlement, payment, Sale and role state remain server-owned.
  update public.users
  set
    phone = coalesce(nullif(v_user ->> 'phone', ''), phone),
    full_name = coalesce(nullif(v_user ->> 'full_name', ''), full_name),
    avatar_url = coalesce(nullif(v_user ->> 'avatar_url', ''), avatar_url),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    onboarding_status = case
      when v_user ->> 'onboarding_status' = 'completed'
        then 'completed'::public.nb_onboarding_status
      when v_user ->> 'onboarding_status' = 'in_progress'
        then 'in_progress'::public.nb_onboarding_status
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

  -- This block turns one client row into a validated, typed INSERT. It never
  -- inserts omitted columns, so Postgres defaults remain active. Timestamps
  -- are deliberately server-generated instead of accepted from the client.
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
      select value from jsonb_array_elements(coalesce(v_tables -> v_table, '[]'::jsonb))
    loop
      if jsonb_typeof(v_row) <> 'object' then
        raise exception 'INVALID_SNAPSHOT_ROW for table %', v_table
          using errcode = '22023';
      end if;

      select coalesce(array_agg(c.column_name order by c.ordinality), array[]::text[])
      into v_payload_columns
      from unnest(v_allowed_columns) with ordinality as c(column_name, ordinality)
      where v_row ? c.column_name
        and (v_row -> c.column_name) <> 'null'::jsonb;

      select coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
      into v_payload
      from jsonb_each(v_row) as e(key, value)
      where e.key = any(v_allowed_columns)
        and e.value <> 'null'::jsonb;

      v_payload := v_payload || jsonb_build_object(
        'user_id', v_user_id,
        'subject_id', v_subject_id
      );
      v_insert_columns := array['user_id', 'subject_id']::text[] || v_payload_columns;

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
        on cls.relname = v_table
      join pg_catalog.pg_namespace ns
        on ns.oid = cls.relnamespace and ns.nspname = 'public'
      join pg_catalog.pg_attribute a
        on a.attrelid = cls.oid
       and a.attname = c.column_name
       and a.attnum > 0
       and not a.attisdropped;

      if v_matched_column_count <> cardinality(v_insert_columns) then
        raise exception 'SNAPSHOT_SCHEMA_MISMATCH for table %', v_table
          using errcode = '22023';
      end if;

      execute format(
        'insert into public.%I (%s) select %s from jsonb_to_record($1) as x(%s)',
        v_table,
        v_column_names,
        v_select_names,
        v_column_definitions
      ) using v_payload;
      v_rows := v_rows + 1;
    end loop;
  end loop;

  foreach v_table in array v_collection_tables loop
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
      select value from jsonb_array_elements(coalesce(v_tables -> v_table, '[]'::jsonb))
    loop
      if jsonb_typeof(v_row) <> 'object' then
        raise exception 'INVALID_SNAPSHOT_ROW for table %', v_table
          using errcode = '22023';
      end if;

      select coalesce(array_agg(c.column_name order by c.ordinality), array[]::text[])
      into v_payload_columns
      from unnest(v_allowed_columns) with ordinality as c(column_name, ordinality)
      where v_row ? c.column_name
        and (v_row -> c.column_name) <> 'null'::jsonb;

      select coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
      into v_payload
      from jsonb_each(v_row) as e(key, value)
      where e.key = any(v_allowed_columns)
        and e.value <> 'null'::jsonb;

      v_payload := v_payload || jsonb_build_object(
        'user_id', v_user_id,
        'subject_id', v_subject_id
      );
      v_insert_columns := array['user_id', 'subject_id']::text[] || v_payload_columns;

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
        on cls.relname = v_table
      join pg_catalog.pg_namespace ns
        on ns.oid = cls.relnamespace and ns.nspname = 'public'
      join pg_catalog.pg_attribute a
        on a.attrelid = cls.oid
       and a.attname = c.column_name
       and a.attnum > 0
       and not a.attisdropped;

      if v_matched_column_count <> cardinality(v_insert_columns) then
        raise exception 'SNAPSHOT_SCHEMA_MISMATCH for table %', v_table
          using errcode = '22023';
      end if;

      execute format(
        'insert into public.%I (%s) select %s from jsonb_to_record($1) as x(%s)',
        v_table,
        v_column_names,
        v_select_names,
        v_column_definitions
      ) using v_payload;
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

commit;
