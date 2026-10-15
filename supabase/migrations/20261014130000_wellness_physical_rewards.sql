begin;

alter table public.wellness_reward_offers
  add column if not exists reward_type text not null default 'voucher',
  add column if not exists stock_count integer not null default 0;

alter table public.wellness_reward_offers
  drop constraint if exists wellness_reward_offers_reward_type_check;
alter table public.wellness_reward_offers
  add constraint wellness_reward_offers_reward_type_check
    check (reward_type in ('voucher', 'physical'));
alter table public.wellness_reward_offers
  drop constraint if exists wellness_reward_offers_stock_count_check;
alter table public.wellness_reward_offers
  add constraint wellness_reward_offers_stock_count_check
    check (stock_count >= 0);

alter table public.wellness_reward_redemptions
  alter column reward_code_id drop not null,
  alter column voucher_expires_at drop not null,
  add column if not exists reward_type_snapshot text not null default 'voucher',
  add column if not exists received_at timestamptz,
  add column if not exists received_by uuid references public.users(id) on delete set null;

alter table public.wellness_reward_redemptions
  drop constraint if exists wellness_reward_redemptions_status_check;
alter table public.wellness_reward_redemptions
  add constraint wellness_reward_redemptions_status_check
    check (status in ('issued', 'cancelled', 'redeemed', 'received'));
alter table public.wellness_reward_redemptions
  drop constraint if exists wellness_reward_redemptions_reward_type_snapshot_check;
alter table public.wellness_reward_redemptions
  add constraint wellness_reward_redemptions_reward_type_snapshot_check
    check (reward_type_snapshot in ('voucher', 'physical'));

create index if not exists idx_wellness_reward_offers_type_stock
  on public.wellness_reward_offers (reward_type, is_active, stock_count);
create index if not exists idx_wellness_reward_redemptions_physical_status
  on public.wellness_reward_redemptions (user_id, reward_type_snapshot, status, created_at desc);

-- Keep legacy voucher screens scoped to voucher records.
create or replace function public.list_my_reward_offers(
  p_limit integer default 100
)
returns table (
  id uuid,
  offer_id uuid,
  offer_code text,
  title text,
  description text,
  provider_name text,
  cost_points integer,
  available_codes integer,
  eligible_plan_codes text[],
  available_from timestamptz,
  available_until timestamptz,
  voucher_expires_at timestamptz,
  is_active boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan text;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  v_plan := public.current_plan_for_user(v_user_id)::text;

  return query
  select
    wro.id, wro.id, wro.offer_code, wro.title, wro.description,
    wro.provider_name, wro.cost_points,
    count(wrc.id) filter (
      where wrc.status = 'available'
        and coalesce(wrc.voucher_expires_at, wro.voucher_expires_at) > now()
    )::integer,
    wro.eligible_plan_codes, wro.available_from, wro.available_until,
    wro.voucher_expires_at, wro.is_active
  from public.wellness_reward_offers wro
  left join public.wellness_reward_codes wrc on wrc.offer_id = wro.id
  where public.wellness_rewards_feature_enabled()
    and wro.reward_type = 'voucher'
    and wro.is_active = true
    and (wro.available_from is null or wro.available_from <= now())
    and (wro.available_until is null or wro.available_until > now())
    and v_plan = any(wro.eligible_plan_codes)
  group by wro.id
  order by wro.cost_points, wro.created_at desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.list_my_reward_redemptions(
  p_limit integer default 100
)
returns table (
  id uuid,
  redemption_id uuid,
  offer_id uuid,
  title text,
  provider_name text,
  points_spent integer,
  status text,
  voucher_expires_at timestamptz,
  created_at timestamptz,
  cancelled_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  return query
  select
    wrr.id, wrr.id, wrr.offer_id, wrr.offer_title_snapshot,
    wrr.provider_name_snapshot, wrr.points_spent, wrr.status,
    wrr.voucher_expires_at, wrr.created_at, wrr.cancelled_at
  from public.wellness_reward_redemptions wrr
  where wrr.user_id = v_user_id and wrr.reward_type_snapshot = 'voucher'
  order by wrr.created_at desc, wrr.id desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.guard_wellness_reward_redemption_type()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_offer_type text;
begin
  select reward_type into v_offer_type
  from public.wellness_reward_offers
  where id = new.offer_id;

  if v_offer_type is null or v_offer_type <> new.reward_type_snapshot then
    raise exception using errcode = 'P0001', message = 'reward_type_mismatch';
  end if;

  if v_offer_type = 'voucher' and new.reward_code_id is null then
    raise exception using errcode = 'P0001', message = 'reward_code_required';
  end if;

  if v_offer_type = 'physical' and new.reward_code_id is not null then
    raise exception using errcode = 'P0001', message = 'reward_code_not_allowed';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_wellness_reward_redemption_type
  on public.wellness_reward_redemptions;
create trigger trg_wellness_reward_redemption_type
  before insert or update of offer_id, reward_code_id, reward_type_snapshot
  on public.wellness_reward_redemptions
  for each row execute function public.guard_wellness_reward_redemption_type();

create or replace function public.guard_wellness_reward_code_offer_type()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1
    from public.wellness_reward_offers wro
    where wro.id = new.offer_id
      and wro.reward_type = 'voucher'
  ) then
    raise exception using errcode = 'P0001', message = 'reward_type_mismatch';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_wellness_reward_code_offer_type
  on public.wellness_reward_codes;
create trigger trg_wellness_reward_code_offer_type
  before insert or update of offer_id on public.wellness_reward_codes
  for each row execute function public.guard_wellness_reward_code_offer_type();

create or replace function public.list_my_reward_catalog_v2(
  p_limit integer default 100
)
returns table (
  id uuid,
  offer_id uuid,
  offer_code text,
  reward_type text,
  title text,
  description text,
  provider_name text,
  cost_points integer,
  available_codes integer,
  stock_count integer,
  eligible_plan_codes text[],
  available_from timestamptz,
  available_until timestamptz,
  voucher_expires_at timestamptz,
  is_active boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan text;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  v_plan := public.current_plan_for_user(v_user_id)::text;

  return query
  select
    wro.id,
    wro.id,
    wro.offer_code,
    wro.reward_type,
    wro.title,
    wro.description,
    wro.provider_name,
    wro.cost_points,
    count(wrc.id) filter (
      where wrc.status = 'available'
        and coalesce(wrc.voucher_expires_at, wro.voucher_expires_at) > now()
    )::integer,
    wro.stock_count,
    wro.eligible_plan_codes,
    wro.available_from,
    wro.available_until,
    wro.voucher_expires_at,
    wro.is_active
  from public.wellness_reward_offers wro
  left join public.wellness_reward_codes wrc
    on wrc.offer_id = wro.id
  where public.wellness_rewards_feature_enabled()
    and wro.is_active = true
    and (wro.available_from is null or wro.available_from <= now())
    and (wro.available_until is null or wro.available_until > now())
    and v_plan = any(wro.eligible_plan_codes)
  group by wro.id
  order by wro.cost_points, wro.created_at desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.list_my_reward_redemptions_v2(
  p_limit integer default 100
)
returns table (
  id uuid,
  redemption_id uuid,
  offer_id uuid,
  reward_type text,
  title text,
  provider_name text,
  points_spent integer,
  status text,
  voucher_expires_at timestamptz,
  created_at timestamptz,
  cancelled_at timestamptz,
  received_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  return query
  select
    wrr.id,
    wrr.id,
    wrr.offer_id,
    wrr.reward_type_snapshot,
    wrr.offer_title_snapshot,
    wrr.provider_name_snapshot,
    wrr.points_spent,
    wrr.status,
    wrr.voucher_expires_at,
    wrr.created_at,
    wrr.cancelled_at,
    wrr.received_at
  from public.wellness_reward_redemptions wrr
  where wrr.user_id = v_user_id
  order by wrr.created_at desc, wrr.id desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$$;

create or replace function public.redeem_my_reward_v2(
  p_offer_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan text;
  v_offer public.wellness_reward_offers%rowtype;
  v_wallet public.wellness_reward_wallets%rowtype;
  v_existing public.wellness_reward_redemptions%rowtype;
  v_response jsonb;
  v_ledger_id uuid;
  v_redemption_id uuid := gen_random_uuid();
  v_subject_id uuid;
  v_allocation record;
  v_needed integer;
  v_take integer;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;
  if p_offer_id is null then
    raise exception using errcode = 'P0001', message = 'offer_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:redeem:v2:' || v_user_id::text || ':' || btrim(p_idempotency_key),
    0
  ));

  select * into v_existing
  from public.wellness_reward_redemptions wrr
  where wrr.user_id = v_user_id
    and wrr.idempotency_key = btrim(p_idempotency_key);

  if v_existing.id is not null then
    if v_existing.offer_id <> p_offer_id then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    if v_existing.reward_type_snapshot = 'voucher' then
      v_response := public.redeem_my_reward_offer(p_offer_id, p_idempotency_key);
      select id into v_ledger_id
      from public.wellness_point_ledgers
      where redemption_id = v_existing.id
      order by created_at desc
      limit 1;
      return v_response || jsonb_build_object('point_ledger_id', v_ledger_id);
    end if;
    select available_points into v_wallet.available_points
    from public.wellness_reward_wallets
    where user_id = v_user_id;
    select id into v_ledger_id
    from public.wellness_point_ledgers
    where redemption_id = v_existing.id
    order by created_at desc
    limit 1;
    return jsonb_build_object(
      'success', true,
      'id', v_existing.id,
      'redemption_id', v_existing.id,
      'offer_id', v_existing.offer_id,
      'reward_type', 'physical',
      'title', v_existing.offer_title_snapshot,
      'provider_name', v_existing.provider_name_snapshot,
      'points_spent', v_existing.points_spent,
      'status', v_existing.status,
      'point_ledger_id', v_ledger_id,
      'available_points', coalesce(v_wallet.available_points, 0),
      'created_at', v_existing.created_at,
      'received_at', v_existing.received_at,
      'idempotent_replay', true
    );
  end if;

  if not public.wellness_rewards_feature_enabled() then
    raise exception using errcode = 'P0001', message = 'wellness_rewards_disabled';
  end if;

  select * into v_offer
  from public.wellness_reward_offers wro
  where wro.id = p_offer_id
  for update;

  if v_offer.id is null
     or not v_offer.is_active
     or (v_offer.available_from is not null and v_offer.available_from > now())
     or (v_offer.available_until is not null and v_offer.available_until <= now()) then
    raise exception using errcode = 'P0001', message = 'offer_unavailable';
  end if;

  if v_offer.reward_type = 'voucher' then
    v_response := public.redeem_my_reward_offer(p_offer_id, p_idempotency_key);
    select id into v_ledger_id
    from public.wellness_point_ledgers
    where redemption_id = (v_response ->> 'redemption_id')::uuid
    order by created_at desc
    limit 1;
    return v_response || jsonb_build_object('point_ledger_id', v_ledger_id);
  end if;

  if v_offer.stock_count <= 0 then
    raise exception using errcode = 'P0001', message = 'offer_out_of_stock';
  end if;

  v_plan := public.current_plan_for_user(v_user_id)::text;
  if not (v_plan = any(v_offer.eligible_plan_codes)) then
    raise exception using errcode = 'P0001', message = 'offer_ineligible';
  end if;

  perform public.refresh_wellness_reward_wallet(v_user_id);
  select * into v_wallet
  from public.wellness_reward_wallets
  where user_id = v_user_id
  for update;

  if v_wallet.available_points < v_offer.cost_points then
    raise exception using errcode = 'P0001', message = 'insufficient_points';
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

  update public.wellness_reward_offers
  set stock_count = stock_count - 1, updated_at = now()
  where id = v_offer.id and stock_count > 0;
  if not found then
    raise exception using errcode = 'P0001', message = 'offer_out_of_stock';
  end if;

  insert into public.wellness_reward_redemptions (
    id, user_id, offer_id, reward_code_id, reward_type_snapshot,
    offer_title_snapshot, provider_name_snapshot, points_spent, status,
    voucher_expires_at, idempotency_key
  ) values (
    v_redemption_id, v_user_id, v_offer.id, null, 'physical',
    v_offer.title, v_offer.provider_name, v_offer.cost_points, 'redeemed',
    null, btrim(p_idempotency_key)
  );

  v_needed := v_offer.cost_points;
  for v_allocation in
    select wpa.id, wpa.remaining_points
    from public.wellness_point_allocations wpa
    where wpa.user_id = v_user_id
      and wpa.status = 'available'
      and wpa.remaining_points > 0
      and wpa.expires_at > now()
    order by wpa.expires_at, wpa.created_at, wpa.id
    for update
  loop
    exit when v_needed = 0;
    v_take := least(v_needed, v_allocation.remaining_points);
    insert into public.wellness_redemption_allocation_usages (
      redemption_id, allocation_id, points_used
    ) values (v_redemption_id, v_allocation.id, v_take);
    update public.wellness_point_allocations
    set remaining_points = remaining_points - v_take,
        status = case when remaining_points - v_take = 0 then 'spent' else status end,
        updated_at = now()
    where id = v_allocation.id;
    v_needed := v_needed - v_take;
  end loop;

  if v_needed <> 0 then
    raise exception using errcode = 'P0001', message = 'wallet_allocation_mismatch';
  end if;

  insert into public.wellness_point_ledgers (
    user_id, subject_id, source_type, source_id, schedule_date, points_delta,
    program_code, idempotency_key, event_type, status, title, is_redeemable,
    redemption_id, metadata
  ) values (
    v_user_id, v_subject_id, 'reward_redemption', v_redemption_id,
    (now() at time zone 'Asia/Ho_Chi_Minh')::date, -v_offer.cost_points,
    'wellness_rewards_v2', 'reward_redemption:' || v_redemption_id::text,
    'redemption', 'redeemed', 'Đổi quà: ' || v_offer.title, true,
    v_redemption_id, jsonb_build_object('offer_id', v_offer.id, 'reward_type', 'physical')
  ) returning id into v_ledger_id;

  update public.wellness_reward_wallets
  set available_points = available_points - v_offer.cost_points,
      lifetime_spent_points = lifetime_spent_points + v_offer.cost_points,
      lock_version = lock_version + 1,
      updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  return jsonb_build_object(
    'success', true,
    'id', v_redemption_id,
    'redemption_id', v_redemption_id,
    'offer_id', v_offer.id,
    'reward_type', 'physical',
    'title', v_offer.title,
    'provider_name', v_offer.provider_name,
    'points_spent', v_offer.cost_points,
    'status', 'redeemed',
    'point_ledger_id', v_ledger_id,
    'available_points', v_wallet.available_points,
    'created_at', now(),
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.admin_upsert_reward_offer_v2(
  p_offer_id uuid,
  p_reward_type text,
  p_title text,
  p_description text,
  p_provider_name text,
  p_cost_points integer,
  p_stock_count integer,
  p_eligible_plan_codes text[],
  p_available_from timestamptz,
  p_available_until timestamptz,
  p_voucher_expires_at timestamptz,
  p_is_active boolean,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_offer public.wellness_reward_offers%rowtype;
  v_existing_audit public.admin_audit_events%rowtype;
  v_new_id uuid := coalesce(p_offer_id, gen_random_uuid());
begin
  perform public.admin_assert_permission('wellness_rewards.write');
  if coalesce(p_reward_type, '') not in ('voucher', 'physical') then
    raise exception using errcode = 'P0001', message = 'reward_type_invalid';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;
  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'admin_reason_required';
  end if;

  if p_offer_id is not null then
    select * into v_offer from public.wellness_reward_offers
    where id = p_offer_id for update;
    if v_offer.id is null then
      raise exception using errcode = 'P0001', message = 'offer_not_found';
    end if;
    if v_offer.reward_type <> p_reward_type then
      raise exception using errcode = 'P0001', message = 'reward_type_immutable';
    end if;
  end if;

  if p_reward_type = 'voucher' then
    return public.admin_upsert_reward_offer(
      p_offer_id, p_title, p_description, p_provider_name, p_cost_points,
      p_eligible_plan_codes, p_available_from, p_available_until,
      p_voucher_expires_at, p_is_active, p_reason, p_idempotency_key
    );
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:admin:upsert:physical:' || btrim(p_idempotency_key), 0
  ));
  select * into v_existing_audit
  from public.admin_audit_events aae
  where aae.action = 'admin_upsert_physical_reward_offer'
    and aae.idempotency_key = btrim(p_idempotency_key);
  if v_existing_audit.id is not null then
    if p_offer_id is not null and v_existing_audit.target_id <> p_offer_id::text then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    return jsonb_build_object(
      'success', true,
      'message', 'Yêu cầu đã được xử lý trước đó.',
      'offer_id', v_existing_audit.target_id,
      'idempotent_replay', true
    );
  end if;

  if not public.reward_text_is_vietnamese(p_title)
     or not public.reward_text_is_vietnamese(p_description) then
    raise exception using errcode = 'P0001', message = 'invalid_vietnamese_copy';
  end if;
  if nullif(btrim(coalesce(p_provider_name, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'provider_name_required';
  end if;
  if p_cost_points is null or p_cost_points <= 0 then
    raise exception using errcode = 'P0001', message = 'reward_cost_invalid';
  end if;
  if p_stock_count is null or p_stock_count < 0 then
    raise exception using errcode = 'P0001', message = 'reward_stock_invalid';
  end if;
  if p_eligible_plan_codes is null
     or cardinality(p_eligible_plan_codes) = 0
     or not (p_eligible_plan_codes <@ array['free', 'plus', 'family_plus']::text[]) then
    raise exception using errcode = 'P0001', message = 'eligible_plans_invalid';
  end if;
  if p_available_from is not null and p_available_until is not null
     and p_available_until <= p_available_from then
    raise exception using errcode = 'P0001', message = 'offer_window_invalid';
  end if;

  insert into public.wellness_reward_offers (
    id, offer_code, reward_type, stock_count, title, description, provider_name,
    cost_points, eligible_plan_codes, available_from, available_until,
    voucher_expires_at, is_active, created_by, updated_by
  ) values (
    v_new_id, 'reward_' || replace(v_new_id::text, '-', ''), 'physical', p_stock_count,
    btrim(p_title), btrim(p_description), btrim(p_provider_name), p_cost_points,
    array(select distinct lower(btrim(x)) from unnest(p_eligible_plan_codes) x order by 1),
    p_available_from, p_available_until, null, coalesce(p_is_active, false), auth.uid(), auth.uid()
  )
  on conflict (id) do update set
    title = excluded.title,
    description = excluded.description,
    provider_name = excluded.provider_name,
    cost_points = excluded.cost_points,
    stock_count = excluded.stock_count,
    eligible_plan_codes = excluded.eligible_plan_codes,
    available_from = excluded.available_from,
    available_until = excluded.available_until,
    is_active = excluded.is_active,
    updated_by = auth.uid(),
    updated_at = now()
  returning * into v_offer;

  perform public.admin_write_audit(
    'admin_upsert_physical_reward_offer', 'wellness_reward_offer', v_offer.id::text,
    p_reason, p_idempotency_key,
    jsonb_build_object(
      'reward_type', v_offer.reward_type,
      'is_active', v_offer.is_active,
      'cost_points', v_offer.cost_points,
      'stock_count', v_offer.stock_count,
      'eligible_plan_codes', v_offer.eligible_plan_codes
    )
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Đã lưu quà tặng.',
    'offer_id', v_offer.id,
    'accepted_count', 1,
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.admin_list_wellness_rewards_v2(
  p_query text default '',
  p_limit integer default 100
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_offers jsonb;
  v_redemptions jsonb;
  v_limit integer := greatest(1, least(coalesce(p_limit, 100), 200));
begin
  perform public.admin_assert_permission('wellness_rewards.read');

  select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) into v_offers
  from (
    select
      'offer'::text as item_type,
      wro.id,
      wro.id as offer_id,
      wro.reward_type,
      wro.title,
      wro.description,
      wro.provider_name,
      wro.cost_points,
      wro.stock_count,
      wro.eligible_plan_codes,
      wro.available_from,
      wro.available_until,
      wro.voucher_expires_at,
      wro.is_active,
      (select count(*)::integer from public.wellness_reward_codes wrc
        where wrc.offer_id = wro.id and wrc.status = 'available'
          and coalesce(wrc.voucher_expires_at, wro.voucher_expires_at) > now()) as available_codes,
      (select count(*)::integer from public.wellness_reward_codes wrc
        where wrc.offer_id = wro.id and wrc.status = 'issued') as issued_codes,
      wro.created_at,
      wro.updated_at as sort_at
    from public.wellness_reward_offers wro
    where coalesce(btrim(p_query), '') = ''
       or wro.title ilike '%' || btrim(p_query) || '%'
       or wro.provider_name ilike '%' || btrim(p_query) || '%'
       or wro.offer_code ilike '%' || btrim(p_query) || '%'
    order by wro.updated_at desc, wro.id desc
    limit v_limit
  ) q;

  select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) into v_redemptions
  from (
    select
      'redemption'::text as item_type,
      wrr.id,
      wrr.id as redemption_id,
      wrr.offer_id,
      wrr.reward_type_snapshot as reward_type,
      wrr.offer_title_snapshot as title,
      wrr.provider_name_snapshot as provider_name,
      wrr.points_spent,
      wrr.status,
      wrr.voucher_expires_at,
      wrr.received_at,
      wrr.received_by,
      wrr.user_id,
      coalesce(nullif(u.full_name, ''),
        case when position('@' in coalesce(u.email, '')) > 1
          then left(u.email, 1) || '***' || substring(u.email from position('@' in u.email))
          else 'Tài khoản NanoBio' end) as user_label,
      case when wrr.reward_type_snapshot = 'voucher' then '••••••'::text else null end as masked_code,
      wrr.created_at,
      wrr.cancelled_at,
      wrr.updated_at as sort_at
    from public.wellness_reward_redemptions wrr
    join public.users u on u.id = wrr.user_id
    where coalesce(btrim(p_query), '') = ''
       or wrr.offer_title_snapshot ilike '%' || btrim(p_query) || '%'
       or wrr.provider_name_snapshot ilike '%' || btrim(p_query) || '%'
       or coalesce(u.full_name, '') ilike '%' || btrim(p_query) || '%'
       or coalesce(u.email, '') ilike '%' || btrim(p_query) || '%'
    order by wrr.updated_at desc, wrr.id desc
    limit v_limit
  ) q;

  return jsonb_build_object('offers', v_offers, 'redemptions', v_redemptions);
end;
$$;

create or replace function public.admin_mark_reward_redemption_received(
  p_redemption_id uuid,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_redemption public.wellness_reward_redemptions%rowtype;
  v_existing_audit public.admin_audit_events%rowtype;
begin
  perform public.admin_assert_permission('wellness_rewards.write');
  if p_redemption_id is null then
    raise exception using errcode = 'P0001', message = 'redemption_required';
  end if;
  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'admin_reason_required';
  end if;
  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception using errcode = 'P0001', message = 'idempotency_key_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness:admin:received:' || btrim(p_idempotency_key), 0
  ));
  select * into v_existing_audit
  from public.admin_audit_events aae
  where aae.action = 'admin_mark_reward_redemption_received'
    and aae.idempotency_key = btrim(p_idempotency_key);
  if v_existing_audit.id is not null then
    if v_existing_audit.target_id <> p_redemption_id::text then
      raise exception using errcode = 'P0001', message = 'idempotency_conflict';
    end if;
    return jsonb_build_object('success', true, 'status', 'received', 'idempotent_replay', true);
  end if;

  select * into v_redemption
  from public.wellness_reward_redemptions
  where id = p_redemption_id
  for update;
  if v_redemption.id is null then
    raise exception using errcode = 'P0001', message = 'redemption_not_found';
  end if;
  if v_redemption.reward_type_snapshot <> 'physical' then
    raise exception using errcode = 'P0001', message = 'physical_reward_required';
  end if;
  if v_redemption.status = 'received' then
    return jsonb_build_object(
      'success', true, 'status', 'received', 'received_at', v_redemption.received_at,
      'idempotent_replay', true
    );
  end if;
  if v_redemption.status <> 'redeemed' then
    raise exception using errcode = 'P0001', message = 'reward_cannot_be_received';
  end if;

  update public.wellness_reward_redemptions
  set status = 'received', received_at = now(), received_by = auth.uid(), updated_at = now()
  where id = v_redemption.id
  returning * into v_redemption;

  perform public.admin_write_audit(
    'admin_mark_reward_redemption_received', 'wellness_reward_redemption',
    v_redemption.id::text, p_reason, p_idempotency_key,
    jsonb_build_object(
      'reward_type', v_redemption.reward_type_snapshot,
      'previous_status', 'redeemed',
      'status', 'received',
      'received_at', v_redemption.received_at
    )
  );

  return jsonb_build_object(
    'success', true, 'redemption_id', v_redemption.id, 'status', 'received',
    'received_at', v_redemption.received_at, 'received_by', v_redemption.received_by,
    'idempotent_replay', false
  );
end;
$$;

revoke all on function public.guard_wellness_reward_redemption_type() from public, anon, authenticated;
revoke all on function public.guard_wellness_reward_code_offer_type() from public, anon, authenticated;
revoke all on function public.list_my_reward_catalog_v2(integer) from public, anon;
revoke all on function public.list_my_reward_redemptions_v2(integer) from public, anon;
revoke all on function public.redeem_my_reward_v2(uuid, text) from public, anon;
revoke all on function public.admin_upsert_reward_offer_v2(uuid, text, text, text, text, integer, integer, text[], timestamptz, timestamptz, timestamptz, boolean, text, text) from public, anon;
revoke all on function public.admin_list_wellness_rewards_v2(text, integer) from public, anon;
revoke all on function public.admin_mark_reward_redemption_received(uuid, text, text) from public, anon;

grant execute on function public.list_my_reward_catalog_v2(integer) to authenticated;
grant execute on function public.list_my_reward_redemptions_v2(integer) to authenticated;
grant execute on function public.redeem_my_reward_v2(uuid, text) to authenticated;
grant execute on function public.admin_upsert_reward_offer_v2(uuid, text, text, text, text, integer, integer, text[], timestamptz, timestamptz, timestamptz, boolean, text, text) to authenticated;
grant execute on function public.admin_list_wellness_rewards_v2(text, integer) to authenticated;
grant execute on function public.admin_mark_reward_redemption_received(uuid, text, text) to authenticated;

commit;
