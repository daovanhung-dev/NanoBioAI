-- NanoBio comprehensive local/sandbox fixture.
-- This source is mirrored verbatim into config.sql immediately before its
-- final COMMIT. It deliberately has no transaction wrapper or module markers.
-- Never run it on production or shared staging.
--
-- Every identifier, person, address, bank detail, citizen identifier and
-- voucher below is fictional. Relative dates use the database clock and the
-- Asia/Ho_Chi_Minh quota boundary so the fixture stays meaningful over time.

-- fixture-table: users
-- fixture-table: health_subjects
-- fixture-table: health_profiles
-- fixture-table: lifestyle_habits
-- fixture-table: health_goals
-- fixture-table: health_conditions
-- fixture-table: food_allergies
-- fixture-table: medical_treatments
-- fixture-table: survey_answers
-- fixture-table: meal_plans
-- fixture-table: daily_health_tasks
-- fixture-table: lifestyle_schedule_items
-- fixture-table: notifications
-- fixture-table: health_tracking_logs
-- fixture-table: health_score_ledgers
-- fixture-table: wellness_point_ledgers
-- fixture-table: nutrition_logs
-- fixture-table: ai_insights
-- fixture-table: ai_recommendations
-- fixture-table: personal_schedule_ai_requests
-- fixture-table: meal_catalog
-- fixture-table: exercise_catalog
-- fixture-table: schedule_task_catalog
-- fixture-table: membership_plans
-- fixture-table: plan_entitlements
-- fixture-table: membership_subscriptions
-- fixture-table: usage_quota_rules
-- fixture-table: usage_quota_counters
-- fixture-table: usage_events
-- fixture-table: family_groups
-- fixture-table: family_members
-- fixture-table: sale_profiles
-- fixture-table: referral_codes
-- fixture-table: referral_relationships
-- fixture-table: payment_events
-- fixture-table: commission_rates
-- fixture-table: commission_records
-- fixture-table: admin_roles
-- fixture-table: admin_permissions
-- fixture-table: admin_role_permissions
-- fixture-table: admin_user_roles
-- fixture-table: admin_audit_events
-- fixture-table: system_config_versions
-- fixture-table: report_exports
-- fixture-table: sale_point_adjustments
-- fixture-table: admin_reconciliation_runs
-- fixture-table: admin_reconciliation_discrepancies
-- fixture-table: sale_point_conversions
-- fixture-table: sale_payout_profiles
-- fixture-table: guest_schedule_reward_registrations
-- fixture-table: member_schedule_reward_registrations
-- fixture-table: schedule_reward_eligibilities
-- fixture-table: schedule_completion_attempts
-- fixture-table: schedule_completion_proofs
-- fixture-table: wellness_reward_wallets
-- fixture-table: wellness_point_allocations
-- fixture-table: wellness_reward_offers
-- fixture-table: wellness_reward_codes
-- fixture-table: wellness_reward_redemptions
-- fixture-table: wellness_redemption_allocation_usages
-- fixture-table: nabi_notification_definitions
-- fixture-table: nabi_notification_user_states
-- fixture-table: nabi_notification_preferences
-- fixture-table: nabi_notification_events

-- ---------------------------------------------------------------------------
-- Auth -> users/self subjects. Existing dev.free/dev.plus/dev.family/dev.admin
-- bindings are owned by the historical config seed and are intentionally not
-- changed here.
-- ---------------------------------------------------------------------------

with fixture_users as (
  select *
  from (
    values
      ('11000000-0000-4000-8000-000000000001'::uuid, '21000000-0000-4000-8000-000000000001'::uuid, 'dev.fixture.guest@nanobio.local', 'Fixture Guest', 'anonymous', true),
      ('11000000-0000-4000-8000-000000000002'::uuid, '21000000-0000-4000-8000-000000000002'::uuid, 'dev.fixture.free.ready@nanobio.local', 'Fixture Free Ready', 'email', false),
      ('11000000-0000-4000-8000-000000000003'::uuid, '21000000-0000-4000-8000-000000000003'::uuid, 'dev.fixture.free.exhausted@nanobio.local', 'Fixture Free Exhausted', 'email', false),
      ('11000000-0000-4000-8000-000000000004'::uuid, '21000000-0000-4000-8000-000000000004'::uuid, 'dev.fixture.plus.active@nanobio.local', 'Fixture Plus Active', 'email', false),
      ('11000000-0000-4000-8000-000000000005'::uuid, '21000000-0000-4000-8000-000000000005'::uuid, 'dev.fixture.plus.trial@nanobio.local', 'Fixture Plus Trial', 'email', false),
      ('11000000-0000-4000-8000-000000000006'::uuid, '21000000-0000-4000-8000-000000000006'::uuid, 'dev.fixture.plus.pastdue@nanobio.local', 'Fixture Plus Past Due', 'email', false),
      ('11000000-0000-4000-8000-000000000007'::uuid, '21000000-0000-4000-8000-000000000007'::uuid, 'dev.fixture.plus.canceled@nanobio.local', 'Fixture Plus Canceled', 'email', false),
      ('11000000-0000-4000-8000-000000000008'::uuid, '21000000-0000-4000-8000-000000000008'::uuid, 'dev.fixture.plus.expired@nanobio.local', 'Fixture Plus Expired', 'email', false),
      ('11000000-0000-4000-8000-000000000009'::uuid, '21000000-0000-4000-8000-000000000009'::uuid, 'dev.fixture.family.owner@nanobio.local', 'Fixture Family Owner', 'email', false),
      ('11000000-0000-4000-8000-000000000010'::uuid, '21000000-0000-4000-8000-000000000010'::uuid, 'dev.fixture.family.adult@nanobio.local', 'Fixture Family Adult', 'email', false),
      ('11000000-0000-4000-8000-000000000011'::uuid, '21000000-0000-4000-8000-000000000011'::uuid, 'dev.fixture.family.member@nanobio.local', 'Fixture Family Member', 'email', false),
      ('11000000-0000-4000-8000-000000000012'::uuid, '21000000-0000-4000-8000-000000000012'::uuid, 'dev.fixture.family.child@nanobio.local', 'Fixture Family Child', 'email', false),
      ('11000000-0000-4000-8000-000000000013'::uuid, '21000000-0000-4000-8000-000000000013'::uuid, 'dev.fixture.family.viewer@nanobio.local', 'Fixture Family Viewer', 'email', false),
      ('11000000-0000-4000-8000-000000000014'::uuid, '21000000-0000-4000-8000-000000000014'::uuid, 'dev.fixture.family.invited@nanobio.local', 'Fixture Family Invited', 'email', false),
      ('11000000-0000-4000-8000-000000000015'::uuid, '21000000-0000-4000-8000-000000000015'::uuid, 'dev.fixture.family.removed@nanobio.local', 'Fixture Family Removed', 'email', false),
      ('11000000-0000-4000-8000-000000000016'::uuid, '21000000-0000-4000-8000-000000000016'::uuid, 'dev.fixture.family.paused@nanobio.local', 'Fixture Family Paused', 'email', false),
      ('11000000-0000-4000-8000-000000000017'::uuid, '21000000-0000-4000-8000-000000000017'::uuid, 'dev.fixture.family.closed@nanobio.local', 'Fixture Family Closed', 'email', false),
      ('11000000-0000-4000-8000-000000000018'::uuid, '21000000-0000-4000-8000-000000000018'::uuid, 'dev.fixture.sale.active@nanobio.local', 'Fixture Sale A', 'email', false),
      ('11000000-0000-4000-8000-000000000019'::uuid, '21000000-0000-4000-8000-000000000019'::uuid, 'dev.fixture.sale.direct@nanobio.local', 'Fixture Sale B', 'email', false),
      ('11000000-0000-4000-8000-000000000020'::uuid, '21000000-0000-4000-8000-000000000020'::uuid, 'dev.fixture.sale.customer@nanobio.local', 'Fixture Sale Customer C', 'email', false),
      ('11000000-0000-4000-8000-000000000021'::uuid, '21000000-0000-4000-8000-000000000021'::uuid, 'dev.fixture.sale.pending@nanobio.local', 'Fixture Sale Pending', 'email', false),
      ('11000000-0000-4000-8000-000000000022'::uuid, '21000000-0000-4000-8000-000000000022'::uuid, 'dev.fixture.sale.suspended@nanobio.local', 'Fixture Sale Suspended', 'email', false),
      ('11000000-0000-4000-8000-000000000023'::uuid, '21000000-0000-4000-8000-000000000023'::uuid, 'dev.fixture.sale.closed@nanobio.local', 'Fixture Sale Closed', 'email', false),
      ('11000000-0000-4000-8000-000000000024'::uuid, '21000000-0000-4000-8000-000000000024'::uuid, 'dev.fixture.wellness@nanobio.local', 'Fixture Wellness', 'email', false),
      ('11000000-0000-4000-8000-000000000025'::uuid, '21000000-0000-4000-8000-000000000025'::uuid, 'dev.fixture.admin.finance@nanobio.local', 'Fixture Finance Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000026'::uuid, '21000000-0000-4000-8000-000000000026'::uuid, 'dev.fixture.admin.support@nanobio.local', 'Fixture Support Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000027'::uuid, '21000000-0000-4000-8000-000000000027'::uuid, 'dev.fixture.admin.content@nanobio.local', 'Fixture Content Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000028'::uuid, '21000000-0000-4000-8000-000000000028'::uuid, 'dev.fixture.admin.operations@nanobio.local', 'Fixture Operations Admin', 'email', false),
      ('11000000-0000-4000-8000-000000000029'::uuid, '21000000-0000-4000-8000-000000000029'::uuid, 'dev.fixture.admin.only@nanobio.local', 'Fixture Admin Only', 'email', false),
      ('11000000-0000-4000-8000-000000000030'::uuid, '21000000-0000-4000-8000-000000000030'::uuid, 'dev.fixture.admin.revoked@nanobio.local', 'Fixture Revoked Admin', 'email', false)
  ) as t(user_id, identity_id, email, full_name, provider, is_anonymous)
)
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone_change, phone_change_token,
  reauthentication_token, raw_app_meta_data, raw_user_meta_data, created_at,
  updated_at, is_sso_user, is_anonymous
)
select
  user_id,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'authenticated',
  'authenticated',
  email,
  crypt('NanoBio@123456', gen_salt('bf')),
  now(),
  '', '', '', '', '', '', '', '',
  jsonb_build_object('provider', provider, 'providers', array[provider]),
  jsonb_build_object(
    'full_name', full_name,
    'seed_fixture', 'dev-sandbox-comprehensive-v1',
    'fixture_key', replace(replace(email, 'dev.fixture.', ''), '@nanobio.local', '')
  ),
  now(), now(), false, is_anonymous
from fixture_users
on conflict (id) do update
set
  email = excluded.email,
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = coalesce(auth.users.email_confirmed_at, excluded.email_confirmed_at),
  confirmation_token = '',
  recovery_token = '',
  email_change = '',
  email_change_token_new = '',
  email_change_token_current = '',
  phone_change = '',
  phone_change_token = '',
  reauthentication_token = '',
  raw_app_meta_data = excluded.raw_app_meta_data,
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at = now(),
  is_anonymous = excluded.is_anonymous;

with fixture_users as (
  select *
  from (
    values
      ('11000000-0000-4000-8000-000000000001'::uuid, '21000000-0000-4000-8000-000000000001'::uuid, 'dev.fixture.guest@nanobio.local', 'Fixture Guest', 'anonymous'),
      ('11000000-0000-4000-8000-000000000002'::uuid, '21000000-0000-4000-8000-000000000002'::uuid, 'dev.fixture.free.ready@nanobio.local', 'Fixture Free Ready', 'email'),
      ('11000000-0000-4000-8000-000000000003'::uuid, '21000000-0000-4000-8000-000000000003'::uuid, 'dev.fixture.free.exhausted@nanobio.local', 'Fixture Free Exhausted', 'email'),
      ('11000000-0000-4000-8000-000000000004'::uuid, '21000000-0000-4000-8000-000000000004'::uuid, 'dev.fixture.plus.active@nanobio.local', 'Fixture Plus Active', 'email'),
      ('11000000-0000-4000-8000-000000000005'::uuid, '21000000-0000-4000-8000-000000000005'::uuid, 'dev.fixture.plus.trial@nanobio.local', 'Fixture Plus Trial', 'email'),
      ('11000000-0000-4000-8000-000000000006'::uuid, '21000000-0000-4000-8000-000000000006'::uuid, 'dev.fixture.plus.pastdue@nanobio.local', 'Fixture Plus Past Due', 'email'),
      ('11000000-0000-4000-8000-000000000007'::uuid, '21000000-0000-4000-8000-000000000007'::uuid, 'dev.fixture.plus.canceled@nanobio.local', 'Fixture Plus Canceled', 'email'),
      ('11000000-0000-4000-8000-000000000008'::uuid, '21000000-0000-4000-8000-000000000008'::uuid, 'dev.fixture.plus.expired@nanobio.local', 'Fixture Plus Expired', 'email'),
      ('11000000-0000-4000-8000-000000000009'::uuid, '21000000-0000-4000-8000-000000000009'::uuid, 'dev.fixture.family.owner@nanobio.local', 'Fixture Family Owner', 'email'),
      ('11000000-0000-4000-8000-000000000010'::uuid, '21000000-0000-4000-8000-000000000010'::uuid, 'dev.fixture.family.adult@nanobio.local', 'Fixture Family Adult', 'email'),
      ('11000000-0000-4000-8000-000000000011'::uuid, '21000000-0000-4000-8000-000000000011'::uuid, 'dev.fixture.family.member@nanobio.local', 'Fixture Family Member', 'email'),
      ('11000000-0000-4000-8000-000000000012'::uuid, '21000000-0000-4000-8000-000000000012'::uuid, 'dev.fixture.family.child@nanobio.local', 'Fixture Family Child', 'email'),
      ('11000000-0000-4000-8000-000000000013'::uuid, '21000000-0000-4000-8000-000000000013'::uuid, 'dev.fixture.family.viewer@nanobio.local', 'Fixture Family Viewer', 'email'),
      ('11000000-0000-4000-8000-000000000014'::uuid, '21000000-0000-4000-8000-000000000014'::uuid, 'dev.fixture.family.invited@nanobio.local', 'Fixture Family Invited', 'email'),
      ('11000000-0000-4000-8000-000000000015'::uuid, '21000000-0000-4000-8000-000000000015'::uuid, 'dev.fixture.family.removed@nanobio.local', 'Fixture Family Removed', 'email'),
      ('11000000-0000-4000-8000-000000000016'::uuid, '21000000-0000-4000-8000-000000000016'::uuid, 'dev.fixture.family.paused@nanobio.local', 'Fixture Family Paused', 'email'),
      ('11000000-0000-4000-8000-000000000017'::uuid, '21000000-0000-4000-8000-000000000017'::uuid, 'dev.fixture.family.closed@nanobio.local', 'Fixture Family Closed', 'email'),
      ('11000000-0000-4000-8000-000000000018'::uuid, '21000000-0000-4000-8000-000000000018'::uuid, 'dev.fixture.sale.active@nanobio.local', 'Fixture Sale A', 'email'),
      ('11000000-0000-4000-8000-000000000019'::uuid, '21000000-0000-4000-8000-000000000019'::uuid, 'dev.fixture.sale.direct@nanobio.local', 'Fixture Sale B', 'email'),
      ('11000000-0000-4000-8000-000000000020'::uuid, '21000000-0000-4000-8000-000000000020'::uuid, 'dev.fixture.sale.customer@nanobio.local', 'Fixture Sale Customer C', 'email'),
      ('11000000-0000-4000-8000-000000000021'::uuid, '21000000-0000-4000-8000-000000000021'::uuid, 'dev.fixture.sale.pending@nanobio.local', 'Fixture Sale Pending', 'email'),
      ('11000000-0000-4000-8000-000000000022'::uuid, '21000000-0000-4000-8000-000000000022'::uuid, 'dev.fixture.sale.suspended@nanobio.local', 'Fixture Sale Suspended', 'email'),
      ('11000000-0000-4000-8000-000000000023'::uuid, '21000000-0000-4000-8000-000000000023'::uuid, 'dev.fixture.sale.closed@nanobio.local', 'Fixture Sale Closed', 'email'),
      ('11000000-0000-4000-8000-000000000024'::uuid, '21000000-0000-4000-8000-000000000024'::uuid, 'dev.fixture.wellness@nanobio.local', 'Fixture Wellness', 'email'),
      ('11000000-0000-4000-8000-000000000025'::uuid, '21000000-0000-4000-8000-000000000025'::uuid, 'dev.fixture.admin.finance@nanobio.local', 'Fixture Finance Admin', 'email'),
      ('11000000-0000-4000-8000-000000000026'::uuid, '21000000-0000-4000-8000-000000000026'::uuid, 'dev.fixture.admin.support@nanobio.local', 'Fixture Support Admin', 'email'),
      ('11000000-0000-4000-8000-000000000027'::uuid, '21000000-0000-4000-8000-000000000027'::uuid, 'dev.fixture.admin.content@nanobio.local', 'Fixture Content Admin', 'email'),
      ('11000000-0000-4000-8000-000000000028'::uuid, '21000000-0000-4000-8000-000000000028'::uuid, 'dev.fixture.admin.operations@nanobio.local', 'Fixture Operations Admin', 'email'),
      ('11000000-0000-4000-8000-000000000029'::uuid, '21000000-0000-4000-8000-000000000029'::uuid, 'dev.fixture.admin.only@nanobio.local', 'Fixture Admin Only', 'email'),
      ('11000000-0000-4000-8000-000000000030'::uuid, '21000000-0000-4000-8000-000000000030'::uuid, 'dev.fixture.admin.revoked@nanobio.local', 'Fixture Revoked Admin', 'email')
  ) as t(user_id, identity_id, email, full_name, provider)
)
insert into auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at,
  created_at, updated_at
)
select
  identity_id,
  user_id,
  user_id::text,
  jsonb_build_object(
    'sub', user_id::text,
    'email', email,
    'email_verified', true,
    'phone_verified', false,
    'full_name', full_name,
    'seed_fixture', 'dev-sandbox-comprehensive-v1'
  ),
  provider,
  now(), now(), now()
from fixture_users
on conflict (provider, provider_id) do update
set
  user_id = excluded.user_id,
  identity_data = excluded.identity_data,
  updated_at = now();

update public.users
set
  phone = case id
    when '11000000-0000-4000-8000-000000000002'::uuid then '+84900000002'
    when '11000000-0000-4000-8000-000000000003'::uuid then '+84900000003'
    when '11000000-0000-4000-8000-000000000018'::uuid then '+84900000018'
    when '11000000-0000-4000-8000-000000000019'::uuid then '+84900000019'
    when '11000000-0000-4000-8000-000000000020'::uuid then '+84900000020'
    else phone
  end,
  onboarding_status = case id
    when '11000000-0000-4000-8000-000000000002'::uuid then 'not_started'::public.nb_onboarding_status
    when '11000000-0000-4000-8000-000000000003'::uuid then 'in_progress'::public.nb_onboarding_status
    else 'completed'::public.nb_onboarding_status
  end,
  onboarding_completed_at = case
    when id in (
      '11000000-0000-4000-8000-000000000002'::uuid,
      '11000000-0000-4000-8000-000000000003'::uuid
    ) then null
    else now() - interval '1 day'
  end,
  app_access_mode = case
    when id = '11000000-0000-4000-8000-000000000029'::uuid then 'admin'
    when id in (
      '11000000-0000-4000-8000-000000000025'::uuid,
      '11000000-0000-4000-8000-000000000026'::uuid,
      '11000000-0000-4000-8000-000000000027'::uuid,
      '11000000-0000-4000-8000-000000000028'::uuid
    ) then 'both'
    else 'user'
  end,
  admin_status = case
    when id = '11000000-0000-4000-8000-000000000030'::uuid then 'closed'
    when id = '11000000-0000-4000-8000-000000000022'::uuid then 'suspended'
    else 'active'
  end,
  updated_at = now()
where id between
  '11000000-0000-4000-8000-000000000001'::uuid and
  '11000000-0000-4000-8000-000000000030'::uuid;

-- Make the historical Admin a dual-surface account; its super_admin role is
-- created by the legacy bootstrap and remains the stable Storage uploader.
update public.users
set app_access_mode = 'both', updated_at = now()
where id = '10000000-0000-4000-8000-000000000104'::uuid;

-- ---------------------------------------------------------------------------
-- Membership, entitlement and quota cohorts.
-- ---------------------------------------------------------------------------

insert into public.membership_subscriptions (
  id, user_id, plan_code, status, source, starts_at, ends_at,
  current_period_start, current_period_end, provider, provider_subscription_id,
  metadata
)
values
  ('31000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'free', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'free-ready-v1', '{"fixture":true,"scenario":"free-ready"}'::jsonb),
  ('31000000-0000-4000-8000-000000000003'::uuid, '11000000-0000-4000-8000-000000000003'::uuid, 'free', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'free-exhausted-v1', '{"fixture":true,"scenario":"free-exhausted"}'::jsonb),
  ('31000000-0000-4000-8000-000000000004'::uuid, '11000000-0000-4000-8000-000000000004'::uuid, 'plus', 'active', 'payment_provider', now() - interval '7 days', now() + interval '23 days', now() - interval '7 days', now() + interval '23 days', 'fixture', 'plus-active-v1', '{"fixture":true,"scenario":"plus-active"}'::jsonb),
  ('31000000-0000-4000-8000-000000000005'::uuid, '11000000-0000-4000-8000-000000000005'::uuid, 'plus', 'trialing', 'promotion', now() - interval '2 days', now() + interval '12 days', now() - interval '2 days', now() + interval '12 days', 'fixture', 'plus-trial-v1', '{"fixture":true,"scenario":"plus-trial"}'::jsonb),
  ('31000000-0000-4000-8000-000000000006'::uuid, '11000000-0000-4000-8000-000000000006'::uuid, 'plus', 'past_due', 'payment_provider', now() - interval '29 days', now() + interval '1 day', now() - interval '29 days', now() + interval '1 day', 'fixture', 'plus-past-due-v1', '{"fixture":true,"scenario":"plus-past-due"}'::jsonb),
  ('31000000-0000-4000-8000-000000000007'::uuid, '11000000-0000-4000-8000-000000000007'::uuid, 'plus', 'canceled', 'payment_provider', now() - interval '31 days', now() - interval '1 day', now() - interval '31 days', now() - interval '1 day', 'fixture', 'plus-canceled-v1', '{"fixture":true,"scenario":"plus-canceled"}'::jsonb),
  ('31000000-0000-4000-8000-000000000008'::uuid, '11000000-0000-4000-8000-000000000008'::uuid, 'plus', 'expired', 'payment_provider', now() - interval '61 days', now() - interval '31 days', now() - interval '61 days', now() - interval '31 days', 'fixture', 'plus-expired-v1', '{"fixture":true,"scenario":"plus-expired"}'::jsonb),
  ('31000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, 'family_plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'family-owner-v1', '{"fixture":true,"scenario":"family-active"}'::jsonb),
  ('31000000-0000-4000-8000-000000000016'::uuid, '11000000-0000-4000-8000-000000000016'::uuid, 'family_plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'family-paused-v1', '{"fixture":true,"scenario":"family-paused"}'::jsonb),
  ('31000000-0000-4000-8000-000000000017'::uuid, '11000000-0000-4000-8000-000000000017'::uuid, 'family_plus', 'active', 'manual', now() - interval '37 days', now() + interval '3 days', now() - interval '37 days', now() + interval '3 days', 'fixture', 'family-closed-v1', '{"fixture":true,"scenario":"family-closed"}'::jsonb),
  ('31000000-0000-4000-8000-000000000018'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 'plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'sale-a-v1', '{"fixture":true,"scenario":"sale-a"}'::jsonb),
  ('31000000-0000-4000-8000-000000000019'::uuid, '11000000-0000-4000-8000-000000000019'::uuid, 'plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'sale-b-v1', '{"fixture":true,"scenario":"sale-b"}'::jsonb),
  ('31000000-0000-4000-8000-000000000020'::uuid, '11000000-0000-4000-8000-000000000020'::uuid, 'plus', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'sale-c-v1', '{"fixture":true,"scenario":"sale-c"}'::jsonb),
  ('31000000-0000-4000-8000-000000000024'::uuid, '11000000-0000-4000-8000-000000000024'::uuid, 'free', 'active', 'manual', now() - interval '7 days', now() + interval '30 days', now() - interval '7 days', now() + interval '30 days', 'fixture', 'wellness-v1', '{"fixture":true,"scenario":"wellness"}'::jsonb)
on conflict (id) do update
set
  plan_code = excluded.plan_code,
  status = excluded.status,
  source = excluded.source,
  starts_at = excluded.starts_at,
  ends_at = excluded.ends_at,
  current_period_start = excluded.current_period_start,
  current_period_end = excluded.current_period_end,
  metadata = excluded.metadata,
  updated_at = now();

insert into public.usage_quota_counters (
  id, user_id, feature_key, period_key, plan_code, used_count, limit_count,
  reset_at
)
values
  (
    '32000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('day', now(), 'Asia/Ho_Chi_Minh'),
    'free', 1, 3,
    public.usage_quota_reset_at('day', now(), 'Asia/Ho_Chi_Minh')
  ),
  (
    '32000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000003'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('day', now(), 'Asia/Ho_Chi_Minh'),
    'free', 3, 3,
    public.usage_quota_reset_at('day', now(), 'Asia/Ho_Chi_Minh')
  ),
  (
    '32000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'personal_schedule_generation',
    public.usage_quota_period_key('month', now(), 'Asia/Ho_Chi_Minh'),
    'free', 1, 3,
    public.usage_quota_reset_at('month', now(), 'Asia/Ho_Chi_Minh')
  ),
  (
    '32000000-0000-4000-8000-000000000024'::uuid,
    '11000000-0000-4000-8000-000000000024'::uuid,
    'personal_schedule_generation',
    public.usage_quota_period_key('month', now(), 'Asia/Ho_Chi_Minh'),
    'free', 1, 3,
    public.usage_quota_reset_at('month', now(), 'Asia/Ho_Chi_Minh')
  )
on conflict (user_id, feature_key, period_key) do update
set
  used_count = excluded.used_count,
  plan_code = excluded.plan_code,
  limit_count = excluded.limit_count,
  reset_at = excluded.reset_at,
  updated_at = now();

insert into public.usage_events (
  id, user_id, feature_key, period_key, count_delta, idempotency_key,
  event_source, metadata
)
values
  (
    '33000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('day', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-free-ready-ai-chat', 'admin',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000003'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('day', now(), 'Asia/Ho_Chi_Minh'),
    3, 'fixture-free-exhausted-ai-chat', 'admin',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'personal_schedule_generation',
    public.usage_quota_period_key('month', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-free-ready-schedule-request', 'trusted_backend',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh","source":"quota_commit"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000005'::uuid,
    '11000000-0000-4000-8000-000000000004'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('none', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-plus-edge-ai-chat', 'edge_function',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000006'::uuid,
    '11000000-0000-4000-8000-000000000005'::uuid,
    'ai_chat_message',
    public.usage_quota_period_key('none', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-plus-sql-job-ai-chat', 'sql_job',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh"}'::jsonb
  ),
  (
    '33000000-0000-4000-8000-000000000024'::uuid,
    '11000000-0000-4000-8000-000000000024'::uuid,
    'personal_schedule_generation',
    public.usage_quota_period_key('month', now(), 'Asia/Ho_Chi_Minh'),
    1, 'fixture-wellness-reward-request', 'trusted_backend',
    '{"fixture":true,"timezone":"Asia/Ho_Chi_Minh","source":"quota_commit"}'::jsonb
  )
on conflict (user_id, feature_key, idempotency_key) do update
set count_delta = excluded.count_delta,
    event_source = excluded.event_source,
    metadata = excluded.metadata;

-- ---------------------------------------------------------------------------
-- Health/cloud-sync representative rows. They use the Free-ready self subject
-- and remain ordinary user-owned data, unlike the server-owned reward rows.
-- ---------------------------------------------------------------------------

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_profiles (
  id, user_id, subject_id, occupation, height_cm, weight_kg, bmi,
  blood_pressure, blood_sugar
)
select
  '40000000-0000-4000-8000-000000000001'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture analyst', 165, 60, 22.04, '118/76', '5.2'
from s
on conflict (subject_id) do update
set occupation = excluded.occupation, height_cm = excluded.height_cm,
    weight_kg = excluded.weight_kg, bmi = excluded.bmi,
    blood_pressure = excluded.blood_pressure, blood_sugar = excluded.blood_sugar,
    updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.lifestyle_habits (
  id, user_id, subject_id, skip_breakfast, eat_late, eat_sweet, eat_oily,
  low_vegetable, low_water, fast_food, alcohol, coffee_high, sleep_quality,
  activity_level, water_per_day
)
select
  '40000000-0000-4000-8000-000000000002'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  false, true, false, false, false, false, false, false, false,
  'good', 'moderate', '2000ml'
from s
on conflict (subject_id) do update
set skip_breakfast = excluded.skip_breakfast, eat_late = excluded.eat_late,
    sleep_quality = excluded.sleep_quality, activity_level = excluded.activity_level,
    water_per_day = excluded.water_per_day, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_goals (
  id, user_id, subject_id, goal_code, goal_name, is_active
)
select
  '40000000-0000-4000-8000-000000000003'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture-balance', 'Fixture balanced routine', true
from s
on conflict (subject_id, goal_code) do update
set goal_name = excluded.goal_name, is_active = excluded.is_active;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_conditions (
  id, user_id, subject_id, condition_code, condition_name, severity_level
)
select
  '40000000-0000-4000-8000-000000000004'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture-monitor', 'Fixture monitoring only', 1
from s
on conflict (subject_id, condition_code) do update
set condition_name = excluded.condition_name, severity_level = excluded.severity_level;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.food_allergies (
  id, user_id, subject_id, allergy_name, note
)
select
  '40000000-0000-4000-8000-000000000005'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture ingredient', 'Synthetic fixture only'
from s
on conflict (subject_id, allergy_name) do update set note = excluded.note;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.medical_treatments (
  id, user_id, subject_id, treatment_name, medication_name, note
)
select
  '40000000-0000-4000-8000-000000000006'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture review', 'Fixture placebo', 'No real medical information'
from s
on conflict (id) do update
set treatment_name = excluded.treatment_name, medication_name = excluded.medication_name,
    note = excluded.note;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.survey_answers (
  id, user_id, subject_id, question_code, answer_value
)
select
  '40000000-0000-4000-8000-000000000007'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture-consent', 'accepted'
from s
on conflict (subject_id, question_code) do update set answer_value = excluded.answer_value;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.meal_plans (
  id, user_id, subject_id, plan_date, meal_type, meal_name, description,
  calories, protein, carbs, fat, fiber, water_ml, meal_order, start_time,
  end_time, cooking_instructions, is_completed, ai_generated
)
select
  '40000000-0000-4000-8000-000000000008'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date, 'breakfast',
  'Fixture breakfast', 'Synthetic meal plan', 420, 22, 54, 12, 8, 300, 1,
  time '07:00', time '07:30', 'Fixture instructions', false, true
from s
on conflict (subject_id, plan_date, meal_order) do update
set meal_name = excluded.meal_name, description = excluded.description,
    is_completed = excluded.is_completed, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.daily_health_tasks (
  id, user_id, subject_id, task_date, task_code, category, title, description,
  target_value, current_value, unit, is_completed, sort_order, source,
  encouragement
)
select
  '40000000-0000-4000-8000-000000000009'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date, 'fixture-water',
  'hydration', 'Fixture hydration task', 'Synthetic task', 2000, 1200, 'ml',
  false, 1, 'fixture', 'Keep going'
from s
on conflict (subject_id, task_date, task_code) do update
set current_value = excluded.current_value, is_completed = excluded.is_completed,
    updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.notifications (
  id, user_id, subject_id, title, body, type, is_read, source_type, source_id,
  scheduled_at, notification_id, action_status, payload
)
select
  '40000000-0000-4000-8000-000000000010'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture reminder', 'Synthetic notification', 'fixture', false,
  'fixture', 'fixture-notification', now(), 19001, 'pending',
  '{"fixture":true}'::jsonb
from s
on conflict (id) do update
set title = excluded.title, body = excluded.body, is_read = excluded.is_read,
    updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
), rows as (
  select *
  from (
    values
      ('40000000-0000-4000-8000-000000000016'::uuid, 'Fixture completed reminder', 'Synthetic completed notification', true, 'fixture-notification-completed', 19002, 'completed', now() - interval '20 minutes'),
      ('40000000-0000-4000-8000-000000000017'::uuid, 'Fixture skipped reminder', 'Synthetic skipped notification', true, 'fixture-notification-skipped', 19003, 'skipped', now() - interval '10 minutes')
  ) as t(id, title, body, is_read, source_id, notification_id, action_status, responded_at)
)
insert into public.notifications (
  id, user_id, subject_id, title, body, type, is_read, source_type, source_id,
  scheduled_at, notification_id, action_status, responded_at, payload
)
select
  r.id, '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  r.title, r.body, 'fixture', r.is_read, 'fixture', r.source_id,
  now(), r.notification_id, r.action_status, r.responded_at,
  jsonb_build_object('fixture', true, 'action_status', r.action_status)
from s cross join rows r
on conflict (id) do update
set title = excluded.title, body = excluded.body, is_read = excluded.is_read,
    action_status = excluded.action_status, responded_at = excluded.responded_at,
    payload = excluded.payload, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_tracking_logs (
  id, user_id, subject_id, weight_kg, calories, water_ml, sleep_hours,
  stress_level, steps_count, heart_rate_bpm, oxygen_saturation, daily_score,
  mood, log_date
)
select
  '40000000-0000-4000-8000-000000000011'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  60, 1800, 1600, 7.5, 2, 7200, 72, 98, 82, 'steady',
  (now() at time zone 'Asia/Ho_Chi_Minh')::date
from s
on conflict (subject_id, log_date) do update
set water_ml = excluded.water_ml, steps_count = excluded.steps_count,
    daily_score = excluded.daily_score, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.health_score_ledgers (
  id, user_id, subject_id, period_start, period_end, score, formula_version,
  breakdown, idempotency_key, calculated_at
)
select
  '40000000-0000-4000-8000-000000000012'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date - 6,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  82, 'fixture-v1', '{"fixture":true}'::jsonb, 'fixture-health-score-v1', now()
from s
on conflict (subject_id, period_start, period_end, formula_version) do update
set score = excluded.score, breakdown = excluded.breakdown, updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.nutrition_logs (
  id, user_id, subject_id, food_name, calories, protein, carbs, fat, meal_type,
  eaten_at
)
select
  '40000000-0000-4000-8000-000000000013'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'Fixture salad', 210, 8, 28, 7, 'lunch', now()
from s
on conflict (id) do update set food_name = excluded.food_name, eaten_at = excluded.eaten_at;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.ai_insights (
  id, user_id, subject_id, insight_type, title, content, risk_level
)
select
  '40000000-0000-4000-8000-000000000014'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture', 'Fixture insight', 'Synthetic insight only', 'low'
from s
on conflict (id) do update
set title = excluded.title, content = excluded.content, risk_level = excluded.risk_level;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.ai_recommendations (
  id, user_id, subject_id, recommendation_type, title, description, action_text,
  is_read
)
select
  '40000000-0000-4000-8000-000000000015'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid, s.id,
  'fixture', 'Fixture recommendation', 'Synthetic recommendation', 'Review', false
from s
on conflict (id) do update
set title = excluded.title, description = excluded.description,
    action_text = excluded.action_text, is_read = excluded.is_read;

insert into public.personal_schedule_ai_requests (
  request_id, user_id, actor_mode, status, start_date, days, meal_count,
  exercise_count, schedule_item_count, error_code, completed_at
)
values
  (
    'fixture-free-ready-schedule-request',
    '11000000-0000-4000-8000-000000000002'::uuid,
    'member_new', 'succeeded', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 3, 3, 10, null, now()
  ),
  (
    'fixture-free-ready-schedule-generating',
    '11000000-0000-4000-8000-000000000002'::uuid,
    'member_new', 'generating', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 0, 0, 0, null, null
  ),
  (
    'fixture-free-ready-schedule-failed',
    '11000000-0000-4000-8000-000000000002'::uuid,
    'member_new', 'failed', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 0, 0, 0, 'fixture_generation_failed', now() - interval '1 hour'
  ),
  (
    'fixture-guest-initial-schedule-request',
    '11000000-0000-4000-8000-000000000003'::uuid,
    'initial_guest', 'succeeded', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 3, 3, 10, null, now() - interval '2 hours'
  ),
  (
    'fixture-wellness-reward-request',
    '11000000-0000-4000-8000-000000000024'::uuid,
    'member_new', 'succeeded', (now() at time zone 'Asia/Ho_Chi_Minh')::date,
    1, 3, 3, 11, null, now() - interval '3 hours'
  )
on conflict (request_id) do update
set status = excluded.status, completed_at = excluded.completed_at,
    schedule_item_count = excluded.schedule_item_count,
    error_code = excluded.error_code, updated_at = now();

-- Reference catalogs are intentionally small but complete enough for a bare
-- local/sandbox rebuild to exercise every public catalog table.
insert into public.meal_catalog (
  code, meal_type, meal_name, description, cooking_instructions, calories,
  protein, carbs, fat, fiber, water_ml, is_active
)
values (
  'fixture-meal-breakfast-v1', 'breakfast', 'Fixture balanced breakfast',
  'Synthetic reference meal; not nutrition guidance.',
  'Fixture-only preparation instructions.', 420, 22, 54, 12, 8, 300, true
)
on conflict (code) do update
set meal_type = excluded.meal_type, meal_name = excluded.meal_name,
    description = excluded.description,
    cooking_instructions = excluded.cooking_instructions,
    calories = excluded.calories, protein = excluded.protein,
    carbs = excluded.carbs, fat = excluded.fat, fiber = excluded.fiber,
    water_ml = excluded.water_ml, is_active = excluded.is_active,
    updated_at = now();

insert into public.exercise_catalog (
  code, category, title, description, unit, encouragement, min_target,
  max_target, default_target, intensity_level, is_active
)
values (
  'fixture-exercise-walk-v1', 'cardio', 'Fixture walk',
  'Synthetic reference exercise; not medical advice.', 'minutes',
  'Fixture encouragement.', 5, 60, 20, 'low', true
)
on conflict (code) do update
set category = excluded.category, title = excluded.title,
    description = excluded.description, unit = excluded.unit,
    encouragement = excluded.encouragement, min_target = excluded.min_target,
    max_target = excluded.max_target, default_target = excluded.default_target,
    intensity_level = excluded.intensity_level, is_active = excluded.is_active,
    updated_at = now();

insert into public.schedule_task_catalog (
  code, category, title, description, start_time, end_time, target_value,
  unit, encouragement, sort_order, is_active
)
values (
  'fixture-task-hydration-v1', 'hydration', 'Fixture hydration task',
  'Synthetic reference task.', time '07:00', time '21:00', 2000, 'ml',
  'Fixture encouragement.', 1, true
)
on conflict (code) do update
set category = excluded.category, title = excluded.title,
    description = excluded.description, start_time = excluded.start_time,
    end_time = excluded.end_time, target_value = excluded.target_value,
    unit = excluded.unit, encouragement = excluded.encouragement,
    sort_order = excluded.sort_order, is_active = excluded.is_active,
    updated_at = now();

-- The wellness account gets a complete 11-item manifest. The first two items
-- deliberately have a current 30-minute proof window for the Storage runner.
-- The runner, not static SQL, creates the completed/undone proof lifecycle;
-- the remaining rows are void historical cases or a future eligible case.
with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000024'::uuid
    and subject_type = 'self'
  limit 1
), items as (
  select *
  from (
    values
      ('44000000-0000-4000-8000-000000000001'::uuid, 0, 'Fixture proof active', 'wellness'),
      ('44000000-0000-4000-8000-000000000002'::uuid, 1, 'Fixture proof reversed', 'wellness'),
      ('44000000-0000-4000-8000-000000000003'::uuid, 2, 'Fixture completed', 'wellness'),
      ('44000000-0000-4000-8000-000000000004'::uuid, 3, 'Fixture undone', 'wellness'),
      ('44000000-0000-4000-8000-000000000005'::uuid, 4, 'Fixture void', 'wellness'),
      ('44000000-0000-4000-8000-000000000006'::uuid, 5, 'Fixture item 6', 'wellness'),
      ('44000000-0000-4000-8000-000000000007'::uuid, 6, 'Fixture item 7', 'wellness'),
      ('44000000-0000-4000-8000-000000000008'::uuid, 7, 'Fixture item 8', 'wellness'),
      ('44000000-0000-4000-8000-000000000009'::uuid, 8, 'Fixture item 9', 'wellness'),
      ('44000000-0000-4000-8000-000000000010'::uuid, 9, 'Fixture item 10', 'wellness'),
      ('44000000-0000-4000-8000-000000000011'::uuid, 10, 'Fixture proof future', 'wellness')
  ) as t(id, item_order, title, category)
)
insert into public.lifestyle_schedule_items (
  id, user_id, subject_id, schedule_date, start_time, end_time, title,
  description, category, source_type, source_id, target_value, current_value,
  unit, is_completed, sort_order, ai_generated, encouragement
)
select
  i.id,
  '11000000-0000-4000-8000-000000000024'::uuid,
  s.id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  ((now() at time zone 'Asia/Ho_Chi_Minh') + make_interval(mins => i.item_order))::time,
  ((now() at time zone 'Asia/Ho_Chi_Minh') + make_interval(mins => i.item_order + 20))::time,
  i.title, 'Synthetic schedule fixture', i.category, 'fixture',
  'fixture-wellness-manifest', 1, 0, 'task', false, i.item_order, true,
  'Fixture encouragement'
from s cross join items i
on conflict (id) do update
set title = excluded.title, description = excluded.description,
    schedule_date = excluded.schedule_date, start_time = excluded.start_time,
    end_time = excluded.end_time, updated_at = now();

-- ---------------------------------------------------------------------------
-- FamilyPlus: an active linked group, plus paused and closed groups. Owner is
-- represented by family_groups.owner_user_id; family_members uses reachable
-- app roles only (adult/member/child/viewer).
-- ---------------------------------------------------------------------------

insert into public.family_groups (
  id, owner_user_id, plan_subscription_id, display_name, status,
  last_idempotency_key
)
values
  (
    '50000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000009'::uuid,
    '31000000-0000-4000-8000-000000000009'::uuid,
    'Fixture Active Family', 'active', 'fixture-family-active-v1'
  ),
  (
    '50000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000016'::uuid,
    '31000000-0000-4000-8000-000000000016'::uuid,
    'Fixture Paused Family', 'paused', 'fixture-family-paused-v1'
  ),
  (
    '50000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000017'::uuid,
    '31000000-0000-4000-8000-000000000017'::uuid,
    'Fixture Closed Family', 'closed', 'fixture-family-closed-v1'
  )
on conflict (id) do update
set display_name = excluded.display_name, status = excluded.status,
    plan_subscription_id = excluded.plan_subscription_id,
    last_idempotency_key = excluded.last_idempotency_key, updated_at = now();

-- The app-owned family subjects belong to the FamilyPlus owner while retaining
-- an optional linked account. This is the same ownership boundary enforced by
-- the FamilyPlus RPC, rather than reusing each member's self subject.
insert into public.health_subjects (
  id, owner_user_id, linked_user_id, family_group_id, subject_type,
  display_name, relationship, is_active
)
values
  ('52000000-0000-4000-8000-000000000010'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000010'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Adult', 'adult', true),
  ('52000000-0000-4000-8000-000000000011'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000011'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Member', 'member', true),
  ('52000000-0000-4000-8000-000000000012'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000012'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Child', 'child', true),
  ('52000000-0000-4000-8000-000000000013'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000013'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Viewer', 'viewer', true),
  ('52000000-0000-4000-8000-000000000014'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000014'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Invited', 'member', true),
  ('52000000-0000-4000-8000-000000000015'::uuid, '11000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000015'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, 'family_member', 'Fixture Removed', 'member', false),
  ('52000000-0000-4000-8000-000000000016'::uuid, '11000000-0000-4000-8000-000000000016'::uuid, null, '50000000-0000-4000-8000-000000000002'::uuid, 'family_member', 'Fixture Paused Subject', 'adult', true)
on conflict (id) do update
set
  owner_user_id = excluded.owner_user_id,
  linked_user_id = excluded.linked_user_id,
  family_group_id = excluded.family_group_id,
  subject_type = excluded.subject_type,
  display_name = excluded.display_name,
  relationship = excluded.relationship,
  is_active = excluded.is_active,
  updated_at = now();

with family_subjects as (
  select *
  from (
    values
      ('11000000-0000-4000-8000-000000000010'::uuid, '52000000-0000-4000-8000-000000000010'::uuid),
      ('11000000-0000-4000-8000-000000000011'::uuid, '52000000-0000-4000-8000-000000000011'::uuid),
      ('11000000-0000-4000-8000-000000000012'::uuid, '52000000-0000-4000-8000-000000000012'::uuid),
      ('11000000-0000-4000-8000-000000000013'::uuid, '52000000-0000-4000-8000-000000000013'::uuid),
      ('11000000-0000-4000-8000-000000000014'::uuid, '52000000-0000-4000-8000-000000000014'::uuid),
      ('11000000-0000-4000-8000-000000000015'::uuid, '52000000-0000-4000-8000-000000000015'::uuid),
      ('11000000-0000-4000-8000-000000000016'::uuid, '52000000-0000-4000-8000-000000000016'::uuid)
  ) as t(user_id, id)
)
insert into public.family_members (
  id, family_group_id, subject_id, user_id, invited_email, display_name, role,
  status, can_view, can_edit, last_idempotency_key, joined_at
)
select
  v.id, v.family_group_id, fs.id, v.user_id, v.invited_email, v.display_name,
  v.role, v.status, v.can_view, v.can_edit, v.idempotency_key, v.joined_at
from (
  values
    ('51000000-0000-4000-8000-000000000010'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000010'::uuid, null::text, 'Fixture Adult', 'adult', 'active', true, true, 'fixture-family-adult-v1', now() - interval '5 days'),
    ('51000000-0000-4000-8000-000000000011'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000011'::uuid, null::text, 'Fixture Member', 'member', 'active', true, false, 'fixture-family-member-v1', now() - interval '5 days'),
    ('51000000-0000-4000-8000-000000000012'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000012'::uuid, null::text, 'Fixture Child', 'child', 'active', true, false, 'fixture-family-child-v1', now() - interval '5 days'),
    ('51000000-0000-4000-8000-000000000013'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000013'::uuid, null::text, 'Fixture Viewer', 'viewer', 'active', true, false, 'fixture-family-viewer-v1', now() - interval '5 days'),
    ('51000000-0000-4000-8000-000000000014'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000014'::uuid, 'dev.fixture.family.invited@nanobio.local', 'Fixture Invited', 'member', 'invited', false, false, 'fixture-family-invited-v1', null::timestamptz),
    ('51000000-0000-4000-8000-000000000015'::uuid, '50000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000015'::uuid, null::text, 'Fixture Removed', 'member', 'removed', false, false, 'fixture-family-removed-v1', now() - interval '10 days'),
    ('51000000-0000-4000-8000-000000000016'::uuid, '50000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000016'::uuid, null::text, 'Fixture Paused Member', 'adult', 'active', true, true, 'fixture-family-paused-member-v1', now() - interval '5 days')
) as v(id, family_group_id, user_id, invited_email, display_name, role, status, can_view, can_edit, idempotency_key, joined_at)
join family_subjects fs on fs.user_id = v.user_id
on conflict (id) do update
set
  user_id = excluded.user_id, invited_email = excluded.invited_email,
  display_name = excluded.display_name, role = excluded.role, status = excluded.status,
  can_view = excluded.can_view, can_edit = excluded.can_edit,
  last_idempotency_key = excluded.last_idempotency_key,
  joined_at = excluded.joined_at, updated_at = now();


-- ---------------------------------------------------------------------------
-- Sale: A -> B -> Customer C. C's succeeded payment produces the only
-- direct 10% commission for B; no seed creates an upstream commission.
-- ---------------------------------------------------------------------------

insert into public.sale_profiles (
  user_id, status, approved_at, suspended_at, closed_at, terms_version,
  terms_accepted_at, participation_device_hash, note, metadata
)
values
  ('11000000-0000-4000-8000-000000000018'::uuid, 'active', now() - interval '20 days', null, null, 'fixture-v1', now() - interval '21 days', 'fixture-sale-a-device', 'Fixture Sale A active', '{"fixture":true,"graph":"A"}'::jsonb),
  ('11000000-0000-4000-8000-000000000019'::uuid, 'active', now() - interval '19 days', null, null, 'fixture-v1', now() - interval '20 days', 'fixture-sale-b-device', 'Fixture Sale B active', '{"fixture":true,"graph":"B"}'::jsonb),
  ('11000000-0000-4000-8000-000000000021'::uuid, 'pending', null, null, null, 'fixture-v1', now() - interval '2 days', 'fixture-sale-pending-device', 'Fixture Sale pending review', '{"fixture":true}'::jsonb),
  ('11000000-0000-4000-8000-000000000022'::uuid, 'suspended', now() - interval '30 days', now() - interval '2 days', null, 'fixture-v1', now() - interval '31 days', 'fixture-sale-suspended-device', 'Fixture Sale suspended', '{"fixture":true}'::jsonb),
  ('11000000-0000-4000-8000-000000000023'::uuid, 'closed', now() - interval '60 days', null, now() - interval '3 days', 'fixture-v1', now() - interval '61 days', 'fixture-sale-closed-device', 'Fixture Sale closed', '{"fixture":true}'::jsonb)
on conflict (user_id) do update
set
  status = excluded.status, approved_at = excluded.approved_at,
  suspended_at = excluded.suspended_at, closed_at = excluded.closed_at,
  terms_version = excluded.terms_version, terms_accepted_at = excluded.terms_accepted_at,
  participation_device_hash = excluded.participation_device_hash,
  note = excluded.note, metadata = excluded.metadata, updated_at = now();

insert into public.referral_codes (
  code, sale_user_id, status, created_at, revoked_at
)
values
  ('FIXTURE-A', '11000000-0000-4000-8000-000000000018'::uuid, 'active', now() - interval '20 days', null),
  ('FIXTURE-B', '11000000-0000-4000-8000-000000000019'::uuid, 'active', now() - interval '19 days', null),
  ('FIXTURE-CLOSED', '11000000-0000-4000-8000-000000000023'::uuid, 'revoked', now() - interval '59 days', now() - interval '3 days')
on conflict (code) do update
set sale_user_id = excluded.sale_user_id, status = excluded.status,
    revoked_at = excluded.revoked_at;

insert into public.referral_relationships (
  id, referrer_user_id, referred_user_id, referral_code, accepted_at, source,
  status, device_hash, metadata
)
values
  (
    '62000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000019'::uuid,
    'FIXTURE-A', now() - interval '18 days', 'signup', 'active',
    'fixture-referral-a-b', '{"fixture":true,"edge":"A->B"}'::jsonb
  ),
  (
    '62000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000019'::uuid,
    '11000000-0000-4000-8000-000000000020'::uuid,
    'FIXTURE-B', now() - interval '17 days', 'signup', 'active',
    'fixture-referral-b-c', '{"fixture":true,"edge":"B->C","direct_only":true}'::jsonb
  ),
  (
    '62000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    'FIXTURE-A', now() - interval '1 day', 'manual_admin', 'voided',
    'fixture-referral-voided', '{"fixture":true,"scenario":"voided"}'::jsonb
  )
on conflict (id) do update
set
  referrer_user_id = excluded.referrer_user_id,
  referred_user_id = excluded.referred_user_id,
  referral_code = excluded.referral_code,
  accepted_at = excluded.accepted_at, source = excluded.source,
  status = excluded.status, device_hash = excluded.device_hash,
  metadata = excluded.metadata;

insert into public.commission_rates (code, rate, is_active)
values ('direct_referral', 0.1000, true)
on conflict (code) do update set rate = excluded.rate, is_active = excluded.is_active,
  updated_at = now();

insert into public.payment_events (
  id, payer_user_id, subscription_id, plan_code, provider, provider_event_id,
  amount_cents, list_price_cents, commission_base_cents, currency, status,
  paid_at, reviewed_by, reviewed_at, review_reason, idempotency_key,
  raw_event_hash, metadata
)
values
  (
    '63000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000020'::uuid,
    '31000000-0000-4000-8000-000000000020'::uuid,
    'plus', 'fixture', 'payment-c-succeeded-v1', 199000, 199000, 199000,
    'VND', 'succeeded', now() - interval '2 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '2 days',
    'Fixture payment succeeded', 'fixture-payment-c-succeeded-v1',
    'fixture-payment-hash-c-1',
    '{"fixture":true,"commission_base_cents":199000,"graph":"A->B->C"}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    null, 'plus', 'fixture', 'payment-pending-v1', 199000, 199000, 199000,
    'VND', 'pending', null, null, null, null, 'fixture-payment-pending-v1',
    'fixture-payment-hash-pending', '{"fixture":true}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    null, 'plus', 'fixture', 'payment-refunded-v1', 199000, 199000, 199000,
    'VND', 'refunded', now() - interval '10 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '9 days',
    'Fixture refund', 'fixture-payment-refunded-v1',
    'fixture-payment-hash-refunded', '{"fixture":true}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000022'::uuid,
    null, 'plus', 'fixture', 'payment-chargeback-v1', 199000, 199000, 199000,
    'VND', 'chargeback', now() - interval '12 days',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '11 days',
    'Fixture chargeback', 'fixture-payment-chargeback-v1',
    'fixture-payment-hash-chargeback', '{"fixture":true}'::jsonb
  ),
  (
    '63000000-0000-4000-8000-000000000005'::uuid,
    '11000000-0000-4000-8000-000000000023'::uuid,
    null, 'plus', 'fixture', 'payment-failed-v1', 199000, 199000, 199000,
    'VND', 'failed', null, null, null, 'Fixture payment failed',
    'fixture-payment-failed-v1', 'fixture-payment-hash-failed',
    '{"fixture":true}'::jsonb
  )
on conflict (provider, provider_event_id) do update
set
  status = excluded.status, paid_at = excluded.paid_at,
  reviewed_by = excluded.reviewed_by, reviewed_at = excluded.reviewed_at,
  review_reason = excluded.review_reason, metadata = excluded.metadata;

-- This direct insert supplies historical lifecycle rows for non-succeeded
-- payments. The succeeded C event receives its pending B commission through
-- the database trigger above and is never assigned to Sale A.
insert into public.commission_records (
  id, payment_event_id, receiver_user_id, payer_user_id, source_referral_id,
  rate, amount_cents, currency, status, available_at
)
values
  (
    '64000000-0000-4000-8000-000000000002'::uuid,
    '63000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000019'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    '62000000-0000-4000-8000-000000000003'::uuid,
    0.1000, 19900, 'VND', 'approved', now() - interval '1 day'
  ),
  (
    '64000000-0000-4000-8000-000000000003'::uuid,
    '63000000-0000-4000-8000-000000000003'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000021'::uuid,
    '62000000-0000-4000-8000-000000000003'::uuid,
    0.1000, 19900, 'VND', 'reversed', now() - interval '8 days'
  ),
  (
    '64000000-0000-4000-8000-000000000004'::uuid,
    '63000000-0000-4000-8000-000000000004'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    '11000000-0000-4000-8000-000000000022'::uuid,
    null, 0.1000, 19900, 'VND', 'paid', now() - interval '10 days'
  )
on conflict (payment_event_id, receiver_user_id) do update
set status = excluded.status, available_at = excluded.available_at,
    amount_cents = excluded.amount_cents, updated_at = now();

insert into public.sale_payout_profiles (
  sale_user_id, citizen_id, bank_bin, bank_name, bank_account_number,
  bank_account_name, updated_by, metadata
)
values (
  '11000000-0000-4000-8000-000000000018'::uuid,
  '000000000000', '9704', 'Fixture Bank', '000018000018',
  'FIXTURE SALE A', '10000000-0000-4000-8000-000000000104'::uuid,
  '{"fixture":true,"all_personal_data_is_fake":true}'::jsonb
)
on conflict (sale_user_id) do update
set citizen_id = excluded.citizen_id, bank_bin = excluded.bank_bin,
    bank_name = excluded.bank_name, bank_account_number = excluded.bank_account_number,
    bank_account_name = excluded.bank_account_name, updated_by = excluded.updated_by,
    metadata = excluded.metadata, updated_at = now();

insert into public.sale_point_adjustments (
  id, sale_user_id, point_delta_cents, currency, status, reason, reviewed_by,
  idempotency_key, metadata
)
values
  (
    '65000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    2000000, 'VND', 'approved', 'Fixture point credit',
    '10000000-0000-4000-8000-000000000104'::uuid,
    'fixture-sale-point-credit-v1', '{"fixture":true}'::jsonb
  ),
  (
    '65000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000018'::uuid,
    -100000, 'VND', 'reversed', 'Fixture reversal',
    '10000000-0000-4000-8000-000000000104'::uuid,
    'fixture-sale-point-reversal-v1', '{"fixture":true}'::jsonb
  )
on conflict (idempotency_key) do update
set point_delta_cents = excluded.point_delta_cents, status = excluded.status,
    reason = excluded.reason, reviewed_by = excluded.reviewed_by,
    metadata = excluded.metadata;

insert into public.sale_point_conversions (
  id, sale_user_id, requested_point_cents, point_to_money_rate,
  money_amount_cents, currency, status, idempotency_key, requested_at,
  reviewed_by, reviewed_at, review_reason, paid_at, metadata
)
values
  ('66000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'requested', 'fixture-conversion-requested-v1', now() - interval '6 days', null, null, null, null, '{"fixture":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'pending_review', 'fixture-conversion-pending-v1', now() - interval '5 days', null, null, null, null, '{"fixture":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000003'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'approved', 'fixture-conversion-approved-v1', now() - interval '4 days', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '3 days', 'Fixture approval for Storage upload', null, '{"fixture":true,"storage_runner":"upload_here"}'::jsonb),
  ('66000000-0000-4000-8000-000000000007'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'approved', 'fixture-conversion-approved-retained-v1', now() - interval '2 days', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 day', 'Fixture approved lifecycle retained after optional payout finalization', null, '{"fixture":true,"retain_approved_state":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000004'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'paid', 'fixture-conversion-paid-v1', now() - interval '10 days', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '9 days', 'Fixture paid without Storage object', now() - interval '8 days', '{"fixture":true,"no_static_storage_object":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000005'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'rejected', 'fixture-conversion-rejected-v1', now() - interval '12 days', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '11 days', 'Fixture reject', null, '{"fixture":true}'::jsonb),
  ('66000000-0000-4000-8000-000000000006'::uuid, '11000000-0000-4000-8000-000000000018'::uuid, 500000, 1, 500000, 'VND', 'cancelled', 'fixture-conversion-cancelled-v1', now() - interval '14 days', null, null, 'Fixture cancel', null, '{"fixture":true}'::jsonb)
on conflict (sale_user_id, idempotency_key) where idempotency_key is not null do update
set
  status = excluded.status, reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at, review_reason = excluded.review_reason,
  paid_at = excluded.paid_at, metadata = excluded.metadata, updated_at = now();

-- ---------------------------------------------------------------------------
-- Admin roles, audit, export and reconciliation surfaces.
-- ---------------------------------------------------------------------------

insert into public.admin_user_roles (
  user_id, role_code, scope, is_active, granted_by, granted_at, revoked_at
)
values
  ('11000000-0000-4000-8000-000000000025'::uuid, 'finance_admin', 'global', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000026'::uuid, 'support_admin', 'global', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000027'::uuid, 'content_admin', 'global', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000028'::uuid, 'operations_admin', 'global', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000029'::uuid, 'super_admin', 'admin-only', true, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '7 days', null),
  ('11000000-0000-4000-8000-000000000030'::uuid, 'support_admin', 'global', false, '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '30 days', now() - interval '1 day')
on conflict (user_id, role_code, scope) do update
set
  is_active = excluded.is_active, granted_by = excluded.granted_by,
  granted_at = excluded.granted_at, revoked_at = excluded.revoked_at;

insert into public.admin_audit_events (
  id, actor_id, action, target_type, target_id, reason, idempotency_key,
  metadata
)
values
  (
    '67000000-0000-4000-8000-000000000001'::uuid,
    '10000000-0000-4000-8000-000000000104'::uuid,
    'fixture_seed', 'sale_point_conversion',
    '66000000-0000-4000-8000-000000000003',
    'Fixture Admin audit', 'fixture-admin-audit-v1',
    '{"fixture":true,"no_production_data":true}'::jsonb
  )
on conflict (action, idempotency_key) do update
set reason = excluded.reason, metadata = excluded.metadata;

insert into public.system_config_versions (
  id, config_key, config_value, status, reason, created_by, created_at
)
values
  (
    '68000000-0000-4000-8000-000000000001'::uuid,
    'fixture_comprehensive_seed',
    '{"enabled":true,"contract":"dev-sandbox-comprehensive-v1","timezone":"Asia/Ho_Chi_Minh"}'::jsonb,
    'active', 'Comprehensive local/sandbox fixture marker.',
    '10000000-0000-4000-8000-000000000104'::uuid, now()
  ),
  (
    '68000000-0000-4000-8000-000000000002'::uuid,
    'fixture_comprehensive_seed_draft',
    '{"enabled":false,"contract":"dev-sandbox-comprehensive-v1","timezone":"Asia/Ho_Chi_Minh"}'::jsonb,
    'draft', 'Comprehensive local/sandbox fixture draft configuration.',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '2 minutes'
  ),
  (
    '68000000-0000-4000-8000-000000000003'::uuid,
    'fixture_comprehensive_seed_archived',
    '{"enabled":false,"contract":"dev-sandbox-comprehensive-v1","timezone":"Asia/Ho_Chi_Minh"}'::jsonb,
    'archived', 'Comprehensive local/sandbox fixture archived configuration.',
    '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 minute'
  )
on conflict (id) do update
set config_value = excluded.config_value, status = excluded.status,
    reason = excluded.reason, created_by = excluded.created_by;

insert into public.report_exports (
  id, report_type, filters, status, reason, requested_by, completed_at
)
values
  ('69000000-0000-4000-8000-000000000001'::uuid, 'fixture', '{"range":"today"}'::jsonb, 'requested', 'Fixture requested export', '10000000-0000-4000-8000-000000000104'::uuid, null),
  ('69000000-0000-4000-8000-000000000002'::uuid, 'fixture', '{"range":"week"}'::jsonb, 'generating', 'Fixture generating export', '10000000-0000-4000-8000-000000000104'::uuid, null),
  ('69000000-0000-4000-8000-000000000003'::uuid, 'fixture', '{"range":"month"}'::jsonb, 'ready', 'Fixture ready export', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 day'),
  ('69000000-0000-4000-8000-000000000004'::uuid, 'fixture', '{"range":"year"}'::jsonb, 'failed', 'Fixture failed export', '10000000-0000-4000-8000-000000000104'::uuid, now() - interval '1 day')
on conflict (id) do update
set status = excluded.status, reason = excluded.reason, completed_at = excluded.completed_at;

insert into public.admin_reconciliation_runs (
  id, scope, status, reason, created_by, idempotency_key, metadata, completed_at
)
values
  ('6a000000-0000-4000-8000-000000000001'::uuid, 'payments', 'open', 'Fixture open reconciliation', '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-reconciliation-open-v1', '{"fixture":true}'::jsonb, null),
  ('6a000000-0000-4000-8000-000000000002'::uuid, 'payments', 'resolved', 'Fixture resolved reconciliation', '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-reconciliation-resolved-v1', '{"fixture":true}'::jsonb, now() - interval '1 day'),
  ('6a000000-0000-4000-8000-000000000003'::uuid, 'payments', 'failed', 'Fixture failed reconciliation', '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-reconciliation-failed-v1', '{"fixture":true}'::jsonb, now() - interval '1 day')
on conflict (idempotency_key) do update
set status = excluded.status, reason = excluded.reason,
    metadata = excluded.metadata, completed_at = excluded.completed_at;

insert into public.admin_reconciliation_discrepancies (
  id, run_id, target_type, target_id, severity, status, summary, metadata,
  reviewed_by, reviewed_at, review_reason
)
values
  ('6b000000-0000-4000-8000-000000000001'::uuid, '6a000000-0000-4000-8000-000000000001'::uuid, 'payment', '63000000-0000-4000-8000-000000000002', 'low', 'open', 'Fixture open discrepancy', '{"fixture":true}'::jsonb, null, null, null),
  ('6b000000-0000-4000-8000-000000000002'::uuid, '6a000000-0000-4000-8000-000000000001'::uuid, 'payment', '63000000-0000-4000-8000-000000000003', 'medium', 'needs_follow_up', 'Fixture follow-up discrepancy', '{"fixture":true}'::jsonb, '10000000-0000-4000-8000-000000000104'::uuid, now(), 'Fixture follow-up'),
  ('6b000000-0000-4000-8000-000000000003'::uuid, '6a000000-0000-4000-8000-000000000002'::uuid, 'payment', '63000000-0000-4000-8000-000000000004', 'high', 'resolved', 'Fixture resolved discrepancy', '{"fixture":true}'::jsonb, '10000000-0000-4000-8000-000000000104'::uuid, now(), 'Fixture resolved'),
  ('6b000000-0000-4000-8000-000000000004'::uuid, '6a000000-0000-4000-8000-000000000002'::uuid, 'conversion', '66000000-0000-4000-8000-000000000003', 'medium', 'adjusted', 'Fixture adjusted discrepancy', '{"fixture":true}'::jsonb, '10000000-0000-4000-8000-000000000104'::uuid, now(), 'Fixture adjusted'),
  ('6b000000-0000-4000-8000-000000000005'::uuid, '6a000000-0000-4000-8000-000000000003'::uuid, 'payment', '63000000-0000-4000-8000-000000000005', 'low', 'dismissed', 'Fixture dismissed discrepancy', '{"fixture":true}'::jsonb, '10000000-0000-4000-8000-000000000104'::uuid, now(), 'Fixture dismissed')
on conflict (id) do update
set status = excluded.status, summary = excluded.summary, metadata = excluded.metadata,
    reviewed_by = excluded.reviewed_by, reviewed_at = excluded.reviewed_at,
    review_reason = excluded.review_reason;

-- ---------------------------------------------------------------------------
-- Wellness / wallet / voucher data. Proof rows and Storage objects are
-- intentionally absent here: Seed-StorageFixtures.ps1 creates them through
-- the actual Auth + RPC + Storage path after the opt-in demo profile is set.
-- ---------------------------------------------------------------------------

insert into public.guest_schedule_reward_registrations (
  user_id, schedule_request_id, plan_start_date, plan_days, plan_item_count,
  manifest_hash, plan_item_ids, eligible_item_ids,
  first_registration_idempotency_key, registered_item_count
)
values (
  '11000000-0000-4000-8000-000000000003'::uuid,
  'fixture-guest-initial-schedule-request',
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  1, 10,
  repeat('a', 64),
  array[
    '45000000-0000-4000-8000-000000000001'::uuid,
    '45000000-0000-4000-8000-000000000002'::uuid,
    '45000000-0000-4000-8000-000000000003'::uuid,
    '45000000-0000-4000-8000-000000000004'::uuid,
    '45000000-0000-4000-8000-000000000005'::uuid,
    '45000000-0000-4000-8000-000000000006'::uuid,
    '45000000-0000-4000-8000-000000000007'::uuid,
    '45000000-0000-4000-8000-000000000008'::uuid,
    '45000000-0000-4000-8000-000000000009'::uuid,
    '45000000-0000-4000-8000-000000000010'::uuid
  ],
  array[
    '45000000-0000-4000-8000-000000000001'::uuid,
    '45000000-0000-4000-8000-000000000002'::uuid
  ],
  'fixture-guest-registration-v1', 2
)
on conflict (user_id) do update
set
  schedule_request_id = excluded.schedule_request_id,
  plan_start_date = excluded.plan_start_date,
  plan_days = excluded.plan_days,
  plan_item_count = excluded.plan_item_count,
  manifest_hash = excluded.manifest_hash,
  plan_item_ids = excluded.plan_item_ids,
  eligible_item_ids = excluded.eligible_item_ids,
  first_registration_idempotency_key = excluded.first_registration_idempotency_key,
  registered_item_count = excluded.registered_item_count,
  updated_at = now();

insert into public.member_schedule_reward_registrations (
  schedule_request_id, user_id, plan_start_date, plan_days, plan_item_count,
  manifest_hash, registration_idempotency_key, registered_item_count
)
values (
  'fixture-wellness-reward-request',
  '11000000-0000-4000-8000-000000000024'::uuid,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  1, 11, repeat('b', 64), 'fixture-wellness-registration-v1', 11
)
on conflict (schedule_request_id) do update
set
  user_id = excluded.user_id,
  plan_start_date = excluded.plan_start_date,
  plan_days = excluded.plan_days,
  plan_item_count = excluded.plan_item_count,
  manifest_hash = excluded.manifest_hash,
  registration_idempotency_key = excluded.registration_idempotency_key,
  registered_item_count = excluded.registered_item_count,
  updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000024'::uuid
    and subject_type = 'self'
  limit 1
), rows as (
  select *
  from (
    values
      ('70000000-0000-4000-8000-000000000001'::uuid, '44000000-0000-4000-8000-000000000001'::uuid, 0, 'eligible'),
      ('70000000-0000-4000-8000-000000000002'::uuid, '44000000-0000-4000-8000-000000000002'::uuid, 1, 'eligible'),
      ('70000000-0000-4000-8000-000000000003'::uuid, '44000000-0000-4000-8000-000000000003'::uuid, 2, 'void'),
      ('70000000-0000-4000-8000-000000000004'::uuid, '44000000-0000-4000-8000-000000000004'::uuid, 3, 'void'),
      ('70000000-0000-4000-8000-000000000005'::uuid, '44000000-0000-4000-8000-000000000005'::uuid, 4, 'void'),
      ('70000000-0000-4000-8000-000000000006'::uuid, '44000000-0000-4000-8000-000000000006'::uuid, 5, 'void'),
      ('70000000-0000-4000-8000-000000000007'::uuid, '44000000-0000-4000-8000-000000000007'::uuid, 6, 'void'),
      ('70000000-0000-4000-8000-000000000008'::uuid, '44000000-0000-4000-8000-000000000008'::uuid, 7, 'void'),
      ('70000000-0000-4000-8000-000000000009'::uuid, '44000000-0000-4000-8000-000000000009'::uuid, 8, 'void'),
      ('70000000-0000-4000-8000-000000000010'::uuid, '44000000-0000-4000-8000-000000000010'::uuid, 9, 'void'),
      ('70000000-0000-4000-8000-000000000011'::uuid, '44000000-0000-4000-8000-000000000011'::uuid, 10, 'eligible')
  ) as t(id, schedule_item_id, item_order, status)
)
insert into public.schedule_reward_eligibilities (
  id, user_id, subject_id, schedule_item_id, schedule_request_id, schedule_date,
  start_time, window_start, window_end, title_snapshot, category_snapshot,
  source_type_snapshot, source_id_snapshot, status, registration_idempotency_key
)
select
  r.id,
  '11000000-0000-4000-8000-000000000024'::uuid,
  s.id,
  r.schedule_item_id,
  'fixture-wellness-reward-request',
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  ((now() at time zone 'Asia/Ho_Chi_Minh') + make_interval(mins => r.item_order - 5))::time,
  case
    when r.item_order in (0, 1) then now() - interval '1 minute' + r.item_order * interval '30 seconds'
    when r.item_order = 10 then now() + interval '1 hour'
    else now() - interval '3 hours' + make_interval(mins => r.item_order)
  end,
  case
    when r.item_order in (0, 1) then now() + interval '29 minutes' + r.item_order * interval '30 seconds'
    when r.item_order = 10 then now() + interval '1 hour 30 minutes'
    else now() - interval '2 hours 30 minutes' + make_interval(mins => r.item_order)
  end,
  concat('Fixture wellness item ', r.item_order + 1),
  'wellness', 'fixture', 'fixture-wellness-manifest', r.status,
  'fixture-wellness-registration-v1'
from s cross join rows r
on conflict (id) do update
set
  schedule_item_id = excluded.schedule_item_id,
  schedule_request_id = excluded.schedule_request_id,
  schedule_date = excluded.schedule_date,
  start_time = excluded.start_time,
  window_start = excluded.window_start,
  window_end = excluded.window_end,
  title_snapshot = excluded.title_snapshot,
  status = excluded.status,
  registration_idempotency_key = excluded.registration_idempotency_key,
  updated_at = now();

-- These historical attempts belong to the separate Free-ready cohort, so the
-- Storage runner for dev.fixture.wellness never attempts to delete a fake
-- nonexistent static object path.
with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000002'::uuid
    and subject_type = 'self'
  limit 1
)
insert into public.schedule_reward_eligibilities (
  id, user_id, subject_id, schedule_item_id, schedule_request_id, schedule_date,
  start_time, window_start, window_end, title_snapshot, category_snapshot,
  source_type_snapshot, source_id_snapshot, status, registration_idempotency_key
)
select
  '70000000-0000-4000-8000-000000000012'::uuid,
  '11000000-0000-4000-8000-000000000002'::uuid,
  s.id,
  '45000000-0000-4000-8000-000000000001'::uuid,
  'fixture-free-ready-reward-request',
  (now() at time zone 'Asia/Ho_Chi_Minh')::date - 1,
  time '09:00', now() - interval '1 day', now() - interval '1 day' + interval '30 minutes',
  'Fixture historical attempt', 'wellness', 'fixture', 'fixture-free-ready',
  'void', 'fixture-free-ready-registration-v1'
from s
on conflict (id) do update
set status = excluded.status, updated_at = now();

insert into public.schedule_completion_attempts (
  id, eligibility_id, user_id, begin_idempotency_key, finalize_idempotency_key,
  undo_idempotency_key, object_path, status, began_at, finalized_at,
  rejection_code
)
values
  (
    '73000000-0000-4000-8000-000000000001'::uuid,
    '70000000-0000-4000-8000-000000000012'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'fixture-static-begun-v1', null, null,
    '11000000-0000-4000-8000-000000000002/fixture-static-begun.jpg',
    'begun', now() - interval '1 day', null, null
  ),
  (
    '73000000-0000-4000-8000-000000000002'::uuid,
    '70000000-0000-4000-8000-000000000012'::uuid,
    '11000000-0000-4000-8000-000000000002'::uuid,
    'fixture-static-rejected-v1', null, null,
    '11000000-0000-4000-8000-000000000002/fixture-static-rejected.jpg',
    'rejected', now() - interval '2 days', null, 'fixture_rejected'
  )
on conflict (id) do update
set
  status = excluded.status, object_path = excluded.object_path,
  began_at = excluded.began_at, rejection_code = excluded.rejection_code,
  updated_at = now();

-- This module deliberately omits proof rows and Storage object rows; the
-- runner creates immutable schedule evidence only through the real application
-- path. Historical wallet lifecycle rows below use the admin-refund source,
-- so they do not claim a proof-backed schedule completion before the runner.

insert into public.wellness_reward_wallets (
  user_id, pending_points, available_points, lifetime_earned_points,
  lifetime_spent_points, lifetime_refunded_points, lock_version
)
values (
  '11000000-0000-4000-8000-000000000024'::uuid,
  10, 20, 50, 10, 10, 1
)
on conflict (user_id) do update
set
  pending_points = excluded.pending_points,
  available_points = excluded.available_points,
  lifetime_earned_points = excluded.lifetime_earned_points,
  lifetime_spent_points = excluded.lifetime_spent_points,
  lifetime_refunded_points = excluded.lifetime_refunded_points,
  lock_version = excluded.lock_version,
  updated_at = now();

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000024'::uuid
    and subject_type = 'self'
  limit 1
), program as (
  select id
  from public.system_config_versions
  where config_key = 'wellness_reward_program' and status = 'active'
  order by created_at desc
  limit 1
), rows as (
  select *
  from (
    values
      ('74000000-0000-4000-8000-000000000001'::uuid, '75000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'pending', 10, 10, now() + interval '1 day', now() + interval '180 days'),
      ('74000000-0000-4000-8000-000000000002'::uuid, '75000000-0000-4000-8000-000000000002'::uuid, null::uuid, 'available', 10, 10, now() - interval '2 days', now() + interval '180 days'),
      ('74000000-0000-4000-8000-000000000003'::uuid, '75000000-0000-4000-8000-000000000003'::uuid, null::uuid, 'spent', 10, 0, now() - interval '10 days', now() + interval '170 days'),
      ('74000000-0000-4000-8000-000000000004'::uuid, '75000000-0000-4000-8000-000000000004'::uuid, null::uuid, 'expired', 10, 10, now() - interval '200 days', now() - interval '1 day'),
      ('74000000-0000-4000-8000-000000000005'::uuid, '75000000-0000-4000-8000-000000000005'::uuid, null::uuid, 'reversed', 10, 0, now() - interval '5 days', now() + interval '175 days')
  ) as t(ledger_id, allocation_id, eligibility_id, allocation_status, original_points, remaining_points, available_at, expires_at)
)
insert into public.wellness_point_ledgers (
  id, user_id, subject_id, source_type, source_id, schedule_date, points_delta,
  program_code, idempotency_key, event_type, status, title, is_redeemable,
  available_at, expires_at, program_config_id, eligibility_id, metadata
)
select
  r.ledger_id,
  '11000000-0000-4000-8000-000000000024'::uuid,
  s.id,
  'admin_refund',
  r.allocation_id,
  (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  case when r.allocation_status = 'reversed' then -10 else 10 end,
  'wellness_schedule_fixture_v1',
  concat('fixture-wellness-ledger-', r.allocation_status),
  'fixture_reward', r.allocation_status, concat('Fixture ', r.allocation_status),
  true, r.available_at, r.expires_at, program.id, r.eligibility_id,
  '{"fixture":true}'::jsonb
from s cross join program cross join rows r
on conflict (user_id, idempotency_key) do nothing;

with s as (
  select id
  from public.health_subjects
  where owner_user_id = '11000000-0000-4000-8000-000000000024'::uuid
    and subject_type = 'self'
  limit 1
), program as (
  select id
  from public.system_config_versions
  where config_key = 'wellness_reward_program' and status = 'active'
  order by created_at desc
  limit 1
), rows as (
  select *
  from (
    values
      ('75000000-0000-4000-8000-000000000001'::uuid, '74000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'pending', 10, 10, now() + interval '1 day', now() + interval '180 days'),
      ('75000000-0000-4000-8000-000000000002'::uuid, '74000000-0000-4000-8000-000000000002'::uuid, null::uuid, 'available', 10, 10, now() - interval '2 days', now() + interval '180 days'),
      ('75000000-0000-4000-8000-000000000003'::uuid, '74000000-0000-4000-8000-000000000003'::uuid, null::uuid, 'spent', 10, 0, now() - interval '10 days', now() + interval '170 days'),
      ('75000000-0000-4000-8000-000000000004'::uuid, '74000000-0000-4000-8000-000000000004'::uuid, null::uuid, 'expired', 10, 10, now() - interval '200 days', now() - interval '1 day'),
      ('75000000-0000-4000-8000-000000000005'::uuid, '74000000-0000-4000-8000-000000000005'::uuid, null::uuid, 'reversed', 10, 0, now() - interval '5 days', now() + interval '175 days')
  ) as t(id, ledger_id, eligibility_id, allocation_status, original_points, remaining_points, available_at, expires_at)
)
insert into public.wellness_point_allocations (
  id, user_id, subject_id, ledger_id, eligibility_id, source_type, source_id,
  original_points, remaining_points, status, available_at, expires_at,
  program_config_id
)
select
  r.id,
  '11000000-0000-4000-8000-000000000024'::uuid,
  s.id,
  r.ledger_id, r.eligibility_id,
  'admin_refund',
  r.id,
  r.original_points, r.remaining_points, r.allocation_status,
  r.available_at, r.expires_at, program.id
from s cross join program cross join rows r
on conflict (id) do update
set
  remaining_points = excluded.remaining_points,
  status = excluded.status,
  available_at = excluded.available_at,
  expires_at = excluded.expires_at,
  updated_at = now();

insert into public.wellness_reward_offers (
  id, offer_code, title, description, provider_name, cost_points,
  eligible_plan_codes, available_from, available_until, voucher_expires_at,
  is_active, metadata, created_by, updated_by
)
values (
  '76000000-0000-4000-8000-000000000001'::uuid,
  'FIXTURE-REWARD', 'Fixture reward', 'Synthetic reward only',
  'Fixture Provider', 10, array['free','plus','family_plus']::text[],
  now() - interval '30 days', now() + interval '30 days',
  now() + interval '90 days', true,
  '{"fixture":true,"not_for_production":true}'::jsonb,
  '10000000-0000-4000-8000-000000000104'::uuid,
  '10000000-0000-4000-8000-000000000104'::uuid
)
on conflict (offer_code) do update
set
  title = excluded.title, description = excluded.description,
  cost_points = excluded.cost_points, available_from = excluded.available_from,
  available_until = excluded.available_until,
  voucher_expires_at = excluded.voucher_expires_at, is_active = excluded.is_active,
  metadata = excluded.metadata, updated_by = excluded.updated_by, updated_at = now();

insert into public.wellness_reward_codes (
  id, offer_id, code_value, code_hash, status, voucher_expires_at,
  assigned_user_id, assigned_redemption_id, issued_at, retired_at, imported_by,
  import_batch_key
)
values
  ('77000000-0000-4000-8000-000000000001'::uuid, '76000000-0000-4000-8000-000000000001'::uuid, 'FIXTURE-AVAILABLE-001', repeat('1', 64), 'available', now() + interval '90 days', null, null, null, null, '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-voucher-v1'),
  ('77000000-0000-4000-8000-000000000002'::uuid, '76000000-0000-4000-8000-000000000001'::uuid, 'FIXTURE-ISSUED-002', repeat('2', 64), 'issued', now() + interval '90 days', '11000000-0000-4000-8000-000000000024'::uuid, '78000000-0000-4000-8000-000000000001'::uuid, now() - interval '2 days', null, '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-voucher-v1'),
  ('77000000-0000-4000-8000-000000000003'::uuid, '76000000-0000-4000-8000-000000000001'::uuid, 'FIXTURE-RETIRED-003', repeat('3', 64), 'retired', now() - interval '1 day', null, null, null, now() - interval '1 day', '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-voucher-v1'),
  ('77000000-0000-4000-8000-000000000004'::uuid, '76000000-0000-4000-8000-000000000001'::uuid, 'FIXTURE-CANCELLED-004', repeat('4', 64), 'issued', now() + interval '90 days', '11000000-0000-4000-8000-000000000024'::uuid, '78000000-0000-4000-8000-000000000002'::uuid, now() - interval '4 days', null, '10000000-0000-4000-8000-000000000104'::uuid, 'fixture-voucher-v1')
on conflict (code_hash) do update
set
  status = excluded.status, voucher_expires_at = excluded.voucher_expires_at,
  assigned_user_id = excluded.assigned_user_id,
  assigned_redemption_id = excluded.assigned_redemption_id,
  issued_at = excluded.issued_at, retired_at = excluded.retired_at,
  imported_by = excluded.imported_by, import_batch_key = excluded.import_batch_key;

insert into public.wellness_reward_redemptions (
  id, user_id, offer_id, reward_code_id, offer_title_snapshot,
  provider_name_snapshot, points_spent, status, voucher_expires_at,
  idempotency_key, issued_at, cancelled_at, cancelled_by, cancellation_reason,
  refund_allocation_id
)
values
  (
    '78000000-0000-4000-8000-000000000001'::uuid,
    '11000000-0000-4000-8000-000000000024'::uuid,
    '76000000-0000-4000-8000-000000000001'::uuid,
    '77000000-0000-4000-8000-000000000002'::uuid,
    'Fixture reward', 'Fixture Provider', 10, 'issued', now() + interval '90 days',
    'fixture-redemption-issued-v1', now() - interval '2 days', null, null, null, null
  ),
  (
    '78000000-0000-4000-8000-000000000002'::uuid,
    '11000000-0000-4000-8000-000000000024'::uuid,
    '76000000-0000-4000-8000-000000000001'::uuid,
    '77000000-0000-4000-8000-000000000004'::uuid,
    'Fixture reward', 'Fixture Provider', 10, 'cancelled', now() + interval '90 days',
    'fixture-redemption-cancelled-v1', now() - interval '4 days',
    now() - interval '3 days', '10000000-0000-4000-8000-000000000104'::uuid,
    'Fixture cancellation', '75000000-0000-4000-8000-000000000005'::uuid
  )
on conflict (id) do update
set
  status = excluded.status, cancelled_at = excluded.cancelled_at,
  cancelled_by = excluded.cancelled_by, cancellation_reason = excluded.cancellation_reason,
  refund_allocation_id = excluded.refund_allocation_id, updated_at = now();

insert into public.wellness_redemption_allocation_usages (
  redemption_id, allocation_id, points_used
)
values
  ('78000000-0000-4000-8000-000000000001'::uuid, '75000000-0000-4000-8000-000000000003'::uuid, 10),
  ('78000000-0000-4000-8000-000000000002'::uuid, '75000000-0000-4000-8000-000000000005'::uuid, 10)
on conflict (redemption_id, allocation_id) do update
set points_used = excluded.points_used;

-- ---------------------------------------------------------------------------
-- Nabi notification catalog, occurrence and event lifecycles.
-- ---------------------------------------------------------------------------

insert into public.nabi_notification_definitions (
  id, notification_id, content_version, category, priority, policy_key,
  primary_action_key, secondary_action_key, allowed_channels, title_template,
  body_template, config, effective_from, effective_until, status, reason,
  created_by
)
values
  (
    '80000000-0000-4000-8000-000000000001'::uuid,
    'fixture-nabi-draft', 1, 'contextual', 100, 'partial_day',
    'today_tasks', null, array['in_app']::text[], 'Fixture draft',
    'Synthetic Nabi draft', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'draft',
    'Fixture draft definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000002'::uuid,
    'fixture-nabi-active', 1, 'reward', 200, 'reward_ready',
    'reward_box', 'today_tasks', array['in_app']::text[], 'Fixture active',
    'Synthetic Nabi active', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture active definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000003'::uuid,
    'fixture-nabi-archived', 1, 'retention', 50, 'return_72h',
    'dashboard_today', null, array['in_app']::text[], 'Fixture archived',
    'Synthetic Nabi archived', '{"fixture":true}'::jsonb,
    now() - interval '31 days', now() - interval '1 day', 'archived',
    'Fixture archived definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000004'::uuid,
    'fixture-nabi-milestone', 1, 'milestone', 300, 'milestone_reached',
    'dashboard_today', null, array['in_app']::text[], 'Fixture milestone',
    'Synthetic Nabi milestone', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture milestone definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000005'::uuid,
    'fixture-nabi-subscription', 1, 'subscription', 300, 'subscription_due',
    'membership', null, array['in_app']::text[], 'Fixture subscription',
    'Synthetic Nabi subscription', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture subscription definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000006'::uuid,
    'fixture-nabi-report', 1, 'report', 300, 'report_ready',
    'health_report', null, array['in_app']::text[], 'Fixture report',
    'Synthetic Nabi report', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture report definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000007'::uuid,
    'fixture-nabi-care', 1, 'care', 300, 'care_reminder',
    'today_tasks', null, array['in_app']::text[], 'Fixture care',
    'Synthetic Nabi care', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture care definition', '10000000-0000-4000-8000-000000000104'::uuid
  ),
  (
    '80000000-0000-4000-8000-000000000008'::uuid,
    'fixture-nabi-profile', 1, 'profile', 300, 'profile_incomplete',
    'profile', null, array['in_app']::text[], 'Fixture profile',
    'Synthetic Nabi profile', '{"fixture":true}'::jsonb,
    now() - interval '1 day', now() + interval '30 days', 'active',
    'Fixture profile definition', '10000000-0000-4000-8000-000000000104'::uuid
  )
on conflict (notification_id, content_version) do update
set
  category = excluded.category, priority = excluded.priority,
  policy_key = excluded.policy_key, primary_action_key = excluded.primary_action_key,
  secondary_action_key = excluded.secondary_action_key,
  allowed_channels = excluded.allowed_channels, title_template = excluded.title_template,
  body_template = excluded.body_template, config = excluded.config,
  effective_from = excluded.effective_from, effective_until = excluded.effective_until,
  status = excluded.status, reason = excluded.reason, created_by = excluded.created_by;

insert into public.nabi_notification_user_states (
  id, user_id, notification_id, content_version, source_event_id, status,
  eligible_at, presented_at, opened_at, deferred_until, actioned_at,
  converted_at, expires_at, display_count, dismiss_count, primary_click_count,
  secondary_click_count, last_session_id, last_screen_key, membership_plan,
  billing_cycle, safe_metadata
)
values
  ('81000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-eligible', 'eligible', now() - interval '10 minutes', null, null, null, null, null, now() + interval '1 day', 0, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-queued', 'queued', now() - interval '20 minutes', null, null, null, null, null, now() + interval '1 day', 0, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000003'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-presented', 'presented', now() - interval '30 minutes', now() - interval '20 minutes', null, null, null, null, now() + interval '1 day', 1, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000004'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-collapsed', 'collapsed', now() - interval '40 minutes', now() - interval '35 minutes', null, null, null, null, now() + interval '1 day', 1, 1, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000005'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-opened', 'opened', now() - interval '50 minutes', now() - interval '45 minutes', now() - interval '44 minutes', null, null, null, now() + interval '1 day', 1, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000006'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-deferred', 'deferred', now() - interval '60 minutes', now() - interval '55 minutes', null, now() + interval '1 hour', null, null, now() + interval '1 day', 1, 1, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000007'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-actioned', 'actioned', now() - interval '70 minutes', now() - interval '65 minutes', now() - interval '64 minutes', null, now() - interval '63 minutes', null, now() + interval '1 day', 1, 0, 1, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000008'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-converted', 'converted', now() - interval '80 minutes', now() - interval '75 minutes', now() - interval '74 minutes', null, now() - interval '73 minutes', now() - interval '72 minutes', now() + interval '1 day', 1, 0, 1, 0, 'fixture-session', 'membership', 'plus', 'monthly', '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-expired', 'expired', now() - interval '2 days', null, null, null, null, null, now() - interval '1 day', 0, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000010'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-cancelled', 'cancelled', now() - interval '3 hours', null, null, null, null, null, now() + interval '1 day', 0, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true}'::jsonb),
  ('81000000-0000-4000-8000-000000000011'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, 'fixture-nabi-active', 1, 'fixture-nabi-failed', 'failed', now() - interval '4 hours', now() - interval '3 hours', null, null, null, null, now() + interval '1 day', 1, 0, 0, 0, 'fixture-session', 'home', 'free', null, '{"fixture":true,"result":"fixture_failure"}'::jsonb)
on conflict (user_id, notification_id, source_event_id, content_version) do update
set
  status = excluded.status, eligible_at = excluded.eligible_at,
  presented_at = excluded.presented_at, opened_at = excluded.opened_at,
  deferred_until = excluded.deferred_until, actioned_at = excluded.actioned_at,
  converted_at = excluded.converted_at, expires_at = excluded.expires_at,
  display_count = excluded.display_count, dismiss_count = excluded.dismiss_count,
  primary_click_count = excluded.primary_click_count,
  secondary_click_count = excluded.secondary_click_count,
  last_session_id = excluded.last_session_id, last_screen_key = excluded.last_screen_key,
  membership_plan = excluded.membership_plan, billing_cycle = excluded.billing_cycle,
  safe_metadata = excluded.safe_metadata, updated_at = now();

insert into public.nabi_notification_preferences (
  user_id, proactive_in_app_enabled, push_enabled, analytics_upload_enabled,
  quiet_start_minutes, quiet_end_minutes
)
values (
  '11000000-0000-4000-8000-000000000002'::uuid,
  true, false, true, 1320, 420
)
on conflict (user_id) do update
set
  proactive_in_app_enabled = excluded.proactive_in_app_enabled,
  push_enabled = excluded.push_enabled,
  analytics_upload_enabled = excluded.analytics_upload_enabled,
  quiet_start_minutes = excluded.quiet_start_minutes,
  quiet_end_minutes = excluded.quiet_end_minutes,
  updated_at = now();

insert into public.nabi_notification_events (
  id, user_id, occurrence_id, notification_id, event_name, session_id,
  screen_key, app_version, result_code, safe_metadata, created_at
)
values
  ('82000000-0000-4000-8000-000000000001'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000001'::uuid, 'fixture-nabi-active', 'nabi_notification_eligible', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '10 minutes'),
  ('82000000-0000-4000-8000-000000000002'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000003'::uuid, 'fixture-nabi-active', 'nabi_notification_shown', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '20 minutes'),
  ('82000000-0000-4000-8000-000000000003'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000005'::uuid, 'fixture-nabi-active', 'nabi_notification_opened', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '44 minutes'),
  ('82000000-0000-4000-8000-000000000004'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000004'::uuid, 'fixture-nabi-active', 'nabi_notification_dismissed', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '35 minutes'),
  ('82000000-0000-4000-8000-000000000005'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000007'::uuid, 'fixture-nabi-active', 'nabi_notification_primary_clicked', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '63 minutes'),
  ('82000000-0000-4000-8000-000000000006'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000007'::uuid, 'fixture-nabi-active', 'nabi_notification_secondary_clicked', 'fixture-session', 'home', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '63 minutes'),
  ('82000000-0000-4000-8000-000000000007'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000008'::uuid, 'fixture-nabi-active', 'nabi_upgrade_page_viewed', 'fixture-session', 'membership', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '73 minutes'),
  ('82000000-0000-4000-8000-000000000008'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000008'::uuid, 'fixture-nabi-active', 'nabi_checkout_started', 'fixture-session', 'membership', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '73 minutes'),
  ('82000000-0000-4000-8000-000000000009'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000008'::uuid, 'fixture-nabi-active', 'nabi_conversion_completed', 'fixture-session', 'membership', 'fixture', 'ok', '{"fixture":true}'::jsonb, now() - interval '72 minutes'),
  ('82000000-0000-4000-8000-000000000010'::uuid, '11000000-0000-4000-8000-000000000002'::uuid, '81000000-0000-4000-8000-000000000011'::uuid, 'fixture-nabi-active', 'nabi_notification_failed', 'fixture-session', 'home', 'fixture', 'fixture_failure', '{"fixture":true}'::jsonb, now() - interval '3 hours')
on conflict (id) do update
set
  occurrence_id = excluded.occurrence_id, notification_id = excluded.notification_id,
  event_name = excluded.event_name, session_id = excluded.session_id,
  screen_key = excluded.screen_key, app_version = excluded.app_version,
  result_code = excluded.result_code, safe_metadata = excluded.safe_metadata,
  created_at = excluded.created_at;

-- ---------------------------------------------------------------------------
-- Private Sale proof bucket contract. Object rows remain Storage API-owned.
-- ---------------------------------------------------------------------------

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'sale-payout-proofs',
  'sale-payout-proofs',
  false,
  5242880,
  array['image/jpeg']::text[]
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists sale_payout_proofs_storage_select_admin on storage.objects;
create policy sale_payout_proofs_storage_select_admin
  on storage.objects for select to authenticated
  using (
    bucket_id = 'sale-payout-proofs'
    and public.admin_has_permission('sales.write')
  );

drop policy if exists sale_payout_proofs_storage_insert_admin on storage.objects;
create policy sale_payout_proofs_storage_insert_admin
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'sale-payout-proofs'
    and public.admin_has_permission('sales.write')
    and split_part(name, '/', 1) = 'sale-point-conversions'
    and nullif(split_part(name, '/', 2), '') is not null
  );

-- Paths are unique and evidence is immutable. Do not grant authenticated
-- UPDATE/DELETE access; the service-role cleanup in the local runner is
-- intentionally scoped to fixture prefixes only.
drop policy if exists sale_payout_proofs_storage_update_admin on storage.objects;
drop policy if exists sale_payout_proofs_storage_delete_admin on storage.objects;

-- Rollback-only smoke performs the executable negative assertions under RLS.
-- These static guards stop an accidental fixture edit that would create an
-- invalid referral cycle, exceed the FamilyPlus limit, or pay a second level.
do $$
begin
  if exists (
    select 1
    from public.referral_relationships r
    where r.referrer_user_id = r.referred_user_id
       or exists (
         select 1
         from public.referral_relationships reverse_r
         where reverse_r.referrer_user_id = r.referred_user_id
           and reverse_r.referred_user_id = r.referrer_user_id
           and reverse_r.status = 'active'
       )
  ) then
    raise exception 'FIXTURE_REFERRAL_FRAUD_ASSERTION_FAILED';
  end if;

  if exists (
    select 1
    from public.family_members fm
    join public.family_groups fg on fg.id = fm.family_group_id
    where fm.status = 'active'
    group by fg.id
    having count(*) > 5
  ) then
    raise exception 'FIXTURE_FAMILY_LIMIT_ASSERTION_FAILED';
  end if;

  if exists (
    select 1
    from public.commission_records cr
    join public.payment_events pe on pe.id = cr.payment_event_id
    where pe.id = '63000000-0000-4000-8000-000000000001'::uuid
      and cr.receiver_user_id <> '11000000-0000-4000-8000-000000000019'::uuid
  ) then
    raise exception 'FIXTURE_DIRECT_ONLY_ASSERTION_FAILED';
  end if;
end
$$;
