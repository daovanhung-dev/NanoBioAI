-- M13 QR rebuild contract smoke. Run after 25-membership-payment-qr-rebuild.sql
-- in local/sandbox/staging. This script is read-only with respect to app data.

begin;

do $$
declare
  v_definition text;
  v_bad_reference_count integer;
  v_distinct_reference_count integer;
begin
  if to_regprocedure('public.generate_membership_payment_reference()') is null then
    raise exception 'M13_SMOKE_REFERENCE_GENERATOR_MISSING';
  end if;

  if to_regprocedure(
    'public.create_membership_payment_request(public.nb_membership_plan,text,text)'
  ) is null then
    raise exception 'M13_SMOKE_CANONICAL_CREATE_RPC_MISSING';
  end if;

  select pg_get_functiondef(
    'public.create_membership_payment_request(public.nb_membership_plan,text,text)'::regprocedure
  ) into v_definition;

  if v_definition not like '%generate_membership_payment_reference%' then
    raise exception 'M13_SMOKE_CREATE_RPC_DOES_NOT_USE_REFERENCE_GENERATOR';
  end if;

  if v_definition like '%p_payer_full_name%' then
    raise exception 'M13_SMOKE_CANONICAL_RPC_STILL_DEPENDS_ON_CLIENT_PAYER_NAME';
  end if;

  select count(*) filter (where ref !~ '^NB[0-9A-F]{12}$'),
         count(distinct ref)
  into v_bad_reference_count, v_distinct_reference_count
  from (
    select public.generate_membership_payment_reference() as ref
    from generate_series(1, 1000)
  ) generated;

  if v_bad_reference_count <> 0 then
    raise exception 'M13_SMOKE_REFERENCE_FORMAT_INVALID';
  end if;

  if v_distinct_reference_count <> 1000 then
    raise exception 'M13_SMOKE_REFERENCE_GENERATOR_COLLISION_IN_SAMPLE';
  end if;

  if not exists (
    select 1
    from public.system_config_versions
    where config_key = 'membership_payment_prices'
      and status = 'active'
  ) then
    raise exception 'M13_SMOKE_PRICE_CONFIG_MISSING';
  end if;

  if not exists (
    select 1
    from public.system_config_versions scv
    where scv.config_key = 'membership_payment_bank'
      and scv.status = 'active'
      and scv.config_value ->> 'bank_bin' ~ '^[0-9]{6}$'
      and scv.config_value ->> 'bank_account_number' ~ '^[0-9]{4,32}$'
      and nullif(btrim(scv.config_value ->> 'bank_account_name'), '') is not null
  ) then
    raise exception 'M13_SMOKE_BANK_CONFIG_INVALID';
  end if;
end;
$$;

rollback;
