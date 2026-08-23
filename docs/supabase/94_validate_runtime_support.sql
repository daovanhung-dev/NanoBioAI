-- Rollback-only runtime infrastructure smoke. Run after 01 through 06.

begin;

do $$
declare
  v_missing_functions text[];
  v_missing_triggers text[];
  v_missing_buckets text[];
begin
  select array_agg(v.name order by v.name)
  into v_missing_functions
  from unnest(array[
    'check_usage_quota',
    'commit_usage_quota',
    'sync_my_mobile_snapshot',
    'create_membership_payment_request',
    'get_my_familyplus_context',
    'get_my_sale_dashboard',
    'get_my_admin_session',
    'finalize_my_schedule_completion',
    'finalize_my_schedule_health_checkin',
    'get_my_wellness_reward_summary'
  ]) as v(name)
  where not exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = v.name
  );

  if v_missing_functions is not null then
    raise exception 'RUNTIME_RPC_MISSING_%', array_to_string(v_missing_functions, ',');
  end if;

  if to_regclass('public.effective_user_access') is null then
    raise exception 'RUNTIME_VIEW_MISSING_effective_user_access';
  end if;

  select array_agg(v.name order by v.name)
  into v_missing_triggers
  from unnest(array[
    'on_auth_user_created',
    'trg_membership_subscriptions_sync_user',
    'trg_payment_events_create_commission',
    'trg_schedule_completion_attempts_updated_at',
    'trg_wellness_point_ledgers_append_only'
  ]) as v(name)
  where not exists (
    select 1
    from pg_trigger t
    where t.tgname = v.name
      and not t.tgisinternal
  );

  if v_missing_triggers is not null then
    raise exception 'RUNTIME_TRIGGER_MISSING_%', array_to_string(v_missing_triggers, ',');
  end if;

  select array_agg(v.name order by v.name)
  into v_missing_buckets
  from unnest(array['schedule-completion-proofs', 'sale-payout-proofs']) as v(name)
  where not exists (
    select 1
    from storage.buckets b
    where b.id = v.name
      and b.public = false
      and b.file_size_limit = 5242880
      and b.allowed_mime_types = array['image/jpeg']::text[]
  );

  if v_missing_buckets is not null then
    raise exception 'RUNTIME_STORAGE_BUCKET_INVALID_%', array_to_string(v_missing_buckets, ',');
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.check_usage_quota(uuid,text,text,text,timestamp with time zone)'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'RUNTIME_RPC_GRANT_MISSING_check_usage_quota';
  end if;

  raise notice 'PASS runtime support: RPC, view, trigger, Storage and grants available.';
end;
$$;

-- Print the complete live public-schema inventory for the SQL Editor result
-- pane. This is intentionally catalog-driven so it includes objects created
-- through dynamic SQL as well as literal CREATE statements.
select
  'function' as object_kind,
  count(*)::integer as object_count
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prokind = 'f'
union all
select
  'procedure' as object_kind,
  count(*)::integer as object_count
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prokind = 'p'
union all
select
  'table' as object_kind,
  count(*)::integer as object_count
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r', 'p')
union all
select
  'view' as object_kind,
  count(*)::integer as object_count
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'v'
union all
select
  'trigger' as object_kind,
  count(*)::integer as object_count
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public', 'auth')
  and not t.tgisinternal
union all
select
  'rls_policy' as object_kind,
  count(*)::integer as object_count
from pg_policies
where schemaname = 'public'
order by object_kind;

select id, public, file_size_limit, allowed_mime_types
from storage.buckets
where id in ('schedule-completion-proofs', 'sale-payout-proofs')
order by id;

rollback;
