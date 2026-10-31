begin;

do $$
begin
  if to_regclass('public.sleep_safety_runtime_config') is null
    or to_regclass('public.sleep_safety_contacts') is null
    or to_regclass('public.sleep_safety_dispatches') is null then
    raise exception 'M31_SCHEMA_MISSING_APPLY_CANONICAL_SCHEMA_FIRST';
  end if;

  -- Preserve any historical dispatch records instead of rewriting or deleting
  -- them. This migration can tighten the channel constraint when no legacy
  -- Zalo rows remain in the target project.
  if exists (
    select 1 from public.sleep_safety_dispatches where channel = 'zalo'
  ) then
    raise exception 'M31_LEGACY_ZALO_DISPATCH_ROWS_REQUIRE_REVIEW';
  end if;
end;
$$;

alter table public.sleep_safety_runtime_config
  drop column if exists zalo_enabled;

alter table public.sleep_safety_contacts
  drop column if exists allow_zalo_alert;

alter table public.sleep_safety_dispatches
  drop constraint if exists sleep_safety_dispatches_channel_check;
alter table public.sleep_safety_dispatches
  add constraint sleep_safety_dispatches_channel_check
  check (channel in ('sms', 'voice'));

-- Remove the deployed Zalo RPC overloads and expose only the current contact
-- options. The original five-argument RPC remains for older app versions.
drop function if exists public.upsert_sleep_safety_contact(
  uuid, text, text, text, integer, boolean, boolean, boolean
);
drop function if exists public.upsert_sleep_safety_contact(
  uuid, text, text, text, integer, boolean, boolean
);

create function public.upsert_sleep_safety_contact(
  p_contact_id uuid,
  p_name text,
  p_relationship text,
  p_phone_e164 text,
  p_priority integer,
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
    p_priority
  );

  update public.sleep_safety_contacts c
  set allow_phone_fallback = coalesce(p_allow_phone_fallback, true),
      allow_unverified_voice_alert = coalesce(
        p_allow_unverified_voice_alert,
        false
      ),
      active = true,
      updated_at = now()
  where c.id = v_contact.id
    and c.user_id = (select auth.uid())
  returning c.* into v_contact;

  return next v_contact;
end;
$$;

revoke all on function public.upsert_sleep_safety_contact(
  uuid, text, text, text, integer, boolean, boolean
) from public, anon;
grant execute on function public.upsert_sleep_safety_contact(
  uuid, text, text, text, integer, boolean, boolean
) to authenticated, service_role;

commit;
