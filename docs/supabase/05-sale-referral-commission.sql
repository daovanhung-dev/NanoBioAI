-- Commit de xuat: docs(supabase): cap nhat sale referral direct-only
-- NanoBio / BioAI - Sale/referral, payment event and direct 10% commission draft.
-- Run after 01-core-auth-profile.sql and 03-membership-quota.sql.
-- Draft only: review in sandbox/staging before production migration.

begin;

create table if not exists public.sale_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  status public.nb_sale_status not null default 'pending',
  approved_at timestamptz,
  suspended_at timestamptz,
  closed_at timestamptz,
  terms_version text,
  terms_accepted_at timestamptz,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.referral_codes (
  code text primary key,
  sale_user_id uuid not null references public.sale_profiles(user_id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'revoked')),
  created_at timestamptz not null default now(),
  revoked_at timestamptz
);

create unique index if not exists idx_referral_codes_active_sale_user
  on public.referral_codes (sale_user_id)
  where status = 'active';

create table if not exists public.referral_relationships (
  id uuid primary key default gen_random_uuid(),
  referrer_user_id uuid not null references public.users(id) on delete restrict,
  referred_user_id uuid not null references public.users(id) on delete cascade,
  referral_code text references public.referral_codes(code) on delete set null,
  accepted_at timestamptz not null default now(),
  source text not null default 'signup'
    check (source in ('signup', 'manual_admin', 'migration')),
  status text not null default 'active'
    check (status in ('active', 'voided')),
  created_at timestamptz not null default now(),
  constraint referral_relationship_no_self
    check (referrer_user_id <> referred_user_id),
  unique (referred_user_id)
);

create index if not exists idx_referral_relationships_referrer
  on public.referral_relationships (referrer_user_id, created_at desc);

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  payer_user_id uuid not null references public.users(id) on delete restrict,
  subscription_id uuid references public.membership_subscriptions(id) on delete set null,
  plan_code public.nb_membership_plan not null,
  provider text not null,
  provider_event_id text not null,
  amount_cents integer not null check (amount_cents >= 0),
  currency text not null default 'VND',
  status text not null
    check (status in ('pending', 'succeeded', 'refunded', 'chargeback', 'failed')),
  paid_at timestamptz,
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  review_reason text,
  idempotency_key text,
  raw_event_hash text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (provider, provider_event_id)
);

create index if not exists idx_payment_events_payer_paid
  on public.payment_events (payer_user_id, paid_at desc);

create table if not exists public.commission_rates (
  code text primary key default 'direct_referral',
  rate numeric(5, 4) not null check (rate >= 0 and rate <= 1),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commission_records (
  id uuid primary key default gen_random_uuid(),
  payment_event_id uuid not null references public.payment_events(id) on delete cascade,
  receiver_user_id uuid not null references public.users(id) on delete restrict,
  payer_user_id uuid not null references public.users(id) on delete restrict,
  source_referral_id uuid references public.referral_relationships(id) on delete set null,
  rate numeric(5, 4) not null check (rate >= 0 and rate <= 1),
  amount_cents integer not null check (amount_cents >= 0),
  currency text not null default 'VND',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'reversed', 'paid')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (payment_event_id, receiver_user_id)
);

create index if not exists idx_commission_records_receiver_created
  on public.commission_records (receiver_user_id, created_at desc);

drop trigger if exists trg_sale_profiles_updated_at on public.sale_profiles;
create trigger trg_sale_profiles_updated_at
  before update on public.sale_profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_commission_rates_updated_at on public.commission_rates;
create trigger trg_commission_rates_updated_at
  before update on public.commission_rates
  for each row execute function public.set_updated_at();

drop trigger if exists trg_commission_records_updated_at on public.commission_records;
create trigger trg_commission_records_updated_at
  before update on public.commission_records
  for each row execute function public.set_updated_at();

create or replace function public.sync_user_sale_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'DELETE' then
    update public.users
    set sale_status = 'none', updated_at = now()
    where id = old.user_id;
    return old;
  end if;

  update public.users
  set sale_status = new.status, updated_at = now()
  where id = new.user_id;

  return new;
end;
$$;

drop trigger if exists trg_sale_profiles_sync_user on public.sale_profiles;
create trigger trg_sale_profiles_sync_user
  after insert or update or delete on public.sale_profiles
  for each row execute function public.sync_user_sale_status();

create or replace function public.create_commission_records_for_payment(
  p_payment_event_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.payment_events%rowtype;
  v_direct public.referral_relationships%rowtype;
  v_rate numeric(5, 4);
begin
  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
    and status = 'succeeded'
    and paid_at is not null;

  if not found then
    return;
  end if;

  select * into v_direct
  from public.referral_relationships
  where referred_user_id = v_payment.payer_user_id
    and status = 'active'
  limit 1;

  if not found then
    return;
  end if;

  select rate into v_rate
  from public.commission_rates
  where code = 'direct_referral' and is_active = true;

  if v_rate is null then
    return;
  end if;

  if exists (
    select 1 from public.sale_profiles
    where user_id = v_direct.referrer_user_id
      and status = 'active'
  ) then
    insert into public.commission_records (
      payment_event_id,
      receiver_user_id,
      payer_user_id,
      source_referral_id,
      rate,
      amount_cents,
      currency,
      status
    )
    values (
      v_payment.id,
      v_direct.referrer_user_id,
      v_payment.payer_user_id,
      v_direct.id,
      v_rate,
      round(v_payment.amount_cents * v_rate)::integer,
      v_payment.currency,
      'approved'
    )
    on conflict (payment_event_id, receiver_user_id) do nothing;
  end if;
end;
$$;

create or replace function public.handle_successful_payment_commission()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'succeeded' and new.paid_at is not null then
    perform public.create_commission_records_for_payment(new.id);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_payment_events_create_commission on public.payment_events;
create trigger trg_payment_events_create_commission
  after insert or update of status, paid_at on public.payment_events
  for each row execute function public.handle_successful_payment_commission();

alter table public.sale_profiles enable row level security;
alter table public.referral_codes enable row level security;
alter table public.referral_relationships enable row level security;
alter table public.payment_events enable row level security;
alter table public.commission_rates enable row level security;
alter table public.commission_records enable row level security;

drop policy if exists sale_profiles_select_own on public.sale_profiles;
create policy sale_profiles_select_own
  on public.sale_profiles for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists referral_codes_select_own on public.referral_codes;
create policy referral_codes_select_own
  on public.referral_codes for select to authenticated
  using (sale_user_id = (select auth.uid()));

drop policy if exists referral_relationships_select_related on public.referral_relationships;
create policy referral_relationships_select_related
  on public.referral_relationships for select to authenticated
  using (
    referrer_user_id = (select auth.uid())
    or referred_user_id = (select auth.uid())
  );

drop policy if exists payment_events_select_payer on public.payment_events;
create policy payment_events_select_payer
  on public.payment_events for select to authenticated
  using (payer_user_id = (select auth.uid()));

drop policy if exists commission_rates_read_authenticated on public.commission_rates;
create policy commission_rates_read_authenticated
  on public.commission_rates for select to authenticated
  using (is_active = true);

drop policy if exists commission_records_select_receiver on public.commission_records;
create policy commission_records_select_receiver
  on public.commission_records for select to authenticated
  using (receiver_user_id = (select auth.uid()));

grant select on
  public.sale_profiles,
  public.referral_codes,
  public.referral_relationships,
  public.payment_events,
  public.commission_rates,
  public.commission_records
to authenticated;

revoke insert, update, delete on
  public.sale_profiles,
  public.referral_codes,
  public.referral_relationships,
  public.payment_events,
  public.commission_rates,
  public.commission_records
from anon, authenticated;

commit;
