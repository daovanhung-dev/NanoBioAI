-- DD-AUTH-DB-001
-- Verification only. Run in Supabase SQL Editor as an administrator.
-- Expected result: zero rows. Every auth user must have all baseline profile rows.

select
  au.id as auth_user_id,
  au.email,
  case when pu.id is null then true else false end as missing_public_user,
  case when hp.user_id is null then true else false end as missing_health_profile,
  case when lh.user_id is null then true else false end as missing_lifestyle_habits,
  pu.onboarding_status,
  pu.created_at as public_user_created_at
from auth.users au
left join public.users pu on pu.id = au.id
left join public.health_profiles hp on hp.user_id = au.id
left join public.lifestyle_habits lh on lh.user_id = au.id
where pu.id is null
   or hp.user_id is null
   or lh.user_id is null
order by au.created_at desc;

-- Summary count (must be 0):
-- select count(*) as accounts_missing_baseline_rows from (...same query...) q;
