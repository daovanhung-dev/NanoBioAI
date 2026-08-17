-- Static/sandbox validation for 20260816_daily_health_hub_rewards.sql.
-- Run after setup.sql + this migration in a disposable Supabase sandbox.

select to_regclass('public.schedule_health_checkins') as schedule_health_checkins_table;

select
  public.schedule_health_action_reward_points('hydration') as hydration_points,
  public.schedule_health_action_reward_points('mood_stress') as mood_points,
  public.schedule_health_action_reward_points('sleep_checkin') as sleep_points,
  public.schedule_health_action_reward_points('weight_checkin') as weight_points,
  public.schedule_health_action_reward_points('quick_complete') as quick_points;

select proname
from pg_proc
where proname in (
  'finalize_my_schedule_health_checkin',
  'undo_my_schedule_health_checkin',
  'schedule_health_action_reward_points',
  'sync_my_mobile_snapshot',
  'sync_my_mobile_snapshot_before_daily_health_hub'
)
order by proname;

select grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name = 'schedule_health_checkins'
order by grantee, privilege_type;

select
  is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'schedule_health_checkins'
  and column_name = 'eligibility_id';

-- Expected:
-- - authenticated has SELECT only on schedule_health_checkins.
-- - eligibility_id is nullable so manual tasks never need generated eligibility.
-- - setup.sql JPEG proof constraints remain unchanged.
-- - base mobile sync is private; authenticated executes only the Daily Health
--   Hub wrapper.
--
-- Acceptance matrix with two disposable authenticated users:
-- 1. Generated water +250 => +4 and active check-in; snapshot sync preserves
--    completed state even though there is no JPEG proof.
-- 2. mood/stress => +5; sleep => +6; weight => +4; quick => +5 for matching
--    manual actions.
-- 3. meal/exercise => photo_proof_required and existing camera flow untouched.
-- 4. before/after 30-minute window => denied.
-- 5. manual task fifth active rewarded completion on one date =>
--    manual_reward_daily_limit; no schedule_reward_eligibility is created.
-- 6. stale snapshot omitting an active completed manual task => wrapper restores
--    the occurrence from immutable check-in snapshots.
-- 7. undo while allocation is pending => points reversed; second undo is
--    idempotent; snapshot overlay keeps the task incomplete.
-- 8. cross-user schedule item => denied/not found; direct INSERT/UPDATE/DELETE
--    on schedule_health_checkins remains rejected by RLS/privileges.
