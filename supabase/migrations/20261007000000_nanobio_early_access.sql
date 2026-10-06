-- NanoBio Website Early Access lead capture and durable IP rate limiting.
-- Additive forward migration; do not run the canonical destructive rebuild remotely.
begin;

create extension if not exists pgcrypto;
create extension if not exists pg_cron;
create schema if not exists early_access_private;
revoke all on schema early_access_private from public, anon, authenticated, service_role;

create table if not exists public.early_access_leads (
  id uuid primary key default gen_random_uuid(),
  phone_e164 text not null unique,
  phone_display text,
  source text not null default 'nanobio_web',
  app_version text,
  vip_support_requested boolean not null default true,
  privacy_consent boolean not null default false,
  promotion_code text not null default 'EARLY_ACCESS_PLUS_30D',
  requested_plan text not null default 'plus',
  vip_duration_days integer not null default 30,
  vip_grant_status text not null default 'pending_account_link',
  claimed_user_id uuid null references auth.users(id) on delete set null,
  vip_granted_at timestamptz null,
  vip_expires_at timestamptz null,
  full_name text null,
  status text not null default 'new',
  utm_source text null,
  utm_medium text null,
  utm_campaign text null,
  referrer text null,
  landing_path text not null default '/nanobio',
  user_agent text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint early_access_phone_e164_ck check (phone_e164 ~ '^\+84(3|5|7|8|9)[0-9]{8}$'),
  constraint early_access_consent_ck check (privacy_consent = true),
  constraint early_access_plan_ck check (requested_plan = 'plus'),
  constraint early_access_vip_days_ck check (vip_duration_days = 30),
  constraint early_access_vip_status_ck check (vip_grant_status in ('pending_account_link','pending_activation','active','expired','cancelled')),
  constraint early_access_lead_status_ck check (status in ('new','contacted','registered','converted','rejected')),
  constraint early_access_full_name_length_ck check (full_name is null or char_length(full_name) <= 120),
  constraint early_access_utm_source_length_ck check (utm_source is null or char_length(utm_source) <= 100),
  constraint early_access_utm_medium_length_ck check (utm_medium is null or char_length(utm_medium) <= 100),
  constraint early_access_utm_campaign_length_ck check (utm_campaign is null or char_length(utm_campaign) <= 100),
  constraint early_access_referrer_length_ck check (referrer is null or char_length(referrer) <= 512),
  constraint early_access_landing_path_ck check (landing_path in ('/nanobio','/nanobio/privacy')),
  constraint early_access_user_agent_length_ck check (user_agent is null or char_length(user_agent) <= 512)
);

alter table public.early_access_leads add column if not exists full_name text null;
alter table public.early_access_leads add column if not exists status text not null default 'new';
alter table public.early_access_leads add column if not exists utm_source text null;
alter table public.early_access_leads add column if not exists utm_medium text null;
alter table public.early_access_leads add column if not exists utm_campaign text null;
alter table public.early_access_leads add column if not exists referrer text null;
alter table public.early_access_leads add column if not exists landing_path text not null default '/nanobio';
alter table public.early_access_leads add column if not exists user_agent text null;

do $$
begin
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_lead_status_ck') then
    alter table public.early_access_leads add constraint early_access_lead_status_ck check (status in ('new','contacted','registered','converted','rejected'));
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_full_name_length_ck') then
    alter table public.early_access_leads add constraint early_access_full_name_length_ck check (full_name is null or char_length(full_name) <= 120);
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_utm_source_length_ck') then
    alter table public.early_access_leads add constraint early_access_utm_source_length_ck check (utm_source is null or char_length(utm_source) <= 100);
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_utm_medium_length_ck') then
    alter table public.early_access_leads add constraint early_access_utm_medium_length_ck check (utm_medium is null or char_length(utm_medium) <= 100);
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_utm_campaign_length_ck') then
    alter table public.early_access_leads add constraint early_access_utm_campaign_length_ck check (utm_campaign is null or char_length(utm_campaign) <= 100);
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_referrer_length_ck') then
    alter table public.early_access_leads add constraint early_access_referrer_length_ck check (referrer is null or char_length(referrer) <= 512);
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_landing_path_ck') then
    alter table public.early_access_leads add constraint early_access_landing_path_ck check (landing_path in ('/nanobio','/nanobio/privacy'));
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_user_agent_length_ck') then
    alter table public.early_access_leads add constraint early_access_user_agent_length_ck check (user_agent is null or char_length(user_agent) <= 512);
  end if;
end
$$;

create index if not exists early_access_vip_grant_status_idx
  on public.early_access_leads(vip_grant_status, created_at desc);
create index if not exists early_access_lead_status_created_idx
  on public.early_access_leads(status, created_at desc);

alter table public.early_access_leads enable row level security;
revoke all on table public.early_access_leads from public, anon, authenticated;
grant select, insert, update on table public.early_access_leads to service_role;

create or replace function public.set_early_access_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
revoke all on function public.set_early_access_updated_at() from public, anon, authenticated, service_role;
drop trigger if exists trg_early_access_updated_at on public.early_access_leads;
create trigger trg_early_access_updated_at
  before update on public.early_access_leads
  for each row execute function public.set_early_access_updated_at();

create table if not exists early_access_private.rate_limits (
  ip_hash text not null check (ip_hash ~ '^[0-9a-f]{64}$'),
  window_started_at timestamptz not null,
  request_count integer not null check (request_count between 1 and 10),
  expires_at timestamptz not null,
  primary key (ip_hash, window_started_at)
);
alter table early_access_private.rate_limits enable row level security;
revoke all on table early_access_private.rate_limits from public, anon, authenticated, service_role;

create or replace function public.consume_early_access_rate_limit(
  p_ip_hash text,
  p_window_started_at timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_request_count integer;
begin
  if p_ip_hash is null or p_ip_hash !~ '^[0-9a-f]{64}$'
     or p_window_started_at is null
     or mod(extract(epoch from p_window_started_at)::bigint, 3600) <> 0 then
    raise exception 'INVALID_EARLY_ACCESS_RATE_LIMIT_KEY' using errcode = '22023';
  end if;

  insert into early_access_private.rate_limits as rate_limits (
    ip_hash, window_started_at, request_count, expires_at
  ) values (
    p_ip_hash, p_window_started_at, 1, p_window_started_at + interval '23 hours 55 minutes'
  )
  on conflict (ip_hash, window_started_at) do update
    set request_count = rate_limits.request_count + 1,
        expires_at = excluded.expires_at
    where rate_limits.request_count < 10
  returning request_count into v_request_count;

  return v_request_count is not null;
end;
$$;
revoke all on function public.consume_early_access_rate_limit(text, timestamptz) from public, anon, authenticated;
grant execute on function public.consume_early_access_rate_limit(text, timestamptz) to service_role;

create or replace function public.purge_early_access_rate_limits()
returns integer
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_deleted integer;
begin
  delete from early_access_private.rate_limits where expires_at <= now();
  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;
revoke all on function public.purge_early_access_rate_limits() from public, anon, authenticated, service_role;

do $cron$
declare
  v_job_id bigint;
begin
  for v_job_id in
    select jobid from cron.job where jobname = 'nanobio-purge-early-access-rate-limits'
  loop
    perform cron.unschedule(v_job_id);
  end loop;
  perform cron.schedule(
    'nanobio-purge-early-access-rate-limits',
    '*/5 * * * *',
    'select public.purge_early_access_rate_limits();'
  );
end
$cron$;

commit;
