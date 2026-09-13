-- Membership expiration rollback-only executable smoke.
-- Run after docs/supabase/01_build_system.sql and 02_seed_data.sql on a
-- disposable Supabase local/sandbox database as postgres/service role.

begin;

do $$
declare
  v_user_id constant uuid := '10000000-0000-4000-8000-000000000104'::uuid;
  v_expired_subscription_id uuid := gen_random_uuid();
  v_expired_family_subscription_id uuid := gen_random_uuid();
  v_future_subscription_id uuid := gen_random_uuid();
  v_permanent_subscription_id uuid := gen_random_uuid();
  v_canceled_subscription_id uuid := gen_random_uuid();
  v_new_subscription_id uuid := gen_random_uuid();
  v_expired_count integer;
  v_expired_rows integer;
  v_status text;
  v_plan text;
  v_access text;
begin
  if not exists (
    select 1
    from public.users
    where id = v_user_id
  ) then
    raise exception 'MEMBERSHIP_EXPIRY_USER_MISSING';
  end if;

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
    metadata
  )
  values (
    v_expired_subscription_id,
    v_user_id,
    'plus',
    'active',
    'manual',
    now() - interval '30 days',
    now() - interval '1 minute',
    now() - interval '30 days',
    now() - interval '1 minute',
    jsonb_build_object('smoke', 'membership-expiration-plus')
  ), (
    v_expired_family_subscription_id,
    v_user_id,
    'family_plus',
    'active',
    'manual',
    now() - interval '30 days',
    now() - interval '1 minute',
    now() - interval '30 days',
    now() - interval '1 minute',
    jsonb_build_object('smoke', 'membership-expiration-family-plus')
  );

  select public.expire_membership_subscriptions()
  into v_expired_count;

  select count(*)
  into v_expired_rows
  from public.membership_subscriptions ms
  where ms.id in (v_expired_subscription_id, v_expired_family_subscription_id)
    and ms.status = 'expired';

  if v_expired_rows <> 2 or v_expired_count < 2 then
    raise exception 'MEMBERSHIP_EXPIRY_DID_NOT_EXPIRE';
  end if;

  select public.expire_membership_subscriptions()
  into v_expired_count;

  if v_expired_count <> 0 then
    raise exception 'MEMBERSHIP_EXPIRY_NOT_IDEMPOTENT';
  end if;

  select u.subscription_tier::text, u.product_access_status::text
  into v_plan, v_access
  from public.users u
  where u.id = v_user_id;

  if v_plan <> 'free' or v_access <> 'free' then
    raise exception 'MEMBERSHIP_EXPIRY_USER_NOT_FREE';
  end if;

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
    metadata
  )
  values (
    v_future_subscription_id,
    v_user_id,
    'family_plus',
    'active',
    'manual',
    now() - interval '1 day',
    now() + interval '30 days',
    now() - interval '1 day',
    now() + interval '30 days',
    jsonb_build_object('smoke', 'membership-expiration-active-peer')
  );

  perform public.expire_membership_subscriptions();

  select u.subscription_tier::text
  into v_plan
  from public.users u
  where u.id = v_user_id;

  if v_plan <> 'family_plus' then
    raise exception 'MEMBERSHIP_EXPIRY_OTHER_ACTIVE_PLAN_LOST';
  end if;

  insert into public.membership_subscriptions (
    id,
    user_id,
    plan_code,
    status,
    source,
    starts_at,
    current_period_start,
    metadata
  )
  values (
    v_permanent_subscription_id,
    v_user_id,
    'plus',
    'active',
    'manual',
    now() - interval '1 day',
    now() - interval '1 day',
    jsonb_build_object('smoke', 'membership-expiration-permanent')
  );

  perform public.expire_membership_subscriptions();

  select ms.status
  into v_status
  from public.membership_subscriptions ms
  where ms.id = v_permanent_subscription_id;

  if v_status <> 'active' then
    raise exception 'MEMBERSHIP_EXPIRY_PERMANENT_CHANGED';
  end if;

  delete from public.membership_subscriptions
  where id in (v_future_subscription_id, v_permanent_subscription_id);

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
    metadata
  )
  values (
    v_canceled_subscription_id,
    v_user_id,
    'plus',
    'canceled',
    'manual',
    now() - interval '30 days',
    now() - interval '1 minute',
    now() - interval '30 days',
    now() - interval '1 minute',
    jsonb_build_object('smoke', 'membership-expiration-canceled')
  );

  perform public.expire_membership_subscriptions();

  select ms.status
  into v_status
  from public.membership_subscriptions ms
  where ms.id = v_canceled_subscription_id;

  if v_status <> 'canceled' then
    raise exception 'MEMBERSHIP_EXPIRY_CANCELED_RECLASSIFIED';
  end if;

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
    metadata
  )
  values (
    v_new_subscription_id,
    v_user_id,
    'plus',
    'active',
    'manual',
    now() - interval '1 day',
    now() + interval '30 days',
    now() - interval '1 day',
    now() + interval '30 days',
    jsonb_build_object('smoke', 'membership-expiration-new-grant')
  );

  select u.subscription_tier::text, u.product_access_status::text
  into v_plan, v_access
  from public.users u
  where u.id = v_user_id;

  if v_plan <> 'plus' or v_access <> 'plus' then
    raise exception 'MEMBERSHIP_EXPIRY_NEW_GRANT_NOT_RESTORED';
  end if;
end;
$$;

rollback;
