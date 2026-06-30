-- Commit de xuat: docs(supabase): seed du lieu tham chieu
-- NanoBio / BioAI - reference seed for plans, entitlements, quota and commission.
-- Run after 03-membership-quota.sql and 05-sale-referral-commission.sql.

begin;

insert into public.membership_plans (code, display_name, access_version, sort_order, is_active)
values
  ('free', 'Free', 'v2', 10, true),
  ('plus', 'Plus', 'v3', 20, true),
  ('family_plus', 'FamilyPlus', 'v3', 30, true)
on conflict (code) do update
set
  display_name = excluded.display_name,
  access_version = excluded.access_version,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.plan_entitlements (plan_code, entitlement_key, entitlement_value, is_active)
values
  ('free', 'ai_chat', '{"enabled": true, "quota_key": "ai_chat_message"}'::jsonb, true),
  ('free', 'personal_schedule_generation', '{"enabled": true, "quota_key": "personal_schedule_generation"}'::jsonb, true),
  ('free', 'health_score', '{"enabled": true, "basis": "ai_schedule_completion_history"}'::jsonb, true),
  ('plus', 'ai_chat', '{"enabled": true, "unlimited": true}'::jsonb, true),
  ('plus', 'personal_schedule_generation', '{"enabled": true, "unlimited": true}'::jsonb, true),
  ('plus', 'goal_roadmap', '{"enabled": true}'::jsonb, true),
  ('plus', 'advanced_health_tracking', '{"enabled": true}'::jsonb, true),
  ('family_plus', 'ai_chat', '{"enabled": true, "unlimited": true, "inherits": "plus"}'::jsonb, true),
  ('family_plus', 'personal_schedule_generation', '{"enabled": true, "unlimited": true, "inherits": "plus"}'::jsonb, true),
  ('family_plus', 'family_members', '{"enabled": true}'::jsonb, true),
  ('family_plus', 'family_schedule', '{"enabled": true}'::jsonb, true),
  ('family_plus', 'family_health_tracking', '{"enabled": true}'::jsonb, true)
on conflict (plan_code, entitlement_key) do update
set
  entitlement_value = excluded.entitlement_value,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.usage_quota_rules (
  plan_code,
  feature_key,
  period_unit,
  max_count,
  reset_timezone,
  is_active
)
values
  ('free', 'ai_chat_message', 'day', 3, 'Asia/Ho_Chi_Minh', true),
  ('free', 'personal_schedule_generation', 'month', 3, 'Asia/Ho_Chi_Minh', true),
  ('plus', 'ai_chat_message', 'none', null, 'Asia/Ho_Chi_Minh', true),
  ('plus', 'personal_schedule_generation', 'none', null, 'Asia/Ho_Chi_Minh', true),
  ('family_plus', 'ai_chat_message', 'none', null, 'Asia/Ho_Chi_Minh', true),
  ('family_plus', 'personal_schedule_generation', 'none', null, 'Asia/Ho_Chi_Minh', true)
on conflict (plan_code, feature_key, period_unit) do update
set
  max_count = excluded.max_count,
  reset_timezone = excluded.reset_timezone,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.commission_rates (code, rate, is_active)
values
  ('direct_referral', 0.1000, true)
on conflict (code) do update
set
  rate = excluded.rate,
  is_active = excluded.is_active,
  updated_at = now();

commit;
