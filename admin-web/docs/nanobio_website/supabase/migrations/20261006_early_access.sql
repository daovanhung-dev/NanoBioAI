-- NanoBio Early Access + Plus/VIP 30-day promotion
-- Safe-by-default: public clients cannot read/write this table directly.
-- Marketing name "VIP 1 tháng" maps to the existing internal Plus plan for 30 days.
create extension if not exists pgcrypto;

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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint early_access_phone_e164_ck check (phone_e164 ~ '^\+84(3|5|7|8|9)[0-9]{8}$'),
  constraint early_access_consent_ck check (privacy_consent = true),
  constraint early_access_plan_ck check (requested_plan = 'plus'),
  constraint early_access_vip_days_ck check (vip_duration_days = 30),
  constraint early_access_vip_status_ck check (vip_grant_status in ('pending_account_link','pending_activation','active','expired','cancelled'))
);

-- Make the migration idempotent for databases where the first Early Access version already exists.
alter table public.early_access_leads add column if not exists promotion_code text not null default 'EARLY_ACCESS_PLUS_30D';
alter table public.early_access_leads add column if not exists requested_plan text not null default 'plus';
alter table public.early_access_leads add column if not exists vip_duration_days integer not null default 30;
alter table public.early_access_leads add column if not exists vip_grant_status text not null default 'pending_account_link';
alter table public.early_access_leads add column if not exists claimed_user_id uuid null references auth.users(id) on delete set null;
alter table public.early_access_leads add column if not exists vip_granted_at timestamptz null;
alter table public.early_access_leads add column if not exists vip_expires_at timestamptz null;

create index if not exists early_access_vip_grant_status_idx on public.early_access_leads(vip_grant_status, created_at desc);

alter table public.early_access_leads enable row level security;
revoke all on table public.early_access_leads from anon, authenticated;

create or replace function public.set_early_access_updated_at()
returns trigger language plpgsql security invoker as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_early_access_updated_at on public.early_access_leads;
create trigger trg_early_access_updated_at
before update on public.early_access_leads
for each row execute function public.set_early_access_updated_at();

-- Private storage bucket for signed APK links.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('early-access-apk', 'early-access-apk', false, 314572800, array['application/vnd.android.package-archive','application/octet-stream'])
on conflict (id) do update set public = false;

-- No public object policies are created. Edge Function uses service role to sign URLs.
-- IMPORTANT: this website only records the 30-day Plus/VIP promotion request.
-- Actual entitlement activation must be linked to a trusted NanoBio user account
-- through the existing Admin/trusted membership flow; never grant paid access from the browser.
