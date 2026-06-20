# Database scripts - Authentication DD

## Run order

1. Run `prerequisites/20260620_nanobio_multitenant.sql` once to create the multi-user Supabase schema.
2. Run `prerequisites/20260620_02_auth_profile_bootstrap.sql` to replace the base auth trigger with the profile bootstrap trigger and backfill baseline rows for existing accounts.
3. Run `001_add_auth_lifecycle_fields.sql` to add the lifecycle columns required by AuthGate.
4. Run `002_verify_auth_profile_integrity.sql` in SQL Editor to inspect profile consistency.

## Permissions

Run only from Supabase SQL Editor or controlled database migration tool. Do not package these scripts into Flutter client runtime.

## Notes

- The prerequisite scripts are copied into this DD package for traceability. Use a formal migration runner in a shared/staging/production project; never execute blindly against production without backup/change review.
- `001_add_auth_lifecycle_fields.sql` adds the route-control fields required by the BD/DD.
- The base schema already contains the unique constraints for `health_profiles.user_id` and `lifestyle_habits.user_id`.
- The trigger patch intentionally revokes client `INSERT` from baseline profile tables. Flutter updates the existing rows after onboarding; it does not create them.
