-- =============================================================================
-- 07_schema_sleep_safety.sql
-- NanoBio M31 - Sleep Safety Monitoring / safety-contact escalation contracts.
--
-- LOCAL/SANDBOX authored schema component. This file is appended to the
-- canonical rebuild by tools/build_supabase_rebuild_config.py.
-- Raw microphone audio is intentionally absent from every table and RPC.
-- =============================================================================

begin;

create table if not exists public.sleep_safety_runtime_config (
  config_key text primary key,
  enabled boolean not null default false,
  max_dispatches_per_hour integer not null default 3
    check (max_dispatches_per_hour between 1 and 12),
  event_freshness_seconds integer not null default 600
    check (event_freshness_seconds between 60 and 1800),
  contact_verification_ttl_seconds integer not null default 600
    check (contact_verification_ttl_seconds between 120 and 1800),
  updated_at timestamptz not null default now()
);

insert into public.sleep_safety_runtime_config (
  config_key,
  enabled,
  max_dispatches_per_hour,
  event_freshness_seconds,
  contact_verification_ttl_seconds
) values ('default', false, 3, 600, 600)
on conflict (config_key) do nothing;

create table if not exists public.sleep_safety_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  enabled boolean not null default true,
  sensitivity text not null default 'balanced'
    check (sensitivity in ('low', 'balanced', 'high')),
  schedule_enabled boolean not null default false,
  schedule_start_minutes integer not null default 1350
    check (schedule_start_minutes between 0 and 1439),
  schedule_end_minutes integer not null default 390
    check (schedule_end_minutes between 0 and 1439),
  timezone text not null default 'Asia/Ho_Chi_Minh',
  selected_weekdays integer[] not null default array[1,2,3,4,5,6,7],
  calibration_required boolean not null default true,
  calibration_noise_floor double precision,
  calibration_updated_at timestamptz,
  cooldown_seconds integer not null default 120
    check (cooldown_seconds between 30 and 900),
  consent_version text not null default 'sleep-safety-v1',
  updated_at timestamptz not null default now(),
  constraint sleep_safety_weekdays_valid check (
    selected_weekdays <@ array[1,2,3,4,5,6,7]::integer[]
    and cardinality(selected_weekdays) between 1 and 7
  )
);

create table if not exists public.sleep_safety_sessions (
  id text primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  started_at timestamptz not null,
  ended_at timestamptz,
  scheduled_window_start timestamptz,
  scheduled_window_end timestamptz,
  sensitivity text not null check (sensitivity in ('low', 'balanced', 'high')),
  calibration_noise_floor double precision,
  status text not null check (
    status in ('idle', 'arming', 'calibrating', 'monitoring', 'alerting', 'escalating', 'stopped', 'failed')
  ),
  start_source text not null check (start_source in ('manual', 'scheduled_reminder')),
  stop_reason text,
  platform text not null,
  app_version text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_sleep_safety_sessions_user_started
  on public.sleep_safety_sessions(user_id, started_at desc);

create table if not exists public.sleep_safety_events (
  id text primary key,
  session_id text not null references public.sleep_safety_sessions(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  detected_at timestamptz not null,
  event_type text not null check (
    event_type in (
      'suddenLoudSound',
      'strongImpact',
      'abnormalShout',
      'abnormalScream',
      'repeatedSuspiciousPattern',
      'unknownHighEnergyEvent'
    )
  ),
  severity text not null check (severity in ('attention', 'high')),
  confidence double precision not null check (confidence between 0 and 1),
  relative_energy double precision not null check (relative_energy >= 0),
  baseline_delta double precision not null check (baseline_delta >= 0),
  repetition_count integer not null default 1 check (repetition_count >= 1),
  state text not null,
  response text not null default 'none'
    check (response in ('none', 'ok', 'needHelp', 'noResponse')),
  response_at timestamptz,
  escalation_required boolean not null default false,
  escalation_status text not null default 'notRequired'
    check (escalation_status in ('notRequired', 'pending', 'dispatching', 'accepted', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Session/user ownership is cross-row and is therefore enforced by a trigger
-- plus RLS instead of an invalid CHECK-subquery contract.

create or replace function public.validate_sleep_safety_event_session_owner()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.sleep_safety_sessions s
    where s.id = new.session_id
      and s.user_id = new.user_id
  ) then
    raise exception 'sleep_safety_session_owner_mismatch';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sleep_safety_event_session_owner on public.sleep_safety_events;
create trigger trg_sleep_safety_event_session_owner
before insert or update of session_id, user_id on public.sleep_safety_events
for each row execute function public.validate_sleep_safety_event_session_owner();

create index if not exists idx_sleep_safety_events_user_detected
  on public.sleep_safety_events(user_id, detected_at desc);
create index if not exists idx_sleep_safety_events_escalation
  on public.sleep_safety_events(user_id, escalation_required, detected_at desc);

create table if not exists public.sleep_safety_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 80),
  relationship text not null check (char_length(btrim(relationship)) between 1 and 60),
  phone_e164 text not null check (phone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  priority integer not null check (priority between 1 and 3),
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'failed', 'revoked')),
  verified_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, phone_e164),
  unique(user_id, priority)
);

create index if not exists idx_sleep_safety_contacts_user_priority
  on public.sleep_safety_contacts(user_id, active, priority);

create table if not exists public.sleep_safety_contact_verification_challenges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  contact_id uuid not null references public.sleep_safety_contacts(id) on delete cascade,
  code_hash text not null,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'expired', 'locked')),
  attempt_count integer not null default 0 check (attempt_count between 0 and 10),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_sleep_safety_verification_contact_pending
  on public.sleep_safety_contact_verification_challenges(contact_id, status, expires_at desc);

create table if not exists public.sleep_safety_dispatches (
  id uuid primary key default gen_random_uuid(),
  event_id text not null references public.sleep_safety_events(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  contact_id uuid not null references public.sleep_safety_contacts(id) on delete restrict,
  priority integer not null check (priority between 1 and 3),
  channel text not null check (channel in ('sms', 'voice')),
  provider text not null default 'generic_http',
  provider_external_id text,
  status text not null default 'queued'
    check (status in ('queued', 'submitted', 'delivered', 'answered', 'failed', 'noAnswer', 'cancelled')),
  attempt integer not null default 1 check (attempt between 1 and 10),
  idempotency_key text not null,
  failure_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, idempotency_key, contact_id, channel)
);

create index if not exists idx_sleep_safety_dispatches_user_created
  on public.sleep_safety_dispatches(user_id, created_at desc);
create index if not exists idx_sleep_safety_dispatches_event
  on public.sleep_safety_dispatches(event_id, priority, channel);

-- ---------------------------------------------------------------------------
-- Contact mutations: server-owned verification fields cannot be written by a
-- Flutter client. Priority conflicts fail closed and must be resolved by the UI.
-- ---------------------------------------------------------------------------

create or replace function public.upsert_sleep_safety_contact(
  p_contact_id uuid,
  p_name text,
  p_relationship text,
  p_phone_e164 text,
  p_priority integer
)
returns setof public.sleep_safety_contacts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := (select auth.uid());
  v_existing public.sleep_safety_contacts%rowtype;
begin
  if v_uid is null then
    raise exception 'authentication_required';
  end if;
  if p_priority not between 1 and 3 then
    raise exception 'sleep_safety_priority_invalid';
  end if;
  if p_phone_e164 !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'sleep_safety_phone_invalid';
  end if;

  if p_contact_id is null then
    if (
      select count(*)
      from public.sleep_safety_contacts c
      where c.user_id = v_uid and c.active = true
    ) >= 3 then
      raise exception 'sleep_safety_contact_limit';
    end if;

    return query
    insert into public.sleep_safety_contacts (
      user_id, name, relationship, phone_e164, priority
    ) values (
      v_uid, btrim(p_name), btrim(p_relationship), p_phone_e164, p_priority
    )
    returning *;
    return;
  end if;

  select * into v_existing
  from public.sleep_safety_contacts c
  where c.id = p_contact_id and c.user_id = v_uid
  for update;

  if not found then
    raise exception 'sleep_safety_contact_not_found';
  end if;

  return query
  update public.sleep_safety_contacts c
  set name = btrim(p_name),
      relationship = btrim(p_relationship),
      phone_e164 = p_phone_e164,
      priority = p_priority,
      verification_status = case
        when c.phone_e164 is distinct from p_phone_e164 then 'pending'
        else c.verification_status
      end,
      verified_at = case
        when c.phone_e164 is distinct from p_phone_e164 then null
        else c.verified_at
      end,
      active = true,
      updated_at = now()
  where c.id = p_contact_id and c.user_id = v_uid
  returning c.*;
end;
$$;

create or replace function public.delete_sleep_safety_contact(p_contact_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'authentication_required';
  end if;
  delete from public.sleep_safety_contacts
  where id = p_contact_id and user_id = v_uid;
end;
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.sleep_safety_runtime_config enable row level security;
alter table public.sleep_safety_preferences enable row level security;
alter table public.sleep_safety_sessions enable row level security;
alter table public.sleep_safety_events enable row level security;
alter table public.sleep_safety_contacts enable row level security;
alter table public.sleep_safety_contact_verification_challenges enable row level security;
alter table public.sleep_safety_dispatches enable row level security;

create policy sleep_safety_runtime_read on public.sleep_safety_runtime_config
for select to authenticated using (true);

create policy sleep_safety_preferences_own on public.sleep_safety_preferences
for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy sleep_safety_sessions_own on public.sleep_safety_sessions
for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy sleep_safety_events_own on public.sleep_safety_events
for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy sleep_safety_contacts_read_own on public.sleep_safety_contacts
for select to authenticated
using (user_id = (select auth.uid()));

create policy sleep_safety_dispatches_read_own on public.sleep_safety_dispatches
for select to authenticated
using (user_id = (select auth.uid()));

-- Challenges and dispatch writes are Edge Function/service-role only.
revoke all on public.sleep_safety_contact_verification_challenges from anon, authenticated;
revoke insert, update, delete on public.sleep_safety_contacts from anon, authenticated;
revoke insert, update, delete on public.sleep_safety_dispatches from anon, authenticated;
revoke insert, update, delete on public.sleep_safety_runtime_config from anon, authenticated;

grant select on public.sleep_safety_runtime_config to authenticated;
grant select, insert, update, delete on public.sleep_safety_preferences to authenticated;
grant select, insert, update, delete on public.sleep_safety_sessions to authenticated;
grant select, insert, update, delete on public.sleep_safety_events to authenticated;
grant select on public.sleep_safety_contacts to authenticated;
grant select on public.sleep_safety_dispatches to authenticated;
grant execute on function public.upsert_sleep_safety_contact(uuid, text, text, text, integer) to authenticated;
grant execute on function public.delete_sleep_safety_contact(uuid) to authenticated;

-- Keep updated_at deterministic on mutable cloud rows.
drop trigger if exists trg_sleep_safety_preferences_updated_at on public.sleep_safety_preferences;
create trigger trg_sleep_safety_preferences_updated_at
before update on public.sleep_safety_preferences
for each row execute function public.set_updated_at();

drop trigger if exists trg_sleep_safety_sessions_updated_at on public.sleep_safety_sessions;
create trigger trg_sleep_safety_sessions_updated_at
before update on public.sleep_safety_sessions
for each row execute function public.set_updated_at();

drop trigger if exists trg_sleep_safety_events_updated_at on public.sleep_safety_events;
create trigger trg_sleep_safety_events_updated_at
before update on public.sleep_safety_events
for each row execute function public.set_updated_at();

drop trigger if exists trg_sleep_safety_contacts_updated_at on public.sleep_safety_contacts;
create trigger trg_sleep_safety_contacts_updated_at
before update on public.sleep_safety_contacts
for each row execute function public.set_updated_at();

drop trigger if exists trg_sleep_safety_verification_updated_at on public.sleep_safety_contact_verification_challenges;
create trigger trg_sleep_safety_verification_updated_at
before update on public.sleep_safety_contact_verification_challenges
for each row execute function public.set_updated_at();

drop trigger if exists trg_sleep_safety_dispatches_updated_at on public.sleep_safety_dispatches;
create trigger trg_sleep_safety_dispatches_updated_at
before update on public.sleep_safety_dispatches
for each row execute function public.set_updated_at();

commit;
