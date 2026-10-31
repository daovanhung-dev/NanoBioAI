begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;

create unique index if not exists idx_users_phone_unique_not_null
  on public.users(phone) where phone is not null;

revoke update on public.users from anon, authenticated;
grant update (
  full_name,
  avatar_url,
  gender,
  birth_year,
  onboarding_status,
  onboarding_completed_at,
  last_login_at
) on public.users to authenticated;

-- Preserve the currently deployed snapshot behavior while stripping the
-- client-controlled phone field before any older SECURITY DEFINER body runs.
do $$
begin
  if to_regprocedure('public.sync_my_mobile_snapshot_before_member_phone_auth(jsonb)') is null then
    if to_regprocedure('public.sync_my_mobile_snapshot(jsonb)') is null then
      raise exception 'sync_my_mobile_snapshot(jsonb) must exist before applying member phone auth migration';
    end if;
    execute 'alter function public.sync_my_mobile_snapshot(jsonb) rename to sync_my_mobile_snapshot_before_member_phone_auth';
  end if;
end
$$;

revoke all on function public.sync_my_mobile_snapshot_before_member_phone_auth(jsonb)
from public, anon, authenticated;

create or replace function public.sync_my_mobile_snapshot(p_snapshot jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_safe_snapshot jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if coalesce(jsonb_typeof(p_snapshot), '') <> 'object'
     or (p_snapshot ? 'user' and coalesce(jsonb_typeof(p_snapshot -> 'user'), '') <> 'object') then
    raise exception using errcode = '22023', message = 'INVALID_SNAPSHOT';
  end if;

  v_safe_snapshot := jsonb_set(
    p_snapshot,
    '{user}',
    coalesce(p_snapshot -> 'user', '{}'::jsonb) - 'phone',
    true
  );
  return public.sync_my_mobile_snapshot_before_member_phone_auth(v_safe_snapshot);
end;
$$;

revoke all on function public.sync_my_mobile_snapshot(jsonb)
from public, anon;
grant execute on function public.sync_my_mobile_snapshot(jsonb)
to authenticated;

do $$
begin
  if has_column_privilege('anon', 'public.users', 'phone', 'UPDATE')
     or has_column_privilege('authenticated', 'public.users', 'phone', 'UPDATE') then
    raise exception 'MEMBER_PHONE_CLIENT_UPDATE_GRANT_INVALID';
  end if;
  if has_function_privilege(
       'anon',
       'public.sync_my_mobile_snapshot(jsonb)'::regprocedure,
       'EXECUTE'
     )
     or not has_function_privilege(
       'authenticated',
       'public.sync_my_mobile_snapshot(jsonb)'::regprocedure,
       'EXECUTE'
     )
     or has_function_privilege(
       'authenticated',
       'public.sync_my_mobile_snapshot_before_member_phone_auth(jsonb)'::regprocedure,
       'EXECUTE'
     ) then
    raise exception 'MEMBER_PHONE_SNAPSHOT_RPC_GRANT_INVALID';
  end if;
end
$$;

commit;
