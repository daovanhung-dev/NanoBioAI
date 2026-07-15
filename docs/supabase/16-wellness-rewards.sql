-- NanoBio / BioAI
-- Migration 16: server-authoritative schedule proof, wellness points and rewards.
--
-- Non-destructive migration. Apply to local/sandbox first. This migration
-- depends on the schema through migration 15, including Admin permission and
-- audit helpers. Never replace a remote database with config.sql.

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 16A. Versioned program configuration and server-owned reward tables
-- ---------------------------------------------------------------------------

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'wellness_reward_program',
  jsonb_build_object(
    'contract_version', 'wellness_schedule_v2_2026_07',
    'reward_points', 10,
    'expiry_days', 180,
    'time_zone', 'Asia/Ho_Chi_Minh'
  ),
  'active',
  'Khởi tạo chương trình Điểm chăm sóc v2.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'wellness_reward_program'
    and status = 'active'
);

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'wellness_rewards_rollout',
  '{"enabled": false, "contract_version": "wellness_rewards_v1"}'::jsonb,
  'active',
  'Cờ tính năng mặc định tắt cho đến khi kiểm thử trên môi trường thử nghiệm hoàn tất.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'wellness_rewards_rollout'
    and status = 'active'
);

-- Server-owned marker that permanently pins the only initial Guest request
-- allowed to issue reward eligibility for an account after sign-in. The
-- request table itself is mobile-snapshot data and can be replaced on pull;
-- this marker therefore snapshots the validated request identity and shape.
create table if not exists public.guest_schedule_reward_registrations (
  user_id uuid primary key references public.users(id) on delete cascade,
  schedule_request_id text not null unique,
  plan_start_date date not null,
  plan_days integer not null check (plan_days between 1 and 7),
  plan_item_count integer not null,
  manifest_hash text not null check (manifest_hash ~ '^[0-9a-f]{64}$'),
  plan_item_ids uuid[] not null,
  eligible_item_ids uuid[] not null,
  first_registration_idempotency_key text not null,
  registered_item_count integer not null default 0
    check (registered_item_count >= 0 and registered_item_count <= plan_item_count),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint guest_reward_plan_shape_valid check (
    plan_item_count between plan_days * 10 and plan_days * 11
    and cardinality(plan_item_ids) = plan_item_count
    and eligible_item_ids <@ plan_item_ids
  )
);

-- Member requests are quota-backed and must be registered exactly once with
-- one immutable full-plan manifest. A different idempotency key can never add
-- eligibility to an already pinned Member request.
create table if not exists public.member_schedule_reward_registrations (
  schedule_request_id text primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  plan_start_date date not null,
  plan_days integer not null check (plan_days between 1 and 7),
  plan_item_count integer not null,
  manifest_hash text not null check (manifest_hash ~ '^[0-9a-f]{64}$'),
  registration_idempotency_key text not null,
  registered_item_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_reward_plan_shape_valid check (
    plan_item_count between plan_days * 10 and plan_days * 11
    and registered_item_count between 0 and plan_item_count
  ),
  unique (user_id, registration_idempotency_key)
);

alter table public.guest_schedule_reward_registrations
  drop constraint if exists guest_reward_plan_shape_valid;
alter table public.guest_schedule_reward_registrations
  add constraint guest_reward_plan_shape_valid check (
    plan_item_count between plan_days * 10 and plan_days * 11
    and cardinality(plan_item_ids) = plan_item_count
    and eligible_item_ids <@ plan_item_ids
  );

alter table public.member_schedule_reward_registrations
  drop constraint if exists member_reward_plan_shape_valid;
alter table public.member_schedule_reward_registrations
  add constraint member_reward_plan_shape_valid check (
    plan_item_count between plan_days * 10 and plan_days * 11
    and registered_item_count between 0 and plan_item_count
  );

create table if not exists public.schedule_reward_eligibilities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  subject_id uuid not null references public.health_subjects(id) on delete cascade,
  schedule_item_id uuid not null,
  schedule_request_id text not null,
  schedule_date date not null,
  start_time time not null,
  window_start timestamptz not null,
  window_end timestamptz not null,
  title_snapshot text not null,
  category_snapshot text,
  source_type_snapshot text not null,
  source_id_snapshot text,
  status text not null default 'eligible'
    check (status in ('eligible', 'completed', 'undone', 'void')),
  registration_idempotency_key text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint schedule_reward_window_valid check (
    window_end = window_start + interval '30 minutes'
    and window_end > window_start
  ),
  unique (user_id, schedule_item_id),
  unique (user_id, schedule_request_id, schedule_date, start_time)
);

create table if not exists public.schedule_completion_attempts (
  id uuid primary key default gen_random_uuid(),
  eligibility_id uuid not null references public.schedule_reward_eligibilities(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  begin_idempotency_key text not null,
  finalize_idempotency_key text,
  undo_idempotency_key text,
  object_path text not null unique,
  status text not null default 'begun'
    check (status in ('begun', 'finalized', 'undone', 'rejected')),
  began_at timestamptz not null default now(),
  finalized_at timestamptz,
  rejection_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, begin_idempotency_key),
  unique (user_id, finalize_idempotency_key),
  unique (user_id, undo_idempotency_key)
);

create table if not exists public.schedule_completion_proofs (
  id uuid primary key default gen_random_uuid(),
  eligibility_id uuid not null references public.schedule_reward_eligibilities(id) on delete cascade,
  attempt_id uuid not null unique references public.schedule_completion_attempts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  bucket_id text not null default 'schedule-completion-proofs',
  object_path text not null unique,
  content_type text not null check (content_type = 'image/jpeg'),
  byte_size integer not null check (byte_size > 0 and byte_size <= 5242880),
  captured_at timestamptz not null,
  uploaded_at timestamptz not null,
  status text not null default 'active'
    check (status in ('active', 'reversed')),
  reversed_at timestamptz,
  undo_idempotency_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, undo_idempotency_key)
);

create unique index if not exists idx_schedule_completion_proofs_one_active
  on public.schedule_completion_proofs (eligibility_id)
  where status = 'active';

create table if not exists public.wellness_reward_wallets (
  user_id uuid primary key references public.users(id) on delete cascade,
  pending_points integer not null default 0 check (pending_points >= 0),
  available_points integer not null default 0 check (available_points >= 0),
  lifetime_earned_points integer not null default 0 check (lifetime_earned_points >= 0),
  lifetime_spent_points integer not null default 0 check (lifetime_spent_points >= 0),
  lifetime_refunded_points integer not null default 0 check (lifetime_refunded_points >= 0),
  lock_version bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Existing +1/-1 mobile rows become display-only +10/-10 history. They never
-- seed the redeemable wallet because the old client-controlled snapshot could
-- not prove eligibility or evidence ownership.
alter table public.wellness_point_ledgers
  add column if not exists event_type text not null default 'legacy_history',
  add column if not exists status text not null default 'history',
  add column if not exists title text not null default 'Lịch sử điểm nhiệm vụ cũ',
  add column if not exists is_redeemable boolean not null default false,
  add column if not exists available_at timestamptz,
  add column if not exists expires_at timestamptz,
  add column if not exists program_config_id uuid references public.system_config_versions(id) on delete restrict,
  add column if not exists eligibility_id uuid references public.schedule_reward_eligibilities(id) on delete set null,
  add column if not exists redemption_id uuid,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

update public.wellness_point_ledgers
set
  points_delta = points_delta * 10,
  program_code = 'wellness_schedule_legacy_v1',
  event_type = 'legacy_history',
  status = 'history',
  title = 'Lịch sử điểm nhiệm vụ cũ',
  is_redeemable = false,
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'migration', '16-wellness-rewards',
    'original_points_delta', points_delta,
    'redeemable', false
  ),
  updated_at = now()
where program_code = 'wellness_schedule_v1'
  and abs(points_delta) = 1
  and event_type = 'legacy_history';

create table if not exists public.wellness_point_allocations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  subject_id uuid not null references public.health_subjects(id) on delete cascade,
  ledger_id uuid not null unique references public.wellness_point_ledgers(id) on delete restrict,
  eligibility_id uuid references public.schedule_reward_eligibilities(id) on delete set null,
  source_type text not null check (source_type in ('schedule_reward', 'admin_refund')),
  source_id uuid not null,
  original_points integer not null check (original_points > 0),
  remaining_points integer not null check (remaining_points >= 0 and remaining_points <= original_points),
  status text not null check (status in ('pending', 'available', 'spent', 'expired', 'reversed')),
  available_at timestamptz not null,
  expires_at timestamptz not null,
  program_config_id uuid not null references public.system_config_versions(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_type, source_id)
);

create table if not exists public.wellness_reward_offers (
  id uuid primary key default gen_random_uuid(),
  offer_code text not null unique,
  title text not null,
  description text not null,
  provider_name text not null,
  cost_points integer not null check (cost_points > 0),
  eligible_plan_codes text[] not null default array['free', 'plus', 'family_plus']::text[],
  available_from timestamptz,
  available_until timestamptz,
  voucher_expires_at timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references public.users(id) on delete set null,
  updated_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wellness_reward_offer_window_valid check (
    available_until is null or available_from is null or available_until > available_from
  ),
  constraint wellness_reward_offer_plans_valid check (
    cardinality(eligible_plan_codes) > 0
    and eligible_plan_codes <@ array['free', 'plus', 'family_plus']::text[]
  )
);

create table if not exists public.wellness_reward_codes (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid not null references public.wellness_reward_offers(id) on delete restrict,
  code_value text not null,
  code_hash text not null,
  status text not null default 'available'
    check (status in ('available', 'issued', 'retired')),
  voucher_expires_at timestamptz,
  assigned_user_id uuid references public.users(id) on delete set null,
  assigned_redemption_id uuid,
  issued_at timestamptz,
  retired_at timestamptz,
  imported_by uuid references public.users(id) on delete set null,
  import_batch_key text,
  created_at timestamptz not null default now(),
  unique (code_hash)
);

create table if not exists public.wellness_reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  offer_id uuid not null references public.wellness_reward_offers(id) on delete restrict,
  reward_code_id uuid not null unique references public.wellness_reward_codes(id) on delete restrict,
  offer_title_snapshot text not null,
  provider_name_snapshot text not null,
  points_spent integer not null check (points_spent > 0),
  status text not null default 'issued' check (status in ('issued', 'cancelled')),
  voucher_expires_at timestamptz not null,
  idempotency_key text not null,
  issued_at timestamptz not null default now(),
  cancelled_at timestamptz,
  cancelled_by uuid references public.users(id) on delete set null,
  cancellation_reason text,
  refund_allocation_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create table if not exists public.wellness_redemption_allocation_usages (
  redemption_id uuid not null references public.wellness_reward_redemptions(id) on delete restrict,
  allocation_id uuid not null references public.wellness_point_allocations(id) on delete restrict,
  points_used integer not null check (points_used > 0),
  created_at timestamptz not null default now(),
  primary key (redemption_id, allocation_id)
);

create index if not exists idx_schedule_reward_eligibilities_user_window
  on public.schedule_reward_eligibilities (user_id, window_start, window_end);
create index if not exists idx_schedule_completion_attempts_user_status
  on public.schedule_completion_attempts (user_id, status, began_at desc);
create index if not exists idx_schedule_completion_proofs_user_created
  on public.schedule_completion_proofs (user_id, created_at desc);
create index if not exists idx_wellness_point_allocations_wallet_expiry
  on public.wellness_point_allocations (user_id, status, available_at, expires_at);
create unique index if not exists idx_wellness_point_allocations_one_schedule_reward
  on public.wellness_point_allocations (eligibility_id)
  where eligibility_id is not null;
create index if not exists idx_wellness_point_ledgers_reward_history
  on public.wellness_point_ledgers (user_id, is_redeemable, created_at desc);
create index if not exists idx_wellness_reward_offers_catalog
  on public.wellness_reward_offers (is_active, available_from, available_until);
create index if not exists idx_wellness_reward_codes_stock
  on public.wellness_reward_codes (offer_id, status, created_at);
create unique index if not exists idx_wellness_reward_codes_global_hash
  on public.wellness_reward_codes (code_hash);
create index if not exists idx_wellness_reward_redemptions_user_created
  on public.wellness_reward_redemptions (user_id, created_at desc);

drop trigger if exists trg_schedule_reward_eligibilities_updated_at
  on public.schedule_reward_eligibilities;
create trigger trg_schedule_reward_eligibilities_updated_at
  before update on public.schedule_reward_eligibilities
  for each row execute function public.set_updated_at();

drop trigger if exists trg_guest_schedule_reward_registrations_updated_at
  on public.guest_schedule_reward_registrations;
create trigger trg_guest_schedule_reward_registrations_updated_at
  before update on public.guest_schedule_reward_registrations
  for each row execute function public.set_updated_at();

drop trigger if exists trg_member_schedule_reward_registrations_updated_at
  on public.member_schedule_reward_registrations;
create trigger trg_member_schedule_reward_registrations_updated_at
  before update on public.member_schedule_reward_registrations
  for each row execute function public.set_updated_at();

drop trigger if exists trg_schedule_completion_attempts_updated_at
  on public.schedule_completion_attempts;
create trigger trg_schedule_completion_attempts_updated_at
  before update on public.schedule_completion_attempts
  for each row execute function public.set_updated_at();

drop trigger if exists trg_schedule_completion_proofs_updated_at
  on public.schedule_completion_proofs;
create trigger trg_schedule_completion_proofs_updated_at
  before update on public.schedule_completion_proofs
  for each row execute function public.set_updated_at();

drop trigger if exists trg_wellness_reward_wallets_updated_at
  on public.wellness_reward_wallets;
create trigger trg_wellness_reward_wallets_updated_at
  before update on public.wellness_reward_wallets
  for each row execute function public.set_updated_at();

drop trigger if exists trg_wellness_point_allocations_updated_at
  on public.wellness_point_allocations;
create trigger trg_wellness_point_allocations_updated_at
  before update on public.wellness_point_allocations
  for each row execute function public.set_updated_at();

drop trigger if exists trg_wellness_reward_offers_updated_at
  on public.wellness_reward_offers;
create trigger trg_wellness_reward_offers_updated_at
  before update on public.wellness_reward_offers
  for each row execute function public.set_updated_at();

drop trigger if exists trg_wellness_reward_redemptions_updated_at
  on public.wellness_reward_redemptions;
create trigger trg_wellness_reward_redemptions_updated_at
  before update on public.wellness_reward_redemptions
  for each row execute function public.set_updated_at();

-- The legacy updated_at trigger would imply mutation is supported. From this
-- migration onward the ledger is append-only; account-cascade deletion remains
-- allowed so the account-deletion contract can remove personal data.
drop trigger if exists trg_wellness_point_ledgers_updated_at
  on public.wellness_point_ledgers;

create or replace function public.guard_wellness_point_ledger_append_only()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if current_setting('nanobio.wellness_ledger_maintenance', true) = 'on' then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  if tg_op = 'DELETE'
     and not exists (select 1 from public.users where id = old.user_id) then
    return old;
  end if;

  raise exception using
    errcode = 'P0001',
    message = 'wellness_ledger_append_only';
end;
$$;

drop trigger if exists trg_wellness_point_ledgers_append_only
  on public.wellness_point_ledgers;
create trigger trg_wellness_point_ledgers_append_only
  before update or delete on public.wellness_point_ledgers
  for each row execute function public.guard_wellness_point_ledger_append_only();

create or replace function public.wellness_rewards_feature_enabled()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce((
    select case
      when lower(scv.config_value ->> 'enabled') in ('true', '1') then true
      else false
    end
    from public.system_config_versions scv
    where scv.config_key = 'wellness_rewards_rollout'
      and scv.status = 'active'
    order by scv.created_at desc
    limit 1
  ), false)
$$;

create or replace function public.current_wellness_reward_program()
returns table (
  program_config_id uuid,
  contract_version text,
  reward_points integer,
  expiry_days integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_config public.system_config_versions%rowtype;
  v_expiry_text text;
begin
  select * into v_config
  from public.system_config_versions scv
  where scv.config_key = 'wellness_reward_program'
    and scv.status = 'active'
  order by scv.created_at desc
  limit 1;

  if v_config.id is null then
    raise exception using errcode = 'P0001', message = 'reward_program_not_configured';
  end if;

  v_expiry_text := v_config.config_value ->> 'expiry_days';
  if coalesce(v_expiry_text, '') !~ '^[0-9]{1,4}$'
     or v_expiry_text::integer not between 1 and 3650 then
    raise exception using errcode = 'P0001', message = 'reward_program_invalid';
  end if;

  return query select
    v_config.id,
    coalesce(nullif(v_config.config_value ->> 'contract_version', ''), 'wellness_schedule_v2'),
    10,
    v_expiry_text::integer;
end;
$$;

create or replace function public.reward_text_is_vietnamese(p_text text)
returns boolean
language sql
immutable
set search_path = public, pg_temp
as $$
  select
    nullif(btrim(coalesce(p_text, '')), '') is not null
    and p_text ~ '[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]'
    and p_text !~ '(Ã.|Â.|Ä.|Æ.|�)'
$$;

create or replace function public.refresh_wellness_reward_wallet(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_newly_available integer := 0;
  v_expired integer := 0;
begin
  if p_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  insert into public.wellness_reward_wallets (user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  perform 1
  from public.wellness_reward_wallets
  where user_id = p_user_id
  for update;

  perform 1
  from public.wellness_point_allocations
  where user_id = p_user_id
    and status = 'pending'
    and available_at <= now()
    and remaining_points > 0
  for update;

  select coalesce(sum(remaining_points), 0)::integer
  into v_newly_available
  from public.wellness_point_allocations
  where user_id = p_user_id
    and status = 'pending'
    and available_at <= now()
    and remaining_points > 0;

  update public.wellness_point_allocations
  set status = 'available', updated_at = now()
  where user_id = p_user_id
    and status = 'pending'
    and available_at <= now()
    and remaining_points > 0;

  if v_newly_available > 0 then
    update public.wellness_reward_wallets
    set
      pending_points = pending_points - v_newly_available,
      available_points = available_points + v_newly_available,
      lock_version = lock_version + 1,
      updated_at = now()
    where user_id = p_user_id;
  end if;

  perform 1
  from public.wellness_point_allocations
  where user_id = p_user_id
    and status = 'available'
    and expires_at <= now()
    and remaining_points > 0
  for update;

  select coalesce(sum(remaining_points), 0)::integer
  into v_expired
  from public.wellness_point_allocations
  where user_id = p_user_id
    and status = 'available'
    and expires_at <= now()
    and remaining_points > 0;

  insert into public.wellness_point_ledgers (
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    available_at,
    expires_at,
    program_config_id,
    metadata
  )
  select
    wpa.user_id,
    wpa.subject_id,
    'wellness_point_allocation',
    wpa.id,
    (wpa.expires_at at time zone 'Asia/Ho_Chi_Minh')::date,
    -wpa.remaining_points,
    'wellness_rewards_v2',
    'wellness_expiry:' || wpa.id::text,
    'expiry',
    'expired',
    'Điểm chăm sóc đã hết hạn',
    true,
    wpa.available_at,
    wpa.expires_at,
    wpa.program_config_id,
    jsonb_build_object('allocation_id', wpa.id)
  from public.wellness_point_allocations wpa
  where wpa.user_id = p_user_id
    and wpa.status = 'available'
    and wpa.expires_at <= now()
    and wpa.remaining_points > 0
  on conflict (user_id, idempotency_key) do nothing;

  update public.wellness_point_allocations
  set remaining_points = 0, status = 'expired', updated_at = now()
  where user_id = p_user_id
    and status = 'available'
    and expires_at <= now()
    and remaining_points > 0;

  if v_expired > 0 then
    update public.wellness_reward_wallets
    set
      available_points = available_points - v_expired,
      lock_version = lock_version + 1,
      updated_at = now()
    where user_id = p_user_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 16B. RLS, grants and private Storage contract
-- ---------------------------------------------------------------------------

alter table public.guest_schedule_reward_registrations enable row level security;
alter table public.member_schedule_reward_registrations enable row level security;
alter table public.schedule_reward_eligibilities enable row level security;
alter table public.schedule_completion_attempts enable row level security;
alter table public.schedule_completion_proofs enable row level security;
alter table public.wellness_reward_wallets enable row level security;
alter table public.wellness_point_allocations enable row level security;
alter table public.wellness_reward_offers enable row level security;
alter table public.wellness_reward_codes enable row level security;
alter table public.wellness_reward_redemptions enable row level security;
alter table public.wellness_redemption_allocation_usages enable row level security;

drop policy if exists wellness_point_ledgers_select_subject
  on public.wellness_point_ledgers;
drop policy if exists wellness_point_ledgers_insert_subject
  on public.wellness_point_ledgers;
drop policy if exists wellness_point_ledgers_update_subject
  on public.wellness_point_ledgers;
drop policy if exists wellness_point_ledgers_delete_subject
  on public.wellness_point_ledgers;
drop policy if exists wellness_point_ledgers_select_own
  on public.wellness_point_ledgers;
create policy wellness_point_ledgers_select_own
  on public.wellness_point_ledgers for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists schedule_reward_eligibilities_select_own
  on public.schedule_reward_eligibilities;
create policy schedule_reward_eligibilities_select_own
  on public.schedule_reward_eligibilities for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists schedule_completion_attempts_select_own
  on public.schedule_completion_attempts;
create policy schedule_completion_attempts_select_own
  on public.schedule_completion_attempts for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists schedule_completion_proofs_select_own
  on public.schedule_completion_proofs;
create policy schedule_completion_proofs_select_own
  on public.schedule_completion_proofs for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists wellness_reward_wallets_select_own
  on public.wellness_reward_wallets;
create policy wellness_reward_wallets_select_own
  on public.wellness_reward_wallets for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists wellness_point_allocations_select_own
  on public.wellness_point_allocations;
create policy wellness_point_allocations_select_own
  on public.wellness_point_allocations for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists wellness_reward_offers_select_active
  on public.wellness_reward_offers;
create policy wellness_reward_offers_select_active
  on public.wellness_reward_offers for select to authenticated
  using (is_active = true);

drop policy if exists wellness_reward_redemptions_select_own
  on public.wellness_reward_redemptions;
create policy wellness_reward_redemptions_select_own
  on public.wellness_reward_redemptions for select to authenticated
  using (user_id = (select auth.uid()));

revoke all on
  public.guest_schedule_reward_registrations,
  public.member_schedule_reward_registrations,
  public.schedule_reward_eligibilities,
  public.schedule_completion_attempts,
  public.schedule_completion_proofs,
  public.wellness_reward_wallets,
  public.wellness_point_allocations,
  public.wellness_reward_offers,
  public.wellness_reward_codes,
  public.wellness_reward_redemptions,
  public.wellness_redemption_allocation_usages
from anon, authenticated;

revoke insert, update, delete on public.wellness_point_ledgers
from anon, authenticated;
grant select on
  public.schedule_reward_eligibilities,
  public.schedule_completion_attempts,
  public.schedule_completion_proofs,
  public.wellness_reward_wallets,
  public.wellness_point_ledgers,
  public.wellness_point_allocations,
  public.wellness_reward_offers,
  public.wellness_reward_redemptions
to authenticated;

insert into public.admin_permissions (code, description)
values
  ('wellness_rewards.read', 'Xem danh mục, tồn kho và giao dịch Điểm chăm sóc.'),
  ('wellness_rewards.write', 'Quản lý ưu đãi, kho mã và hủy giao dịch Điểm chăm sóc.')
on conflict (code) do update
set description = excluded.description, is_active = true;

create or replace function public.can_access_schedule_proof_object(p_name text)
returns boolean
language sql
stable
security definer
set search_path = public, storage, pg_temp
as $$
  select
    split_part(coalesce(p_name, ''), '/', 1) = auth.uid()::text
    and exists (
      select 1
      from public.schedule_completion_attempts sca
      where sca.user_id = auth.uid()
        and sca.object_path = p_name
        and sca.status in ('begun', 'finalized', 'undone')
    )
$$;

revoke all on function public.guard_wellness_point_ledger_append_only()
from public, anon, authenticated;
revoke all on function public.refresh_wellness_reward_wallet(uuid)
from public, anon, authenticated;
revoke all on function public.current_wellness_reward_program()
from public, anon, authenticated;
revoke all on function public.reward_text_is_vietnamese(text)
from public, anon, authenticated;
revoke all on function public.can_access_schedule_proof_object(text)
from public, anon;
grant execute on function public.can_access_schedule_proof_object(text)
to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'schedule-completion-proofs',
  'schedule-completion-proofs',
  false,
  5242880,
  array['image/jpeg']::text[]
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists schedule_completion_proofs_storage_select_own
  on storage.objects;
create policy schedule_completion_proofs_storage_select_own
  on storage.objects for select to authenticated
  using (
    bucket_id = 'schedule-completion-proofs'
    and public.can_access_schedule_proof_object(name)
  );

drop policy if exists schedule_completion_proofs_storage_insert_own
  on storage.objects;
create policy schedule_completion_proofs_storage_insert_own
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'schedule-completion-proofs'
    and split_part(name, '/', 1) = auth.uid()::text
    and public.can_access_schedule_proof_object(name)
  );

-- Deliberately no authenticated UPDATE or DELETE policy. Combined with the
-- server-issued unique path this makes Storage upsert impossible and keeps
-- active/reversed evidence until account deletion or trusted retention work.
drop policy if exists schedule_completion_proofs_storage_update_own
  on storage.objects;
drop policy if exists schedule_completion_proofs_storage_delete_own
  on storage.objects;

-- ---------------------------------------------------------------------------
-- 16C. Schedule eligibility, proof and +10 point RPCs
-- ---------------------------------------------------------------------------

create or replace function public.register_my_schedule_reward_eligibilities(
  p_request_id text,
  p_items jsonb,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_subject_id uuid;
  v_request public.personal_schedule_ai_requests%rowtype;
  v_guest_marker public.guest_schedule_reward_registrations%rowtype;
  v_member_marker public.member_schedule_reward_registrations%rowtype;
  v_item_count integer;
  v_matched_count integer;
  v_full_item_count integer;
  v_full_day_count integer;
  v_request_eligible_count integer;
  v_manifest_hash text;
  v_full_item_id_hash text;
  v_full_manifest_hash text;
  v_full_item_ids uuid[];
  v_guest_eligible_item_ids uuid[];
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if nullif(btrim(coalesce(p_request_id, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'schedule_request_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if jsonb_typeof(p_items) <> 'array' then
    raise exception using errcode = 'P0001', message = 'schedule_items_invalid';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:register:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  v_item_count := jsonb_array_length(p_items);
  if v_item_count < 1 or v_item_count > 70 then
    raise exception using errcode = 'P0001', message = 'schedule_items_invalid';
  end if;

  if exists (
    select 1 from public.users
    where id = v_user_id and is_anonymous = true
  ) then
    raise exception using errcode = 'P0001', message = 'member_account_required';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'eligibility_id', sre.id,
        'schedule_item_id', sre.schedule_item_id,
        'schedule_date', sre.schedule_date,
        'window_start', sre.window_start,
        'window_end', sre.window_end,
        'status', sre.status
      ) order by sre.window_start
    ),
    '[]'::jsonb
  )
  into v_result
  from public.schedule_reward_eligibilities sre
  where sre.user_id = v_user_id
    and sre.registration_idempotency_key = btrim(p_idempotency_key);

  if jsonb_array_length(v_result) > 0 then
    if exists (
      select 1
      from public.schedule_reward_eligibilities sre
      where sre.user_id = v_user_id
        and sre.registration_idempotency_key = btrim(p_idempotency_key)
        and sre.schedule_request_id <> btrim(p_request_id)
    ) then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    return jsonb_build_object(
      'request_id', btrim(p_request_id),
      'registered_count', jsonb_array_length(v_result),
      'eligibilities', v_result,
      'idempotent_replay', true
    );
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) item
    where coalesce(item ->> 'schedule_item_id', item ->> 'id', '')
      !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_item_id_invalid';
  end if;

  select encode(
    digest(string_agg(parsed.schedule_item_id::text, ',' order by parsed.schedule_item_id), 'sha256'),
    'hex'
  )
  into v_manifest_hash
  from (
    select distinct
      coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid as schedule_item_id
    from jsonb_array_elements(p_items) item
  ) parsed;

  select * into v_request
  from public.personal_schedule_ai_requests psar
  where psar.request_id = btrim(p_request_id)
    and psar.user_id = v_user_id
    and psar.actor_mode in ('member_new', 'initial_guest')
    and psar.status = 'succeeded';

  if v_request.request_id is null
     or v_request.start_date is null
     or v_request.days not between 1 and 7
     or v_request.schedule_item_count < v_request.days * 10
     or v_request.schedule_item_count > v_request.days * 11 then
    raise exception using errcode = 'P0001', message = 'schedule_request_not_eligible';
  end if;

  -- This request-scoped lock is independent of the client key. It prevents a
  -- second key racing the first registration before its immutable marker is
  -- visible.
  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:register-request:' || btrim(p_request_id),
    0
  ));

  if v_request.actor_mode = 'member_new' then
    if v_request.schedule_item_count <> v_item_count then
      raise exception using errcode = 'P0001', message = 'schedule_request_not_eligible';
    end if;

    if not exists (
      select 1
      from public.usage_events ue
      where ue.user_id = v_user_id
        and ue.feature_key = 'personal_schedule_generation'
        and ue.idempotency_key = btrim(p_request_id)
        and ue.event_source in ('trusted_backend', 'edge_function', 'sql_job', 'admin')
    ) then
      raise exception using errcode = 'P0001', message = 'schedule_quota_commit_required';
    end if;

    select * into v_member_marker
    from public.member_schedule_reward_registrations msrr
    where msrr.schedule_request_id = btrim(p_request_id)
    for update;

    if v_member_marker.schedule_request_id is not null then
      if v_member_marker.user_id <> v_user_id then
        raise exception using errcode = 'P0001', message = 'member_schedule_request_claimed';
      end if;
      raise exception using errcode = 'P0001', message = 'member_schedule_request_already_registered';
    end if;
  else
    -- Different idempotency keys for the same account/request must still
    -- serialize against the lifetime Guest marker and its unique request ID.
    perform pg_advisory_xact_lock(hashtextextended(
      'wellness:guest-register:' || v_user_id::text,
      0
    ));
    if (
      select count(*)
      from public.personal_schedule_ai_requests psar
      where psar.user_id = v_user_id
        and psar.actor_mode = 'initial_guest'
        and psar.status = 'succeeded'
    ) <> 1 then
      raise exception using errcode = 'P0001', message = 'guest_schedule_request_ambiguous';
    end if;

    select * into v_guest_marker
    from public.guest_schedule_reward_registrations gsrr
    where gsrr.user_id = v_user_id
    for update;

    if v_guest_marker.user_id is not null
       and v_guest_marker.schedule_request_id <> btrim(p_request_id) then
      raise exception using errcode = 'P0001', message = 'guest_schedule_request_already_registered';
    end if;
    if v_guest_marker.user_id is not null
       and (
         v_guest_marker.plan_start_date <> v_request.start_date
         or v_guest_marker.plan_days <> v_request.days
         or v_guest_marker.plan_item_count <> v_request.schedule_item_count
       ) then
      raise exception using errcode = 'P0001', message = 'guest_schedule_request_changed';
    end if;
    if exists (
      select 1
      from public.guest_schedule_reward_registrations gsrr
      where gsrr.schedule_request_id = btrim(p_request_id)
        and gsrr.user_id <> v_user_id
    ) then
      raise exception using errcode = 'P0001', message = 'guest_schedule_request_claimed';
    end if;

  end if;

  -- Validate the complete server-side schedule range for both modes. Member
  -- manifests must enumerate this exact set; Guest manifests may be a future,
  -- incomplete subset of it.
  select
    count(*)::integer,
    count(distinct lsi.schedule_date)::integer,
    array_agg(lsi.id order by lsi.id),
    encode(digest(string_agg(lsi.id::text, ',' order by lsi.id), 'sha256'), 'hex'),
    encode(digest(string_agg(
      jsonb_build_array(
        lsi.id,
        lsi.schedule_date,
        lsi.start_time::text,
        lsi.title,
        lsi.category,
        lsi.source_type,
        lsi.source_id
      )::text,
      E'\n' order by lsi.id
    ), 'sha256'), 'hex')
  into
    v_full_item_count,
    v_full_day_count,
    v_full_item_ids,
    v_full_item_id_hash,
    v_full_manifest_hash
  from public.lifestyle_schedule_items lsi
  where lsi.user_id = v_user_id
    and lsi.ai_generated = true
    and lsi.schedule_date >= v_request.start_date
    and lsi.schedule_date < v_request.start_date + v_request.days;

  if v_full_item_count <> v_request.schedule_item_count
     or v_full_day_count <> v_request.days
     or exists (
       select 1
       from public.lifestyle_schedule_items lsi
       where lsi.user_id = v_user_id
         and lsi.ai_generated = true
         and lsi.schedule_date >= v_request.start_date
         and lsi.schedule_date < v_request.start_date + v_request.days
       group by lsi.schedule_date
       having count(*) not between 10 and 11
           or count(distinct lsi.start_time) <> count(*)
     ) then
    if v_request.actor_mode = 'initial_guest' then
      raise exception using errcode = 'P0001', message = 'guest_schedule_plan_invalid';
    end if;
    raise exception using errcode = 'P0001', message = 'member_schedule_plan_invalid';
  end if;

  if v_request.actor_mode = 'member_new'
     and v_manifest_hash <> v_full_item_id_hash then
    raise exception using errcode = 'P0001', message = 'member_schedule_manifest_mismatch';
  end if;
  if v_request.actor_mode = 'initial_guest'
     and v_guest_marker.user_id is not null
     and v_guest_marker.manifest_hash <> v_full_manifest_hash then
    raise exception using errcode = 'P0001', message = 'guest_schedule_request_changed';
  end if;

  if v_request.actor_mode = 'initial_guest' then
    if v_guest_marker.user_id is null then
      select coalesce(array_agg(lsi.id order by lsi.id), '{}'::uuid[])
      into v_guest_eligible_item_ids
      from public.lifestyle_schedule_items lsi
      where lsi.user_id = v_user_id
        and lsi.id = any(v_full_item_ids)
        and lsi.is_completed = false
        and ((lsi.schedule_date + lsi.start_time) at time zone 'Asia/Ho_Chi_Minh') > now();
    else
      v_guest_eligible_item_ids := v_guest_marker.eligible_item_ids;
    end if;
  end if;

  select count(distinct lsi.id)::integer
  into v_matched_count
  from jsonb_array_elements(p_items) item
  join public.lifestyle_schedule_items lsi
    on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
   and lsi.user_id = v_user_id
  where lsi.is_completed = false
    and lsi.ai_generated = true;

  if v_matched_count <> v_item_count then
    raise exception using errcode = 'P0001', message = 'schedule_items_not_found';
  end if;

  if v_request.actor_mode = 'initial_guest' and exists (
    select 1
    from jsonb_array_elements(p_items) item
    where not (
      coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
      = any(v_guest_eligible_item_ids)
    )
  ) then
    raise exception using errcode = 'P0001', message = 'guest_schedule_item_not_in_pinned_plan';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) item
    join public.lifestyle_schedule_items lsi
      on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
     and lsi.user_id = v_user_id
    where lsi.schedule_date < v_request.start_date
       or lsi.schedule_date >= v_request.start_date + v_request.days
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_items_outside_request_range';
  end if;

  if v_request.actor_mode = 'member_new' and exists (
    select 1
    from jsonb_array_elements(p_items) item
    join public.lifestyle_schedule_items lsi
      on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
     and lsi.user_id = v_user_id
    group by lsi.schedule_date
    having count(*) <> 10
        or count(distinct lsi.id) <> 10
        or count(distinct lsi.start_time) <> 10
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_day_must_have_10_items';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) item
    join public.lifestyle_schedule_items lsi
      on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
     and lsi.user_id = v_user_id
    where ((lsi.schedule_date + lsi.start_time) at time zone 'Asia/Ho_Chi_Minh') <= now()
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_window_must_be_future';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) item
    join public.schedule_reward_eligibilities sre
      on sre.user_id = v_user_id
     and sre.schedule_item_id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
    where sre.schedule_request_id <> btrim(p_request_id)
  ) then
    raise exception using errcode = 'P0001', message = 'schedule_item_already_registered';
  end if;

  select hs.id into v_subject_id
  from public.health_subjects hs
  where hs.owner_user_id = v_user_id
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1;

  if v_subject_id is null then
    raise exception using errcode = 'P0001', message = 'health_subject_required';
  end if;

  if v_request.actor_mode = 'initial_guest' then
    insert into public.guest_schedule_reward_registrations (
      user_id,
      schedule_request_id,
      plan_start_date,
      plan_days,
      plan_item_count,
      manifest_hash,
      plan_item_ids,
      eligible_item_ids,
      first_registration_idempotency_key
    )
    values (
      v_user_id,
      btrim(p_request_id),
      v_request.start_date,
      v_request.days,
      v_request.schedule_item_count,
      v_full_manifest_hash,
      v_full_item_ids,
      v_guest_eligible_item_ids,
      btrim(p_idempotency_key)
    )
    on conflict (user_id) do nothing;
  else
    insert into public.member_schedule_reward_registrations (
      schedule_request_id,
      user_id,
      plan_start_date,
      plan_days,
      plan_item_count,
      manifest_hash,
      registration_idempotency_key
    )
    values (
      btrim(p_request_id),
      v_user_id,
      v_request.start_date,
      v_request.days,
      v_request.schedule_item_count,
      v_full_manifest_hash,
      btrim(p_idempotency_key)
    );
  end if;

  insert into public.schedule_reward_eligibilities (
    user_id,
    subject_id,
    schedule_item_id,
    schedule_request_id,
    schedule_date,
    start_time,
    window_start,
    window_end,
    title_snapshot,
    category_snapshot,
    source_type_snapshot,
    source_id_snapshot,
    registration_idempotency_key
  )
  select
    v_user_id,
    v_subject_id,
    lsi.id,
    btrim(p_request_id),
    lsi.schedule_date,
    lsi.start_time,
    ((lsi.schedule_date + lsi.start_time) at time zone 'Asia/Ho_Chi_Minh'),
    ((lsi.schedule_date + lsi.start_time) at time zone 'Asia/Ho_Chi_Minh') + interval '30 minutes',
    lsi.title,
    lsi.category,
    lsi.source_type,
    lsi.source_id,
    btrim(p_idempotency_key)
  from jsonb_array_elements(p_items) item
  join public.lifestyle_schedule_items lsi
    on lsi.id = coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
   and lsi.user_id = v_user_id
  on conflict (user_id, schedule_item_id) do nothing;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'eligibility_id', sre.id,
        'schedule_item_id', sre.schedule_item_id,
        'schedule_date', sre.schedule_date,
        'window_start', sre.window_start,
        'window_end', sre.window_end,
        'status', sre.status
      ) order by sre.window_start
    ),
    '[]'::jsonb
  )
  into v_result
  from public.schedule_reward_eligibilities sre
  where sre.user_id = v_user_id
    and sre.schedule_request_id = btrim(p_request_id)
    and sre.schedule_item_id in (
      select coalesce(item ->> 'schedule_item_id', item ->> 'id')::uuid
      from jsonb_array_elements(p_items) item
    );

  if jsonb_array_length(v_result) <> v_item_count then
    raise exception using errcode = 'P0001', message = 'eligibility_registration_conflict';
  end if;

  select count(*)::integer
  into v_request_eligible_count
  from public.schedule_reward_eligibilities sre
  where sre.user_id = v_user_id
    and sre.schedule_request_id = btrim(p_request_id);

  if v_request_eligible_count > v_request.schedule_item_count then
    raise exception using errcode = 'P0001', message = 'schedule_request_eligibility_limit_exceeded';
  end if;

  if v_request.actor_mode = 'initial_guest' then
    update public.guest_schedule_reward_registrations gsrr
    set registered_item_count = v_request_eligible_count
    where gsrr.user_id = v_user_id
      and gsrr.schedule_request_id = btrim(p_request_id);
  else
    if v_request_eligible_count <> v_request.schedule_item_count then
      raise exception using errcode = 'P0001', message = 'member_schedule_manifest_incomplete';
    end if;
    update public.member_schedule_reward_registrations msrr
    set registered_item_count = v_request_eligible_count
    where msrr.schedule_request_id = btrim(p_request_id)
      and msrr.user_id = v_user_id;
  end if;

  return jsonb_build_object(
    'request_id', btrim(p_request_id),
    'registered_count', v_item_count,
    'eligibilities', v_result,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.begin_my_schedule_completion(
  p_schedule_item_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_eligibility public.schedule_reward_eligibilities%rowtype;
  v_attempt public.schedule_completion_attempts%rowtype;
  v_attempt_id uuid := gen_random_uuid();
  v_path text;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if p_schedule_item_id is null then
    raise exception using errcode = 'P0001', message = 'schedule_item_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:begin:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  select * into v_attempt
  from public.schedule_completion_attempts sca
  where sca.user_id = v_user_id
    and sca.begin_idempotency_key = btrim(p_idempotency_key);

  if v_attempt.id is not null then
    if not exists (
      select 1
      from public.schedule_reward_eligibilities sre
      where sre.id = v_attempt.eligibility_id
        and sre.schedule_item_id = p_schedule_item_id
    ) then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    if v_attempt.status = 'undone' then
      raise exception using errcode = 'P0001', message = 'eligibility_not_available';
    end if;
    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'eligibility_id', v_attempt.eligibility_id,
      'bucket_id', 'schedule-completion-proofs',
      'storage_path', v_attempt.object_path,
      'object_path', v_attempt.object_path,
      'content_type', 'image/jpeg',
      'max_bytes', 5242880,
      'window_end', (
        select window_end from public.schedule_reward_eligibilities
        where id = v_attempt.eligibility_id
      ),
      'upload_deadline', (
        select window_end from public.schedule_reward_eligibilities
        where id = v_attempt.eligibility_id
      ),
      'status', v_attempt.status,
      'idempotent_replay', true
    );
  end if;

  select * into v_eligibility
  from public.schedule_reward_eligibilities sre
  where sre.schedule_item_id = p_schedule_item_id
    and sre.user_id = v_user_id
  for update;

  if v_eligibility.id is null then
    raise exception using errcode = 'P0001', message = 'eligibility_not_found';
  end if;
  if v_eligibility.status = 'completed' then
    raise exception using errcode = 'P0001', message = 'schedule_already_completed';
  end if;
  if v_eligibility.status <> 'eligible' then
    raise exception using errcode = 'P0001', message = 'eligibility_not_available';
  end if;
  if now() < v_eligibility.window_start then
    raise exception using errcode = 'P0001', message = 'schedule_window_not_open';
  end if;
  if now() > v_eligibility.window_end then
    raise exception using errcode = 'P0001', message = 'schedule_window_locked';
  end if;

  v_path := v_user_id::text || '/' || v_eligibility.id::text || '/' || v_attempt_id::text || '.jpg';

  insert into public.schedule_completion_attempts (
    id,
    eligibility_id,
    user_id,
    begin_idempotency_key,
    object_path
  )
  values (
    v_attempt_id,
    v_eligibility.id,
    v_user_id,
    btrim(p_idempotency_key),
    v_path
  )
  returning * into v_attempt;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'eligibility_id', v_attempt.eligibility_id,
    'bucket_id', 'schedule-completion-proofs',
    'storage_path', v_attempt.object_path,
    'object_path', v_attempt.object_path,
    'content_type', 'image/jpeg',
    'max_bytes', 5242880,
    'window_end', v_eligibility.window_end,
    'upload_deadline', v_eligibility.window_end,
    'status', v_attempt.status,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.finalize_my_schedule_completion(
  p_attempt_id uuid,
  p_storage_path text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, storage, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt public.schedule_completion_attempts%rowtype;
  v_eligibility public.schedule_reward_eligibilities%rowtype;
  v_object storage.objects%rowtype;
  v_proof public.schedule_completion_proofs%rowtype;
  v_allocation public.wellness_point_allocations%rowtype;
  v_wallet public.wellness_reward_wallets%rowtype;
  v_program record;
  v_ledger_id uuid := gen_random_uuid();
  v_allocation_id uuid := gen_random_uuid();
  v_size_text text;
  v_content_type text;
  v_byte_size integer;
  v_reward_status text;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if p_attempt_id is null then
    raise exception using errcode = 'P0001', message = 'completion_attempt_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if nullif(btrim(coalesce(p_storage_path, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'storage_path_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:finalize:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  if exists (
    select 1
    from public.schedule_completion_attempts sca
    where sca.user_id = v_user_id
      and sca.finalize_idempotency_key = btrim(p_idempotency_key)
      and sca.id <> p_attempt_id
  ) then
    raise exception using errcode = 'P0001', message = 'idempotency_conflict';
  end if;

  select * into v_attempt
  from public.schedule_completion_attempts sca
  where sca.id = p_attempt_id
    and sca.user_id = v_user_id
  for update;

  if v_attempt.id is null then
    raise exception using errcode = 'P0001', message = 'completion_attempt_not_found';
  end if;
  if v_attempt.object_path <> btrim(p_storage_path) then
    raise exception using errcode = 'P0001', message = 'storage_path_mismatch';
  end if;

  select * into v_eligibility
  from public.schedule_reward_eligibilities sre
  where sre.id = v_attempt.eligibility_id
    and sre.user_id = v_user_id
  for update;

  if v_attempt.status = 'finalized' then
    if v_attempt.finalize_idempotency_key <> btrim(p_idempotency_key) then
      raise exception using errcode = 'P0001', message = 'schedule_already_completed';
    end if;

    select * into v_proof
    from public.schedule_completion_proofs scp
    where scp.attempt_id = v_attempt.id;

    select * into v_allocation
    from public.wellness_point_allocations wpa
    where wpa.source_type = 'schedule_reward'
      and wpa.source_id = v_attempt.id;

    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;

    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'eligibility_id', v_attempt.eligibility_id,
      'proof_id', v_proof.id,
      'proof_status', v_proof.status,
      'reward_points', v_allocation.original_points,
      'points_delta', v_allocation.original_points,
      'reward_status', v_allocation.status,
      'available_at', v_allocation.available_at,
      'expires_at', v_allocation.expires_at,
      'pending_points', v_wallet.pending_points,
      'available_points', v_wallet.available_points,
      'idempotent_replay', true
    );
  end if;

  if v_eligibility.id is null then
    raise exception using errcode = 'P0001', message = 'eligibility_not_available';
  end if;
  if exists (
    select 1
    from public.wellness_point_allocations wpa
    where wpa.eligibility_id = v_eligibility.id
  ) then
    raise exception using errcode = 'P0001', message = 'eligibility_reward_already_awarded';
  end if;
  if v_eligibility.status <> 'eligible' then
    raise exception using errcode = 'P0001', message = 'eligibility_not_available';
  end if;
  if v_attempt.status <> 'begun' then
    raise exception using errcode = 'P0001', message = 'completion_attempt_not_active';
  end if;

  select * into v_object
  from storage.objects so
  where so.bucket_id = 'schedule-completion-proofs'
    and so.name = v_attempt.object_path
  limit 1;

  if v_object.id is null then
    raise exception using errcode = 'P0001', message = 'proof_not_uploaded';
  end if;
  if v_object.created_at < greatest(v_attempt.began_at, v_eligibility.window_start)
     or v_object.created_at > v_eligibility.window_end then
    raise exception using errcode = 'P0001', message = 'proof_upload_outside_window';
  end if;

  v_content_type := lower(coalesce(
    v_object.metadata ->> 'mimetype',
    v_object.metadata ->> 'contentType',
    ''
  ));
  v_size_text := coalesce(v_object.metadata ->> 'size', '');

  if v_content_type <> 'image/jpeg' then
    raise exception using errcode = 'P0001', message = 'proof_content_type_invalid';
  end if;
  if v_size_text !~ '^[0-9]{1,7}$' then
    raise exception using errcode = 'P0001', message = 'proof_size_invalid';
  end if;
  v_byte_size := v_size_text::integer;
  if v_byte_size < 1 or v_byte_size > 5242880 then
    raise exception using errcode = 'P0001', message = 'proof_size_invalid';
  end if;

  select * into v_program
  from public.current_wellness_reward_program();

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  v_reward_status := case
    when now() > v_eligibility.window_end then 'available'
    else 'pending'
  end;

  insert into public.schedule_completion_proofs (
    eligibility_id,
    attempt_id,
    user_id,
    object_path,
    content_type,
    byte_size,
    captured_at,
    uploaded_at
  )
  values (
    v_eligibility.id,
    v_attempt.id,
    v_user_id,
    v_attempt.object_path,
    v_content_type,
    v_byte_size,
    greatest(
      v_attempt.began_at,
      v_eligibility.window_start,
      v_object.created_at
    ),
    v_object.created_at
  )
  returning * into v_proof;

  insert into public.wellness_point_ledgers (
    id,
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    available_at,
    expires_at,
    program_config_id,
    eligibility_id,
    metadata
  )
  values (
    v_ledger_id,
    v_user_id,
    v_eligibility.subject_id,
    'schedule_completion_attempt',
    v_attempt.id,
    v_eligibility.schedule_date,
    v_program.reward_points,
    v_program.contract_version,
    'schedule_reward:' || v_attempt.id::text,
    'schedule_award',
    v_reward_status,
    'Hoàn thành nhiệm vụ: ' || v_eligibility.title_snapshot,
    true,
    v_eligibility.window_end,
    v_eligibility.window_end + make_interval(days => v_program.expiry_days),
    v_program.program_config_id,
    v_eligibility.id,
    jsonb_build_object(
      'attempt_id', v_attempt.id,
      'proof_id', v_proof.id,
      'client_idempotency_key', btrim(p_idempotency_key)
    )
  );

  insert into public.wellness_point_allocations (
    id,
    user_id,
    subject_id,
    ledger_id,
    eligibility_id,
    source_type,
    source_id,
    original_points,
    remaining_points,
    status,
    available_at,
    expires_at,
    program_config_id
  )
  values (
    v_allocation_id,
    v_user_id,
    v_eligibility.subject_id,
    v_ledger_id,
    v_eligibility.id,
    'schedule_reward',
    v_attempt.id,
    v_program.reward_points,
    v_program.reward_points,
    v_reward_status,
    v_eligibility.window_end,
    v_eligibility.window_end + make_interval(days => v_program.expiry_days),
    v_program.program_config_id
  )
  returning * into v_allocation;

  update public.wellness_reward_wallets
  set
    pending_points = pending_points + case when v_reward_status = 'pending' then v_program.reward_points else 0 end,
    available_points = available_points + case when v_reward_status = 'available' then v_program.reward_points else 0 end,
    lifetime_earned_points = lifetime_earned_points + v_program.reward_points,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  update public.schedule_completion_attempts
  set
    finalize_idempotency_key = btrim(p_idempotency_key),
    status = 'finalized',
    finalized_at = now(),
    updated_at = now()
  where id = v_attempt.id;

  update public.schedule_reward_eligibilities
  set status = 'completed', updated_at = now()
  where id = v_eligibility.id;

  update public.lifestyle_schedule_items
  set
    is_completed = true,
    current_value = greatest(current_value, target_value),
    updated_at = now()
  where id = v_eligibility.schedule_item_id
    and user_id = v_user_id;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'eligibility_id', v_eligibility.id,
    'proof_id', v_proof.id,
    'proof_status', v_proof.status,
    'reward_points', v_allocation.original_points,
    'points_delta', v_allocation.original_points,
    'reward_status', v_allocation.status,
    'available_at', v_allocation.available_at,
    'expires_at', v_allocation.expires_at,
    'pending_points', v_wallet.pending_points,
    'available_points', v_wallet.available_points,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.undo_my_schedule_completion(
  p_schedule_item_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_eligibility public.schedule_reward_eligibilities%rowtype;
  v_proof public.schedule_completion_proofs%rowtype;
  v_attempt public.schedule_completion_attempts%rowtype;
  v_allocation public.wellness_point_allocations%rowtype;
  v_wallet public.wellness_reward_wallets%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if p_schedule_item_id is null then
    raise exception using errcode = 'P0001', message = 'schedule_item_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:undo:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  select * into v_proof
  from public.schedule_completion_proofs scp
  where scp.user_id = v_user_id
    and scp.undo_idempotency_key = btrim(p_idempotency_key);

  if v_proof.id is not null then
    if not exists (
      select 1
      from public.schedule_reward_eligibilities sre
      where sre.id = v_proof.eligibility_id
        and sre.schedule_item_id = p_schedule_item_id
    ) then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;
    return jsonb_build_object(
      'eligibility_id', v_proof.eligibility_id,
      'schedule_item_id', p_schedule_item_id,
      'proof_id', v_proof.id,
      'proof_status', v_proof.status,
      'reward_delta', -10,
      'points_delta', -10,
      'reward_status', 'reversed',
      'pending_points', v_wallet.pending_points,
      'available_points', v_wallet.available_points,
      'idempotent_replay', true
    );
  end if;

  -- An undo may arrive while upload/finalize is still pending. Persist the
  -- client key on the attempt so a lost response can be replayed without ever
  -- creating or reversing points.
  select * into v_attempt
  from public.schedule_completion_attempts sca
  where sca.user_id = v_user_id
    and sca.undo_idempotency_key = btrim(p_idempotency_key);

  if v_attempt.id is not null then
    if not exists (
      select 1
      from public.schedule_reward_eligibilities sre
      where sre.id = v_attempt.eligibility_id
        and sre.schedule_item_id = p_schedule_item_id
    ) then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;
    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'eligibility_id', v_attempt.eligibility_id,
      'schedule_item_id', p_schedule_item_id,
      'proof_id', null,
      'proof_status', 'not_created',
      'reward_delta', 0,
      'points_delta', 0,
      'reward_status', 'not_awarded',
      'pending_points', v_wallet.pending_points,
      'available_points', v_wallet.available_points,
      'idempotent_replay', true
    );
  end if;

  select * into v_eligibility
  from public.schedule_reward_eligibilities sre
  where sre.schedule_item_id = p_schedule_item_id
    and sre.user_id = v_user_id
  for update;

  if v_eligibility.id is null then
    raise exception using errcode = 'P0001', message = 'eligibility_not_found';
  end if;
  if now() > v_eligibility.window_end then
    raise exception using errcode = 'P0001', message = 'undo_window_locked';
  end if;

  if v_eligibility.status = 'eligible' then
    select * into v_attempt
    from public.schedule_completion_attempts sca
    where sca.eligibility_id = v_eligibility.id
      and sca.user_id = v_user_id
      and sca.status = 'begun'
    order by sca.began_at desc, sca.id desc
    limit 1
    for update;

    if v_attempt.id is null then
      raise exception using errcode = 'P0001', message = 'schedule_not_completed';
    end if;

    update public.schedule_completion_attempts
    set
      status = 'undone',
      undo_idempotency_key = btrim(p_idempotency_key),
      rejection_code = 'cancelled_by_user_before_finalize',
      updated_at = now()
    where id = v_attempt.id;

    -- A caller may have begun more than one attempt with different keys. Once
    -- the task is undone, every still-open attempt must become non-finalizable.
    update public.schedule_completion_attempts
    set
      status = 'undone',
      rejection_code = 'cancelled_by_user_before_finalize',
      updated_at = now()
    where eligibility_id = v_eligibility.id
      and user_id = v_user_id
      and status = 'begun'
      and id <> v_attempt.id;

    update public.schedule_reward_eligibilities
    set status = 'undone', updated_at = now()
    where id = v_eligibility.id;

    update public.lifestyle_schedule_items
    set is_completed = false, current_value = 0, updated_at = now()
    where id = v_eligibility.schedule_item_id
      and user_id = v_user_id;

    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;

    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'eligibility_id', v_eligibility.id,
      'schedule_item_id', p_schedule_item_id,
      'proof_id', null,
      'proof_status', 'not_created',
      'reward_delta', 0,
      'points_delta', 0,
      'reward_status', 'not_awarded',
      'pending_points', v_wallet.pending_points,
      'available_points', v_wallet.available_points,
      'idempotent_replay', false
    );
  end if;

  if v_eligibility.status <> 'completed' then
    raise exception using errcode = 'P0001', message = 'eligibility_not_available';
  end if;

  select * into v_proof
  from public.schedule_completion_proofs scp
  where scp.eligibility_id = v_eligibility.id
    and scp.user_id = v_user_id
    and scp.status = 'active'
  for update;

  if v_proof.id is null then
    raise exception using errcode = 'P0001', message = 'active_proof_not_found';
  end if;

  select * into v_attempt
  from public.schedule_completion_attempts sca
  where sca.id = v_proof.attempt_id
  for update;

  select * into v_allocation
  from public.wellness_point_allocations wpa
  where wpa.user_id = v_user_id
    and wpa.source_type = 'schedule_reward'
    and wpa.source_id = v_attempt.id
  for update;

  if v_allocation.id is null or v_allocation.status <> 'pending'
     or v_allocation.remaining_points <> v_allocation.original_points then
    raise exception using errcode = 'P0001', message = 'reward_cannot_be_undone';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  insert into public.wellness_point_ledgers (
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    available_at,
    expires_at,
    program_config_id,
    eligibility_id,
    metadata
  )
  values (
    v_user_id,
    v_eligibility.subject_id,
    'schedule_completion_proof',
    v_proof.id,
    v_eligibility.schedule_date,
    -v_allocation.original_points,
    'wellness_rewards_v2',
    'schedule_undo:' || v_proof.id::text,
    'schedule_reversal',
    'reversed',
    'Hoàn tác nhiệm vụ: ' || v_eligibility.title_snapshot,
    true,
    v_allocation.available_at,
    v_allocation.expires_at,
    v_allocation.program_config_id,
    v_eligibility.id,
    jsonb_build_object('client_idempotency_key', btrim(p_idempotency_key))
  );

  update public.wellness_point_allocations
  set remaining_points = 0, status = 'reversed', updated_at = now()
  where id = v_allocation.id;

  update public.wellness_reward_wallets
  set
    pending_points = pending_points - v_allocation.original_points,
    lifetime_earned_points = lifetime_earned_points - v_allocation.original_points,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  update public.schedule_completion_proofs
  set
    status = 'reversed',
    reversed_at = now(),
    undo_idempotency_key = btrim(p_idempotency_key),
    updated_at = now()
  where id = v_proof.id;

  update public.schedule_completion_attempts
  set status = 'undone', updated_at = now()
  where id = v_attempt.id;

  update public.schedule_reward_eligibilities
  set status = 'undone', updated_at = now()
  where id = v_eligibility.id;

  update public.lifestyle_schedule_items
  set is_completed = false, current_value = 0, updated_at = now()
  where id = v_eligibility.schedule_item_id
    and user_id = v_user_id;

  return jsonb_build_object(
    'eligibility_id', v_eligibility.id,
    'schedule_item_id', p_schedule_item_id,
    'proof_id', v_proof.id,
    'proof_status', 'reversed',
    'reward_delta', -v_allocation.original_points,
    'points_delta', -v_allocation.original_points,
    'reward_status', 'reversed',
    'pending_points', v_wallet.pending_points,
    'available_points', v_wallet.available_points,
    'idempotent_replay', false
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 16D. User wallet, catalog and atomic redemption RPCs
-- ---------------------------------------------------------------------------

create or replace function public.get_my_wellness_reward_summary()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_wallet public.wellness_reward_wallets%rowtype;
  v_expiring integer := 0;
  v_next_expiry timestamptz;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id;

  select
    coalesce(sum(remaining_points), 0)::integer,
    min(expires_at)
  into v_expiring, v_next_expiry
  from public.wellness_point_allocations
  where user_id = v_user_id
    and status = 'available'
    and remaining_points > 0
    and expires_at > now()
    and expires_at <= now() + interval '30 days';

  return jsonb_build_object(
    'pending_points', v_wallet.pending_points,
    'available_points', v_wallet.available_points,
    'expiring_soon_points', v_expiring,
    'next_expiry_at', v_next_expiry,
    'synced_at', now(),
    'program_enabled', public.wellness_rewards_feature_enabled()
  );
end;
$$;

create or replace function public.list_my_wellness_point_history(
  p_limit integer default 100
)
returns table (
  id uuid,
  points_delta integer,
  event_type text,
  status text,
  title text,
  is_redeemable boolean,
  available_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);

  return query
  select
    wpl.id,
    wpl.points_delta,
    wpl.event_type,
    case
      when wpl.event_type = 'schedule_award' then coalesce(wpa.status, wpl.status)
      else wpl.status
    end,
    wpl.title,
    wpl.is_redeemable,
    wpl.available_at,
    wpl.expires_at,
    wpl.created_at
  from public.wellness_point_ledgers wpl
  left join public.wellness_point_allocations wpa
    on wpa.ledger_id = wpl.id
  where wpl.user_id = v_user_id
  order by wpl.created_at desc, wpl.id desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.list_my_reward_offers(
  p_limit integer default 100
)
returns table (
  id uuid,
  offer_id uuid,
  offer_code text,
  title text,
  description text,
  provider_name text,
  cost_points integer,
  available_codes integer,
  eligible_plan_codes text[],
  available_from timestamptz,
  available_until timestamptz,
  voucher_expires_at timestamptz,
  is_active boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan text;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  v_plan := public.current_plan_for_user(v_user_id)::text;

  return query
  select
    wro.id,
    wro.id,
    wro.offer_code,
    wro.title,
    wro.description,
    wro.provider_name,
    wro.cost_points,
    count(wrc.id) filter (
      where wrc.status = 'available'
        and coalesce(wrc.voucher_expires_at, wro.voucher_expires_at) > now()
    )::integer,
    wro.eligible_plan_codes,
    wro.available_from,
    wro.available_until,
    wro.voucher_expires_at,
    wro.is_active
  from public.wellness_reward_offers wro
  left join public.wellness_reward_codes wrc
    on wrc.offer_id = wro.id
  where public.wellness_rewards_feature_enabled()
    and wro.is_active = true
    and (wro.available_from is null or wro.available_from <= now())
    and (wro.available_until is null or wro.available_until > now())
    and v_plan = any(wro.eligible_plan_codes)
  group by wro.id
  order by wro.cost_points, wro.created_at desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.redeem_my_reward_offer(
  p_offer_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan text;
  v_offer public.wellness_reward_offers%rowtype;
  v_code public.wellness_reward_codes%rowtype;
  v_existing public.wellness_reward_redemptions%rowtype;
  v_redemption_id uuid := gen_random_uuid();
  v_subject_id uuid;
  v_wallet public.wellness_reward_wallets%rowtype;
  v_allocation record;
  v_needed integer;
  v_take integer;
  v_voucher_expires_at timestamptz;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if p_offer_id is null then
    raise exception using errcode = 'P0001', message = 'offer_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:redeem:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing
  from public.wellness_reward_redemptions wrr
  where wrr.user_id = v_user_id
    and wrr.idempotency_key = btrim(p_idempotency_key)
  for update;

  if v_existing.id is not null then
    if v_existing.offer_id <> p_offer_id then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    select * into v_code
    from public.wellness_reward_codes
    where id = v_existing.reward_code_id;
    return jsonb_build_object(
      'id', v_existing.id,
      'redemption_id', v_existing.id,
      'offer_id', v_existing.offer_id,
      'title', v_existing.offer_title_snapshot,
      'provider_name', v_existing.provider_name_snapshot,
      'points_spent', v_existing.points_spent,
      'status', v_existing.status,
      'voucher_code', case when v_existing.status = 'issued' then v_code.code_value else null end,
      'voucher_expires_at', v_existing.voucher_expires_at,
      'created_at', v_existing.created_at,
      'cancelled_at', v_existing.cancelled_at,
      'idempotent_replay', true
    );
  end if;

  select * into v_offer
  from public.wellness_reward_offers wro
  where wro.id = p_offer_id
  for update;

  if v_offer.id is null
     or not v_offer.is_active
     or (v_offer.available_from is not null and v_offer.available_from > now())
     or (v_offer.available_until is not null and v_offer.available_until <= now()) then
    raise exception using errcode = 'P0001', message = 'offer_unavailable';
  end if;

  v_plan := public.current_plan_for_user(v_user_id)::text;
  if not (v_plan = any(v_offer.eligible_plan_codes)) then
    raise exception using errcode = 'P0001', message = 'offer_ineligible';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  if v_wallet.available_points < v_offer.cost_points then
    raise exception using errcode = 'P0001', message = 'insufficient_points';
  end if;

  select * into v_code
  from public.wellness_reward_codes wrc
  where wrc.offer_id = v_offer.id
    and wrc.status = 'available'
    and coalesce(wrc.voucher_expires_at, v_offer.voucher_expires_at) > now()
  order by coalesce(wrc.voucher_expires_at, v_offer.voucher_expires_at), wrc.created_at
  for update skip locked
  limit 1;

  if v_code.id is null then
    raise exception using errcode = 'P0001', message = 'offer_out_of_stock';
  end if;

  v_voucher_expires_at := coalesce(v_code.voucher_expires_at, v_offer.voucher_expires_at);
  select hs.id into v_subject_id
  from public.health_subjects hs
  where hs.owner_user_id = v_user_id
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1;

  if v_subject_id is null then
    raise exception using errcode = 'P0001', message = 'health_subject_required';
  end if;

  insert into public.wellness_reward_redemptions (
    id,
    user_id,
    offer_id,
    reward_code_id,
    offer_title_snapshot,
    provider_name_snapshot,
    points_spent,
    voucher_expires_at,
    idempotency_key
  )
  values (
    v_redemption_id,
    v_user_id,
    v_offer.id,
    v_code.id,
    v_offer.title,
    v_offer.provider_name,
    v_offer.cost_points,
    v_voucher_expires_at,
    btrim(p_idempotency_key)
  );

  v_needed := v_offer.cost_points;
  for v_allocation in
    select wpa.id, wpa.remaining_points
    from public.wellness_point_allocations wpa
    where wpa.user_id = v_user_id
      and wpa.status = 'available'
      and wpa.remaining_points > 0
      and wpa.expires_at > now()
    order by wpa.expires_at, wpa.created_at, wpa.id
    for update
  loop
    exit when v_needed = 0;
    v_take := least(v_needed, v_allocation.remaining_points);

    insert into public.wellness_redemption_allocation_usages (
      redemption_id,
      allocation_id,
      points_used
    )
    values (v_redemption_id, v_allocation.id, v_take);

    update public.wellness_point_allocations
    set
      remaining_points = remaining_points - v_take,
      status = case when remaining_points - v_take = 0 then 'spent' else status end,
      updated_at = now()
    where id = v_allocation.id;

    v_needed := v_needed - v_take;
  end loop;

  if v_needed <> 0 then
    raise exception using errcode = 'P0001', message = 'wallet_allocation_mismatch';
  end if;

  update public.wellness_reward_codes
  set
    status = 'issued',
    assigned_user_id = v_user_id,
    assigned_redemption_id = v_redemption_id,
    issued_at = now()
  where id = v_code.id;

  insert into public.wellness_point_ledgers (
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    redemption_id,
    metadata
  )
  values (
    v_user_id,
    v_subject_id,
    'reward_redemption',
    v_redemption_id,
    (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    -v_offer.cost_points,
    'wellness_rewards_v2',
    'reward_redemption:' || v_redemption_id::text,
    'redemption',
    'redeemed',
    'Đổi ưu đãi: ' || v_offer.title,
    true,
    v_redemption_id,
    jsonb_build_object('offer_id', v_offer.id)
  );

  update public.wellness_reward_wallets
  set
    available_points = available_points - v_offer.cost_points,
    lifetime_spent_points = lifetime_spent_points + v_offer.cost_points,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  return jsonb_build_object(
    'id', v_redemption_id,
    'redemption_id', v_redemption_id,
    'offer_id', v_offer.id,
    'title', v_offer.title,
    'provider_name', v_offer.provider_name,
    'points_spent', v_offer.cost_points,
    'status', 'issued',
    'voucher_code', v_code.code_value,
    'voucher_expires_at', v_voucher_expires_at,
    'available_points', v_wallet.available_points,
    'created_at', now(),
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.list_my_reward_redemptions(
  p_limit integer default 100
)
returns table (
  id uuid,
  redemption_id uuid,
  offer_id uuid,
  title text,
  provider_name text,
  points_spent integer,
  status text,
  voucher_expires_at timestamptz,
  created_at timestamptz,
  cancelled_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  return query
  select
    wrr.id,
    wrr.id,
    wrr.offer_id,
    wrr.offer_title_snapshot,
    wrr.provider_name_snapshot,
    wrr.points_spent,
    wrr.status,
    wrr.voucher_expires_at,
    wrr.created_at,
    wrr.cancelled_at
  from public.wellness_reward_redemptions wrr
  where wrr.user_id = v_user_id
  order by wrr.created_at desc, wrr.id desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.get_my_reward_code(
  p_redemption_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_redemption public.wellness_reward_redemptions%rowtype;
  v_code public.wellness_reward_codes%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  select * into v_redemption
  from public.wellness_reward_redemptions wrr
  where wrr.id = p_redemption_id
    and wrr.user_id = v_user_id;

  if v_redemption.id is null then
    raise exception using errcode = 'P0001', message = 'redemption_not_found';
  end if;

  select * into v_code
  from public.wellness_reward_codes wrc
  where wrc.id = v_redemption.reward_code_id;

  return jsonb_build_object(
    'redemption_id', v_redemption.id,
    'status', v_redemption.status,
    'voucher_code', case when v_redemption.status = 'issued' then v_code.code_value else null end,
    'voucher_expires_at', v_redemption.voucher_expires_at
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 16E. Admin catalog, inventory, cancellation/refund and audit RPCs
-- ---------------------------------------------------------------------------

create or replace function public.admin_list_wellness_rewards(
  p_query text default '',
  p_limit integer default 100
)
returns table (
  item_type text,
  id uuid,
  offer_id uuid,
  redemption_id uuid,
  title text,
  description text,
  provider_name text,
  cost_points integer,
  points_spent integer,
  status text,
  is_active boolean,
  eligible_plan_codes text[],
  available_from timestamptz,
  available_until timestamptz,
  voucher_expires_at timestamptz,
  available_codes integer,
  issued_codes integer,
  retired_codes integer,
  user_id uuid,
  user_label text,
  masked_code text,
  created_at timestamptz,
  cancelled_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('wellness_rewards.read');

  return query
  with offer_rows as (
    select
      'offer'::text as item_type,
      wro.id,
      wro.id as offer_id,
      null::uuid as redemption_id,
      wro.title,
      wro.description,
      wro.provider_name,
      wro.cost_points,
      null::integer as points_spent,
      case when wro.is_active then 'active' else 'inactive' end::text as status,
      wro.is_active,
      wro.eligible_plan_codes,
      wro.available_from,
      wro.available_until,
      wro.voucher_expires_at,
      count(wrc.id) filter (
        where wrc.status = 'available'
          and coalesce(wrc.voucher_expires_at, wro.voucher_expires_at) > now()
      )::integer as available_codes,
      count(wrc.id) filter (where wrc.status = 'issued')::integer as issued_codes,
      count(wrc.id) filter (where wrc.status = 'retired')::integer as retired_codes,
      null::uuid as user_id,
      null::text as user_label,
      null::text as masked_code,
      wro.created_at,
      null::timestamptz as cancelled_at,
      wro.updated_at as sort_at
    from public.wellness_reward_offers wro
    left join public.wellness_reward_codes wrc on wrc.offer_id = wro.id
    where coalesce(btrim(p_query), '') = ''
       or wro.title ilike '%' || btrim(p_query) || '%'
       or wro.provider_name ilike '%' || btrim(p_query) || '%'
       or wro.offer_code ilike '%' || btrim(p_query) || '%'
    group by wro.id
  ),
  redemption_rows as (
    select
      'redemption'::text as item_type,
      wrr.id,
      wrr.offer_id,
      wrr.id as redemption_id,
      wrr.offer_title_snapshot as title,
      ''::text as description,
      wrr.provider_name_snapshot as provider_name,
      null::integer as cost_points,
      wrr.points_spent,
      wrr.status,
      true as is_active,
      array[]::text[] as eligible_plan_codes,
      null::timestamptz as available_from,
      null::timestamptz as available_until,
      wrr.voucher_expires_at,
      null::integer as available_codes,
      null::integer as issued_codes,
      null::integer as retired_codes,
      wrr.user_id,
      coalesce(
        nullif(u.full_name, ''),
        case
          when position('@' in coalesce(u.email, '')) > 1
            then left(u.email, 1) || '***' || substring(u.email from position('@' in u.email))
          else 'Tài khoản NanoBio'
        end
      ) as user_label,
      '••••••'::text as masked_code,
      wrr.created_at,
      wrr.cancelled_at,
      wrr.updated_at as sort_at
    from public.wellness_reward_redemptions wrr
    join public.users u on u.id = wrr.user_id
    where coalesce(btrim(p_query), '') = ''
       or wrr.offer_title_snapshot ilike '%' || btrim(p_query) || '%'
       or wrr.provider_name_snapshot ilike '%' || btrim(p_query) || '%'
       or coalesce(u.full_name, '') ilike '%' || btrim(p_query) || '%'
       or coalesce(u.email, '') ilike '%' || btrim(p_query) || '%'
  ),
  combined as (
    select * from offer_rows
    union all
    select * from redemption_rows
  )
  select
    c.item_type,
    c.id,
    c.offer_id,
    c.redemption_id,
    c.title,
    c.description,
    c.provider_name,
    c.cost_points,
    c.points_spent,
    c.status,
    c.is_active,
    c.eligible_plan_codes,
    c.available_from,
    c.available_until,
    c.voucher_expires_at,
    c.available_codes,
    c.issued_codes,
    c.retired_codes,
    c.user_id,
    c.user_label,
    c.masked_code,
    c.created_at,
    c.cancelled_at
  from combined c
  order by c.sort_at desc, c.id desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.admin_upsert_reward_offer(
  p_offer_id uuid,
  p_title text,
  p_description text,
  p_provider_name text,
  p_cost_points integer,
  p_eligible_plan_codes text[],
  p_available_from timestamptz,
  p_available_until timestamptz,
  p_voucher_expires_at timestamptz,
  p_is_active boolean,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_offer public.wellness_reward_offers%rowtype;
  v_new_id uuid := coalesce(p_offer_id, gen_random_uuid());
  v_existing_audit public.admin_audit_events%rowtype;
begin
  perform public.admin_assert_permission('wellness_rewards.write');

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'admin_reason_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:admin:upsert:' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing_audit
  from public.admin_audit_events aae
  where aae.action = 'admin_upsert_reward_offer'
    and aae.idempotency_key = btrim(p_idempotency_key);

  if v_existing_audit.id is not null then
    if p_offer_id is not null
       and v_existing_audit.target_id <> p_offer_id::text then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    select * into v_offer
    from public.wellness_reward_offers
    where id::text = v_existing_audit.target_id;
    return jsonb_build_object(
      'success', true,
      'message', 'Yêu cầu đã được xử lý trước đó.',
      'offer_id', v_offer.id,
      'accepted_count', 0,
      'duplicate_count', 0,
      'rejected_count', 0,
      'idempotent_replay', true
    );
  end if;

  if not public.reward_text_is_vietnamese(p_title)
     or not public.reward_text_is_vietnamese(p_description) then
    raise exception using errcode = 'P0001', message = 'invalid_vietnamese_copy';
  end if;
  if nullif(btrim(coalesce(p_provider_name, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'provider_name_required';
  end if;
  if p_cost_points is null or p_cost_points <= 0 then
    raise exception using errcode = 'P0001', message = 'reward_cost_invalid';
  end if;
  if p_eligible_plan_codes is null
     or cardinality(p_eligible_plan_codes) = 0
     or not (p_eligible_plan_codes <@ array['free', 'plus', 'family_plus']::text[]) then
    raise exception using errcode = 'P0001', message = 'eligible_plans_invalid';
  end if;
  if p_available_from is not null and p_available_until is not null
     and p_available_until <= p_available_from then
    raise exception using errcode = 'P0001', message = 'offer_window_invalid';
  end if;
  if p_voucher_expires_at is not null and p_voucher_expires_at <= now() then
    raise exception using errcode = 'P0001', message = 'voucher_expiry_invalid';
  end if;

  if p_offer_id is not null and not exists (
    select 1 from public.wellness_reward_offers where id = p_offer_id
  ) then
    raise exception using errcode = 'P0001', message = 'offer_not_found';
  end if;

  insert into public.wellness_reward_offers (
    id,
    offer_code,
    title,
    description,
    provider_name,
    cost_points,
    eligible_plan_codes,
    available_from,
    available_until,
    voucher_expires_at,
    is_active,
    created_by,
    updated_by
  )
  values (
    v_new_id,
    'reward_' || replace(v_new_id::text, '-', ''),
    btrim(p_title),
    btrim(p_description),
    btrim(p_provider_name),
    p_cost_points,
    array(select distinct lower(btrim(x)) from unnest(p_eligible_plan_codes) x order by 1),
    p_available_from,
    p_available_until,
    p_voucher_expires_at,
    coalesce(p_is_active, false),
    auth.uid(),
    auth.uid()
  )
  on conflict (id) do update
  set
    title = excluded.title,
    description = excluded.description,
    provider_name = excluded.provider_name,
    cost_points = excluded.cost_points,
    eligible_plan_codes = excluded.eligible_plan_codes,
    available_from = excluded.available_from,
    available_until = excluded.available_until,
    voucher_expires_at = excluded.voucher_expires_at,
    is_active = excluded.is_active,
    updated_by = auth.uid(),
    updated_at = now()
  returning * into v_offer;

  perform public.admin_write_audit(
    'admin_upsert_reward_offer',
    'wellness_reward_offer',
    v_offer.id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'is_active', v_offer.is_active,
      'cost_points', v_offer.cost_points,
      'eligible_plan_codes', v_offer.eligible_plan_codes,
      'voucher_expires_at', v_offer.voucher_expires_at
    )
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Đã lưu ưu đãi.',
    'offer_id', v_offer.id,
    'accepted_count', 1,
    'duplicate_count', 0,
    'rejected_count', 0,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.admin_import_reward_codes(
  p_offer_id uuid,
  p_codes text[],
  p_voucher_expires_at timestamptz,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_offer public.wellness_reward_offers%rowtype;
  v_existing_audit public.admin_audit_events%rowtype;
  v_expiry timestamptz;
  v_total integer;
  v_valid integer;
  v_accepted integer := 0;
  v_duplicate integer;
  v_rejected integer;
begin
  perform public.admin_assert_permission('wellness_rewards.write');

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'admin_reason_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:admin:import:' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing_audit
  from public.admin_audit_events aae
  where aae.action = 'admin_import_reward_codes'
    and aae.idempotency_key = btrim(p_idempotency_key);

  if v_existing_audit.id is not null then
    if v_existing_audit.target_id <> p_offer_id::text then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    return jsonb_build_object(
      'success', true,
      'message', 'Yêu cầu nhập mã đã được xử lý trước đó.',
      'offer_id', v_existing_audit.target_id,
      'accepted_count', coalesce((v_existing_audit.metadata ->> 'accepted_count')::integer, 0),
      'duplicate_count', coalesce((v_existing_audit.metadata ->> 'duplicate_count')::integer, 0),
      'rejected_count', coalesce((v_existing_audit.metadata ->> 'rejected_count')::integer, 0),
      'idempotent_replay', true
    );
  end if;

  select * into v_offer
  from public.wellness_reward_offers
  where id = p_offer_id
  for update;

  if v_offer.id is null then
    raise exception using errcode = 'P0001', message = 'offer_not_found';
  end if;

  v_total := coalesce(cardinality(p_codes), 0);
  if v_total < 1 or v_total > 1000 then
    raise exception using errcode = 'P0001', message = 'voucher_codes_count_invalid';
  end if;

  v_expiry := coalesce(p_voucher_expires_at, v_offer.voucher_expires_at);
  if v_expiry is null or v_expiry <= now() then
    raise exception using errcode = 'P0001', message = 'voucher_expiry_required';
  end if;

  select count(*)::integer
  into v_valid
  from unnest(p_codes) raw_code
  where btrim(coalesce(raw_code, '')) ~ '^[A-Za-z0-9][A-Za-z0-9_-]{3,127}$';

  v_rejected := v_total - v_valid;

  insert into public.wellness_reward_codes (
    offer_id,
    code_value,
    code_hash,
    voucher_expires_at,
    imported_by,
    import_batch_key
  )
  select
    v_offer.id,
    normalized.code_value,
    encode(digest(upper(normalized.code_value), 'sha256'), 'hex'),
    v_expiry,
    auth.uid(),
    btrim(p_idempotency_key)
  from (
    select distinct on (upper(btrim(raw_code))) btrim(raw_code) as code_value
    from unnest(p_codes) raw_code
    where btrim(coalesce(raw_code, '')) ~ '^[A-Za-z0-9][A-Za-z0-9_-]{3,127}$'
    order by upper(btrim(raw_code)), btrim(raw_code)
  ) normalized
  on conflict (code_hash) do nothing;

  get diagnostics v_accepted = row_count;
  v_duplicate := v_valid - v_accepted;

  perform public.admin_write_audit(
    'admin_import_reward_codes',
    'wellness_reward_offer',
    v_offer.id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'accepted_count', v_accepted,
      'duplicate_count', v_duplicate,
      'rejected_count', v_rejected,
      'voucher_expires_at', v_expiry,
      'raw_codes_logged', false
    )
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Đã xử lý kho mã ưu đãi.',
    'offer_id', v_offer.id,
    'accepted_count', v_accepted,
    'duplicate_count', v_duplicate,
    'rejected_count', v_rejected,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.admin_cancel_reward_redemption(
  p_redemption_id uuid,
  p_reason text,
  p_external_revocation_confirmed boolean,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_redemption public.wellness_reward_redemptions%rowtype;
  v_code public.wellness_reward_codes%rowtype;
  v_existing_audit public.admin_audit_events%rowtype;
  v_program record;
  v_subject_id uuid;
  v_ledger_id uuid := gen_random_uuid();
  v_allocation public.wellness_point_allocations%rowtype;
  v_allocation_id uuid := gen_random_uuid();
  v_wallet public.wellness_reward_wallets%rowtype;
begin
  perform public.admin_assert_permission('wellness_rewards.write');

  if p_redemption_id is null then
    raise exception using errcode = 'P0001', message = 'redemption_required';
  end if;
  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'admin_reason_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if not coalesce(p_external_revocation_confirmed, false) then
    raise exception using errcode = 'P0001', message = 'external_revocation_confirmation_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:admin:cancel:' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing_audit
  from public.admin_audit_events aae
  where aae.action = 'admin_cancel_reward_redemption'
    and aae.idempotency_key = btrim(p_idempotency_key);

  if v_existing_audit.id is not null then
    if v_existing_audit.target_id <> p_redemption_id::text then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    return jsonb_build_object(
      'success', true,
      'message', 'Giao dịch đã được hủy trước đó.',
      'redemption_id', p_redemption_id,
      'accepted_count', 0,
      'duplicate_count', 0,
      'rejected_count', 0,
      'idempotent_replay', true
    );
  end if;

  select * into v_redemption
  from public.wellness_reward_redemptions wrr
  where wrr.id = p_redemption_id
  for update;

  if v_redemption.id is null then
    raise exception using errcode = 'P0001', message = 'redemption_not_found';
  end if;

  if v_redemption.status = 'cancelled' then
    perform public.admin_write_audit(
      'admin_cancel_reward_redemption',
      'wellness_reward_redemption',
      v_redemption.id::text,
      p_reason,
      p_idempotency_key,
      jsonb_build_object(
        'already_cancelled', true,
        'refund_created', false,
        'external_revocation_confirmed', true
      )
    );
    return jsonb_build_object(
      'success', true,
      'message', 'Giao dịch đã ở trạng thái hủy.',
      'redemption_id', v_redemption.id,
      'accepted_count', 0,
      'duplicate_count', 0,
      'rejected_count', 0,
      'idempotent_replay', true
    );
  end if;

  select * into v_code
  from public.wellness_reward_codes wrc
  where wrc.id = v_redemption.reward_code_id
  for update;

  select hs.id into v_subject_id
  from public.health_subjects hs
  where hs.owner_user_id = v_redemption.user_id
    and hs.subject_type = 'self'
    and hs.is_active = true
  limit 1;

  if v_subject_id is null then
    raise exception using errcode = 'P0001', message = 'health_subject_required';
  end if;

  select * into v_program
  from public.current_wellness_reward_program();

  perform public.refresh_wellness_reward_wallet(v_redemption.user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_redemption.user_id
  for update;

  insert into public.wellness_point_ledgers (
    id,
    user_id,
    subject_id,
    source_type,
    source_id,
    schedule_date,
    points_delta,
    program_code,
    idempotency_key,
    event_type,
    status,
    title,
    is_redeemable,
    available_at,
    expires_at,
    program_config_id,
    redemption_id,
    metadata
  )
  values (
    v_ledger_id,
    v_redemption.user_id,
    v_subject_id,
    'reward_redemption_refund',
    v_redemption.id,
    (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    v_redemption.points_spent,
    v_program.contract_version,
    'reward_refund:' || v_redemption.id::text,
    'refund',
    'refunded',
    'Hoàn điểm ưu đãi: ' || v_redemption.offer_title_snapshot,
    true,
    now(),
    now() + make_interval(days => v_program.expiry_days),
    v_program.program_config_id,
    v_redemption.id,
    jsonb_build_object(
      'cancelled_by', auth.uid(),
      'external_revocation_confirmed', true
    )
  );

  insert into public.wellness_point_allocations (
    id,
    user_id,
    subject_id,
    ledger_id,
    source_type,
    source_id,
    original_points,
    remaining_points,
    status,
    available_at,
    expires_at,
    program_config_id
  )
  values (
    v_allocation_id,
    v_redemption.user_id,
    v_subject_id,
    v_ledger_id,
    'admin_refund',
    v_redemption.id,
    v_redemption.points_spent,
    v_redemption.points_spent,
    'available',
    now(),
    now() + make_interval(days => v_program.expiry_days),
    v_program.program_config_id
  )
  returning * into v_allocation;

  update public.wellness_reward_wallets
  set
    available_points = available_points + v_redemption.points_spent,
    lifetime_refunded_points = lifetime_refunded_points + v_redemption.points_spent,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_redemption.user_id
  returning * into v_wallet;

  update public.wellness_reward_codes
  set
    status = 'retired',
    retired_at = now()
  where id = v_code.id;

  update public.wellness_reward_redemptions
  set
    status = 'cancelled',
    cancelled_at = now(),
    cancelled_by = auth.uid(),
    cancellation_reason = btrim(p_reason),
    refund_allocation_id = v_allocation.id,
    updated_at = now()
  where id = v_redemption.id;

  perform public.admin_write_audit(
    'admin_cancel_reward_redemption',
    'wellness_reward_redemption',
    v_redemption.id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'external_revocation_confirmed', true,
      'code_restocked', false,
      'refund_points', v_redemption.points_spent,
      'refund_allocation_id', v_allocation.id,
      'refund_expires_at', v_allocation.expires_at
    )
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Đã hủy giao dịch và hoàn Điểm chăm sóc.',
    'redemption_id', v_redemption.id,
    'refund_points', v_redemption.points_spent,
    'available_points', v_wallet.available_points,
    'accepted_count', 1,
    'duplicate_count', 0,
    'rejected_count', 0,
    'idempotent_replay', false
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 16F. Mobile snapshot hardening
-- ---------------------------------------------------------------------------
-- The wellness ledger is intentionally absent from both the replacement list
-- and the client column whitelist. The app may pull the owner-scoped ledger as
-- a read-only projection, but snapshot push can neither insert nor delete it.

create or replace function public.sync_my_mobile_snapshot(p_snapshot jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_subject_id uuid;
  v_user jsonb := coalesce(p_snapshot -> 'user', '{}'::jsonb);
  v_tables jsonb := coalesce(p_snapshot -> 'tables', '{}'::jsonb);
  v_table text;
  v_row jsonb;
  v_authoritative_row jsonb;
  v_authoritative_schedule_rows jsonb := '[]'::jsonb;
  v_allowed_columns text[];
  v_rows integer := 0;
  v_collection_tables text[] := array[
    'health_goals',
    'health_conditions',
    'food_allergies',
    'medical_treatments',
    'survey_answers',
    'meal_plans',
    'daily_health_tasks',
    'lifestyle_schedule_items',
    'notifications',
    'health_tracking_logs',
    'health_score_ledgers',
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations'
  ];
  v_singleton_tables text[] := array['health_profiles', 'lifestyle_habits'];
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if coalesce(jsonb_typeof(p_snapshot), '') <> 'object'
     or coalesce(jsonb_typeof(v_tables), '') <> 'object' then
    raise exception 'INVALID_SNAPSHOT' using errcode = '22023';
  end if;

  select id into v_subject_id
  from public.health_subjects
  where owner_user_id = v_user_id
    and subject_type = 'self'
    and is_active = true
  limit 1;

  if v_subject_id is null then
    insert into public.health_subjects (
      owner_user_id, linked_user_id, subject_type, display_name, relationship
    )
    values (v_user_id, v_user_id, 'self', 'Bạn', 'self')
    on conflict (owner_user_id) where subject_type = 'self'
    do update set linked_user_id = excluded.linked_user_id, is_active = true
    returning id into v_subject_id;
  end if;

  update public.users
  set
    phone = coalesce(nullif(v_user ->> 'phone', ''), phone),
    full_name = coalesce(nullif(v_user ->> 'full_name', ''), full_name),
    avatar_url = coalesce(nullif(v_user ->> 'avatar_url', ''), avatar_url),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    onboarding_status = case
      when v_user ->> 'onboarding_status' = 'completed' then 'completed'::public.nb_onboarding_status
      when v_user ->> 'onboarding_status' = 'in_progress' then 'in_progress'::public.nb_onboarding_status
      else onboarding_status
    end,
    onboarding_completed_at = case
      when v_user ->> 'onboarding_status' = 'completed'
        then coalesce(nullif(v_user ->> 'onboarding_completed_at', '')::timestamptz, now())
      else onboarding_completed_at
    end,
    updated_at = now()
  where id = v_user_id;

  update public.health_subjects
  set
    display_name = coalesce(nullif(v_user ->> 'full_name', ''), display_name),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    updated_at = now()
  where id = v_subject_id;

  foreach v_table in array v_singleton_tables loop
    execute format(
      'delete from public.%I where user_id = $1 and subject_id = $2',
      v_table
    ) using v_user_id, v_subject_id;

    if v_table = 'health_profiles' then
      v_allowed_columns := array[
        'id', 'occupation', 'height_cm', 'weight_kg', 'bmi',
        'blood_pressure', 'blood_sugar'
      ];
    elsif v_table = 'lifestyle_habits' then
      v_allowed_columns := array[
        'id', 'skip_breakfast', 'eat_late', 'eat_sweet', 'eat_oily',
        'low_vegetable', 'low_water', 'fast_food', 'alcohol', 'coffee_high',
        'sleep_quality', 'activity_level', 'water_per_day'
      ];
    else
      raise exception 'UNSUPPORTED_SNAPSHOT_TABLE: %', v_table
        using errcode = '22023';
    end if;

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      perform public.insert_mobile_snapshot_row(
        v_table,
        v_user_id,
        v_subject_id,
        v_row,
        v_allowed_columns,
        true
      );
      v_rows := v_rows + 1;
    end loop;
  end loop;

  foreach v_table in array v_collection_tables loop
    if v_table = 'lifestyle_schedule_items' then
      -- Preserve every row already governed by server-issued eligibility.
      -- A stale device may omit the row entirely, so overlaying booleans after
      -- a destructive replace would otherwise be insufficient.
      select coalesce(jsonb_agg(to_jsonb(lsi) order by lsi.id), '[]'::jsonb)
      into v_authoritative_schedule_rows
      from public.lifestyle_schedule_items lsi
      where lsi.user_id = v_user_id
        and lsi.subject_id = v_subject_id
        and exists (
          select 1
          from public.schedule_reward_eligibilities sre
          where sre.user_id = v_user_id
            and sre.schedule_item_id = lsi.id
        );

      delete from public.lifestyle_schedule_items
      where user_id = v_user_id and subject_id = v_subject_id;
    elsif v_table = 'notifications' then
      execute 'delete from public.notifications where user_id = $1'
        using v_user_id;
    else
      execute format(
        'delete from public.%I where user_id = $1 and subject_id = $2',
        v_table
      ) using v_user_id, v_subject_id;
    end if;

    if v_table = 'health_goals' then
      v_allowed_columns := array['id', 'goal_code', 'goal_name', 'is_active'];
    elsif v_table = 'health_conditions' then
      v_allowed_columns := array[
        'id', 'condition_code', 'condition_name', 'severity_level'
      ];
    elsif v_table = 'food_allergies' then
      v_allowed_columns := array['id', 'allergy_name', 'note'];
    elsif v_table = 'medical_treatments' then
      v_allowed_columns := array[
        'id', 'treatment_name', 'medication_name', 'note'
      ];
    elsif v_table = 'survey_answers' then
      v_allowed_columns := array['id', 'question_code', 'answer_value'];
    elsif v_table = 'meal_plans' then
      v_allowed_columns := array[
        'id', 'plan_date', 'meal_type', 'meal_name', 'description', 'calories',
        'protein', 'carbs', 'fat', 'fiber', 'water_ml', 'meal_order',
        'start_time', 'end_time', 'cooking_instructions', 'is_completed',
        'ai_generated'
      ];
    elsif v_table = 'daily_health_tasks' then
      v_allowed_columns := array[
        'id', 'task_date', 'task_code', 'category', 'title', 'description',
        'target_value', 'current_value', 'unit', 'is_completed', 'sort_order',
        'source', 'encouragement'
      ];
    elsif v_table = 'lifestyle_schedule_items' then
      v_allowed_columns := array[
        'id', 'schedule_date', 'start_time', 'end_time', 'title', 'description',
        'category', 'source_type', 'source_id', 'target_value', 'current_value',
        'unit', 'is_completed', 'sort_order', 'ai_generated', 'encouragement'
      ];
    elsif v_table = 'notifications' then
      v_allowed_columns := array[
        'id', 'title', 'body', 'type', 'is_read', 'source_type', 'source_id',
        'scheduled_at', 'notification_id', 'action_status', 'responded_at', 'payload'
      ];
    elsif v_table = 'health_tracking_logs' then
      v_allowed_columns := array[
        'id', 'weight_kg', 'calories', 'water_ml', 'sleep_hours', 'stress_level',
        'steps_count', 'heart_rate_bpm', 'oxygen_saturation', 'daily_score',
        'mood', 'log_date'
      ];
    elsif v_table = 'health_score_ledgers' then
      v_allowed_columns := array[
        'id', 'period_start', 'period_end', 'score', 'formula_version',
        'breakdown', 'idempotency_key', 'calculated_at'
      ];
    elsif v_table = 'nutrition_logs' then
      v_allowed_columns := array[
        'id', 'food_name', 'calories', 'protein', 'carbs', 'fat', 'meal_type',
        'eaten_at'
      ];
    elsif v_table = 'ai_insights' then
      v_allowed_columns := array['id', 'insight_type', 'title', 'content', 'risk_level'];
    elsif v_table = 'ai_recommendations' then
      v_allowed_columns := array[
        'id', 'recommendation_type', 'title', 'description', 'action_text', 'is_read'
      ];
    else
      raise exception 'UNSUPPORTED_SNAPSHOT_TABLE: %', v_table
        using errcode = '22023';
    end if;

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      perform public.insert_mobile_snapshot_row(
        v_table,
        v_user_id,
        v_subject_id,
        v_row,
        v_allowed_columns,
        true
      );
      v_rows := v_rows + 1;
    end loop;

    if v_table = 'lifestyle_schedule_items' then
      -- Restore eligible rows omitted by this snapshot, then force immutable
      -- schedule snapshots and completion state from eligibility/proof. This
      -- makes a stale device push unable to undo a finalized completion or
      -- mutate a pinned Guest/Member manifest.
      for v_authoritative_row in
        select value
        from jsonb_array_elements(v_authoritative_schedule_rows)
      loop
        if not exists (
          select 1
          from public.lifestyle_schedule_items lsi
          where lsi.id = (v_authoritative_row ->> 'id')::uuid
            and lsi.user_id = v_user_id
        ) then
          perform public.insert_mobile_snapshot_row(
            'lifestyle_schedule_items',
            v_user_id,
            v_subject_id,
            v_authoritative_row,
            v_allowed_columns,
            true
          );
        end if;
      end loop;

      update public.lifestyle_schedule_items lsi
      set
        schedule_date = sre.schedule_date,
        start_time = sre.start_time,
        title = sre.title_snapshot,
        category = coalesce(sre.category_snapshot, lsi.category),
        source_type = sre.source_type_snapshot,
        source_id = sre.source_id_snapshot,
        ai_generated = true,
        is_completed = (
          sre.status = 'completed'
          and exists (
            select 1
            from public.schedule_completion_proofs scp
            where scp.eligibility_id = sre.id
              and scp.user_id = v_user_id
              and scp.status = 'active'
          )
        ),
        current_value = case
          when sre.status = 'completed'
           and exists (
             select 1
             from public.schedule_completion_proofs scp
             where scp.eligibility_id = sre.id
               and scp.user_id = v_user_id
               and scp.status = 'active'
           )
            then lsi.target_value
          else 0
        end,
        updated_at = now()
      from public.schedule_reward_eligibilities sre
      where lsi.user_id = v_user_id
        and lsi.subject_id = v_subject_id
        and sre.user_id = v_user_id
        and sre.schedule_item_id = lsi.id;
    end if;
  end loop;

  delete from public.personal_schedule_ai_requests where user_id = v_user_id;
  v_allowed_columns := array[
    'request_id', 'actor_mode', 'status', 'start_date', 'days', 'meal_count',
    'exercise_count', 'schedule_item_count', 'error_code', 'completed_at'
  ];

  for v_row in
    select value from jsonb_array_elements(
      coalesce(v_tables -> 'personal_schedule_ai_requests', '[]'::jsonb)
    )
  loop
    perform public.insert_mobile_snapshot_row(
      'personal_schedule_ai_requests',
      v_user_id,
      null,
      v_row,
      v_allowed_columns,
      false
    );
    v_rows := v_rows + 1;
  end loop;

  return jsonb_build_object(
    'user_id', v_user_id,
    'subject_id', v_subject_id,
    'synced_rows', v_rows,
    'synced_at', now(),
    'server_owned_tables', jsonb_build_array('wellness_point_ledgers')
  );
end;
$$;

revoke all on function public.wellness_rewards_feature_enabled()
from public, anon, authenticated;

revoke all on function public.register_my_schedule_reward_eligibilities(text, jsonb, text)
from public, anon;
revoke all on function public.begin_my_schedule_completion(uuid, text)
from public, anon;
revoke all on function public.finalize_my_schedule_completion(uuid, text, text)
from public, anon;
revoke all on function public.undo_my_schedule_completion(uuid, text)
from public, anon;
revoke all on function public.get_my_wellness_reward_summary()
from public, anon;
revoke all on function public.list_my_wellness_point_history(integer)
from public, anon;
revoke all on function public.list_my_reward_offers(integer)
from public, anon;
revoke all on function public.redeem_my_reward_offer(uuid, text)
from public, anon;
revoke all on function public.list_my_reward_redemptions(integer)
from public, anon;
revoke all on function public.get_my_reward_code(uuid)
from public, anon;
revoke all on function public.admin_list_wellness_rewards(text, integer)
from public, anon;
revoke all on function public.admin_upsert_reward_offer(
  uuid, text, text, text, integer, text[], timestamptz, timestamptz,
  timestamptz, boolean, text, text
)
from public, anon;
revoke all on function public.admin_import_reward_codes(
  uuid, text[], timestamptz, text, text
)
from public, anon;
revoke all on function public.admin_cancel_reward_redemption(
  uuid, text, boolean, text
)
from public, anon;

grant execute on function public.register_my_schedule_reward_eligibilities(text, jsonb, text)
to authenticated;
grant execute on function public.begin_my_schedule_completion(uuid, text)
to authenticated;
grant execute on function public.finalize_my_schedule_completion(uuid, text, text)
to authenticated;
grant execute on function public.undo_my_schedule_completion(uuid, text)
to authenticated;
grant execute on function public.get_my_wellness_reward_summary()
to authenticated;
grant execute on function public.list_my_wellness_point_history(integer)
to authenticated;
grant execute on function public.list_my_reward_offers(integer)
to authenticated;
grant execute on function public.redeem_my_reward_offer(uuid, text)
to authenticated;
grant execute on function public.list_my_reward_redemptions(integer)
to authenticated;
grant execute on function public.get_my_reward_code(uuid)
to authenticated;
grant execute on function public.admin_list_wellness_rewards(text, integer)
to authenticated;
grant execute on function public.admin_upsert_reward_offer(
  uuid, text, text, text, integer, text[], timestamptz, timestamptz,
  timestamptz, boolean, text, text
)
to authenticated;
grant execute on function public.admin_import_reward_codes(
  uuid, text[], timestamptz, text, text
)
to authenticated;
grant execute on function public.admin_cancel_reward_redemption(
  uuid, text, boolean, text
)
to authenticated;

commit;
