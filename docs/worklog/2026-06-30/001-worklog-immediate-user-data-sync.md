# Worklog — immediate user-data sync

Commit de xuat: `feat(sync): request immediate outbox drain after user data writes`

- Date/timezone: 2026-06-30, Asia/Bangkok
- Task type: coding
- Requested scope: synchronize persistent user actions to Supabase after onboarding, schedule completion, profile updates and other user-owned writes.

## Changes

- Added a core post-commit dispatcher so V1 writers do not directly import the V2-backed cloud-sync implementation.
- Registered the trusted Supabase outbox drain at `main.dart` and `main_v2.dart` after Supabase initialization.
- Added non-blocking immediate drain requests after selected persistent write paths.
- Retained SQLite-first durability, existing trigger-created dirty markers, retry behavior and authenticated user scoping.
- Replaced two existing direct V1 outbox imports with the version-neutral dispatch design.

## Validation

- Static source review: complete.
- Flutter format, analyze and tests: SKIPPED; `dart` and `flutter` are not installed in this environment.
- No Supabase sandbox/RLS verification was run.

## Risks / follow-up

- Cloud sync requires an authenticated Supabase session. Guest writes remain durable locally and are handled by the existing guest-to-account sync flow after authentication.
- Device-only preferences still need an explicit product and backend contract before cloud synchronization.
- Run the documented unit tests and distinct-user RLS acceptance checks in a Flutter-enabled workspace before release.
