-- Commit de xuat: docs(supabase): tao family plus schema
-- NanoBio / BioAI - FamilyPlus data boundary draft.
-- Run after 01-core-auth-profile.sql and 03-membership-quota.sql.

begin;

create table if not exists public.family_groups (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  plan_subscription_id uuid references public.membership_subscriptions(id) on delete set null,
  display_name text not null,
  status text not null default 'active'
    check (status in ('active', 'paused', 'closed')),
  last_idempotency_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_group_id uuid not null references public.family_groups(id) on delete cascade,
  subject_id uuid not null references public.health_subjects(id) on delete cascade,
  user_id uuid references public.users(id) on delete set null,
  invited_email text,
  display_name text not null,
  role text not null default 'member'
    check (role in ('owner', 'adult', 'member', 'child', 'viewer')),
  status text not null default 'active'
    check (status in ('invited', 'active', 'removed')),
  can_view boolean not null default true,
  can_edit boolean not null default false,
  last_idempotency_key text,
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_group_id, subject_id)
);

alter table public.family_groups
  add column if not exists last_idempotency_key text;

alter table public.family_members
  add column if not exists last_idempotency_key text;

create unique index if not exists idx_family_members_group_user_unique
  on public.family_members (family_group_id, user_id)
  where user_id is not null and status <> 'removed';

create unique index if not exists idx_family_groups_owner_active_unique
  on public.family_groups (owner_user_id)
  where status = 'active';

create index if not exists idx_family_groups_owner_status
  on public.family_groups (owner_user_id, status);

create index if not exists idx_family_members_subject
  on public.family_members (subject_id);

create index if not exists idx_family_members_user_status
  on public.family_members (user_id, status)
  where user_id is not null;

drop trigger if exists trg_family_groups_updated_at on public.family_groups;
create trigger trg_family_groups_updated_at
  before update on public.family_groups
  for each row execute function public.set_updated_at();

drop trigger if exists trg_family_members_updated_at on public.family_members;
create trigger trg_family_members_updated_at
  before update on public.family_members
  for each row execute function public.set_updated_at();

create or replace function public.can_read_health_subject(p_subject_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.health_subjects hs
    where hs.id = p_subject_id
      and hs.is_active = true
      and (
        hs.owner_user_id = (select auth.uid())
        or hs.linked_user_id = (select auth.uid())
        or exists (
          select 1
          from public.family_members target_member
          join public.family_groups fg
            on fg.id = target_member.family_group_id
          left join public.family_members actor_member
            on actor_member.family_group_id = target_member.family_group_id
           and actor_member.user_id = (select auth.uid())
           and actor_member.status = 'active'
          where target_member.subject_id = hs.id
            and target_member.status = 'active'
            and fg.status = 'active'
            and (
              fg.owner_user_id = (select auth.uid())
              or actor_member.can_view = true
            )
        )
      )
  )
$$;

create or replace function public.can_write_health_subject(p_subject_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.health_subjects hs
    where hs.id = p_subject_id
      and hs.is_active = true
      and (
        hs.owner_user_id = (select auth.uid())
        or exists (
          select 1
          from public.family_members target_member
          join public.family_groups fg
            on fg.id = target_member.family_group_id
          join public.family_members actor_member
            on actor_member.family_group_id = target_member.family_group_id
           and actor_member.user_id = (select auth.uid())
           and actor_member.status = 'active'
          where target_member.subject_id = hs.id
            and target_member.status = 'active'
            and fg.status = 'active'
            and (
              fg.owner_user_id = (select auth.uid())
              or actor_member.can_edit = true
            )
        )
      )
  )
$$;

create or replace function public.assert_current_user_familyplus()
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.membership_subscriptions ms
    where ms.user_id = v_user_id
      and ms.plan_code = 'family_plus'
      and ms.status = 'active'
      and (ms.ends_at is null or ms.ends_at > now())
  ) then
    raise exception 'FAMILYPLUS_REQUIRED' using errcode = '42501';
  end if;

  return v_user_id;
end;
$$;

create or replace function public.familyplus_context_for_user(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_group public.family_groups%rowtype;
  v_self_subject_id uuid;
  v_has_familyplus boolean;
  v_members jsonb := '[]'::jsonb;
begin
  select exists (
    select 1
    from public.membership_subscriptions ms
    where ms.user_id = p_user_id
      and ms.plan_code = 'family_plus'
      and ms.status = 'active'
      and (ms.ends_at is null or ms.ends_at > now())
  ) into v_has_familyplus;

  select hs.id into v_self_subject_id
  from public.health_subjects hs
  where hs.owner_user_id = p_user_id
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1;

  select * into v_group
  from public.family_groups fg
  where fg.owner_user_id = p_user_id
    and fg.status = 'active'
  order by fg.created_at desc
  limit 1;

  if v_group.id is not null then
    select coalesce(jsonb_agg(
      jsonb_build_object(
        'id', fm.id,
        'family_group_id', fm.family_group_id,
        'subject_id', fm.subject_id,
        'user_id', fm.user_id,
        'display_name', fm.display_name,
        'role', fm.role,
        'status', fm.status,
        'can_view', fm.can_view,
        'can_edit', fm.can_edit
      )
      order by fm.created_at asc
    ), '[]'::jsonb)
    into v_members
    from public.family_members fm
    where fm.family_group_id = v_group.id;
  end if;

  return jsonb_build_object(
    'actor_id', p_user_id,
    'self_subject_id', v_self_subject_id,
    'has_family_plus', coalesce(v_has_familyplus, false),
    'group', case when v_group.id is null then null else jsonb_build_object(
      'id', v_group.id,
      'owner_user_id', v_group.owner_user_id,
      'display_name', v_group.display_name,
      'status', v_group.status
    ) end,
    'members', v_members,
    'selected_subject_id', v_self_subject_id
  );
end;
$$;

create or replace function public.get_my_familyplus_context()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.familyplus_context_for_user(public.assert_current_user_familyplus())
$$;

create or replace function public.upsert_my_familyplus_group(
  p_display_name text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.assert_current_user_familyplus();
  v_display_name text := nullif(btrim(coalesce(p_display_name, '')), '');
  v_idempotency_key text := nullif(btrim(coalesce(p_idempotency_key, '')), '');
  v_subscription_id uuid;
  v_group_id uuid;
begin
  if v_display_name is null or v_idempotency_key is null then
    raise exception 'INVALID_FAMILYPLUS_GROUP' using errcode = '22023';
  end if;

  select ms.id into v_subscription_id
  from public.membership_subscriptions ms
  where ms.user_id = v_user_id
    and ms.plan_code = 'family_plus'
    and ms.status = 'active'
    and (ms.ends_at is null or ms.ends_at > now())
  order by ms.starts_at desc
  limit 1;

  insert into public.family_groups (
    owner_user_id,
    plan_subscription_id,
    display_name,
    status,
    last_idempotency_key
  )
  values (
    v_user_id,
    v_subscription_id,
    v_display_name,
    'active',
    v_idempotency_key
  )
  on conflict do nothing;

  select fg.id into v_group_id
  from public.family_groups fg
  where fg.owner_user_id = v_user_id
    and fg.status = 'active'
  order by fg.created_at desc
  limit 1;

  update public.family_groups
  set
    display_name = v_display_name,
    plan_subscription_id = coalesce(v_subscription_id, plan_subscription_id),
    last_idempotency_key = v_idempotency_key,
    updated_at = now()
  where id = v_group_id;

  return public.familyplus_context_for_user(v_user_id);
end;
$$;

create or replace function public.upsert_my_familyplus_member(
  p_subject_id uuid,
  p_display_name text,
  p_role text default 'member',
  p_can_view boolean default true,
  p_can_edit boolean default false,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.assert_current_user_familyplus();
  v_display_name text := nullif(btrim(coalesce(p_display_name, '')), '');
  v_role text := lower(nullif(btrim(coalesce(p_role, 'member')), ''));
  v_idempotency_key text := nullif(btrim(coalesce(p_idempotency_key, '')), '');
  v_group_id uuid;
  v_subject public.health_subjects%rowtype;
  v_existing_id uuid;
  v_active_count integer;
begin
  if p_subject_id is null or v_display_name is null or v_idempotency_key is null then
    raise exception 'INVALID_FAMILYPLUS_MEMBER' using errcode = '22023';
  end if;
  if v_role not in ('adult', 'member', 'child', 'viewer') then
    raise exception 'INVALID_FAMILYPLUS_ROLE' using errcode = '22023';
  end if;

  select * into v_subject
  from public.health_subjects hs
  where hs.id = p_subject_id
    and hs.owner_user_id = v_user_id
    and hs.is_active = true;

  if not found then
    raise exception 'FAMILYPLUS_SUBJECT_NOT_ALLOWED' using errcode = '42501';
  end if;

  select fg.id into v_group_id
  from public.family_groups fg
  where fg.owner_user_id = v_user_id
    and fg.status = 'active'
  order by fg.created_at desc
  limit 1;

  if v_group_id is null then
    raise exception 'FAMILYPLUS_GROUP_REQUIRED' using errcode = '22023';
  end if;

  select fm.id into v_existing_id
  from public.family_members fm
  where fm.family_group_id = v_group_id
    and fm.subject_id = p_subject_id
  limit 1;

  select count(*)::integer into v_active_count
  from public.family_members fm
  where fm.family_group_id = v_group_id
    and fm.status = 'active';

  if v_existing_id is null and v_active_count >= 5 then
    raise exception 'FAMILYPLUS_MEMBER_LIMIT' using errcode = '22023';
  end if;

  insert into public.family_members (
    family_group_id,
    subject_id,
    user_id,
    display_name,
    role,
    status,
    can_view,
    can_edit,
    joined_at,
    last_idempotency_key
  )
  values (
    v_group_id,
    p_subject_id,
    v_subject.linked_user_id,
    v_display_name,
    v_role,
    'active',
    coalesce(p_can_view, true),
    coalesce(p_can_edit, false),
    now(),
    v_idempotency_key
  )
  on conflict (family_group_id, subject_id)
  do update set
    user_id = excluded.user_id,
    display_name = excluded.display_name,
    role = excluded.role,
    status = 'active',
    can_view = excluded.can_view,
    can_edit = excluded.can_edit,
    joined_at = coalesce(public.family_members.joined_at, now()),
    last_idempotency_key = excluded.last_idempotency_key,
    updated_at = now();

  return public.familyplus_context_for_user(v_user_id);
end;
$$;

create or replace function public.remove_my_familyplus_member(
  p_member_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.assert_current_user_familyplus();
  v_idempotency_key text := nullif(btrim(coalesce(p_idempotency_key, '')), '');
begin
  if p_member_id is null or v_idempotency_key is null then
    raise exception 'INVALID_FAMILYPLUS_REMOVE' using errcode = '22023';
  end if;

  update public.family_members fm
  set
    status = 'removed',
    last_idempotency_key = v_idempotency_key,
    updated_at = now()
  from public.family_groups fg
  where fm.id = p_member_id
    and fm.family_group_id = fg.id
    and fg.owner_user_id = v_user_id
    and fg.status = 'active';

  if not found then
    raise exception 'FAMILYPLUS_MEMBER_NOT_FOUND' using errcode = '22023';
  end if;

  return public.familyplus_context_for_user(v_user_id);
end;
$$;

alter table public.family_groups enable row level security;
alter table public.family_members enable row level security;

drop policy if exists family_groups_select_allowed on public.family_groups;
create policy family_groups_select_allowed
  on public.family_groups for select to authenticated
  using (
    owner_user_id = (select auth.uid())
    or exists (
      select 1
      from public.family_members fm
      where fm.family_group_id = id
        and fm.user_id = (select auth.uid())
        and fm.status = 'active'
    )
  );

drop policy if exists family_members_select_allowed on public.family_members;
create policy family_members_select_allowed
  on public.family_members for select to authenticated
  using (
    exists (
      select 1
      from public.family_groups fg
      where fg.id = family_group_id
        and fg.owner_user_id = (select auth.uid())
    )
    or exists (
      select 1
      from public.family_members actor
      where actor.family_group_id = family_members.family_group_id
        and actor.user_id = (select auth.uid())
        and actor.status = 'active'
        and actor.can_view = true
    )
  );

grant select on public.family_groups, public.family_members to authenticated;

revoke insert, update, delete on public.family_groups, public.family_members from anon, authenticated;
revoke all on function public.assert_current_user_familyplus() from public, anon, authenticated;
revoke all on function public.familyplus_context_for_user(uuid) from public, anon, authenticated;
revoke all on function public.get_my_familyplus_context() from public, anon;
revoke all on function public.upsert_my_familyplus_group(text, text) from public, anon;
revoke all on function public.upsert_my_familyplus_member(uuid, text, text, boolean, boolean, text)
  from public, anon;
revoke all on function public.remove_my_familyplus_member(uuid, text) from public, anon;

grant execute on function public.get_my_familyplus_context() to authenticated;
grant execute on function public.upsert_my_familyplus_group(text, text) to authenticated;
grant execute on function public.upsert_my_familyplus_member(uuid, text, text, boolean, boolean, text)
  to authenticated;
grant execute on function public.remove_my_familyplus_member(uuid, text) to authenticated;

commit;
