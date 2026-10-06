-- NanoBio Early Access customer profile, status administration, and retention.
-- Forward-only additive migration; never run the canonical sandbox rebuild remotely.
begin;

alter table public.early_access_leads
  add column if not exists phone_hash text null,
  add column if not exists age smallint null,
  add column if not exists gender text null,
  add column if not exists address text null;

do $$
begin
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_phone_hash_ck') then
    alter table public.early_access_leads add constraint early_access_phone_hash_ck check (phone_hash is null or phone_hash ~ '^[0-9a-f]{64}$');
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_age_ck') then
    alter table public.early_access_leads add constraint early_access_age_ck check (age is null or age between 18 and 120);
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_gender_ck') then
    alter table public.early_access_leads add constraint early_access_gender_ck check (gender is null or gender in ('male','female','other','prefer_not_to_say'));
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.early_access_leads'::regclass and conname = 'early_access_address_length_ck') then
    alter table public.early_access_leads add constraint early_access_address_length_ck check (address is null or char_length(address) <= 512);
  end if;
end
$$;

create index if not exists early_access_lead_retention_idx
  on public.early_access_leads(status, created_at)
  where status in ('registered','converted','rejected');

create table if not exists early_access_private.promo_phone_suppressions (
  phone_hash text primary key check (phone_hash ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now()
);
alter table early_access_private.promo_phone_suppressions enable row level security;
revoke all on table early_access_private.promo_phone_suppressions from public, anon, authenticated, service_role;

create or replace function public.save_early_access_lead(p_lead jsonb)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, early_access_private
as $$
declare
  v_phone text := p_lead ->> 'phone_e164';
  v_phone_hash text := p_lead ->> 'phone_hash';
  v_inserted integer;
begin
  if jsonb_typeof(p_lead) <> 'object'
     or v_phone is null or v_phone !~ '^\+84(3|5|7|8|9)[0-9]{8}$'
     or v_phone_hash is null or v_phone_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'INVALID_EARLY_ACCESS_LEAD' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_phone_hash, 0));
  if exists (
    select 1 from early_access_private.promo_phone_suppressions
    where phone_hash = v_phone_hash
  ) then
    return false;
  end if;

  insert into public.early_access_leads (
    phone_e164, phone_display, source, app_version, vip_support_requested,
    privacy_consent, promotion_code, requested_plan, vip_duration_days,
    vip_grant_status, phone_hash, full_name, age, gender, address, status,
    utm_source, utm_medium, utm_campaign, referrer, landing_path, user_agent
  ) values (
    v_phone, p_lead ->> 'phone_display', 'nanobio_web', p_lead ->> 'app_version',
    true, true, 'EARLY_ACCESS_PLUS_30D', 'plus', 30, 'pending_account_link',
    v_phone_hash, p_lead ->> 'full_name', (p_lead ->> 'age')::smallint,
    p_lead ->> 'gender', p_lead ->> 'address', 'new',
    p_lead ->> 'utm_source', p_lead ->> 'utm_medium', p_lead ->> 'utm_campaign',
    p_lead ->> 'referrer', coalesce(p_lead ->> 'landing_path', '/nanobio'),
    p_lead ->> 'user_agent'
  ) on conflict (phone_e164) do nothing;
  get diagnostics v_inserted = row_count;
  return v_inserted = 1;
end;
$$;
revoke all on function public.save_early_access_lead(jsonb) from public, anon, authenticated;
grant execute on function public.save_early_access_lead(jsonb) to service_role;

create or replace function public.admin_update_early_access_lead_status(
  p_lead_id uuid,
  p_status text,
  p_actor_id uuid,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_old_status text;
  v_existing_target text;
begin
  if p_status not in ('new','contacted','registered','converted','rejected')
     or p_reason is null or char_length(btrim(p_reason)) < 5 or char_length(p_reason) > 300
     or p_idempotency_key is null or char_length(p_idempotency_key) < 8
     or char_length(p_idempotency_key) > 120 then
    raise exception 'INVALID_EARLY_ACCESS_STATUS_UPDATE' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.users u
    where u.id = p_actor_id and u.admin_status = 'active'
  ) or not exists (
    select 1
    from public.admin_user_roles aur
    join public.admin_roles ar on ar.code = aur.role_code and ar.is_active = true
    where aur.user_id = p_actor_id
      and aur.role_code in ('super_admin','support_admin','operations_admin')
      and aur.is_active = true and aur.revoked_at is null
  ) then
    raise exception 'EARLY_ACCESS_ADMIN_ROLE_REQUIRED' using errcode = '42501';
  end if;

  select target_id into v_existing_target
  from public.admin_audit_events
  where action = 'early_access_lead_status_updated'
    and idempotency_key = p_idempotency_key;
  if found then
    if v_existing_target <> p_lead_id::text then
      raise exception 'EARLY_ACCESS_IDEMPOTENCY_CONFLICT' using errcode = '23505';
    end if;
    return jsonb_build_object('success', true, 'message', 'Đã xử lý thao tác trước đó.');
  end if;

  select status into v_old_status
  from public.early_access_leads
  where id = p_lead_id
  for update;
  if not found then
    raise exception 'EARLY_ACCESS_LEAD_NOT_FOUND' using errcode = 'P0002';
  end if;

  update public.early_access_leads set status = p_status where id = p_lead_id;
  insert into public.admin_audit_events (
    actor_id, action, target_type, target_id, reason, idempotency_key, metadata
  ) values (
    p_actor_id, 'early_access_lead_status_updated', 'early_access_lead',
    p_lead_id::text, btrim(p_reason), p_idempotency_key,
    jsonb_build_object('from_status', v_old_status, 'to_status', p_status)
  );
  return jsonb_build_object('success', true, 'message', 'Đã cập nhật trạng thái hồ sơ.');
end;
$$;
revoke all on function public.admin_update_early_access_lead_status(uuid,text,uuid,text,text) from public, anon, authenticated;
grant execute on function public.admin_update_early_access_lead_status(uuid,text,uuid,text,text) to service_role;

create or replace function public.purge_early_access_closed_leads()
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, early_access_private
as $$
declare
  v_candidate record;
  v_deleted integer := 0;
  v_row_count integer;
begin
  for v_candidate in
    select id, phone_hash
    from public.early_access_leads
    where created_at < now() - interval '12 months'
      and status in ('registered','converted','rejected')
  loop
    if v_candidate.phone_hash is not null then
      perform pg_advisory_xact_lock(hashtextextended(v_candidate.phone_hash, 0));
      insert into early_access_private.promo_phone_suppressions(phone_hash)
      values (v_candidate.phone_hash)
      on conflict (phone_hash) do nothing;
    end if;
    delete from public.early_access_leads
    where id = v_candidate.id
      and created_at < now() - interval '12 months'
      and status in ('registered','converted','rejected');
    get diagnostics v_row_count = row_count;
    v_deleted := v_deleted + v_row_count;
  end loop;
  return v_deleted;
end;
$$;
revoke all on function public.purge_early_access_closed_leads() from public, anon, authenticated, service_role;

do $cron$
declare
  v_job_id bigint;
begin
  for v_job_id in
    select jobid from cron.job where jobname = 'nanobio-purge-closed-early-access-leads'
  loop
    perform cron.unschedule(v_job_id);
  end loop;
  perform cron.schedule(
    'nanobio-purge-closed-early-access-leads',
    '17 3 * * *',
    'select public.purge_early_access_closed_leads();'
  );
end
$cron$;

insert into public.admin_permissions(code, description)
values
  ('early_access.read', 'Xem hồ sơ đăng ký NanoBio Early Access.'),
  ('early_access.update', 'Cập nhật trạng thái hồ sơ NanoBio Early Access.')
on conflict (code) do update set description = excluded.description, is_active = true;

insert into public.admin_role_permissions(role_code, permission_code)
values
  ('super_admin', 'early_access.read'),
  ('super_admin', 'early_access.update'),
  ('support_admin', 'early_access.read'),
  ('support_admin', 'early_access.update'),
  ('operations_admin', 'early_access.read'),
  ('operations_admin', 'early_access.update')
on conflict (role_code, permission_code) do nothing;

commit;
