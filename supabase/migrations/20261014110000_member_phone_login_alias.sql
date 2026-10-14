begin;

-- Member-facing phone/password credentials use a stable internal email alias
-- because this project keeps Supabase Phone Auth disabled. The app never asks
-- members for this alias; it normalizes the phone and derives the same value.
create table if not exists private.member_phone_signup_rate_limits (
  key_hash text not null,
  bucket_start timestamptz not null,
  request_count integer not null default 0,
  primary key (key_hash, bucket_start)
);
revoke all on table private.member_phone_signup_rate_limits
from public, anon, authenticated, service_role;

create or replace function public.consume_member_phone_signup_rate_limit(
  p_ip_hash text
)
returns boolean
language plpgsql
security definer
set search_path = private, auth, pg_temp
as $$
declare
  v_count integer;
  v_bucket timestamptz := date_trunc('hour', now());
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service_role_required' using errcode = '42501';
  end if;
  if coalesce(p_ip_hash, '') !~ '^[0-9a-f]{64}$' then
    return false;
  end if;

  delete from private.member_phone_signup_rate_limits
  where bucket_start < now() - interval '30 days';
  insert into private.member_phone_signup_rate_limits(
    key_hash, bucket_start, request_count
  ) values (
    'signup:' || p_ip_hash, v_bucket, 1
  )
  on conflict (key_hash, bucket_start) do update
    set request_count = private.member_phone_signup_rate_limits.request_count + 1
  returning request_count into v_count;
  return v_count <= 10;
end;
$$;

revoke all on function public.consume_member_phone_signup_rate_limit(text)
from public, anon, authenticated;
grant execute on function public.consume_member_phone_signup_rate_limit(text)
to service_role;

do $$
begin
  if to_regclass('public.idx_users_phone_unique_not_null') is null then
    raise exception 'MEMBER_PHONE_UNIQUE_INDEX_MISSING';
  end if;
  if has_function_privilege(
    'anon',
    'public.consume_member_phone_signup_rate_limit(text)'::regprocedure,
    'EXECUTE'
  ) or has_function_privilege(
    'authenticated',
    'public.consume_member_phone_signup_rate_limit(text)'::regprocedure,
    'EXECUTE'
  ) or not has_function_privilege(
    'service_role',
    'public.consume_member_phone_signup_rate_limit(text)'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'MEMBER_PHONE_SIGNUP_RATE_LIMIT_GRANTS_INVALID';
  end if;
end
$$;

commit;
