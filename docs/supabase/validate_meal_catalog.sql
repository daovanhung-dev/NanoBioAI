-- NanoBio meal catalog runtime invariants.
-- Run after docs/supabase/setup.sql + docs/supabase/seed_data.sql.
-- Canonical content source: docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md

do $$
declare
  v_recipe_count integer;
  v_topic_count integer;
  v_chapter_count integer;
begin
  select count(*) into v_recipe_count
  from public.meal_catalog
  where source_name = 'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md'
    and is_active = true;

  select count(distinct health_topic_code) into v_topic_count
  from public.meal_catalog
  where source_name = 'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md'
    and is_active = true;

  select count(distinct chapter_number) into v_chapter_count
  from public.meal_catalog
  where source_name = 'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md'
    and is_active = true;

  if v_recipe_count <> 163 then
    raise exception 'MEAL_CATALOG_RECIPE_COUNT_MISMATCH: expected 163, found %', v_recipe_count;
  end if;
  if v_topic_count <> 64 then
    raise exception 'MEAL_CATALOG_TOPIC_COUNT_MISMATCH: expected 64, found %', v_topic_count;
  end if;
  if v_chapter_count <> 11 then
    raise exception 'MEAL_CATALOG_CHAPTER_COUNT_MISMATCH: expected 11, found %', v_chapter_count;
  end if;

  if exists (
    select 1 from public.meal_catalog
    where source_name = 'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md'
      and (
        health_topic_code is null
        or health_topic_name is null
        or health_topic_description is null
        or chapter_number is null
        or chapter_name is null
        or ingredients_json is null
        or jsonb_array_length(ingredients_json) = 0
        or cooking_steps_json is null
        or jsonb_array_length(cooking_steps_json) = 0
        or benefits is null
        or btrim(benefits) = ''
        or source_page is null
        or source_chapter is null
        or source_topic is null
        or source_recipe_order is null
        or source_hash is null
      )
  ) then
    raise exception 'MEAL_CATALOG_SOURCE_FIELDS_INCOMPLETE';
  end if;

  if exists (
    select 1 from public.meal_catalog
    where source_name = 'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md'
      and (
        nutrition_status <> 'missing_source_data'
        or constraint_metadata_status <> 'awaiting_professional_review'
        or metadata_status <> 'source_imported'
        or is_plan_eligible <> false
        or meal_type <> 'unclassified'
      )
  ) then
    raise exception 'MEAL_CATALOG_UNAPPROVED_METADATA_STATE';
  end if;

  if exists (
    select source_hash
    from public.meal_catalog
    where source_name = 'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md'
    group by source_hash
    having count(*) > 1
  ) then
    raise exception 'MEAL_CATALOG_DUPLICATE_SOURCE_HASH';
  end if;

  raise notice 'PASS meal_catalog: % recipes / % topics / % chapters',
    v_recipe_count, v_topic_count, v_chapter_count;
end
$$;
