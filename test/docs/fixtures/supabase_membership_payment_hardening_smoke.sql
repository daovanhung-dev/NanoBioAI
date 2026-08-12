-- M13 VietQR hardening executable smoke.
-- Prerequisite: disposable local/sandbox rebuilt with docs/supabase/config.sql
-- from the same commit/patch. This script intentionally mutates fixture rows
-- inside one transaction and always rolls back.
--
-- Covers:
-- - canonical NB-only memo and server-owned recipient/price
-- - owner-only cancellation and post-confirm cancellation denial
-- - one-open-request guard and idempotent replay
-- - no client direct writes to payment/subscription/quota tables
-- - Support/Content/Operations denial; Finance/Super review access
-- - no entitlement before approval
-- - approve/reject idempotency and audit
-- - same-plan renewal, Plus <-> FamilyPlus switch, monthly/yearly calendar period
-- - legacy active paid subscription with NULL ends_at blocks approval
--
-- True two-session concurrency is intentionally tracked in
-- docs/supabase/08-acceptance-checks.md because one SQL transaction cannot
-- prove lock ordering across separate sessions.

begin;

do $$
declare
  v_payer constant uuid := '11000000-0000-4000-8000-000000000002'::uuid;
  v_other constant uuid := '11000000-0000-4000-8000-000000000003'::uuid;
  v_reject_payer constant uuid := '11000000-0000-4000-8000-000000000024'::uuid;
  v_finance constant uuid := '11000000-0000-4000-8000-000000000025'::uuid;
  v_support constant uuid := '11000000-0000-4000-8000-000000000026'::uuid;
  v_content constant uuid := '11000000-0000-4000-8000-000000000027'::uuid;
  v_operations constant uuid := '11000000-0000-4000-8000-000000000028'::uuid;
  v_super constant uuid := '11000000-0000-4000-8000-000000000029'::uuid;

  v_request record;
  v_same_request record;
  v_renewal record;
  v_switch record;
  v_rejected record;
  v_legacy_request record;
  v_first_subscription_id uuid;
  v_first_start timestamptz;
  v_first_end timestamptz;
  v_expected_end timestamptz;
  v_renewed_end timestamptz;
  v_family_start timestamptz;
  v_family_end timestamptz;
  v_count integer;
  v_message text;
begin
  -- Normalize the selected disposable fixture users for this smoke. All
  -- changes are rolled back at the end.
  delete from public.payment_events
  where provider = 'manual_membership_request'
    and payer_user_id in (v_payer, v_other, v_reject_payer);

  delete from public.membership_subscriptions
  where user_id in (v_payer, v_other, v_reject_payer)
    and plan_code in ('plus', 'family_plus');

  -- -----------------------------------------------------------------------
  -- Create request: exact reference-only memo, server-owned price/bank.
  -- -----------------------------------------------------------------------
  perform set_config('request.jwt.claim.sub', v_payer::text, true);
  execute 'set local role authenticated';

  select *
  into v_request
  from public.create_membership_payment_request(
    'plus'::public.nb_membership_plan,
    'monthly',
    'm13-smoke-create-1',
    'Fixture Free Ready'
  );

  if v_request.status <> 'awaiting_transfer' then
    raise exception 'M13_CREATE_STATUS_%', v_request.status;
  end if;
  if v_request.transfer_reference !~ '^NB[0-9A-F]{12}$' then
    raise exception 'M13_REFERENCE_NOT_CANONICAL_%', v_request.transfer_reference;
  end if;
  if v_request.transfer_memo is distinct from v_request.transfer_reference then
    raise exception 'M13_MEMO_NOT_REFERENCE_ONLY';
  end if;
  if v_request.bank_code <> 'VCB'
     or v_request.bank_bin <> '970436'
     or v_request.bank_account_number <> '1026806174'
     or v_request.bank_account_name <> 'LE PHU THACH' then
    raise exception 'M13_SERVER_BANK_CONFIG_MISMATCH';
  end if;
  if v_request.amount_cents <= 0 or v_request.currency <> 'VND' then
    raise exception 'M13_SERVER_PRICE_INVALID';
  end if;

  -- Same idempotency key returns the same request.
  select *
  into v_same_request
  from public.create_membership_payment_request(
    'plus'::public.nb_membership_plan,
    'monthly',
    'm13-smoke-create-1',
    'Fixture Free Ready'
  );
  if v_same_request.payment_event_id <> v_request.payment_event_id
     or v_same_request.transfer_reference <> v_request.transfer_reference then
    raise exception 'M13_CREATE_IDEMPOTENCY_BROKEN';
  end if;

  -- A second key while the first request is open must be rejected.
  begin
    perform *
    from public.create_membership_payment_request(
      'plus'::public.nb_membership_plan,
      'monthly',
      'm13-smoke-open-conflict',
      'Fixture Free Ready'
    );
    raise exception 'M13_OPEN_REQUEST_CONFLICT_NOT_BLOCKED';
  exception
    when others then
      if sqlerrm = 'M13_OPEN_REQUEST_CONFLICT_NOT_BLOCKED'
         or position('MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN' in sqlerrm) = 0 then
        raise;
      end if;
  end;

  -- Direct client writes to server-owned financial/access tables are denied.
  begin
    insert into public.payment_events (
      payer_user_id, plan_code, provider, provider_event_id,
      amount_cents, currency, status
    )
    values (
      v_payer, 'plus', 'client_forbidden', 'm13-direct-payment',
      1, 'VND', 'pending'
    );
    raise exception 'M13_DIRECT_PAYMENT_WRITE_ALLOWED';
  exception
    when others then
      if sqlerrm = 'M13_DIRECT_PAYMENT_WRITE_ALLOWED' or sqlstate <> '42501' then
        raise;
      end if;
  end;

  begin
    insert into public.membership_subscriptions (
      user_id, plan_code, status, source, starts_at, ends_at
    )
    values (
      v_payer, 'plus', 'active', 'manual', now(), now() + interval '1 month'
    );
    raise exception 'M13_DIRECT_SUBSCRIPTION_WRITE_ALLOWED';
  exception
    when others then
      if sqlerrm = 'M13_DIRECT_SUBSCRIPTION_WRITE_ALLOWED'
         or sqlstate <> '42501' then
        raise;
      end if;
  end;

  begin
    insert into public.usage_quota_counters (
      user_id, feature_key, period_key, plan_code, used_count
    )
    values (v_payer, 'ai_chat_message', 'm13-forbidden', 'plus', 0);
    raise exception 'M13_DIRECT_QUOTA_WRITE_ALLOWED';
  exception
    when others then
      if sqlerrm = 'M13_DIRECT_QUOTA_WRITE_ALLOWED' or sqlstate <> '42501' then
        raise;
      end if;
  end;

  execute 'reset role';

  -- No paid entitlement before Admin approval.
  if public.current_plan_for_user(v_payer) <> 'free' then
    raise exception 'M13_ACCESS_GRANTED_BEFORE_APPROVAL';
  end if;

  -- -----------------------------------------------------------------------
  -- Owner-only cancellation; cancellation is idempotent only while canceled.
  -- -----------------------------------------------------------------------
  perform set_config('request.jwt.claim.sub', v_other::text, true);
  execute 'set local role authenticated';
  begin
    perform *
    from public.cancel_my_membership_payment_request(v_request.payment_event_id);
    raise exception 'M13_CROSS_OWNER_CANCEL_ALLOWED';
  exception
    when others then
      if sqlerrm = 'M13_CROSS_OWNER_CANCEL_ALLOWED'
         or position('PAYMENT_NOT_FOUND' in sqlerrm) = 0 then
        raise;
      end if;
  end;
  execute 'reset role';

  perform set_config('request.jwt.claim.sub', v_payer::text, true);
  execute 'set local role authenticated';
  select *
  into v_request
  from public.cancel_my_membership_payment_request(v_request.payment_event_id);
  if v_request.status <> 'canceled' or v_request.can_cancel then
    raise exception 'M13_OWNER_CANCEL_FAILED';
  end if;

  select *
  into v_same_request
  from public.cancel_my_membership_payment_request(v_request.payment_event_id);
  if v_same_request.status <> 'canceled' then
    raise exception 'M13_CANCEL_IDEMPOTENCY_FAILED';
  end if;

  -- New request is allowed after the previous one is terminal.
  select *
  into v_request
  from public.create_membership_payment_request(
    'plus'::public.nb_membership_plan,
    'monthly',
    'm13-smoke-approve-1',
    'Fixture Free Ready'
  );

  select *
  into v_request
  from public.confirm_my_membership_payment_transfer(v_request.payment_event_id);
  if v_request.status <> 'pending_review' or v_request.can_cancel then
    raise exception 'M13_CONFIRM_DID_NOT_ENTER_PENDING_REVIEW';
  end if;

  begin
    perform *
    from public.cancel_my_membership_payment_request(v_request.payment_event_id);
    raise exception 'M13_CANCEL_AFTER_CONFIRM_ALLOWED';
  exception
    when others then
      if sqlerrm = 'M13_CANCEL_AFTER_CONFIRM_ALLOWED'
         or position('PAYMENT_CANCELLATION_NOT_ALLOWED' in sqlerrm) = 0 then
        raise;
      end if;
  end;
  execute 'reset role';

  if public.current_plan_for_user(v_payer) <> 'free' then
    raise exception 'M13_PENDING_REVIEW_GRANTED_ACCESS';
  end if;

  -- -----------------------------------------------------------------------
  -- Non-financial Admin roles must not observe or mutate the payment queue.
  -- -----------------------------------------------------------------------
  foreach v_message in array array[
    v_support::text,
    v_content::text,
    v_operations::text
  ]
  loop
    perform set_config('request.jwt.claim.sub', v_message, true);
    execute 'set local role authenticated';

    begin
      perform * from public.admin_get_payment_review_alert();
      raise exception 'M13_NON_FINANCE_ALERT_ALLOWED_%', v_message;
    exception
      when others then
        if position('M13_NON_FINANCE_ALERT_ALLOWED_' in sqlerrm) > 0
           or position('PAYMENT_REVIEWER_ROLE_REQUIRED' in sqlerrm) = 0 then
          raise;
        end if;
    end;

    begin
      perform *
      from public.admin_review_payment(
        v_request.payment_event_id,
        'approve',
        'Should be denied.',
        'm13-denied-' || right(v_message, 3),
        true
      );
      raise exception 'M13_NON_FINANCE_REVIEW_ALLOWED_%', v_message;
    exception
      when others then
        if position('M13_NON_FINANCE_REVIEW_ALLOWED_' in sqlerrm) > 0
           or position('PAYMENT_REVIEWER_ROLE_REQUIRED' in sqlerrm) = 0 then
          raise;
        end if;
    end;

    execute 'reset role';
  end loop;

  -- Finance can see queue, but approve requires explicit VCB reconciliation.
  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  execute 'set local role authenticated';
  perform * from public.admin_get_payment_review_alert();

  begin
    perform *
    from public.admin_review_payment(
      v_request.payment_event_id,
      'approve',
      'VCB not checked yet.',
      'm13-finance-unverified',
      false
    );
    raise exception 'M13_UNVERIFIED_APPROVE_ALLOWED';
  exception
    when others then
      if sqlerrm = 'M13_UNVERIFIED_APPROVE_ALLOWED'
         or position('PAYMENT_TRANSFER_RECONCILIATION_REQUIRED' in sqlerrm) = 0 then
        raise;
      end if;
  end;

  perform *
  from public.admin_review_payment(
    v_request.payment_event_id,
    'approve',
    'Đã đối chiếu mã NB, số tiền và nội dung trong VCB.',
    'm13-finance-approve-1',
    true
  );

  -- Same decision retry is idempotent.
  perform *
  from public.admin_review_payment(
    v_request.payment_event_id,
    'approve',
    'Đã đối chiếu mã NB, số tiền và nội dung trong VCB.',
    'm13-finance-approve-1',
    true
  );
  execute 'reset role';

  select ms.id, ms.starts_at, ms.ends_at
  into v_first_subscription_id, v_first_start, v_first_end
  from public.membership_subscriptions ms
  where ms.user_id = v_payer
    and ms.plan_code = 'plus'
    and ms.status in ('trialing', 'active')
  order by ms.ends_at desc
  limit 1;

  if v_first_subscription_id is null or v_first_end is null then
    raise exception 'M13_APPROVE_DID_NOT_CREATE_FINITE_SUBSCRIPTION';
  end if;
  if public.current_plan_for_user(v_payer) <> 'plus' then
    raise exception 'M13_APPROVE_DID_NOT_ENABLE_PLUS';
  end if;
  if not exists (
    select 1 from public.users u
    where u.id = v_payer and u.subscription_tier = 'plus'
  ) then
    raise exception 'M13_USER_PROJECTION_NOT_SYNCED_TO_PLUS';
  end if;
  if not exists (
    select 1
    from public.admin_audit_events a
    where a.actor_id = v_finance
      and a.action = 'admin_review_payment'
      and a.target_id = v_request.payment_event_id::text
  ) then
    raise exception 'M13_APPROVAL_AUDIT_MISSING';
  end if;

  -- First monthly period must be one Vietnam calendar month.
  v_expected_end := (
    (v_first_start at time zone 'Asia/Ho_Chi_Minh') + interval '1 month'
  ) at time zone 'Asia/Ho_Chi_Minh';
  if v_first_end is distinct from v_expected_end then
    raise exception 'M13_MONTHLY_PERIOD_NOT_VIETNAM_CALENDAR_MONTH';
  end if;

  -- -----------------------------------------------------------------------
  -- Same-plan renewal extends from the active end, not approval time.
  -- -----------------------------------------------------------------------
  perform set_config('request.jwt.claim.sub', v_payer::text, true);
  execute 'set local role authenticated';
  select *
  into v_renewal
  from public.create_membership_payment_request(
    'plus'::public.nb_membership_plan,
    'yearly',
    'm13-smoke-renew-1',
    'Fixture Free Ready'
  );
  select *
  into v_renewal
  from public.confirm_my_membership_payment_transfer(v_renewal.payment_event_id);
  execute 'reset role';

  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  execute 'set local role authenticated';
  perform *
  from public.admin_review_payment(
    v_renewal.payment_event_id,
    'approve',
    'Gia hạn Plus sau khi đối chiếu VCB.',
    'm13-finance-renew-1',
    true
  );
  execute 'reset role';

  select ms.ends_at
  into v_renewed_end
  from public.membership_subscriptions ms
  where ms.id = v_first_subscription_id;

  if v_renewed_end is null or v_renewed_end <= v_first_end then
    raise exception 'M13_SAME_PLAN_RENEWAL_DID_NOT_EXTEND';
  end if;
  v_expected_end := (
    (v_first_end at time zone 'Asia/Ho_Chi_Minh') + interval '1 year'
  ) at time zone 'Asia/Ho_Chi_Minh';
  if v_renewed_end is distinct from v_expected_end then
    raise exception 'M13_YEARLY_RENEWAL_NOT_FROM_EXISTING_END';
  end if;

  -- -----------------------------------------------------------------------
  -- Plus -> FamilyPlus is an immediate switch with audited linkage.
  -- -----------------------------------------------------------------------
  perform set_config('request.jwt.claim.sub', v_payer::text, true);
  execute 'set local role authenticated';
  select *
  into v_switch
  from public.create_membership_payment_request(
    'family_plus'::public.nb_membership_plan,
    'monthly',
    'm13-smoke-switch-1',
    'Fixture Free Ready'
  );
  select *
  into v_switch
  from public.confirm_my_membership_payment_transfer(v_switch.payment_event_id);
  execute 'reset role';

  perform set_config('request.jwt.claim.sub', v_super::text, true);
  execute 'set local role authenticated';
  perform * from public.admin_get_payment_review_alert();
  perform *
  from public.admin_review_payment(
    v_switch.payment_event_id,
    'approve',
    'Super Admin đã đối chiếu VCB và chuyển sang FamilyPlus.',
    'm13-super-switch-1',
    true
  );
  execute 'reset role';

  if public.current_plan_for_user(v_payer) <> 'family_plus' then
    raise exception 'M13_PLAN_SWITCH_DID_NOT_ENABLE_FAMILYPLUS';
  end if;
  if exists (
    select 1
    from public.membership_subscriptions ms
    where ms.user_id = v_payer
      and ms.plan_code = 'plus'
      and ms.status in ('trialing', 'active')
      and ms.starts_at <= now()
      and (ms.ends_at is null or ms.ends_at > now())
  ) then
    raise exception 'M13_PLAN_SWITCH_LEFT_PLUS_ACTIVE';
  end if;

  select ms.starts_at, ms.ends_at
  into v_family_start, v_family_end
  from public.membership_subscriptions ms
  where ms.user_id = v_payer
    and ms.plan_code = 'family_plus'
    and ms.status = 'active'
  order by ms.created_at desc
  limit 1;

  if v_family_start is null or v_family_end is null then
    raise exception 'M13_FAMILYPLUS_PERIOD_MISSING';
  end if;
  v_expected_end := (
    (v_family_start at time zone 'Asia/Ho_Chi_Minh') + interval '1 month'
  ) at time zone 'Asia/Ho_Chi_Minh';
  if v_family_end is distinct from v_expected_end then
    raise exception 'M13_SWITCH_MONTHLY_PERIOD_INVALID';
  end if;
  if not exists (
    select 1
    from public.payment_events pe
    where pe.id = v_switch.payment_event_id
      and pe.metadata ->> 'subscription_transition' = 'plan_switch'
      and jsonb_array_length(
        coalesce(pe.metadata -> 'superseded_subscription_ids', '[]'::jsonb)
      ) >= 1
  ) then
    raise exception 'M13_PLAN_SWITCH_AUDIT_LINK_MISSING';
  end if;

  -- -----------------------------------------------------------------------
  -- Reject never creates access and is idempotent.
  -- -----------------------------------------------------------------------
  perform set_config('request.jwt.claim.sub', v_reject_payer::text, true);
  execute 'set local role authenticated';
  select *
  into v_rejected
  from public.create_membership_payment_request(
    'plus'::public.nb_membership_plan,
    'monthly',
    'm13-smoke-reject-1',
    'Fixture Wellness'
  );
  select *
  into v_rejected
  from public.confirm_my_membership_payment_transfer(v_rejected.payment_event_id);
  execute 'reset role';

  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  execute 'set local role authenticated';
  perform *
  from public.admin_review_payment(
    v_rejected.payment_event_id,
    'reject',
    'Không tìm thấy giao dịch khớp trong VCB.',
    'm13-finance-reject-1',
    false
  );
  perform *
  from public.admin_review_payment(
    v_rejected.payment_event_id,
    'reject',
    'Không tìm thấy giao dịch khớp trong VCB.',
    'm13-finance-reject-1',
    false
  );
  execute 'reset role';

  if public.current_plan_for_user(v_reject_payer) <> 'free' then
    raise exception 'M13_REJECT_GRANTED_ACCESS';
  end if;
  if exists (
    select 1
    from public.membership_subscriptions ms
    where ms.user_id = v_reject_payer
      and ms.plan_code in ('plus', 'family_plus')
      and ms.status in ('trialing', 'active')
      and ms.starts_at <= now()
      and (ms.ends_at is null or ms.ends_at > now())
  ) then
    raise exception 'M13_REJECT_CREATED_PAID_SUBSCRIPTION';
  end if;
  if not exists (
    select 1
    from public.payment_events pe
    where pe.id = v_rejected.payment_event_id
      and pe.status = 'failed'
      and nullif(pe.review_reason, '') is not null
  ) then
    raise exception 'M13_REJECT_REASON_NOT_PERSISTED';
  end if;

  -- -----------------------------------------------------------------------
  -- RLS: user A cannot see user B's manual payment.
  -- -----------------------------------------------------------------------
  perform set_config('request.jwt.claim.sub', v_payer::text, true);
  execute 'set local role authenticated';
  select count(*)
  into v_count
  from public.payment_events pe
  where pe.id = v_rejected.payment_event_id;
  execute 'reset role';
  if v_count <> 0 then
    raise exception 'M13_PAYMENT_RLS_CROSS_USER_LEAK';
  end if;

  -- -----------------------------------------------------------------------
  -- Legacy active paid access without ends_at blocks a new approval.
  -- -----------------------------------------------------------------------
  delete from public.payment_events
  where provider = 'manual_membership_request'
    and payer_user_id = v_other;
  delete from public.membership_subscriptions
  where user_id = v_other and plan_code in ('plus', 'family_plus');

  insert into public.membership_subscriptions (
    user_id,
    plan_code,
    status,
    source,
    starts_at,
    ends_at,
    current_period_start,
    current_period_end,
    metadata
  )
  values (
    v_other,
    'plus',
    'active',
    'migration',
    now() - interval '10 days',
    null,
    now() - interval '10 days',
    null,
    '{"fixture":"m13_legacy_missing_end"}'::jsonb
  );

  perform set_config('request.jwt.claim.sub', v_other::text, true);
  execute 'set local role authenticated';
  select *
  into v_legacy_request
  from public.create_membership_payment_request(
    'family_plus'::public.nb_membership_plan,
    'monthly',
    'm13-smoke-legacy-1',
    'Fixture Free Exhausted'
  );
  select *
  into v_legacy_request
  from public.confirm_my_membership_payment_transfer(
    v_legacy_request.payment_event_id
  );
  execute 'reset role';

  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  execute 'set local role authenticated';
  begin
    perform *
    from public.admin_review_payment(
      v_legacy_request.payment_event_id,
      'approve',
      'Legacy row must be repaired first.',
      'm13-finance-legacy-1',
      true
    );
    raise exception 'M13_LEGACY_MISSING_END_APPROVED';
  exception
    when others then
      if sqlerrm = 'M13_LEGACY_MISSING_END_APPROVED'
         or position('LEGACY_PAID_SUBSCRIPTION_MISSING_ENDS_AT' in sqlerrm) = 0 then
        raise;
      end if;
  end;
  execute 'reset role';

  if not exists (
    select 1
    from public.payment_events pe
    where pe.id = v_legacy_request.payment_event_id
      and pe.status = 'pending_review'
  ) then
    raise exception 'M13_LEGACY_BLOCK_CHANGED_PAYMENT_STATE';
  end if;
end
$$;

rollback;
