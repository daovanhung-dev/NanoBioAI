begin;

-- PostgreSQL treats backslashes literally in standard-conforming strings. The
-- earlier `\\+` expression therefore rejected valid E.164 phone numbers.
-- Replace the table constraint with an escape-free literal-plus character set.
alter table public.sleep_safety_contacts
  drop constraint if exists sleep_safety_contacts_phone_e164_check;
alter table public.sleep_safety_contacts
  add constraint sleep_safety_contacts_phone_e164_check
  check (phone_e164 ~ '^[+][1-9][0-9]{7,14}$');

-- Patch both supported RPC signatures while preserving their existing logic,
-- owner and grants. Fail closed if either function has drifted from the known
-- faulty pattern instead of silently rewriting an unexpected definition.
do $fix_phone_regex$
declare
  v_oid oid;
  v_definition text;
  v_old_pattern text := $old$'^\\+[1-9][0-9]{7,14}$'$old$;
  v_new_pattern text := $new$'^[+][1-9][0-9]{7,14}$'$new$;
begin
  foreach v_oid in array array[
    'public.upsert_sleep_safety_contact(uuid,text,text,text,integer)'::regprocedure::oid,
    'public.upsert_sleep_safety_contact(uuid,text,text,text,integer,boolean,boolean)'::regprocedure::oid
  ] loop
    v_definition := pg_get_functiondef(v_oid);
    if strpos(v_definition, v_old_pattern) = 0 then
      raise exception 'sleep_safety_contact_phone_regex_drift_%',
        v_oid::regprocedure;
    end if;
    execute replace(v_definition, v_old_pattern, v_new_pattern);
  end loop;
end;
$fix_phone_regex$;

commit;
