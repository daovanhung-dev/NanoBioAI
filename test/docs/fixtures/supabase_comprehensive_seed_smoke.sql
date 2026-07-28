-- Local/sandbox smoke assertions for the comprehensive dev fixture.
-- Prerequisite: rebuild a disposable database with docs/supabase/config.sql,
-- apply docs/supabase/20-dev-sandbox-demo-profile.sql, then run
-- tools/supabase/Seed-StorageFixtures.ps1 against that same database.
-- This script always rolls back. It is not a production migration.

begin;

-- Confirm the static account contract, Auth identity coverage, every public
-- table, and the two private proof buckets before checking cross-table flows.
do $$
declare
  v_expected_tables constant text[] := array[
    'users',
    'health_subjects',
    'health_profiles',
    'lifestyle_habits',
    'health_goals',
    'health_conditions',
    'food_allergies',
    'medical_treatments',
    'survey_answers',
    'meal_plans',
    'daily_health_tasks',
    'lifestyle_schedule_items',
    'notifications',
    'health_tracking_logs',
    'health_score_ledgers',
    'wellness_point_ledgers',
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations',
    'personal_schedule_ai_requests',
    'meal_catalog',
    'exercise_catalog',
    'schedule_task_catalog',
    'membership_plans',
    'plan_entitlements',
    'membership_subscriptions',
    'usage_quota_rules',
    'usage_quota_counters',
    'usage_events',
    'family_groups',
    'family_members',
    'sale_profiles',
    'referral_codes',
    'referral_relationships',
    'payment_events',
    'commission_rates',
    'commission_records',
    'admin_roles',
    'admin_permissions',
    'admin_role_permissions',
    'admin_user_roles',
    'admin_audit_events',
    'system_config_versions',
    'report_exports',
    'sale_point_adjustments',
    'admin_reconciliation_runs',
    'admin_reconciliation_discrepancies',
    'sale_point_conversions',
    'sale_payout_profiles',
    'guest_schedule_reward_registrations',
    'member_schedule_reward_registrations',
    'schedule_reward_eligibilities',
    'schedule_completion_attempts',
    'schedule_completion_proofs',
    'wellness_reward_wallets',
    'wellness_point_allocations',
    'wellness_reward_offers',
    'wellness_reward_codes',
    'wellness_reward_redemptions',
    'wellness_redemption_allocation_usages',
    'nabi_notification_definitions',
    'nabi_notification_user_states',
    'nabi_notification_preferences',
    'nabi_notification_events'
  ];
  v_table text;
  v_has_row boolean;
  v_fixture_users integer;
  v_fixture_identities integer;
  v_proof_status text;
  v_cross_user_visible integer;
begin
  if not exists (
    select 1 from auth.users
    where id = '10000000-0000-4000-8000-000000000101'::uuid
      and email = 'dev.free@nanobio.local'
  ) then
    raise exception 'COMPREHENSIVE_SEED_LEGACY_FREE_ACCOUNT_CHANGED';
  end if;
  if not exists (
    select 1 from auth.users
    where id = '10000000-0000-4000-8000-000000000102'::uuid
      and email = 'dev.plus@nanobio.local'
  ) then
    raise exception 'COMPREHENSIVE_SEED_LEGACY_PLUS_ACCOUNT_CHANGED';
  end if;
  if not exists (
    select 1 from auth.users
    where id = '10000000-0000-4000-8000-000000000103'::uuid
      and email = 'dev.family@nanobio.local'
  ) then
    raise exception 'COMPREHENSIVE_SEED_LEGACY_FAMILY_ACCOUNT_CHANGED';
  end if;
  if not exists (
    select 1 from auth.users
    where id = '10000000-0000-4000-8000-000000000104'::uuid
      and email = 'dev.admin@nanobio.local'
  ) then
    raise exception 'COMPREHENSIVE_SEED_LEGACY_ADMIN_ACCOUNT_CHANGED';
  end if;

  select count(*) into v_fixture_users
  from auth.users au
  where au.raw_user_meta_data @> jsonb_build_object(
    'seed_fixture', 'dev-sandbox-comprehensive-v1'
  );
  if v_fixture_users = 0 then
    raise exception 'COMPREHENSIVE_SEED_FIXTURE_AUTH_USERS_MISSING';
  end if;

  select count(*) into v_fixture_identities
  from auth.identities ai
  join auth.users au on au.id = ai.user_id
  where au.raw_user_meta_data @> jsonb_build_object(
    'seed_fixture', 'dev-sandbox-comprehensive-v1'
  );
  if v_fixture_identities <> v_fixture_users then
    raise exception 'COMPREHENSIVE_SEED_AUTH_IDENTITIES_INCOMPLETE';
  end if;

  if not exists (
    select 1
    from public.users u
    join auth.users au on au.id = u.id
    where u.is_anonymous = true and au.is_anonymous = true
  ) then
    raise exception 'COMPREHENSIVE_SEED_ANONYMOUS_COHORT_MISSING';
  end if;

  foreach v_table in array v_expected_tables
  loop
    if to_regclass(format('public.%I', v_table)) is null then
      raise exception 'COMPREHENSIVE_SEED_TABLE_MISSING_%', v_table;
    end if;
    execute format('select exists (select 1 from public.%I)', v_table)
      into v_has_row;
    if not coalesce(v_has_row, false) then
      raise exception 'COMPREHENSIVE_SEED_TABLE_EMPTY_%', v_table;
    end if;
  end loop;

  foreach v_table in array array[
    'schedule-completion-proofs',
    'sale-payout-proofs'
  ]
  loop
    if not exists (
      select 1 from storage.buckets b
      where b.id = v_table and b.public = false
    ) then
      raise exception 'COMPREHENSIVE_SEED_PRIVATE_BUCKET_MISSING_%', v_table;
    end if;
    if not exists (
      select 1 from storage.objects o where o.bucket_id = v_table
    ) then
      raise exception 'COMPREHENSIVE_SEED_STORAGE_OBJECT_MISSING_%', v_table;
    end if;
  end loop;

  foreach v_proof_status in array array['active', 'reversed']
  loop
    if not exists (
      select 1
      from public.schedule_completion_proofs scp
      join public.users wellness on wellness.id = scp.user_id
      join storage.objects so
        on so.bucket_id = scp.bucket_id
       and so.name = scp.object_path
      where wellness.email = 'dev.fixture.wellness@nanobio.local'
        and scp.status = v_proof_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_WELLNESS_PROOF_OBJECT_MISSING_%', v_proof_status;
    end if;
  end loop;

  if not exists (
    select 1
    from public.sale_point_conversions spc
    join storage.objects so
      on so.bucket_id = 'sale-payout-proofs'
     and so.name like 'sale-point-conversions/' || spc.id::text || '/%'
    where spc.id = '66000000-0000-4000-8000-000000000003'::uuid
  ) then
    raise exception 'COMPREHENSIVE_SEED_SALE_PAYOUT_PROOF_OBJECT_MISSING';
  end if;

  perform set_config(
    'request.jwt.claim.sub',
    '11000000-0000-4000-8000-000000000002',
    true
  );
  execute 'set local role authenticated';
  select count(*) into v_cross_user_visible
  from public.schedule_completion_proofs scp
  where scp.user_id = '11000000-0000-4000-8000-000000000024'::uuid;
  execute 'reset role';
  if v_cross_user_visible <> 0 then
    raise exception 'COMPREHENSIVE_SEED_PROOF_RLS_LEAK';
  end if;
end
$$;

-- Membership, effective access, and retry-safe quota behavior use the seeded
-- Free-ready cohort selected by entitlement rather than an invented UUID.
do $$
declare
  v_free uuid;
  v_candidate record;
  v_status text;
  v_at timestamptz := now();
  v_quota_before record;
  v_quota_first record;
  v_quota_retry record;
begin
  foreach v_status in array array[
    'not_started', 'in_progress', 'completed'
  ]
  loop
    if not exists (
      select 1 from public.users where onboarding_status::text = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_ONBOARDING_STATE_MISSING_%', v_status;
    end if;
  end loop;

  foreach v_status in array array['guest', 'free', 'plus', 'family_plus']
  loop
    if not exists (
      select 1 from public.users where product_access_status::text = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_PRODUCT_ACCESS_STATE_MISSING_%', v_status;
    end if;
  end loop;

  foreach v_status in array array[
    'trialing', 'active', 'past_due', 'canceled', 'expired'
  ]
  loop
    if not exists (
      select 1 from public.membership_subscriptions where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_SUBSCRIPTION_STATE_MISSING_%', v_status;
    end if;
  end loop;

  foreach v_status in array array['generating', 'succeeded', 'failed']
  loop
    if not exists (
      select 1 from public.personal_schedule_ai_requests where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_SCHEDULE_REQUEST_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['initial_guest', 'member_new']
  loop
    if not exists (
      select 1 from public.personal_schedule_ai_requests where actor_mode = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_SCHEDULE_REQUEST_ACTOR_MISSING_%', v_status;
    end if;
  end loop;
  if exists (
    select 1
    from public.personal_schedule_ai_requests psar
    join public.users u on u.id = psar.user_id
    where psar.actor_mode = 'initial_guest'
      and u.is_anonymous = true
  ) then
    raise exception 'COMPREHENSIVE_SEED_INITIAL_GUEST_REQUEST_HAS_ANONYMOUS_OWNER';
  end if;
  foreach v_status in array array['pending', 'completed', 'skipped']
  loop
    if not exists (
      select 1 from public.notifications where action_status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_NOTIFICATION_STATE_MISSING_%', v_status;
    end if;
  end loop;

  if not exists (
    select 1 from public.effective_user_access
    where user_id = '10000000-0000-4000-8000-000000000102'::uuid
      and membership_plan::text = 'plus'
  ) then
    raise exception 'COMPREHENSIVE_SEED_PLUS_EFFECTIVE_ACCESS_MISSING';
  end if;
  if not exists (
    select 1 from public.effective_user_access
    where user_id = '10000000-0000-4000-8000-000000000103'::uuid
      and membership_plan::text = 'family_plus'
  ) then
    raise exception 'COMPREHENSIVE_SEED_FAMILY_EFFECTIVE_ACCESS_MISSING';
  end if;
  if not exists (
    select 1
    from public.usage_quota_counters uqc
    join public.users u on u.id = uqc.user_id
    where u.email like 'dev.fixture.%@nanobio.local'
      and uqc.limit_count is not null
      and uqc.used_count >= uqc.limit_count
  ) then
    raise exception 'COMPREHENSIVE_SEED_EXHAUSTED_FREE_QUOTA_MISSING';
  end if;
  foreach v_status in array array[
    'trusted_backend', 'edge_function', 'sql_job', 'admin'
  ]
  loop
    if not exists (
      select 1 from public.usage_events where event_source = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_USAGE_EVENT_SOURCE_MISSING_%', v_status;
    end if;
  end loop;
  if not exists (
    select 1
    from public.personal_schedule_ai_requests psar
    join public.usage_events ue
      on ue.user_id = psar.user_id
     and ue.feature_key = 'personal_schedule_generation'
     and ue.idempotency_key = psar.request_id
    where psar.actor_mode = 'member_new'
      and psar.status = 'succeeded'
      and ue.event_source in ('trusted_backend', 'edge_function', 'sql_job', 'admin')
  ) then
    raise exception 'COMPREHENSIVE_SEED_MEMBER_SCHEDULE_QUOTA_EVENT_MISSING';
  end if;
  if not exists (
    select 1
    from public.guest_schedule_reward_registrations gsrr
    join public.personal_schedule_ai_requests psar
      on psar.user_id = gsrr.user_id
     and psar.request_id = gsrr.schedule_request_id
     and psar.actor_mode = 'initial_guest'
     and psar.status = 'succeeded'
    join public.users u
      on u.id = gsrr.user_id
     and u.is_anonymous = false
    where gsrr.schedule_request_id = 'fixture-guest-initial-schedule-request'
  ) then
    raise exception 'COMPREHENSIVE_SEED_GUEST_REWARD_REGISTRATION_LINK_MISSING';
  end if;
  if not exists (
    select 1
    from public.member_schedule_reward_registrations msrr
    join public.personal_schedule_ai_requests psar
      on psar.user_id = msrr.user_id
     and psar.request_id = msrr.schedule_request_id
     and psar.actor_mode = 'member_new'
     and psar.status = 'succeeded'
    join public.usage_events ue
      on ue.user_id = msrr.user_id
     and ue.feature_key = 'personal_schedule_generation'
     and ue.idempotency_key = msrr.schedule_request_id
    where msrr.schedule_request_id = 'fixture-wellness-reward-request'
  ) then
    raise exception 'COMPREHENSIVE_SEED_MEMBER_REWARD_REGISTRATION_LINK_MISSING';
  end if;

  for v_candidate in
    select u.id
    from public.users u
    join auth.users au on au.id = u.id
    where u.subscription_tier = 'free'
      and au.raw_user_meta_data @> jsonb_build_object(
        'seed_fixture', 'dev-sandbox-comprehensive-v1'
      )
    order by u.email nulls last, u.id
  loop
    perform set_config('request.jwt.claim.sub', v_candidate.id::text, true);
    select * into v_quota_before
    from public.check_usage_quota(
      v_candidate.id,
      'comprehensive-seed-smoke-quota-retry',
      'ai_chat_message',
      'Asia/Ho_Chi_Minh',
      v_at
    );
    if coalesce(v_quota_before.allowed, false) then
      v_free := v_candidate.id;
      exit;
    end if;
  end loop;
  if v_free is null then
    raise exception 'COMPREHENSIVE_SEED_FREE_QUOTA_READY_MISSING';
  end if;

  select * into v_quota_first
  from public.commit_usage_quota(
    v_free,
    'comprehensive-seed-smoke-quota-retry',
    'ai_chat_message',
    'Asia/Ho_Chi_Minh',
    v_at,
    1
  );
  select * into v_quota_retry
  from public.commit_usage_quota(
    v_free,
    'comprehensive-seed-smoke-quota-retry',
    'ai_chat_message',
    'Asia/Ho_Chi_Minh',
    v_at,
    1
  );
  if not coalesce(v_quota_first.committed, false)
     or not coalesce(v_quota_retry.committed, false)
     or v_quota_first.used_count <> v_quota_retry.used_count then
    raise exception 'COMPREHENSIVE_SEED_QUOTA_RETRY_FAILED';
  end if;
end
$$;

-- FamilyPlus fixture must show a real linked member but keep an unrelated
-- authenticated account out of the active group via RLS.
do $$
declare
  v_group uuid;
  v_viewer uuid;
  v_subject uuid;
  v_outsider uuid;
  v_visible_count integer;
  v_state text;
begin
  foreach v_state in array array['active', 'paused', 'closed']
  loop
    if not exists (select 1 from public.family_groups where status = v_state) then
      raise exception 'COMPREHENSIVE_SEED_FAMILY_GROUP_STATE_MISSING_%', v_state;
    end if;
  end loop;
  foreach v_state in array array['adult', 'member', 'child', 'viewer']
  loop
    if not exists (select 1 from public.family_members where role = v_state) then
      raise exception 'COMPREHENSIVE_SEED_FAMILY_ROLE_MISSING_%', v_state;
    end if;
  end loop;
  foreach v_state in array array['invited', 'active', 'removed']
  loop
    if not exists (select 1 from public.family_members where status = v_state) then
      raise exception 'COMPREHENSIVE_SEED_FAMILY_MEMBER_STATE_MISSING_%', v_state;
    end if;
  end loop;
  if not exists (select 1 from public.family_members where can_edit = true)
     or not exists (select 1 from public.family_members where can_edit = false) then
    raise exception 'COMPREHENSIVE_SEED_FAMILY_EDIT_PERMISSION_CASE_MISSING';
  end if;

  select fg.id, viewer.user_id, target.subject_id
    into v_group, v_viewer, v_subject
  from public.family_groups fg
  join public.family_members viewer on viewer.family_group_id = fg.id
  join public.family_members target on target.family_group_id = fg.id
  where fg.status = 'active'
    and viewer.status = 'active'
    and viewer.role = 'viewer'
    and viewer.user_id is not null
    and viewer.can_view = true
    and target.status = 'active'
    and target.role = 'child'
    and target.subject_id <> viewer.subject_id
  order by fg.created_at, viewer.created_at, target.created_at
  limit 1;
  if v_group is null or v_viewer is null or v_subject is null then
    raise exception 'COMPREHENSIVE_SEED_FAMILY_LINKED_VIEWER_MISSING';
  end if;

  if exists (
    select 1
    from public.family_groups fg
    join public.family_members fm on fm.family_group_id = fg.id
    where fm.status = 'active'
    group by fg.id
    having count(*) > 5
  ) then
    raise exception 'COMPREHENSIVE_SEED_FAMILY_MEMBER_LIMIT_EXCEEDED';
  end if;

  select u.id into v_outsider
  from public.users u
  where u.id <> v_viewer
    and u.id <> (
      select owner_user_id from public.family_groups where id = v_group
    )
    and not exists (
      select 1
      from public.family_members fm
      where fm.family_group_id = v_group
        and fm.user_id = u.id
        and fm.status = 'active'
    )
  order by u.email nulls last, u.id
  limit 1;
  if v_outsider is null then
    raise exception 'COMPREHENSIVE_SEED_FAMILY_OUTSIDER_MISSING';
  end if;

  perform set_config('request.jwt.claim.sub', v_outsider::text, true);
  execute 'set local role authenticated';
  select count(*) into v_visible_count
  from public.health_subjects where id = v_subject;
  execute 'reset role';
  if v_visible_count <> 0 then
    raise exception 'COMPREHENSIVE_SEED_FAMILY_RLS_LEAK';
  end if;

  perform set_config('request.jwt.claim.sub', v_viewer::text, true);
  execute 'set local role authenticated';
  select count(*) into v_visible_count
  from public.health_subjects where id = v_subject;
  execute 'reset role';
  if v_visible_count = 0 then
    raise exception 'COMPREHENSIVE_SEED_FAMILY_VIEWER_ACCESS_MISSING';
  end if;
end
$$;

-- The A -> B -> C fixture is direct-only: a succeeded payment by C pays B at
-- 10%, never A or any other upstream Sale account.
do $$
declare
  v_sale_a uuid;
  v_sale_b uuid;
  v_customer_c uuid;
  v_direct_commissions integer;
  v_status text;
begin
  foreach v_status in array array['pending', 'active', 'suspended', 'closed']
  loop
    if not exists (select 1 from public.sale_profiles where status::text = v_status) then
      raise exception 'COMPREHENSIVE_SEED_SALE_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['active', 'revoked']
  loop
    if not exists (select 1 from public.referral_codes where status = v_status) then
      raise exception 'COMPREHENSIVE_SEED_REFERRAL_CODE_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array[
    'pending', 'succeeded', 'refunded', 'chargeback', 'failed'
  ]
  loop
    if not exists (select 1 from public.payment_events where status = v_status) then
      raise exception 'COMPREHENSIVE_SEED_PAYMENT_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['pending', 'approved', 'reversed', 'paid']
  loop
    if not exists (select 1 from public.commission_records where status = v_status) then
      raise exception 'COMPREHENSIVE_SEED_COMMISSION_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array[
    'requested', 'pending_review', 'approved', 'paid', 'rejected', 'cancelled'
  ]
  loop
    if not exists (select 1 from public.sale_point_conversions where status = v_status) then
      raise exception 'COMPREHENSIVE_SEED_CONVERSION_STATE_MISSING_%', v_status;
    end if;
  end loop;

  select r1.referrer_user_id, r1.referred_user_id, r2.referred_user_id
    into v_sale_a, v_sale_b, v_customer_c
  from public.referral_relationships r1
  join public.referral_relationships r2
    on r2.referrer_user_id = r1.referred_user_id
  join auth.users au_a
    on au_a.id = r1.referrer_user_id
   and au_a.raw_user_meta_data @> jsonb_build_object(
     'seed_fixture', 'dev-sandbox-comprehensive-v1'
   )
  join auth.users au_b
    on au_b.id = r1.referred_user_id
   and au_b.raw_user_meta_data @> jsonb_build_object(
     'seed_fixture', 'dev-sandbox-comprehensive-v1'
   )
  join auth.users au_c
    on au_c.id = r2.referred_user_id
   and au_c.raw_user_meta_data @> jsonb_build_object(
     'seed_fixture', 'dev-sandbox-comprehensive-v1'
   )
  join public.sale_profiles sp_a
    on sp_a.user_id = r1.referrer_user_id and sp_a.status = 'active'
  join public.sale_profiles sp_b
    on sp_b.user_id = r2.referrer_user_id and sp_b.status = 'active'
  where r1.status = 'active' and r2.status = 'active'
  order by r1.created_at, r2.created_at
  limit 1;
  if v_sale_a is null or v_sale_b is null or v_customer_c is null then
    raise exception 'COMPREHENSIVE_SEED_DIRECT_REFERRAL_GRAPH_MISSING';
  end if;

  select count(*) into v_direct_commissions
  from public.commission_records cr
  join public.payment_events pe on pe.id = cr.payment_event_id
  where pe.payer_user_id = v_customer_c
    and pe.status = 'succeeded'
    and cr.receiver_user_id = v_sale_b
    and cr.rate = 0.1000;
  if v_direct_commissions = 0 then
    raise exception 'COMPREHENSIVE_SEED_DIRECT_COMMISSION_MISSING';
  end if;
  if exists (
    select 1
    from public.commission_records cr
    join public.payment_events pe on pe.id = cr.payment_event_id
    where pe.payer_user_id = v_customer_c
      and pe.status = 'succeeded'
      and cr.receiver_user_id <> v_sale_b
  ) then
    raise exception 'COMPREHENSIVE_SEED_DIRECT_ONLY_VIOLATION';
  end if;
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
    raise exception 'COMPREHENSIVE_SEED_REFERRAL_FRAUD_STATE';
  end if;
end
$$;

-- Admin, Wellness and Nabi rows are server-owned. Verify all role surfaces,
-- essential lifecycle rows, and an authenticated dual-surface session.
do $$
declare
  v_role text;
  v_status text;
  v_dual_admin uuid;
  v_is_admin boolean;
  v_can_use_user_app boolean;
begin
  foreach v_role in array array[
    'super_admin', 'finance_admin', 'support_admin', 'content_admin',
    'operations_admin'
  ]
  loop
    if not exists (
      select 1 from public.admin_user_roles aur
      where aur.role_code = v_role
        and aur.is_active = true
        and aur.revoked_at is null
    ) then
      raise exception 'COMPREHENSIVE_SEED_ADMIN_ROLE_SURFACE_MISSING_%', v_role;
    end if;
  end loop;
  if not exists (
    select 1 from public.admin_user_roles
    where is_active = false or revoked_at is not null
  ) then
    raise exception 'COMPREHENSIVE_SEED_REVOKED_ADMIN_ROLE_MISSING';
  end if;
  if not exists (select 1 from public.users where app_access_mode = 'admin') then
    raise exception 'COMPREHENSIVE_SEED_ADMIN_ONLY_SURFACE_MISSING';
  end if;
  foreach v_status in array array['active', 'suspended', 'closed']
  loop
    if not exists (
      select 1 from public.users where admin_status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_ADMIN_STATUS_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['draft', 'active', 'archived']
  loop
    if not exists (
      select 1 from public.system_config_versions where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_CONFIG_VERSION_STATE_MISSING_%', v_status;
    end if;
  end loop;

  select u.id into v_dual_admin
  from public.users u
  join public.admin_user_roles aur
    on aur.user_id = u.id
   and aur.is_active = true
   and aur.revoked_at is null
  where u.app_access_mode = 'both'
  order by u.email
  limit 1;
  if v_dual_admin is null then
    raise exception 'COMPREHENSIVE_SEED_DUAL_ADMIN_SURFACE_MISSING';
  end if;
  perform set_config('request.jwt.claim.sub', v_dual_admin::text, true);
  execute 'set local role authenticated';
  select s.is_active, s.can_use_user_app
    into v_is_admin, v_can_use_user_app
  from public.get_my_admin_session() s;
  execute 'reset role';
  if not coalesce(v_is_admin, false) or not coalesce(v_can_use_user_app, false) then
    raise exception 'COMPREHENSIVE_SEED_ADMIN_SESSION_SURFACE_FAILED';
  end if;

  foreach v_status in array array['eligible', 'completed', 'undone', 'void']
  loop
    if not exists (
      select 1 from public.schedule_reward_eligibilities where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_ELIGIBILITY_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['begun', 'finalized', 'undone', 'rejected']
  loop
    if not exists (
      select 1 from public.schedule_completion_attempts where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_ATTEMPT_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['active', 'reversed']
  loop
    if not exists (
      select 1 from public.schedule_completion_proofs where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_PROOF_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['pending', 'available', 'spent', 'expired', 'reversed']
  loop
    if not exists (
      select 1 from public.wellness_point_allocations where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_WALLET_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['available', 'issued', 'retired']
  loop
    if not exists (
      select 1 from public.wellness_reward_codes where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_VOUCHER_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array['issued', 'cancelled']
  loop
    if not exists (
      select 1 from public.wellness_reward_redemptions where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_REDEMPTION_STATE_MISSING_%', v_status;
    end if;
  end loop;

  foreach v_status in array array['draft', 'active', 'archived']
  loop
    if not exists (
      select 1 from public.nabi_notification_definitions where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_NABI_DEFINITION_STATE_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array[
    'contextual', 'milestone', 'subscription', 'retention',
    'reward', 'report', 'care', 'profile'
  ]
  loop
    if not exists (
      select 1 from public.nabi_notification_definitions where category = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_NABI_CATEGORY_MISSING_%', v_status;
    end if;
  end loop;
  foreach v_status in array array[
    'eligible', 'queued', 'presented', 'collapsed', 'opened', 'deferred',
    'actioned', 'converted', 'expired', 'cancelled', 'failed'
  ]
  loop
    if not exists (
      select 1 from public.nabi_notification_user_states where status = v_status
    ) then
      raise exception 'COMPREHENSIVE_SEED_NABI_LIFECYCLE_STATE_MISSING_%', v_status;
    end if;
  end loop;
end
$$;

rollback;
