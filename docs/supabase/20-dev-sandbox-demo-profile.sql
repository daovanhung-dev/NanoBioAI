-- Local/sandbox-only opt-in demo profile.
--
-- Apply after config.sql and 19-dev-sandbox-comprehensive-seed.sql. This
-- intentionally changes only active configuration versions; it does not
-- alter schema, RLS, seed data, or the default disabled rollout in config.sql.
-- Do not run on production.

begin;

do $$
begin
  if to_regclass('public.system_config_versions') is null then
    raise exception 'system_config_versions is required; rebuild the local/sandbox database first';
  end if;
end;
$$;

update public.system_config_versions
set status = 'archived'
where config_key in (
  'wellness_rewards_rollout',
  'sale_point_conversion',
  'nabi_companion_notifications_rollout'
)
and status = 'active';

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
values
  (
    'wellness_rewards_rollout',
    '{"enabled": true, "contract_version": "wellness_rewards_v1", "demo_profile": "dev_sandbox"}'::jsonb,
    'active',
    'Bật tạm Điểm chăm sóc cho fixture local/sandbox.',
    (select id from public.users where email = 'dev.admin@nanobio.local' limit 1)
  ),
  (
    'sale_point_conversion',
    '{"enabled": true, "point_to_money_rate": 1, "minimum_point_cents": 500000, "currency": "VND", "demo_profile": "dev_sandbox"}'::jsonb,
    'active',
    'Bật tạm quy đổi điểm Sale cho fixture local/sandbox.',
    (select id from public.users where email = 'dev.admin@nanobio.local' limit 1)
  ),
  (
    'nabi_companion_notifications_rollout',
    '{"enabled": true, "in_app_enabled": true, "os_local_enabled": false, "demo_profile": "dev_sandbox"}'::jsonb,
    'active',
    'Bật tạm Nabi in-app cho fixture local/sandbox.',
    (select id from public.users where email = 'dev.admin@nanobio.local' limit 1)
  );

commit;
