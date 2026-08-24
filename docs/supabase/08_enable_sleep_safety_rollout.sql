-- =============================================================================
-- 08_enable_sleep_safety_rollout.sql
-- NanoBio M31 - Enable Sleep Safety for trusted Plus / FamilyPlus accounts.
--
-- Run AFTER 07_schema_sleep_safety.sql. This is a runtime kill-switch decision,
-- not a membership grant. Flutter/Edge Functions must still enforce trusted paid
-- access from effective_user_access.
-- =============================================================================

begin;

do $$
begin
  if to_regclass('public.sleep_safety_runtime_config') is null then
    raise exception 'SLEEP_SAFETY_RUNTIME_CONFIG_MISSING';
  end if;

  update public.sleep_safety_runtime_config
  set enabled = true,
      updated_at = now()
  where config_key = 'default';

  if not found then
    raise exception 'SLEEP_SAFETY_DEFAULT_CONFIG_MISSING';
  end if;
end
$$;

commit;

-- Emergency rollback / kill switch (run explicitly when required):
-- update public.sleep_safety_runtime_config
-- set enabled = false, updated_at = now()
-- where config_key = 'default';
