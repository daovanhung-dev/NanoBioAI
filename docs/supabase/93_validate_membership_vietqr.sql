-- Rollback-only local/sandbox smoke for a server-issued VietQR transaction.
-- Run after 01 through 06. It creates a temporary request, verifies the
-- returned NB reconciliation key, and always rolls the transaction back.

begin;

do $$
declare
  v_payer constant uuid := '11000000-0000-4000-8000-000000000002'::uuid;
  v_request record;
  v_replay record;
begin
  -- Make this smoke repeatable without preserving any fixture mutations.
  delete from public.payment_events
  where provider = 'manual_membership_request'
    and payer_user_id = v_payer;

  perform set_config('request.jwt.claim.sub', v_payer::text, true);
  execute 'set local role authenticated';

  select *
  into v_request
  from public.create_membership_payment_request(
    'plus'::public.nb_membership_plan,
    'monthly',
    'local-vietqr-smoke-create-1',
    'Fixture Free Ready'
  );

  if v_request.status <> 'awaiting_transfer' then
    raise exception 'VIETQR_CREATE_STATUS_INVALID_%', v_request.status;
  end if;
  if v_request.transfer_reference !~ '^NB[0-9A-F]{12}$' then
    raise exception 'VIETQR_REFERENCE_INVALID_%', v_request.transfer_reference;
  end if;
  if v_request.transfer_memo is distinct from v_request.transfer_reference then
    raise exception 'VIETQR_MEMO_NOT_REFERENCE_ONLY';
  end if;
  if v_request.amount_cents <= 0
     or v_request.currency <> 'VND'
     or coalesce(v_request.bank_bin, '') !~ '^[0-9]{6}$'
     or coalesce(v_request.bank_account_number, '') !~ '^[0-9]{4,32}$'
     or coalesce(v_request.bank_account_name, '') = '' then
    raise exception 'VIETQR_SERVER_PAYMENT_DETAILS_INVALID';
  end if;

  -- The same idempotency key must return the original transaction and code.
  select *
  into v_replay
  from public.create_membership_payment_request(
    'plus'::public.nb_membership_plan,
    'monthly',
    'local-vietqr-smoke-create-1',
    'Fixture Free Ready'
  );

  if v_replay.payment_event_id <> v_request.payment_event_id
     or v_replay.transfer_reference <> v_request.transfer_reference then
    raise exception 'VIETQR_IDEMPOTENCY_BROKEN';
  end if;

  -- A different key cannot bypass the one-open-request guard.
  begin
    perform *
    from public.create_membership_payment_request(
      'plus'::public.nb_membership_plan,
      'monthly',
      'local-vietqr-smoke-open-conflict',
      'Fixture Free Ready'
    );
    raise exception 'VIETQR_OPEN_REQUEST_GUARD_MISSING';
  exception
    when others then
      if sqlerrm = 'VIETQR_OPEN_REQUEST_GUARD_MISSING'
         or position('MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN' in sqlerrm) = 0 then
        raise;
      end if;
  end;

  execute 'reset role';
  raise notice 'PASS VietQR: generated temporary reference %',
    v_request.transfer_reference;
end
$$;

rollback;
