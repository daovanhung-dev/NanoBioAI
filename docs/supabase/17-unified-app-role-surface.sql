-- NanoBio / BioAI - Unified user/Admin app surface migration.
-- Non-destructive migration for an existing Supabase project.
-- Run after 11-admin-access-dashboard.sql.

begin;

alter table public.users
  add column if not exists app_access_mode text not null default 'user';

update public.users
set app_access_mode = 'user'
where app_access_mode is null
   or app_access_mode not in ('user', 'admin', 'both');

alter table public.users
  alter column app_access_mode set default 'user',
  alter column app_access_mode set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.users'::regclass
      and conname = 'users_app_access_mode_check'
  ) then
    alter table public.users
      add constraint users_app_access_mode_check
      check (app_access_mode in ('user', 'admin', 'both'));
  end if;
end;
$$;

-- The previous schema did not distinguish Admin-only from dual-role accounts.
-- Preserve user access for existing active Admin assignments during migration.
update public.users u
set
  app_access_mode = 'both',
  updated_at = now()
where u.app_access_mode = 'user'
  and exists (
    select 1
    from public.admin_user_roles aur
    where aur.user_id = u.id
      and aur.is_active = true
      and aur.revoked_at is null
  );

revoke update (app_access_mode) on public.users from anon, authenticated;

drop function if exists public.get_my_admin_session();

create or replace function public.get_my_admin_session()
returns table (
  user_id uuid,
  roles text[],
  permissions text[],
  is_active boolean,
  app_access_mode text,
  can_use_user_app boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    u.id as user_id,
    coalesce(
      array_agg(distinct aur.role_code)
        filter (where aur.role_code is not null),
      array[]::text[]
    ) as roles,
    coalesce(
      array_agg(distinct arp.permission_code)
        filter (where arp.permission_code is not null),
      array[]::text[]
    ) as permissions,
    exists (
      select 1
      from public.admin_user_roles active_aur
      where active_aur.user_id = u.id
        and active_aur.is_active = true
        and active_aur.revoked_at is null
    ) as is_active,
    u.app_access_mode,
    u.app_access_mode in ('user', 'both') as can_use_user_app
  from public.users u
  left join public.admin_user_roles aur
    on aur.user_id = u.id
   and aur.is_active = true
   and aur.revoked_at is null
  left join public.admin_role_permissions arp
    on arp.role_code = aur.role_code
  where u.id = auth.uid()
  group by u.id, u.app_access_mode
$$;

revoke all on function public.get_my_admin_session() from public, anon;
grant execute on function public.get_my_admin_session() to authenticated;

commit;
