-- Run after the canonical rebuild or the additive Early Access migration.
-- The rate-limit checks run in a transaction and are rolled back below.
begin;

set local role service_role;

do $$
declare
  v_ip_hash text := encode(public.gen_random_bytes(32), 'hex');
  v_window timestamptz := to_timestamp(floor(extract(epoch from now()) / 3600) * 3600);
  v_attempt integer;
begin
  for v_attempt in 1..10 loop
    if not public.consume_early_access_rate_limit(v_ip_hash, v_window) then
      raise exception 'EARLY_ACCESS_RATE_LIMIT_BLOCKED_BEFORE_ATTEMPT_10';
    end if;
  end loop;
  if public.consume_early_access_rate_limit(v_ip_hash, v_window) then
    raise exception 'EARLY_ACCESS_RATE_LIMIT_ALLOWED_ATTEMPT_11';
  end if;
end
$$;

reset role;

do $$
begin
  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'early_access_leads' and c.relrowsecurity
  ) or not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'early_access_private' and c.relname = 'rate_limits' and c.relrowsecurity
  ) then
    raise exception 'EARLY_ACCESS_RLS_MISSING';
  end if;

  if has_table_privilege('anon', 'public.early_access_leads', 'SELECT')
     or has_table_privilege('anon', 'public.early_access_leads', 'INSERT')
     or has_table_privilege('anon', 'public.early_access_leads', 'UPDATE')
     or has_table_privilege('anon', 'public.early_access_leads', 'DELETE')
     or has_table_privilege('authenticated', 'public.early_access_leads', 'SELECT')
     or has_table_privilege('authenticated', 'public.early_access_leads', 'INSERT')
     or has_table_privilege('authenticated', 'public.early_access_leads', 'UPDATE')
     or has_table_privilege('authenticated', 'public.early_access_leads', 'DELETE')
     or has_schema_privilege('anon', 'early_access_private', 'USAGE')
     or has_schema_privilege('authenticated', 'early_access_private', 'USAGE') then
    raise exception 'EARLY_ACCESS_CLIENT_GRANT_INVALID';
  end if;

  if not has_function_privilege('service_role', 'public.consume_early_access_rate_limit(text,timestamp with time zone)'::regprocedure, 'EXECUTE')
     or has_function_privilege('anon', 'public.consume_early_access_rate_limit(text,timestamp with time zone)'::regprocedure, 'EXECUTE')
     or has_function_privilege('authenticated', 'public.consume_early_access_rate_limit(text,timestamp with time zone)'::regprocedure, 'EXECUTE') then
    raise exception 'EARLY_ACCESS_RATE_LIMIT_RPC_GRANT_INVALID';
  end if;

  if not exists (
    select 1 from storage.buckets where id = 'early-access-apk' and public = false
  ) then
    raise exception 'EARLY_ACCESS_APK_BUCKET_NOT_PRIVATE';
  end if;
end
$$;

rollback;
