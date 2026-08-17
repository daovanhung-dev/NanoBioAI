-- NanoBio / Daily Health Hub reward delta — 2026-08-16
-- Apply AFTER docs/supabase/setup.sql on a disposable sandbox first.
-- Adds server-authoritative structured schedule check-ins without weakening the
-- existing JPEG photo-proof contract for meals/exercise.

begin;

create table if not exists public.schedule_health_checkins (
    id uuid primary key default gen_random_uuid(),
    eligibility_id uuid unique references public.schedule_reward_eligibilities(id) on delete set null,
    user_id uuid not null references public.users(id) on delete cascade,
    subject_id uuid not null references public.health_subjects(id) on delete cascade,
    schedule_item_id uuid not null,
    action_type text not null check (
        action_type in (
            'quick_complete',
            'hydration',
            'mood_stress',
            'sleep_checkin',
            'weight_checkin'
        )
    ),
    checkin_payload jsonb not null default '{}'::jsonb,
    reward_points integer not null check (reward_points between 1 and 10),
    schedule_date_snapshot date not null,
    start_time_snapshot time not null,
    end_time_snapshot time,
    window_start_snapshot timestamptz not null,
    window_end_snapshot timestamptz not null,
    title_snapshot text not null,
    description_snapshot text not null default '',
    category_snapshot text not null,
    source_type_snapshot text not null,
    source_id_snapshot text,
    target_value_snapshot numeric not null default 1,
    unit_snapshot text not null default 'lần',
    sort_order_snapshot integer not null default 0,
    ai_generated_snapshot boolean not null default false,
    status text not null default 'active' check (status in ('active', 'reversed')),
    idempotency_key text not null,
    undo_idempotency_key text,
    reversed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, idempotency_key),
    unique (user_id, undo_idempotency_key)
);

-- Keep this migration safe if a development database briefly received an older
-- draft where eligibility_id was NOT NULL.
alter table public.schedule_health_checkins
  alter column eligibility_id drop not null;

alter table public.schedule_health_checkins
  add column if not exists schedule_date_snapshot date,
  add column if not exists start_time_snapshot time,
  add column if not exists end_time_snapshot time,
  add column if not exists window_start_snapshot timestamptz,
  add column if not exists window_end_snapshot timestamptz,
  add column if not exists title_snapshot text,
  add column if not exists description_snapshot text not null default '',
  add column if not exists category_snapshot text,
  add column if not exists source_type_snapshot text,
  add column if not exists source_id_snapshot text,
  add column if not exists target_value_snapshot numeric not null default 1,
  add column if not exists unit_snapshot text not null default 'lần',
  add column if not exists sort_order_snapshot integer not null default 0,
  add column if not exists ai_generated_snapshot boolean not null default false;

create index if not exists idx_schedule_health_checkins_user_date
on public.schedule_health_checkins(user_id, schedule_date_snapshot, created_at desc);

create unique index if not exists idx_schedule_health_checkins_one_active_item
on public.schedule_health_checkins(user_id, schedule_item_id)
where status = 'active';

drop trigger if exists trg_schedule_health_checkins_updated_at
on public.schedule_health_checkins;

create trigger trg_schedule_health_checkins_updated_at
before update on public.schedule_health_checkins
for each row execute function public.set_updated_at();

alter table public.schedule_health_checkins enable row level security;

drop policy if exists schedule_health_checkins_select_own
on public.schedule_health_checkins;

create policy schedule_health_checkins_select_own
on public.schedule_health_checkins
for select to authenticated
using (user_id = (select auth.uid()));

revoke all on public.schedule_health_checkins from anon, authenticated;
grant select on public.schedule_health_checkins to authenticated;

create or replace function public.schedule_health_action_reward_points(
  p_action_type text
)
returns integer
language sql
immutable
set search_path = public, pg_temp
as $$
  select case btrim(coalesce(p_action_type, ''))
    when 'hydration' then 4
    when 'mood_stress' then 5
    when 'sleep_checkin' then 6
    when 'weight_checkin' then 4
    when 'quick_complete' then 5
    else 0
  end
$$;

revoke all on function public.schedule_health_action_reward_points(text)
from public, anon, authenticated;

create or replace function public.finalize_my_schedule_health_checkin(
  p_item jsonb,
  p_action_type text,
  p_checkin jsonb,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_subject_id uuid;
  v_item_id uuid;
  v_item public.lifestyle_schedule_items%rowtype;
  v_eligibility public.schedule_reward_eligibilities%rowtype;
  v_checkin public.schedule_health_checkins%rowtype;
  v_existing_checkin public.schedule_health_checkins%rowtype;
  v_allocation public.wellness_point_allocations%rowtype;
  v_wallet public.wellness_reward_wallets%rowtype;
  v_program record;
  v_action text := btrim(coalesce(p_action_type, ''));
  v_idempotency text := btrim(coalesce(p_idempotency_key, ''));
  v_source_type text;
  v_source_id text;
  v_category text;
  v_window_start timestamptz;
  v_window_end timestamptz;
  v_points integer;
  v_reward_status text := 'pending';
  v_ledger_id uuid := gen_random_uuid();
  v_allocation_id uuid := gen_random_uuid();
  v_checkin_id uuid := gen_random_uuid();
  v_amount_ml integer;
  v_stress integer;
  v_sleep double precision;
  v_weight double precision;
  v_mood text;
  v_manual_count integer;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;
  if jsonb_typeof(p_item) <> 'object'
     or jsonb_typeof(coalesce(p_checkin, '{}'::jsonb)) <> 'object' then
    raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
  end if;
  if v_idempotency = '' then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  v_points := public.schedule_health_action_reward_points(v_action);
  if v_points <= 0 then
    raise exception using errcode = 'P0001', message = 'health_action_not_rewardable';
  end if;

  begin
    v_item_id := (p_item ->> 'schedule_item_id')::uuid;
  exception when others then
    raise exception using errcode = 'P0001', message = 'schedule_item_id_invalid';
  end;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:health-checkin:' || v_user_id::text || ':' || v_item_id::text,
    0
  ));

  select * into v_checkin
  from public.schedule_health_checkins shc
  where shc.user_id = v_user_id
    and shc.idempotency_key = v_idempotency;

  if v_checkin.id is not null then
    if v_checkin.schedule_item_id <> v_item_id or v_checkin.action_type <> v_action then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;
    select * into v_allocation
    from public.wellness_point_allocations wpa
    where wpa.source_type = 'schedule_reward'
      and wpa.source_id = v_checkin.id;
    return jsonb_build_object(
      'checkin_id', v_checkin.id,
      'schedule_item_id', v_item_id,
      'points_delta', case when v_checkin.status = 'active' then v_checkin.reward_points else 0 end,
      'reward_status', case
        when v_checkin.status = 'reversed' then 'reversed'
        else coalesce(v_allocation.status, 'pending')
      end,
      'pending_points', coalesce(v_wallet.pending_points, 0),
      'available_points', coalesce(v_wallet.available_points, 0),
      'idempotent_replay', true
    );
  end if;

  select * into v_item
  from public.lifestyle_schedule_items lsi
  where lsi.id = v_item_id
    and lsi.user_id = v_user_id
  for update;

  v_source_type := btrim(coalesce(p_item ->> 'source_type', ''));
  v_source_id := nullif(btrim(coalesce(p_item ->> 'source_id', '')), '');
  v_category := btrim(coalesce(p_item ->> 'category', ''));

  -- Manual tasks are local-first. The reward RPC may race the mobile snapshot,
  -- so it can create only the single validated occurrence that is being completed.
  if v_item.id is null then
    if v_source_type <> 'manual_health_task' then
      raise exception using errcode = 'P0001', message = 'schedule_item_not_found';
    end if;
    if v_source_id is null
       or v_source_id !~ '^manual_health\|[0-9a-fA-F-]{36}\|(quick_complete|hydration|mood_stress|sleep_checkin|weight_checkin)\|[01]\|(once|daily|weekdays|weekends)$'
       or split_part(v_source_id, '|', 3) <> v_action then
      raise exception using errcode = 'P0001', message = 'manual_health_task_invalid';
    end if;
    if v_category not in ('routine', 'water', 'body', 'mind', 'brain', 'sleep', 'metric') then
      raise exception using errcode = 'P0001', message = 'manual_health_task_invalid';
    end if;

    select hs.id into v_subject_id
    from public.health_subjects hs
    where hs.owner_user_id = v_user_id
      and hs.subject_type = 'self'
      and hs.is_active = true
    limit 1;

    if v_subject_id is null then
      raise exception using errcode = 'P0001', message = 'health_subject_required';
    end if;

    begin
      insert into public.lifestyle_schedule_items (
        id, user_id, subject_id, schedule_date, start_time, end_time,
        title, description, category, source_type, source_id,
        target_value, current_value, unit, is_completed, sort_order,
        ai_generated, encouragement
      ) values (
        v_item_id,
        v_user_id,
        v_subject_id,
        (p_item ->> 'schedule_date')::date,
        (p_item ->> 'start_time')::time,
        nullif(p_item ->> 'end_time', '')::time,
        left(btrim(coalesce(p_item ->> 'title', 'Nhiệm vụ chăm sóc')), 120),
        left(coalesce(p_item ->> 'description', ''), 500),
        v_category,
        'manual_health_task',
        v_source_id,
        greatest(coalesce(nullif(p_item ->> 'target_value', '')::numeric, 1), 1),
        0,
        left(coalesce(nullif(p_item ->> 'unit', ''), 'lần'), 30),
        false,
        900,
        false,
        ''
      );
    exception when others then
      raise exception using errcode = 'P0001', message = 'manual_health_task_invalid';
    end;

    select * into v_item
    from public.lifestyle_schedule_items lsi
    where lsi.id = v_item_id and lsi.user_id = v_user_id
    for update;
  end if;

  v_subject_id := v_item.subject_id;
  if v_subject_id is null then
    raise exception using errcode = 'P0001', message = 'health_subject_required';
  end if;

  if v_item.source_type in ('meal_plan', 'exercise_task') then
    raise exception using errcode = 'P0001', message = 'photo_proof_required';
  end if;

  if v_item.source_type = 'manual_health_task' then
    if v_item.source_id is null
       or v_item.source_id !~ '^manual_health\|[0-9a-fA-F-]{36}\|(quick_complete|hydration|mood_stress|sleep_checkin|weight_checkin)\|[01]\|(once|daily|weekdays|weekends)$'
       or split_part(v_item.source_id, '|', 3) <> v_action then
      raise exception using errcode = 'P0001', message = 'health_action_mismatch';
    end if;
  else
    if v_action = 'hydration' and v_item.category <> 'water' then
      raise exception using errcode = 'P0001', message = 'health_action_mismatch';
    end if;
    if v_action <> 'hydration' and v_action <> 'quick_complete' then
      raise exception using errcode = 'P0001', message = 'health_action_mismatch';
    end if;
    if v_action = 'quick_complete'
       and v_item.category not in ('routine', 'mind', 'brain', 'body', 'sleep') then
      raise exception using errcode = 'P0001', message = 'health_action_mismatch';
    end if;
  end if;

  if v_action = 'hydration' then
    if jsonb_typeof(p_checkin -> 'amount_ml') <> 'number' then
      raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
    end if;
    v_amount_ml := (p_checkin ->> 'amount_ml')::integer;
    if v_amount_ml < 50 or v_amount_ml > 2000 then
      raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
    end if;
  elsif v_action = 'mood_stress' then
    v_mood := btrim(coalesce(p_checkin ->> 'mood', ''));
    if v_mood not in ('very_good', 'good', 'neutral', 'tired', 'stressed')
       or jsonb_typeof(p_checkin -> 'stress_level') <> 'number' then
      raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
    end if;
    v_stress := (p_checkin ->> 'stress_level')::integer;
    if v_stress < 1 or v_stress > 5 then
      raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
    end if;
  elsif v_action = 'sleep_checkin' then
    if jsonb_typeof(p_checkin -> 'sleep_hours') <> 'number' then
      raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
    end if;
    v_sleep := (p_checkin ->> 'sleep_hours')::double precision;
    if v_sleep < 0 or v_sleep > 24 then
      raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
    end if;
  elsif v_action = 'weight_checkin' then
    if jsonb_typeof(p_checkin -> 'weight_kg') <> 'number' then
      raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
    end if;
    v_weight := (p_checkin ->> 'weight_kg')::double precision;
    if v_weight < 20 or v_weight > 500 then
      raise exception using errcode = 'P0001', message = 'health_checkin_invalid';
    end if;
  end if;

  v_window_start := ((v_item.schedule_date + v_item.start_time) at time zone 'Asia/Ho_Chi_Minh');
  v_window_end := v_window_start + interval '30 minutes';
  if now() < v_window_start then
    raise exception using errcode = 'P0001', message = 'schedule_window_not_open';
  end if;
  if now() > v_window_end then
    raise exception using errcode = 'P0001', message = 'schedule_window_locked';
  end if;

  select * into v_existing_checkin
  from public.schedule_health_checkins shc
  where shc.user_id = v_user_id
    and shc.schedule_item_id = v_item.id
    and shc.status = 'active'
  for update;

  if v_existing_checkin.id is not null then
    raise exception using errcode = 'P0001', message = 'health_checkin_already_recorded';
  end if;

  if v_item.source_type <> 'manual_health_task' then
    select * into v_eligibility
    from public.schedule_reward_eligibilities sre
    where sre.user_id = v_user_id
      and sre.schedule_item_id = v_item.id
    for update;

    if v_eligibility.id is null then
      raise exception using errcode = 'P0001', message = 'eligibility_not_found';
    end if;
    if v_eligibility.status <> 'eligible' then
      raise exception using errcode = 'P0001', message = 'eligibility_not_available';
    end if;
    if exists (
      select 1 from public.wellness_point_allocations wpa
      where wpa.eligibility_id = v_eligibility.id
    ) then
      raise exception using errcode = 'P0001', message = 'eligibility_reward_already_awarded';
    end if;
  else
    -- Manual tasks never mint schedule_reward_eligibilities. Keeping eligibility
    -- NULL prevents user-created tasks from being misclassified as generated
    -- photo-proof tasks by the existing mobile snapshot hardening layer.
    v_eligibility.id := null;
    select count(*)::integer into v_manual_count
    from public.schedule_health_checkins shc
    where shc.user_id = v_user_id
      and shc.source_type_snapshot = 'manual_health_task'
      and shc.schedule_date_snapshot = v_item.schedule_date
      and shc.status = 'active';
    if v_manual_count >= 4 then
      raise exception using errcode = 'P0001', message = 'manual_reward_daily_limit';
    end if;
  end if;

  select * into v_program from public.current_wellness_reward_program();

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  insert into public.schedule_health_checkins (
    id, eligibility_id, user_id, subject_id, schedule_item_id,
    action_type, checkin_payload, reward_points,
    schedule_date_snapshot, start_time_snapshot, end_time_snapshot,
    window_start_snapshot, window_end_snapshot,
    title_snapshot, description_snapshot, category_snapshot,
    source_type_snapshot, source_id_snapshot, target_value_snapshot,
    unit_snapshot, sort_order_snapshot, ai_generated_snapshot,
    idempotency_key
  ) values (
    v_checkin_id,
    case when v_item.source_type = 'manual_health_task' then null else v_eligibility.id end,
    v_user_id,
    v_subject_id,
    v_item.id,
    v_action,
    coalesce(p_checkin, '{}'::jsonb),
    v_points,
    v_item.schedule_date,
    v_item.start_time,
    v_item.end_time,
    v_window_start,
    v_window_end,
    v_item.title,
    coalesce(v_item.description, ''),
    v_item.category,
    v_item.source_type,
    v_item.source_id,
    greatest(v_item.target_value, 1),
    coalesce(nullif(v_item.unit, ''), 'lần'),
    v_item.sort_order,
    v_item.ai_generated,
    v_idempotency
  ) returning * into v_checkin;

  -- Health metrics remain local-first and are synchronized through the existing
  -- user-data outbox. This RPC validates and stores structured evidence only;
  -- it deliberately does not insert public.health_tracking_logs.

  insert into public.wellness_point_ledgers (
    id, user_id, subject_id, source_type, source_id, schedule_date,
    points_delta, program_code, idempotency_key, event_type, status,
    title, is_redeemable, available_at, expires_at, program_config_id,
    eligibility_id, metadata
  ) values (
    v_ledger_id,
    v_user_id,
    v_subject_id,
    'schedule_health_checkin',
    v_checkin.id,
    v_item.schedule_date,
    v_points,
    v_program.contract_version,
    'schedule_health_checkin:' || v_checkin.id::text,
    'schedule_award',
    v_reward_status,
    'Hoàn thành nhiệm vụ: ' || v_item.title,
    true,
    v_window_end,
    v_window_end + make_interval(days => v_program.expiry_days),
    v_program.program_config_id,
    case when v_item.source_type = 'manual_health_task' then null else v_eligibility.id end,
    jsonb_build_object(
      'evidence_kind', 'health_checkin',
      'action_type', v_action,
      'manual_task', v_item.source_type = 'manual_health_task'
    )
  );

  insert into public.wellness_point_allocations (
    id, user_id, subject_id, ledger_id, eligibility_id,
    source_type, source_id, original_points, remaining_points,
    status, available_at, expires_at, program_config_id
  ) values (
    v_allocation_id,
    v_user_id,
    v_subject_id,
    v_ledger_id,
    case when v_item.source_type = 'manual_health_task' then null else v_eligibility.id end,
    'schedule_reward',
    v_checkin.id,
    v_points,
    v_points,
    v_reward_status,
    v_window_end,
    v_window_end + make_interval(days => v_program.expiry_days),
    v_program.program_config_id
  ) returning * into v_allocation;

  update public.wellness_reward_wallets
  set
    pending_points = pending_points + v_points,
    lifetime_earned_points = lifetime_earned_points + v_points,
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  if v_item.source_type <> 'manual_health_task' then
    update public.schedule_reward_eligibilities
    set status = 'completed', updated_at = now()
    where id = v_eligibility.id;
  end if;

  update public.lifestyle_schedule_items
  set
    is_completed = true,
    current_value = greatest(current_value, target_value),
    updated_at = now()
  where id = v_item.id and user_id = v_user_id;

  return jsonb_build_object(
    'checkin_id', v_checkin.id,
    'schedule_item_id', v_item.id,
    'points_delta', v_points,
    'reward_status', v_allocation.status,
    'pending_points', v_wallet.pending_points,
    'available_points', v_wallet.available_points,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.undo_my_schedule_health_checkin(
  p_schedule_item_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_idempotency text := btrim(coalesce(p_idempotency_key, ''));
  v_checkin public.schedule_health_checkins%rowtype;
  v_allocation public.wellness_point_allocations%rowtype;
  v_wallet public.wellness_reward_wallets%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if v_idempotency = '' then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:health-checkin-undo:' || v_user_id::text || ':' || p_schedule_item_id::text,
    0
  ));

  select * into v_checkin
  from public.schedule_health_checkins shc
  where shc.user_id = v_user_id
    and shc.undo_idempotency_key = v_idempotency;

  if v_checkin.id is not null then
    if v_checkin.schedule_item_id <> p_schedule_item_id then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    perform public.refresh_wellness_reward_wallet(v_user_id);
    select * into v_wallet
    from public.wellness_reward_wallets where user_id = v_user_id;
    return jsonb_build_object(
      'checkin_id', v_checkin.id,
      'schedule_item_id', p_schedule_item_id,
      'points_delta', -v_checkin.reward_points,
      'reward_status', 'reversed',
      'pending_points', coalesce(v_wallet.pending_points, 0),
      'available_points', coalesce(v_wallet.available_points, 0),
      'idempotent_replay', true
    );
  end if;

  select * into v_checkin
  from public.schedule_health_checkins shc
  where shc.user_id = v_user_id
    and shc.schedule_item_id = p_schedule_item_id
    and shc.status = 'active'
  for update;

  if v_checkin.id is null then
    raise exception using errcode = 'P0001', message = 'health_checkin_not_found';
  end if;
  if now() > v_checkin.window_end_snapshot then
    raise exception using errcode = 'P0001', message = 'undo_window_locked';
  end if;

  select * into v_allocation
  from public.wellness_point_allocations wpa
  where wpa.user_id = v_user_id
    and wpa.source_type = 'schedule_reward'
    and wpa.source_id = v_checkin.id
  for update;

  if v_allocation.id is null
     or v_allocation.status <> 'pending'
     or v_allocation.remaining_points <> v_allocation.original_points then
    raise exception using errcode = 'P0001', message = 'reward_cannot_be_undone';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  insert into public.wellness_point_ledgers (
    user_id, subject_id, source_type, source_id, schedule_date,
    points_delta, program_code, idempotency_key, event_type, status,
    title, is_redeemable, available_at, expires_at, program_config_id,
    eligibility_id, metadata
  ) values (
    v_user_id,
    v_checkin.subject_id,
    'schedule_health_checkin',
    v_checkin.id,
    v_checkin.schedule_date_snapshot,
    -v_allocation.original_points,
    'wellness_rewards_v2',
    'schedule_health_checkin_undo:' || v_checkin.id::text,
    'schedule_reversal',
    'reversed',
    'Hoàn tác nhiệm vụ: ' || v_checkin.title_snapshot,
    true,
    v_allocation.available_at,
    v_allocation.expires_at,
    v_allocation.program_config_id,
    v_checkin.eligibility_id,
    jsonb_build_object('evidence_kind', 'health_checkin')
  );

  update public.wellness_point_allocations
  set remaining_points = 0, status = 'reversed', updated_at = now()
  where id = v_allocation.id;

  update public.wellness_reward_wallets
  set
    pending_points = greatest(pending_points - v_allocation.original_points, 0),
    lifetime_earned_points = greatest(lifetime_earned_points - v_allocation.original_points, 0),
    lock_version = lock_version + 1,
    updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  update public.schedule_health_checkins
  set
    status = 'reversed',
    reversed_at = now(),
    undo_idempotency_key = v_idempotency,
    updated_at = now()
  where id = v_checkin.id;

  if v_checkin.eligibility_id is not null then
    update public.schedule_reward_eligibilities
    set status = 'undone', updated_at = now()
    where id = v_checkin.eligibility_id;
  end if;

  update public.lifestyle_schedule_items
  set is_completed = false, current_value = 0, updated_at = now()
  where id = p_schedule_item_id and user_id = v_user_id;

  return jsonb_build_object(
    'checkin_id', v_checkin.id,
    'schedule_item_id', p_schedule_item_id,
    'points_delta', -v_allocation.original_points,
    'reward_status', 'reversed',
    'pending_points', v_wallet.pending_points,
    'available_points', v_wallet.available_points,
    'idempotent_replay', false
  );
end;
$$;

revoke all on function public.finalize_my_schedule_health_checkin(jsonb, text, jsonb, text)
from public, anon;
revoke all on function public.undo_my_schedule_health_checkin(uuid, text)
from public, anon;

grant execute on function public.finalize_my_schedule_health_checkin(jsonb, text, jsonb, text)
to authenticated;
grant execute on function public.undo_my_schedule_health_checkin(uuid, text)
to authenticated;

-- ---------------------------------------------------------------------------
-- Mobile snapshot compatibility
-- ---------------------------------------------------------------------------
-- setup.sql intentionally treats schedule_reward_eligibilities + active JPEG
-- proofs as authoritative generated-task completion. Structured check-ins use
-- their own server evidence table, so wrap the canonical sync function and
-- overlay the latest structured check-in state after the existing sync logic.
-- This keeps the photo-proof contract unchanged and also protects completed
-- manual tasks from a stale snapshot that omits their local-first occurrence.

do $$
begin
  if to_regprocedure('public.sync_my_mobile_snapshot_before_daily_health_hub(jsonb)') is null then
    if to_regprocedure('public.sync_my_mobile_snapshot(jsonb)') is null then
      raise exception 'sync_my_mobile_snapshot(jsonb) must exist before applying Daily Health Hub migration';
    end if;
    execute 'alter function public.sync_my_mobile_snapshot(jsonb) rename to sync_my_mobile_snapshot_before_daily_health_hub';
  end if;
end
$$;

revoke all on function public.sync_my_mobile_snapshot_before_daily_health_hub(jsonb)
from public, anon, authenticated;

create or replace function public.sync_my_mobile_snapshot(p_snapshot jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
  v_overlay_count integer := 0;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  v_result := public.sync_my_mobile_snapshot_before_daily_health_hub(p_snapshot);

  -- Re-create active manual occurrences if a stale snapshot omitted them.
  with latest as (
    select distinct on (shc.schedule_item_id) shc.*
    from public.schedule_health_checkins shc
    where shc.user_id = v_user_id
      and shc.source_type_snapshot = 'manual_health_task'
    order by shc.schedule_item_id, shc.created_at desc
  ), restored as (
    insert into public.lifestyle_schedule_items (
      id, user_id, subject_id, schedule_date, start_time, end_time,
      title, description, category, source_type, source_id,
      target_value, current_value, unit, is_completed, sort_order,
      ai_generated, encouragement, created_at, updated_at
    )
    select
      l.schedule_item_id,
      l.user_id,
      l.subject_id,
      l.schedule_date_snapshot,
      l.start_time_snapshot,
      l.end_time_snapshot,
      l.title_snapshot,
      l.description_snapshot,
      l.category_snapshot,
      l.source_type_snapshot,
      l.source_id_snapshot,
      greatest(l.target_value_snapshot, 1),
      greatest(l.target_value_snapshot, 1),
      l.unit_snapshot,
      true,
      l.sort_order_snapshot,
      false,
      '',
      l.created_at,
      now()
    from latest l
    where l.status = 'active'
      and l.schedule_date_snapshot is not null
      and l.start_time_snapshot is not null
      and l.title_snapshot is not null
      and l.category_snapshot is not null
      and l.source_type_snapshot = 'manual_health_task'
    on conflict (id) do update set
      user_id = excluded.user_id,
      subject_id = excluded.subject_id,
      schedule_date = excluded.schedule_date,
      start_time = excluded.start_time,
      end_time = excluded.end_time,
      title = excluded.title,
      description = excluded.description,
      category = excluded.category,
      source_type = excluded.source_type,
      source_id = excluded.source_id,
      target_value = excluded.target_value,
      current_value = excluded.target_value,
      unit = excluded.unit,
      is_completed = true,
      sort_order = excluded.sort_order,
      ai_generated = false,
      updated_at = now()
    returning 1
  )
  select count(*)::integer into v_overlay_count from restored;

  -- Overlay latest server evidence for rows that survived/reappeared through
  -- the base snapshot flow. Generated tasks keep their immutable eligibility
  -- snapshots from setup.sql; only completion state is changed here.
  with latest as (
    select distinct on (shc.schedule_item_id)
      shc.schedule_item_id,
      shc.status
    from public.schedule_health_checkins shc
    where shc.user_id = v_user_id
    order by shc.schedule_item_id, shc.created_at desc
  )
  update public.lifestyle_schedule_items lsi
  set
    is_completed = (l.status = 'active'),
    current_value = case
      when l.status = 'active' then greatest(lsi.current_value, lsi.target_value)
      else 0
    end,
    updated_at = now()
  from latest l
  where lsi.id = l.schedule_item_id
    and lsi.user_id = v_user_id;

  return coalesce(v_result, '{}'::jsonb) || jsonb_build_object(
    'daily_health_hub_overlay', v_overlay_count
  );
end;
$$;

revoke all on function public.sync_my_mobile_snapshot(jsonb)
from public, anon;
grant execute on function public.sync_my_mobile_snapshot(jsonb)
to authenticated;

commit;
