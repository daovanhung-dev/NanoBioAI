-- Runtime-only Supabase resources that must exist independently from fixtures.
-- Run after 01 through 05. This file is idempotent and safe to re-run on a
-- local/sandbox database, but the complete numbered bundle remains destructive.

begin;

-- These buckets are application infrastructure, not sample data. Keeping them
-- outside the seed prevents a production-like schema deployment from missing
-- the Storage targets used by the authenticated app.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'schedule-completion-proofs',
    'schedule-completion-proofs',
    false,
    5242880,
    array['image/jpeg']::text[]
  ),
  (
    'sale-payout-proofs',
    'sale-payout-proofs',
    false,
    5242880,
    array['image/jpeg']::text[]
  )
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- The schema rebuild creates these RPCs in 01 through 04. This manifest keeps
-- the app-facing API explicit and fails the rebuild before a missing function
-- becomes a vague Flutter/PostgREST runtime error. The loop also restores the
-- explicit authenticated grant if a sandbox has had function privileges reset.
do $$
declare
  v_function_name text;
  v_function_oid oid;
begin
  foreach v_function_name in array array[
    'admin_adjust_sale_points',
    'admin_cancel_reward_redemption',
    'admin_create_reconciliation_run',
    'admin_get_payment_review_alert',
    'admin_import_reward_codes',
    'admin_list_audit_events',
    'admin_list_config_versions',
    'admin_list_payments',
    'admin_list_plan_config_versions',
    'admin_list_reconciliation_discrepancies',
    'admin_list_report_catalog',
    'admin_list_sale_point_conversions',
    'admin_list_sales',
    'admin_list_wellness_rewards',
    'admin_refund_or_cancel_payment',
    'admin_request_report_export',
    'admin_review_payment',
    'admin_review_sale_point_conversion',
    'admin_review_sale_profile',
    'admin_search_users',
    'admin_update_reconciliation_discrepancy_status',
    'admin_update_user_status',
    'admin_upsert_config_version',
    'admin_upsert_reward_offer',
    'attach_my_referral_code',
    'begin_my_schedule_completion',
    'cancel_my_membership_payment_request',
    'check_personal_schedule_generation_quota',
    'check_usage_quota',
    'commit_personal_schedule_generation_quota',
    'commit_usage_quota',
    'confirm_my_membership_payment_transfer',
    'create_membership_payment_request',
    'finalize_my_schedule_completion',
    'finalize_my_schedule_health_checkin',
    'get_admin_dashboard_summary',
    'get_my_admin_session',
    'get_my_familyplus_context',
    'get_my_membership_payment_request',
    'get_my_reward_code',
    'get_my_sale_conversions',
    'get_my_sale_dashboard',
    'get_my_sale_direct_customers',
    'get_my_sale_payout_profile',
    'get_my_sale_point_ledger',
    'get_my_sale_state',
    'get_my_wellness_reward_summary',
    'list_my_reward_offers',
    'list_my_reward_redemptions',
    'list_my_wellness_point_history',
    'redeem_my_reward_offer',
    'register_my_schedule_reward_eligibilities',
    'remove_my_familyplus_member',
    'request_sale_participation',
    'request_sale_point_conversion',
    'sync_my_mobile_snapshot',
    'undo_my_schedule_completion',
    'undo_my_schedule_health_checkin',
    'upsert_my_familyplus_group',
    'upsert_my_familyplus_member',
    'upsert_my_sale_payout_profile'
  ] loop
    select p.oid
    into v_function_oid
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = v_function_name
    order by p.oid
    limit 1;

    if v_function_oid is null then
      raise exception 'RUNTIME_RPC_MISSING_%', v_function_name;
    end if;

    execute format(
      'grant execute on function public.%I(%s) to authenticated',
      v_function_name,
      pg_get_function_identity_arguments(v_function_oid)
    );
  end loop;
end;
$$;

commit;
