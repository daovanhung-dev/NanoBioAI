-- =============================================================================
-- 03_ai_runtime_enablement.sql
-- OPTIONAL AI RUNTIME PREFLIGHT (READ ONLY)
--
-- Run this only after 01_build_system.sql and 02_seed_data.sql have completed
-- successfully on the same local or sandbox project. It validates the
-- PostgreSQL side of AI chat, personal schedule generation, AI feedback, and
-- membership quota controls without changing schema or data.
--
-- This file cannot deploy an Edge Function or configure a provider credential.
-- Use the deployment instructions in docs/supabase/README.md after this
-- preflight passes.
-- =============================================================================

begin read only;

do $$
declare
  v_missing_tables text[];
  v_missing_functions text[];
  v_missing_rls_tables text[];
  v_missing_policies text[];
  v_missing_entitlements text[];
  v_missing_quota_rules text[];
  v_signature text;
begin
  select array_agg(required_object.name order by required_object.name)
  into v_missing_tables
  from unnest(array[
    'ai_insights',
    'ai_recommendations',
    'ai_content_reports',
    'personal_schedule_ai_requests',
    'membership_plans',
    'plan_entitlements',
    'membership_subscriptions',
    'usage_quota_rules',
    'usage_quota_counters',
    'usage_events'
  ]) as required_object(name)
  where to_regclass('public.' || required_object.name) is null;

  if v_missing_tables is not null then
    raise exception 'AI_RUNTIME_TABLE_MISSING_%', array_to_string(v_missing_tables, ',');
  end if;

  select array_agg(required_function.name order by required_function.name)
  into v_missing_functions
  from (
    values
      ('current_plan_for_user', 'public.current_plan_for_user(uuid)'),
      ('check_usage_quota', 'public.check_usage_quota(uuid,text,text,text,timestamp with time zone)'),
      ('commit_usage_quota', 'public.commit_usage_quota(uuid,text,text,text,timestamp with time zone,integer)'),
      ('check_personal_schedule_generation_quota', 'public.check_personal_schedule_generation_quota(uuid,text,text,text,timestamp with time zone)'),
      ('commit_personal_schedule_generation_quota', 'public.commit_personal_schedule_generation_quota(uuid,text,text,text,timestamp with time zone)')
  ) as required_function(name, signature)
  where to_regprocedure(required_function.signature) is null;

  if v_missing_functions is not null then
    raise exception 'AI_RUNTIME_RPC_MISSING_%', array_to_string(v_missing_functions, ',');
  end if;

  select array_agg(required_object.name order by required_object.name)
  into v_missing_rls_tables
  from unnest(array[
    'ai_insights',
    'ai_recommendations',
    'ai_content_reports',
    'personal_schedule_ai_requests',
    'usage_quota_rules',
    'usage_quota_counters',
    'usage_events'
  ]) as required_object(name)
  where not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = required_object.name
      and c.relrowsecurity
  );

  if v_missing_rls_tables is not null then
    raise exception 'AI_RUNTIME_RLS_MISSING_%', array_to_string(v_missing_rls_tables, ',');
  end if;

  select array_agg(
    required_policy.table_name || ':' || required_policy.policy_name
    order by required_policy.table_name, required_policy.policy_name
  )
  into v_missing_policies
  from (
    values
      ('ai_insights', 'ai_insights_select_subject'),
      ('ai_insights', 'ai_insights_insert_subject'),
      ('ai_insights', 'ai_insights_update_subject'),
      ('ai_insights', 'ai_insights_delete_subject'),
      ('ai_recommendations', 'ai_recommendations_select_subject'),
      ('ai_recommendations', 'ai_recommendations_insert_subject'),
      ('ai_recommendations', 'ai_recommendations_update_subject'),
      ('ai_recommendations', 'ai_recommendations_delete_subject'),
      ('personal_schedule_ai_requests', 'personal_schedule_ai_requests_select_own'),
      ('usage_quota_rules', 'usage_quota_rules_read_authenticated'),
      ('usage_quota_counters', 'usage_quota_counters_select_own'),
      ('usage_events', 'usage_events_select_own')
  ) as required_policy(table_name, policy_name)
  where not exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = required_policy.table_name
      and p.policyname = required_policy.policy_name
  );

  if v_missing_policies is not null then
    raise exception 'AI_RUNTIME_RLS_POLICY_MISSING_%', array_to_string(v_missing_policies, ',');
  end if;

  if not has_table_privilege('authenticated', 'public.ai_insights', 'SELECT')
     or not has_table_privilege('authenticated', 'public.ai_insights', 'INSERT')
     or not has_table_privilege('authenticated', 'public.ai_insights', 'UPDATE')
     or not has_table_privilege('authenticated', 'public.ai_insights', 'DELETE')
     or not has_table_privilege('authenticated', 'public.ai_recommendations', 'SELECT')
     or not has_table_privilege('authenticated', 'public.ai_recommendations', 'INSERT')
     or not has_table_privilege('authenticated', 'public.ai_recommendations', 'UPDATE')
     or not has_table_privilege('authenticated', 'public.ai_recommendations', 'DELETE') then
    raise exception 'AI_RUNTIME_SUBJECT_GRANT_INVALID';
  end if;

  if has_table_privilege('anon', 'public.ai_content_reports', 'SELECT')
     or has_table_privilege('anon', 'public.ai_content_reports', 'INSERT')
     or has_table_privilege('anon', 'public.ai_content_reports', 'UPDATE')
     or has_table_privilege('anon', 'public.ai_content_reports', 'DELETE')
     or has_table_privilege('authenticated', 'public.ai_content_reports', 'SELECT')
     or has_table_privilege('authenticated', 'public.ai_content_reports', 'INSERT')
     or has_table_privilege('authenticated', 'public.ai_content_reports', 'UPDATE')
     or has_table_privilege('authenticated', 'public.ai_content_reports', 'DELETE') then
    raise exception 'AI_RUNTIME_REPORT_GRANT_INVALID';
  end if;

  if exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'ai_content_reports'
  ) then
    raise exception 'AI_RUNTIME_REPORT_POLICY_INVALID';
  end if;

  if to_regprocedure('public.anonymize_deleted_user_records()') is null then
    raise exception 'AI_RUNTIME_REPORT_ANONYMIZER_MISSING';
  end if;

  if not exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'users'
      and t.tgname = 'trg_users_anonymize_deleted_records'
      and t.tgfoid = to_regprocedure('public.anonymize_deleted_user_records()')
      and not t.tgisinternal
  ) then
    raise exception 'AI_RUNTIME_REPORT_ANONYMIZER_TRIGGER_MISSING';
  end if;

  if not has_table_privilege('service_role', 'public.ai_content_reports', 'INSERT')
     or not has_table_privilege('service_role', 'public.ai_content_reports', 'SELECT') then
    raise exception 'AI_RUNTIME_REPORT_SERVICE_ROLE_GRANT_INVALID';
  end if;

  if not has_table_privilege('authenticated', 'public.personal_schedule_ai_requests', 'SELECT')
     or has_table_privilege('authenticated', 'public.personal_schedule_ai_requests', 'INSERT')
     or has_table_privilege('authenticated', 'public.personal_schedule_ai_requests', 'UPDATE')
     or has_table_privilege('authenticated', 'public.personal_schedule_ai_requests', 'DELETE') then
    raise exception 'AI_RUNTIME_SCHEDULE_GRANT_INVALID';
  end if;

  if not has_table_privilege('authenticated', 'public.usage_quota_rules', 'SELECT')
     or has_table_privilege('authenticated', 'public.usage_quota_rules', 'INSERT')
     or has_table_privilege('authenticated', 'public.usage_quota_rules', 'UPDATE')
     or has_table_privilege('authenticated', 'public.usage_quota_rules', 'DELETE')
     or not has_table_privilege('authenticated', 'public.usage_quota_counters', 'SELECT')
     or has_table_privilege('authenticated', 'public.usage_quota_counters', 'INSERT')
     or has_table_privilege('authenticated', 'public.usage_quota_counters', 'UPDATE')
     or has_table_privilege('authenticated', 'public.usage_quota_counters', 'DELETE')
     or not has_table_privilege('authenticated', 'public.usage_events', 'SELECT')
     or has_table_privilege('authenticated', 'public.usage_events', 'INSERT')
     or has_table_privilege('authenticated', 'public.usage_events', 'UPDATE')
     or has_table_privilege('authenticated', 'public.usage_events', 'DELETE') then
    raise exception 'AI_RUNTIME_QUOTA_TABLE_GRANT_INVALID';
  end if;

  foreach v_signature in array array[
    'public.check_usage_quota(uuid,text,text,text,timestamp with time zone)',
    'public.commit_usage_quota(uuid,text,text,text,timestamp with time zone,integer)',
    'public.check_personal_schedule_generation_quota(uuid,text,text,text,timestamp with time zone)',
    'public.commit_personal_schedule_generation_quota(uuid,text,text,text,timestamp with time zone)'
  ]
  loop
    if not has_function_privilege('authenticated', v_signature::regprocedure, 'EXECUTE') then
      raise exception 'AI_RUNTIME_RPC_GRANT_MISSING_%', v_signature;
    end if;

    if has_function_privilege('anon', v_signature::regprocedure, 'EXECUTE') then
      raise exception 'AI_RUNTIME_ANON_RPC_GRANT_INVALID_%', v_signature;
    end if;
  end loop;

  select array_agg(
    expected.plan_code || ':' || expected.entitlement_key
    order by expected.plan_code, expected.entitlement_key
  )
  into v_missing_entitlements
  from (
    values
      ('free', 'ai_chat', '{"enabled": true, "quota_key": "ai_chat_message"}'::jsonb),
      ('free', 'personal_schedule_generation', '{"enabled": true, "quota_key": "personal_schedule_generation"}'::jsonb),
      ('plus', 'ai_chat', '{"enabled": true, "unlimited": true}'::jsonb),
      ('plus', 'personal_schedule_generation', '{"enabled": true, "unlimited": true}'::jsonb),
      ('family_plus', 'ai_chat', '{"enabled": true, "unlimited": true}'::jsonb),
      ('family_plus', 'personal_schedule_generation', '{"enabled": true, "unlimited": true}'::jsonb)
  ) as expected(plan_code, entitlement_key, required_value)
  where not exists (
    select 1
    from public.plan_entitlements entitlement
    where entitlement.plan_code::text = expected.plan_code
      and entitlement.entitlement_key = expected.entitlement_key
      and entitlement.is_active
      and entitlement.entitlement_value @> expected.required_value
  );

  if v_missing_entitlements is not null then
    raise exception 'AI_RUNTIME_ENTITLEMENT_MISSING_%', array_to_string(v_missing_entitlements, ',');
  end if;

  select array_agg(
    expected.plan_code || ':' || expected.feature_key
    order by expected.plan_code, expected.feature_key
  )
  into v_missing_quota_rules
  from (
    values
      ('free', 'ai_chat_message', 'day', 3::integer),
      ('free', 'personal_schedule_generation', 'month', 3::integer),
      ('plus', 'ai_chat_message', 'none', null::integer),
      ('plus', 'personal_schedule_generation', 'none', null::integer),
      ('family_plus', 'ai_chat_message', 'none', null::integer),
      ('family_plus', 'personal_schedule_generation', 'none', null::integer)
  ) as expected(plan_code, feature_key, period_unit, max_count)
  where not exists (
    select 1
    from public.usage_quota_rules quota_rule
    where quota_rule.plan_code::text = expected.plan_code
      and quota_rule.feature_key = expected.feature_key
      and quota_rule.period_unit = expected.period_unit
      and quota_rule.max_count is not distinct from expected.max_count
      and quota_rule.is_active
  );

  if v_missing_quota_rules is not null then
    raise exception 'AI_RUNTIME_QUOTA_RULE_MISSING_%', array_to_string(v_missing_quota_rules, ',');
  end if;

  raise notice 'PASS AI runtime database preflight';
end
$$;

rollback;
