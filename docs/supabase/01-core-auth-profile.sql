-- Commit de xuat: docs(supabase): tao core auth profile schema
-- NanoBio / BioAI - Supabase core Auth/Profile draft.
-- Run before other docs/supabase SQL files.

begin;

create extension if not exists pgcrypto;

do $$
begin
  create domain public.nb_membership_plan as text
    check (value in ('free', 'plus', 'family_plus'));
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create domain public.nb_onboarding_status as text
    check (value in ('not_started', 'in_progress', 'completed'));
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create domain public.nb_product_access_status as text
    check (value in ('guest', 'free', 'plus', 'family_plus'));
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create domain public.nb_sale_status as text
    check (value in ('none', 'pending', 'active', 'suspended', 'closed'));
exception
  when duplicate_object then null;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  phone text,
  full_name text,
  avatar_url text,
  gender text,
  birth_year integer,
  subscription_tier public.nb_membership_plan not null default 'free',
  product_access_status public.nb_product_access_status not null default 'guest',
  sale_status public.nb_sale_status not null default 'none',
  is_anonymous boolean not null default false,
  onboarding_status public.nb_onboarding_status not null default 'not_started',
  onboarding_completed_at timestamptz,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_completed_onboarding_has_time
    check (onboarding_status <> 'completed' or onboarding_completed_at is not null)
);

create unique index if not exists idx_users_phone_unique_not_null
  on public.users (phone)
  where phone is not null;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

create table if not exists public.health_subjects (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  linked_user_id uuid references public.users(id) on delete set null,
  family_group_id uuid,
  subject_type text not null default 'self'
    check (subject_type in ('self', 'family_member')),
  display_name text,
  relationship text,
  gender text,
  birth_year integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint health_subject_self_owner
    check (subject_type <> 'self' or owner_user_id = coalesce(linked_user_id, owner_user_id))
);

create unique index if not exists idx_health_subjects_one_self_per_owner
  on public.health_subjects (owner_user_id)
  where subject_type = 'self';

create index if not exists idx_health_subjects_owner_active
  on public.health_subjects (owner_user_id, is_active);

create index if not exists idx_health_subjects_linked_user
  on public.health_subjects (linked_user_id)
  where linked_user_id is not null;

drop trigger if exists trg_health_subjects_updated_at on public.health_subjects;
create trigger trg_health_subjects_updated_at
  before update on public.health_subjects
  for each row execute function public.set_updated_at();

create or replace function public.default_self_subject_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select hs.id
  from public.health_subjects hs
  where hs.owner_user_id = (select auth.uid())
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1
$$;

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
      and hs.owner_user_id = (select auth.uid())
  )
$$;

create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_anonymous boolean;
  v_product_status public.nb_product_access_status;
begin
  v_is_anonymous := coalesce(
    (new.raw_app_meta_data ->> 'provider') = 'anonymous',
    new.email is null and new.phone is null
  );

  v_product_status := case when v_is_anonymous then 'guest' else 'free' end;

  insert into public.users (
    id,
    email,
    phone,
    full_name,
    avatar_url,
    subscription_tier,
    product_access_status,
    is_anonymous
  )
  values (
    new.id,
    new.email,
    coalesce(new.phone, nullif(new.raw_user_meta_data ->> 'phone', '')),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', '')
    ),
    nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
    'free',
    v_product_status,
    v_is_anonymous
  )
  on conflict (id) do update
  set
    email = excluded.email,
    phone = coalesce(excluded.phone, public.users.phone),
    full_name = coalesce(public.users.full_name, excluded.full_name),
    avatar_url = coalesce(public.users.avatar_url, excluded.avatar_url),
    product_access_status = excluded.product_access_status,
    is_anonymous = excluded.is_anonymous,
    updated_at = now();

  insert into public.health_subjects (
    owner_user_id,
    linked_user_id,
    subject_type,
    display_name,
    relationship
  )
  values (
    new.id,
    new.id,
    'self',
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      new.email,
      'Bạn'
    ),
    'self'
  )
  on conflict (owner_user_id) where subject_type = 'self'
  do update
  set
    linked_user_id = excluded.linked_user_id,
    display_name = coalesce(public.health_subjects.display_name, excluded.display_name),
    is_active = true,
    updated_at = now();

  return new;
end;
$$;

create or replace function public.handle_auth_user_contact_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
  set
    email = new.email,
    phone = coalesce(new.phone, public.users.phone),
    updated_at = now()
  where id = new.id;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_auth_user_created();

drop trigger if exists on_auth_user_contact_changed on auth.users;
create trigger on_auth_user_contact_changed
  after update of email, phone on auth.users
  for each row execute function public.handle_auth_user_contact_changed();

insert into public.users (id, email, phone, full_name, avatar_url, subscription_tier, product_access_status, is_anonymous)
select
  au.id,
  au.email,
  coalesce(au.phone, nullif(au.raw_user_meta_data ->> 'phone', '')),
  coalesce(nullif(au.raw_user_meta_data ->> 'full_name', ''), nullif(au.raw_user_meta_data ->> 'name', '')),
  nullif(au.raw_user_meta_data ->> 'avatar_url', ''),
  'free',
  case when au.email is null and au.phone is null then 'guest' else 'free' end,
  au.email is null and au.phone is null
from auth.users au
on conflict (id) do nothing;

insert into public.health_subjects (owner_user_id, linked_user_id, subject_type, display_name, relationship)
select
  u.id,
  u.id,
  'self',
  coalesce(u.full_name, u.email, 'Bạn'),
  'self'
from public.users u
on conflict (owner_user_id) where subject_type = 'self' do nothing;

alter table public.users enable row level security;
alter table public.health_subjects enable row level security;

drop policy if exists users_select_own on public.users;
drop policy if exists users_update_own_profile on public.users;

create policy users_select_own
  on public.users for select to authenticated
  using ((select auth.uid()) = id);

create policy users_update_own_profile
  on public.users for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists health_subjects_select_allowed on public.health_subjects;
drop policy if exists health_subjects_insert_own on public.health_subjects;
drop policy if exists health_subjects_update_allowed on public.health_subjects;
drop policy if exists health_subjects_delete_own on public.health_subjects;

create policy health_subjects_select_allowed
  on public.health_subjects for select to authenticated
  using (public.can_read_health_subject(id));

create policy health_subjects_insert_own
  on public.health_subjects for insert to authenticated
  with check (owner_user_id = (select auth.uid()));

create policy health_subjects_update_allowed
  on public.health_subjects for update to authenticated
  using (public.can_write_health_subject(id))
  with check (public.can_write_health_subject(id));

create policy health_subjects_delete_own
  on public.health_subjects for delete to authenticated
  using (owner_user_id = (select auth.uid()));

grant usage on schema public to anon, authenticated;
grant select on public.users, public.health_subjects to authenticated;
grant update (
  phone,
  full_name,
  avatar_url,
  gender,
  birth_year,
  onboarding_status,
  onboarding_completed_at,
  last_login_at
) on public.users to authenticated;
grant select, insert, update, delete on public.health_subjects to authenticated;

revoke insert, delete on public.users from anon, authenticated;
revoke update (
  subscription_tier,
  product_access_status,
  sale_status,
  is_anonymous,
  created_at,
  updated_at
) on public.users from anon, authenticated;

commit;
