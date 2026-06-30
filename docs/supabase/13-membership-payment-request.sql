-- NanoBio / BioAI - client-safe membership payment request RPC.
-- Run after 03-membership-quota.sql, 05-sale-referral-commission.sql and
-- 11-admin-access-dashboard.sql because it uses payment_events and
-- system_config_versions.

begin;

create or replace function public.create_membership_payment_request(
  p_plan_code public.nb_membership_plan,
  p_billing_cycle text,
  p_idempotency_key text
)
returns table (
  payment_event_id uuid,
  plan_code text,
  billing_cycle text,
  status text,
  amount_cents integer,
  currency text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_config jsonb;
  v_amount_cents integer;
  v_currency text;
  v_provider text := 'manual_membership_request';
  v_provider_event_id text;
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if p_plan_code not in ('plus', 'family_plus') then
    raise exception 'INVALID_MEMBERSHIP_PLAN' using errcode = '22023';
  end if;

  if btrim(coalesce(p_billing_cycle, '')) not in ('monthly', 'yearly') then
    raise exception 'INVALID_BILLING_CYCLE' using errcode = '22023';
  end if;

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED' using errcode = '22023';
  end if;

  select scv.config_value
  into v_config
  from public.system_config_versions scv
  where scv.config_key = 'membership_payment_prices'
    and scv.status = 'active'
  order by scv.created_at desc
  limit 1;

  v_amount_cents := nullif(
    v_config #>> array['prices', p_plan_code::text, btrim(p_billing_cycle)],
    ''
  )::integer;
  v_currency := coalesce(nullif(v_config ->> 'currency', ''), 'VND');

  if v_amount_cents is null or v_amount_cents <= 0 then
    raise exception 'MEMBERSHIP_PAYMENT_PRICE_NOT_CONFIGURED'
      using errcode = '22023';
  end if;

  v_provider_event_id := concat(v_user_id::text, ':', btrim(p_idempotency_key));

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
    'pending',
    btrim(p_idempotency_key),
    jsonb_build_object(
      'billing_cycle',
      btrim(p_billing_cycle),
      'manual_approval_required',
      true,
      'grants_access_before_approval',
      false
    )
  )
  on conflict (provider, provider_event_id) do update
  set metadata = public.payment_events.metadata || jsonb_build_object(
    'idempotent_replay',
    true
  )
  returning * into v_payment;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    coalesce(v_payment.metadata ->> 'billing_cycle', btrim(p_billing_cycle)),
    v_payment.status,
    v_payment.amount_cents,
    v_payment.currency,
    v_payment.created_at;
end;
$$;

grant execute on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
) to authenticated;

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

commit;
