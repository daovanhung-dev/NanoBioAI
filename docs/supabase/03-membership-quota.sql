-- Commit de xuat: docs(supabase): tao membership quota schema
-- NanoBio / BioAI - membership entitlement and usage quota draft.
-- Run after 01-core-auth-profile.sql.

begin;

create table if not exists public.membership_plans (
  code public.nb_membership_plan primary key,
  display_name text not null,
  access_version text not null check (access_version in ('v2', 'v3')),
  sort_order integer not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.plan_entitlements (
  id uuid primary key default gen_random_uuid(),
  plan_code public.nb_membership_plan not null references public.membership_plans(code) on delete cascade,
  entitlement_key text not null,
  entitlement_value jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (plan_code, entitlement_key)
);

create table if not exists public.membership_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  plan_code public.nb_membership_plan not null references public.membership_plans(code),
  status text not null default 'active'
    check (status in ('trialing', 'active', 'past_due', 'canceled', 'expired')),
  source text not null default 'manual'
    check (source in ('manual', 'payment_provider', 'promotion', 'migration')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  current_period_start timestamptz,
  current_period_end timestamptz,
  provider text,
  provider_subscription_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint membership_subscription_period_valid
    check (ends_at is null or ends_at > starts_at)
);

create index if not exists idx_membership_subscriptions_user_status
  on public.membership_subscriptions (user_id, status, starts_at desc);

create unique index if not exists idx_membership_subscriptions_provider_id
  on public.membership_subscriptions (provider, provider_subscription_id)
  where provider is not null and provider_subscription_id is not null;

create table if not exists public.usage_quota_rules (
  id uuid primary key default gen_random_uuid(),
  plan_code public.nb_membership_plan not null references public.membership_plans(code) on delete cascade,
  feature_key text not null,
  period_unit text not null check (period_unit in ('day', 'month', 'lifetime', 'none')),
  max_count integer,
  reset_timezone text not null default 'Asia/Saigon',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint usage_quota_rule_limit_valid
    check (
      (period_unit = 'none' and max_count is null)
      or (period_unit <> 'none' and max_count is not null and max_count >= 0)
    ),
  unique (plan_code, feature_key, period_unit)
);

create table if not exists public.usage_quota_counters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  feature_key text not null,
  period_key text not null,
  plan_code public.nb_membership_plan not null,
  used_count integer not null default 0 check (used_count >= 0),
  limit_count integer,
  reset_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, feature_key, period_key)
);

create table if not exists public.usage_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  feature_key text not null,
  period_key text not null,
  count_delta integer not null default 1,
  idempotency_key text,
  event_source text not null default 'trusted_backend'
    check (event_source in ('trusted_backend', 'edge_function', 'sql_job', 'admin')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, feature_key, idempotency_key)
);

create index if not exists idx_usage_events_user_feature_created
  on public.usage_events (user_id, feature_key, created_at desc);

create or replace function public.current_plan_for_user(p_user_id uuid)
returns public.nb_membership_plan
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select ms.plan_code
      from public.membership_subscriptions ms
      where ms.user_id = p_user_id
        and ms.status in ('trialing', 'active')
        and ms.starts_at <= now()
        and (ms.ends_at is null or ms.ends_at > now())
      order by
        case ms.plan_code
          when 'family_plus' then 3
          when 'plus' then 2
          else 1
        end desc,
        ms.starts_at desc
      limit 1
    ),
    'free'::public.nb_membership_plan
  )
$$;

create or replace function public.sync_user_subscription_tier()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_plan public.nb_membership_plan;
begin
  if TG_OP = 'DELETE' then
    v_user_id := old.user_id;
  else
    v_user_id := new.user_id;
  end if;

  v_plan := public.current_plan_for_user(v_user_id);

  update public.users
  set
    subscription_tier = v_plan,
    product_access_status = case
      when product_access_status = 'guest' and is_anonymous then product_access_status
      else v_plan::text::public.nb_product_access_status
    end,
    updated_at = now()
  where id = v_user_id;

  if TG_OP = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_membership_subscriptions_sync_user on public.membership_subscriptions;
create trigger trg_membership_subscriptions_sync_user
  after insert or update or delete on public.membership_subscriptions
  for each row execute function public.sync_user_subscription_tier();

create or replace view public.effective_user_access
with (security_invoker = true)
as
select
  u.id as user_id,
  u.is_anonymous,
  case
    when u.is_anonymous and u.product_access_status = 'guest' then 'guest'
    else public.current_plan_for_user(u.id)::text
  end as product_access,
  public.current_plan_for_user(u.id) as membership_plan,
  u.sale_status,
  u.onboarding_status,
  u.updated_at
from public.users u;

create or replace function public.can_consume_quota(
  p_user_id uuid,
  p_feature_key text,
  p_period_key text,
  p_count integer default 1
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with plan as (
    select public.current_plan_for_user(p_user_id) as plan_code
  ),
  rule as (
    select r.max_count
    from public.usage_quota_rules r
    join plan p on p.plan_code = r.plan_code
    where r.feature_key = p_feature_key
      and r.is_active = true
    order by
      case r.period_unit
        when 'none' then 0
        when 'day' then 1
        when 'month' then 2
        else 3
      end
    limit 1
  ),
  counter as (
    select used_count
    from public.usage_quota_counters
    where user_id = p_user_id
      and feature_key = p_feature_key
      and period_key = p_period_key
  )
  select case
    when not exists (select 1 from rule) then true
    when (select max_count from rule) is null then true
    else coalesce((select used_count from counter), 0) + p_count <= (select max_count from rule)
  end
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'membership_plans',
    'plan_entitlements',
    'membership_subscriptions',
    'usage_quota_rules',
    'usage_quota_counters'
  ]
  loop
    execute format('drop trigger if exists %I on public.%I', 'trg_' || table_name || '_updated_at', table_name);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
      'trg_' || table_name || '_updated_at',
      table_name
    );
  end loop;
end;
$$;

alter table public.membership_plans enable row level security;
alter table public.plan_entitlements enable row level security;
alter table public.membership_subscriptions enable row level security;
alter table public.usage_quota_rules enable row level security;
alter table public.usage_quota_counters enable row level security;
alter table public.usage_events enable row level security;

drop policy if exists membership_plans_read_authenticated on public.membership_plans;
drop policy if exists plan_entitlements_read_authenticated on public.plan_entitlements;
drop policy if exists usage_quota_rules_read_authenticated on public.usage_quota_rules;

create policy membership_plans_read_authenticated
  on public.membership_plans for select to authenticated
  using (is_active = true);

create policy plan_entitlements_read_authenticated
  on public.plan_entitlements for select to authenticated
  using (is_active = true);

create policy usage_quota_rules_read_authenticated
  on public.usage_quota_rules for select to authenticated
  using (is_active = true);

drop policy if exists membership_subscriptions_select_own on public.membership_subscriptions;
create policy membership_subscriptions_select_own
  on public.membership_subscriptions for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists usage_quota_counters_select_own on public.usage_quota_counters;
create policy usage_quota_counters_select_own
  on public.usage_quota_counters for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists usage_events_select_own on public.usage_events;
create policy usage_events_select_own
  on public.usage_events for select to authenticated
  using (user_id = (select auth.uid()));

grant select on
  public.membership_plans,
  public.plan_entitlements,
  public.membership_subscriptions,
  public.usage_quota_rules,
  public.usage_quota_counters,
  public.usage_events,
  public.effective_user_access
to authenticated;

revoke insert, update, delete on
  public.membership_plans,
  public.plan_entitlements,
  public.membership_subscriptions,
  public.usage_quota_rules,
  public.usage_quota_counters,
  public.usage_events
from anon, authenticated;

commit;
