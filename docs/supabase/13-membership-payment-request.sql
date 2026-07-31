-- NanoBio / BioAI - VietQR membership payment request and manual review.
-- Run after 03-membership-quota.sql, 05-sale-referral-commission.sql and
-- 11-admin-access-dashboard.sql. This is a non-destructive contract update:
-- legacy `pending` payment events remain reviewable, while new requests use
-- awaiting_transfer -> pending_review -> succeeded|failed.

begin;

-- Keep the transaction reference and transfer memo server-owned. A partial
-- unique index permits existing non-VietQR rows to keep a NULL reference.
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
      'failed'
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

alter table public.payment_events
  drop constraint if exists payment_events_transfer_memo_format_check;
alter table public.payment_events
  add constraint payment_events_transfer_memo_format_check
  check (
    transfer_memo is null
    or transfer_memo ~ '^[A-Z0-9 ]{1,25}$'
  );

create unique index if not exists uq_payment_events_transfer_reference
  on public.payment_events (transfer_reference)
  where transfer_reference is not null;

drop function if exists public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
);

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
  status text,
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
  v_payer_name_ascii text;
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

  -- VietQR transfer content is ASCII and capped at 25 characters. Preserve
  -- the generated reference first so Admins can always reconcile it.
  v_payer_name_ascii := upper(v_payer_full_name);
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴàáạảãâầấậẩẫăằắặẳẵ]',
    'A',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÈÉẸẺẼÊỀẾỆỂỄèéẹẻẽêềếệểễ]',
    'E',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÌÍỊỈĨìíịỉĩ]',
    'I',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠòóọỏõôồốộổỗơờớợởỡ]',
    'O',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ÙÚỤỦŨƯỪỨỰỬỮùúụủũưừứựửữ]',
    'U',
    'g'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[ỲÝỴỶỸỳýỵỷỹ]',
    'Y',
    'g'
  );
  v_payer_name_ascii := replace(
    replace(v_payer_name_ascii, 'Đ', 'D'),
    'đ',
    'D'
  );
  v_payer_name_ascii := regexp_replace(
    v_payer_name_ascii,
    '[^A-Z0-9 ]+',
    ' ',
    'g'
  );
  v_payer_name_ascii := btrim(
    regexp_replace(v_payer_name_ascii, '[[:space:]]+', ' ', 'g')
  );

  if v_payer_name_ascii = '' then
    raise exception 'PAYER_FULL_NAME_INVALID' using errcode = '22023';
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

  v_provider_event_id := concat(v_user_id::text, ':', btrim(p_idempotency_key));

  select *
  into v_payment
  from public.payment_events
  where provider = v_provider
    and provider_event_id = v_provider_event_id
  for update;

  if found then
    update public.payment_events
    set metadata = metadata || jsonb_build_object(
      'idempotent_replay',
      true
    )
    where id = v_payment.id
    returning * into v_payment;
  else
    loop
      v_attempt := v_attempt + 1;
      v_transfer_reference := concat(
        'NB',
        upper(encode(gen_random_bytes(6), 'hex'))
      );
      v_transfer_memo := concat(
        v_transfer_reference,
        ' ',
        left(v_payer_name_ascii, 25 - length(v_transfer_reference) - 1)
      );

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
            'billing_cycle',
            v_billing_cycle,
            'payer_full_name',
            v_payer_full_name,
            'manual_approval_required',
            true,
            'grants_access_before_approval',
            false,
            'transfer_reference',
            v_transfer_reference,
            'transfer_memo',
            v_transfer_memo,
            'bank',
            jsonb_build_object(
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
          -- A concurrent retry may have won the provider/idempotency race.
          -- Otherwise retry the vanishingly unlikely random reference collision.
          select *
          into v_payment
          from public.payment_events
          where provider = v_provider
            and provider_event_id = v_provider_event_id
          for update;

          if found then
            update public.payment_events
            set metadata = metadata || jsonb_build_object(
              'idempotent_replay',
              true
            )
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
    v_payment.status,
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
  status text,
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
  from public.payment_events
  where id = p_payment_event_id
    and payer_user_id = v_user_id
    and provider = v_provider
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if v_payment.status = 'awaiting_transfer' then
    if v_payment.transfer_reference is null or v_payment.transfer_memo is null then
      raise exception 'PAYMENT_TRANSFER_DETAILS_MISSING' using errcode = '22023';
    end if;

    v_confirmed_at := now();
    update public.payment_events
    set
      status = 'pending_review',
      metadata = metadata || jsonb_build_object(
        'transfer_confirmed_at',
        v_confirmed_at,
        'transfer_confirmation',
        jsonb_build_object(
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
    v_payment.status,
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
  status text,
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
    v_payment.status,
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

-- The alert is separate from dashboard.read: only payments.write Administrators
-- can learn the count of customer-confirmed transfers waiting for reconciliation.
create or replace function public.admin_get_payment_review_alert()
returns table (pending_review_count integer)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('payments.write');

  return query
  select count(*)::integer
  from public.payment_events pe
  where pe.status = 'pending_review';
end;
$$;

-- The additional transfer fields change the return type, so the prior two-field
-- signature must be dropped before it is recreated.
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
  perform public.admin_assert_permission('payments.write');

  return query
  select
    pe.id::text,
    concat(pe.plan_code::text, ' - ', pe.amount_cents::text, ' ', pe.currency),
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

create or replace function public.admin_review_payment(
  p_payment_event_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_payment public.payment_events%rowtype;
  v_status text;
  v_subscription_id uuid;
begin
  perform public.admin_assert_permission('payments.write');

  if p_decision not in ('approve', 'reject') then
    raise exception 'INVALID_PAYMENT_DECISION' using errcode = '22023';
  end if;

  if p_decision = 'reject'
    and nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception 'PAYMENT_REJECTION_REASON_REQUIRED' using errcode = '22023';
  end if;

  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  -- New records need customer confirmation. Historical `pending` requests
  -- remain actionable so the migration does not strand existing payments.
  if v_payment.status not in ('pending_review', 'pending') then
    raise exception 'PAYMENT_NOT_READY_FOR_REVIEW' using errcode = '22023';
  end if;

  v_status := case when p_decision = 'approve' then 'succeeded' else 'failed' end;

  update public.payment_events
  set
    status = v_status,
    paid_at = case when p_decision = 'approve' then coalesce(paid_at, now()) else paid_at end,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = nullif(btrim(p_reason), ''),
    idempotency_key = nullif(btrim(p_idempotency_key), ''),
    metadata = metadata || jsonb_build_object(
      'admin_decision',
      p_decision,
      'manual_approval_required',
      true,
      'transfer_reference',
      transfer_reference,
      'transfer_memo',
      transfer_memo,
      'transfer_confirmed_at',
      metadata ->> 'transfer_confirmed_at'
    )
  where id = p_payment_event_id
  returning * into v_payment;

  if p_decision = 'approve' then
    insert into public.membership_subscriptions (
      user_id,
      plan_code,
      status,
      source,
      starts_at,
      provider,
      provider_subscription_id,
      metadata
    )
    values (
      v_payment.payer_user_id,
      v_payment.plan_code,
      'active',
      'payment_provider',
      now(),
      v_payment.provider,
      v_payment.provider_event_id,
      jsonb_build_object('payment_event_id', v_payment.id)
    )
    returning id into v_subscription_id;

    update public.payment_events
    set subscription_id = v_subscription_id
    where id = v_payment.id;
  end if;

  perform public.admin_write_audit(
    'admin_review_payment',
    'payment_event',
    p_payment_event_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'decision', p_decision,
      'transfer_reference', v_payment.transfer_reference,
      'transfer_memo', v_payment.transfer_memo,
      'transfer_confirmed_at', v_payment.metadata ->> 'transfer_confirmed_at'
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
    "bank_account_display_name": "Lê Phú Thạch"
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

revoke all on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
) from public, anon;
revoke all on function public.confirm_my_membership_payment_transfer(uuid)
  from public, anon;
revoke all on function public.get_my_membership_payment_request()
  from public, anon;
revoke all on function public.admin_get_payment_review_alert()
  from public, anon;
revoke all on function public.admin_list_payments(text, integer)
  from public, anon;
revoke all on function public.admin_review_payment(uuid, text, text, text)
  from public, anon;

grant execute on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text,
  text
) to authenticated;
grant execute on function public.confirm_my_membership_payment_transfer(uuid)
  to authenticated;
grant execute on function public.get_my_membership_payment_request()
  to authenticated;
grant execute on function public.admin_get_payment_review_alert()
  to authenticated;
grant execute on function public.admin_list_payments(text, integer)
  to authenticated;
grant execute on function public.admin_review_payment(uuid, text, text, text)
  to authenticated;

commit;
