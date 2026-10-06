begin;

do $$
begin
  if to_regclass('public.sleep_safety_contacts') is null then
    raise exception 'M31_SCHEMA_MISSING_APPLY_CANONICAL_SCHEMA_FIRST';
  end if;
  if to_regprocedure(
    'public.upsert_sleep_safety_contact(uuid,text,text,text,integer,boolean,boolean)'
  ) is null then
    raise exception 'M31_CONTACT_RPC_MISSING_APPLY_CANONICAL_SCHEMA_FIRST';
  end if;
end;
$$;

alter table public.sleep_safety_contacts
  add column if not exists allow_unverified_voice_alert boolean not null default false;

comment on column public.sleep_safety_contacts.allow_unverified_voice_alert is
  'Explicit opt-in for automated voice alerts while this contact number is unverified.';

-- Keep the legacy 5- and 7-argument RPCs intact. New clients use this overload.
create or replace function public.upsert_sleep_safety_contact(
  p_contact_id uuid,
  p_name text,
  p_relationship text,
  p_phone_e164 text,
  p_priority integer,
  p_allow_zalo_alert boolean,
  p_allow_phone_fallback boolean,
  p_allow_unverified_voice_alert boolean
)
returns setof public.sleep_safety_contacts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_contact public.sleep_safety_contacts%rowtype;
begin
  select * into v_contact
  from public.upsert_sleep_safety_contact(
    p_contact_id,
    p_name,
    p_relationship,
    p_phone_e164,
    p_priority,
    p_allow_zalo_alert,
    p_allow_phone_fallback
  );

  update public.sleep_safety_contacts c
  set allow_unverified_voice_alert = coalesce(
        p_allow_unverified_voice_alert,
        false
      ),
      updated_at = now()
  where c.id = v_contact.id
    and c.user_id = (select auth.uid())
  returning c.* into v_contact;

  return next v_contact;
end;
$$;

revoke all on function public.upsert_sleep_safety_contact(
  uuid, text, text, text, integer, boolean, boolean, boolean
) from public, anon;

grant execute on function public.upsert_sleep_safety_contact(
  uuid, text, text, text, integer, boolean, boolean, boolean
) to authenticated, service_role;

commit;
