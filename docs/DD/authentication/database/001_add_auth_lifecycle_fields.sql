-- DD-AUTH-DB-001
-- Add onboarding lifecycle columns needed by AuthGate.
-- Run after the base multitenant schema and auth bootstrap trigger patch.

begin;

alter table public.users
  add column if not exists onboarding_status text not null default 'not_started',
  add column if not exists onboarding_completed_at timestamptz,
  add column if not exists last_login_at timestamptz;

alter table public.users
  drop constraint if exists users_onboarding_status_valid;

alter table public.users
  add constraint users_onboarding_status_valid
  check (onboarding_status in ('not_started', 'in_progress', 'completed'));

alter table public.users
  drop constraint if exists users_completed_onboarding_has_time;

alter table public.users
  add constraint users_completed_onboarding_has_time
  check (
    onboarding_status <> 'completed'
    or onboarding_completed_at is not null
  );

create index if not exists idx_users_onboarding_status
  on public.users (onboarding_status);

commit;

-- Optional safety query after migration:
-- select onboarding_status, count(*) from public.users group by onboarding_status;
