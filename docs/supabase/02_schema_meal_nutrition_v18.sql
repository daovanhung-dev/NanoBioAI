begin;

alter table if exists public.meal_catalog
  add column if not exists sugar_g numeric(10,2),
  add column if not exists saturated_fat_g numeric(10,2),
  add column if not exists sodium_mg numeric(12,2),
  add column if not exists cholesterol_mg numeric(12,2),
  add column if not exists potassium_mg numeric(12,2),
  add column if not exists calcium_mg numeric(12,2),
  add column if not exists iron_mg numeric(12,2);

alter table if exists public.meal_plans
  add column if not exists sugar_g numeric(10,2),
  add column if not exists saturated_fat_g numeric(10,2),
  add column if not exists sodium_mg numeric(12,2),
  add column if not exists cholesterol_mg numeric(12,2),
  add column if not exists potassium_mg numeric(12,2),
  add column if not exists calcium_mg numeric(12,2),
  add column if not exists iron_mg numeric(12,2);

alter table if exists public.meal_plans
  add column if not exists nutrition_status text;

alter table if exists public.meal_catalog
  drop constraint if exists meal_catalog_nutrition_nonnegative_v18;

alter table if exists public.meal_catalog
  add constraint meal_catalog_nutrition_nonnegative_v18 check (
    calories >= 0 and protein >= 0 and carbs >= 0 and fat >= 0 and fiber >= 0 and water_ml >= 0
    and (sugar_g is null or sugar_g >= 0)
    and (saturated_fat_g is null or saturated_fat_g >= 0)
    and (sodium_mg is null or sodium_mg >= 0)
    and (cholesterol_mg is null or cholesterol_mg >= 0)
    and (potassium_mg is null or potassium_mg >= 0)
    and (calcium_mg is null or calcium_mg >= 0)
    and (iron_mg is null or iron_mg >= 0)
  ) not valid;

alter table if exists public.meal_catalog
  validate constraint meal_catalog_nutrition_nonnegative_v18;


-- Keep the existing snapshot RPC compatible without redefining the entire
-- function: its helper receives the historical meal_plans whitelist. Extend
-- that whitelist server-side when the v18 columns exist.
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
  v_allowed_columns text[] := p_allowed_columns;
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

  if p_table_name = 'meal_plans' then
    v_allowed_columns := v_allowed_columns || array[
      'sugar_g', 'saturated_fat_g', 'sodium_mg', 'cholesterol_mg',
      'potassium_mg', 'calcium_mg', 'iron_mg', 'nutrition_status'
    ];
  end if;

  select coalesce(array_agg(c.column_name order by c.ordinality), array[]::text[])
  into v_payload_columns
  from unnest(v_allowed_columns) with ordinality as c(column_name, ordinality)
  where c.column_name not in ('user_id', 'subject_id')
    and p_row ? c.column_name
    and (p_row -> c.column_name) <> 'null'::jsonb;

  select coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
  into v_payload
  from jsonb_each(p_row) as e(key, value)
  where e.key = any(v_allowed_columns)
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

commit;
