-- Local/sandbox adversarial smoke test for migration 16.
-- Prerequisite: rebuild the disposable database with docs/supabase/config.sql.
-- The transaction is always rolled back.

begin;

update public.system_config_versions
set config_value = jsonb_set(config_value, '{enabled}', 'true'::jsonb)
where config_key = 'wellness_rewards_rollout'
  and status = 'active';

do $$
declare
  v_member uuid := '10000000-0000-4000-8000-000000000101';
  v_guest uuid := '10000000-0000-4000-8000-000000000102';
  v_member_subject uuid;
  v_guest_subject uuid;
  v_member_date date := (now() at time zone 'Asia/Ho_Chi_Minh')::date + 1;
  v_guest_start date := (now() at time zone 'Asia/Ho_Chi_Minh')::date - 1;
  v_items jsonb;
  v_result jsonb;
  v_count integer;
begin
  select id into v_member_subject
  from public.health_subjects
  where owner_user_id = v_member and subject_type = 'self' and is_active
  limit 1;
  select id into v_guest_subject
  from public.health_subjects
  where owner_user_id = v_guest and subject_type = 'self' and is_active
  limit 1;

  -- Member: one quota-backed request, one immutable full manifest.
  insert into public.personal_schedule_ai_requests (
    request_id, user_id, actor_mode, status, start_date, days,
    schedule_item_count, completed_at
  ) values (
    'adversarial-member-request', v_member, 'member_new', 'succeeded',
    v_member_date, 1, 10, now()
  );
  insert into public.usage_events (
    user_id, feature_key, period_key, idempotency_key, event_source
  ) values (
    v_member, 'personal_schedule_generation', 'adversarial',
    'adversarial-member-request', 'trusted_backend'
  );
  insert into public.lifestyle_schedule_items (
    id, user_id, subject_id, schedule_date, start_time, title, category,
    source_type, source_id, sort_order, ai_generated
  )
  select
    gen_random_uuid(), v_member, v_member_subject, v_member_date,
    make_time(8 + slot, 0, 0), 'Nhiệm vụ thành viên ' || slot,
    'wellness', 'generated_task', 'member-' || slot, slot, true
  from generate_series(0, 9) slot;

  select jsonb_agg(jsonb_build_object('schedule_item_id', id) order by id)
  into v_items
  from public.lifestyle_schedule_items
  where user_id = v_member and schedule_date = v_member_date;

  perform set_config('request.jwt.claim.sub', v_member::text, false);
  v_result := public.register_my_schedule_reward_eligibilities(
    'adversarial-member-request', v_items, 'member-registration-1'
  );
  if (v_result ->> 'registered_count')::integer <> 10 then
    raise exception 'MEMBER_INITIAL_REGISTRATION_FAILED';
  end if;

  -- Ten alternate client-writable rows cannot reuse the same request/quota.
  insert into public.lifestyle_schedule_items (
    id, user_id, subject_id, schedule_date, start_time, title, category,
    source_type, source_id, sort_order, ai_generated
  )
  select
    gen_random_uuid(), v_member, v_member_subject, v_member_date,
    case when slot < 8 then make_time(slot, 0, 0)
         else make_time(10 + slot, 0, 0) end,
    'Nhiệm vụ giả ' || slot, 'wellness', 'generated_task',
    'member-alt-' || slot, 20 + slot, true
  from generate_series(0, 9) slot;
  select jsonb_agg(jsonb_build_object('schedule_item_id', id) order by id)
  into v_items
  from public.lifestyle_schedule_items
  where user_id = v_member and source_id like 'member-alt-%';

  begin
    perform public.register_my_schedule_reward_eligibilities(
      'adversarial-member-request', v_items, 'member-registration-2'
    );
    raise exception 'MEMBER_SECOND_BATCH_ACCEPTED';
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'member_schedule_request_already_registered' then raise; end if;
  end;
  select count(*) into v_count
  from public.schedule_reward_eligibilities
  where user_id = v_member
    and schedule_request_id = 'adversarial-member-request';
  if v_count <> 10 then raise exception 'MEMBER_ELIGIBILITY_CAP_FAILED'; end if;

  -- Guest: full plan is 10 items/day, but only pinned future/incomplete subsets
  -- may be registered after sign-in.
  insert into public.personal_schedule_ai_requests (
    request_id, user_id, actor_mode, status, start_date, days,
    schedule_item_count, completed_at
  ) values (
    'adversarial-guest-request', v_guest, 'initial_guest', 'succeeded',
    v_guest_start, 3, 30, now()
  );
  insert into public.lifestyle_schedule_items (
    id, user_id, subject_id, schedule_date, start_time, title, category,
    source_type, source_id, sort_order, ai_generated
  )
  select
    gen_random_uuid(), v_guest, v_guest_subject, v_guest_start + day_offset,
    make_time(8 + slot, 0, 0),
    'Nhiệm vụ khách ' || day_offset || '-' || slot,
    'wellness', 'generated_task',
    'guest-' || day_offset || '-' || slot,
    day_offset * 10 + slot, true
  from generate_series(0, 2) day_offset
  cross join generate_series(0, 9) slot;
  update public.lifestyle_schedule_items
  set is_completed = true
  where id = (
    select id from public.lifestyle_schedule_items
    where user_id = v_guest and schedule_date = v_guest_start + 2
    order by start_time limit 1
  );

  select jsonb_agg(jsonb_build_object('schedule_item_id', id) order by start_time)
  into v_items
  from (
    select id, start_time
    from public.lifestyle_schedule_items
    where user_id = v_guest
      and schedule_date = v_guest_start + 2
      and not is_completed
    order by start_time limit 3
  ) future_subset;
  perform set_config('request.jwt.claim.sub', v_guest::text, false);
  perform public.register_my_schedule_reward_eligibilities(
    'adversarial-guest-request', v_items, 'guest-registration-1'
  );

  select jsonb_agg(jsonb_build_object('schedule_item_id', id) order by start_time)
  into v_items
  from (
    select lsi.id, lsi.start_time
    from public.lifestyle_schedule_items lsi
    where lsi.user_id = v_guest
      and lsi.schedule_date = v_guest_start + 2
      and not lsi.is_completed
      and not exists (
        select 1 from public.schedule_reward_eligibilities sre
        where sre.schedule_item_id = lsi.id
      )
    order by lsi.start_time limit 2
  ) second_subset;
  perform public.register_my_schedule_reward_eligibilities(
    'adversarial-guest-request', v_items, 'guest-registration-2'
  );

  -- Keeping the UUID but changing the schedule time invalidates the canonical
  -- pinned manifest before another subset can be added.
  update public.lifestyle_schedule_items
  set start_time = start_time + interval '1 minute'
  where id = (
    select id from public.lifestyle_schedule_items
    where user_id = v_guest and schedule_date = v_guest_start
    order by id limit 1
  );
  begin
    perform public.register_my_schedule_reward_eligibilities(
      'adversarial-guest-request', v_items, 'guest-registration-3'
    );
    raise exception 'MUTATED_GUEST_PLAN_ACCEPTED';
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'guest_schedule_request_changed' then raise; end if;
  end;

  insert into public.personal_schedule_ai_requests (
    request_id, user_id, actor_mode, status, start_date, days,
    schedule_item_count, completed_at
  ) values (
    'adversarial-guest-request-2', v_guest, 'initial_guest', 'succeeded',
    v_guest_start, 3, 30, now()
  );
  begin
    perform public.register_my_schedule_reward_eligibilities(
      'adversarial-guest-request-2', v_items, 'guest-registration-4'
    );
    raise exception 'SECOND_GUEST_REQUEST_ACCEPTED';
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'guest_schedule_request_ambiguous' then raise; end if;
  end;
end $$;

-- A voucher code is globally one-time inventory, not reusable in another
-- offer. The second Admin import must report a duplicate without inserting.
do $$
declare
  v_admin uuid := '10000000-0000-4000-8000-000000000104';
  v_offer_1 uuid := gen_random_uuid();
  v_offer_2 uuid := gen_random_uuid();
  v_result jsonb;
begin
  insert into public.wellness_reward_offers (
    id, offer_code, title, description, provider_name, cost_points,
    eligible_plan_codes, is_active
  ) values
    (v_offer_1, 'adversarial_offer_1', 'Ưu đãi thử một',
     'Mô tả ưu đãi thử một', 'NanoBio', 10, array['free'], true),
    (v_offer_2, 'adversarial_offer_2', 'Ưu đãi thử hai',
     'Mô tả ưu đãi thử hai', 'NanoBio', 10, array['free'], true);
  perform set_config('request.jwt.claim.sub', v_admin::text, false);
  v_result := public.admin_import_reward_codes(
    v_offer_1, array['GLOBAL-ADVERSARIAL-CODE'], now() + interval '30 days',
    'Kiểm thử mã toàn cục', 'adversarial-code-import-1'
  );
  if (v_result ->> 'accepted_count')::integer <> 1 then
    raise exception 'FIRST_GLOBAL_CODE_IMPORT_FAILED';
  end if;
  v_result := public.admin_import_reward_codes(
    v_offer_2, array['GLOBAL-ADVERSARIAL-CODE'], now() + interval '30 days',
    'Kiểm thử mã trùng toàn cục', 'adversarial-code-import-2'
  );
  if (v_result ->> 'accepted_count')::integer <> 0
     or (v_result ->> 'duplicate_count')::integer <> 1 then
    raise exception 'GLOBAL_CODE_DUPLICATE_ACCEPTED';
  end if;
end $$;

-- Marker tables are server-owned and invisible to authenticated clients.
do $$
begin
  perform set_config(
    'request.jwt.claim.sub',
    '10000000-0000-4000-8000-000000000102',
    false
  );
  execute 'set local role authenticated';
  begin
    perform 1 from public.guest_schedule_reward_registrations;
    raise exception 'GUEST_MARKER_READ_ALLOWED';
  exception when insufficient_privilege then null;
  end;
  begin
    perform 1 from public.member_schedule_reward_registrations;
    raise exception 'MEMBER_MARKER_READ_ALLOWED';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
end $$;

rollback;
