-- Commit de xuat: docs(supabase): tao admin access dashboard schema
-- NanoBio / BioAI - Admin roles, dashboard, CRUD RPC and audit draft.
-- Run after 01-core-auth-profile.sql, 03-membership-quota.sql and
-- 05-sale-referral-commission.sql.
-- Draft only: review in sandbox/staging before production migration.

begin;

alter table public.users
  add column if not exists admin_status text not null default 'active'
    check (admin_status in ('active', 'suspended', 'closed'));

create table if not exists public.admin_roles (
  code text primary key
    check (code in (
      'super_admin',
      'finance_admin',
      'support_admin',
      'content_admin',
      'operations_admin'
    )),
  display_name text not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_permissions (
  code text primary key,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_role_permissions (
  role_code text not null references public.admin_roles(code) on delete cascade,
  permission_code text not null references public.admin_permissions(code) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role_code, permission_code)
);

create table if not exists public.admin_user_roles (
  user_id uuid not null references public.users(id) on delete cascade,
  role_code text not null references public.admin_roles(code) on delete restrict,
  scope text not null default 'global',
  is_active boolean not null default true,
  granted_by uuid references public.users(id) on delete set null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  primary key (user_id, role_code, scope)
);

create table if not exists public.admin_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text not null,
  reason text not null,
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (action, idempotency_key)
);

create table if not exists public.system_config_versions (
  id uuid primary key default gen_random_uuid(),
  config_key text not null,
  config_value jsonb not null default '{}'::jsonb,
  status text not null default 'active'
    check (status in ('draft', 'active', 'archived')),
  reason text not null,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (config_key, created_at)
);

create or replace function public.create_membership_payment_request(
  p_plan_code public.nb_membership_plan,
  p_billing_cycle text,
  p_idempotency_key text
)
returns table (
  payment_event_id uuid,
  plan_code text,
  billing_cycle text,
  status text,
  amount_cents integer,
  currency text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_config jsonb;
  v_amount_cents integer;
  v_currency text;
  v_provider text := 'manual_membership_request';
  v_provider_event_id text;
  v_payment public.payment_events%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if p_plan_code not in ('plus', 'family_plus') then
    raise exception 'INVALID_MEMBERSHIP_PLAN' using errcode = '22023';
  end if;

  if btrim(coalesce(p_billing_cycle, '')) not in ('monthly', 'yearly') then
    raise exception 'INVALID_BILLING_CYCLE' using errcode = '22023';
  end if;

  if nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED' using errcode = '22023';
  end if;

  select scv.config_value
  into v_config
  from public.system_config_versions scv
  where scv.config_key = 'membership_payment_prices'
    and scv.status = 'active'
  order by scv.created_at desc
  limit 1;

  v_amount_cents := nullif(
    v_config #>> array['prices', p_plan_code::text, btrim(p_billing_cycle)],
    ''
  )::integer;
  v_currency := coalesce(nullif(v_config ->> 'currency', ''), 'VND');

  if v_amount_cents is null or v_amount_cents <= 0 then
    raise exception 'MEMBERSHIP_PAYMENT_PRICE_NOT_CONFIGURED'
      using errcode = '22023';
  end if;

  v_provider_event_id := concat(v_user_id::text, ':', btrim(p_idempotency_key));

  insert into public.payment_events (
    payer_user_id,
    plan_code,
    provider,
    provider_event_id,
    amount_cents,
    list_price_cents,
    commission_base_cents,
    currency,
    status,
    idempotency_key,
    metadata
  )
  values (
    v_user_id,
    p_plan_code,
    v_provider,
    v_provider_event_id,
    v_amount_cents,
    v_amount_cents,
    v_amount_cents,
    v_currency,
    'pending',
    btrim(p_idempotency_key),
    jsonb_build_object(
      'billing_cycle',
      btrim(p_billing_cycle),
      'manual_approval_required',
      true,
      'grants_access_before_approval',
      false
    )
  )
  on conflict (provider, provider_event_id) do update
  set metadata = public.payment_events.metadata || jsonb_build_object(
    'idempotent_replay',
    true
  )
  returning * into v_payment;

  return query select
    v_payment.id,
    v_payment.plan_code::text,
    coalesce(v_payment.metadata ->> 'billing_cycle', btrim(p_billing_cycle)),
    v_payment.status,
    v_payment.amount_cents,
    v_payment.currency,
    v_payment.created_at;
end;
$$;

create table if not exists public.report_exports (
  id uuid primary key default gen_random_uuid(),
  report_type text not null,
  filters jsonb not null default '{}'::jsonb,
  status text not null default 'requested'
    check (status in ('requested', 'generating', 'ready', 'failed')),
  reason text not null,
  requested_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.sale_point_adjustments (
  id uuid primary key default gen_random_uuid(),
  sale_user_id uuid not null references public.users(id) on delete restrict,
  point_delta_cents integer not null check (point_delta_cents <> 0),
  currency text not null default 'VND',
  status text not null default 'approved'
    check (status in ('approved', 'reversed')),
  reason text not null,
  reviewed_by uuid references public.users(id) on delete set null,
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (idempotency_key)
);

create table if not exists public.admin_reconciliation_runs (
  id uuid primary key default gen_random_uuid(),
  scope text not null default 'payments',
  status text not null default 'open'
    check (status in ('open', 'resolved', 'failed')),
  reason text not null,
  created_by uuid references public.users(id) on delete set null,
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (idempotency_key)
);

create table if not exists public.admin_reconciliation_discrepancies (
  id uuid primary key default gen_random_uuid(),
  run_id uuid references public.admin_reconciliation_runs(id) on delete set null,
  target_type text not null,
  target_id text not null,
  severity text not null default 'medium'
    check (severity in ('low', 'medium', 'high')),
  status text not null default 'open'
    check (status in ('open', 'needs_follow_up', 'resolved', 'adjusted', 'dismissed')),
  summary text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  review_reason text
);

drop trigger if exists trg_admin_roles_updated_at on public.admin_roles;
create trigger trg_admin_roles_updated_at
  before update on public.admin_roles
  for each row execute function public.set_updated_at();

insert into public.admin_roles (code, display_name, description)
values
  ('super_admin', 'Super Admin', 'Full Admin control including roles and config.'),
  ('finance_admin', 'Finance Admin', 'Payment, Sale point and finance reports.'),
  ('support_admin', 'Support Admin', 'Customer support and user operations.'),
  ('content_admin', 'Content Admin', 'Content and plan configuration operations.'),
  ('operations_admin', 'Operations Admin', 'User, Sale and support operations.')
on conflict (code) do update
set
  display_name = excluded.display_name,
  description = excluded.description,
  is_active = true,
  updated_at = now();

insert into public.admin_permissions (code, description)
values
  ('*', 'All Admin permissions.'),
  ('dashboard.read', 'Read Admin dashboard.'),
  ('users.write', 'Manage user operational state.'),
  ('payments.write', 'Approve or reject payment events.'),
  ('sales.write', 'Approve or suspend Sale profiles.'),
  ('reconciliation.write', 'Run reconciliation and classify discrepancies.'),
  ('points.write', 'Adjust Sale points with Admin audit.'),
  ('plans.write', 'Version plan and package config.'),
  ('reports.write', 'Request report exports.'),
  ('audit.read', 'Read Admin audit events.'),
  ('config.write', 'Version system configuration.')
on conflict (code) do update
set description = excluded.description, is_active = true;

insert into public.admin_role_permissions (role_code, permission_code)
values
  ('super_admin', '*'),
  ('finance_admin', '*'),
  ('support_admin', '*'),
  ('content_admin', '*'),
  ('operations_admin', '*')
on conflict (role_code, permission_code) do nothing;

create or replace function public.admin_has_permission(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.admin_user_roles aur
    join public.admin_roles ar
      on ar.code = aur.role_code
     and ar.is_active = true
    join public.admin_role_permissions arp
      on arp.role_code = aur.role_code
    join public.admin_permissions ap
      on ap.code = arp.permission_code
     and ap.is_active = true
    where aur.user_id = auth.uid()
      and aur.is_active = true
      and aur.revoked_at is null
      and (ap.code = '*' or ap.code = p_permission)
  )
$$;

create or replace function public.admin_assert_permission(p_permission text)
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not public.admin_has_permission(p_permission) then
    raise exception 'ADMIN_PERMISSION_REQUIRED' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.admin_write_audit(
  p_action text,
  p_target_type text,
  p_target_id text,
  p_reason text,
  p_idempotency_key text,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if nullif(btrim(p_reason), '') is null then
    raise exception 'ADMIN_REASON_REQUIRED' using errcode = '22023';
  end if;

  insert into public.admin_audit_events (
    actor_id,
    action,
    target_type,
    target_id,
    reason,
    idempotency_key,
    metadata
  )
  values (
    auth.uid(),
    p_action,
    p_target_type,
    p_target_id,
    btrim(p_reason),
    nullif(btrim(p_idempotency_key), ''),
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (action, idempotency_key) do update
  set metadata = public.admin_audit_events.metadata
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.get_my_admin_session()
returns table (
  user_id uuid,
  roles text[],
  permissions text[],
  is_active boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    auth.uid() as user_id,
    coalesce(array_agg(distinct aur.role_code) filter (where aur.role_code is not null), array[]::text[]) as roles,
    coalesce(array_agg(distinct arp.permission_code) filter (where arp.permission_code is not null), array[]::text[]) as permissions,
    exists (
      select 1
      from public.admin_user_roles active_aur
      where active_aur.user_id = auth.uid()
        and active_aur.is_active = true
        and active_aur.revoked_at is null
    ) as is_active
  from public.admin_user_roles aur
  left join public.admin_role_permissions arp on arp.role_code = aur.role_code
  where aur.user_id = auth.uid()
    and aur.is_active = true
    and aur.revoked_at is null
$$;

drop function if exists public.get_admin_dashboard_summary(timestamptz, timestamptz, text);

create or replace function public.get_admin_dashboard_summary(
  p_from timestamptz,
  p_to timestamptz,
  p_scope text default 'global',
  p_time_zone text default 'Asia/Ho_Chi_Minh'
)
returns table (
  metric_key text,
  label text,
  metric_value integer,
  status text,
  target_section text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_time_zone text := coalesce(nullif(p_time_zone, ''), 'Asia/Ho_Chi_Minh');
begin
  perform public.admin_assert_permission('dashboard.read');
  v_time_zone := case
    when v_time_zone = 'Asia/Ho_Chi_Minh' then v_time_zone
    else 'Asia/Ho_Chi_Minh'
  end;

  return query
  select 'users_total', 'Nguoi dung', count(*)::integer, 'ready', 'users'
  from public.users
  union all
  select 'onboarding_completed', 'Da hoan thanh onboarding', count(*)::integer, 'ready', 'users'
  from public.users u
  where u.onboarding_status = 'completed'
  union all
  select 'packages_active', 'Goi thanh vien active', count(*)::integer, 'active', 'plans'
  from public.membership_subscriptions ms
  where ms.status in ('trialing', 'active')
  union all
  select 'payments_pending', 'Payment cho duyet', count(*)::integer, 'pending', 'payments'
  from public.payment_events pe
  where pe.status = 'pending'
    and pe.created_at between p_from and p_to
  union all
  select 'payments_succeeded', 'Payment hop le', count(*)::integer, 'ready', 'payments'
  from public.payment_events pe
  where pe.status = 'succeeded'
    and coalesce(pe.paid_at, pe.created_at) between p_from and p_to
  union all
  select
    'revenue_succeeded',
    'Doanh thu da duyet',
    coalesce(sum(pe.amount_cents), 0)::integer,
    'ready',
    'reports'
  from public.payment_events pe
  where pe.status = 'succeeded'
    and coalesce(pe.paid_at, pe.created_at) between p_from and p_to
  union all
  select 'sales_active', 'Sale active', count(*)::integer, 'active', 'sales'
  from public.sale_profiles sp
  where sp.status = 'active'
  union all
  select 'familyplus_active', 'FamilyPlus active', count(*)::integer, 'active', 'users'
  from public.family_groups fg
  where fg.status = 'active'
  union all
  select
    'commission_available',
    'Diem Sale kha dung',
    coalesce(sum(cr.amount_cents), 0)::integer,
    'approved',
    'sale_conversions'
  from public.commission_records cr
  where cr.status in ('pending', 'approved')
    and cr.available_at <= now()
    and cr.created_at between p_from and p_to
  union all
  select
    'admin_alerts',
    'Can Admin xu ly',
    (
      (select count(*) from public.admin_reconciliation_discrepancies ard
       where ard.status in ('open', 'needs_follow_up'))
      + (select count(*) from public.payment_events pe
         where pe.status = 'pending' and pe.created_at between p_from and p_to)
    )::integer,
    'pending',
    'reconciliation';
end;
$$;

create or replace function public.admin_search_users(
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
  perform public.admin_assert_permission('users.write');

  return query
  select
    u.id::text,
    coalesce(nullif(u.full_name, ''), nullif(u.email, ''), u.id::text),
    concat_ws(' - ', u.email, u.product_access_status::text, u.sale_status::text),
    u.admin_status,
    'users',
    u.created_at
  from public.users u
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or u.phone ilike '%' || p_query || '%'
  order by u.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_update_user_status(
  p_user_id uuid,
  p_status text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('users.write');

  if p_status not in ('active', 'suspended', 'closed') then
    raise exception 'INVALID_USER_STATUS' using errcode = '22023';
  end if;

  update public.users
  set admin_status = p_status, updated_at = now()
  where id = p_user_id;

  perform public.admin_write_audit(
    'admin_update_user_status',
    'user',
    p_user_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('status', p_status)
  );

  return query select true, 'Da cap nhat trang thai nguoi dung.';
end;
$$;

create or replace function public.admin_list_payments(
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
  perform public.admin_assert_permission('payments.write');

  return query
  select
    pe.id::text,
    concat(pe.plan_code::text, ' - ', pe.amount_cents::text, ' ', pe.currency),
    concat_ws(' - ', coalesce(nullif(u.full_name, ''), u.email), pe.provider, pe.plan_code::text),
    pe.status,
    'payments',
    pe.created_at
  from public.payment_events pe
  join public.users u on u.id = pe.payer_user_id
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or pe.provider_event_id ilike '%' || p_query || '%'
  order by pe.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_review_payment(
  p_payment_event_id uuid,
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
  v_payment public.payment_events%rowtype;
  v_status text;
  v_subscription_id uuid;
begin
  perform public.admin_assert_permission('payments.write');

  if p_decision not in ('approve', 'reject') then
    raise exception 'INVALID_PAYMENT_DECISION' using errcode = '22023';
  end if;

  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if v_payment.status <> 'pending' then
    raise exception 'PAYMENT_ALREADY_REVIEWED' using errcode = '22023';
  end if;

  v_status := case when p_decision = 'approve' then 'succeeded' else 'failed' end;

  update public.payment_events
  set
    status = v_status,
    paid_at = case when p_decision = 'approve' then coalesce(paid_at, now()) else paid_at end,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason),
    idempotency_key = nullif(btrim(p_idempotency_key), ''),
    metadata = metadata || jsonb_build_object(
      'admin_decision',
      p_decision,
      'manual_approval_required',
      true
    )
  where id = p_payment_event_id
  returning * into v_payment;

  if p_decision = 'approve' then
    insert into public.membership_subscriptions (
      user_id,
      plan_code,
      status,
      source,
      starts_at,
      provider,
      provider_subscription_id,
      metadata
    )
    values (
      v_payment.payer_user_id,
      v_payment.plan_code,
      'active',
      'payment_provider',
      now(),
      v_payment.provider,
      v_payment.provider_event_id,
      jsonb_build_object('payment_event_id', v_payment.id)
    )
    returning id into v_subscription_id;

    update public.payment_events
    set subscription_id = v_subscription_id
    where id = v_payment.id;
  end if;

  perform public.admin_write_audit(
    'admin_review_payment',
    'payment_event',
    p_payment_event_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('decision', p_decision)
  );

  return query select true, 'Da xu ly payment.';
end;
$$;

create or replace function public.record_trusted_payment_event(
  p_payer_user_id uuid,
  p_plan_code public.nb_membership_plan,
  p_provider text,
  p_provider_event_id text,
  p_amount_cents integer,
  p_list_price_cents integer default null,
  p_commission_base_cents integer default null,
  p_currency text default 'VND',
  p_auto_approve boolean default false,
  p_raw_event_hash text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_payment_id uuid;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
  v_list_price_cents integer;
  v_commission_base_cents integer;
begin
  v_list_price_cents := coalesce(
    p_list_price_cents,
    nullif(v_metadata ->> 'list_price_cents', '')::integer
  );
  v_commission_base_cents := coalesce(
    p_commission_base_cents,
    v_list_price_cents,
    nullif(v_metadata ->> 'commission_base_cents', '')::integer,
    p_amount_cents
  );

  insert into public.payment_events (
    payer_user_id,
    plan_code,
    provider,
    provider_event_id,
    amount_cents,
    list_price_cents,
    commission_base_cents,
    currency,
    status,
    paid_at,
    raw_event_hash,
    metadata
  )
  values (
    p_payer_user_id,
    p_plan_code,
    p_provider,
    p_provider_event_id,
    p_amount_cents,
    v_list_price_cents,
    v_commission_base_cents,
    coalesce(nullif(p_currency, ''), 'VND'),
    'pending',
    null,
    p_raw_event_hash,
    v_metadata || jsonb_build_object(
      'manual_approval_required',
      true,
      'auto_approve_requested',
      coalesce(p_auto_approve, false),
      'commission_base_policy',
      'list_price_owner_package_only'
    )
  )
  on conflict (provider, provider_event_id) do update
  set
    list_price_cents = coalesce(public.payment_events.list_price_cents, excluded.list_price_cents),
    commission_base_cents = coalesce(public.payment_events.commission_base_cents, excluded.commission_base_cents),
    metadata = public.payment_events.metadata || excluded.metadata
  returning id into v_payment_id;

  return v_payment_id;
end;
$$;

create or replace function public.create_sale_point_reversal_for_payment(
  p_payment_event_id uuid,
  p_decision text,
  p_reason text,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_record record;
begin
  for v_record in
    select
      cr.id,
      cr.receiver_user_id,
      cr.amount_cents,
      cr.currency
    from public.commission_records cr
    where cr.payment_event_id = p_payment_event_id
      and cr.amount_cents > 0
  loop
    insert into public.sale_point_adjustments (
      sale_user_id,
      point_delta_cents,
      currency,
      reason,
      reviewed_by,
      idempotency_key,
      metadata
    )
    values (
      v_record.receiver_user_id,
      -v_record.amount_cents,
      v_record.currency,
      btrim(p_reason),
      auth.uid(),
      concat('sale-reversal-', v_record.id::text),
      jsonb_build_object(
        'payment_event_id',
        p_payment_event_id,
        'commission_record_id',
        v_record.id,
        'reversal_decision',
        p_decision,
        'ledger_policy',
        'negative_adjustment_without_overwriting_commission'
      )
    )
    on conflict (idempotency_key) do nothing;
  end loop;
end;
$$;

create or replace function public.admin_refund_or_cancel_payment(
  p_payment_event_id uuid,
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
  v_payment public.payment_events%rowtype;
  v_status text;
begin
  perform public.admin_assert_permission('payments.write');

  if p_decision not in ('refund', 'cancel', 'chargeback') then
    raise exception 'INVALID_PAYMENT_REVERSAL_DECISION' using errcode = '22023';
  end if;

  select * into v_payment
  from public.payment_events
  where id = p_payment_event_id
  for update;

  if not found then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = '22023';
  end if;

  if coalesce(v_payment.paid_at, v_payment.reviewed_at, v_payment.created_at)
      < now() - interval '24 hours' then
    raise exception 'PAYMENT_REVERSAL_WINDOW_EXPIRED' using errcode = '22023';
  end if;

  v_status := case
    when p_decision = 'refund' then 'refunded'
    when p_decision = 'chargeback' then 'chargeback'
    else 'failed'
  end;

  update public.payment_events
  set
    status = v_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason),
    metadata = metadata || jsonb_build_object('admin_decision', p_decision)
  where id = p_payment_event_id;

  perform public.create_sale_point_reversal_for_payment(
    p_payment_event_id,
    p_decision,
    p_reason,
    p_idempotency_key
  );

  if v_payment.subscription_id is not null then
    update public.membership_subscriptions
    set status = 'canceled', ends_at = least(coalesce(ends_at, now()), now())
    where id = v_payment.subscription_id
      and status in ('trialing', 'active', 'past_due');
  end if;

  perform public.admin_write_audit(
    'admin_refund_or_cancel_payment',
    'payment_event',
    p_payment_event_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'decision',
      p_decision,
      'reversal_policy',
      'negative_sale_point_adjustment'
    )
  );

  return query select true, 'Da xu ly hoan huy va tru diem Sale neu co.';
end;
$$;

create or replace function public.admin_list_sales(
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
    sp.user_id::text,
    coalesce(nullif(u.full_name, ''), nullif(u.email, ''), sp.user_id::text),
    concat_ws(' - ', u.email, rc.code),
    sp.status::text,
    'sales',
    sp.created_at
  from public.sale_profiles sp
  join public.users u on u.id = sp.user_id
  left join public.referral_codes rc
    on rc.sale_user_id = sp.user_id
   and rc.status = 'active'
  where coalesce(p_query, '') = ''
     or u.email ilike '%' || p_query || '%'
     or u.full_name ilike '%' || p_query || '%'
     or rc.code ilike '%' || p_query || '%'
  order by sp.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
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
    approved_at = case when excluded.status = 'active' then coalesce(public.sale_profiles.approved_at, now()) else public.sale_profiles.approved_at end,
    suspended_at = case when excluded.status = 'suspended' then now() else public.sale_profiles.suspended_at end,
    closed_at = case when excluded.status = 'closed' then now() else public.sale_profiles.closed_at end,
    note = excluded.note,
    updated_at = now();

  perform public.admin_write_audit(
    'admin_review_sale_profile',
    'sale_profile',
    p_sale_user_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('decision', p_decision)
  );

  return query select true, 'Da cap nhat Sale.';
end;
$$;

create or replace function public.admin_upsert_config_version(
  p_config_key text,
  p_config_value jsonb,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_permission text;
begin
  v_permission := case
    when p_config_key ilike 'plan%' then 'plans.write'
    else 'config.write'
  end;

  perform public.admin_assert_permission(v_permission);

  update public.system_config_versions
  set status = 'archived'
  where config_key = p_config_key
    and status = 'active';

  insert into public.system_config_versions (
    config_key,
    config_value,
    status,
    reason,
    created_by
  )
  values (
    btrim(p_config_key),
    coalesce(p_config_value, '{}'::jsonb),
    'active',
    btrim(p_reason),
    auth.uid()
  );

  perform public.admin_write_audit(
    'admin_upsert_config_version',
    'system_config',
    p_config_key,
    p_reason,
    p_idempotency_key,
    coalesce(p_config_value, '{}'::jsonb)
  );

  return query select true, 'Da luu phien ban cau hinh.';
end;
$$;

create or replace function public.admin_list_config_versions(
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
  perform public.admin_assert_permission('config.write');

  return query
  select
    scv.config_key,
    scv.config_key,
    scv.reason,
    scv.status,
    'config',
    scv.created_at
  from public.system_config_versions scv
  where coalesce(p_query, '') = ''
     or scv.config_key ilike '%' || p_query || '%'
  order by scv.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_list_plan_config_versions(
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
  perform public.admin_assert_permission('plans.write');

  return query
  select
    scv.config_key,
    scv.config_key,
    scv.reason,
    scv.status,
    'plans',
    scv.created_at
  from public.system_config_versions scv
  where scv.config_key ilike 'plan%'
    and (
      coalesce(p_query, '') = ''
      or scv.config_key ilike '%' || p_query || '%'
    )
  order by scv.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_request_report_export(
  p_report_type text,
  p_filters jsonb,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_export_id uuid;
begin
  perform public.admin_assert_permission('reports.write');

  insert into public.report_exports (
    report_type,
    filters,
    reason,
    requested_by
  )
  values (
    btrim(p_report_type),
    coalesce(p_filters, '{}'::jsonb),
    btrim(p_reason),
    auth.uid()
  )
  returning id into v_export_id;

  perform public.admin_write_audit(
    'admin_request_report_export',
    'report_export',
    v_export_id::text,
    p_reason,
    p_idempotency_key,
    coalesce(p_filters, '{}'::jsonb)
  );

  return query select true, 'Da tao yeu cau xuat bao cao.';
end;
$$;

create or replace function public.admin_list_report_exports(
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
  perform public.admin_assert_permission('reports.write');

  return query
  select
    re.id::text,
    re.report_type,
    re.reason,
    re.status,
    'reports',
    re.created_at
  from public.report_exports re
  where coalesce(p_query, '') = ''
     or re.report_type ilike '%' || p_query || '%'
     or re.reason ilike '%' || p_query || '%'
  order by re.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_adjust_sale_points(
  p_sale_user_id uuid,
  p_point_delta_cents integer,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_adjustment_id uuid;
begin
  perform public.admin_assert_permission('points.write');

  if p_point_delta_cents is null or p_point_delta_cents = 0 then
    raise exception 'INVALID_POINT_ADJUSTMENT' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.sale_profiles
    where user_id = p_sale_user_id
  ) then
    raise exception 'SALE_PROFILE_NOT_FOUND' using errcode = '22023';
  end if;

  insert into public.sale_point_adjustments (
    sale_user_id,
    point_delta_cents,
    reason,
    reviewed_by,
    idempotency_key,
    metadata
  )
  values (
    p_sale_user_id,
    p_point_delta_cents,
    btrim(p_reason),
    auth.uid(),
    nullif(btrim(p_idempotency_key), ''),
    jsonb_build_object('approval_count_required', 1)
  )
  on conflict (idempotency_key) do update
  set metadata = public.sale_point_adjustments.metadata
  returning id into v_adjustment_id;

  perform public.admin_write_audit(
    'admin_adjust_sale_points',
    'sale_point_adjustment',
    v_adjustment_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'sale_user_id',
      p_sale_user_id,
      'point_delta_cents',
      p_point_delta_cents,
      'approval_count_required',
      1
    )
  );

  return query select true, 'Da ghi dieu chinh diem Sale.';
end;
$$;

create or replace function public.admin_create_reconciliation_run(
  p_scope text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_run_id uuid;
begin
  perform public.admin_assert_permission('reconciliation.write');

  insert into public.admin_reconciliation_runs (
    scope,
    status,
    reason,
    created_by,
    idempotency_key
  )
  values (
    coalesce(nullif(btrim(p_scope), ''), 'payments'),
    'open',
    btrim(p_reason),
    auth.uid(),
    nullif(btrim(p_idempotency_key), '')
  )
  on conflict (idempotency_key) do update
  set metadata = public.admin_reconciliation_runs.metadata
  returning id into v_run_id;

  insert into public.admin_reconciliation_discrepancies (
    run_id,
    target_type,
    target_id,
    severity,
    status,
    summary,
    metadata
  )
  select
    v_run_id,
    'payment_event',
    pe.id::text,
    'high',
    'open',
    'Payment da duyet nhung chua co subscription lien ket.',
    jsonb_build_object('payment_event_id', pe.id, 'plan_code', pe.plan_code)
  from public.payment_events pe
  where pe.status = 'succeeded'
    and pe.subscription_id is null
  on conflict do nothing;

  perform public.admin_write_audit(
    'admin_create_reconciliation_run',
    'admin_reconciliation_run',
    v_run_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('scope', p_scope)
  );

  return query select true, 'Da tao phien doi soat.';
end;
$$;

create or replace function public.admin_list_reconciliation_discrepancies(
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
  perform public.admin_assert_permission('reconciliation.write');

  return query
  select
    ard.id::text,
    ard.summary,
    concat_ws(' - ', ard.target_type, ard.target_id, ard.severity),
    ard.status,
    'reconciliation',
    ard.created_at
  from public.admin_reconciliation_discrepancies ard
  where coalesce(p_query, '') = ''
     or ard.summary ilike '%' || p_query || '%'
     or ard.target_id = p_query
  order by ard.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

create or replace function public.admin_update_reconciliation_discrepancy_status(
  p_discrepancy_id uuid,
  p_status text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_discrepancy public.admin_reconciliation_discrepancies%rowtype;
begin
  perform public.admin_assert_permission('reconciliation.write');

  if p_status not in ('needs_follow_up', 'resolved', 'adjusted', 'dismissed') then
    raise exception 'INVALID_RECONCILIATION_STATUS' using errcode = '22023';
  end if;

  select * into v_discrepancy
  from public.admin_reconciliation_discrepancies
  where id = p_discrepancy_id
  for update;

  if not found then
    raise exception 'RECONCILIATION_DISCREPANCY_NOT_FOUND' using errcode = '22023';
  end if;

  update public.admin_reconciliation_discrepancies
  set
    status = p_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_reason = btrim(p_reason)
  where id = p_discrepancy_id;

  if p_status = 'adjusted'
    and (v_discrepancy.metadata ? 'sale_user_id')
    and (v_discrepancy.metadata ? 'point_delta_cents') then
    insert into public.sale_point_adjustments (
      sale_user_id,
      point_delta_cents,
      reason,
      reviewed_by,
      idempotency_key,
      metadata
    )
    values (
      (v_discrepancy.metadata ->> 'sale_user_id')::uuid,
      (v_discrepancy.metadata ->> 'point_delta_cents')::integer,
      btrim(p_reason),
      auth.uid(),
      nullif(btrim(p_idempotency_key), ''),
      jsonb_build_object('reconciliation_discrepancy_id', p_discrepancy_id)
    )
    on conflict (idempotency_key) do update
    set metadata = public.sale_point_adjustments.metadata;
  end if;

  perform public.admin_write_audit(
    'admin_update_reconciliation_discrepancy_status',
    'admin_reconciliation_discrepancy',
    p_discrepancy_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object('status', p_status)
  );

  return query select true, 'Da cap nhat doi soat.';
end;
$$;

create or replace function public.admin_list_audit_events(
  p_query text default '',
  p_limit integer default 50
)
returns table (
  id text,
  action text,
  actor_id text,
  target text,
  reason text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('audit.read');

  return query
  select
    aae.id::text,
    aae.action,
    coalesce(aae.actor_id::text, ''),
    aae.target_type || ':' || aae.target_id,
    aae.reason,
    aae.created_at
  from public.admin_audit_events aae
  where coalesce(p_query, '') = ''
     or aae.action ilike '%' || p_query || '%'
     or aae.target_id ilike '%' || p_query || '%'
     or aae.reason ilike '%' || p_query || '%'
  order by aae.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

alter table public.admin_roles enable row level security;
alter table public.admin_permissions enable row level security;
alter table public.admin_role_permissions enable row level security;
alter table public.admin_user_roles enable row level security;
alter table public.admin_audit_events enable row level security;
alter table public.system_config_versions enable row level security;
alter table public.report_exports enable row level security;
alter table public.sale_point_adjustments enable row level security;
alter table public.admin_reconciliation_runs enable row level security;
alter table public.admin_reconciliation_discrepancies enable row level security;

drop policy if exists admin_roles_read_admin on public.admin_roles;
create policy admin_roles_read_admin
  on public.admin_roles for select to authenticated
  using (public.admin_has_permission('audit.read'));

drop policy if exists admin_permissions_read_admin on public.admin_permissions;
create policy admin_permissions_read_admin
  on public.admin_permissions for select to authenticated
  using (public.admin_has_permission('audit.read'));

drop policy if exists admin_role_permissions_read_admin on public.admin_role_permissions;
create policy admin_role_permissions_read_admin
  on public.admin_role_permissions for select to authenticated
  using (public.admin_has_permission('audit.read'));

drop policy if exists admin_user_roles_read_self_or_admin on public.admin_user_roles;
create policy admin_user_roles_read_self_or_admin
  on public.admin_user_roles for select to authenticated
  using (
    user_id = (select auth.uid())
    or public.admin_has_permission('audit.read')
  );

drop policy if exists admin_audit_events_read_admin on public.admin_audit_events;
create policy admin_audit_events_read_admin
  on public.admin_audit_events for select to authenticated
  using (public.admin_has_permission('audit.read'));

drop policy if exists system_config_versions_read_admin on public.system_config_versions;
create policy system_config_versions_read_admin
  on public.system_config_versions for select to authenticated
  using (public.admin_has_permission('config.write'));

drop policy if exists report_exports_read_admin on public.report_exports;
create policy report_exports_read_admin
  on public.report_exports for select to authenticated
  using (public.admin_has_permission('reports.write'));

drop policy if exists sale_point_adjustments_read_admin on public.sale_point_adjustments;
create policy sale_point_adjustments_read_admin
  on public.sale_point_adjustments for select to authenticated
  using (public.admin_has_permission('points.write'));

drop policy if exists admin_reconciliation_runs_read_admin
  on public.admin_reconciliation_runs;
create policy admin_reconciliation_runs_read_admin
  on public.admin_reconciliation_runs for select to authenticated
  using (public.admin_has_permission('reconciliation.write'));

drop policy if exists admin_reconciliation_discrepancies_read_admin
  on public.admin_reconciliation_discrepancies;
create policy admin_reconciliation_discrepancies_read_admin
  on public.admin_reconciliation_discrepancies for select to authenticated
  using (public.admin_has_permission('reconciliation.write'));

grant select on
  public.admin_roles,
  public.admin_permissions,
  public.admin_role_permissions,
  public.admin_user_roles,
  public.admin_audit_events,
  public.system_config_versions,
  public.report_exports,
  public.sale_point_adjustments,
  public.admin_reconciliation_runs,
  public.admin_reconciliation_discrepancies
to authenticated;

revoke insert, update, delete on
  public.admin_roles,
  public.admin_permissions,
  public.admin_role_permissions,
  public.admin_user_roles,
  public.admin_audit_events,
  public.system_config_versions,
  public.report_exports,
  public.sale_point_adjustments,
  public.admin_reconciliation_runs,
  public.admin_reconciliation_discrepancies
from anon, authenticated;

grant execute on function public.get_my_admin_session() to authenticated;
grant execute on function public.get_admin_dashboard_summary(timestamptz, timestamptz, text, text) to authenticated;
grant execute on function public.create_membership_payment_request(
  public.nb_membership_plan,
  text,
  text
) to authenticated;
grant execute on function public.admin_search_users(text, integer) to authenticated;
grant execute on function public.admin_update_user_status(uuid, text, text, text) to authenticated;
grant execute on function public.admin_list_payments(text, integer) to authenticated;
grant execute on function public.admin_review_payment(uuid, text, text, text) to authenticated;
grant execute on function public.admin_refund_or_cancel_payment(uuid, text, text, text) to authenticated;
grant execute on function public.admin_list_sales(text, integer) to authenticated;
grant execute on function public.admin_review_sale_profile(uuid, text, text, text) to authenticated;
grant execute on function public.admin_upsert_config_version(text, jsonb, text, text) to authenticated;
grant execute on function public.admin_list_config_versions(text, integer) to authenticated;
grant execute on function public.admin_list_plan_config_versions(text, integer) to authenticated;
grant execute on function public.admin_request_report_export(text, jsonb, text, text) to authenticated;
grant execute on function public.admin_list_report_exports(text, integer) to authenticated;
grant execute on function public.admin_adjust_sale_points(uuid, integer, text, text) to authenticated;
grant execute on function public.admin_create_reconciliation_run(text, text, text) to authenticated;
grant execute on function public.admin_list_reconciliation_discrepancies(text, integer) to authenticated;
grant execute on function public.admin_update_reconciliation_discrepancy_status(uuid, text, text, text) to authenticated;
grant execute on function public.admin_list_audit_events(text, integer) to authenticated;

revoke all on function public.record_trusted_payment_event(
  uuid,
  public.nb_membership_plan,
  text,
  text,
  integer,
  integer,
  integer,
  text,
  boolean,
  text,
  jsonb
) from public, anon, authenticated;

revoke all on function public.create_sale_point_reversal_for_payment(
  uuid,
  text,
  text,
  text
) from public, anon, authenticated;

commit;
