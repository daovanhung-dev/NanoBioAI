begin;

do $$
begin
  if to_regclass('public.sleep_safety_runtime_config') is null
    or to_regclass('public.sleep_safety_contacts') is null
    or to_regclass('public.sleep_safety_dispatches') is null then
    raise exception 'M31_SCHEMA_MISSING_APPLY_CANONICAL_SCHEMA_FIRST';
  end if;
end;
$$;

alter table public.sleep_safety_runtime_config
  add column if not exists zalo_enabled boolean not null default false,
  add column if not exists phone_fallback_enabled boolean not null default false;

alter table public.sleep_safety_contacts
  add column if not exists allow_zalo_alert boolean not null default false,
  add column if not exists allow_phone_fallback boolean not null default true;

alter table public.sleep_safety_dispatches
  drop constraint if exists sleep_safety_dispatches_channel_check;
alter table public.sleep_safety_dispatches
  add constraint sleep_safety_dispatches_channel_check
  check (channel in ('sms', 'voice', 'zalo'));

create or replace function public.upsert_sleep_safety_contact(
  p_contact_id uuid,
  p_name text,
  p_relationship text,
  p_phone_e164 text,
  p_priority integer,
  p_allow_zalo_alert boolean,
  p_allow_phone_fallback boolean
)
returns setof public.sleep_safety_contacts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := (select auth.uid());
  v_existing public.sleep_safety_contacts%rowtype;
begin
  if v_uid is null then
    raise exception 'authentication_required';
  end if;
  if p_priority not between 1 and 3 then
    raise exception 'sleep_safety_priority_invalid';
  end if;
  if p_phone_e164 !~ '^\\+[1-9][0-9]{7,14}$' then
    raise exception 'sleep_safety_phone_invalid';
  end if;

  if p_contact_id is null then
    if (
      select count(*)
      from public.sleep_safety_contacts c
      where c.user_id = v_uid and c.active = true
    ) >= 3 then
      raise exception 'sleep_safety_contact_limit';
    end if;

    return query
    insert into public.sleep_safety_contacts (
      user_id, name, relationship, phone_e164, priority,
      allow_zalo_alert, allow_phone_fallback
    ) values (
      v_uid, btrim(p_name), btrim(p_relationship), p_phone_e164, p_priority,
      coalesce(p_allow_zalo_alert, false), coalesce(p_allow_phone_fallback, true)
    )
    returning *;
    return;
  end if;

  select * into v_existing
  from public.sleep_safety_contacts c
  where c.id = p_contact_id and c.user_id = v_uid
  for update;

  if not found then
    raise exception 'sleep_safety_contact_not_found';
  end if;

  return query
  update public.sleep_safety_contacts c
  set name = btrim(p_name),
      relationship = btrim(p_relationship),
      phone_e164 = p_phone_e164,
      priority = p_priority,
      verification_status = case
        when c.phone_e164 is distinct from p_phone_e164 then 'pending'
        else c.verification_status
      end,
      verified_at = case
        when c.phone_e164 is distinct from p_phone_e164 then null
        else c.verified_at
      end,
      allow_zalo_alert = coalesce(p_allow_zalo_alert, false),
      allow_phone_fallback = coalesce(p_allow_phone_fallback, true),
      active = true,
      updated_at = now()
  where c.id = p_contact_id and c.user_id = v_uid
  returning c.*;
end;
$$;

revoke all on function public.upsert_sleep_safety_contact(
  uuid, text, text, text, integer, boolean, boolean
) from public, anon;

grant execute on function public.upsert_sleep_safety_contact(
  uuid, text, text, text, integer, boolean, boolean
) to authenticated, service_role;

commit;
