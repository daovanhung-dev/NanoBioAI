-- Commit de xuat: docs(supabase): them mobile snapshot sync va Sale RPC bao mat
-- NanoBio / BioAI - DRAFT migration.
-- Run AFTER 01-core-auth-profile.sql, 02-health-and-schedule.sql,
-- 03-membership-quota.sql and 05-sale-referral-commission.sql.
--
-- IMPORTANT:
-- 1. Review and run first in Supabase sandbox/staging.
-- 2. `sync_my_mobile_snapshot` is cloud-wins at login and local-wins only for
--    a pending guest snapshot whose cloud onboarding is not completed.
-- 3. This RPC deliberately never accepts membership, entitlement, sale status,
--    commission, payment or another user's subject identity from the mobile app.

begin;

-- ---------------------------------------------------------------------------
-- A. Mobile full-snapshot synchronisation
-- ---------------------------------------------------------------------------
-- A user may write only his/her own self-subject data. The payload comes from
-- the Flutter mapping; user_id and subject_id are overwritten server-side.
-- Collection rows are replaced atomically so removed local data is also removed
-- from cloud. This is intentional for a complete user-scoped snapshot, not a
-- generic multi-device conflict resolver.

create or replace function public.sync_my_mobile_snapshot(p_snapshot jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_subject_id uuid;
  v_user jsonb := coalesce(p_snapshot -> 'user', '{}'::jsonb);
  v_tables jsonb := coalesce(p_snapshot -> 'tables', '{}'::jsonb);
  v_table text;
  v_row jsonb;
  v_rows integer := 0;
  v_collection_tables text[] := array[
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
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations'
  ];
  v_singleton_tables text[] := array['health_profiles', 'lifestyle_habits'];
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if jsonb_typeof(p_snapshot) <> 'object' then
    raise exception 'INVALID_SNAPSHOT' using errcode = '22023';
  end if;

  select id into v_subject_id
  from public.health_subjects
  where owner_user_id = v_user_id
    and subject_type = 'self'
    and is_active = true
  limit 1;

  if v_subject_id is null then
    insert into public.health_subjects (
      owner_user_id, linked_user_id, subject_type, display_name, relationship
    )
    values (v_user_id, v_user_id, 'self', 'Bạn', 'self')
    on conflict (owner_user_id) where subject_type = 'self'
    do update set linked_user_id = excluded.linked_user_id, is_active = true
    returning id into v_subject_id;
  end if;

  -- User-controlled profile fields only. Access and Sale states remain trusted
  -- server-owned fields.
  update public.users
  set
    phone = coalesce(nullif(v_user ->> 'phone', ''), phone),
    full_name = coalesce(nullif(v_user ->> 'full_name', ''), full_name),
    avatar_url = coalesce(nullif(v_user ->> 'avatar_url', ''), avatar_url),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    onboarding_status = case
      when v_user ->> 'onboarding_status' = 'completed' then 'completed'::public.nb_onboarding_status
      when v_user ->> 'onboarding_status' = 'in_progress' then 'in_progress'::public.nb_onboarding_status
      else onboarding_status
    end,
    onboarding_completed_at = case
      when v_user ->> 'onboarding_status' = 'completed'
        then coalesce(nullif(v_user ->> 'onboarding_completed_at', '')::timestamptz, now())
      else onboarding_completed_at
    end,
    updated_at = now()
  where id = v_user_id;

  update public.health_subjects
  set
    display_name = coalesce(nullif(v_user ->> 'full_name', ''), display_name),
    gender = coalesce(nullif(v_user ->> 'gender', ''), gender),
    birth_year = coalesce(nullif(v_user ->> 'birth_year', '')::integer, birth_year),
    updated_at = now()
  where id = v_subject_id;

  -- Singleton records: exactly one row for this user's self subject.
  foreach v_table in array v_singleton_tables loop
    execute format(
      'delete from public.%I where user_id = $1 and subject_id = $2',
      v_table
    ) using v_user_id, v_subject_id;

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      execute format(
        'insert into public.%I '
        'select (jsonb_populate_record(null::public.%I, $1)).*',
        v_table,
        v_table
      ) using (
        (v_row - 'user_id' - 'subject_id') ||
        jsonb_build_object('user_id', v_user_id, 'subject_id', v_subject_id)
      );
      v_rows := v_rows + 1;
    end loop;
  end loop;

  -- Collections: delete then recreate the self-scoped cloud projection. The
  -- client uses UUIDs, so source_id references are already mapped before RPC.
  foreach v_table in array v_collection_tables loop
    -- Legacy notifications may be user-scoped without a subject_id. Delete by
    -- owner so a complete snapshot cannot leave stale notification rows.
    if v_table = 'notifications' then
      execute 'delete from public.notifications where user_id = $1'
        using v_user_id;
    else
      execute format(
        'delete from public.%I where user_id = $1 and subject_id = $2',
        v_table
      ) using v_user_id, v_subject_id;
    end if;

    for v_row in
      select value from jsonb_array_elements(
        coalesce(v_tables -> v_table, '[]'::jsonb)
      )
    loop
      execute format(
        'insert into public.%I '
        'select (jsonb_populate_record(null::public.%I, $1)).*',
        v_table,
        v_table
      ) using (
        (v_row - 'user_id' - 'subject_id') ||
        jsonb_build_object('user_id', v_user_id, 'subject_id', v_subject_id)
      );
      v_rows := v_rows + 1;
    end loop;
  end loop;

  return jsonb_build_object(
    'user_id', v_user_id,
    'subject_id', v_subject_id,
    'synced_rows', v_rows,
    'synced_at', now()
  );
end;
$$;

revoke all on function public.sync_my_mobile_snapshot(jsonb) from public, anon;
grant execute on function public.sync_my_mobile_snapshot(jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- B. Sale participation, direct cloud dashboard, tree and leaderboard
-- ---------------------------------------------------------------------------
-- Terms acceptance grants a Sale role for this product's current business rule.
-- Suspended/closed statuses remain administrator-controlled and cannot be
-- reactivated by this RPC. No member is paid for recruiting; commissions are
-- created only from a successful, non-reversed payment event by trusted logic.

alter table public.sale_profiles
  add column if not exists terms_version text,
  add column if not exists terms_accepted_at timestamptz;

create or replace function public.require_active_sale_user()
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or not exists (
    select 1
    from public.sale_profiles sp
    where sp.user_id = v_user_id
      and sp.status = 'active'
  ) then
    raise exception 'SALE_ACCESS_REQUIRED' using errcode = '42501';
  end if;

  return v_user_id;
end;
$$;

create or replace function public.get_my_sale_state()
returns table (
  sale_status text,
  referral_code text,
  terms_version text,
  approved_at timestamptz,
  note text
)
language sql
security definer
set search_path = public, pg_temp
as $$
  select
    coalesce(sp.status::text, u.sale_status::text, 'none') as sale_status,
    rc.code as referral_code,
    sp.terms_version,
    sp.approved_at,
    sp.note
  from public.users u
  left join public.sale_profiles sp on sp.user_id = u.id
  left join lateral (
    select code
    from public.referral_codes
    where sale_user_id = u.id and status = 'active'
    order by created_at asc
    limit 1
  ) rc on true
  where u.id = auth.uid()
$$;

create or replace function public.request_sale_participation(p_terms_version text)
returns table (
  sale_status text,
  referral_code text,
  terms_version text,
  approved_at timestamptz,
  note text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing_status public.nb_sale_status;
  v_candidate text;
  v_created_code text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if nullif(btrim(p_terms_version), '') is null then
    raise exception 'TERMS_VERSION_REQUIRED' using errcode = '22023';
  end if;

  select status into v_existing_status
  from public.sale_profiles
  where user_id = v_user_id;

  if v_existing_status in ('suspended', 'closed') then
    raise exception 'SALE_STATUS_REQUIRES_SUPPORT' using errcode = '42501';
  end if;

  insert into public.sale_profiles (
    user_id, status, approved_at, terms_version, terms_accepted_at, note
  )
  values (
    v_user_id, 'active', now(), btrim(p_terms_version), now(),
    'Đã chấp nhận điều lệ Sale trong ứng dụng.'
  )
  on conflict (user_id) do update
  set
    status = 'active',
    approved_at = coalesce(public.sale_profiles.approved_at, now()),
    terms_version = excluded.terms_version,
    terms_accepted_at = excluded.terms_accepted_at,
    note = excluded.note,
    updated_at = now();

  if not exists (
    select 1 from public.referral_codes
    where sale_user_id = v_user_id and status = 'active'
  ) then
    for i in 1..12 loop
      v_candidate := 'NAMI-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
      insert into public.referral_codes (code, sale_user_id, status)
      values (v_candidate, v_user_id, 'active')
      on conflict (code) do nothing
      returning code into v_created_code;
      exit when v_created_code is not null;
    end loop;

    if v_created_code is null then
      raise exception 'REFERRAL_CODE_ALLOCATION_FAILED';
    end if;
  end if;

  return query select * from public.get_my_sale_state();
end;
$$;

create or replace function public.get_my_sale_dashboard()
returns table (
  direct_referrals integer,
  second_level_referrals integer,
  pending_commission_cents integer,
  approved_commission_cents integer,
  paid_commission_cents integer,
  currency text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  return query
  with direct_nodes as (
    select rr.referred_user_id
    from public.referral_relationships rr
    where rr.referrer_user_id = v_user_id
  ), second_nodes as (
    select rr.referred_user_id
    from public.referral_relationships rr
    join direct_nodes d on d.referred_user_id = rr.referrer_user_id
  ), commission as (
    select
      coalesce(sum(amount_cents) filter (where status = 'pending'), 0)::integer as pending_cents,
      coalesce(sum(amount_cents) filter (where status = 'approved'), 0)::integer as approved_cents,
      coalesce(sum(amount_cents) filter (where status = 'paid'), 0)::integer as paid_cents,
      coalesce(max(currency), 'VND') as result_currency
    from public.commission_records
    where receiver_user_id = v_user_id
  )
  select
    (select count(*)::integer from direct_nodes),
    (select count(*)::integer from second_nodes),
    c.pending_cents,
    c.approved_cents,
    c.paid_cents,
    c.result_currency
  from commission c;
end;
$$;

create or replace function public.get_my_sale_referral_tree()
returns table (
  level integer,
  display_name text,
  accepted_at timestamptz,
  successful_payments integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  return query
  with direct_nodes as (
    select 1 as depth, rr.referred_user_id, rr.accepted_at
    from public.referral_relationships rr
    where rr.referrer_user_id = v_user_id
  ), second_nodes as (
    select 2 as depth, rr.referred_user_id, rr.accepted_at
    from public.referral_relationships rr
    join direct_nodes d on d.referred_user_id = rr.referrer_user_id
  ), network as (
    select * from direct_nodes
    union all
    select * from second_nodes
  )
  select
    n.depth,
    case
      when nullif(btrim(u.full_name), '') is null then 'Người dùng Nami'
      else split_part(btrim(u.full_name), ' ', 1) || ' •••'
    end,
    n.accepted_at,
    count(distinct pe.id) filter (where pe.status = 'succeeded')::integer
  from network n
  join public.users u on u.id = n.referred_user_id
  left join public.payment_events pe on pe.payer_user_id = n.referred_user_id
  group by n.depth, n.accepted_at, u.full_name
  order by n.depth asc, n.accepted_at desc;
end;
$$;

create or replace function public.get_sale_leaderboard()
returns table (
  rank integer,
  display_name text,
  direct_referrals integer,
  approved_commission_cents integer,
  currency text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  -- v_user_id intentionally gates this report; the public-facing output contains
  -- only a masked name and aggregate metrics.
  return query
  with candidates as (
    select
      sp.user_id,
      u.full_name,
      count(distinct rr.referred_user_id)::integer as direct_count,
      coalesce(sum(cr.amount_cents) filter (where cr.status = 'approved'), 0)::integer as approved_cents,
      coalesce(max(cr.currency), 'VND') as result_currency
    from public.sale_profiles sp
    join public.users u on u.id = sp.user_id
    left join public.referral_relationships rr on rr.referrer_user_id = sp.user_id
    left join public.commission_records cr on cr.receiver_user_id = sp.user_id
    where sp.status = 'active'
    group by sp.user_id, u.full_name
  ), ranked as (
    select
      dense_rank() over (order by approved_cents desc, direct_count desc, user_id asc)::integer as computed_rank,
      *
    from candidates
  )
  select
    computed_rank,
    case
      when nullif(btrim(full_name), '') is null then 'Sale Nami'
      else split_part(btrim(full_name), ' ', 1) || ' •••'
    end,
    direct_count,
    approved_cents,
    result_currency
  from ranked
  order by computed_rank asc, user_id asc
  limit 50;
end;
$$;

revoke all on function public.require_active_sale_user() from public, anon, authenticated;
revoke all on function public.get_my_sale_state() from public, anon;
revoke all on function public.request_sale_participation(text) from public, anon;
revoke all on function public.get_my_sale_dashboard() from public, anon;
revoke all on function public.get_my_sale_referral_tree() from public, anon;
revoke all on function public.get_sale_leaderboard() from public, anon;

grant execute on function public.get_my_sale_state() to authenticated;
grant execute on function public.request_sale_participation(text) to authenticated;
grant execute on function public.get_my_sale_dashboard() to authenticated;
grant execute on function public.get_my_sale_referral_tree() to authenticated;
grant execute on function public.get_sale_leaderboard() to authenticated;

commit;
