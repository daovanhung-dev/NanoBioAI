-- Commit de xuat: docs(supabase): cap nhat module Sale full noi bo
-- NanoBio / BioAI - Sale direct-only internal module update.
-- Run after 01-core-auth-profile.sql, 05-sale-referral-commission.sql,
-- 10-mobile-sync-and-sale-rpc.sql and 11-admin-access-dashboard.sql.
-- Draft only: review in sandbox/staging before production migration.

begin;

-- In the existing domain, `pending` represents BD v2.0 pending_review.
-- Admin approval is required before a user receives an active referral code.

create table if not exists public.sale_point_conversions (
  id uuid primary key default gen_random_uuid(),
  sale_user_id uuid not null references public.users(id) on delete restrict,
  requested_point_cents integer not null check (requested_point_cents > 0),
  point_to_money_rate numeric(12, 4) not null check (point_to_money_rate > 0),
  money_amount_cents integer not null check (money_amount_cents >= 0),
  currency text not null default 'VND',
  status text not null default 'requested'
    check (status in ('requested', 'pending_review', 'approved', 'paid', 'rejected', 'cancelled')),
  idempotency_key text,
  requested_at timestamptz not null default now(),
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  review_reason text,
  paid_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_sale_point_conversions_idempotency
  on public.sale_point_conversions (sale_user_id, idempotency_key)
  where idempotency_key is not null;

create index if not exists idx_sale_point_conversions_sale_created
  on public.sale_point_conversions (sale_user_id, created_at desc);

drop trigger if exists trg_sale_point_conversions_updated_at
  on public.sale_point_conversions;
create trigger trg_sale_point_conversions_updated_at
  before update on public.sale_point_conversions
  for each row execute function public.set_updated_at();

insert into public.system_config_versions (
  config_key,
  config_value,
  status,
  reason,
  created_by
)
select
  'sale_point_conversion',
  '{"enabled": false, "point_to_money_rate": 1, "minimum_point_cents": 100000, "currency": "VND"}'::jsonb,
  'active',
  'Default disabled Sale point conversion policy.',
  null
where not exists (
  select 1
  from public.system_config_versions
  where config_key = 'sale_point_conversion'
    and status = 'active'
);

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

create or replace function public.request_sale_participation(
  p_terms_version text
)
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
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if nullif(btrim(p_terms_version), '') is null then
    raise exception 'TERMS_VERSION_REQUIRED' using errcode = '22023';
  end if;

  select status into v_existing_status
  from public.sale_profiles
  where user_id = v_user_id
  for update;

  if v_existing_status in ('suspended', 'closed') then
    raise exception 'SALE_STATUS_REQUIRES_SUPPORT' using errcode = '42501';
  end if;

  if v_existing_status = 'active' then
    update public.sale_profiles
    set
      terms_version = btrim(p_terms_version),
      terms_accepted_at = now(),
      note = 'Da cap nhat dieu le Sale trong ung dung.',
      updated_at = now()
    where user_id = v_user_id;
  else
    insert into public.sale_profiles (
      user_id,
      status,
      terms_version,
      terms_accepted_at,
      note
    )
    values (
      v_user_id,
      'pending',
      btrim(p_terms_version),
      now(),
      'Da gui yeu cau Sale; dang cho Admin duyet.'
    )
    on conflict (user_id) do update
    set
      status = 'pending',
      terms_version = excluded.terms_version,
      terms_accepted_at = excluded.terms_accepted_at,
      note = excluded.note,
      updated_at = now();
  end if;

  return query select * from public.get_my_sale_state();
end;
$$;

create or replace function public.attach_my_referral_code(
  p_referral_code text
)
returns table (
  success boolean,
  message text,
  referrer_display_name text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_code text := upper(replace(btrim(coalesce(p_referral_code, '')), ' ', ''));
  v_referrer_id uuid;
  v_referrer_name text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if v_code = '' then
    return query select false, 'Ma gioi thieu khong hop le.', null::text;
    return;
  end if;

  select rc.sale_user_id, coalesce(nullif(u.full_name, ''), 'Sale NanoBio')
  into v_referrer_id, v_referrer_name
  from public.referral_codes rc
  join public.sale_profiles sp
    on sp.user_id = rc.sale_user_id
   and sp.status = 'active'
  join public.users u on u.id = rc.sale_user_id
  where rc.code = v_code
    and rc.status = 'active'
  limit 1;

  if v_referrer_id is null then
    return query select false, 'Ma gioi thieu khong ton tai hoac chua hoat dong.', null::text;
    return;
  end if;

  if v_referrer_id = v_user_id then
    return query select false, 'Khong the dung ma gioi thieu cua chinh minh.', null::text;
    return;
  end if;

  if exists (
    select 1
    from public.referral_relationships
    where referred_user_id = v_user_id
      and status = 'active'
  ) then
    return query select false, 'Tai khoan da co ma gioi thieu.', null::text;
    return;
  end if;

  if exists (
    select 1
    from public.payment_events
    where payer_user_id = v_user_id
      and status in ('pending', 'succeeded', 'refunded', 'chargeback')
  ) then
    return query select false, 'Tai khoan da co lich su payment nen khong the gan ma trong ung dung.', null::text;
    return;
  end if;

  insert into public.referral_relationships (
    referrer_user_id,
    referred_user_id,
    referral_code,
    source,
    status
  )
  values (
    v_referrer_id,
    v_user_id,
    v_code,
    'signup',
    'active'
  );

  return query select true, 'Da gan ma gioi thieu.', v_referrer_name;
end;
$$;

create or replace function public.admin_review_sale_profile(
  p_sale_user_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status public.nb_sale_status;
  v_candidate text;
  v_created_code text;
begin
  perform public.admin_assert_permission('sales.write');

  v_status := case p_decision
    when 'approve' then 'active'::public.nb_sale_status
    when 'reject' then 'closed'::public.nb_sale_status
    when 'suspend' then 'suspended'::public.nb_sale_status
    when 'close' then 'closed'::public.nb_sale_status
    else null
  end;

  if v_status is null then
    raise exception 'INVALID_SALE_DECISION' using errcode = '22023';
  end if;

  insert into public.sale_profiles (user_id, status, approved_at, note)
  values (
    p_sale_user_id,
    v_status,
    case when v_status = 'active' then now() else null end,
    btrim(p_reason)
  )
  on conflict (user_id) do update
  set
    status = excluded.status,
    approved_at = case
      when excluded.status = 'active' then coalesce(public.sale_profiles.approved_at, now())
      else public.sale_profiles.approved_at
    end,
    suspended_at = case
      when excluded.status = 'suspended' then now()
      else public.sale_profiles.suspended_at
    end,
    closed_at = case
      when excluded.status = 'closed' then now()
      else public.sale_profiles.closed_at
    end,
    note = excluded.note,
    updated_at = now();

  if v_status = 'active' and not exists (
    select 1
    from public.referral_codes
    where sale_user_id = p_sale_user_id
      and status = 'active'
  ) then
    for i in 1..12 loop
      v_candidate := 'NANO-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
      insert into public.referral_codes (code, sale_user_id, status)
      values (v_candidate, p_sale_user_id, 'active')
      on conflict (code) do nothing
      returning code into v_created_code;
      exit when v_created_code is not null;
    end loop;

    if v_created_code is null then
      raise exception 'REFERRAL_CODE_ALLOCATION_FAILED';
    end if;
  end if;

  perform public.admin_write_audit(
    'admin_review_sale_profile',
    'sale_profile',
    p_sale_user_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('decision', p_decision, 'status', v_status::text)
  );

  return query select true, 'Da cap nhat Sale.';
end;
$$;

create or replace function public.get_my_sale_dashboard()
returns table (
  direct_customers integer,
  successful_payments integer,
  pending_point_cents integer,
  approved_point_cents integer,
  paid_point_cents integer,
  converted_point_cents integer,
  available_point_cents integer,
  currency text,
  conversion_enabled boolean,
  conversion_rate numeric,
  conversion_minimum_point_cents integer,
  conversion_currency text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
  v_config jsonb := '{}'::jsonb;
  v_enabled boolean := false;
  v_rate numeric := 0;
  v_minimum integer := 0;
  v_conversion_currency text := 'VND';
begin
  select config_value into v_config
  from public.system_config_versions
  where config_key = 'sale_point_conversion'
    and status = 'active'
  order by created_at desc
  limit 1;

  v_config := coalesce(v_config, '{}'::jsonb);
  v_enabled := coalesce((v_config ->> 'enabled')::boolean, false);
  v_rate := coalesce((v_config ->> 'point_to_money_rate')::numeric, 0);
  v_minimum := coalesce((v_config ->> 'minimum_point_cents')::integer, 0);
  v_conversion_currency := coalesce(nullif(v_config ->> 'currency', ''), 'VND');

  return query
  with direct_nodes as (
    select rr.referred_user_id
    from public.referral_relationships rr
    where rr.referrer_user_id = v_user_id
      and rr.status = 'active'
  ), payment_summary as (
    select count(distinct pe.id)::integer as success_count
    from public.payment_events pe
    join direct_nodes dn on dn.referred_user_id = pe.payer_user_id
    where pe.status = 'succeeded'
  ), point_summary as (
    select
      coalesce(sum(amount_cents) filter (
        where status in ('pending', 'approved')
          and available_at > now()
      ), 0)::integer as pending_cents,
      coalesce(sum(amount_cents) filter (
        where status in ('pending', 'approved')
          and available_at <= now()
      ), 0)::integer as approved_cents,
      coalesce(sum(amount_cents) filter (where status = 'paid'), 0)::integer as paid_cents,
      coalesce(max(currency), 'VND') as result_currency
    from public.commission_records
    where receiver_user_id = v_user_id
  ), adjustment_summary as (
    select coalesce(sum(point_delta_cents), 0)::integer as adjustment_cents
    from public.sale_point_adjustments
    where sale_user_id = v_user_id
      and status = 'approved'
  ), conversion_summary as (
    select coalesce(sum(requested_point_cents), 0)::integer as converted_cents
    from public.sale_point_conversions
    where sale_user_id = v_user_id
      and status in ('requested', 'pending_review', 'approved', 'paid')
  )
  select
    (select count(*)::integer from direct_nodes),
    coalesce(ps.success_count, 0),
    pts.pending_cents,
    greatest(pts.approved_cents + ads.adjustment_cents, 0)::integer,
    pts.paid_cents,
    cs.converted_cents,
    greatest(pts.approved_cents + ads.adjustment_cents - cs.converted_cents, 0)::integer,
    pts.result_currency,
    v_enabled,
    v_rate,
    v_minimum,
    v_conversion_currency
  from payment_summary ps
  cross join point_summary pts
  cross join adjustment_summary ads
  cross join conversion_summary cs;
end;
$$;

create or replace function public.get_my_sale_direct_customers()
returns table (
  display_name text,
  accepted_at timestamptz,
  successful_payments integer,
  approved_point_cents integer,
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
    select rr.referred_user_id, rr.accepted_at
    from public.referral_relationships rr
    where rr.referrer_user_id = v_user_id
      and rr.status = 'active'
  ), payments as (
    select payer_user_id, count(*)::integer as success_count
    from public.payment_events
    where status = 'succeeded'
    group by payer_user_id
  ), points as (
    select
      payer_user_id,
      coalesce(sum(amount_cents) filter (
        where status in ('pending', 'approved')
          and available_at <= now()
      ), 0)::integer as approved_cents,
      coalesce(max(currency), 'VND') as result_currency
    from public.commission_records
    where receiver_user_id = v_user_id
    group by payer_user_id
  )
  select
    coalesce(nullif(u.full_name, ''), 'Nguoi dung NanoBio'),
    dn.accepted_at,
    coalesce(p.success_count, 0),
    coalesce(pt.approved_cents, 0),
    coalesce(pt.result_currency, 'VND')
  from direct_nodes dn
  join public.users u on u.id = dn.referred_user_id
  left join payments p on p.payer_user_id = dn.referred_user_id
  left join points pt on pt.payer_user_id = dn.referred_user_id
  order by dn.accepted_at desc;
end;
$$;

create or replace function public.get_my_sale_point_ledger()
returns table (
  id text,
  customer_name text,
  plan_code text,
  payment_amount_cents integer,
  point_amount_cents integer,
  currency text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  return query
  select
    cr.id::text,
    coalesce(nullif(u.full_name, ''), 'Nguoi dung NanoBio') as customer_name,
    pe.plan_code::text,
    pe.amount_cents,
    cr.amount_cents,
    cr.currency,
    cr.status,
    cr.created_at
  from public.commission_records cr
  join public.payment_events pe on pe.id = cr.payment_event_id
  join public.users u on u.id = cr.payer_user_id
  where cr.receiver_user_id = v_user_id
  union all
  select
    spa.id::text,
    'Dieu chinh Admin' as customer_name,
    'manual_adjustment' as plan_code,
    0 as payment_amount_cents,
    spa.point_delta_cents,
    spa.currency,
    spa.status,
    spa.created_at
  from public.sale_point_adjustments spa
  where spa.sale_user_id = v_user_id
  order by created_at desc;
end;
$$;

create or replace function public.get_my_sale_conversions()
returns table (
  id text,
  requested_point_cents integer,
  money_amount_cents integer,
  currency text,
  status text,
  requested_at timestamptz,
  reviewed_at timestamptz,
  note text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
begin
  return query
  select
    spc.id::text,
    spc.requested_point_cents,
    spc.money_amount_cents,
    spc.currency,
    spc.status,
    spc.requested_at,
    spc.reviewed_at,
    spc.review_reason
  from public.sale_point_conversions spc
  where spc.sale_user_id = v_user_id
  order by spc.created_at desc;
end;
$$;

create or replace function public.request_sale_point_conversion(
  p_requested_point_cents integer,
  p_idempotency_key text
)
returns table (
  id text,
  requested_point_cents integer,
  money_amount_cents integer,
  currency text,
  status text,
  requested_at timestamptz,
  reviewed_at timestamptz,
  note text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := public.require_active_sale_user();
  v_config jsonb := '{}'::jsonb;
  v_enabled boolean := false;
  v_rate numeric := 0;
  v_minimum integer := 0;
  v_currency text := 'VND';
  v_approved integer := 0;
  v_held integer := 0;
  v_available integer := 0;
  v_conversion_id uuid;
begin
  if p_requested_point_cents is null or p_requested_point_cents <= 0 then
    raise exception 'INVALID_CONVERSION_POINTS' using errcode = '22023';
  end if;

  select config_value into v_config
  from public.system_config_versions
  where config_key = 'sale_point_conversion'
    and status = 'active'
  order by created_at desc
  limit 1;

  v_config := coalesce(v_config, '{}'::jsonb);
  v_enabled := coalesce((v_config ->> 'enabled')::boolean, false);
  v_rate := coalesce((v_config ->> 'point_to_money_rate')::numeric, 0);
  v_minimum := coalesce((v_config ->> 'minimum_point_cents')::integer, 0);
  v_currency := coalesce(nullif(v_config ->> 'currency', ''), 'VND');

  if not v_enabled or v_rate <= 0 then
    raise exception 'SALE_CONVERSION_DISABLED' using errcode = '42501';
  end if;

  if p_requested_point_cents < v_minimum then
    raise exception 'SALE_CONVERSION_MINIMUM_NOT_MET' using errcode = '22023';
  end if;

  select (
    select coalesce(sum(amount_cents), 0)::integer
    from public.commission_records
    where receiver_user_id = v_user_id
      and status in ('pending', 'approved')
      and available_at <= now()
  ) + (
    select coalesce(sum(point_delta_cents), 0)::integer
    from public.sale_point_adjustments
    where sale_user_id = v_user_id
      and status = 'approved'
  ) into v_approved;

  select coalesce(sum(requested_point_cents), 0)::integer into v_held
  from public.sale_point_conversions
  where sale_user_id = v_user_id
    and status in ('requested', 'pending_review', 'approved', 'paid');

  v_available := greatest(v_approved - v_held, 0);

  if p_requested_point_cents > v_available then
    raise exception 'SALE_CONVERSION_POINTS_EXCEED_AVAILABLE' using errcode = '22023';
  end if;

  insert into public.sale_point_conversions (
    sale_user_id,
    requested_point_cents,
    point_to_money_rate,
    money_amount_cents,
    currency,
    status,
    idempotency_key
  )
  values (
    v_user_id,
    p_requested_point_cents,
    v_rate,
    round(p_requested_point_cents * v_rate)::integer,
    v_currency,
    'requested',
    nullif(btrim(p_idempotency_key), '')
  )
  on conflict (sale_user_id, idempotency_key)
  where idempotency_key is not null
  do update set metadata = public.sale_point_conversions.metadata
  returning public.sale_point_conversions.id into v_conversion_id;

  return query
  select
    spc.id::text,
    spc.requested_point_cents,
    spc.money_amount_cents,
    spc.currency,
    spc.status,
    spc.requested_at,
    spc.reviewed_at,
    spc.review_reason
  from public.sale_point_conversions spc
  where spc.id = v_conversion_id;
end;
$$;

create or replace function public.admin_list_sale_point_conversions(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  title text,
  subtitle text,
  status text,
  section text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('sales.write');

  return query
  select
    spc.id::text,
    concat(coalesce(nullif(u.full_name, ''), u.email, spc.sale_user_id::text), ' - ', spc.requested_point_cents::text, ' diem'),
    concat_ws(' - ', spc.money_amount_cents::text || ' ' || spc.currency, spc.review_reason),
    spc.status,
    'sale_point_conversions',
    spc.created_at
  from public.sale_point_conversions spc
  join public.users u on u.id = spc.sale_user_id
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or spc.id::text = p_query
  order by spc.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_review_sale_point_conversion(
  p_conversion_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
begin
  perform public.admin_assert_permission('sales.write');

  v_status := case p_decision
    when 'approve' then 'approved'
    when 'reject' then 'rejected'
    when 'mark_paid' then 'paid'
    else null
  end;

  if v_status is null then
    raise exception 'INVALID_CONVERSION_DECISION' using errcode = '22023';
  end if;

  update public.sale_point_conversions
  set
    status = v_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason),
    paid_at = case when v_status = 'paid' then now() else paid_at end,
    metadata = metadata || jsonb_build_object('admin_decision', p_decision)
  where id = p_conversion_id;

  if not found then
    raise exception 'SALE_CONVERSION_NOT_FOUND' using errcode = '22023';
  end if;

  perform public.admin_write_audit(
    'admin_review_sale_point_conversion',
    'sale_point_conversion',
    p_conversion_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('decision', p_decision, 'status', v_status)
  );

  return query select true, 'Da cap nhat yeu cau quy doi diem Sale.';
end;
$$;

alter table public.sale_point_conversions enable row level security;

drop policy if exists sale_point_conversions_select_own
  on public.sale_point_conversions;
create policy sale_point_conversions_select_own
  on public.sale_point_conversions for select to authenticated
  using (
    sale_user_id = (select auth.uid())
    or public.admin_has_permission('sales.write')
  );

grant select on public.sale_point_conversions to authenticated;
revoke insert, update, delete on public.sale_point_conversions
from anon, authenticated;

revoke all on function public.attach_my_referral_code(text) from public, anon;
revoke all on function public.get_my_sale_direct_customers() from public, anon;
revoke all on function public.get_my_sale_point_ledger() from public, anon;
revoke all on function public.get_my_sale_conversions() from public, anon;
revoke all on function public.request_sale_point_conversion(integer, text)
from public, anon;
revoke all on function public.admin_list_sale_point_conversions(text, integer)
from public, anon;
revoke all on function public.admin_review_sale_point_conversion(uuid, text, text, text)
from public, anon;

grant execute on function public.attach_my_referral_code(text) to authenticated;
grant execute on function public.get_my_sale_direct_customers() to authenticated;
grant execute on function public.get_my_sale_point_ledger() to authenticated;
grant execute on function public.get_my_sale_conversions() to authenticated;
grant execute on function public.request_sale_point_conversion(integer, text)
to authenticated;
grant execute on function public.admin_list_sale_point_conversions(text, integer)
to authenticated;
grant execute on function public.admin_review_sale_point_conversion(uuid, text, text, text)
to authenticated;

commit;
