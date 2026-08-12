-- NanoBio / BioAI - M13 VietQR membership payment hardening.
-- Non-destructive migration for environments that previously applied the
-- manual membership request contract. Run in sandbox/staging before any
-- production rollout. It never guesses legacy paid-expiry dates; an active
-- paid subscription with NULL ends_at blocks approval until remediated.

begin;

alter table public.payment_events
  add column if not exists transfer_reference text,
  add column if not exists transfer_memo text;

alter table public.payment_events
  drop constraint if exists payment_events_status_check;

alter table public.payment_events
  add constraint payment_events_status_check
  check (
    status in (
      'awaiting_transfer',
      'pending_review',
      'pending',
      'succeeded',
      'refunded',
      'chargeback',
      'failed',
      'canceled'
    )
  );

alter table public.payment_events
  drop constraint if exists payment_events_transfer_reference_format_check;
alter table public.payment_events
  add constraint payment_events_transfer_reference_format_check
  check (
    transfer_reference is null
    or transfer_reference ~ '^NB[0-9A-F]{12}$'
  );

-- Preserve historical transfer evidence without changing its stored memo.
-- All requests created by the V2 contract below carry reference_only_v2 and
-- must have an exact NB reference as their transfer memo.
update public.payment_events
set metadata = metadata || jsonb_build_object(
  'transfer_memo_contract',
  'legacy_preserved'
)
where provider = 'manual_membership_request'
  and transfer_memo is distinct from transfer_reference
  and coalesce(metadata ->> 'transfer_memo_contract', '') = '';

alter table public.payment_events
  drop constraint if exists payment_events_transfer_memo_format_check;
alter table public.payment_events
  add constraint payment_events_transfer_memo_format_check
  check (
    provider <> 'manual_membership_request'
    or (transfer_reference is null and transfer_memo is null)
    or coalesce(metadata ->> 'transfer_memo_contract', '') = 'legacy_preserved'
    or (
      transfer_reference ~ '^NB[0-9A-F]{12}$'
      and transfer_memo = transfer_reference
    )
  );

create unique index if not exists uq_payment_events_transfer_reference
  on public.payment_events (transfer_reference)
  where transfer_reference is not null;

-- Do not silently discard or reclassify financial requests during migration.
-- A duplicate requires controlled Finance remediation before this index can be
-- installed on a long-lived environment.
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
      using errcode = '22023',
        hint = 'Resolve duplicate awaiting_transfer/pending_review requests before applying this contract.';
  end if;
end;
$$;

create unique index if not exists uq_payment_events_one_open_manual_membership
  on public.payment_events (payer_user_id)
  where provider = 'manual_membership_request'
    and status in ('awaiting_transfer', 'pending_review');

-- `payments.write` historically used wildcard grants for every Admin role.
-- Payment review is intentionally stricter: only active Finance/Super roles
-- retain this capability, including callers of legacy payment RPCs.
create or replace function public.admin_has_payment_reviewer_role()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.admin_user_roles aur
    join public.admin_roles ar
      on ar.code = aur.role_code
     and ar.is_active = true
    join public.admin_role_permissions arp
      on arp.role_code = aur.role_code
    join public.admin_permissions ap
      on ap.code = arp.permission_code
     and ap.is_active = true
    where aur.user_id = auth.uid()
      and aur.is_active = true
      and aur.revoked_at is null
      and aur.role_code in ('finance_admin', 'super_admin')
      and ap.code in ('payments.write', '*')
  )
$$;

create or replace function public.admin_has_permission(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when p_permission = 'payments.write'
      then public.admin_has_payment_reviewer_role()
    else exists (
      select 1
      from public.admin_user_roles aur
      join public.admin_roles ar
        on ar.code = aur.role_code
       and ar.is_active = true
      join public.admin_role_permissions arp
        on arp.role_code = aur.role_code
      join public.admin_permissions ap
        on ap.code = arp.permission_code
       and ap.is_active = true
      where aur.user_id = auth.uid()
        and aur.is_active = true
        and aur.revoked_at is null
        and (ap.code = '*' or ap.code = p_permission)
    )
  end
$$;

create or replace function public.admin_assert_payment_reviewer()
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not public.admin_has_payment_reviewer_role() then
    raise exception 'PAYMENT_REVIEWER_ROLE_REQUIRED' using errcode = '42501';
  end if;
end;
$$;

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
drop function if exists public.confirm_my_membership_payment_transfer(uuid);
drop function if exists public.cancel_my_membership_payment_request(uuid);
drop function if exists public.get_my_membership_payment_request();
drop function if exists public.admin_get_payment_review_alert();
drop function if exists public.admin_list_payments(text, integer);
drop function if exists public.admin_review_payment(uuid, text, text, text);

create or replace function public.create_membership_payment_request(
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
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_price_config jsonb;
  v_bank_config jsonb;
  v_billing_cycle text;
  v_amount_cents integer;
  v_currency text;
  v_provider text := 'manual_membership_request';
  v_provider_event_id text;
  v_payer_full_name text;
  v_bank_code text;
  v_bank_name text;
  v_bank_bin text;
  v_bank_account_number text;
  v_bank_account_name text;
  v_bank_account_display_name text;
  v_transfer_reference text;
  v_transfer_memo text;
  v_attempt integer := 0;
  v_payment public.payment_events%rowtype;
  v_open_payment public.payment_events%rowtype;
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

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED' using errcode = '22023';
  end if;

  v_payer_full_name := btrim(coalesce(p_payer_full_name, ''));
  if v_payer_full_name = '' then
    raise exception 'PAYER_FULL_NAME_REQUIRED' using errcode = '22023';
  end if;

  -- Serialize create/retry/cancel transitions per payer. The partial unique
  -- index below remains the final concurrency backstop across sessions.
  perform 1
  from public.users u
  where u.id = v_user_id
  for update;

  if not found then
    raise exception 'USER_PROFILE_NOT_FOUND' using errcode = '22023';
  end if;

  v_provider_event_id := concat(v_user_id::text, ':', btrim(p_idempotency_key));

  select *
  into v_payment
  from public.payment_events pe
  where pe.provider = v_provider
    and pe.provider_event_id = v_provider_event_id
  for update;

  if found then
    update public.payment_events
    set metadata = metadata || jsonb_build_object('idempotent_replay', true)
    where id = v_payment.id
    returning * into v_payment;
  else
    select *
    into v_open_payment
    from public.payment_events pe
    where pe.payer_user_id = v_user_id
      and pe.provider = v_provider
      and pe.status in ('awaiting_transfer', 'pending_review')
    for update;

    if found then
      raise exception 'MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN'
        using errcode = 'P0001',
          hint = 'Load the current membership payment request instead of creating another one.';
    end if;

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
    v_bank_account_name := btrim(
      coalesce(v_bank_config ->> 'bank_account_name', '')
    );
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
      v_transfer_reference := concat(
        'NB',
        upper(encode(gen_random_bytes(6), 'hex'))
      );
      -- VietQR content must be the immutable NB reconciliation key only.
      v_transfer_memo := v_transfer_reference;

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
          v_transfer_memo,
          btrim(p_idempotency_key),
          jsonb_build_object(
            'billing_cycle', v_billing_cycle,
            'payer_full_name', v_payer_full_name,
            'manual_approval_required', true,
            'grants_access_before_approval', false,
            'transfer_reference', v_transfer_reference,
            'transfer_memo', v_transfer_memo,
            'transfer_memo_contract', 'reference_only_v2',
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
          -- The user row lock makes an open-request conflict impossible here;
          -- this loop only retries an extremely unlikely NB reference collision.
          select *
          into v_payment
          from public.payment_events pe
          where pe.provider = v_provider
            and pe.provider_event_id = v_provider_event_id
          for update;

          if found then
            update public.payment_events
            set metadata = metadata || jsonb_build_object('idempotent_replay', true)
            where id = v_payment.id
            returning * into v_payment;
            exit;
          end if;

          if v_attempt >= 5 then
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

create or replace function public.confirm_my_membership_payment_transfer(
  p_payment_event_id uuid
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
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_provider text := 'manual_membership_request';
  v_confirmed_at timestamptz;
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  select *
  into v_payment
  from public.payment_events pe
  where pe.id = p_payment_event_id
    and pe.payer_user_id = v_user_id
    and pe.provider = v_provider
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if v_payment.status = 'awaiting_transfer' then
    if v_payment.transfer_reference is null
      or v_payment.transfer_memo is distinct from v_payment.transfer_reference then
      raise exception 'PAYMENT_TRANSFER_DETAILS_MISSING' using errcode = '22023';
    end if;

    v_confirmed_at := now();
    update public.payment_events
    set
      status = 'pending_review',
      metadata = metadata || jsonb_build_object(
        'transfer_confirmed_at', v_confirmed_at,
        'transfer_confirmation', jsonb_build_object(
          'confirmed_at', v_confirmed_at,
          'confirmed_by_user_id', v_user_id,
          'transfer_reference', transfer_reference,
          'transfer_memo', transfer_memo,
          'bank', metadata -> 'bank'
        )
      )
    where id = v_payment.id
    returning * into v_payment;
  elsif v_payment.status <> 'pending_review' then
    raise exception 'PAYMENT_TRANSFER_NOT_AWAITING_CONFIRMATION'
      using errcode = '22023';
  end if;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    v_payment.metadata ->> 'billing_cycle',
    nullif(v_payment.metadata ->> 'payer_full_name', ''),
    v_payment.status,
    false,
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

create or replace function public.cancel_my_membership_payment_request(
  p_payment_event_id uuid
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
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_provider text := 'manual_membership_request';
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  select *
  into v_payment
  from public.payment_events pe
  where pe.id = p_payment_event_id
    and pe.payer_user_id = v_user_id
    and pe.provider = v_provider
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if v_payment.status = 'awaiting_transfer' then
    update public.payment_events
    set
      status = 'canceled',
      metadata = metadata || jsonb_build_object(
        'canceled_at', now(),
        'canceled_by_user_id', v_user_id,
        'cancellation_reason', 'user_canceled_before_transfer'
      )
    where id = v_payment.id
    returning * into v_payment;
  elsif v_payment.status <> 'canceled' then
    raise exception 'PAYMENT_CANCELLATION_NOT_ALLOWED'
      using errcode = '22023';
  end if;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    v_payment.metadata ->> 'billing_cycle',
    nullif(v_payment.metadata ->> 'payer_full_name', ''),
    v_payment.status,
    false,
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

create or replace function public.get_my_membership_payment_request()
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
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_provider text := 'manual_membership_request';
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  select *
  into v_payment
  from public.payment_events pe
  where pe.payer_user_id = v_user_id
    and pe.provider = v_provider
  order by
    case
      when pe.status in ('awaiting_transfer', 'pending_review', 'pending') then 0
      else 1
    end,
    pe.created_at desc
  limit 1;

  if not found then
    return;
  end if;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    v_payment.metadata ->> 'billing_cycle',
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

-- Only Finance/Super can observe customer-confirmed transfers waiting for
-- reconciliation. This is independent of the historical wildcard mapping.
create or replace function public.admin_get_payment_review_alert()
returns table (pending_review_count integer)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_payment_reviewer();

  return query
  select count(*)::integer
  from public.payment_events pe
  where pe.status = 'pending_review';
end;
$$;

drop function if exists public.admin_list_payments(text, integer);

create or replace function public.admin_list_payments(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz,
  transfer_reference text,
  transfer_memo text,
  payer_full_name text,
  plan_code text,
  billing_cycle text,
  amount_cents integer,
  currency text,
  transfer_confirmed_at timestamptz,
  review_reason text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_payment_reviewer();

  return query
  select
    pe.id::text,
    concat(
      pe.plan_code::text,
      ' - ',
      coalesce(nullif(pe.metadata ->> 'billing_cycle', ''), 'unknown'),
      ' - ',
      pe.amount_cents::text,
      ' ',
      pe.currency
    ),
    concat_ws(
      ' - ',
      coalesce(
        nullif(pe.metadata ->> 'payer_full_name', ''),
        nullif(u.full_name, ''),
        u.email,
        pe.payer_user_id::text
      ),
      pe.provider,
      pe.transfer_reference
    ),
    pe.status,
    'payments',
    pe.created_at,
    pe.transfer_reference,
    pe.transfer_memo,
    coalesce(
      nullif(pe.metadata ->> 'payer_full_name', ''),
      nullif(u.full_name, ''),
      u.email,
      pe.payer_user_id::text
    ),
    pe.plan_code::text,
    nullif(pe.metadata ->> 'billing_cycle', ''),
    pe.amount_cents,
    pe.currency,
    nullif(pe.metadata ->> 'transfer_confirmed_at', '')::timestamptz,
    nullif(pe.review_reason, '')
  from public.payment_events pe
  join public.users u on u.id = pe.payer_user_id
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or pe.provider_event_id ilike '%' || p_query || '%'
     or pe.transfer_reference ilike '%' || p_query || '%'
     or pe.transfer_memo ilike '%' || p_query || '%'
     or coalesce(pe.metadata ->> 'payer_full_name', '') ilike '%' || p_query || '%'
  order by
    case
      when pe.status = 'pending_review' then 0
      when pe.status = 'pending' then 1
      else 2
    end,
    pe.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

drop function if exists public.admin_review_payment(uuid, text, text, text);

create or replace function public.admin_review_payment(
  p_payment_event_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text,
  p_transfer_verified boolean
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_payment public.payment_events%rowtype;
  v_existing_subscription public.membership_subscriptions%rowtype;
  v_payer_user_id uuid;
  v_legacy_subscription_id uuid;
  v_subscription_id uuid := gen_random_uuid();
  v_switched_subscription_ids uuid[] := array[]::uuid[];
  v_decision text := lower(btrim(coalesce(p_decision, '')));
  v_billing_cycle text;
  v_reviewed_at timestamptz := now();
  v_period_start timestamptz;
  v_period_end timestamptz;
  v_transition text;
begin
  perform public.admin_assert_payment_reviewer();

  if v_decision not in ('approve', 'reject') then
    raise exception 'INVALID_PAYMENT_DECISION' using errcode = '22023';
  end if;

  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception 'PAYMENT_REVIEW_REASON_REQUIRED' using errcode = '22023';
  end if;

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED' using errcode = '22023';
  end if;

  if v_decision = 'approve' and p_transfer_verified is distinct from true then
    raise exception 'PAYMENT_TRANSFER_RECONCILIATION_REQUIRED'
      using errcode = '22023';
  end if;

  -- Lock the payer before the payment row so parallel approvals and request
  -- creation serialize on the same user.
  select pe.payer_user_id
  into v_payer_user_id
  from public.payment_events pe
  where pe.id = p_payment_event_id;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  perform 1
  from public.users u
  where u.id = v_payer_user_id
  for update;

  select *
  into v_payment
  from public.payment_events pe
  where pe.id = p_payment_event_id
  for update;

  if v_payment.status in ('succeeded', 'failed') then
    if v_payment.metadata ->> 'admin_decision' = v_decision then
      return query select true, 'Payment da duoc xu ly truoc do.';
      return;
    end if;

    raise exception 'PAYMENT_ALREADY_REVIEWED' using errcode = '22023';
  end if;

  -- Historical `pending` payments remain reviewable, but must include the
  -- billing-cycle snapshot required for finite, auditable access periods.
  if v_payment.status not in ('pending_review', 'pending') then
    raise exception 'PAYMENT_NOT_READY_FOR_REVIEW' using errcode = '22023';
  end if;

  v_billing_cycle := lower(btrim(coalesce(
    v_payment.metadata ->> 'billing_cycle',
    ''
  )));
  if v_billing_cycle not in ('monthly', 'yearly') then
    raise exception 'PAYMENT_BILLING_CYCLE_MISSING' using errcode = '22023';
  end if;

  if v_decision = 'approve' then
    -- Never infer an expiry for old paid access. A controlled data migration
    -- must repair it before a new approval can change the user's plan.
    select ms.id
    into v_legacy_subscription_id
    from public.membership_subscriptions ms
    where ms.user_id = v_payment.payer_user_id
      and ms.plan_code in ('plus', 'family_plus')
      and ms.status in ('trialing', 'active')
      and ms.starts_at <= v_reviewed_at
      and ms.ends_at is null
    limit 1
    for update;

    if found then
      raise exception 'LEGACY_PAID_SUBSCRIPTION_MISSING_ENDS_AT'
        using errcode = '22023',
          hint = 'Repair the legacy paid subscription with a controlled migration before approving another package.';
    end if;

    -- A cross-plan purchase is an immediate switch. Each superseded record is
    -- linked to the new payment/subscription for both user history and audit.
    with switched as (
      update public.membership_subscriptions ms
      set
        status = 'canceled',
        -- Keep the row's period constraint valid even for a legacy record
        -- that started at exactly v_reviewed_at. Its canceled status removes
        -- access immediately; the microsecond is schema-only bookkeeping.
        ends_at = greatest(
          v_reviewed_at,
          ms.starts_at + interval '1 microsecond'
        ),
        current_period_end = greatest(
          v_reviewed_at,
          ms.starts_at + interval '1 microsecond'
        ),
        metadata = ms.metadata || jsonb_build_object(
          'superseded_at', v_reviewed_at,
          'superseded_by_payment_event_id', v_payment.id,
          'superseded_by_subscription_id', v_subscription_id,
          'superseded_by_plan_code', v_payment.plan_code::text
        )
      where ms.user_id = v_payment.payer_user_id
        and ms.plan_code in ('plus', 'family_plus')
        and ms.plan_code <> v_payment.plan_code
        and ms.status in ('trialing', 'active')
        and ms.starts_at <= v_reviewed_at
        and ms.ends_at > v_reviewed_at
      returning ms.id
    )
    select coalesce(array_agg(id), array[]::uuid[])
    into v_switched_subscription_ids
    from switched;

    select *
    into v_existing_subscription
    from public.membership_subscriptions ms
    where ms.user_id = v_payment.payer_user_id
      and ms.plan_code = v_payment.plan_code
      and ms.status in ('trialing', 'active')
      and ms.starts_at <= v_reviewed_at
      and ms.ends_at > v_reviewed_at
    order by ms.ends_at desc, ms.starts_at desc
    limit 1
    for update;

    if found then
      v_period_start := v_existing_subscription.ends_at;
      v_transition := 'same_plan_renewal';
    else
      v_period_start := v_reviewed_at;
      v_transition := case
        when cardinality(v_switched_subscription_ids) > 0 then 'plan_switch'
        else 'new_subscription'
      end;
    end if;

    v_period_end := case v_billing_cycle
      when 'monthly' then (
        (v_period_start at time zone 'Asia/Ho_Chi_Minh') + interval '1 month'
      ) at time zone 'Asia/Ho_Chi_Minh'
      when 'yearly' then (
        (v_period_start at time zone 'Asia/Ho_Chi_Minh') + interval '1 year'
      ) at time zone 'Asia/Ho_Chi_Minh'
    end;

    if v_transition = 'same_plan_renewal' then
      v_subscription_id := v_existing_subscription.id;

      update public.membership_subscriptions
      set
        ends_at = v_period_end,
        current_period_start = v_period_start,
        current_period_end = v_period_end,
        metadata = metadata || jsonb_build_object(
          'last_membership_payment_event_id', v_payment.id,
          'last_billing_cycle', v_billing_cycle,
          'last_renewed_at', v_reviewed_at
        )
      where id = v_subscription_id;
    else
      insert into public.membership_subscriptions (
        id,
        user_id,
        plan_code,
        status,
        source,
        starts_at,
        ends_at,
        current_period_start,
        current_period_end,
        provider,
        provider_subscription_id,
        metadata
      )
      values (
        v_subscription_id,
        v_payment.payer_user_id,
        v_payment.plan_code,
        'active',
        'payment_provider',
        v_period_start,
        v_period_end,
        v_period_start,
        v_period_end,
        v_payment.provider,
        v_payment.provider_event_id,
        jsonb_build_object(
          'payment_event_id', v_payment.id,
          'billing_cycle', v_billing_cycle,
          'approved_at', v_reviewed_at,
          'subscription_transition', v_transition,
          'superseded_subscription_ids', v_switched_subscription_ids
        )
      );
    end if;
  else
    v_transition := 'rejected';
  end if;

  update public.payment_events
  set
    status = case when v_decision = 'approve' then 'succeeded' else 'failed' end,
    paid_at = case
      when v_decision = 'approve' then coalesce(paid_at, v_reviewed_at)
      else paid_at
    end,
    reviewed_by = auth.uid(),
    reviewed_at = v_reviewed_at,
    review_reason = nullif(btrim(p_reason), ''),
    subscription_id = case
      when v_decision = 'approve' then v_subscription_id
      else subscription_id
    end,
    metadata = metadata || jsonb_build_object(
      'admin_decision', v_decision,
      'admin_review_idempotency_key', btrim(p_idempotency_key),
      'manual_approval_required', true,
      'transfer_reconciliation_confirmed', coalesce(p_transfer_verified, false),
      'transfer_reference', transfer_reference,
      'transfer_memo', transfer_memo,
      'transfer_confirmed_at', metadata ->> 'transfer_confirmed_at',
      'billing_cycle', v_billing_cycle,
      'subscription_transition', v_transition,
      'subscription_id', case
        when v_decision = 'approve' then v_subscription_id::text
        else null
      end,
      'superseded_subscription_ids', v_switched_subscription_ids
    )
  where id = p_payment_event_id
  returning * into v_payment;

  perform public.admin_write_audit(
    'admin_review_payment',
    'payment_event',
    p_payment_event_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'decision', v_decision,
      'transfer_reconciliation_confirmed', coalesce(p_transfer_verified, false),
      'transfer_reference', v_payment.transfer_reference,
      'transfer_memo', v_payment.transfer_memo,
      'transfer_confirmed_at', v_payment.metadata ->> 'transfer_confirmed_at',
      'billing_cycle', v_billing_cycle,
      'subscription_transition', v_transition,
      'subscription_id', case
        when v_decision = 'approve' then v_subscription_id::text
        else null
      end,
      'superseded_subscription_ids', v_switched_subscription_ids
    )
  );

  return query select true, 'Da xu ly payment.';
end;
$$;

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
  'Default membership payment price table used by create_membership_payment_request.',
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
    "bank_account_display_name": "L\u00ea Ph\u00fa Th\u1ea1ch"
  }'::jsonb,
  'active',
  'Server-owned VietQR receiving account for manually reviewed membership payments.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'membership_payment_bank'
    and status = 'active'
);

-- Clients can only invoke owner-scoped request actions. Direct payment and
-- subscription writes remain blocked by RLS and table grants.
revoke insert, update, delete on public.payment_events from anon, authenticated;
revoke all on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
) from public, anon;
revoke all on function public.confirm_my_membership_payment_transfer(uuid)
  from public, anon;
revoke all on function public.cancel_my_membership_payment_request(uuid)
  from public, anon;
revoke all on function public.get_my_membership_payment_request()
  from public, anon;
revoke all on function public.admin_get_payment_review_alert()
  from public, anon;
revoke all on function public.admin_list_payments(text, integer)
  from public, anon;
revoke all on function public.admin_review_payment(uuid, text, text, text, boolean)
  from public, anon;

grant execute on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
) to authenticated;
grant execute on function public.confirm_my_membership_payment_transfer(uuid)
  to authenticated;
grant execute on function public.cancel_my_membership_payment_request(uuid)
  to authenticated;
grant execute on function public.get_my_membership_payment_request()
  to authenticated;
grant execute on function public.admin_get_payment_review_alert()
  to authenticated;
grant execute on function public.admin_list_payments(text, integer)
  to authenticated;
grant execute on function public.admin_review_payment(uuid, text, text, text, boolean)
  to authenticated;

commit;
