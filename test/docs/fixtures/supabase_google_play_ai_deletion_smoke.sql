-- Google Play / AI backend / deletion sandbox smoke.
-- Run only after the canonical two-script rebuild on a disposable sandbox.
-- This script deliberately rolls back all mutations.
begin;

do $$
begin
  if to_regclass('public.google_play_purchase_ledger') is null then
    raise exception 'NB_P0_PLAY_LEDGER_MISSING';
  end if;
  if to_regclass('public.ai_content_reports') is null then
    raise exception 'NB_P0_AI_REPORTS_MISSING';
  end if;
  if to_regprocedure('public.finalize_google_play_purchase(uuid,text,text,text,text,text,timestamptz,timestamptz,boolean)') is null then
    raise exception 'NB_P0_PLAY_FINALIZE_RPC_MISSING';
  end if;
  if to_regprocedure('public.anonymize_deleted_user_records()') is null then
    raise exception 'NB_P1_DELETION_TRIGGER_MISSING';
  end if;
end;
$$;

do $$
declare
  v_rls boolean;
  v_policy_count integer;
  v_grant_count integer;
begin
  select c.relrowsecurity into v_rls
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'google_play_purchase_ledger';
  if coalesce(v_rls, false) is not true then
    raise exception 'NB_P1_PLAY_LEDGER_RLS_DISABLED';
  end if;

  select count(*) into v_policy_count
  from pg_policies
  where schemaname = 'public' and tablename = 'ai_content_reports';
  if v_policy_count <> 0 then
    raise exception 'NB_P0_AI_REPORTS_CLIENT_POLICY_PRESENT';
  end if;

  select count(*) into v_grant_count
  from information_schema.role_table_grants
  where table_schema = 'public'
    and table_name = 'google_play_purchase_ledger'
    and grantee in ('anon', 'authenticated')
    and privilege_type in ('INSERT', 'UPDATE', 'DELETE');
  if v_grant_count <> 0 then
    raise exception 'NB_P0_PLAY_LEDGER_CLIENT_WRITE_ALLOWED';
  end if;
end;
$$;

-- Runtime purchase replay, RLS cross-user read, guest report rate-limit and
-- actual auth deletion must be completed in two independent SQL/HTTP sessions.
-- Keep those results in .codex/history/OPEN_RISKS.md.

rollback;
