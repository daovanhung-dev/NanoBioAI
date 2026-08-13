-- NanoBio / BioAI - M13 membership payment QR rebuild.
-- Non-destructive migration for an existing Supabase environment.
-- Canonical flow:
-- mobile(plan, cycle, idempotency) -> Supabase reference generator -> payment row
-- -> trusted bank/amount/reference response -> Flutter renders VietQR locally.

begin;

create extension if not exists pgcrypto;

alter table public.payment_events
  add column if not exists transfer_reference text,
  add column if not exists transfer_memo text;

alter table public.payment_events
  drop constraint if exists payment_events_transfer_reference_format_check;
alter table public.payment_events
  add constraint payment_events_transfer_reference_format_check
  check (
    transfer_reference is null
    or transfer_reference ~ '^NB[0-9A-F]{12}$'
  );

create unique index if not exists uq_payment_events_transfer_reference
  on public.payment_events (transfer_reference)
  where transfer_reference is not null;

-- A user may have at most one active manual membership request. Historical
-- rows are preserved; duplicates must be remediated before this index is added.
do $$
begin
  if exists (
    select 1
    from public.payment_events pe
    where pe.provider = 'manual_membership_request'
      and pe.status in ('awaiting_transfer', 'pending_review')
    group by pe.payer_user_id
    having count(*) > 1
  ) then
    raise exception 'OPEN_MEMBERSHIP_PAYMENT_REQUEST_DUPLICATES_EXIST'
      using errcode = '22023';
  end if;
end;
$$;

create unique index if not exists uq_payment_events_one_open_manual_membership
  on public.payment_events (payer_user_id)
  where provider = 'manual_membership_request'
    and status in ('awaiting_transfer', 'pending_review');

-- Ensure canonical server-owned payment configuration exists. Existing active
-- config is never overwritten.
insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'membership_payment_prices',
  '{
    "currency": "VND",
    "prices": {
      "plus": {"monthly": 199000, "yearly": 1990000},
      "family_plus": {"monthly": 399000, "yearly": 3990000}
    }
  }'::jsonb,
  'active',
  'M13 canonical server-owned membership price table.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'membership_payment_prices'
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
  'membership_payment_bank',
  '{
    "bank_code": "VCB",
    "bank_name": "Vietcombank",
    "bank_bin": "970436",
    "bank_account_number": "1026806174",
    "bank_account_name": "LE PHU THACH",
    "bank_account_display_name": "Lê Phú Thạch"
  }'::jsonb,
  'active',
  'M13 canonical server-owned VietQR receiving account.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'membership_payment_bank'
    and status = 'active'
);

-- Private server helper. The client never calls this function directly.
create or replace function public.generate_membership_payment_reference()
returns text
language plpgsql
volatile
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_candidate text;
  v_attempt integer;
begin
  for v_attempt in 1..32 loop
    v_candidate := 'NB' || upper(encode(gen_random_bytes(6), 'hex'));

    if not exists (
      select 1
      from public.payment_events pe
      where pe.transfer_reference = v_candidate
    ) then
      return v_candidate;
    end if;
  end loop;

  raise exception 'MEMBERSHIP_PAYMENT_REFERENCE_GENERATION_FAILED'
    using errcode = 'P0001';
end;
$$;

revoke all on function public.generate_membership_payment_reference()
  from public, anon, authenticated;

-- Remove the old client-profile-dependent overloads before installing the
-- canonical three-argument RPC and a compatibility wrapper for older clients.
drop function if exists public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
);
drop function if exists public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
);

create function public.create_membership_payment_request(
  p_plan_code public.nb_membership_plan,
  p_billing_cycle text,
  p_idempotency_key text
)
returns table (
  payment_event_id uuid,
  plan_code text,
  billing_cycle text,
  payer_full_name text,
  status text,
  can_cancel boolean,
  amount_cents integer,
  currency text,
  transfer_reference text,
  transfer_memo text,
  bank_code text,
  bank_name text,
  bank_bin text,
  bank_account_number text,
  bank_account_name text,
  bank_account_display_name text,
  transfer_confirmed_at timestamptz,
  review_reason text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_billing_cycle text;
  v_idempotency_key text;
  v_provider constant text := 'manual_membership_request';
  v_provider_event_id text;
  v_payer_full_name text;
  v_price_config jsonb;
  v_bank_config jsonb;
  v_amount_cents integer;
  v_currency text;
  v_bank_code text;
  v_bank_name text;
  v_bank_bin text;
  v_bank_account_number text;
  v_bank_account_name text;
  v_bank_account_display_name text;
  v_transfer_reference text;
  v_attempt integer := 0;
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if p_plan_code not in ('plus', 'family_plus') then
    raise exception 'INVALID_MEMBERSHIP_PLAN' using errcode = '22023';
  end if;

  v_billing_cycle := lower(btrim(coalesce(p_billing_cycle, '')));
  if v_billing_cycle not in ('monthly', 'yearly') then
    raise exception 'INVALID_BILLING_CYCLE' using errcode = '22023';
  end if;

  v_idempotency_key := btrim(coalesce(p_idempotency_key, ''));
  if v_idempotency_key = '' then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED' using errcode = '22023';
  end if;

  -- Serialize all create/retry/open-request decisions for one payer and read
  -- payer metadata from Supabase. A missing full name never blocks QR creation.
  select nullif(btrim(u.full_name), '')
  into v_payer_full_name
  from public.users u
  where u.id = v_user_id
  for update;

  if not found then
    raise exception 'USER_PROFILE_NOT_FOUND' using errcode = '22023';
  end if;

  v_provider_event_id := concat(v_user_id::text, ':', v_idempotency_key);

  -- Same idempotency key always returns the same financial request.
  select *
  into v_payment
  from public.payment_events pe
  where pe.provider = v_provider
    and pe.provider_event_id = v_provider_event_id
  for update;

  if not found then
    -- A different create attempt while another request is open returns that
    -- request rather than failing the UI or generating another reference.
    select *
    into v_payment
    from public.payment_events pe
    where pe.payer_user_id = v_user_id
      and pe.provider = v_provider
      and pe.status in ('awaiting_transfer', 'pending_review')
    order by pe.created_at desc
    limit 1
    for update;
  end if;

  if not found then
    select scv.config_value
    into v_price_config
    from public.system_config_versions scv
    where scv.config_key = 'membership_payment_prices'
      and scv.status = 'active'
    order by scv.created_at desc
    limit 1;

    v_amount_cents := nullif(
      v_price_config #>> array['prices', p_plan_code::text, v_billing_cycle],
      ''
    )::integer;
    v_currency := upper(coalesce(nullif(v_price_config ->> 'currency', ''), ''));

    if v_amount_cents is null or v_amount_cents <= 0 or v_currency <> 'VND' then
      raise exception 'MEMBERSHIP_PAYMENT_PRICE_NOT_CONFIGURED'
        using errcode = '22023';
    end if;

    select scv.config_value
    into v_bank_config
    from public.system_config_versions scv
    where scv.config_key = 'membership_payment_bank'
      and scv.status = 'active'
    order by scv.created_at desc
    limit 1;

    v_bank_code := upper(btrim(coalesce(v_bank_config ->> 'bank_code', '')));
    v_bank_name := btrim(coalesce(v_bank_config ->> 'bank_name', ''));
    v_bank_bin := btrim(coalesce(v_bank_config ->> 'bank_bin', ''));
    v_bank_account_number := btrim(
      coalesce(v_bank_config ->> 'bank_account_number', '')
    );
    v_bank_account_name := upper(btrim(
      coalesce(v_bank_config ->> 'bank_account_name', '')
    ));
    v_bank_account_display_name := btrim(
      coalesce(v_bank_config ->> 'bank_account_display_name', '')
    );

    if v_bank_code = ''
      or v_bank_name = ''
      or v_bank_bin !~ '^[0-9]{6}$'
      or v_bank_account_number !~ '^[0-9]{4,32}$'
      or v_bank_account_name = ''
      or v_bank_account_display_name = '' then
      raise exception 'MEMBERSHIP_PAYMENT_BANK_NOT_CONFIGURED'
        using errcode = '22023';
    end if;

    loop
      v_attempt := v_attempt + 1;
      v_transfer_reference := public.generate_membership_payment_reference();

      begin
        insert into public.payment_events (
          payer_user_id,
          plan_code,
          provider,
          provider_event_id,
          amount_cents,
          list_price_cents,
          commission_base_cents,
          currency,
          status,
          transfer_reference,
          transfer_memo,
          idempotency_key,
          metadata
        )
        values (
          v_user_id,
          p_plan_code,
          v_provider,
          v_provider_event_id,
          v_amount_cents,
          v_amount_cents,
          v_amount_cents,
          v_currency,
          'awaiting_transfer',
          v_transfer_reference,
          v_transfer_reference,
          v_idempotency_key,
          jsonb_build_object(
            'billing_cycle', v_billing_cycle,
            'payer_full_name', v_payer_full_name,
            'manual_approval_required', true,
            'grants_access_before_approval', false,
            'transfer_reference', v_transfer_reference,
            'transfer_memo', v_transfer_reference,
            'transfer_memo_contract', 'reference_only_v3',
            'bank', jsonb_build_object(
              'bank_code', v_bank_code,
              'bank_name', v_bank_name,
              'bank_bin', v_bank_bin,
              'bank_account_number', v_bank_account_number,
              'bank_account_name', v_bank_account_name,
              'bank_account_display_name', v_bank_account_display_name
            )
          )
        )
        returning * into v_payment;
        exit;
      exception
        when unique_violation then
          if v_attempt >= 8 then
            raise;
          end if;
      end;
    end loop;
  end if;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    coalesce(v_payment.metadata ->> 'billing_cycle', v_billing_cycle),
    nullif(v_payment.metadata ->> 'payer_full_name', ''),
    v_payment.status,
    v_payment.status = 'awaiting_transfer',
    v_payment.amount_cents,
    v_payment.currency,
    v_payment.transfer_reference,
    v_payment.transfer_memo,
    nullif(v_payment.metadata #>> '{bank,bank_code}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_name}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_bin}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_number}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_name}', ''),
    nullif(v_payment.metadata #>> '{bank,bank_account_display_name}', ''),
    nullif(v_payment.metadata ->> 'transfer_confirmed_at', '')::timestamptz,
    nullif(v_payment.review_reason, ''),
    v_payment.created_at;
end;
$$;

-- Compatibility adapter for an older app build. The supplied payer name is
-- ignored; the canonical three-argument function reads trusted profile data.
create function public.create_membership_payment_request(
  p_plan_code public.nb_membership_plan,
  p_billing_cycle text,
  p_idempotency_key text,
  p_payer_full_name text
)
returns table (
  payment_event_id uuid,
  plan_code text,
  billing_cycle text,
  payer_full_name text,
  status text,
  can_cancel boolean,
  amount_cents integer,
  currency text,
  transfer_reference text,
  transfer_memo text,
  bank_code text,
  bank_name text,
  bank_bin text,
  bank_account_number text,
  bank_account_name text,
  bank_account_display_name text,
  transfer_confirmed_at timestamptz,
  review_reason text,
  created_at timestamptz
)
language sql
security definer
set search_path = public, extensions, pg_temp
as $$
  select *
  from public.create_membership_payment_request(
    p_plan_code,
    p_billing_cycle,
    p_idempotency_key
  )
$$;

revoke all on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
) from public, anon;
revoke all on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
) from public, anon;

grant execute on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
) to authenticated;
grant execute on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
) to authenticated;

comment on function public.generate_membership_payment_reference() is
  'Private M13 generator: NB + 12 uppercase hexadecimal characters.';
comment on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
) is
  'Canonical M13 create RPC. Client sends plan/cycle/idempotency only.';

commit;
