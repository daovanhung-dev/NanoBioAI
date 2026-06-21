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
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_group_id, subject_id)
);

create unique index if not exists idx_family_members_group_user_unique
  on public.family_members (family_group_id, user_id)
  where user_id is not null and status <> 'removed';

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

-- Family mutations must validate FamilyPlus entitlement, consent and member limits.
-- Keep writes server-only until a DD defines the exact UX and backend contract.
revoke insert, update, delete on public.family_groups, public.family_members from anon, authenticated;

commit;
